#' Tidy a mirt model into a data frame of parameters
#'
#' Returns one row per estimated parameter, ready for dplyr, tables, and
#' plotting. For unidimensional models the traditional IRT parameterization
#' (discrimination `a`, difficulty `b`, guessing `g`, upper bound `u`) is used
#' by default; multidimensional models are reported in slope-intercept form.
#'
#' @param x a model returned by [mirt::mirt()] or [mirt::multipleGroup()].
#' @param IRTpars logical; use the traditional IRT parameterization when
#'   possible. Ignored (treated as `FALSE`) for multidimensional models.
#' @param conf.int logical; add Wald confidence limits (needs standard errors,
#'   i.e. the model fitted with `SE = TRUE`).
#' @param conf.level confidence level for `conf.int`.
#' @param group_pars logical; also return latent mean and (co)variance
#'   parameters.
#' @param ... unused.
#'
#' @return A tibble with columns `item`, `itemtype`, `term`, `estimate`, and
#'   `std.error` (plus `group`, `conf.low`, `conf.high` when relevant).
#' @examples
#' mod <- mirt(expand.table(LSAT7), 1, SE = TRUE, verbose = FALSE)
#' tidy(mod)
#' tidy(mod, conf.int = TRUE)
#' @name tidy_mirt
#' @method tidy SingleGroupClass
#' @export
tidy.SingleGroupClass <- function(x, IRTpars = TRUE, conf.int = FALSE,
                                  conf.level = 0.95, group_pars = FALSE, ...) {
  out <- tidy_pars(x, IRTpars = IRTpars, group_pars = group_pars)
  add_ci(out, conf.int, conf.level)
}

#' @rdname tidy_mirt
#' @method tidy MultipleGroupClass
#' @export
tidy.MultipleGroupClass <- function(x, IRTpars = TRUE, conf.int = FALSE,
                                    conf.level = 0.95, group_pars = TRUE, ...) {
  groups <- mirt::extract.mirt(x, "groupNames")
  out <- lapply(seq_along(groups), function(g) {
    gm <- mirt::extract.group(x, group = g)
    res <- tidy_pars(gm, IRTpars = IRTpars, group_pars = group_pars)
    res$group <- groups[g]
    res
  })
  out <- do.call(rbind, out)
  out <- out[, c("group", setdiff(names(out), "group"))]
  add_ci(as_tbl(out), conf.int, conf.level)
}

tidy_pars <- function(x, IRTpars = TRUE, group_pars = FALSE) {
  nfact <- mirt::extract.mirt(x, "nfact")
  use_irt <- IRTpars && nfact == 1L
  itemtype <- mirt::extract.mirt(x, "itemtype")
  cf <- NULL
  if (use_irt)
    cf <- safe(mirt::coef(x, IRTpars = TRUE, printSE = TRUE))
  if (is.null(cf)) {
    use_irt <- FALSE
    cf <- mirt::coef(x, printSE = TRUE)
  }
  nms <- item_names(x)
  rows <- list()
  for (nm in names(cf)) {
    m <- cf[[nm]]
    if (!is.matrix(m)) m <- matrix(m, nrow = 1, dimnames = list("par", names(m)))
    est <- m[1, ]
    se <- if ("SE" %in% rownames(m)) m["SE", ] else rep(NA_real_, length(est))
    if (nm %in% nms) {
      rows[[length(rows) + 1]] <- data.frame(
        component = "item", item = nm, itemtype = itemtype[match(nm, nms)],
        term = colnames(m), estimate = as.numeric(est),
        std.error = as.numeric(se), stringsAsFactors = FALSE)
    } else if (group_pars && nm == "GroupPars") {
      rows[[length(rows) + 1]] <- data.frame(
        component = "group", item = NA_character_, itemtype = NA_character_,
        term = colnames(m), estimate = as.numeric(est),
        std.error = as.numeric(se), stringsAsFactors = FALSE)
    }
  }
  out <- do.call(rbind, rows)
  # drop fixed bounds that carry no information (e.g. g = 0, u = 1 in a 2PL)
  fixed <- out$component == "item" & is.na(out$std.error) &
    ((out$term == "g" & out$estimate == 0) | (out$term == "u" & out$estimate == 1))
  out <- out[!fixed, ]
  if (!group_pars) out$component <- NULL
  out <- as_tbl(out)
  attr(out, "parameterization") <- if (use_irt) "IRT (a, b, g, u)" else "slope-intercept"
  out
}

