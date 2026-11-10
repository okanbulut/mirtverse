#' Explain item difficulty with a knowledge graph
#'
#' Fits an explanatory item response model in which the knowledge graph
#' predicts how hard each item is: A linear logistic test model (LLTM;
#' Fischer, 1973) with a random item effect for the part of difficulty the
#' graph leaves unexplained (De Boeck, 2008), estimated with the eirm
#' package (Bulut et al., 2021). Two sets of predictors are offered:
#'
#' * `"concepts"`: One indicator per concept, from the graph's Q-matrix.
#'   Each concept gets its own difficulty, and an item that needs several
#'   concepts gets the sum.
#' * `"depth"`: The item's place in the learning order (the largest
#'   prerequisite depth among its concepts) and the number of concepts it
#'   needs. This tests the graph's claim that later concepts are harder.
#'
#' Item metadata added with [mv_kg_annotate()], such as word count or item
#' format, can join either set through `covariates`. Numeric columns are
#' centred, so the concept difficulties refer to an item of average value;
#' other columns get one 0/1 indicator for each value but the first. This
#' asks whether a feature of the items explains difficulty beyond what the
#' graph does.
#'
#' A Rasch model with random items and no predictors is fitted too, and
#' `explained` in `glance()` is the share of its item variance that the
#' predictors account for.
#'
#' @param kg a knowledge graph from [mv_kg_build()] or [as_mv_kg()].
#' @param data a data frame or matrix of 0/1 item scores; columns that are
#'   not items of the graph, such as an ID, are skipped.
#' @param predictors `"concepts"` or `"depth"`.
#' @param covariates optional names of item metadata columns to add as
#'   predictors (see [mv_kg_annotate()]).
#' @return An object of class `mv_kg_explain`: A list with `effects` (one
#'   row per predictor, with its `difficulty`, standard error and p
#'   value), `items` (each item's difficulty in the Rasch model, the
#'   difficulty the graph predicts, and the residual), `fit` (the two
#'   models' variances and information criteria), and the two
#'   [eirm::eirm()] fits in `model` and `base`. Difficulties are on the
#'   logit scale, with higher values for harder items.
#' @references
#' Bulut, O., Gorgun, G., & Yildirim-Erbasli, S. N. (2021). Estimating
#' explanatory extensions of dichotomous and polytomous Rasch models: The
#' eirm package in R. *Psych, 3*(3), 308-321.
#'
#' De Boeck, P. (2008). Random item IRT models. *Psychometrika, 73*(4),
#' 533-559.
#'
#' Fischer, G. H. (1973). The linear logistic test model as an instrument
#' in educational research. *Acta Psychologica, 37*(6), 359-374.
#' @seealso [predict_difficulty()] for difficulty from item text features.
#' @examples
#' \donttest{
#' if (requireNamespace("eirm", quietly = TRUE)) {
#'   ex <- mv_kg_explain(fractions_kg, fractions)
#'   ex
#'   tidy(ex)
#'   mv_kg_explain(fractions_kg, fractions, predictors = "depth")
#'
#'   # does the item format explain difficulty beyond the concepts?
#'   kg <- mv_kg_annotate(fractions_kg, data.frame(
#'     item = sprintf("F%02d", 1:24), format = rep(c("choice", "open"), 12)))
#'   mv_kg_explain(kg, fractions, covariates = "format")
#' }
#' }
#' @export
mv_kg_explain <- function(kg, data, predictors = c("concepts", "depth"), covariates = NULL) {
  check_kg(kg)
  predictors <- match.arg(predictors)
  if (!requireNamespace("eirm", quietly = TRUE) || !requireNamespace("lme4", quietly = TRUE))
    stop("mv_kg_explain() needs the eirm package: install.packages(\"eirm\").", call. = FALSE)
  q <- mv_kg_qmatrix(kg, data, drop_empty = TRUE)
  X <- as.matrix(as.data.frame(data)[rownames(q)])
  vals <- unique(stats::na.omit(as.vector(X)))
  if (!all(vals %in% c(0, 1)))
    stop("mv_kg_explain() needs 0/1 item scores.", call. = FALSE)
  q[q != 0] <- 1

  # item covariates
  if (predictors == "concepts") {
    cov <- as.data.frame(q)
    terms <- make.names(colnames(q), unique = TRUE)
    names(cov) <- terms
    lab <- stats::setNames(colnames(q), terms)
    rhs <- paste("-1 +", paste(terms, collapse = " + "))
  } else {
    d <- kg_depth(kg)
    if (anyNA(d)) stop("The prerequisite edges contain a cycle; see mv_kg_check().", call. = FALSE)
    cov <- data.frame(
      depth = apply(q, 1, function(r) max(d[colnames(q)[r == 1]])),
      n_concepts = rowSums(q))
    terms <- c("depth", "n_concepts")
    if (stats::var(cov$n_concepts) == 0) terms <- "depth"
    if (stats::var(cov$depth) == 0)
      stop("All items sit at the same depth in the learning order, so depth cannot explain difficulty.",
           call. = FALSE)
    lab <- c(depth = "Learning-order depth", n_concepts = "Number of concepts")[terms]
    rhs <- paste("1 +", paste(terms, collapse = " + "))
  }
  if (length(covariates)) {
    mc <- kg_meta_covariates(kg, covariates, rownames(q))
    nm <- make.names(c(terms, names(mc$data)), unique = TRUE)[-seq_along(terms)]
    names(mc$data) <- nm
    lab <- c(lab, stats::setNames(unname(mc$labels), nm))
    cov <- cbind(cov, mc$data)
    terms <- c(terms, nm)
    rhs <- paste(rhs, "+", paste(nm, collapse = " + "))
  }
  rownames(cov) <- rownames(q)
  long <- data.frame(
    person = factor(rep(seq_len(nrow(X)), times = ncol(X))),
    item = factor(rep(colnames(X), each = nrow(X)), levels = colnames(X)),
    response = as.vector(X))
  long <- cbind(long, cov[as.character(long$item), , drop = FALSE])
  rownames(long) <- NULL
  long <- long[!is.na(long$response), , drop = FALSE]

  form <- paste("response ~", rhs, "+ (1|person) + (1|item)")
  fit <- suppressMessages(eirm::eirm(form, data = long))
  base <- suppressMessages(eirm::eirm("response ~ 1 + (1|person) + (1|item)", data = long))
  m <- fit$model; m0 <- base$model

  b <- lme4::fixef(m)
  se <- sqrt(diag(as.matrix(stats::vcov(m))))
  keep <- names(b) %in% terms
  effects <- data.frame(term = names(b)[keep], label = unname(lab[names(b)[keep]]),
                        difficulty = -unname(b[keep]), se = unname(se[keep]),
                        stringsAsFactors = FALSE)
  effects$z <- effects$difficulty / effects$se
  effects$p.value <- 2 * stats::pnorm(-abs(effects$z))

  vc <- function(mod, grp) {
    v <- as.data.frame(lme4::VarCorr(mod))
    v$vcov[v$grp == grp][1]
  }
  # item difficulties: Rasch (base) and the part the graph predicts
  re0 <- lme4::ranef(m0)$item
  obs <- -(lme4::fixef(m0)[["(Intercept)"]] + re0[colnames(X), 1])
  Xc <- as.matrix(cov[colnames(X), intersect(terms, names(cov)), drop = FALSE])
  pred <- if (predictors == "concepts") -drop(Xc %*% b[colnames(Xc)]) else
    -(b[["(Intercept)"]] + drop(Xc %*% b[colnames(Xc)]))
  items <- data.frame(item = colnames(X),
                      concepts = apply(q[colnames(X), , drop = FALSE], 1,
                                       function(r) paste(colnames(q)[r == 1], collapse = ", ")),
                      difficulty = unname(obs), predicted = unname(pred),
                      stringsAsFactors = FALSE)
  items$residual <- items$difficulty - items$predicted

  v1 <- vc(m, "item"); v0 <- vc(m0, "item")
  fitstats <- data.frame(
    model = c("Rasch, random items", sprintf("Graph (%s)", predictors)),
    item_var = c(v0, v1), person_var = c(vc(m0, "person"), vc(m, "person")),
    AIC = c(stats::AIC(m0), stats::AIC(m)), BIC = c(stats::BIC(m0), stats::BIC(m)),
    stringsAsFactors = FALSE)
  structure(list(effects = as_tbl(effects), items = as_tbl(items), fit = as_tbl(fitstats),
                 explained = max(0, 1 - v1 / v0), predictors = predictors,
                 covariates = as.character(covariates),
                 model = fit, base = base, kg = kg, n = nrow(X)),
            class = "mv_kg_explain")
}

