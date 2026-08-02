// ============================================================================
// INVENTORY SYNC SERVICE — web-triggered version
// ============================================================================
// Same sync logic as before, but now it's a small web service instead of a
// script that runs once and exits. It sits idle until something sends it an
// HTTP request to /sync, then runs the full sync and returns a text log —
// exactly like the console output you've seen before, just delivered as a
// web response instead of printed to a terminal.
//
// A SYNC_SECRET_KEY environment variable protects it from strangers finding
// the URL and triggering syncs — every request must include the matching
// ?key= value or it's rejected.
// ============================================================================

using Microsoft.Data.SqlClient;
using Npgsql;
using NpgsqlTypes;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Render tells the app which port to listen on via the PORT environment variable.
var port = Environment.GetEnvironmentVariable("PORT") ?? "8080";
builder.WebHost.UseUrls($"http://0.0.0.0:{port}");

var app = builder.Build();

// Simple health check — lets you confirm the service is alive by just visiting the root URL.
app.MapGet("/", () => "Inventory Sync Service is running. Trigger a sync at /sync?key=YOUR_SECRET");

app.MapGet("/sync", async (HttpContext ctx) =>
{
    var expectedKey = Environment.GetEnvironmentVariable("SYNC_SECRET_KEY");
    var providedKey = ctx.Request.Query["key"].ToString();

    if (string.IsNullOrEmpty(expectedKey) || providedKey != expectedKey)
    {
        ctx.Response.StatusCode = 401;
        await ctx.Response.WriteAsync("Unauthorized: missing or incorrect key.");
        return;
    }

    var log = new StringBuilder();
    void Log(string msg)
    {
        log.AppendLine(msg);
        Console.WriteLine(msg); // also visible in Render's own logs
    }

    string? sourceConnStr = Environment.GetEnvironmentVariable("ERP_CONNECTION_STRING");
    string? supabaseConnStr = Environment.GetEnvironmentVariable("SUPABASE_CONNECTION_STRING");

    if (string.IsNullOrEmpty(sourceConnStr) || string.IsNullOrEmpty(supabaseConnStr))
    {
        await ctx.Response.WriteAsync("!! Missing ERP_CONNECTION_STRING or SUPABASE_CONNECTION_STRING environment variables.");
        return;
    }

    Log($"=== Inventory sync started: {DateTime.Now} ===");

    using var source = new SqlConnection(sourceConnStr);
    using var target = new NpgsqlConnection(supabaseConnStr);

    try { await source.OpenAsync(); Log("Connected to production ERP (read-only)."); }
    catch (Exception ex) { Log("!! Could not connect to the ERP database: " + ex.Message); await ctx.Response.WriteAsync(log.ToString()); return; }

    try { await target.OpenAsync(); Log("Connected to Supabase."); }
    catch (Exception ex) { Log("!! Could not connect to Supabase: " + ex.Message); await ctx.Response.WriteAsync(log.ToString()); return; }

    var runner = new SyncRunner(source, target, Log);

    await runner.RefreshMasterTableAsync(
        "SELECT STORE_CODE, STORE_NAME FROM STORE",
        "store", new[] { "store_code", "store_name" },
        new[] { NpgsqlDbType.Text, NpgsqlDbType.Text });

    await runner.RefreshMasterTableAsync(
        "SELECT BARCODE, USER_BARCODE, category_name, sub_category_name, NAME FROM PRODUCT_FILE",
        "product_file", new[] { "barcode", "user_barcode", "category", "sub_category", "item_name" },
        new[] { NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text });

    await runner.RefreshMasterTableAsync(
        "SELECT MAX(BARCODE) AS BARCODE, SAL_BARCODE, MAX(SAL_CPU) AS SAL_CPU, MAX(SAL_PRICE) AS SAL_PRICE FROM PRODUCT_STOCK GROUP BY SAL_BARCODE",
        "product_stock", new[] { "barcode", "sal_barcode", "cpu", "mrp" },
        new[] { NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric });

    await runner.SyncIncrementalAsync("PurchaseRcvDetails", "purchase_rcv_details", "PURCHASE_DATE", "txn_date",
        cutoff => $"SELECT MEMO_NO, PURCHASE_DATE, STORE_CODE, BARCODE, SAL_BARCODE, PUR_PRICE, SAL_PRICE, PUR_QTY, STATUS FROM PURCHASE_RCV_DETAILS WHERE PURCHASE_DATE >= @cutoff",
        new[] { "challan_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "pur_qty", "status" },
        new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text });

    await runner.SyncIncrementalAsync("StoreDeliveryDetails", "store_delivery_details", "DELIVERY_DATE", "txn_date",
        cutoff => $"SELECT CHALLAN_NO, DELIVERY_DATE, STORE_CODE, DELIVERY_TO, BARCODE, SAL_BARCODE, CPU, SAL_PRICE, DEL_QTY, STATUS FROM STORE_DELIVERY_DETAILS WHERE DELIVERY_DATE >= @cutoff",
        new[] { "challan_no", "txn_date", "delivery_from", "delivery_to", "barcode", "sal_barcode", "cpu", "mrp", "del_qty", "status" },
        new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text });

    await runner.SyncIncrementalAsync("StoreDeliveryReceive", "store_delivery_receive", "RECEIVE_DATE", "txn_date",
        cutoff => $"SELECT CHALLAN_NO, RECEIVE_DATE, STORE_CODE, DELIVERY_TO, BARCODE, SAL_BARCODE, CPU, SAL_PRICE, DEL_QTY, RCV_QTY, STATUS FROM STOREDELIVERYRECEIVE WHERE RECEIVE_DATE >= @cutoff",
        new[] { "challan_no", "txn_date", "delivery_from", "delivery_to", "barcode", "sal_barcode", "cpu", "mrp", "del_qty", "rcv_qty", "status" },
        new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text });

    await runner.SyncIncrementalAsync("StoreDml", "store_dml", "DML_DATE", "txn_date",
        cutoff => $"SELECT REF_NO, DML_DATE, STORE_CODE, BARCODE, SAL_BARCODE, CPU, SAL_PRICE, DML_QTY, STATUS FROM STORE_DML WHERE DML_DATE >= @cutoff",
        new[] { "challan_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "dml_qty", "status" },
        new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text });

    await runner.SyncIncrementalAsync("PurchaseReturnDetails", "purchase_return_details", "RTN_DT", "txn_date",
        cutoff => $"SELECT CHALLAN_NO, RTN_DT, STORE_CODE, BARCODE, SAL_BARCODE, CPU, SAL_PRICE, RTN_QTY, STATUS FROM PURCHASE_RETURN_DETAILS WHERE RTN_DT >= @cutoff",
        new[] { "challan_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "rtn_qty", "status" },
        new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text });

    await runner.SyncIncrementalAsync("InvTrackingSummary", "inv_tracking_summary", "ScanStartDate", "txn_date",
        cutoff => $"SELECT SessionId, CAST(ScanStartDate AS DATE) AS ScanStartDate, STORE_CODE, Barcode, sBarcode, CPU, MRP, AdjQty FROM InvTrackingSummary WHERE ScanStartDate >= @cutoff",
        new[] { "challan_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "adj_qty" },
        new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric });

    await runner.SyncIncrementalAsync("Sale", "sale", "INVOICE_DT", "txn_date",
        cutoff => $"SELECT INVOICE_NO, INVOICE_DT, STORE_CODE, BARCODE, SAL_BARCODE, CPU, MRP, SQTY, RQTY FROM SALE WHERE INVOICE_DT >= @cutoff",
        new[] { "invoice_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "sale_qty", "rtn_qty" },
        new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric });

    Log($"=== Inventory sync finished: {DateTime.Now} ===");

    ctx.Response.ContentType = "text/plain";
    await ctx.Response.WriteAsync(log.ToString());
});

