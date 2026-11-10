#' Build a knowledge graph of concepts and items
#'
#' A knowledge graph describes what a test measures as a network: Concepts
#' (skills, attributes, learning objectives), the items that measure them,
#' and the relations between concepts. `mv_kg_build()` puts these pieces into
#' one `mv_kg` object that the other `mv_kg_*()` functions and [gg_kg()]
#' read. The graph is stored as two tibbles, one of nodes and one of edges,
#' so no graph package is needed.
#'
#' Three kinds of edges are used:
#'
#' * `prerequisite`: A directed edge between two concepts. `from` must be
#'   learned before `to` (for example, equivalent fractions before adding
#'   fractions with unlike denominators). Prerequisite edges should form a
#'   directed acyclic graph; [mv_kg_check()] flags cycles.
#' * `related`: An undirected link between two concepts that are connected
#'   but where neither comes first.
#' * `measures`: A link from an item to a concept it measures. The items and
#'   their concepts are the rows of a Q-matrix.
#'
#' @param concepts the concepts: A character vector of names, or a data frame
#'   with a column `concept` and optional columns `label` (a longer name for
#'   plots) and `description`.
#' @param edges optional relations between concepts: A data frame with
#'   columns `from` and `to` and an optional column `type` (`"prerequisite"`,
#'   the default, or `"related"`) and `weight`.
#' @param items optional item-to-concept links: Either a data frame in long
#'   form with columns `item` and `concept` (one row per link, optional
#'   `weight`), or a Q-matrix (a matrix or data frame of 0/1 with one row per
#'   item and one column per concept; item names come from the row names or a
#'   column `item`).
#' @param name optional name of the graph, shown when it is printed.
#' @return An object of class `mv_kg`: A list with `nodes` (a tibble with
#'   `node`, `kind` (`"concept"` or `"item"`), `label` and `description`),
#'   `edges` (a tibble with `from`, `to`, `type` and `weight`) and `name`.
#' @seealso [as_mv_kg()] to build a graph from a Q-matrix, an edge list, a
#'   fitted confirmatory mirt model or an igraph object; [mv_kg_check()] and
#'   [gg_kg()]; the [fractions_kg] and [fraction_subtraction_kg] examples.
#' @examples
#' kg <- mv_kg_build(
#'   concepts = c("meaning", "equivalent", "add"),
#'   edges = data.frame(from = c("meaning", "equivalent"),
#'                      to = c("equivalent", "add")),
#'   items = data.frame(item = c("Q1", "Q2", "Q3", "Q4"),
#'                      concept = c("meaning", "equivalent", "add", "add")))
#' kg
#' tidy(kg, "edges")
#' gg_kg(kg)
#' @export
mv_kg_build <- function(concepts, edges = NULL, items = NULL, name = NULL) {
  concepts <- kg_concepts(concepts)
  links <- kg_item_links(items)
  rel <- kg_relations(edges)
  unknown <- setdiff(c(rel$from, rel$to), concepts$node)
  if (length(unknown))
    stop("`edges` names concepts that are not in `concepts`: ",
         paste(unique(unknown), collapse = ", "), ".", call. = FALSE)
  unknown <- setdiff(links$concept, concepts$node)
  if (length(unknown))
    stop("`items` links to concepts that are not in `concepts`: ",
         paste(unique(unknown), collapse = ", "), ".", call. = FALSE)
  item_ids <- unique(links$item)
  clash <- intersect(item_ids, concepts$node)
  if (length(clash))
    stop("Items and concepts need different names; both use: ",
         paste(clash, collapse = ", "), ".", call. = FALSE)
  nodes <- rbind(
    concepts,
    data.frame(node = item_ids, kind = rep("item", length(item_ids)), label = item_ids,
               description = rep(NA_character_, length(item_ids)), stringsAsFactors = FALSE))
  measures <- data.frame(from = links$item, to = links$concept,
                         type = rep("measures", nrow(links)), weight = links$weight,
                         stringsAsFactors = FALSE)
  all_edges <- rbind(rel, measures)
  structure(list(nodes = as_tbl(nodes), edges = as_tbl(all_edges),
                 name = if (is.null(name)) NA_character_ else as.character(name)),
            class = "mv_kg")
}

