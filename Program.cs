// ============================================================================
// INVENTORY SYNC JOB
// ============================================================================
// What this does, in plain terms:
//   1. Connects to your production ERP (SQL Server) using your READ-ONLY
//      login. It only ever runs SELECT statements against that database —
//      never INSERT/UPDATE/DELETE. It cannot change anything there.
//   2. Connects to your Supabase (Postgres) database, where you DO have
//      full permissions.
//   3. Copies data across:
//        - Master tables (Store, ProductFile, ProductStock) are small and
//          change rarely, so they're fully refreshed every run.
//        - Transactional tables (Sale, PurchaseRcvDetails, etc.) are synced
//          incrementally: only rows dated on/after the last successful sync
//          are re-pulled and re-inserted. This keeps it fast on repeat runs
//          while staying correct if a run happens mid-day and misses late
//          same-day entries (they get picked up next time).
//
// How to run it manually (to test):
//   1. Edit appsettings.json with your real connection strings.
//   2. Open a terminal in this folder and run:  dotnet run
//   3. Watch the console output — it prints what it's doing, table by table.
//
// How to run it automatically (once it works):
//   - Windows: Task Scheduler -> Create Task -> Trigger: Daily at (say) 2 AM
//     -> Action: run "dotnet.exe" with argument pointing at the published
//     InventorySync.dll. This runs on your own PC/server, so it costs
//     nothing extra.
//   - Mac/Linux: a cron entry calling `dotnet /path/to/InventorySync.dll`.
// ============================================================================

using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Npgsql;

var config = new ConfigurationBuilder()
    .SetBasePath(AppContext.BaseDirectory)
    .AddJsonFile("appsettings.json", optional: true)   // optional now — only used for local testing
    .Build();

// GitHub Actions injects these as environment variables from encrypted Secrets.
// appsettings.json is just a fallback for anyone testing on their own machine.
string sourceConnStr = Environment.GetEnvironmentVariable("ERP_CONNECTION_STRING")
    ?? config["SourceConnectionString"]
    ?? throw new Exception("Missing ERP_CONNECTION_STRING (set it as a GitHub Actions secret, or in appsettings.json for local testing)");
string supabaseConnStr = Environment.GetEnvironmentVariable("SUPABASE_CONNECTION_STRING")
    ?? config["SupabaseConnectionString"]
    ?? throw new Exception("Missing SUPABASE_CONNECTION_STRING (set it as a GitHub Actions secret, or in appsettings.json for local testing)");

Console.WriteLine($"=== Inventory sync started: {DateTime.Now} ===");

using var source = new SqlConnection(sourceConnStr);
using var target = new NpgsqlConnection(supabaseConnStr);

try
{
    await source.OpenAsync();
    Console.WriteLine("Connected to production ERP (read-only).");
}
catch (Exception ex)
{
    Console.WriteLine("!! Could not connect to the ERP database. Error below — this is exactly");
    Console.WriteLine("!! the kind of message to screenshot and send back if it happens:");
    Console.WriteLine(ex.Message);
    return;
}

try
{
    await target.OpenAsync();
    Console.WriteLine("Connected to Supabase.");
}
catch (Exception ex)
{
    Console.WriteLine("!! Could not connect to Supabase. Error below:");
    Console.WriteLine(ex.Message);
    return;
}

var runner = new SyncRunner(source, target);

// ---- Master data: small tables, full refresh every run ----
await runner.RefreshMasterTableAsync(
    "SELECT STORE_CODE, STORE_NAME FROM STORE",
    "store",
    new[] { "store_code", "store_name" });

await runner.RefreshMasterTableAsync(
    "SELECT BARCODE, USER_BARCODE, NAME, category_name, sub_category_name FROM PRODUCT_FILE",
    "product_file",
    new[] { "barcode", "user_barcode", "item_name", "category_name", "sub_category_name" });

await runner.RefreshMasterTableAsync(
    "SELECT BARCODE, SAL_BARCODE, SAL_CPU, SAL_PRICE FROM PRODUCT_STOCK",
    "product_stock",
    new[] { "barcode", "sal_barcode", "sal_cpu", "sal_price" });

