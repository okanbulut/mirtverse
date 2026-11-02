#' Text features of test items
#'
#' Describes each item by features that can be read off its text before
#' anyone answers it: How long and how hard to read the stem is, how many
#' and how large its numbers are, whether it uses decimals or fractions or a
#' negation, and, for multiple-choice items, what its options look like. It
#' also finds each item's most similar other item, to flag near-duplicates.
#' Everything runs in base R.
#'
#' The features are the item covariates of an explanatory IRT model such as
#' the linear logistic test model (LLTM): Pass them with the items'
#' difficulties to [predict_difficulty()]. They are deliberately simple and
#' transparent. Your own features (an item writer's rating of the number of
#' solution steps, or text embeddings from a language model) can be joined
#' by `id` and used in the same way.
#'
#' The features are:
#'
#' * `words`, `sentences`: Words (including numbers) and sentences in the
#'   stem.
#' * `word_length`: Mean letters per word.
#' * `grade`: Flesch-Kincaid grade level of the stem, from words per
#'   sentence and syllables per word.
#' * `numbers`, `max_digits`: How many numbers the stem contains, and the
#'   digits in the whole part of the largest one.
#' * `decimals`: 1 if the stem or the keyed option uses decimals or
#'   fractions (whole amounts of money such as $5.00 do not count).
#' * `negation`: 1 if the stem contains not, never, no, except, least or
#'   false.
#' * `option_words`: Mean words per option.
#' * `key_longest`: 1 if the keyed option is longer than every other option,
#'   a classic item-writing flaw.
#' * `distractor_distance`: For numeric options, the median distance of the
#'   distractors from the key, relative to the key (`NA` when the options
#'   are not all numbers). Close distractors usually make an item harder.
#' * `option_overlap`: Mean word overlap (Jaccard) between pairs of options.
#' * `similarity`, `nearest`: The overlap (Jaccard) of the two-word
#'   sequences in the item's stem and options with those of its most similar
#'   other item, and that item's id. Values near 1 mark near-duplicates;
#'   items written from the same template with different numbers score
#'   lower, because every changed number breaks two sequences.
#'
#' @param items a data frame with one row per item.
#' @param stem name of the column that holds the stem (question text).
#' @param options names of the option columns; `NULL` uses whichever of `A`
#'   to `E` exist. Use `character(0)` for items without options.
#' @param key name of the column with the keyed option (a letter matching
#'   one of `options`); ignored when absent.
#' @param id name of the item id column; when absent, items are numbered.
#' @return A tibble with one row per item: `id` and the features above.
#' @seealso [predict_difficulty()] to predict difficulty from the features;
#'   the [AI Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.html).
#' @examples
#' f <- item_features(itemtext)
#' f
#' # surface features and difficulty
#' round(cor(f[, c("words", "max_digits", "decimals")], itemtext$b), 2)
#' # the most similar pairs of items
#' head(f[order(-f$similarity), c("id", "nearest", "similarity")])
#' @export
item_features <- function(items, stem = "stem", options = NULL, key = "key", id = "id") {
  items <- as.data.frame(items, stringsAsFactors = FALSE)
  if (!stem %in% names(items)) stop(sprintf("`items` has no column `%s`.", stem), call. = FALSE)
  if (is.null(options)) options <- intersect(LETTERS[1:5], names(items))
  miss <- setdiff(options, names(items))
  if (length(miss)) stop(sprintf("`items` has no option column `%s`.", miss[1]), call. = FALSE)
  n <- nrow(items)
  ids <- if (id %in% names(items)) as.character(items[[id]]) else sprintf("item%03d", seq_len(n))
  s <- as.character(items[[stem]])
  s[is.na(s)] <- ""
  toks <- lapply(s, text_tokens)
  alpha <- lapply(toks, function(t) t[grepl("^[a-z]", t)])
  nw <- lengths(toks)
  ns <- pmax(1L, lengths(regmatches(s, gregexpr("[.?!]+(\\s+[A-Z\"]|\\s*$)", s))))
  syl <- vapply(alpha, function(w) sum(syllables(w)), 0)
  na <- pmax(lengths(alpha), 1L)
  nums <- regmatches(s, gregexpr("[0-9][0-9,]*(\\.[0-9]+)?", s))
  out <- data.frame(
    id = ids,
    words = nw,
    sentences = ns,
    word_length = round(vapply(alpha, function(w) if (length(w)) mean(nchar(w)) else 0, 0), 2),
    grade = round(0.39 * nw / ns + 11.8 * syl / na - 15.59, 1),
    numbers = lengths(nums),
    max_digits = vapply(nums, function(x) {
      if (!length(x)) return(0L)
      v <- suppressWarnings(as.numeric(gsub(",", "", x)))
      nchar(format(floor(max(v, na.rm = TRUE)), scientific = FALSE))
    }, 0L),
    stringsAsFactors = FALSE)
  opt <- if (length(options)) as.matrix(items[options]) else matrix(character(0), n, 0)
  opt[is.na(opt)] <- ""
  dec_pat <- "[0-9]\\.[0-9]*[1-9]|[0-9]/[0-9]"
  k <- if (ncol(opt) && key %in% names(items)) match(as.character(items[[key]]), options)
       else rep(NA_integer_, n)
  key_text <- if (ncol(opt)) opt[cbind(seq_len(n), ifelse(is.na(k), 1L, k))] else rep("", n)
  if (ncol(opt)) key_text[is.na(k)] <- ""
  out$decimals <- as.integer(grepl(dec_pat, s) | grepl(dec_pat, key_text))
  out$negation <- as.integer(grepl("\\b(not|never|no|except|least|false)\\b", tolower(s)))
  if (ncol(opt) >= 2) {
    out$option_words <- round(apply(opt, 1, function(o) mean(lengths(lapply(o, text_tokens)))), 2)
    out$key_longest <- vapply(seq_len(n), function(i) {
      if (is.na(k[i])) return(NA_integer_)
      len <- nchar(trimws(opt[i, ]))
      as.integer(len[k[i]] > max(len[-k[i]]))
    }, 0L)
    out$distractor_distance <- vapply(seq_len(n), function(i) {
      if (is.na(k[i])) return(NA_real_)
      v <- option_value(opt[i, ])
      if (anyNA(v)) return(NA_real_)
      round(stats::median(abs(v[-k[i]] - v[k[i]])) / max(abs(v[k[i]]), 1e-8), 3)
    }, 0)
    out$option_overlap <- round(vapply(seq_len(n), function(i) {
      t <- lapply(opt[i, ], function(o) unique(text_tokens(o)))
      pr <- utils::combn(length(t), 2)
      mean(apply(pr, 2, function(p) jaccard(t[[p[1]]], t[[p[2]]])))
    }, 0), 3)
  }
  full <- if (ncol(opt)) paste(s, apply(opt, 1, paste, collapse = " ")) else s
  near <- nearest_item(lapply(full, function(x) {
    t <- text_tokens(x)
    if (length(t) < 2) t else unique(paste(t[-length(t)], t[-1]))
  }))
  out$similarity <- round(near$similarity, 3)
  out$nearest <- ids[near$nearest]
  as_tbl(out)
}