kg_concepts <- function(concepts) {
  if (is.factor(concepts)) concepts <- as.character(concepts)
  if (is.character(concepts)) concepts <- data.frame(concept = concepts, stringsAsFactors = FALSE)
  concepts <- as.data.frame(concepts, stringsAsFactors = FALSE)
  if (!"concept" %in% names(concepts))
    stop("`concepts` needs a column `concept` (or give a character vector).", call. = FALSE)
  node <- as.character(concepts$concept)
  if (anyNA(node) || any(!nzchar(node))) stop("Concept names cannot be empty.", call. = FALSE)
  if (anyDuplicated(node))
    stop("Concept names must be unique; repeated: ",
         paste(unique(node[duplicated(node)]), collapse = ", "), ".", call. = FALSE)
  label <- if ("label" %in% names(concepts)) as.character(concepts$label) else node
  label[is.na(label) | !nzchar(label)] <- node[is.na(label) | !nzchar(label)]
  desc <- if ("description" %in% names(concepts)) as.character(concepts$description) else
    rep(NA_character_, length(node))
  data.frame(node = node, kind = rep("concept", length(node)), label = label,
             description = desc, stringsAsFactors = FALSE)
}

kg_relations <- function(edges) {
  empty <- data.frame(from = character(), to = character(), type = character(),
                      weight = numeric(), stringsAsFactors = FALSE)
  if (is.null(edges) || NROW(edges) == 0) return(empty)
  edges <- as.data.frame(edges, stringsAsFactors = FALSE)
  if (!all(c("from", "to") %in% names(edges)))
    stop("`edges` needs columns `from` and `to`.", call. = FALSE)
  type <- if ("type" %in% names(edges)) as.character(edges$type) else rep("prerequisite", nrow(edges))
  type[is.na(type)] <- "prerequisite"
  bad <- setdiff(type, c("prerequisite", "related"))
  if (length(bad))
    stop("Edge `type` must be \"prerequisite\" or \"related\" (items are linked with ",
         "`items`); found: ", paste(unique(bad), collapse = ", "), ".", call. = FALSE)
  weight <- if ("weight" %in% names(edges)) as.numeric(edges$weight) else rep(1, nrow(edges))
  data.frame(from = as.character(edges$from), to = as.character(edges$to), type = type,
             weight = weight, stringsAsFactors = FALSE)
}

kg_item_links <- function(items) {
  empty <- data.frame(item = character(), concept = character(), weight = numeric(),
                      stringsAsFactors = FALSE)
  if (is.null(items) || NROW(items) == 0) return(empty)
  if (is.data.frame(items) && all(c("item", "concept") %in% names(items))) {
    w <- if ("weight" %in% names(items)) as.numeric(items$weight) else rep(1, nrow(items))
    out <- data.frame(item = as.character(items$item), concept = as.character(items$concept),
                      weight = w, stringsAsFactors = FALSE)
    return(out[!duplicated(out[c("item", "concept")]), , drop = FALSE])
  }
  q <- kg_qmatrix_input(items)
  idx <- which(q != 0, arr.ind = TRUE)
  idx <- idx[order(idx[, 1], idx[, 2]), , drop = FALSE]
  if (!nrow(idx)) return(empty)
  data.frame(item = rownames(q)[idx[, 1]], concept = colnames(q)[idx[, 2]],
             weight = as.numeric(q[idx]), stringsAsFactors = FALSE)
}

# A Q-matrix given as a matrix or a data frame, with item names as row names
# or in a column `item`.
kg_qmatrix_input <- function(q) {
  if (is.data.frame(q)) {
    if ("item" %in% names(q)) {
      rn <- as.character(q$item)
      q <- q[setdiff(names(q), "item")]
    } else {
      rn <- rownames(q)
    }
    q <- as.matrix(q)
    rownames(q) <- rn
  }
  if (!is.matrix(q) || !is.numeric(q))
    stop("`items` must be a data frame with columns `item` and `concept`, or a numeric ",
         "Q-matrix with one row per item and one column per concept.", call. = FALSE)
  if (is.null(colnames(q))) stop("The Q-matrix needs column names (the concepts).", call. = FALSE)
  if (is.null(rownames(q)) || all(rownames(q) == as.character(seq_len(nrow(q)))))
    rownames(q) <- sprintf("I%02d", seq_len(nrow(q)))
  if (anyNA(q)) stop("The Q-matrix cannot contain missing values.", call. = FALSE)
  q
}

