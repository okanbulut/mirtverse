#' Train an automated scorer on human-scored text
#'
#' Fits a simple, transparent automated scoring engine: A ridge regression
#' of human scores on the words of the responses ("bag of words"). It runs
#' in base R with no internet connection and no API key, so it suits
#' teaching and small programs, and it plugs straight into [score_open()]
#' through its [predict()] method.
#'
#' Each response is turned into counts of its words and, with `ngrams = 1:2`,
#' of its two-word phrases, kept when they appear in at least `min_docs`
#' training responses. The counts enter as `log(1 + count)`. With
#' `length = TRUE` the log of the number of words is added as a feature,
#' as many commercial engines do. The ridge penalty `lambda` is chosen by
#' `folds`-fold cross-validation unless you give it, and the
#' cross-validated predictions are kept, so the scorer's agreement with
#' people can be judged on responses it was not trained on (see
#' [agreement_report()]).
#'
#' A ridge regression treats scoring as prediction: It learns which words go
#' with high human scores in the training responses, whatever the reason.
#' Words that signal a key idea help, but so can words that merely go with
#' longer or more fluent answers. That is why the scorer's agreement must be
#' checked overall and within groups before its scores are used.
#'
#' @param data a data frame with one row per human-scored response.
#' @param response,score names of the columns that hold the response text
#'   and the human score used for training.
#' @param by optional name of a column (such as the prompt or item) to train
#'   a separate scorer for each of its values.
#' @param ngrams `1` for single words, `1:2` to add two-word phrases.
#' @param length logical; add the log number of words as a feature.
#' @param min_docs smallest number of training responses a word must appear
#'   in to be used.
#' @param lambda the ridge penalty; `NULL` chooses it by cross-validation.
#' @param folds number of cross-validation folds.
#' @param seed random seed for the fold split, or `NULL`.
#' @return An object of class `mv_scorer`: A list with one model per value
#'   of `by` (`models`), the settings, and `cv`, a tibble of out-of-fold
#'   predictions for the training responses (`row`, `by`, `human`,
#'   `predicted`, `machine`). Use [predict()] to score new responses,
#'   [tidy()] for the word weights, and [agreement_report()] to check it.
#' @seealso [score_open()] to use the scorer in an assessment pipeline,
#'   [agreement_report()] to check it; the
#'   [AI Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.html).
#' @examples
#' e1 <- essays[essays$prompt == "E1", ]
#' s <- train_scorer(e1, response = "response", score = "human1")
#' s
#' head(tidy(s))
#' predict(s, c("Ice is less dense than water, so it floats.", "I don't know."))
#' @export
train_scorer <- function(data, response = "response", score = "human1", by = NULL,
                         ngrams = 1:2, length = FALSE, min_docs = 3, lambda = NULL,
                         folds = 5, seed = 1) {
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  for (nm in c(response, score, by))
    if (!nm %in% names(data)) stop(sprintf("`data` has no column `%s`.", nm), call. = FALSE)
  if (!all(ngrams %in% 1:2)) stop("`ngrams` must be 1 or 1:2.", call. = FALSE)
  y <- suppressWarnings(as.numeric(data[[score]]))
  keep <- !is.na(y) & !is.na(data[[response]])
  if (sum(keep) < 20) stop("Train the scorer on at least 20 human-scored responses.", call. = FALSE)
  if (!is.null(seed)) {
    old <- if (exists(".Random.seed", globalenv())) get(".Random.seed", globalenv()) else NULL
    on.exit(if (is.null(old)) rm(".Random.seed", envir = globalenv())
            else assign(".Random.seed", old, envir = globalenv()), add = TRUE)
    set.seed(seed)
  }
  key <- if (is.null(by)) rep("all", nrow(data)) else as.character(data[[by]])
  models <- list()
  cv <- list()
  for (k in unique(key[keep])) {
    rows <- which(keep & key == k)
    fit <- fit_ridge_scorer(as.character(data[[response]][rows]), y[rows], ngrams = ngrams,
                            length = length, min_docs = min_docs, lambda = lambda,
                            folds = folds)
    models[[k]] <- fit$model
    cv[[k]] <- data.frame(row = rows, by = k, human = y[rows], predicted = fit$cv,
                          machine = round_score(fit$cv, fit$model$range),
                          stringsAsFactors = FALSE)
  }
  cv <- do.call(rbind, cv)
  rownames(cv) <- NULL
  structure(list(models = models, response = response, score = score, by = by,
                 settings = list(ngrams = ngrams, length = length, min_docs = min_docs,
                                 folds = folds),
                 cv = as_tbl(cv[order(cv$row), ])),
            class = "mv_scorer")
}

