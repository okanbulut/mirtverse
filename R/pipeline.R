#' Start an assessment pipeline
#'
#' An assessment pipeline takes a test from response data to a score report in
#' stages. Each stage does its work, then runs a set of checks (a *gate*) and
#' records what it finds as *flags* that the user should consider before the
#' next stage. The stages available so far (numbered as in the pipeline
#' plan; start at any of them):
#'
#' 0. [set_blueprint()]: the construct, content cells and score use.
#' 1. [generate_items()] or [add_items()]: item writing with a language model
#'    or by people (keys, distractors, rubrics, duplicates, coverage).
#' 4. [add_responses()]: data intake and cleaning (scoring with a key,
#'    missing data, miskeyed items, straight-lining, rapid guessing, sparse
#'    categories).
#' 5. [calibrate()]: model fitting with mirt (convergence, model fit, local
#'    dependence, item fit, parameter ranges, DIF, reliability, person fit).
#' 6. [link_to_bank()] and [bank_items()] (optional): put the calibration on
#'    the scale of an item bank through anchor items and add the new items to
#'    the bank (anchor drift, linking constants).
#' 7. [assemble_forms()], [simulate_cat()] or [assemble_mst()]: fixed forms,
#'    adaptive or multistage tests (blueprint, parallelism, precision,
#'    exposure, routing).
#' 8. [set_cuts()]: cut scores and classification accuracy and consistency.
#' 11. [pipeline_report()]: an HTML technical report that also lists every
#'    flag and every decision made about it.
#'
#' Flags have three levels. `info` flags are shown for awareness. `review`
#' flags point at something a psychometrician should look at. `block` flags
#' point at problems that make later stages unsafe, such as a model that did
#' not converge or an item with large DIF.
#'
#' By default flags only warn: every stage runs, and a warning lists the open
#' flags it is moving past. With `strict = TRUE`, a stage refuses to run while
#' an earlier stage has open `review` flags (record a decision with
#' [acknowledge()]) or open `block` flags (fix the problem, for example with
#' [drop_items()], or record a reason with [override()]). Every decision is
#' logged with its time and note and printed in the report.
#'
#' @param title a name for the pipeline, used as the report title.
#' @param rules thresholds for the checks, from [mv_rules()].
#' @param strict logical; if `TRUE`, open `review` and `block` flags stop the
#'   next stage until a decision is recorded.
#' @param verbose logical; print a summary of each stage's flags.
#' @return An object of class `mv_pipeline`. Use [flags()] to list its flags
#'   and [tidy()] to get all of them as a tibble.
#' @seealso [mv_rules()], [flags()], [acknowledge()], [override()],
#'   [drop_items()]
#' @examples
#' \donttest{
#' p <- mv_pipeline("Certification exam")
#' p <- add_responses(p, certexam, items = 3:34, key = certexam_key,
#'                    id = "id", group = "language")
#' flags(p)
#' p <- drop_items(p, "Q14", note = "Miskeyed; confirmed with the item writer")
#' p <- calibrate(p, model = "3PL")
#' p
#' f <- pipeline_report(p, file = tempfile(fileext = ".html"))
#' }
#' @export
mv_pipeline <- function(title = "Assessment pipeline", rules = mv_rules(), strict = FALSE,
                        verbose = interactive()) {
  if (!inherits(rules, "mv_rules"))
    stop("`rules` must come from mv_rules().", call. = FALSE)
  cl <- match.call()
  p <- structure(list(
    title = title, rules = rules, strict = isTRUE(strict), verbose = isTRUE(verbose),
    stages = data.frame(stage = pipeline_stages$stage, status = "not run", summary = "",
                        stringsAsFactors = FALSE),
    data = NULL, model = NULL, selection = NULL, dif = NULL,
    persons = empty_person_flags(), flags = empty_flags(),
    log = data.frame(time = character(0), action = character(0), detail = character(0),
                     stringsAsFactors = FALSE),
    code = c("library(mirtverse)", paste("p <-", deparse_call(cl)))),
    class = "mv_pipeline")
  p
}

pipeline_stages <- data.frame(
  stage = c("blueprint", "generation", "intake", "calibration", "linking", "forms", "cuts",
            "reporting"),
  number = c(0L, 1L, 4L, 5L, 6L, 7L, 8L, 11L),
  label = c("Blueprint", "Item generation", "Data intake", "Calibration", "Linking and bank", "Forms", "Cut scores", "Reporting"),
  stringsAsFactors = FALSE)

stage_label <- function(stage) pipeline_stages$label[match(stage, pipeline_stages$stage)]

