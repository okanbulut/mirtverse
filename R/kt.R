#' Bayesian knowledge tracing
#'
#' **Experimental.** Fits a Bayesian knowledge tracing (BKT) model to
#' practice logs: Each skill is either known or not known, a student who
#' does not know a skill can learn it after each attempt, and the answers
#' are noisy signals of the hidden state. Where IRT measures ability at one
#' point in time, BKT follows each student's mastery of each skill from one
#' attempt to the next.
#'
#' Each skill has four parameters (Corbett & Anderson, 1995): `prior`, the
#' probability of knowing the skill before the first attempt; `learn`, the
#' probability of moving from not known to known after an attempt; `guess`,
#' the probability of a correct answer without knowing the skill; and
#' `slip`, the probability of a wrong answer while knowing it. The model is
#' fitted by expectation-maximization (the Baum-Welch algorithm) for each
#' skill separately, from several starting values. Two variants follow the
#' pyBKT library (Badrinath et al., 2021; Bulut et al., 2023): `forgets =
#' TRUE` lets a known skill be forgotten, and `multigs = TRUE` gives every
#' item its own guess and slip (the item difficulty effect model, KT-IDEM;
#' Pardos & Heffernan, 2011).
#'
#' With a knowledge graph, items are mapped to skills through the graph's
#' item links; an item linked to several concepts counts as an attempt on
#' each of them. [gg_kt()] then draws mastery on the graph.
#'
#' @param data practice logs in long format: One row per attempt, with a
#'   student id, an item id, the skill (or a knowledge graph in `kg`) and
#'   the answer (1 = correct, 0 = wrong).
#' @param kg optional knowledge graph ([mv_kg_build()]) whose item links
#'   give the skill of each item; used when `data` has no skill column.
#' @param student,item,skill,correct names of the columns of `data`. `item`
#'   is only needed with `kg` or `multigs = TRUE`.
#' @param order optional name of a column (a time, or an attempt number)
#'   that orders each student's attempts; by default the row order is used.
#' @param skills optional skills to fit (default: All).
#' @param forgets logical; let a known skill be forgotten (a `forget`
#'   parameter per skill).
#' @param multigs logical; a guess and a slip per item instead of per skill.
#' @param starts number of starting values per skill; the solution with the
#'   highest log-likelihood is kept.
#' @param max_iter,tol maximum EM iterations and the convergence tolerance
#'   on the log-likelihood.
#' @param seed optional random seed for the starting values.
#' @return An `mv_kt` object: A list with `params` (one row per skill),
#'   `items` (per-item guess and slip with `multigs = TRUE`), `trace` (one
#'   row per attempt, with the predicted probability of a correct answer and
#'   the probability that the skill is known before and after the attempt),
#'   `kg` and `settings`. Use [tidy()][tidy_mv_kt], [glance()][tidy_mv_kt],
#'   [predict()][predict.mv_kt], [mv_kt_cv()] and [gg_kt()].
#' @references
#' Badrinath, A., Wang, F., & Pardos, Z. (2021). pyBKT: An accessible Python
#' library of Bayesian knowledge tracing models. In *Proceedings of the 14th
#' International Conference on Educational Data Mining* (pp. 468-474).
#'
#' Bulut, O., Shin, J., Yildirim-Erbasli, S. N., Gorgun, G., & Pardos, Z. A.
#' (2023). An introduction to Bayesian knowledge tracing with pyBKT.
#' *Psych, 5*(3), 770-786. \doi{10.3390/psych5030050}
#'
#' Corbett, A. T., & Anderson, J. R. (1995). Knowledge tracing: Modeling the
#' acquisition of procedural knowledge. *User Modeling and User-Adapted
#' Interaction, 4*(4), 253-278.
#'
#' Pardos, Z. A., & Heffernan, N. T. (2011). KT-IDEM: Introducing item
#' difficulty to the knowledge tracing model. In *User Modeling, Adaption and
#' Personalization* (pp. 243-254). Springer.
#' @seealso [cognitive_tutor] and [fractions_logs] for example data.
#' @examples
#' kt <- mv_kt_fit(cognitive_tutor, student = "student", skill = "skill",
#'                 correct = "correct", skills = c("Plot pi", "Plot whole number"))
#' kt
#' tidy(kt)
#' glance(kt)
#'
#' # practice logs on the fractions graph
#' kt2 <- mv_kt_fit(fractions_logs, kg = fractions_kg)
#' gg_kt(kt2)
#' @export
mv_kt_fit <- function(data, kg = NULL, student = "student", item = "item", skill = "skill",
                      correct = "correct", order = NULL, skills = NULL, forgets = FALSE,
                      multigs = FALSE, starts = 3, max_iter = 500, tol = 1e-6, seed = NULL) {
  logs <- kt_prepare(data, kg, student, item, skill, correct, order, skills,
                     need_item = multigs)
  if (!is.null(seed)) {
    old <- if (exists(".Random.seed", envir = globalenv())) get(".Random.seed", envir = globalenv())
    on.exit(if (is.null(old)) rm(".Random.seed", envir = globalenv()) else
      assign(".Random.seed", old, envir = globalenv()), add = TRUE)
    set.seed(seed)
  }
  lev <- unique(logs$skill)
  if (!is.null(kg) && !skill %in% names(data)) lev <- intersect(kg_concept_names(kg), lev)
  fits <- lapply(split(logs, factor(logs$skill, levels = lev)), function(d)
    kt_fit_skill(d, forgets = forgets, multigs = multigs, starts = starts,
                 max_iter = max_iter, tol = tol))
  params <- do.call(rbind, lapply(names(fits), function(s) {
    f <- fits[[s]]
    data.frame(skill = s, prior = f$prior, learn = f$learn, forget = f$forget,
               guess = if (multigs) NA_real_ else f$guess[1],
               slip = if (multigs) NA_real_ else f$slip[1],
               n_students = f$n_students, n_attempts = f$n_attempts,
               loglik = f$loglik, iterations = f$iter, converged = f$converged,
               stringsAsFactors = FALSE)
  }))
  items <- if (multigs) do.call(rbind, lapply(names(fits), function(s) {
    f <- fits[[s]]
    data.frame(skill = s, item = f$item_levels, guess = f$guess, slip = f$slip,
               n = f$item_n, stringsAsFactors = FALSE)
  }))
  out <- list(params = as_tbl(params), items = if (!is.null(items)) as_tbl(items),
              trace = NULL, kg = kg,
              settings = list(forgets = forgets, multigs = multigs, starts = starts,
                              columns = c(student = student, item = item, skill = skill,
                                          correct = correct)))
  class(out) <- "mv_kt"
  out$trace <- kt_filter(out, logs)
  out
}

