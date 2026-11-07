#' Place human and AI raters on the Wright map
#'
#' Fits a many-facet Rasch model (Linacre, 1989) in which human raters and
#' an automated scoring engine are elements of one rater facet, so that the
#' severity of each rater sits on the same logit scale as the test takers
#' and the items. A severe engine shows up as a rater above the human
#' raters on the map; an engine that is severe only for some items or some
#' groups of test takers shows up in the bias analysis.
#'
#' The model is fit as an explanatory item response model with the
#' [eirm](https://CRAN.R-project.org/package=eirm) package: The scores are
#' split into adjacent-category steps with [eirm::polyreformat()], so that
#' the model is a partial credit model (Rasch for 0/1 scores) with a rater
#' facet, estimated as a generalized linear mixed model with a random person
#' effect,
#'
#' \deqn{\mathrm{logit}\, P(X_{pir} = k \mid k-1 \text{ or } k) = \theta_p - \delta_{ik} - \lambda_{r},}
#'
#' where \eqn{\lambda_r} is the severity of rater \eqn{r}. With
#' `by_item = TRUE` each rater has a severity for each item
#' (\eqn{\lambda_{ri}}, the rater-by-item bias terms of a facets analysis);
#' with `group` each rater has a severity for each group of test takers
#' (\eqn{\lambda_{rg}}), and the group means of \eqn{\theta} are estimated
#' as well. Severities are centred within each item and group, so they read
#' as "harsher (positive) or more lenient (negative) than the average rater",
#' and the item thresholds are those of the average rater.
#'
#' For each AI rater (`ai`), the gap between its severity and the mean
#' severity of the human raters is tested in every item and group. A gap is
#' flagged when it is larger than `rater_bias` logits in [mv_rules()] and
#' more than 1.96 standard errors from 0 (check `"rater severity"`). With
#' `group`, the difference between a focal group's gap and the reference
#' group's (the first level) is flagged in the same way (check
#' `"differential severity"`): The engine is harsher, relative to human
#' raters, for one group of test takers than for another. Use a year or
#' engine-version column as `group` to check for drift.
#'
#' The adjacent-category split treats the steps of a response as
#' independent, so the fit is a close approximation of the partial credit
#' model rather than its exact likelihood (the approach of the eirm
#' package). The human score columns are reading slots ("first read",
#' "second read"), not individual raters, unless the data say otherwise.
#'
#' @param data a data frame with one row per scored response (person and
#'   item), with one column of scores for each rater, as [essays] and
#'   [aiscored_cr]; or, with `score`, one row per rating.
#' @param raters names of the score columns, one per rater (for example
#'   `c("human1", "human2", "machine")`). With `score`, the name of the
#'   column that says who gave the rating.
#' @param person,item names of the columns with the person and item IDs.
#' @param group optional name of a column with a person-level grouping (for
#'   example `"group"` for language groups, or `"year"` for drift).
#' @param ai names of the raters that are AI scoring engines. Defaults to
#'   the raters whose name contains `machine`, `engine`, `ai` or `auto`.
#' @param by_item estimate each rater's severity separately for each item?
#' @param score with long data (one row per rating), the name of the score
#'   column.
#' @param labels optional display names for the raters, in the order of
#'   `raters` (for example `c("Human 1", "Human 2", "Engine")`).
#' @param rules thresholds from [mv_rules()] (`rater_bias`).
#' @return An object of class `mv_facets`: A list with `raters` (one row
#'   per rater: overall `severity`, `se`, and whether it is an AI rater),
#'   `severity` (one row per rater, item and group), `gaps` (AI minus human
#'   severity in each item and group, with `se` and `flag`), `differential`
#'   (with `group`: the focal group's gap minus the reference group's),
#'   `items` (the item thresholds, `difficulty` and `se`), `persons` (`id`,
#'   `group`, `theta`), `flags`, `checks` and `model` (the [eirm::eirm()]
#'   fit). It has `print()`, `tidy()` (the flags) and `autoplot()` methods
#'   (`type = "wright"` for the Wright map with a rater column, or
#'   `type = "bias"` for the gaps), and [gg_wright()] draws its Wright map.
#'   Pass it to [ai_audit()] in `components` to add its flags to an audit.
#' @references Linacre, J. M. (1989). *Many-facet Rasch measurement.* MESA
#'   Press.
#'
#'   Bulut, O., Gorgun, G., & Yildirim-Erbasli, S. N. (2021). Estimating
#'   explanatory extensions of dichotomous and polytomous Rasch models: The
#'   eirm package in R. *Psych, 3*(3), 308-321.
#'   \doi{10.3390/psych3030023}
#'
#'   Wind, S. A., & Peterson, M. E. (2018). A systematic review of methods
#'   for evaluating rating quality in language assessment. *Language
#'   Testing, 35*(2), 161-192.
#' @seealso [scoring_shift()] for the item thresholds and person scores
#'   under human and AI scoring; [ai_audit()], [agreement_report()].
#' @examples
#' \donttest{
#' if (requireNamespace("eirm", quietly = TRUE)) {
#'   # the double-scored validity sample of the AI-scored science test
#'   cr <- aiscored_cr[aiscored_cr$year == 2026 & !is.na(aiscored_cr$human1), ]
#'   fx <- rater_facets(cr, raters = c("human1", "human2", "machine"),
#'                      labels = c("Human 1", "Human 2", "Engine"))
#'   fx
#'   gg_wright(fx)
#'
#'   # severity by item and by language group: where is the engine biased?
#'   fx2 <- rater_facets(cr, raters = c("human1", "human2", "machine"),
#'                       group = "group", by_item = TRUE)
#'   fx2$gaps
#'   autoplot(fx2, type = "bias")
#' }
#' }
#' @export
rater_facets <- function(data, raters, person = "student", item = "item", group = NULL,
                         ai = NULL, by_item = FALSE, score = NULL, labels = NULL,
                         rules = mv_rules()) {
  if (!requireNamespace("eirm", quietly = TRUE) || !requireNamespace("lme4", quietly = TRUE))
    stop("rater_facets() needs the eirm package: install.packages(\"eirm\").", call. = FALSE)
  data <- as.data.frame(data)
  long <- facets_long(data, raters, person, item, group, score)
  rl <- levels(long$rater)
  if (!is.null(labels)) {
    if (length(labels) != length(rl))
      stop(sprintf("Give one label for each of the %d raters.", length(rl)), call. = FALSE)
    names(labels) <- rl
  } else labels <- stats::setNames(rl, rl)
  if (is.null(ai)) ai <- rl[grepl("machine|engine|auto|(^|[^a-z])ai([^a-z]|$)", tolower(rl))]
  if (length(setdiff(ai, rl)))
    stop("`ai` must name raters in `raters`: ", paste(setdiff(ai, rl), collapse = ", "),
         call. = FALSE)
  if (length(rl) < 2L) stop("Give at least two raters.", call. = FALSE)

  # cells: the item-by-group combinations a rater gets a severity for
  long$cell_item <- if (by_item) as.character(long$item) else "All"
  cells <- unique(long[, c("cell_item", "group")])
  cells <- cells[order(cells$group, match(cells$cell_item, levels(long$item))), ]
  rownames(cells) <- NULL
  cells$cell <- seq_len(nrow(cells))
  long$cell <- cells$cell[match(paste(long$cell_item, long$group),
                                paste(cells$cell_item, cells$group))]

  pl <- eirm::polyreformat(long, id.var = "person", long.format = FALSE,
                           var.name = "item", val.name = "score")
  pl <- pl[!is.na(pl$polyresponse), ]
  pl$polyitem <- droplevels(pl$polyitem)

  # rater dummies: one per non-reference rater and cell (the first rater is 0)
  sev_cols <- character(0)
  for (k in cells$cell) for (r in rl[-1]) {
    nm <- sprintf("sev_%d_%d", k, match(r, rl))
    pl[[nm]] <- as.numeric(pl$cell == k & pl$rater == r)
    sev_cols <- c(sev_cols, nm)
  }
  gl <- levels(long$group)
  grp_cols <- character(0)
  if (!is.null(group)) for (g in gl[-1]) {
    nm <- sprintf("grp_%d", match(g, gl))
    pl[[nm]] <- as.numeric(pl$group == g)
    grp_cols <- c(grp_cols, nm)
  }
  form <- paste("polyresponse ~ -1 + polyitem",
                paste(c("", grp_cols, sev_cols), collapse = " + "), "+ (1|person)")
  fit <- suppressMessages(eirm::eirm(form, data = pl))
  b <- lme4::fixef(fit$model)
  V <- as.matrix(stats::vcov(fit$model))
  lin <- function(L) {
    L <- L[, names(b), drop = FALSE]
    est <- drop(L %*% b)
    se <- sqrt(pmax(0, diag(L %*% V %*% t(L))))
    list(est = est, se = se)
  }
  zero <- function(n) matrix(0, n, length(b), dimnames = list(NULL, names(b)))
  # severity = -easiness; S[r, ] is the coefficient row of rater r in a cell
  sev_row <- function(k, r) {
    v <- stats::setNames(numeric(length(b)), names(b))
    nm <- sprintf("sev_%d_%d", k, r)
    if (r > 1 && nm %in% names(b)) v[nm] <- -1
    v
  }
  R <- length(rl)
  # centred severity of each rater in each cell
  rows <- list(); Ls <- list()
  for (k in cells$cell) {
    raw <- t(vapply(seq_len(R), function(r) sev_row(k, r), numeric(length(b))))
    cen <- raw - matrix(colMeans(raw), R, length(b), byrow = TRUE)
    colnames(cen) <- names(b)
    Ls[[k]] <- cen
    rows[[k]] <- data.frame(rater = rl, item = cells$cell_item[k], group = cells$group[k],
                            stringsAsFactors = FALSE)
  }
  L_all <- do.call(rbind, Ls)
  s <- lin(L_all)
  sev <- do.call(rbind, rows)
  sev$label <- unname(labels[sev$rater])
  sev$ai <- sev$rater %in% ai
  sev$severity <- s$est
  sev$se <- s$se

  # overall severity: average over cells
  Lo <- t(vapply(seq_len(R), function(r) colMeans(L_all[sev$rater == rl[r], , drop = FALSE]),
                 numeric(length(b))))
  colnames(Lo) <- names(b)
  o <- lin(Lo)
  overall <- data.frame(rater = rl, label = unname(labels[rl]), ai = rl %in% ai,
                        severity = o$est, se = o$se, stringsAsFactors = FALSE)

  # AI minus human gaps in each cell
  hum <- setdiff(rl, ai)
  gaps <- NULL; diffs <- NULL
  gap_L <- list()
  if (length(ai) && length(hum)) {
    gr <- list()
    for (a in ai) for (k in cells$cell) {
      Lc <- Ls[[k]]
      lr <- Lc[match(a, rl), ] - colMeans(Lc[match(hum, rl), , drop = FALSE])
      gap_L[[paste(a, k)]] <- lr
      gr[[length(gr) + 1L]] <- data.frame(rater = a, item = cells$cell_item[k],
                                          group = cells$group[k], stringsAsFactors = FALSE)
    }
    gaps <- do.call(rbind, gr)
    Lg <- do.call(rbind, gap_L)
    gs <- lin(Lg)
    gaps$label <- unname(labels[gaps$rater])
    gaps$gap <- gs$est
    gaps$se <- gs$se
    gaps$flag <- abs(gaps$gap) > rules$rater_bias & abs(gaps$gap) > 1.96 * gaps$se
    if (!is.null(group) && length(gl) > 1L) {
      dr <- list(); dL <- list()
      for (a in ai) for (it in unique(cells$cell_item)) for (g in gl[-1]) {
        cf <- cells$cell[cells$cell_item == it & cells$group == g]
        c0 <- cells$cell[cells$cell_item == it & cells$group == gl[1]]
        if (!length(cf) || !length(c0)) next
        dL[[length(dL) + 1L]] <- gap_L[[paste(a, cf)]] - gap_L[[paste(a, c0)]]
        dr[[length(dr) + 1L]] <- data.frame(rater = a, item = it, group = g, reference = gl[1],
                                            stringsAsFactors = FALSE)
      }
      if (length(dr)) {
        diffs <- do.call(rbind, dr)
        ds <- lin(do.call(rbind, dL))
        diffs$label <- unname(labels[diffs$rater])
        diffs$difference <- ds$est
        diffs$se <- ds$se
        diffs$flag <- abs(diffs$difference) > rules$rater_bias &
          abs(diffs$difference) > 1.96 * diffs$se
      }
    }
  }

  # item thresholds of the average rater (reference group)
  pi_names <- names(b)[startsWith(names(b), "polyitem")]
  node <- sub("^polyitem", "", pi_names)
  it_nm <- sub("\\.cat_[^.]*$", "", node)
  step <- sub("^.*\\.cat_", "", node)
  ref_cells <- cells[cells$group == gl[1], ]
  Li <- zero(length(pi_names))
  for (j in seq_along(pi_names)) {
    Li[j, pi_names[j]] <- -1
    k <- ref_cells$cell[ref_cells$cell_item == if (by_item) it_nm[j] else "All"]
    if (length(k)) {
      raw <- t(vapply(seq_len(R), function(r) sev_row(k, r), numeric(length(b))))
      Li[j, ] <- Li[j, ] + colMeans(raw)
    }
  }
  ii <- lin(Li)
  items <- data.frame(item = it_nm, threshold = suppressWarnings(as.integer(step)),
                      difficulty = ii$est, se = ii$se, stringsAsFactors = FALSE)
  items <- items[order(match(items$item, levels(long$item)), items$threshold), ]

  # persons: random effect plus group mean, on the average rater's scale
  re <- lme4::ranef(fit$model)$person
  pid <- rownames(re)
  pg <- long$group[match(pid, long$person)]
  gm <- stats::setNames(numeric(length(gl)), gl)
  for (g in gl[-1]) {
    nm <- sprintf("grp_%d", match(g, gl))
    if (nm %in% names(b)) gm[g] <- b[[nm]]
  }
  # put each group on the average rater's scale (mean severity shift
  # against the reference group, averaged over items)
  if (length(gl) > 1L) for (g in gl[-1]) {
    sh <- vapply(unique(cells$cell_item), function(it) {
      cg <- cells$cell[cells$cell_item == it & cells$group == g]
      c0 <- cells$cell[cells$cell_item == it & cells$group == gl[1]]
      if (!length(cg) || !length(c0)) return(NA_real_)
      raw_g <- t(vapply(seq_len(R), function(r) sev_row(cg, r), numeric(length(b))))
      raw_0 <- t(vapply(seq_len(R), function(r) sev_row(c0, r), numeric(length(b))))
      sum((colMeans(raw_g) - colMeans(raw_0)) * b)
    }, 0)
    gm[g] <- gm[g] - mean(sh, na.rm = TRUE)
  }
  persons <- data.frame(id = pid, group = as.character(pg),
                        theta = re[, 1] + unname(gm[as.character(pg)]), stringsAsFactors = FALSE)

  # flags
  flags <- list(); checks <- list()
  if (!is.null(gaps)) {
    tg <- facets_target(gaps)
    checks[[1]] <- data.frame(check = "rater severity", tested = nrow(gaps),
                              flagged = sum(gaps$flag), stringsAsFactors = FALSE)
    if (any(gaps$flag)) {
      f <- gaps[gaps$flag, ]
      flags[[1]] <- new_flag("rater_facets", "rater severity", tg[gaps$flag],
                             sprintf("%+.2f logits, SE %.2f", f$gap, f$se),
                             sprintf("rater_bias = %s, and beyond 1.96 SE", rules$rater_bias),
                             "block",
                             sprintf("%s is %s than the human raters here.", cap1(f$label),
                                     ifelse(f$gap > 0, "harsher", "more lenient")))
    }
  }
  if (!is.null(diffs)) {
    tg <- facets_target(diffs)
    checks[[2]] <- data.frame(check = "differential severity", tested = nrow(diffs),
                              flagged = sum(diffs$flag), stringsAsFactors = FALSE)
    if (any(diffs$flag)) {
      f <- diffs[diffs$flag, ]
      flags[[2]] <- new_flag("rater_facets", "differential severity", tg[diffs$flag],
                             sprintf("%+.2f logits, SE %.2f", f$difference, f$se),
                             sprintf("rater_bias = %s, and beyond 1.96 SE", rules$rater_bias),
                             "block",
                             sprintf("Relative to the human raters, %s is %s for %s than for %s.",
                                     f$label, ifelse(f$difference > 0, "harsher", "more lenient"),
                                     f$group, f$reference))
    }
  }
  fl <- bind_flags(flags)
  ck <- if (length(checks)) do.call(rbind, checks) else
    data.frame(check = character(0), tested = integer(0), flagged = integer(0))

  structure(list(
    raters = as_tbl(overall), severity = as_tbl(sev[, c("rater", "label", "ai", "item", "group",
                                                       "severity", "se")]),
    gaps = if (is.null(gaps)) NULL else as_tbl(gaps[, c("rater", "label", "item", "group", "gap",
                                                        "se", "flag")]),
    differential = if (is.null(diffs)) NULL else
      as_tbl(diffs[, c("rater", "label", "item", "group", "reference", "difference", "se", "flag")]),
    items = as_tbl(items), persons = as_tbl(persons),
    flags = as_tbl(fl[, c("check", "target", "value", "rule", "level", "advice")]),
    checks = as_tbl(ck), model = fit, by_item = by_item, group = group, ai = ai,
    labels = labels, rules = rules),
    class = "mv_facets")
}

