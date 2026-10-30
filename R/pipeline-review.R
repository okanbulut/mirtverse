#' Pipeline stage: item review
#'
#' Items, whether written by people or generated, need human content and
#' sensitivity (bias) review before they are field-tested. `review_packet()`
#' writes a review form (a CSV file that opens in a spreadsheet) with one row
#' per item and reviewer, ready for reviewers to fill in. `read_reviews()`
#' reads their decisions back, sets each item's status (`"approved"`,
#' `"revise"` or `"rejected"`, by majority) and runs the review checks.
#'
#' With `ai_screen = TRUE`, a language model (see [mv_ask_setup()]) first
#' screens every item for possible bias, sensitivity and accessibility
#' problems; its notes go into the packet for reviewers to weigh. The screen
#' assists reviewers and does not replace them.
#'
#' The checks (thresholds from [mv_rules()]):
#'
#' * `under_reviewed` (block): an item reviewed by fewer than
#'   `min_reviewers` reviewers.
#' * `alignment` (review): a reviewer does not agree the item measures its
#'   blueprint cell.
#' * `sensitivity` (review): a reviewer (or the AI screen) raised a bias or
#'   sensitivity concern.
#' * `needs_revision` (review): reviewers asked for the item to be revised.
#' * `reviewer_agreement` (info): Fleiss' kappa for the reviewers' decisions
#'   is below `review_kappa`.
#' * `provenance` (info): an item without a recorded source (person or
#'   model), which testing programs now need to disclose.
#'
#' @param p a pipeline with items from [generate_items()] or [add_items()].
#' @param file path of the CSV file to write.
#' @param reviewers optional reviewer names; the packet then has one row per
#'   item and reviewer.
#' @param ai_screen logical; screen items with a language model first.
#' @param provider,model the language model for the screen.
#' @return `review_packet()` returns the pipeline (with the screen's notes in
#'   `p$items$ai_screen`) invisibly and writes `file`.
#' @examples
#' items <- data.frame(stem = c("2 + 2 = ?", "3 x 3 = ?"), A = c("4", "6"),
#'                     B = c("5", "9"), key = c("A", "B"), cell = "Arithmetic")
#' p <- add_items(mv_pipeline(verbose = FALSE), items)
#' f <- tempfile(fileext = ".csv")
#' p <- review_packet(p, f, reviewers = c("Ana", "Ben"))
#' rv <- utils::read.csv(f)
#' rv$decision <- "accept"; rv$aligned <- "yes"; rv$sensitivity <- "no"
#' p <- read_reviews(p, rv)
#' p$items$status
#' @export
review_packet <- function(p, file = "review-packet.csv", reviewers = NULL, ai_screen = FALSE,
                          provider = NULL, model = NULL) {
  check_pipeline(p)
  cl <- match.call()
  if (is.null(p$items)) stop("The pipeline has no items; use generate_items() or add_items().",
                             call. = FALSE)
  enforce_gate(p, "review")
  it <- p$items
  if (ai_screen) {
    llm <- item_llm(provider, model)
    todo <- which(it$status != "rejected")
    for (j in todo) it$ai_screen[j] <- llm_screen_item(llm, item_text(it, j))
    p$items <- it
  }
  if (!"ai_screen" %in% names(it)) it$ai_screen <- NA_character_
  keep <- it$status != "rejected"
  rows <- data.frame(id = it$id, cell = it$cell, type = it$type,
                     item = vapply(seq_len(nrow(it)), function(j) item_text(it, j), character(1)),
                     key = ifelse(it$type == "mc", it$key, ""),
                     rubric = vapply(it$rubric, rubric_text, character(1)),
                     source = it$source, ai_screen = ifelse(is.na(it$ai_screen), "", it$ai_screen),
                     stringsAsFactors = FALSE)[keep, , drop = FALSE]
  if (!is.null(reviewers))
    rows <- do.call(rbind, lapply(reviewers, function(r) cbind(rows, reviewer = r)))
  else rows$reviewer <- ""
  rows$decision <- ""
  rows$aligned <- ""
  rows$sensitivity <- ""
  rows$comment <- ""
  utils::write.csv(rows, file, row.names = FALSE, na = "")
  p <- log_event(p, "review packet", sprintf("%d items to %s", sum(keep), basename(file)))
  p <- add_code(p, cl)
  if (p$verbose)
    message(sprintf(paste("Wrote %s. Reviewers fill in decision (accept, revise or reject),",
                          "aligned (yes/no: the item measures its cell), sensitivity (yes/no)",
                          "and comment; then read it back with read_reviews()."), file))
  invisible(p)
}

