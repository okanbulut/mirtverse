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
#   * the rater model scores two ELL answers one point
#     below the rubric, and is unsure about very short answers
#   * the simulated respondents (experimental) find the items far too easy,
#     judge difficulty mostly by how long and wordy an item is, answer alike
#     when their personas are alike, and play "still learning English" and
#     "reads slowly" as a stereotype: They miss every long word problem
#   * the knowledge graph drafts (experimental): For Tatsuoka's fraction
#     subtraction items, the model misses column_borrow on FS01 and
#     borrow_whole on FS04, adds reduce_answer to FS08, misspells
#     common_denominator on FS13 (the link is dropped), links a 21st item
#     that does not exist, proposes a concept it was told not to add, and
#     gives prerequisites that point both ways and form a cycle. For the
#     numeracy items it links an item that does not exist. For the Grade 5
#     fractions items (Lab 12) it links F14 to common_denominator, as the
#     true graph does (but keeps compare too), finds the missing
#     equivalent -> compare edge, but adds five more links the true graph
#     does not have, adds a wrong
#     prerequisite compare -> common_denominator, and gives mixed and
#     add_subtract a two-way prerequisite
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

# rubric scoring for E1: the true number of key ideas (a careful rater sees
# through misspellings and gives no credit to reversed statements), with
# planted slips
e1_truth <- local({
  e1 <- essays[essays$prompt == "E1", ]
  tr <- mirtverse::lab_truth("essays")
  list(text = e1$response, group = as.character(e1$group),
       score = unname(tr$true_score[e1$id]), off = e1$id %in% tr$off_topic)
})
score_answer <- function(texts) {
  slips <- 0L
  lapply(seq_along(texts), function(k) {
    j <- match(texts[k], e1_truth$text)
    s <- e1_truth$score[j]
    off <- e1_truth$off[j]
    words <- lengths(strsplit(texts[k], "\\s+"))
    # the rater model marks down the first two ELL answers with two or more ideas
    slip <- identical(e1_truth$group[j], "ELL") && s >= 2L && slips < 2L
    if (slip) { s <- s - 1L; slips <<- slips + 1L }
    why <- if (off) "Not an attempt to answer the question." else if (s == 0)
      "States no key idea from the rubric correctly." else
      sprintf("States %d of the rubric's four key ideas.", s)
    list(index = k, score = if (off) 0L else s, rationale = why,
         confidence = if (off) 0.95 else if (words < 8) 0.55 else if (slip) 0.7 else 0.9,
         off_topic = off)
  })
}

# simulated respondents: a persona's "ability" read from its wording, an item's
# difficulty as the model sees it (mostly surface length, a little real b)
synth_items <- local({
  it <- itemtext[endsWith(itemtext$id, "-01"), ]
  words <- lengths(strsplit(it$stem, "\\s+"))
  z <- function(v) (v - mean(v)) / stats::sd(v)
  data.frame(id = it$id, key = it$key, words = words,
             seen = 0.35 * z(it$b) + 0.65 * z(words), stringsAsFactors = FALSE)
})
synth_answer <- function(prompt) {
  persona <- sub("^Respondent: ([^\n]+)\n.*$", "\\1", prompt)
  cut <- if (grepl("struggles|hard|rushes", persona)) 0.3 else
    if (grepl("average", persona)) 1.0 else 9
  wordy <- grepl("learning English|reads slowly", persona)
  ids <- regmatches(prompt, gregexpr("(?<=\\[)[A-Z0-9-]+(?=\\])", prompt, perl = TRUE))[[1]]
  lapply(ids, function(i) {
    r <- synth_items[synth_items$id == i, ]
    right <- r$seen < cut && !(wordy && r$words >= 16)
    if (grepl("fractions and decimals", persona) && i %in% c("N06-01", "N09-01")) right <- FALSE
    list(item = i, answer = if (right) r$key else setdiff(LETTERS[1:4], r$key)[1])
  })
}

L <- function(item, concept, reason) list(item = item, concept = concept, reason = reason)
P <- function(from, to, confidence, reason) list(from = from, to = to, confidence = confidence,
                                                 reason = reason)
C <- function(concept, label, description) list(concept = concept, label = label,
                                                description = description)
