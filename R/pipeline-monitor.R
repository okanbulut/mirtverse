#' Pipeline stage: bank monitoring
#'
#' Keeps an item bank healthy from one administration to the next. Each run
#' records the current administration in the bank (how many test takers saw
#' each item, and the test's marginal reliability) under a window name, then
#' checks the bank's history. Items it flags can be retired or sent back to
#' review with [retire_items()]. Drift and compromise checks are in
#' [check_security()].
#'
#' The checks (thresholds from [mv_rules()]):
#'
#' * `over_exposure` (review): active items seen by more than `max_exposure`
#'   of the test takers in each of the last `exposure_windows` windows.
#' * `bank_depth` (review): a content cell with fewer active items than its
#'   minimum: `min_items`, or by default `cell_depth` times the cell's count
#'   in the blueprint from [set_blueprint()].
#' * `reliability_trend` (review): marginal reliability in the latest window
#'   more than `reliability_drop` below its value in the first window.
#' * `unused_items` (info): more than `unused_share` of the active items
#'   (that have been in the bank for `unused_days`) not used in the last
#'   `unused_days` days.
#'
#' @param p a pipeline.
#' @param bank the item bank, from [mv_bank()] or [bank_items()]; defaults to
#'   `p$bank`.
#' @param window a name for the current administration, such as `"2026
#'   spring"`. Defaults to the pipeline title. Recording a window again
#'   replaces it. Use `record = FALSE` to check the bank without recording.
#' @param date the date of the administration.
#' @param content optional content cell of each bank item: a named vector
#'   (item id = cell). It is stored in the bank. By default the cells come
#'   from the bank, or from the items in the pipeline ([add_items()],
#'   [generate_items()]).
#' @param min_items optional fewest active items per cell: one number, or a
#'   named vector by cell.
#' @param record logical; record the current administration in the bank. It
#'   needs a calibrated pipeline.
#' @return The pipeline with the updated bank in `p$bank` and `p$monitoring`:
#'   `windows` (one row per administration), `items` (use of each bank
#'   item), and `cells` (active items per content cell). Save the bank with
#'   `saveRDS(p$bank, ...)` to keep its history.
#' @seealso [retire_items()]
#' @examples
#' \donttest{
#' p <- add_responses(mv_pipeline("Spring"), certexam, items = 3:34, key = certexam_key)
#' p <- calibrate(drop_items(p, "Q14"), model = "2PL")
#' p <- bank_items(p, name = "Certification bank")
#' p <- monitor_bank(p, window = "2026 spring", date = as.Date("2026-04-15"))
#' p$monitoring$windows
#' flags(p, stage = "monitoring")
#' }
#' @export
monitor_bank <- function(p, bank = NULL, window = p$title, date = Sys.Date(), content = NULL,
                         min_items = NULL, record = TRUE) {
  check_pipeline(p)
  cl <- match.call()
  if (is.null(bank)) bank <- p$bank
  if (!inherits(bank, "mv_bank"))
    stop("Give an item bank from mv_bank() or bank_items().", call. = FALSE)
  enforce_gate(p, "monitoring")
  date <- as.Date(date)
  if (length(window) != 1L || length(date) != 1L || is.na(date))
    stop("`window` and `date` must be single values.", call. = FALSE)
  bank <- set_bank_content(bank, content, p)
  if (record) {
    if (is.null(p$model) || is.null(p$data))
      stop("Recording an administration needs a calibrated pipeline; use record = FALSE ",
           "to check the bank only.", call. = FALSE)
    bank <- record_window(bank, p, as.character(window), date)
  }
  if (is.null(bank$usage)) bank <- empty_usage(bank)

  r <- p$rules
  out <- list()
  add <- function(...) out[[length(out) + 1L]] <<- new_flag("monitoring", ...)
  wins <- bank$windows[order(bank$windows$date, seq_len(nrow(bank$windows))), , drop = FALSE]
  it <- bank$items
  active <- it$item[it$status == "active"]

  k <- r$exposure_windows
  if (nrow(wins) >= k) {
    last <- utils::tail(wins$window, k)
    u <- bank$usage[bank$usage$window %in% last & bank$usage$item %in% active, , drop = FALSE]
    u <- u[order(match(u$window, last)), , drop = FALSE]
    high <- tapply(u$exposure > r$max_exposure, u$item, function(x) length(x) == k && all(x))
    hit <- names(high)[high]
    if (length(hit)) {
      ex <- tapply(u$exposure, u$item, function(x) sprintf("%.0f%%", 100 * x))
      add("over_exposure", hit,
          vapply(hit, function(i) paste(ex[[i]], collapse = ", "), character(1)),
          sprintf("exposure <= %s in at least one of the last %d windows", r$max_exposure, k),
          "review", "Rotate the item out, add parallel items, or retire it with retire_items().")
    }
  }

  cells <- bank_cells(bank, p, min_items, r$cell_depth)
  if (!is.null(cells)) {
    low <- !is.na(cells$minimum) & cells$active < cells$minimum
    add("bank_depth", cells$cell[low],
        sprintf("%d active item(s), minimum %s", cells$active[low], cells$minimum[low]),
        "enough active items in every cell", "review",
        "Write and field-test new items for this cell before more items are retired.")
  }

  rel <- wins$reliability
  if (sum(!is.na(rel)) >= 2L) {
    first <- rel[!is.na(rel)][1]
    now <- utils::tail(rel[!is.na(rel)], 1L)
    if (first - now > r$reliability_drop)
      add("reliability_trend", utils::tail(wins$window[!is.na(rel)], 1L),
          sprintf("reliability %.2f, first window %.2f", now, first),
          sprintf("drop <= %s", r$reliability_drop), "review",
          "Check for retired or drifting items, a changed population, or weaker forms.")
  }

  items <- bank_item_use(bank, wins)
  if (nrow(wins)) {
    as_of <- max(wins$date)
    old <- items$status == "active" & !is.na(items$added) &
      as_of - items$added >= r$unused_days
    unused <- old & (is.na(items$last_used) | as_of - items$last_used >= r$unused_days)
    share <- if (any(old)) sum(unused) / sum(items$status == "active") else 0
    if (share > r$unused_share)
      add("unused_items", "bank",
          sprintf("%d of %d active items (%.0f%%) unused for %d days", sum(unused),
                  sum(items$status == "active"), 100 * share, r$unused_days),
          sprintf("unused share <= %s", r$unused_share), "info",
          "Use these items on new forms, check whether they still fit the blueprint, or retire them.")
  }

  bank$history <- rbind(bank$history, data.frame(
    time = format(Sys.time(), "%Y-%m-%d %H:%M:%S"), action = "monitor",
    detail = sprintf("%d window(s), %d active items", nrow(wins), length(active)),
    stringsAsFactors = FALSE))
  p$bank <- bank
  p$monitoring <- list(windows = as_tbl(wins), items = items,
                       cells = if (!is.null(cells)) as_tbl(cells))
  p <- set_stage_flags(p, "monitoring", bind_flags(out))
  p <- set_stage(p, "monitoring", "done",
                 sprintf("%d window%s, %d active items", nrow(wins),
                         if (nrow(wins) == 1L) "" else "s", length(active)))
  p <- log_event(p, "monitor bank", p$stages$summary[p$stages$stage == "monitoring"])
  p <- add_code(p, cl)
  report_stage_flags(p, "monitoring")
  p
}

