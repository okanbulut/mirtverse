bp_cells <- data.frame(content = c("Fractions", "Decimals"), cognitive = c("Recall", "Apply"),
                       n = c(2, 1))
bp_pipe <- function(...) set_blueprint(mv_pipeline(verbose = FALSE), bp_cells,
                                       construct = "Grade 5 number sense", ...)

human_items <- function() data.frame(
  id = c("H1", "H2", "H3"),
  cell = c("Fractions / Recall", "Fractions / Recall", "Decimals / Apply"),
  stem = c("Which fraction is equal to one half?", "Which fraction is equal to one half?",
           "What is 0.5 plus 0.25?"),
  A = c("2/4", "2/4", "0.75"), B = c("1/3", "1/3", "0.30"), C = c("3/4", "3/5", "0.525"),
  D = c("2/3", "2/3", "0.55"), key = c("A", "A", "E"), stringsAsFactors = FALSE)

test_that("set_blueprint() records the cells and flags gaps", {
  p <- bp_pipe(use = "diagnostic", reliability = 0.85)
  expect_equal(p$blueprint$cells$cell, c("Fractions / Recall", "Decimals / Apply"))
  expect_equal(p$blueprint$length, 3)
  expect_equal(p$rules$reliability, 0.85)
  expect_equal(nrow(flags(p)), 0L)
  p <- set_blueprint(mv_pipeline(verbose = FALSE), c(Algebra = 4, Geometry = 0), length = 5)
  f <- flags(p)
  expect_setequal(f$check, c("empty_cell", "score_use", "target_reliability", "test_length"))
  expect_equal(f$target[f$check == "empty_cell"], "Geometry")
  expect_equal(p$stages$status[p$stages$stage == "blueprint"], "done")
  expect_error(set_blueprint(mv_pipeline(), data.frame(x = 1)), "content")
  expect_error(set_blueprint(mv_pipeline(), c(A = 1), reliability = 2), "between 0 and 1")
})

test_that("add_items() checks keys, duplicates, coverage and rubrics", {
  p <- add_items(bp_pipe(use = "diagnostic"), human_items())
  it <- p$items
  expect_equal(it$id, c("H1", "H2", "H3"))
  expect_equal(it$options[[1]], c("2/4", "1/3", "3/4", "2/3"))
  expect_equal(it$source, rep("human", 3))
  f <- flags(p, stage = "generation")
  expect_equal(f$target[f$check == "invalid_key"], "H3")
  expect_equal(f$target[f$check == "near_duplicate"], "H1 & H2")
  expect_setequal(f$target[f$check == "coverage"], c("Fractions / Recall", "Decimals / Apply"))
  open <- data.frame(id = c("O1", "O2"), cell = "Decimals / Apply", type = "open",
                     stem = c("Explain why 0.5 equals 1/2.", "Explain how to round 2.45."))
  open$rubric <- list(
    data.frame(score = 0:2, descriptor = c("None", "Partial", "Full"),
               anchor = c("I don't know", "They are the same", "5 tenths is 1 of 2 halves")),
    data.frame(score = c(0, 2), descriptor = c("None", "Full"), anchor = c("?", "2.5")))
  p <- add_items(p, open)
  f <- flags(p, stage = "generation")
  expect_equal(f$target[f$check == "rubric_incomplete"], "O2")
  expect_equal(p$items$max_score[p$items$id == "O1"], 2)
  expect_error(add_items(p, human_items()[1, ]), "already in the pool")
})

test_that("rubric_complete() needs every score point described and anchored", {
  ok <- data.frame(score = 0:1, descriptor = c("a", "b"), anchor = c("x", "y"))
  expect_true(rubric_complete(ok))
  expect_false(rubric_complete(NULL))
  expect_false(rubric_complete(transform(ok, anchor = c("x", ""))))
  expect_false(rubric_complete(ok[2, ]))
})

