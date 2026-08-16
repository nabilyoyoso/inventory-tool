// ============================================================================
// SYNC RELAY — Render-hosted trigger/status service
// ============================================================================
// The relay has no ERP or Supabase database access. It only:
//   1. verifies the caller's Supabase session;
//   2. dispatches the GitHub Actions workflow;
//   3. identifies the exact workflow run created by that dispatch;
//   4. reports status for that exact run when the browser supplies run_id.
//
// This removes the old "latest run" race: a scheduled run can no longer make
// the Refresh button report the wrong run's success/failure.
// ============================================================================
 
using System.Net.Http.Headers;
using System.Text.Json;
 
const string GitHubOwner = "nabilyoyoso";
const string GitHubRepo = "inventory-tool";
const string WorkflowFile = "sync.yml";
 
var builder = WebApplication.CreateBuilder(args);
var port = Environment.GetEnvironmentVariable("PORT") ?? "8080";
builder.WebHost.UseUrls($"http://0.0.0.0:{port}");
 
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
        policy.WithOrigins("https://nabilyoyoso.github.io")
              .AllowAnyHeader()
              .AllowAnyMethod());
});
 
var app = builder.Build();
app.UseCors("AllowFrontend");
 
var httpClient = new HttpClient
{
    Timeout = TimeSpan.FromSeconds(30)
};
httpClient.DefaultRequestHeaders.UserAgent.ParseAdd("inventory-sync-relay");
 
string? supabaseUrl = Environment.GetEnvironmentVariable("SUPABASE_URL");
string? supabaseAnonKey = Environment.GetEnvironmentVariable("SUPABASE_ANON_KEY");
string? githubPat = Environment.GetEnvironmentVariable("GITHUB_PAT");
 
app.MapGet("/", () => "Inventory Sync Relay is running.");
 
// -----------------------------------------------------------------------------
// Trigger a sync and identify the exact GitHub run created by this request.
// -----------------------------------------------------------------------------
app.MapGet("/trigger-sync", async (HttpContext ctx) =>
{
    if (!await IsLoggedInUserAsync(ctx))
    {
        ctx.Response.StatusCode = 401;
        await ctx.Response.WriteAsync("Unauthorized.");
        return;
    }
 
    if (string.IsNullOrWhiteSpace(githubPat))
    {
        ctx.Response.StatusCode = 500;
        await ctx.Response.WriteAsync("Server misconfigured: GITHUB_PAT is not set.");
        return;
    }
 
    DateTimeOffset dispatchStartedAt = DateTimeOffset.UtcNow;
    string requestId = Guid.NewGuid().ToString("N");
 
    using var dispatchReq = new HttpRequestMessage(
        HttpMethod.Post,
        $"https://api.github.com/repos/{GitHubOwner}/{GitHubRepo}/actions/workflows/{WorkflowFile}/dispatches");
 
    AddGitHubHeaders(dispatchReq);
    dispatchReq.Content = new StringContent(
        JsonSerializer.Serialize(new
        {
            @ref = "main",
            inputs = new { request_id = requestId }
        }),
        System.Text.Encoding.UTF8,
        "application/json");
 
    using HttpResponseMessage dispatchResp = await httpClient.SendAsync(dispatchReq);
 
    if (dispatchResp.StatusCode != System.Net.HttpStatusCode.NoContent)
    {
        string detail = await dispatchResp.Content.ReadAsStringAsync();
        ctx.Response.StatusCode = 502;
        await ctx.Response.WriteAsync(
            $"Could not trigger the sync workflow: {(int)dispatchResp.StatusCode} {detail}");
        return;
    }
 
    // GitHub's workflow_dispatch endpoint returns 204 and does not include the
    // run id. Poll briefly until GitHub creates the corresponding run.
    long? runId = await FindWorkflowDispatchRunAsync(dispatchStartedAt, requestId);
 
    ctx.Response.StatusCode = 202;
    ctx.Response.ContentType = "application/json";
    await ctx.Response.WriteAsync(JsonSerializer.Serialize(new
    {
        triggered = true,
        requestId,
        runId,
        triggeredAt = dispatchStartedAt
    }));
});
 
