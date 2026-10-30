#' Pipeline stage: assemble fixed test forms
#'
#' Builds one or more fixed test forms from the calibrated items with
#' automated test assembly (mixed-integer programming through the eatATA
#' package). The items come from the pipeline's item bank ([bank_items()]) if
#' it has one, otherwise from the calibrated model. Each form has `length`
#' items, meets the content blueprint, keeps enemy items apart, and the forms
#' are made as informative as possible at the `theta` points: with one form
#' the information summed over `theta` is maximized, with several forms the
#' smallest of the forms' sums is maximized, which keeps them parallel.
#'
#' The checks (thresholds from [mv_rules()]):
#'
#' * `no_solution` (block): no set of forms meets every constraint; relax the
#'   blueprint, shorten the forms or allow items on more than one form
#'   (`max_use`).
#' * `blueprint` (block): a form's content counts fall outside the blueprint.
#' * `enemy_items` (block): two enemy items on one form.
#' * `parallel_forms` (review): the forms' test information at a `theta`
#'   point differs by more than `parallel_tol` (relative to the largest).
#' * `form_precision` (review): the standard error of measurement of a form
#'   at a `theta` point is above `cat_sem`.
#' * `not_optimal` (info): the solver found forms that meet every constraint
#'   but ran out of time before proving they are the most informative ones;
#'   a longer `time_limit` may give slightly better forms.
#'
#' @param p a calibrated pipeline from [calibrate()].
#' @param length number of items per form.
#' @param n_forms number of forms.
#' @param theta ability points (on the bank scale) where the forms should be
#'   most informative, such as a cut score.
#' @param content optional content category of each item: a named vector
#'   (names are item names).
#' @param blueprint the number of items per content category on each form:
#'   a named vector of exact counts, or a data frame with columns `category`,
#'   `min` and `max`. Needs `content`.
#' @param enemies optional pairs of items that must not appear on the same
#'   form: a list of character vectors of length two, or a two-column matrix.
#' @param max_use the number of forms an item may appear on (1 means no
#'   overlap between forms).
#' @param solver solver used by eatATA: `"GLPK"` (default) or `"lpSolve"`.
#' @param time_limit time limit for the solver, in seconds.
#' @return The pipeline with `p$forms` (a list with `method = "ata"`,
#'   `items`, a tibble with one row per form and item, and `info`, a tibble
#'   of test information and SEM per form at each `theta`).
#' @examples
#' \donttest{
#' if (requireNamespace("eatATA", quietly = TRUE)) {
#'   p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key)
#'   p <- calibrate(drop_items(p, "Q14"), model = "2PL")
#'   p <- assemble_forms(p, length = 12, n_forms = 2, theta = 0)
#'   p$forms$info
#' }
#' }
#' @export
assemble_forms <- function(p, length, n_forms = 1, theta = c(-1, 0, 1), content = NULL,
                           blueprint = NULL, enemies = NULL, max_use = 1,
                           solver = c("GLPK", "lpSolve"), time_limit = 20) {
  check_pipeline(p)
  cl <- match.call()
  solver <- match.arg(solver)
  need_pkg("eatATA", "automated test assembly")
  pool <- item_pool(p)
  enforce_gate(p, "forms")
  ids <- pool$item
  n <- nrow(pool)
  if (length * n_forms > n * max_use)
    stop(sprintf("The pool has %d items, too few for %d forms of %d items.", n, n_forms, length),
         call. = FALSE)
  info <- pool_info(pool, theta)
  obj <- stats::setNames(rowSums(info), ids)
  cons <- list(
    eatATA::itemsPerFormConstraint(n_forms, n, "=", length, itemIDs = ids),
    eatATA::itemUsageConstraint(n_forms, n, operator = "<=", targetValue = max_use,
                                itemIDs = ids))
  bp <- blueprint_table(blueprint, content, ids)
  short <- if (!is.null(bp)) {
    have <- as.integer(table(factor(content[ids], levels = bp$category)))
    bp$category[have * max_use < bp$min * n_forms]
  }
  if (!is.null(bp) && !length(short)) {
    cats <- factor(content[ids], levels = bp$category)
    cons <- c(cons, list(eatATA::itemCategoryRangeConstraint(
      n_forms, stats::setNames(cats, ids), range = cbind(bp$min, bp$max), itemIDs = ids)))
  }
  pairs <- enemy_pairs(enemies, ids)
  for (k in seq_len(nrow(pairs)))
    cons <- c(cons, list(eatATA::itemValuesConstraint(
      n_forms, stats::setNames(as.numeric(ids %in% pairs[k, ]), ids), operator = "<=",
      targetValue = 1, info_text = paste(pairs[k, ], collapse = "_excludes_"))))
  cons <- c(cons, list(if (n_forms == 1) eatATA::maxObjective(n_forms, obj, itemIDs = ids)
                       else eatATA::maximinObjective(n_forms, obj, allowedDeviation = Inf,
                                                     itemIDs = ids)))
  sol <- NULL
  if (!length(short))
    utils::capture.output(sol <- suppressMessages(tryCatch(
      eatATA::useSolver(cons, solver = solver, timeLimit = time_limit),
      error = function(e) NULL)))

  out <- list()
  add <- function(...) out[[length(out) + 1L]] <<- new_flag("forms", ...)
  forms <- NULL
  res <- ata_solution(sol, length)
  if (!res$ok) {
    add("no_solution", "forms",
        if (length(short)) paste("too few items in", paste(short, collapse = ", "))
        else "no feasible forms",
        "every constraint must be met", "block",
        "Relax the blueprint, shorten the forms, add items to the bank, or allow overlap with max_use.")
  } else {
    im <- res$items
    if (!res$optimal)
      add("not_optimal", "forms", "time limit reached",
          sprintf("solver stopped after %s seconds", time_limit), "info",
          "The forms meet every constraint; raise time_limit to look for more informative ones.")
    forms <- do.call(rbind, lapply(seq_len(n_forms), function(f)
      data.frame(form = f, item = ids[im[, f] > 0.5], stringsAsFactors = FALSE)))
    forms <- as_tbl(forms)
    checks <- form_checks(forms, pool, theta, bp, content, pairs, p$rules)
    out <- c(out, checks$flags)
    p$forms <- list(method = "ata", items = forms, info = checks$info, theta = theta,
                    blueprint = bp, content = content)
  }
  if (is.null(forms)) p$forms <- NULL
  p <- set_stage_flags(p, "forms", bind_flags(out))
  p <- set_stage(p, "forms", "done",
                 if (is.null(forms)) "no feasible forms" else
                   sprintf("%d fixed form%s of %d items (ATA)", n_forms,
                           if (n_forms > 1) "s" else "", length))
  if (!is.null(p$cuts$form)) p <- stage_rerun(p, "cuts")
  p <- stage_rerun(p, "reporting")
  p <- log_event(p, "assemble forms", p$stages$summary[p$stages$stage == "forms"])
  p <- add_code(p, cl)
  report_stage_flags(p, "forms")
  p
}

