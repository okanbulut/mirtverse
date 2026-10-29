# Benchmark for mv_ask() request parsing: a fixed set of plain-language
# requests (inst/benchmark/ask-requests.csv) with the plan each should give.
# Run it with mirtverse:::ask_benchmark(provider = "claude"), etc.; see
# inst/benchmark/run-benchmark.R.

bench_data <- function(n = 600) {
  set.seed(2026)
  a <- matrix(stats::rlnorm(12, 0.2, 0.25))
  d <- matrix(stats::rnorm(12))
  x <- as.data.frame(mirt::simdata(a, d, n, itemtype = "2PL"))
  names(x) <- paste0("Q", 1:12)
  rt <- as.data.frame(matrix(round(stats::rlnorm(n * 12, 3, 0.5), 1), n, 12,
                             dimnames = list(NULL, paste0("time_Q", 1:12))))
  data.frame(student_id = seq_len(n), x,
             gender = rep(c("F", "M"), length.out = n),
             language = rep(c("EN", "FR"), each = n / 2),
             grade = rep(4:6, length.out = n), rt)
}

ask_benchmark <- function(provider = "none", model = NULL, anonymize = FALSE,
                          requests = NULL, verbose = TRUE) {
  if (is.null(requests))
    requests <- utils::read.csv(system.file("benchmark", "ask-requests.csv", package = "mirtverse"),
                                stringsAsFactors = FALSE, na.strings = character())
  data <- bench_data()
  prof <- profile_data(data)
  all_items <- prof$column[prof$role == "item"]
  rows <- lapply(seq_len(nrow(requests)), function(i) {
    r <- requests[i, ]
    msgs <- character()
    res <- tryCatch(withCallingHandlers(
                      mv_ask(r$request, data = data, provider = provider, model = model,
                             anonymize = anonymize, ask = FALSE),
                      message = function(m) {
                        msgs <<- c(msgs, conditionMessage(m))
                        invokeRestart("muffleMessage")
                      }),
                    error = function(e) e)
    fallback <- grep("could not be reached", msgs, value = TRUE)[1]
    asked <- inherits(res, "error") && grepl("needs more information|unsure|cannot be run",
                                              conditionMessage(res))
    if (!inherits(res, "error") && any(grepl("unsure", res$plan$notes))) asked <- TRUE
    out <- data.frame(id = r$id, request = r$request, question = asked == as.logical(r$question),
                      model = NA, nfact = NA, group = NA, missing = NA, items = NA, steps = NA,
                      error = if (inherits(res, "error")) conditionMessage(res) else "",
                      fallback = if (is.na(fallback)) "" else trimws(fallback),
                      stringsAsFactors = FALSE)
    if (as.logical(r$question) || inherits(res, "error")) return(out)
    p <- res$plan
    want_steps <- if (nzchar(r$steps)) strsplit(r$steps, ";")[[1]] else character()
    allowed <- c(want_steps, "describe", "fitcheck", "interpret")
    want_items <- if (nzchar(r$items)) expand_ranges(r$items, prof$column) else all_items
    want_missing <- if (nzchar(r$missing)) as.numeric(strsplit(r$missing, ";")[[1]]) else numeric()
    out$model <- identical(p$model, r$model)
    out$nfact <- p$nfact == r$nfact
    out$group <- identical(p$group %||% "", r$group)
    out$missing <- setequal(p$missing %||% numeric(), want_missing)
    out$items <- setequal(p$items, want_items)
    out$steps <- all(want_steps %in% p$steps) && all(p$steps %in% allowed)
    out
  })
  tab <- do.call(rbind, rows)
  fields <- c("question", "model", "nfact", "group", "missing", "items", "steps")
  tab$correct <- apply(tab[, fields], 1, function(v) all(as.logical(v), na.rm = TRUE)) &
    !nzchar(tab$fallback)
  acc <- vapply(fields, function(f) mean(as.logical(tab[[f]]), na.rm = TRUE), numeric(1))
  if (verbose) {
    cat(sprintf("Parser: %s; %d requests\n", provider_label(ask_provider(provider), model), nrow(tab)))
    cat(sprintf("Fully correct plans: %.0f%%\n", 100 * mean(tab$correct)))
    print(round(100 * acc))
    nfb <- sum(nzchar(tab$fallback))
    if (nfb) cat(sprintf("\n%d request%s fell back to the keyword parser and count as wrong. First reason:\n%s\n",
                         nfb, if (nfb > 1) "s" else "", tab$fallback[nzchar(tab$fallback)][1]))
  }
  invisible(structure(tab, accuracy = acc))
}
