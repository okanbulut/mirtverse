#' Differential item functioning (DIF) in one call
#'
#' Tests every item for DIF between groups (for example by gender or language)
#' and reports the results as a tidy table with effect sizes. The analysis uses
#' the constrained-baseline approach: a multiple-group model is fitted with all
#' item parameters equal across groups and free latent means and variances,
#' then each item's parameters are freed in turn and compared with a
#' likelihood-ratio test ([mirt::DIF()] with `scheme = "drop"`).
#'
#' Effect sizes are reported for two-group comparisons as the difference in
#' expected item score between the focal and the reference group at the same
#' ability, averaged over the focal group's ability distribution: `esd` is the
#' signed difference (positive values mean the item is easier for, or favours,
#' the focal group) and `uesd` the unsigned difference, which also captures
#' crossing (non-uniform) DIF. Both are on the item score scale, so for 0/1
#' items they are differences in the probability of a correct answer.
#'
#' @param x a data frame or matrix of item responses, or a
#'   [mirt::multipleGroup()] model whose item parameters are constrained to be
#'   equal across groups (the baseline model).
#' @param group the grouping variable: a vector with one value per respondent,
#'   or the name of a column of `x` (that column is then not treated as an
#'   item). The first group is the reference group: the first level of a
#'   factor, otherwise the first value in sorted order. Ignored when `x` is a
#'   model.
#' @param model item type passed to [mirt::multipleGroup()], e.g. `"Rasch"`,
#'   `"2PL"`, `"3PL"`, `"graded"` or `"gpcm"`. Ignored when `x` is a model.
#' @param items items to test, by name or position. Defaults to all items;
#'   untested items act as anchors.
#' @param which.par parameters to test. Defaults to all estimated item
#'   parameters (for example `a1` and `d` for the 2PL).
#' @param p_adjust p-value adjustment across items (see [stats::p.adjust()]).
#' @param alpha significance level for flagging an item, applied to the
#'   adjusted p-values.
#' @param verbose logical; show progress.
#' @param ... further arguments passed to [mirt::multipleGroup()].
#'
#' @return An object of class `mv_dif` with elements `table` (one row per
#'   tested item: `item`, `X2`, `df`, `p.value`, `p.adjusted`, `flag`, `esd`,
#'   `uesd`, `converged`), `baseline` (the constrained model), `models` (the
#'   models with each item freed), `groups`, `reference`, `focal`,
#'   `which.par`, `alpha` and `p_adjust`. Use [tidy()], [gg_dif()] and
#'   [interpret()] on it.
#' @examples
#' \donttest{
#' set.seed(1)
#' a <- matrix(rlnorm(8, 0.2, 0.3)); d <- matrix(rnorm(8))
#' d2 <- d; d2[1] <- d2[1] - 1
#' data <- rbind(simdata(a, d, 400, itemtype = "2PL"),
#'               simdata(a, d2, 400, itemtype = "2PL"))
#' gender <- rep(c("F", "M"), each = 400)
#' res <- dif(data, group = gender)
#' res
#' gg_dif(res)
#' interpret(res)
#' }
#' @export
dif <- function(x, group = NULL, model = "2PL", items = NULL, which.par = NULL,
                p_adjust = "BH", alpha = 0.05, verbose = FALSE, ...) {
  if (methods::is(x, "MultipleGroupClass")) {
    baseline <- x
    if (!length(mirt::extract.mirt(baseline, "constrain")))
      warning("The model has no equality constraints across groups, so there are no anchor items; ",
              "fit it with invariance = c(colnames(data), \"free_means\", \"free_var\").",
              call. = FALSE)
  } else {
    if (methods::is(x, "SingleGroupClass"))
      stop("`x` must be item responses or a multipleGroup() model; to test DIF, ",
           "pass the data and a `group` variable.", call. = FALSE)
    x <- as.data.frame(x)
    if (is.character(group) && length(group) == 1L && nrow(x) != 1L) {
      if (!group %in% names(x))
        stop(sprintf("`group` column \"%s\" is not in the data.", group), call. = FALSE)
      gname <- group
      group <- x[[gname]]
      x[[gname]] <- NULL
    }
    if (is.null(group)) stop("`group` is required.", call. = FALSE)
    if (length(group) != nrow(x))
      stop("`group` must have one value per respondent (row of the data).", call. = FALSE)
    keep <- !is.na(group)
    if (!all(keep)) {
      if (verbose) message(sum(!keep), " respondents with a missing group were dropped.")
      x <- x[keep, , drop = FALSE]
      group <- group[keep]
    }
    group <- if (is.factor(group)) droplevels(group) else as.character(group)
    sizes <- table(group)
    if (length(sizes) < 2L) stop("`group` must have at least two groups.", call. = FALSE)
    if (any(sizes < 100L))
      warning("Some groups have fewer than 100 respondents (",
              paste(sprintf("%s: %d", names(sizes), as.integer(sizes)), collapse = ", "),
              "); DIF results will be unstable.", call. = FALSE)
    baseline <- mirt::multipleGroup(x, 1, group = group, itemtype = model,
                                    invariance = c(colnames(x), "free_means", "free_var"),
                                    verbose = FALSE, ...)
  }

  nms <- item_names(baseline)
  idx <- if (is.null(items)) seq_along(nms) else {
    if (is.character(items)) {
      bad <- setdiff(items, nms)
      if (length(bad)) stop("Unknown item(s): ", paste(bad, collapse = ", "), call. = FALSE)
      match(items, nms)
    } else as.integer(items)
  }
  if (length(idx) == length(nms) && !is.null(items))
    warning("Testing every item leaves no pure anchor items; results rely on the other items being DIF-free.",
            call. = FALSE)
  if (is.null(which.par)) which.par <- default_dif_pars(baseline, nms[idx])

  models <- mirt::DIF(baseline, which.par = which.par, scheme = "drop", items2test = idx,
                      return_models = TRUE, verbose = verbose)
  groups <- mirt::extract.mirt(baseline, "groupNames")
  ll0 <- mirt::extract.mirt(baseline, "logLik")
  np0 <- mirt::extract.mirt(baseline, "nest")
  rows <- lapply(names(models), function(nm) {
    m <- models[[nm]]
    X2 <- 2 * (mirt::extract.mirt(m, "logLik") - ll0)
    df <- mirt::extract.mirt(m, "nest") - np0
    es <- if (length(groups) == 2L) dif_effect(m, nm, groups) else c(NA_real_, NA_real_)
    data.frame(item = nm, X2 = X2, df = df,
               p.value = stats::pchisq(pmax(X2, 0), df, lower.tail = FALSE),
               esd = es[1], uesd = es[2],
               converged = isTRUE(mirt::extract.mirt(m, "converged")),
               stringsAsFactors = FALSE)
  })
  tab <- do.call(rbind, rows)
  tab$p.adjusted <- stats::p.adjust(tab$p.value, method = p_adjust)
  tab$flag <- tab$p.adjusted < alpha
  tab <- as_tbl(tab[, c("item", "X2", "df", "p.value", "p.adjusted", "flag", "esd", "uesd",
                        "converged")])

  structure(list(table = tab, baseline = baseline, models = models, groups = groups,
                 reference = groups[1], focal = groups[-1], which.par = which.par,
                 alpha = alpha, p_adjust = p_adjust),
            class = "mv_dif")
}

