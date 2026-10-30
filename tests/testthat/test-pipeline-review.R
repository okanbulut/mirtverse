rv_items <- function() {
  items <- data.frame(stem = c("What is 2 + 2?", "What is 3 x 3?", "What is 10 - 4?",
                               "What is 8 / 2?"),
                      A = c("4", "6", "6", "4"), B = c("5", "9", "5", "6"),
                      C = c("3", "8", "7", "2"), key = c("A", "B", "A", "A"),
                      cell = c("Add", "Multiply", "Add", "Multiply"))
  add_items(mv_pipeline(verbose = FALSE), items)
}

test_that("review_packet() writes one row per item and reviewer", {
  p <- rv_items()
  f <- tempfile(fileext = ".csv")
  p <- review_packet(p, f, reviewers = c("Ana", "Ben"))
  pk <- utils::read.csv(f, stringsAsFactors = FALSE)
  expect_equal(nrow(pk), 8L)
  expect_true(all(c("id", "item", "key", "reviewer", "decision", "aligned", "sensitivity",
                    "comment") %in% names(pk)))
  expect_match(pk$item[1], "A. 4")
  expect_error(review_packet(mv_pipeline(), f), "no items")
})

test_that("read_reviews() sets status by majority and raises the review flags", {
  p <- rv_items()
  rv <- data.frame(
    id = rep(c("H001", "H002", "H003", "H004"), each = 2)[-8],
    reviewer = c("Ana", "Ben", "Ana", "Ben", "Ana", "Ben", "Ana"),
    decision = c("accept", "accept", "reject", "reject", "accept", "revise", "accept"),
    aligned = c("yes", "yes", "yes", "yes", "no", "yes", "yes"),
    sensitivity = c("no", "yes", "no", "no", "no", "no", "no"))
  p <- read_reviews(p, rv)
  expect_equal(p$items$status, c("approved", "rejected", "revise", "approved"))
  f <- flags(p, stage = "review")
  expect_equal(f$target[f$check == "under_reviewed"], "H004")
  expect_equal(f$target[f$check == "alignment"], "H003")
  expect_equal(f$target[f$check == "sensitivity"], "H001")
  expect_equal(f$target[f$check == "needs_revision"], "H003")
  # rejected items leave the coverage count and later reviews replace earlier ones
  p <- read_reviews(p, data.frame(id = "H004", reviewer = c("Ben", "Ana"),
                                  decision = c("accept", "accept")))
  expect_false("under_reviewed" %in% flags(p, stage = "review")$check)
  expect_equal(nrow(p$reviews), 8L)
  expect_error(read_reviews(p, data.frame(id = "H001", reviewer = "A", decision = "maybe")),
               "accept, revise or reject")
  expect_error(read_reviews(p, data.frame(id = "Z9", reviewer = "A", decision = "accept")),
               "not in the pool")
})

test_that("review_agreement() computes Fleiss' kappa", {
  # Fleiss (1971)-style toy: perfect agreement gives kappa 1
  rv <- data.frame(id = rep(c("a", "b", "c"), each = 3), reviewer = rep(1:3, 3),
                   decision = rep(c("accept", "reject", "accept"), each = 3))
  expect_equal(review_agreement(rv)$kappa, 1)
  rv$decision <- c("accept", "accept", "reject", "reject", "reject", "accept",
                   "accept", "revise", "accept")
  ag <- review_agreement(rv)
  # hand computation: P_i = 1/3 each, Pbar = 1/3; p = (5, 3, 1)/9, Pe = 35/81
  expect_equal(ag$agreement, 1 / 3)
  expect_equal(ag$kappa, (1 / 3 - 35 / 81) / (1 - 35 / 81))
})