facets_target <- function(d) {
  parts <- d$label
  if (any(d$item != "All")) parts <- paste(parts, d$item, sep = ", ")
  if (any(d$group != "All")) parts <- paste(parts, d$group, sep = ", ")
  parts
}

# One row per rating: person, item, group, rater, score
facets_long <- function(data, raters, person, item, group, score) {
  need <- c(person, item, group, if (is.null(score)) raters else c(raters, score))
  miss <- setdiff(need, names(data))
  if (length(miss)) stop(sprintf("`data` has no column `%s`.", miss[1]), call. = FALSE)
  grp <- if (is.null(group)) factor(rep("All", nrow(data))) else {
    g <- data[[group]]
    if (is.factor(g)) droplevels(g) else factor(g)
  }
  if (is.null(score)) {
    long <- do.call(rbind, lapply(raters, function(r) data.frame(
      person = as.character(data[[person]]), item = as.character(data[[item]]), group = grp,
      rater = r, score = data[[r]], stringsAsFactors = FALSE)))
    long$rater <- factor(long$rater, levels = raters)
  } else {
    if (length(raters) != 1L)
      stop("With `score`, `raters` is the name of the one column that says who rated.",
           call. = FALSE)
    rv <- data[[raters]]
    long <- data.frame(person = as.character(data[[person]]), item = as.character(data[[item]]),
                       group = grp, rater = if (is.factor(rv)) droplevels(rv) else factor(rv),
                       score = data[[score]], stringsAsFactors = FALSE)
  }
  long <- long[!is.na(long$score) & !is.na(long$group), ]
  sc <- long$score
  if (!is.numeric(sc) || any(sc != round(sc)) || any(sc < 0))
    stop("Scores must be whole numbers from 0, such as 0 to 4.", call. = FALSE)
  long$score <- factor(sc, levels = sort(unique(sc)))
  if (!identical(as.numeric(levels(long$score)), as.numeric(seq(0, max(sc)))))
    stop("Every score from 0 to the maximum must occur at least once.", call. = FALSE)
  long$item <- factor(long$item, levels = unique(as.character(data[[item]])))
  long$item <- droplevels(long$item)
  long$group <- droplevels(long$group)
  long
}