empty_flags <- function() {
  data.frame(id = integer(0), stage = character(0), check = character(0),
             target = character(0), value = character(0), rule = character(0),
             level = character(0), advice = character(0), status = character(0),
             note = character(0), stringsAsFactors = FALSE)
}

empty_person_flags <- function() {
  data.frame(row = integer(0), id = character(0), check = character(0),
             value = character(0), stringsAsFactors = FALSE)
}

# One or more flags as a data frame; `target` and `value` may be vectors.
new_flag <- function(stage, check, target, value, rule, level, advice) {
  n <- length(target)
  if (!n) return(empty_flags())
  data.frame(id = NA_integer_, stage = stage, check = check, target = as.character(target),
             value = rep_len(as.character(value), n), rule = rule,
             level = match.arg(level, c("info", "review", "block")),
             advice = rep_len(advice, n), status = "open", note = "",
             stringsAsFactors = FALSE)
}

# Replace a stage's flags with new ones. A decision recorded on a flag with the
# same check and target carries over, so rerunning a stage keeps it.
set_stage_flags <- function(p, stage, new) {
  old <- p$flags[p$flags$stage == stage, , drop = FALSE]
  if (nrow(new) && nrow(old)) {
    key_new <- paste(new$check, new$target)
    key_old <- paste(old$check, old$target)
    hit <- match(key_new, key_old)
    keep <- !is.na(hit) & old$status[pmax(hit, 1L)] %in% c("acknowledged", "overridden")
    new$status[keep] <- old$status[hit[keep]]
    new$note[keep] <- old$note[hit[keep]]
  }
  rest <- p$flags[p$flags$stage != stage, , drop = FALSE]
  start <- if (nrow(p$flags)) max(p$flags$id) else 0L
  if (nrow(new)) new$id <- start + seq_len(nrow(new))
  p$flags <- rbind(rest, new)
  p
}

set_stage <- function(p, stage, status, summary = "") {
  i <- match(stage, p$stages$stage)
  p$stages$status[i] <- status
  p$stages$summary[i] <- summary
  p
}

log_event <- function(p, action, detail) {
  p$log <- rbind(p$log, data.frame(time = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                                   action = action, detail = detail,
                                   stringsAsFactors = FALSE))
  p
}

add_code <- function(p, cl, assign = TRUE) {
  cl[[2]] <- as.name("p")
  names(cl)[2] <- ""
  p$code <- c(p$code, paste0(if (assign) "p <- ", deparse_call(cl)))
  p
}

deparse_call <- function(cl) paste(deparse(cl, width.cutoff = 80L), collapse = "\n")

check_pipeline <- function(p) {
  if (!inherits(p, "mv_pipeline"))
    stop("`p` must be a pipeline from mv_pipeline().", call. = FALSE)
}

# The gate in front of a stage: open review and block flags from earlier
# stages stop it when strict, and are listed in a warning otherwise.
enforce_gate <- function(p, stage) {
  earlier <- pipeline_stages$stage[seq_len(match(stage, pipeline_stages$stage) - 1L)]
  open <- p$flags[p$flags$stage %in% earlier & p$flags$status == "open" &
                    p$flags$level %in% c("review", "block"), , drop = FALSE]
  if (!nrow(open)) return(invisible(TRUE))
  n_block <- sum(open$level == "block")
  n_review <- sum(open$level == "review")
  counts <- paste(c(if (n_block) sprintf("%d block", n_block),
                    if (n_review) sprintf("%d review", n_review)), collapse = " and ")
  shown <- utils::head(open, 8L)
  lines <- sprintf("  #%d [%s] %s: %s (%s)", shown$id, shown$level, shown$check,
                   shown$target, shown$value)
  if (nrow(open) > 8L) lines <- c(lines, sprintf("  ... and %d more", nrow(open) - 8L))
  if (p$strict)
    stop(sprintf("%s cannot start: %s flag(s) from earlier stages are still open.\n%s\n",
                 stage_label(stage), counts, paste(lines, collapse = "\n")),
         "Fix them (for example with drop_items()), record a decision with acknowledge() ",
         "(review flags) or override() (block flags), or use strict = FALSE.", call. = FALSE)
  warning(sprintf("%s is running with %s open flag(s) from earlier stages:\n%s\n",
                  stage_label(stage), counts, paste(lines, collapse = "\n")),
          "Flags only warn because strict = FALSE. See flags(p).", call. = FALSE)
  invisible(FALSE)
}

report_stage_flags <- function(p, stage) {
  if (!p$verbose) return(invisible())
  f <- p$flags[p$flags$stage == stage & p$flags$status == "open", , drop = FALSE]
  message(sprintf("%s: %s", stage_label(stage),
                  if (!nrow(f)) "no open flags." else
                    paste0(flag_counts(f), ". See flags(p).")))
}

