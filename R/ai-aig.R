#' Write an item model for automatic item generation
#'
#' An item model (Gierl & Haladyna, 2013) is a parent item with variable
#' elements: A stem, a key and distractors written as templates, the values
#' each variable can take, and constraints that every generated item must
#' meet. [generate_isomorphs()] fills the templates to produce
#' **isomorphs**: Items that test the same thing in the same way and differ
#' only in their surface. This is the classical, template-based route to
#' automatic item generation (AIG); it is deterministic and every item can
#' be traced to its values. [generate_items()] is the language-model route.
#'
#' Templates mark variable parts with braces. Inside the braces is any R
#' expression of the variables, so `"{l}"` inserts the value of `l` and
#' `"{2 * (l + w)}"` inserts the computed perimeter. Whole numbers are
#' printed without decimals and with a thousands separator, other numbers
#' with up to `digits` decimals. Two helpers can be used in templates:
#' `money(x)` prints `$12.50`, and `fmt(x, d)` prints `x` with exactly `d`
#' decimals.
#'
#' Write each distractor from a **misconception**: The answer a student with
#' a specific misunderstanding would give, such as the area for the
#' perimeter. Write constraints for what the values must satisfy (for
#' example that a result is a whole number), and to keep the distractors
#' different from the key and from each other for every combination of
#' values.
#'
#' @param stem the stem template.
#' @param key the template of the correct answer.
#' @param distractors a character vector of distractor templates, one per
#'   wrong option. Name them to record the misconception behind each.
#' @param values a named list with the values each variable can take.
#' @param constraints optional character vector of R expressions of the
#'   variables, each of which must be `TRUE` for a combination of values to
#'   be used.
#' @param name a short name for the item model, used in item ids.
#' @param digits largest number of decimals printed for computed values.
#' @return An object of class `mv_item_model`. Print it to see the templates
#'   and how many isomorphs it can generate.
#' @references Gierl, M. J., & Haladyna, T. M. (Eds.). (2013). *Automatic
#'   item generation: Theory and practice.* Routledge.
#' @seealso [generate_isomorphs()] to generate items, [calibrate_families()]
#'   to check after field testing that the isomorphs are equally difficult;
#'   the [AI Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.html).
#' @examples
#' perimeter <- item_model(
#'   stem = "A garden is {l} m long and {w} m wide. What is its perimeter?",
#'   key = "{2 * (l + w)} m",
#'   distractors = c(area = "{l * w} m", one_length_one_width = "{l + w} m",
#'                   two_lengths_only = "{2 * l + w} m"),
#'   values = list(l = 5:15, w = 2:9),
#'   constraints = "l > w",
#'   name = "PER")
#' perimeter
#' generate_isomorphs(perimeter, n = 3)
#' @export
item_model <- function(stem, key, distractors, values, constraints = NULL, name = "M",
                       digits = 2) {
  if (!is.character(stem) || length(stem) != 1) stop("`stem` must be one template.", call. = FALSE)
  if (!is.character(key) || length(key) != 1) stop("`key` must be one template.", call. = FALSE)
  if (!is.character(distractors) || !length(distractors))
    stop("`distractors` must be a character vector of templates.", call. = FALSE)
  if (!is.list(values) || is.null(names(values)) || any(!nzchar(names(values))))
    stop("`values` must be a named list.", call. = FALSE)
  used <- unique(c(template_vars(c(stem, key, distractors)),
                   unlist(lapply(constraints, function(cn) all.vars(str2lang(cn))))))
  unknown <- setdiff(used, c(names(values), "money", "fmt", ls(baseenv())))
  if (length(unknown))
    stop(sprintf("The templates use `%s`, which is not in `values`.", unknown[1]), call. = FALSE)
  structure(list(name = name, stem = stem, key = key, distractors = distractors,
                 values = values, constraints = constraints, digits = digits),
            class = "mv_item_model")
}

