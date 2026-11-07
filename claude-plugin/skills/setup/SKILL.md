---
name: setup
description: Set up or troubleshoot the mirtverse agent - check that R and the mirtverse package are installed and connect the mirtverse MCP server to Claude Code. Use when the mirtverse tools are missing, the server fails to start, or the user asks how to get started with the mirtverse agent.
---

# Set up the mirtverse agent

The skills of this plugin use the tools of the `mirtverse` MCP server. The
server is part of the mirtverse R package and runs on the user's computer,
so it is connected once, separately from the plugin. It needs R (4.1 or
later) and the mirtverse package.

1. **Check R.** Run `Rscript --version`. If it is missing, tell the user to
   install R from https://cran.r-project.org (on Windows, see step 4).
2. **Check the package.** Run
   `Rscript -e "packageVersion('mirtverse')"`. If it is missing, install it
   (ask first; it takes a few minutes):
   `Rscript -e "install.packages('remotes', repos = 'https://cloud.r-project.org'); remotes::install_github('okanbulut/mirtverse')"`
3. **Connect the server, once for all projects.** Ask the user before
   running it, then run:

   ```
   claude mcp add --scope user mirtverse -- Rscript -e "mirtverse::mv_agent_server()"
   ```

   The server works in whatever folder Claude Code is opened in. Ask the
   user to restart Claude Code (or run `/mcp` and reconnect `mirtverse`),
   then check that the tools (`project_overview`, `fit_model`, ...) are
   available. If `claude mcp list` already shows a `mirtverse` server, skip
   this step and suggest reconnecting it instead.
4. **If `Rscript` is not on the PATH** (common on Windows), use the full
   path to Rscript. In R, `mirtverse::mv_mcp_config(NULL, client = "claude-code", mode = "analysis")`
   prints the exact command for the user's computer. Alternatively, set up
   one folder with `mirtverse::mv_agent_init("path/to/project")`, which
   writes a `.mcp.json` with the full path and a `CLAUDE.md` with the
   agent's instructions; then restart Claude Code in that folder and
   approve the server.
5. **Data and results.** The data files go in the project folder (the
   folder Claude Code was opened in). Results are written to
   `mirtverse-output/` there.

For Claude Desktop or other MCP clients,
`mirtverse::mv_mcp_config("path/to/project", client = "claude-desktop", mode = "analysis")`
prints the settings to paste.
