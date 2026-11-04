---
name: setup
description: Set up or troubleshoot the mirtverse agent - check that R and the mirtverse package are installed and that the mirtverse MCP server starts. Use when the mirtverse tools are missing, the server fails to start, or the user asks how to get started with the mirtverse agent.
---

# Set up the mirtverse agent

The plugin starts `Rscript -e "mirtverse::mv_agent_server()"` in the
folder Claude Code was opened in. It needs R (4.1 or later) on the PATH and
the mirtverse package.

1. Check R: Run `Rscript --version`. If it is missing, tell the user to
   install R from https://cran.r-project.org (and, on Windows, see step 4).
2. Check the package: Run
   `Rscript -e "packageVersion('mirtverse')"`. If it is missing, install it
   (ask first, it takes a few minutes):
   `Rscript -e "install.packages('remotes', repos = 'https://cloud.r-project.org'); remotes::install_github('okanbulut/mirtverse')"`
3. Check the server: Run
   `Rscript -e "mirtverse:::agent_project()"` from the project folder; it
   should print the folder. Then ask the user to run `/mcp` in Claude Code
   and reconnect the `mirtverse` server (or restart Claude Code).
4. If `Rscript` is not on the PATH (common on Windows), set the folder up
   without the plugin's server: In R, run
   `mirtverse::mv_agent_init("path/to/project")`. It writes a `.mcp.json`
   with the full path to Rscript and a `CLAUDE.md` with the agent's
   instructions. Restart Claude Code in that folder and approve the server.
5. The data files go in the project folder (the folder Claude Code was
   started in). Results are written to `mirtverse-output/` there.

For Claude Desktop or other MCP clients, `mirtverse::mv_mcp_config("path/to/project", client = "claude-desktop", mode = "analysis")`
prints the settings to paste.