#' @export
print.mv_facets <- function(x, ...) {
  cat(sprintf("Rater facets: %d raters (%s), %d persons, %d items%s\n", nrow(x$raters),
              if (length(x$ai)) paste("AI:", paste(x$labels[x$ai], collapse = ", ")) else "no AI rater",
              nrow(x$persons), length(unique(x$items$item)),
              paste0(if (x$by_item) ", severity by item" else "",
                     if (!is.null(x$group)) sprintf(", severity by %s", x$group) else "")))
  cat("\nRater severity (logits; positive = harsher than the average rater):\n")
  r <- as.data.frame(x$raters)
  show <- data.frame(rater = r$label, ai = ifelse(r$ai, "AI", ""),
                     severity = sprintf("%+.2f", r$severity), se = sprintf("%.2f", r$se))
  print(show, row.names = FALSE)
  if (nrow(x$flags)) {
    cat("\nFlags:\n")
    f <- as.data.frame(x$flags)
    for (i in seq_len(nrow(f)))
      cat(strwrap(sprintf("[%s] %s, %s: %s. %s", toupper(f$level[i]), f$check[i], f$target[i],
                          f$value[i], f$advice[i]), indent = 2, exdent = 4), sep = "\n")
  } else if (nrow(x$checks)) cat("\nNo AI rater differs from the human raters by more than",
                                 x$rules$rater_bias, "logits.\n")
  invisible(x)
}

