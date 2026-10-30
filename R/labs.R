#' Interactive IRT teaching labs
#'
#' mirtverse ships interactive [learnr](https://rstudio.github.io/learnr/)
#' tutorials for measurement courses. Students work through a realistic
#' testing scenario with live R exercises and make the decisions an analyst
#' would make, getting feedback on each one. The labs share one storyline: a
#' certification board's 32-item exam ([certexam]).
#'
#' * `"model-choice"` (Lab 1): score the responses, screen the items, check
#'   dimensionality, compare the Rasch, 2PL and 3PL models, check item fit and
#'   local dependence, and commit to a model the board can defend.
#' * `"decisions"` (Lab 2): read the item parameters, check precision at the
#'   pass mark, choose a scoring method, estimate classification accuracy,
#'   test for DIF between English and French candidates, write a memo, and
#'   compare the results with the truth behind the data.
#'
#' `run_lab()` opens a lab in the browser (or the RStudio Viewer). The labs
#' also appear in RStudio's Tutorial pane once mirtverse and learnr are
#' installed. Progress is saved in the browser, so students can stop and come
#' back later.
#'
#' @param name the lab to run; see `list_labs()`.
#' @param ... passed to [learnr::run_tutorial()], for example
#'   `shiny_args = list(launch.browser = FALSE)`.
#' @return `list_labs()` returns a data frame with one row per lab: `name`,
#'   `title` and `description`. `run_lab()` runs the lab and returns nothing
#'   useful.
#' @examples
#' list_labs()
#' if (interactive()) run_lab("model-choice")
#' @export
run_lab <- function(name = "model-choice", ...) {
  labs <- list_labs()
  if (!is.character(name) || length(name) != 1L || !name %in% labs$name)
    stop("Unknown lab \"", paste(name, collapse = ", "), "\". Available labs: ",
         paste(labs$name, collapse = ", "), ".", call. = FALSE)
  if (!requireNamespace("learnr", quietly = TRUE))
    stop("The labs need the learnr package. Install it with install.packages(\"learnr\").",
         call. = FALSE)
  learnr::run_tutorial(name, package = "mirtverse", ...)
}

#' @rdname run_lab
#' @export
list_labs <- function() {
  dir <- system.file("tutorials", package = "mirtverse")
  labs <- if (nzchar(dir)) list.dirs(dir, full.names = TRUE, recursive = FALSE) else character()
  rows <- lapply(labs, function(path) {
    rmd <- list.files(path, pattern = "\\.Rmd$", full.names = TRUE)[1]
    meta <- if (is.na(rmd)) list() else lab_meta(rmd)
    data.frame(name = basename(path), title = meta$title %||% basename(path),
               description = meta$description %||% "", stringsAsFactors = FALSE)
  })
  out <- if (length(rows)) do.call(rbind, rows) else
    data.frame(name = character(), title = character(), description = character())
  as_tbl(out)
}

#' Exercise checker for the mirtverse labs
#'
#' The checker the labs pass to [learnr::tutorial_options()]. It runs an
#' exercise's `-check` chunk in the environment the student's code produced.
#' Inside that chunk, `lab_need(condition, message)` fails the exercise with
#' `message` when `condition` is not `TRUE`, and `.result` holds the value of
#' the student's last expression. If every check passes, the exercise is
#' marked correct and the chunk's last value (when it is a string) is shown as
#' the feedback.
#'
#' @param label,user_code,solution_code,check_code,envir_result,evaluate_result,envir_prep,last_value,stage
#'   supplied by learnr.
#' @param ... ignored.
#' @return A list in the format learnr expects.
#' @keywords internal
#' @export
lab_checker <- function(label = NULL, user_code = NULL, solution_code = NULL,
                        check_code = NULL, envir_result = NULL, evaluate_result = NULL,
                        envir_prep = NULL, last_value = NULL, stage = NULL, ...) {
  # learnr may rebuild this function outside the package namespace, so it must
  # not call any unexported helper
  if (!identical(stage, "check") || is.null(check_code) ||
      !nzchar(paste(check_code, collapse = "")))
    return(NULL)
  env <- new.env(parent = if (is.null(envir_result)) globalenv() else envir_result)
  env$.result <- last_value
  env$lab_need <- function(condition, message) {
    if (!isTRUE(condition))
      stop(structure(class = c("lab_fail", "error", "condition"),
                     list(message = message, call = NULL)))
    invisible(TRUE)
  }
  out <- tryCatch(eval(parse(text = check_code), envir = env),
                  lab_fail = function(e) e,
                  error = function(e) structure(
                    list(message = paste("Something went wrong while checking your answer:",
                                         conditionMessage(e)), call = NULL),
                    class = c("lab_fail", "condition")))
  if (inherits(out, "lab_fail"))
    return(list(message = gsub("`", "", out$message), correct = FALSE, type = "error",
                location = "append"))
  msg <- if (is.character(out) && length(out) == 1L) gsub("`", "", out) else "Well done."
  list(message = msg, correct = TRUE, type = "success", location = "append")
}

