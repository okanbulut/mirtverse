#' Check a knowledge graph against response data
#'
#' Looks for places where the data disagree with a knowledge graph. Two
#' kinds of evidence are collected.
#'
#' **Items.** For each item and each concept, the item is correlated with
#' the rest score of the concept: The mean score on the other items linked
#' to that concept. Each correlation is divided by the square root of the
#' rest score's reliability (Spearman-Brown from the mean inter-item
#' correlation), so that concepts with few items are not put at a
#' disadvantage. An item that correlates clearly more with a concept it is
#' not linked to than with any concept it is linked to gets a `wrong_link`
#' flag, with a suggestion to move it (or, for an item linked to several
#' concepts, to add the link). An item linked to several concepts that
#' correlates clearly less with one of them than with its best one gets a
#' `weak_link` flag, with a suggestion to drop that link: Useful for graphs
#' that link too much, such as drafts from [mv_kg_extract()]. A concept that
#' is part of nearly every item, such as a basic operation, can get
#' `weak_link` flags on items that truly need it, so read these with the
#' item in front of you.
#'
#' **Relations.** The graph's correlated confirmatory model is fitted with
#' [mv_kg_irt()] (or taken from `model`), and the factor correlations are
#' turned into partial correlations: The correlation of two concepts once
#' all other concepts are held constant. Concepts that are directly related
#' in the learning process keep a clear partial correlation; concepts
#' related only through others do not. So a large partial correlation
#' between two concepts with no edge is a `missing_relation` flag, and an
#' edge whose partial correlation is near zero is a `weak_relation` flag.
#' The suggested direction of a missing prerequisite runs from the concept
#' whose items are easier to the one whose items are harder; when the two
#' are about equally hard, a `related` edge is suggested instead. A
#' prerequisite whose items are harder than those of the concept it leads
#' to gets an `order` flag.
#'
#' Item links shape the factor correlations, so a wrong link can produce or
#' hide relation flags. Fix item flags first, refit, and only then act on
#' relation flags; [mv_kg_refine()] applies the suggestions you accept.
#'
#' These are screening heuristics, not tests: The thresholds are rules of
#' thumb, and every flag needs a content expert's judgement.
#'
#' @param kg a knowledge graph from [mv_kg_build()] or [as_mv_kg()].
#' @param data a data frame or matrix of item scores (0/1 or ordered
#'   categories). Columns that are not items of the graph, such as an ID,
#'   are skipped.
#' @param model optional fitted model from [mv_kg_irt()] with
#'   `structure = "correlated"`, to save fitting it again.
#' @param min_gap how much larger (in disattenuated correlation) an item's
#'   best unlinked concept must be than its best linked concept before a
#'   `wrong_link` flag, and how much smaller a linked concept must be than
#'   the item's best linked concept before a `weak_link` flag.
#' @param min_partial smallest partial correlation between two concepts
#'   with no edge before a `missing_relation` flag.
#' @param weak_partial partial correlation below which an existing edge
#'   gets a `weak_relation` flag.
#' @param ... passed to [mv_kg_irt()] when the model is fitted here.
#' @return An object of class `mv_kg_fit`: A list with `flags` (a tibble
#'   with columns `check`, `level`, `nodes`, `message`, and the suggested
#'   change in `action`, `from` and `to`), `items` (the item evidence),
#'   `relations` (one row per pair of concepts), `kg`, `model` and
#'   `settings`. Use `tidy()`, `glance()`, [gg_kg_fit()] and
#'   [mv_kg_refine()] on it.
#' @references
#' de la Torre, J., & Chiu, C.-Y. (2016). A general method of empirical
#' Q-matrix validation. *Psychometrika, 81*(2), 253-273.
#'
#' Marsman, M., Borsboom, D., Kruis, J., Epskamp, S., van Bork, R.,
#' Waldorp, L. J., van der Maas, H. L. J., & Maris, G. (2018). An
#' introduction to network psychometrics: Relating Ising network models to
#' item response theory models. *Multivariate Behavioral Research, 53*(1),
#' 15-35.
#' @seealso [mv_kg_check()] for checks that need no data; [mv_kg_refine()];
#'   [gg_kg_fit()].
#' @examples
#' \donttest{
#' # the published fractions graph has two planted errors; this takes
#' # about two minutes because the six-dimensional model is fitted
#' fit <- mv_kg_fit(fractions_kg, fractions)
#' fit
#' gg_kg_fit(fit)
#' }
#' # a quick version on two concepts
#' kg2 <- mv_kg_subset(fractions_kg, c("meaning", "equivalent"))
#' fit2 <- mv_kg_fit(kg2, fractions, TOL = 0.01)
#' tidy(fit2, "items")
#' @export
mv_kg_fit <- function(kg, data, model = NULL, min_gap = 0.1, min_partial = 0.4,
                      weak_partial = 0.1, ...) {
  check_kg(kg)
  q <- mv_kg_qmatrix(kg, data, drop_empty = TRUE)
  X <- as.matrix(as.data.frame(data)[rownames(q)])
  storage.mode(X) <- "double"
  if (ncol(q) < 1) stop("No item of the data is linked to a concept.", call. = FALSE)

  items <- kg_item_evidence(q, X)
  prop <- apply(X, 2, function(x) mean(x, na.rm = TRUE) / max(x, na.rm = TRUE))
  ease <- vapply(colnames(q), function(k) mean(prop[rownames(q)[q[, k] != 0]]), numeric(1))

  rel <- NULL
  if (ncol(q) > 1) {
    if (is.null(model)) {
      sub <- mv_kg_subset(kg, colnames(q), items = rownames(q))
      model <- mv_kg_irt(sub, as.data.frame(X), structure = "correlated", ...)
    }
    R <- mirt::summary(model, verbose = FALSE)$fcor
    R <- R[colnames(q), colnames(q), drop = FALSE]
    P <- tryCatch({
      p <- -stats::cov2cor(solve(R))
      diag(p) <- 1
      p
    }, error = function(e) {
      warning("The factor correlations are singular, so no partial correlations were computed.",
              call. = FALSE)
      R * NA
    })
    rel <- kg_relation_evidence(kg, R, P, ease)
  }
  flags <- kg_fit_flags(items, rel, min_gap, min_partial, weak_partial)
  structure(list(flags = flags, items = as_tbl(items),
                 relations = if (!is.null(rel)) as_tbl(rel),
                 kg = kg, model = model,
                 settings = list(min_gap = min_gap, min_partial = min_partial,
                                 weak_partial = weak_partial, n = nrow(X), ease = ease)),
            class = "mv_kg_fit")
}