app.Run();


// ============================================================================
// SYNC RUNNER — identical logic to the console version (master table refresh,
// incremental sync with delete-and-reinsert, retry on failure, fast bulk
// COPY loading) — just takes a logging function instead of writing straight
// to the console, so its output can be captured into the HTTP response too.
// ============================================================================
class SyncRunner
{
    private readonly SqlConnection _source;
    private readonly NpgsqlConnection _target;
    private readonly Action<string> _log;

    public SyncRunner(SqlConnection source, NpgsqlConnection target, Action<string> log)
    {
        _source = source;
        _target = target;
        _log = log;
    }

    public async Task RefreshMasterTableAsync(string sourceSql, string targetTable, string[] targetColumns, NpgsqlDbType[] targetTypes)
    {
        const int maxAttempts = 3;
        for (int attempt = 1; attempt <= maxAttempts; attempt++)
        {
            _log(attempt == 1 ? $"--- Refreshing master table: {targetTable} ---" : $"--- Retrying master table: {targetTable} (attempt {attempt}/{maxAttempts}) ---");
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
                        for (int i = 0; i < row.Length; i++) if (row[i] is DBNull) row[i] = null;
                        rows.Add(row);
                    }
                }

                using (var truncate = new NpgsqlCommand($"TRUNCATE TABLE {targetTable}", _target))
                    await truncate.ExecuteNonQueryAsync();