#' Turn other objects into a knowledge graph
#'
#' `as_mv_kg()` builds an [mv_kg][mv_kg_build] object from objects you may
#' already have:
#'
#' * A Q-matrix (a 0/1 matrix or data frame, one row per item and one column
#'   per concept): Concepts and `measures` edges, with no relations between
#'   concepts.
#' * An edge list (a data frame with `from`, `to` and `type`): Rows with type
#'   `"measures"` become item links, the others concept relations.
#' * A fitted confirmatory model from [mirt::mirt()]: Each factor becomes a
#'   concept and each non-zero slope a `measures` edge, so a graph can be
#'   drawn from a model you have already fitted.
#' * An igraph object: Vertices with a `kind` attribute of `"item"` become
#'   items, the others concepts; edge `type` attributes are kept.
#'
#' @param x the object to convert.
#' @param ... passed on to [mv_kg_build()] (for example `name`), or for a
#'   Q-matrix, `edges` with relations between its concepts.
#' @return An `mv_kg` object.
#' @examples
#' q <- matrix(c(1, 0,
#'               1, 0,
#'               0, 1,
#'               1, 1), ncol = 2, byrow = TRUE,
#'             dimnames = list(paste0("Q", 1:4), c("number", "algebra")))
#' as_mv_kg(q, edges = data.frame(from = "number", to = "algebra"))
#' @export
as_mv_kg <- function(x, ...) UseMethod("as_mv_kg")

#' @rdname as_mv_kg
#' @export
as_mv_kg.mv_kg <- function(x, ...) x

#' @rdname as_mv_kg
#' @export
as_mv_kg.matrix <- function(x, ...) {
  q <- kg_qmatrix_input(x)
  mv_kg_build(concepts = colnames(q), items = q, ...)
}

#' @rdname as_mv_kg
#' @export
as_mv_kg.data.frame <- function(x, ...) {
  if (all(c("from", "to") %in% names(x))) {
    type <- if ("type" %in% names(x)) as.character(x$type) else rep("prerequisite", nrow(x))
    is_item <- type == "measures"
    rel <- x[!is_item, , drop = FALSE]
    links <- x[is_item, , drop = FALSE]
    item_links <- if (nrow(links))
      data.frame(item = as.character(links$from), concept = as.character(links$to),
                 weight = if ("weight" %in% names(links)) links$weight else 1,
                 stringsAsFactors = FALSE) else NULL
    concepts <- unique(c(as.character(rel$from), as.character(rel$to),
                         if (nrow(links)) as.character(links$to)))
    return(mv_kg_build(concepts = concepts, edges = if (nrow(rel)) rel else NULL,
                       items = item_links, ...))
  }
  as_mv_kg.matrix(kg_qmatrix_input(x), ...)
}

#' @rdname as_mv_kg
#' @export
as_mv_kg.SingleGroupClass <- function(x, ...) {
  cf <- mirt::coef(x, simplify = TRUE)$items
  slopes <- cf[, grepl("^a[0-9]+$", colnames(cf)), drop = FALSE]
  factors <- mirt::extract.mirt(x, "factorNames")
  colnames(slopes) <- factors[seq_len(ncol(slopes))]
  q <- (abs(slopes) > 0) * 1
  rownames(q) <- rownames(cf)
  mv_kg_build(concepts = colnames(q), items = q, ...)
}

#' @rdname as_mv_kg
#' @export
as_mv_kg.igraph <- function(x, ...) {
  rlang_check("igraph", "to convert an igraph object")
  v <- igraph::as_data_frame(x, what = "vertices")
  e <- igraph::as_data_frame(x, what = "edges")
  if (!"name" %in% names(v)) stop("The igraph object needs vertex names.", call. = FALSE)
  kind <- if ("kind" %in% names(v)) as.character(v$kind) else rep("concept", nrow(v))
  concepts <- v[kind != "item", , drop = FALSE]
  concepts$concept <- concepts$name
  type <- if ("type" %in% names(e)) as.character(e$type) else rep("prerequisite", nrow(e))
  item_names <- v$name[kind == "item"]
  from_item <- e$from %in% item_names
  type[from_item] <- "measures"
  e$type <- type
  rel <- e[type != "measures", c("from", "to", "type", intersect("weight", names(e))), drop = FALSE]
  links <- e[type == "measures", , drop = FALSE]
  mv_kg_build(concepts = concepts[intersect(c("concept", "label", "description"), names(concepts))],
              edges = if (nrow(rel)) rel else NULL,
              items = if (nrow(links)) data.frame(item = links$from, concept = links$to,
                                                  stringsAsFactors = FALSE) else NULL, ...)
}