// -----------------------------------------------------------------------------
// Status endpoint.
//
// /sync-status?run_id=123 -> exact run
// /sync-status             -> latest run, used only for the initial header pill
// /sync-status?after=...   -> latest workflow_dispatch run after timestamp
// -----------------------------------------------------------------------------
app.MapGet("/sync-status", async (HttpContext ctx) =>
{
    ctx.Response.ContentType = "application/json";
 
    if (string.IsNullOrWhiteSpace(githubPat))
    {
        await WriteJsonAsync(ctx, new
        {
            isRunning = false,
            lastSuccess = (bool?)null,
            lastFinishedAt = (string?)null,
            runId = (long?)null,
            error = "GITHUB_PAT not set"
        });
        return;
    }
 
    string? runIdText = ctx.Request.Query["run_id"].FirstOrDefault();
    string? afterText = ctx.Request.Query["after"].FirstOrDefault();
 
    if (long.TryParse(runIdText, out long runId))
    {
        await WriteRunStatusAsync(ctx, runId);
        return;
    }
 
    if (DateTimeOffset.TryParse(afterText, out DateTimeOffset after))
    {
        long? found = await FindWorkflowDispatchRunByTimestampAsync(after);
        if (found.HasValue)
        {
            await WriteRunStatusAsync(ctx, found.Value);
            return;
        }
 
        await WriteJsonAsync(ctx, new
        {
            isRunning = true,
            lastSuccess = (bool?)null,
            lastFinishedAt = (string?)null,
            runId = (long?)null,
            waitingForRunId = true
        });
        return;
    }
 
    // Initial page load: latest run is acceptable here because there is no
    // user-triggered run being tracked yet.
    long? latestRunId = await FindLatestWorkflowRunIdAsync();
    if (!latestRunId.HasValue)
    {
        await WriteJsonAsync(ctx, new
        {
            isRunning = false,
            lastSuccess = (bool?)null,
            lastFinishedAt = (string?)null,
            runId = (long?)null
        });
        return;
    }
 
    await WriteRunStatusAsync(ctx, latestRunId.Value);
});
 
app.Run();
 
static void AddGitHubHeaders(HttpRequestMessage request)
{
    request.Headers.Authorization = new AuthenticationHeaderValue(
        "Bearer",
        Environment.GetEnvironmentVariable("GITHUB_PAT"));
    request.Headers.Add("Accept", "application/vnd.github+json");
    request.Headers.Add("X-GitHub-Api-Version", "2022-11-28");
}
 
static async Task<long?> FindWorkflowDispatchRunAsync(DateTimeOffset notBefore, string requestId)
{
    string? pat = Environment.GetEnvironmentVariable("GITHUB_PAT");
    if (string.IsNullOrWhiteSpace(pat)) return null;
 
    using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };
    client.DefaultRequestHeaders.UserAgent.ParseAdd("inventory-sync-relay");
 
    for (int attempt = 0; attempt < 15; attempt++)
    {
        using var req = new HttpRequestMessage(
            HttpMethod.Get,
            $"https://api.github.com/repos/{GitHubOwner}/{GitHubRepo}/actions/workflows/{WorkflowFile}/runs?event=workflow_dispatch&per_page=20");
        AddGitHubHeaders(req);
 
        using HttpResponseMessage resp = await client.SendAsync(req);
        if (resp.IsSuccessStatusCode)
        {
            using JsonDocument doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
            JsonElement runs = doc.RootElement.GetProperty("workflow_runs");
 
            foreach (JsonElement run in runs.EnumerateArray())
            {
                if (!run.TryGetProperty("id", out JsonElement idElement) ||
                    !idElement.TryGetInt64(out long id))
                    continue;
 
                if (run.TryGetProperty("display_title", out JsonElement titleElement))
                {
                    string? title = titleElement.GetString();
                    if (!string.IsNullOrEmpty(title) &&
                        title.Contains(requestId, StringComparison.OrdinalIgnoreCase))
                    {
                        return id;
                    }
                }
            }
 
            long? fallbackId = null;
            DateTimeOffset? fallbackCreated = null;
 
            foreach (JsonElement run in runs.EnumerateArray())
            {
                if (!run.TryGetProperty("id", out JsonElement idElement) ||
                    !idElement.TryGetInt64(out long id))
                    continue;
 
                if (!run.TryGetProperty("created_at", out JsonElement createdElement) ||
                    !DateTimeOffset.TryParse(createdElement.GetString(), out DateTimeOffset createdAt))
                    continue;
 
                if (createdAt < notBefore) continue;
 
                if (!fallbackCreated.HasValue || createdAt < fallbackCreated.Value)
                {
                    fallbackCreated = createdAt;
                    fallbackId = id;
                }
            }
 
            if (fallbackId.HasValue) return fallbackId.Value;
        }
 
        await Task.Delay(TimeSpan.FromSeconds(2));
    }
 
    return null;
}
 
