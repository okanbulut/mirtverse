# Builds inst/replay/examples.json, the example recordings that
# mv_llm_replay() plays back by default.
#
# The responses are written here by hand, in the form a language model
# returns them, so that the examples run offline and give the same result
# every time. They are not output from a live model. Planted on purpose, for
# mirtverse's checks to catch:
#   * generated item 3 (fencing) is keyed A (the area, 84 m) although the
#     answer is B (the perimeter, 38 m); the verifying pass answers B
#   * generated item 4 (millilitres) has an implausible distractor
#     ("2.5 cm", a length, not a volume)
#   * the rater model scores two ELL answers with grammar slips one point
#     below the rubric, and is unsure about very short answers
#
# The calls are in inst/replay/examples.R. To rebuild, install the package
# from source first, then run from the package root:
# source("data-raw/replay.R")

library(mirtverse)
ns <- asNamespace("mirtverse")
out <- file.path("inst", "replay", "examples.json")
if (file.exists(out)) file.remove(out)

# ---- the authored answers -----------------------------------------------------

plan_answer <- list(
  items = list(), model = "graded", nfact = 1L,
  steps = list("describe", "fitcheck", "plots", "interpret"),
  assumptions = list("All four columns (Comfort, Work, Future, Benefit) are items scored 1 to 4.",
                     "No grouping column was mentioned, so no DIF analysis is included."),
  questions = list())

gen_items <- list(
  "Ratios and rates" = list(
    list(stem = "A recipe uses 3 cups of flour for every 2 cups of milk. How many cups of flour are needed with 8 cups of milk?",
         options = list("12 cups", "9 cups", "16 cups", "5 cups"), key = "A",
         rationales = list("Correct: 8 cups of milk is 4 times 2 cups, so 4 times 3 cups of flour is 12 cups.",
                           "Adds 1 to 8, treating the ratio as a difference of 1 cup.",
                           "Doubles 8, using 2 as the multiplier instead of 3/2.",
                           "Subtracts the ratio terms from 8 instead of scaling.")),
    list(stem = "A cyclist rides 45 km in 3 hours at a steady speed. How far does the cyclist ride in 5 hours at the same speed?",
         options = list("15 km", "135 km", "75 km", "50 km"), key = "C",
         rationales = list("Gives the speed per hour, not the distance in 5 hours.",
                           "Multiplies 45 by 3 instead of finding the rate first.",
                           "Correct: 45 / 3 = 15 km per hour, and 15 x 5 = 75 km.",
                           "Adds 5 to 45, treating the extra time as extra kilometres."))),
  "Measurement" = list(
    list(stem = "A garden is 12 m long and 7 m wide. How many metres of fencing are needed to go all the way around it?",
         options = list("84 m", "38 m", "19 m", "24 m"), key = "A",
         rationales = list("Correct: the fence covers the garden, 12 x 7 = 84.",
                           "Adds all four sides but is not the area.",
                           "Adds only one length and one width.",
                           "Doubles the length only.")),
    list(stem = "A water bottle holds 2.5 litres. How many millilitres does it hold?",
         options = list("250 mL", "2,500 mL", "25,000 mL", "2.5 cm"), key = "B",
         rationales = list("Multiplies by 100 instead of 1,000.",
                           "Correct: 1 litre is 1,000 mL, so 2.5 litres is 2,500 mL.",
                           "Multiplies by 10,000 instead of 1,000.",
                           "Confuses the unit of volume with a unit of length."))))

verify_answer <- function(stem) {
  ok <- function(ans, notes = "") list(answer = ans, defensible = list(ans),
    distractors = lapply(setdiff(LETTERS[1:4], ans), function(o)
      list(option = o, plausible = TRUE, partly_correct = FALSE)), note = notes)
  if (grepl("^A recipe", stem)) return(ok("A"))
  if (grepl("^A cyclist", stem)) return(ok("C"))
  if (grepl("^A garden", stem))
    return(modifyList(ok("B"), list(note = paste(
      "Fencing around the garden is the perimeter, 2 x (12 + 7) = 38 m (option B);",
      "84 m is the area, so the key appears to be wrong."))))
  if (grepl("^A water bottle", stem)) {
    v <- ok("B")
    v$distractors[[3]]$plausible <- FALSE
    v$note <- "Option D gives a length (cm), which no test taker would choose for a volume."
    return(v)
  }
  stop("No authored verification for: ", stem)
}