# Logs as a data frame with columns student, item, skill, correct, in each
# student's order; items linked to several concepts are repeated.
kt_prepare <- function(data, kg, student, item, skill, correct, order, skills, need_item) {
  if (!is.data.frame(data)) stop("`data` must be a data frame of practice logs.", call. = FALSE)
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  need <- c(student, correct, if (!is.null(order)) order)
  miss <- setdiff(need, names(data))
  if (length(miss)) stop("`data` has no column ", paste(miss, collapse = ", "), ".", call. = FALSE)
  has_item <- item %in% names(data)
  ord <- if (is.null(order)) seq_len(nrow(data)) else data[[order]]
  if (!is.null(kg) && !skill %in% names(data)) {
    check_kg(kg)
    if (!has_item) stop("Mapping items to skills with `kg` needs the item column `", item, "`.",
                        call. = FALSE)
    meas <- as.data.frame(kg$edges, stringsAsFactors = FALSE)
    meas <- meas[meas$type == "measures", , drop = FALSE]
    unknown <- setdiff(unique(as.character(data[[item]])), meas$from)
    if (length(unknown))
      warning(sprintf("%d item(s) are not in the graph and were skipped: %s.", length(unknown),
                      paste(utils::head(unknown, 5), collapse = ", ")), call. = FALSE)
    m <- merge(data.frame(.row = seq_len(nrow(data)), .item = as.character(data[[item]]), stringsAsFactors = FALSE),
               data.frame(.item = meas$from, .skill = meas$to, stringsAsFactors = FALSE),
               by = ".item", sort = FALSE)
    m <- m[order(m$.row, match(m$.skill, kg_concept_names(kg))), , drop = FALSE]
    logs <- data.frame(student = as.character(data[[student]][m$.row]), item = m$.item,
                       skill = m$.skill, correct = data[[correct]][m$.row], .ord = ord[m$.row],
                       .row = m$.row, stringsAsFactors = FALSE)
  } else {
    if (!skill %in% names(data))
      stop("`data` has no skill column `", skill, "`; name it with `skill` or give a knowledge graph in `kg`.",
           call. = FALSE)
    if (need_item && !has_item)
      stop("`multigs = TRUE` needs the item column `", item, "`.", call. = FALSE)
    logs <- data.frame(student = as.character(data[[student]]),
                       item = if (has_item) as.character(data[[item]]) else NA_character_,
                       skill = as.character(data[[skill]]), correct = data[[correct]],
                       .ord = ord, .row = seq_len(nrow(data)), stringsAsFactors = FALSE)
  }
  y <- logs$correct
  if (is.logical(y)) y <- as.integer(y)
  if (!is.numeric(y) || any(!is.na(y) & !y %in% c(0, 1)))
    stop("`", correct, "` must be scored 0/1.", call. = FALSE)
  logs$correct <- as.integer(y)
  logs <- logs[!is.na(logs$correct) & !is.na(logs$skill) & !is.na(logs$student), , drop = FALSE]
  if (!is.null(skills)) {
    bad <- setdiff(skills, logs$skill)
    if (length(bad)) stop("Unknown skills: ", paste(bad, collapse = ", "), ".", call. = FALSE)
    logs <- logs[logs$skill %in% skills, , drop = FALSE]
  }
  if (!nrow(logs)) stop("No attempts left to fit.", call. = FALSE)
  logs <- logs[order(match(logs$student, unique(logs$student)), logs$.ord, logs$.row), , drop = FALSE]
  rownames(logs) <- NULL
  logs
}

