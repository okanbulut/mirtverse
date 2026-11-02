#' Audit an AI component before its results are used
#'
#' Runs the checks a psychometrician owes any AI component of a testing
#' program in one call, and returns flags in the same `block` / `review` /
#' `info` style as the assessment pipeline. The main use is an automated
#' scoring engine, checked against human scores; the results of difficulty
#' models and item generators can be added through `components`.
#'
#' The checks, each run when its inputs are given:
#'
#' * **Human agreement** (`human2`): Do two human raters agree well enough
#'   (QWK at least `qwk_min`) for their scores to judge the engine? If not,
#'   the engine is checked against weak evidence.
#' * **Machine agreement**: Quadratic weighted kappa and standardized mean
#'   difference between machine and human scores for each item, against
#'   [mv_rules()] (`qwk_min`, `qwk_drop`, `score_smd`), as in
#'   [agreement_report()].
#' * **Subgroup agreement** (`group`): The same within each group of test
#'   takers, with the stricter `subgroup_smd`.
#' * **Differential scoring** (`group`): Among responses that human raters
#'   scored the same, does the engine give one group lower scores than the
#'   reference group (the first group)? The gap is the focal group's mean
#'   machine-minus-human difference minus the reference group's, averaged
#'   over the human score levels with the focal group's weights, and divided
#'   by the SD of the human scores. It is flagged when it exceeds
#'   `subgroup_smd` and is more than 1.96 standard errors from 0. This
#'   is the comparison Johnson, Liu and McCaffrey (2022) recommend for
#'   telling bias in the engine from real group differences.
#' * **Drift** (`period`): Has the engine changed between administrations or
#'   versions? Each later period's SMD and QWK are compared with the first
#'   period's; a change in SMD above `subgroup_smd` or a drop in QWK above
#'   `qwk_drop` is flagged when the change in the mean machine-human
#'   difference is also beyond sampling error (`p_change` below .05, with a
#'   Bonferroni adjustment across items and periods).
#' * **DIF** (`responses`): A DIF analysis of the whole test as scored, with
#'   [dif()]. DIF on an AI-scored item (`ai_items`) is flagged for review, as
#'   it may come from the engine; DIF on other items is reported for
#'   information, as a matter for content review rather than the engine.
#' * **Components**: Results of [predict_difficulty()] are checked for leaked
#'   features, results of [calibrate_families()] for families that are not
#'   isomorphic, and results of [agreement_report()] for verdicts that are
#'   not met.
#'
#' @param scores a data frame with one row per scored response, or `NULL`
#'   when only `responses` or `components` are audited.
#' @param machine,human1,human2,group,item,period names of the columns of
#'   `scores` with the machine score, the first and second human score (`NA`
#'   when a response was not read), the test taker's group, the item and the
#'   administration or engine version. Only `machine` and `human1` are
#'   required.
#' @param responses optional data frame of item responses, one row per test
#'   taker, as scored operationally (machine scores for AI-scored items).
#' @param person_group the group of each row of `responses`, or the name of
#'   one of its columns.
#' @param ai_items names of the AI-scored items in `responses`. Defaults to
#'   the items in `scores`.
#' @param model item types for the DIF analysis, one per item or one for
#'   all. Defaults to `"2PL"` for 0/1 items and `"graded"` for the others.
#' @param components optional list of results of [predict_difficulty()],
#'   [calibrate_families()] or [agreement_report()].
#' @param rules thresholds from [mv_rules()].
#' @return An object of class `mv_audit`: A list with `checks` (one row per
#'   check: What was tested, how many targets, how many flags, and the
#'   status), `flags` (one row per flag: `check`, `target`, `value`, `rule`,
#'   `level` and `advice`), and the tables behind them: `agreement`,
#'   `differential`, `drift` and `dif`. It has `print()`, `tidy()` (the
#'   flags) and `autoplot()` methods, and is the evidence for
#'   [validity_argument()].
#' @references Johnson, M. S., Liu, X., & McCaffrey, D. F. (2022).
#'   Psychometric methods to evaluate measurement and algorithmic bias in
#'   automated scoring. *Journal of Educational Measurement, 59*(3),
#'   338-361.
#'
#'   Williamson, D. M., Xi, X., & Breyer, F. J. (2012). A framework for
#'   evaluation and use of automated scoring. *Educational Measurement:
#'   Issues and Practice, 31*(1), 2-13.
#' @seealso [validity_argument()] to turn the audit into a validity
#'   argument; [agreement_report()], [dif()].
#' @examples
#' cr <- aiscored_cr[aiscored_cr$year == 2026, ]
#' audit <- ai_audit(cr, human2 = "human2", group = "group", item = "item")
#' audit
#' audit$differential
#' \donttest{
#' # with drift across years and DIF on the test as scored
#' d26 <- aiscored[aiscored$year == 2026, ]
#' audit <- ai_audit(aiscored_cr, human2 = "human2", group = "group", item = "item",
#'                   period = "year", responses = d26[, -(1:3)],
#'                   person_group = d26$group)
#' audit
#' autoplot(audit)
#' }
#' @export
ai_audit <- function(scores = NULL, machine = "machine", human1 = "human1", human2 = NULL,
                     group = NULL, item = NULL, period = NULL, responses = NULL,
                     person_group = NULL, ai_items = NULL, model = NULL, components = NULL,
                     rules = mv_rules()) {
  if (is.null(scores) && is.null(responses) && is.null(components))
    stop("Give `scores`, `responses` or `components` to audit.", call. = FALSE)
  flags <- list()
  checks <- list()
  add_check <- function(check, tested, target_flags) {
    checks[[length(checks) + 1L]] <<- data.frame(
      check = check, tested = tested, flagged = length(unique(target_flags)),
      stringsAsFactors = FALSE)
  }
  add <- function(check, target, value, rule, level, advice) {
    flags[[length(flags) + 1L]] <<- new_flag("ai_audit", check, target, value, rule, level, advice)
  }
  out <- list(agreement = NULL, differential = NULL, drift = NULL, dif = NULL)

  if (!is.null(scores)) {
    scores <- as.data.frame(scores)
    for (nm in c(machine, human1, human2, group, item, period))
      if (!nm %in% names(scores)) stop(sprintf("`scores` has no column `%s`.", nm), call. = FALSE)
    m <- as.numeric(scores[[machine]])
    h1 <- as.numeric(scores[[human1]])
    h2 <- if (is.null(human2)) rep(NA_real_, nrow(scores)) else as.numeric(scores[[human2]])
    g <- if (is.null(group)) NULL else scores[[group]]
    it <- if (is.null(item)) rep("All", nrow(scores)) else as.character(scores[[item]])
    if (is.null(ai_items) && !is.null(item)) ai_items <- unique(it)
    ag <- agreement_report(m, h1, h2, group = g, by = it, rules = rules)
    out$agreement <- ag
    a <- as.data.frame(ag)
    all <- a[a$group == "All", ]

    # human agreement
    if (!is.null(human2)) {
      weak <- !is.na(all$qwk_human) & all$qwk_human < rules$qwk_min
      add_check("human agreement", sum(!is.na(all$qwk_human)), all$by[weak])
      if (any(weak))
        add("human agreement", all$by[weak], sprintf("human QWK %.2f", all$qwk_human[weak]),
            sprintf("qwk_min = %s", rules$qwk_min), "review",
            paste("Human raters disagree, so their scores are weak evidence about the engine.",
                  "Clarify the rubric and retrain raters before judging or retraining the engine."))
    } else weak <- rep(FALSE, nrow(all))

    # machine agreement and overall bias
    low <- !is.na(all$qwk) & (all$qwk < rules$qwk_min |
                                (!is.na(all$qwk_human) & all$qwk < all$qwk_human - rules$qwk_drop))
    add_check("machine agreement", sum(!is.na(all$qwk)), all$by[low])
    if (any(low))
      add("machine agreement", all$by[low],
          sprintf("QWK %.2f%s", all$qwk[low],
                  ifelse(is.na(all$qwk_human[low]), "", sprintf(", human QWK %.2f", all$qwk_human[low]))),
          sprintf("qwk_min = %s, qwk_drop = %s", rules$qwk_min, rules$qwk_drop),
          ifelse(weak[low], "review", "block"),
          ifelse(weak[low],
                 "The engine agrees with people about as well as people agree with each other: Fix the rubric first.",
                 "The engine does not agree with human raters well enough to score on its own."))
    bias <- !is.na(all$smd) & abs(all$smd) > rules$score_smd
    add_check("overall bias", sum(!is.na(all$smd)), all$by[bias])
    if (any(bias))
      add("overall bias", all$by[bias], sprintf("SMD %+.2f", all$smd[bias]),
          sprintf("score_smd = %s", rules$score_smd), "block",
          ifelse(all$smd[bias] > 0, "Machine scores are higher than human scores.",
                 "Machine scores are lower than human scores."))

    if (!is.null(g)) {
      sub <- a[a$group != "All", ]
      sl <- !is.na(sub$qwk) & sub$qwk < rules$qwk_min
      add_check("subgroup agreement", sum(!is.na(sub$qwk)), paste(sub$by, sub$group)[sl])
      if (any(sl))
        add("subgroup agreement", paste(sub$by[sl], sub$group[sl], sep = ", "),
            sprintf("QWK %.2f", sub$qwk[sl]), sprintf("qwk_min = %s", rules$qwk_min), "review",
            "The engine agrees less well with human raters in this group.")
      dg <- differential_scoring(m, h1, g, it)
      out$differential <- dg
      big <- !is.na(dg$gap) & abs(dg$gap) > rules$subgroup_smd & abs(dg$gap) > 1.96 * dg$se
      add_check("differential scoring", sum(!is.na(dg$gap)), paste(dg$item, dg$group)[big])
      if (any(big))
        add("differential scoring", paste(dg$item[big], dg$group[big], sep = ", "),
            sprintf("gap %+.2f SD, SE %.2f", dg$gap[big], dg$se[big]),
            sprintf("subgroup_smd = %s, and beyond 1.96 SE", rules$subgroup_smd),
            "block",
            sprintf("For responses human raters scored the same, the engine scores %s students %s than %s students.",
                    dg$group[big], ifelse(dg$gap[big] < 0, "lower", "higher"), dg$reference[big]))
    }

    if (!is.null(period)) {
      dr <- score_drift(m, h1, scores[[period]], it, rules)
      out$drift <- dr
      moved <- dr$drift
      add_check("drift", sum(!is.na(dr$smd_change)), dr$item[moved])
      if (any(moved))
        add("drift", paste(dr$item[moved], dr$period[moved], sep = ", "),
            sprintf("SMD %+.2f against %+.2f, QWK %.2f against %.2f", dr$smd[moved], dr$smd_first[moved],
                    dr$qwk[moved], dr$qwk_first[moved]),
            sprintf("change in SMD <= %s, drop in QWK <= %s, adjusted p < .05", rules$subgroup_smd, rules$qwk_drop),
            "block", "The engine's scores have changed since the first period: Check what changed (engine version, prompts, population) and rescore if needed.")
    }
  }

  if (!is.null(responses)) {
    responses <- as.data.frame(responses)
    if (is.character(person_group) && length(person_group) == 1L && nrow(responses) != 1L) {
      if (!person_group %in% names(responses))
        stop(sprintf("`responses` has no column `%s`.", person_group), call. = FALSE)
      pg <- responses[[person_group]]
      responses[[person_group]] <- NULL
    } else pg <- person_group
    if (is.null(pg)) stop("Give the group of each test taker in `person_group`.", call. = FALSE)
    if (is.null(model))
      model <- vapply(responses, function(v) if (max(v, na.rm = TRUE) > 1) "graded" else "2PL", "")
    d <- dif(responses, group = pg, model = model, alpha = rules$dif_alpha)
    out$dif <- d
    tab <- as.data.frame(d$table)
    fl <- tab$flag
    ai <- tab$item %in% ai_items
    add_check("DIF", nrow(tab), tab$item[fl])
    if (any(fl & ai))
      add("DIF", tab$item[fl & ai], sprintf("ESD %+.3f, p %s", tab$esd[fl & ai], p_eq(tab$p.adjusted[fl & ai])),
          sprintf("dif_alpha = %s", rules$dif_alpha), "review",
          "DIF on an AI-scored item: Compare with human scores to see whether the engine or the item causes it.")
    if (any(fl & !ai))
      add("DIF", tab$item[fl & !ai], sprintf("ESD %+.3f, p %s", tab$esd[fl & !ai], p_eq(tab$p.adjusted[fl & !ai])),
          sprintf("dif_alpha = %s", rules$dif_alpha), "info",
          "DIF on an item the engine does not score: A matter for content review, not for the engine.")
  }

  if (inherits(components, c("mv_difficulty", "mv_families", "mv_agreement")))
    components <- list(components)
  for (cmp in components) {
    if (inherits(cmp, "mv_difficulty")) {
      lk <- cmp$leaky
      add_check("leakage", length(cmp$features), names(lk))
      if (length(lk))
        add("leakage", names(lk), sprintf("rank correlation with b %+.2f", unname(lk)),
            "|rank correlation| < 0.8", "block",
            "A feature this close to the label is probably computed from the same responses: Leave it out.")
    } else if (inherits(cmp, "mv_families")) {
      bad <- cmp$family[!cmp$isomorphic]
      add_check("isomorphism", nrow(cmp), bad)
      if (length(bad))
        add("isomorphism", bad, sprintf("SD within %.2f", cmp$sd_within[!cmp$isomorphic]),
            sprintf("max_sd = %s", attr(cmp, "max_sd")), "review",
            "The family mean is not a good estimate for new items from this item model.")
    } else if (inherits(cmp, "mv_agreement")) {
      v <- as.data.frame(cmp)
      bad <- v$verdict != "meets"
      tg <- if (is.null(v$by)) v$group else paste(v$by, v$group, sep = ", ")
      add_check("agreement report", nrow(v), tg[bad])
      if (any(bad))
        add("agreement report", tg[bad], v$verdict[bad], "mv_rules()", "review",
            "See agreement_report() for the statistics.")
    } else {
      stop("`components` must hold results of predict_difficulty(), calibrate_families() or agreement_report().",
           call. = FALSE)
    }
  }

  fl <- bind_flags(flags)
  fl$id <- seq_len(nrow(fl))
  ck <- do.call(rbind, checks)
  lv <- vapply(ck$check, function(cc) {
    l <- fl$level[fl$check == cc]
    if (any(l == "block")) "block" else if (any(l == "review")) "review"
    else if (any(l == "info")) "info" else "pass"
  }, "")
  ck$status <- ifelse(ck$tested == 0, "not run", lv)
  out$checks <- as_tbl(ck)
  out$flags <- as_tbl(fl[, c("check", "target", "value", "rule", "level", "advice")])
  out$rules <- rules
  structure(out, class = "mv_audit")
}

