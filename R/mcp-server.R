#' MCP server for instructors
#'
#' `mv_mcp_server()` starts a [Model Context Protocol](https://modelcontextprotocol.io)
#' server that lets an AI assistant (Claude Desktop, Claude Code, OpenAI
#' Codex, ChatGPT, the OpenAI Agents SDK, or any other MCP client) work on
#' your mirtverse teaching materials. You describe what you want ("add a
#' question on local dependence to Lab 1", "use my own exam data in the
#' fairness lab", "turn my ltm lecture notes into mirtverse") and the
#' assistant does it with the server's tools: it reads and edits the files in
#' your course folder, copies and builds labs with the instructor toolkit,
#' looks up mirtverse functions so it does not invent any, translates older
#' ltm, eRm, TAM and irtQ code with [mirtify()], and runs the materials to
#' check that they still work.
#'
#' The server can only read and write files inside `course`. Every change is
#' backed up first (in `course/.mirtverse-mcp/backups`) and can be undone
#' with the `undo_last_change` tool.
#'
#' You normally do not call `mv_mcp_server()` yourself. Your AI client starts
#' it; [mv_mcp_config()] prints the settings to paste into the client.
#'
#' @param course path to the course folder the assistant may work in. It is
#'   created if it does not exist. Defaults to the working directory.
#' @param transport `"stdio"` (the default, for desktop and command-line
#'   clients that start the server themselves) or `"http"` (a Streamable
#'   HTTP endpoint, for clients such as ChatGPT that connect to a URL).
#' @param allow_run logical; may the assistant run R code (the
#'   `check_material` tool and running translated code)? Defaults to `TRUE`
#'   for `"stdio"` and `FALSE` for `"http"`.
#' @param host,port where the HTTP server listens.
#' @param token for `"http"`, a secret that becomes part of the URL
#'   (`http://host:port/mcp/<token>`), so only people who know the URL can
#'   reach the server. A random token is made if `NULL`; use `""` for none.
#' @param timeout seconds a check may run before it is stopped.
#' @return Runs until the client disconnects (stdio) or the R session is
#'   interrupted (http); returns `NULL` invisibly.
#' @seealso [mv_mcp_config()] for client setup, and the "AI assistant for
#'   instructors" article.
#' @examples
#' \dontrun{
#' # Usually started by the AI client, with a command such as
#' #   Rscript -e "mirtverse::mv_mcp_server('~/courses/edpy507')"
#' mv_mcp_server("~/courses/edpy507")
#'
#' # For ChatGPT: serve over HTTP, then expose the port with a tunnel
#' mv_mcp_server("~/courses/edpy507", transport = "http", port = 8765)
#' }
#' @export
mv_mcp_server <- function(course = ".", transport = c("stdio", "http"),
                          allow_run = NULL, host = "127.0.0.1", port = 8765,
                          token = NULL, timeout = 600) {
  transport <- match.arg(transport)
  if (is.null(allow_run)) allow_run <- identical(transport, "stdio")
  ctx <- mcp_context(course, allow_run = allow_run, timeout = timeout)
  if (identical(transport, "stdio")) mcp_serve_stdio(ctx) else
    mcp_serve_http(ctx, host = host, port = port, token = token)
  invisible(NULL)
}

