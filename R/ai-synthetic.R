#' Simulate respondents with a language model (experimental)
#'
#' **Experimental.** `simulate_llm_respondents()` asks a language model to
#' answer multiple-choice items as each of a list of described respondents
#' ("personas") would, and scores the answers. Some researchers use such
#' "synthetic respondents" or "silicon samples" to try out items before a
#' field test. Whether their answers behave like real test takers' answers
#' is an open question, and the evidence so far is mixed: Language models
#' tend to find items too easy, to answer more consistently than people, and
#' to act out stereotypes of the groups they are asked to play. Treat the
#' results as a hypothesis about the items, never as a replacement for
#' responses from real people, and always check them against real data with
#' [compare_synthetic()].
#'
#' Each persona is one request, which lists every item. The model is asked to
#' answer as the persona would, mistakes included, and to give one option
#' letter per item.
#'
#' The function and its output may change in later versions of mirtverse.
#'
#' @param items a data frame with one row per multiple-choice item, such as
#'   [itemtext].
#' @param personas the respondents to simulate: A character vector of
#'   descriptions ("A Grade 7 student who struggles with fractions"), or a
#'   data frame with a `persona` column and any other columns that describe
#'   them (kept in the output).
#' @param stem,key,id names of the columns with the stem, the letter of the
#'   keyed option and the item id.
#' @param options names of the option columns; by default the columns `A`
#'   to `E` that exist.
#' @param provider,model the language model, as in [mv_ask()]. By default the
#'   one chosen with [mv_ask_setup()], or the recordings when
#'   [mv_llm_replay()] is on.
#' @return An object of class `mv_synthetic`: A list with `responses` (a data
#'   frame of scored responses, 1 correct, 0 wrong and `NA` when the model
#'   gave no usable answer, one row per persona and one column per item),
#'   `answers` (the option letters chosen), `personas` (a tibble with an `id`
#'   and the persona columns), `items` (item ids and keys), `provider` and
#'   `model`. It has `print()` and [compare_synthetic()] methods; pass
#'   `$responses` to [mirt::mirt()] like any response data.
#' @seealso [compare_synthetic()]; the book's chapter on large language
#'   models; the [AI Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.html).
#' @references Argyle, L. P., Busby, E. C., Fulda, N., Gubler, J. R.,
#'   Rytting, C., & Wingate, D. (2023). Out of one, many: Using language
#'   models to simulate human samples. *Political Analysis, 31*(3), 337-351.
#' @examples
#' \donttest{
#' if (requireNamespace("ellmer", quietly = TRUE)) {
#'   old <- mv_llm_replay()        # answer from the recordings that come with mirtverse
#'   items <- itemtext[endsWith(itemtext$id, "-01"), ]
#'   personas <- c(
#'     "A Grade 7 student who struggles with mathematics.",
#'     "A Grade 7 student who struggles with mathematics and is still learning English.",
#'     "A Grade 7 student who finds fractions and decimals hard but tries every question.",
#'     "A Grade 7 student who often rushes and makes careless mistakes.",
#'     "A Grade 7 student who is about average in mathematics.",
#'     "A Grade 7 student who is about average in mathematics and is still learning English.",
#'     "A Grade 7 student with average marks who is anxious on tests.",
#'     "A Grade 7 student who is about average in mathematics and likes word problems.",
#'     "A Grade 7 student who is strong in mathematics.",
#'     "A Grade 7 student who is strong in mathematics and is still learning English.",
#'     "A Grade 7 student in an enriched mathematics program.",
#'     "A Grade 7 student who is strong in mathematics but reads slowly.")
#'   syn <- simulate_llm_respondents(items, personas)
#'   syn
#'   compare_synthetic(syn, stats::setNames(items$p_field, items$id))
#'   options(old)
#' }
#' }
#' @export
simulate_llm_respondents <- function(items, personas, stem = "stem", options = NULL, key = "key",
                                     id = "id", provider = NULL, model = NULL) {
  items <- as.data.frame(items, stringsAsFactors = FALSE)
  for (nm in c(stem, key, id))
    if (!nm %in% names(items)) stop(sprintf("`items` has no column `%s`.", nm), call. = FALSE)
  options <- options %||% intersect(LETTERS[1:5], names(items))
  if (length(options) < 2L)
    stop("`items` needs at least two option columns (A, B, ...); name them with `options`.",
         call. = FALSE)
  miss <- setdiff(options, names(items))
  if (length(miss)) stop(sprintf("`items` has no option column `%s`.", miss[1]), call. = FALSE)
  ids <- as.character(items[[id]])
  if (anyDuplicated(ids)) stop("Item ids must be unique.", call. = FALSE)
  keys <- toupper(as.character(items[[key]]))
  letters_used <- LETTERS[seq_along(options)]
  if (!all(keys %in% letters_used))
    stop("Every key must be one of the option letters ", paste(letters_used, collapse = ", "), ".",
         call. = FALSE)

  pers <- if (is.data.frame(personas)) as.data.frame(personas, stringsAsFactors = FALSE) else
    data.frame(persona = as.character(personas), stringsAsFactors = FALSE)
  if (!"persona" %in% names(pers)) stop("`personas` needs a `persona` column.", call. = FALSE)
  pers$persona <- as.character(pers$persona)
  if (!nrow(pers) || any(is.na(pers$persona) | !nzchar(trimws(pers$persona))))
    stop("Give at least one persona, and no empty ones.", call. = FALSE)
  pers <- cbind(id = sprintf("R%03d", seq_len(nrow(pers))), pers, stringsAsFactors = FALSE)

  provider <- ask_provider(provider)
  if (provider == "rules")
    stop("Simulating respondents needs a language model; run mv_ask_setup() to choose one, ",
         "or mv_llm_replay() for the recorded examples.", call. = FALSE)
  model <- ask_model(provider, model)
  block <- vapply(seq_along(ids), function(i) paste(c(
    sprintf("[%s] %s", ids[i], items[[stem]][i]),
    sprintf("%s. %s", letters_used, vapply(options, function(o) as.character(items[[o]][i]), ""))),
    collapse = "\n"), "")
  type <- ellmer::type_object(answers = ellmer::type_array(ellmer::type_object(
    item = ellmer::type_string("The item id in square brackets."),
    answer = ellmer::type_string("The letter of the option this respondent would choose."))))

  ans <- matrix(NA_character_, nrow(pers), length(ids), dimnames = list(pers$id, ids))
  for (r in seq_len(nrow(pers))) {
    chat <- make_chat(provider, model, synthetic_system_prompt())
    res <- chat$chat_structured(paste0("Respondent: ", pers$persona[r], "\n\n",
                                       "Answer every item as this respondent would.\n\n",
                                       paste(block, collapse = "\n\n")),
                                type = type, echo = "none")
    a <- res$answers
    if (is.data.frame(a) && all(c("item", "answer") %in% names(a))) {
      it <- gsub("^\\[|\\]$", "", trimws(as.character(a$item)))
      letter <- toupper(substr(trimws(as.character(a$answer)), 1, 1))
      ok <- it %in% ids & letter %in% letters_used
      ans[r, it[ok]] <- letter[ok]
    }
  }
  scored <- as.data.frame(ifelse(is.na(ans), NA_integer_,
                                 1L * sweep(ans, 2, keys, `==`)), stringsAsFactors = FALSE)
  names(scored) <- ids
  rownames(scored) <- NULL
  if (anyNA(ans))
    warning(sum(is.na(ans)), " answer(s) were missing or not an option letter; they are NA.",
            call. = FALSE)
  structure(list(responses = scored, answers = as.data.frame(ans, stringsAsFactors = FALSE),
                 personas = as_tbl(pers), items = as_tbl(data.frame(item = ids, key = keys)),
                 provider = provider, model = model %||% ""),
            class = "mv_synthetic")
}

