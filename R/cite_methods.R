#' Write the Methods paragraph for an IRT analysis
#'
#' Drafts the software, model, estimation, fit and reliability sentences of a
#' Methods section in APA style, with the references they cite. Give it a
#' fitted model, or the result of [select_model()] to also describe how the
#' model was chosen. The text is a starting point: Read it, check that it
#' describes what you did, and edit it.
#'
#' Numbers follow APA conventions: Statistics that cannot exceed 1 (p values,
#' RMSEA, SRMSR, CFI, reliability) have no leading zero, and p values below
#' .001 are reported as `p < .001`.
#'
#' @param x a unidimensional or multidimensional model from [mirt::mirt()], or
#'   an `mv_model_selection` object from [select_model()].
#' @param sample optional description of the respondents, such as
#'   `"undergraduate students"`. Used as "the responses of 1,200
#'   undergraduate students".
#' @param items optional description of the items, such as
#'   `"multiple-choice items from a statistics exam"`.
#' @param fit logical; report limited-information fit (M2, or C2 for
#'   polytomous items).
#' @param item_fit logical; report how many items show misfit on the S-X2
#'   statistic.
#' @param alpha significance level for item misfit.
#' @param dropped optional character vector of items removed before the
#'   final calibration, with the reason in `dropped_reason`.
#' @param dropped_reason optional reason for dropping the items, such as
#'   `"a negative item-total correlation"`.
#' @param file optional output file. A `.docx` file is written with pandoc
#'   (through rmarkdown); any other extension gets Markdown text.
#' @return An object of class `mv_methods` with `text` (the paragraphs, as a
#'   character vector) and `references` (APA references, alphabetical).
#'   `format()` and `as.character()` give the whole text as one string,
#'   and printing shows it.
#' @seealso The [thesis kit](https://www.okanbulut.com/mirtverse/articles/thesis-kit.html)
#'   article.
#' @examples
#' mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
#' cite_methods(mod, sample = "law school applicants",
#'              items = "items from the Law School Admission Test")
#' \donttest{
#' sel <- select_model(expand.table(LSAT7), verbose = FALSE)
#' cite_methods(sel)
#' }
#' @export
cite_methods <- function(x, sample = NULL, items = NULL, fit = TRUE, item_fit = TRUE,
                         alpha = 0.01, dropped = NULL, dropped_reason = NULL,
                         file = NULL) {
  sel <- NULL
  if (inherits(x, "mv_model_selection")) {
    sel <- x
    x <- x$best
  }
  check_single(x)
  refs <- c("r", "mirt", "mirtverse")
  ex <- function(what) mirt::extract.mirt(x, what)

  N <- nrow(ex("data"))
  J <- ex("nitems")
  K <- ex("K")
  dich <- all(K == 2L)
  nfact <- ex("nfact")
  itemtype <- unique(ex("itemtype"))

  # 1. Software
  p_soft <- sprintf(paste(
    "Analyses were conducted in R (version %s; R Core Team, %s) with the mirt",
    "package (version %s; Chalmers, 2012) for item response theory (IRT) and the",
    "mirtverse package (version %s; Bulut, 2026) for model comparison, fit",
    "summaries and reporting."),
    paste(R.version$major, R.version$minor, sep = "."), R.version$year,
    utils::packageVersion("mirt"), utils::packageVersion("mirtverse"))

  # 2. Model and estimation
  mdesc <- vapply(itemtype, describe_itemtype, character(1), dich = dich)
  refs <- c(refs, unlist(lapply(itemtype, itemtype_refs, dich = dich)))
  model_txt <- if (length(mdesc) == 1L) unname(mdesc)
               else paste0("model combining the ", and_list(unname(mdesc)))
  dim_txt <- if (nfact == 1L) "unidimensional" else sprintf("%d-dimensional exploratory", nfact)
  who <- if (is.null(sample)) "respondents" else sample
  what <- if (is.null(items)) "items" else items
  kk <- sort(unique(K))
  item_txt <- if (dich) paste(J, "dichotomously scored", what) else
    sprintf("%d %s scored in %s categories", J, what,
            if (length(kk) == 1) kk else paste(range(kk), collapse = " to "))
  method <- ex("method")
  est_txt <- switch(method,
    EM = { refs <- c(refs, "bock1981")
           "marginal maximum likelihood with the expectation-maximization (EM) algorithm (Bock & Aitkin, 1981)" },
    QMCEM = { refs <- c(refs, "bock1981")
           "marginal maximum likelihood with quasi-Monte Carlo EM integration (Bock & Aitkin, 1981)" },
    MHRM = { refs <- c(refs, "cai2010")
           "the Metropolis-Hastings Robbins-Monro algorithm (Cai, 2010)" },
    sprintf("the %s estimation method", method))
  p_model <- sprintf(paste(
    "A %s %s was fitted to the responses of %s %s to %s, using %s."),
    dim_txt, model_txt, format(N, big.mark = ","), who, item_txt, est_txt)
  if (!is.null(dropped) && length(dropped)) {
    p_model <- paste(p_model, sprintf("%s %s removed before the final calibration%s.",
      and_list(dropped),
      if (length(dropped) == 1) "was" else "were",
      if (is.null(dropped_reason)) "" else paste0(" because of ", dropped_reason)))
  }

  # 3. Model choice
  p_sel <- NULL
  if (!is.null(sel)) {
    tab <- as.data.frame(sel$table)
    crit <- sel$criterion
    refs <- c(refs, switch(crit, BIC = "schwarz1978", AIC = "akaike1974", SABIC = "sclove1987"))
    others <- tab[tab$model != sel$best_name, , drop = FALSE]
    p_sel <- sprintf(paste(
      "To choose the model, the %s models were compared on the %s (%s); the %s model had the",
      "lowest value (%s = %s%s)."),
      and_list(tab$model[order(tab$npar)]),
      c(BIC = "Bayesian information criterion", AIC = "Akaike information criterion",
        SABIC = "sample-size adjusted Bayesian information criterion")[[crit]],
      crit_cite(crit), sel$best_name, crit, fmt(tab[[crit]][tab$model == sel$best_name], 1),
      if (nrow(others)) paste0(", compared with ", and_list(sprintf("%s for the %s",
        fmt(others[[crit]], 1), others$model))) else "")
    lrt <- sel$lrt
    if (is.data.frame(lrt) && nrow(lrt)) {
      lrt <- as.data.frame(lrt)
      best_rows <- lrt[lrt$complex == sel$best_name | lrt$simpler == sel$best_name, , drop = FALSE]
      if (nrow(best_rows)) {
        p_sel <- paste(p_sel, paste0("Likelihood-ratio tests between nested models gave ",
          and_list(sprintf("\u03c7\u00b2(%d) = %s, p %s for the %s against the %s",
                           as.integer(best_rows$df), fmt(best_rows$X2, 2),
                           vapply(best_rows$p.value, p_eq, character(1)),
                           best_rows$complex, best_rows$simpler)), "."))
      }
    }
  }

  # 4. Fit and reliability
  p_fit <- NULL
  if (fit) {
    g <- model_fit_stats(x)
    if (!is.na(g$M2)) {
      stat <- g$fit_stat
      refs <- c(refs, if (stat == "M2") "maydeu2006" else "cai2014")
      p_fit <- sprintf(paste(
        "Overall model fit was evaluated with the limited-information %s statistic (%s):",
        "%s(%d) = %s, p %s, RMSEA = %s, SRMSR = %s, CFI = %s."),
        stat, if (stat == "M2") "Maydeu-Olivares & Joe, 2006" else "Cai & Monroe, 2014",
        stat, as.integer(g$df), fmt(g$M2, 2), p_eq(g$p.value), apa0(g$RMSEA, 3),
        apa0(g$SRMSR, 3), apa0(g$CFI, 3))
    }
  }
  if (item_fit) {
    it <- safe(mirt::itemfit(x, fit_stats = "S_X2", na.rm = anyNA(ex("data"))))
    if (!is.null(it)) {
      refs <- c(refs, "orlando2000")
      bad <- it$item[!is.na(it$p.S_X2) & it$p.S_X2 < alpha]
      p_fit <- paste(c(p_fit, sprintf(
        "Item fit was examined with the S-X\u00b2 statistic (Orlando & Thissen, 2000); %s at \u03b1 = %s.",
        if (!length(bad)) sprintf("none of the %d items showed misfit", J)
        else sprintf("%d of the %d items (%s) showed misfit", length(bad), J, and_list(bad)),
        sub("^0", "", format(alpha)))), collapse = " ")
    }
  }
  if (nfact == 1L) {
    rxx <- safe(mirt::marginal_rxx(x), NA_real_)
    if (!is.na(rxx))
      p_fit <- paste(c(p_fit, sprintf("Marginal reliability was %s.", apa0(rxx, 2))),
                     collapse = " ")
  }

  text <- c(p_soft, p_model, p_sel, p_fit)
  text <- text[!vapply(text, is.null, logical(1))]
  out <- structure(list(text = text, references = methods_references(unique(refs))),
                   class = "mv_methods")
  if (!is.null(file)) write_methods(out, file)
  out
}

