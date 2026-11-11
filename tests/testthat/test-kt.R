# Simulated logs with known BKT values for one skill
sim_bkt <- function(n = 300, len = 12, prior = 0.2, learn = 0.15, guess = 0.2, slip = 0.1,
                    seed = 1) {
  set.seed(seed)
  rows <- lapply(seq_len(n), function(i) {
    k <- stats::runif(1) < prior
    y <- integer(len)
    for (t in seq_len(len)) {
      y[t] <- as.integer(stats::runif(1) < if (k) 1 - slip else guess)
      if (!k) k <- stats::runif(1) < learn
    }
    data.frame(student = sprintf("s%03d", i), skill = "A", item = sample(c("q1", "q2"), len, TRUE),
               correct = y)
  })
  do.call(rbind, rows)
}

test_that("mv_kt_fit() recovers the parameters of a simulated skill", {
  d <- sim_bkt()
  kt <- mv_kt_fit(d, seed = 1)
  expect_s3_class(kt, "mv_kt")
  p <- tidy(kt)
  expect_equal(p$skill, "A")
  expect_lt(abs(p$prior - 0.2), 0.06)
  expect_lt(abs(p$learn - 0.15), 0.04)
  expect_lt(abs(p$guess - 0.2), 0.04)
  expect_lt(abs(p$slip - 0.1), 0.04)
  expect_equal(p$forget, 0)
  expect_true(p$converged)
  expect_equal(p$n_students, 300)
  expect_equal(p$n_attempts, 3600)
  g <- glance(kt)
  expect_equal(g$n_attempts, 3600)
  expect_gt(g$auc, 0.7)
  expect_output(print(kt), "EXPERIMENTAL")
  tr <- tidy(kt, "trace")
  expect_equal(nrow(tr), 3600)
  expect_true(all(tr$p_correct > 0 & tr$p_correct < 1))
  # the first prediction of every student is the prior
  expect_equal(unique(round(tr$p_known_before[tr$step == 1], 8)), round(p$prior, 8))
  m <- tidy(kt, "mastery")
  expect_equal(nrow(m), 300)
  expect_true(all(m$attempts == 12))
  expect_error(tidy(kt, "items"), "multigs")
  # more forgetting-free data: forgets stays near zero
  kf <- mv_kt_fit(d, forgets = TRUE, seed = 1)
  expect_lt(tidy(kf)$forget, 0.05)
  expect_output(print(kf), "forgets")
})

test_that("mv_kt_fit() fits item guess and slip and uses a knowledge graph", {
  kt <- mv_kt_fit(fractions_logs, kg = fractions_kg, multigs = TRUE, seed = 1)
  expect_equal(tidy(kt)$skill, kg_concept_names(fractions_kg))
  it <- tidy(kt, "items")
  truth <- lab_truth("fractions_logs")
  m <- merge(it, truth$items, by = "item")
  expect_gt(cor(m$guess.x, m$guess.y), 0.8)
  expect_true(all(is.na(tidy(kt)$guess)))
  expect_output(print(kt), "item guess and slip")
  expect_s3_class(gg_kt(kt), "ggplot")
  expect_s3_class(gg_kt(kt, student = "P001"), "ggplot")
  expect_s3_class(gg_kt(kt, type = "graph"), "ggplot")
  expect_s3_class(gg_kt(kt, student = "P001", type = "graph"), "ggplot")
  expect_s3_class(gg_kt(kt, skills = "meaning"), "ggplot")
  expect_error(gg_kt(kt, student = "nope"), "Unknown student")
  expect_error(gg_kt(kt, skills = "nope"), "Unknown skills")
  expect_error(gg_kt(list()), "mv_kt_fit")
})

test_that("predict() and mv_kt_cv() work on new students", {
  d <- sim_bkt(n = 120, len = 8)
  kt <- mv_kt_fit(d[d$student <= "s080", ], multigs = TRUE, seed = 1)
  pr <- predict(kt, d[d$student > "s080", ])
  expect_equal(nrow(pr), 40 * 8)
  expect_identical(predict(kt), kt$trace)
  cv <- mv_kt_cv(d, folds = 3, seed = 2)
  expect_equal(cv$fold, c("1", "2", "3", "mean"))
  expect_true(all(cv$auc > 0.6))
  expect_error(mv_kt_cv(d, folds = 1), "folds")
})

test_that("mv_kt_fit() reads the Cognitive Tutor logs", {
  kt <- mv_kt_fit(cognitive_tutor, skills = c("Plot pi", "Plot whole number"), seed = 1)
  expect_equal(tidy(kt)$skill, c("Plot whole number", "Plot pi"))
  expect_equal(sum(tidy(kt)$n_attempts), 417 + 590)
})

test_that("mv_kt_fit() checks its input", {
  expect_error(mv_kt_fit(list()), "data frame")
  expect_error(mv_kt_fit(data.frame(student = 1, correct = 1)), "skill column")
  expect_error(mv_kt_fit(data.frame(student = 1, skill = "a", correct = 2)), "0/1")
  expect_error(mv_kt_fit(data.frame(student = 1, skill = "a", correct = 1), multigs = TRUE), "item column")
  expect_error(mv_kt_fit(data.frame(student = 1, correct = 1), kg = fractions_kg), "item column")
  expect_error(mv_kt_fit(data.frame(x = 1)), "no column")
  expect_error(mv_kt_fit(data.frame(student = 1, skill = "a", correct = 1), skills = "b"), "Unknown skills")
  expect_warning(mv_kt_fit(data.frame(student = c(1, 1), item = c("F01", "Z9"), correct = c(1, 0)),
                           kg = fractions_kg, starts = 1), "not in the graph")
})