#' @rdname review_packet
#' @param reviews the completed packet: a path to the CSV file or a data
#'   frame with columns `id`, `reviewer`, `decision` (`accept`, `revise` or
#'   `reject`), `aligned` (`yes`/`no`), `sensitivity` (`yes`/`no`) and
#'   optionally `comment`. Rows with an empty decision are ignored.
#' @return `read_reviews()` returns the pipeline with the reviews in
#'   `p$reviews`, an agreement summary in `p$review_agreement`, and the items'
#'   status updated.
#' @export
read_reviews <- function(p, reviews) {
  check_pipeline(p)
  cl <- match.call()
  if (is.null(p$items)) stop("The pipeline has no items.", call. = FALSE)
  if (is.character(reviews)) reviews <- utils::read.csv(reviews, stringsAsFactors = FALSE,
                                                         colClasses = "character")
  rv <- as.data.frame(reviews, stringsAsFactors = FALSE)
  need <- c("id", "reviewer", "decision")
  if (!all(need %in% names(rv)))
    stop("`reviews` needs columns id, reviewer and decision (and aligned, sensitivity).",
         call. = FALSE)
  for (nm in c("aligned", "sensitivity", "comment")) if (!nm %in% names(rv)) rv[[nm]] <- ""
  rv[] <- lapply(rv, function(v) trimws(as.character(v)))
  rv[is.na(rv)] <- ""
  rv$decision <- tolower(rv$decision)
  rv <- rv[nzchar(rv$decision), c("id", "reviewer", "decision", "aligned", "sensitivity",
                                  "comment"), drop = FALSE]
  bad <- setdiff(rv$decision, c("accept", "revise", "reject"))
  if (length(bad)) stop("Decisions must be accept, revise or reject, not: ",
                        paste(unique(bad), collapse = ", "), call. = FALSE)
  unknown <- setdiff(rv$id, p$items$id)
  if (length(unknown)) stop("Reviews for items not in the pool: ",
                            paste(unknown, collapse = ", "), call. = FALSE)
  if (!is.null(p$reviews)) {
    old <- p$reviews
    old <- old[!paste(old$id, old$reviewer) %in% paste(rv$id, rv$reviewer), , drop = FALSE]
    rv <- rbind(old, rv)
  }
  p$reviews <- as_tbl(rv)

  it <- p$items
  for (j in seq_len(nrow(it))) {
    d <- rv$decision[rv$id == it$id[j]]
    if (!length(d)) next
    tab <- table(factor(d, levels = c("accept", "revise", "reject")))
    top <- names(tab)[tab == max(tab)]
    it$status[j] <- if (length(top) > 1L) "revise" else
      c(accept = "approved", revise = "revise", reject = "rejected")[[top]]
  }
  p$items <- it
  p$review_agreement <- review_agreement(rv)

  p <- set_stage_flags(p, "review", review_checks(p))
  p <- set_stage_flags(p, "generation", item_checks(p))
  st <- table(factor(it$status, levels = c("approved", "revise", "rejected", "draft")))
  p <- set_stage(p, "review", "done",
                 sprintf("%d approved, %d to revise, %d rejected", st[["approved"]],
                         st[["revise"]], st[["rejected"]]))
  p <- stage_rerun(p, "field_test")
  p <- log_event(p, "read reviews", sprintf("%d reviews from %d reviewers", nrow(rv),
                                            length(unique(rv$reviewer))))
  p <- add_code(p, cl)
  report_stage_flags(p, "review")
  p
}

