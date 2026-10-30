#' An item bank
#'
#' An item bank holds calibrated items on one common scale, with their mirt
#' parameters, a summary of their location and discrimination, where they came
#' from and whether they are in use. Start a bank from a calibrated model or
#' pipeline with `mv_bank()`, put a new calibration on the bank's scale with
#' [link_to_bank()], and add its new items with [bank_items()]. A bank is an
#' ordinary R object: keep it between administrations with [saveRDS()] and
#' [readRDS()].
#'
#' Supported item types are the unidimensional `"Rasch"`, `"2PL"`, `"3PL"`,
#' `"graded"` and `"gpcm"` models.
#'
#' @param x a unidimensional model from [mirt::mirt()], or a calibrated
#'   pipeline from [calibrate()] (if the pipeline was linked with
#'   [link_to_bank()], its parameters are taken on the bank's scale).
#' @param name a name for the bank.
#' @param source a label for where the items came from, such as the
#'   administration. Defaults to the pipeline title, or `"calibration"`.
#' @return An object of class `mv_bank`: a list with `name`, `items` (a tibble
#'   with one row per item: `item`, `itemtype`, `ncat`, `a` (discrimination),
#'   `b` (location; the mean threshold for polytomous items), `g` (lower
#'   asymptote), `source`, `added`, `status` and the list column `pars` with
#'   the mirt slope-intercept parameters) and `history`.
#' @seealso [bank_items()], [link_to_bank()]
#' @examples
#' \donttest{
#' mod <- mirt(expand.table(LSAT7), 1, itemtype = "2PL", verbose = FALSE)
#' bank <- mv_bank(mod, name = "LSAT bank")
#' bank
#' }
#' @export
mv_bank <- function(x, name = "Item bank", source = NULL) {
  if (inherits(x, "mv_pipeline")) {
    if (is.null(x$model)) stop("Calibrate the pipeline with calibrate() first.", call. = FALSE)
    if (is.null(source)) source <- x$title
    items <- pipeline_bank_rows(x, source)
  } else {
    check_single(x)
    check_unidim(x, "mv_bank()")
    items <- model_bank_rows(x, if (is.null(source)) "calibration" else source)
  }
  structure(list(name = name, items = items,
                 history = data.frame(time = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                                      action = "create",
                                      detail = sprintf("%d items from %s", nrow(items),
                                                       items$source[1]),
                                      stringsAsFactors = FALSE)),
            class = "mv_bank")
}

bank_types <- c("Rasch", "2PL", "3PL", "graded", "gpcm")

