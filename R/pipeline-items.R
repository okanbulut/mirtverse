#' Pipeline stage: item generation
#'
#' `generate_items()` writes candidate items for the blueprint's cells with a
#' large language model through the ellmer package, using the provider set up
#' with [mv_ask_setup()] (Claude, OpenAI or a local Ollama model).
#' Multiple-choice items come with a key and a rationale for every option;
#' open-ended items come with a scoring rubric that has a descriptor and an
#' anchor response for every score point. `add_items()` adds items written by
#' people (or another generator) to the same pool, so the checks treat both
#' alike.
#'
#' With `verify = TRUE` (the default), a second, independent model call
#' answers each multiple-choice item without seeing the key and judges each
#' distractor ([verify_items()] runs this pass on its own).
#'
#' The checks (thresholds from [mv_rules()]):
#'
#' * `invalid_key` (block): a multiple-choice key that is not one of the
#'   options.
#' * `key_check` (block): the verifying pass chose another answer, or found
#'   more than one defensible answer.
#' * `rubric_incomplete` (block): an open-ended item without a descriptor and
#'   an anchor response for every score point from 0 to the maximum.
#' * `distractor` (review): a distractor the verifying pass judged
#'   implausible or partly correct.
#' * `near_duplicate` (review): two items whose wording overlaps by more than
#'   `duplicate_sim` (Jaccard similarity of their words).
#' * `coverage` (review): a blueprint cell with fewer than `coverage_ratio`
#'   times its target count of items (items are lost in review and field
#'   testing).
#' * `readability` (info): item text above the blueprint's grade level
#'   (Flesch-Kincaid grade).
#'
#' Generated items are drafts: they need human content and sensitivity review
#' before they are field-tested, and every item records its source.
#'
#' @param p a pipeline; `generate_items()` needs a blueprint from
#'   [set_blueprint()].
#' @param n number of items to write per cell and item type. Defaults to
#'   `coverage_ratio` times the cell's target count, less the items the cell
#'   already has.
#' @param cells optional cells to write for (by name, as in
#'   `p$blueprint$cells$cell`); defaults to all.
#' @param type item types to write; defaults to the blueprint's.
#' @param n_options number of options of a multiple-choice item.
#' @param instructions optional extra instructions for the item writer, such
#'   as a style guide or a reading passage.
#' @param provider,model the language model; see [mv_ask_setup()].
#' @param verify logical; run the verifying pass on multiple-choice items.
#' @param batch number of items to ask for in one call.
#' @return The pipeline with the new items in `p$items`: a tibble with one row
#'   per item (`id`, `cell`, `type`, `stem`, `options`, `key`, `rationales`,
#'   `rubric`, `max_score`, `grade`, `source`, `status` and the verification
#'   results).
#' @examples
#' \dontrun{
#' p <- set_blueprint(mv_pipeline(), c(Fractions = 4, Decimals = 4),
#'                    construct = "Grade 5 number sense", use = "diagnostic",
#'                    population = "Grade 5 students", grade_level = 5)
#' p <- generate_items(p, n = 3)
#' p$items
#' flags(p)
#' }
#' @export
generate_items <- function(p, n = NULL, cells = NULL, type = NULL, n_options = 4,
                           instructions = NULL, provider = NULL, model = NULL, verify = TRUE,
                           batch = 5) {
  check_pipeline(p)
  cl <- match.call()
  if (is.null(p$blueprint)) stop("Set a blueprint with set_blueprint() first.", call. = FALSE)
  enforce_gate(p, "generation")
  llm <- item_llm(provider, model)
  bp <- p$blueprint
  todo <- bp$cells
  if (!is.null(cells)) {
    bad <- setdiff(cells, todo$cell)
    if (length(bad)) stop("Not blueprint cells: ", paste(bad, collapse = ", "), call. = FALSE)
    todo <- todo[todo$cell %in% cells, , drop = FALSE]
  }
  todo <- todo[!is.na(todo$n) & todo$n > 0, , drop = FALSE]
  type <- match.arg(type %||% bp$item_types, c("mc", "open"), several.ok = TRUE)
  have <- function(cell, tp) if (is.null(p$items)) 0 else
    sum(p$items$cell == cell & p$items$type == tp & p$items$status != "rejected", na.rm = TRUE)

  new <- list()
  for (i in seq_len(nrow(todo))) {
    for (tp in type) {
      k <- n %||% max(0, ceiling(p$rules$coverage_ratio * todo$n[i] / length(type)) -
                        have(todo$cell[i], tp))
      while (k > 0) {
        m <- min(k, batch)
        got <- llm_generate_batch(llm, bp, todo[i, ], tp, m, n_options, instructions,
                                  existing = c(p$items$stem, unlist(lapply(new, `[[`, "stem"))))
        if (!nrow(got)) break
        new[[length(new) + 1L]] <- got
        k <- k - nrow(got)
      }
    }
  }
  if (!length(new)) stop("The model returned no items.", call. = FALSE)
  items <- do.call(rbind, new)
  items$source <- sprintf("AI: %s", provider_label(llm$provider, llm$model))
  p <- append_items(p, items, prefix = "G")
  if (verify) p <- verify_items(p, ids = utils::tail(p$items$id, nrow(items)),
                                provider = llm$provider, model = llm$model, .rerun = FALSE)
  p <- finish_generation(p, sprintf("%d items written by %s", nrow(items),
                                    provider_label(llm$provider, llm$model)))
  add_code(p, cl)
}