// ---- Transactional data: incremental sync by date ----
await runner.SyncIncrementalAsync(
    syncKey: "PurchaseRcvDetails",
    targetTable: "purchase_rcv_details",
    sourceDateColumn: "PURCHASE_DATE",
    targetDateColumn: "purchase_date",
    buildSourceSql: cutoff =>
        $"SELECT MEMO_NO, PURCHASE_DATE, STORE_CODE, BARCODE, PUR_PRICE, PUR_QTY, SAL_BARCODE " +
        $"FROM PURCHASE_RCV_DETAILS WHERE PURCHASE_DATE >= @cutoff",
    targetColumns: new[] { "memo_no", "purchase_date", "store_code", "barcode", "pur_price", "pur_qty", "sal_barcode" });

await runner.SyncIncrementalAsync(
    syncKey: "StoreDeliveryDetails",
    targetTable: "store_delivery_details",
    sourceDateColumn: "DELIVERY_DATE",
    targetDateColumn: "delivery_date",
    buildSourceSql: cutoff =>
        $"SELECT CHALLAN_NO, DELIVERY_DATE, STORE_CODE, DELIVERY_TO, BARCODE, CPU, DEL_QTY, SAL_BARCODE, SAL_PRICE, STATUS " +
        $"FROM STORE_DELIVERY_DETAILS WHERE DELIVERY_DATE >= @cutoff",
    targetColumns: new[] { "challan_no", "delivery_date", "store_code", "delivery_to", "barcode", "cpu", "del_qty", "sal_barcode", "sal_price", "status" });

await runner.SyncIncrementalAsync(
    syncKey: "StoreDeliveryReceive",
    targetTable: "store_delivery_receive",
    sourceDateColumn: "RECEIVE_DATE",
    targetDateColumn: "receive_date",
    buildSourceSql: cutoff =>
        $"SELECT CHALLAN_NO, STORE_CODE, DELIVERY_TO, BARCODE, CPU, DEL_QTY, RCV_QTY, RECEIVE_DATE, SAL_BARCODE, SAL_PRICE, STATUS " +
        $"FROM STOREDELIVERYRECEIVE WHERE RECEIVE_DATE >= @cutoff",
    targetColumns: new[] { "challan_no", "store_code", "delivery_to", "barcode", "cpu", "del_qty", "rcv_qty", "receive_date", "sal_barcode", "sal_price", "status" });

await runner.SyncIncrementalAsync(
    syncKey: "StoreDml",
    targetTable: "store_dml",
    sourceDateColumn: "DML_DATE",
    targetDateColumn: "dml_date",
    buildSourceSql: cutoff =>
        $"SELECT STORE_CODE, REF_NO, DML_DATE, BARCODE, DML_QTY, SAL_BARCODE, SAL_PRICE, CPU " +
        $"FROM STORE_DML WHERE DML_DATE >= @cutoff",
    targetColumns: new[] { "store_code", "ref_no", "dml_date", "barcode", "dml_qty", "sal_barcode", "sal_price", "cpu" });

await runner.SyncIncrementalAsync(
    syncKey: "PurchaseReturnDetails",
    targetTable: "purchase_return_details",
    sourceDateColumn: "RTN_DT",
    targetDateColumn: "rtn_date",
    buildSourceSql: cutoff =>
        $"SELECT CHALLAN_NO, RTN_DT, STORE_CODE, BARCODE, CPU, RTN_QTY, SAL_BARCODE " +
        $"FROM PURCHASE_RETURN_DETAILS WHERE RTN_DT >= @cutoff",
    targetColumns: new[] { "challan_no", "rtn_date", "store_code", "barcode", "cpu", "rtn_qty", "sal_barcode" });

await runner.SyncIncrementalAsync(
    syncKey: "InvTrackingSummary",
    targetTable: "inv_tracking_summary",
    sourceDateColumn: "ScanStartDate",
    targetDateColumn: "adj_date",
    buildSourceSql: cutoff =>
        $"SELECT STORE_CODE, Barcode, sBarcode, AdjQty, SessionId, MRP, CPU, CAST(ScanStartDate AS DATE) AS AdjDate " +
        $"FROM InvTrackingSummary WHERE ScanStartDate >= @cutoff",
    targetColumns: new[] { "store_code", "barcode", "sbarcode", "adj_qty", "session_id", "mrp", "cpu", "adj_date" });

