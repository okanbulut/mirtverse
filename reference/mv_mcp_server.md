# MCP server for instructors

`mv_mcp_server()` starts a [Model Context
Protocol](https://modelcontextprotocol.io) server that lets an AI
assistant (Claude Desktop, Claude Code, OpenAI Codex, ChatGPT, the
OpenAI Agents SDK, or any other MCP client) work on your mirtverse
teaching materials. You describe what you want ("add a question on local
dependence to Lab 1", "use my own exam data in the fairness lab", "turn
my ltm lecture notes into mirtverse") and the assistant does it with the
server's tools: It reads and edits the files in your course folder,
copies and builds labs with the instructor toolkit, looks up mirtverse
functions so it does not invent any, translates older ltm, eRm, TAM and
irtQ code with
[`mirtify()`](https://www.okanbulut.com/mirtverse/reference/mirtify.md),
and runs the materials to check that they still work.

## Usage

``` r
mv_mcp_server(
  course = ".",
  transport = c("stdio", "http"),
  allow_run = NULL,
  host = "127.0.0.1",
  port = 8765,
  token = NULL,
  timeout = 600
)
```

## Arguments

- course:

  path to the course folder the assistant may work in. It is created if
  it does not exist. Defaults to the working directory.

- transport:

  `"stdio"` (the default, for desktop and command-line clients that
  start the server themselves) or `"http"` (a Streamable HTTP endpoint,
  for clients such as ChatGPT that connect to a URL).

- allow_run:

  logical; may the assistant run R code (the `check_material` tool and
  running translated code)? Defaults to `TRUE` for `"stdio"` and `FALSE`
  for `"http"`.

- host, port:

  where the HTTP server listens.

- token:

  for `"http"`, a secret that becomes part of the URL
  (`http://host:port/mcp/<token>`), so only people who know the URL can
  reach the server. A random token is made if `NULL`; use `""` for none.

- timeout:

  seconds a check may run before it is stopped.

## Value

Runs until the client disconnects (stdio) or the R session is
interrupted (http); returns `NULL` invisibly.

## Details

The server can only read and write files inside `course`. Every change
is backed up first (in `course/.mirtverse-mcp/backups`) and can be
undone with the `undo_last_change` tool.

You normally do not call `mv_mcp_server()` yourself. Your AI client
starts it;
[`mv_mcp_config()`](https://www.okanbulut.com/mirtverse/reference/mv_mcp_config.md)
prints the settings to paste into the client.

## See also

[`mv_mcp_config()`](https://www.okanbulut.com/mirtverse/reference/mv_mcp_config.md)
for client setup, and the "AI assistant for instructors" article.

## Examples

``` r
if (FALSE) { # \dontrun{
# Usually started by the AI client, with a command such as
#   Rscript -e "mirtverse::mv_mcp_server('~/courses/edpy507')"
mv_mcp_server("~/courses/edpy507")

# For ChatGPT: serve over HTTP, then expose the port with a tunnel
mv_mcp_server("~/courses/edpy507", transport = "http", port = 8765)
} # }
```