#' @rdname generate_items
#' @param items for `add_items()`, a data frame with one row per item and
#'   columns `stem`, `cell`, `type` (`"mc"` or `"open"`, default `"mc"`), the
#'   options either as a list column `options` or as columns `A`, `B`, `C`,
#'   ..., `key` (the letter of the correct option), and optionally `id`,
#'   `rubric` (a list column of data frames with columns `score`,
#'   `descriptor` and `anchor`) and `source` (default `"human"`).
#' @export
add_items <- function(p, items) {
  check_pipeline(p)
  cl <- match.call()
  items <- as.data.frame(items, stringsAsFactors = FALSE)
  if (!"stem" %in% names(items)) stop("`items` needs a `stem` column.", call. = FALSE)
  n <- nrow(items)
  if (!"type" %in% names(items)) items$type <- "mc"
  if (!"cell" %in% names(items)) items$cell <- NA_character_
  if (!"source" %in% names(items)) items$source <- "human"
  if (!"options" %in% names(items)) {
    letters_cols <- intersect(LETTERS, names(items))
    items$options <- lapply(seq_len(n), function(i) {
      v <- as.character(unlist(items[i, letters_cols, drop = TRUE]))
      v[!is.na(v) & nzchar(v)]
    })
    items[letters_cols] <- NULL
  }
  if (!"key" %in% names(items)) items$key <- NA_character_
  if (!"rubric" %in% names(items)) items$rubric <- rep(list(NULL), n)
  if (!"rationales" %in% names(items)) items$rationales <- rep(list(character(0)), n)
  items$type <- match.arg(items$type, c("mc", "open"), several.ok = TRUE)
  items$max_score <- vapply(seq_len(n), function(i) {
    if (items$type[i] == "mc") return(1)
    r <- items$rubric[[i]]
    if (is.null(r) || !nrow(as.data.frame(r))) NA_real_ else max(as.data.frame(r)$score)
  }, numeric(1))
  p <- append_items(p, items, prefix = "H")
  finish_generation(add_code(p, cl), sprintf("%d items added", n), event = "add items")
}

#' @rdname generate_items
#' @param ids items to verify; defaults to every multiple-choice item not yet
#'   verified.
#' @param .rerun internal.
#' @export
verify_items <- function(p, ids = NULL, provider = NULL, model = NULL, .rerun = TRUE) {
  check_pipeline(p)
  if (is.null(p$items)) stop("The pipeline has no items.", call. = FALSE)
  llm <- item_llm(provider, model)
  it <- p$items
  ids <- ids %||% it$id[it$type == "mc" & is.na(it$key_check)]
  for (id in ids) {
    j <- match(id, it$id)
    if (it$type[j] != "mc" || !length(it$options[[j]])) next
    v <- llm_verify_item(llm, it$stem[j], it$options[[j]])
    letters_j <- LETTERS[seq_along(it$options[[j]])]
    defensible <- intersect(toupper(as.character(unlist(v$defensible))), letters_j)
    it$verify_answer[j] <- toupper(as.character(v$answer %||% NA))
    it$key_check[j] <- if (identical(it$verify_answer[j], it$key[j]) && length(defensible) <= 1L)
      "agree" else "disagree"
    d <- v$distractors
    if (!is.data.frame(d)) d <- if (length(d)) do.call(rbind, lapply(d, as.data.frame))
    issues <- character(0)
    if (!is.null(d) && nrow(d)) {
      d$option <- toupper(as.character(d$option))
      bad <- d$option != it$key[j] & d$option %in% letters_j &
        (!as.logical(d$plausible) | as.logical(d$partly_correct))
      issues <- sprintf("%s (%s)", d$option[bad],
                        ifelse(as.logical(d$partly_correct[bad]), "partly correct", "implausible"))
    }
    it$weak_distractors[j] <- paste(issues, collapse = ", ")
    it$verify_note[j] <- as.character(v$note %||% "")
    if (length(defensible) > 1L)
      it$verify_note[j] <- trimws(paste(it$verify_note[j],
                                        sprintf("Defensible answers: %s.", paste(defensible, collapse = ", "))))
  }
  p$items <- it
  if (.rerun) {
    p <- finish_generation(p, sprintf("%d items verified", length(ids)), event = "verify items")
    p <- add_code(p, match.call())
  }
  p
}