# One skill's attempts as student x step matrices.
kt_matrices <- function(d, item_levels = NULL) {
  st <- factor(d$student, levels = unique(d$student))
  step <- stats::ave(seq_len(nrow(d)), st, FUN = seq_along)
  S <- nlevels(st); Tm <- max(step)
  Y <- matrix(NA_integer_, S, Tm); I <- matrix(1L, S, Tm)
  Y[cbind(as.integer(st), step)] <- d$correct
  if (!is.null(item_levels)) I[cbind(as.integer(st), step)] <- match(d$item, item_levels)
  list(Y = Y, I = I, M = !is.na(Y), st = st, step = step)
}

# Forward pass (scaled); returns the filtered and predicted P(known).
kt_forward <- function(Y, I, M, prior, learn, forget, guess, slip) {
  S <- nrow(Y); Tm <- ncol(Y)
  g <- matrix(guess[I], S, Tm); s <- matrix(slip[I], S, Tm)
  e1 <- ifelse(M, ifelse(Y == 1L, 1 - s, s), 1)
  e0 <- ifelse(M, ifelse(Y == 1L, g, 1 - g), 1)
  pred <- filt <- cc <- matrix(1, S, Tm)
  p1 <- rep(prior, S)
  for (t in seq_len(Tm)) {
    if (t > 1) p1 <- filt[, t - 1] * (1 - forget) + (1 - filt[, t - 1]) * learn
    pred[, t] <- p1
    a1 <- p1 * e1[, t]; a0 <- (1 - p1) * e0[, t]
    cc[, t] <- a1 + a0
    filt[, t] <- a1 / cc[, t]
  }
  list(pred = pred, filt = filt, cc = cc, e0 = e0, e1 = e1)
}