synthetic_system_prompt <- function() paste(
  "You are simulating how a particular test taker would answer multiple-choice items.",
  "You are given a description of the respondent and a set of items.",
  "Answer each item as that respondent would on a real test, including the mistakes they would plausibly make; do not simply give the correct answers.",
  "Give exactly one option letter for every item.",
  sep = "\n")

#' @export
print.mv_synthetic <- function(x, ...) {
  r <- x$responses
  pat <- apply(r, 1, paste, collapse = "")
  cat(sprintf("<mv_synthetic> %d simulated respondents, %d items (EXPERIMENTAL)\n",
              nrow(r), ncol(r)))
  cat(sprintf("Mean proportion correct %.2f; %d distinct response patterns; model: %s\n",
              mean(as.matrix(r), na.rm = TRUE), length(unique(pat)),
              if (nzchar(x$model)) paste(x$provider, x$model) else x$provider))
  cat(strwrap(paste("These answers come from a language model, not from people. Check them",
                    "against real responses with compare_synthetic() before drawing any",
                    "conclusion about the items."), prefix = "  "), sep = "\n")
  invisible(x)
}

#' Compare simulated respondents with real ones (experimental)
#'
#' **Experimental.** Checks whether the respondents simulated with
#' [simulate_llm_respondents()] answer like real test takers. With a vector
#' of real proportions correct, it compares the items' difficulty. With real
#' responses, it also compares the spread of total scores and how well each
#' item separates high and low scorers (item-total correlations). For the
#' simulated answers alone it counts the distinct response patterns: Real
#' respondents rarely give identical answers, while language models playing
#' similar personas often do.
#'
#' @param synthetic an `mv_synthetic` object.
#' @param real the real data: A data frame or matrix of 0/1 responses with
#'   the items as columns (named as in `synthetic`), or a named numeric
#'   vector of proportions correct.
#' @param tolerance the difference in mean proportion correct, and in the
#'   correlation of item difficulties below 1, that the notes treat as
#'   meaningful.
#' @return An object of class `mv_synthetic_comparison`: A list with `items`
#'   (a tibble with `item`, `p_real`, `p_synthetic` and `difference`, plus
#'   `rit_real` and `rit_synthetic` with real responses), `summary` (a one-row
#'   tibble) and `notes` (what the comparison shows, in sentences). It has
#'   `print()` and `autoplot()` methods.
#' @seealso [simulate_llm_respondents()]
#' @examples
#' # a small made-up example: synthetic answers that are too easy
#' syn <- structure(list(
#'   responses = data.frame(I1 = c(1, 1, 1, 1), I2 = c(1, 1, 1, 0), I3 = c(1, 1, 0, 0)),
#'   provider = "example", model = ""), class = "mv_synthetic")
#' compare_synthetic(syn, c(I1 = 0.7, I2 = 0.5, I3 = 0.3))
#' @export
compare_synthetic <- function(synthetic, real, tolerance = 0.1) {
  if (!inherits(synthetic, "mv_synthetic"))
    stop("`synthetic` must come from simulate_llm_respondents().", call. = FALSE)
  syn <- as.data.frame(synthetic$responses)
  responses <- !is.null(dim(real))
  if (responses) {
    real <- as.data.frame(real)
    common <- intersect(names(syn), names(real))
    p_real <- colMeans(real[common], na.rm = TRUE)
  } else {
    if (!is.numeric(real) || is.null(names(real)))
      stop("`real` must be response data or a named vector of proportions correct.", call. = FALSE)
    common <- intersect(names(syn), names(real))
    p_real <- real[common]
  }
  if (length(common) < 3L)
    stop("`synthetic` and `real` share ", length(common), " item(s); at least 3 are needed. ",
         "Check that the item names match.", call. = FALSE)
  p_syn <- colMeans(syn[common], na.rm = TRUE)
  tab <- data.frame(item = common, p_real = unname(p_real), p_synthetic = unname(p_syn),
                    difference = unname(p_syn - p_real), stringsAsFactors = FALSE)
  rit <- function(d) vapply(common, function(j) {
    rest <- rowSums(d[setdiff(common, j)], na.rm = TRUE)
    v <- d[[j]]
    if (stats::sd(v, na.rm = TRUE) %in% c(0, NA) || stats::sd(rest) == 0) NA_real_ else
      suppressWarnings(stats::cor(v, rest, use = "complete.obs"))
  }, numeric(1))
  if (responses) {
    tab$rit_real <- unname(rit(real))
    tab$rit_synthetic <- unname(rit(syn))
  }
  pat <- apply(syn[common], 1, paste, collapse = "")
  cor_or_na <- function(x, y, method) if (stats::sd(x) > 0 && stats::sd(y) > 0)
    stats::cor(x, y, method = method) else NA_real_
  s <- data.frame(
    n_synthetic = nrow(syn), n_items = length(common),
    mean_p_real = mean(p_real), mean_p_synthetic = mean(p_syn),
    r_p = cor_or_na(p_real, p_syn, "pearson"), rho_p = cor_or_na(p_real, p_syn, "spearman"),
    distinct_patterns = length(unique(pat)),
    sd_total_real = if (responses) stats::sd(rowSums(real[common], na.rm = TRUE)) else NA_real_,
    sd_total_synthetic = stats::sd(rowSums(syn[common], na.rm = TRUE)),
    mean_rit_real = if (responses) mean(tab$rit_real, na.rm = TRUE) else NA_real_,
    mean_rit_synthetic = if (responses) mean(tab$rit_synthetic, na.rm = TRUE) else NA_real_)

  notes <- character()
  d <- s$mean_p_synthetic - s$mean_p_real
  notes <- c(notes, if (abs(d) > tolerance)
    sprintf("The simulated respondents find the items %s than real test takers: Mean proportion correct %.2f against %.2f.",
            if (d > 0) "easier" else "harder", s$mean_p_synthetic, s$mean_p_real) else
    sprintf("Mean proportion correct is close: %.2f simulated against %.2f real.",
            s$mean_p_synthetic, s$mean_p_real))
  notes <- c(notes, if (is.na(s$rho_p))
    "The items' difficulty cannot be compared, because every item has the same proportion correct in one of the two sets." else
    if (s$rho_p < 1 - 3 * tolerance)
      sprintf("They order the items by difficulty only loosely like real test takers do (Spearman correlation %.2f), so they cannot stand in for a field test of difficulty.", s$rho_p) else
      sprintf("They order the items by difficulty much like real test takers (Spearman correlation %.2f); this still says nothing about any single new item.", s$rho_p))
  if (s$distinct_patterns < 0.8 * s$n_synthetic)
    notes <- c(notes, sprintf("Their answers vary little: %d distinct response patterns among %d simulated respondents. Respondents described alike answer alike.",
                              s$distinct_patterns, s$n_synthetic))
  if (responses && !is.na(s$mean_rit_synthetic) && !is.na(s$mean_rit_real) &&
      s$mean_rit_synthetic > s$mean_rit_real + tolerance)
    notes <- c(notes, sprintf("Their answers are more consistent than people's (mean item-total correlation %.2f against %.2f), which would overstate reliability.",
                              s$mean_rit_synthetic, s$mean_rit_real))
  notes <- c(notes, paste("Simulated respondents are experimental: Use them to find unclear",
                          "items or to plan a study, not to estimate item parameters or to",
                          "replace a field test."))
  structure(list(items = as_tbl(tab), summary = as_tbl(s), notes = notes),
            class = "mv_synthetic_comparison")
}