rlang_check <- function(pkg, what) {
  if (!requireNamespace(pkg, quietly = TRUE))
    stop(sprintf("The %s package is needed %s; install it with install.packages(\"%s\").",
                 pkg, what, pkg), call. = FALSE)
}

check_kg <- function(kg) {
  if (!inherits(kg, "mv_kg"))
    stop("Expected a knowledge graph from mv_kg_build() or as_mv_kg().", call. = FALSE)
}

kg_concept_names <- function(kg) kg$nodes$node[kg$nodes$kind == "concept"]
kg_item_names <- function(kg) kg$nodes$node[kg$nodes$kind == "item"]
kg_prereq <- function(kg) kg$edges[kg$edges$type == "prerequisite", , drop = FALSE]

# Longest-path depth of each concept in the prerequisite graph (roots are 0).
# Concepts on a cycle get NA.
kg_depth <- function(kg) {
  cn <- kg_concept_names(kg)
  pre <- kg_prereq(kg)
  pre <- pre[pre$from != pre$to, , drop = FALSE]
  depth <- stats::setNames(rep(NA_real_, length(cn)), cn)
  indeg <- stats::setNames(vapply(cn, function(n) sum(pre$to == n), numeric(1)), cn)
  queue <- cn[indeg == 0]
  depth[queue] <- 0
  while (length(queue)) {
    n <- queue[1]; queue <- queue[-1]
    for (m in pre$to[pre$from == n]) {
      depth[m] <- max(depth[m], depth[n] + 1, na.rm = TRUE)
      indeg[m] <- indeg[m] - 1
      if (indeg[m] == 0) queue <- c(queue, m)
    }
  }
  depth[indeg > 0] <- NA_real_
  depth
}

# Concepts that sit on a prerequisite cycle (including self loops).
kg_cycle_nodes <- function(kg) {
  d <- kg_depth(kg)
  pre <- kg_prereq(kg)
  unique(c(names(d)[is.na(d)], pre$from[pre$from == pre$to]))
}

# Concepts reachable from `node` along prerequisite edges (its descendants).
kg_reach <- function(pre, node) {
  seen <- character()
  frontier <- node
  while (length(frontier)) {
    nxt <- setdiff(pre$to[pre$from %in% frontier], seen)
    seen <- c(seen, nxt)
    frontier <- nxt
  }
  seen
}