#' @rdname rater_facets
#' @param x,object an `mv_facets` object.
#' @param ... not used.
#' @export
tidy.mv_facets <- function(x, ...) x$flags

#' @rdname rater_facets
#' @param type `"wright"` for the Wright map with a rater column, or `"bias"`
#'   for the AI-minus-human severity gaps with 95% intervals.
#' @param bins number of bins of the person histogram.
#' @export
autoplot.mv_facets <- function(object, type = c("wright", "bias"), bins = 30, ...) {
  type <- match.arg(type)
  if (type == "bias") return(plot_facet_bias(object))
  th <- object$persons$theta
  persons <- wright_bins(th[is.finite(th)], bins)
  it <- as.data.frame(object$items)
  items <- data.frame(item = factor(it$item, levels = unique(it$item)), difficulty = it$difficulty,
                      label = if (length(unique(it$threshold)) > 1L)
                        paste0("Threshold ", it$threshold) else "Location")
  rt <- as.data.frame(object$raters)
  rt$label <- factor(rt$label, levels = rt$label)
  rt$kind <- ifelse(rt$ai, "AI", "Human")
  sv <- as.data.frame(object$severity)
  sv$label <- factor(sv$label, levels = levels(rt$label))
  sv$kind <- ifelse(sv$ai, "AI", "Human")
  lim <- range(c(persons$lo, persons$hi, items$difficulty, rt$severity - 1.96 * rt$se,
                 rt$severity + 1.96 * rt$se), na.rm = TRUE) + c(-0.25, 0.25)
  pn <- wright_panels(persons, items, lim)
  p1 <- pn[[1]]
  p2 <- pn[[2]] + ggplot2::theme(axis.title.y.right = ggplot2::element_blank(),
                                 axis.text.y.right = ggplot2::element_blank())
  cols <- c(Human = mv_colours[["primary"]], AI = mv_colours[["accent"]])
  p3 <- ggplot2::ggplot(rt, ggplot2::aes(x = label, y = severity, colour = kind))
  if (nrow(sv) > nrow(rt))
    p3 <- p3 + ggplot2::geom_point(data = sv, size = 1.4, alpha = 0.45,
                                   position = ggplot2::position_jitter(width = 0.12, height = 0,
                                                                       seed = 1))
  p3 <- p3 +
    ggplot2::geom_hline(yintercept = 0, colour = "grey70", linetype = "dotted") +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = severity - 1.96 * se, ymax = severity + 1.96 * se),
                           width = 0.2) +
    ggplot2::geom_point(size = 3) +
    ggplot2::scale_colour_manual(values = cols, name = NULL) +
    ggplot2::scale_y_continuous(position = "right") +
    ggplot2::coord_cartesian(ylim = lim) +
    ggplot2::labs(x = "Raters", y = "Severity (logits)") +
    theme_mirtverse() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90, vjust = 0.5, hjust = 1))
  sub <- if (nrow(sv) > nrow(rt))
    "Raters: Overall severity with 95% CI; faint points are severities by item or group." else
    "Raters: Severity with 95% CI. Higher means harsher."
  patchwork::wrap_plots(p1, p2, p3, widths = c(1, 2, 1)) +
    patchwork::plot_annotation(
      title = "Wright map with a rater facet", subtitle = sub,
      theme = ggplot2::theme(plot.title = ggplot2::element_text(face = "bold")))
}