add_ci <- function(out, conf.int, conf.level) {
  if (!conf.int) return(out)
  z <- stats::qnorm(1 - (1 - conf.level) / 2)
  out$conf.low <- out$estimate - z * out$std.error
  out$conf.high <- out$estimate + z * out$std.error
  out
}

#' One-row model summary
#'
#' Collects sample size, information criteria, convergence, limited-information
#' fit (M2 or C2) and marginal reliability in a single row, which makes it easy
#' to compare models with `rbind()`.
#'
#' @param x a model returned by [mirt::mirt()].
#' @param fit logical; compute the M2-family fit statistics. For polytomous
#'   items the C2 statistic is used.
#' @param ... unused.
#' @return A one-row tibble.
#' @examples
#' mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
#' glance(mod)
#' @name glance_mirt
#' @method glance SingleGroupClass
#' @export
glance.SingleGroupClass <- function(x, fit = TRUE, ...) {
  ex <- function(what) mirt::extract.mirt(x, what)
  itemtype <- ex("itemtype")
  out <- data.frame(
    nobs = nrow(ex("data")),
    nitems = ex("nitems"),
    nfact = ex("nfact"),
    itemtype = paste(unique(itemtype), collapse = "/"),
    npar = ex("nestpars"),
    logLik = ex("logLik"),
    AIC = ex("AIC"), BIC = ex("BIC"), SABIC = ex("SABIC"),
    converged = isTRUE(ex("converged")),
    method = ex("method"),
    stringsAsFactors = FALSE)
  if (fit) {
    m2 <- model_fit_stats(x)
    out <- cbind(out, m2)
  }
  out$reliability <- if (ex("nfact") == 1L) safe(mirt::marginal_rxx(x), NA_real_)
                     else NA_real_
  as_tbl(out)
}

#' @rdname glance_mirt
#' @method glance MultipleGroupClass
#' @export
glance.MultipleGroupClass <- function(x, ...) {
  ex <- function(what) mirt::extract.mirt(x, what)
  as_tbl(data.frame(
    nobs = nrow(ex("data")), nitems = ex("nitems"), nfact = ex("nfact"),
    ngroups = ex("ngroups"), npar = ex("nestpars"), logLik = ex("logLik"),
    AIC = ex("AIC"), BIC = ex("BIC"), SABIC = ex("SABIC"),
    converged = isTRUE(ex("converged")), stringsAsFactors = FALSE))
}

model_fit_stats <- function(x) {
  K <- mirt::extract.mirt(x, "K")
  type <- if (all(K == 2L)) "M2" else "C2"
  m2 <- safe(mirt::M2(x, type = type, na.rm = TRUE))
  if (is.null(m2))
    return(data.frame(fit_stat = type, M2 = NA_real_, df = NA_real_,
                      p.value = NA_real_, RMSEA = NA_real_, SRMSR = NA_real_,
                      CFI = NA_real_, TLI = NA_real_))
  data.frame(fit_stat = type, M2 = m2[[1]][1], df = m2$df[1],
             p.value = m2$p[1], RMSEA = m2$RMSEA[1], SRMSR = m2$SRMSR[1],
             CFI = m2$CFI[1], TLI = m2$TLI[1])
}

