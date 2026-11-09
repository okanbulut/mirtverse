#' Q-matrix from a knowledge graph
#'
#' Returns the item-by-concept Q-matrix stored in a knowledge graph: A 1
#' where an item measures a concept, else 0. Weights given to the
#' `measures` edges are kept.
#'
#' @param kg a knowledge graph from [mv_kg_build()] or [as_mv_kg()].
#' @param items optional item names (or a data frame whose column names are
#'   used) to set the order of the rows; columns of a data frame that are
#'   not items of the graph, such as an ID column, are skipped.
#' @param drop_empty logical; drop concepts that no item measures.
#' @return A numeric matrix with one row per item and one column per
#'   concept.
#' @seealso [mv_kg_model()] and [mv_kg_irt()] to fit the matching mirt
#'   model; [mv_kg_hierarchy()] for the mastery patterns the prerequisites
#'   allow.
#' @examples
#' mv_kg_qmatrix(fractions_kg)
#' mv_kg_qmatrix(fraction_subtraction_kg, fraction_subtraction)
#' @export
mv_kg_qmatrix <- function(kg, items = NULL, drop_empty = FALSE) {
  check_kg(kg)
  cn <- kg_concept_names(kg)
  it <- kg_resolve_items(kg, items)
  meas <- kg$edges[kg$edges$type == "measures", , drop = FALSE]
  q <- matrix(0, length(it), length(cn), dimnames = list(it, cn))
  keep <- meas$from %in% it
  q[cbind(meas$from[keep], meas$to[keep])] <- meas$weight[keep]
  if (drop_empty) q <- q[, colSums(q != 0) > 0, drop = FALSE]
  q
}

kg_resolve_items <- function(kg, items = NULL) {
  it <- kg_item_names(kg)
  if (is.null(items)) return(it)
  if (is.data.frame(items) || is.matrix(items)) items <- colnames(items)
  items <- as.character(items)
  out <- items[items %in% it]
  if (!length(out))
    stop("None of the items are in the knowledge graph.", call. = FALSE)
  out
}

#' Write a mirt model from a knowledge graph
#'
#' Turns a knowledge graph into a confirmatory multidimensional model for
#' [mirt::mirt()]: Each concept that items measure becomes a factor, each
#' item loads on the concepts it measures, and the graph decides which
#' factors may correlate.
#'
#' The `structure` sets the factor correlations:
#'
#' * `"correlated"` (the default): All concepts correlate, the usual
#'   confirmatory model.
#' * `"graph"`: Only concepts joined directly by a prerequisite or related
#'   edge correlate; the others are fixed to be uncorrelated. This is a
#'   strict reading of the graph. Concepts on the same learning path
#'   usually correlate even when they are not neighbours, so expect
#'   `anova()` to favour `"correlated"`; the size of the gap shows
#'   how much the indirect links matter.
#' * `"orthogonal"`: No correlations.
#'
#' @param kg a knowledge graph from [mv_kg_build()] or [as_mv_kg()].
#' @param data optional response data; only its items that are in the
#'   graph are used, in the order of the data. Defaults to the items of the
#'   graph.
#' @param structure `"correlated"`, `"graph"` or `"orthogonal"`.
#' @return A [mirt::mirt.model()] object. The `mirt` syntax is in its
#'   `"item_syntax"` attribute, and `print()` shows it.
#' @examples
#' spec <- mv_kg_model(fractions_kg)
#' cat(attr(spec, "item_syntax"))
#' @export
mv_kg_model <- function(kg, data = NULL, structure = c("correlated", "graph", "orthogonal")) {
  check_kg(kg)
  structure <- match.arg(structure)
  q <- mv_kg_qmatrix(kg, data)
  empty <- colnames(q)[colSums(q != 0) == 0]
  if (length(empty))
    message("Concepts with no items are left out of the model: ",
            paste(empty, collapse = ", "), ".")
  q <- q[, colSums(q != 0) > 0, drop = FALSE]
  if (!ncol(q)) stop("No item in the data measures a concept of the graph.", call. = FALSE)
  noload <- rownames(q)[rowSums(q != 0) == 0]
  if (length(noload))
    stop("These items measure no concept, so they cannot be placed in the model: ",
         paste(noload, collapse = ", "), ".", call. = FALSE)
  cn <- colnames(q)
  lines <- vapply(cn, function(k) sprintf("%s = %s", k, paste(rownames(q)[q[, k] != 0],
                                                             collapse = ", ")), character(1))
  pairs <- kg_cov_pairs(kg, cn, structure)
  if (nrow(pairs))
    lines <- c(lines, sprintf("COV = %s", paste(pairs$a, pairs$b, sep = "*", collapse = ", ")))
  syntax <- paste(lines, collapse = "\n")
  mirt::mirt.model(syntax, itemnames = rownames(q), quiet = TRUE)
}

