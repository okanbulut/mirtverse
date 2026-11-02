fake_provider_chat <- function(provider, model, system_prompt) {
  list(chat = function(prompt, ..., echo = "none") paste("echo:", prompt),
       chat_structured = function(prompt, ..., type = NULL, echo = "none")
         list(items = data.frame(stem = c("Q1", "Q2"), key = c("A", "B"))))
}

test_that("mv_llm_record() saves requests that mv_llm_replay() plays back", {
  skip_if_not_installed("ellmer")
  withr::local_options(mirtverse.provider = NULL, mirtverse.replay = NULL, mirtverse.record = NULL)
  local_mocked_bindings(provider_chat = fake_provider_chat)
  f <- withr::local_tempfile(fileext = ".json")
  expect_message(mv_llm_record(f, append = FALSE), "Recording")
  ch <- make_chat("claude", "m", "system text")
  live_text <- ch$chat("hello")
  live_obj <- ch$chat_structured("make items")
  expect_message(mv_llm_record(NULL), "Stopped")
  expect_null(getOption("mirtverse.record"))

  recs <- mv_llm_recordings(f)
  expect_equal(nrow(recs), 2L)
  expect_equal(recs$structured, c(FALSE, TRUE))

  expect_message(old <- mv_llm_replay(f), "2 recorded requests")
  withr::defer(options(old))
  expect_equal(ask_provider(), "replay")
  rp <- make_chat(ask_provider(), NULL, "system text")
  expect_equal(rp$chat("hello"), live_text)
  expect_equal(rp$chat_structured("make items"), live_obj)
  # a different request, or the same prompt with other instructions, is not in it
  expect_error(rp$chat("goodbye"), "not in the recording")
  expect_error(make_chat("replay", NULL, "other system")$chat("hello"), "not in the recording")
  mv_llm_replay(FALSE)
  expect_null(getOption("mirtverse.replay"))
})

test_that("recording again replaces an earlier answer to the same request", {
  skip_if_not_installed("ellmer")
  withr::local_options(mirtverse.record = NULL)
  local_mocked_bindings(provider_chat = fake_provider_chat)
  f <- withr::local_tempfile(fileext = ".json")
  suppressMessages(mv_llm_record(f, append = FALSE))
  ch <- make_chat("claude", "m", "s")
  ch$chat("same"); ch$chat("same")
  suppressMessages(mv_llm_record(NULL))
  expect_equal(nrow(mv_llm_recordings(f)), 1L)
})

test_that("the example recordings answer the calls in examples.R", {
  skip_if_not_installed("ellmer")
  withr::local_options(mirtverse.provider = NULL, mirtverse.replay = NULL)
  old <- suppressMessages(mv_llm_replay())
  withr::defer(options(old))
  expect_equal(provider_label("replay"), "recorded responses")
  expect_true(all(mv_llm_recordings()$provider == "authored"))

  s <- mv_ask("Fit a graded response model to these attitude items, check the fit and explain the results.",
              data = Science, ask = FALSE)
  expect_equal(s$parser, "recorded responses")
  expect_equal(s$plan$model, "graded")

  cells <- data.frame(content = c("Ratios and rates", "Measurement"),
                      cognitive = c("Apply", "Apply"), n = c(2, 2))
  p <- mv_pipeline("Grade 7 numeracy", verbose = FALSE)
  p <- set_blueprint(p, cells, construct = "Grade 7 numeracy", use = "classroom diagnostic",
                     population = "Grade 7 students")
  p <- suppressMessages(suppressWarnings(generate_items(p, n = 2)))
  expect_equal(nrow(p$items), 4L)
  expect_equal(p$items$key_check, c("agree", "agree", "disagree", "agree"))
  f <- flags(p, stage = "generation")
  expect_equal(f$target[f$check == "key_check"], "G003")
  expect_equal(f$target[f$check == "distractor"], "G004")

  # another blueprint is not in the recording
  p2 <- set_blueprint(mv_pipeline(verbose = FALSE), c(Algebra = 2))
  expect_error(suppressWarnings(generate_items(p2, n = 1)), "not in the recording")
})

test_that("the AI Hub datasets have the documented shape and truth", {
  expect_equal(dim(itemtext), c(192L, 17L))
  expect_equal(length(unique(itemtext$family)), 12L)
  expect_true(all(itemtext$key %in% LETTERS[1:4]))
  tr <- lab_truth("itemtext")
  expect_equal(names(tr$b), itemtext$id)
  expect_true(all(itemtext$a[match(tr$miskeyed$id, itemtext$id)] < 0))
  expect_gt(cor(itemtext$b, itemtext$p_field), -1)
  expect_lt(cor(itemtext$b, itemtext$p_field), -0.5)

  expect_equal(dim(essays), c(1600L, 8L))
  expect_equal(levels(essays$group), c("Fluent", "ELL"))
  expect_true(all(essays$human1 %in% 0:4))
  et <- lab_truth("essays")
  expect_equal(names(et$true_score), essays$id)
  # at the same true score, fluent answers are much longer
  len <- tapply(essays$words, list(et$true_score, essays$group), mean)
  expect_true(all(len[, "Fluent"] > 1.5 * len[, "ELL"]))
})