# Machine-minus-human gap of each group against the reference group, among
# responses with the same human score, in SD units of the human scores
differential_scoring <- function(m, h, g, it) {
  g <- if (is.factor(g)) droplevels(g) else factor(g)
  ref <- levels(g)[1]
  rows <- list()
  for (i in unique(it)) {
    s <- it == i & !is.na(m) & !is.na(h) & !is.na(g)
    d <- data.frame(diff = m[s] - h[s], h = h[s], g = g[s])
    sdh <- stats::sd(d$h)
    for (fg in setdiff(levels(g), ref)) {
      lev <- sort(unique(d$h[d$g == fg]))
      vr <- function(x) if (length(x) > 1) stats::var(x) else 0
      parts <- vapply(lev, function(k) {
        f <- d$diff[d$g == fg & d$h == k]
        r <- d$diff[d$g == ref & d$h == k]
        if (!length(f) || length(r) < 2) return(c(NA_real_, 0, NA_real_))
        c(mean(f) - mean(r), length(f), vr(f) / length(f) + vr(r) / length(r))
      }, numeric(3))
      ok <- !is.na(parts[1, ])
      if (any(ok) && is.finite(sdh) && sdh > 0) {
        w <- parts[2, ok] / sum(parts[2, ok])
        gap <- sum(w * parts[1, ok]) / sdh
        se <- sqrt(sum(w^2 * parts[3, ok])) / sdh
      } else gap <- se <- NA_real_
      rows[[length(rows) + 1L]] <- data.frame(item = i, group = fg, reference = ref,
                                              n = sum(d$g == fg), gap = gap, se = se,
                                              stringsAsFactors = FALSE)
    }
  }
  as_tbl(do.call(rbind, rows))
}