#' Check a knowledge graph for problems
#'
#' Runs structural checks on a knowledge graph before it is used to build a
#' model. The flags use the same three levels as the
#' [assessment pipeline][mv_pipeline]: `block` (the graph cannot be used as
#' it is), `review` (a psychometrician should look) and `info`.
#'
#' The checks:
#'
#' * `cycle` (block): Prerequisite edges form a cycle, so no learning order
#'   exists.
#' * `self_loop` (block): A concept is listed as its own prerequisite.
#' * `few_items` (review): A concept is measured by fewer than `min_items`
#'   items, too few to estimate it as its own dimension.
#' * `unmeasured` (review): A concept is measured by no item. This is fine
#'   for a concept that only organizes the graph, but it cannot be scored.
#' * `same_items` (review): Two concepts are measured by exactly the same
#'   items, so the data cannot tell them apart.
#' * `redundant_prerequisite` (info): A prerequisite edge is implied by a
#'   longer path (A before B before C makes A before C redundant).
#' * `isolated` (info): A concept has no relations to other concepts, in a
#'   graph where other concepts do have relations.
#' * `duplicate_edge` (info): The same edge is listed more than once.
#'
#' @param kg a knowledge graph from [mv_kg_build()] or [as_mv_kg()].
#' @param min_items smallest number of items per concept before a
#'   `few_items` flag.
#' @return A tibble of class `mv_kg_check` with columns `check`, `level`,
#'   `nodes` (the concepts or items involved) and `message`; zero rows when
#'   nothing was found.
#' @examples
#' mv_kg_check(fractions_kg)
#' mv_kg_check(fraction_subtraction_kg)
#' @export
mv_kg_check <- function(kg, min_items = 3) {
  check_kg(kg)
  cn <- kg_concept_names(kg)
  e <- kg$edges
  pre <- kg_prereq(kg)
  meas <- e[e$type == "measures", , drop = FALSE]
  out <- list()
  add <- function(check, level, nodes, message)
    out[[length(out) + 1L]] <<- data.frame(check = check, level = level,
                                            nodes = paste(nodes, collapse = ", "),
                                            message = message, stringsAsFactors = FALSE)
  loops <- unique(pre$from[pre$from == pre$to])
  for (n in loops) add("self_loop", "block", n, sprintf("%s is listed as its own prerequisite.", n))
  cyc <- setdiff(kg_cycle_nodes(kg), loops)
  if (length(cyc))
    add("cycle", "block", cyc,
        sprintf("Prerequisite edges form a cycle through %s, so no learning order exists.",
                paste(cyc, collapse = ", ")))
  n_items <- vapply(cn, function(n) length(unique(meas$from[meas$to == n])), integer(1))
  if (nrow(meas)) {
    for (n in cn[n_items == 0])
      add("unmeasured", "review", n, sprintf("No item measures %s.", n))
    for (n in cn[n_items > 0 & n_items < min_items])
      add("few_items", "review", n,
          sprintf("%s is measured by %d item(s); at least %d are needed to estimate it as its own dimension.",
                  n, n_items[n], min_items))
    sets <- lapply(cn, function(n) sort(unique(meas$from[meas$to == n])))
    names(sets) <- cn
    keys <- vapply(sets, paste, character(1), collapse = "|")
    for (k in unique(keys[duplicated(keys) & nzchar(keys)])) {
      same <- cn[keys == k]
      add("same_items", "review", same,
          sprintf("%s are measured by exactly the same items, so the data cannot tell them apart.",
                  paste(same, collapse = " and ")))
    }
  }
  if (!length(cyc) && !length(loops) && nrow(pre)) {
    for (i in seq_len(nrow(pre))) {
      others <- pre[-i, , drop = FALSE]
      if (pre$to[i] %in% kg_reach(others, pre$from[i]))
        add("redundant_prerequisite", "info", c(pre$from[i], pre$to[i]),
            sprintf("%s -> %s is implied by a longer prerequisite path.", pre$from[i], pre$to[i]))
    }
  }
  rel <- e[e$type != "measures", , drop = FALSE]
  linked <- unique(c(rel$from, rel$to))
  if (length(cn) > 1 && nrow(rel))
    for (n in setdiff(cn, linked))
      add("isolated", "info", n, sprintf("%s has no relations to other concepts.", n))
  key <- ifelse(e$type == "related", paste(pmin(e$from, e$to), pmax(e$from, e$to), e$type),
                paste(e$from, e$to, e$type))
  for (k in unique(key[duplicated(key)])) {
    d <- e[key == k, , drop = FALSE][1, ]
    add("duplicate_edge", "info", c(d$from, d$to),
        sprintf("The %s edge %s -> %s is listed more than once.", d$type, d$from, d$to))
  }
  res <- if (length(out)) do.call(rbind, out) else
    data.frame(check = character(), level = character(), nodes = character(),
               message = character(), stringsAsFactors = FALSE)
  res <- res[order(match(res$level, c("block", "review", "info"))), , drop = FALSE]
  rownames(res) <- NULL
  structure(as_tbl(res), class = c("mv_kg_check", class(as_tbl(res))))
}

#' @export
print.mv_kg_check <- function(x, ...) {
  if (!nrow(x)) {
    cat("<mv_kg_check> No problems found.\n")
    return(invisible(x))
  }
  counts <- table(factor(x$level, c("block", "review", "info")))
  cat(sprintf("<mv_kg_check> %d block, %d review, %d info\n",
              counts[["block"]], counts[["review"]], counts[["info"]]))
  for (i in seq_len(nrow(x)))
    cat(strwrap(sprintf("[%s] %s: %s", x$level[i], x$check[i], x$message[i]),
                initial = "* ", prefix = "  "), sep = "\n")
  invisible(x)
}

#' @export
print.mv_kg <- function(x, ...) {
  g <- glance(x)
  title <- if (!is.na(x$name)) sprintf(" %s:", x$name) else ""
  cat(sprintf("<mv_kg>%s %d concept(s), %d item(s)\n", title, g$concepts, g$items))
  cat(sprintf("Edges: %d prerequisite, %d related, %d measures\n",
              g$prerequisite, g$related, g$measures))
  if (!g$acyclic) {
    cat("Prerequisite edges contain a cycle; see mv_kg_check().\n")
  } else if (g$prerequisite) {
    d <- kg_depth(x)
    cat("Learning order (by prerequisite depth):\n")
    for (lv in sort(unique(d)))
      cat(sprintf("  %d: %s\n", lv, paste(names(d)[d == lv], collapse = ", ")))
  }
  invisible(x)
}

