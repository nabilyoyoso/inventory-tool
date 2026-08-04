// ============================================================================
// SYNC RELAY — tiny always-on service, no database access at all.
// ============================================================================
// Its only job: when a logged-in user clicks "Refresh" on the report page,
// tell GitHub to run the sync workflow right now, and let the page check on
// its progress. All the actual ERP/Supabase work happens inside GitHub
// Actions, not here — this service never touches SQL Server or Postgres.
//
// The GitHub token that can trigger workflow runs lives only as a Render
// environment variable (GITHUB_PAT) — it's never sent to or visible from
// the browser.
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

var httpClient = new HttpClient();
httpClient.DefaultRequestHeaders.UserAgent.ParseAdd("inventory-sync-relay");

string? supabaseUrl = Environment.GetEnvironmentVariable("SUPABASE_URL");
string? supabaseAnonKey = Environment.GetEnvironmentVariable("SUPABASE_ANON_KEY");
string? githubPat = Environment.GetEnvironmentVariable("GITHUB_PAT");

app.MapGet("/", () => "Inventory Sync Relay is running.");

// Triggers the GitHub Actions workflow immediately.
app.MapGet("/trigger-sync", async (HttpContext ctx) =>
{
    if (!await IsLoggedInUserAsync(ctx))
    {
        ctx.Response.StatusCode = 401;
        await ctx.Response.WriteAsync("Unauthorized.");
        return;
    }

    if (string.IsNullOrEmpty(githubPat))
    {
        ctx.Response.StatusCode = 500;
        await ctx.Response.WriteAsync("Server misconfigured: GITHUB_PAT is not set.");
        return;
    }

    var dispatchReq = new HttpRequestMessage(
        HttpMethod.Post,
        $"https://api.github.com/repos/{GitHubOwner}/{GitHubRepo}/actions/workflows/{WorkflowFile}/dispatches");
    dispatchReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", githubPat);
    dispatchReq.Headers.Add("Accept", "application/vnd.github+json");
    dispatchReq.Headers.Add("X-GitHub-Api-Version", "2022-11-28");
    dispatchReq.Content = new StringContent("{\"ref\":\"main\"}", System.Text.Encoding.UTF8, "application/json");

    var resp = await httpClient.SendAsync(dispatchReq);

    if (resp.StatusCode == System.Net.HttpStatusCode.NoContent) // GitHub returns 204 on success
    {
        ctx.Response.StatusCode = 202;
        await ctx.Response.WriteAsync("Sync triggered.");
    }
    else
    {
        var detail = await resp.Content.ReadAsStringAsync();
        ctx.Response.StatusCode = 502;
        await ctx.Response.WriteAsync($"Could not trigger the sync workflow: {(int)resp.StatusCode} {detail}");
    }
});

// Reports on the most recent run of the workflow, so the Refresh button can
// show a real in-progress / success / failure result instead of guessing.
app.MapGet("/sync-status", async (HttpContext ctx) =>
{
    ctx.Response.ContentType = "application/json";

    if (string.IsNullOrEmpty(githubPat))
    {
        await ctx.Response.WriteAsync(JsonSerializer.Serialize(new { isRunning = false, lastSuccess = (bool?)null, lastFinishedAt = (string?)null, error = "GITHUB_PAT not set" }));
        return;
    }

    var runsReq = new HttpRequestMessage(
        HttpMethod.Get,
        $"https://api.github.com/repos/{GitHubOwner}/{GitHubRepo}/actions/workflows/{WorkflowFile}/runs?per_page=1");
    runsReq.Headers.Authorization = new AuthenticationHeaderValue("Bearer", githubPat);
    runsReq.Headers.Add("Accept", "application/vnd.github+json");
    runsReq.Headers.Add("X-GitHub-Api-Version", "2022-11-28");

    var resp = await httpClient.SendAsync(runsReq);
    if (!resp.IsSuccessStatusCode)
    {
        await ctx.Response.WriteAsync(JsonSerializer.Serialize(new { isRunning = false, lastSuccess = (bool?)null, lastFinishedAt = (string?)null, error = "Could not reach GitHub" }));
        return;
    }

    using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
    var runsArray = doc.RootElement.GetProperty("workflow_runs");

    if (runsArray.GetArrayLength() == 0)
    {
        await ctx.Response.WriteAsync(JsonSerializer.Serialize(new { isRunning = false, lastSuccess = (bool?)null, lastFinishedAt = (string?)null }));
        return;
    }

    var latest = runsArray[0];
    string status = latest.GetProperty("status").GetString() ?? ""; // "queued" | "in_progress" | "completed"
    string? conclusion = latest.TryGetProperty("conclusion", out var c) ? c.GetString() : null; // "success" | "failure" | null
    string? updatedAt = latest.TryGetProperty("updated_at", out var u) ? u.GetString() : null;

    bool isRunning = status != "completed";
    bool? lastSuccess = status == "completed" ? conclusion == "success" : null;

    await ctx.Response.WriteAsync(JsonSerializer.Serialize(new { isRunning, lastSuccess, lastFinishedAt = updatedAt }));
});

app.Run();

// Confirms the request carries a real, currently-logged-in user's Supabase
// session token — the same check the previous service used for the
// Refresh button, kept here so only signed-in users can trigger a sync.
static async Task<bool> IsLoggedInUserAsync(HttpContext ctx)
{
    var supabaseUrl = Environment.GetEnvironmentVariable("SUPABASE_URL");
    var supabaseAnonKey = Environment.GetEnvironmentVariable("SUPABASE_ANON_KEY");
    if (string.IsNullOrEmpty(supabaseUrl) || string.IsNullOrEmpty(supabaseAnonKey)) return false;

    var authHeader = ctx.Request.Headers["Authorization"].ToString();
    if (!authHeader.StartsWith("Bearer ")) return false;

    var token = authHeader["Bearer ".Length..];
    using var client = new HttpClient();
    var request = new HttpRequestMessage(HttpMethod.Get, $"{supabaseUrl}/auth/v1/user");
    request.Headers.Add("Authorization", $"Bearer {token}");
    request.Headers.Add("apikey", supabaseAnonKey);
    var resp = await client.SendAsync(request);
    return resp.IsSuccessStatusCode;
}