flag_counts <- function(f) {
  lv <- c("block", "review", "info")
  n <- vapply(lv, function(l) sum(f$level == l), integer(1))
  paste(sprintf("%d %s", n[n > 0], lv[n > 0]), collapse = ", ")
}

#' List the flags raised by a pipeline
#'
#' @param p a pipeline from [mv_pipeline()].
#' @param status which flags to show: `"open"` (the default), `"all"`, or any
#'   of `"acknowledged"`, `"overridden"` and `"fixed"`.
#' @param level optional levels to keep (`"info"`, `"review"`, `"block"`).
#' @param stage optional stages to keep (`"blueprint"`, `"generation"`,
#'   `"intake"`, `"calibration"`, `"linking"`, `"forms"`, `"cuts"`,
#'   `"reporting"`).
#' @return A tibble with one row per flag: `id`, `stage`, `check`, `target`
#'   (an item, a pair of items, a group, or the whole test), `value` (the
#'   statistic), `rule` (the threshold that fired), `level`, `advice` (what to
#'   do about it), `status` and `note` (the reason recorded with a decision).
#' @examples
#' \donttest{
#' p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key)
#' flags(p)
#' flags(p, level = "block")
#' }
#' @export
flags <- function(p, status = "open", level = NULL, stage = NULL) {
  check_pipeline(p)
  f <- p$flags
  if (!identical(status, "all")) f <- f[f$status %in% status, , drop = FALSE]
  if (!is.null(level)) f <- f[f$level %in% level, , drop = FALSE]
  if (!is.null(stage)) f <- f[f$stage %in% stage, , drop = FALSE]
  f <- f[order(match(f$level, c("block", "review", "info")), f$id), , drop = FALSE]
  as_tbl(f)
}

#' @rdname mv_pipeline
#' @param x a pipeline.
#' @param ... not used.
#' @export
tidy.mv_pipeline <- function(x, ...) flags(x, status = "all")

select_flags <- function(p, id, check, target, level, statuses = "open") {
  f <- p$flags
  sel <- f$status %in% statuses
  if (!is.null(id)) sel <- sel & f$id %in% id
  if (!is.null(check)) sel <- sel & f$check %in% check
  if (!is.null(target)) sel <- sel & f$target %in% target
  if (!is.null(level)) sel <- sel & f$level %in% level
  which(sel)
}

#' Record a decision about a flag
#'
#' `acknowledge()` records that a flag was looked at and the pipeline may move
#' on; it is meant for `info` and `review` flags. `override()` records a
#' decision to continue despite a `block` flag (or any other flag) and needs a
#' written reason. Both are logged with the time and the note, and the report
#' from [pipeline_report()] lists them. Choose flags by `id`, `check`,
#' `target` or `level`; with none of these, every open flag that the function
#' can take is chosen.
#'
#' To fix a problem instead, remove the item with [drop_items()] or rerun the
#' stage with corrected input; flags that no longer apply disappear.
#'
#' @param p a pipeline from [mv_pipeline()].
#' @param id flag numbers, as shown by [flags()].
#' @param check names of checks, e.g. `"item_misfit"`.
#' @param target items (or other targets) the flags are about.
#' @param level levels to choose, e.g. `"review"`.
#' @param note the reason for the decision. Required for `override()`.
#' @return The pipeline, with the chosen flags' status changed.
#' @examples
#' \donttest{
#' p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key)
#' p <- acknowledge(p, level = "review", note = "Checked with the content team")
#' p <- override(p, check = "possible_miskey",
#'               note = "Keep Q14 until the item writer replies")
#' flags(p, status = "all")
#' }
#' @export
acknowledge <- function(p, id = NULL, check = NULL, target = NULL, level = NULL, note = "") {
  check_pipeline(p)
  cl <- match.call()
  sel <- select_flags(p, id, check, target, level)
  if (!length(sel)) {
    warning("No open flags match; nothing was acknowledged.", call. = FALSE)
    return(p)
  }
  is_block <- p$flags$level[sel] == "block"
  if (any(is_block)) {
    if (is.null(id) && is.null(check) && is.null(target)) {
      sel <- sel[!is_block]
      if (!length(sel)) {
        warning("Only block flags match; use override() with a note for those.", call. = FALSE)
        return(p)
      }
    } else {
      stop("Block flags need override() with a written reason: ",
           paste0("#", p$flags$id[sel][is_block], collapse = ", "), ".", call. = FALSE)
    }
  }
  record_decision(p, sel, "acknowledged", note, cl)
}

