#' Draft a knowledge graph from item text with a language model
#'
#' **Experimental.** Sends the text of the items to a language model and
#' asks it to draft a knowledge graph: Which concepts the items measure,
#' which items measure which concepts, and which concepts are prerequisites
#' of others. The draft is a starting point for people who know the
#' content, not a finished graph, so it comes back with checks already run
#' and every link carrying the model's reason.
#'
#' Two uses are supported:
#'
#' * **Concepts given:** Pass a list of concepts (or a graph whose concepts
#'   you want to keep) and the model only links items to them and proposes
#'   prerequisites. This is how to draft a Q-matrix for new items, or to
#'   get a second opinion on an existing one; compare the two with
#'   [mv_kg_compare()].
#' * **Concepts proposed:** Leave `concepts` empty and the model also
#'   proposes the concepts, with labels and descriptions.
#'
#' What the model returns is checked before the graph is built, and each
#' problem becomes a row of `tidy(draft, "flags")`: Links to items or
#' concepts that do not exist are dropped, items the model did not link are
#' listed, prerequisite edges that point both ways keep the one with higher
#' confidence, and edges that form a cycle are removed, lowest confidence
#' first, until the prerequisites have a learning order. The usual next
#' steps are [mv_kg_check()] for the structure and [mv_kg_fit()] for
#' whether response data agree with it.
#'
#' Only the item ids and text, the concept list and `subject` are sent to
#' the model; no response data. To run without a live model, for teaching
#' or examples, use [mv_llm_replay()]: The example recordings that come with
#' mirtverse answer the calls in
#' `system.file("replay", "examples.R", package = "mirtverse")`.
#'
#' @param items the items: A data frame with an id column and a text
#'   column, an [mv_pipeline()] (its items are used), or a knowledge graph
#'   whose item metadata has the text (see [mv_kg_annotate()]); a graph also
#'   gives the concepts unless `concepts` is set.
#' @param concepts optional concepts the model must use: A character vector
#'   of names, a data frame with `concept` and optional `label` and
#'   `description` columns, or a knowledge graph. Descriptions help the
#'   model, so give them when you can.
#' @param text name of the item text column. Defaults to `text`, or `stem`
#'   when there is no `text` column. Several columns (for example a stem and
#'   its options) are joined.
#' @param id name of the item id column. Defaults to `item`, or `id`.
#' @param subject optional one-line description of the test, such as
#'   `"Grade 7 numeracy"`, to give the model context.
#' @param n_concepts optional number of concepts to aim for when the model
#'   proposes them.
#' @param prerequisites logical; ask for prerequisite edges between
#'   concepts.
#' @param provider,model the language model, as in [mv_ask_setup()].
#' @param name optional name of the graph.
#' @return An object of class `mv_kg_draft`, which is also an `mv_kg`, so
#'   every knowledge graph function accepts it. The item columns other than
#'   the id are kept as item metadata. `tidy(draft, "reasons")` returns the
#'   model's reason for each link and prerequisite edge, with the
#'   prerequisites' confidence; `tidy(draft, "flags")` returns the problems
#'   found in the model's answer.
#' @seealso [mv_kg_compare()] to compare the draft with an expert graph;
#'   [mv_kg_check()], [mv_kg_fit()] and [mv_kg_refine()] for the review.
#' @examples
#' if (requireNamespace("ellmer", quietly = TRUE)) {
#'   old <- mv_llm_replay()        # answer from the recordings that come with mirtverse
#'
#'   # a second opinion on Tatsuoka's Q-matrix, from the text of the 20 problems
#'   draft <- mv_kg_extract(fraction_subtraction_kg,
#'                          subject = "Middle school fraction subtraction")
#'   print(draft)
#'   print(tidy(draft, "flags"))
#'   print(mv_kg_compare(draft, fraction_subtraction_kg))
#'
#'   # concepts proposed by the model
#'   items <- itemtext[endsWith(itemtext$id, "-01"), c("id", "domain", "stem")]
#'   draft2 <- mv_kg_extract(items, subject = "Grade 7 numeracy")
#'   print(gg_kg(draft2, colour = "domain"))
#'
#'   options(old)
#' }
#' @export
mv_kg_extract <- function(items, concepts = NULL, text = NULL, id = NULL, subject = NULL,
                          n_concepts = NULL, prerequisites = TRUE, provider = NULL,
                          model = NULL, name = NULL) {
  if (inherits(items, "mv_kg")) {
    if (is.null(concepts)) concepts <- items
    if (is.null(name) && !is.na(items$name)) name <- paste(items$name, "(drafted)")
    if (is.null(items$meta))
      stop("This graph has no item metadata, so there is no item text to read; ",
           "add it with mv_kg_annotate().", call. = FALSE)
    items <- items$meta
  } else if (inherits(items, "mv_pipeline")) {
    items <- items$items
    if (is.null(items) || !NROW(items)) stop("The pipeline has no items yet.", call. = FALSE)
  }
  if (!is.data.frame(items)) stop("`items` must be a data frame, a pipeline or a knowledge graph.",
                                  call. = FALSE)
  items <- as.data.frame(items, stringsAsFactors = FALSE)
  id <- id %||% intersect(c("item", "id"), names(items))[1]
  if (is.na(id) || !id %in% names(items))
    stop("`items` needs an id column: Name it `item` or `id`, or give its name in `id`.", call. = FALSE)
  text <- text %||% intersect(c("text", "stem"), names(items))[1]
  if (anyNA(text) || !all(text %in% names(items)))
    stop("`items` needs a text column: Name it `text` or `stem`, or give its name in `text`.",
         call. = FALSE)
  ids <- as.character(items[[id]])
  if (anyNA(ids) || anyDuplicated(ids)) stop("Item ids must be unique and not missing.", call. = FALSE)
  body <- kg_item_text(items, text)
  if (any(!nzchar(body))) stop("Some items have no text: ",
                               paste(utils::head(ids[!nzchar(body)], 5), collapse = ", "), ".",
                               call. = FALSE)
  given <- if (is.null(concepts)) NULL else kg_given_concepts(concepts)
  if (!is.null(given) && any(given$concept %in% ids))
    stop("Items and concepts need different names.", call. = FALSE)

  provider <- ask_provider(provider)
  if (provider == "rules")
    stop("Drafting a knowledge graph needs a language model; run mv_ask_setup() to choose one, ",
         "or mv_llm_replay() for the recorded examples.", call. = FALSE)
  model <- ask_model(provider, model)
  sys <- kg_extract_system_prompt(!is.null(given), n_concepts, prerequisites)
  prompt <- kg_extract_prompt(ids, body, given, subject)
  chat <- make_chat(provider, model, sys)
  res <- chat$chat_structured(prompt, type = kg_extract_type(), echo = "none")

  d <- kg_extract_assemble(res, ids, given, prerequisites)
  meta <- items[vapply(items, function(v) is.atomic(v) && !is.matrix(v), NA)]
  names(meta)[names(meta) == id] <- "item"
  meta <- meta[c("item", setdiff(names(meta), c("item", "concepts", "n_concepts")))]
  kg <- mv_kg_build(d$concepts, edges = if (nrow(d$prereq)) d$prereq[c("from", "to")],
                    items = if (nrow(d$links)) d$links[c("item", "concept")],
                    name = name %||% (if (!is.null(subject)) paste(subject, "(drafted)")) %||%
                      "Drafted knowledge graph")
  if (ncol(meta) > 1) kg <- kg_carry_meta(kg, meta)
  kg$draft <- list(links = as_tbl(d$all_links), prerequisites = as_tbl(d$all_prereq),
                   flags = as_tbl(d$flags), provider = provider, model = model %||% "",
                   subject = subject %||% NA_character_, given = !is.null(given))
  class(kg) <- c("mv_kg_draft", class(kg))
  kg
}