static async Task<long?> FindWorkflowDispatchRunByTimestampAsync(DateTimeOffset notBefore)
{
    string? pat = Environment.GetEnvironmentVariable("GITHUB_PAT");
    if (string.IsNullOrWhiteSpace(pat)) return null;
 
    using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };
    client.DefaultRequestHeaders.UserAgent.ParseAdd("inventory-sync-relay");
 
    for (int attempt = 0; attempt < 10; attempt++)
    {
        using var req = new HttpRequestMessage(
            HttpMethod.Get,
            $"https://api.github.com/repos/{GitHubOwner}/{GitHubRepo}/actions/workflows/{WorkflowFile}/runs?event=workflow_dispatch&per_page=20");
        AddGitHubHeaders(req);
 
        using HttpResponseMessage resp = await client.SendAsync(req);
        if (resp.IsSuccessStatusCode)
        {
            using JsonDocument doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
            JsonElement runs = doc.RootElement.GetProperty("workflow_runs");
 
            long? bestId = null;
            DateTimeOffset? bestCreated = null;
 
            foreach (JsonElement run in runs.EnumerateArray())
            {
                if (!run.TryGetProperty("id", out JsonElement idElement) ||
                    !idElement.TryGetInt64(out long id))
                    continue;
 
                if (!run.TryGetProperty("created_at", out JsonElement createdElement) ||
                    !DateTimeOffset.TryParse(createdElement.GetString(), out DateTimeOffset createdAt))
                    continue;
 
                if (createdAt < notBefore) continue;
 
                if (!bestCreated.HasValue || createdAt < bestCreated.Value)
                {
                    bestCreated = createdAt;
                    bestId = id;
                }
            }
 
            if (bestId.HasValue) return bestId.Value;
        }
 
        await Task.Delay(TimeSpan.FromSeconds(2));
    }
 
    return null;
}
 
static async Task<long?> FindLatestWorkflowRunIdAsync()
{
    string? pat = Environment.GetEnvironmentVariable("GITHUB_PAT");
    if (string.IsNullOrWhiteSpace(pat)) return null;
 
    using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };
    client.DefaultRequestHeaders.UserAgent.ParseAdd("inventory-sync-relay");
 
    using var req = new HttpRequestMessage(
        HttpMethod.Get,
        $"https://api.github.com/repos/{GitHubOwner}/{GitHubRepo}/actions/workflows/{WorkflowFile}/runs?per_page=1");
    AddGitHubHeaders(req);
 
    using HttpResponseMessage resp = await client.SendAsync(req);
    if (!resp.IsSuccessStatusCode) return null;
 
    using JsonDocument doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
    JsonElement runs = doc.RootElement.GetProperty("workflow_runs");
    if (runs.GetArrayLength() == 0) return null;
 
    return runs[0].GetProperty("id").GetInt64();
}
 
