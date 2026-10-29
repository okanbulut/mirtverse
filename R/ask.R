#' Write an analysis script from a plain-language request
#'
#' Describe the analysis in your own words, for example "fit a 2PL, check DIF
#' by gender and make a report", and `mv_ask()` writes a complete, commented R
#' script for it. The request is turned into an analysis plan (see
#' [mv_plan()]), checked against your data, and the script is built from
#' tested templates, so it only uses mirt and mirtverse functions with checked
#' arguments. Nothing is run until you call [run_script()].
#'
#' Requests are understood by an AI model set up with [mv_ask_setup()]
#' (Claude, OpenAI GPT or a local Ollama model), or, when none is set up, by a
#' built-in keyword parser that works offline and asks follow-up questions in
#' the console when something is unclear. The AI model only sees your request
#' and a summary of the columns ([profile_data()]); never individual
#' responses. Use `dry_run = TRUE` to see exactly what would be sent.
#'
#' @param request a plain-language description of the analysis. To change an
#'   earlier script, pass it first: `mv_ask(scr, "use a 3PL instead")`.
#' @param data the data: a data frame, or the path of a `.csv`, `.xlsx`,
#'   `.sav`, `.dta`, `.sas7bdat` or `.rds` file. The script refers to a data
#'   frame by the name you pass, so pass a named object (e.g. `data = mydata`).
#' @param plan an [mv_plan()] to use instead of a request.
#' @param provider `"claude"`, `"openai"`, `"ollama"` or `"none"` (keyword
#'   parser). Defaults to the provider chosen with [mv_ask_setup()], then to
#'   whichever API key is available, then to `"none"`.
#' @param model the AI model name; see [mv_ask_setup()].
#' @param anonymize logical; replace column names with V1, V2, ... (and drop
#'   category labels) before anything is sent to the AI model. The names are
#'   restored locally.
#' @param dry_run logical; print exactly what would be sent to the AI model and
#'   return it, without sending anything or writing a script.
#' @param ask logical; ask follow-up questions in the console when the keyword
#'   parser needs more information. If `FALSE` the questions are reported as an
#'   error instead.
#' @param ... unused; there to catch a mistyped argument such as `plan`.
#' @return An object of class `mv_script` with elements `script` (the code as
#'   a character vector), `plan`, `profile` (see [profile_data()]),
#'   `request`, `data_name` and `parser` (what understood the request).
#'   Printing it shows the plan, any assumptions and the code. With
#'   `dry_run = TRUE`, the text that would be sent, invisibly.
#' @seealso [run_script()], [save_script()], [mv_plan()], [mv_ask_setup()].
#' @examples
#' scr <- mv_ask("fit a graded response model, plot the curves and summarise",
#'               data = Science, provider = "none")
#' scr
#' scr <- mv_ask(scr, "also make a report")
#' mv_ask("check DIF by gender", data = Science, dry_run = TRUE)
#' \donttest{
#' res <- run_script(scr, echo = FALSE)
#' res$mod
#' }
#' @export
mv_ask <- function(request = NULL, data = NULL, plan = NULL, provider = NULL, model = NULL,
                   anonymize = FALSE, dry_run = FALSE, ask = interactive(), ...) {
  if (...length()) stop("Unknown argument(s) passed to mv_ask().", call. = FALSE)
  prev <- NULL
  if (inherits(request, "mv_script")) {
    prev <- request
    request <- if (inherits(data, "character") && !is_file_path(data) && length(data) == 1L) {
      r <- data
      data <- NULL
      r
    } else NULL
  }
  if (is.null(data) && !is.null(prev)) {
    data_name <- prev$data_name
    data <- prev$data
  } else {
    if (is.null(data)) stop("`data` is required.", call. = FALSE)
    data_name <- if (is.character(data) && length(data) == 1L) data else
      paste(deparse(substitute(data)), collapse = "")
  }
  df <- load_data(data)
  profile <- profile_data(df)
  parser <- if (!is.null(prev)) prev$parser else "a hand-written plan"
  questions <- character()

  if (is.null(plan)) {
    if (is.null(request)) {
      if (is.null(prev)) stop("Describe the analysis in `request`, or give a `plan`.", call. = FALSE)
      plan <- prev$plan
    } else {
      prov <- ask_provider(provider)
      if (dry_run) {
        payload <- ask_payload(request, profile, prev$plan, anonymize)
        cat(if (prov == "rules") "No AI model is set up, so nothing would be sent; an AI model would receive:\n\n"
            else sprintf("This would be sent to %s:\n\n", provider_label(prov, ask_model(prov, model))))
        cat(payload, "\n")
        return(invisible(as.character(payload)))
      }
      plan <- NULL
      if (prov != "rules") {
        mdl <- ask_model(prov, model)
        plan <- tryCatch(llm_plan(request, profile, prov, mdl, prev$plan, anonymize),
                         error = function(e) {
                           message(sprintf("%s could not be reached (%s); using the built-in keyword parser.",
                                           provider_label(prov, mdl), conditionMessage(e)))
                           NULL
                         })
        if (!is.null(plan)) {
          parser <- provider_label(prov, mdl)
          questions <- attr(plan, "questions")
        }
      }
      if (is.null(plan)) {
        parsed <- resolve_questions(parse_request_rules(request, profile, prev$plan), ask)
        plan <- plan_from_fields(parsed, prev$plan)
        parser <- provider_label("rules")
      }
    }
  }
  if (!inherits(plan, "mv_plan")) stop("`plan` must be made with mv_plan().", call. = FALSE)
  plan$data <- data_name
  plan <- check_plan(plan, profile)
  if (length(plan$errors))
    stop("The plan cannot be run:\n", paste("*", c(plan$errors, questions), collapse = "\n"),
         call. = FALSE)
  if (length(questions))
    plan$notes <- c(plan$notes, paste("The AI model was unsure about:", questions))
  request <- if (!is.null(prev$request) && !is.null(request)) paste(prev$request, "Then:", request) else
    request %||% prev$request

  structure(list(script = render_script(plan, request), plan = plan, profile = profile,
                 request = request, data_name = data_name, parser = parser,
                 data = if (is.data.frame(data) || is.matrix(data)) df else data),
            class = "mv_script")
}

