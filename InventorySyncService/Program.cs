// ============================================================================
// INVENTORY SYNC SERVICE — v3: all-or-nothing atomic sync
// ============================================================================
// How this version works, in plain terms:
//   PHASE 1 — STAGE: every one of the 10 tables loads its fresh data into a
//   throwaway "_staging" copy. The real tables are never touched during this
//   phase. Each table gets up to 3 retry attempts on its own fresh
//   connection if something hiccups.
//
//   PHASE 2 — CHECK: if ANY table failed to stage after its retries, the
//   whole sync stops here. Nothing gets swapped in. Every real table is
//   left exactly as it was after the last successful sync — stale, but
//   never inconsistent or half-updated.
//
//   PHASE 3 — SWAP: only if all 10 staged successfully, every table is
//   swapped into place inside a single database transaction — either all
//   ten changes commit together, or (if something goes wrong at this very
//   last step) none of them do. There is no possible in-between state.
//
// "Automatic retry" here means: this whole process re-runs cleanly from
// scratch every time it's triggered — either by the 15-minute schedule or
// the manual Refresh button — so a failed attempt simply gets tried again
// in full on the next trigger, with no partial state left behind to worry
// about in between.
//
// AUTH: two ways to trigger a sync —
//   1. ?key=... query string (used by the automated 15-minute scheduler)
//   2. Authorization: Bearer <token> header, where <token> is a real logged
//      -in user's Supabase session token (used by the report page's
//      "Refresh" button — no shared secret needs to live in the public
//      front-end code this way).
// ============================================================================

using Microsoft.Data.SqlClient;
using Npgsql;
using NpgsqlTypes;
using System.Text;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);
var port = Environment.GetEnvironmentVariable("PORT") ?? "8080";
builder.WebHost.UseUrls($"http://0.0.0.0:{port}");

// Without this, the browser blocks every request from the GitHub Pages front-end
// before it's even sent — that's what shows up in the browser as "Failed to fetch".
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
        policy.WithOrigins("https://nabilyoyoso.github.io")
              .AllowAnyHeader()
              .AllowAnyMethod());
});

var app = builder.Build();
app.UseCors("AllowFrontend");

var httpClient = new HttpClient();

app.MapGet("/", () => "Inventory Sync Service is running.");

var syncLock = new SemaphoreSlim(1, 1);

app.MapGet("/sync", async (HttpContext ctx) =>
{
    bool authorized = await IsAuthorizedAsync(ctx, httpClient);
    if (!authorized)
    {
        ctx.Response.StatusCode = 401;
        await ctx.Response.WriteAsync("Unauthorized.");
        return;
    }

    if (!await syncLock.WaitAsync(0))
    {
        ctx.Response.StatusCode = 409;
        await ctx.Response.WriteAsync("A sync is already running. Check /sync/status for progress.");
        return;
    }

    // Kick the actual work off in the background and respond immediately.
    // This avoids holding the HTTP connection open for the several minutes
    // a full sync can take — which risks the browser or Render's own
    // infrastructure killing the connection and showing "Failed to fetch."
    SyncStatus.MarkStarted();
    _ = Task.Run(async () =>
    {
        try
        {
            var log = new StringBuilder();
            void Log(string msg) { log.AppendLine(msg); Console.WriteLine(msg); SyncStatus.UpdateLog(log.ToString()); }

            string? sourceConnStr = Environment.GetEnvironmentVariable("ERP_CONNECTION_STRING");
            string? supabaseConnStr = Environment.GetEnvironmentVariable("SUPABASE_CONNECTION_STRING");

            if (string.IsNullOrEmpty(sourceConnStr) || string.IsNullOrEmpty(supabaseConnStr))
            {
                Log("!! Missing ERP_CONNECTION_STRING or SUPABASE_CONNECTION_STRING.");
                SyncStatus.MarkFinished(false, log.ToString());
                return;
            }

            Log($"=== Inventory sync started: {DateTime.Now} ===");

            var runner = new SyncRunner(sourceConnStr, supabaseConnStr, Log);
            bool success = await runner.RunFullSyncAsync(BuildTableSpecs());

            Log(success
                ? $"=== SYNC SUCCESSFUL — all tables updated together: {DateTime.Now} ==="
                : $"=== SYNC FAILED — no changes were applied, all data unchanged: {DateTime.Now} ===");

            SyncStatus.MarkFinished(success, log.ToString());
        }
        catch (Exception ex)
        {
            SyncStatus.MarkFinished(false, $"!! Unexpected error: {ex.Message}");
        }
        finally
        {
            syncLock.Release();
        }
    });

    ctx.Response.StatusCode = 202; // Accepted — work is running in the background
    ctx.Response.ContentType = "text/plain";
    await ctx.Response.WriteAsync("Sync started in the background. Poll /sync/status for progress.");
});