# words and numbers of a text, lower case
text_tokens <- function(x) {
  x <- tolower(x)
  regmatches(x, gregexpr("[a-z]+('[a-z]+)?|[0-9][0-9,]*([./:][0-9]+)?", x))[[1]]
}

# rough English syllable count
syllables <- function(w) {
  if (!length(w)) return(integer(0))
  v <- lengths(regmatches(w, gregexpr("[aeiouy]+", w)))
  silent <- grepl("[^aeiouy]e$", w) & !grepl("[^aeiouy]le$", w) & v > 1
  pmax(1L, v - silent)
}

jaccard <- function(a, b) {
  u <- length(union(a, b))
  if (u == 0) return(0)
  length(intersect(a, b)) / u
}

# numeric value of options such as "$1.25", "3/4", "1,200 square cm" or "4:35 p.m."
option_value <- function(o) {
  vapply(o, function(x) {
    x <- gsub(",", "", x)
    if (grepl("^\\s*[$]?-?[0-9]+/[0-9]+", x)) {
      p <- as.numeric(regmatches(x, regexpr("[0-9]+/[0-9]+", x)) |> strsplit("/") |> unlist())
      return(p[1] / p[2])
    }
    if (grepl("^\\s*[0-9]+:[0-9]{2}", x)) {
      p <- as.numeric(strsplit(regmatches(x, regexpr("[0-9]+:[0-9]{2}", x)), ":")[[1]])
      return(p[1] * 60 + p[2])
    }
    m <- regmatches(x, regexpr("^\\s*[$]?-?[0-9]+(\\.[0-9]+)?", x))
    if (!length(m)) return(NA_real_)
    as.numeric(gsub("[$\\s]", "", m, perl = TRUE))
  }, 0, USE.NAMES = FALSE)
}

