#' Plain-language interpretation of IRT results
#'
#' Turns a fitted model into short, readable statements about model fit,
#' reliability, test targeting, problem items, local dependence and person
#' fit. Each statement quotes the numbers it rests on, so the text can go
#' straight into a report. The rules used are documented in the Details.
#'
#' Rules of thumb used:
#' * RMSEA (M2/C2): <= .05 close, <= .08 reasonable, <= .10 mediocre, otherwise poor.
#' * Marginal reliability: >= .90 excellent, >= .80 good, >= .70 acceptable.
#' * Discrimination: < 0.5 low, > 4 suspiciously high; location beyond +/- 3
#'   extreme; guessing > .30 high; S-X2 p < `alpha` misfit.
#' * Local dependence: Q3 more than 0.2 above the average Q3.
#' * Person fit: Zh < -1.96 flags aberrant response patterns.
#'
#' @param x a model from [mirt::mirt()], an `mv_model_selection` object from
#'   [select_model()], or an `mv_rt` object from [fit_rt()].
#' @param alpha significance level for item misfit.
#' @param ... unused.
#' @return An object of class `mv_interpretation`: a named list of character
#'   vectors, one per section. It prints as formatted text; use
#'   `as.character()` or `format(x, "markdown")` to reuse it.
#' @examples
#' mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
#' interpret(mod)
#' @export
interpret <- function(x, ...) UseMethod("interpret")

#' @rdname interpret
#' @method interpret SingleGroupClass
#' @export
interpret.SingleGroupClass <- function(x, alpha = 0.01, ...) {
  ex <- function(what) mirt::extract.mirt(x, what)
  nfact <- ex("nfact")
  dat <- ex("data")
  itemtype <- ex("itemtype")
  out <- list()

  out$Overview <- c(sprintf(
    "A %s model with %d dimension%s was fitted to %d respondents and %d items (%s estimation).",
    paste(unique(itemtype), collapse = "/"), nfact, if (nfact > 1) "s" else "",
    nrow(dat), ncol(dat), ex("method")),
    if (!isTRUE(ex("converged")))
      "Warning: the estimation did not converge, so the results below should not be trusted yet. Try more iterations (technical = list(NCYCLES = 2000)) or a simpler model."
    else "The estimation converged normally.",
    if (anyNA(dat)) sprintf("%.1f%% of responses are missing.", 100 * mean(is.na(dat))))

  fitst <- model_fit_stats(x)
  out$`Model fit` <- if (is.na(fitst$RMSEA)) {
    "Limited-information fit statistics could not be computed for this model (often because there are too few degrees of freedom)."
  } else {
    c(sprintf("Overall model fit is %s: %s = %s, df = %d, RMSEA = %s, CFI = %s, SRMSR = %s.",
              rmsea_label(fitst$RMSEA), fitst$fit_stat, fmt(fitst$M2, 2), as.integer(fitst$df),
              fmt(fitst$RMSEA, 3), fmt(fitst$CFI, 3), fmt(fitst$SRMSR, 3)),
      if (!is.na(fitst$p.value) && fitst$p.value < .05 && fitst$RMSEA <= .05)
        "The chi-square test is significant, but with large samples this is common; the RMSEA indicates the misfit is small in practical terms.")
  }

  if (nfact == 1L) {
    rxx <- safe(mirt::marginal_rxx(x), NA_real_)
    lab <- if (is.na(rxx)) "unknown" else if (rxx >= .9) "excellent" else if (rxx >= .8) "good" else
      if (rxx >= .7) "acceptable" else "low"
    out$Reliability <- c(sprintf("Marginal reliability is %s (%s).", fmt(rxx, 2), lab),
      if (!is.na(rxx) && rxx < .7) "Scores are too imprecise for decisions about individuals; consider adding items or using the scores only for group-level summaries.")

    th <- as.numeric(mirt::fscores(x, verbose = FALSE)[, 1])
    loc <- item_locations(x)
    Theta <- matrix(theta_grid(c(-4, 4)))
    ti <- mirt::testinfo(x, Theta)
    peak <- Theta[which.max(ti), 1]
    gap <- mean(loc, na.rm = TRUE) - mean(th, na.rm = TRUE)
    out$Targeting <- c(
      sprintf("The average item location is %s and the average person score is %s, so the test is %s for this group.",
              fmt(mean(loc, na.rm = TRUE)), fmt(mean(th, na.rm = TRUE)),
              if (abs(gap) < 0.5) "well targeted" else if (gap > 0) "relatively hard" else "relatively easy"),
      sprintf("Measurement is most precise around theta = %s (information = %s, SE = %s).",
              fmt(peak), fmt(max(ti)), fmt(1 / sqrt(max(ti)))))
  }

  it <- item_table(x, alpha = alpha)
  issues <- character()
  if (any(itemtype %in% c("3PL", "4PL"))) {
    cf <- safe(mirt::coef(x, IRTpars = TRUE, simplify = TRUE)$items)
    if (!is.null(cf) && "g" %in% colnames(cf)) {
      hi_g <- rownames(cf)[cf[, "g"] > .30]
      if (length(hi_g))
        issues <- c(issues, sprintf("High lower asymptote (guessing > .30): %s.",
                                    paste(hi_g, collapse = ", ")))
    }
  }
  for (lab in c("low discrimination", "very high discrimination", "extreme location",
                "low item-total correlation", "misfit")) {
    hit <- it$item[grepl(lab, it$flag, fixed = TRUE)]
    if (length(hit))
      issues <- c(issues, item_issue_text(lab, hit, it, alpha))
  }
  out$Items <- if (length(issues)) issues else
    "No items were flagged for low discrimination, extreme location, or misfit."

  q3 <- safe(q3_long(x))
  if (!is.null(q3)) {
    f <- q3[q3$flag, ]
    out$`Local dependence` <- if (nrow(f)) {
      f <- f[order(-f$Q3), ]
      top <- utils::head(f, 5)
      c(sprintf("%d item %s possible local dependence (Q3 exceeds the average of %s by more than 0.2).",
                nrow(f), if (nrow(f) > 1) "pairs show" else "pair shows", fmt(attr(q3, "average"))),
        sprintf("Strongest: %s.", paste(sprintf("%s & %s (Q3 = %s)", top$item1, top$item2,
                                                 fmt(top$Q3)), collapse = "; ")),
        "Check whether these items share a stimulus, wording, or content; consider a testlet or bifactor model.")
    } else "No item pairs show signs of local dependence (Q3)."
  }

  pf <- safe(mirt::personfit(x))
  if (!is.null(pf)) {
    pr <- mean(pf$Zh < -1.96, na.rm = TRUE)
    out$`Person fit` <- sprintf(
      "%.1f%% of respondents have unusual response patterns (Zh < -1.96)%s",
      100 * pr, if (pr > .1) ", which is more than expected by chance; look for careless responding or speededness." else ", which is within what chance alone would produce.")
  }
  structure(out, class = "mv_interpretation")
}

