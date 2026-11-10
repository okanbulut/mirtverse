#' Add item metadata to a knowledge graph
#'
#' Attaches a table of item-level information to the items of a knowledge
#' graph: Item text, format, cognitive level, a curriculum standard, word
#' count, response time, whether a person or a language model wrote the
#' item, or anything else known about each item. The metadata travels with
#' the graph: `tidy(kg, "items")` returns it, [gg_kg()] can colour items by
#' it, [mv_kg_explain()] can use it to explain item difficulty next to the
#' concepts, and [mv_kg_extract()] reads item text from it.
#'
#' Calling `mv_kg_annotate()` again adds more columns; a column with the
#' same name as an existing one replaces it. [mv_kg_subset()] and
#' [mv_kg_refine()] keep the metadata of the items they keep.
#'
#' @param kg a knowledge graph from [mv_kg_build()] or [as_mv_kg()].
#' @param meta a data frame with one row per item and an item id column.
#' @param by the name of the item id column in `meta`. By default `item`,
#'   or `id` when there is no `item` column.
#' @return The graph with its metadata in `kg$meta`: A tibble with a column
#'   `item` (every item of the graph, in graph order) and one column per
#'   metadata field. Items without a row in `meta` get `NA`.
#' @seealso [mv_kg_build()], which takes metadata through its `meta`
#'   argument.
#' @examples
#' kg <- mv_kg_annotate(fractions_kg, data.frame(
#'   item = sprintf("F%02d", 1:24),
#'   format = rep(c("multiple choice", "constructed response"), 12)))
#' tidy(kg, "items")
#' gg_kg(kg, colour = "format")
#'
#' # the Tatsuoka items come with their text
#' tidy(fraction_subtraction_kg, "items")
#' @export
mv_kg_annotate <- function(kg, meta, by = NULL) {
  check_kg(kg)
  if (!is.data.frame(meta) && !is.matrix(meta))
    stop("`meta` must be a data frame with one row per item.", call. = FALSE)
  meta <- as.data.frame(meta, stringsAsFactors = FALSE)
  by <- by %||% intersect(c("item", "id"), names(meta))[1]
  if (is.na(by) || !by %in% names(meta))
    stop("`meta` needs an item id column: Name it `item` or `id`, or give its name in `by`.",
         call. = FALSE)
  ids <- as.character(meta[[by]])
  if (anyNA(ids) || anyDuplicated(ids))
    stop("The item ids in `meta` must be unique and not missing.", call. = FALSE)
  fields <- setdiff(names(meta), by)
  if (!length(fields)) stop("`meta` has no columns besides the item id.", call. = FALSE)
  bad <- intersect(fields, c("item", "concepts", "n_concepts"))
  if (length(bad))
    stop("These names are used by the graph and cannot be metadata columns: ",
         paste(bad, collapse = ", "), ".", call. = FALSE)
  items <- kg_item_names(kg)
  known <- ids %in% items
  if (!any(known)) stop("None of the ids in `meta` are items of the graph.", call. = FALSE)
  if (!all(known))
    warning(sprintf("%d row(s) of `meta` name items that are not in the graph and were skipped: %s.",
                    sum(!known), paste(utils::head(ids[!known], 5), collapse = ", ")),
            call. = FALSE)
  add <- meta[known, fields, drop = FALSE]
  pos <- match(items, ids[known])
  out <- if (is.null(kg$meta)) data.frame(item = items, stringsAsFactors = FALSE) else {
    old <- as.data.frame(kg$meta, stringsAsFactors = FALSE)
    old[match(items, old$item), setdiff(names(old), fields), drop = FALSE]
  }
  out$item <- items
  for (f in fields) out[[f]] <- add[[f]][pos]
  rownames(out) <- NULL
  kg$meta <- as_tbl(out[c("item", setdiff(names(out), "item"))])
  kg
}

