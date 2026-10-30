#' Pipeline stage: test blueprint and construct definition
#'
#' States what the test measures and how it is built: the construct, the
#' content cells with a target number of items in each, the item types, the
#' intended score use and the target reliability. The blueprint is the
#' contract later stages check against: [generate_items()] fills its cells,
#' item coverage is counted against its targets, and the target reliability
#' replaces the `reliability` rule used at calibration.
#'
#' The checks:
#'
#' * `empty_cell` (block): a content cell has no target count (zero or
#'   missing).
#' * `score_use` (review): the intended use of the scores is not stated;
#'   decisions about cut scores, reliability and reporting depend on it.
#' * `target_reliability` (info): no target reliability was given, so the
#'   `reliability` rule (0.80 by default) is used.
#' * `test_length` (info): the stated test length differs from the sum of the
#'   cell targets.
#'
#' @param p a pipeline from [mv_pipeline()].
#' @param cells the content cells: a data frame with a column `content`, an
#'   optional column `cognitive` (cognitive level, such as recall or
#'   application) and a column `n` with the target number of items per test
#'   form; or a named vector of target counts, with content areas as names.
#' @param construct a sentence describing what the test measures.
#' @param use the intended use of the scores, such as `"pass/fail"`,
#'   `"classification"`, `"ranking"`, `"diagnostic"` or `"growth"`.
#' @param item_types item types to write: `"mc"` (multiple choice) and/or
#'   `"open"` (open-ended, scored with a rubric).
#' @param length number of items on a form; defaults to the sum of the cell
#'   targets.
#' @param population a description of the test takers (used when writing
#'   items).
#' @param grade_level optional target reading grade level for item text.
#' @param reliability optional target reliability; replaces the
#'   `reliability` rule.
#' @return The pipeline with `p$blueprint`, a list holding the settings and
#'   `cells`, a tibble with one row per cell (`cell`, `content`, `cognitive`,
#'   `n`).
#' @examples
#' bp <- data.frame(content = c("Algebra", "Algebra", "Geometry"),
#'                  cognitive = c("Recall", "Application", "Application"),
#'                  n = c(5, 10, 5))
#' p <- set_blueprint(mv_pipeline(), bp, construct = "Grade 8 mathematics",
#'                    use = "pass/fail", reliability = 0.85)
#' p$blueprint$cells
#' @export
set_blueprint <- function(p, cells, construct = NULL, use = NULL, item_types = "mc",
                          length = NULL, population = NULL, grade_level = NULL,
                          reliability = NULL) {
  check_pipeline(p)
  cl <- match.call()
  if (is.numeric(cells) && !is.null(names(cells)))
    cells <- data.frame(content = names(cells), n = unname(cells), stringsAsFactors = FALSE)
  cells <- as.data.frame(cells, stringsAsFactors = FALSE)
  if (!all(c("content", "n") %in% names(cells)))
    stop("`cells` needs columns `content` and `n` (and optionally `cognitive`).", call. = FALSE)
  if (!"cognitive" %in% names(cells)) cells$cognitive <- NA_character_
  cells$content <- as.character(cells$content)
  cells$cognitive <- as.character(cells$cognitive)
  cells$n <- suppressWarnings(as.numeric(cells$n))
  cells$cell <- ifelse(is.na(cells$cognitive), cells$content,
                       paste(cells$content, cells$cognitive, sep = " / "))
  if (anyDuplicated(cells$cell))
    stop("Each content (and cognitive level) must appear once in `cells`.", call. = FALSE)
  item_types <- match.arg(item_types, c("mc", "open"), several.ok = TRUE)
  if (!is.null(reliability) && (!is.numeric(reliability) || reliability <= 0 || reliability >= 1))
    stop("`reliability` must be between 0 and 1.", call. = FALSE)
  total <- sum(cells$n, na.rm = TRUE)
  if (is.null(length)) length <- total

  out <- list()
  add <- function(...) out[[length(out) + 1L]] <<- new_flag("blueprint", ...)
  empty <- is.na(cells$n) | cells$n <= 0
  add("empty_cell", cells$cell[empty], "no target count", "every cell needs a target count",
      "block", "Give the cell a target number of items, or remove it from the blueprint.")
  if (is.null(use) || !nzchar(use))
    add("score_use", "blueprint", "not stated", "the intended score use must be stated",
        "review", "State how scores will be used (for example pass/fail or diagnostic); cut scores, reliability targets and reports depend on it.")
  if (is.null(reliability))
    add("target_reliability", "blueprint", sprintf("default %s used", p$rules$reliability),
        "a target reliability should be given", "info",
        "Give a target reliability that fits the score use (higher for high-stakes decisions).")
  if (length != total)
    add("test_length", "blueprint", sprintf("length %d, cells sum to %d", length, total),
        "length equals the sum of the cell targets", "info",
        "Check the cell targets; forms built from this blueprint will follow them.")

  if (!is.null(reliability)) {
    p$rules$reliability <- reliability
    attr(p$rules, "changed") <- union(attr(p$rules, "changed"), "reliability")
  }
  p$blueprint <- list(construct = construct, use = use, item_types = item_types,
                      length = length, population = population, grade_level = grade_level,
                      reliability = reliability %||% p$rules$reliability,
                      cells = as_tbl(cells[, c("cell", "content", "cognitive", "n")]))
  p <- set_stage_flags(p, "blueprint", bind_flags(out))
  p <- set_stage(p, "blueprint", "done",
                 sprintf("%d cells, %d items per form", nrow(cells), length))
  if (!is.null(p$items)) p <- stage_rerun(p, "generation")
  p <- log_event(p, "set blueprint", sprintf("%d cells; use: %s", nrow(cells), use %||% "not stated"))
  p <- add_code(p, cl)
  report_stage_flags(p, "blueprint")
  p
}