#' Retire bank items or send them back to review
#'
#' Takes items out of use in an item bank. Retired items stay in the bank
#' with their history but are no longer used for linking, forms or
#' monitoring. Items sent to review are also out of use until they are made
#' active again (`status = "active"`).
#'
#' @param x a pipeline with a bank (`p$bank`), or a bank from [mv_bank()].
#' @param items item ids.
#' @param status `"retired"`, `"review"` or `"active"`.
#' @param note the reason, kept in the bank's history.
#' @return `x`, with the bank updated.
#' @examples
#' \donttest{
#' mod <- mirt(expand.table(LSAT7), 1, itemtype = "2PL", verbose = FALSE)
#' bank <- retire_items(mv_bank(mod), "Item.1", note = "Exposed on a forum")
#' tidy(bank)
#' }
#' @export
retire_items <- function(x, items, status = c("retired", "review", "active"), note = "") {
  status <- match.arg(status)
  bank <- if (inherits(x, "mv_pipeline")) x$bank else x
  if (!inherits(bank, "mv_bank"))
    stop("`x` must be a bank from mv_bank() or a pipeline with a bank.", call. = FALSE)
  bad <- setdiff(items, bank$items$item)
  if (length(bad)) stop("Items not in the bank: ", paste(bad, collapse = ", "), call. = FALSE)
  bank$items$status[bank$items$item %in% items] <- status
  bank$history <- rbind(bank$history, data.frame(
    time = format(Sys.time(), "%Y-%m-%d %H:%M:%S"), action = status,
    detail = paste0(paste(items, collapse = ", "), if (nzchar(note)) paste0(": ", note)),
    stringsAsFactors = FALSE))
  if (!inherits(x, "mv_pipeline")) return(bank)
  cl <- match.call()
  x$bank <- bank
  x <- stage_rerun(x, "forms")
  x <- stage_rerun(x, "monitoring")
  x <- log_event(x, if (status == "active") "reactivate items" else
    paste("set items to", status),
    paste0(paste(items, collapse = ", "), if (nzchar(note)) paste0(": ", note)))
  add_code(x, cl)
}