# All freely estimated item parameters of the tested items
default_dif_pars <- function(model, items) {
  sv <- mirt::mod2values(model)
  sv <- sv[sv$group == sv$group[1] & sv$item %in% items & sv$est, ]
  unique(sv$name)
}

# Signed and unsigned expected-score difference (focal minus reference),
# weighted by the focal group's latent distribution
dif_effect <- function(m, item, groups) {
  Theta <- matrix(theta_grid(c(-6, 6), 241))
  gp <- mirt::coef(m)[[groups[2]]]$GroupPars
  w <- stats::dnorm(Theta[, 1], gp[1, "MEAN_1"], sqrt(gp[1, "COV_11"]))
  w <- w / sum(w)
  e <- vapply(groups, function(g) {
    it <- mirt::extract.item(mirt::extract.group(m, group = g), item)
    mirt::expected.item(it, Theta)
  }, numeric(nrow(Theta)))
  diff <- e[, 2] - e[, 1]
  c(sum(w * diff), sum(w * abs(diff)))
}

#' @method print mv_dif
#' @export
print.mv_dif <- function(x, ...) {
  tab <- x$table
  cat(sprintf("DIF analysis: %s (reference) vs %s; %d items tested\n",
              x$reference, paste(x$focal, collapse = ", "), nrow(tab)))
  cat(sprintf("Likelihood-ratio tests freeing %s; %s-adjusted p < %s flags DIF\n\n",
              paste(x$which.par, collapse = ", "), x$p_adjust, x$alpha))
  show <- as.data.frame(tab)
  num <- c("X2", "esd", "uesd")
  show[num] <- lapply(show[num], function(v) round(v, 3))
  show$p.value <- fmt_p(show$p.value)
  show$p.adjusted <- fmt_p(show$p.adjusted)
  show$flag <- ifelse(tab$flag, "DIF", "")
  print(show, row.names = FALSE)
  if (any(!tab$converged))
    cat("\nWarning: some models did not converge:", paste(tab$item[!tab$converged], collapse = ", "), "\n")
  invisible(x)
}