test_that("the AI screen adds its notes to the packet and the flags", {
  skip_if_not_installed("ellmer")
  local_mocked_bindings(
    item_llm = function(provider, model) list(provider = "claude", model = "m"),
    llm_screen_item = function(llm, text) if (grepl("10 - 4", text)) "Assumes Western numerals." else "")
  p <- rv_items()
  f <- tempfile(fileext = ".csv")
  p <- review_packet(p, f, ai_screen = TRUE)
  expect_equal(p$items$ai_screen[3], "Assumes Western numerals.")
  rv <- data.frame(id = rep(p$items$id, each = 2), reviewer = rep(c("A", "B"), 4),
                   decision = "accept", aligned = "yes", sensitivity = "no")
  p <- read_reviews(p, rv)
  f <- flags(p, stage = "review")
  expect_equal(f$target[f$check == "sensitivity"], "H003")
  expect_match(f$value[f$check == "sensitivity"], "AI screen")
})

test_that("design_field_test() spreads items over forms with anchors", {
  p <- design_field_test(mv_pipeline(verbose = FALSE), n_forms = 3, n_per_form = 200,
                         items = 30, reps = 0)
  ft <- p$field_test
  # 3 anchors are the fewest that make up 20% of a form (3 + 9 = 12 items)
  expect_equal(length(ft$anchors), 3L)
  expect_true(all(table(ft$forms$form) == 12L))
  expect_equal(sum(ft$forms$role == "unique"), 27L)
  expect_equal(ft$items$n[ft$items$role == "anchor"], rep(600, 3))
  f <- flags(p, stage = "field_test")
  expect_equal(f$check, "sample_size")
  expect_match(f$target, "27 unique")
  expect_null(ft$recovery)
  p2 <- design_field_test(mv_pipeline(verbose = FALSE), n_forms = 2, n_per_form = 400,
                          items = 20, anchors = "I001", reps = 0)
  expect_true("anchor_share" %in% flags(p2)$check)
  expect_error(design_field_test(mv_pipeline(), 2, 100, anchors = "x", items = 10), "Anchors")
})

test_that("design_field_test() simulates parameter recovery", {
  p <- design_field_test(mv_pipeline(verbose = FALSE), n_forms = 2, n_per_form = 1500,
                         items = 30, reps = 2, seed = 4)
  rec <- p$field_test$recovery
  expect_lt(rec$rmse_a, 0.2)
  expect_lt(rec$rmse_d, 0.2)
  expect_equal(rec$converged, 1)
  q <- design_field_test(mv_pipeline(verbose = FALSE), n_forms = 4, n_per_form = 150,
                         items = 40, reps = 2, seed = 4)
  expect_true("recovery" %in% flags(q)$check)
})

test_that("field tests use reviewed items, open items count as polytomous", {
  p <- rv_items()
  op <- data.frame(stem = "Explain why 2 + 2 = 4.", type = "open", cell = "Add")
  op$rubric <- list(data.frame(score = 0:2, descriptor = c("a", "b", "c"), anchor = c("x", "y", "z")))
  p <- add_items(p, op)
  rv <- data.frame(id = rep(p$items$id, each = 2), reviewer = rep(c("A", "B"), 5),
                   decision = c(rep("accept", 6), "reject", "reject", "accept", "accept"))
  p <- read_reviews(p, rv)
  p <- design_field_test(p, n_forms = 1, n_per_form = 800, reps = 0)
  expect_setequal(p$field_test$forms$item, c("H001", "H002", "H003", "H005"))
  f <- flags(p, stage = "field_test")
  expect_equal(f$target, "1 unique item(s)")
  f <- tempfile(fileext = ".html")
  p <- suppressWarnings(calibrate(suppressWarnings(add_responses(p, expand.table(LSAT7))),
                                  model = "2PL"))
  p <- suppressWarnings(pipeline_report(p, file = f, open = FALSE, cards = FALSE))
  html <- paste(readLines(f, warn = FALSE), collapse = "\n")
  expect_match(html, "<h2>Field-test design</h2>")
  expect_match(html, "Fleiss")
})
