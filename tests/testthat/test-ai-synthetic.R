synth_personas <- function() c(
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

test_that("simulate_llm_respondents() replays the example and scores the answers", {
  skip_if_not_installed("ellmer")
  old <- suppressMessages(mv_llm_replay())
  on.exit(options(old))
  items <- itemtext[endsWith(itemtext$id, "-01"), ]
  syn <- simulate_llm_respondents(items, synth_personas())
  expect_s3_class(syn, "mv_synthetic")
  expect_equal(dim(syn$responses), c(12L, 12L))
  expect_equal(names(syn$responses), items$id)
  expect_true(all(unlist(syn$responses) %in% 0:1))
  # scoring matches the letters
  expect_equal(syn$responses[[1]], as.integer(syn$answers[[1]] == items$key[1]))
  expect_equal(syn$personas$id[1], "R001")
  expect_output(print(syn), "EXPERIMENTAL")
  cmp <- compare_synthetic(syn, stats::setNames(items$p_field, items$id))
  expect_s3_class(cmp, "mv_synthetic_comparison")
  expect_gt(cmp$summary$mean_p_synthetic, cmp$summary$mean_p_real + 0.2)
  expect_lt(cmp$summary$distinct_patterns, 12)
  expect_match(paste(cmp$notes, collapse = " "), "easier")
  expect_match(paste(cmp$notes, collapse = " "), "vary little")
  expect_output(print(cmp), "N01-01")
  expect_s3_class(autoplot(cmp), "ggplot")
  # a request that is not recorded stops with a clear error
  expect_error(simulate_llm_respondents(items, "A Grade 9 student."), "not in the recording")
})

test_that("simulate_llm_respondents() checks its input", {
  items <- itemtext[1:3, ]
  expect_error(simulate_llm_respondents(items[, -4], "x"), "no column `stem`")
  expect_error(simulate_llm_respondents(items, ""), "no empty")
  expect_error(simulate_llm_respondents(items, data.frame(who = "x")), "`persona` column")
  bad <- items; bad$key[1] <- "Z"
  expect_error(simulate_llm_respondents(bad, "x"), "option letters")
  withr::local_options(mirtverse.provider = "rules")
  expect_error(simulate_llm_respondents(items, "x"), "needs a language model")
})

test_that("compare_synthetic() uses real responses when given them", {
  syn <- structure(list(responses = data.frame(I1 = c(1, 1, 1, 0), I2 = c(1, 1, 0, 0),
                                               I3 = c(1, 0, 0, 0), I4 = c(1, 1, 1, 1)),
                        provider = "example", model = ""), class = "mv_synthetic")
  set.seed(1)
  real <- data.frame(I1 = rbinom(200, 1, .6), I2 = rbinom(200, 1, .5),
                     I3 = rbinom(200, 1, .4), I4 = rbinom(200, 1, .7))
  cmp <- compare_synthetic(syn, real)
  expect_true(all(c("rit_real", "rit_synthetic") %in% names(cmp$items)))
  expect_false(is.na(cmp$summary$sd_total_real))
  expect_match(paste(cmp$notes, collapse = " "), "more consistent")
  expect_error(compare_synthetic(syn, c(X = 1)), "share 0")
  expect_error(compare_synthetic(list(), real), "simulate_llm_respondents")
})