score_drift <- function(m, h, period, it, rules) {
  per <- if (is.factor(period)) levels(droplevels(period)) else sort(unique(period))
  rows <- list()
  attr_diff <- list()
  for (i in unique(it)) {
    st <- lapply(per, function(p) {
      s <- it == i & period == p & !is.na(h) & !is.na(m)
      dd <- m[s] - h[s]
      c(n = sum(s), smd = smd(m[s], h[s]), qwk = qwk(m[s], h[s]),
        mean_diff = mean(dd), var_diff = stats::var(dd))
    })
    for (k in seq_along(per)) {
      rows[[length(rows) + 1L]] <- data.frame(
        item = i, period = as.character(per[k]), n = st[[k]][["n"]], smd = st[[k]][["smd"]],
        qwk = st[[k]][["qwk"]], smd_first = st[[1]][["smd"]], qwk_first = st[[1]][["qwk"]],
        stringsAsFactors = FALSE)
    }
    attr_diff[[i]] <- st
  }
  d <- do.call(rbind, rows)
  d$smd_change <- ifelse(d$period == as.character(per[1]), NA_real_, d$smd - d$smd_first)
  # is the change in the mean machine-human difference beyond sampling error?
  d$p_change <- NA_real_
  for (i in unique(d$item)) {
    r <- which(d$item == i)
    first <- r[1]
    for (k in r[-1]) {
      se <- sqrt(attr_diff[[i]][[1]]["var_diff"] / d$n[first] +
                   attr_diff[[i]][[k - first + 1]]["var_diff"] / d$n[k])
      z <- (attr_diff[[i]][[k - first + 1]]["mean_diff"] - attr_diff[[i]][[1]]["mean_diff"]) / se
      d$p_change[k] <- 2 * stats::pnorm(-abs(z))
    }
  }
  # Bonferroni across items and later periods
  d$p_change <- pmin(1, d$p_change * sum(!is.na(d$p_change)))
  d$drift <- !is.na(d$smd_change) & d$p_change < 0.05 &
    (abs(d$smd_change) > rules$subgroup_smd | d$qwk < d$qwk_first - rules$qwk_drop)
  as_tbl(d)
}

