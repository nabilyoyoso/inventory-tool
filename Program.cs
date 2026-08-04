// ============================================================================
// INVENTORY SYNC — console version, run by GitHub Actions
// ============================================================================
// Runs once, syncs every table, then exits. GitHub Actions runs this on a
// schedule and also on-demand (triggered by the "Refresh" button through the
// relay service). No web server, no auth logic needed here — only GitHub
// Actions itself ever runs this, using secrets it already trusts.
//
// Safety model: every table is staged into a "_staging" copy first. Only if
// EVERY table stages successfully does anything get swapped into the real
// tables — and that swap happens inside one Postgres transaction, so either
// everything updates together or nothing does. A network blip partway
// through never leaves your data half-updated.
// ============================================================================

using Microsoft.Data.SqlClient;
using Npgsql;
using NpgsqlTypes;

string? sourceConnStr = Environment.GetEnvironmentVariable("ERP_CONNECTION_STRING");
string? supabaseConnStr = Environment.GetEnvironmentVariable("SUPABASE_CONNECTION_STRING");

if (string.IsNullOrEmpty(sourceConnStr) || string.IsNullOrEmpty(supabaseConnStr))
{
    Console.Error.WriteLine("!! Missing ERP_CONNECTION_STRING or SUPABASE_CONNECTION_STRING environment variables.");
    Environment.Exit(1);
    return;
}

void Log(string msg) => Console.WriteLine(msg);

Log($"=== Inventory sync started: {DateTime.Now} ===");

var runner = new SyncRunner(sourceConnStr, supabaseConnStr, Log);
bool success = await runner.RunFullSyncAsync(BuildTableSpecs());

Log(success
    ? $"=== SYNC SUCCESSFUL — all tables updated together: {DateTime.Now} ==="
    : $"=== SYNC FAILED — no changes were applied, all data unchanged: {DateTime.Now} ===");

// A non-zero exit code makes GitHub Actions mark the run as failed (visible
// with a red X in the Actions tab), so failures are never silent.
Environment.Exit(success ? 0 : 1);