#' @export
print.mv_scorer <- function(x, ...) {
  cat("<mv_scorer> ridge regression on ", if (identical(x$settings$ngrams, 1)) "words"
      else "words and two-word phrases", if (x$settings$length) " plus response length", "\n",
      sep = "")
  for (k in names(x$models)) {
    m <- x$models[[k]]
    cv <- x$cv[x$cv$by == k, ]
    cat(sprintf("  %s%d responses, %d features, lambda = %s, cross-validated RMSE = %.2f, QWK = %.2f\n",
                if (is.null(x$by)) "" else paste0(k, ": "), m$n, length(m$beta),
                format(signif(m$lambda, 3)), m$cv_rmse, qwk(cv$machine, cv$human)))
  }
  cat("Check it with agreement_report(); use it with predict() or score_open().\n")
  invisible(x)
}

#' Score new responses with a trained scorer
#'
#' @param object a scorer from [train_scorer()].
#' @param newdata a character vector of responses, or a data frame with the
#'   response column used in training (or a column `response`, as in
#'   [score_open()]). When the scorer was trained with `by`, the data frame
#'   needs that column, or a column `item` with the same values.
#' @param type `"score"` for whole-number scores within the training range,
#'   `"raw"` for the unrounded predictions.
#' @param ... not used.
#' @return A numeric vector with one score per response.
#' @export
predict.mv_scorer <- function(object, newdata, type = c("score", "raw"), ...) {
  type <- match.arg(type)
  if (is.data.frame(newdata)) {
    col <- if (object$response %in% names(newdata)) object$response else "response"
    if (!col %in% names(newdata))
      stop(sprintf("`newdata` needs a column `%s`.", object$response), call. = FALSE)
    text <- as.character(newdata[[col]])
    key <- if (is.null(object$by)) rep("all", nrow(newdata)) else {
      bcol <- if (object$by %in% names(newdata)) object$by else if ("item" %in% names(newdata))
        "item" else stop(sprintf("`newdata` needs a column `%s` (or `item`).", object$by),
                         call. = FALSE)
      as.character(newdata[[bcol]])
    }
  } else {
    text <- as.character(newdata)
    if (!is.null(object$by) && length(object$models) > 1)
      stop("This scorer has one model per ", object$by, "; give a data frame with that column.",
           call. = FALSE)
    key <- rep(names(object$models)[1], length(text))
  }
  unknown <- setdiff(unique(key), names(object$models))
  if (length(unknown))
    stop("No scorer was trained for: ", paste(unknown, collapse = ", "), call. = FALSE)
  out <- rep(NA_real_, length(text))
  for (k in unique(key)) {
    i <- which(key == k)
    m <- object$models[[k]]
    pred <- predict_ridge(m, text[i])
    out[i] <- if (type == "score") round_score(pred, m$range) else pred
  }
  out[is.na(text)] <- NA_real_
  out
}