#' Pipeline stage: simulate a computerized adaptive test
#'
#' Simulates a computerized adaptive test (CAT) from the calibrated items with
#' mirtCAT, to see how precise, how long and how secure the test would be
#' before it goes live. Simulees are drawn from a standard normal ability
#' distribution on the bank scale (or given in `theta`); each takes a CAT
#' that starts with the most informative item, picks items by maximum
#' information (`criteria`), estimates ability by `method`, and stops when the
#' standard error reaches `min_sem` or `max_items` items are given.
#'
#' The checks (thresholds from [mv_rules()]):
#'
#' * `cat_precision` (review): the average final standard error is above
#'   `cat_sem`, or the average bias of the ability estimates is beyond
#'   `cat_bias` in absolute value.
#' * `cat_exposure` (review): an item is given to more than `max_exposure` of
#'   the simulees. Use `randomesque` to spread exposure.
#' * `unused_items` (review): more than `unused_share` of the bank is never
#'   used.
#' * `bank_depth` (info): the bank holds fewer than `bank_depth` times
#'   `max_items` items.
#'
#' @param p a calibrated pipeline from [calibrate()].
#' @param n number of simulees.
#' @param min_sem standard error at which the CAT stops. Defaults to the
#'   `cat_sem` rule.
#' @param max_items,min_items longest and shortest test.
#' @param criteria item selection criterion passed to [mirtCAT::mirtCAT()].
#' @param method ability estimation method passed to [mirtCAT::mirtCAT()].
#' @param randomesque exposure control: choose each item at random from the
#'   `randomesque` most informative ones (1 means none).
#' @param theta optional true abilities of the simulees.
#' @param seed optional random seed.
#' @return The pipeline with `p$forms` (a list with `method = "cat"`,
#'   `persons`, a tibble with each simulee's true and estimated ability,
#'   standard error and test length, `exposure`, a tibble of item exposure
#'   rates, and `summary`).
#' @examples
#' \donttest{
#' if (requireNamespace("mirtCAT", quietly = TRUE)) {
#'   p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key)
#'   p <- calibrate(drop_items(p, "Q14"), model = "2PL")
#'   p <- simulate_cat(p, n = 200, max_items = 15, seed = 1)
#'   p$forms$summary
#' }
#' }
#' @export
simulate_cat <- function(p, n = 1000, min_sem = NULL, max_items = 30, min_items = 5,
                         criteria = "MI", method = "MAP", randomesque = 1, theta = NULL,
                         seed = NULL) {
  check_pipeline(p)
  cl <- match.call()
  need_pkg("mirtCAT", "adaptive test simulation")
  pool <- item_pool(p)
  enforce_gate(p, "forms")
  rules <- p$rules
  if (is.null(min_sem)) min_sem <- rules$cat_sem
  max_items <- min(max_items, nrow(pool))
  if (!is.null(seed)) set.seed(seed)
  if (is.null(theta)) theta <- stats::rnorm(n)
  n <- length(theta)
  mo <- pool_model(pool)
  pattern <- mirtCAT::generate_pattern(mo, Theta = matrix(theta))
  design <- list(min_SEM = min_sem, max_items = max_items, min_items = min_items)
  if (randomesque > 1) design$exposure <- rep(randomesque, nrow(pool))
  res <- NULL
  utils::capture.output(res <- mirtCAT::mirtCAT(mo = mo, local_pattern = pattern, design = design,
                                                criteria = criteria, start_item = criteria,
                                                method = method))
  if (n == 1L) res <- list(res)
  persons <- as_tbl(data.frame(
    true_theta = theta,
    theta = vapply(res, function(r) r$thetas[1], numeric(1)),
    se = vapply(res, function(r) r$SE_thetas[1], numeric(1)),
    n_items = vapply(res, function(r) length(r$items_answered), integer(1))))
  used <- unlist(lapply(res, function(r) r$items_answered))
  exposure <- as_tbl(data.frame(item = pool$item,
                                exposure = tabulate(used, nrow(pool)) / n,
                                stringsAsFactors = FALSE))
  summ <- list(n = n, mean_items = mean(persons$n_items), mean_se = mean(persons$se),
               bias = mean(persons$theta - persons$true_theta),
               rmse = sqrt(mean((persons$theta - persons$true_theta)^2)),
               reached_sem = mean(persons$se <= min_sem), max_exposure = max(exposure$exposure),
               unused = mean(exposure$exposure == 0))

  out <- list()
  add <- function(...) out[[length(out) + 1L]] <<- new_flag("forms", ...)
  if (summ$mean_se > rules$cat_sem || abs(summ$bias) > rules$cat_bias)
    add("cat_precision", "CAT", sprintf("mean SE = %.2f, bias = %+.2f", summ$mean_se, summ$bias),
        sprintf("mean SE <= %s and |bias| <= %s", rules$cat_sem, rules$cat_bias), "review",
        "Allow longer tests (max_items) or add informative items where the bank is thin.")
  over <- exposure$exposure > rules$max_exposure
  add("cat_exposure", exposure$item[over], sprintf("exposure = %.2f", exposure$exposure[over]),
      sprintf("exposure <= %s", rules$max_exposure), "review",
      "Over-exposed items are a security risk; use randomesque > 1 or add similar items.")
  if (summ$unused > rules$unused_share)
    add("unused_items", "bank", sprintf("%.0f%% of items never used", 100 * summ$unused),
        sprintf("at most %.0f%% unused", 100 * rules$unused_share), "review",
        "Unused items cost money to develop; check whether they target abilities nobody has, or spread exposure with randomesque.")
  if (nrow(pool) < rules$bank_depth * max_items)
    add("bank_depth", "bank", sprintf("%d items for a %d-item CAT", nrow(pool), max_items),
        sprintf("at least %d times the test length", rules$bank_depth), "info",
        "A shallow bank leads to high exposure; plan to add items.")

  p$forms <- list(method = "cat", persons = persons, exposure = exposure, summary = summ,
                  design = c(design, list(criteria = criteria, method = method)))
  p <- set_stage_flags(p, "forms", bind_flags(out))
  p <- set_stage(p, "forms", "done",
                 sprintf("CAT simulated: %d simulees, %.1f items on average, mean SE %.2f",
                         n, summ$mean_items, summ$mean_se))
  if (!is.null(p$cuts$form)) p <- stage_rerun(p, "cuts")
  p <- stage_rerun(p, "reporting")
  p <- log_event(p, "simulate CAT", p$stages$summary[p$stages$stage == "forms"])
  p <- add_code(p, cl)
  report_stage_flags(p, "forms")
  p
}