                await BulkInsertAsync(targetTable, targetColumns, targetTypes, rows);
                _log($"    {targetTable}: {rows.Count} rows loaded.");
                return;
            }
            catch (Exception ex)
            {
                if (attempt == maxAttempts) { _log($"    !! Failed syncing {targetTable} after {maxAttempts} attempts: {ex.Message}"); }
                else { _log($"    Attempt {attempt} failed ({ex.Message}). Waiting before retry..."); await Task.Delay(TimeSpan.FromSeconds(5 * attempt)); }
            }
        }
    }

    public async Task SyncIncrementalAsync(string syncKey, string targetTable, string sourceDateColumn, string targetDateColumn,
        Func<string, string> buildSourceSql, string[] targetColumns, NpgsqlDbType[] targetTypes)
    {
        const int maxAttempts = 3;
        for (int attempt = 1; attempt <= maxAttempts; attempt++)
        {
            _log(attempt == 1 ? $"--- Syncing: {targetTable} ---" : $"--- Retrying: {targetTable} (attempt {attempt}/{maxAttempts}) ---");
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
                        for (int i = 0; i < row.Length; i++) if (row[i] is DBNull) row[i] = null;
                        rows.Add(row);
                    }
                }

                using (var del = new NpgsqlCommand($"DELETE FROM {targetTable} WHERE {targetDateColumn} >= @cutoff", _target))
                {
                    del.Parameters.AddWithValue("cutoff", cutoff.Date);
                    await del.ExecuteNonQueryAsync();
                }

                await BulkInsertAsync(targetTable, targetColumns, targetTypes, rows);

                DateTime newCutoff = rows.Count > 0 ? DateTime.Now.Date : cutoff;
                await UpdateSyncLogAsync(syncKey, newCutoff, rows.Count);

                _log($"    {targetTable}: {rows.Count} rows synced (from {cutoff:yyyy-MM-dd} onward).");
                return;
            }
            catch (Exception ex)
            {
                if (attempt == maxAttempts) { _log($"    !! Failed syncing {targetTable} after {maxAttempts} attempts: {ex.Message}"); }
                else { _log($"    Attempt {attempt} failed ({ex.Message}). Waiting before retry..."); await Task.Delay(TimeSpan.FromSeconds(5 * attempt)); }
            }
        }
    }

    private async Task<DateTime?> GetLastSyncedDateAsync(string syncKey)
    {
        using var cmd = new NpgsqlCommand("SELECT last_synced_date FROM sync_log WHERE table_name = @key", _target);
        cmd.Parameters.AddWithValue("key", syncKey);
        var result = await cmd.ExecuteScalarAsync();
        return (result == null || result is DBNull) ? null : (DateTime)result;
    }

    private async Task UpdateSyncLogAsync(string syncKey, DateTime syncedThrough, int rowCount)
    {
        using var cmd = new NpgsqlCommand("UPDATE sync_log SET last_synced_date = @d, last_synced_at = now(), rows_synced = @r WHERE table_name = @key", _target);
        cmd.Parameters.AddWithValue("d", syncedThrough);
        cmd.Parameters.AddWithValue("r", rowCount);
        cmd.Parameters.AddWithValue("key", syncKey);
        await cmd.ExecuteNonQueryAsync();
    }

    private async Task BulkInsertAsync(string table, string[] columns, NpgsqlDbType[] types, List<object?[]> rows)
    {
        if (rows.Count == 0) return;
        string colList = string.Join(", ", columns);
        await using var writer = await _target.BeginBinaryImportAsync($"COPY {table} ({colList}) FROM STDIN (FORMAT BINARY)");
        foreach (var row in rows)
        {
            await writer.StartRowAsync();
            for (int i = 0; i < row.Length; i++)
            {
                var val = row[i];
                if (val == null) await writer.WriteNullAsync();
                else if (types[i] == NpgsqlDbType.Date && val is DateTime dt) await writer.WriteAsync(DateOnly.FromDateTime(dt), NpgsqlDbType.Date);
                else await writer.WriteAsync(val, types[i]);
            }
        }
        await writer.CompleteAsync();
    }
}
