#' Run the mirtverse analysis agent server
#'
#' `mv_agent_server()` starts a [Model Context Protocol](https://modelcontextprotocol.io)
#' (MCP) server that lets an AI assistant such as Claude run item response
#' theory analyses on the data in one project folder. The assistant reads
#' your data, fits and compares models, checks items, tests for differential
#' item functioning, scores people, draws plots, explains the results and
#' writes an HTML report, all with mirtverse. Every step is also written as
#' R code, so `save_script` leaves a script that reproduces the analysis.
#'
#' Fitted models live in the R session of the server and are saved in the
#' project's `.mirtverse-mcp/models` folder, so they survive a restart.
#' Files the server writes (plots, scores, reports, scripts) go to the
#' `mirtverse-output` folder of the project. Your data files are only read,
#' never changed.
#'
#' You normally do not call `mv_agent_server()` yourself. The mirtverse
#' plugin for Claude Code starts it in the folder you work in; for other
#' clients, [mv_mcp_config()] with `mode = "analysis"` prints the settings,
#' and [mv_agent_init()] sets up a folder for Claude Code without the plugin.
#'
#' @param project path to the project folder that holds the data. By default
#'   the `MIRTVERSE_PROJECT` environment variable when it is set (the
#'   `.mcp.json` written by [mv_agent_init()] sets it), otherwise the working
#'   directory, which for the plugin is the folder Claude Code was opened in.
#' @param transport `"stdio"` (the client starts the server) or `"http"`
#'   (a URL the client connects to).
#' @param allow_run logical; allow the `run_r` tool, which runs R code the
#'   assistant writes. Defaults to `TRUE` for stdio and `FALSE` for HTTP.
#' @param host,port,token where the HTTP server listens; see
#'   [mv_mcp_server()].
#' @param timeout seconds a single `run_r` call may take.
#' @return Called for its side effect; returns `NULL` when the client
#'   disconnects.
#' @seealso [mv_agent_init()], [mv_mcp_config()], and the "mirtverse agent
#'   for Claude" article on the website.
#' @examples
#' \dontrun{
#' # The plugin runs a script that calls mv_agent_server() in the folder
#' # Claude Code was opened in. By hand:
#' mv_agent_server("~/projects/math-test")
#' }
#' @export
mv_agent_server <- function(project = NULL, transport = c("stdio", "http"),
                            allow_run = NULL, host = "127.0.0.1", port = 8766,
                            token = NULL, timeout = 600) {
  transport <- match.arg(transport)
  if (is.null(allow_run)) allow_run <- identical(transport, "stdio")
  ctx <- mcp_context(agent_project(project), allow_run = allow_run, timeout = timeout,
                     mode = "analysis")
  if (identical(transport, "stdio")) mcp_serve_stdio(ctx) else
    mcp_serve_http(ctx, host = host, port = port, token = token)
  invisible(NULL)
}

# The project folder: the argument, then MIRTVERSE_PROJECT (unless the client
# left the ${...} placeholder unexpanded), then the working directory.
agent_project <- function(project = NULL) {
  if (!is.null(project) && nzchar(project)) return(project)
  env <- Sys.getenv("MIRTVERSE_PROJECT", "")
  if (nzchar(env) && !grepl("${", env, fixed = TRUE)) return(env)
  getwd()
}

#' Set up a folder for the mirtverse agent in Claude Code
#'
#' Writes the files that turn a folder into a mirtverse analysis project for
#' Claude Code, for people who do not install the mirtverse plugin: A
#' `CLAUDE.md` that tells Claude how to work (which tools to use, which
#' checks to run, how to explain results) and a `.mcp.json` that starts
#' [mv_agent_server()] in the folder. Open the folder in Claude Code
#' afterwards and approve the `mirtverse` server when Claude asks.
#'
#' The `CLAUDE.md` is plain text, so edit it to add what Claude should know
#' about your project, such as what the test measures, who took it, and how
#' results should be reported.
#'
#' @param path the project folder. It is created if needed.
#' @param title optional project title, written at the top of `CLAUDE.md`.
#' @param overwrite logical; replace existing files. Without it, existing
#'   files are left alone and reported.
#' @return The paths of the files written, invisibly.
#' @seealso [mv_agent_server()]
#' @examples
#' dir <- file.path(tempdir(), "math-test")
#' mv_agent_init(dir, title = "Grade 8 math test, spring 2026")
#' list.files(dir, all.files = TRUE, no.. = TRUE)
#' @export
mv_agent_init <- function(path = ".", title = NULL, overwrite = FALSE) {
  path <- path.expand(path)
  if (!dir.exists(path)) dir.create(path, recursive = TRUE)
  root <- normalizePath(path, winslash = "/", mustWork = TRUE)
  tmpl <- system.file("agent", "CLAUDE.md", package = "mirtverse")
  if (!nzchar(tmpl)) stop("The CLAUDE.md template is missing from the mirtverse installation.",
                          call. = FALSE)
  claude <- read_lines_utf8(tmpl)
  if (!is.null(title) && nzchar(title)) claude[1] <- paste("#", title)
  rscript <- normalizePath(file.path(R.home("bin"), if (.Platform$OS.type == "windows")
    "Rscript.exe" else "Rscript"), winslash = "/", mustWork = FALSE)
  mcp <- list(mcpServers = list(mirtverse = list(
    command = rscript, args = list("-e", "mirtverse::mv_agent_server()"),
    env = list(MIRTVERSE_PROJECT = root))))
  files <- list("CLAUDE.md" = claude,
                ".mcp.json" = as.character(jsonlite::toJSON(mcp, auto_unbox = TRUE, pretty = TRUE)))
  written <- character()
  for (f in names(files)) {
    dest <- file.path(root, f)
    if (file.exists(dest) && !overwrite) {
      message(f, " already exists; left as it is (use overwrite = TRUE to replace it).")
      next
    }
    write_lines_utf8(files[[f]], dest)
    written <- c(written, dest)
  }
  dir.create(file.path(root, agent_output_dir), showWarnings = FALSE)
  if (length(written))
    message("Wrote ", paste(basename(written), collapse = " and "), " in ", root, ".\n",
            "Put your data files in the folder, open it in Claude Code (`claude` in a terminal),\n",
            "approve the mirtverse server, and ask, for example: \"Analyze exam.csv\".")
  invisible(written)
}