#' @rdname train_scorer
#' @param x a scorer from [train_scorer()].
#' @param ... not used.
#' @return `tidy()` returns a tibble with one row per feature and model:
#'   `by`, `term` and `weight`, the change in the predicted score for one
#'   more use of the word (on the `log(1 + count)` scale), sorted from the
#'   largest positive weight.
#' @export
tidy.mv_scorer <- function(x, ...) {
  out <- do.call(rbind, lapply(names(x$models), function(k) {
    m <- x$models[[k]]
    data.frame(by = k, term = names(m$beta), weight = unname(m$beta), stringsAsFactors = FALSE)
  }))
  out <- out[order(out$by, -out$weight), ]
  rownames(out) <- NULL
  as_tbl(out)
}

# ---- engine -------------------------------------------------------------------

tokens <- function(text, ngrams = 1:2) {
  w <- strsplit(trimws(gsub("[^a-z0-9']+", " ", tolower(text))), "\\s+")
  w <- lapply(w, function(x) x[nzchar(x)])
  if (2 %in% ngrams)
    w <- lapply(w, function(x) c(if (1 %in% ngrams) x,
                                 if (length(x) > 1) paste(x[-length(x)], x[-1])))
  w
}

dtm <- function(tok, vocab) {
  X <- matrix(0, length(tok), length(vocab), dimnames = list(NULL, vocab))
  for (i in seq_along(tok)) {
    tab <- table(tok[[i]][tok[[i]] %in% vocab])
    if (length(tab)) X[i, names(tab)] <- log1p(as.numeric(tab))
  }
  X
}

n_words <- function(text) {
  n <- lengths(strsplit(trimws(text), "\\s+"))
  n[!nzchar(trimws(text))] <- 0L
  n
}

features <- function(text, m) {
  X <- dtm(tokens(text, m$ngrams), m$vocab)
  if (m$length) X <- cbind(X, `(length)` = log1p(n_words(text)))
  X
}

# ridge coefficients for centred X and y for several lambdas, by SVD
ridge_path <- function(X, y, lambdas) {
  s <- svd(X)
  uy <- crossprod(s$u, y)
  vapply(lambdas, function(l) as.numeric(s$v %*% (s$d / (s$d^2 + l) * uy)),
         numeric(ncol(X)))
}

fit_ridge_scorer <- function(text, y, ngrams, length, min_docs, lambda, folds) {
  tok <- tokens(text, ngrams)
  df <- table(unlist(lapply(tok, unique)))
  vocab <- sort(names(df)[df >= min_docs])
  if (!length(vocab)) stop("No word appears in `min_docs` responses; lower `min_docs`.",
                           call. = FALSE)
  m <- list(vocab = vocab, ngrams = ngrams, length = length)
  X <- features(text, m)
  n <- nrow(X)
  lambdas <- if (is.null(lambda)) 10^seq(-1, 3, length.out = 25) else lambda
  fold <- sample(rep(seq_len(folds), length.out = n))
  cv_pred <- matrix(NA_real_, n, length(lambdas))
  for (f in seq_len(folds)) {
    tr <- fold != f
    mx <- colMeans(X[tr, , drop = FALSE]); my <- mean(y[tr])
    B <- ridge_path(sweep(X[tr, , drop = FALSE], 2, mx), y[tr] - my, lambdas)
    cv_pred[!tr, ] <- sweep(X[!tr, , drop = FALSE], 2, mx) %*% B + my
  }
  rmse <- sqrt(colMeans((cv_pred - y)^2))
  best <- which.min(rmse)
  mx <- colMeans(X); my <- mean(y)
  beta <- ridge_path(sweep(X, 2, mx), y - my, lambdas[best])[, 1]
  names(beta) <- colnames(X)
  m$beta <- beta
  m$intercept <- my - sum(mx * beta)
  m$lambda <- lambdas[best]
  m$cv_rmse <- rmse[best]
  m$range <- range(y)
  m$n <- n
  list(model = m, cv = cv_pred[, best])
}

predict_ridge <- function(m, text) {
  as.numeric(features(text, m) %*% m$beta + m$intercept)
}

