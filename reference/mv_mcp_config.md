# Settings to connect an AI client to a mirtverse MCP server

Prints the configuration that tells an AI client how to start
[`mv_mcp_server()`](https://www.okanbulut.com/mirtverse/reference/mv_mcp_server.md)
for your course folder, or
[`mv_agent_server()`](https://www.okanbulut.com/mirtverse/reference/mv_agent_server.md)
for an analysis project, with the full path to `Rscript` filled in, and
where the settings go.

## Usage

``` r
mv_mcp_config(
  course = ".",
  client = c("claude-desktop", "claude-code", "codex", "openai-agents", "chatgpt"),
  name = "mirtverse",
  mode = c("course", "analysis")
)
```

## Arguments

- course:

  path to the course folder, or with `mode = "analysis"` the project
  folder that holds your data. With `mode = "analysis"` and
  `client = "claude-code"`, `NULL` gives a command that registers the
  server once for all your projects (it then works in whatever folder
  Claude Code is opened in).

- client:

  one of `"claude-desktop"`, `"claude-code"`, `"codex"` (OpenAI Codex
  CLI and IDE extension), `"openai-agents"` (OpenAI Agents SDK for
  Python) or `"chatgpt"` (ChatGPT developer mode, which connects over
  HTTP).

- name:

  the name the client shows for the server.

- mode:

  `"course"` for the instructor server
  ([`mv_mcp_server()`](https://www.okanbulut.com/mirtverse/reference/mv_mcp_server.md))
  or `"analysis"` for the analysis agent
  ([`mv_agent_server()`](https://www.okanbulut.com/mirtverse/reference/mv_agent_server.md)).

## Value

The configuration text, invisibly. It is also printed.

## Examples

``` r
mv_mcp_config("~/courses/edpy507", client = "claude-desktop")
#> # Claude Desktop: Settings > Developer > Edit Config opens
#> # claude_desktop_config.json. Add this entry, save, and restart Claude.
#> {
#>   "mcpServers": {
#>     "mirtverse": {
#>       "command": "/opt/R/4.6.2/lib/R/bin/Rscript",
#>       "args": [
#>         "-e",
#>         "mirtverse::mv_mcp_server('/home/runner/courses/edpy507')"
#>       ]
#>     }
#>   }
#> }
#> 
mv_mcp_config("~/courses/edpy507", client = "codex")
#> # OpenAI Codex (CLI and IDE extension): add to ~/.codex/config.toml
#> [mcp_servers.mirtverse]
#> command = "/opt/R/4.6.2/lib/R/bin/Rscript"
#> args = ["-e","mirtverse::mv_mcp_server('/home/runner/courses/edpy507')"]
#> startup_timeout_sec = 30
#> tool_timeout_sec = 900
mv_mcp_config("~/projects/math-test", client = "claude-desktop", mode = "analysis")
#> # Claude Desktop: Settings > Developer > Edit Config opens
#> # claude_desktop_config.json. Add this entry, save, and restart Claude.
#> {
#>   "mcpServers": {
#>     "mirtverse": {
#>       "command": "/opt/R/4.6.2/lib/R/bin/Rscript",
#>       "args": [
#>         "-e",
#>         "mirtverse::mv_agent_server('/home/runner/projects/math-test')"
#>       ]
#>     }
#>   }
#> }
#> 
mv_mcp_config(NULL, client = "claude-code", mode = "analysis")
#> # Claude Code: run this once in a terminal.
#> claude mcp add --scope user mirtverse -- "/opt/R/4.6.2/lib/R/bin/Rscript" -e "mirtverse::mv_agent_server()"
```
