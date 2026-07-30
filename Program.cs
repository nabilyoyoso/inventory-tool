// ============================================================================
// INVENTORY SYNC JOB — v2 (matches schema_v2.sql)
// ============================================================================
// What changed from v1: table and column names now match the renamed
// schema, every transactional table now carries its own status and
// cpu/mrp columns, and PRODUCT_STOCK is keyed by SAL_BARCODE alone.
// ============================================================================

using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Npgsql;
using NpgsqlTypes;

var config = new ConfigurationBuilder()
    .SetBasePath(AppContext.BaseDirectory)
    .AddJsonFile("appsettings.json", optional: true)
    .Build();

string sourceConnStr = Environment.GetEnvironmentVariable("ERP_CONNECTION_STRING")
    ?? config["SourceConnectionString"]
    ?? throw new Exception("Missing ERP_CONNECTION_STRING (set it as a GitHub Actions secret, or in appsettings.json for local testing)");
string supabaseConnStr = Environment.GetEnvironmentVariable("SUPABASE_CONNECTION_STRING")
    ?? config["SupabaseConnectionString"]
    ?? throw new Exception("Missing SUPABASE_CONNECTION_STRING (set it as a GitHub Actions secret, or in appsettings.json for local testing)");

Console.WriteLine($"=== Inventory sync started: {DateTime.Now} ===");

using var source = new SqlConnection(sourceConnStr);
using var target = new NpgsqlConnection(supabaseConnStr);

try { await source.OpenAsync(); Console.WriteLine("Connected to production ERP (read-only)."); }
catch (Exception ex) { Console.WriteLine("!! Could not connect to the ERP database:"); Console.WriteLine(ex.Message); return; }

try { await target.OpenAsync(); Console.WriteLine("Connected to Supabase."); }
catch (Exception ex) { Console.WriteLine("!! Could not connect to Supabase:"); Console.WriteLine(ex.Message); return; }

var runner = new SyncRunner(source, target);

// ---- Master data: full refresh every run ----
await runner.RefreshMasterTableAsync(
    "SELECT STORE_CODE, STORE_NAME FROM STORE",
    "store",
    new[] { "store_code", "store_name" },
    new[] { NpgsqlDbType.Text, NpgsqlDbType.Text });

await runner.RefreshMasterTableAsync(
    "SELECT BARCODE, USER_BARCODE, category_name, sub_category_name, NAME FROM PRODUCT_FILE",
    "product_file",
    new[] { "barcode", "user_barcode", "category", "sub_category", "item_name" },
    new[] { NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text });

await runner.RefreshMasterTableAsync(
    // SAL_BARCODE alone is the true unique key — GROUP BY dedupes any real duplicates.
    "SELECT MAX(BARCODE) AS BARCODE, SAL_BARCODE, MAX(SAL_CPU) AS SAL_CPU, MAX(SAL_PRICE) AS SAL_PRICE " +
    "FROM PRODUCT_STOCK GROUP BY SAL_BARCODE",
    "product_stock",
    new[] { "barcode", "sal_barcode", "cpu", "mrp" },
    new[] { NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric });

// ---- Transactional data: incremental sync by date ----
await runner.SyncIncrementalAsync(
    syncKey: "PurchaseRcvDetails",
    targetTable: "purchase_rcv_details",
    sourceDateColumn: "PURCHASE_DATE",
    targetDateColumn: "txn_date",
    buildSourceSql: cutoff =>
        $"SELECT MEMO_NO, PURCHASE_DATE, STORE_CODE, BARCODE, SAL_BARCODE, PUR_PRICE, SAL_PRICE, PUR_QTY, STATUS " +
        $"FROM PURCHASE_RCV_DETAILS WHERE PURCHASE_DATE >= @cutoff",
    targetColumns: new[] { "challan_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "pur_qty", "status" },
    targetTypes: new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text });

await runner.SyncIncrementalAsync(
    syncKey: "StoreDeliveryDetails",
    targetTable: "store_delivery_details",
    sourceDateColumn: "DELIVERY_DATE",
    targetDateColumn: "txn_date",
    buildSourceSql: cutoff =>
        $"SELECT CHALLAN_NO, DELIVERY_DATE, STORE_CODE, DELIVERY_TO, BARCODE, SAL_BARCODE, CPU, SAL_PRICE, DEL_QTY, STATUS " +
        $"FROM STORE_DELIVERY_DETAILS WHERE DELIVERY_DATE >= @cutoff",
    targetColumns: new[] { "challan_no", "txn_date", "delivery_from", "delivery_to", "barcode", "sal_barcode", "cpu", "mrp", "del_qty", "status" },
    targetTypes: new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text });