plot_facet_bias <- function(object) {
  r <- object$rules$rater_bias
  parts <- list()
  g <- object$gaps
  if (!is.null(g) && nrow(g))
    parts[[1]] <- data.frame(target = facets_target(g), value = g$gap, se = g$se, flag = g$flag,
                             panel = "AI minus human severity (logits)")
  d <- object$differential
  if (!is.null(d) && nrow(d))
    parts[[2]] <- data.frame(target = facets_target(d), value = d$difference, se = d$se,
                             flag = d$flag,
                             panel = sprintf("Differential: Gap against %s (logits)", d$reference[1]))
  if (!length(parts))
    stop("Nothing to plot: Name the AI rater(s) in `ai` and give at least one human rater.",
         call. = FALSE)
  d <- do.call(rbind, parts)
  d$target <- factor(d$target, levels = rev(unique(d$target)))
  d$panel <- factor(d$panel, levels = unique(d$panel))
  d$status <- ifelse(d$flag, "Flagged", "Not flagged")
  ggplot2::ggplot(d, ggplot2::aes(value, target, colour = status)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey60") +
    ggplot2::geom_vline(xintercept = c(-r, r), linetype = "dashed", colour = "grey60") +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = value - 1.96 * se, xmax = value + 1.96 * se),
                           width = 0.2, orientation = "y") +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::facet_wrap(~panel, scales = "free_y") +
    ggplot2::scale_colour_manual(values = c(Flagged = "#d95f02", `Not flagged` = "#2c7fb8"),
                                 name = NULL) +
    ggplot2::labs(x = NULL, y = NULL, title = "Rater bias",
                  subtitle = sprintf("Positive = the engine is harsher. Dashed lines: rater_bias = %s logits.", r)) +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "bottom")
}

