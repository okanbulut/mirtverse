# Starts the mirtverse analysis agent (an MCP server over stdio) for the
# folder Claude Code was opened in. The mirtverse plugin runs this file with
# Rscript; it needs R and the mirtverse package on the user's computer.

if (!requireNamespace("mirtverse", quietly = TRUE)) {
  message("[mirtverse plugin] The mirtverse R package is not installed. In R, run:\n",
          "  install.packages(\"remotes\")\n",
          "  remotes::install_github(\"okanbulut/mirtverse\")\n",
          "then restart Claude Code.")
  quit(save = "no", status = 1)
}

mirtverse::mv_agent_server()