#' Tidy and glance methods for knowledge graphs
#'
#' `tidy()` returns the nodes or edges of a knowledge graph as a tibble;
#' `glance()` returns a one-row summary.
#'
#' @param x a knowledge graph from [mv_kg_build()] or [as_mv_kg()].
#' @param what `"nodes"` or `"edges"` for `tidy()`. Nodes get the number of
#'   items (for concepts) or concepts (for items) they are linked to and,
#'   for concepts, their prerequisite `depth`.
#' @param ... unused.
#' @return A tibble.
#' @examples
#' tidy(fractions_kg)
#' tidy(fractions_kg, "edges")
#' glance(fractions_kg)
#' @name tidy_mv_kg
#' @export
tidy.mv_kg <- function(x, what = c("nodes", "edges"), ...) {
  what <- match.arg(what)
  if (what == "edges") return(x$edges)
  n <- as.data.frame(x$nodes, stringsAsFactors = FALSE)
  meas <- x$edges[x$edges$type == "measures", , drop = FALSE]
  n$links <- vapply(seq_len(nrow(n)), function(i)
    if (n$kind[i] == "concept") sum(meas$to == n$node[i]) else sum(meas$from == n$node[i]),
    numeric(1))
  d <- kg_depth(x)
  n$depth <- unname(d[n$node])
  as_tbl(n)
}

#' @rdname tidy_mv_kg
#' @export
glance.mv_kg <- function(x, ...) {
  d <- kg_depth(x)
  ty <- x$edges$type
  acyclic <- !length(kg_cycle_nodes(x))
  as_tbl(data.frame(
    concepts = length(kg_concept_names(x)), items = length(kg_item_names(x)),
    prerequisite = sum(ty == "prerequisite"), related = sum(ty == "related"),
    measures = sum(ty == "measures"), acyclic = acyclic,
    depth = if (acyclic && length(d)) max(d) else NA_real_,
    stringsAsFactors = FALSE))
}

# Positions for gg_kg(): Concepts in columns by prerequisite depth, ordered
# within a column to reduce crossings; items in a final column, next to the
# concepts they measure. Columns share one height so the picture stays
# balanced.
kg_layout <- function(kg, items = TRUE) {
  cn <- kg_concept_names(kg)
  d <- kg_depth(kg)
  if (anyNA(d)) d[is.na(d)] <- max(c(0, d), na.rm = TRUE) + 1
  rel <- kg$edges[kg$edges$type != "measures", , drop = FALSE]
  it <- if (items) kg_item_names(kg) else character()
  layers <- sort(unique(d))
  widest <- max(vapply(layers, function(lv) sum(d == lv), numeric(1)))
  height <- max(widest, 0.4 * length(it), 1)
  spread <- function(n) if (n == 1) 0 else seq(height / 2, -height / 2, length.out = n) * (n / (n + 1))
  y <- stats::setNames(numeric(length(cn)), cn)
  for (lv in layers) {
    m <- names(d)[d == lv]
    y[m] <- spread(length(m))
  }
  # two barycenter sweeps: Place each concept near the mean height of the
  # concepts it is related to in earlier columns, keeping a minimum gap
  gap <- height / (widest + 1)
  for (sweep in 1:2) {
    for (lv in layers[-1]) {
      m <- names(d)[d == lv]
      bc <- vapply(m, function(n) {
        nb <- c(rel$from[rel$to == n], rel$to[rel$from == n])
        nb <- nb[nb %in% names(d) & d[nb] < lv]
        if (length(nb)) mean(y[nb]) else y[n]
      }, numeric(1))
      ord <- order(-bc)
      yy <- bc[ord]
      if (length(yy) > 1)
        for (i in 2:length(yy)) yy[i] <- min(yy[i], yy[i - 1] - gap)
      yy <- yy - (mean(yy) - mean(bc))
      yy <- yy - max(0, max(yy) - height / 2) + max(0, -height / 2 - min(yy))
      y[m[ord]] <- yy
    }
  }
  out <- data.frame(node = cn, kind = "concept", x = unname(d[cn]), y = unname(y[cn]),
                    stringsAsFactors = FALSE)
  if (length(it)) {
    meas <- kg$edges[kg$edges$type == "measures", , drop = FALSE]
    bc <- vapply(it, function(i) mean(y[meas$to[meas$from == i]]), numeric(1))
    ord <- it[order(-bc, it)]
    out <- rbind(out, data.frame(node = ord, kind = "item", x = max(d) + 1, y = spread(length(ord)),
                                 stringsAsFactors = FALSE))
  }
  out
}