#' Compare item thresholds and scores under human and AI scoring
#'
#' Calibrates the AI-scored items twice on the same test takers, once with
#' the human scores and once with the machine scores, puts both
#' calibrations on one scale, and compares them: How far each item
#' threshold moves when the engine scores instead of a person, and how far
#' the test takers' scores move, overall and in each group. It is a Wright
#' map for the question "would the scale be the same if people had scored
#' it?".
#'
#' The human calibration fits the anchor items (`anchors`, items no engine
#' scores, such as multiple-choice items) together with the human scores.
#' The machine calibration fits the same anchors with the machine scores,
#' with the anchor parameters fixed at their human-calibration values and
#' the mean and variance of \eqn{\theta} free, so that both are on the scale
#' the anchors define (fixed-parameter linking). Without anchors both
#' calibrations fix \eqn{\theta} at mean 0 and SD 1; that is a fair
#' comparison only because the test takers are the same.
#'
#' A threshold is flagged when it moves by more than `drift_b` logits in
#' [mv_rules()] (check `"threshold shift"`), and an item's slope when it
#' changes by more than `drift_a` (check `"slope change"`).
#'
#' The person scores answer a different question: What happens to test
#' takers' scores when the engine scores their responses but the item
#' parameters stay those of the human calibration, as in operational
#' scoring with a bank calibrated on human scores? (Rescoring each person
#' with the machine calibration would hide the engine's effect, because the
#' recalibrated thresholds absorb it.) The mean \eqn{\theta} change is flagged when it is larger than `score_smd` SD
#' (check `"score impact"`) and, with `group`, a focal group's change minus
#' the reference group's when it is larger than `subgroup_smd` SD (check
#' `"differential impact"`): The engine moves one group's scores more than
#' another's.
#'
#' @param scores a data frame with one row per scored response (person and
#'   item), with a machine and a human score, as [aiscored_cr]. Rows
#'   without both scores are left out.
#' @param machine,human names of the machine and human score columns.
#' @param person,item names of the person and item ID columns.
#' @param anchors optional data frame of the anchor items, one row per
#'   person, with a column named as `person` and one column per item.
#' @param group optional name of a person-level column of `scores` (for
#'   example `"group"`).
#' @param itemtype item types for [mirt::mirt()], one for all items or one
#'   per item (anchors first). Defaults to `"2PL"` for 0/1 items and
#'   `"graded"` for the others.
#' @param method the [mirt::fscores()] method for the person scores.
#' @param rules thresholds from [mv_rules()] (`drift_b`, `drift_a`,
#'   `score_smd`, `subgroup_smd`).
#' @return An object of class `mv_shift`: A list with `thresholds` (one row
#'   per item and threshold: `human`, `machine`, `shift` and `flag`), `items`
#'   (slopes and the mean and largest threshold shift of each item),
#'   `persons` (`id`, `group`, `theta_human`, `theta_machine`: Both scored
#'   with the human calibration, from the human and the machine scores),
#'   `impact` (the
#'   mean \eqn{\theta} change in each group, in logits and SD units),
#'   `flags`, `checks` and the two models (`human_model`, `machine_model`).
#'   It has `print()`, `tidy()` (the flags) and `autoplot()` methods, and
#'   [gg_wright()] draws its Wright map: The person distributions under
#'   both scorings next to each item's thresholds, human and machine,
#'   joined by a line. Pass it to [ai_audit()] in `components` to add its
#'   flags to an audit.
#' @seealso [rater_facets()] for rater severity on the same scale;
#'   [ai_audit()], [train_scorer()].
#' @examples
#' \donttest{
#' # 2026 validity sample: Students read by a person as well as the engine
#' cr <- aiscored_cr[aiscored_cr$year == 2026, ]
#' mc <- aiscored[aiscored$year == 2026, c("student", sprintf("MC%02d", 1:16))]
#' sh <- scoring_shift(cr, human = "human1", anchors = mc, group = "group")
#' sh
#' sh$impact
#' gg_wright(sh)
#' }
#' @export
scoring_shift <- function(scores, machine = "machine", human = "human1", person = "student",
                          item = "item", anchors = NULL, group = NULL, itemtype = NULL,
                          method = "EAP", rules = mv_rules()) {
  scores <- as.data.frame(scores)
  for (nm in c(machine, human, person, item, group))
    if (!nm %in% names(scores)) stop(sprintf("`scores` has no column `%s`.", nm), call. = FALSE)
  s <- scores[!is.na(scores[[machine]]) & !is.na(scores[[human]]), ]
  if (!nrow(s)) stop("No responses have both a machine and a human score.", call. = FALSE)
  ids <- unique(as.character(s[[person]]))
  its <- unique(as.character(s[[item]]))
  wide <- function(col) {
    m <- matrix(NA_real_, length(ids), length(its), dimnames = list(ids, its))
    m[cbind(match(as.character(s[[person]]), ids), match(as.character(s[[item]]), its))] <-
      as.numeric(s[[col]])
    as.data.frame(m, check.names = FALSE)
  }
  H <- wide(human); M <- wide(machine)
  A <- NULL
  if (!is.null(anchors)) {
    anchors <- as.data.frame(anchors)
    if (!person %in% names(anchors))
      stop(sprintf("`anchors` needs the person column `%s`.", person), call. = FALSE)
    A <- anchors[match(ids, as.character(anchors[[person]])), setdiff(names(anchors), person),
                 drop = FALSE]
    bad <- names(A)[!vapply(A, function(v) is.numeric(v) &&
                              all(is.na(v) | (v == round(v) & v >= 0 & v <= 20)), TRUE)]
    if (length(bad))
      stop(sprintf("`anchors` column `%s` is not an item (scores 0, 1, 2, ...). Keep only the person ID and the item columns.",
                   bad[1]), call. = FALSE)
    if (any(names(A) %in% its))
      stop("The anchor items and the AI-scored items must have different names.", call. = FALSE)
    rownames(A) <- NULL
  }
  dH <- if (is.null(A)) H else cbind(A, H)
  dM <- if (is.null(A)) M else cbind(A, M)
  rownames(dH) <- rownames(dM) <- NULL
  if (is.null(itemtype))
    itemtype <- vapply(dH, function(v) if (max(v, na.rm = TRUE) > 1) "graded" else "2PL", "")
  mh <- mirt::mirt(dH, 1, itemtype = itemtype, verbose = FALSE)
  if (is.null(A)) {
    mm <- mirt::mirt(dM, 1, itemtype = itemtype, verbose = FALSE)
  } else {
    sv <- mirt::mirt(dM, 1, itemtype = itemtype, pars = "values")
    hv <- mirt::mod2values(mh)
    anc <- sv$item %in% names(A)
    key <- paste(sv$item, sv$name)
    sv$value[anc] <- hv$value[match(key[anc], paste(hv$item, hv$name))]
    sv$est[anc] <- FALSE
    sv$est[sv$item == "GROUP" & sv$name %in% c("MEAN_1", "COV_11")] <- TRUE
    mm <- mirt::mirt(dM, 1, itemtype = itemtype, pars = sv, verbose = FALSE)
  }
  ch <- mirt::coef(mh, IRTpars = TRUE, simplify = TRUE)$items
  cm <- mirt::coef(mm, IRTpars = TRUE, simplify = TRUE)$items
  bcols <- grep("^b[0-9]*$", colnames(ch), value = TRUE)
  th <- do.call(rbind, lapply(its, function(j) {
    bh <- ch[j, bcols]; bm <- cm[j, bcols]
    ok <- !is.na(bh) & !is.na(bm)
    data.frame(item = j, threshold = seq_len(sum(ok)), human = unname(bh[ok]),
               machine = unname(bm[ok]), stringsAsFactors = FALSE)
  }))
  th$shift <- th$machine - th$human
  th$flag <- abs(th$shift) > rules$drift_b
  itab <- data.frame(item = its, a_human = unname(ch[its, "a"]), a_machine = unname(cm[its, "a"]),
                     stringsAsFactors = FALSE)
  itab$a_change <- itab$a_machine - itab$a_human
  itab$mean_shift <- vapply(its, function(j) mean(th$shift[th$item == j]), 0)
  itab$max_shift <- vapply(its, function(j) {
    v <- th$shift[th$item == j]; v[which.max(abs(v))]
  }, 0)
  itab$flag <- abs(itab$a_change) > rules$drift_a

  # both with the human calibration: the machine scores' effect on test takers
  t_h <- as.numeric(mirt::fscores(mh, method = method, verbose = FALSE)[, 1])
  t_m <- as.numeric(mirt::fscores(mh, method = method, response.pattern = as.matrix(dM),
                                  verbose = FALSE)[, "F1"])
  pg <- if (is.null(group)) rep("All", length(ids)) else
    as.character(s[[group]][match(ids, as.character(s[[person]]))])
  gl <- if (is.null(group)) "All" else {
    g <- s[[group]]
    if (is.factor(g)) levels(droplevels(g)) else sort(unique(as.character(g)))
  }
  persons <- data.frame(id = ids, group = pg, theta_human = t_h, theta_machine = t_m,
                        stringsAsFactors = FALSE)
  sdh <- stats::sd(t_h)
  imp_row <- function(k, label) {
    d <- t_m[k] - t_h[k]
    data.frame(group = label, n = sum(k), mean_human = mean(t_h[k]),
               mean_machine = mean(t_m[k]), change = mean(d), se = stats::sd(d) / sqrt(sum(k)),
               smd = mean(d) / sdh, stringsAsFactors = FALSE)
  }
  impact <- imp_row(rep(TRUE, length(ids)), "All")
  if (!is.null(group)) impact <- rbind(impact, do.call(rbind, lapply(gl, function(g)
    imp_row(pg == g, g))))

  # flags
  flags <- list(); checks <- list()
  tgt <- paste(th$item, paste0("threshold ", th$threshold), sep = ", ")
  checks[[1]] <- data.frame(check = "threshold shift", tested = nrow(th), flagged = sum(th$flag))
  if (any(th$flag))
    flags[[1]] <- new_flag("scoring_shift", "threshold shift", tgt[th$flag],
                           sprintf("%+.2f logits (human %.2f, machine %.2f)", th$shift[th$flag],
                                   th$human[th$flag], th$machine[th$flag]),
                           sprintf("drift_b = %s", rules$drift_b), "review",
                           ifelse(th$shift[th$flag] > 0,
                                  "This score is harder to reach when the engine scores: It is harsher here than human raters.",
                                  "This score is easier to reach when the engine scores: It is more lenient here than human raters."))
  checks[[2]] <- data.frame(check = "slope change", tested = nrow(itab), flagged = sum(itab$flag))
  if (any(itab$flag))
    flags[[2]] <- new_flag("scoring_shift", "slope change", itab$item[itab$flag],
                           sprintf("a %.2f under human scoring, %.2f under machine scoring",
                                   itab$a_human[itab$flag], itab$a_machine[itab$flag]),
                           sprintf("drift_a = %s", rules$drift_a), "review",
                           "The item measures the trait more or less sharply when the engine scores it.")
  all <- impact[impact$group == "All", ]
  big <- abs(all$smd) > rules$score_smd
  checks[[3]] <- data.frame(check = "score impact", tested = 1L, flagged = as.integer(big))
  if (big)
    flags[[3]] <- new_flag("scoring_shift", "score impact", "All",
                           sprintf("%+.2f SD", all$smd), sprintf("score_smd = %s", rules$score_smd),
                           "block", sprintf("Test takers' scores are %s when the engine scores.",
                                            if (all$smd > 0) "higher" else "lower"))
  if (!is.null(group) && length(gl) > 1L) {
    ref <- impact[impact$group == gl[1], ]
    foc <- impact[impact$group %in% gl[-1], ]
    dsmd <- foc$smd - ref$smd
    dse <- sqrt(foc$se^2 + ref$se^2) / sdh
    hit <- abs(dsmd) > rules$subgroup_smd & abs(dsmd) > 1.96 * dse
    impact$differential <- NA_real_
    impact$differential[match(foc$group, impact$group)] <- dsmd
    checks[[4]] <- data.frame(check = "differential impact", tested = nrow(foc), flagged = sum(hit))
    if (any(hit))
      flags[[4]] <- new_flag("scoring_shift", "differential impact", foc$group[hit],
                             sprintf("%+.2f SD against %s, SE %.2f", dsmd[hit], gl[1], dse[hit]),
                             sprintf("subgroup_smd = %s, and beyond 1.96 SE", rules$subgroup_smd),
                             "block",
                             sprintf("The engine moves %s students' scores %s than %s students' scores.",
                                     foc$group[hit], ifelse(dsmd[hit] < 0, "down more", "up more"),
                                     gl[1]))
  }
  fl <- bind_flags(flags)
  structure(list(
    thresholds = as_tbl(th), items = as_tbl(itab), persons = as_tbl(persons),
    impact = as_tbl(impact),
    flags = as_tbl(fl[, c("check", "target", "value", "rule", "level", "advice")]),
    checks = as_tbl(do.call(rbind, checks)), human_model = mh, machine_model = mm,
    anchors = if (is.null(A)) character(0) else names(A), group = group, group_levels = gl,
    rules = rules),
    class = "mv_shift")
}