#' @export
print.mv_audit <- function(x, ...) {
  ck <- as.data.frame(x$checks)
  cat(sprintf("AI audit: %d checks, %d flags (%d block, %d review)\n", nrow(ck), nrow(x$flags),
              sum(x$flags$level == "block"), sum(x$flags$level == "review")))
  mark <- c(pass = "ok", info = "info", review = "REVIEW", block = "BLOCK", `not run` = "-")
  show <- data.frame(check = ck$check, tested = ck$tested, flagged = ck$flagged,
                     status = mark[ck$status], stringsAsFactors = FALSE)
  print(show, row.names = FALSE)
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

#' @rdname ai_audit
#' @param x,object an `mv_audit` object.
#' @param ... not used.
#' @export
tidy.mv_audit <- function(x, ...) x$flags

#' @rdname ai_audit
#' @export
autoplot.mv_audit <- function(object, ...) {
  dg <- object$differential
  dr <- object$drift
  r <- object$rules
  fl <- as.data.frame(object$flags)
  plots <- list()
  ag <- as.data.frame(object$agreement)
  if (nrow(ag)) {
    ag <- ag[ag$group == "All" & !is.na(ag$smd), ]
    lab <- if (is.null(ag$by)) ag$group else ag$by
    plots <- c(plots, list(data.frame(
      label = lab, value = ag$smd, lo = NA_real_, hi = NA_real_, limit = r$score_smd,
      flag = lab %in% fl$target[fl$check == "overall bias"],
      panel = "Overall: Machine minus human (SMD)")))
  }
  if (!is.null(dg) && nrow(dg)) {
    lab <- paste(dg$item, dg$group, sep = ", ")
    plots <- c(plots, list(data.frame(
      label = lab, value = dg$gap, lo = dg$gap - 1.96 * dg$se, hi = dg$gap + 1.96 * dg$se,
      limit = r$subgroup_smd, flag = lab %in% fl$target[fl$check == "differential scoring"],
      panel = "Differential scoring (gap in SD, 95% CI)")))
  }
  if (!is.null(dr) && nrow(dr)) {
    dd <- dr[!is.na(dr$smd_change), ]
    plots <- c(plots, list(data.frame(
      label = paste(dd$item, dd$period, sep = ", "), value = dd$smd_change, lo = NA_real_,
      hi = NA_real_, limit = r$subgroup_smd, flag = dd$drift,
      panel = "Drift (change in SMD)")))
  }
  if (!length(plots)) stop("Nothing to plot: The audit has no score checks.", call. = FALSE)
  d <- do.call(rbind, plots)
  d$label <- factor(d$label, levels = rev(unique(d$label)))
  d$panel <- factor(d$panel, levels = unique(d$panel))
  d$status <- ifelse(d$flag, "Flagged", "Not flagged")
  ggplot2::ggplot(d, ggplot2::aes(value, label, colour = status)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey60") +
    ggplot2::geom_vline(ggplot2::aes(xintercept = limit), linetype = "dashed", colour = "grey60") +
    ggplot2::geom_vline(ggplot2::aes(xintercept = -limit), linetype = "dashed", colour = "grey60") +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = lo, xmax = hi), width = 0.2, orientation = "y",
                           na.rm = TRUE) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::facet_wrap(~panel, scales = "free_y") +
    ggplot2::scale_colour_manual(values = c(Flagged = "#d95f02", `Not flagged` = "#2c7fb8"),
                                 name = NULL) +
    ggplot2::labs(x = NULL, y = NULL, title = "AI audit",
                  subtitle = "Dashed lines: The limits of mv_rules(). Flags also require the difference to be beyond sampling error.") +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "bottom")
}