#' Pipeline stage: assemble and simulate a multistage test
#'
#' Builds a two-stage multistage test (MST) from the calibrated items: a
#' routing module of medium difficulty, then `n_modules` second-stage modules
#' targeted at increasing ability levels. Each module is assembled with
#' eatATA to be most informative at its target. Simulees are routed to the
#' second-stage module whose target is closest to their ability estimate after
#' the routing module; their final ability is estimated from both modules.
#'
#' The checks (thresholds from [mv_rules()]):
#'
#' * `no_solution` (block): the modules could not be assembled.
#' * `mst_routing` (review): more than `mst_routing` of the simulees were
#'   routed to a different module than their true ability calls for.
#' * `cat_precision` (review): the average final standard error is above
#'   `cat_sem`, or the average bias is beyond `cat_bias`.
#'
#' @param p a calibrated pipeline from [calibrate()].
#' @param router_length,module_length number of items in the routing module
#'   and in each second-stage module.
#' @param n_modules number of second-stage modules (2 or 3 are typical).
#' @param targets ability targets of the second-stage modules. Defaults to
#'   evenly spaced standard normal quantiles.
#' @param n number of simulees.
#' @param solver,time_limit passed to eatATA's solver.
#' @param seed optional random seed.
#' @return The pipeline with `p$forms` (a list with `method = "mst"`,
#'   `modules`, a tibble of module and item, `targets`, `cuts` (the routing
#'   cut points), `persons` and `summary`).
#' @examples
#' \donttest{
#' if (requireNamespace("eatATA", quietly = TRUE) &&
#'     requireNamespace("mirtCAT", quietly = TRUE)) {
#'   p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key)
#'   p <- calibrate(drop_items(p, "Q14"), model = "2PL")
#'   p <- assemble_mst(p, router_length = 8, module_length = 7, n_modules = 3,
#'                     n = 300, seed = 1)
#'   p$forms$summary
#' }
#' }
#' @export
assemble_mst <- function(p, router_length = 10, module_length = 10, n_modules = 3,
                         targets = NULL, n = 1000, solver = c("GLPK", "lpSolve"),
                         time_limit = 20, seed = NULL) {
  check_pipeline(p)
  cl <- match.call()
  solver <- match.arg(solver)
  need_pkg("eatATA", "multistage test assembly")
  need_pkg("mirtCAT", "multistage test simulation")
  pool <- item_pool(p)
  enforce_gate(p, "forms")
  rules <- p$rules
  if (router_length + n_modules * module_length > nrow(pool))
    stop(sprintf("The pool has %d items, too few for a router of %d and %d modules of %d.",
                 nrow(pool), router_length, n_modules, module_length), call. = FALSE)
  if (is.null(targets))
    targets <- stats::qnorm(seq_len(n_modules) / (n_modules + 1))
  if (length(targets) != n_modules) stop("Give one target per module.", call. = FALSE)
  targets <- sort(targets)

  # assemble the router, then each module from the items still free
  free <- pool$item
  pick <- function(len, at) {
    sub <- pool[pool$item %in% free, , drop = FALSE]
    obj <- stats::setNames(rowSums(pool_info(sub, at)), sub$item)
    cons <- list(eatATA::itemsPerFormConstraint(1, nrow(sub), "=", len, itemIDs = sub$item),
                 eatATA::maxObjective(1, obj, itemIDs = sub$item))
    sol <- NULL
    utils::capture.output(sol <- suppressMessages(
      eatATA::useSolver(cons, solver = solver, timeLimit = time_limit)))
    res <- ata_solution(sol, len)
    if (!res$ok) return(NULL)
    sub$item[res$items[, 1] > 0.5]
  }
  modules <- list(router = pick(router_length, 0))
  free <- setdiff(free, modules$router)
  for (k in seq_len(n_modules)) {
    m <- pick(module_length, targets[k])
    modules[[paste0("module_", k)]] <- m
    free <- setdiff(free, m)
  }

  out <- list()
  add <- function(...) out[[length(out) + 1L]] <<- new_flag("forms", ...)
  if (any(vapply(modules, is.null, logical(1)))) {
    add("no_solution", "MST", "modules could not be assembled", "every constraint must be met",
        "block", "Shorten the modules or add items to the bank.")
    p$forms <- NULL
    p <- set_stage_flags(p, "forms", bind_flags(out))
    p <- set_stage(p, "forms", "done", "no feasible MST")
    return(add_code(p, cl))
  }
  mod_tab <- as_tbl(do.call(rbind, lapply(names(modules), function(m)
    data.frame(module = m, item = modules[[m]], stringsAsFactors = FALSE))))
  cuts <- (targets[-1] + targets[-n_modules]) / 2

  if (!is.null(seed)) set.seed(seed)
  theta <- stats::rnorm(n)
  mo <- pool_model(pool)
  pattern <- mirtCAT::generate_pattern(mo, Theta = matrix(theta))
  colnames(pattern) <- pool$item
  r_items <- match(modules$router, pool$item)
  stage1 <- matrix(NA_real_, n, nrow(pool))
  stage1[, r_items] <- pattern[, r_items]
  est1 <- mirt::fscores(mo, response.pattern = stage1, method = "EAP")[, "F1"]
  route <- findInterval(est1, cuts) + 1L
  ideal <- findInterval(theta, cuts) + 1L
  final <- stage1
  for (k in seq_len(n_modules)) {
    who <- route == k
    cols <- match(modules[[paste0("module_", k)]], pool$item)
    final[who, cols] <- pattern[who, cols]
  }
  est <- mirt::fscores(mo, response.pattern = final, method = "EAP")
  persons <- as_tbl(data.frame(true_theta = theta, theta = est[, "F1"], se = est[, "SE_F1"],
                               route = route, ideal_route = ideal))
  summ <- list(n = n, mean_se = mean(persons$se), bias = mean(persons$theta - theta),
               rmse = sqrt(mean((persons$theta - theta)^2)),
               misrouted = mean(route != ideal),
               routed = as.numeric(table(factor(route, levels = seq_len(n_modules)))) / n)

  if (summ$misrouted > rules$mst_routing)
    add("mst_routing", "MST", sprintf("%.0f%% misrouted", 100 * summ$misrouted),
        sprintf("at most %.0f%% misrouted", 100 * rules$mst_routing), "review",
        "Lengthen the routing module or move the module targets apart.")
  if (summ$mean_se > rules$cat_sem || abs(summ$bias) > rules$cat_bias)
    add("cat_precision", "MST", sprintf("mean SE = %.2f, bias = %+.2f", summ$mean_se, summ$bias),
        sprintf("mean SE <= %s and |bias| <= %s", rules$cat_sem, rules$cat_bias), "review",
        "Lengthen the modules or add informative items.")

  p$forms <- list(method = "mst", modules = mod_tab, targets = targets, cuts = cuts,
                  persons = persons, summary = summ)
  p <- set_stage_flags(p, "forms", bind_flags(out))
  p <- set_stage(p, "forms", "done",
                 sprintf("MST: router of %d items, %d modules of %d; %.0f%% misrouted",
                         router_length, n_modules, module_length, 100 * summ$misrouted))
  if (!is.null(p$cuts$form)) p <- stage_rerun(p, "cuts")
  p <- stage_rerun(p, "reporting")
  p <- log_event(p, "assemble MST", p$stages$summary[p$stages$stage == "forms"])
  p <- add_code(p, cl)
  report_stage_flags(p, "forms")
  p
}