test_that("fk_grade() ranks easy text below hard text", {
  hard <- "Photosynthesis transforms electromagnetic radiation into chemical potential energy."
  expect_lt(fk_grade("The cat sat on the mat. It was fun."), 3)
  expect_gt(fk_grade(hard), 12)
  p <- add_items(bp_pipe(use = "diagnostic", grade_level = 4),
                 data.frame(cell = "Decimals / Apply", key = "A", A = "x", B = "y",
                            stem = hard))
  expect_true("readability" %in% flags(p)$check)
})

test_that("generate_items() writes items for every cell and verifies keys", {
  skip_if_not_installed("ellmer")
  calls <- 0
  local_mocked_bindings(
    item_llm = function(provider, model) list(provider = "claude", model = "test-model"),
    llm_generate_batch = function(llm, bp, cell, tp, m, n_options, instructions, existing) {
      calls <<- calls + 1
      items_from_llm(lapply(seq_len(m), function(i) list(
        stem = sprintf("%s question %d about %s?", cell$cell, calls * 10 + i, cell$content),
        options = paste("option", letters[1:4], calls, i), key = "b",
        rationales = rep("why", 4))), cell$cell, tp)
    },
    llm_verify_item = function(llm, stem, options) {
      bad <- grepl("question 11", stem)
      list(answer = if (bad) "C" else "B", defensible = if (bad) c("B", "C") else "B",
           distractors = data.frame(option = c("A", "C", "D"), plausible = c(TRUE, TRUE, FALSE),
                                    partly_correct = FALSE),
           note = "")
    })
  p <- generate_items(bp_pipe(use = "pass/fail"))
  it <- p$items
  expect_equal(as.integer(table(it$cell)[c("Fractions / Recall", "Decimals / Apply")]), c(6L, 3L))
  expect_true(all(it$key == "B"))
  expect_match(it$source[1], "AI: Claude")
  expect_true(all(!is.na(it$key_check)))
  f <- flags(p, stage = "generation")
  expect_equal(f$target[f$check == "key_check"], it$id[grepl("question 11", it$stem)])
  expect_true(all(f$value[f$check == "distractor"] == "D (implausible)"))
  expect_false("coverage" %in% f$check)
  expect_error(generate_items(mv_pipeline()), "blueprint")
  expect_error(generate_items(bp_pipe(use = "pass/fail"), cells = "Nope"), "Not blueprint cells")
})

test_that("items_from_llm() reads open-ended items with rubrics", {
  x <- list(list(stem = "Explain.", max_score = 1,
                 rubric = list(list(score = 0, descriptor = "No", anchor = "?"),
                               list(score = 1, descriptor = "Yes", anchor = "Because."))))
  r <- items_from_llm(x, "Cell", "open")
  expect_equal(r$type, "open")
  expect_true(rubric_complete(r$rubric[[1]]))
})

test_that("the structured-output types for the model build", {
  skip_if_not_installed("ellmer")
  expect_true(inherits(item_type_spec("mc", 4), "ellmer::TypeObject"))
  expect_true(inherits(item_type_spec("open", 4), "ellmer::TypeObject"))
  expect_match(item_request(bp_pipe(use = "x", grade_level = 5)$blueprint,
                            bp_pipe()$blueprint$cells[1, ], "mc", 3, 4, NULL, "Old item?"),
               "Write 3 multiple-choice \\(4 options\\)")
})

test_that("the report shows the blueprint and item pool", {
  p <- add_items(bp_pipe(use = "pass/fail"), human_items())
  p <- suppressWarnings(add_responses(p, expand.table(LSAT7)))
  p <- suppressWarnings(calibrate(p, model = "2PL"))
  f <- tempfile(fileext = ".html")
  p <- suppressWarnings(pipeline_report(p, file = f, open = FALSE, cards = FALSE))
  html <- paste(readLines(f, warn = FALSE), collapse = "\n")
  expect_match(html, "<h2>Blueprint</h2>")
  expect_match(html, "<h2>Item development</h2>")
  expect_match(html, "Grade 5 number sense")
})