# rubric scoring for E1: one point per key idea found, with planted slips
idea_patterns <- c(density = "dens", structure = "molecul|crystal|pattern|lattice|hydrogen",
                   volume = "volume|more space|takes? more space|bigger|expand",
                   floats = "buoy|push|float")
idea_names <- c(density = "ice is less dense than water",
                structure = "molecules form an open structure",
                volume = "the same mass takes more volume",
                floats = "less dense things float")
score_answer <- function(texts) {
  e1 <- essays[essays$prompt == "E1", ]
  grp <- as.character(e1$group[match(texts, e1$response)])
  slips <- 0L
  lapply(seq_along(texts), function(k) {
    x <- tolower(texts[k])
    off <- lengths(strsplit(x, "\\s+")) < 4 && !grepl("dens|float", x)
    found <- vapply(idea_patterns, grepl, NA, x = x)
    # "Ice floats because it has air in it" mentions floating without the reason
    if (grepl("air in it|is cold|is solid", x) && sum(found) == 1L) found[] <- FALSE
    s <- sum(found)
    slip <- identical(grp[k], "ELL") && s >= 2L && grepl("\\b(have|get|take|push|freeze)\\b", x) &&
      slips < 2L
    if (slip) { s <- s - 1L; slips <<- slips + 1L }
    words <- lengths(strsplit(x, "\\s+"))
    why <- if (off) "Not an attempt to answer the question." else if (!any(found))
      "States no key idea from the rubric." else
      sprintf("States %s.", paste(idea_names[found], collapse = "; "))
    list(index = k, score = if (off) 0L else s, rationale = why,
         confidence = if (off) 0.95 else if (words < 8) 0.55 else if (slip) 0.7 else 0.9,
         off_topic = off)
  })
}

# ---- a stand-in chat that gives the authored answers --------------------------

authored_chat <- function(provider, model, system_prompt) {
  answer <- function(prompt) {
    if (startsWith(system_prompt, "You turn a researcher")) return(plan_answer)
    if (startsWith(system_prompt, "You are an experienced assessment developer")) {
      content <- sub("^.*\nContent: ([^\n]+)\n.*$", "\\1", prompt)
      return(list(items = gen_items[[content]]))
    }
    if (startsWith(system_prompt, "You are a careful subject-matter expert"))
      return(verify_answer(strsplit(prompt, "\n")[[1]][1]))
    if (startsWith(system_prompt, "You are a trained rater")) {
      lines <- grep("^\\[[0-9]+\\] ", strsplit(prompt, "\n")[[1]], value = TRUE)
      return(list(scores = score_answer(sub("^\\[[0-9]+\\] ", "", lines))))
    }
    stop("No authored answer for this system prompt.")
  }
  # return what ellmer would: arrays of objects as data frames
  as_ellmer <- function(x) jsonlite::fromJSON(jsonlite::toJSON(x, auto_unbox = TRUE), simplifyVector = TRUE)
  list(chat = function(prompt, ..., echo = "none") stop("plain chat not used"),
       chat_structured = function(prompt, ..., type = NULL, echo = "none") as_ellmer(answer(prompt)))
}

unlockBinding("provider_chat", ns)
real_provider_chat <- get("provider_chat", ns)
assign("provider_chat", authored_chat, envir = ns)

options(mirtverse.provider = "claude", mirtverse.model = "authored")
Sys.setenv(ANTHROPIC_API_KEY = "not-used")
mv_llm_record(out, append = FALSE)

# run the example calls, skipping the mv_llm_replay() line
ex <- parse(file.path("inst", "replay", "examples.R"))
for (e in ex) {
  if (grepl("^(library|mv_llm_replay)", deparse(e)[1])) next
  eval(e, envir = globalenv())
}
mv_llm_record(NULL)
assign("provider_chat", real_provider_chat, envir = ns)
lockBinding("provider_chat", ns)
options(mirtverse.provider = NULL, mirtverse.model = NULL)
Sys.unsetenv("ANTHROPIC_API_KEY")

# label the file honestly
rec <- jsonlite::fromJSON(out, simplifyVector = FALSE)
rec$source <- paste("Example responses written by the mirtverse authors to show what a language",
                    "model returns, with deliberate mistakes for the checks to catch. Not output",
                    "from a live model. The calls are in examples.R.")
rec$recordings <- lapply(rec$recordings, function(r) {
  r$provider <- "authored"; r$model <- ""; r$recorded <- "2026-11-02"; r
})
writeLines(jsonlite::toJSON(rec, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null",
                            digits = NA), out, useBytes = TRUE)
message(sprintf("%d recordings written to %s", length(rec$recordings), out))