kt_em <- function(Y, I, M, n_items, start, forgets, multigs, max_iter, tol) {
  prior <- start$prior; learn <- start$learn; forget <- if (forgets) start$forget else 0
  guess <- rep(start$guess, n_items); slip <- rep(start$slip, n_items)
  S <- nrow(Y); Tm <- ncol(Y)
  ll_old <- -Inf; conv <- FALSE; it <- 0L
  Yz <- ifelse(M, Y, 0L)
  for (it in seq_len(max_iter)) {
    f <- kt_forward(Y, I, M, prior, learn, forget, guess, slip)
    ll <- sum(log(f$cc[M]))
    # backward pass on the scaled quantities
    b1 <- b0 <- matrix(1, S, Tm)
    if (Tm > 1) for (t in (Tm - 1):1) {
      m <- M[, t + 1]
      n1 <- f$e1[, t + 1] * b1[, t + 1] / f$cc[, t + 1]
      n0 <- f$e0[, t + 1] * b0[, t + 1] / f$cc[, t + 1]
      b0[, t] <- ifelse(m, (1 - learn) * n0 + learn * n1, 1)
      b1[, t] <- ifelse(m, forget * n0 + (1 - forget) * n1, 1)
    }
    g1 <- f$filt * b1; g0 <- (1 - f$filt) * b0
    tot <- g1 + g0; g1 <- g1 / tot; g0 <- g0 / tot
    g1[!M] <- 0; g0[!M] <- 0
    if (Tm > 1) {
      nx <- M[, -1, drop = FALSE]
      n1 <- f$e1[, -1, drop = FALSE] * b1[, -1, drop = FALSE] / f$cc[, -1, drop = FALSE]
      n0 <- f$e0[, -1, drop = FALSE] * b0[, -1, drop = FALSE] / f$cc[, -1, drop = FALSE]
      a1 <- f$filt[, -Tm, drop = FALSE]; a0 <- 1 - a1
      x01 <- sum((a0 * learn * n1)[nx]); x00 <- sum((a0 * (1 - learn) * n0)[nx])
      x10 <- sum((a1 * forget * n0)[nx]); x11 <- sum((a1 * (1 - forget) * n1)[nx])
      learn <- kt_clip(x01 / (x01 + x00))
      if (forgets) forget <- kt_clip(x10 / (x10 + x11))
    }
    prior <- kt_clip(mean(g1[, 1]))
    if (multigs) {
      fI <- factor(I, levels = seq_len(n_items))
      num_g <- tapply(g0 * Yz, fI, sum)
      den_g <- tapply(g0, fI, sum)
      num_s <- tapply(g1 * (1 - Yz) * M, fI, sum)
      den_s <- tapply(g1, fI, sum)
      # pseudo-counts pull rarely seen items toward the skill's value
      gs <- sum(g0 * Yz) / sum(g0); ss <- sum(g1 * (1 - Yz) * M) / sum(g1)
      num_g[is.na(num_g)] <- 0; den_g[is.na(den_g)] <- 0
      num_s[is.na(num_s)] <- 0; den_s[is.na(den_s)] <- 0
      guess <- kt_clip((num_g + gs) / (den_g + 1), hi = 0.5)
      slip <- kt_clip((num_s + ss) / (den_s + 1), hi = 0.5)
    } else {
      guess <- rep(kt_clip(sum(g0 * Yz) / sum(g0), hi = 0.5), n_items)
      slip <- rep(kt_clip(sum(g1 * (1 - Yz) * M) / sum(g1), hi = 0.5), n_items)
    }
    if (abs(ll - ll_old) < tol * max(1, abs(ll))) { conv <- TRUE; break }
    ll_old <- ll
  }
  f <- kt_forward(Y, I, M, prior, learn, forget, guess, slip)
  list(prior = prior, learn = learn, forget = forget, guess = unname(as.numeric(guess)),
       slip = unname(as.numeric(slip)), loglik = sum(log(f$cc[M])), iter = it, converged = conv)
}

kt_clip <- function(x, lo = 1e-4, hi = 1 - 1e-4) pmin(pmax(x, lo), hi)