#' Draw a knowledge graph
#'
#' Draws concepts in columns by their place in the learning order: Concepts
#' with no prerequisites on the left, and each prerequisite arrow pointing to
#' the right. Related concepts are joined by dashed lines. Items, when
#' shown, sit in a column on the right, joined to the concepts they measure.
#'
#' @param kg a knowledge graph from [mv_kg_build()] or [as_mv_kg()].
#' @param items logical; draw the items. Defaults to `TRUE` when the graph
#'   has 40 or fewer items.
#' @param labels `"label"` to print concept labels or `"node"` for the short
#'   concept names.
#' @param highlight optional concepts or items to draw in the accent colour,
#'   for example the concepts flagged by [mv_kg_check()].
#' @return A ggplot object.
#' @examples
#' gg_kg(fractions_kg)
#' gg_kg(fractions_kg, items = FALSE, highlight = "common_denominator")
#' gg_kg(fraction_subtraction_kg, labels = "node")
#' @export
gg_kg <- function(kg, items = NULL, labels = c("label", "node"), highlight = NULL) {
  check_kg(kg)
  labels <- match.arg(labels)
  if (is.null(items)) items <- length(kg_item_names(kg)) <= 40
  kg_plot(kg, items, labels, highlight)$plot
}

# Draws a graph; `lay` can give node positions from another graph (used by
# gg_kg_fit() to place suggested edges), and `hl_edges` colours the edges
# of highlighted nodes. Returns the plot and the node table.
kg_plot <- function(kg, items, labels, highlight = NULL, lay = NULL, hl_edges = TRUE) {
  if (is.null(lay)) lay <- kg_layout(kg, items = items)
  lay <- lay[lay$node %in% kg$nodes$node & (items | lay$kind == "concept"), , drop = FALSE]
  nodes <- merge(lay, as.data.frame(kg$nodes)[c("node", "label")], by = "node", sort = FALSE)
  nodes$text <- if (labels == "label") nodes$label else nodes$node
  is_c <- nodes$kind == "concept"
  nodes$text[is_c] <- vapply(nodes$text[is_c], function(t) paste(strwrap(t, 14), collapse = "\n"),
                             character(1))
  # rough half-width of each concept label, in columns
  nodes$hw <- ifelse(is_c, pmin(0.42, 0.03 * vapply(strsplit(nodes$text, "\n"),
                                                    function(l) max(nchar(l)), numeric(1)) + 0.04), 0)
  nodes$hl <- nodes$node %in% highlight
  pos <- function(n, col) nodes[[col]][match(n, nodes$node)]
  e <- as.data.frame(kg$edges, stringsAsFactors = FALSE)
  e <- e[e$from %in% nodes$node & e$to %in% nodes$node, , drop = FALSE]
  e$x <- pos(e$from, "x"); e$y <- pos(e$from, "y")
  e$xend <- pos(e$to, "x"); e$yend <- pos(e$to, "y")
  e$hl <- hl_edges & (e$from %in% highlight | e$to %in% highlight)
  # prerequisite arrows run from the right edge of one label to the left edge of the next
  pre <- e[e$type == "prerequisite", , drop = FALSE]
  if (nrow(pre)) {
    fwd <- pre$xend > pre$x
    pre$x <- pre$x + ifelse(fwd, pos(pre$from, "hw"), 0)
    pre$xend <- pre$xend - ifelse(fwd, pos(pre$to, "hw"), 0)
    pre$y <- pre$y + ifelse(fwd, 0, -0.25)
    pre$yend <- pre$yend + ifelse(fwd, 0, 0.25)
  }
  rel <- e[e$type == "related", , drop = FALSE]
  meas <- e[e$type == "measures", , drop = FALSE]
  concepts <- nodes[nodes$kind == "concept", , drop = FALSE]
  its <- nodes[nodes$kind == "item", , drop = FALSE]
  col_line <- function(h) ifelse(h, mv_colours[["accent"]], mv_colours[["primary"]])
  p <- ggplot2::ggplot()
  if (nrow(meas))
    p <- p + ggplot2::geom_segment(
      data = meas, ggplot2::aes(x = xend, y = yend, xend = x, yend = y),
      colour = ifelse(meas$hl, mv_colours[["accent"]], "grey80"), linewidth = 0.3)
  if (nrow(rel))
    p <- p + ggplot2::geom_segment(
      data = rel, ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
      colour = mv_colours[["grey"]], linetype = "dashed", linewidth = 0.5)
  if (nrow(pre))
    p <- p + ggplot2::geom_segment(
      data = pre, ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
      colour = col_line(pre$hl), linewidth = 0.7,
      arrow = grid::arrow(length = grid::unit(2.2, "mm"), type = "closed"))
  if (nrow(its))
    p <- p + ggplot2::geom_point(data = its, ggplot2::aes(x = x, y = y),
                                 colour = ifelse(its$hl, mv_colours[["accent"]], mv_colours[["grey"]]),
                                 size = 1.6) +
      ggplot2::geom_text(data = its, ggplot2::aes(x = x + 0.05, y = y, label = text),
                         hjust = 0, size = 2.6, colour = "grey30")
  p <- p + ggplot2::geom_label(
    data = concepts, ggplot2::aes(x = x, y = y, label = text),
    fill = ifelse(concepts$hl, "#F8E1E4", "white"),
    colour = ifelse(concepts$hl, mv_colours[["accent"]], mv_colours[["primary"]]),
    size = 3.2, lineheight = 0.95, label.padding = grid::unit(0.3, "lines"))
  xmax <- max(nodes$x) + if (nrow(its)) 0.35 else 0.5
  p <- p + ggplot2::scale_x_continuous(expand = ggplot2::expansion(add = 0.5),
                                  limits = c(min(nodes$x) - 0.5, xmax)) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(add = 0.5)) +
    ggplot2::labs(title = if (!is.na(kg$name)) kg$name else NULL,
                  subtitle = if (nrow(pre)) "Prerequisite arrows point left to right" else NULL) +
    theme_mirtverse() +
    ggplot2::theme(axis.text = ggplot2::element_blank(), axis.title = ggplot2::element_blank(),
                   panel.grid = ggplot2::element_blank())
  list(plot = p, nodes = nodes)
}