load_data <- function(data) {
  if (is.character(data) && length(data) == 1L) {
    if (!file.exists(data)) stop(sprintf("File \"%s\" not found.", data), call. = FALSE)
    return(read_any(data, data))
  }
  if (!is.data.frame(data) && !is.matrix(data))
    stop("`data` must be a data frame or the path of a data file.", call. = FALSE)
  as.data.frame(data)
}

#' @method print mv_script
#' @export
print.mv_script <- function(x, ...) {
  if (!is.null(x$request))
    cat(paste(strwrap(paste("Request:", x$request), 78), collapse = "\n"),
        sprintf("\nUnderstood by %s\n\n", x$parser))
  print(x$plan)
  if (length(x$plan$notes)) {
    cat("Notes\n")
    for (s in x$plan$notes) cat(paste(strwrap(s, 76, initial = "  - ", exdent = 4), collapse = "\n"), "\n")
  }
  cat("\nR script (run it with run_script(), save it with save_script())\n")
  cat(strrep("-", 64), "\n", sep = "")
  cat(x$script, sep = "\n")
  invisible(x)
}

#' @method as.character mv_script
#' @export
as.character.mv_script <- function(x, ...) x$script

#' Run or save a script written by mv_ask()
#'
#' `run_script()` runs the script in a fresh environment and returns the
#' objects it created (for example `mod`, `sel`, `dif_res`, `scores`).
#' With `check = TRUE` it first runs the whole script on simulated data with
#' the same structure as yours (same items, categories and groups) in a
#' temporary folder, so errors show up before your data are touched.
#' `save_script()` writes the script to a `.R` file.
#'
#' @param x an `mv_script` from [mv_ask()].
#' @param check logical; do a dry run on simulated data first.
#' @param echo logical; print each line and its output as it runs.
#' @return `run_script()`: a named list of the objects the script created,
#'   invisibly. `save_script()`: the file path, invisibly.
#' @examples
#' scr <- mv_ask(data = Science, plan = mv_plan(model = "graded", steps = "fitcheck"))
#' f <- save_script(scr, tempfile(fileext = ".R"))
#' \donttest{
#' res <- run_script(scr, echo = FALSE)
#' }
#' @export
run_script <- function(x, check = FALSE, echo = interactive()) {
  if (!inherits(x, "mv_script")) stop("`x` must be made with mv_ask().", call. = FALSE)
  if (check) {
    sim <- simulate_like(load_data(x$data), x$plan)
    dir <- tempfile("mv_check")
    dir.create(dir)
    op <- options(mirtverse.dry_run = TRUE)
    on.exit(options(op), add = TRUE)
    res <- tryCatch(eval_script(x$script, sim, dir, echo = FALSE),
                    error = function(e) e)
    if (inherits(res, "error"))
      stop("The dry run on simulated data failed, so the script was not run on your data:\n",
           conditionMessage(res), call. = FALSE)
    options(op)
    message("Dry run on simulated data succeeded; running on your data.")
  }
  invisible(eval_script(x$script, load_data(x$data), getwd(), echo = echo))
}