await runner.SyncIncrementalAsync(
    syncKey: "StoreDeliveryReceive",
    targetTable: "store_delivery_receive",
    sourceDateColumn: "RECEIVE_DATE",
    targetDateColumn: "txn_date",
    buildSourceSql: cutoff =>
        $"SELECT CHALLAN_NO, RECEIVE_DATE, STORE_CODE, DELIVERY_TO, BARCODE, SAL_BARCODE, CPU, SAL_PRICE, DEL_QTY, RCV_QTY, STATUS " +
        $"FROM STOREDELIVERYRECEIVE WHERE RECEIVE_DATE >= @cutoff",
    targetColumns: new[] { "challan_no", "txn_date", "delivery_from", "delivery_to", "barcode", "sal_barcode", "cpu", "mrp", "del_qty", "rcv_qty", "status" },
    targetTypes: new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text });

await runner.SyncIncrementalAsync(
    syncKey: "StoreDml",
    targetTable: "store_dml",
    sourceDateColumn: "DML_DATE",
    targetDateColumn: "txn_date",
    buildSourceSql: cutoff =>
        $"SELECT REF_NO, DML_DATE, STORE_CODE, BARCODE, SAL_BARCODE, CPU, SAL_PRICE, DML_QTY, STATUS " +
        $"FROM STORE_DML WHERE DML_DATE >= @cutoff",
    targetColumns: new[] { "challan_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "dml_qty", "status" },
    targetTypes: new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text });

await runner.SyncIncrementalAsync(
    syncKey: "PurchaseReturnDetails",
    targetTable: "purchase_return_details",
    sourceDateColumn: "RTN_DT",
    targetDateColumn: "txn_date",
    buildSourceSql: cutoff =>
        $"SELECT CHALLAN_NO, RTN_DT, STORE_CODE, BARCODE, SAL_BARCODE, CPU, SAL_PRICE, RTN_QTY, STATUS " +
        $"FROM PURCHASE_RETURN_DETAILS WHERE RTN_DT >= @cutoff",
    targetColumns: new[] { "challan_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "rtn_qty", "status" },
    targetTypes: new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text });

await runner.SyncIncrementalAsync(
    syncKey: "InvTrackingSummary",
    targetTable: "inv_tracking_summary",
    sourceDateColumn: "ScanStartDate",
    targetDateColumn: "txn_date",
    buildSourceSql: cutoff =>
        $"SELECT SessionId, CAST(ScanStartDate AS DATE) AS ScanStartDate, STORE_CODE, Barcode, sBarcode, CPU, MRP, AdjQty " +
        $"FROM InvTrackingSummary WHERE ScanStartDate >= @cutoff",
    targetColumns: new[] { "challan_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "adj_qty" },
    targetTypes: new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric });

await runner.SyncIncrementalAsync(
    syncKey: "Sale",
    targetTable: "sale",
    sourceDateColumn: "INVOICE_DT",
    targetDateColumn: "txn_date",
    buildSourceSql: cutoff =>
        $"SELECT INVOICE_NO, INVOICE_DT, STORE_CODE, BARCODE, SAL_BARCODE, CPU, MRP, SQTY, RQTY " +
        $"FROM SALE WHERE INVOICE_DT >= @cutoff",
    targetColumns: new[] { "invoice_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "sale_qty", "rtn_qty" },
    targetTypes: new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric });

Console.WriteLine($"=== Inventory sync finished: {DateTime.Now} ===");


// ============================================================================
// SYNC RUNNER — unchanged logic from before: master tables get a full
// wipe-and-reload, transactional tables get an incremental delete-and-
// reinsert from the last synced date forward, everything loads via
// Postgres's fast COPY protocol with explicit column types.
// ============================================================================
class SyncRunner
{
    private readonly SqlConnection _source;
    private readonly NpgsqlConnection _target;

    public SyncRunner(SqlConnection source, NpgsqlConnection target)
    {
        _source = source;
        _target = target;
    }