#' Add person scores to the response data
#'
#' @param x a model returned by [mirt::mirt()].
#' @param data optional data frame to bind the scores to. Defaults to the
#'   response data used to fit the model.
#' @param method scoring method passed to [mirt::fscores()] (e.g. `"EAP"`,
#'   `"MAP"`, `"ML"`, `"WLE"`).
#' @param person_fit logical; add the standardized log-likelihood person-fit
#'   statistic `Zh`.
#' @param ... further arguments passed to [mirt::fscores()].
#' @return A tibble with the data plus `.F1` (one column per factor), `.se_F1`,
#'   and optionally `.Zh`.
#' @examples
#' mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
#' head(augment(mod))
#' @name augment_mirt
#' @method augment SingleGroupClass
#' @export
augment.SingleGroupClass <- function(x, data = NULL, method = "EAP",
                                     person_fit = FALSE, ...) {
  if (is.null(data)) data <- as.data.frame(mirt::extract.mirt(x, "data"))
  fs <- mirt::fscores(x, method = method, full.scores = TRUE,
                      full.scores.SE = TRUE, verbose = FALSE, ...)
  fs <- as.data.frame(unclass(fs))
  names(fs) <- paste0(".", sub("^SE_", "se_", names(fs)))
  if (nrow(fs) != nrow(data))
    stop("`data` must have one row per respondent in the fitted model.", call. = FALSE)
  out <- cbind(as.data.frame(data), fs)
  if (person_fit) {
    pf <- safe(mirt::personfit(x))
    out$.Zh <- if (is.null(pf)) NA_real_ else pf$Zh
  }
  as_tbl(out)
}

#' Tidy item statistics and item fit in one table
#'
#' Combines classical item statistics ([mirt::itemstats()]), IRT parameters and
#' item fit ([mirt::itemfit()]) into one row per item, with a `flag` column
#' that marks items worth reviewing.
#'
#' @param x a model returned by [mirt::mirt()].
#' @param fit_stats fit statistic passed to [mirt::itemfit()].
#' @param p_adjust p-value adjustment method (see [stats::p.adjust()]).
#' @param alpha significance level used for misfit flags.
#' @return A tibble with one row per item.
#' @examples
#' mod <- mirt(expand.table(LSAT7), 1, verbose = FALSE)
#' item_table(mod)
#' @export
item_table <- function(x, fit_stats = "S_X2", p_adjust = "none", alpha = 0.01) {
  check_single(x)
  dat <- mirt::extract.mirt(x, "data")
  nms <- item_names(x)
  ist <- safe(mirt::itemstats(dat)$itemstats)
  out <- data.frame(item = nms, itemtype = mirt::extract.mirt(x, "itemtype"),
                    stringsAsFactors = FALSE)
  if (!is.null(ist)) {
    out$N <- ist$N
    out$mean <- ist$mean
    out$item_total_r <- ist$cor_if_rm
  }
  out$discrimination <- as.numeric(item_slopes(x))
  out$location <- if (mirt::extract.mirt(x, "nfact") == 1L)
    as.numeric(item_locations(x)) else NA_real_
  fit <- safe(mirt::itemfit(x, fit_stats = fit_stats, na.rm = anyNA(dat)))
  if (!is.null(fit) && fit_stats == "S_X2") {
    out$S_X2 <- fit$S_X2
    out$df <- fit$df.S_X2
    out$RMSEA <- fit$RMSEA.S_X2
    out$p.value <- stats::p.adjust(fit$p.S_X2, method = p_adjust)
  } else if (!is.null(fit)) {
    out <- merge(out, fit, by = "item", sort = FALSE)
  }
  out$flag <- item_flags(out, alpha = alpha)
  as_tbl(out)
}

item_flags <- function(tab, alpha = 0.01) {
  f <- character(nrow(tab))
  add <- function(cond, msg) {
    cond[is.na(cond)] <- FALSE
    f[cond] <<- ifelse(f[cond] == "", msg, paste(f[cond], msg, sep = "; "))
  }
  if (!is.null(tab$discrimination)) add(tab$discrimination < 0.5, "low discrimination")
  if (!is.null(tab$discrimination)) add(tab$discrimination > 4, "very high discrimination")
  if (!is.null(tab$location)) add(abs(tab$location) > 3, "extreme location")
  if (!is.null(tab$item_total_r)) add(tab$item_total_r < 0.2, "low item-total correlation")
  if (!is.null(tab$p.value)) add(tab$p.value < alpha, "misfit")
  f
}
