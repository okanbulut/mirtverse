# Offline keyword parser for mv_ask(). It reads a plain-language request and
# returns the plan fields it is confident about plus the questions it could
# not answer; mv_ask() asks those questions in the console.

parse_request_rules <- function(request, profile, prev = NULL) {
  txt <- tolower(request)
  has <- function(...) any(vapply(c(...), function(p) grepl(p, txt, perl = TRUE), logical(1)))
  cols <- profile$column
  fields <- list()
  questions <- list()
  notes <- character()

  # model
  model <- if (has("\\brasch\\b", "\\b1[- ]?pl\\b", "one[- ]parameter")) "Rasch" else
    if (has("\\b2[- ]?pl\\b", "two[- ]parameter")) "2PL" else
    if (has("\\b3[- ]?pl\\b", "three[- ]parameter", "guessing")) "3PL" else
    if (has("\\bgrm\\b", "graded", "samejima")) "graded" else
    if (has("gpcm", "partial credit")) "gpcm" else
    if (has("best model", "compare (the )?models", "which model", "select (a |the )?model",
            "model selection", "choose (a |the )?model")) "auto" else NULL
  if (!is.null(model)) fields$model <- model

  num <- c(one = 1, two = 2, three = 3, `1` = 1, `2` = 2, `3` = 3)
  m <- regmatches(txt, regexpr("\\b(one|two|three|[123])[- ]?(factors?|dimensions?|dimensional)", txt))
  if (length(m)) fields$nfact <- unname(num[sub("[- ]?(factors?|dimensions?|dimensional)$", "", m)])
  else if (has("unidimensional")) fields$nfact <- 1
  else if (has("multidimensional")) {
    fields$nfact <- 2
    notes <- c(notes, "Fitted two dimensions for \"multidimensional\"; say how many if you want more.")
  }

  # items
  rng <- regmatches(request, gregexpr("[A-Za-z_.]+[0-9]+\\s*(?:-|:|to|through)\\s*[A-Za-z_.]*[0-9]+",
                                      request, perl = TRUE))[[1]]
  for (r in rng) {
    ends <- trimws(strsplit(r, "\\s*(-|:|to|through)\\s*", perl = TRUE)[[1]])
    if (length(ends) == 2 && !grepl("[A-Za-z]", ends[2]))
      ends[2] <- paste0(sub("[0-9]+$", "", ends[1]), ends[2])
    if (all(ends %in% cols)) {
      fields$items <- c(fields$items, paste(ends, collapse = ":"))
    }
  }

  # missing-value codes
  codes_re <- "(-?[0-9]+(?:\\s*(?:,|and|or|/)\\s*-?[0-9]+)*)(?![A-Za-z0-9])"
  mm <- c(regmatches(txt, regexpr(paste0(
            "missing(?:\\s+(?:values?|codes?|responses?|data))?\\s*(?:(?:are|is|=|:|coded|as|by)\\s*)*",
            codes_re), txt, perl = TRUE)),
          regmatches(txt, regexpr(paste0("(?<![A-Za-z0-9])", codes_re,
                                         "\\s+(?:as|=|means?|is|are)\\s+missing"), txt, perl = TRUE)))
  if (length(mm)) {
    codes <- as.numeric(regmatches(mm[1], gregexpr("-?[0-9]+", mm[1]))[[1]])
    if (length(codes)) fields$missing <- codes
  }

  # steps
  steps <- character()
  if (has("descri", "item stat", "classical", "ctt", "p-values?\\b", "difficult(y|ies) and discrimination"))
    steps <- c(steps, "describe")
  if (has("\\bfit (check|stat|index|indices)", "item fit", "misfit", "model fit",
          "check (the |model |item )?fit", "how well", "\\bm2\\b",
          "local dependence", "\\bq3\\b"))
    steps <- c(steps, "fitcheck")
  dif_wanted <- has("\\bdif\\b", "differential item", "item bias", "\\bbias", "fairness",
                    "measurement invariance", "invariance")
  if (dif_wanted) steps <- c(steps, "dif")
  if (has("scores?\\b(?! table)", "theta", "ability estimates", "person estimates", "\\beap\\b",
          "(?<!wright )\\bmap\\b", "\\bwle\\b"))
    steps <- c(steps, "scores")
  if (has("plot", "graph", "chart", "curve", "\\bicc", "information", "wright", "visuali"))
    steps <- c(steps, "plots")
  if (has("interpret", "explain", "summar", "plain language", "what (does|do) .* mean"))
    steps <- c(steps, "interpret")
  if (has("card")) steps <- c(steps, "cards")
  if (has("report", "html")) steps <- c(steps, "report")
  rt_wanted <- has("response times?", "\\brts?\\b", "speed", "rapid guess", "latenc")
  if (rt_wanted) steps <- c(steps, "rt")

  method <- if (has("\\bwle\\b")) "WLE" else if (has("(?<!wright )\\bmap\\b")) "MAP" else
    if (has("\\bml\\b", "maximum likelihood")) "ML" else NULL
  if (!is.null(method)) fields$options$scores$method <- method
  files <- regmatches(request, gregexpr("[A-Za-z0-9_./-]+\\.(csv|html)", request))[[1]]
  for (f in files) {
    if (grepl("\\.csv$", f)) {
      fields$options$scores$file <- f
      steps <- c(steps, "scores")
    } else {
      fields$options$report$file <- f
      steps <- c(steps, "report")
    }
  }

  removed <- character()
  for (s in c("describe", "fitcheck", "dif", "scores", "plots", "interpret", "cards", "report", "rt")) {
    word <- switch(s, describe = "descri|item stat", fitcheck = "fit", dif = "dif", scores = "score",
                   plots = "plot|graph", interpret = "interpret|summar", cards = "card",
                   report = "report", rt = "response time")
    if (grepl(sprintf("(no|without|drop|remove|skip|don'?t (need|want|include))\\s+(the |a |any )?(%s)", word),
              txt, perl = TRUE))
      removed <- c(removed, s)
  }
  steps <- setdiff(unique(steps), removed)

  # group for DIF
  if (dif_wanted) {
    mentioned <- cols[vapply(cols, function(cl)
      grepl(sprintf("(^|[^a-z0-9_])%s([^a-z0-9_]|$)", tolower(gsub("([.])", "\\\\.", cl))), txt), logical(1))]
    mentioned <- setdiff(mentioned, unlist(lapply(fields$items, expand_ranges, cols = cols)))
    cand <- mentioned[profile$role[match(mentioned, cols)] %in% c("group", "item", "other")]
    if (length(cand)) {
      fields$group <- cand[1]
    } else {
      groups <- cols[profile$role == "group"]
      if (length(groups) == 1L) {
        fields$group <- groups
        notes <- c(notes, sprintf("Tested DIF by \"%s\", the only column that looks like a grouping variable.", groups))
      } else if (is.null(prev$group)) {
        questions$group <- list(
          text = "Which column holds the groups to compare for DIF?",
          choices = if (length(groups)) groups else cols[profile$role != "item"])
      }
    }
  }

  # response-time columns
  if (rt_wanted && is.null(prev$rt)) {
    rts <- cols[profile$role == "rt"]
    if (length(rts)) fields$rt <- rts else
      questions$rt <- list(text = "The data have no columns that look like response times. Leave the response-time step out?",
                           choices = c("Yes, leave it out"))
  }

  fields$steps <- steps
  list(fields = fields, questions = questions, notes = notes, removed = removed)
}