# ---- What the model sees -----------------------------------------------------

kg_item_text <- function(items, text) {
  first <- trimws(as.character(items[[text[1]]]))
  first[is.na(first)] <- ""
  if (length(text) == 1) return(first)
  rest <- vapply(seq_len(nrow(items)), function(i) {
    v <- vapply(text[-1], function(t) as.character(items[[t]][i]), "")
    v <- v[!is.na(v) & nzchar(v)]
    if (length(v)) paste(sprintf("%s: %s", names(v), v), collapse = "; ") else ""
  }, "")
  ifelse(nzchar(rest), paste0(first, " (", rest, ")"), first)
}

kg_given_concepts <- function(concepts) {
  if (inherits(concepts, "mv_kg")) {
    n <- as.data.frame(concepts$nodes, stringsAsFactors = FALSE)
    n <- n[n$kind == "concept", , drop = FALSE]
    return(data.frame(concept = n$node, label = n$label, description = n$description,
                      stringsAsFactors = FALSE))
  }
  k <- kg_concepts(concepts)
  data.frame(concept = k$node, label = k$label, description = k$description,
             stringsAsFactors = FALSE)
}

kg_extract_system_prompt <- function(given, n_concepts, prerequisites) paste(c(
  "You draft a knowledge graph for an educational test from the text of its items.",
  "A knowledge graph lists the concepts (skills or attributes) the test measures, which items measure which concepts, and which concepts are prerequisites of others.",
  "Do not answer the items.",
  "",
  "Rules:",
  if (given) c(
    "- concepts: Use only the concepts listed, by their exact id. Do not add concepts; return an empty concepts list."
  ) else c(
    "- concepts: Propose the concepts the items measure. Give each a short lowercase id with underscores (for example unit_rate), a label of a few words and a one-sentence description.",
    if (!is.null(n_concepts)) sprintf("- Aim for about %d concepts.", as.integer(n_concepts)) else
      "- Aim for between 3 and 8 concepts, each measured by at least 3 items where the items allow it."
  ),
  "- links: For every item, list each concept a student needs to answer it correctly, one link per item and concept. An item can need several concepts. Use the item ids exactly as given, and give a short reason.",
  if (prerequisites) c(
    "- prerequisites: An edge from A to B means a student must learn A before B can be learned. List only direct prerequisites, each with a confidence between 0 and 1 and a short reason.",
    "- The prerequisite edges must not form a cycle."
  ) else "- prerequisites: Return an empty list."),
  collapse = "\n")