#' Draft a validity argument for an AI component
#'
#' Drafts the interpretation-and-use argument (Kane, 2013) for test scores
#' that an AI component helps produce, organized by the four inferences of
#' the argument-based approach: **Scoring** (the scores follow the rubric),
#' **generalization** (they would be the same on another occasion, form or
#' engine version), **extrapolation** (they reflect the construct, equally
#' for all groups) and **decision** (the decisions made with them are
#' appropriate). For each inference it states the claim, the threats an AI
#' component adds, the evidence from an [ai_audit()] and a status.
#'
#' The draft is a starting point, not a verdict: It shows which claims the
#' audit supports, which it calls into question, and which no audit can
#' settle (such as human oversight, disclosure to test takers and appeals),
#' so that the evidence still owed is explicit. Add it to an HTML report with
#' `mv_report(model, extra = list("Validity argument" = format(va, "html")))`
#' or simply `extra = list("Validity argument" = va)`.
#'
#' @param audit an [ai_audit()] result, or `NULL` for an argument with no
#'   evidence yet.
#' @param construct what the test measures, e.g. `"Grade 8 science"`.
#' @param use the intended use of the scores, e.g. `"school accountability"`.
#' @param population the test takers.
#' @param component what the AI component does, e.g. `"automated scoring of
#'   constructed responses"`.
#' @return A tibble of class `mv_validity` with one row per inference:
#'   `inference`, `claim`, `threats`, `evidence`, `status` (`"supported"`,
#'   `"partly supported"`, `"threatened"` or `"needs evidence"`) and `todo`.
#'   It has `print()` and `format()` methods (`format(x, "html")` or
#'   `format(x, "markdown")`).
#' @references Kane, M. T. (2013). Validating the interpretations and uses
#'   of test scores. *Journal of Educational Measurement, 50*(1), 1-73.
#'
#'   American Educational Research Association, American Psychological
#'   Association, & National Council on Measurement in Education. (2014).
#'   *Standards for educational and psychological testing.* AERA.
#' @seealso [ai_audit()], [mv_report()].
#' @examples
#' cr <- aiscored_cr[aiscored_cr$year == 2026, ]
#' audit <- ai_audit(cr, human2 = "human2", group = "group", item = "item")
#' va <- validity_argument(audit, construct = "Grade 8 science",
#'                         use = "school accountability",
#'                         population = "Grade 8 students")
#' va
#' cat(format(va, "markdown"))
#' @export
validity_argument <- function(audit = NULL, construct = "the construct", use = "the intended use",
                              population = "the test takers",
                              component = "automated scoring of constructed responses") {
  if (!is.null(audit) && !inherits(audit, "mv_audit"))
    stop("`audit` must be a result of ai_audit().", call. = FALSE)
  inf <- data.frame(
    inference = c("Scoring", "Generalization", "Extrapolation", "Decision"),
    claim = c(
      sprintf("Scores from %s follow the scoring rubric as trained human raters apply it.", component),
      sprintf("Scores would be the same on another occasion, form, rater or engine version, so they mean the same across administrations."),
      sprintf("Scores reflect %s, and do so equally for all groups of %s.", construct, population),
      sprintf("Using the scores for %s is appropriate, with the human oversight, disclosure and appeals the use requires.", use)),
    threats = c(
      "The engine rewards surface features (length, vocabulary, spelling) rather than the ideas in the rubric; human scores used to train or check it are unreliable.",
      "An engine update, a new prompt or a change in the population shifts machine scores; agreement holds in one year only.",
      "Features unrelated to the construct, such as language proficiency, lower machine scores for some groups; DIF on AI-scored items.",
      "Machine scores are used without human review where stakes are high; test takers are not told how they were scored; errors cannot be appealed."),
    stringsAsFactors = FALSE)
  map <- list(Scoring = c("human agreement", "machine agreement", "overall bias", "agreement report"),
              Generalization = c("drift", "isomorphism"),
              Extrapolation = c("subgroup agreement", "differential scoring", "DIF", "leakage"),
              Decision = character(0))
  todo_none <- c(
    Scoring = "Compare machine and human scores on a double-scored validity sample with ai_audit().",
    Generalization = "Check drift across administrations and engine versions with ai_audit(period = ).",
    Extrapolation = "Check subgroup agreement, differential scoring and DIF with ai_audit(group = , responses = ).",
    Decision = "Document human review of flagged and low-confidence responses, disclosure to test takers, and an appeals process. No audit can supply this evidence.")
  ck <- if (is.null(audit)) NULL else as.data.frame(audit$checks)
  fl <- if (is.null(audit)) NULL else as.data.frame(audit$flags)
  inf$evidence <- inf$status <- inf$todo <- ""
  for (i in seq_len(nrow(inf))) {
    nm <- inf$inference[i]
    run <- if (is.null(ck)) character(0) else ck$check[ck$check %in% map[[nm]] & ck$status != "not run"]
    if (!length(run)) {
      inf$evidence[i] <- "None yet."
      inf$status[i] <- "needs evidence"
      inf$todo[i] <- todo_none[[nm]]
      next
    }
    f <- fl[fl$check %in% run, , drop = FALSE]
    ev <- vapply(run, function(cc) {
      r <- ck[ck$check == cc, ]
      fc <- f[f$check == cc, , drop = FALSE]
      if (!nrow(fc)) return(sprintf("%s: %d tested, no flags.", cap1(cc), r$tested))
      sprintf("%s: %d tested, flagged %s.", cap1(cc), r$tested,
              paste(sprintf("%s [%s]", fc$target, fc$value), collapse = "; "))
    }, "")
    inf$evidence[i] <- paste(ev, collapse = " ")
    inf$status[i] <- if (any(f$level == "block")) "threatened"
      else if (any(f$level == "review")) "partly supported" else "supported"
    missing <- setdiff(map[[nm]], c(run, "agreement report", "isomorphism", "leakage"))
    todo <- if (inf$status[i] == "supported") "" else
      "Resolve the flags, then rerun the audit before the scores are used."
    if (length(missing))
      todo <- trimws(paste(todo, sprintf("Not checked yet: %s.", paste(missing, collapse = ", "))))
    inf$todo[i] <- todo
  }
  structure(as_tbl(inf), class = c("mv_validity", class(as_tbl(inf))),
            construct = construct, use = use, population = population, component = component)
}