kg_answers <- list(
  "Middle school fraction subtraction" = list(
    concepts = list(C("subtract_whole_numbers", "Subtract whole numbers",
                      "Subtracting the whole number parts of mixed numbers.")),
    links = list(
      L("FS01", "common_denominator", "Thirds and fourths need a common denominator."),
      L("FS01", "subtract_numerators", "Subtract the numerators once the denominators match."),
      L("FS02", "common_denominator", "Rewrite 3/4 as eighths."),
      L("FS02", "subtract_numerators", "Subtract the numerators."),
      L("FS03", "common_denominator", "Sixths and ninths need a common denominator."),
      L("FS03", "subtract_numerators", "Subtract the numerators."),
      L("FS04", "separate_whole", "Work with the whole numbers and fractions separately."),
      L("FS04", "simplify_first", "3/2 is improper and can be simplified to 1 1/2 first."),
      L("FS04", "subtract_numerators", "Subtract the fractional parts."),
      L("FS05", "separate_whole", "Work with the whole numbers and fractions separately."),
      L("FS05", "common_denominator", "Fifths and tenths need a common denominator."),
      L("FS05", "subtract_numerators", "Subtract the numerators."),
      L("FS05", "reduce_answer", "2/10 should be reduced to 1/5."),
      L("FS06", "subtract_numerators", "Like denominators; subtract the numerators."),
      L("FS07", "convert_whole", "3 has no fraction part and must be written as a fraction or mixed number."),
      L("FS07", "separate_whole", "Work with the whole numbers and fractions separately."),
      L("FS07", "subtract_numerators", "Subtract the numerators."),
      L("FS08", "subtract_numerators", "Like denominators; subtract the numerators."),
      L("FS08", "reduce_answer", "The answer 0/3 should be written as 0."),
      L("FS09", "separate_whole", "Subtract the whole numbers and keep 7/8."),
      L("FS10", "separate_whole", "Work with the whole numbers and fractions separately."),
      L("FS10", "borrow_whole", "4/12 is smaller than 7/12, so borrow 1 from the 4."),
      L("FS10", "subtract_numerators", "Subtract the numerators."),
      L("FS10", "reduce_answer", "9/12 should be reduced to 3/4."),
      L("FS11", "separate_whole", "Work with the whole numbers and fractions separately."),
      L("FS11", "borrow_whole", "1/3 is smaller than 4/3, so borrow from the 4."),
      L("FS11", "subtract_numerators", "Subtract the numerators."),
      L("FS12", "subtract_numerators", "Like denominators; subtract the numerators."),
      L("FS12", "reduce_answer", "10/8 should be reduced to 5/4."),
      L("FS13", "separate_whole", "Work with the whole numbers and fractions separately."),
      L("FS13", "find_common_denominator", "Eighths and sixths need a common denominator."),
      L("FS13", "borrow_whole", "9/24 is smaller than 20/24, so borrow from the 3."),
      L("FS13", "subtract_numerators", "Subtract the numerators."),
      L("FS14", "separate_whole", "The whole numbers cancel; subtract the fractions."),
      L("FS14", "subtract_numerators", "Like denominators; subtract the numerators."),
      L("FS15", "convert_whole", "2 must be written as a fraction, such as 6/3."),
      L("FS15", "subtract_numerators", "Subtract the numerators."),
      L("FS16", "separate_whole", "Work with the whole numbers and fractions separately."),
      L("FS16", "subtract_numerators", "Like denominators; subtract the numerators."),
      L("FS17", "separate_whole", "Work with the whole number and fractions separately."),
      L("FS17", "borrow_whole", "3/5 is smaller than 4/5, so borrow from the 7."),
      L("FS17", "subtract_numerators", "Subtract the numerators."),
      L("FS18", "separate_whole", "Work with the whole numbers and fractions separately."),
      L("FS18", "borrow_whole", "1/10 is smaller than 8/10, so borrow from the 4."),
      L("FS18", "column_borrow", "Borrowing turns 1/10 into 11/10 before subtracting 8/10."),
      L("FS18", "subtract_numerators", "Subtract the numerators."),
      L("FS19", "convert_whole", "4 has no fraction part and must be rewritten."),
      L("FS19", "separate_whole", "Work with the whole numbers and fractions separately."),
      L("FS19", "simplify_first", "4/3 is improper and can be simplified first."),
      L("FS19", "borrow_whole", "Borrow from the 4 to subtract the fraction."),
      L("FS19", "subtract_numerators", "Subtract the numerators."),
      L("FS20", "separate_whole", "Work with the whole numbers and fractions separately."),
      L("FS20", "simplify_first", "5/3 is improper and can be simplified first."),
      L("FS20", "borrow_whole", "1/3 is smaller than 2/3, so borrow from the 4."),
      L("FS20", "subtract_numerators", "Subtract the numerators."),
      L("FS21", "subtract_numerators", "Subtract the numerators.")),
    prerequisites = list(
      P("subtract_numerators", "common_denominator", 0.8, "Subtracting like fractions comes before rewriting unlike ones."),
      P("subtract_numerators", "borrow_whole", 0.7, "Borrowing only makes sense once like fractions can be subtracted."),
      P("separate_whole", "borrow_whole", 0.9, "Borrowing moves 1 from the whole number part into the fraction part."),
      P("convert_whole", "borrow_whole", 0.6, "Borrowing rewrites a whole as a fraction."),
      P("subtract_numerators", "reduce_answer", 0.6, "An answer must exist before it can be reduced."),
      P("borrow_whole", "column_borrow", 0.5, "Column borrowing is a step inside borrowing from the whole."),
      P("column_borrow", "subtract_numerators", 0.3, "The numerators are subtracted after the borrow."),
      P("simplify_first", "reduce_answer", 0.5, "Both rely on rewriting a fraction in simplest or mixed form."),
      P("reduce_answer", "simplify_first", 0.4, "Reducing answers is practised before simplifying improper fractions."))),
  "Grade 7 numeracy" = list(
    concepts = list(
      C("multiply_divide", "Multiplying and dividing", "Multiplying and dividing whole numbers and decimals in context."),
      C("fractions_decimals", "Fractions and decimals", "Reading, comparing and operating on fractions, decimals and percents."),
      C("proportional_reasoning", "Proportional reasoning", "Using ratios, rates and percents to compare quantities."),
      C("measurement", "Measurement", "Measuring length, area and time, and converting between units."),
      C("data_chance", "Data and chance", "Summarizing data and finding simple probabilities."),
      C("linear_equations", "Linear equations", "Solving one-variable linear equations.")),
    links = list(
      L("N01-01", "multiply_divide", "Divide the cost by the number of pencils."),
      L("N01-01", "proportional_reasoning", "A unit rate is the cost for one."),
      L("N02-01", "fractions_decimals", "25% is one quarter."),
      L("N02-01", "proportional_reasoning", "A percent is a rate per hundred."),
      L("N03-01", "multiply_divide", "Multiply length by width."),
      L("N03-01", "measurement", "Area of a rectangle in square centimetres."),
      L("N04-01", "measurement", "Elapsed time in hours and minutes."),
      L("N05-01", "multiply_divide", "Divide the sum by the number of scores."),
      L("N05-01", "Data and chance", "The mean summarizes data."),
      L("N06-01", "fractions_decimals", "Add fractions with like denominators."),
      L("N07-01", "linear_equations", "Solve 5x + 7 = 47."),
      L("N08-01", "proportional_reasoning", "Use the ratio 3:5 to split 96."),
      L("N08-01", "multiply_divide", "Divide 96 into 8 parts."),
      L("N09-01", "fractions_decimals", "Compare decimals by place value."),
      L("N10-01", "measurement", "Convert metres to centimetres."),
      L("N11-01", "data_chance", "Probability of a simple event."),
      L("N11-01", "fractions_decimals", "A probability is written as a fraction."),
      L("N12-01", "proportional_reasoning", "Speed is a rate."),
      L("N12-01", "multiply_divide", "Divide the distance by the time."),
      L("N13-01", "measurement", "Converting units.")),
    prerequisites = list(
      P("multiply_divide", "proportional_reasoning", 0.85, "Rates and ratios rest on multiplication and division."),
      P("fractions_decimals", "proportional_reasoning", 0.7, "Percents and ratios are written as fractions."),
      P("multiply_divide", "measurement", 0.6, "Area and unit conversion use multiplication."),
      P("fractions_decimals", "data_chance", 0.6, "Probabilities are fractions."),
      P("multiply_divide", "linear_equations", 0.6, "Solving the equation uses inverse operations."))),
  "Grade 5 fractions" = list(
    concepts = list(),
    links = list(
      L("F01", "meaning", "Names shaded equal parts of a whole."),
      L("F02", "meaning", "Names a part of a whole."),
      L("F03", "meaning", "Places a fraction on the number line."),
      L("F04", "meaning", "Asks what the denominator means."),
      L("F05", "equivalent", "Finds a fraction equal to 2/3."),
      L("F06", "equivalent", "Completes an equivalent fraction."),
      L("F07", "equivalent", "Simplest form is an equivalent fraction."),
      L("F08", "equivalent", "Decides whether two fractions are equal."),
      L("F09", "mixed", "Mixed number to improper fraction."),
      L("F10", "mixed", "Improper fraction to mixed number."),
      L("F11", "mixed", "Counts quarters in a mixed number."),
      L("F11", "meaning", "A quarter is one of four equal parts."),
      L("F12", "mixed", "Improper fraction to mixed number."),
      L("F13", "compare", "Compares fractions with like denominators."),
      L("F14", "compare", "Asks which of two fractions is larger."),
      L("F14", "common_denominator", "3/4 and 5/6 are compared by rewriting them as twelfths."),
      L("F15", "compare", "Orders three fractions."),
      L("F15", "common_denominator", "Ordering is easiest with a common denominator."),
      L("F16", "compare", "Compares fractions with like numerators."),
      L("F17", "common_denominator", "Finds the least common denominator."),
      L("F18", "common_denominator", "Rewrites with a common denominator."),
      L("F19", "common_denominator", "Rewrites as twelfths."),
      L("F19", "equivalent", "Twelfths equal to 3/4 and 5/6."),
      L("F20", "add_subtract", "Adds two fractions."),
      L("F20", "Common denominators", "Halves and thirds need a common denominator."),
      L("F21", "add_subtract", "Subtracts two fractions."),
      L("F21", "common_denominator", "Sixths and thirds need a common denominator."),
      L("F22", "add_subtract", "Adds two fractions."),
      L("F22", "common_denominator", "Fourths and sixths need a common denominator."),
      L("F23", "add_subtract", "Adds mixed numbers."),
      L("F23", "mixed", "Works with mixed numbers."),
      L("F24", "add_subtract", "Subtracts two fractions."),
      L("F24", "common_denominator", "Eighths and sixths need a common denominator.")),
    prerequisites = list(
      P("meaning", "equivalent", 0.9, "Equal fractions rest on what a fraction means."),
      P("meaning", "mixed", 0.8, "Mixed numbers extend fractions beyond one whole."),
      P("equivalent", "common_denominator", 0.9, "A common denominator is found by writing equivalent fractions."),
      P("equivalent", "compare", 0.7, "Comparing unlike fractions uses equivalent fractions."),
      P("compare", "common_denominator", 0.4, "Students compare fractions before rewriting them."),
      P("common_denominator", "add_subtract", 0.9, "Unlike fractions are added after rewriting them."),
      P("mixed", "add_subtract", 0.7, "Adding mixed numbers needs mixed numbers."),
      P("add_subtract", "mixed", 0.3, "Adding fractions past one whole gives mixed numbers."))))

kg_answer <- function(prompt) {
  test <- sub("^Test: ([^\n]+)\n.*$", "\\1", prompt)
  kg_answers[[test]] %||% stop("No authored knowledge graph for this test.")
}
`%||%` <- function(x, y) if (is.null(x)) y else x

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
    if (startsWith(system_prompt, "You are simulating how a particular test taker"))
      return(list(answers = synth_answer(prompt)))
    if (startsWith(system_prompt, "You draft a knowledge graph")) return(kg_answer(prompt))
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
  r$provider <- "authored"; r$model <- ""
  r$recorded <- if (identical(r$function_name, "mv_kg_extract")) "2026-11-10" else "2026-11-02"
  r
})
writeLines(jsonlite::toJSON(rec, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null",
                            digits = NA), out, useBytes = TRUE)
message(sprintf("%d recordings written to %s", length(rec$recordings), out))
