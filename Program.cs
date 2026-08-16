// ============================================================================
// INVENTORY SYNC — console version, run by GitHub Actions
// ============================================================================
// Runs once, syncs every table, then exits. GitHub Actions runs this on a
// schedule and also on-demand (triggered by the "Refresh" button through the
// relay service). No web server, no auth logic needed here — only GitHub
// Actions itself ever runs this, using secrets it already trusts.
//
// Safety model:
//   * ERP SQL Server is strictly READ-ONLY. This program performs SELECTs only.
//   * No ERP database setting, schema, index, or persistent transaction mode is changed.
//   * Source reads use short-lived commands with a 5-second lock timeout and
//     LOW deadlock priority, so the ERP workload is protected.
//   * Every table is staged into a Supabase "_staging" copy first.
//   * Only if EVERY table stages successfully does anything get swapped into the
//     real Supabase tables, and that swap happens inside one PostgreSQL transaction.
//   * Incremental tables re-read an overlap window (default 30 days), protecting
//     against ordinary late/backdated ERP entries without touching the ERP.
// ============================================================================

using Microsoft.Data.SqlClient;
using System.Data;
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
    private const int DefaultOverlapDays = 30;
    private const int DefaultSourceCommandTimeoutSeconds = 600;
    // BUGFIX (2026-08-16): every NpgsqlCommand run against Supabase in this
    // file used to rely on Npgsql's built-in default CommandTimeout, which
    // is 30 seconds. That's fine for small master tables, but the sync log
    // showed the swap succeeding for store (11 rows), product_file (17,333),
    // product_stock (18,748), and purchase_rcv_details (28,114 rows) —
    // then failing with "Exception while reading from stream" on the very
    // next table, store_delivery_details, which had 200,745 rows staged.
    // That's the exact signature of a command being aborted mid-flight by a
    // 30-second client-side timeout, not a real database error. Setting
    // CommandTimeout on the connection string (rather than per-command)
    // means every command opened against Supabase in this file — CREATE
    // TABLE, TRUNCATE, INSERT, DELETE, the sync_log upsert — inherits the
    // same generous timeout automatically.
    private const int DefaultTargetCommandTimeoutSeconds = 600;
    private const string AdvisoryLockSql =
        "SELECT pg_advisory_lock(hashtextextended('yoyoso_inventory_sync', 0));";

    // BUGFIX (2026-08-15): every table reference in this file used to be
    // unqualified (e.g. "store_staging" instead of "public.store_staging").
    // That relied entirely on the connecting role's search_path resolving to
    // "public" on its own. Against Supabase's pooled connection string that
    // resolution isn't guaranteed to happen the same way every session, and
    // when it doesn't, Postgres raises 3F000 "no schema has been selected to
    // create in" on the very first CREATE TABLE — which is exactly the error
    // seen in the failed GitHub Actions run. Schema-qualifying every
    // reference removes the dependency on search_path entirely, and
    // SET search_path is issued defensively on every connection as a second
    // layer of protection.
    private const string Schema = "public";

    private static string Qualified(string tableName) => $"{Schema}.{tableName}";

    private readonly string _sourceConnStr;
    private readonly string _targetConnStr;
    private readonly Action<string> _log;
    private readonly int _overlapDays;
    private readonly int _sourceCommandTimeoutSeconds;
    private readonly int _targetCommandTimeoutSeconds;

    public SyncRunner(string sourceConnStr, string targetConnStr, Action<string> log)
    {
        _sourceConnStr = sourceConnStr;
        _log = log;

        _overlapDays = ReadPositiveIntEnvironment("SYNC_OVERLAP_DAYS", DefaultOverlapDays, 1, 365);
        _sourceCommandTimeoutSeconds = ReadPositiveIntEnvironment(
            "ERP_COMMAND_TIMEOUT_SECONDS",
            DefaultSourceCommandTimeoutSeconds,
            60,
            1800);
        _targetCommandTimeoutSeconds = ReadPositiveIntEnvironment(
            "SUPABASE_COMMAND_TIMEOUT_SECONDS",
            DefaultTargetCommandTimeoutSeconds,
            60,
            1800);

        // This is a short-lived batch job. Pooling is intentionally disabled so
        // a broken connection from a failed COPY can never poison the next
        // table's connection. CommandTimeout is set here too, so it applies to
        // every command opened against this connection string without having
        // to remember to set it at each call site.
        var csBuilder = new NpgsqlConnectionStringBuilder(targetConnStr)
        {
            Pooling = false,
            CommandTimeout = _targetCommandTimeoutSeconds,
        };
        _targetConnStr = csBuilder.ConnectionString;
    }

    // Opens a Postgres connection and explicitly resets search_path to
    // "public" before any other statement runs on it. Belt-and-suspenders
    // alongside schema-qualifying every table reference below — either one
    // alone would have prevented the 3F000 failure seen in the sync log.
    private static async Task OpenPgAsync(NpgsqlConnection conn)
    {
        await conn.OpenAsync();
        await using var setPath = new NpgsqlCommand("SET search_path TO public;", conn);
        await setPath.ExecuteNonQueryAsync();
    }

    public async Task<bool> RunFullSyncAsync(List<TableSpec> specs)
    {
        await using var lockConnection = new NpgsqlConnection(_targetConnStr);
        await OpenPgAsync(lockConnection);
        await AcquireAdvisoryLockAsync(lockConnection);

        _log($"--- PostgreSQL sync lock acquired. Incremental overlap: {_overlapDays} day(s). Supabase command timeout: {_targetCommandTimeoutSeconds}s. ---");

        var staged = new List<(TableSpec spec, int rowCount, DateTime cutoff)>();

        await using var source = new SqlConnection(_sourceConnStr);
        await source.OpenAsync();

        // HARD SAFETY RULE:
        // The ERP is production-critical and strictly READ-ONLY. This program
        // performs SELECTs only. It never changes ERP data, schema, indexes,
        // persistent settings, or transaction configuration.
        //
        // These are session-only protections. If our SELECT is blocked by an
        // ERP workload for more than five seconds, the sync fails safely instead
        // of waiting indefinitely or putting pressure on the ERP.
        await using (var safetyCmd = new SqlCommand(
            "SET LOCK_TIMEOUT 5000; SET DEADLOCK_PRIORITY LOW;",
            source))
        {
            await safetyCmd.ExecuteNonQueryAsync();
        }

        try
        {
            await ValidateSourceMasterKeysAsync(source);

            foreach (var spec in specs)
            {
                DateTime cutoff = spec.Kind == TableKind.Incremental
                    ? CalculateSafeCutoff(await GetLastSyncedDateAsync(spec.SyncKey), _overlapDays)
                    : DateTime.MinValue;

                _log(spec.Kind == TableKind.Incremental
                    ? $"--- Staging: {spec.TargetTable} from {cutoff:yyyy-MM-dd} (overlap protected) ---"
                    : $"--- Staging: {spec.TargetTable} (full master reload) ---");

                int rowCount = await StageTableAsync(spec, source, cutoff);
                staged.Add((spec, rowCount, cutoff));
                _log($"    {spec.TargetTable}: {rowCount} rows staged.");
            }

            _log("--- ERP extraction completed using SELECT-only, short-lived read commands. No source transaction was held. ---");
        }
        catch (Exception ex)
        {
            _log($"!! ERP read/staging failed. No Supabase data was swapped: {ex.Message}");
            await TryClearStagingTablesAsync(specs);
            return false;
        }

        _log("--- All tables staged successfully. Swapping into place... ---");

        await using var target = new NpgsqlConnection(_targetConnStr);
        await OpenPgAsync(target);
        await using var targetTx = await target.BeginTransactionAsync();

        try
        {
            foreach (var (spec, rowCount, cutoff) in staged)
            {
                string colList = string.Join(", ", spec.Columns);
                string qualifiedTarget = Qualified(spec.TargetTable);
                string qualifiedStaging = Qualified($"{spec.TargetTable}_staging");

                if (spec.Kind == TableKind.Master)
                {
                    await ExecAsync(target, targetTx, $"TRUNCATE TABLE {qualifiedTarget}");
                    await ExecAsync(
                        target,
                        targetTx,
                        $"INSERT INTO {qualifiedTarget} ({colList}) SELECT {colList} FROM {qualifiedStaging}");
                }
                else
                {
                    await ExecAsync(
                        target,
                        targetTx,
                        $"DELETE FROM {qualifiedTarget} WHERE {spec.TargetDateColumn} >= @cutoff",
                        cmd => cmd.Parameters.AddWithValue("cutoff", cutoff.Date));

                    await ExecAsync(
                        target,
                        targetTx,
                        $"INSERT INTO {qualifiedTarget} ({colList}) SELECT {colList} FROM {qualifiedStaging}");

                    // The watermark is the current ERP day, not "only if rows
                    // were found". The overlap window means later syncs always
                    // re-check recent history, so late/backdated rows in that
                    // protected window cannot be lost.
                    DateTime newCutoff = DateTime.Now.Date;
                    await ExecAsync(
                        target,
                        targetTx,
                        $"""
                        INSERT INTO {Qualified("sync_log")} (table_name, last_synced_date, last_synced_at, rows_synced)
                        VALUES (@k, @d, now(), @r)
                        ON CONFLICT (table_name)
                        DO UPDATE SET
                            last_synced_date = EXCLUDED.last_synced_date,
                            last_synced_at = EXCLUDED.last_synced_at,
                            rows_synced = EXCLUDED.rows_synced
                        """,
                        cmd =>
                        {
                            cmd.Parameters.AddWithValue("d", newCutoff);
                            cmd.Parameters.AddWithValue("r", rowCount);
                            cmd.Parameters.AddWithValue("k", spec.SyncKey);
                        });
                }

                _log($"    {spec.TargetTable}: {rowCount} rows swapped into place.");
            }

            await targetTx.CommitAsync();
            _log("--- Atomic Supabase swap committed successfully. ---");
        }
        catch (Exception ex)
        {
            try { await targetTx.RollbackAsync(); } catch { /* best effort */ }
            _log($"!! Supabase swap failed — transaction rolled back: {ex.Message}");
            await TryClearStagingTablesAsync(specs);
            return false;
        }

        await TryClearStagingTablesAsync(specs);
        _log("--- Staging cleanup complete. Sync finished while the advisory lock remained held. ---");
        return true;
    }

    private async Task<int> StageTableAsync(
        TableSpec spec,
        SqlConnection source,
        DateTime cutoff)
    {
        string stagingTable = Qualified($"{spec.TargetTable}_staging");
        string qualifiedTarget = Qualified(spec.TargetTable);

        await using (var target = new NpgsqlConnection(_targetConnStr))
        {
            await OpenPgAsync(target);
            await using var createStaging = new NpgsqlCommand(
                $"CREATE TABLE IF NOT EXISTS {stagingTable} (LIKE {qualifiedTarget} INCLUDING ALL)",
                target);
            await createStaging.ExecuteNonQueryAsync();

            await using var truncateStaging = new NpgsqlCommand(
                $"TRUNCATE TABLE {stagingTable}",
                target);
            await truncateStaging.ExecuteNonQueryAsync();
        }

        string sql = spec.Kind == TableKind.Incremental
            ? spec.SourceSql
            : spec.SourceSql;

        await using var cmd = new SqlCommand(sql, source)
        {
            CommandTimeout = _sourceCommandTimeoutSeconds
        };

        if (spec.Kind == TableKind.Incremental)
        {
            cmd.Parameters.Add("@cutoff", System.Data.SqlDbType.Date).Value = cutoff.Date;
        }

        await using var reader = await cmd.ExecuteReaderAsync(CommandBehavior.SequentialAccess);
        await using var targetConnection = new NpgsqlConnection(_targetConnStr);
        await OpenPgAsync(targetConnection);

        string colList = string.Join(", ", spec.Columns);
        await using var writer = await targetConnection.BeginBinaryImportAsync(
            $"COPY {stagingTable} ({colList}) FROM STDIN (FORMAT BINARY)");

        int count = 0;
        var row = new object?[spec.Columns.Length];

        while (await reader.ReadAsync())
        {
            reader.GetValues(row!);
            await writer.StartRowAsync();

            for (int i = 0; i < row.Length; i++)
            {
                object? value = row[i] is DBNull ? null : row[i];

                if (value is null)
                {
                    await writer.WriteNullAsync();
                }
                else if (spec.Types[i] == NpgsqlDbType.Date && value is DateTime dt)
                {
                    await writer.WriteAsync(DateOnly.FromDateTime(dt), NpgsqlDbType.Date);
                }
                else
                {
                    await writer.WriteAsync(value, spec.Types[i]);
                }
            }

            count++;
        }

        await writer.CompleteAsync();
        return count;
    }

    private async Task<DateTime?> GetLastSyncedDateAsync(string syncKey)
    {
        await using var conn = new NpgsqlConnection(_targetConnStr);
        await OpenPgAsync(conn);
        await using var cmd = new NpgsqlCommand(
            $"SELECT last_synced_date FROM {Qualified("sync_log")} WHERE table_name = @key",
            conn);
        cmd.Parameters.AddWithValue("key", syncKey);
        object? result = await cmd.ExecuteScalarAsync();
        return result is null || result is DBNull ? null : (DateTime)result;
    }

    private static DateTime CalculateSafeCutoff(DateTime? lastSyncedDate, int overlapDays)
    {
        DateTime baseline = (lastSyncedDate ?? new DateTime(2000, 1, 1)).Date;
        DateTime cutoff = baseline.AddDays(-overlapDays);
        return cutoff < new DateTime(2000, 1, 1) ? new DateTime(2000, 1, 1) : cutoff;
    }

    private async Task ValidateSourceMasterKeysAsync(SqlConnection source)
    {
        // STORE_CODE and PRODUCT_FILE.BARCODE are direct relationship keys in
        // Supabase and must be unique in the source master.
        await EnsureNoDuplicateKeyAsync(
            source,
            "SELECT TOP (1) STORE_CODE FROM STORE WHERE STORE_CODE IS NOT NULL GROUP BY STORE_CODE HAVING COUNT_BIG(*) > 1",
            "STORE.STORE_CODE");

        await EnsureNoDuplicateKeyAsync(
            source,
            "SELECT TOP (1) BARCODE FROM PRODUCT_FILE WHERE BARCODE IS NOT NULL GROUP BY BARCODE HAVING COUNT_BIG(*) > 1",
            "PRODUCT_FILE.BARCODE");

        // PRODUCT_STOCK is intentionally normalized by the source SELECT
        // (GROUP BY SAL_BARCODE with MAX pricing), so raw duplicate SAL_BARCODE
        // rows are not automatically an error in the ERP schema.
    }

    private async Task EnsureNoDuplicateKeyAsync(
        SqlConnection source,
        string sql,
        string keyName)
    {
        await using var cmd = new SqlCommand(sql, source)
        {
            CommandTimeout = _sourceCommandTimeoutSeconds
        };

        object? duplicate = await cmd.ExecuteScalarAsync();
        if (duplicate is not null && duplicate is not DBNull)
        {
            throw new InvalidOperationException(
                $"Source master-data validation failed: duplicate {keyName} value '{duplicate}'. " +
                "The sync was stopped to prevent report quantity multiplication.");
        }
    }

    private static async Task ExecAsync(
        NpgsqlConnection conn,
        NpgsqlTransaction tx,
        string sql,
        Action<NpgsqlCommand>? configure = null)
    {
        await using var cmd = new NpgsqlCommand(sql, conn, tx);
        configure?.Invoke(cmd);
        await cmd.ExecuteNonQueryAsync();
    }

    private static async Task AcquireAdvisoryLockAsync(NpgsqlConnection conn)
    {
        await using var cmd = new NpgsqlCommand(AdvisoryLockSql, conn);
        await cmd.ExecuteNonQueryAsync();
    }

    private async Task TryClearStagingTablesAsync(IEnumerable<TableSpec> specs)
    {
        await using var target = new NpgsqlConnection(_targetConnStr);
        try
        {
            await OpenPgAsync(target);
        }
        catch (Exception ex)
        {
            _log($"    (warning) Could not open Supabase connection for staging cleanup: {ex.Message}");
            return;
        }

        foreach (var spec in specs)
        {
            try
            {
                await using var cmd = new NpgsqlCommand(
                    $"TRUNCATE TABLE {Qualified($"{spec.TargetTable}_staging")}",
                    target);
                await cmd.ExecuteNonQueryAsync();
            }
            catch (Exception ex)
            {
                _log($"    (warning) Could not clear {spec.TargetTable}_staging: {ex.Message}");
            }
        }
    }

    private static int ReadPositiveIntEnvironment(
        string name,
        int defaultValue,
        int min,
        int max)
    {
        string? raw = Environment.GetEnvironmentVariable(name);
        if (int.TryParse(raw, out int value) && value >= min && value <= max)
        {
            return value;
        }

        return defaultValue;
    }
}