kg_extract_prompt <- function(ids, body, given, subject) {
  c_lines <- if (!is.null(given)) {
    lab <- ifelse(given$label != given$concept, paste0(": ", given$label), "")
    desc <- ifelse(is.na(given$description) | !nzchar(given$description %||% ""), "",
                   paste0(". ", given$description))
    c("Concepts:", sprintf("- %s%s%s", given$concept, lab, desc), "")
  }
  paste(c(if (!is.null(subject)) c(sprintf("Test: %s", subject), ""),
          c_lines,
          "Items:", sprintf("[%s] %s", ids, body)), collapse = "\n")
}

kg_extract_type <- function() ellmer::type_object(
  concepts = ellmer::type_array(ellmer::type_object(
    concept = ellmer::type_string("Short lowercase id with underscores."),
    label = ellmer::type_string("A label of a few words."),
    description = ellmer::type_string("One sentence."))),
  links = ellmer::type_array(ellmer::type_object(
    item = ellmer::type_string("The item id, exactly as given."),
    concept = ellmer::type_string("The concept id."),
    reason = ellmer::type_string("Why the item needs this concept, in a few words."))),
  prerequisites = ellmer::type_array(ellmer::type_object(
    from = ellmer::type_string("The concept learned first."),
    to = ellmer::type_string("The concept that builds on it."),
    confidence = ellmer::type_number("Between 0 and 1."),
    reason = ellmer::type_string("Why, in a few words."))))

# ---- Checking the answer -----------------------------------------------------

kg_clean_id <- function(x) {
  x <- tolower(trimws(as.character(x)))
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("^_+|_+$", "", x)
  ifelse(grepl("^[0-9]", x), paste0("c_", x), x)
}

kg_rows <- function(x, cols) {
  if (is.null(x) || !length(x)) x <- list()
  if (!is.data.frame(x)) {
    x <- lapply(x, function(r) lapply(cols, function(cl) r[[cl]] %||% NA))
    x <- if (length(x)) do.call(rbind, lapply(x, function(r)
      as.data.frame(stats::setNames(r, cols), stringsAsFactors = FALSE))) else NULL
  }
  if (is.null(x) || !nrow(x)) {
    out <- as.data.frame(stats::setNames(rep(list(character()), length(cols)), cols),
                         stringsAsFactors = FALSE)
    return(out)
  }
  for (cl in setdiff(cols, names(x))) x[[cl]] <- NA
  x <- as.data.frame(x[cols], stringsAsFactors = FALSE)
  rownames(x) <- NULL
  x
}