need_pkg <- function(pkg, what) {
  if (!requireNamespace(pkg, quietly = TRUE))
    stop(sprintf("The %s package is needed for %s: install.packages(\"%s\")", pkg, what, pkg),
         call. = FALSE)
}

bind_flags <- function(out) if (length(out)) do.call(rbind, out) else empty_flags()

stage_rerun <- function(p, stage) {
  if (p$stages$status[p$stages$stage == stage] != "not run")
    p <- set_stage(p, stage, "needs rerun", "earlier stages changed since this stage ran")
  p
}

# The items available for forms: the active bank items, or the calibrated
# model's items on the bank scale.
item_pool <- function(p) {
  if (!is.null(p$bank)) return(p$bank$items[p$bank$items$status == "active", , drop = FALSE])
  if (is.null(p$model)) stop("Calibrate the pipeline with calibrate() first.", call. = FALSE)
  pipeline_bank_rows(p, p$title)
}

# Fisher information of each pool item (rows) at each theta (columns):
# the sum over categories of P'(theta)^2 / P(theta), by central differences.
pool_info <- function(pool, theta, h = 1e-4) {
  out <- vapply(seq_len(nrow(pool)), function(j) {
    p0 <- item_probs(pool$pars[[j]], pool$itemtype[j], theta)
    d <- (item_probs(pool$pars[[j]], pool$itemtype[j], theta + h) -
            item_probs(pool$pars[[j]], pool$itemtype[j], theta - h)) / (2 * h)
    rowSums(d^2 / pmax(p0, 1e-12))
  }, numeric(length(theta)))
  out <- t(matrix(out, nrow = length(theta)))
  dimnames(out) <- list(pool$item, paste0("theta_", theta))
  out
}