# most similar other item by word overlap
nearest_item <- function(tok) {
  n <- length(tok)
  if (n < 2) return(list(similarity = rep(NA_real_, n), nearest = rep(NA_integer_, n)))
  vocab <- unique(unlist(tok))
  m <- matrix(0, n, length(vocab))
  for (i in seq_len(n)) m[i, match(tok[[i]], vocab)] <- 1
  inter <- tcrossprod(m)
  sz <- rowSums(m)
  sim <- inter / pmax(outer(sz, sz, "+") - inter, 1)
  diag(sim) <- -1
  j <- max.col(sim, ties.method = "first")
  list(similarity = sim[cbind(seq_len(n), j)], nearest = j)
}

#' Predict item difficulty from item features
#'
#' Predicts the difficulty of items from their features (for example the
#' text features of [item_features()]) with up to three models, and compares
#' them by how well they predict items they were not fitted on:
#'
#' * `"lltm"`: A linear model of difficulty on the features, the two-step
#'   form of the linear logistic test model (Fischer, 1973) and of
#'   explanatory IRT. Its coefficients say how much each feature adds to
#'   difficulty, in logits. With `se`, items are weighted by the precision
#'   of their estimated difficulty.
#' * `"lasso"`: A linear model whose coefficients are shrunk towards zero,
#'   with some set to exactly zero; the penalty is chosen by
#'   cross-validation within the training items.
#' * `"forest"`: A random forest of regression trees, which can pick up
#'   interactions and non-linear effects but has no coefficients to read.
#'
#' All three are fitted in base R. Each model is judged by `folds`-fold
#' cross-validation: The items are split into folds, and each fold's
#' difficulties are predicted from a model fitted to the other folds. With
#' `group` (such as the item family), whole groups are held out together,
#' which shows how well difficulty can be predicted for a new family rather
#' than for a new item from a family already seen. A factor feature whose
#' level was not seen in training is predicted as the average of the levels
#' that were.
#'
#' As a guard against leakage, numeric features whose rank correlation with
#' difficulty is 0.8 or more on their own are listed when the result is
#' printed: A
#' feature that predicts difficulty that well is often computed from the
#' same responses as the difficulty itself, and so is not available before
#' field testing.
#'
#' @param data a data frame with one row per item, holding the difficulties
#'   and the features (for example `merge(items, item_features(items))`).
#' @param features names of the feature columns. Character and factor
#'   columns are turned into indicator variables.
#' @param b name of the column with the item difficulties.
#' @param se optional name of a column with the standard errors of `b`;
#'   used to weight the LLTM and to show the estimation error in `b`.
#' @param methods any of `"lltm"`, `"lasso"` and `"forest"`.
#' @param folds number of cross-validation folds.
#' @param group optional name of a column whose values are held out together.
#' @param id name of the item id column; when absent, items are numbered.
#' @param ntree number of trees in the random forest.
#' @param seed random seed for the folds and the forest, or `NULL`.
#' @return An object of class `mv_difficulty`: A list with `accuracy` (a
#'   tibble with `method`, `rmse`, `mae`, `r` and `r2`, all from
#'   cross-validation), `cv` (the out-of-fold predictions: `id`, `b`,
#'   `method`, `predicted`, `fold`), `models` (each method fitted to all
#'   items), `leaky` (the rank correlations with `b` of features at 0.8 or
#'   more), and the
#'   settings. Use [tidy()] for the coefficients and importances,
#'   [autoplot()] to plot the predictions and [predict()] for new items.
#' @references Fischer, G. H. (1973). The linear logistic test model as an
#'   instrument in educational research. *Acta Psychologica, 37*(6),
#'   359-374.
#' @seealso [item_features()]; for the one-step LLTM fitted to responses,
#'   the `itemdesign` and `item.formula` arguments of [mirt::mirt()].
#' @examples
#' d <- merge(itemtext, item_features(itemtext))
#' m <- predict_difficulty(d, c("words", "sentences", "max_digits", "decimals"),
#'                         se = "b_se", methods = c("lltm", "lasso"))
#' m
#' tidy(m)
#' \donttest{
#' # with the item family, holding out whole families
#' m2 <- predict_difficulty(d, c("family", "sentences", "max_digits", "decimals"),
#'                          group = "family")
#' m2
#' autoplot(m2)
#' }
#' @export
predict_difficulty <- function(data, features, b = "b", se = NULL,
                               methods = c("lltm", "lasso", "forest"), folds = 5,
                               group = NULL, id = "id", ntree = 100, seed = 1) {
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  methods <- unique(match.arg(methods, c("lltm", "lasso", "forest"), several.ok = TRUE))
  for (nm in c(b, se, group, features))
    if (!nm %in% names(data)) stop(sprintf("`data` has no column `%s`.", nm), call. = FALSE)
  if (!length(features)) stop("Give at least one feature.", call. = FALSE)
  y <- suppressWarnings(as.numeric(data[[b]]))
  keep <- !is.na(y)
  if (sum(keep) < 20) stop("Predicting difficulty needs at least 20 items with a difficulty.",
                           call. = FALSE)
  data <- data[keep, , drop = FALSE]
  y <- y[keep]
  n <- length(y)
  ids <- if (id %in% names(data)) as.character(data[[id]]) else sprintf("item%03d", seq_len(n))
  w <- if (is.null(se)) rep(1, n) else {
    s <- as.numeric(data[[se]])
    s[is.na(s) | s <= 0] <- stats::median(s[s > 0], na.rm = TRUE)
    1 / s^2
  }
  if (!is.null(seed)) {
    old <- if (exists(".Random.seed", globalenv())) get(".Random.seed", globalenv()) else NULL
    on.exit(if (is.null(old)) rm(".Random.seed", envir = globalenv())
            else assign(".Random.seed", old, envir = globalenv()), add = TRUE)
    set.seed(seed)
  }
  fold <- if (is.null(group)) {
    sample(rep(seq_len(folds), length.out = n))
  } else {
    g <- as.character(data[[group]])
    ug <- sample(unique(g))
    folds <- min(folds, length(ug))
    rep(seq_len(folds), length.out = length(ug))[match(g, ug)]
  }
  cv <- list()
  for (m in methods) {
    pred <- rep(NA_real_, n)
    for (k in seq_len(folds)) {
      tr <- fold != k
      fit <- fit_difficulty(m, data[tr, , drop = FALSE], features, y[tr], w[tr], ntree)
      pred[!tr] <- predict_difficulty_fit(fit, data[!tr, , drop = FALSE])
    }
    cv[[m]] <- data.frame(id = ids, b = y, method = m, predicted = pred, fold = fold,
                          stringsAsFactors = FALSE)
  }
  cv <- do.call(rbind, cv)
  rownames(cv) <- NULL
  acc <- do.call(rbind, lapply(methods, function(m) {
    d <- cv[cv$method == m, ]
    e <- d$predicted - d$b
    data.frame(method = m, rmse = sqrt(mean(e^2)), mae = mean(abs(e)),
               r = stats::cor(d$predicted, d$b), r2 = 1 - sum(e^2) / sum((d$b - mean(d$b))^2),
               stringsAsFactors = FALSE)
  }))
  models <- lapply(stats::setNames(methods, methods), function(m)
    fit_difficulty(m, data, features, y, w, ntree))
  num <- features[vapply(data[features], is.numeric, TRUE)]
  r <- vapply(num, function(f) {
    x <- data[[f]]
    ok <- !is.na(x)
    if (sum(ok) < 3 || stats::sd(x[ok]) == 0) return(0)
    stats::cor(x[ok], y[ok], method = "spearman")
  }, 0)
  leaky <- r[abs(r) >= 0.8]
  structure(list(accuracy = as_tbl(acc), cv = as_tbl(cv), models = models,
                 leaky = leaky, features = features, b = b, se = se, group = group,
                 folds = folds, n = n,
                 se_rmse = if (is.null(se)) NA_real_ else sqrt(mean(1 / w))),
            class = "mv_difficulty")
}

