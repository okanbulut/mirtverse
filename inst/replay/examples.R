# The calls answered by mirtverse's example recordings (examples.json).
#
# Run them after mv_llm_replay(): no API key or internet connection is
# needed, and every run gives the same results. The responses were written
# by the package authors to show what a language model returns, including a
# few deliberate mistakes for mirtverse's checks to catch; they were not
# produced by a live model. Change any argument or input and the request no
# longer matches the recording.

library(mirtverse)
mv_llm_replay()

# ---- 1. Analysis code from a plain-language request ---------------------------

s <- mv_ask("Fit a graded response model to these attitude items, check the fit and explain the results.",
            data = Science, ask = FALSE)
s

# ---- 2. Generate items, then verify them with a second model call -------------

cells <- data.frame(content = c("Ratios and rates", "Measurement"),
                    cognitive = c("Apply", "Apply"), n = c(2, 2))
p <- mv_pipeline("Grade 7 numeracy", verbose = FALSE)
p <- set_blueprint(p, cells, construct = "Grade 7 numeracy", use = "classroom diagnostic",
                   population = "Grade 7 students")
p <- generate_items(p, n = 2)
p$items[, c("id", "cell", "stem", "key", "key_check", "weak_distractors")]
flags(p, stage = "generation")

# ---- 3. Score open-ended responses against a rubric ---------------------------

e1 <- essays[essays$prompt == "E1", ][1:40, ]
item <- data.frame(id = "E1", type = "open", cell = "Physical science",
                   stem = "Explain why ice floats on liquid water.")
item$rubric <- list(data.frame(
  score = 0:4,
  descriptor = c("No correct key idea.",
                 "One key idea: ice is less dense; molecules form an open structure; ice takes more volume; less dense things float.",
                 "Two key ideas.",
                 "Three key ideas.",
                 "All four key ideas, linked into one explanation."),
  anchor = c("Ice is cold so it floats.",
             "Ice is less dense than water.",
             "Ice is less dense than water, so the water pushes it up and it floats.",
             "Water expands when it freezes, so ice is less dense than water and floats.",
             paste("When water freezes its molecules form an open crystal, so the same mass takes",
                   "more volume. Ice is therefore less dense than water, and less dense things float."))))
q <- add_items(mv_pipeline("Science explanations", verbose = FALSE), item)
responses <- data.frame(person = e1$student, item = "E1", response = e1$response,
                        human1 = e1$human1, human2 = e1$human2, group = e1$group)
q <- score_open(q, responses)
q$agreement
head(q$open_scores[, c("person", "machine", "human1", "confidence", "rationale")])

# ---- 4. Simulated respondents (experimental) ----------------------------------

items <- itemtext[endsWith(itemtext$id, "-01"), ]
personas <- c(
  "A Grade 7 student who struggles with mathematics.",
  "A Grade 7 student who struggles with mathematics and is still learning English.",
  "A Grade 7 student who finds fractions and decimals hard but tries every question.",
  "A Grade 7 student who often rushes and makes careless mistakes.",
  "A Grade 7 student who is about average in mathematics.",
  "A Grade 7 student who is about average in mathematics and is still learning English.",
  "A Grade 7 student with average marks who is anxious on tests.",
  "A Grade 7 student who is about average in mathematics and likes word problems.",
  "A Grade 7 student who is strong in mathematics.",
  "A Grade 7 student who is strong in mathematics and is still learning English.",
  "A Grade 7 student in an enriched mathematics program.",
  "A Grade 7 student who is strong in mathematics but reads slowly.")
syn <- simulate_llm_respondents(items, personas)
syn
compare_synthetic(syn, stats::setNames(items$p_field, items$id))

# ---- 5. Draft a knowledge graph from item text (experimental) -----------------

# concepts given: A second opinion on Tatsuoka's Q-matrix
draft <- mv_kg_extract(fraction_subtraction_kg, subject = "Middle school fraction subtraction")
draft
mv_kg_compare(draft, fraction_subtraction_kg)

# concepts proposed by the model
items <- itemtext[endsWith(itemtext$id, "-01"), c("id", "domain", "stem")]
draft2 <- mv_kg_extract(items, subject = "Grade 7 numeracy")
draft2
gg_kg(draft2, colour = "domain")
