#' Pipeline stage: field-test design
#'
#' Plans how new items reach test takers before they are calibrated: the
#' number of forms, the anchor items every form shares (so the forms can be
#' put on one scale), and the sample size per form. The unique items are
#' spread over the forms in turn by blueprint cell, so each form covers the
#' blueprint. A simulation then shows how well the item parameters would be
#' recovered under the plan: responses are simulated from plausible item
#' parameters ([mirt::simdata()]), the items a form does not include are set
#' to missing, the model is fitted, and the estimates are compared with the
#' true values.
#'
#' The checks (thresholds from [mv_rules()]):
#'
#' * `sample_size` (review): items answered by fewer than `n_rasch`,
#'   `n_2pl` or `n_3pl` respondents, depending on the model (polytomous
#'   items count as needing `n_3pl`).
#' * `anchor_share` (review): the anchors make up less than
#'   `min_anchor_share` of a form.
#' * `anchor_coverage` (review): a blueprint cell with no anchor item, so
#'   the link between forms does not represent it.
#' * `recovery` (review): the average RMSE of the simulated slopes (or of
#'   the intercepts, for the Rasch model) is above `recovery_rmse`.
#'
#' @param p a pipeline.
#' @param n_forms number of field-test forms.
#' @param n_per_form number of test takers who take each form.
#' @param items the items to field-test: by default the approved items in the
#'   pipeline (or every item not rejected, if none has been reviewed); or a
#'   character vector of item ids; or a number of items, for planning before
#'   items exist.
#' @param anchors optional anchor item ids. By default the fewest items that
#'   make up `min_anchor_share` of a form, taken in turn from each blueprint
#'   cell.
#' @param model the model the items will be calibrated with: `"2PL"`,
#'   `"Rasch"`, `"3PL"` or `"graded"` (polytomous items use the graded model
#'   in any case).
#' @param reps number of simulated field tests (0 skips the simulation).
#' @param seed optional random seed.
#' @return The pipeline with `p$field_test`: `forms` (a tibble with one row
#'   per form and item, and its role), `items` (respondents per item),
#'   `recovery` (average RMSE of slopes and intercepts over the replications)
#'   and the settings.
#' @examples
#' \donttest{
#' p <- design_field_test(mv_pipeline(verbose = FALSE), n_forms = 3, n_per_form = 300,
#'                        items = 60, reps = 2, seed = 1)
#' p$field_test$items
#' flags(p)
#' }
#' @export
design_field_test <- function(p, n_forms, n_per_form, items = NULL, anchors = NULL,
                              model = c("2PL", "Rasch", "3PL", "graded"), reps = 10,
                              seed = NULL) {
  check_pipeline(p)
  cl <- match.call()
  model <- match.arg(model)
  enforce_gate(p, "field_test")
  pool <- field_test_pool(p, items, model)
  n_items <- nrow(pool)
  if (n_forms < 1 || n_per_form < 1) stop("`n_forms` and `n_per_form` must be positive.",
                                          call. = FALSE)
  if (is.null(anchors)) {
    anchors <- if (n_forms > 1) default_anchors(pool, n_forms, p$rules$min_anchor_share) else
      character(0)
  } else {
    bad <- setdiff(anchors, pool$id)
    if (length(bad)) stop("Anchors not among the items: ", paste(bad, collapse = ", "),
                          call. = FALSE)
  }
  uniq <- pool[!pool$id %in% anchors, , drop = FALSE]
  uniq <- uniq[order(uniq$cell, uniq$id), , drop = FALSE]
  form_of <- rep_len(seq_len(n_forms), nrow(uniq))
  forms <- rbind(
    if (length(anchors)) data.frame(form = rep(seq_len(n_forms), each = length(anchors)),
                                    item = rep(anchors, n_forms), role = "anchor"),
    data.frame(form = form_of, item = uniq$id, role = rep("unique", nrow(uniq))))
  forms <- forms[order(forms$form, forms$role, forms$item), , drop = FALSE]
  per_item <- as.data.frame(table(item = forms$item), responseName = "forms",
                            stringsAsFactors = FALSE)
  per_item$n <- per_item$forms * n_per_form
  per_item$role <- ifelse(per_item$item %in% anchors, "anchor", "unique")
  per_item <- per_item[match(pool$id, per_item$item), , drop = FALSE]
  lengths_f <- as.integer(table(forms$form))

  out <- list()
  add <- function(...) out[[length(out) + 1L]] <<- new_flag("field_test", ...)
  r <- p$rules
  need <- ifelse(pool$ncat > 2 | model %in% c("3PL", "graded"), r$n_3pl,
                 if (model == "Rasch") r$n_rasch else r$n_2pl)
  low <- per_item$n < need
  if (any(low)) {
    grp <- split(seq_along(low)[low], per_item$role[low])
    for (g in names(grp))
      add("sample_size", sprintf("%d %s item(s)", length(grp[[g]]), g),
          sprintf("n = %s", paste(unique(per_item$n[grp[[g]]]), collapse = ", ")),
          sprintf("at least %s respondents per item", paste(unique(need[grp[[g]]]), collapse = "/")),
          "review", "Add test takers per form, use fewer forms, or move items to a later field test.")
  }
  if (n_forms > 1) {
    share <- length(anchors) / max(lengths_f)
    if (share < r$min_anchor_share)
      add("anchor_share", "anchors", sprintf("%d anchors, %.0f%% of a form", length(anchors),
                                             100 * share),
          sprintf("at least %.0f%% of a form", 100 * r$min_anchor_share), "review",
          "Add anchor items so the forms can be linked reliably.")
    cells <- if (!is.null(p$blueprint)) p$blueprint$cells$cell else unique(stats::na.omit(pool$cell))
    cells <- intersect(cells, pool$cell)
    missing_cells <- setdiff(cells, pool$cell[pool$id %in% anchors])
    add("anchor_coverage", missing_cells, "no anchor item", "anchors cover every cell", "review",
        "Add an anchor from this cell so the link represents the whole blueprint.")
  }
  recovery <- NULL
  if (reps > 0) {
    if (!is.null(seed)) set.seed(seed)
    recovery <- simulate_recovery(pool, forms, n_forms, n_per_form, model, reps)
    crit <- if (model == "Rasch") recovery$rmse_d else recovery$rmse_a
    if (!is.na(crit) && crit > r$recovery_rmse)
      add("recovery", "design", sprintf("RMSE of %s = %.2f",
                                        if (model == "Rasch") "intercepts" else "slopes", crit),
          sprintf("RMSE <= %s", r$recovery_rmse), "review",
          "Parameters would be estimated imprecisely; increase the sample per form or reduce the number of forms.")
  }

  p$field_test <- list(forms = as_tbl(forms), items = as_tbl(per_item), recovery = recovery,
                       n_forms = n_forms, n_per_form = n_per_form, model = model,
                       anchors = anchors, form_length = lengths_f, reps = reps)
  p <- set_stage_flags(p, "field_test", bind_flags(out))
  p <- set_stage(p, "field_test", "done",
                 sprintf("%d form%s of %s items, %d anchors, %s test takers", n_forms,
                         if (n_forms > 1) "s" else "", paste(unique(lengths_f), collapse = "/"),
                         length(anchors), format(n_forms * n_per_form, big.mark = ",")))
  p <- log_event(p, "design field test", p$stages$summary[p$stages$stage == "field_test"])
  p <- add_code(p, cl)
  report_stage_flags(p, "field_test")
  p
}