method_label <- function(m) c(lltm = "LLTM", lasso = "Lasso", forest = "Random forest")[m]

#' @export
print.mv_difficulty <- function(x, digits = 2, ...) {
  cat(sprintf("<mv_difficulty> %d items, %d feature%s, %d-fold cross-validation%s\n",
              x$n, length(x$features), if (length(x$features) == 1) "" else "s", x$folds,
              if (is.null(x$group)) " (random folds)" else sprintf(" (folds by %s)", x$group)))
  a <- as.data.frame(x$accuracy)
  a$method <- method_label(a$method)
  a[-1] <- lapply(a[-1], function(v) round(v, digits))
  names(a) <- c("method", "RMSE", "MAE", "r", "R2")
  print(a, row.names = FALSE)
  if (!is.na(x$se_rmse))
    cat(sprintf("Estimation error in b (RMSE of %s): %.2f. No model can predict b more closely than that.\n",
                x$se, x$se_rmse))
  for (f in names(x$leaky))
    cat(sprintf("Check: `%s` alone has a rank correlation of %.2f with b. Is it known before field testing, or computed from the same responses?\n",
                f, x$leaky[[f]]))
  cat("Use tidy() for the coefficients, autoplot() for the predictions.\n")
  invisible(x)
}

#' @rdname predict_difficulty
#' @param x,object a result of `predict_difficulty()`.
#' @param ... not used.
#' @return `tidy()` returns a tibble with `method`, `term`, `estimate` and
#'   `std_error`: The coefficients of the LLTM (with standard errors) and the
#'   lasso, in logits per unit of the feature, and for the forest each
#'   feature's share of the total improvement in fit (`std_error` is `NA`).
#' @export
tidy.mv_difficulty <- function(x, ...) {
  out <- lapply(names(x$models), function(m) {
    f <- x$models[[m]]
    if (m == "forest") {
      imp <- f$importance / max(sum(f$importance), 1e-12)
      d <- data.frame(term = names(imp), estimate = as.numeric(imp), std_error = NA_real_)
      d <- d[order(-d$estimate), ]
    } else {
      d <- data.frame(term = names(f$coef), estimate = as.numeric(f$coef),
                      std_error = if (m == "lltm") as.numeric(f$se) else NA_real_)
      if (m == "lasso") d <- d[d$term == "(Intercept)" | d$estimate != 0, ]
    }
    cbind(method = m, d, stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, out)
  rownames(out) <- NULL
  as_tbl(out)
}

#' @rdname predict_difficulty
#' @param label number of the worst-predicted items to label in each panel.
#' @export
autoplot.mv_difficulty <- function(object, label = 3, ...) {
  d <- as.data.frame(object$cv)
  acc <- object$accuracy
  lab <- stats::setNames(sprintf("%s: RMSE %.2f, r %.2f", method_label(acc$method), acc$rmse, acc$r),
                         acc$method)
  d$panel <- factor(lab[d$method], levels = lab)
  d$resid <- d$predicted - d$b
  worst <- do.call(rbind, lapply(split(d, d$method), function(s)
    s[order(-abs(s$resid)), ][seq_len(min(label, nrow(s))), ]))
  ggplot2::ggplot(d, ggplot2::aes(predicted, b)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, colour = "grey60", linetype = 2) +
    ggplot2::geom_point(alpha = 0.6, colour = "#2c7fb8") +
    ggplot2::geom_text(data = worst, ggplot2::aes(label = id), size = 3, vjust = -0.7,
                       hjust = "inward", colour = "#b2182b", check_overlap = TRUE) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0.05, 0.12))) +
    ggplot2::facet_wrap(~panel) +
    ggplot2::labs(x = "Predicted difficulty (cross-validated)", y = "Estimated difficulty (b)",
                  title = "Predicted against estimated difficulty",
                  subtitle = "Dashed line: Perfect prediction. Labels: The worst-predicted items.") +
    ggplot2::theme_minimal()
}