#' @export
print.mv_item_model <- function(x, ...) {
  cat(sprintf("<mv_item_model> %s\n", x$name))
  cat("  Stem: ", x$stem, "\n", sep = "")
  cat("  Key:  ", x$key, "\n", sep = "")
  dn <- names(x$distractors) %||% rep("", length(x$distractors))
  for (i in seq_along(x$distractors))
    cat(sprintf("  Distractor %d: %s%s\n", i, x$distractors[i],
                if (nzchar(dn[i])) paste0("  (", gsub("_", " ", dn[i]), ")") else ""))
  for (v in names(x$values)) {
    vals <- x$values[[v]]
    cat(sprintf("  %s: %s\n", v, if (length(vals) > 6)
      paste(c(utils::head(vals, 3), "...", utils::tail(vals, 2)), collapse = ", ")
      else paste(vals, collapse = ", ")))
  }
  if (length(x$constraints)) cat("  Constraints:", paste(x$constraints, collapse = "; "), "\n")
  g <- model_grid(x)
  ok <- vapply(seq_len(nrow(g)), function(i) {
    r <- render_isomorph(x, g[i, , drop = FALSE])
    !is.null(r) && !anyDuplicated(c(r$key, r$distractors))
  }, TRUE)
  cat(sprintf("  %d combinations of values meet the constraints; %d give items whose options all differ.\n",
              nrow(g), sum(ok)))
  invisible(x)
}

#' Generate isomorphs from item models
#'
#' Fills the templates of one or more item models ([item_model()]) with
#' combinations of their values that meet the constraints, and returns the
#' generated items with their options in random order. Each item keeps the
#' values it was generated from, which are its features for calibration and
#' for [predict_difficulty()].
#'
#' Combinations that give two identical options, or that cannot be computed,
#' would make flawed items: By default they are left out of the pool that
#' isomorphs are drawn from, with a message, so that the constraints can be
#' fixed. With `drop_flawed = FALSE`, combinations with identical options
#' stay in the pool and their items are marked in the `flag` column.
#'
#' @param model an item model, or a list of item models.
#' @param n number of isomorphs per model; `NULL` generates every
#'   combination of values.
#' @param seed random seed for the choice of values and the order of the
#'   options, or `NULL`.
#' @param shuffle logical; put the options in random order. Otherwise the
#'   key is option A.
#' @param drop_flawed logical; drop items whose options are not all
#'   different.
#' @return A tibble with one row per item: `id`, `model`, `stem`, the
#'   options `A`, `B`, ..., `key` (the letter of the correct option), one
#'   column per variable, and `flag`. It can be passed to [add_items()],
#'   [item_features()] and [review_packet()].
#' @seealso [item_model()], [calibrate_families()].
#' @examples
#' speed <- item_model(
#'   stem = "A car travels {s * t} km in {t} hours. What is its average speed?",
#'   key = "{s} km/h",
#'   distractors = c(multiplied = "{s * t * t} km/h", subtracted = "{s * t - t} km/h",
#'                   distance = "{s * t} km/h"),
#'   values = list(s = seq(40, 90, 10), t = 2:5), name = "SPD")
#' generate_isomorphs(speed, n = 4)
#' @export
generate_isomorphs <- function(model, n = 10, seed = 1, shuffle = TRUE, drop_flawed = TRUE) {
  models <- if (inherits(model, "mv_item_model")) list(model) else model
  if (!length(models) || !all(vapply(models, inherits, TRUE, "mv_item_model")))
    stop("`model` must be an item model from item_model(), or a list of them.", call. = FALSE)
  if (!is.null(seed)) {
    old <- if (exists(".Random.seed", globalenv())) get(".Random.seed", globalenv()) else NULL
    on.exit(if (is.null(old)) rm(".Random.seed", envir = globalenv())
            else assign(".Random.seed", old, envir = globalenv()), add = TRUE)
    set.seed(seed)
  }
  out <- lapply(models, function(m) {
    g <- model_grid(m)
    if (!nrow(g)) stop(sprintf("No combination of values meets the constraints of %s.", m$name),
                       call. = FALSE)
    rendered <- lapply(seq_len(nrow(g)), function(r) render_isomorph(m, g[r, , drop = FALSE]))
    broken <- vapply(rendered, is.null, TRUE)
    flawed <- vapply(rendered, function(it) !is.null(it) && anyDuplicated(c(it$key, it$distractors)) > 0,
                     TRUE)
    bad <- broken | (flawed & drop_flawed)
    if (any(bad))
      message(sprintf("%s: %d of %d combinations of values %s left out. Add a constraint to rule them out.",
                      m$name, sum(bad), nrow(g),
                      if (drop_flawed) "give two identical options or cannot be computed, and were"
                      else "cannot be computed, and were"))
    pool <- which(!bad)
    if (!length(pool)) return(NULL)
    if (!is.null(n) && n > length(pool))
      message(sprintf("%s can only generate %d isomorph%s.", m$name, length(pool),
                      if (length(pool) == 1) "" else "s"))
    rows <- if (is.null(n) || n >= length(pool)) pool else sort(pool[sample.int(length(pool), n)])
    items <- lapply(rows, function(r) {
      it <- rendered[[r]]
      opts <- c(it$key, it$distractors)
      ord <- if (shuffle) sample(length(opts)) else seq_along(opts)
      row <- data.frame(model = m$name, stem = it$stem, stringsAsFactors = FALSE)
      for (k in seq_along(opts)) row[[LETTERS[k]]] <- opts[ord[k]]
      row$key <- LETTERS[which(ord == 1)]
      for (v in names(g)) row[[v]] <- g[[v]][r]
      row$flag <- if (flawed[r]) "two options are the same" else ""
      row
    })
    if (!length(items)) return(NULL)
    d <- bind_rows_fill(items)
    d$id <- sprintf("%s-%02d", m$name, seq_len(nrow(d)))
    d
  })
  out <- bind_rows_fill(Filter(Negate(is.null), out))
  if (is.null(out)) stop("No items could be generated.", call. = FALSE)
  first <- c("id", "model", "stem", intersect(LETTERS, names(out)), "key")
  out <- out[c(first, setdiff(names(out), c(first, "flag")), "flag")]
  rownames(out) <- NULL
  as_tbl(out)
}