agent_output_dir <- "mirtverse-output"

agent_init_context <- function(ctx) {
  ctx$models <- new.env(parent = emptyenv())
  ctx$session <- new.env(parent = globalenv())
  ctx$script <- character()
  invisible(ctx)
}

agent_server_instructions <- function() {
  paste(
    "This server runs item response theory analyses with mirtverse (an R package",
    "built on mirt) on the data in one project folder. Start with project_overview,",
    "then describe_dataset to find the item, group and ID columns, and confirm",
    "them with the user when unsure. Read guide('analysis') once before the first",
    "analysis and guide('interpreting') before explaining results. Typical order:",
    "fit_model (model = 'auto' compares models), check_items, check_dif when a group",
    "variable exists, score_people, plot_model, interpret_model, write_report.",
    "Look functions up with mirtverse_help instead of guessing; use run_r only for",
    "what the other tools do not cover. Explain results in plain language for",
    "someone who does not know R, give the numbers that support each claim, and",
    "finish with save_script so the user has R code that reproduces the analysis.",
    "Files go to the mirtverse-output folder; data files are never changed.")
}

agent_guide_topics <- c(analysis = "How to run an IRT analysis with the analysis tools",
                        interpreting = "Rules of thumb for judging and explaining results")

agent_prompts <- function() {
  opt <- function(x, pre) if (!is.null(x) && nzchar(x)) paste0(pre, x) else ""
  list(
    list(name = "analyze_test", title = "Analyze my test",
         description = "Calibrate a test from a data file: choose a model, check the items, score people and explain the results.",
         arguments = list(
           list(name = "data", description = "The data file (relative to the project folder) or a dataset name.", required = TRUE),
           list(name = "context", description = "Optional: What the test measures, who took it, and what you need from the analysis.", required = FALSE)),
         text = function(a) paste0(
           "Analyze my test data `", a$data, "` with mirtverse.", opt(a$context, "\n\nContext: "), "\n\n",
           "Please: (1) call guide('analysis'); (2) describe_dataset and tell me which columns you take as items, groups and IDs; ",
           "(3) fit_model with model = 'auto' and explain the choice; (4) check_items and say which items need attention and why; ",
           "(5) if there is a group variable, check_dif; (6) score_people; (7) show the key plots; ",
           "(8) explain the results in plain language (guide('interpreting')); (9) write_report and save_script, and tell me where both are.")),
    list(name = "check_fairness", title = "Check items for fairness (DIF)",
         description = "Test whether items work differently for groups of test takers, and explain what to do about flagged items.",
         arguments = list(
           list(name = "data", description = "The data file or dataset name.", required = TRUE),
           list(name = "group", description = "The grouping column, e.g. gender or language.", required = TRUE)),
         text = function(a) paste0(
           "Check the items in `", a$data, "` for differential item functioning across `", a$group, "`.\n\n",
           "Please: (1) call guide('analysis'); (2) describe_dataset and check that the groups are large enough; ",
           "(3) fit_model; (4) check_dif with group = '", a$group, "'; (5) plot_model with type = 'dif' for flagged items; ",
           "(6) explain each flagged item's direction and size, separate statistical from practical importance, ",
           "and say what a content review should look at; (7) save_script.")),
    list(name = "write_report", title = "Write a technical report",
         description = "Turn a fitted model into an HTML technical report with a plain-language summary.",
         arguments = list(
           list(name = "model", description = "Optional: The model name (see project_overview).", required = FALSE),
           list(name = "audience", description = "Optional: Who will read it, e.g. 'school board' or 'psychometric reviewers'.", required = FALSE)),
         text = function(a) paste0(
           "Write a report on ", if (!is.null(a$model) && nzchar(a$model)) paste0("model `", a$model, "`") else "my analysis",
           opt(a$audience, " for this audience: "), ".\n\n",
           "Please: (1) project_overview; (2) interpret_model and check_items so you know the findings; ",
           "(3) write_report; (4) write a short plain-language summary for the audience, with the numbers behind each claim; ",
           "(5) save_script, and tell me where the report and script are.")))
}