#' Settings to connect an AI client to the instructor MCP server
#'
#' Prints the configuration that tells an AI client how to start
#' [mv_mcp_server()] for your course folder, with the full path to `Rscript`
#' filled in, and where the settings go.
#'
#' @param course path to the course folder.
#' @param client one of `"claude-desktop"`, `"claude-code"`, `"codex"`
#'   (OpenAI Codex CLI and IDE extension), `"openai-agents"` (OpenAI Agents
#'   SDK for Python) or `"chatgpt"` (ChatGPT developer mode, which connects
#'   over HTTP).
#' @param name the name the client shows for the server.
#' @return The configuration text, invisibly. It is also printed.
#' @examples
#' mv_mcp_config("~/courses/edpy507", client = "claude-desktop")
#' mv_mcp_config("~/courses/edpy507", client = "codex")
#' @export
mv_mcp_config <- function(course = ".", client = c("claude-desktop", "claude-code",
                                                   "codex", "openai-agents", "chatgpt"),
                          name = "mirtverse") {
  client <- match.arg(client)
  course <- normalizePath(path.expand(course), winslash = "/", mustWork = FALSE)
  rscript <- normalizePath(file.path(R.home("bin"), if (.Platform$OS.type == "windows")
    "Rscript.exe" else "Rscript"), winslash = "/", mustWork = FALSE)
  expr <- sprintf("mirtverse::mv_mcp_server('%s')", course)
  json_args <- jsonlite::toJSON(c("-e", expr), auto_unbox = FALSE)
  txt <- switch(client,
    "claude-desktop" = c(
      "# Claude Desktop: Settings > Developer > Edit Config opens",
      "# claude_desktop_config.json. Add this entry, save, and restart Claude.",
      jsonlite::prettify(sprintf('{"mcpServers": {"%s": {"command": "%s", "args": %s}}}',
                                 name, rscript, json_args), indent = 2)),
    "claude-code" = c(
      "# Claude Code: run this once in a terminal.",
      sprintf("claude mcp add %s -- \"%s\" -e \"%s\"", name, rscript, expr)),
    "codex" = c(
      "# OpenAI Codex (CLI and IDE extension): add to ~/.codex/config.toml",
      sprintf("[mcp_servers.%s]", name),
      sprintf("command = \"%s\"", rscript),
      sprintf("args = %s", json_args),
      "startup_timeout_sec = 30",
      "tool_timeout_sec = 900"),
    "openai-agents" = c(
      "# OpenAI Agents SDK (Python)",
      "from agents import Agent, Runner",
      "from agents.mcp import MCPServerStdio",
      "",
      sprintf("server = MCPServerStdio(name=\"%s\", params={", name),
      sprintf("    \"command\": \"%s\",", rscript),
      sprintf("    \"args\": %s,", json_args),
      "}, client_session_timeout_seconds=900)",
      "",
      "async with server:",
      "    agent = Agent(name=\"Course assistant\", mcp_servers=[server],",
      "                  instructions=\"Help me revise my mirtverse teaching materials.\")",
      "    result = await Runner.run(agent, \"Add a local dependence question to Lab 1.\")"),
    "chatgpt" = c(
      "# ChatGPT connects to a URL, so run the server over HTTP and expose it",
      "# with a tunnel (for example `ngrok http 8765` or `cloudflared tunnel",
      "# --url http://localhost:8765`). In R:",
      sprintf("mirtverse::mv_mcp_server('%s', transport = \"http\", port = 8765)", course),
      "# The server prints its URL, http://127.0.0.1:8765/mcp/<token>. In ChatGPT,",
      "# turn on Settings > Apps & Connectors > Advanced > Developer mode, create",
      "# a connector, and paste the tunnel address followed by /mcp/<token>, with",
      "# no authentication. Code checks are off over HTTP unless you start the",
      "# server with allow_run = TRUE."))
  txt <- paste(txt, collapse = "\n")
  cat(txt, "\n", sep = "")
  invisible(txt)
}

# ---------------------------------------------------------------------------
# Protocol

mcp_protocol_versions <- c("2025-11-25", "2025-06-18", "2025-03-26", "2024-11-05")

mcp_context <- function(course, allow_run = TRUE, timeout = 600) {
  course <- path.expand(course)
  if (!dir.exists(course)) dir.create(course, recursive = TRUE)
  ctx <- new.env(parent = emptyenv())
  ctx$root <- normalizePath(course, winslash = "/", mustWork = TRUE)
  ctx$allow_run <- isTRUE(allow_run)
  ctx$timeout <- timeout
  ctx
}

mcp_server_instructions <- function() {
  paste(
    "This server edits an instructor's mirtverse teaching materials (R package for",
    "item response theory built on mirt): learnr labs, book chapters, lecture notes",
    "and datasets in one course folder. Start with course_overview. Read a material",
    "before changing it, prefer the lab_* and toolkit tools for lab structure and",
    "edit_material for small text changes, look functions up with mirtverse_help",
    "instead of guessing, and run check_material after every change. Read the",
    "guide tool's 'lab-style' and 'adapting' topics before writing labs or",
    "converting existing materials. Tell the instructor what you changed; every",
    "change can be undone with undo_last_change.")
}

# Handle one decoded JSON-RPC message; returns the response (a list) or NULL
# for notifications.
mcp_dispatch <- function(msg, ctx) {
  id <- msg$id
  method <- msg$method %||% ""
  params <- msg$params %||% list()
  is_notification <- is.null(id)
  if (!is.character(method) || !nzchar(method)) {
    if (is_notification) return(NULL)
    return(mcp_error(id, -32600, "Invalid request"))
  }
  result <- tryCatch(switch(method,
    "initialize" = mcp_initialize(params),
    "ping" = structure(list(), names = character()),
    "tools/list" = list(tools = mcp_tool_list(ctx)),
    "tools/call" = mcp_call_tool(params, ctx),
    "prompts/list" = list(prompts = mcp_prompt_list()),
    "prompts/get" = mcp_get_prompt(params),
    "resources/list" = list(resources = mcp_resource_list()),
    "resources/templates/list" = list(resourceTemplates = list()),
    "resources/read" = mcp_read_resource(params),
    "logging/setLevel" = structure(list(), names = character()),
    if (startsWith(method, "notifications/")) NULL else
      structure(list(code = -32601, message = paste("Method not found:", method)),
                class = "mcp_rpc_error")),
    error = function(e) structure(
      list(code = if (inherits(e, "mcp_rpc_condition")) e$code else -32603,
           message = conditionMessage(e)),
      class = "mcp_rpc_error"))
  if (is_notification) return(NULL)
  if (inherits(result, "mcp_rpc_error"))
    return(mcp_error(id, result$code, result$message))
  list(jsonrpc = "2.0", id = id, result = result)
}