# A mirt model holding the pool's parameters, for mirtCAT and scoring.
pool_model <- function(pool) {
  nms <- unique(unlist(lapply(pool$pars, names)))
  pars <- as.data.frame(do.call(rbind, lapply(pool$pars, function(x) x[nms])))
  names(pars) <- nms
  pars <- pars[, colSums(!is.na(pars)) > 0, drop = FALSE]
  types <- ifelse(pool$itemtype == "Rasch", "2PL", pool$itemtype)
  mirtCAT::generate.mirt_object(pars, itemtype = types)
}

blueprint_table <- function(blueprint, content, ids) {
  if (is.null(blueprint)) return(NULL)
  if (is.null(content)) stop("`blueprint` needs `content`.", call. = FALSE)
  if (is.null(names(content)) || !all(ids %in% names(content)))
    stop("`content` must be a named vector with a category for every item in the pool.",
         call. = FALSE)
  bp <- if (is.data.frame(blueprint)) blueprint else
    data.frame(category = names(blueprint), min = as.integer(blueprint),
               max = as.integer(blueprint), stringsAsFactors = FALSE)
  if (!all(c("category", "min", "max") %in% names(bp)))
    stop("A blueprint data frame needs columns category, min and max.", call. = FALSE)
  bad <- setdiff(bp$category, content[ids])
  if (length(bad)) stop("Blueprint categories with no items: ", paste(bad, collapse = ", "),
                        call. = FALSE)
  other <- setdiff(unique(content[ids]), bp$category)
  if (length(other))
    bp <- rbind(bp, data.frame(category = other, min = 0L, max = 0L, stringsAsFactors = FALSE))
  bp
}