p_eq <- function(p) { f <- fmt_p(p); ifelse(substr(f, 1, 1) == "<", f, paste("=", f)) }

cap1 <- function(x) paste0(toupper(substring(x, 1, 1)), substring(x, 2))

#' @export
print.mv_validity <- function(x, ...) {
  if (!all(c("inference", "claim", "threats", "evidence", "status", "todo") %in% names(x)))
    return(NextMethod())
  cat(sprintf("Validity argument: %s scores for %s\n", attr(x, "construct"), attr(x, "use")))
  cat(sprintf("AI component: %s\n\n", attr(x, "component")))
  for (i in seq_len(nrow(x))) {
    cat(sprintf("%s [%s]\n", x$inference[i], toupper(x$status[i])))
    cat(strwrap(paste("Claim:", x$claim[i]), indent = 2, exdent = 4), sep = "\n")
    cat(strwrap(paste("Threats:", x$threats[i]), indent = 2, exdent = 4), sep = "\n")
    cat(strwrap(paste("Evidence:", x$evidence[i]), indent = 2, exdent = 4), sep = "\n")
    if (nzchar(x$todo[i])) cat(strwrap(paste("To do:", x$todo[i]), indent = 2, exdent = 4), sep = "\n")
    cat("\n")
  }
  invisible(x)
}

