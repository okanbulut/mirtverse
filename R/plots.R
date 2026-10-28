#' A clean ggplot2 theme for psychometric graphics
#'
#' @param base_size base font size.
#' @return A ggplot2 theme.
#' @export
theme_mirtverse <- function(base_size = 11) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold", hjust = 0),
      plot.title = ggplot2::element_text(face = "bold"),
      plot.title.position = "plot",
      legend.position = "bottom")
}

mv_colours <- c(primary = "#2C5F8A", accent = "#D1495B", good = "#2E8B57",
                warn = "#E09F3E", grey = "#7A7A7A")

#' Item characteristic (trace) curves
#'
#' @param x a unidimensional model returned by [mirt::mirt()].
#' @param which.items items to plot, by position or name. Defaults to all.
#' @param type `"prob"` for category probability curves or `"expected"` for
#'   the expected item score.
#' @param facet logical; one panel per item. If `FALSE` all items share one
#'   panel (only sensible for `type = "expected"` or dichotomous items).
#' @param theta_lim range of the latent trait.
#' @return A ggplot object.
#' @examples
#' mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
#' gg_trace(mod)
#' gg_trace(mod, facet = FALSE)
#' @export
gg_trace <- function(x, which.items = NULL, type = c("prob", "expected"),
                     facet = TRUE, theta_lim = c(-4, 4)) {
  check_single(x); check_unidim(x, "gg_trace()")
  type <- match.arg(type)
  df <- trace_data(x, which.items, theta_lim)
  dich <- all(mirt::extract.mirt(x, "K")[resolve_items(x, which.items)] == 2L)
  if (type == "expected") {
    df <- df[df$first, ]
    p <- ggplot2::ggplot(df, ggplot2::aes(theta, expected))
    p <- if (facet) p + ggplot2::geom_line(colour = mv_colours[["primary"]], linewidth = 0.9)
         else p + ggplot2::geom_line(ggplot2::aes(colour = item), linewidth = 0.9)
    p <- p + ggplot2::labs(y = "Expected item score")
  } else if (dich) {
    df <- df[df$top, ]
    p <- ggplot2::ggplot(df, ggplot2::aes(theta, prob))
    p <- if (facet) p + ggplot2::geom_line(colour = mv_colours[["primary"]], linewidth = 0.9)
         else p + ggplot2::geom_line(ggplot2::aes(colour = item), linewidth = 0.9)
    p <- p + ggplot2::scale_y_continuous(limits = c(0, 1)) +
      ggplot2::labs(y = "P(correct)")
  } else {
    p <- ggplot2::ggplot(df, ggplot2::aes(theta, prob, colour = category)) +
      ggplot2::geom_line(linewidth = 0.9) +
      ggplot2::scale_y_continuous(limits = c(0, 1)) +
      ggplot2::labs(y = "Probability", colour = "Category")
  }
  if (facet) p <- p + ggplot2::facet_wrap(~item)
  p + ggplot2::scale_colour_viridis_d(end = 0.9) +
    ggplot2::labs(x = expression(theta), title = "Item characteristic curves") +
    theme_mirtverse()
}