#' @export
print.mv_shift <- function(x, ...) {
  cat(sprintf("Human vs AI scoring: %d AI-scored items, %d persons, %s\n", nrow(x$items),
              nrow(x$persons),
              if (length(x$anchors)) sprintf("linked through %d anchor items", length(x$anchors))
              else "no anchors (same persons, N(0, 1) in both calibrations)"))
  cat("\nThreshold shift (machine minus human, logits):\n")
  it <- as.data.frame(x$items)
  print(data.frame(item = it$item, a_human = sprintf("%.2f", it$a_human),
                   a_machine = sprintf("%.2f", it$a_machine),
                   mean_shift = sprintf("%+.2f", it$mean_shift),
                   max_shift = sprintf("%+.2f", it$max_shift)), row.names = FALSE)
  cat("\nScore impact (mean theta change):\n")
  im <- as.data.frame(x$impact)
  print(data.frame(group = im$group, n = im$n, change = sprintf("%+.2f", im$change),
                   smd = sprintf("%+.2f", im$smd)), row.names = FALSE)
  if (nrow(x$flags)) {
    cat("\nFlags:\n")
    f <- as.data.frame(x$flags)
    f <- f[order(match(f$level, c("block", "review", "info"))), ]
    for (i in seq_len(nrow(f)))
      cat(strwrap(sprintf("[%s] %s, %s: %s. %s", toupper(f$level[i]), f$check[i], f$target[i],
                          f$value[i], f$advice[i]), indent = 2, exdent = 4), sep = "\n")
  }
  invisible(x)
}