#' Keep part of a knowledge graph
#'
#' Returns the part of a graph that covers chosen concepts or items: The
#' concepts kept, the relations among them, and the items that measure at
#' least one of them. Useful for fitting a model to a few well-measured
#' concepts, or to the items a data set actually has.
#'
#' @param kg a knowledge graph from [mv_kg_build()] or [as_mv_kg()].
#' @param concepts concepts to keep (default: All).
#' @param items optional items to keep, as names or a data frame whose
#'   column names are used; other columns (such as an ID) are skipped.
#' @return An `mv_kg` object. Items left without a concept are dropped.
#' @examples
#' kg3 <- mv_kg_subset(fraction_subtraction_kg,
#'                     c("separate_whole", "borrow_whole", "common_denominator"))
#' kg3
#' @export
mv_kg_subset <- function(kg, concepts = NULL, items = NULL) {
  check_kg(kg)
  cn <- kg_concept_names(kg)
  if (is.null(concepts)) concepts <- cn
  bad <- setdiff(concepts, cn)
  if (length(bad)) stop("Unknown concepts: ", paste(bad, collapse = ", "), ".", call. = FALSE)
  keep_items <- if (is.null(items)) kg_item_names(kg) else kg_resolve_items(kg, items)
  e <- as.data.frame(kg$edges, stringsAsFactors = FALSE)
  rel <- e[e$type != "measures" & e$from %in% concepts & e$to %in% concepts, , drop = FALSE]
  meas <- e[e$type == "measures" & e$to %in% concepts & e$from %in% keep_items, , drop = FALSE]
  nodes <- as.data.frame(kg$nodes, stringsAsFactors = FALSE)
  cnodes <- nodes[nodes$kind == "concept" & nodes$node %in% concepts, , drop = FALSE]
  mv_kg_build(
    concepts = data.frame(concept = cnodes$node, label = cnodes$label,
                          description = cnodes$description, stringsAsFactors = FALSE),
    edges = if (nrow(rel)) rel[c("from", "to", "type", "weight")],
    items = if (nrow(meas)) data.frame(item = meas$from, concept = meas$to, weight = meas$weight,
                                       stringsAsFactors = FALSE),
    name = kg$name)
}