item_issue_text <- function(lab, hit, it, alpha) {
  sub <- it[match(hit, it$item), ]
  detail <- switch(lab,
    "low discrimination" = sprintf("%s (a = %s)", hit, fmt(sub$discrimination)),
    "very high discrimination" = sprintf("%s (a = %s)", hit, fmt(sub$discrimination)),
    "extreme location" = sprintf("%s (b = %s)", hit, fmt(sub$location)),
    "low item-total correlation" = sprintf("%s (r = %s)", hit, fmt(sub$item_total_r)),
    "misfit" = sprintf("%s (S-X2 p %s)", hit, ifelse(sub$p.value < .001, "< .001",
                                                     paste("=", fmt_p(sub$p.value)))))
  advice <- switch(lab,
    "low discrimination" = "These items barely separate high and low scorers; review the key and wording.",
    "very high discrimination" = "Very steep curves can signal local dependence or a near-duplicate item.",
    "extreme location" = "These items are far too easy or too hard for most respondents.",
    "low item-total correlation" = "These items relate weakly to the rest of the test.",
    "misfit" = sprintf("The model does not describe responses to these items well (alpha = %s); inspect them with gg_empirical() or item_card().", alpha))
  sprintf("%s%s: %s. %s", toupper(substr(lab, 1, 1)), substring(lab, 2),
          paste(detail, collapse = ", "), advice)
}

#' @rdname interpret
#' @method interpret mv_model_selection
#' @export
interpret.mv_model_selection <- function(x, ...) {
  structure(list(`Model selection` = x$explanation), class = "mv_interpretation")
}

#' @method print mv_interpretation
#' @export
print.mv_interpretation <- function(x, ...) {
  for (nm in names(x)) {
    cat(nm, "\n", strrep("-", nchar(nm)), "\n", sep = "")
    for (s in x[[nm]])
      cat(paste(strwrap(s, width = 78, initial = "* ", exdent = 2), collapse = "\n"), "\n")
    cat("\n")
  }
  invisible(x)
}

#' @method format mv_interpretation
#' @export
format.mv_interpretation <- function(x, style = c("text", "markdown"), ...) {
  style <- match.arg(style)
  if (style == "markdown")
    return(paste(unlist(lapply(names(x), function(nm)
      c(paste("###", nm), "", paste("-", x[[nm]]), ""))), collapse = "\n"))
  paste(utils::capture.output(print(x)), collapse = "\n")
}

#' @method as.character mv_interpretation
#' @export
as.character.mv_interpretation <- function(x, ...) unlist(unclass(x), use.names = FALSE)

#' Build a prompt for an AI assistant from a fitted model
#'
#' Packs the key results of a model (parameters, fit, reliability and the
#' rule-based interpretation) into a text prompt you can paste into any large
#' language model to get a longer narrative or a draft technical-report
#' section. Nothing is sent anywhere by this function.
#'
#' @param x a model from [mirt::mirt()].
#' @param audience who the text is for, e.g. `"teachers"` or
#'   `"a psychometric technical report"`.
#' @return A single character string.
#' @examples
#' mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
#' cat(interpret_prompt(mod))
#' @export
interpret_prompt <- function(x, audience = "a psychometric technical report") {
  check_single(x)
  pars <- as.data.frame(tidy(x))
  g <- as.data.frame(glance(x))
  paste0(
    "You are an expert psychometrician. Write a clear, accurate summary of the ",
    "following item response theory results for ", audience, ". Quote numbers ",
    "where they support a point and do not invent results.\n\n",
    "## Model summary\n", paste(utils::capture.output(print(g, row.names = FALSE)), collapse = "\n"),
    "\n\n## Item parameters\n", paste(utils::capture.output(print(pars, row.names = FALSE)), collapse = "\n"),
    "\n\n## Rule-based findings\n", format(interpret(x), style = "markdown"))
}