round_score <- function(x, range) pmin(pmax(round(x), range[1]), range[2])

# ---- agreement ----------------------------------------------------------------

#' Agreement between machine and human scores
#'
#' Summarizes how well machine scores agree with human scores, overall and
#' within groups of test takers, with the statistics used to evaluate
#' automated scoring (Williamson, Xi and Breyer, 2012):
#'
#' * `exact`, `adjacent`: The share of responses where the machine score
#'   equals the first human score, or is within one point of it.
#' * `qwk`: Quadratic weighted kappa between machine and first human score,
#'   and `qwk_human` between the two human scores (double-scored responses).
#' * `corr`: The correlation between machine and first human score.
#' * `smd`: The standardized mean difference, machine minus human, divided
#'   by the pooled standard deviation. Positive values mean the machine is
#'   more generous than people.
#' * `prmse`: The proportional reduction in mean squared error (Haberman,
#'   2008; Loukina et al., 2020): How much of the variance of the *true*
#'   score the machine score explains, after allowing for the disagreement
#'   between human raters. It needs double-scored responses.
#'
#' A row's `verdict` applies the thresholds of [mv_rules()] (the same ones
#' as the agreement gate of [score_open()]): `qwk` at least `qwk_min` and no
#' more than `qwk_drop` below `qwk_human`; `|smd|` at most `score_smd`
#' overall and at most `subgroup_smd` within a group.
#'
#' @param machine machine scores, or a pipeline that has been through
#'   [score_open()] (its `open_scores` are used, by item and group).
#' @param human1 the first human score for each response.
#' @param human2 the second human score, `NA` for responses read once.
#' @param group optional group of each test taker, such as language status.
#' @param by optional item or prompt of each response, for one report per
#'   item.
#' @param rules thresholds from [mv_rules()].
#' @return A tibble of class `mv_agreement` with one row per item (if `by`)
#'   and group (`"All"` first): `n`, `n_double`, `mean_human`,
#'   `mean_machine`, `exact`, `adjacent`, `qwk`, `qwk_human`, `corr`, `smd`,
#'   `prmse` and `verdict`. Plot it with [autoplot()].
#' @references Haberman, S. J. (2008). When can subscores have value?
#'   *Journal of Educational and Behavioral Statistics, 33*(2), 204-229.
#'
#'   Loukina, A., Madnani, N., Cahill, A., Yao, L., Johnson, M. S., Riordan,
#'   B., & McCaffrey, D. F. (2020). Using PRMSE to evaluate automated scoring
#'   systems in the presence of label noise. In *Proceedings of the Fifteenth
#'   Workshop on Innovative Use of NLP for Building Educational Applications*
#'   (pp. 18-29).
#'
#'   Williamson, D. M., Xi, X., & Breyer, F. J. (2012). A framework for
#'   evaluation and use of automated scoring. *Educational Measurement:
#'   Issues and Practice, 31*(1), 2-13.
#' @seealso [train_scorer()], [score_open()].
#' @examples
#' e1 <- essays[essays$prompt == "E1", ]
#' s <- train_scorer(e1)
#' # judge the scorer on its cross-validated predictions
#' a <- agreement_report(s$cv$machine, e1$human1, e1$human2, group = e1$group)
#' a
#' autoplot(a)
#' @export
agreement_report <- function(machine, human1 = NULL, human2 = NULL, group = NULL, by = NULL,
                             rules = mv_rules()) {
  if (inherits(machine, "mv_pipeline")) {
    os <- machine$open_scores
    if (is.null(os)) stop("Score the responses with score_open() first.", call. = FALSE)
    grp <- if (all(is.na(os$group))) NULL else os$group
    return(agreement_report(os$machine, os$human1, os$human2, group = grp, by = os$item,
                            rules = rules))
  }
  n <- length(machine)
  if (is.null(human1)) stop("Give the human scores in `human1`.", call. = FALSE)
  if (length(human1) != n) stop("`machine` and `human1` must have the same length.",
                                call. = FALSE)
  if (is.null(human2)) human2 <- rep(NA_real_, n)
  if (length(human2) != n) stop("`human2` must have the same length as `machine`.",
                                call. = FALSE)
  if (!is.null(group) && length(group) != n)
    stop("`group` must have one value per response.", call. = FALSE)
  if (!is.null(by) && length(by) != n)
    stop("`by` must have one value per response.", call. = FALSE)
  d <- data.frame(m = as.numeric(machine), h1 = as.numeric(human1), h2 = as.numeric(human2),
                  g = if (is.null(group)) "All" else as.character(group),
                  b = if (is.null(by)) "All" else as.character(by), stringsAsFactors = FALSE)
  glev <- if (is.null(group)) character() else
    if (is.factor(group)) levels(droplevels(group)) else sort(unique(stats::na.omit(d$g)))
  blev <- if (is.null(by)) "All" else
    if (is.factor(by)) levels(droplevels(by)) else sort(unique(stats::na.omit(d$b)))
  rows <- list()
  for (b in blev) {
    db <- d[d$b %in% b, , drop = FALSE]
    rows[[length(rows) + 1]] <- agreement_row(db, b, "All")
    for (g in glev) rows[[length(rows) + 1]] <- agreement_row(db[db$g %in% g, , drop = FALSE], b, g)
  }
  out <- do.call(rbind, rows)
  if (is.null(by)) out$by <- NULL
  overall <- out$group == "All"
  smd_max <- ifelse(overall, rules$score_smd, rules$subgroup_smd)
  ok_qwk <- !is.na(out$qwk) & out$qwk >= rules$qwk_min &
    (is.na(out$qwk_human) | out$qwk >= out$qwk_human - rules$qwk_drop)
  ok_smd <- !is.na(out$smd) & abs(out$smd) <= smd_max
  out$verdict <- ifelse(is.na(out$qwk), "too few",
                        ifelse(ok_qwk & ok_smd, "meets", ifelse(!ok_qwk, "agreement too low",
                               ifelse(out$smd > 0, "machine too high", "machine too low"))))
  rownames(out) <- NULL
  structure(as_tbl(out), class = c("mv_agreement", class(as_tbl(out))),
            rules = rules[c("qwk_min", "qwk_drop", "score_smd", "subgroup_smd")])
}