#' @rdname predict_difficulty
#' @param newdata a data frame of new items with the same feature columns.
#' @param method which fitted model to use; the first one by default.
#' @export
predict.mv_difficulty <- function(object, newdata, method = NULL, ...) {
  method <- method %||% names(object$models)[1]
  if (!method %in% names(object$models))
    stop(sprintf("No `%s` model was fitted.", method), call. = FALSE)
  newdata <- as.data.frame(newdata, stringsAsFactors = FALSE)
  miss <- setdiff(object$features, names(newdata))
  if (length(miss)) stop(sprintf("`newdata` has no column `%s`.", miss[1]), call. = FALSE)
  predict_difficulty_fit(object$models[[method]], newdata)
}

# ---- design matrix --------------------------------------------------------

design_spec <- function(data, features) {
  lapply(stats::setNames(features, features), function(f) {
    x <- data[[f]]
    if (is.numeric(x) || is.logical(x)) {
      list(type = "num", mean = mean(as.numeric(x), na.rm = TRUE))
    } else {
      x <- as.character(x)
      lv <- sort(unique(x[!is.na(x)]))
      list(type = "cat", levels = lv, prop = as.numeric(table(factor(x, lv))) / sum(!is.na(x)))
    }
  })
}

design_x <- function(data, spec) {
  cols <- lapply(names(spec), function(f) {
    s <- spec[[f]]
    x <- data[[f]]
    if (s$type == "num") {
      x <- as.numeric(x)
      x[is.na(x)] <- if (is.nan(s$mean)) 0 else s$mean
      m <- matrix(x, ncol = 1, dimnames = list(NULL, f))
    } else {
      x <- as.character(x)
      m <- outer(x, s$levels, "==") * 1
      m[is.na(m)] <- 0
      unseen <- rowSums(m) == 0
      if (any(unseen)) m[unseen, ] <- matrix(s$prop, sum(unseen), length(s$prop), byrow = TRUE)
      colnames(m) <- paste0(f, ": ", s$levels)
    }
    m
  })
  do.call(cbind, cols)
}