field_test_pool <- function(p, items, model) {
  if (is.numeric(items) && length(items) == 1L) {
    n <- as.integer(items)
    return(data.frame(id = sprintf("I%03d", seq_len(n)), cell = NA_character_,
                      ncat = if (model == "graded") 4L else 2L, stringsAsFactors = FALSE))
  }
  it <- p$items
  if (is.null(it)) stop("Give `items` (ids or a number of items), or add items to the pipeline.",
                        call. = FALSE)
  if (is.null(items)) {
    items <- if (any(it$status == "approved")) it$id[it$status == "approved"] else
      it$id[it$status != "rejected"]
  }
  bad <- setdiff(items, it$id)
  if (length(bad)) stop("Items not in the pool: ", paste(bad, collapse = ", "), call. = FALSE)
  it <- it[match(items, it$id), , drop = FALSE]
  if (nrow(it) < 3L) stop("A field test needs at least three items.", call. = FALSE)
  ncat <- ifelse(it$type == "open", pmax(2, it$max_score + 1), 2)
  ncat[is.na(ncat)] <- 3
  data.frame(id = it$id, cell = it$cell, ncat = as.integer(ncat), stringsAsFactors = FALSE)
}

# the fewest anchors that reach `share` of a form, taken in turn from each cell
default_anchors <- function(pool, n_forms, share) {
  n <- nrow(pool)
  a <- 0L
  while (a < n && a < share * (a + ceiling((n - a) / n_forms))) a <- a + 1L
  if (!a) return(character(0))
  cell <- ifelse(is.na(pool$cell), "", pool$cell)
  by_cell <- split(pool$id, factor(cell, levels = unique(cell)))
  out <- character(0)
  k <- 1L
  while (length(out) < a) {
    for (ids in by_cell) if (length(ids) >= k && length(out) < a) out <- c(out, ids[k])
    k <- k + 1L
  }
  out
}