kg_cov_pairs <- function(kg, concepts, structure) {
  empty <- data.frame(a = character(), b = character(), stringsAsFactors = FALSE)
  if (structure == "orthogonal" || length(concepts) < 2) return(empty)
  if (structure == "correlated") {
    cmb <- utils::combn(concepts, 2)
    return(data.frame(a = cmb[1, ], b = cmb[2, ], stringsAsFactors = FALSE))
  }
  rel <- kg$edges[kg$edges$type %in% c("prerequisite", "related") &
                    kg$edges$from %in% concepts & kg$edges$to %in% concepts &
                    kg$edges$from != kg$edges$to, , drop = FALSE]
  if (!nrow(rel)) return(empty)
  ord <- function(x) match(x, concepts)
  a <- ifelse(ord(rel$from) < ord(rel$to), rel$from, rel$to)
  b <- ifelse(ord(rel$from) < ord(rel$to), rel$to, rel$from)
  out <- unique(data.frame(a = a, b = b, stringsAsFactors = FALSE))
  rownames(out) <- NULL
  out
}

#' Fit a confirmatory IRT model built from a knowledge graph
#'
#' Writes the model with [mv_kg_model()] and fits it with [mirt::mirt()].
#' The result is an ordinary mirt model, so [tidy()], [glance()],
#' `anova()`, [mirt::M2()] and the other mirtverse and mirt functions
#' work on it; the graph is kept in its `"mv_kg"` attribute.
#'
#' With more than three concepts the default estimation method is
#' quasi-Monte Carlo EM (`"QMCEM"`), which is much faster than standard EM
#' in many dimensions; set `method` to change it.
#'
#' @inheritParams mv_kg_model
#' @param data response data. Columns that are not items of the graph,
#'   such as an ID column, are dropped.
#' @param itemtype item type passed to [mirt::mirt()], such as `"2PL"` or
#'   `"graded"`.
#' @param method estimation method; defaults to `"EM"` with up to three
#'   concepts and `"QMCEM"` with more.
#' @param ... further arguments passed to [mirt::mirt()].
#' @return A fitted mirt model (class `SingleGroupClass`) with the graph in
#'   attribute `"mv_kg"` and the structure in attribute `"mv_kg_structure"`.
#' @examples
#' \donttest{
#' # about two minutes each: six concepts, 1,200 students
#' published <- mv_kg_irt(fractions_kg, fractions)
#' glance(published)
#' # the strict reading of the graph: Only neighbours correlate
#' strict <- mv_kg_irt(fractions_kg, fractions, structure = "graph")
#' anova(strict, published)
#' # the true graph (lab_truth) fits better than the published one
#' true <- mv_kg_irt(lab_truth("fractions")$graph, fractions)
#' anova(published, true)
#' }
#' # a quick two-concept model
#' kg2 <- mv_kg_build(c("meaning", "equivalent"),
#'                    items = data.frame(item = sprintf("F%02d", 1:8),
#'                                       concept = rep(c("meaning", "equivalent"), each = 4)))
#' mod <- mv_kg_irt(kg2, fractions)
#' tidy(mod)
#' @export
mv_kg_irt <- function(kg, data, structure = c("correlated", "graph", "orthogonal"),
                      itemtype = "2PL", method = NULL, ...) {
  check_kg(kg)
  structure <- match.arg(structure)
  data <- as.data.frame(data)
  it <- kg_resolve_items(kg, data)
  data <- data[it]
  spec <- mv_kg_model(kg, data, structure)
  nfact <- sum(colSums(mv_kg_qmatrix(kg, it) != 0) > 0)
  if (is.null(method)) method <- if (nfact > 3) "QMCEM" else "EM"
  mod <- mirt::mirt(data, spec, itemtype = itemtype, method = method, verbose = FALSE, ...)
  attr(mod, "mv_kg") <- kg
  attr(mod, "mv_kg_structure") <- structure
  mod
}