#' @method tidy mv_dif
#' @export
tidy.mv_dif <- function(x, ...) x$table

#' DIF effect sizes plot
#'
#' `type = "effect"` shows the signed expected-score difference for each item,
#' with flagged items highlighted; `type = "curves"` overlays the expected item
#' score curves of each group for the chosen (by default the flagged) items.
#'
#' @param x an `mv_dif` object from [dif()].
#' @param type `"effect"` or `"curves"`.
#' @param which.items items to draw for `type = "curves"`, by name. Defaults to
#'   the flagged items, or the item with the largest effect if none is flagged.
#' @param theta_lim range of the latent trait for `type = "curves"`.
#' @return A ggplot object.
#' @examples
#' \donttest{
#' set.seed(1)
#' a <- matrix(rlnorm(8, 0.2, 0.3)); d <- matrix(rnorm(8))
#' d2 <- d; d2[1] <- d2[1] - 1
#' data <- rbind(simdata(a, d, 400, itemtype = "2PL"),
#'               simdata(a, d2, 400, itemtype = "2PL"))
#' res <- dif(data, group = rep(c("F", "M"), each = 400))
#' gg_dif(res)
#' gg_dif(res, type = "curves")
#' }
#' @export
gg_dif <- function(x, type = c("effect", "curves"), which.items = NULL,
                   theta_lim = c(-4, 4)) {
  if (!inherits(x, "mv_dif")) stop("`x` must be the result of dif().", call. = FALSE)
  type <- match.arg(type)
  tab <- as.data.frame(x$table)
  if (type == "effect") {
    if (all(is.na(tab$esd)))
      stop("Effect sizes are only available for two groups; use type = \"curves\".", call. = FALSE)
    tab$status <- factor(ifelse(tab$flag, "DIF", "No DIF"), levels = c("DIF", "No DIF"))
    tab$item <- factor(tab$item, levels = rev(tab$item))
    return(ggplot2::ggplot(tab, ggplot2::aes(x = esd, y = item, colour = status)) +
      ggplot2::geom_vline(xintercept = 0, colour = "grey50") +
      ggplot2::geom_segment(ggplot2::aes(x = 0, xend = esd, yend = item), colour = "grey80") +
      ggplot2::geom_point(size = 3) +
      ggplot2::scale_colour_manual(values = c(DIF = mv_colours[["accent"]],
                                              `No DIF` = mv_colours[["primary"]]),
                                   drop = FALSE) +
      ggplot2::labs(x = sprintf("Expected score difference (%s minus %s)", x$focal, x$reference),
                    y = NULL, colour = NULL, title = "Differential item functioning",
                    subtitle = sprintf("Right of zero: easier for %s at the same ability. Red: %s-adjusted p < %s",
                                       x$focal, x$p_adjust, x$alpha)) +
      theme_mirtverse())
  }
  if (is.null(which.items)) {
    which.items <- tab$item[tab$flag]
    if (!length(which.items))
      which.items <- tab$item[which.max(if (all(is.na(tab$uesd))) tab$X2 else tab$uesd)]
  }
  bad <- setdiff(which.items, names(x$models))
  if (length(bad)) stop("Item(s) not tested: ", paste(bad, collapse = ", "), call. = FALSE)
  Theta <- matrix(theta_grid(theta_lim))
  d <- do.call(rbind, lapply(which.items, function(nm) {
    do.call(rbind, lapply(x$groups, function(g) {
      it <- mirt::extract.item(mirt::extract.group(x$models[[nm]], group = g), nm)
      data.frame(item = nm, group = g, theta = Theta[, 1],
                 expected = mirt::expected.item(it, Theta), stringsAsFactors = FALSE)
    }))
  }))
  d$item <- factor(d$item, levels = which.items)
  d$group <- factor(d$group, levels = x$groups)
  ggplot2::ggplot(d, ggplot2::aes(theta, expected, colour = group)) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::facet_wrap(~item) +
    ggplot2::scale_colour_manual(values = unname(c(mv_colours[c("primary", "accent", "good", "warn")],
                                                   grDevices::hcl.colors(8))[seq_along(x$groups)])) +
    ggplot2::labs(x = expression(theta), y = "Expected item score", colour = NULL,
                  title = "Item curves by group",
                  subtitle = "Curves estimated with the item's parameters free across groups") +
    theme_mirtverse()
}

