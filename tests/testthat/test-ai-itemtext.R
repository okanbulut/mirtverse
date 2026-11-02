test_that("item_features reads stems and options", {
  items <- data.frame(
    id = c("i1", "i2", "i3", "i4"),
    stem = c("What is 3 + 4?",
             "Maya has 1,250 marbles. She gives away 0.5 of them. How many does she keep?",
             "Which of these is NOT a mammal?",
             "Which of these is NOT a mammal?"),
    A = c("7", "625", "whale", "whale"), B = c("8", "1,250", "shark", "shark"),
    C = c("12", "600", "bat", "bat"), D = c("1", "650", "horse", "horse"),
    key = c("A", "A", "B", "B"), stringsAsFactors = FALSE)
  f <- item_features(items)
  expect_s3_class(f, "tbl_df")
  expect_equal(f$id, items$id)
  expect_equal(f$sentences, c(1, 3, 1, 1))
  expect_equal(f$numbers, c(2, 2, 0, 0))
  expect_equal(f$max_digits, c(1, 4, 0, 0))
  expect_equal(f$decimals, c(0, 1, 0, 0))
  expect_equal(f$negation, c(0, 0, 1, 1))
  expect_equal(f$key_longest, c(0, 0, 0, 0))
  expect_equal(f$distractor_distance[1], round(median(abs(c(8, 12, 1) - 7)) / 7, 3))
  expect_true(is.na(f$distractor_distance[3]))
  expect_equal(f$similarity[3], 1)
  expect_equal(f$nearest[3:4], c("i4", "i3"))
  # money with zero cents is not a decimal; fractions and times parse
  expect_equal(mirtverse:::option_value(c("$5.00", "3/4", "4:30 p.m.", "1,200 square cm", "idk")),
               c(5, 0.75, 270, 1200, NA))
  # no options, no id column
  f2 <- item_features(data.frame(stem = c("Why do we have seasons?", "Is ice less dense than water?")),
                      options = character(0))
  expect_equal(f2$id, c("item001", "item002"))
  expect_false("key_longest" %in% names(f2))
  expect_error(item_features(items, stem = "nope"), "no column `nope`")
})

test_that("item_features finds the planted near-duplicates in itemtext", {
  f <- item_features(itemtext)
  expect_equal(nrow(f), 192L)
  top <- f[order(-f$similarity), ][1:4, ]
  expect_setequal(top$id, c("N01-02", "N01-14", "N06-05", "N06-12"))
  expect_true(all(f$similarity[!f$id %in% top$id] < 0.8))
  d <- merge(itemtext, f)
  ok <- d$a > 0   # the miskeyed items list a distractor as the key
  expect_equal(d$decimals[ok], d$decimal[ok])
})

test_that("predict_difficulty recovers LLTM effects and compares methods", {
  set.seed(5)
  n <- 120
  d <- data.frame(id = sprintf("i%03d", 1:n), x1 = rbinom(n, 1, 0.5), x2 = rnorm(n),
                  fam = sample(c("f1", "f2", "f3", "f4"), n, replace = TRUE))
  d$b <- 0.8 * d$x1 + 0.3 * d$x2 + c(f1 = -1, f2 = 0, f3 = 0.5, f4 = 1)[d$fam] + rnorm(n, 0, 0.2)
  d$se <- 0.1
  m <- predict_difficulty(d, c("x1", "x2", "fam"), se = "se", ntree = 30)
  expect_s3_class(m, "mv_difficulty")
  expect_equal(m$accuracy$method, c("lltm", "lasso", "forest"))
  expect_equal(nrow(m$cv), 3 * n)
  expect_true(all(m$accuracy$r2[1:2] > 0.85))
  expect_output(print(m), "Estimation error in b")
  w <- tidy(m)
  expect_named(w, c("method", "term", "estimate", "std_error"))
  lltm <- w[w$method == "lltm", ]
  expect_equal(lltm$estimate[lltm$term == "x1"], 0.8, tolerance = 0.1)
  expect_equal(lltm$estimate[lltm$term == "x2"], 0.3, tolerance = 0.1)
  expect_true(all(!is.na(lltm$std_error[lltm$term %in% c("x1", "x2")])))
  expect_equal(sum(w$estimate[w$method == "forest"]), 1)
  p <- predict(m, data.frame(x1 = c(0, 1), x2 = 0, fam = c("f2", "f2")))
  expect_equal(diff(p), 0.8, tolerance = 0.1)
  # a family never seen in training is predicted as an average family
  pu <- predict(m, data.frame(x1 = 0, x2 = 0, fam = "new"))
  expect_equal(pu, mean(predict(m, data.frame(x1 = 0, x2 = 0, fam = d$fam))), tolerance = 0.05)
  expect_length(predict(m, d[1:3, ], method = "forest"), 3)
  expect_error(predict(m, d, method = "nope"), "No `nope` model")
  expect_s3_class(autoplot(m), "ggplot")

  # holding out whole families and the leakage check
  g <- predict_difficulty(d, c("x1", "x2", "fam"), group = "fam", methods = "lltm")
  expect_equal(g$folds, 4L)
  expect_true(all(tapply(g$cv$fold, d$fam, function(x) length(unique(x))) == 1))
  expect_lt(g$accuracy$r2, m$accuracy$r2[1])
  d$leak <- d$b + rnorm(n, 0, 0.01)
  l <- predict_difficulty(d, c("x1", "leak"), methods = "lltm")
  expect_named(l$leaky, "leak")
  expect_output(print(l), "Check: `leak`")
  expect_error(predict_difficulty(d, "nope"), "no column `nope`")
  expect_error(predict_difficulty(d[1:10, ], "x1"), "at least 20")
  same <- predict_difficulty(d, c("x1", "x2"), methods = "lasso")
  expect_equal(same$cv, predict_difficulty(d, c("x1", "x2"), methods = "lasso")$cv)
})