# names used in the {expressions} of templates
template_vars <- function(x) {
  ex <- unlist(regmatches(x, gregexpr("\\{[^{}]+\\}", x)))
  ex <- substr(ex, 2, nchar(ex) - 1)
  unique(unlist(lapply(ex, function(e) tryCatch(all.vars(str2lang(e)), error = function(err) character(0)))))
}

model_grid <- function(m) {
  g <- expand.grid(m$values, stringsAsFactors = FALSE, KEEP.OUT.ATTRS = FALSE)
  if (length(m$constraints)) {
    keep <- vapply(seq_len(nrow(g)), function(i) {
      env <- template_env(g[i, , drop = FALSE])
      all(vapply(m$constraints, function(cn) isTRUE(tryCatch(eval(str2lang(cn), env),
                                                             error = function(e) FALSE)), TRUE))
    }, TRUE)
    g <- g[keep, , drop = FALSE]
  }
  rownames(g) <- NULL
  g
}

template_env <- function(row, digits = 2) {
  env <- list2env(as.list(row), parent = baseenv())
  env$money <- function(x) paste0("$", formatC(x, format = "f", digits = 2, big.mark = ","))
  env$fmt <- function(x, d = 0) formatC(x, format = "f", digits = d, big.mark = ",")
  env
}

format_value <- function(x, digits) {
  if (is.character(x)) return(x)
  if (!is.numeric(x) || length(x) != 1 || !is.finite(x)) stop("not a single number")
  if (abs(x - round(x)) < 1e-9) return(format(round(x), big.mark = ",", scientific = FALSE, trim = TRUE))
  sub("\\.?0+$", "", formatC(round(x, digits), format = "f", digits = digits, big.mark = ","))
}