empty_usage <- function(bank) {
  bank$usage <- data.frame(window = character(0), item = character(0), n = integer(0),
                           exposure = numeric(0), stringsAsFactors = FALSE)
  bank$windows <- data.frame(window = character(0), date = as.Date(character(0)),
                             n = integer(0), reliability = numeric(0),
                             stringsAsFactors = FALSE)
  bank
}

# Store this administration's item use and reliability in the bank.
record_window <- function(bank, p, window, date) {
  if (is.null(bank$usage)) bank <- empty_usage(bank)
  resp <- p$data$responses
  ids <- intersect(item_names(p$model), names(resp))
  seen <- colSums(!is.na(resp[, ids, drop = FALSE]))
  N <- nrow(resp)
  bank$usage <- rbind(bank$usage[bank$usage$window != window, , drop = FALSE],
                      data.frame(window = window, item = ids, n = as.integer(seen),
                                 exposure = unname(seen / N), stringsAsFactors = FALSE))
  rxx <- safe(mirt::marginal_rxx(p$model), NA_real_)
  bank$windows <- rbind(bank$windows[bank$windows$window != window, , drop = FALSE],
                        data.frame(window = window, date = date, n = N, reliability = rxx,
                                   stringsAsFactors = FALSE))
  bank
}

set_bank_content <- function(bank, content, p) {
  if (!"content" %in% names(bank$items)) bank$items$content <- NA_character_
  if (is.null(content) && !is.null(p$items) && "cell" %in% names(p$items))
    content <- stats::setNames(p$items$cell, p$items$id)
  if (is.null(content)) return(bank)
  if (is.null(names(content))) stop("`content` must be a named vector (item id = cell).",
                                    call. = FALSE)
  hit <- match(bank$items$item, names(content))
  set <- !is.na(hit) & !is.na(content[pmax(hit, 1L)])
  bank$items$content[set] <- as.character(content[hit[set]])
  bank
}

# Active items per content cell and each cell's minimum.
bank_cells <- function(bank, p, min_items, depth) {
  it <- bank$items
  cells <- if (!is.null(p$blueprint)) p$blueprint$cells$cell else character(0)
  cells <- unique(c(cells, stats::na.omit(it$content)))
  if (!length(cells)) return(NULL)
  act <- it$status == "active"
  n <- vapply(cells, function(cc) sum(act & it$content %in% cc), integer(1))
  minimum <- rep(NA_real_, length(cells))
  if (!is.null(p$blueprint)) {
    bp <- p$blueprint$cells
    hit <- match(cells, bp$cell)
    minimum <- ifelse(is.na(hit), NA_real_, ceiling(depth * bp$n[pmax(hit, 1L)]))
  }
  if (!is.null(min_items)) {
    if (is.null(names(min_items))) minimum[] <- min_items[1] else {
      hit <- match(cells, names(min_items))
      minimum[!is.na(hit)] <- min_items[hit[!is.na(hit)]]
    }
  }
  data.frame(cell = cells, active = unname(n), minimum = minimum, stringsAsFactors = FALSE)
}

# One row per bank item: how often and how recently it was used.
bank_item_use <- function(bank, wins) {
  it <- bank$items
  u <- bank$usage[bank$usage$n > 0, , drop = FALSE]
  u$date <- wins$date[match(u$window, wins$window)]
  used <- tapply(u$window, u$item, length)
  last <- tapply(as.numeric(u$date), u$item, max)
  mean_exp <- tapply(u$exposure, u$item, mean)
  latest <- utils::tail(wins$window, 1L)
  lat <- bank$usage[bank$usage$window %in% latest, , drop = FALSE]
  as_tbl(data.frame(
    item = it$item, status = it$status, content = it$content,
    added = suppressWarnings(as.Date(it$added)),
    windows_used = as.integer(ifelse(is.na(used[it$item]), 0L, used[it$item])),
    last_used = as.Date(unname(last[it$item]), origin = "1970-01-01"),
    mean_exposure = unname(mean_exp[it$item]),
    latest_exposure = lat$exposure[match(it$item, lat$item)],
    stringsAsFactors = FALSE))
}
