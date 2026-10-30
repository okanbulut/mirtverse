#' Pipeline stage: data intake and cleaning
#'
#' Adds item responses to a pipeline, scores them with an answer key if one is
#' given, and screens items and respondents before calibration. The checks
#' (thresholds from [mv_rules()]):
#'
#' * `zero_variance` (block): every respondent gave the same answer, so the
#'   item cannot be calibrated.
#' * `possible_miskey` (block): a 0/1 item with a very low proportion correct
#'   or a negative corrected item-total correlation, or a polytomous item with
#'   a negative correlation (possibly reverse-coded).
#' * `item_missing` (review): an item with many missing responses.
#' * `person_missing` (review): respondents who skipped most items.
#' * `straight_lining` (review): respondents who gave the same answer to every
#'   item of a rating-scale (polytomous, unkeyed) test.
#' * `rapid_guessing` (review): respondents with many responses faster than
#'   `rapid_rt` times the item's median response time (needs `rt`).
#' * `sparse_category` (review): score categories with few responses.
#' * `small_group` (info): groups too small for stable DIF results (fewer than
#'   100 respondents).
#'
#' Respondent-level checks raise one flag each, with the number of respondents
#' as the target; the respondents themselves are listed in `p$persons`.
#'
#' @param p a pipeline from [mv_pipeline()].
#' @param data a data frame (or matrix) of responses, possibly with other
#'   columns such as an ID or a grouping variable.
#' @param items the item columns, by name or position. Defaults to every
#'   column that is not `id`, `group` or `rt`.
#' @param key optional answer key: one correct option per item. Responses are
#'   then scored 1 (correct) or 0 (incorrect); missing responses stay missing.
#' @param group optional grouping variable for DIF and group summaries: a
#'   column name of `data` or a vector with one value per respondent.
#' @param id optional respondent IDs: a column name of `data` or a vector.
#' @param rt optional response times: a matrix or data frame with one column
#'   per item (same order), or the names of those columns in `data`.
#' @return The pipeline with the data and the intake flags added.
#' @examples
#' \donttest{
#' p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key,
#'                    id = "id", group = "language")
#' flags(p)
#' }
#' @export
add_responses <- function(p, data, items = NULL, key = NULL, group = NULL, id = NULL,
                          rt = NULL) {
  check_pipeline(p)
  cl <- match.call()
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  n <- nrow(data)
  if (!n) stop("`data` has no rows.", call. = FALSE)
  used <- character(0)
  column_or_vector <- function(v, what) {
    if (is.null(v)) return(NULL)
    if (is.character(v) && length(v) == 1L && n != 1L) {
      if (!v %in% names(data))
        stop(sprintf("`%s` column \"%s\" is not in the data.", what, v), call. = FALSE)
      used <<- c(used, v)
      return(data[[v]])
    }
    if (length(v) != n)
      stop(sprintf("`%s` must have one value per respondent (row of the data).", what),
           call. = FALSE)
    v
  }
  group <- column_or_vector(group, "group")
  id <- column_or_vector(id, "id")
  if (is.character(rt)) {
    miss <- setdiff(rt, names(data))
    if (length(miss)) stop("Response time column(s) not in the data: ",
                           paste(miss, collapse = ", "), call. = FALSE)
    used <- c(used, rt)
    rt <- data[, rt, drop = FALSE]
  }
  items <- if (is.null(items)) setdiff(names(data), used) else
    if (is.numeric(items)) names(data)[items] else items
  bad <- setdiff(items, names(data))
  if (length(bad)) stop("Unknown item column(s): ", paste(bad, collapse = ", "), call. = FALSE)
  if (length(items) < 3L) stop("At least three items are needed.", call. = FALSE)
  raw <- data[, items, drop = FALSE]

  if (!is.null(key)) {
    if (length(key) != length(items))
      stop(sprintf("`key` has %d entries but there are %d items.", length(key), length(items)),
           call. = FALSE)
    if (!is.null(names(key)) && all(items %in% names(key))) key <- key[items]
    resp <- as.data.frame(lapply(seq_along(items), function(j) {
      v <- raw[[j]]
      ifelse(is.na(v) | v == "", NA_integer_, as.integer(as.character(v) == as.character(key[[j]])))
    }))
    names(resp) <- items
  } else {
    resp <- as.data.frame(lapply(raw, function(v) {
      if (is.factor(v)) v <- as.character(v)
      out <- suppressWarnings(as.numeric(v))
      if (any(is.na(out) & !is.na(v) & v != ""))
        stop("Item responses must be numbers when no `key` is given; ",
             "give a `key` to score option letters.", call. = FALSE)
      out
    }))
    names(resp) <- items
  }

  if (!is.null(rt)) {
    rt <- as.data.frame(rt)
    if (nrow(rt) != n || ncol(rt) != length(items))
      stop("`rt` must have one row per respondent and one column per item.", call. = FALSE)
    names(rt) <- items
  }
  if (is.null(id)) id <- as.character(seq_len(n))

  p$data <- list(responses = resp, raw = raw, key = key, group = group,
                 id = as.character(id), rt = rt)
  if (!is.null(p$model)) {
    p$model <- NULL; p$selection <- NULL; p$dif <- NULL; p$link <- NULL
  }
  checks <- intake_checks(p$data, p$rules)
  p$persons <- checks$persons
  p <- set_stage_flags(p, "intake", checks$flags)
  p$forms <- NULL; p$cuts <- NULL
  for (s in c("calibration", "linking", "forms", "cuts", "reporting"))
    if (p$stages$status[p$stages$stage == s] != "not run")
      p <- set_stage(p, s, "needs rerun", "data changed since this stage ran")
  p <- set_stage(p, "intake", "done",
                 sprintf("%s respondents, %d items%s", format(n, big.mark = ","), length(items),
                         if (!is.null(key)) ", scored with key" else ""))
  p <- log_event(p, "add responses", sprintf("%d respondents, %d items", n, length(items)))
  p <- add_code(p, cl)
  report_stage_flags(p, "intake")
  p
}