mcp_error <- function(id, code, message) {
  list(jsonrpc = "2.0", id = id, error = list(code = code, message = message))
}

mcp_initialize <- function(params) {
  asked <- params$protocolVersion %||% mcp_protocol_versions[1]
  version <- if (asked %in% mcp_protocol_versions) asked else mcp_protocol_versions[1]
  list(protocolVersion = version,
       capabilities = list(tools = list(listChanged = FALSE),
                           prompts = list(listChanged = FALSE),
                           resources = list(listChanged = FALSE),
                           logging = structure(list(), names = character())),
       serverInfo = list(name = "mirtverse",
                         title = "mirtverse instructor assistant",
                         version = as.character(utils::packageVersion("mirtverse"))),
       instructions = mcp_server_instructions())
}

mcp_handle_text <- function(line, ctx) {
  msg <- tryCatch(jsonlite::fromJSON(line, simplifyVector = FALSE),
                  error = function(e) NULL)
  if (is.null(msg)) return(mcp_error(NULL, -32700, "Parse error"))
  if (is.null(names(msg)) && length(msg)) {
    out <- Filter(Negate(is.null), lapply(msg, mcp_dispatch, ctx = ctx))
    return(if (length(out)) out else NULL)
  }
  mcp_dispatch(msg, ctx)
}

mcp_to_json <- function(x) {
  as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", na = "null",
                                digits = NA, force = TRUE))
}

mcp_log <- function(...) {
  cat("[mirtverse-mcp] ", ..., "\n", sep = "", file = stderr())
}

# ---------------------------------------------------------------------------
# Transports

mcp_serve_stdio <- function(ctx, input = NULL, output = stdout()) {
  if (is.null(input)) {
    input <- file("stdin", open = "r")
    on.exit(close(input), add = TRUE)
  }
  mcp_log("serving ", ctx$root, " over stdio")
  repeat {
    line <- readLines(input, n = 1L, warn = FALSE, encoding = "UTF-8")
    if (!length(line)) break
    if (!nzchar(trimws(line))) next
    # anything printed while handling the message must not reach the
    # protocol stream, so it goes to stderr
    printed <- utils::capture.output(resp <- mcp_handle_text(line, ctx), type = "output")
    if (length(printed)) mcp_log(paste(printed, collapse = "\n"))
    if (!is.null(resp)) {
      cat(enc2utf8(mcp_to_json(resp)), "\n", sep = "", file = output)
      flush(output)
    }
  }
  invisible(NULL)
}

mcp_serve_http <- function(ctx, host = "127.0.0.1", port = 8765, token = NULL) {
  if (is.null(token))
    token <- paste(sample(c(letters, 0:9), 24, replace = TRUE), collapse = "")
  path <- if (nzchar(token)) paste0("/mcp/", token) else "/mcp"
  if (!requireNamespace("httpuv", quietly = TRUE))
    stop("The HTTP transport needs the httpuv package: install.packages(\"httpuv\").",
         call. = FALSE)
  app <- list(call = function(req) mcp_http_call(req, ctx, path))
  url <- sprintf("http://%s:%s%s", host, port, path)
  message("mirtverse MCP server for ", ctx$root, "\nURL: ", url,
          if (!ctx$allow_run) "\nCode checks are off (allow_run = FALSE).",
          "\nPress Esc or Ctrl+C to stop.")
  httpuv::runServer(host, port, app)
  invisible(NULL)
}

mcp_http_call <- function(req, ctx, path) {
  headers <- list("Content-Type" = "application/json",
                  "Access-Control-Allow-Origin" = "*",
                  "Access-Control-Allow-Headers" = "*",
                  "Access-Control-Allow-Methods" = "POST, DELETE, OPTIONS")
  reply <- function(status, body = "") list(status = status, headers = headers, body = body)
  if (!identical(sub("/$", "", req$PATH_INFO), path)) return(reply(404L, '{"error":"not found"}'))
  if (identical(req$REQUEST_METHOD, "OPTIONS")) return(reply(204L))
  # sessions are not tracked, so ending one is a no-op
  if (identical(req$REQUEST_METHOD, "DELETE")) return(reply(200L))
  if (!identical(req$REQUEST_METHOD, "POST")) return(reply(405L, '{"error":"use POST"}'))
  body <- rawToChar(req$rook.input$read())
  Encoding(body) <- "UTF-8"
  resp <- utils::capture.output(out <- mcp_handle_text(body, ctx), type = "output")
  if (length(resp)) mcp_log(paste(resp, collapse = "\n"))
  if (is.null(out)) return(reply(202L))
  reply(200L, enc2utf8(mcp_to_json(out)))
}
