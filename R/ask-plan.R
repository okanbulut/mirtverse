#' An analysis plan for mv_ask()
#'
#' A plan lists, in a structured form, what the generated script should do:
#' which columns are items, which model to fit, which group to test for DIF
#' and which outputs to produce. [mv_ask()] fills a plan from a plain-language
#' request, but a plan can also be written by hand and passed to
#' `mv_ask(plan = )`, or changed with [update_plan()].
#'
#' @param items item columns: a character vector of names, a range such as
#'   `"Q1:Q20"`, or `NULL` for all columns that look like items.
#' @param model `"auto"` (compare models with [select_model()]), `"Rasch"`,
#'   `"2PL"`, `"3PL"`, `"graded"` or `"gpcm"`.
#' @param nfact number of latent dimensions (1 to 3).
#' @param group name of a grouping column (e.g. `"gender"`) for a DIF
#'   analysis. Setting it adds the `"dif"` step.
#' @param missing numeric codes that mean "missing", e.g. `c(9, 99)`.
#' @param key answer key for multiple-choice items that are not yet scored.
#' @param rt response-time columns, one per item and in the same order.
#'   Setting it adds the `"rt"` step.
#' @param steps the analysis steps, any of `"describe"`, `"fitcheck"`,
#'   `"dif"`, `"scores"`, `"plots"`, `"interpret"`, `"cards"`, `"report"` and
#'   `"rt"`. A model is always fitted.
#' @param options per-step options as a named list of lists, e.g.
#'   `list(scores = list(method = "MAP", file = "scores.csv"),
#'   report = list(file = "report.html"), fit = list(criterion = "AIC"))`.
#' @param assumptions notes about how the request was understood; they are
#'   printed with the plan and written as comments in the script.
#' @return An object of class `mv_plan`.
#' @examples
#' mv_plan(model = "2PL", group = "gender", steps = c("fitcheck", "report"))
#' @export
mv_plan <- function(items = NULL, model = "auto", nfact = 1, group = NULL, missing = NULL,
                    key = NULL, rt = NULL,
                    steps = c("describe", "fitcheck", "interpret"),
                    options = list(), assumptions = character()) {
  model <- normalise_model(model)
  steps <- unique(match.arg(steps, plan_steps, several.ok = TRUE))
  if (!is.null(group) && !"dif" %in% steps) steps <- c(steps, "dif")
  if (length(rt) && !"rt" %in% steps) steps <- c(steps, "rt")
  nfact <- as.integer(nfact)
  if (length(nfact) != 1L || is.na(nfact) || nfact < 1L || nfact > 3L)
    stop("`nfact` must be 1, 2 or 3.", call. = FALSE)
  if (!is.list(options)) stop("`options` must be a list.", call. = FALSE)
  structure(list(data = NULL, items = items, model = model, nfact = nfact, group = group,
                 missing = if (length(missing)) as.numeric(missing),
                 key = key, rt = rt, steps = plan_steps[plan_steps %in% steps],
                 options = options, assumptions = as.character(assumptions)),
            class = "mv_plan")
}

plan_steps <- c("describe", "fitcheck", "dif", "scores", "plots", "interpret", "cards",
                "report", "rt")
plan_models <- c("auto", "Rasch", "2PL", "3PL", "graded", "gpcm")

normalise_model <- function(model) {
  if (is.null(model) || !length(model)) return("auto")
  m <- tolower(gsub("[^A-Za-z0-9]", "", model[1]))
  out <- switch(m,
    auto = , best = , select = "auto",
    rasch = , `1pl` = , pl1 = "Rasch",
    `2pl` = , pl2 = "2PL",
    `3pl` = , pl3 = "3PL",
    graded = , grm = , gradedresponse = , samejima = "graded",
    gpcm = , generalizedpartialcredit = , pcm = , partialcredit = "gpcm",
    NA_character_)
  if (is.na(out))
    stop(sprintf("Unknown model \"%s\"; use one of %s.", model[1],
                 paste(plan_models, collapse = ", ")), call. = FALSE)
  out
}

#' @rdname mv_plan
#' @param plan an `mv_plan` object.
#' @param ... fields to change, as in `mv_plan()`.
#' @export
update_plan <- function(plan, ...) {
  if (!inherits(plan, "mv_plan")) stop("`plan` must be an mv_plan object.", call. = FALSE)
  args <- list(...)
  bad <- setdiff(names(args), setdiff(names(formals(mv_plan)), "data"))
  if (length(bad)) stop("Unknown plan field(s): ", paste(bad, collapse = ", "), call. = FALSE)
  fields <- unclass(plan)
  fields$data <- NULL
  fields[names(args)] <- args
  fields <- fields[names(fields) %in% names(formals(mv_plan))]
  new <- do.call(mv_plan, fields)
  new$data <- plan$data
  new
}

#' @method print mv_plan
#' @export
print.mv_plan <- function(x, ...) {
  cat("Analysis plan\n")
  for (s in plan_summary(x)) cat("  -", s, "\n")
  if (length(x$assumptions)) {
    cat("Assumptions\n")
    for (s in x$assumptions) cat("  -", s, "\n")
  }
  invisible(x)
}