// ============================================================================
// TABLE DEFINITIONS
// ============================================================================
static List<TableSpec> BuildTableSpecs() => new()
{
    new TableSpec
    {
        Kind = TableKind.Master, TargetTable = "store",
        Columns = new[] { "store_code", "store_name" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Text },
        SourceSql = "SELECT STORE_CODE, STORE_NAME FROM STORE",
    },
    new TableSpec
    {
        Kind = TableKind.Master, TargetTable = "product_file",
        Columns = new[] { "barcode", "user_barcode", "category", "sub_category", "item_name" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text },
        SourceSql = "SELECT BARCODE, USER_BARCODE, category_name, sub_category_name, NAME FROM PRODUCT_FILE",
    },
    new TableSpec
    {
        Kind = TableKind.Master, TargetTable = "product_stock",
        Columns = new[] { "barcode", "sal_barcode", "cpu", "mrp" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric },
        SourceSql = "SELECT MAX(BARCODE) AS BARCODE, SAL_BARCODE, MAX(SAL_CPU) AS SAL_CPU, MAX(SAL_PRICE) AS SAL_PRICE FROM PRODUCT_STOCK GROUP BY SAL_BARCODE",
    },
    new TableSpec
    {
        Kind = TableKind.Incremental, SyncKey = "PurchaseRcvDetails", TargetTable = "purchase_rcv_details", TargetDateColumn = "txn_date",
        Columns = new[] { "challan_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "pur_qty", "status" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text },
        SourceSql = "SELECT MEMO_NO, PURCHASE_DATE, STORE_CODE, BARCODE, SAL_BARCODE, PUR_PRICE, SAL_PRICE, PUR_QTY, STATUS FROM PURCHASE_RCV_DETAILS WHERE PURCHASE_DATE >= @cutoff",
    },
    new TableSpec
    {
        Kind = TableKind.Incremental, SyncKey = "StoreDeliveryDetails", TargetTable = "store_delivery_details", TargetDateColumn = "txn_date",
        Columns = new[] { "challan_no", "txn_date", "delivery_from", "delivery_to", "barcode", "sal_barcode", "cpu", "mrp", "del_qty", "status" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text },
        SourceSql = "SELECT CHALLAN_NO, DELIVERY_DATE, STORE_CODE, DELIVERY_TO, BARCODE, SAL_BARCODE, CPU, SAL_PRICE, DEL_QTY, STATUS FROM STORE_DELIVERY_DETAILS WHERE DELIVERY_DATE >= @cutoff",
    },
    new TableSpec
    {
        Kind = TableKind.Incremental, SyncKey = "StoreDeliveryReceive", TargetTable = "store_delivery_receive", TargetDateColumn = "txn_date",
        Columns = new[] { "challan_no", "txn_date", "delivery_from", "delivery_to", "barcode", "sal_barcode", "cpu", "mrp", "del_qty", "rcv_qty", "status" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text },
        SourceSql = "SELECT CHALLAN_NO, RECEIVE_DATE, STORE_CODE, DELIVERY_TO, BARCODE, SAL_BARCODE, CPU, SAL_PRICE, DEL_QTY, RCV_QTY, STATUS FROM STOREDELIVERYRECEIVE WHERE RECEIVE_DATE >= @cutoff",
    },
    new TableSpec
    {
        Kind = TableKind.Incremental, SyncKey = "StoreDml", TargetTable = "store_dml", TargetDateColumn = "txn_date",
        Columns = new[] { "challan_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "dml_qty", "status" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text },
        SourceSql = "SELECT REF_NO, DML_DATE, STORE_CODE, BARCODE, SAL_BARCODE, CPU, SAL_PRICE, DML_QTY, STATUS FROM STORE_DML WHERE DML_DATE >= @cutoff",
    },
    new TableSpec
    {
        Kind = TableKind.Incremental, SyncKey = "PurchaseReturnDetails", TargetTable = "purchase_return_details", TargetDateColumn = "txn_date",
        Columns = new[] { "challan_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "rtn_qty", "status" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text },
        SourceSql = "SELECT CHALLAN_NO, RTN_DT, STORE_CODE, BARCODE, SAL_BARCODE, CPU, SAL_PRICE, RTN_QTY, STATUS FROM PURCHASE_RETURN_DETAILS WHERE RTN_DT >= @cutoff",
    },
    new TableSpec
    {
        Kind = TableKind.Incremental, SyncKey = "InvTrackingSummary", TargetTable = "inv_tracking_summary", TargetDateColumn = "txn_date",
        Columns = new[] { "challan_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "adj_qty" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric },
        SourceSql = "SELECT SessionId, CAST(ScanStartDate AS DATE) AS ScanStartDate, STORE_CODE, Barcode, sBarcode, CPU, MRP, AdjQty FROM InvTrackingSummary WHERE ScanStartDate >= @cutoff",
    },
    new TableSpec
    {
        Kind = TableKind.Incremental, SyncKey = "Sale", TargetTable = "sale", TargetDateColumn = "txn_date",
        Columns = new[] { "invoice_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "sale_qty", "rtn_qty" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric },
        SourceSql = "SELECT INVOICE_NO, INVOICE_DT, STORE_CODE, BARCODE, SAL_BARCODE, CPU, MRP, SQTY, RQTY FROM SALE WHERE INVOICE_DT >= @cutoff",
    },
};

// ============================================================================
// SUPPORTING TYPES
// ============================================================================
enum TableKind { Master, Incremental }

class TableSpec
{
    public required TableKind Kind { get; init; }
    public string SyncKey { get; init; } = "";
    public required string TargetTable { get; init; }
    public required string[] Columns { get; init; }
    public required NpgsqlDbType[] Types { get; init; }
    public required string SourceSql { get; init; }
    public string? TargetDateColumn { get; init; }
}

// ============================================================================
// SYNC RUNNER
// ============================================================================
class SyncRunner
{
    private readonly string _sourceConnStr;
    private readonly string _targetConnStr;
    private readonly Action<string> _log;

    public SyncRunner(string sourceConnStr, string targetConnStr, Action<string> log)
    {
        _sourceConnStr = sourceConnStr;

        // Connection pooling is switched off entirely. This is a short-lived
        // batch job, not a long-running web app, so the small extra cost of
        // opening a fresh connection each time is irrelevant — and it
        // permanently rules out a broken connection from one failed table
        // "poisoning" the next table's connection, which pooling was doing.
        var csBuilder = new NpgsqlConnectionStringBuilder(targetConnStr) { Pooling = false };
        _targetConnStr = csBuilder.ConnectionString;

        _log = log;
    }

    public async Task<bool> RunFullSyncAsync(List<TableSpec> specs)
    {
        var staged = new List<(TableSpec spec, int rowCount, DateTime? cutoff)>();

        foreach (var spec in specs)
        {
            var (ok, rowCount, cutoff) = await StageTableAsync(spec);
            if (!ok)
            {
                _log("!! One or more tables failed to stage. Aborting — no changes applied to any table.");
                return false;
            }
            staged.Add((spec, rowCount, cutoff));
        }

        _log("--- All tables staged successfully. Swapping into place... ---");

        await using var target = new NpgsqlConnection(_targetConnStr);
        await target.OpenAsync();
        await using var tx = await target.BeginTransactionAsync();

        try
        {
            foreach (var (spec, rowCount, cutoff) in staged)
            {
                string colList = string.Join(", ", spec.Columns);

                if (spec.Kind == TableKind.Master)
                {
                    await ExecAsync(target, tx, $"TRUNCATE TABLE {spec.TargetTable}");
                    await ExecAsync(target, tx, $"INSERT INTO {spec.TargetTable} ({colList}) SELECT {colList} FROM {spec.TargetTable}_staging");
                }
                else
                {
                    await ExecAsync(target, tx,
                        $"DELETE FROM {spec.TargetTable} WHERE {spec.TargetDateColumn} >= @cutoff",
                        cmd => cmd.Parameters.AddWithValue("cutoff", (cutoff ?? new DateTime(2000, 1, 1)).Date));

                    await ExecAsync(target, tx, $"INSERT INTO {spec.TargetTable} ({colList}) SELECT {colList} FROM {spec.TargetTable}_staging");

                    DateTime newCutoff = rowCount > 0 ? DateTime.Now.Date : (cutoff ?? new DateTime(2000, 1, 1));
                    await ExecAsync(target, tx,
                        "UPDATE sync_log SET last_synced_date = @d, last_synced_at = now(), rows_synced = @r WHERE table_name = @k",
                        cmd => { cmd.Parameters.AddWithValue("d", newCutoff); cmd.Parameters.AddWithValue("r", rowCount); cmd.Parameters.AddWithValue("k", spec.SyncKey); });
                }

                _log($"    {spec.TargetTable}: {rowCount} rows swapped into place.");
            }

            await tx.CommitAsync();
            return true;
        }
        catch (Exception ex)
        {
            await tx.RollbackAsync();
            _log($"!! Swap step failed, rolled back everything: {ex.Message}");
            return false;
        }
    }

    private static async Task ExecAsync(NpgsqlConnection conn, NpgsqlTransaction tx, string sql, Action<NpgsqlCommand>? configure = null)
    {
        using var cmd = new NpgsqlCommand(sql, conn, tx);
        configure?.Invoke(cmd);
        await cmd.ExecuteNonQueryAsync();
    }

    private async Task<(bool ok, int rowCount, DateTime? cutoff)> StageTableAsync(TableSpec spec)
    {
        string stagingTable = $"{spec.TargetTable}_staging";
        const int maxAttempts = 3;

        DateTime? cutoff = spec.Kind == TableKind.Incremental
            ? (await GetLastSyncedDateAsync(spec.SyncKey) ?? new DateTime(2000, 1, 1))
            : null;

        for (int attempt = 1; attempt <= maxAttempts; attempt++)
        {
            _log(attempt == 1 ? $"--- Staging: {spec.TargetTable} ---" : $"--- Retrying stage: {spec.TargetTable} (attempt {attempt}/{maxAttempts}) ---");
            try
            {
                await using (var target = new NpgsqlConnection(_targetConnStr))
                {
                    await target.OpenAsync();
                    using var createStaging = new NpgsqlCommand($"CREATE TABLE IF NOT EXISTS {stagingTable} (LIKE {spec.TargetTable} INCLUDING ALL)", target);
                    await createStaging.ExecuteNonQueryAsync();
                    using var truncateStaging = new NpgsqlCommand($"TRUNCATE TABLE {stagingTable}", target);
                    await truncateStaging.ExecuteNonQueryAsync();
                }

                int rowCount = await StreamCopyAsync(spec.SourceSql, cutoff, stagingTable, spec.Columns, spec.Types);
                _log($"    {spec.TargetTable}: {rowCount} rows staged.");
                return (true, rowCount, cutoff);
            }
            catch (Exception ex)
            {
                if (attempt == maxAttempts) { _log($"    !! Staging failed for {spec.TargetTable} after {maxAttempts} attempts: {ex.Message}"); }
                else { _log($"    Attempt {attempt} failed ({ex.Message}). Waiting before retry..."); await Task.Delay(TimeSpan.FromSeconds(5 * attempt)); }
            }
        }
        return (false, 0, cutoff);
    }

    private async Task<DateTime?> GetLastSyncedDateAsync(string syncKey)
    {
        await using var conn = new NpgsqlConnection(_targetConnStr);
        await conn.OpenAsync();
        using var cmd = new NpgsqlCommand("SELECT last_synced_date FROM sync_log WHERE table_name = @key", conn);
        cmd.Parameters.AddWithValue("key", syncKey);
        var result = await cmd.ExecuteScalarAsync();
        return (result == null || result is DBNull) ? null : (DateTime)result;
    }

    private async Task<int> StreamCopyAsync(string sourceSql, DateTime? cutoffParam, string targetTable, string[] columns, NpgsqlDbType[] types)
    {
        using var source = new SqlConnection(_sourceConnStr);
        await source.OpenAsync();
        using var cmd = new SqlCommand(sourceSql, source) { CommandTimeout = 300 };
        if (cutoffParam.HasValue) cmd.Parameters.AddWithValue("@cutoff", cutoffParam.Value);
        using var reader = await cmd.ExecuteReaderAsync();

        await using var target = new NpgsqlConnection(_targetConnStr);
        await target.OpenAsync();

        string colList = string.Join(", ", columns);
        await using var writer = await target.BeginBinaryImportAsync($"COPY {targetTable} ({colList}) FROM STDIN (FORMAT BINARY)");

        int count = 0;
        var row = new object?[columns.Length];
        while (await reader.ReadAsync())
        {
            reader.GetValues(row!);
            await writer.StartRowAsync();
            for (int i = 0; i < row.Length; i++)
            {
                var val = row[i] is DBNull ? null : row[i];
                if (val == null) await writer.WriteNullAsync();
                else if (types[i] == NpgsqlDbType.Date && val is DateTime dt) await writer.WriteAsync(DateOnly.FromDateTime(dt), NpgsqlDbType.Date);
                else await writer.WriteAsync(val, types[i]);
            }
            count++;
        }

        await writer.CompleteAsync();
        return count;
    }
}