agreement_row <- function(d, b, g) {
  ok <- !is.na(d$m) & !is.na(d$h1)
  dd <- d[ok, , drop = FALSE]
  dbl <- !is.na(dd$h2)
  data.frame(by = b, group = g, n = nrow(dd), n_double = sum(dbl),
             mean_human = if (nrow(dd)) mean(dd$h1) else NA_real_,
             mean_machine = if (nrow(dd)) mean(dd$m) else NA_real_,
             exact = if (nrow(dd)) mean(dd$m == dd$h1) else NA_real_,
             adjacent = if (nrow(dd)) mean(abs(dd$m - dd$h1) <= 1) else NA_real_,
             qwk = qwk(dd$m, dd$h1),
             qwk_human = if (sum(dbl) >= 2) qwk(dd$h1[dbl], dd$h2[dbl]) else NA_real_,
             corr = if (nrow(dd) > 2 && stats::sd(dd$m) > 0 && stats::sd(dd$h1) > 0)
               stats::cor(dd$m, dd$h1) else NA_real_,
             smd = smd(dd$m, dd$h1),
             prmse = prmse(dd$m, dd$h1, dd$h2),
             stringsAsFactors = FALSE)
}

# PRMSE of machine scores for the true score (Loukina et al., 2020), from
# one or two human scores per response
prmse <- function(m, h1, h2) {
  H <- cbind(h1, h2)
  c_i <- rowSums(!is.na(H))
  ok <- !is.na(m) & c_i > 0
  m <- m[ok]; H <- H[ok, , drop = FALSE]; c_i <- c_i[ok]
  dbl <- c_i == 2
  if (sum(dbl) < 10) return(NA_real_)
  var_err <- sum((H[dbl, 1] - H[dbl, 2])^2 / 2) / sum(dbl)
  hbar <- rowMeans(H, na.rm = TRUE)
  N <- sum(c_i); n <- length(m)
  grand <- sum(c_i * hbar) / N
  var_true <- (sum(c_i * (hbar - grand)^2) - (n - 1) * var_err) / (N - sum(c_i^2) / N)
  mse <- (sum(c_i * (hbar - m)^2) - n * var_err) / N
  if (!is.finite(var_true) || var_true <= 0) return(NA_real_)
  1 - mse / var_true
}