#' @export
print.mv_synthetic_comparison <- function(x, ...) {
  s <- x$summary
  cat(sprintf("<mv_synthetic_comparison> %d simulated respondents, %d items (EXPERIMENTAL)\n",
              s$n_synthetic, s$n_items))
  tab <- as.data.frame(x$items)
  num <- vapply(tab, is.numeric, logical(1))
  tab[num] <- lapply(tab[num], round, 2)
  print(tab, row.names = FALSE)
  cat("\n")
  for (n in x$notes) cat(strwrap(n, initial = "* ", prefix = "  "), sep = "\n")
  invisible(x)
}

#' @export
autoplot.mv_synthetic_comparison <- function(object, ...) {
  d <- as.data.frame(object$items)
  ggplot2::ggplot(d, ggplot2::aes(x = p_real, y = p_synthetic)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey50") +
    ggplot2::geom_point(colour = "#2c7fb8", size = 2.5) +
    ggplot2::geom_text(ggplot2::aes(label = item), vjust = -0.8, size = 3) +
    ggplot2::coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
    ggplot2::labs(x = "Proportion correct, real test takers",
                  y = "Proportion correct, simulated respondents",
                  title = "Simulated against real item difficulty (experimental)",
                  subtitle = "Points above the dashed line are easier for the simulated respondents") +
    ggplot2::theme_minimal()
}