# Carry metadata over to a rebuilt graph, keeping only its items.
kg_carry_meta <- function(kg, meta) {
  if (is.null(meta) || !NROW(meta) || ncol(meta) < 2) return(kg)
  meta <- as.data.frame(meta, stringsAsFactors = FALSE)
  meta <- meta[meta$item %in% kg_item_names(kg), , drop = FALSE]
  if (!nrow(meta)) return(kg)
  mv_kg_annotate(kg, meta, by = "item")
}

# The item table returned by tidy(kg, "items").
kg_item_table <- function(kg) {
  items <- kg_item_names(kg)
  meas <- kg$edges[kg$edges$type == "measures", , drop = FALSE]
  linked <- lapply(items, function(i) meas$to[meas$from == i])
  out <- data.frame(item = items,
                    concepts = vapply(linked, paste, character(1), collapse = ", "),
                    n_concepts = lengths(linked), stringsAsFactors = FALSE)
  if (!is.null(kg$meta)) {
    m <- as.data.frame(kg$meta, stringsAsFactors = FALSE)
    m <- m[match(items, m$item), setdiff(names(m), "item"), drop = FALSE]
    rownames(m) <- NULL
    out <- cbind(out, m)
  }
  as_tbl(out)
}

kg_meta_fields <- function(kg) if (is.null(kg$meta)) character() else setdiff(names(kg$meta), "item")

# Item covariates for mv_kg_explain(): Numbers are centred, other columns
# become 0/1 indicators for every value but the first.
kg_meta_covariates <- function(kg, fields, items) {
  have <- kg_meta_fields(kg)
  bad <- setdiff(fields, have)
  if (length(bad))
    stop(sprintf("Not item metadata of the graph: %s. %s", paste(bad, collapse = ", "),
                 if (length(have)) paste0("Available: ", paste(have, collapse = ", "), ".") else
                   "Add metadata with mv_kg_annotate()."), call. = FALSE)
  m <- as.data.frame(kg$meta, stringsAsFactors = FALSE)
  m <- m[match(items, m$item), , drop = FALSE]
  cols <- list(); labs <- character()
  for (f in fields) {
    v <- m[[f]]
    if (anyNA(v))
      stop(sprintf("Metadata column `%s` is missing for item(s) %s.", f,
                   paste(utils::head(items[is.na(v)], 5), collapse = ", ")), call. = FALSE)
    if (is.numeric(v)) {
      if (stats::var(v) == 0) stop(sprintf("`%s` has the same value for every item.", f), call. = FALSE)
      cols[[f]] <- v - mean(v)
      labs[f] <- f
    } else {
      v <- if (is.factor(v)) droplevels(v) else factor(as.character(v))
      lv <- levels(v)
      if (length(lv) < 2) stop(sprintf("`%s` has the same value for every item.", f), call. = FALSE)
      for (l in lv[-1]) {
        nm <- paste0(f, "_", l)
        cols[[nm]] <- as.numeric(v == l)
        labs[nm] <- sprintf("%s: %s (vs %s)", f, l, lv[1])
      }
    }
  }
  out <- as.data.frame(cols, check.names = FALSE, stringsAsFactors = FALSE)
  list(data = out, labels = labs)
}