kt_fit_skill <- function(d, forgets, multigs, starts, max_iter, tol) {
  item_levels <- if (multigs) unique(d$item) else NULL
  mm <- kt_matrices(d, item_levels)
  n_items <- if (multigs) length(item_levels) else 1L
  best <- NULL
  for (k in seq_len(max(1, starts))) {
    start <- if (k == 1) list(prior = 0.3, learn = 0.15, forget = 0.02, guess = 0.2, slip = 0.1) else
      list(prior = stats::runif(1, 0.05, 0.7), learn = stats::runif(1, 0.02, 0.4),
           forget = stats::runif(1, 0, 0.1), guess = stats::runif(1, 0.05, 0.35),
           slip = stats::runif(1, 0.02, 0.25))
    fit <- kt_em(mm$Y, mm$I, mm$M, n_items, start, forgets, multigs, max_iter, tol)
    if (is.null(best) || fit$loglik > best$loglik + 1e-8) best <- fit
  }
  best$item_levels <- item_levels
  best$item_n <- if (multigs) as.integer(table(factor(d$item, levels = item_levels)))
  best$n_students <- nrow(mm$Y)
  best$n_attempts <- nrow(d)
  best
}

# Runs the fitted model over logs: Predicted P(correct) before each
# attempt and P(known) before and after it.
kt_filter <- function(kt, logs) {
  out <- lapply(split(logs, factor(logs$skill, levels = unique(logs$skill))), function(d) {
    p <- kt$params[kt$params$skill == d$skill[1], , drop = FALSE]
    if (!nrow(p)) return(NULL)
    if (kt$settings$multigs) {
      it <- kt$items[kt$items$skill == d$skill[1], , drop = FALSE]
      lev <- c(it$item, setdiff(unique(d$item), it$item))
      # items not seen in fitting get the mean guess and slip of the skill
      guess <- c(it$guess, rep(mean(it$guess), length(lev) - nrow(it)))
      slip <- c(it$slip, rep(mean(it$slip), length(lev) - nrow(it)))
    } else {
      lev <- NULL; guess <- p$guess; slip <- p$slip
    }
    mm <- kt_matrices(d, lev)
    f <- kt_forward(mm$Y, mm$I, mm$M, p$prior, p$learn, p$forget, guess, slip)
    idx <- cbind(as.integer(mm$st), mm$step)
    gi <- guess[mm$I[idx]]; si <- slip[mm$I[idx]]
    pk <- f$pred[idx]
    data.frame(student = d$student, skill = d$skill, item = d$item, step = mm$step,
               correct = d$correct, p_known_before = pk,
               p_correct = pk * (1 - si) + (1 - pk) * gi, p_known = f$filt[idx],
               .row = d$.row, stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, out)
  out <- out[order(match(out$student, unique(logs$student)), out$.row), , drop = FALSE]
  out$.row <- NULL
  as_tbl(out)
}

kt_metrics <- function(y, p) {
  ok <- !is.na(y) & !is.na(p)
  y <- y[ok]; p <- p[ok]
  n1 <- sum(y == 1); n0 <- sum(y == 0)
  auc <- if (n1 && n0) (sum(rank(p)[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0) else NA_real_
  c(rmse = sqrt(mean((y - p)^2)), accuracy = mean((p >= 0.5) == (y == 1)), auc = auc)
}

#' @export
print.mv_kt <- function(x, ...) {
  s <- x$settings
  variant <- c(if (s$forgets) "forgets", if (s$multigs) "item guess and slip")
  cat(sprintf("<mv_kt> (EXPERIMENTAL) Bayesian knowledge tracing%s\n",
              if (length(variant)) paste0(" with ", paste(variant, collapse = " and ")) else ""))
  g <- glance(x)
  cat(sprintf("%d skill(s), %d student(s), %d attempt(s)\n", g$n_skills, g$n_students, g$n_attempts))
  p <- as.data.frame(x$params)
  show <- p[c("skill", "prior", "learn", if (s$forgets) "forget", if (!s$multigs) c("guess", "slip"))]
  num <- vapply(show, is.numeric, logical(1))
  show[num] <- lapply(show[num], round, 3)
  print(show, row.names = FALSE)
  cat(sprintf("Fit on the same logs: RMSE %.3f, accuracy %.3f, AUC %.3f\n", g$rmse, g$accuracy, g$auc))
  if (any(!p$converged)) cat("Not converged: ", paste(p$skill[!p$converged], collapse = ", "), "\n", sep = "")
  invisible(x)
}

#' Tidy a knowledge tracing model
#'
#' @param x an `mv_kt` object from [mv_kt_fit()].
#' @param what `"parameters"` (one row per skill, the default), `"items"`
#'   (per-item guess and slip of a `multigs` model), `"trace"` (one row per
#'   attempt) or `"mastery"` (each student's probability of knowing each
#'   skill after their last attempt).
#' @param ... unused.
#' @return A tibble. `glance()` returns the numbers of skills, students and
#'   attempts, the log-likelihood, AIC and BIC, and the RMSE, accuracy and
#'   AUC of the one-step-ahead predictions on the logs the model was fitted
#'   to (use [mv_kt_cv()] for new students).
#' @name tidy_mv_kt
#' @export
tidy.mv_kt <- function(x, what = c("parameters", "items", "trace", "mastery"), ...) {
  what <- match.arg(what)
  switch(what,
    parameters = x$params,
    items = {
      if (is.null(x$items)) stop("Item guess and slip need `multigs = TRUE`.", call. = FALSE)
      x$items
    },
    trace = x$trace,
    mastery = {
      tr <- as.data.frame(x$trace)
      last <- !duplicated(paste(tr$student, tr$skill), fromLast = TRUE)
      tr <- tr[last, c("student", "skill", "step", "p_known"), drop = FALSE]
      names(tr)[3] <- "attempts"
      as_tbl(tr)
    })
}

#' @rdname tidy_mv_kt
#' @export
glance.mv_kt <- function(x, ...) {
  p <- x$params
  k <- nrow(p) * (3 + x$settings$forgets) +
    if (x$settings$multigs) 2 * nrow(x$items) else 2 * nrow(p)
  n <- sum(p$n_attempts)
  m <- kt_metrics(x$trace$correct, x$trace$p_correct)
  ll <- sum(p$loglik)
  as_tbl(data.frame(n_skills = nrow(p), n_students = length(unique(x$trace$student)),
                    n_attempts = n, loglik = ll, AIC = -2 * ll + 2 * k,
                    BIC = -2 * ll + log(n) * k, rmse = m[["rmse"]], accuracy = m[["accuracy"]],
                    auc = m[["auc"]]))
}

#' Predict answers with a knowledge tracing model
#'
#' Runs a fitted model over new practice logs: Before each attempt, the
#' probability that the student knows the skill and the predicted
#' probability of a correct answer, using only the student's earlier
#' attempts; after it, the updated probability of knowing the skill.
#'
#' @param object an `mv_kt` object from [mv_kt_fit()].
#' @param newdata practice logs with the same columns as the logs the model
#'   was fitted to (by default, those logs).
#' @param ... unused.
#' @return A tibble with one row per attempt: `student`, `skill`, `item`,
#'   `step`, `correct`, `p_known_before`, `p_correct` and `p_known`.
#'   Attempts on skills the model has not seen are dropped.
#' @examples
#' kt <- mv_kt_fit(cognitive_tutor, skills = "Plot pi")
#' head(predict(kt))
#' @export
predict.mv_kt <- function(object, newdata = NULL, ...) {
  if (is.null(newdata)) return(object$trace)
  cols <- object$settings$columns
  logs <- kt_prepare(newdata, object$kg, cols[["student"]], cols[["item"]], cols[["skill"]],
                     cols[["correct"]], NULL, NULL, need_item = object$settings$multigs)
  logs <- logs[logs$skill %in% object$params$skill, , drop = FALSE]
  if (!nrow(logs)) stop("`newdata` has no attempts on the skills of the model.", call. = FALSE)
  kt_filter(object, logs)
}

#' Cross-validate a knowledge tracing model
#'
#' Splits the students into folds, fits [mv_kt_fit()] on the other folds and
#' predicts each held-out student's answers one attempt ahead, as pyBKT's
#' `crossvalidate()` does. This shows how well the model predicts new
#' students, which the fit on the same logs overstates.
#'
#' @param data,... practice logs and the arguments of [mv_kt_fit()].
#' @param folds number of folds.
#' @param seed optional random seed for the folds and the starting values.
#' @return A tibble with one row per skill and fold: `skill`, `fold`,
#'   `rmse`, `accuracy` and `auc`, plus a `"mean"` row per skill.
#' @examples
#' \donttest{
#' mv_kt_cv(cognitive_tutor, skills = c("Plot pi", "Plot whole number"), folds = 3, seed = 1)
#' }
#' @export
mv_kt_cv <- function(data, ..., folds = 5, seed = NULL) {
  args <- list(...)
  student <- args$student %||% "student"
  if (!student %in% names(data)) stop("`data` has no column ", student, ".", call. = FALSE)
  if (!is.null(seed)) {
    old <- if (exists(".Random.seed", envir = globalenv())) get(".Random.seed", envir = globalenv())
    on.exit(if (is.null(old)) rm(".Random.seed", envir = globalenv()) else
      assign(".Random.seed", old, envir = globalenv()), add = TRUE)
    set.seed(seed)
  }
  ids <- unique(as.character(data[[student]]))
  if (folds < 2 || folds > length(ids)) stop("`folds` must be between 2 and the number of students.",
                                             call. = FALSE)
  fold_of <- stats::setNames(sample(rep_len(seq_len(folds), length(ids))), ids)
  res <- list()
  for (k in seq_len(folds)) {
    test <- fold_of[as.character(data[[student]])] == k
    fit <- do.call(mv_kt_fit, c(list(data = data[!test, , drop = FALSE]), args))
    pr <- tryCatch(stats::predict(fit, data[test, , drop = FALSE]), error = function(e) NULL)
    if (is.null(pr)) next
    for (s in unique(pr$skill)) {
      m <- kt_metrics(pr$correct[pr$skill == s], pr$p_correct[pr$skill == s])
      res[[length(res) + 1]] <- data.frame(skill = s, fold = as.character(k), rmse = m[["rmse"]],
                                           accuracy = m[["accuracy"]], auc = m[["auc"]],
                                           stringsAsFactors = FALSE)
    }
  }
  out <- do.call(rbind, res)
  means <- do.call(rbind, lapply(split(out, factor(out$skill, levels = unique(out$skill))), function(d)
    data.frame(skill = d$skill[1], fold = "mean", rmse = mean(d$rmse), accuracy = mean(d$accuracy),
               auc = mean(d$auc, na.rm = TRUE), stringsAsFactors = FALSE)))
  out <- rbind(out, means)
  out <- out[order(match(out$skill, unique(out$skill))), , drop = FALSE]
  as_tbl(out)
}

#' Plot knowledge tracing results
#'
#' **Experimental.** Three views of a model from [mv_kt_fit()]:
#'
#' * `type = "curve"` with no `student`: Learning curves, the mean
#'   probability of knowing each skill and the proportion of correct answers
#'   at each attempt number.
#' * `type = "curve"` with a `student`: That student's probability of
#'   knowing each skill after every attempt, with the answers as points
#'   (filled = correct).
#' * `type = "graph"`: The knowledge graph with each concept shaded by the
#'   probability of knowing it after the last attempt, for one student or
#'   on average over all students.
#'
#' @param kt an `mv_kt` object from [mv_kt_fit()].
#' @param student optional student id.
#' @param skills optional skills to show (curves only).
#' @param type `"curve"` (the default) or `"graph"`.
#' @param kg the knowledge graph for `type = "graph"`; by default the graph
#'   the model was fitted with.
#' @param max_attempts for learning curves, the last attempt number shown.
#' @return A ggplot object.
#' @examples
#' kt <- mv_kt_fit(fractions_logs, kg = fractions_kg)
#' gg_kt(kt)
#' gg_kt(kt, student = "P001")
#' gg_kt(kt, student = "P001", type = "graph")
#' @export
gg_kt <- function(kt, student = NULL, skills = NULL, type = c("curve", "graph"), kg = NULL,
                  max_attempts = 20) {
  if (!inherits(kt, "mv_kt")) stop("`kt` must be a model from mv_kt_fit().", call. = FALSE)
  type <- match.arg(type)
  tr <- as.data.frame(kt$trace, stringsAsFactors = FALSE)
  if (!is.null(student)) {
    if (length(student) != 1 || !student %in% tr$student)
      stop("Unknown student: ", paste(student, collapse = ", "), ".", call. = FALSE)
    tr <- tr[tr$student == student, , drop = FALSE]
  }
  if (type == "graph") {
    kg <- kg %||% kt$kg
    if (is.null(kg)) stop("`type = \"graph\"` needs a knowledge graph: Fit with `kg` or give one in `kg`.",
                          call. = FALSE)
    check_kg(kg)
    m <- as.data.frame(tidy(kt, "mastery"))
    if (!is.null(student)) m <- m[m$student == student, , drop = FALSE]
    val <- tapply(m$p_known, m$skill, mean)
    val <- val[names(val) %in% kg_concept_names(kg)]
    if (!length(val)) stop("None of the model's skills are concepts of the graph.", call. = FALSE)
    p <- kg_plot(kg, items = FALSE, labels = "label", concept_value = val)$plot
    sub <- if (is.null(student)) "Mean probability of knowing each concept after the last attempt" else
      sprintf("Student %s: Probability of knowing each concept after the last attempt", student)
    return(p + ggplot2::labs(subtitle = sub))
  }
  if (!is.null(skills)) {
    bad <- setdiff(skills, tr$skill)
    if (length(bad)) stop("Unknown skills: ", paste(bad, collapse = ", "), ".", call. = FALSE)
    tr <- tr[tr$skill %in% skills, , drop = FALSE]
  }
  tr$skill <- factor(tr$skill, levels = unique(kt$params$skill[kt$params$skill %in% tr$skill]))
  pal <- kt_palette(nlevels(tr$skill))
  if (is.null(student)) {
    tr <- tr[tr$step <= max_attempts, , drop = FALSE]
    agg <- stats::aggregate(cbind(p_known_before, correct, p_correct) ~ skill + step, data = tr, FUN = mean)
    agg$n <- stats::aggregate(correct ~ skill + step, data = tr, FUN = length)$correct
    agg <- agg[agg$n >= 5, , drop = FALSE]
    ggplot2::ggplot(agg, ggplot2::aes(x = step, colour = skill)) +
      ggplot2::geom_line(ggplot2::aes(y = p_known_before), linewidth = 0.8) +
      ggplot2::geom_point(ggplot2::aes(y = correct), size = 1.4, alpha = 0.7) +
      ggplot2::scale_colour_manual(values = pal, name = NULL) +
      ggplot2::scale_y_continuous(limits = c(0, 1)) +
      ggplot2::labs(x = "Attempt on the skill", y = "Probability",
                    title = "Learning curves",
                    subtitle = "Lines: Mean probability of knowing the skill before the attempt; points: Proportion correct") +
      theme_mirtverse()
  } else {
    ggplot2::ggplot(tr, ggplot2::aes(x = step, y = p_known, colour = skill)) +
      ggplot2::geom_hline(yintercept = 0.95, linetype = "dotted", colour = "grey60") +
      ggplot2::geom_line(linewidth = 0.8) +
      ggplot2::geom_point(ggplot2::aes(shape = factor(correct, levels = c(0, 1))), size = 2) +
      ggplot2::scale_shape_manual(values = c(`0` = 1, `1` = 16), labels = c("wrong", "correct"),
                                  name = NULL, drop = FALSE) +
      ggplot2::scale_colour_manual(values = pal, name = NULL) +
      ggplot2::scale_y_continuous(limits = c(0, 1)) +
      ggplot2::labs(x = "Attempt on the skill", y = "Probability of knowing the skill",
                    title = sprintf("Student %s", student),
                    subtitle = "After each attempt; the dotted line marks 0.95, a common mastery cut") +
      theme_mirtverse()
  }
}

kt_palette <- function(n) {
  base <- c(unname(mv_colours[c("primary", "accent", "good", "warn")]), "#6A4C93", "#1B998B",
            "#8D6346", "#5DA9E9", "#C05299", "#7A7A7A", "#B5A33A", "#3D405B")
  rep(base, length.out = n)
}