#' Mastery patterns allowed by the prerequisites
#'
#' Lists the mastery patterns (profiles of mastered and not mastered
#' concepts) that respect the prerequisite edges of a knowledge graph: A
#' concept can be mastered only when all its prerequisites are. This is the
#' attribute hierarchy of Leighton, Gierl and Hunka (2004) and of
#' hierarchical diagnostic classification models (Templin and Bradshaw,
#' 2014). Without prerequisites all 2^K patterns are allowed; each
#' prerequisite edge rules some out, which makes diagnostic models smaller
#' and easier to estimate.
#'
#' The patterns can be passed as `customTheta` to [mirt::mdirt()] to fit a
#' diagnostic model that respects the hierarchy.
#'
#' @param kg a knowledge graph from [mv_kg_build()] or [as_mv_kg()].
#' @param concepts optional concepts to keep (default: All concepts).
#'   Prerequisite paths through left-out concepts are kept, so A before B
#'   before C still makes A a prerequisite of C when B is left out.
#' @return A tibble with one row per allowed pattern and one 0/1 column per
#'   concept, plus `mastered` (the number of concepts mastered). The number
#'   of patterns without the hierarchy (2^K) is in attribute `"possible"`.
#' @references
#' Leighton, J. P., Gierl, M. J., & Hunka, S. M. (2004). The attribute
#' hierarchy method for cognitive assessment: A variation on Tatsuoka's
#' rule-space approach. *Journal of Educational Measurement, 41*, 205-237.
#'
#' Templin, J., & Bradshaw, L. (2014). Hierarchical diagnostic
#' classification models: A family of models for estimating and testing
#' attribute hierarchies. *Psychometrika, 79*, 317-339.
#' @examples
#' pat <- mv_kg_hierarchy(fractions_kg)
#' nrow(pat)
#' attr(pat, "possible")
#' pat
#' @export
mv_kg_hierarchy <- function(kg, concepts = NULL) {
  check_kg(kg)
  if (length(kg_cycle_nodes(kg)))
    stop("The prerequisite edges contain a cycle; see mv_kg_check().", call. = FALSE)
  cn <- kg_concept_names(kg)
  if (!is.null(concepts)) {
    bad <- setdiff(concepts, cn)
    if (length(bad)) stop("Unknown concepts: ", paste(bad, collapse = ", "), ".", call. = FALSE)
    cn <- cn[cn %in% concepts]
  }
  K <- length(cn)
  if (K > 20) stop("Too many concepts (", K, ") to list all patterns; keep 20 or fewer.",
                   call. = FALSE)
  pre <- kg_prereq(kg)
  # prerequisite pairs among the kept concepts, following paths through the rest
  pairs <- do.call(rbind, lapply(cn, function(a) {
    reach <- intersect(kg_reach(pre, a), cn)
    if (length(reach)) data.frame(from = a, to = reach, stringsAsFactors = FALSE) else NULL
  }))
  grid <- as.matrix(expand.grid(rep(list(0:1), K)))
  colnames(grid) <- cn
  ok <- rep(TRUE, nrow(grid))
  if (!is.null(pairs))
    for (i in seq_len(nrow(pairs)))
      ok <- ok & !(grid[, pairs$to[i]] == 1 & grid[, pairs$from[i]] == 0)
  grid <- grid[ok, , drop = FALSE]
  grid <- grid[order(rowSums(grid), -apply(grid, 1, function(r) sum(r * 2^(rev(seq_along(r)) - 1)))), ,
               drop = FALSE]
  out <- as.data.frame(grid)
  out$mastered <- as.integer(rowSums(grid))
  rownames(out) <- NULL
  out <- as_tbl(out)
  attr(out, "possible") <- 2^K
  out
}