enemy_pairs <- function(enemies, ids) {
  if (is.null(enemies)) return(matrix(character(0), 0, 2))
  m <- if (is.list(enemies)) do.call(rbind, enemies) else as.matrix(enemies)
  if (ncol(m) != 2L) stop("Give enemies as pairs of item names.", call. = FALSE)
  m[m[, 1] %in% ids & m[, 2] %in% ids, , drop = FALSE]
}

form_checks <- function(forms, pool, theta, bp, content, pairs, rules) {
  out <- list()
  add <- function(...) out[[length(out) + 1L]] <<- new_flag("forms", ...)
  info <- pool_info(pool, theta)
  fids <- sort(unique(forms$form))
  tif <- t(vapply(fids, function(f) colSums(info[forms$item[forms$form == f], , drop = FALSE]),
                  numeric(length(theta))))
  tif <- matrix(tif, nrow = length(fids))
  info_tab <- as_tbl(data.frame(form = rep(fids, each = length(theta)),
                                theta = rep(theta, length(fids)),
                                information = as.vector(t(tif)),
                                sem = 1 / sqrt(as.vector(t(tif)))))
  if (!is.null(bp)) {
    for (f in fids) {
      cnt <- table(factor(content[forms$item[forms$form == f]], levels = bp$category))
      off <- cnt < bp$min | cnt > bp$max
      add("blueprint", sprintf("form %d: %s", f, bp$category[off]),
          sprintf("%d items", as.integer(cnt[off])), "within the blueprint range", "block",
          "Fix the blueprint or the content codes and assemble again.")
    }
  }
  for (k in seq_len(nrow(pairs)))
    for (f in fids)
      if (all(pairs[k, ] %in% forms$item[forms$form == f]))
        add("enemy_items", sprintf("form %d: %s", f, paste(pairs[k, ], collapse = " & ")),
            "both on the form", "enemies on different forms", "block",
            "Assemble again with the enemy pairs given.")
  if (length(fids) > 1L) {
    spread <- apply(tif, 2L, function(v) (max(v) - min(v)) / max(v))
    bad <- spread > rules$parallel_tol
    add("parallel_forms", sprintf("theta = %s", theta[bad]),
        sprintf("information differs by %.0f%%", 100 * spread[bad]),
        sprintf("at most %.0f%% apart", 100 * rules$parallel_tol), "review",
        "Forms are not parallel here; scores will need equating, or add items so the solver has more room.")
  }
  hi <- info_tab$sem > rules$cat_sem
  add("form_precision", sprintf("form %d at theta = %s", info_tab$form[hi], info_tab$theta[hi]),
      sprintf("SEM = %.2f", info_tab$sem[hi]), sprintf("SEM <= %s", rules$cat_sem), "review",
      "The form is imprecise at this ability; lengthen it or add items targeted here.")
  list(flags = out, info = info_tab)
}

# eatATA reports solution_found = FALSE when the time limit stops the solver,
# even if the forms it returns meet every constraint; accept those
ata_solution <- function(sol, len) {
  im <- if (!is.null(sol$item_matrix)) as.matrix(sol$item_matrix)
  ok <- !is.null(im) && ncol(im) > 0 && all(abs(colSums(im) - len) < 0.5) &&
    (isTRUE(sol$solution_found) || grepl("feasible", sol$solution_status %||% "", ignore.case = TRUE)) &&
    !grepl("infeasible|no (primal )?feasible|not feasible", sol$solution_status %||% "", ignore.case = TRUE)
  list(ok = ok, items = im, optimal = isTRUE(sol$solution_found))
}