// Lets the front-end (or you, manually) check on a sync that's running in
// the background, instead of waiting on one long-held request.
app.MapGet("/sync/status", (HttpContext ctx) =>
{
    ctx.Response.ContentType = "application/json";
    return ctx.Response.WriteAsync(JsonSerializer.Serialize(SyncStatus.Snapshot()));
});

app.Run();

// ============================================================================
// AUTH — accepts either the shared secret key (for the scheduler) or a real
// logged-in user's Supabase session token (for the Refresh button).
// ============================================================================
static async Task<bool> IsAuthorizedAsync(HttpContext ctx, HttpClient httpClient)
{
    var expectedKey = Environment.GetEnvironmentVariable("SYNC_SECRET_KEY");
    var providedKey = ctx.Request.Query["key"].ToString();
    if (!string.IsNullOrEmpty(expectedKey) && providedKey == expectedKey) return true;

    var authHeader = ctx.Request.Headers.Authorization.ToString();
    if (authHeader.StartsWith("Bearer "))
    {
        var token = authHeader["Bearer ".Length..];
        var supabaseUrl = Environment.GetEnvironmentVariable("SUPABASE_URL");
        var anonKey = Environment.GetEnvironmentVariable("SUPABASE_ANON_KEY");
        if (string.IsNullOrEmpty(supabaseUrl) || string.IsNullOrEmpty(anonKey)) return false;

        try
        {
            var req = new HttpRequestMessage(HttpMethod.Get, $"{supabaseUrl}/auth/v1/user");
            req.Headers.Add("apikey", anonKey);
            req.Headers.Add("Authorization", $"Bearer {token}");
            var resp = await httpClient.SendAsync(req);
            return resp.IsSuccessStatusCode;
        }
        catch { return false; }
    }

    return false;
}