# title and description from a tutorial's YAML header (single-line or folded)
lab_meta <- function(rmd) {
  lines <- readLines(rmd, warn = FALSE)
  bounds <- which(lines == "---")
  if (length(bounds) < 2L) return(list())
  yaml <- lines[(bounds[1] + 1L):(bounds[2] - 1L)]
  field <- function(key) {
    i <- grep(paste0("^", key, ":"), yaml)
    if (!length(i)) return(NULL)
    val <- trimws(sub(paste0("^", key, ":"), "", yaml[i[1]]))
    if (val %in% c(">", "|", ">-", "|-")) {
      rest <- yaml[-seq_len(i[1])]
      cont <- rest[seq_len(match(FALSE, grepl("^\\s", rest), nomatch = length(rest) + 1L) - 1L)]
      val <- paste(trimws(cont), collapse = " ")
    }
    gsub("^[\"']|[\"']$", "", val)
  }
  list(title = field("title"), description = field("description"))
}

`%||%` <- function(x, y) if (is.null(x)) y else x


#' Summarise a student's decisions in a lab
#'
#' Used at the end of each lab to list the answers a student gave to the
#' decision questions.
#'
#' @param state the tutorial state, from [learnr::get_tutorial_state()].
#' @param labels named character vector: question labels as names, short
#'   descriptions as values, in the order to show them.
#' @return A data frame with columns `Decision`, `Your answer` and `Verdict`.
#' @keywords internal
#' @export
lab_decisions <- function(state, labels) {
  rows <- lapply(names(labels), function(id) {
    s <- state[[id]]
    if (is.null(s) || is.null(s$answer))
      return(c(labels[[id]], "(not answered yet)", ""))
    ans <- gsub("[*`]", "", paste(unlist(s$answer), collapse = "; "))
    if (nchar(ans) > 140) ans <- paste0(substr(ans, 1, 137), "...")
    verdict <- if (isTRUE(s$correct)) "Defensible" else "Revisit"
    c(labels[[id]], ans, verdict)
  })
  out <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
  names(out) <- c("Decision", "Your answer", "Verdict")
  out
}

#' Answer key and true values for the lab dataset
#'
#' Instructor helper: returns how [certexam] was generated, so you can check
#' students' conclusions. Students meet the same information in the reveal at
#' the end of the labs.
#'
#' @return A list with the true `model`, the correct `key`, the `miskeyed`
#'   item, the `testlet` items, the `dif` items and their type, the group
#'   `impact` (mean ability difference in SD units), the generating item
#'   parameters `pars` and the pass mark `cut_raw`.
#' @examples
#' lab_truth()$dif
#' @export
lab_truth <- function() certexam_truth

#' Certification exam data for the teaching labs
#'
#' Simulated responses of 1,200 candidates to a fictional 32-item,
#' five-option certification exam taken in English or French. Item parameters
#' are based on a 3PL calibration of mirt's [mirt::SAT12] data, so the items
#' behave like real ones. Some problems were planted on purpose for the
#' [teaching labs][run_lab]; [lab_truth()] lists them.
#'
#' @format `certexam` is a data frame with 1,200 rows and 34 columns: `id`
#'   (candidate ID), `language` (factor, English or French) and `Q01` to `Q32`
#'   (the option chosen, A to E). `certexam_key` is a named character vector
#'   with the published answer key for `Q01` to `Q32`.
#' @source Simulated; the script is `data-raw/certexam.R` in the package's
#'   GitHub repository.
#' @examples
#' head(certexam[, 1:6])
#' scored <- key2binary(certexam[, -(1:2)], certexam_key)
#' @name certexam
"certexam"

#' @rdname certexam
"certexam_key"