await runner.SyncIncrementalAsync(
    syncKey: "Sale",
    targetTable: "sale",
    sourceDateColumn: "INVOICE_DT",
    targetDateColumn: "invoice_dt",
    buildSourceSql: cutoff =>
        $"SELECT INVOICE_NO, INVOICE_DT, BARCODE, SAL_BARCODE, CPU, MRP, SQTY, RQTY, STORE_CODE " +
        $"FROM SALE WHERE INVOICE_DT >= @cutoff",
    targetColumns: new[] { "invoice_no", "invoice_dt", "barcode", "sal_barcode", "cpu", "mrp", "sqty", "rqty", "store_code" });

Console.WriteLine($"=== Inventory sync finished: {DateTime.Now} ===");


// ============================================================================
// SYNC RUNNER — the actual logic, kept in one place so each table above is
// just a short declaration of "what to pull and where it goes".
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

    /// <summary>Full refresh of a small master table: wipe it, reload it.</summary>
    public async Task RefreshMasterTableAsync(string sourceSql, string targetTable, string[] targetColumns)
    {
        Console.WriteLine($"--- Refreshing master table: {targetTable} ---");
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

            using var tx = await _target.BeginTransactionAsync();
            using (var truncate = new NpgsqlCommand($"TRUNCATE TABLE {targetTable}", _target, (NpgsqlTransaction)tx))
                await truncate.ExecuteNonQueryAsync();

            foreach (var row in rows)
                await InsertRowAsync(targetTable, targetColumns, row, (NpgsqlTransaction)tx);

            await tx.CommitAsync();
            Console.WriteLine($"    {targetTable}: {rows.Count} rows loaded.");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"    !! Failed syncing {targetTable}. Error (screenshot/copy this):");
            Console.WriteLine("    " + ex.Message);
        }
    }

    /// <summary>
    /// Incremental sync: re-pull everything from (last synced date) onward,
    /// delete that same window in the target, then re-insert. Safe to re-run
    /// and correctly picks up late-arriving same-day rows.
    /// </summary>
    public async Task SyncIncrementalAsync(
        string syncKey,
        string targetTable,
        string sourceDateColumn,
        string targetDateColumn,
        Func<string, string> buildSourceSql,
        string[] targetColumns)
    {
        Console.WriteLine($"--- Syncing: {targetTable} ---");
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

            using var tx = await _target.BeginTransactionAsync();

            using (var del = new NpgsqlCommand(
                $"DELETE FROM {targetTable} WHERE {targetDateColumn} >= @cutoff", _target, (NpgsqlTransaction)tx))
            {
                del.Parameters.AddWithValue("cutoff", cutoff.Date);
                await del.ExecuteNonQueryAsync();
            }

            foreach (var row in rows)
                await InsertRowAsync(targetTable, targetColumns, row, (NpgsqlTransaction)tx);

            DateTime newCutoff = rows.Count > 0 ? DateTime.Now.Date : cutoff;
            await UpdateSyncLogAsync(syncKey, newCutoff, rows.Count, (NpgsqlTransaction)tx);

            await tx.CommitAsync();
            Console.WriteLine($"    {targetTable}: {rows.Count} rows synced (from {cutoff:yyyy-MM-dd} onward).");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"    !! Failed syncing {targetTable}. Error (screenshot/copy this):");
            Console.WriteLine("    " + ex.Message);
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

    private async Task UpdateSyncLogAsync(string syncKey, DateTime syncedThrough, int rowCount, NpgsqlTransaction tx)
    {
        using var cmd = new NpgsqlCommand(
            "UPDATE sync_log SET last_synced_date = @d, last_synced_at = now(), rows_synced = @r WHERE table_name = @key",
            _target, tx);
        cmd.Parameters.AddWithValue("d", syncedThrough);
        cmd.Parameters.AddWithValue("r", rowCount);
        cmd.Parameters.AddWithValue("key", syncKey);
        await cmd.ExecuteNonQueryAsync();
    }

    private async Task InsertRowAsync(string table, string[] columns, object?[] values, NpgsqlTransaction tx)
    {
        string colList = string.Join(", ", columns);
        string paramList = string.Join(", ", columns.Select((c, i) => $"@p{i}"));
        using var cmd = new NpgsqlCommand($"INSERT INTO {table} ({colList}) VALUES ({paramList})", _target, tx);
        for (int i = 0; i < values.Length; i++)
            cmd.Parameters.AddWithValue($"p{i}", values[i] ?? DBNull.Value);
        await cmd.ExecuteNonQueryAsync();
    }
}