// ============================================================================
// TABLE SPECIFICATIONS — declarative list of all 10 tables, used to drive
// both the staging phase and the swap phase.
// ============================================================================
static List<TableSpec> BuildTableSpecs() => new()
{
    new TableSpec
    {
        TargetTable = "store", IsMaster = true,
        Columns = new[] { "store_code", "store_name" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Text },
        StaticSql = "SELECT STORE_CODE, STORE_NAME FROM STORE",
    },
    new TableSpec
    {
        TargetTable = "product_file", IsMaster = true,
        Columns = new[] { "barcode", "user_barcode", "category", "sub_category", "item_name" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text },
        StaticSql = "SELECT BARCODE, USER_BARCODE, category_name, sub_category_name, NAME FROM PRODUCT_FILE",
    },
    new TableSpec
    {
        TargetTable = "product_stock", IsMaster = true,
        Columns = new[] { "barcode", "sal_barcode", "cpu", "mrp" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric },
        StaticSql = "SELECT MAX(BARCODE) AS BARCODE, SAL_BARCODE, MAX(SAL_CPU) AS SAL_CPU, MAX(SAL_PRICE) AS SAL_PRICE FROM PRODUCT_STOCK GROUP BY SAL_BARCODE",
    },
    new TableSpec
    {
        TargetTable = "purchase_rcv_details", SyncKey = "PurchaseRcvDetails", TargetDateColumn = "txn_date",
        Columns = new[] { "challan_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "pur_qty", "status" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text },
        BuildSql = () => "SELECT MEMO_NO, PURCHASE_DATE, STORE_CODE, BARCODE, SAL_BARCODE, PUR_PRICE, SAL_PRICE, PUR_QTY, STATUS FROM PURCHASE_RCV_DETAILS WHERE PURCHASE_DATE >= @cutoff",
    },
    new TableSpec
    {
        TargetTable = "store_delivery_details", SyncKey = "StoreDeliveryDetails", TargetDateColumn = "txn_date",
        Columns = new[] { "challan_no", "txn_date", "delivery_from", "delivery_to", "barcode", "sal_barcode", "cpu", "mrp", "del_qty", "status" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text },
        BuildSql = () => "SELECT CHALLAN_NO, DELIVERY_DATE, STORE_CODE, DELIVERY_TO, BARCODE, SAL_BARCODE, CPU, SAL_PRICE, DEL_QTY, STATUS FROM STORE_DELIVERY_DETAILS WHERE DELIVERY_DATE >= @cutoff",
    },
    new TableSpec
    {
        TargetTable = "store_delivery_receive", SyncKey = "StoreDeliveryReceive", TargetDateColumn = "txn_date",
        Columns = new[] { "challan_no", "txn_date", "delivery_from", "delivery_to", "barcode", "sal_barcode", "cpu", "mrp", "del_qty", "rcv_qty", "status" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text },
        BuildSql = () => "SELECT CHALLAN_NO, RECEIVE_DATE, STORE_CODE, DELIVERY_TO, BARCODE, SAL_BARCODE, CPU, SAL_PRICE, DEL_QTY, RCV_QTY, STATUS FROM STOREDELIVERYRECEIVE WHERE RECEIVE_DATE >= @cutoff",
    },
    new TableSpec
    {
        TargetTable = "store_dml", SyncKey = "StoreDml", TargetDateColumn = "txn_date",
        Columns = new[] { "challan_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "dml_qty", "status" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text },
        BuildSql = () => "SELECT REF_NO, DML_DATE, STORE_CODE, BARCODE, SAL_BARCODE, CPU, SAL_PRICE, DML_QTY, STATUS FROM STORE_DML WHERE DML_DATE >= @cutoff",
    },
    new TableSpec
    {
        TargetTable = "purchase_return_details", SyncKey = "PurchaseReturnDetails", TargetDateColumn = "txn_date",
        Columns = new[] { "challan_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "rtn_qty", "status" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Text },
        BuildSql = () => "SELECT CHALLAN_NO, RTN_DT, STORE_CODE, BARCODE, SAL_BARCODE, CPU, SAL_PRICE, RTN_QTY, STATUS FROM PURCHASE_RETURN_DETAILS WHERE RTN_DT >= @cutoff",
    },
    new TableSpec
    {
        TargetTable = "inv_tracking_summary", SyncKey = "InvTrackingSummary", TargetDateColumn = "txn_date",
        Columns = new[] { "challan_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "adj_qty" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric },
        BuildSql = () => "SELECT SessionId, CAST(ScanStartDate AS DATE) AS ScanStartDate, STORE_CODE, Barcode, sBarcode, CPU, MRP, AdjQty FROM InvTrackingSummary WHERE ScanStartDate >= @cutoff",
    },
    new TableSpec
    {
        TargetTable = "sale", SyncKey = "Sale", TargetDateColumn = "txn_date",
        Columns = new[] { "invoice_no", "txn_date", "store_code", "barcode", "sal_barcode", "cpu", "mrp", "sale_qty", "rtn_qty" },
        Types = new[] { NpgsqlDbType.Text, NpgsqlDbType.Date, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Text, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric, NpgsqlDbType.Numeric },
        BuildSql = () => "SELECT INVOICE_NO, INVOICE_DT, STORE_CODE, BARCODE, SAL_BARCODE, CPU, MRP, SQTY, RQTY FROM SALE WHERE INVOICE_DT >= @cutoff",
    },
};

class TableSpec
{
    public string TargetTable = "";
    public bool IsMaster = false;
    public string[] Columns = Array.Empty<string>();
    public NpgsqlDbType[] Types = Array.Empty<NpgsqlDbType>();
    public string? StaticSql;                    // master tables: fixed query, no cutoff
    public Func<string>? BuildSql;                 // incremental tables: query needing @cutoff
    public string? SyncKey;                       // incremental tables: sync_log row key
    public string? TargetDateColumn;               // incremental tables: date column name
    public string StagingTable => $"{TargetTable}_staging";
}


// ============================================================================
// SYNC RUNNER — stage everything, then swap everything atomically.
// ============================================================================
class SyncRunner
{
    private readonly string _sourceConnStr;
    private readonly string _targetConnStr;
    private readonly Action<string> _log;

    public SyncRunner(string sourceConnStr, string targetConnStr, Action<string> log)
    {
        _sourceConnStr = sourceConnStr;
        _targetConnStr = targetConnStr;
        _log = log;
    }

    public async Task<bool> RunFullSyncAsync(List<TableSpec> specs)
    {
        // ---------- PHASE 1: STAGE ----------
        var stagedRowCounts = new Dictionary<string, int>();
        var stagedCutoffs = new Dictionary<string, DateTime>();
        bool allStaged = true;

        foreach (var spec in specs)
        {
            const int maxAttempts = 3;
            bool tableOk = false;

            for (int attempt = 1; attempt <= maxAttempts && !tableOk; attempt++)
            {
                _log(attempt == 1 ? $"--- Staging: {spec.TargetTable} ---" : $"--- Retrying stage: {spec.TargetTable} (attempt {attempt}/{maxAttempts}) ---");
                try
                {
                    DateTime cutoff = spec.IsMaster ? DateTime.MinValue : (await GetLastSyncedDateAsync(spec.SyncKey!) ?? new DateTime(2000, 1, 1));
                    string sql = spec.IsMaster ? spec.StaticSql! : spec.BuildSql!();

                    using (var target = new NpgsqlConnection(_targetConnStr))
                    {
                        await target.OpenAsync();
                        using var create = new NpgsqlCommand($"CREATE TABLE IF NOT EXISTS {spec.StagingTable} (LIKE {spec.TargetTable} INCLUDING ALL)", target);
                        await create.ExecuteNonQueryAsync();
                        using var truncate = new NpgsqlCommand($"TRUNCATE TABLE {spec.StagingTable}", target);
                        await truncate.ExecuteNonQueryAsync();
                    }

                    int rowCount = await StreamCopyAsync(sql, spec.IsMaster ? null : cutoff, spec.StagingTable, spec.Columns, spec.Types);

                    stagedRowCounts[spec.TargetTable] = rowCount;
                    if (!spec.IsMaster) stagedCutoffs[spec.TargetTable] = cutoff;

                    _log($"    {spec.TargetTable}: {rowCount} rows staged.");
                    tableOk = true;
                }
                catch (Exception ex)
                {
                    if (attempt == maxAttempts) _log($"    !! Staging failed for {spec.TargetTable} after {maxAttempts} attempts: {ex.Message}");
                    else { _log($"    Attempt {attempt} failed ({ex.Message}). Waiting before retry..."); await Task.Delay(TimeSpan.FromSeconds(5 * attempt)); }
                }
            }

            if (!tableOk) allStaged = false;
        }

        // ---------- PHASE 2: CHECK ----------
        if (!allStaged)
        {
            _log("!! One or more tables failed to stage. Aborting — no changes applied to any table.");
            return false;
        }

        // ---------- PHASE 3: SWAP (all-or-nothing) ----------
        _log("--- All tables staged successfully. Applying changes atomically... ---");
        try
        {
            using var target = new NpgsqlConnection(_targetConnStr);
            await target.OpenAsync();
            using var tx = await target.BeginTransactionAsync();

            foreach (var spec in specs)
            {
                if (spec.IsMaster)
                {
                    using var swap = new NpgsqlCommand(
                        $"DROP TABLE IF EXISTS {spec.TargetTable}_old; " +
                        $"ALTER TABLE {spec.TargetTable} RENAME TO {spec.TargetTable}_old; " +
                        $"ALTER TABLE {spec.StagingTable} RENAME TO {spec.TargetTable}; " +
                        $"ALTER TABLE {spec.TargetTable}_old RENAME TO {spec.StagingTable}; " +
                        $"TRUNCATE TABLE {spec.StagingTable};",
                        target, (NpgsqlTransaction)tx);
                    await swap.ExecuteNonQueryAsync();
                }
                else
                {
                    var cutoff = stagedCutoffs[spec.TargetTable];
                    using (var del = new NpgsqlCommand($"DELETE FROM {spec.TargetTable} WHERE {spec.TargetDateColumn} >= @cutoff", target, (NpgsqlTransaction)tx))
                    {
                        del.Parameters.AddWithValue("cutoff", cutoff.Date);
                        await del.ExecuteNonQueryAsync();
                    }
                    using (var ins = new NpgsqlCommand($"INSERT INTO {spec.TargetTable} SELECT * FROM {spec.StagingTable}", target, (NpgsqlTransaction)tx))
                        await ins.ExecuteNonQueryAsync();
                    using (var truncStaging = new NpgsqlCommand($"TRUNCATE TABLE {spec.StagingTable}", target, (NpgsqlTransaction)tx))
                        await truncStaging.ExecuteNonQueryAsync();

                    DateTime newCutoff = stagedRowCounts[spec.TargetTable] > 0 ? DateTime.Now.Date : cutoff;
                    using var updLog = new NpgsqlCommand(
                        "UPDATE sync_log SET last_synced_date = @d, last_synced_at = now(), rows_synced = @r WHERE table_name = @key",
                        target, (NpgsqlTransaction)tx);
                    updLog.Parameters.AddWithValue("d", newCutoff);
                    updLog.Parameters.AddWithValue("r", stagedRowCounts[spec.TargetTable]);
                    updLog.Parameters.AddWithValue("key", spec.SyncKey!);
                    await updLog.ExecuteNonQueryAsync();
                }
            }

            await tx.CommitAsync();
            foreach (var spec in specs) _log($"    {spec.TargetTable}: {stagedRowCounts[spec.TargetTable]} rows applied.");
            return true;
        }
        catch (Exception ex)
        {
            _log($"!! Final swap failed: {ex.Message}. The database automatically rolled back — no partial changes were applied.");
            return false;
        }
    }

    private async Task<DateTime?> GetLastSyncedDateAsync(string syncKey)
    {
        using var target = new NpgsqlConnection(_targetConnStr);
        await target.OpenAsync();
        using var cmd = new NpgsqlCommand("SELECT last_synced_date FROM sync_log WHERE table_name = @key", target);
        cmd.Parameters.AddWithValue("key", syncKey);
        var result = await cmd.ExecuteScalarAsync();
        return (result == null || result is DBNull) ? null : (DateTime)result;
    }

    private async Task<int> StreamCopyAsync(string sourceSql, DateTime? cutoffParam, string targetTable, string[] columns, NpgsqlDbType[] types)
    {
        using var source = new SqlConnection(_sourceConnStr);
        await source.OpenAsync();
        using var target = new NpgsqlConnection(_targetConnStr);
        await target.OpenAsync();

        try
        {
            using var cmd = new SqlCommand(sourceSql, source);
            if (cutoffParam.HasValue) cmd.Parameters.AddWithValue("@cutoff", cutoffParam.Value);

            using var reader = await cmd.ExecuteReaderAsync();

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
        catch
        {
            // A connection that dies mid-COPY leaves Postgres in a state where
            // the next command sent on it fails immediately with a confusing
            // "unexpected message type" error — even though that next command
            // is for a completely different, otherwise-healthy table. Clearing
            // the pool here means the very next table opens a guaranteed-fresh
            // connection instead of possibly reusing this broken one.
            NpgsqlConnection.ClearPool(target);
            throw;
        }
    }
}

// ============================================================================
// SYNC STATUS — simple in-memory tracker so /sync can return instantly while
// the real work continues in the background, and callers can poll progress.
// This resets if the service restarts or spins down, which is fine — it's
// just a "what's happening right now" indicator, not a permanent record
// (permanent history already lives in the sync_log table in Supabase).
// ============================================================================
static class SyncStatus
{
    private static readonly object _lock = new();
    private static bool _isRunning = false;
    private static string _lastLog = "";
    private static bool? _lastSuccess = null;
    private static DateTime? _lastFinishedAt = null;

    public static void MarkStarted()
    {
        lock (_lock) { _isRunning = true; _lastLog = ""; }
    }

    public static void UpdateLog(string log)
    {
        lock (_lock) { _lastLog = log; }
    }

    public static void MarkFinished(bool success, string log)
    {
        lock (_lock) { _isRunning = false; _lastSuccess = success; _lastLog = log; _lastFinishedAt = DateTime.Now; }
    }

    public static object Snapshot()
    {
        lock (_lock)
        {
            return new
            {
                isRunning = _isRunning,
                lastSuccess = _lastSuccess,
                lastFinishedAt = _lastFinishedAt,
                log = _lastLog,
            };
        }
    }
}
