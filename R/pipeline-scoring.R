#' Pipeline stage: scoring open-ended responses
#'
#' Scores open-ended (constructed) responses by one of two routes, chosen by
#' the user, and checks the machine scores against human scores before they
#' are used:
#'
#' * `scorer = "llm"`: a language model (see [mv_ask_setup()]) scores each
#'   response against the item's rubric from [generate_items()] or
#'   [add_items()] and returns a score, a one-sentence rationale and its
#'   confidence.
#' * `scorer = <a fitted model>`: any object with a `predict()` method
#'   trained on human scores, such as a tidymodels workflow. It is called as
#'   `predict(scorer, newdata)` with the responses data frame (columns
#'   `item`, `response` and any other columns you supply) and must return
#'   one score per row; predictions are rounded and kept within the item's
#'   score range.
#'
#' Both routes pass the same agreement gate, computed on the responses that
#' have human scores (`human1`, and `human2` for double-scored responses),
#' following Williamson, Xi and Breyer (2012) (thresholds from [mv_rules()]):
#'
#' * `validation_n` (review): fewer than `n_validation` double-scored
#'   responses for an item.
#' * `human_agreement` (block): quadratic weighted kappa (QWK) between the two
#'   human scores below `qwk_min`.
#' * `machine_agreement` (block): QWK between machine and human scores below
#'   `qwk_min`, or more than `qwk_drop` below the human-human QWK.
#' * `score_distribution` (review): the standardized mean difference between
#'   machine and human scores is beyond `score_smd` in absolute value.
#' * `subgroup_fairness` (review): the machine-human standardized mean
#'   difference within a group is beyond `subgroup_smd`.
#' * `low_confidence` (review): responses that are off topic, shorter than
#'   `min_words` words, or scored with confidence below `min_confidence`.
#'   They are routed to human scoring: their final score is the human score
#'   if there is one, otherwise missing.
#'
#' With `add_to_data = TRUE` the final scores join the pipeline's response
#' data as polytomous items (matched by respondent id), so a mixed test can be
#' calibrated with [calibrate()].
#'
#' @param p a pipeline whose item pool has the open-ended items (with
#'   rubrics) or, for a trained model, at least their ids.
#' @param responses a data frame with one row per response and columns
#'   `person`, `item` (an item id in `p$items`), `response` (the text), and
#'   optionally `human1`, `human2` (human scores) and `group`.
#' @param scorer `"llm"` or a fitted model with a `predict()` method.
#' @param provider,model the language model for `scorer = "llm"`.
#' @param add_to_data logical; add the final scores to the response data.
#' @param batch responses scored in one model call.
#' @return The pipeline with `p$open_scores`, a tibble with one row per
#'   response (`machine`, `rationale`, `confidence`, `routed` and `final`
#'   scores), and `p$agreement`, a tibble of agreement statistics per item.
#' @references Williamson, D. M., Xi, X., & Breyer, F. J. (2012). A framework
#'   for evaluation and use of automated scoring. *Educational Measurement:
#'   Issues and Practice, 31*(1), 2-13.
#' @examples
#' \dontrun{
#' p <- score_open(p, essays, scorer = "llm")
#' p$agreement
#' # or a model trained on human scores
#' p <- score_open(p, essays, scorer = my_workflow)
#' }
#' @export
score_open <- function(p, responses, scorer = "llm", provider = NULL, model = NULL,
                       add_to_data = FALSE, batch = 10) {
  check_pipeline(p)
  cl <- match.call()
  enforce_gate(p, "scoring")
  rs <- as.data.frame(responses, stringsAsFactors = FALSE)
  need <- c("person", "item", "response")
  if (!all(need %in% names(rs)))
    stop("`responses` needs columns person, item and response.", call. = FALSE)
  for (nm in c("human1", "human2")) {
    if (!nm %in% names(rs)) rs[[nm]] <- NA_real_
    rs[[nm]] <- suppressWarnings(as.numeric(rs[[nm]]))
  }
  if (!"group" %in% names(rs)) rs$group <- NA_character_
  rs$person <- as.character(rs$person)
  rs$item <- as.character(rs$item)
  rs$response <- as.character(rs$response)
  it <- p$items
  if (is.null(it)) stop("The pipeline has no items; add the open-ended items with add_items().",
                        call. = FALSE)
  unknown <- setdiff(rs$item, it$id)
  if (length(unknown)) stop("Responses to items not in the pool: ",
                            paste(unique(unknown), collapse = ", "), call. = FALSE)
  max_score <- stats::setNames(it$max_score, it$id)[rs$item]
  if (anyNA(max_score))
    stop("Every scored item needs a maximum score (a rubric).", call. = FALSE)

  if (identical(scorer, "llm")) {
    llm <- item_llm(provider, model)
    rs$machine <- NA_real_; rs$rationale <- ""; rs$confidence <- NA_real_
    rs$off_topic <- FALSE
    for (item in unique(rs$item)) {
      j <- match(item, it$id)
      if (!rubric_complete(it$rubric[[j]]))
        stop(sprintf("Item %s has no complete rubric to score against.", item), call. = FALSE)
      rows <- which(rs$item == item)
      for (chunk in split(rows, ceiling(seq_along(rows) / batch))) {
        res <- llm_score_batch(llm, it$stem[j], it$rubric[[j]], rs$response[chunk])
        rs$machine[chunk] <- res$score
        rs$rationale[chunk] <- res$rationale
        rs$confidence[chunk] <- res$confidence
        rs$off_topic[chunk] <- res$off_topic
      }
    }
    how <- sprintf("LLM rubric scoring (%s)", provider_label(llm$provider, llm$model))
  } else {
    pred <- tryCatch(stats::predict(scorer, rs), error = function(e)
      stop("predict() on the scorer failed: ", conditionMessage(e), call. = FALSE))
    if (is.data.frame(pred)) pred <- pred[[1]]
    pred <- as.numeric(unlist(pred))
    if (length(pred) != nrow(rs))
      stop("The scorer must return one score per response.", call. = FALSE)
    rs$machine <- pred
    rs$rationale <- ""; rs$confidence <- NA_real_; rs$off_topic <- FALSE
    how <- sprintf("trained model (%s)", class(scorer)[1])
  }
  rs$machine <- pmin(pmax(round(rs$machine), 0), max_score)
  words <- lengths(strsplit(trimws(rs$response), "\\s+"))
  words[!nzchar(trimws(rs$response))] <- 0L
  r <- p$rules
  rs$routed <- rs$off_topic %in% TRUE | words < r$min_words |
    (!is.na(rs$confidence) & rs$confidence < r$min_confidence) | is.na(rs$machine)
  rs$final <- ifelse(rs$routed, rs$human1, rs$machine)

  agree <- scoring_agreement(rs, r)
  p$open_scores <- as_tbl(rs)
  p$agreement <- agree
  p$scoring <- list(method = how)
  if (add_to_data) p <- open_scores_to_data(p, rs)
  p <- set_scoring_flags(p, scoring_checks(rs, agree, r), person = FALSE)
  p <- set_stage(p, "scoring", "done",
                 sprintf("%d responses to %d items by %s; %d routed to humans", nrow(rs),
                         length(unique(rs$item)), how, sum(rs$routed)))
  p <- stage_rerun(p, "reporting")
  p <- log_event(p, "score open responses", how)
  p <- add_code(p, cl)
  report_stage_flags(p, "scoring")
  p
}

