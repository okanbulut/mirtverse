#' Model selection assistant
#'
#' Fits a set of candidate IRT models to the same data, compares them on
#' information criteria, likelihood-ratio tests and limited-information fit,
#' and recommends one with a plain-language explanation.
#'
#' By default the candidates depend on the data: for dichotomous items the
#' Rasch, 2PL and 3PL models; for polytomous (or mixed) items the partial
#' credit (Rasch), generalized partial credit and graded response models.
#' Set `dims = 1:2` to also try two-factor exploratory versions.
#'
#' @param data a data frame or matrix of item responses.
#' @param candidates optional character vector of `itemtype` values passed to
#'   [mirt::mirt()].
#' @param dims number(s) of latent dimensions to try.
#' @param criterion information criterion used to rank models.
#' @param fit logical; compute M2/C2 fit statistics for each model.
#' @param verbose logical; print progress.
#' @param ... further arguments passed to [mirt::mirt()].
#'
#' @return An object of class `mv_model_selection` with elements `table`
#'   (comparison table), `models` (fitted models), `best` (the recommended
#'   model), `lrt` (likelihood-ratio tests between nested models) and
#'   `explanation` (text).
#' @examples
#' \donttest{
#' sel <- select_model(expand.table(LSAT7))
#' sel
#' sel$best
#' }
#' @export
select_model <- function(data, candidates = NULL, dims = 1,
                         criterion = c("BIC", "AIC", "SABIC"),
                         fit = TRUE, verbose = TRUE, ...) {
  criterion <- match.arg(criterion)
  data <- as.data.frame(data)
  K <- vapply(data, function(v) length(unique(stats::na.omit(v))), integer(1))
  dich <- all(K <= 2L)
  if (is.null(candidates))
    candidates <- if (dich) c("Rasch", "2PL", "3PL") else c("Rasch", "gpcm", "graded")
  grid <- expand.grid(itemtype = candidates, nfact = dims, stringsAsFactors = FALSE)
  # the Rasch and 3PL models are only offered unidimensionally
  grid <- grid[!(grid$nfact > 1 & grid$itemtype %in% c("Rasch", "3PL")), , drop = FALSE]
  labels <- ifelse(grid$nfact == 1, display_itemtype(grid$itemtype, dich),
                   paste0(display_itemtype(grid$itemtype, dich), " (", grid$nfact, "F)"))
  models <- vector("list", nrow(grid))
  names(models) <- labels
  for (i in seq_len(nrow(grid))) {
    if (verbose) message("Fitting ", labels[i], " ...")
    models[[i]] <- safe(mirt::mirt(data, grid$nfact[i], itemtype = grid$itemtype[i],
                                   verbose = FALSE, ...))
  }
  ok <- !vapply(models, is.null, logical(1))
  if (!any(ok)) stop("None of the candidate models could be estimated.", call. = FALSE)
  if (any(!ok) && verbose)
    message("Could not estimate: ", paste(labels[!ok], collapse = ", "))
  models <- models[ok]; grid <- grid[ok, , drop = FALSE]
  tab <- do.call(rbind, lapply(names(models), function(nm) {
    g <- glance.SingleGroupClass(models[[nm]], fit = fit)
    data.frame(model = nm, itemtype = grid$itemtype[match(nm, names(models))],
               nfact = g$nfact, npar = g$npar, logLik = g$logLik, AIC = g$AIC,
               BIC = g$BIC, SABIC = g$SABIC, converged = g$converged,
               RMSEA = if (fit) g$RMSEA else NA_real_,
               CFI = if (fit) g$CFI else NA_real_,
               SRMSR = if (fit) g$SRMSR else NA_real_,
               stringsAsFactors = FALSE)
  }))
  crit <- tab[[criterion]]
  crit_ok <- ifelse(tab$converged, crit, Inf)
  tab$delta <- crit - min(crit_ok)
  tab$weight <- exp(-tab$delta / 2) / sum(exp(-tab$delta[is.finite(crit_ok)] / 2))
  tab$weight[!is.finite(crit_ok)] <- 0
  tab <- tab[order(crit_ok, tab$npar), ]
  best_name <- tab$model[1]
  lrt <- nested_lrt(models, tab)
  res <- structure(list(
    table = as_tbl(tab), models = models, best = models[[best_name]],
    best_name = best_name, criterion = criterion, lrt = lrt,
    dichotomous = dich), class = "mv_model_selection")
  res$explanation <- explain_selection(res)
  res
}

display_itemtype <- function(itemtype, dich) {
  lab <- c(Rasch = if (dich) "Rasch" else "PCM (Rasch)", `2PL` = "2PL", `3PL` = "3PL",
           `4PL` = "4PL", gpcm = "GPCM", graded = "GRM", rsm = "RSM",
           nominal = "Nominal")
  out <- unname(lab[itemtype])
  ifelse(is.na(out), itemtype, out)
}

nested_lrt <- function(models, tab) {
  tab <- tab[order(tab$npar), ]
  out <- list()
  for (i in seq_len(nrow(tab) - 1)) for (k in (i + 1):nrow(tab)) {
    a <- tab[i, ]; b <- tab[k, ]
    nested <- (a$nfact <= b$nfact) &&
      ((a$itemtype == b$itemtype) ||
         (a$itemtype == "Rasch" && b$itemtype %in% c("2PL", "3PL", "gpcm")) ||
         (a$itemtype == "2PL" && b$itemtype == "3PL"))
    if (!nested || b$npar <= a$npar) next
    X2 <- 2 * (b$logLik - a$logLik)
    df <- b$npar - a$npar
    out[[length(out) + 1]] <- data.frame(
      simpler = a$model, complex = b$model, X2 = X2, df = df,
      p.value = stats::pchisq(X2, df, lower.tail = FALSE), stringsAsFactors = FALSE)
  }
  if (!length(out)) return(as_tbl(data.frame(simpler = character(), complex = character(),
                                             X2 = numeric(), df = numeric(),
                                             p.value = numeric())))
  as_tbl(do.call(rbind, out))
}