#' Test and item information curves
#'
#' @param x a unidimensional model returned by [mirt::mirt()].
#' @param type `"test"` for the test information function with its conditional
#'   standard error, `"items"` for item information curves, or `"se"` for the
#'   conditional standard error of measurement alone.
#' @param which.items items to include for `type = "items"`.
#' @param theta_lim range of the latent trait.
#' @return A ggplot object.
#' @examples
#' mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
#' gg_info(mod)
#' gg_info(mod, type = "items")
#' @export
gg_info <- function(x, type = c("test", "items", "se"), which.items = NULL,
                    theta_lim = c(-4, 4)) {
  check_single(x); check_unidim(x, "gg_info()")
  type <- match.arg(type)
  if (type == "items") {
    df <- info_data(x, which.items, theta_lim)
    return(ggplot2::ggplot(df, ggplot2::aes(theta, info, colour = item)) +
      ggplot2::geom_line(linewidth = 0.9) +
      ggplot2::scale_colour_viridis_d(end = 0.9) +
      ggplot2::labs(x = expression(theta), y = "Information", colour = NULL,
                    title = "Item information curves") +
      theme_mirtverse())
  }
  Theta <- matrix(theta_grid(theta_lim))
  ti <- mirt::testinfo(x, Theta)
  df <- data.frame(theta = Theta[, 1], info = ti, se = 1 / sqrt(ti))
  if (type == "se") {
    return(ggplot2::ggplot(df, ggplot2::aes(theta, se)) +
      ggplot2::geom_line(colour = mv_colours[["accent"]], linewidth = 1) +
      ggplot2::labs(x = expression(theta), y = "Standard error",
                    title = "Conditional standard error of measurement") +
      theme_mirtverse())
  }
  k <- max(df$info) / max(df$se[is.finite(df$se)])
  long <- rbind(data.frame(theta = df$theta, value = df$info, series = "Information"),
                data.frame(theta = df$theta, value = df$se * k, series = "Standard error"))
  ggplot2::ggplot(long, ggplot2::aes(theta, value, colour = series, linetype = series)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::scale_colour_manual(values = unname(mv_colours[c("primary", "accent")])) +
    ggplot2::scale_y_continuous(
      name = "Information",
      sec.axis = ggplot2::sec_axis(~ . / k, name = "Standard error")) +
    ggplot2::labs(x = expression(theta), colour = NULL, linetype = NULL,
                  title = "Test information and standard error") +
    theme_mirtverse()
}

#' Wright map (person-item map)
#'
#' Places the distribution of person estimates beside the item locations on
#' the same latent scale, so you can see whether the test is targeted at the
#' examinees. Polytomous items show each threshold.
#'
#' @param x a unidimensional model returned by [mirt::mirt()].
#' @param method scoring method for persons, passed to [mirt::fscores()].
#' @param thresholds logical; plot every threshold of polytomous items rather
#'   than their average location.
#' @param bins number of histogram bins for persons.
#' @return A patchwork object (a combined ggplot).
#' @examples
#' mod <- mirt(Science, 1, verbose = FALSE)
#' gg_wright(mod)
#' @export
gg_wright <- function(x, method = "EAP", thresholds = TRUE, bins = 30) {
  check_single(x); check_unidim(x, "gg_wright()")
  th <- as.numeric(mirt::fscores(x, method = method, verbose = FALSE)[, 1])
  th <- th[is.finite(th)]
  items <- wright_items(x, thresholds)
  lim <- range(c(th, items$difficulty), na.rm = TRUE) + c(-0.25, 0.25)
  p1 <- ggplot2::ggplot(data.frame(theta = th), ggplot2::aes(y = theta)) +
    ggplot2::geom_histogram(bins = bins, fill = mv_colours[["primary"]],
                            colour = "white") +
    ggplot2::scale_x_reverse() +
    ggplot2::coord_cartesian(ylim = lim) +
    ggplot2::labs(x = "Persons", y = expression(theta)) +
    theme_mirtverse()
  p2 <- ggplot2::ggplot(items, ggplot2::aes(x = item, y = difficulty)) +
    ggplot2::geom_point(ggplot2::aes(shape = label), size = 2.6,
                        colour = mv_colours[["accent"]]) +
    ggplot2::scale_y_continuous(position = "right") +
    ggplot2::coord_cartesian(ylim = lim) +
    ggplot2::labs(x = "Items", y = "Item location", shape = NULL) +
    theme_mirtverse() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90, vjust = 0.5, hjust = 1))
  if (length(unique(items$label)) == 1L) p2 <- p2 + ggplot2::guides(shape = "none")
  patchwork::wrap_plots(p1, p2, widths = c(1, 2)) +
    patchwork::plot_annotation(title = "Wright map",
                               theme = ggplot2::theme(plot.title = ggplot2::element_text(face = "bold")))
}

wright_items <- function(x, thresholds = TRUE) {
  nms <- item_names(x)
  cf <- safe(mirt::coef(x, IRTpars = TRUE, simplify = TRUE)$items)
  bcols <- if (is.null(cf)) integer() else grep("^b[0-9]*$", colnames(cf))
  if (thresholds && length(bcols) > 1L) {
    rows <- lapply(seq_along(nms), function(j) {
      b <- cf[j, bcols]
      b <- b[!is.na(b)]
      if (!length(b)) return(NULL)
      data.frame(item = nms[j], difficulty = as.numeric(b),
                 label = if (length(b) > 1) paste0("Threshold ", seq_along(b)) else "Location")
    })
    out <- do.call(rbind, rows)
  } else {
    out <- data.frame(item = nms, difficulty = as.numeric(item_locations(x)),
                      label = "Location")
  }
  out$item <- factor(out$item, levels = nms)
  out
}