# ---- Item pool --------------------------------------------------------------

item_columns <- c("id", "cell", "type", "stem", "options", "key", "rationales", "rubric",
                  "max_score", "grade", "source", "status", "key_check", "verify_answer",
                  "weak_distractors", "verify_note", "ai_screen")

append_items <- function(p, items, prefix) {
  n <- nrow(items)
  start <- if (is.null(p$items)) 0L else nrow(p$items)
  if (!"id" %in% names(items) || anyNA(items$id))
    items$id <- sprintf("%s%03d", prefix, start + seq_len(n))
  items$id <- as.character(items$id)
  if (!is.null(p$items) && any(items$id %in% p$items$id))
    stop("Item ids already in the pool: ",
         paste(intersect(items$id, p$items$id), collapse = ", "), call. = FALSE)
  items$key <- toupper(as.character(items$key))
  items$grade <- vapply(items$stem, fk_grade, numeric(1), USE.NAMES = FALSE)
  items$status <- "draft"
  for (nm in c("key_check", "verify_answer", "weak_distractors", "verify_note", "ai_screen"))
    if (!nm %in% names(items)) items[[nm]] <- NA_character_
  items <- as_tbl(items[, item_columns])
  p$items <- if (is.null(p$items)) items else rbind(p$items, items)
  p
}

finish_generation <- function(p, summary, event = "generate items") {
  p <- set_stage_flags(p, "generation", item_checks(p))
  n <- sum(p$items$status != "rejected")
  p <- set_stage(p, "generation", "done", sprintf("%d items in the pool", n))
  for (s in c("review", "field_test")) p <- stage_rerun(p, s)
  p <- log_event(p, event, summary)
  report_stage_flags(p, "generation")
  p
}

item_checks <- function(p) {
  it <- p$items[p$items$status != "rejected", , drop = FALSE]
  r <- p$rules
  out <- list()
  add <- function(...) out[[length(out) + 1L]] <<- new_flag("generation", ...)
  mc <- it$type == "mc"
  nopt <- lengths(it$options)
  kpos <- match(it$key, LETTERS)
  bad_key <- mc & (is.na(kpos) | kpos > nopt)
  add("invalid_key", it$id[bad_key], sprintf("key %s, %d options", it$key[bad_key], nopt[bad_key]),
      "the key must be one of the options", "block",
      "Fix the key or the options before review.")
  dis <- mc & !is.na(it$key_check) & it$key_check == "disagree"
  add("key_check", it$id[dis],
      sprintf("key %s, verifier chose %s%s", it$key[dis], it$verify_answer[dis],
              ifelse(nzchar(it$verify_note[dis] %||% ""), paste0("; ", it$verify_note[dis]), "")),
      "an independent answer must match the key, with one defensible answer", "block",
      "Check the key and make sure exactly one option is correct; revise or drop the item.")
  open <- it$type == "open"
  incomplete <- vapply(which(open), function(i) !rubric_complete(it$rubric[[i]]), logical(1))
  add("rubric_incomplete", it$id[open][incomplete], "missing score points, descriptors or anchors",
      "a descriptor and an anchor response for every score point", "block",
      "Complete the rubric so raters (human or automated) can score consistently.")
  weak <- mc & !is.na(it$weak_distractors) & nzchar(it$weak_distractors)
  add("distractor", it$id[weak], it$weak_distractors[weak],
      "every distractor plausible and clearly wrong", "review",
      "Rewrite the distractor so it reflects a real misconception and is clearly incorrect.")
  pairs <- near_duplicates(it, r$duplicate_sim)
  add("near_duplicate", if (nrow(pairs)) paste(pairs$a, pairs$b, sep = " & ") else character(0),
      sprintf("similarity = %.2f", pairs$sim), sprintf("similarity <= %s", r$duplicate_sim),
      "review", "Keep one of the two items, or make them clearly different.")
  if (!is.null(p$blueprint)) {
    cells <- p$blueprint$cells
    cells <- cells[!is.na(cells$n) & cells$n > 0, , drop = FALSE]
    have <- as.integer(table(factor(it$cell, levels = cells$cell)))
    need <- ceiling(r$coverage_ratio * cells$n)
    low <- have < need
    add("coverage", cells$cell[low], sprintf("%d items for a target of %d", have[low], cells$n[low]),
        sprintf("at least %s times the target", r$coverage_ratio), "review",
        "Write more items for this cell; items are lost in review and field testing.")
    off <- !is.na(it$cell) & !it$cell %in% p$blueprint$cells$cell
    add("off_blueprint", it$id[off], sprintf("cell \"%s\"", it$cell[off]),
        "every item belongs to a blueprint cell", "review",
        "Assign the item to a blueprint cell or drop it.")
    gl <- p$blueprint$grade_level
    if (!is.null(gl)) {
      hard <- !is.na(it$grade) & it$grade > gl
      add("readability", it$id[hard], sprintf("grade %.1f", it$grade[hard]),
          sprintf("reading grade <= %s", gl), "info",
          "Simplify the wording so reading does not get in the way of the construct.")
    }
  }
  bind_flags(out)
}