#' @export
print.mv_agreement <- function(x, digits = 2, ...) {
  r <- attr(x, "rules")
  cat("Machine-human agreement\n")
  df <- as.data.frame(x)
  num <- vapply(df, is.numeric, NA)
  int <- names(df) %in% c("n", "n_double")
  df[num & !int] <- lapply(df[num & !int], function(v) formatC(v, digits = digits, format = "f"))
  df[] <- lapply(df, function(v) { v[v == "NA"] <- ""; v })
  print(df, row.names = FALSE, right = TRUE)
  if (!is.null(r))
    cat(sprintf(paste0("Meets: QWK >= %s and within %s of human-human QWK; |SMD| <= %s overall ",
                       "and <= %s within groups (mv_rules()).\n"),
                r$qwk_min, r$qwk_drop, r$score_smd, r$subgroup_smd))
  invisible(x)
}

#' @rdname agreement_report
#' @param object an agreement report.
#' @export
autoplot.mv_agreement <- function(object, ...) {
  r <- attr(object, "rules")
  d <- as.data.frame(object)
  if (is.null(d$by)) d$by <- "All"
  d$group <- factor(d$group, levels = rev(unique(d$group)))
  d$overall <- ifelse(d$group == "All", "All", "Group")
  multi <- length(unique(d$by)) > 1
  p1 <- ggplot2::ggplot(d, ggplot2::aes(qwk, group)) +
    ggplot2::geom_vline(xintercept = r$qwk_min, linetype = 2, colour = "grey50") +
    ggplot2::geom_point(ggplot2::aes(x = qwk_human), shape = 4, size = 2.5,
                        colour = "grey40", na.rm = TRUE) +
    ggplot2::geom_point(size = 2.8, colour = "#2b6cb0", na.rm = TRUE) +
    ggplot2::labs(x = "QWK", y = NULL, title = "Agreement",
                  subtitle = "Dot: machine-human. Cross: two humans.") +
    theme_mirtverse()
  lim <- max(0.3, abs(d$smd), na.rm = TRUE)
  p2 <- ggplot2::ggplot(d, ggplot2::aes(smd, group)) +
    ggplot2::annotate("rect", xmin = -r$subgroup_smd, xmax = r$subgroup_smd, ymin = -Inf,
                      ymax = Inf, fill = "grey90") +
    ggplot2::geom_vline(xintercept = 0, colour = "grey50") +
    ggplot2::geom_segment(ggplot2::aes(x = 0, xend = smd, yend = group),
                          colour = "grey60", na.rm = TRUE) +
    ggplot2::geom_point(size = 2.8, colour = "#c05621", na.rm = TRUE) +
    ggplot2::scale_x_continuous(limits = c(-lim, lim)) +
    ggplot2::labs(x = "SMD", y = NULL, title = "Machine minus human",
                  subtitle = "Band: the limit for groups.") +
    theme_mirtverse()
  if (multi) {
    p1 <- p1 + ggplot2::facet_grid(by ~ .)
    p2 <- p2 + ggplot2::facet_grid(by ~ .)
  }
  patchwork::wrap_plots(p1, p2, nrow = 1)
}