explain_selection <- function(sel) {
  tab <- sel$table
  best <- tab[1, ]
  txt <- sprintf("The %s model is recommended because it has the lowest %s (%s).",
                 best$model, sel$criterion, fmt(best[[sel$criterion]], 1))
  if (nrow(tab) > 1) {
    d <- tab$delta[2]
    strength <- if (d > 10) "very strong" else if (d > 6) "strong" else
      if (d > 2) "positive" else "weak"
    txt <- c(txt, sprintf("The runner-up, %s, is %s %s points worse, which is %s evidence for the %s model.",
                          tab$model[2], fmt(d, 1), sel$criterion, strength, best$model))
    if (d <= 2)
      txt <- c(txt, sprintf("Because the difference is small, the simpler of the two (%s) is a defensible choice too.",
                            tab$model[which.min(tab$npar[1:2])]))
  }
  lrt <- sel$lrt
  if (nrow(lrt)) {
    hit <- lrt[lrt$simpler == best$model | lrt$complex == best$model, ]
    for (i in seq_len(nrow(hit))) {
      h <- hit[i, ]
      txt <- c(txt, sprintf("Likelihood-ratio test %s vs. %s: chi-square(%d) = %s, p %s; %s.",
                            h$simpler, h$complex, as.integer(h$df), fmt(h$X2, 2),
                            ifelse(h$p.value < .001, "< .001", paste("=", fmt_p(h$p.value))),
                            if (h$p.value < .05) sprintf("the %s model fits significantly better", h$complex)
                            else sprintf("the extra parameters of %s are not needed", h$complex)))
    }
  }
  if (nrow(lrt)) {
    beats_best <- lrt$simpler == best$model & lrt$p.value < .05
    if (any(beats_best))
      txt <- c(txt, sprintf("Note the tension: the likelihood-ratio test prefers %s, while %s penalizes extra parameters and prefers %s. Choose %s if parsimony matters most, or %s if fit to these data matters most.",
                            paste(lrt$complex[beats_best], collapse = " / "), sel$criterion,
                            best$model, best$model, lrt$complex[beats_best][1]))
  }
  other <- setdiff(c("AIC", "BIC"), sel$criterion)[1]
  alt <- tab$model[which.min(ifelse(tab$converged, tab[[other]], Inf))]
  if (alt != best$model)
    txt <- c(txt, sprintf("%s would instead select the %s model.", other, alt))
  if (!is.na(best$RMSEA))
    txt <- c(txt, sprintf("Absolute fit of the %s model: RMSEA = %s (%s fit), CFI = %s, SRMSR = %s.",
                          best$model, fmt(best$RMSEA, 3), rmsea_label(best$RMSEA),
                          fmt(best$CFI, 3), fmt(best$SRMSR, 3)))
  if (any(!tab$converged))
    txt <- c(txt, sprintf("Not converged (excluded from the recommendation): %s.",
                          paste(tab$model[!tab$converged], collapse = ", ")))
  txt
}

rmsea_label <- function(r) {
  if (is.na(r)) return("not available")
  if (r <= .05) "close" else if (r <= .08) "reasonable" else
    if (r <= .10) "mediocre" else "poor"
}

#' @method print mv_model_selection
#' @export
print.mv_model_selection <- function(x, ...) {
  cat("mirtverse model selection (ranked by ", x$criterion, ")\n\n", sep = "")
  tab <- as.data.frame(x$table)
  show <- tab[, c("model", "npar", "logLik", "AIC", "BIC", "SABIC", "RMSEA", "CFI", "delta", "weight")]
  num <- vapply(show, is.numeric, logical(1))
  show[num] <- lapply(show[num], function(v) round(v, 3))
  print(show, row.names = FALSE)
  cat("\n", paste(strwrap(paste(x$explanation, collapse = " "), width = 80), collapse = "\n"),
      "\n", sep = "")
  invisible(x)
}

#' @method tidy mv_model_selection
#' @export
tidy.mv_model_selection <- function(x, ...) x$table

#' @method autoplot mv_model_selection
#' @export
autoplot.mv_model_selection <- function(object, ...) {
  tab <- as.data.frame(object$table)
  tab$model <- factor(tab$model, levels = rev(tab$model))
  tab$best <- tab$model == object$best_name
  ggplot2::ggplot(tab, ggplot2::aes(x = delta, y = model, fill = best)) +
    ggplot2::geom_col(width = 0.6) +
    ggplot2::geom_vline(xintercept = c(2, 10), linetype = 2, colour = "grey60") +
    ggplot2::scale_fill_manual(values = c(`TRUE` = mv_colours[["good"]],
                                          `FALSE` = mv_colours[["grey"]]), guide = "none") +
    ggplot2::labs(x = bquote(Delta * .(object$criterion) ~ "(0 = best)"), y = NULL,
                  title = "Model comparison",
                  subtitle = "Dashed lines at 2 and 10: weak vs. very strong evidence") +
    theme_mirtverse()
}
