# Run the mirtverse analysis agent server

`mv_agent_server()` starts a [Model Context
Protocol](https://modelcontextprotocol.io) (MCP) server that lets an AI
assistant such as Claude run item response theory analyses on the data
in one project folder. The assistant reads your data, fits and compares
models, checks items, tests for differential item functioning, scores
people, draws plots, explains the results and writes an HTML report, all
with mirtverse. Every step is also written as R code, so `save_script`
leaves a script that reproduces the analysis.

## Usage

``` r
mv_agent_server(
  project = NULL,
  transport = c("stdio", "http"),
  allow_run = NULL,
  host = "127.0.0.1",
  port = 8766,
  token = NULL,
  timeout = 600
)
```

## Arguments

- project:

  path to the project folder that holds the data. By default the
  `MIRTVERSE_PROJECT` environment variable when it is set (the
  `.mcp.json` written by
  [`mv_agent_init()`](https://www.okanbulut.com/mirtverse/reference/mv_agent_init.md)
  sets it), otherwise the working directory, which for the plugin is the
  folder Claude Code was opened in.

- transport:

  `"stdio"` (the client starts the server) or `"http"` (a URL the client
  connects to).

- allow_run:

  logical; allow the `run_r` tool, which runs R code the assistant
  writes. Defaults to `TRUE` for stdio and `FALSE` for HTTP.

- host, port, token:

  where the HTTP server listens; see
  [`mv_mcp_server()`](https://www.okanbulut.com/mirtverse/reference/mv_mcp_server.md).

- timeout:

  seconds a single `run_r` call may take.

## Value

Called for its side effect; returns `NULL` when the client disconnects.

## Details

Fitted models live in the R session of the server and are saved in the
project's `.mirtverse-mcp/models` folder, so they survive a restart.
Files the server writes (plots, scores, reports, scripts) go to the
`mirtverse-output` folder of the project. Your data files are only read,
never changed.

You normally do not call `mv_agent_server()` yourself. The mirtverse
plugin for Claude Code starts it in the folder you work in; for other
clients,
[`mv_mcp_config()`](https://www.okanbulut.com/mirtverse/reference/mv_mcp_config.md)
with `mode = "analysis"` prints the settings, and
[`mv_agent_init()`](https://www.okanbulut.com/mirtverse/reference/mv_agent_init.md)
sets up a folder for Claude Code without the plugin.

## See also

[`mv_agent_init()`](https://www.okanbulut.com/mirtverse/reference/mv_agent_init.md),
[`mv_mcp_config()`](https://www.okanbulut.com/mirtverse/reference/mv_mcp_config.md),
and the "mirtverse agent for Claude" article on the website.

## Examples

``` r
if (FALSE) { # \dontrun{
# The plugin runs a script that calls mv_agent_server() in the folder
# Claude Code was opened in. By hand:
mv_agent_server("~/projects/math-test")
} # }
```