fill_template <- function(tpl, env, digits) {
  m <- gregexpr("\\{[^{}]+\\}", tpl)
  parts <- regmatches(tpl, m)[[1]]
  if (!length(parts)) return(tpl)
  vals <- vapply(parts, function(p) format_value(eval(str2lang(substr(p, 2, nchar(p) - 1)), env),
                                                 digits), "")
  regmatches(tpl, m) <- list(vals)
  tpl
}

render_isomorph <- function(m, row) {
  env <- template_env(row, m$digits)
  tryCatch(list(stem = fill_template(m$stem, env, m$digits),
                key = fill_template(m$key, env, m$digits),
                distractors = vapply(m$distractors, fill_template, "", env = env,
                                     digits = m$digits, USE.NAMES = FALSE)),
           error = function(e) NULL)
}

bind_rows_fill <- function(lst) {
  if (!length(lst)) return(NULL)
  cols <- unique(unlist(lapply(lst, names)))
  do.call(rbind, lapply(lst, function(d) {
    for (cc in setdiff(cols, names(d))) d[[cc]] <- NA
    d[cols]
  }))
}

#' Calibrate item families
#'
#' Summarizes the calibrated difficulties of items generated from the same
#' item model (a family of isomorphs): The family's mean difficulty, how
#' much its items vary around it, and whether the family mean could stand in
#' for field testing a new isomorph.
#'
#' The observed spread of the difficulties in a family includes their
#' estimation error. With `se`, the error variance is subtracted, which
#' leaves the **within-family SD**: How much isomorphs really differ. For a
#' new isomorph, the family mean predicts its difficulty with a typical error
#' of about the within-family SD (plus the uncertainty of the mean). The
#' result also translates that error into the number of test takers a field
#' test would need to estimate the item's difficulty as precisely
#' (`field_test_n`, for a Rasch item and abilities from a standard normal
#' distribution).
#'
#' A family whose within-family SD exceeds `max_sd` is not isomorphic: Some
#' variable in the item model changes what the items demand. Look for it
#' among the values the items were generated from, and split the model or
#' add the variable as a feature (see [predict_difficulty()]).
#'
#' This is the two-step approach. A one-step alternative fits the responses
#' with the family as a fixed effect and a random effect for items, for
#' example with mirt's [mirt::mixedmirt()] (`fixed = ~ 0 + family, random =
#' ~ 1 | items`) or with the eirm package; see the examples in the online
#' book's chapter on automatic item generation.
#'
#' @param items a data frame with one row per calibrated item.
#' @param family name of the column with the item model of each item.
#' @param b name of the column with the difficulties.
#' @param se optional name of the column with the standard errors of `b`.
#' @param max_sd largest within-family SD, in logits, for a family to count
#'   as isomorphic.
#' @return A tibble of class `mv_families` with one row per family:
#'   `family`, `n_items`, `mean_b`, `sd_b` (observed), `sd_within`
#'   (corrected for estimation error when `se` is given), `se_mean`,
#'   `lower` and `upper` (a 95% interval for a new isomorph), `field_test_n`
#'   and `isomorphic`. It has `print()` and `autoplot()` methods.
#' @seealso [item_model()], [generate_isomorphs()], [predict_difficulty()].
#' @examples
#' cal <- calibrate_families(itemtext[itemtext$a > 0, ], family = "family", se = "b_se")
#' cal
#' autoplot(cal)
#' @export
calibrate_families <- function(items, family = "model", b = "b", se = NULL, max_sd = 0.3) {
  items <- as.data.frame(items, stringsAsFactors = FALSE)
  for (nm in c(family, b, se))
    if (!nm %in% names(items)) stop(sprintf("`items` has no column `%s`.", nm), call. = FALSE)
  d <- data.frame(family = as.character(items[[family]]), b = as.numeric(items[[b]]),
                  se = if (is.null(se)) 0 else as.numeric(items[[se]]), stringsAsFactors = FALSE)
  d <- d[!is.na(d$b) & !is.na(d$family), ]
  d$se[is.na(d$se)] <- 0
  fams <- unique(d$family)
  out <- do.call(rbind, lapply(fams, function(f) {
    x <- d[d$family == f, ]
    n <- nrow(x)
    m <- mean(x$b)
    s <- if (n > 1) stats::sd(x$b) else NA_real_
    sw <- if (n > 1) sqrt(max(s^2 - mean(x$se^2), 0)) else NA_real_
    se_m <- if (n > 1) s / sqrt(n) else NA_real_
    half <- 1.96 * sqrt(sw^2 + se_m^2)
    data.frame(family = f, n_items = n, mean_b = m, sd_b = s, sd_within = sw, se_mean = se_m,
               lower = m - half, upper = m + half,
               field_test_n = if (is.na(sw)) NA_real_ else if (sw < 1e-6) Inf
                              else 1 / (sw^2 * rasch_info(m)),
               isomorphic = !is.na(sw) & sw <= max_sd, stringsAsFactors = FALSE)
  }))
  out <- out[order(out$mean_b), ]
  rownames(out) <- NULL
  structure(as_tbl(out), class = c("mv_families", class(as_tbl(out))),
            items = as_tbl(d), max_sd = max_sd, corrected = !is.null(se))
}