#' Item fit plot
#'
#' Shows the RMSEA of the S-X2 item-fit statistic for each item and marks
#' items whose p-value falls below `alpha`.
#'
#' @param x a model returned by [mirt::mirt()].
#' @param alpha significance level for flagging misfit.
#' @param p_adjust p-value adjustment (see [stats::p.adjust()]).
#' @return A ggplot object.
#' @examples
#' mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
#' gg_itemfit(mod)
#' @export
gg_itemfit <- function(x, alpha = 0.01, p_adjust = "none") {
  check_single(x)
  dat <- mirt::extract.mirt(x, "data")
  fit <- mirt::itemfit(x, fit_stats = "S_X2", na.rm = anyNA(dat))
  fit$p.value <- stats::p.adjust(fit$p.S_X2, method = p_adjust)
  fit$status <- ifelse(fit$p.value < alpha, "Misfit", "Acceptable")
  fit$item <- factor(fit$item, levels = rev(fit$item))
  ggplot2::ggplot(fit, ggplot2::aes(x = RMSEA.S_X2, y = item, colour = status)) +
    ggplot2::geom_segment(ggplot2::aes(x = 0, xend = RMSEA.S_X2, yend = item),
                          colour = "grey80") +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_vline(xintercept = 0.05, linetype = 2, colour = "grey50") +
    ggplot2::scale_colour_manual(values = c(Acceptable = mv_colours[["good"]],
                                            Misfit = mv_colours[["accent"]]),
                                 drop = FALSE) +
    ggplot2::labs(x = "RMSEA (S-X2)", y = NULL, colour = NULL,
                  title = "Item fit",
                  subtitle = sprintf("Red points: p < %s; dashed line: RMSEA = .05", alpha)) +
    theme_mirtverse()
}

#' Local dependence heatmap (Yen's Q3)
#'
#' @param x a model returned by [mirt::mirt()].
#' @param cutoff absolute residual correlation above the average Q3 that is
#'   marked as possible local dependence (0.2 by default, Christensen et al.,
#'   2017).
#' @param label logical; print values in flagged cells.
#' @return A ggplot object.
#' @examples
#' mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
#' gg_q3(mod)
#' @export
gg_q3 <- function(x, cutoff = 0.2, label = TRUE) {
  q3 <- q3_long(x, cutoff)
  p <- ggplot2::ggplot(q3, ggplot2::aes(item1, item2, fill = Q3)) +
    ggplot2::geom_tile(colour = "white") +
    ggplot2::scale_fill_gradient2(low = mv_colours[["primary"]], mid = "white",
                                  high = mv_colours[["accent"]], midpoint = 0,
                                  limits = c(-1, 1)) +
    ggplot2::coord_fixed() +
    ggplot2::labs(x = NULL, y = NULL, title = "Local dependence (Q3)",
                  subtitle = sprintf("Labelled cells exceed the average Q3 by more than %s", cutoff)) +
    theme_mirtverse() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90, vjust = 0.5, hjust = 1),
                   panel.grid = ggplot2::element_blank())
  if (label && any(q3$flag))
    p <- p + ggplot2::geom_text(data = q3[q3$flag, ],
                                ggplot2::aes(label = sub("^(-?)0", "\\1", fmt(Q3))), size = 3)
  p
}

q3_long <- function(x, cutoff = 0.2) {
  check_single(x)
  dat <- mirt::extract.mirt(x, "data")
  q3 <- suppressMessages(mirt::residuals(x, type = "Q3", verbose = FALSE))
  q3 <- unclass(q3)
  nms <- item_names(x)
  dimnames(q3) <- list(nms, nms)
  avg <- mean(q3[upper.tri(q3)], na.rm = TRUE)
  idx <- which(lower.tri(q3), arr.ind = TRUE)
  out <- data.frame(item1 = factor(nms[idx[, 2]], levels = nms),
                    item2 = factor(nms[idx[, 1]], levels = rev(nms)),
                    Q3 = q3[idx])
  out$flag <- (out$Q3 - avg) > cutoff
  attr(out, "average") <- avg
  out
}