# Item-by-concept evidence: Disattenuated correlations with concept rest
# scores.
kg_item_evidence <- function(q, X) {
  C <- suppressWarnings(stats::cor(X, use = "pairwise.complete.obs"))
  sb <- function(its) {
    if (length(its) < 2) return(NA_real_)
    cc <- C[its, its]
    r <- mean(cc[upper.tri(cc)], na.rm = TRUE)
    if (!is.finite(r) || r <= 0) return(NA_real_)
    length(its) * r / (1 + (length(its) - 1) * r)
  }
  cn <- colnames(q)
  out <- lapply(rownames(q), function(i) {
    r <- vapply(cn, function(k) {
      rest <- setdiff(rownames(q)[q[, k] != 0], i)
      rel <- sb(rest)
      if (is.na(rel)) return(NA_real_)
      score <- rowMeans(X[, rest, drop = FALSE], na.rm = TRUE)
      suppressWarnings(stats::cor(X[, i], score, use = "pairwise.complete.obs")) / sqrt(rel)
    }, numeric(1))
    linked <- cn[q[i, ] != 0]
    other <- setdiff(cn, linked)
    rl <- r[linked]; ro <- r[other]
    bl <- if (any(!is.na(rl))) names(rl)[which.max(rl)] else NA_character_
    wl <- if (sum(!is.na(rl)) > 1) names(rl)[which.min(rl)] else NA_character_
    bo <- if (any(!is.na(ro))) names(ro)[which.max(ro)] else NA_character_
    data.frame(item = i, linked = paste(linked, collapse = ", "), n_linked = length(linked),
               best_linked = bl, r_linked = if (is.na(bl)) NA_real_ else unname(r[bl]),
               best_other = bo, r_other = if (is.na(bo)) NA_real_ else unname(r[bo]),
               weakest_linked = wl, r_weakest = if (is.na(wl)) NA_real_ else unname(r[wl]),
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, out)
  out$gap <- out$r_other - out$r_linked
  out <- out[c(setdiff(names(out), c("weakest_linked", "r_weakest")), "weakest_linked", "r_weakest")]
  out
}

# One row per pair of concepts: The edge between them (if any), the factor
# correlation, the partial correlation and how easy each concept's items are.
kg_relation_evidence <- function(kg, R, P, ease) {
  cn <- colnames(R)
  e <- kg$edges[kg$edges$type != "measures", , drop = FALSE]
  pairs <- utils::combn(cn, 2)
  out <- lapply(seq_len(ncol(pairs)), function(j) {
    a <- pairs[1, j]; b <- pairs[2, j]
    hit <- e[(e$from == a & e$to == b) | (e$from == b & e$to == a), , drop = FALSE]
    edge <- if (!nrow(hit)) "none" else if (hit$type[1] == "related") "related" else
      sprintf("%s -> %s", hit$from[1], hit$to[1])
    data.frame(concept_a = a, concept_b = b, edge = edge,
               from = if (nrow(hit)) hit$from[1] else NA_character_,
               to = if (nrow(hit)) hit$to[1] else NA_character_,
               type = if (nrow(hit)) hit$type[1] else NA_character_,
               r = R[a, b], partial = P[a, b], ease_a = unname(ease[a]), ease_b = unname(ease[b]),
               stringsAsFactors = FALSE)
  })
  do.call(rbind, out)
}

kg_fit_flags <- function(items, rel, min_gap, min_partial, weak_partial) {
  out <- list()
  add <- function(check, level, nodes, message, action = "none", from = NA_character_,
                  to = NA_character_)
    out[[length(out) + 1L]] <<- data.frame(
      check = check, level = level, nodes = paste(nodes, collapse = ", "), message = message,
      action = action, from = from, to = to, stringsAsFactors = FALSE)
  for (i in seq_len(nrow(items))) {
    it <- items[i, ]
    if (!is.na(it$gap) && it$gap >= min_gap) {
      if (it$n_linked == 1) {
        add("wrong_link", "review", c(it$item, it$best_other),
            sprintf("%s is linked to %s but agrees more with %s (r = %.2f vs %.2f); move it to %s?",
                    it$item, it$best_linked, it$best_other, it$r_other, it$r_linked, it$best_other),
            "relink", it$item, it$best_other)
      } else {
        add("wrong_link", "review", c(it$item, it$best_other),
            sprintf("%s is linked to %s but agrees more with %s (r = %.2f vs %.2f); add a link to %s?",
                    it$item, it$linked, it$best_other, it$r_other, it$r_linked, it$best_other),
            "add_link", it$item, it$best_other)
      }
    }
    if (it$n_linked > 1 && !is.na(it$r_weakest) && it$r_linked - it$r_weakest >= min_gap)
      add("weak_link", "review", c(it$item, it$weakest_linked),
          sprintf("%s is linked to %s but agrees much less with %s than with %s (r = %.2f vs %.2f); drop the link to %s?",
                  it$item, it$linked, it$weakest_linked, it$best_linked, it$r_weakest,
                  it$r_linked, it$weakest_linked),
          "drop_link", it$item, it$weakest_linked)
  }
  if (!is.null(rel)) {
    for (j in seq_len(nrow(rel))) {
      x <- rel[j, ]
      if (is.na(x$partial)) next
      a <- x$concept_a; b <- x$concept_b
      if (x$edge == "none" && x$partial >= min_partial) {
        diff <- x$ease_a - x$ease_b
        if (abs(diff) < 0.05) {
          add("missing_relation", "review", c(a, b),
              sprintf("%s and %s have no edge but a partial correlation of %.2f, and their items are about equally hard; add a related edge?",
                      a, b, x$partial), "add_related", a, b)
        } else {
          fr <- if (diff > 0) a else b
          to <- if (diff > 0) b else a
          add("missing_relation", "review", c(fr, to),
              sprintf("%s and %s have no edge but a partial correlation of %.2f; %s's items are easier, so add the prerequisite %s -> %s?",
                      fr, to, x$partial, fr, fr, to), "add_prerequisite", fr, to)
        }
      }
      if (x$edge != "none" && x$partial < weak_partial)
        add("weak_relation", "info", c(x$from, x$to),
            sprintf("The edge %s has a partial correlation of only %.2f; the data show little direct link once the other concepts are held constant.",
                    if (x$type == "related") paste(a, "-", b) else x$edge, x$partial))
      if (identical(x$type, "prerequisite")) {
        ef <- if (x$from == a) x$ease_a else x$ease_b
        et <- if (x$from == a) x$ease_b else x$ease_a
        if (ef < et - 0.05)
          add("order", "review", c(x$from, x$to),
              sprintf("%s is listed as a prerequisite of %s, but its items are harder (proportion correct %.2f vs %.2f); is the edge reversed?",
                      x$from, x$to, ef, et))
      }
    }
  }
  res <- if (length(out)) do.call(rbind, out) else
    data.frame(check = character(), level = character(), nodes = character(),
               message = character(), action = character(), from = character(),
               to = character(), stringsAsFactors = FALSE)
  res <- res[order(match(res$level, c("block", "review", "info"))), , drop = FALSE]
  as_tbl(res)
}

#' @export
print.mv_kg_fit <- function(x, ...) {
  g <- glance(x)
  cat(sprintf("<mv_kg_fit> %s: %d concept(s), %d item(s), N = %d\n",
              if (!is.na(x$kg$name)) x$kg$name else "Knowledge graph", g$concepts, g$items, g$n))
  f <- x$flags
  if (!nrow(f)) {
    cat("No flags: The data agree with the graph on the checks run.\n")
    return(invisible(x))
  }
  counts <- table(factor(f$level, c("block", "review", "info")))
  cat(sprintf("%d review, %d info\n", counts[["review"]], counts[["info"]]))
  for (i in seq_len(nrow(f)))
    cat(strwrap(sprintf("[%s] %s: %s", f$level[i], f$check[i], f$message[i]),
                initial = "* ", prefix = "  "), sep = "\n")
  if (any(f$check %in% c("wrong_link", "weak_link")) &&
      any(!f$check %in% c("wrong_link", "weak_link")))
    cat(strwrap(paste("Item links shape the concept correlations: Fix item flags first and",
                      "refit before acting on relation flags.")), sep = "\n")
  invisible(x)
}

#' Tidy and glance methods for knowledge graph checks
#'
#' @param x a result of [mv_kg_fit()].
#' @param what `"flags"` (the default), `"items"` for the evidence on each
#'   item, or `"relations"` for the evidence on each pair of concepts.
#' @param ... unused.
#' @return A tibble.
#' @name tidy_mv_kg_fit
#' @export
tidy.mv_kg_fit <- function(x, what = c("flags", "items", "relations"), ...) {
  what <- match.arg(what)
  x[[what]]
}

#' @rdname tidy_mv_kg_fit
#' @export
glance.mv_kg_fit <- function(x, ...) {
  f <- x$flags
  as_tbl(data.frame(
    concepts = length(x$settings$ease), items = nrow(x$items), n = x$settings$n,
    wrong_link = sum(f$check == "wrong_link"), weak_link = sum(f$check == "weak_link"),
    missing_relation = sum(f$check == "missing_relation"),
    weak_relation = sum(f$check == "weak_relation"), order = sum(f$check == "order"),
    stringsAsFactors = FALSE))
}

#' Apply suggested changes to a knowledge graph
#'
#' Returns a new graph with the changes [mv_kg_fit()] suggested: Items moved
#' to (or also linked to) another concept, weak links dropped, and missing
#' prerequisite or related edges added. Flags without a suggested change, such as
#' `weak_relation` or `order`, are left for you to decide.
#'
#' @param fit a result of [mv_kg_fit()].
#' @param accept which suggestions to apply: `"all"`, `"items"` (only the
#'   item link changes), `"relations"` (only the new edges), or row numbers
#'   of `tidy(fit)`.
#' @return An `mv_kg` object. Its name ends in "(refined)".
#' @examples
#' \donttest{
#' fit <- mv_kg_fit(fractions_kg, fractions)
#' refined <- mv_kg_refine(fit, "items")
#' refined
#' }
#' @export
mv_kg_refine <- function(fit, accept = "all") {
  if (!inherits(fit, "mv_kg_fit")) stop("`fit` must come from mv_kg_fit().", call. = FALSE)
  f <- fit$flags
  rows <- if (is.numeric(accept)) {
    if (any(accept < 1 | accept > nrow(f))) stop("`accept` has row numbers outside the flags.",
                                                 call. = FALSE)
    accept
  } else {
    accept <- match.arg(accept, c("all", "items", "relations"))
    keep <- switch(accept, all = f$action != "none",
                   items = f$action %in% c("relink", "add_link", "drop_link"),
                   relations = f$action %in% c("add_prerequisite", "add_related"))
    which(keep)
  }
  rows <- rows[f$action[rows] != "none"]
  kg <- fit$kg
  e <- as.data.frame(kg$edges, stringsAsFactors = FALSE)
  for (i in rows) {
    a <- f$action[i]; fr <- f$from[i]; to <- f$to[i]
    if (a == "relink") e <- e[!(e$type == "measures" & e$from == fr), , drop = FALSE]
    if (a == "drop_link") {
      if (sum(e$type == "measures" & e$from == fr) > 1)
        e <- e[!(e$type == "measures" & e$from == fr & e$to == to), , drop = FALSE]
      next
    }
    type <- switch(a, relink = , add_link = "measures", add_prerequisite = "prerequisite",
                   add_related = "related")
    e <- rbind(e, data.frame(from = fr, to = to, type = type, weight = 1,
                             stringsAsFactors = FALSE))
  }
  nodes <- as.data.frame(kg$nodes, stringsAsFactors = FALSE)
  cnodes <- nodes[nodes$kind == "concept", , drop = FALSE]
  rel <- e[e$type != "measures", , drop = FALSE]
  meas <- e[e$type == "measures", , drop = FALSE]
  base <- if (!is.na(kg$name)) sub(" \\(refined\\)$", "", kg$name) else "Knowledge graph"
  out <- mv_kg_build(
    concepts = data.frame(concept = cnodes$node, label = cnodes$label,
                          description = cnodes$description, stringsAsFactors = FALSE),
    edges = if (nrow(rel)) rel[c("from", "to", "type", "weight")],
    items = if (nrow(meas)) data.frame(item = meas$from, concept = meas$to, weight = meas$weight,
                                       stringsAsFactors = FALSE),
    name = paste(base, "(refined)"))
  kg_carry_meta(out, kg$meta)
}

#' Draw the data's evidence on a knowledge graph
#'
#' Draws the graph as [gg_kg()] does and marks what [mv_kg_fit()] found:
#' Concepts and items with flags in the accent colour, suggested new edges
#' and item links as dashed accent lines, and the partial correlation of
#' each pair of related concepts next to its edge.
#'
#' @param fit a result of [mv_kg_fit()].
#' @param items `"flagged"` (the default) to draw only the items with flags,
#'   `"all"`, or `"none"`.
#' @param labels `"label"` or `"node"`, as in [gg_kg()].
#' @return A ggplot object.
#' @examples
#' kg2 <- mv_kg_subset(fractions_kg, c("meaning", "equivalent"))
#' gg_kg_fit(mv_kg_fit(kg2, fractions, TOL = 0.01), items = "all")
#' @export
gg_kg_fit <- function(fit, items = c("flagged", "all", "none"), labels = c("label", "node")) {
  if (!inherits(fit, "mv_kg_fit")) stop("`fit` must come from mv_kg_fit().", call. = FALSE)
  items <- match.arg(items)
  labels <- match.arg(labels)
  f <- fit$flags
  kg <- fit$kg
  flagged_items <- unique(f$from[f$action %in% c("relink", "add_link", "drop_link")])
  keep_items <- switch(items, all = fit$items$item, flagged = flagged_items, none = character())
  cn <- kg_concept_names(kg)
  shown <- mv_kg_subset(kg, cn, items = if (length(keep_items)) keep_items else NULL)
  if (!length(keep_items)) shown$nodes <- shown$nodes[shown$nodes$kind == "concept", ]
  if (!length(keep_items))
    shown$edges <- shown$edges[shown$edges$type != "measures", , drop = FALSE]
  shown$name <- kg$name
  hl <- unique(unlist(strsplit(f$nodes[f$level != "info"], ", ")))
  # place nodes as if the suggestions were applied, so new edges run forward
  drops <- f[f$action == "drop_link", , drop = FALSE]
  sug <- f[!f$action %in% c("none", "drop_link"), , drop = FALSE]
  union <- shown
  add <- sug[sug$from %in% shown$nodes$node, , drop = FALSE]
  if (nrow(add)) {
    add$type <- ifelse(add$action %in% c("relink", "add_link"), "measures",
                       ifelse(add$action == "add_related", "related", "prerequisite"))
    union$edges <- rbind(as.data.frame(shown$edges, stringsAsFactors = FALSE),
                         data.frame(from = add$from, to = add$to, type = add$type, weight = 1,
                                    stringsAsFactors = FALSE))
  }
  show_items <- length(keep_items) > 0
  lay <- kg_layout(union, items = show_items)
  drawn <- kg_plot(shown, show_items, labels, highlight = hl, lay = lay, hl_edges = FALSE)
  p <- drawn$plot
  nodes <- drawn$nodes
  pos <- function(n, col) nodes[[col]][match(n, nodes$node)]
  drops <- drops[drops$from %in% nodes$node & drops$to %in% nodes$node, , drop = FALSE]
  if (nrow(drops)) {
    drops$x <- pos(drops$from, "x"); drops$y <- pos(drops$from, "y")
    drops$xend <- pos(drops$to, "x"); drops$yend <- pos(drops$to, "y")
    p <- p + ggplot2::geom_segment(
      data = drops, ggplot2::aes(x = xend, y = yend, xend = x, yend = y),
      colour = mv_colours[["accent"]], linetype = "dotted", linewidth = 0.8)
  }
  sug <- sug[sug$from %in% nodes$node & sug$to %in% nodes$node, , drop = FALSE]
  if (nrow(sug)) {
    sug$x <- pos(sug$from, "x"); sug$y <- pos(sug$from, "y")
    sug$xend <- pos(sug$to, "x"); sug$yend <- pos(sug$to, "y")
    is_item <- sug$action %in% c("relink", "add_link")
    if (any(is_item))
      p <- p + ggplot2::geom_segment(
        data = sug[is_item, , drop = FALSE], ggplot2::aes(x = xend, y = yend, xend = x, yend = y),
        colour = mv_colours[["accent"]], linetype = "dashed", linewidth = 0.6)
    if (any(!is_item)) {
      ed <- sug[!is_item, , drop = FALSE]
      fwd <- ed$xend > ed$x
      ed$x <- ed$x + ifelse(fwd, pos(ed$from, "hw"), 0)
      ed$xend <- ed$xend - ifelse(fwd, pos(ed$to, "hw"), 0)
      p <- p + ggplot2::geom_segment(
        data = ed, ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
        colour = mv_colours[["accent"]], linetype = "dashed", linewidth = 0.7,
        arrow = if (all(ed$action == "add_related")) NULL else
          grid::arrow(length = grid::unit(2.2, "mm"), type = "closed"))
    }
  }
  rel <- fit$relations
  if (!is.null(rel)) {
    lab <- rel[rel$edge != "none" | rel$partial >= fit$settings$min_partial, , drop = FALSE]
    lab <- lab[!is.na(lab$partial), , drop = FALSE]
    if (nrow(lab)) {
      lab$x <- (pos(lab$concept_a, "x") + pos(lab$concept_b, "x")) / 2
      lab$y <- (pos(lab$concept_a, "y") + pos(lab$concept_b, "y")) / 2
      lab$text <- sprintf("%.2f", lab$partial)
      p <- p + ggplot2::geom_label(
        data = lab, ggplot2::aes(x = x, y = y, label = text), size = 2.6,
        colour = ifelse(lab$edge == "none", mv_colours[["accent"]], "grey35"),
        fill = "white", label.size = 0, label.padding = grid::unit(0.12, "lines"))
    }
  }
  p + ggplot2::labs(subtitle = paste0("Numbers: Partial correlations between concepts.\n",
                                      "Dashed accent lines: Links or edges the data suggest adding.\n",
                                      "Dotted lines: Links they suggest dropping."))
}
