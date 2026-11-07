# Three raters (two people and an engine) score four 0-3 items; the engine
# can be harsh on item I2 for group B, and lenient on item I3 for everyone
sim_ratings <- function(n = 500, harsh = 0, lenient = 0, seed = 2) {
  set.seed(seed)
  g <- factor(sample(c("A", "B"), n, TRUE, prob = c(0.6, 0.4)), levels = c("A", "B"))
  theta <- stats::rnorm(n, ifelse(g == "B", -0.3, 0))
  b <- c(-1, 0, 1)
  rows <- lapply(sprintf("I%d", 1:4), function(it) {
    true <- rowSums(sapply(b, function(bk) stats::runif(n) < stats::plogis(1.5 * (theta - bk))))
    noisy <- function(x) pmin(pmax(x + sample(c(-1, 0, 0, 0, 0, 1), n, TRUE), 0), 3)
    m <- noisy(true)
    if (it == "I2") {
      hit <- g == "B" & m > 0 & stats::runif(n) < harsh
      m[hit] <- m[hit] - 1
    }
    if (it == "I3") {
      up <- m < 3 & stats::runif(n) < lenient
      m[up] <- m[up] + 1
    }
    data.frame(student = sprintf("P%03d", seq_len(n)), item = it, group = g,
               human1 = noisy(true), human2 = ifelse(stats::runif(n) < 0.5, noisy(true), NA),
               machine = m, stringsAsFactors = FALSE)
  })
  d <- do.call(rbind, rows)
  attr(d, "mc") <- data.frame(student = sprintf("P%03d", seq_len(n)),
                              sapply(seq(-1.5, 1.5, length.out = 12), function(bk)
                                as.integer(stats::runif(n) < stats::plogis(1.2 * (theta - bk)))))
  d
}

test_that("rater_facets() puts a fair engine among the human raters", {
  skip_if_not_installed("eirm")
  fx <- rater_facets(sim_ratings(), raters = c("human1", "human2", "machine"))
  expect_s3_class(fx, "mv_facets")
  expect_equal(fx$ai, "machine")
  expect_equal(nrow(fx$raters), 3)
  expect_lt(max(abs(fx$raters$severity)), 0.15)
  expect_equal(sum(fx$raters$severity), 0, tolerance = 1e-8)
  expect_equal(nrow(fx$flags), 0)
  expect_equal(nrow(fx$items), 12)
  expect_true(all(diff(fx$items$difficulty[fx$items$item == "I1"]) > 0))
  expect_equal(nrow(fx$persons), 500)
  expect_output(print(fx), "Rater facets: 3 raters \\(AI: machine\\)")
  expect_s3_class(gg_wright(fx), "patchwork")
})

test_that("rater_facets() finds an engine that is harsh for one group on one item", {
  skip_if_not_installed("eirm")
  fx <- rater_facets(sim_ratings(harsh = 0.6), raters = c("human1", "human2", "machine"),
                     group = "group", by_item = TRUE,
                     labels = c("Human 1", "Human 2", "Engine"))
  expect_setequal(fx$flags$check, c("rater severity", "differential severity"))
  expect_true(all(grepl("I2, B", fx$flags$target)))
  d <- fx$differential
  expect_gt(d$difference[d$item == "I2"], 0.3)
  expect_false(any(d$flag[d$item != "I2"]))
  expect_match(fx$flags$advice[fx$flags$check == "rater severity"], "^Engine is harsher")
  expect_s3_class(autoplot(fx, type = "bias"), "ggplot")
  expect_equal(nrow(tidy(fx)), nrow(fx$flags))
  # its flags join an audit
  a <- ai_audit(components = fx)
  expect_true("differential severity" %in% a$checks$check)
  va <- validity_argument(a)
  expect_match(va$evidence[va$inference == "Extrapolation"], "Differential severity")
})

test_that("rater_facets() takes long data and checks its input", {
  skip_if_not_installed("eirm")
  d <- sim_ratings(n = 200)
  long <- rbind(data.frame(d[, c("student", "item")], who = "H", score = d$human1),
                data.frame(d[, c("student", "item")], who = "AI", score = d$machine))
  fx <- rater_facets(long, raters = "who", score = "score")
  expect_equal(fx$ai, "AI")
  expect_equal(sort(fx$raters$rater), c("AI", "H"))
  expect_error(rater_facets(d, raters = c("human1", "nope")), "no column `nope`")
  d$human1[1] <- 0.5
  expect_error(rater_facets(d, raters = c("human1", "machine")), "whole numbers")
})

test_that("scoring_shift() finds thresholds an engine moves", {
  d <- sim_ratings(lenient = 0.4)
  sh <- scoring_shift(d, human = "human1", anchors = attr(d, "mc"), group = "group")
  expect_s3_class(sh, "mv_shift")
  expect_equal(nrow(sh$thresholds), 12)
  i3 <- sh$thresholds[sh$thresholds$item == "I3", ]
  expect_true(all(i3$shift < -0.3))
  expect_true(all(sh$thresholds$flag == (sh$thresholds$item == "I3")))
  expect_gt(sh$impact$change[sh$impact$group == "All"], 0)
  expect_equal(sh$anchors, sprintf("X%d", 1:12))
  expect_output(print(sh), "linked through 12 anchor items")
  expect_s3_class(gg_wright(sh), "patchwork")
  a <- ai_audit(components = list(sh))
  expect_true("threshold shift" %in% a$flags$check)
})

test_that("scoring_shift() works without anchors and checks anchors", {
  d <- sim_ratings(n = 400)
  sh <- scoring_shift(d, human = "human1")
  expect_lt(max(abs(sh$thresholds$shift)), 0.5)
  expect_lt(abs(sh$impact$change), 0.05)
  expect_output(print(sh), "no anchors")
  mc <- attr(d, "mc")
  mc$year <- 2026
  expect_error(scoring_shift(d, anchors = mc), "`year` is not an item")
  expect_error(scoring_shift(d, anchors = mc[, -1]), "needs the person column")
})