# One bank row per item of a model, with parameters transformed to the bank
# scale by theta_bank = A * theta + B.
model_bank_rows <- function(mod, source, A = 1, B = 0) {
  nms <- item_names(mod)
  types <- mirt::extract.mirt(mod, "itemtype")
  bad <- setdiff(unique(types), bank_types)
  if (length(bad))
    stop("Item type(s) not supported in a bank: ", paste(bad, collapse = ", "),
         ". Use ", paste(bank_types, collapse = ", "), ".", call. = FALSE)
  co <- mirt::coef(mod)
  pars <- lapply(seq_along(nms), function(j)
    transform_pars(co[[nms[j]]][1, ], types[j], A, B))
  names(pars) <- nms
  rows <- lapply(seq_along(nms), function(j) {
    s <- par_summary(pars[[j]], types[j])
    data.frame(item = nms[j], itemtype = types[j], ncat = s$ncat, a = s$a, b = s$b, g = s$g,
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  out$source <- source
  out$added <- format(Sys.Date())
  out$status <- "active"
  out <- as_tbl(out)
  out$pars <- unname(pars)
  out
}

pipeline_bank_rows <- function(p, source) {
  A <- B <- NULL
  if (!is.null(p$link) && p$link$method != "fixed") {
    A <- p$link$A
    B <- p$link$B
  }
  model_bank_rows(p$model, source, if (is.null(A)) 1 else A, if (is.null(B)) 0 else B)
}

# mirt slope-intercept parameters after the change of scale
# theta_bank = A * theta + B: a1 -> a1 / A and every intercept d_k ->
# d_k - a1 * s_k * B / A, where s_k is the category's scoring weight (1 for
# dichotomous and graded items, ak_k for gpcm).
transform_pars <- function(par, type, A = 1, B = 0) {
  par <- par[!is.na(par)]
  a1 <- par[["a1"]]
  dn <- grep("^d[0-9]*$", names(par))
  w <- if (type == "gpcm") par[paste0("ak", sub("^d", "", names(par)[dn]))] else 1
  par[dn] <- par[dn] - a1 * w * B / A
  par[["a1"]] <- a1 / A
  par
}

par_summary <- function(par, type) {
  a1 <- par[["a1"]]
  if (type %in% c("Rasch", "2PL", "3PL"))
    return(list(ncat = 2L, a = a1, b = -par[["d"]] / a1,
                g = if ("g" %in% names(par)) par[["g"]] else 0))
  if (type == "graded") {
    d <- par[grep("^d[0-9]+$", names(par))]
    return(list(ncat = length(d) + 1L, a = a1, b = mean(-d / a1), g = NA_real_))
  }
  d <- par[grep("^d[0-9]+$", names(par))]
  steps <- -diff(d) / a1
  list(ncat = length(d), a = a1, b = mean(steps), g = NA_real_)
}

# Category probabilities (rows = theta, columns = categories) from mirt
# slope-intercept parameters.
item_probs <- function(par, type, theta) {
  a1 <- par[["a1"]]
  if (type %in% c("Rasch", "2PL", "3PL")) {
    g <- if ("g" %in% names(par)) par[["g"]] else 0
    u <- if ("u" %in% names(par)) par[["u"]] else 1
    p1 <- g + (u - g) / (1 + exp(-(a1 * theta + par[["d"]])))
    return(cbind(1 - p1, p1))
  }
  d <- par[grep("^d[0-9]+$", names(par))]
  if (type == "graded") {
    star <- cbind(1, sapply(d, function(dk) 1 / (1 + exp(-(a1 * theta + dk)))), 0)
    return(star[, -ncol(star), drop = FALSE] - star[, -1, drop = FALSE])
  }
  ak <- par[paste0("ak", seq_along(d) - 1L)]
  z <- sapply(seq_along(d), function(k) ak[k] * a1 * theta + d[k])
  z <- matrix(z, nrow = length(theta))
  e <- exp(z - apply(z, 1L, max))
  e / rowSums(e)
}

item_expected <- function(par, type, theta) {
  pr <- item_probs(par, type, theta)
  drop(pr %*% (seq_len(ncol(pr)) - 1L))
}

#' @export
print.mv_bank <- function(x, ...) {
  it <- x$items
  act <- it$status == "active"
  cat(sprintf("<mv_bank> %s: %d items (%d active)\n", x$name, nrow(it), sum(act)))
  tab <- table(it$itemtype[act])
  cat("Item types:", paste(sprintf("%s %d", names(tab), as.integer(tab)), collapse = ", "), "\n")
  if (any(act))
    cat(sprintf("Location (b) from %.2f to %.2f; median discrimination %.2f\n",
                min(it$b[act]), max(it$b[act]), stats::median(it$a[act])))
  srcs <- unique(it$source)
  cat("Sources:", paste(srcs, collapse = ", "), "\n")
  invisible(x)
}

#' @rdname mv_bank
#' @param ... not used.
#' @export
tidy.mv_bank <- function(x, ...) x$items[, setdiff(names(x$items), "pars")]

#' Pipeline stage: add items to a bank
#'
#' Adds the items of a calibrated pipeline to an item bank, on the bank's
#' scale. With no `bank`, a new bank is started from the pipeline. With an
#' existing bank, the pipeline should first be linked to it with
#' [link_to_bank()] so that the new items are on the same scale; items already
#' in the bank (the anchors) keep their bank parameters unless
#' `update_anchors = TRUE`.
#'
#' @param p a calibrated pipeline from [calibrate()].
#' @param bank optional existing bank from [mv_bank()].
#' @param name name for a new bank.
#' @param update_anchors logical; replace the bank parameters of items that
#'   are already in the bank with the new estimates.
#' @return The pipeline with the bank in `p$bank`. Get it with `p$bank` and
#'   save it with [saveRDS()].
#' @examples
#' \donttest{
#' p <- add_responses(mv_pipeline("Form A"), certexam, items = 3:34,
#'                    key = certexam_key)
#' p <- calibrate(drop_items(p, "Q14"), model = "2PL")
#' p <- bank_items(p, name = "Certification bank")
#' p$bank
#' }
#' @export
bank_items <- function(p, bank = NULL, name = "Item bank", update_anchors = FALSE) {
  check_pipeline(p)
  cl <- match.call()
  if (is.null(p$model)) stop("Calibrate the pipeline with calibrate() first.", call. = FALSE)
  if (is.null(bank)) {
    bank <- mv_bank(p, name = name)
    added <- nrow(bank$items)
    updated <- 0L
  } else {
    if (!inherits(bank, "mv_bank")) stop("`bank` must come from mv_bank().", call. = FALSE)
    if (is.null(p$link))
      warning("The pipeline was not linked to the bank with link_to_bank(); its items may be ",
              "on a different scale.", call. = FALSE)
    rows <- pipeline_bank_rows(p, p$title)
    old <- rows$item %in% bank$items$item
    if (update_anchors && any(old)) {
      bank$items <- bank$items[!bank$items$item %in% rows$item[old], , drop = FALSE]
      new_rows <- rows
    } else new_rows <- rows[!old, , drop = FALSE]
    bank$items <- rbind(bank$items, new_rows)
    added <- sum(!old)
    updated <- if (update_anchors) sum(old) else 0L
    bank$history <- rbind(bank$history, data.frame(
      time = format(Sys.time(), "%Y-%m-%d %H:%M:%S"), action = "add",
      detail = sprintf("%d new items%s from %s", added,
                       if (updated) sprintf(", %d updated", updated) else "", p$title),
      stringsAsFactors = FALSE))
  }
  p$bank <- bank
  p <- stage_rerun(p, "forms")
  p <- log_event(p, "bank items", sprintf("%d items added to %s", added, bank$name))
  p <- set_stage(p, "linking", "done",
                 paste(c(if (!is.null(p$link)) link_summary(p$link),
                         sprintf("%d items added to the bank", added)), collapse = "; "))
  if (p$verbose) message(sprintf("Added %d item(s) to %s (%d items).", added, bank$name,
                                 nrow(bank$items)))
  add_code(p, cl)
}

#' Pipeline stage: link a calibration to an item bank
#'
#' Puts a calibrated pipeline on the scale of an existing item bank through
#' the anchor items the two have in common, then checks the anchors. Methods:
#'
#' * `"stocking-lord"` (default) and `"haebara"`: characteristic-curve
#'   methods. They find the slope `A` and intercept `B` of the change of scale
#'   (theta on the bank scale = `A` x theta + `B`) that make the anchors'
#'   test characteristic curve (Stocking-Lord) or item curves (Haebara) match
#'   the bank's, weighted by a standard normal ability distribution.
#' * `"mean-sigma"` and `"mean-mean"`: moment methods based on the anchors'
#'   locations (and discriminations).
#' * `"fixed"`: fixed-anchor calibration. The model is refitted with the
#'   anchor parameters fixed at their bank values and the ability mean and
#'   variance free, so every new item lands on the bank scale directly.
#'
#' For the Rasch model the slope is fixed at 1. The checks (thresholds from
#' [mv_rules()]):
#'
#' * `too_few_anchors` (review): fewer than `min_anchors` anchor items, or
#'   fewer than `min_anchor_share` of the test.
#' * `anchor_drift` (review): an anchor whose location on the bank scale
#'   differs from its bank value by more than `anchor_displacement`. Drifting
#'   anchors can be left out with the `anchors` argument.
#' * `linking_constants` (review): a slope `A` outside `link_slope_min` to
#'   `link_slope_max`, which suggests a very different ability spread or
#'   unstable anchors.
#' * `not_converged` (block): the fixed-anchor calibration did not converge.
#'
#' The constants and the anchor table are kept in `p$link` and shown in the
#' report.
#'
#' @param p a calibrated pipeline from [calibrate()].
#' @param bank an item bank from [mv_bank()] or [bank_items()].
#' @param method linking method; see above.
#' @param anchors anchor items to use. Defaults to every active bank item
#'   that is also in the pipeline with the same item type.
#' @param ... further arguments passed to [mirt::mirt()] for `"fixed"`.
#' @return The pipeline with `p$link` (a list with `method`, `A`, `B` and
#'   `anchors`, a tibble of the anchors' bank and linked locations and their
#'   displacement) and the linking flags added. With `"fixed"`, `p$model` is
#'   replaced by the fixed-anchor model.
#' @examples
#' \donttest{
#' set.seed(1)
#' a <- matrix(rlnorm(40, 0.2, 0.2)); d <- matrix(rnorm(40))
#' form_x <- simdata(a[1:25, , drop = FALSE], d[1:25, , drop = FALSE], 1500,
#'                   itemtype = "2PL")
#' form_y <- simdata(a[16:40, , drop = FALSE], d[16:40, , drop = FALSE], 1500,
#'                   itemtype = "2PL", Theta = matrix(rnorm(1500, 0.5, 1.2)))
#' colnames(form_x) <- sprintf("I%02d", 1:25)
#' colnames(form_y) <- sprintf("I%02d", 16:40)
#' px <- calibrate(add_responses(mv_pipeline("Form X"), form_x), model = "2PL")
#' bank <- bank_items(px)$bank
#' py <- calibrate(add_responses(mv_pipeline("Form Y"), form_y), model = "2PL")
#' py <- link_to_bank(py, bank)
#' py$link$A; py$link$B
#' py <- bank_items(py, bank)
#' }
#' @export
link_to_bank <- function(p, bank, method = c("stocking-lord", "haebara", "mean-sigma",
                                             "mean-mean", "fixed"),
                         anchors = NULL, ...) {
  check_pipeline(p)
  cl <- match.call()
  method <- match.arg(method)
  if (is.null(p$model)) stop("Calibrate the pipeline with calibrate() first.", call. = FALSE)
  if (inherits(bank, "mv_pipeline")) bank <- bank$bank
  if (!inherits(bank, "mv_bank")) stop("`bank` must come from mv_bank().", call. = FALSE)
  enforce_gate(p, "linking")
  rules <- p$rules
  mod <- p$model
  new <- model_bank_rows(mod, p$title)
  act <- bank$items[bank$items$status == "active", , drop = FALSE]
  common <- intersect(new$item, act$item)
  same_type <- common[new$itemtype[match(common, new$item)] == act$itemtype[match(common, act$item)] &
                        new$ncat[match(common, new$item)] == act$ncat[match(common, act$item)]]
  if (is.null(anchors)) anchors <- same_type else {
    bad <- setdiff(anchors, same_type)
    if (length(bad))
      stop("Not usable as anchors (not in both, or a different item type): ",
           paste(bad, collapse = ", "), call. = FALSE)
  }
  if (length(anchors) < 2L)
    stop("Linking needs at least two anchor items in both the pipeline and the bank.",
         call. = FALSE)
  rasch <- all(new$itemtype[match(anchors, new$item)] == "Rasch")
  np <- new[match(anchors, new$item), , drop = FALSE]
  bp <- act[match(anchors, act$item), , drop = FALSE]

  out <- list()
  add <- function(...) out[[length(out) + 1L]] <<- new_flag("linking", ...)
  if (method == "fixed") {
    mod <- fixed_anchor_fit(mod, bp, ...)
    if (!isTRUE(mirt::extract.mirt(mod, "converged")))
      add("not_converged", "test", "not converged", "estimation must converge", "block",
          "Check the anchors for drift and try again, or use a characteristic-curve method.")
    # drift is judged on the separate calibration, linked by Stocking-Lord
    ab <- link_constants(np, bp, "stocking-lord", rasch)
    gp <- mirt::coef(mod)$GroupPars
    consts <- list(A = sqrt(gp[1, "COV_11"]), B = gp[1, "MEAN_1"])
  } else {
    ab <- link_constants(np, bp, method, rasch)
    consts <- ab
  }
  linked_b <- ab$A * np$b + ab$B
  disp <- linked_b - bp$b
  anchor_tab <- as_tbl(data.frame(item = anchors, bank_b = bp$b, new_b = np$b,
                                  linked_b = linked_b, displacement = disp,
                                  stringsAsFactors = FALSE))

  n_items <- nrow(new)
  if (length(anchors) < rules$min_anchors || length(anchors) / n_items < rules$min_anchor_share)
    add("too_few_anchors", "test",
        sprintf("%d anchors (%.0f%% of %d items)", length(anchors),
                100 * length(anchors) / n_items, n_items),
        sprintf("at least %d anchors and %.0f%% of the test", rules$min_anchors,
                100 * rules$min_anchor_share), "review",
        "Few anchors make the link sensitive to any one item; add anchors in future forms.")
  drift <- abs(disp) > rules$anchor_displacement
  add("anchor_drift", anchors[drift], sprintf("displacement = %+.2f", disp[drift]),
      sprintf("|displacement| > %s", rules$anchor_displacement), "review",
      "The item behaves differently than when it was banked (exposure, a changed context, or a content change); consider linking without it (anchors = ...).")
  if (!rasch && (ab$A < rules$link_slope_min || ab$A > rules$link_slope_max))
    add("linking_constants", "test", sprintf("A = %.2f, B = %.2f", ab$A, ab$B),
        sprintf("A within [%s, %s]", rules$link_slope_min, rules$link_slope_max), "review",
        "A slope this far from 1 means very different score spreads or unstable anchors; check the anchors.")

  if (method == "fixed") {
    p$model <- mod
    p$selection <- NULL
  }
  p$link <- list(method = method, A = consts$A, B = consts$B, anchors = anchor_tab,
                 bank = bank$name)
  p <- set_stage_flags(p, "linking", if (length(out)) do.call(rbind, out) else empty_flags())
  p <- set_stage(p, "linking", "done", link_summary(p$link))
  p <- stage_rerun(p, "forms")
  p <- stage_rerun(p, "reporting")
  p <- log_event(p, "link", link_summary(p$link))
  p <- add_code(p, cl)
  report_stage_flags(p, "linking")
  p
}

link_summary <- function(link) {
  sprintf("linked to %s by %s (A = %.2f, B = %.2f, %d anchors)", link$bank, link$method,
          link$A, link$B, nrow(link$anchors))
}

# Linking constants A and B with theta_bank = A * theta_new + B.
link_constants <- function(np, bp, method, rasch = FALSE) {
  if (method == "mean-mean") {
    A <- if (rasch) 1 else mean(np$a) / mean(bp$a)
    B <- mean(bp$b) - A * mean(np$b)
  } else {
    A <- if (rasch) 1 else stats::sd(bp$b) / stats::sd(np$b)
    B <- mean(bp$b) - A * mean(np$b)
  }
  if (method %in% c("mean-mean", "mean-sigma")) return(list(A = A, B = B))
  theta <- seq(-4, 4, length.out = 41)
  w <- stats::dnorm(theta)
  w <- w / sum(w)
  bank_curves <- lapply(seq_len(nrow(bp)), function(j)
    item_probs(bp$pars[[j]], bp$itemtype[j], theta))
  bank_tcc <- Reduce(`+`, lapply(seq_len(nrow(bp)), function(j)
    item_expected(bp$pars[[j]], bp$itemtype[j], theta)))
  loss <- function(ab) {
    if (ab[1] <= 0) return(1e10)
    tp <- lapply(seq_len(nrow(np)), function(j)
      transform_pars(np$pars[[j]], np$itemtype[j], ab[1], ab[2]))
    if (method == "stocking-lord") {
      tcc <- Reduce(`+`, lapply(seq_len(nrow(np)), function(j)
        item_expected(tp[[j]], np$itemtype[j], theta)))
      sum(w * (bank_tcc - tcc)^2)
    } else {
      sum(vapply(seq_len(nrow(np)), function(j)
        sum(w * (bank_curves[[j]] - item_probs(tp[[j]], np$itemtype[j], theta))^2),
        numeric(1)))
    }
  }
  if (rasch) {
    opt <- stats::optimize(function(b) loss(c(1, b)), c(B - 3, B + 3))
    return(list(A = 1, B = opt$minimum))
  }
  opt <- stats::optim(c(A, B), loss, method = "Nelder-Mead",
                      control = list(reltol = 1e-12, maxit = 2000))
  list(A = opt$par[1], B = opt$par[2])
}

# Refit with the anchors fixed at their bank values and the latent mean and
# variance free.
fixed_anchor_fit <- function(mod, bp, ...) {
  dat <- mirt::extract.mirt(mod, "data")
  types <- mirt::extract.mirt(mod, "itemtype")
  sv <- mirt::mirt(dat, 1, itemtype = types, pars = "values", verbose = FALSE)
  for (j in seq_len(nrow(bp))) {
    par <- bp$pars[[j]]
    for (nm in names(par)) {
      r <- which(sv$item == bp$item[j] & sv$name == nm)
      if (length(r)) {
        sv$value[r] <- par[[nm]]
        sv$est[r] <- FALSE
      }
    }
  }
  gp <- sv$item == "GROUP"
  sv$est[gp & sv$name %in% c("MEAN_1", "COV_11")] <- TRUE
  mirt::mirt(dat, 1, itemtype = types, pars = sv, verbose = FALSE, ...)
}