# expected Rasch item information at difficulty b for theta ~ N(0, 1)
rasch_info <- function(b) {
  q <- seq(-5, 5, length.out = 101)
  w <- stats::dnorm(q)
  p <- stats::plogis(q - b)
  sum(w * p * (1 - p)) / sum(w)
}

#' @export
print.mv_families <- function(x, digits = 2, ...) {
  cat(sprintf("Item families: %d families, %d items%s\n", nrow(x), sum(x$n_items),
              if (isTRUE(attr(x, "corrected"))) "; SD within corrected for estimation error" else ""))
  d <- as.data.frame(x)
  show <- data.frame(family = d$family, items = d$n_items, mean_b = round(d$mean_b, digits),
                     sd_within = round(d$sd_within, digits),
                     new_item = sprintf("%.*f to %.*f", digits, d$lower, digits, d$upper),
                     field_n = ifelse(is.na(d$field_test_n), NA_character_,
                                      ifelse(d$field_test_n > 5000, ">5,000",
                                             format(round(d$field_test_n), big.mark = ","))),
                     isomorphic = ifelse(d$isomorphic, "yes", "NO"), stringsAsFactors = FALSE)
  names(show)[5] <- "95% for new item"
  print(show, row.names = FALSE)
  cat(sprintf(paste0("field_n: Test takers a field test would need to estimate a new isomorph's b as precisely\n",
                     "as its family mean predicts it. Isomorphic: SD within at most %.2f.\n"), attr(x, "max_sd")))
  invisible(x)
}

#' @rdname calibrate_families
#' @param object a result of `calibrate_families()`.
#' @param ... not used.
#' @export
autoplot.mv_families <- function(object, ...) {
  d <- as.data.frame(object)
  it <- as.data.frame(attr(object, "items"))
  lv <- d$family
  it$family <- factor(it$family, levels = lv)
  d$family <- factor(d$family, levels = lv)
  d$status <- ifelse(d$isomorphic, "Isomorphic", "Not isomorphic")
  ggplot2::ggplot(d, ggplot2::aes(y = family)) +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = lower, xmax = upper, colour = status),
                           width = 0.3, linewidth = 0.8, orientation = "y") +
    ggplot2::geom_point(data = it, ggplot2::aes(x = b), alpha = 0.6, size = 1.8,
                        colour = "grey30") +
    ggplot2::geom_point(ggplot2::aes(x = mean_b, colour = status), shape = 18, size = 4) +
    ggplot2::scale_colour_manual(values = c(Isomorphic = "#2c7fb8", `Not isomorphic` = "#d95f02"),
                                 name = NULL) +
    ggplot2::labs(x = "Difficulty (b)", y = NULL, title = "Item families",
                  subtitle = "Dots: Items. Diamond and bar: Family mean and 95% interval for a new isomorph.") +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "bottom")
}