kg_extract_assemble <- function(res, ids, given, prerequisites) {
  flags <- list()
  add <- function(check, level, nodes, message)
    flags[[length(flags) + 1L]] <<- data.frame(check = check, level = level,
                                                nodes = paste(nodes, collapse = ", "),
                                                message = message, stringsAsFactors = FALSE)
  rc <- kg_rows(res$concepts, c("concept", "label", "description"))
  if (!is.null(given)) {
    concepts <- given
    lookup <- c(stats::setNames(given$concept, given$concept),
                stats::setNames(given$concept, given$label))
    lookup <- lookup[!is.na(names(lookup)) & !duplicated(names(lookup))]
    new <- setdiff(unique(as.character(rc$concept)), given$concept)
    new <- new[!is.na(new) & nzchar(new)]
    for (n in new) add("new_concept", "info", n,
                       sprintf("The model proposed a new concept, %s; it was left out because the concepts were given.", n))
  } else {
    rc <- rc[!is.na(rc$concept) & nzchar(trimws(rc$concept)), , drop = FALSE]
    clean <- kg_clean_id(rc$concept)
    clean[clean %in% ids] <- paste0("concept_", clean[clean %in% ids])
    dup <- duplicated(clean)
    for (n in unique(clean[dup])) add("duplicate_concept", "info", n,
                                      sprintf("The model listed %s more than once; the first was kept.", n))
    lookup <- c(stats::setNames(clean, rc$concept), stats::setNames(clean, clean),
                stats::setNames(clean, as.character(rc$label)))
    lookup <- lookup[!is.na(names(lookup)) & !duplicated(names(lookup))]
    rc <- rc[!dup, , drop = FALSE]; clean <- clean[!dup]
    if (!nrow(rc)) stop("The model proposed no concepts.", call. = FALSE)
    concepts <- data.frame(concept = clean,
                           label = ifelse(is.na(rc$label) | !nzchar(rc$label), clean, rc$label),
                           description = rc$description, stringsAsFactors = FALSE)
  }
  to_concept <- function(x) {
    x <- as.character(x)
    out <- unname(lookup[x])
    miss <- is.na(out) & !is.na(x)
    out[miss] <- unname(lookup[kg_clean_id(x[miss])])
    out
  }

  # links
  rl <- kg_rows(res$links, c("item", "concept", "reason"))
  rl$item <- gsub("^\\[|\\]$", "", trimws(as.character(rl$item)))
  rl$raw <- as.character(rl$concept)
  rl$concept <- to_concept(rl$raw)
  rl$kept <- rep(TRUE, nrow(rl))
  bad_item <- !rl$item %in% ids
  for (i in which(bad_item))
    add("unknown_item", "review", rl$item[i],
        sprintf("The model linked %s, which is not one of the items; the link was dropped.", rl$item[i]))
  bad_c <- !bad_item & is.na(rl$concept)
  for (i in which(bad_c))
    add("unknown_concept", "review", c(rl$item[i], rl$raw[i]),
        sprintf("%s was linked to %s, which is not a concept; the link was dropped.", rl$item[i], rl$raw[i]))
  rl$kept <- !bad_item & !bad_c
  rl$kept[rl$kept & duplicated(paste(rl$item, rl$concept))] <- FALSE
  links <- rl[rl$kept, c("item", "concept", "reason"), drop = FALSE]
  unlinked <- setdiff(ids, links$item)
  for (i in unlinked)
    add("unlinked_item", "review", i,
        sprintf("%s was not linked to any concept, so it is not in the graph.", i))

  # prerequisites
  rp <- kg_rows(if (prerequisites) res$prerequisites, c("from", "to", "confidence", "reason"))
  rp$raw_from <- as.character(rp$from); rp$raw_to <- as.character(rp$to)
  rp$from <- to_concept(rp$raw_from); rp$to <- to_concept(rp$raw_to)
  rp$confidence <- suppressWarnings(as.numeric(rp$confidence))
  rp$kept <- rep(TRUE, nrow(rp))
  for (i in seq_len(nrow(rp))) {
    if (is.na(rp$from[i]) || is.na(rp$to[i])) {
      rp$kept[i] <- FALSE
      n <- c(rp$raw_from[i], rp$raw_to[i])[is.na(c(rp$from[i], rp$to[i]))]
      add("unknown_concept", "review", n,
          sprintf("The prerequisite %s -> %s names %s, which is not a concept; it was dropped.",
                  rp$raw_from[i], rp$raw_to[i], paste(n, collapse = " and ")))
    } else if (rp$from[i] == rp$to[i]) {
      rp$kept[i] <- FALSE
      add("self_loop", "review", rp$from[i],
          sprintf("The model listed %s as its own prerequisite; the edge was dropped.", rp$from[i]))
    }
  }
  key <- paste(rp$from, rp$to)
  rp$kept[rp$kept & duplicated(key) ] <- FALSE
  for (i in which(rp$kept)) {
    if (!rp$kept[i]) next
    j <- which(rp$kept & rp$from == rp$to[i] & rp$to == rp$from[i])
    if (length(j)) {
      ci <- rp$confidence[i] %||% 0; cj <- rp$confidence[j[1]] %||% 0
      drop <- if (isTRUE(cj > ci)) i else j[1]
      keep <- setdiff(c(i, j[1]), drop)
      rp$kept[drop] <- FALSE
      add("two_way", "review", c(rp$from[i], rp$to[i]),
          sprintf("The model gave the prerequisite both ways between %s and %s; %s -> %s was kept (higher confidence).",
                  rp$from[i], rp$to[i], rp$from[keep], rp$to[keep]))
    }
  }
  # break cycles, lowest confidence first
  repeat {
    pre <- rp[rp$kept, c("from", "to"), drop = FALSE]
    if (!nrow(pre)) break
    on_cycle <- vapply(seq_len(nrow(pre)), function(i)
      pre$from[i] %in% kg_reach(pre, pre$to[i]), NA)
    if (!any(on_cycle)) break
    idx <- which(rp$kept)[on_cycle]
    conf <- rp$confidence[idx]; conf[is.na(conf)] <- -Inf
    drop <- idx[which.min(conf)]
    cyc <- unique(c(pre$from[on_cycle], pre$to[on_cycle]))
    rp$kept[drop] <- FALSE
    add("cycle", "review", cyc,
        sprintf("The prerequisites formed a cycle through %s; %s -> %s (confidence %s) was removed.",
                paste(cyc, collapse = ", "), rp$from[drop], rp$to[drop],
                format(rp$confidence[drop], digits = 2)))
  }
  prereq <- rp[rp$kept, c("from", "to", "confidence", "reason"), drop = FALSE]

  fl <- if (length(flags)) do.call(rbind, flags) else
    data.frame(check = character(), level = character(), nodes = character(),
               message = character(), stringsAsFactors = FALSE)
  fl <- fl[order(match(fl$level, c("block", "review", "info"))), , drop = FALSE]
  rownames(fl) <- NULL
  list(concepts = concepts, links = links, prereq = prereq, flags = fl,
       all_links = data.frame(item = rl$item, concept = ifelse(is.na(rl$concept), rl$raw, rl$concept),
                              reason = as.character(rl$reason), kept = rl$kept,
                              stringsAsFactors = FALSE),
       all_prereq = data.frame(from = ifelse(is.na(rp$from), rp$raw_from, rp$from),
                               to = ifelse(is.na(rp$to), rp$raw_to, rp$to),
                               confidence = rp$confidence, reason = as.character(rp$reason),
                               kept = rp$kept, stringsAsFactors = FALSE))
}