#' @rdname acknowledge
#' @export
override <- function(p, id = NULL, check = NULL, target = NULL, level = NULL, note) {
  check_pipeline(p)
  cl <- match.call()
  if (missing(note) || !is.character(note) || !nzchar(trimws(note)))
    stop("override() needs a `note` that says why it is safe to continue.", call. = FALSE)
  sel <- select_flags(p, id, check, target, level)
  if (!length(sel)) {
    warning("No open flags match; nothing was overridden.", call. = FALSE)
    return(p)
  }
  record_decision(p, sel, "overridden", note, cl)
}

record_decision <- function(p, sel, status, note, cl) {
  p$flags$status[sel] <- status
  p$flags$note[sel] <- note
  detail <- sprintf("%s %s%s", status,
                    paste0("#", p$flags$id[sel], " ", p$flags$check[sel], " (",
                           p$flags$target[sel], ")", collapse = ", "),
                    if (nzchar(note)) paste0(": ", note) else "")
  p <- log_event(p, c(acknowledged = "acknowledge", overridden = "override")[[status]], detail)
  if (p$verbose) message(sprintf("%s %d flag(s).", tools::toTitleCase(status), length(sel)))
  add_code(p, cl)
}

#' Remove items from a pipeline
#'
#' Drops items from the response data (and the response times), marks every
#' open flag about them as fixed, and logs the decision. A model fitted
#' earlier no longer matches the data, so [calibrate()] has to be run again.
#'
#' @param p a pipeline with responses from [add_responses()].
#' @param items item names to remove.
#' @param note the reason, kept in the log and the report.
#' @return The pipeline without the items.
#' @examples
#' \donttest{
#' p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key)
#' p <- drop_items(p, "Q14", note = "Miskeyed")
#' }
#' @export
drop_items <- function(p, items, note = "") {
  check_pipeline(p)
  cl <- match.call()
  if (is.null(p$data)) stop("Add responses with add_responses() first.", call. = FALSE)
  nms <- colnames(p$data$responses)
  bad <- setdiff(items, nms)
  if (length(bad)) stop("Unknown item(s): ", paste(bad, collapse = ", "), call. = FALSE)
  keep <- setdiff(nms, items)
  if (length(keep) < 3L) stop("At least three items must remain.", call. = FALSE)
  p$data$responses <- p$data$responses[, keep, drop = FALSE]
  if (!is.null(p$data$rt)) p$data$rt <- p$data$rt[, keep, drop = FALSE]
  about <- vapply(strsplit(p$flags$target, " & ", fixed = TRUE),
                  function(t) any(t %in% items), logical(1))
  fixed <- about & p$flags$status == "open"
  p$flags$status[fixed] <- "fixed"
  p$flags$note[fixed] <- if (nzchar(note)) paste("Item dropped:", note) else "Item dropped"
  p <- log_event(p, "drop items", paste0(paste(items, collapse = ", "),
                                         if (nzchar(note)) paste0(": ", note) else ""))
  if (!is.null(p$model)) {
    p$model <- NULL; p$selection <- NULL; p$dif <- NULL; p$link <- NULL
    p$forms <- NULL; p$cuts <- NULL
    for (s in c("calibration", "linking", "forms", "cuts", "reporting"))
      if (p$stages$status[p$stages$stage == s] != "not run")
        p <- set_stage(p, s, "needs rerun", "items changed since this stage ran")
  }
  if (p$verbose) message(sprintf("Dropped %d item(s); %d remain.", length(items), length(keep)))
  add_code(p, cl)
}

#' @export
print.mv_pipeline <- function(x, ...) {
  cat(sprintf("<mv_pipeline> %s\n", x$title))
  cat(sprintf("%s; rules: %s\n",
              if (x$strict) "strict: open review and block flags stop the next stage"
              else "flags warn (strict = FALSE)", attr(x$rules, "preset")))
  cat("\n")
  for (i in seq_len(nrow(x$stages))) {
    s <- x$stages[i, ]
    f <- x$flags[x$flags$stage == s$stage & x$flags$status == "open", , drop = FALSE]
    mark <- switch(s$status, done = "[x]", "needs rerun" = "[!]", "[ ]")
    cat(sprintf("%s %-2d %-16s %s%s\n", mark, pipeline_stages$number[i], pipeline_stages$label[i],
                if (nzchar(s$summary)) s$summary else s$status,
                if (nrow(f)) paste0("  | open: ", flag_counts(f)) else ""))
  }
  open <- x$flags[x$flags$status == "open", , drop = FALSE]
  decided <- sum(x$flags$status != "open")
  cat(sprintf("\n%s%s\n",
              if (nrow(open)) paste0("Open flags: ", flag_counts(open), ". See flags(p).")
              else "No open flags.",
              if (decided) sprintf(" %d decision(s) recorded.", decided) else ""))
  invisible(x)
}