static async Task WriteRunStatusAsync(HttpContext ctx, long runId)
{
    string? pat = Environment.GetEnvironmentVariable("GITHUB_PAT");
    if (string.IsNullOrWhiteSpace(pat))
    {
        await WriteJsonAsync(ctx, new
        {
            isRunning = false,
            lastSuccess = (bool?)null,
            lastFinishedAt = (string?)null,
            runId,
            error = "GITHUB_PAT not set"
        });
        return;
    }
 
    using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };
    client.DefaultRequestHeaders.UserAgent.ParseAdd("inventory-sync-relay");
 
    using var req = new HttpRequestMessage(
        HttpMethod.Get,
        $"https://api.github.com/repos/{GitHubOwner}/{GitHubRepo}/actions/runs/{runId}");
    AddGitHubHeaders(req);
 
    using HttpResponseMessage resp = await client.SendAsync(req);
    if (!resp.IsSuccessStatusCode)
    {
        await WriteJsonAsync(ctx, new
        {
            isRunning = false,
            lastSuccess = (bool?)null,
            lastFinishedAt = (string?)null,
            runId,
            error = $"Could not reach GitHub: {(int)resp.StatusCode}"
        });
        return;
    }
 
    using JsonDocument doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
    JsonElement run = doc.RootElement;
 
    string status = run.TryGetProperty("status", out JsonElement statusElement)
        ? statusElement.GetString() ?? ""
        : "";
 
    string? conclusion = run.TryGetProperty("conclusion", out JsonElement conclusionElement)
        ? conclusionElement.GetString()
        : null;
 
    string? updatedAt = run.TryGetProperty("updated_at", out JsonElement updatedElement)
        ? updatedElement.GetString()
        : null;
 
    bool isRunning = status != "completed";
    bool? lastSuccess = status == "completed"
        ? conclusion == "success"
        : null;
 
    await WriteJsonAsync(ctx, new
    {
        isRunning,
        lastSuccess,
        lastFinishedAt = updatedAt,
        runId,
        status,
        conclusion
    });
}
 
static async Task WriteJsonAsync(HttpContext ctx, object value)
{
    ctx.Response.ContentType = "application/json";
    await ctx.Response.WriteAsync(JsonSerializer.Serialize(value));
}
 
// Confirms the request carries a real, currently logged-in Supabase session.
static async Task<bool> IsLoggedInUserAsync(HttpContext ctx)
{
    string? supabaseUrl = Environment.GetEnvironmentVariable("SUPABASE_URL");
    string? supabaseAnonKey = Environment.GetEnvironmentVariable("SUPABASE_ANON_KEY");
 
    if (string.IsNullOrWhiteSpace(supabaseUrl) || string.IsNullOrWhiteSpace(supabaseAnonKey))
    {
        Console.WriteLine("Auth check failed: SUPABASE_URL or SUPABASE_ANON_KEY is missing.");
        return false;
    }
 
    string authHeader = ctx.Request.Headers["Authorization"].ToString();
    if (!authHeader.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
    {
        Console.WriteLine("Auth check failed: no Bearer token was sent.");
        return false;
    }
 
    string token = authHeader["Bearer ".Length..].Trim();
 
    using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };
    using var request = new HttpRequestMessage(
        HttpMethod.Get,
        $"{supabaseUrl.TrimEnd('/')}/auth/v1/user");
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
    request.Headers.Add("apikey", supabaseAnonKey);
 
    using HttpResponseMessage resp = await client.SendAsync(request);
 
    if (!resp.IsSuccessStatusCode)
    {
        string body = await resp.Content.ReadAsStringAsync();
        Console.WriteLine(
            $"Auth check failed: Supabase rejected token — {(int)resp.StatusCode} {resp.StatusCode}. Response: {body}");
    }
 
    return resp.IsSuccessStatusCode;
}