#' @rdname run_script
#' @param file path of the `.R` file to write.
#' @param open logical; open the file in the RStudio or Positron editor (needs
#'   the rstudioapi package).
#' @export
save_script <- function(x, file = "analysis.R", open = FALSE) {
  if (!inherits(x, "mv_script")) stop("`x` must be made with mv_ask().", call. = FALSE)
  writeLines(x$script, file)
  if (open && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
    rstudioapi::navigateToFile(file)
  invisible(file)
}

# Evaluate script lines in a fresh environment. The line that loads the data
# is swapped for the data frame passed in, so a dry run never reads the real
# data. Files the script writes go to `dir`.
eval_script <- function(script, data, dir, echo = TRUE) {
  env <- new.env(parent = globalenv())
  assign(".mv_data", as.data.frame(data), envir = env)
  script[grep("^raw <- ", script)[1]] <- "raw <- .mv_data"
  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)
  exprs <- parse(text = script, keep.source = FALSE)
  for (e in exprs) {
    if (echo) {
      cat(paste(">", deparse(e), collapse = "\n"), "\n", sep = "")
      out <- withVisible(eval(e, env))
      if (out$visible) print(out$value)
    } else {
      suppressMessages(suppressWarnings(eval(e, env)))
    }
  }
  mget(ls(env), envir = env)
}

# Data with the same columns, item categories and groups as `df`, drawn from
# a one-factor model so that IRT models can be fitted to it
simulate_like <- function(df, plan, n = max(500, min(nrow(df), 2000))) {
  set.seed(20261028)
  out <- df[sample.int(nrow(df), n, replace = TRUE), , drop = FALSE]
  rownames(out) <- NULL
  items <- if (length(plan$key)) character() else plan$items
  theta <- stats::rnorm(n)
  for (it in items) {
    vals <- sort(unique(stats::na.omit(df[[it]])))
    vals <- vals[!vals %in% plan$missing]
    K <- length(vals)
    cuts <- sort(stats::rnorm(K - 1, 0, 0.8))
    z <- 1.2 * theta + stats::rlogis(n)
    out[[it]] <- vals[findInterval(z, cuts) + 1]
  }
  if (length(plan$rt))
    for (r in plan$rt) out[[r]] <- stats::rlnorm(n, log(max(stats::median(df[[r]], na.rm = TRUE), 1)), 0.5)
  out
}