# Combine parsed fields with an earlier plan (refinements) or the defaults
plan_from_fields <- function(parsed, prev = NULL) {
  f <- parsed$fields
  steps <- f$steps
  if (is.null(prev)) {
    if (!length(setdiff(steps, c("dif", "rt"))))
      steps <- c("describe", "fitcheck", "interpret", steps)
    args <- f[intersect(names(f), c("items", "model", "nfact", "group", "missing", "rt", "options"))]
    args$steps <- unique(steps)
    args$assumptions <- parsed$notes
    return(do.call(mv_plan, args))
  }
  args <- f[intersect(names(f), c("items", "model", "nfact", "group", "missing", "rt"))]
  args$steps <- setdiff(unique(c(prev$steps, steps)), parsed$removed)
  if ("dif" %in% parsed$removed) args["group"] <- list(NULL)
  if ("rt" %in% parsed$removed) args["rt"] <- list(NULL)
  if (!is.null(f$options)) args$options <- utils::modifyList(prev$options, f$options)
  args$assumptions <- unique(c(prev$assumptions, parsed$notes))
  do.call(update_plan, c(list(prev), args))
}

# Ask the parser's open questions in the console, or fail with them listed
resolve_questions <- function(parsed, ask = interactive()) {
  qs <- parsed$questions
  if (!length(qs)) return(parsed)
  if (!ask)
    stop("mv_ask() needs more information:\n",
         paste("*", vapply(qs, `[[`, "", "text"), collapse = "\n"),
         "\nAdd it to the request or use `plan = mv_plan(...)`.", call. = FALSE)
  for (nm in names(qs)) {
    q <- qs[[nm]]
    pick <- utils::menu(q$choices, title = q$text)
    if (nm == "group") {
      if (pick == 0) stop("No group chosen, so DIF cannot be tested.", call. = FALSE)
      parsed$fields$group <- q$choices[pick]
    } else if (nm == "rt") {
      parsed$fields$steps <- setdiff(parsed$fields$steps, "rt")
    }
  }
  parsed$questions <- list()
  parsed
}
