test_that("train_scorer learns from the words and predicts new responses", {
  e1 <- essays[essays$prompt == "E1", ]
  s <- train_scorer(e1)
  expect_s3_class(s, "mv_scorer")
  expect_equal(nrow(s$cv), nrow(e1))
  expect_true(all(s$cv$machine %in% 0:4))
  expect_gt(qwk(s$cv$machine, e1$human1), 0.7)
  expect_output(print(s), "cross-validated RMSE")

  p <- predict(s, c("Ice is less dense than water, so the water pushes it up and it floats.",
                    "idk"))
  expect_length(p, 2)
  expect_gt(p[1], p[2])
  raw <- predict(s, e1[1:5, ], type = "raw")
  expect_false(isTRUE(all.equal(raw, round(raw))))

  tw <- tidy(s)
  expect_named(tw, c("by", "term", "weight"))
  expect_true(tw$weight[1] >= tw$weight[nrow(tw)])
  expect_true(any(grepl("dense|density", head(tw$term, 25))))
})

test_that("train_scorer fits one model per prompt and the same seed gives the same scorer", {
  sub <- essays[essays$student %in% sprintf("S%03d", 1:120) & essays$prompt %in% c("E1", "E3"), ]
  s1 <- train_scorer(sub, by = "prompt", length = TRUE)
  s2 <- train_scorer(sub, by = "prompt", length = TRUE)
  expect_equal(names(s1$models), c("E1", "E3"))
  expect_equal(s1$cv, s2$cv)
  expect_true("(length)" %in% names(s1$models$E1$beta))
  # a data frame with `item` instead of `prompt` also works (as in score_open)
  nd <- data.frame(item = sub$prompt[1:6], response = sub$response[1:6])
  expect_length(predict(s1, nd), 6)
  expect_error(predict(s1, "Ice floats."), "one model per prompt")
  expect_error(predict(s1, data.frame(item = "E2", response = "x")), "No scorer was trained")
  expect_error(train_scorer(sub, score = "nope"), "no column `nope`")
  expect_error(train_scorer(sub[1:10, ]), "at least 20")
})

test_that("a trained scorer plugs into score_open", {
  e1 <- essays[essays$prompt == "E1", ]
  s <- train_scorer(e1[1:250, ])
  item <- data.frame(id = "E1", type = "open", stem = "Explain why ice floats on liquid water.")
  item$rubric <- list(data.frame(score = 0:4, descriptor = paste(0:4, "key ideas"),
                                 anchor = paste("Example with", 0:4, "key ideas")))
  q <- add_items(mv_pipeline(verbose = FALSE), item)
  rs <- data.frame(person = e1$student[251:400], item = "E1", response = e1$response[251:400],
                   human1 = e1$human1[251:400], human2 = e1$human2[251:400],
                   group = e1$group[251:400])
  q <- suppressMessages(score_open(q, rs, scorer = s))
  expect_equal(nrow(q$open_scores), 150L)
  expect_match(q$scoring$method, "mv_scorer")
  a <- agreement_report(q)
  expect_s3_class(a, "mv_agreement")
  expect_equal(a$group, c("All", "Fluent", "ELL"))
  expect_equal(unique(a$by), "E1")
})

test_that("agreement_report computes the agreement statistics", {
  h1 <- c(0, 1, 2, 3, 4, 2, 1, 3, 4, 0, 2, 3)
  m <- h1
  a <- agreement_report(m, h1)
  expect_equal(a$exact, 1)
  expect_equal(a$adjacent, 1)
  expect_equal(a$qwk, 1)
  expect_equal(a$smd, 0)
  expect_true(is.na(a$prmse))
  expect_equal(a$verdict, "meets")

  a2 <- agreement_report(pmin(m + 1, 4), h1)
  expect_gt(a2$smd, 0)
  expect_equal(a2$verdict, "machine too high")
  expect_lt(a2$exact, 1)
  expect_equal(a2$adjacent, 1)

  expect_error(agreement_report(1:3, 1:2), "same length")
  expect_error(agreement_report(1:3), "human scores")
  expect_output(print(a), "Machine-human agreement")
})

test_that("PRMSE is near 1 for the true score and lower for a noisy machine", {
  set.seed(3)
  n <- 2000
  true <- sample(0:4, n, replace = TRUE)
  rate <- function() pmin(4, pmax(0, round(true + rnorm(n, 0, 0.5))))
  h1 <- rate(); h2 <- ifelse(runif(n) < 0.5, rate(), NA)
  expect_gt(prmse(true, h1, h2), 0.95)
  noisy <- pmin(4, pmax(0, round(true + rnorm(n, 0, 0.8))))
  expect_lt(prmse(noisy, h1, h2), prmse(true, h1, h2))
  expect_true(is.na(prmse(true, h1, rep(NA, n))))
})

test_that("agreement_report works by group and by item, and plots", {
  e <- essays[essays$prompt %in% c("E1", "E2"), ]
  a <- agreement_report(e$human1, e$human1, e$human2, group = e$group, by = e$prompt)
  expect_equal(nrow(a), 6L)
  expect_equal(a$by, rep(c("E1", "E2"), each = 3))
  expect_true(all(a$qwk == 1))
  expect_true(all(a$prmse > 0.5))
  p <- autoplot(a)
  expect_s3_class(p, "patchwork")
})
