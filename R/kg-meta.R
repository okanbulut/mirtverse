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