plan_summary <- function(x) {
  items <- if (is.null(x$items)) "all columns that look like items" else
    if (length(x$items) > 6) sprintf("%d items (%s ... %s)", length(x$items), x$items[1],
                                    x$items[length(x$items)]) else paste(x$items, collapse = ", ")
  c(if (!is.null(x$data)) sprintf("Data: %s", x$data),
    sprintf("Items: %s", items),
    if (length(x$missing)) sprintf("Missing codes: %s", paste(x$missing, collapse = ", ")),
    if (length(x$key)) "Score multiple-choice items with the answer key",
    if (x$model == "auto") sprintf("Model: compare candidate models and keep the best (%d dimension%s)",
                                   x$nfact, if (x$nfact > 1) "s" else "")
    else sprintf("Model: %s, %d dimension%s", model_label(x$model), x$nfact, if (x$nfact > 1) "s" else ""),
    if (!is.null(x$group)) sprintf("DIF by: %s", x$group),
    sprintf("Steps: %s", paste(c("fit", x$steps), collapse = ", ")))
}

# Resolve and check a plan against a data profile. Returns the plan with
# concrete item names plus `errors` (must be fixed) and `notes` (warnings).
check_plan <- function(plan, profile) {
  cols <- profile$column
  errors <- character()
  notes <- character()
  role <- stats::setNames(profile$role, cols)

  items <- plan$items
  if (is.null(items)) {
    items <- cols[role == "item"]
    if (!is.null(plan$group)) items <- setdiff(items, plan$group)
    if (length(items)) plan$assumptions <- c(plan$assumptions, sprintf(
      "Used the %d columns that look like item responses as items.", length(items)))
  } else {
    items <- expand_ranges(items, cols)
  }
  missing_cols <- setdiff(c(items, plan$group, plan$rt), cols)
  if (length(missing_cols))
    errors <- c(errors, sprintf("These columns are not in the data: %s.",
                                paste(missing_cols, collapse = ", ")))
  items <- intersect(items, cols)
  if (length(items) < 3L)
    errors <- c(errors, "At least three item columns are needed.")
  plan$items <- items
  plan$columns <- cols

  if (!is.null(plan$group) && plan$group %in% cols) {
    if (plan$group %in% items)
      errors <- c(errors, sprintf("The group column \"%s\" is also listed as an item.", plan$group))
    k <- profile$n_distinct[cols == plan$group]
    if (k < 2) errors <- c(errors, sprintf("The group column \"%s\" has fewer than two groups.", plan$group))
    if (k > 10) notes <- c(notes, sprintf(
      "The group column \"%s\" has %d distinct values; DIF works best with a few groups.", plan$group, k))
  }

  if (length(items) && all(items %in% cols)) {
    p <- profile[match(items, cols), ]
    if (any(p$type == "text"))
      errors <- c(errors, sprintf("Item columns must be numeric; these are text: %s.",
                                  paste(p$column[p$type == "text"], collapse = ", ")))
    k <- p$n_distinct - vapply(seq_len(nrow(p)), function(i)
      sum(plan$missing >= p$min[i] & plan$missing <= p$max[i]), numeric(1))
    if (length(plan$key)) {
      if (length(plan$key) != length(items))
        errors <- c(errors, sprintf("The answer key has %d entries but there are %d items.",
                                    length(plan$key), length(items)))
      k[] <- 2
    }
    if (any(k < 2))
      errors <- c(errors, sprintf("These items have no variation: %s.",
                                  paste(p$column[k < 2], collapse = ", ")))
    if (plan$model %in% c("Rasch", "2PL", "3PL") && any(k > 2))
      errors <- c(errors, sprintf(
        "The %s model needs items scored 0/1, but %s %s more than two categories. Use model = \"graded\" or \"gpcm\", or give an answer key.",
        plan$model, paste(utils::head(p$column[k > 2], 5), collapse = ", "),
        if (sum(k > 2) > 1) "have" else "has"))
    if (any(p$max - p$min > 10, na.rm = TRUE) && !length(plan$missing))
      notes <- c(notes, "Some items have values far apart (for example 9 or 99); if these are missing-value codes, set them with `missing`.")
  }

  if (length(plan$rt) && length(plan$rt) != length(items))
    errors <- c(errors, sprintf("There are %d response-time columns but %d items; give one per item.",
                                length(plan$rt), length(items)))
  if ("rt" %in% plan$steps && !length(plan$rt))
    errors <- c(errors, "The response-time step needs the response-time columns (`rt`).")
  if ("dif" %in% plan$steps && is.null(plan$group))
    errors <- c(errors, "The DIF step needs a grouping column (`group`).")
  if (plan$nfact > 1 && any(c("plots", "rt") %in% plan$steps))
    notes <- c(notes, "Item plots and response-time models are only drawn for one-dimensional models.")
  n <- attr(profile, "n")
  if (!is.null(n) && n < 200)
    notes <- c(notes, sprintf("Only %d respondents; IRT estimates will be imprecise.", n))

  plan$errors <- errors
  plan$notes <- notes
  plan
}

# Expand "Q1:Q20" style ranges using the column order of the data
expand_ranges <- function(items, cols) {
  unlist(lapply(items, function(s) {
    if (!grepl(":", s, fixed = TRUE) || s %in% cols) return(s)
    ends <- trimws(strsplit(s, ":", fixed = TRUE)[[1]])
    i <- match(ends, cols)
    if (length(ends) != 2L || anyNA(i)) return(s)
    cols[i[1]:i[2]]
  }), use.names = FALSE)
}