#' Add or drop edges of a knowledge graph by hand
#'
#' Makes the changes a reviewer decides on: Add or drop item links,
#' prerequisite edges or related edges. Use it after [mv_kg_fit()] or
#' [mv_kg_compare()] for the changes that [mv_kg_refine()] does not make
#' on its own, such as dropping a prerequisite edge the data do not
#' support.
#'
#' @param kg a knowledge graph from [mv_kg_build()] or [as_mv_kg()].
#' @param add,drop optional edges: Data frames with columns `from` and `to`
#'   and an optional `type`. An edge from an item is an item link
#'   (`"measures"`); other edges are `"prerequisite"` unless `type` says
#'   `"related"`. Edges are dropped before they are added.
#' @param name optional new name; by default the name is kept.
#' @return An `mv_kg` object, with the item metadata kept. An item whose
#'   last link is dropped leaves the graph, with a warning.
#' @examples
#' # the two changes the data suggest for the published fractions graph
#' kg <- mv_kg_edit(fractions_kg,
#'   add = data.frame(from = c("equivalent", "F14"), to = c("compare", "common_denominator")),
#'   drop = data.frame(from = "F14", to = "compare"))
#' mv_kg_compare(kg, lab_truth("fractions")$graph)
#' @export
mv_kg_edit <- function(kg, add = NULL, drop = NULL, name = NULL) {
  check_kg(kg)
  items <- kg_item_names(kg)
  cn <- kg_concept_names(kg)
  norm <- function(x, arg) {
    if (is.null(x) || !NROW(x)) return(NULL)
    x <- as.data.frame(x, stringsAsFactors = FALSE)
    if (!all(c("from", "to") %in% names(x)))
      stop(sprintf("`%s` needs columns `from` and `to`.", arg), call. = FALSE)
    from <- as.character(x$from); to <- as.character(x$to)
    type <- if ("type" %in% names(x)) as.character(x$type) else rep(NA_character_, nrow(x))
    is_item <- !from %in% cn
    type[is.na(type)] <- ifelse(is_item[is.na(type)], "measures", "prerequisite")
    bad <- setdiff(type, c("measures", "prerequisite", "related"))
    if (length(bad)) stop(sprintf("Unknown edge type in `%s`: %s.", arg, paste(bad, collapse = ", ")),
                          call. = FALSE)
    unknown <- unique(c(to[!to %in% cn], from[type != "measures" & !from %in% cn]))
    if (length(unknown))
      stop(sprintf("`%s` names concepts that are not in the graph: %s.", arg,
                   paste(unknown, collapse = ", ")), call. = FALSE)
    data.frame(from = from, to = to, type = type, stringsAsFactors = FALSE)
  }
  add <- norm(add, "add"); drop <- norm(drop, "drop")
  e <- as.data.frame(kg$edges, stringsAsFactors = FALSE)
  if (!is.null(drop)) {
    for (i in seq_len(nrow(drop))) {
      hit <- e$type == drop$type[i] &
        ((e$from == drop$from[i] & e$to == drop$to[i]) |
           (drop$type[i] == "related" & e$from == drop$to[i] & e$to == drop$from[i]))
      if (!any(hit))
        stop(sprintf("There is no %s edge %s -> %s to drop.", drop$type[i], drop$from[i],
                     drop$to[i]), call. = FALSE)
      e <- e[!hit, , drop = FALSE]
    }
  }
  if (!is.null(add)) {
    key <- paste(e$from, e$to, e$type)
    add <- add[!paste(add$from, add$to, add$type) %in% key, , drop = FALSE]
    e <- rbind(e, data.frame(from = add$from, to = add$to, type = add$type,
                             weight = rep(1, nrow(add)), stringsAsFactors = FALSE))
  }
  meas <- e[e$type == "measures", , drop = FALSE]
  ord <- match(meas$from, unique(c(items, meas$from)))
  meas <- meas[order(ord, match(meas$to, cn)), , drop = FALSE]
  gone <- setdiff(items, meas$from)
  if (length(gone))
    warning(sprintf("%s no longer measure%s any concept and left the graph.",
                    paste(gone, collapse = ", "), if (length(gone) == 1) "s" else ""), call. = FALSE)
  nodes <- as.data.frame(kg$nodes, stringsAsFactors = FALSE)
  cnodes <- nodes[nodes$kind == "concept", , drop = FALSE]
  rel <- e[e$type != "measures", , drop = FALSE]
  out <- mv_kg_build(
    concepts = data.frame(concept = cnodes$node, label = cnodes$label,
                          description = cnodes$description, stringsAsFactors = FALSE),
    edges = if (nrow(rel)) rel[c("from", "to", "type", "weight")],
    items = if (nrow(meas)) data.frame(item = meas$from, concept = meas$to, weight = meas$weight,
                                       stringsAsFactors = FALSE),
    name = name %||% kg$name)
  kg_carry_meta(out, kg$meta)
}