# ---- Methods -----------------------------------------------------------------

#' @export
print.mv_kg_draft <- function(x, ...) {
  d <- x$draft
  cat(sprintf("<mv_kg_draft> (EXPERIMENTAL) Drafted by %s%s\n",
              provider_label(d$provider, d$model),
              if (d$given) " from the concepts given" else ""))
  y <- x; class(y) <- setdiff(class(y), "mv_kg_draft")
  print(y)
  f <- d$flags
  if (nrow(f)) {
    cat(sprintf("Checks on the model's answer: %d flag(s)\n", nrow(f)))
    for (i in seq_len(nrow(f)))
      cat(strwrap(sprintf("[%s] %s: %s", f$level[i], f$check[i], f$message[i]),
                  initial = "* ", prefix = "  "), sep = "\n")
  } else cat("Checks on the model's answer: No problems found.\n")
  cat("Review the draft with mv_kg_check() and check it against data with mv_kg_fit().\n")
  invisible(x)
}

#' Tidy methods for drafted knowledge graphs
#'
#' @param x a draft from [mv_kg_extract()].
#' @param what `"nodes"`, `"edges"` or `"items"` as for any knowledge graph
#'   (see [tidy.mv_kg()]); `"reasons"` for the model's reason for every link
#'   and prerequisite edge it returned (with `kept = FALSE` for those the
#'   checks dropped); or `"flags"` for the problems the checks found.
#' @param ... unused.
#' @return A tibble.
#' @name tidy_mv_kg_draft
#' @export
tidy.mv_kg_draft <- function(x, what = c("nodes", "edges", "items", "reasons", "flags"), ...) {
  what <- match.arg(what)
  if (what == "flags") return(x$draft$flags)
  if (what == "reasons") {
    l <- as.data.frame(x$draft$links, stringsAsFactors = FALSE)
    p <- as.data.frame(x$draft$prerequisites, stringsAsFactors = FALSE)
    out <- rbind(
      data.frame(type = rep("measures", nrow(l)), from = l$item, to = l$concept,
                 confidence = rep(NA_real_, nrow(l)), reason = l$reason, kept = l$kept,
                 stringsAsFactors = FALSE),
      data.frame(type = rep("prerequisite", nrow(p)), from = p$from, to = p$to,
                 confidence = p$confidence, reason = p$reason, kept = p$kept,
                 stringsAsFactors = FALSE))
    return(as_tbl(out))
  }
  NextMethod()
}