    public async Task RefreshMasterTableAsync(string sourceSql, string targetTable, string[] targetColumns, NpgsqlDbType[] targetTypes)
    {
        const int maxAttempts = 3;
        for (int attempt = 1; attempt <= maxAttempts; attempt++)
        {
            Console.WriteLine(attempt == 1
                ? $"--- Refreshing master table: {targetTable} ---"
                : $"--- Retrying master table: {targetTable} (attempt {attempt}/{maxAttempts}) ---");
            try
            {
                var rows = new List<object?[]>();
                using (var cmd = new SqlCommand(sourceSql, _source))
                using (var reader = await cmd.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        var row = new object?[reader.FieldCount];
                        reader.GetValues(row!);
                        for (int i = 0; i < row.Length; i++)
                            if (row[i] is DBNull) row[i] = null;
                        rows.Add(row);
                    }
                }

                using (var truncate = new NpgsqlCommand($"TRUNCATE TABLE {targetTable}", _target))
                    await truncate.ExecuteNonQueryAsync();

                await BulkInsertAsync(targetTable, targetColumns, targetTypes, rows);
                Console.WriteLine($"    {targetTable}: {rows.Count} rows loaded.");
                return; // success — stop retrying
            }
            catch (Exception ex)
            {
                if (attempt == maxAttempts)
                {
                    Console.WriteLine($"    !! Failed syncing {targetTable} after {maxAttempts} attempts. Error (screenshot/copy this):");
                    Console.WriteLine("    " + ex.Message);
                }
                else
                {
                    Console.WriteLine($"    Attempt {attempt} failed ({ex.Message}). Waiting before retry...");
                    await Task.Delay(TimeSpan.FromSeconds(5 * attempt)); // 5s, then 10s
                }
            }
        }
    }

    public async Task SyncIncrementalAsync(
        string syncKey,
        string targetTable,
        string sourceDateColumn,
        string targetDateColumn,
        Func<string, string> buildSourceSql,
        string[] targetColumns,
        NpgsqlDbType[] targetTypes)
    {
        const int maxAttempts = 3;
        for (int attempt = 1; attempt <= maxAttempts; attempt++)
        {
            Console.WriteLine(attempt == 1
                ? $"--- Syncing: {targetTable} ---"
                : $"--- Retrying: {targetTable} (attempt {attempt}/{maxAttempts}) ---");
            try
            {
                DateTime cutoff = await GetLastSyncedDateAsync(syncKey) ?? new DateTime(2000, 1, 1);

                var rows = new List<object?[]>();
                string sql = buildSourceSql(sourceDateColumn);
                using (var cmd = new SqlCommand(sql, _source))
                {
                    cmd.Parameters.AddWithValue("@cutoff", cutoff);
                    using var reader = await cmd.ExecuteReaderAsync();
                    while (await reader.ReadAsync())
                    {
                        var row = new object?[reader.FieldCount];
                        reader.GetValues(row!);
                        for (int i = 0; i < row.Length; i++)
                            if (row[i] is DBNull) row[i] = null;
                        rows.Add(row);
                    }
                }

                using (var del = new NpgsqlCommand(
                    $"DELETE FROM {targetTable} WHERE {targetDateColumn} >= @cutoff", _target))
                {
                    del.Parameters.AddWithValue("cutoff", cutoff.Date);
                    await del.ExecuteNonQueryAsync();
                }

                await BulkInsertAsync(targetTable, targetColumns, targetTypes, rows);

                DateTime newCutoff = rows.Count > 0 ? DateTime.Now.Date : cutoff;
                await UpdateSyncLogAsync(syncKey, newCutoff, rows.Count);

                Console.WriteLine($"    {targetTable}: {rows.Count} rows synced (from {cutoff:yyyy-MM-dd} onward).");
                return; // success — stop retrying
            }
            catch (Exception ex)
            {
                if (attempt == maxAttempts)
                {
                    Console.WriteLine($"    !! Failed syncing {targetTable} after {maxAttempts} attempts. Error (screenshot/copy this):");
                    Console.WriteLine("    " + ex.Message);
                }
                else
                {
                    Console.WriteLine($"    Attempt {attempt} failed ({ex.Message}). Waiting before retry...");
                    await Task.Delay(TimeSpan.FromSeconds(5 * attempt)); // 5s, then 10s
                }
            }
        }
    }

    private async Task<DateTime?> GetLastSyncedDateAsync(string syncKey)
    {
        using var cmd = new NpgsqlCommand(
            "SELECT last_synced_date FROM sync_log WHERE table_name = @key", _target);
        cmd.Parameters.AddWithValue("key", syncKey);
        var result = await cmd.ExecuteScalarAsync();
        return (result == null || result is DBNull) ? null : (DateTime)result;
    }

    private async Task UpdateSyncLogAsync(string syncKey, DateTime syncedThrough, int rowCount)
    {
        using var cmd = new NpgsqlCommand(
            "UPDATE sync_log SET last_synced_date = @d, last_synced_at = now(), rows_synced = @r WHERE table_name = @key",
            _target);
        cmd.Parameters.AddWithValue("d", syncedThrough);
        cmd.Parameters.AddWithValue("r", rowCount);
        cmd.Parameters.AddWithValue("key", syncKey);
        await cmd.ExecuteNonQueryAsync();
    }

    private async Task BulkInsertAsync(string table, string[] columns, NpgsqlDbType[] types, List<object?[]> rows)
    {
        if (rows.Count == 0) return;

        string colList = string.Join(", ", columns);
        await using var writer = await _target.BeginBinaryImportAsync(
            $"COPY {table} ({colList}) FROM STDIN (FORMAT BINARY)");

        foreach (var row in rows)
        {
            await writer.StartRowAsync();
            for (int i = 0; i < row.Length; i++)
            {
                var val = row[i];
                if (val == null)
                    await writer.WriteNullAsync();
                else if (types[i] == NpgsqlDbType.Date && val is DateTime dt)
                    await writer.WriteAsync(DateOnly.FromDateTime(dt), NpgsqlDbType.Date);
                else
                    await writer.WriteAsync(val, types[i]);
            }
        }

        await writer.CompleteAsync();
    }
}