simulate_recovery <- function(pool, forms, n_forms, n_per_form, model, reps) {
  J <- nrow(pool)
  N <- n_forms * n_per_form
  form_of_person <- rep(seq_len(n_forms), each = n_per_form)
  given <- matrix(FALSE, N, J)
  for (f in seq_len(n_forms))
    given[form_of_person == f, match(forms$item[forms$form == f], pool$id)] <- TRUE
  maxk <- max(pool$ncat)
  poly <- pool$ncat > 2
  fit_type <- ifelse(poly, "graded", if (model == "graded") "graded" else model)
  sim_type <- ifelse(poly | fit_type == "graded", "graded", if (model == "3PL") "3PL" else "2PL")
  res <- lapply(seq_len(reps), function(r) {
    a <- if (model == "Rasch") rep(1, J) else stats::rlnorm(J, 0.2, 0.25)
    d <- matrix(NA_real_, J, maxk - 1L)
    for (j in seq_len(J)) {
      k <- pool$ncat[j] - 1L
      d[j, seq_len(k)] <- if (k == 1L) stats::rnorm(1) else sort(stats::rnorm(k, 0, 1.2),
                                                                  decreasing = TRUE)
    }
    g <- ifelse(sim_type == "3PL", stats::runif(J, 0.1, 0.25), 0)
    dat <- mirt::simdata(matrix(a), d, N, itemtype = sim_type, guess = g)
    dat[!given] <- NA
    colnames(dat) <- pool$id
    mod <- tryCatch(mirt::mirt(as.data.frame(dat), 1, itemtype = fit_type, verbose = FALSE,
                               technical = list(NCYCLES = 2000)),
                    error = function(e) NULL)
    if (is.null(mod)) return(c(rmse_a = NA, rmse_d = NA, converged = 0))
    cf <- mirt::coef(mod)
    est <- lapply(pool$id, function(id) cf[[id]][1, ])
    est_a <- vapply(est, function(v) v[["a1"]], numeric(1))
    err_d <- unlist(lapply(seq_len(J), function(j) {
      dd <- est[[j]][grep("^d[0-9]*$", names(est[[j]]))]
      k <- pool$ncat[j] - 1L
      if (length(dd) != k) return(NA_real_)
      dd - d[j, seq_len(k)]
    }))
    c(rmse_a = if (model == "Rasch") NA else sqrt(mean((est_a - a)^2)),
      rmse_d = sqrt(mean(err_d^2, na.rm = TRUE)),
      converged = as.numeric(isTRUE(mirt::extract.mirt(mod, "converged"))))
  })
  m <- do.call(rbind, res)
  as_tbl(data.frame(reps = reps, rmse_a = mean(m[, "rmse_a"], na.rm = TRUE),
                    rmse_d = mean(m[, "rmse_d"], na.rm = TRUE),
                    converged = mean(m[, "converged"])))
}