review_checks <- function(p) {
  it <- p$items[p$items$status != "rejected", , drop = FALSE]
  rv <- p$reviews
  r <- p$rules
  out <- list()
  add <- function(...) out[[length(out) + 1L]] <<- new_flag("review", ...)
  n_rev <- vapply(it$id, function(i) length(unique(rv$reviewer[rv$id == i])), integer(1))
  few <- n_rev < r$min_reviewers
  add("under_reviewed", it$id[few], sprintf("%d reviewer(s)", n_rev[few]),
      sprintf("at least %d reviewers", r$min_reviewers), "block",
      "Have more reviewers review the item before it is field-tested.")
  yes <- function(v) tolower(v) %in% c("yes", "y", "true", "1")
  no <- function(v) tolower(v) %in% c("no", "n", "false", "0")
  mis <- vapply(it$id, function(i) sum(no(rv$aligned[rv$id == i])), integer(1))
  add("alignment", it$id[mis > 0], sprintf("%d reviewer(s) disagree", mis[mis > 0]),
      "reviewers agree the item measures its cell", "review",
      "Move the item to the cell it measures, or revise it.")
  sens <- vapply(it$id, function(i) sum(yes(rv$sensitivity[rv$id == i])), integer(1))
  ai <- if ("ai_screen" %in% names(it)) !is.na(it$ai_screen) & nzchar(it$ai_screen) else
    rep(FALSE, nrow(it))
  flag_s <- sens > 0 | ai
  add("sensitivity", it$id[flag_s],
      ifelse(sens[flag_s] > 0, sprintf("%d reviewer(s) raised a concern", sens[flag_s]),
             sprintf("AI screen: %s", it$ai_screen[flag_s])),
      "no bias or sensitivity concern", "review",
      "Read the concern; revise or drop the item, or record why it stays with acknowledge().")
  rev <- it$status == "revise"
  add("needs_revision", it$id[rev], "reviewers asked for revision", "accepted by reviewers",
      "review", "Revise the item and review it again, or reject it.")
  ag <- p$review_agreement
  if (!is.na(ag$kappa) && ag$kappa < r$review_kappa)
    add("reviewer_agreement", "reviewers", sprintf("Fleiss' kappa = %.2f", ag$kappa),
        sprintf("kappa >= %s", r$review_kappa), "info",
        "Reviewers apply the criteria differently; hold a calibration session before the next round.")
  nosrc <- is.na(it$source) | !nzchar(it$source)
  add("provenance", it$id[nosrc], "source not recorded", "every item records its source",
      "info", "Record who or what wrote the item (person or AI model) for disclosure.")
  bind_flags(out)
}

# percent agreement and Fleiss' kappa for the decisions on items with at
# least two reviews
review_agreement <- function(rv) {
  cats <- c("accept", "revise", "reject")
  counts <- do.call(rbind, lapply(split(rv$decision, rv$id), function(d)
    as.numeric(table(factor(d, levels = cats)))))
  if (is.null(counts)) counts <- matrix(0, 0, 3)
  n <- rowSums(counts)
  counts <- counts[n >= 2, , drop = FALSE]
  n <- n[n >= 2]
  if (!nrow(counts)) return(list(items = 0L, agreement = NA_real_, kappa = NA_real_))
  P_i <- (rowSums(counts^2) - n) / (n * (n - 1))
  p_j <- colSums(counts) / sum(counts)
  Pe <- sum(p_j^2)
  Pbar <- mean(P_i)
  list(items = nrow(counts), agreement = Pbar,
       kappa = if (Pe < 1) (Pbar - Pe) / (1 - Pe) else NA_real_)
}

item_text <- function(it, j) {
  opts <- it$options[[j]]
  paste(c(it$stem[j], if (length(opts)) sprintf("%s. %s", LETTERS[seq_along(opts)], opts)),
        collapse = "\n")
}

rubric_text <- function(r) {
  if (is.null(r)) return("")
  r <- as.data.frame(r, stringsAsFactors = FALSE)
  if (!nrow(r) || !all(c("score", "descriptor") %in% names(r))) return("")
  paste(sprintf("%s: %s", r$score, r$descriptor), collapse = "\n")
}

llm_screen_item <- function(llm, text) {
  chat <- make_chat(llm$provider, llm$model, paste(
    "You are a fairness and accessibility reviewer for test items.",
    "Look for content that could disadvantage a group of test takers (culture, gender, region, language, socioeconomic status, disability), that could upset test takers, or that adds reading or language load unrelated to what is measured.",
    "Reply with one short sentence naming each real concern, or an empty string if there is none. Do not comment on content accuracy."))
  out <- chat$chat_structured(text, type = ellmer::type_object(
    concern = ellmer::type_string("The concerns, or an empty string.")), echo = "none")
  trimws(as.character(out$concern %||% ""))
}
