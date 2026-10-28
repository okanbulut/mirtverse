# Internal helpers shared across mirtverse

is_mirt_model <- function(x) {
  methods::is(x, "SingleGroupClass") || methods::is(x, "MultipleGroupClass")
}

check_single <- function(x, arg = "x") {
  if (!methods::is(x, "SingleGroupClass"))
    stop(sprintf("`%s` must be a single-group model estimated with mirt::mirt().", arg),
         call. = FALSE)
  invisible(TRUE)
}

check_unidim <- function(x, what = "This function") {
  if (mirt::extract.mirt(x, "nfact") != 1L)
    stop(what, " currently supports unidimensional models only.", call. = FALSE)
  invisible(TRUE)
}

as_tbl <- function(df) {
  rownames(df) <- NULL
  tibble::as_tibble(df)
}

item_names <- function(x) mirt::extract.mirt(x, "itemnames")

# Resolve `which.items` given as numbers or names into integer indices
resolve_items <- function(x, which.items = NULL) {
  nms <- item_names(x)
  if (is.null(which.items)) return(seq_along(nms))
  if (is.character(which.items)) {
    idx <- match(which.items, nms)
    if (anyNA(idx))
      stop("Unknown item(s): ", paste(which.items[is.na(idx)], collapse = ", "),
           call. = FALSE)
    return(idx)
  }
  which.items <- as.integer(which.items)
  if (any(which.items < 1L | which.items > length(nms)))
    stop("`which.items` is out of range.", call. = FALSE)
  which.items
}

theta_grid <- function(theta_lim = c(-4, 4), n = 201) {
  seq(theta_lim[1], theta_lim[2], length.out = n)
}

# Long data frame of category response curves for unidimensional models
trace_data <- function(x, which.items = NULL, theta_lim = c(-4, 4), n = 201) {
  idx <- resolve_items(x, which.items)
  nms <- item_names(x)
  Theta <- matrix(theta_grid(theta_lim, n))
  mins <- mirt::extract.mirt(x, "mins")
  out <- lapply(idx, function(j) {
    it <- mirt::extract.item(x, j)
    P <- mirt::probtrace(it, Theta)
    K <- ncol(P)
    scores <- mins[j] + seq_len(K) - 1L
    cats <- as.character(scores)
    data.frame(item = nms[j],
               theta = rep(Theta[, 1], K),
               category = rep(cats, each = nrow(Theta)),
               prob = as.vector(P),
               expected = rep(as.vector(P %*% scores), K),
               top = rep(seq_len(K) == K, each = nrow(Theta)),
               first = rep(seq_len(K) == 1L, each = nrow(Theta)),
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, out)
  out$category <- factor(out$category, levels = sort(unique(as.numeric(out$category))))
  out$item <- factor(out$item, levels = nms[idx])
  out
}

info_data <- function(x, which.items = NULL, theta_lim = c(-4, 4), n = 201) {
  idx <- resolve_items(x, which.items)
  nms <- item_names(x)
  Theta <- matrix(theta_grid(theta_lim, n))
  out <- lapply(idx, function(j) {
    data.frame(item = nms[j], theta = Theta[, 1],
               info = mirt::iteminfo(mirt::extract.item(x, j), Theta),
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, out)
  out$item <- factor(out$item, levels = nms[idx])
  out
}

# Unidimensional item location: b for dichotomous items, mean of thresholds
# for polytomous items; falls back to -d/a when IRT parameters are unavailable
item_locations <- function(x) {
  cf <- tryCatch(mirt::coef(x, IRTpars = TRUE, simplify = TRUE)$items,
                 error = function(e) NULL)
  nms <- item_names(x)
  loc <- rep(NA_real_, length(nms))
  if (!is.null(cf)) {
    bcols <- grep("^b[0-9]*$", colnames(cf))
    if (length(bcols))
      loc <- apply(cf[, bcols, drop = FALSE], 1, function(r) mean(r, na.rm = TRUE))
  }
  if (anyNA(loc)) {
    # numeric fallback: theta where expected item score is at its midpoint
    Theta <- matrix(theta_grid(c(-6, 6), 601))
    for (j in which(is.na(loc))) {
      it <- mirt::extract.item(x, j)
      P <- mirt::probtrace(it, Theta)
      es <- as.vector(P %*% (seq_len(ncol(P)) - 1L))
      mid <- (ncol(P) - 1) / 2
      loc[j] <- Theta[which.min(abs(es - mid)), 1]
    }
  }
  stats::setNames(as.numeric(loc), nms)
}

item_slopes <- function(x) {
  cf <- mirt::coef(x, simplify = TRUE)$items
  acols <- grep("^a[0-9]+$", colnames(cf))
  if (!length(acols)) return(stats::setNames(rep(NA_real_, nrow(cf)), rownames(cf)))
  stats::setNames(sqrt(rowSums(cf[, acols, drop = FALSE]^2)), rownames(cf))
}

fmt <- function(x, digits = 2) formatC(x, format = "f", digits = digits)

fmt_p <- function(p) {
  ifelse(is.na(p), "NA", ifelse(p < .001, "< .001", sub("^0", "", fmt(p, 3))))
}

safe <- function(expr, default = NULL) {
  tryCatch(suppressWarnings(suppressMessages(expr)), error = function(e) default)
}