rubric_complete <- function(r) {
  if (is.null(r)) return(FALSE)
  r <- as.data.frame(r, stringsAsFactors = FALSE)
  if (!nrow(r) || !all(c("score", "descriptor", "anchor") %in% names(r))) return(FALSE)
  sc <- suppressWarnings(as.numeric(r$score))
  if (anyNA(sc) || !setequal(sc, 0:max(sc)) || max(sc) < 1) return(FALSE)
  all(!is.na(r$descriptor) & nzchar(trimws(r$descriptor))) &&
    all(!is.na(r$anchor) & nzchar(trimws(r$anchor)))
}

item_words <- function(x) {
  w <- strsplit(tolower(gsub("[^[:alnum:] ]", " ", x)), "\\s+")
  lapply(w, function(v) unique(v[nzchar(v)]))
}

near_duplicates <- function(it, threshold) {
  empty <- data.frame(a = character(0), b = character(0), sim = numeric(0))
  if (nrow(it) < 2L) return(empty)
  txt <- vapply(seq_len(nrow(it)), function(i)
    paste(c(it$stem[i], it$options[[i]]), collapse = " "), character(1))
  w <- item_words(txt)
  out <- list()
  for (i in seq_len(nrow(it) - 1L)) for (j in (i + 1L):nrow(it)) {
    u <- length(union(w[[i]], w[[j]]))
    s <- if (u) length(intersect(w[[i]], w[[j]])) / u else 0
    if (s > threshold) out[[length(out) + 1L]] <- data.frame(a = it$id[i], b = it$id[j], sim = s)
  }
  if (length(out)) do.call(rbind, out) else empty
}

# Flesch-Kincaid grade level, with syllables counted as vowel groups
fk_grade <- function(text) {
  sentences <- max(1L, length(regmatches(text, gregexpr("[.!?]+", text))[[1]]))
  words <- unlist(strsplit(gsub("[^A-Za-z' ]", " ", text), "\\s+"))
  words <- words[nzchar(words)]
  if (!length(words)) return(NA_real_)
  syl <- vapply(tolower(words), function(w) {
    w <- sub("e$", "", w)
    max(1L, length(gregexpr("[aeiouy]+", w)[[1]][gregexpr("[aeiouy]+", w)[[1]] > 0]))
  }, numeric(1))
  0.39 * length(words) / sentences + 11.8 * sum(syl) / length(words) - 15.59
}

# ---- Language model calls ---------------------------------------------------

item_llm <- function(provider, model) {
  provider <- ask_provider(provider)
  if (provider == "rules")
    stop("Item generation needs a language model; run mv_ask_setup() to choose one ",
         "(Claude, OpenAI or a local Ollama model).", call. = FALSE)
  list(provider = provider, model = ask_model(provider, model))
}

item_writer_prompt <- function() paste(
  "You are an experienced assessment developer writing items for a test.",
  "Write original items that measure the stated construct and content cell, at the stated cognitive level, for the stated population.",
  "Follow item-writing guidelines: one clear problem per stem; no clues to the answer; no 'all of the above' or 'none of the above'; options of similar length and form; exactly one correct option; distractors that reflect real misconceptions; fair, accessible and free of cultural, gender or regional bias.",
  "For open-ended items, write a rubric with a descriptor and a short anchor response for every score point from 0 to the maximum.",
  "Do not repeat items you are shown as existing.",
  sep = "\n")