#' @export
format.mv_methods <- function(x, ...) {
  paste(c(x$text, "", "References", "", x$references), collapse = "\n\n")
}

#' @export
as.character.mv_methods <- function(x, ...) format(x, ...)

#' @export
print.mv_methods <- function(x, ...) {
  w <- 0.9 * getOption("width")
  wrap <- function(v, ...) vapply(v, function(t) paste(strwrap(t, width = w, ...),
                                                      collapse = "\n"), character(1))
  cat(wrap(x$text), sep = "\n\n")
  cat("\nReferences\n\n")
  cat(wrap(x$references, exdent = 4), sep = "\n")
  cat("\nCheck the text against your analysis before you use it.\n")
  invisible(x)
}

write_methods <- function(x, file) {
  md <- paste(c("## Method", "", paste(x$text, collapse = "\n\n"), "",
                "## References", "", paste(x$references, collapse = "\n\n")),
              collapse = "\n")
  # APA references italicise titles with *...*, which Markdown keeps
  if (grepl("\\.docx$", file, ignore.case = TRUE)) {
    if (!requireNamespace("rmarkdown", quietly = TRUE) || !rmarkdown::pandoc_available())
      stop("Writing a Word file needs the rmarkdown package and pandoc.", call. = FALSE)
    tmp <- tempfile(fileext = ".md")
    writeLines(md, tmp, useBytes = TRUE)
    # pandoc runs in the temp folder, so the output path must be absolute;
    # normalizePath() leaves a relative path unchanged when the file is new
    out <- file.path(normalizePath(dirname(file), mustWork = TRUE), basename(file))
    rmarkdown::pandoc_convert(tmp, to = "docx", output = out)
  } else {
    writeLines(md, file, useBytes = TRUE)
  }
  invisible(file)
}