#' @rdname scoring_shift
#' @param x,object an `mv_shift` object.
#' @param ... not used.
#' @export
tidy.mv_shift <- function(x, ...) x$flags

#' @rdname scoring_shift
#' @export
autoplot.mv_shift <- function(object, ...) {
  pp <- as.data.frame(object$persons)
  grp <- object$group_levels
  pd <- rbind(data.frame(theta = pp$theta_human, group = pp$group, scoring = "Human"),
              data.frame(theta = pp$theta_machine, group = pp$group, scoring = "Machine"))
  pd$group <- factor(pd$group, levels = grp)
  br <- range(pd$theta, na.rm = TRUE)
  th <- as.data.frame(object$thresholds)
  th$item <- factor(th$item, levels = unique(th$item))
  th$x <- as.numeric(th$item) + (th$threshold - mean(unique(th$threshold))) * 0.12
  long <- rbind(data.frame(th[, c("item", "threshold", "x", "flag")], difficulty = th$human,
                           scoring = "Human"),
                data.frame(th[, c("item", "threshold", "x", "flag")], difficulty = th$machine,
                           scoring = "Machine"))
  lim <- range(c(br, th$human, th$machine), na.rm = TRUE) + c(-0.25, 0.25)
  cols <- c(Human = mv_colours[["primary"]], Machine = mv_colours[["accent"]])
  p1 <- ggplot2::ggplot(pd, ggplot2::aes(y = theta, colour = scoring, linetype = scoring)) +
    ggplot2::geom_density(linewidth = 0.8, bw = "SJ", na.rm = TRUE, key_glyph = "path") +
    ggplot2::scale_linetype_manual(values = c(Human = "solid", Machine = "longdash"), name = NULL) +
    ggplot2::scale_x_reverse() +
    ggplot2::scale_colour_manual(values = cols, name = NULL) +
    ggplot2::coord_cartesian(ylim = lim) +
    ggplot2::labs(x = "Persons (density)", y = expression(theta)) +
    theme_mirtverse() +
    ggplot2::theme(legend.position = "bottom", axis.text.x = ggplot2::element_blank())
  if (length(grp) > 1L) p1 <- p1 + ggplot2::facet_wrap(~group, nrow = 1)
  p2 <- ggplot2::ggplot(long, ggplot2::aes(x = x, y = difficulty)) +
    ggplot2::geom_line(ggplot2::aes(group = interaction(item, threshold),
                                    linewidth = ifelse(flag, "Flagged shift", "Shift")),
                       colour = "grey45") +
    ggplot2::geom_point(ggplot2::aes(colour = scoring, shape = scoring), size = 2.6) +
    ggplot2::scale_linewidth_manual(values = c(`Flagged shift` = 1.4, Shift = 0.4), name = NULL) +
    ggplot2::scale_colour_manual(values = cols, name = NULL) +
    ggplot2::scale_shape_manual(values = c(Human = 16, Machine = 17), name = NULL) +
    ggplot2::scale_x_continuous(breaks = seq_along(levels(th$item)), labels = levels(th$item)) +
    ggplot2::scale_y_continuous(position = "right") +
    ggplot2::coord_cartesian(ylim = lim) +
    ggplot2::labs(x = "Items (thresholds left to right)", y = "Threshold (logits)") +
    theme_mirtverse() + ggplot2::theme(legend.position = "bottom")
  patchwork::wrap_plots(p1, p2, widths = c(if (length(grp) > 1L) 1.6 else 1, 2)) +
    patchwork::plot_annotation(
      title = "Wright map: Human vs AI scoring",
      subtitle = sprintf("Thick lines: Thresholds that move more than drift_b = %s logits.",
                         object$rules$drift_b),
      theme = ggplot2::theme(plot.title = ggplot2::element_text(face = "bold")))
}