fit_difficulty <- function(method, data, features, y, w, ntree) {
  spec <- design_spec(data, features)
  X <- design_x(data, spec)
  fit <- switch(method,
                lltm = fit_lltm2(X, y, w),
                lasso = fit_lasso(X, y),
                forest = fit_forest(X, y, ntree))
  c(fit, list(method = method, spec = spec))
}

predict_difficulty_fit <- function(fit, newdata) {
  X <- design_x(newdata, fit$spec)
  switch(fit$method,
         lltm = , lasso = drop(cbind(1, X) %*% fit$coef),
         forest = predict_forest(fit, X))
}

# ---- two-step LLTM ---------------------------------------------------------

fit_lltm2 <- function(X, y, w) {
  Z <- cbind(`(Intercept)` = 1, X)
  m <- stats::lm.wfit(Z, y, w)
  coef <- m$coefficients
  coef[is.na(coef)] <- 0
  se <- rep(NA_real_, length(coef))
  names(se) <- names(coef)
  p <- m$rank
  if (p > 0 && length(y) > p) {
    piv <- m$qr$pivot[seq_len(p)]
    sigma2 <- sum(w * m$residuals^2) / (length(y) - p)
    R <- chol2inv(m$qr$qr[seq_len(p), seq_len(p), drop = FALSE])
    se[piv] <- sqrt(diag(R) * sigma2)
  }
  list(coef = coef, se = se)
}

# ---- lasso by coordinate descent ------------------------------------------

# coordinate descent on the Gram matrix; Z is centred, y centred
lasso_path <- function(Z, y, lambdas, tol = 1e-5, maxit = 200) {
  n <- nrow(Z)
  p <- ncol(Z)
  G <- crossprod(Z) / n
  cy <- drop(crossprod(Z, y)) / n
  beta <- numeric(p)
  out <- matrix(0, p, length(lambdas))
  act <- which(diag(G) > 1e-10)
  for (l in seq_along(lambdas)) {
    lam <- lambdas[l]
    for (it in seq_len(maxit)) {
      delta <- 0
      for (j in act) {
        bj <- beta[j]
        z <- cy[j] - sum(G[, j] * beta) + G[j, j] * bj
        nb <- sign(z) * max(abs(z) - lam, 0) / G[j, j]
        if (nb != bj) {
          beta[j] <- nb
          delta <- max(delta, abs(nb - bj))
        }
      }
      if (delta < tol) break
    }
    out[, l] <- beta
  }
  out
}