#' @export
print.mv_kg_explain <- function(x, ...) {
  cat(sprintf("<mv_kg_explain> %s: Item difficulty explained by %s\n",
              if (!is.na(x$kg$name)) x$kg$name else "Knowledge graph",
              paste0(if (x$predictors == "concepts") "concepts" else "learning-order depth",
                     if (length(x$covariates)) " and item metadata" else "")))
  cat(sprintf("%d items, N = %d. The graph explains %.0f%% of the item variance.\n",
              nrow(x$items), x$n, 100 * x$explained))
  e <- as.data.frame(x$effects)
  e$difficulty <- round(e$difficulty, 2); e$se <- round(e$se, 2)
  e$p.value <- format.pval(e$p.value, digits = 2, eps = 0.001)
  print(e[c("label", "difficulty", "se", "p.value")], row.names = FALSE)
  big <- x$items[abs(x$items$residual) > 2 * stats::sd(x$items$residual), , drop = FALSE]
  if (nrow(big))
    cat(strwrap(sprintf("Items the graph predicts poorly: %s.",
                        paste(sprintf("%s (%+.2f)", big$item, big$residual), collapse = ", "))),
        sep = "\n")
  invisible(x)
}

#' Tidy and glance methods for explained item difficulty
#'
#' @param x a result of [mv_kg_explain()].
#' @param what `"effects"` (the default) or `"items"` for `tidy()`.
#' @param ... unused.
#' @return A tibble.
#' @name tidy_mv_kg_explain
#' @export
tidy.mv_kg_explain <- function(x, what = c("effects", "items"), ...) {
  what <- match.arg(what)
  x[[what]]
}

#' @rdname tidy_mv_kg_explain
#' @export
glance.mv_kg_explain <- function(x, ...) {
  f <- x$fit
  as_tbl(data.frame(predictors = paste(c(x$predictors, x$covariates), collapse = " + "),
                    items = nrow(x$items), n = x$n,
                    explained = x$explained, item_var = f$item_var[2],
                    item_var_rasch = f$item_var[1], AIC = f$AIC[2], BIC = f$BIC[2],
                    BIC_rasch = f$BIC[1], stringsAsFactors = FALSE))
}