describe_itemtype <- function(itemtype, dich) {
  switch(itemtype,
    Rasch = if (dich) "Rasch model (Rasch, 1960)" else "partial credit model (Masters, 1982)",
    `2PL` = "two-parameter logistic (2PL) model (Birnbaum, 1968)",
    `3PL` = "three-parameter logistic (3PL) model (Birnbaum, 1968)",
    `4PL` = "four-parameter logistic (4PL) model (Barton & Lord, 1981)",
    graded = "graded response model (Samejima, 1969)",
    gpcm = "generalized partial credit model (Muraki, 1992)",
    rsm = "rating scale model (Andrich, 1978)",
    nominal = "nominal response model (Bock, 1972)",
    sprintf("%s model", itemtype))
}

itemtype_refs <- function(itemtype, dich) {
  switch(itemtype,
    Rasch = if (dich) "rasch1960" else "masters1982",
    `2PL` = , `3PL` = "birnbaum1968",
    `4PL` = "barton1981",
    graded = "samejima1969",
    gpcm = "muraki1992",
    rsm = "andrich1978",
    nominal = "bock1972",
    character(0))
}

crit_cite <- function(crit) {
  c(BIC = "Schwarz, 1978", AIC = "Akaike, 1974", SABIC = "Sclove, 1987")[[crit]]
}

and_list <- function(x) {
  x <- as.character(x)
  n <- length(x)
  if (n <= 1) return(x)
  if (n == 2) return(paste(x, collapse = " and "))
  paste0(paste(x[-n], collapse = ", "), ", and ", x[n])
}

# APA style for statistics bounded by 1: no leading zero
apa0 <- function(v, digits = 2) sub("^(-?)0\\.", "\\1.", fmt(v, digits))

p_eq <- function(p) if (is.na(p)) "= NA" else if (p < .001) "< .001" else paste("=", apa0(p, 3))