# ---- Comparing two graphs ----------------------------------------------------

#' Compare a knowledge graph with a reference graph
#'
#' Measures how far a graph, such as a draft from [mv_kg_extract()], agrees
#' with a reference graph, such as an expert Q-matrix: Which item links and
#' prerequisite edges the two share, which only one has, and how many items
#' are linked to exactly the same concepts.
#'
#' When the graphs use different concept names (for example when a model
#' proposed its own concepts), each concept of `kg` is matched to the
#' reference concept whose items overlap most (the largest Jaccard index),
#' and the comparison uses the matched names. `tidy(x, "concepts")` shows
#' the matching.
#'
#' @param kg the graph to check.
#' @param reference the reference graph.
#' @param match `"auto"` (the default) matches concepts by name when every
#'   concept of `kg` is in `reference` and by their items otherwise;
#'   `"name"` or `"items"` force one.
#' @return An object of class `mv_kg_compare` with `summary` (precision,
#'   recall and F1 for item links and prerequisite edges), `items` (one row
#'   per shared item, with the concepts each graph gives it and the links
#'   missing from or extra to `kg`), `concepts` (the matching) and
#'   `prerequisites` (every edge in either graph and whether it is shared,
#'   reversed or in one graph only). Precision is the share of `kg`'s links
#'   that are in the reference; recall is the share of the reference's
#'   links that `kg` has.
#' @examples
#' # two hand-made Q-matrices for the same four items
#' expert <- as_mv_kg(matrix(c(1, 0, 1, 0, 0, 1, 1, 1), ncol = 2,
#'                           dimnames = list(paste0("Q", 1:4), c("number", "algebra"))))
#' other <- as_mv_kg(matrix(c(1, 1, 1, 0, 0, 0, 1, 1), ncol = 2,
#'                          dimnames = list(paste0("Q", 1:4), c("number", "algebra"))))
#' cmp <- mv_kg_compare(other, expert)
#' cmp
#' tidy(cmp, "items")
#'
#' # a language model's draft against Tatsuoka's Q-matrix
#' if (requireNamespace("ellmer", quietly = TRUE)) {
#'   old <- mv_llm_replay()
#'   draft <- mv_kg_extract(fraction_subtraction_kg,
#'                          subject = "Middle school fraction subtraction")
#'   print(mv_kg_compare(draft, fraction_subtraction_kg))
#'   options(old)
#' }
#' @export
mv_kg_compare <- function(kg, reference, match = c("auto", "name", "items")) {
  check_kg(kg); check_kg(reference)
  match <- match.arg(match)
  items <- intersect(kg_item_names(kg), kg_item_names(reference))
  if (!length(items)) stop("The two graphs have no items in common.", call. = FALSE)
  ck <- kg_concept_names(kg); cr <- kg_concept_names(reference)
  if (match == "auto") match <- if (all(ck %in% cr)) "name" else "items"
  mk <- kg$edges[kg$edges$type == "measures" & kg$edges$from %in% items, , drop = FALSE]
  mr <- reference$edges[reference$edges$type == "measures" & reference$edges$from %in% items, , drop = FALSE]
  if (match == "name") {
    map <- stats::setNames(ifelse(ck %in% cr, ck, NA_character_), ck)
    jac <- vapply(ck, function(n) {
      a <- mk$from[mk$to == n]; b <- mr$from[mr$to == n]
      if (!length(union(a, b))) NA_real_ else length(intersect(a, b)) / length(union(a, b))
    }, numeric(1))
  } else {
    best <- lapply(ck, function(n) {
      a <- unique(mk$from[mk$to == n])
      j <- vapply(cr, function(r) {
        b <- unique(mr$from[mr$to == r])
        if (!length(union(a, b))) 0 else length(intersect(a, b)) / length(union(a, b))
      }, numeric(1))
      if (!length(j) || max(j) == 0) list(NA_character_, 0) else list(cr[which.max(j)], max(j))
    })
    map <- stats::setNames(vapply(best, `[[`, "", 1), ck)
    jac <- stats::setNames(vapply(best, `[[`, 0, 2), ck)
  }
  concepts <- data.frame(concept = ck, matched = unname(map[ck]), jaccard = unname(jac[ck]),
                         stringsAsFactors = FALSE)

  pk <- unique(paste(mk$from, map[mk$to], sep = "\r"))
  pk <- pk[!grepl("\rNA$", pk)]
  pr <- unique(paste(mr$from, mr$to, sep = "\r"))
  prf <- function(a, b) {
    s <- length(intersect(a, b))
    p <- if (length(a)) s / length(a) else NA_real_
    r <- if (length(b)) s / length(b) else NA_real_
    c(in_graph = length(a), in_reference = length(b), shared = s, precision = p, recall = r,
      f1 = if (is.na(p) || is.na(r) || p + r == 0) NA_real_ else 2 * p * r / (p + r))
  }
  link_stats <- prf(pk, pr)
  # links of kg to concepts with no match count as extra
  n_unmatched <- length(unique(paste(mk$from, mk$to)[is.na(map[mk$to])]))
  if (n_unmatched) {
    link_stats["in_graph"] <- link_stats["in_graph"] + n_unmatched
    link_stats["precision"] <- link_stats["shared"] / link_stats["in_graph"]
    p <- link_stats["precision"]; r <- link_stats["recall"]
    link_stats["f1"] <- if (p + r == 0) NA_real_ else 2 * p * r / (p + r)
  }

  per_item <- lapply(items, function(i) {
    g <- sort(unique(stats::na.omit(unname(map[mk$to[mk$from == i]]))))
    r <- sort(unique(mr$to[mr$from == i]))
    data.frame(item = i, graph = paste(g, collapse = ", "), reference = paste(r, collapse = ", "),
               missing = paste(setdiff(r, g), collapse = ", "),
               extra = paste(setdiff(g, r), collapse = ", "),
               agree = setequal(g, r), stringsAsFactors = FALSE)
  })
  per_item <- do.call(rbind, per_item)

  ek <- kg_prereq(kg); er <- kg_prereq(reference)
  ek <- data.frame(from = unname(map[ek$from]), to = unname(map[ek$to]), stringsAsFactors = FALSE)
  ek <- unique(ek[!is.na(ek$from) & !is.na(ek$to) & ek$from != ek$to, , drop = FALSE])
  a <- paste(ek$from, ek$to, sep = "\r"); b <- paste(er$from, er$to, sep = "\r")
  pre_stats <- prf(a, b)
  if (!length(b)) pre_stats[c("recall", "f1")] <- NA_real_
  if (!length(b)) pre_stats["precision"] <- NA_real_
  status <- c(ifelse(a %in% b, "shared",
                     ifelse(paste(ek$to, ek$from, sep = "\r") %in% b, "reversed", "graph only")),
              rep("reference only", sum(!b %in% a & !paste(er$to, er$from, sep = "\r") %in% a)))
  pre_tab <- rbind(ek, data.frame(from = er$from, to = er$to, stringsAsFactors = FALSE)[
    !b %in% a & !paste(er$to, er$from, sep = "\r") %in% a, , drop = FALSE])
  pre_tab$status <- status
  rownames(pre_tab) <- NULL

  summary <- data.frame(part = c("item links", "prerequisites"),
                        rbind(link_stats, pre_stats), stringsAsFactors = FALSE, row.names = NULL)
  structure(list(summary = as_tbl(summary), items = as_tbl(per_item), concepts = as_tbl(concepts),
                 prerequisites = as_tbl(pre_tab), match = match,
                 names = c(kg = if (!is.na(kg$name)) kg$name else "Graph",
                           reference = if (!is.na(reference$name)) reference$name else "Reference")),
            class = "mv_kg_compare")
}