#' Pipeline stage: score test takers
#'
#' Estimates each test taker's ability from the calibrated model with
#' [mirt::fscores()] and checks the scores (thresholds from [mv_rules()]):
#'
#' * `score_reliability` (review): the empirical reliability of the scores is
#'   below `reliability` (the blueprint's target, if one was set).
#' * `extreme_scores` (info): maximum-likelihood estimates that are infinite
#'   (all or none correct) or standard errors above `max_se`.
#'
#' @param p a calibrated pipeline.
#' @param method scoring method passed to [mirt::fscores()]: `"EAP"`,
#'   `"MAP"`, `"ML"` or `"WLE"`.
#' @return The pipeline with `p$scores`, a tibble with one row per test taker
#'   (`id`, `theta`, `se`, and `group` if the data have one).
#' @examples
#' \donttest{
#' p <- calibrate(add_responses(mv_pipeline(), expand.table(LSAT7)), model = "2PL")
#' p <- score_persons(p)
#' head(p$scores)
#' }
#' @export
score_persons <- function(p, method = c("EAP", "MAP", "ML", "WLE")) {
  check_pipeline(p)
  cl <- match.call()
  method <- match.arg(method)
  if (is.null(p$model)) stop("Calibrate the pipeline with calibrate() first.", call. = FALSE)
  enforce_gate(p, "scoring")
  fs <- suppressWarnings(mirt::fscores(p$model, method = method, full.scores.SE = TRUE,
                                       verbose = FALSE))
  th <- fs[, 1]
  se <- fs[, 2]
  if (!is.null(p$link) && p$link$method != "fixed") {
    th <- p$link$A * th + p$link$B
    se <- p$link$A * se
  }
  ok <- is.finite(th) & is.finite(se)
  rel <- if (sum(ok) > 2) {
    v <- stats::var(th[ok])
    v / (v + mean(se[ok]^2))
  } else NA_real_
  sc <- data.frame(id = p$data$id, theta = th, se = se, stringsAsFactors = FALSE)
  if (!is.null(p$data$group)) sc$group <- p$data$group
  r <- p$rules
  out <- list()
  add <- function(...) out[[length(out) + 1L]] <<- new_flag("scoring", ...)
  if (!is.na(rel) && rel < r$reliability)
    add("score_reliability", "scores", sprintf("empirical reliability = %.2f", rel),
        sprintf("reliability >= %s", r$reliability), "review",
        "Scores are less precise than the target; report score bands and consider a longer test.")
  extreme <- !is.finite(th) | (is.finite(se) & se > r$max_se) | !is.finite(se)
  if (any(extreme))
    add("extreme_scores", sprintf("%d test takers", sum(extreme)),
        sprintf("%.1f%% of test takers", 100 * mean(extreme)),
        sprintf("finite estimates with SE <= %s", r$max_se), "info",
        if (method == "ML") "Use EAP or WLE scores, which stay finite for all-correct and all-wrong patterns."
        else "These scores are imprecise; report them with their score band.")
  p$scores <- as_tbl(sc)
  p$score_method <- method
  p <- set_scoring_flags(p, bind_flags(out), person = TRUE)
  p <- set_stage(p, "scoring", "done",
                 sprintf("%s scores for %s test takers, reliability %.2f", method,
                         format(nrow(sc), big.mark = ","), rel))
  p <- stage_rerun(p, "reporting")
  p <- log_event(p, "score persons", method)
  p <- add_code(p, cl)
  report_stage_flags(p, "scoring")
  p
}