fit_lasso <- function(X, y, nlambda = 25, inner = 5) {
  mu <- colMeans(X)
  sdv <- apply(X, 2, function(v) sqrt(mean((v - mean(v))^2)))
  use <- sdv > 1e-10
  Z <- sweep(sweep(X[, use, drop = FALSE], 2, mu[use]), 2, sdv[use], "/")
  ym <- mean(y)
  yc <- y - ym
  coef <- stats::setNames(c(ym, numeric(ncol(X))), c("(Intercept)", colnames(X)))
  if (!any(use)) return(list(coef = coef, lambda = NA_real_))
  lmax <- max(abs(crossprod(Z, yc))) / length(y)
  lambdas <- lmax * 10^seq(0, -2, length.out = nlambda)
  # choose lambda by cross-validation within the training items
  f <- sample(rep(seq_len(inner), length.out = length(y)))
  err <- matrix(NA_real_, inner, nlambda)
  for (k in seq_len(inner)) {
    tr <- f != k
    m <- colMeans(Z[tr, , drop = FALSE])
    Zt <- sweep(Z[tr, , drop = FALSE], 2, m)
    yt <- mean(y[tr])
    B <- lasso_path(Zt, y[tr] - yt, lambdas)
    P <- yt + sweep(Z[!tr, , drop = FALSE], 2, m) %*% B
    err[k, ] <- colMeans((P - y[!tr])^2)
  }
  best <- which.min(colMeans(err))
  beta <- lasso_path(Z, yc, lambdas[seq_len(best)])[, best]
  b <- beta / sdv[use]
  coef[colnames(X)[use]] <- b
  coef[1] <- ym - sum(b * mu[use])
  list(coef = coef, lambda = lambdas[best])
}

# ---- random forest of regression trees ------------------------------------

grow_tree <- function(X, y, mtry, min_node = 5, max_depth = 10) {
  var <- integer(0); cut <- numeric(0); left <- integer(0); right <- integer(0)
  value <- numeric(0)
  gain <- numeric(ncol(X))
  new_node <- function() {
    var <<- c(var, NA_integer_); cut <<- c(cut, NA_real_)
    left <<- c(left, NA_integer_); right <<- c(right, NA_integer_)
    value <<- c(value, NA_real_)
    length(var)
  }
  stack <- list(list(node = new_node(), idx = seq_len(nrow(X)), depth = 0))
  while (length(stack)) {
    cur <- stack[[length(stack)]]
    stack[[length(stack)]] <- NULL
    idx <- cur$idx
    yy <- y[idx]
    value[cur$node] <- mean(yy)
    n <- length(idx)
    if (n < 2 * min_node || cur$depth >= max_depth || stats::var(yy) < 1e-12) next
    best <- list(gain = 0)
    tot <- sum(yy)
    base <- tot^2 / n
    for (j in sample(ncol(X), mtry)) {
      x <- X[idx, j]
      o <- order(x)
      xs <- x[o]
      cs <- cumsum(yy[o])
      k <- seq_len(n - 1)
      ok <- xs[k] < xs[k + 1] & k >= min_node & (n - k) >= min_node
      if (!any(ok)) next
      k <- k[ok]
      g <- cs[k]^2 / k + (tot - cs[k])^2 / (n - k) - base
      i <- which.max(g)
      if (g[i] > best$gain)
        best <- list(gain = g[i], var = j, cut = (xs[k[i]] + xs[k[i] + 1]) / 2)
    }
    if (best$gain <= 0) next
    gain[best$var] <- gain[best$var] + best$gain
    var[cur$node] <- best$var
    cut[cur$node] <- best$cut
    goes_left <- X[idx, best$var] <= best$cut
    l <- new_node(); r <- new_node()
    left[cur$node] <- l; right[cur$node] <- r
    stack[[length(stack) + 1]] <- list(node = l, idx = idx[goes_left], depth = cur$depth + 1)
    stack[[length(stack) + 1]] <- list(node = r, idx = idx[!goes_left], depth = cur$depth + 1)
  }
  list(var = var, cut = cut, left = left, right = right, value = value, gain = gain)
}

predict_tree <- function(tree, X) {
  node <- rep(1L, nrow(X))
  repeat {
    v <- tree$var[node]
    inner <- !is.na(v)
    if (!any(inner)) break
    i <- which(inner)
    goes_left <- X[cbind(i, v[i])] <= tree$cut[node[i]]
    node[i] <- ifelse(goes_left, tree$left[node[i]], tree$right[node[i]])
  }
  tree$value[node]
}

fit_forest <- function(X, y, ntree = 100, min_node = 5) {
  mtry <- max(1L, floor(ncol(X) / 3))
  trees <- lapply(seq_len(ntree), function(t) {
    s <- sample(length(y), replace = TRUE)
    grow_tree(X[s, , drop = FALSE], y[s], mtry, min_node)
  })
  imp <- Reduce(`+`, lapply(trees, `[[`, "gain"))
  names(imp) <- colnames(X)
  list(trees = trees, importance = imp)
}

predict_forest <- function(fit, X) {
  rowMeans(vapply(fit$trees, function(t) predict_tree(t, X), numeric(nrow(X))))
}