#' @rdname validity_argument
#' @param x an `mv_validity` object.
#' @param type `"html"` or `"markdown"`.
#' @param ... not used.
#' @export
format.mv_validity <- function(x, type = c("html", "markdown"), ...) {
  type <- match.arg(type)
  intro <- sprintf("The argument for using %s scores for %s, with %s, by the four inferences of the argument-based approach (Kane, 2013).",
                   attr(x, "construct"), attr(x, "use"), attr(x, "component"))
  if (type == "markdown") {
    rows <- vapply(seq_len(nrow(x)), function(i) {
      paste0("### ", x$inference[i], " (", x$status[i], ")\n\n",
             "- **Claim:** ", x$claim[i], "\n",
             "- **Threats:** ", x$threats[i], "\n",
             "- **Evidence:** ", x$evidence[i], "\n",
             if (nzchar(x$todo[i])) paste0("- **To do:** ", x$todo[i], "\n") else "")
    }, "")
    return(paste0(intro, "\n\n", paste(rows, collapse = "\n")))
  }
  h <- htmltools::tags
  col <- c(supported = "#1b7837", `partly supported` = "#b35806", threatened = "#b2182b",
           `needs evidence` = "#555555")
  as.character(htmltools::tagList(
    h$p(intro),
    h$table(class = "table",
      h$thead(h$tr(h$th("Inference"), h$th("Claim"), h$th("Threats from AI"), h$th("Evidence"),
                   h$th("Status"))),
      h$tbody(lapply(seq_len(nrow(x)), function(i) h$tr(
        h$td(h$strong(x$inference[i])), h$td(x$claim[i]), h$td(x$threats[i]),
        h$td(x$evidence[i], if (nzchar(x$todo[i])) h$p(h$em(paste("To do:", x$todo[i])))),
        h$td(h$span(style = sprintf("color:%s;font-weight:bold", col[[x$status[i]]]), x$status[i]))))))))
}