#' @export
print.mv_kg_compare <- function(x, ...) {
  cat(sprintf("<mv_kg_compare> %s vs %s\n", x$names[["kg"]], x$names[["reference"]]))
  if (x$match == "items") {
    cm <- x$concepts
    cat("Concepts matched by their items (Jaccard):\n")
    cat(sprintf("  %s -> %s (%.2f)\n", cm$concept, ifelse(is.na(cm$matched), "no match", cm$matched),
                cm$jaccard), sep = "")
  }
  s <- as.data.frame(x$summary)
  l <- s[1, ]
  cat(strwrap(sprintf(paste("Item links: %d of the %d reference links are in the graph (recall %.2f),",
                             "and %d of the graph's %d links are in the reference (precision %.2f)."),
                       l$shared, l$in_reference, l$recall, l$shared, l$in_graph, l$precision),
              exdent = 2), sep = "\n")
  it <- x$items
  cat(sprintf("%d of %d items are linked to exactly the same concepts.\n", sum(it$agree), nrow(it)))
  d <- it[!it$agree, , drop = FALSE]
  if (nrow(d)) {
    txt <- sprintf("%s (%s)", d$item, paste0(
      ifelse(nzchar(d$missing), paste("missing", d$missing), ""),
      ifelse(nzchar(d$missing) & nzchar(d$extra), "; ", ""),
      ifelse(nzchar(d$extra), paste("extra", d$extra), "")))
    cat(strwrap(paste0("Items that differ: ", paste(txt, collapse = ", "), "."), exdent = 2), sep = "\n")
  }
  p <- s[2, ]
  if (p$in_reference == 0) {
    cat(sprintf("Prerequisites: The graph has %d; the reference has none to compare with.\n",
                p$in_graph))
  } else {
    rev <- sum(x$prerequisites$status == "reversed")
    cat(sprintf("Prerequisites: %d of %d reference edges found (recall %.2f)%s.\n",
                p$shared, p$in_reference, p$recall,
                if (rev) sprintf("; %d reversed", rev) else ""))
  }
  invisible(x)
}

#' Tidy and glance methods for graph comparisons
#'
#' @param x a result of [mv_kg_compare()].
#' @param what `"summary"` (the default), `"items"`, `"concepts"` or
#'   `"prerequisites"` for `tidy()`.
#' @param ... unused.
#' @return A tibble.
#' @name tidy_mv_kg_compare
#' @export
tidy.mv_kg_compare <- function(x, what = c("summary", "items", "concepts", "prerequisites"), ...) {
  what <- match.arg(what)
  x[[what]]
}

#' @rdname tidy_mv_kg_compare
#' @export
glance.mv_kg_compare <- function(x, ...) {
  s <- as.data.frame(x$summary)
  as_tbl(data.frame(match = x$match, items = nrow(x$items), items_agree = sum(x$items$agree),
                    link_precision = s$precision[1], link_recall = s$recall[1], link_f1 = s$f1[1],
                    prerequisite_precision = s$precision[2], prerequisite_recall = s$recall[2],
                    stringsAsFactors = FALSE))
}
