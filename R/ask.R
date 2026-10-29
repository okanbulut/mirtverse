#' Write an analysis script from a plan or a plain-language request
#'
#' `mv_ask()` writes a complete, commented R script for an IRT analysis. The
#' script is built from tested templates, so it only uses mirt and mirtverse
#' functions with checked arguments. Nothing is run until you call
#' [run_script()].
#'
#' @param request a plain-language description of the analysis, or an existing
#'   `mv_script` to refine.
#' @param data the data: a data frame, or the path of a `.csv`, `.xlsx`,
#'   `.sav`, `.dta`, `.sas7bdat` or `.rds` file. The script refers to a data
#'   frame by the name you pass, so pass a named object (e.g. `data = mydata`).
#' @param plan an [mv_plan()] to use instead of a request.
#' @return An object of class `mv_script` with elements `script` (the code as
#'   a character vector), `plan`, `profile` (see [profile_data()]), `request`
#'   and `data_name`. Printing it shows the plan, any assumptions and the code.
#' @seealso [run_script()], [save_script()], [mv_plan()].
#' @examples
#' scr <- mv_ask(data = Science,
#'               plan = mv_plan(model = "graded", steps = c("fitcheck", "plots")))
#' scr
#' \donttest{
#' res <- run_script(scr, echo = FALSE)
#' res$mod
#' }
#' @export
mv_ask <- function(request = NULL, data = NULL, plan = NULL) {
  prev <- NULL
  if (inherits(request, "mv_script")) {
    prev <- request
    request <- NULL
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

  if (is.null(plan)) {
    if (!is.null(prev)) plan <- prev$plan
    if (!is.null(request) || is.null(plan))
      stop("Plain-language requests are not available yet; describe the analysis with ",
           "`plan = mv_plan(...)`.", call. = FALSE)
  }
  if (!inherits(plan, "mv_plan")) stop("`plan` must be made with mv_plan().", call. = FALSE)
  plan$data <- data_name
  plan <- check_plan(plan, profile)
  if (length(plan$errors))
    stop("The plan cannot be run:\n", paste("*", plan$errors, collapse = "\n"), call. = FALSE)
  request <- if (!is.null(prev$request)) prev$request else request

  structure(list(script = render_script(plan, request), plan = plan, profile = profile,
                 request = request, data_name = data_name,
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
  if (!is.null(x$request)) cat("Request:", x$request, "\n\n")
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