methods_references <- function(keys) {
  db <- c(
    r = sprintf("R Core Team. (%s). *R: A language and environment for statistical computing*. R Foundation for Statistical Computing. https://www.R-project.org/",
                R.version$year),
    mirt = "Chalmers, R. P. (2012). mirt: A multidimensional item response theory package for the R environment. *Journal of Statistical Software, 48*(6), 1\u201329. https://doi.org/10.18637/jss.v048.i06",
    mirtverse = sprintf("Bulut, O. (2026). *mirtverse: A friendly workflow and reporting layer for 'mirt'* (Version %s) [R package]. Zenodo. https://doi.org/10.5281/zenodo.23719384",
                        utils::packageVersion("mirtverse")),
    bock1981 = "Bock, R. D., & Aitkin, M. (1981). Marginal maximum likelihood estimation of item parameters: Application of an EM algorithm. *Psychometrika, 46*(4), 443\u2013459. https://doi.org/10.1007/BF02293801",
    cai2010 = "Cai, L. (2010). High-dimensional exploratory item factor analysis by a Metropolis\u2013Hastings Robbins\u2013Monro algorithm. *Psychometrika, 75*(1), 33\u201357. https://doi.org/10.1007/s11336-009-9136-x",
    maydeu2006 = "Maydeu-Olivares, A., & Joe, H. (2006). Limited information goodness-of-fit testing in multidimensional contingency tables. *Psychometrika, 71*(4), 713\u2013732. https://doi.org/10.1007/s11336-005-1295-9",
    cai2014 = "Cai, L., & Monroe, S. (2014). *A new statistic for evaluating item response theory models for ordinal data* (CRESST Report 839). University of California, Los Angeles, National Center for Research on Evaluation, Standards, and Student Testing.",
    orlando2000 = "Orlando, M., & Thissen, D. (2000). Likelihood-based item-fit indices for dichotomous item response theory models. *Applied Psychological Measurement, 24*(1), 50\u201364. https://doi.org/10.1177/01466216000241003",
    rasch1960 = "Rasch, G. (1960). *Probabilistic models for some intelligence and attainment tests*. Danish Institute for Educational Research.",
    birnbaum1968 = "Birnbaum, A. (1968). Some latent trait models and their use in inferring an examinee's ability. In F. M. Lord & M. R. Novick (Eds.), *Statistical theories of mental test scores* (pp. 397\u2013479). Addison-Wesley.",
    barton1981 = "Barton, M. A., & Lord, F. M. (1981). *An upper asymptote for the three-parameter logistic item-response model* (Research Report 81-20). Educational Testing Service.",
    samejima1969 = "Samejima, F. (1969). Estimation of latent ability using a response pattern of graded scores. *Psychometrika Monograph Supplement, 34*(4, Pt. 2), 100.",
    muraki1992 = "Muraki, E. (1992). A generalized partial credit model: Application of an EM algorithm. *Applied Psychological Measurement, 16*(2), 159\u2013176. https://doi.org/10.1177/014662169201600206",
    masters1982 = "Masters, G. N. (1982). A Rasch model for partial credit scoring. *Psychometrika, 47*(2), 149\u2013174. https://doi.org/10.1007/BF02296272",
    andrich1978 = "Andrich, D. (1978). A rating formulation for ordered response categories. *Psychometrika, 43*(4), 561\u2013573. https://doi.org/10.1007/BF02293814",
    bock1972 = "Bock, R. D. (1972). Estimating item parameters and latent ability when responses are scored in two or more nominal categories. *Psychometrika, 37*(1), 29\u201351. https://doi.org/10.1007/BF02291411",
    schwarz1978 = "Schwarz, G. (1978). Estimating the dimension of a model. *The Annals of Statistics, 6*(2), 461\u2013464. https://doi.org/10.1214/aos/1176344136",
    akaike1974 = "Akaike, H. (1974). A new look at the statistical model identification. *IEEE Transactions on Automatic Control, 19*(6), 716\u2013723. https://doi.org/10.1109/TAC.1974.1100705",
    sclove1987 = "Sclove, S. L. (1987). Application of model-selection criteria to some problems in multivariate analysis. *Psychometrika, 52*(3), 333\u2013343. https://doi.org/10.1007/BF02294360")
  out <- unname(db[intersect(keys, names(db))])
  out[order(sub("^\\W+", "", out))]
}