# The scoring stage has two parts (open-ended responses and person scores);
# rerunning one keeps the other's flags
person_score_checks <- c("score_reliability", "extreme_scores")

set_scoring_flags <- function(p, new, person) {
  f <- p$flags[p$flags$stage == "scoring", , drop = FALSE]
  other <- f[if (person) !f$check %in% person_score_checks else f$check %in% person_score_checks,
             , drop = FALSE]
  set_stage_flags(p, "scoring", rbind(other, new))
}

# ---- Agreement --------------------------------------------------------------

# quadratic weighted kappa between two integer score vectors
qwk <- function(x, y) {
  ok <- !is.na(x) & !is.na(y)
  x <- x[ok]; y <- y[ok]
  if (length(x) < 2L) return(NA_real_)
  lv <- seq(min(c(x, y)), max(c(x, y)))
  k <- length(lv)
  if (k < 2L) return(NA_real_)
  O <- table(factor(x, lv), factor(y, lv))
  O <- O / sum(O)
  E <- outer(rowSums(O), colSums(O))
  W <- outer(seq_len(k), seq_len(k), function(i, j) (i - j)^2) / (k - 1)^2
  1 - sum(W * O) / sum(W * E)
}

smd <- function(m, h) {
  ok <- !is.na(m) & !is.na(h)
  m <- m[ok]; h <- h[ok]
  if (length(m) < 2L) return(NA_real_)
  s <- sqrt((stats::var(m) + stats::var(h)) / 2)
  if (!is.finite(s) || s == 0) return(0)
  (mean(m) - mean(h)) / s
}

scoring_agreement <- function(rs, r) {
  rows <- lapply(split(rs, rs$item), function(d) {
    dbl <- !is.na(d$human1) & !is.na(d$human2)
    data.frame(item = d$item[1], responses = nrow(d), human_scored = sum(!is.na(d$human1)),
               double_scored = sum(dbl),
               qwk_human = qwk(d$human1, d$human2),
               qwk_machine = qwk(d$machine, d$human1),
               exact_machine = mean((d$machine == d$human1)[!is.na(d$human1)]),
               smd = smd(d$machine, d$human1),
               routed = sum(d$routed), stringsAsFactors = FALSE)
  })
  as_tbl(do.call(rbind, rows))
}