item_type_spec <- function(tp, n_options) {
  if (tp == "mc") {
    ellmer::type_object(
      stem = ellmer::type_string("The question or prompt."),
      options = ellmer::type_array(ellmer::type_string(),
                                   sprintf("Exactly %d answer options, without letters.", n_options)),
      key = ellmer::type_string("Letter of the correct option (A for the first)."),
      rationales = ellmer::type_array(ellmer::type_string(),
                                      "One rationale per option, in order: why it is correct, or the misconception it reflects."))
  } else {
    ellmer::type_object(
      stem = ellmer::type_string("The open-ended task or question."),
      max_score = ellmer::type_integer("Maximum score (1 to 4)."),
      rubric = ellmer::type_array(ellmer::type_object(
        score = ellmer::type_integer("Score point, from 0 to the maximum."),
        descriptor = ellmer::type_string("What a response at this score point shows."),
        anchor = ellmer::type_string("A short example response at this score point.")),
        "One entry per score point, from 0 to the maximum."))
  }
}

item_request <- function(bp, cell, tp, m, n_options, instructions, existing) {
  paste(c(
    sprintf("Construct: %s", bp$construct %||% "not stated"),
    sprintf("Test takers: %s", bp$population %||% "not stated"),
    sprintf("Score use: %s", bp$use %||% "not stated"),
    if (!is.null(bp$grade_level)) sprintf("Reading level: at or below grade %s.", bp$grade_level),
    sprintf("Content: %s", cell$content),
    if (!is.na(cell$cognitive)) sprintf("Cognitive level: %s", cell$cognitive),
    sprintf("Write %d %s item(s).", m,
            if (tp == "mc") sprintf("multiple-choice (%d options)", n_options) else "open-ended"),
    if (!is.null(instructions)) c("", "Further instructions:", instructions),
    if (length(existing)) c("", "Existing items (do not repeat):",
                            paste("-", utils::tail(existing, 30L)))),
    collapse = "\n")
}

llm_generate_batch <- function(llm, bp, cell, tp, m, n_options, instructions, existing) {
  chat <- make_chat(llm$provider, llm$model, item_writer_prompt())
  res <- chat$chat_structured(item_request(bp, cell, tp, m, n_options, instructions, existing),
                              type = ellmer::type_object(
                                items = ellmer::type_array(item_type_spec(tp, n_options))),
                              echo = "none")
  items_from_llm(res$items, cell$cell, tp)
}

# turn the model's answer (a data frame or a list of items) into item rows
items_from_llm <- function(x, cell, tp) {
  if (is.data.frame(x)) x <- lapply(seq_len(nrow(x)), function(i) as.list(x[i, , drop = FALSE]))
  if (!length(x)) return(data.frame())
  rows <- lapply(x, function(it) {
    unl <- function(v) as.character(unlist(v))
    rub <- if (tp == "open") {
      r <- it$rubric
      if (is.list(r) && !is.data.frame(r) && length(r) == 1L && is.data.frame(r[[1]])) r <- r[[1]]
      if (!is.data.frame(r)) r <- do.call(rbind, lapply(r, as.data.frame))
      r
    }
    row <- data.frame(cell = cell, type = tp, stem = unl(it$stem)[1],
                      key = if (tp == "mc") toupper(unl(it$key)[1]) else NA_character_,
                      max_score = if (tp == "mc") 1 else as.numeric(unl(it$max_score)[1]),
                      source = NA_character_, stringsAsFactors = FALSE)
    row$options <- list(if (tp == "mc") unl(it$options) else character(0))
    row$rationales <- list(if (tp == "mc") unl(it$rationales) else character(0))
    row$rubric <- list(rub)
    row
  })
  do.call(rbind, rows)
}

llm_verify_item <- function(llm, stem, options) {
  chat <- make_chat(llm$provider, llm$model, paste(
    "You are a careful subject-matter expert checking a multiple-choice test item.",
    "Answer it yourself, then judge every option. Be strict: an option is defensible if a knowledgeable test taker could argue it is correct."))
  q <- paste(c(stem, sprintf("%s. %s", LETTERS[seq_along(options)], options)), collapse = "\n")
  chat$chat_structured(q, type = ellmer::type_object(
    answer = ellmer::type_string("Letter of the best answer."),
    defensible = ellmer::type_array(ellmer::type_string(), "Letters of every option that could be defended as correct."),
    distractors = ellmer::type_array(ellmer::type_object(
      option = ellmer::type_string("Option letter."),
      plausible = ellmer::type_boolean("Would a test taker with the misconception choose it?"),
      partly_correct = ellmer::type_boolean("Is it partly correct?"))),
    note = ellmer::type_string("One sentence on any problem with the item, or empty.", required = FALSE)),
    echo = "none")
}