intake_checks <- function(d, rules) {
  resp <- d$responses
  nms <- names(resp)
  out <- list()
  persons <- list()
  add <- function(...) out[[length(out) + 1L]] <<- new_flag("intake", ...)
  add_persons <- function(rows, check, value) {
    if (length(rows))
      persons[[length(persons) + 1L]] <<- data.frame(row = rows, id = d$id[rows], check = check,
                                                    value = as.character(value),
                                                    stringsAsFactors = FALSE)
  }
  K <- vapply(resp, function(v) length(unique(stats::na.omit(v))), integer(1))
  dich <- vapply(resp, function(v) all(stats::na.omit(v) %in% c(0, 1)), logical(1))

  zv <- K <= 1L
  add("zero_variance", nms[zv], "one response value", "at most one distinct response",
      "block", "Every respondent answered the same way; drop the item with drop_items().")

  total <- rowSums(resp, na.rm = TRUE)
  rit <- vapply(seq_along(nms), function(j) {
    if (zv[j]) return(NA_real_)
    rest <- total - ifelse(is.na(resp[[j]]), 0, resp[[j]])
    safe(stats::cor(resp[[j]], rest, use = "pairwise.complete.obs"), NA_real_)
  }, numeric(1))
  pval <- vapply(resp, function(v) mean(v, na.rm = TRUE), numeric(1))
  mk_d <- dich & !zv & ((pval < rules$miskey_p) | (rit < rules$miskey_r))
  mk_d[is.na(mk_d)] <- FALSE
  add("possible_miskey", nms[mk_d],
      sprintf("p = %.2f, item-total r = %.2f", pval[mk_d], rit[mk_d]),
      sprintf("p < %s or item-total r < %s", rules$miskey_p, rules$miskey_r), "block",
      if (!is.null(d$key)) "Check the answer key and the item text; fix the key or drop the item."
      else "Check how the item was scored; fix the scoring or drop the item.")
  mk_p <- !dich & !zv & rit < rules$miskey_r
  mk_p[is.na(mk_p)] <- FALSE
  add("possible_miskey", nms[mk_p], sprintf("item-total r = %.2f", rit[mk_p]),
      sprintf("item-total r < %s", rules$miskey_r), "block",
      "The item runs against the others; check whether it should be reverse-coded.")

  miss <- vapply(resp, function(v) mean(is.na(v)), numeric(1))
  hi <- miss > rules$missing_item
  add("item_missing", nms[hi], sprintf("%.0f%% missing", 100 * miss[hi]),
      sprintf("more than %.0f%% missing", 100 * rules$missing_item), "review",
      "Find out why (not reached, omitted, not administered) before treating these as missing at random.")

  pmiss <- rowMeans(is.na(resp))
  rows <- which(pmiss > rules$missing_person)
  add_persons(rows, "person_missing", sprintf("%.0f%% missing", 100 * pmiss[rows]))
  if (length(rows))
    add("person_missing", sprintf("%d respondents", length(rows)),
        sprintf("%.1f%% of respondents", 100 * length(rows) / nrow(resp)),
        sprintf("more than %.0f%% of items missing", 100 * rules$missing_person), "review",
        "Consider removing these respondents; their scores rest on few answers. See p$persons.")

  if (is.null(d$key) && !all(dich) && length(nms) >= rules$straight_min_items) {
    answered <- rowSums(!is.na(resp))
    same <- apply(resp, 1L, function(r) length(unique(stats::na.omit(r))) == 1L)
    rows <- which(same & answered >= rules$straight_min_items)
    add_persons(rows, "straight_lining", "same answer to every item")
    if (length(rows))
      add("straight_lining", sprintf("%d respondents", length(rows)),
          sprintf("%.1f%% of respondents", 100 * length(rows) / nrow(resp)),
          "same answer to every item", "review",
          "Check whether these respondents were engaged; consider removing them. See p$persons.")
  }

  if (!is.null(d$rt)) {
    rt <- as.matrix(d$rt)
    thr <- rules$rapid_rt * apply(rt, 2L, stats::median, na.rm = TRUE)
    rapid <- sweep(rt, 2L, thr, "<")
    share <- rowMeans(rapid, na.rm = TRUE)
    rows <- which(share > rules$rapid_person)
    add_persons(rows, "rapid_guessing", sprintf("%.0f%% rapid", 100 * share[rows]))
    if (length(rows))
      add("rapid_guessing", sprintf("%d respondents", length(rows)),
          sprintf("%.1f%% of respondents", 100 * length(rows) / nrow(resp)),
          sprintf("more than %.0f%% of responses faster than %.0f%% of the item median",
                  100 * rules$rapid_person, 100 * rules$rapid_rt), "review",
          "Rapid guesses add noise; consider removing these respondents or modelling times with fit_rt().")
  }

  sparse <- lapply(seq_along(nms), function(j) {
    if (dich[j] || zv[j]) return(NULL)
    tb <- table(resp[[j]])
    low <- tb[tb < rules$min_category_n]
    if (length(low)) sprintf("category %s: n = %d", names(low), as.integer(low))
  })
  has <- !vapply(sparse, is.null, logical(1))
  add("sparse_category", nms[has], vapply(sparse[has], paste, character(1), collapse = "; "),
      sprintf("fewer than %d responses in a category", rules$min_category_n), "review",
      "Collapse the sparse category with its neighbour before calibration.")

  if (!is.null(d$group)) {
    sizes <- table(d$group)
    small <- sizes < 100L
    add("small_group", names(sizes)[small], sprintf("n = %d", as.integer(sizes[small])),
        "fewer than 100 respondents", "info",
        "DIF results for this group will be unstable.")
  }

  list(flags = if (length(out)) do.call(rbind, out) else empty_flags(),
       persons = if (length(persons)) do.call(rbind, persons) else empty_person_flags())
}