#' Distribution of person scores
#'
#' @param x a model returned by [mirt::mirt()].
#' @param method scoring method passed to [mirt::fscores()].
#' @return A ggplot object.
#' @examples
#' mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
#' gg_scores(mod)
#' @export
gg_scores <- function(x, method = "EAP") {
  check_single(x)
  fs <- mirt::fscores(x, method = method, full.scores.SE = TRUE, verbose = FALSE)
  df <- data.frame(theta = fs[, 1], se = fs[, 1 + mirt::extract.mirt(x, "nfact")])
  df <- df[is.finite(df$theta), ]
  ggplot2::ggplot(df, ggplot2::aes(theta)) +
    ggplot2::geom_histogram(ggplot2::aes(y = ggplot2::after_stat(density)),
                            bins = 30, fill = mv_colours[["primary"]], colour = "white") +
    ggplot2::geom_density(colour = mv_colours[["accent"]], linewidth = 0.9) +
    ggplot2::labs(x = sprintf("%s estimate of theta", method), y = "Density",
                  title = "Distribution of person scores") +
    theme_mirtverse()
}

#' Empirical versus model-implied item curve
#'
#' Groups examinees by their ability estimate and compares the observed mean
#' item score in each group (with 95% intervals) with the model-implied curve.
#' Large departures point to misfit.
#'
#' @param x a unidimensional model returned by [mirt::mirt()].
#' @param item a single item, by position or name.
#' @param bins number of ability groups.
#' @param theta_lim range of the latent trait.
#' @return A ggplot object.
#' @examples
#' mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
#' gg_empirical(mod, 1)
#' @export
gg_empirical <- function(x, item, bins = 10, theta_lim = c(-3, 3)) {
  check_single(x); check_unidim(x, "gg_empirical()")
  j <- resolve_items(x, item)[1]
  emp <- empirical_curve(x, j, bins)
  model <- trace_data(x, j, theta_lim)
  model <- model[model$first, ]
  ggplot2::ggplot() +
    ggplot2::geom_line(data = model, ggplot2::aes(theta, expected),
                       colour = mv_colours[["primary"]], linewidth = 1) +
    ggplot2::geom_errorbar(data = emp, ggplot2::aes(x = theta, ymin = lower, ymax = upper),
                           width = 0.08, colour = mv_colours[["grey"]]) +
    ggplot2::geom_point(data = emp, ggplot2::aes(theta, observed),
                        colour = mv_colours[["accent"]], size = 2.4) +
    ggplot2::labs(x = expression(theta), y = "Mean item score",
                  title = sprintf("Observed vs. expected: %s", item_names(x)[j])) +
    theme_mirtverse()
}

empirical_curve <- function(x, j, bins = 10) {
  dat <- mirt::extract.mirt(x, "data")
  th <- as.numeric(mirt::fscores(x, verbose = FALSE)[, 1])
  y <- dat[, j]
  ok <- !is.na(y) & is.finite(th)
  th <- th[ok]; y <- y[ok]
  brk <- unique(stats::quantile(th, probs = seq(0, 1, length.out = bins + 1)))
  g <- cut(th, brk, include.lowest = TRUE)
  agg <- lapply(split(seq_along(y), g), function(i) {
    if (!length(i)) return(NULL)
    m <- mean(y[i]); s <- if (length(i) > 1) stats::sd(y[i]) / sqrt(length(i)) else 0
    data.frame(theta = mean(th[i]), observed = m, lower = m - 1.96 * s,
               upper = m + 1.96 * s, n = length(i))
  })
  do.call(rbind, agg)
}

#' Plot a mirt model with ggplot2
#'
#' A single entry point to the mirtverse graphics.
#'
#' @param object a model returned by [mirt::mirt()].
#' @param type one of `"trace"`, `"expected"`, `"info"`, `"iteminfo"`, `"se"`,
#'   `"wright"`, `"itemfit"`, `"q3"`, or `"scores"`.
#' @param ... passed to the matching `gg_*()` function.
#' @return A ggplot object.
#' @examples
#' mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
#' ggplot2::autoplot(mod, "wright")
#' @importFrom ggplot2 autoplot
#' @method autoplot SingleGroupClass
#' @export
autoplot.SingleGroupClass <- function(object, type = c("trace", "expected", "info",
                                                       "iteminfo", "se", "wright",
                                                       "itemfit", "q3", "scores"), ...) {
  type <- match.arg(type)
  switch(type,
         trace = gg_trace(object, ...),
         expected = gg_trace(object, type = "expected", ...),
         info = gg_info(object, "test", ...),
         iteminfo = gg_info(object, "items", ...),
         se = gg_info(object, "se", ...),
         wright = gg_wright(object, ...),
         itemfit = gg_itemfit(object, ...),
         q3 = gg_q3(object, ...),
         scores = gg_scores(object, ...))
}

#' @importFrom ggplot2 autoplot
#' @export
ggplot2::autoplot