#' @rdname interpret
#' @method interpret mv_dif
#' @export
interpret.mv_dif <- function(x, ...) {
  tab <- as.data.frame(x$table)
  bl <- x$baseline
  n <- table(mirt::extract.mirt(bl, "group"))
  out <- list()
  out$`DIF overview` <- c(
    sprintf("Items were tested for DIF between %s, with %s as the reference group (%s).",
            paste(x$groups, collapse = " and "), x$reference,
            paste(sprintf("n = %d %s", as.integer(n[x$groups]), x$groups), collapse = ", ")),
    sprintf("Each item's parameters (%s) were freed in turn and compared with a model holding them equal across groups (likelihood-ratio test, %s-adjusted p < %s).",
            paste(x$which.par, collapse = ", "), x$p_adjust, x$alpha))
  if (length(x$groups) == 2L) {
    gp <- mirt::coef(bl)[[x$focal]]$GroupPars
    out$`DIF overview` <- c(out$`DIF overview`, sprintf(
      "On the common scale, the %s group's mean ability is %s SD %s the %s group's, and its SD is %s.",
      x$focal, fmt(abs(gp[1, "MEAN_1"])), if (gp[1, "MEAN_1"] >= 0) "above" else "below",
      x$reference, fmt(sqrt(gp[1, "COV_11"]))))
  }
  f <- tab[tab$flag, ]
  out$`DIF items` <- if (!nrow(f)) {
    sprintf("No items show statistically significant DIF (%d tested).", nrow(tab))
  } else if (length(x$groups) == 2L) {
    f <- f[order(-f$uesd), ]
    c(sprintf("%d of %d items show DIF: %s.", nrow(f), nrow(tab), paste(sprintf(
        "%s (expected score difference %s, %s; p %s)", f$item, fmt(f$esd, 3),
        ifelse(f$esd >= 0, paste("favours", x$focal), paste("favours", x$reference)),
        ifelse(f$p.adjusted < .001, "< .001", paste("=", fmt_p(f$p.adjusted)))), collapse = "; ")),
      if (any(f$uesd > 2 * abs(f$esd) + 0.01))
        sprintf("For %s the unsigned difference is much larger than the signed one, which suggests the curves cross (non-uniform DIF); see gg_dif(x, type = \"curves\").",
                paste(f$item[f$uesd > 2 * abs(f$esd) + 0.01], collapse = ", ")),
      "Statistical DIF is not proof of bias: ask content experts whether these items measure something other than the intended ability for one group before removing or revising them.")
  } else {
    sprintf("%d of %d items show DIF across the %d groups: %s.", nrow(f), nrow(tab),
            length(x$groups), paste(f$item, collapse = ", "))
  }
  if (any(!tab$converged))
    out$`DIF items` <- c(out$`DIF items`, sprintf("Some models did not converge (%s); treat those results with caution.",
                                                  paste(tab$item[!tab$converged], collapse = ", ")))
  structure(out, class = "mv_interpretation")
}