scoring_checks <- function(rs, agree, r) {
  out <- list()
  add <- function(...) out[[length(out) + 1L]] <<- new_flag("scoring", ...)
  a <- as.data.frame(agree)
  few <- a$double_scored < r$n_validation
  add("validation_n", a$item[few], sprintf("%d double-scored responses", a$double_scored[few]),
      sprintf("at least %d double-scored responses", r$n_validation), "review",
      "Have two people score more responses so agreement can be estimated well.")
  hh <- !is.na(a$qwk_human) & a$qwk_human < r$qwk_min
  add("human_agreement", a$item[hh], sprintf("human-human QWK = %.2f", a$qwk_human[hh]),
      sprintf("QWK >= %s", r$qwk_min), "block",
      "The rubric or rater training is not good enough for reliable human scores; fix that before judging the machine.")
  mh <- !is.na(a$qwk_machine) &
    (a$qwk_machine < r$qwk_min | (!is.na(a$qwk_human) & a$qwk_machine < a$qwk_human - r$qwk_drop))
  add("machine_agreement", a$item[mh],
      sprintf("machine-human QWK = %.2f (human-human %s)", a$qwk_machine[mh],
              ifelse(is.na(a$qwk_human[mh]), "n/a", sprintf("%.2f", a$qwk_human[mh]))),
      sprintf("QWK >= %s and within %s of human-human", r$qwk_min, r$qwk_drop), "block",
      "Machine scores do not agree well enough with people; improve the scorer or score this item by hand.")
  big <- !is.na(a$smd) & abs(a$smd) > r$score_smd
  add("score_distribution", a$item[big], sprintf("SMD = %+.2f", a$smd[big]),
      sprintf("|SMD| <= %s", r$score_smd), "review",
      "Machine scores run systematically higher or lower than human scores; recalibrate the scorer.")
  if (any(!is.na(rs$group))) {
    g <- do.call(rbind, lapply(split(rs, list(rs$item, rs$group), drop = TRUE), function(d)
      data.frame(item = d$item[1], group = d$group[1], smd = smd(d$machine, d$human1),
                 stringsAsFactors = FALSE)))
    unfair <- !is.na(g$smd) & abs(g$smd) > r$subgroup_smd
    add("subgroup_fairness", sprintf("%s (%s)", g$item[unfair], g$group[unfair]),
        sprintf("SMD = %+.2f", g$smd[unfair]), sprintf("|SMD| <= %s in every group", r$subgroup_smd),
        "review", "The scorer treats this group differently from human raters; investigate before using its scores.")
  }
  routed <- a$routed > 0
  add("low_confidence", a$item[routed], sprintf("%d responses routed to humans", a$routed[routed]),
      sprintf("on topic, at least %d words, confidence >= %s", r$min_words, r$min_confidence),
      "review", "Have people score these responses; until then their final score is the human score or missing.")
  bind_flags(out)
}

open_scores_to_data <- function(p, rs) {
  if (is.null(p$data)) stop("`add_to_data` needs response data from add_responses().",
                            call. = FALSE)
  wide <- stats::reshape(rs[, c("person", "item", "final")], idvar = "person",
                         timevar = "item", direction = "wide")
  names(wide) <- sub("^final\\.", "", names(wide))
  m <- wide[match(p$data$id, wide$person), setdiff(names(wide), "person"), drop = FALSE]
  if (all(is.na(match(p$data$id, wide$person))))
    stop("No respondent ids in `responses` match the pipeline's data.", call. = FALSE)
  clash <- intersect(names(m), names(p$data$responses))
  p$data$responses[clash] <- NULL
  p$data$responses <- cbind(p$data$responses, m)
  if (!is.null(p$model)) {
    p$model <- NULL; p$link <- NULL; p$forms <- NULL; p$cuts <- NULL
    for (s in c("calibration", "linking", "forms", "cuts"))
      p <- stage_rerun(p, s)
  }
  p
}

llm_score_batch <- function(llm, stem, rubric, responses) {
  r <- as.data.frame(rubric, stringsAsFactors = FALSE)
  chat <- make_chat(llm$provider, llm$model, paste(
    "You are a trained rater scoring test takers' answers to an open-ended item with a rubric.",
    "Score each response against the rubric only, as a careful human rater would. Do not reward length or style that the rubric does not mention.",
    "For each response give the score, a one-sentence rationale citing the rubric, your confidence from 0 to 1, and whether it is off topic or not a real attempt."))
  prompt <- paste(c(
    sprintf("Item: %s", stem), "", "Rubric:",
    sprintf("%s points: %s Example: %s", r$score, r$descriptor, r$anchor), "",
    "Responses:", sprintf("[%d] %s", seq_along(responses), responses)), collapse = "\n")
  res <- chat$chat_structured(prompt, type = ellmer::type_object(
    scores = ellmer::type_array(ellmer::type_object(
      index = ellmer::type_integer("The response number in brackets."),
      score = ellmer::type_integer("The rubric score."),
      rationale = ellmer::type_string("One sentence citing the rubric."),
      confidence = ellmer::type_number("Confidence in the score, 0 to 1."),
      off_topic = ellmer::type_boolean("Off topic or not a real attempt.")))),
    echo = "none")
  s <- res$scores
  if (!is.data.frame(s)) s <- do.call(rbind, lapply(s, as.data.frame))
  s <- s[match(seq_along(responses), s$index), , drop = FALSE]
  data.frame(score = as.numeric(s$score), rationale = as.character(s$rationale),
             confidence = as.numeric(s$confidence), off_topic = as.logical(s$off_topic),
             stringsAsFactors = FALSE)
}
