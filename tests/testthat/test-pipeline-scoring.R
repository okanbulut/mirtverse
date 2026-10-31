oe_pipe <- function() {
  op <- data.frame(id = c("E1", "E2"), type = "open", cell = "Writing",
                   stem = c("Explain why the sky is blue.", "Describe the water cycle."))
  rub <- data.frame(score = 0:3, descriptor = c("none", "some", "most", "all"),
                    anchor = c("?", "light", "scattered light", "Rayleigh scattering of light"))
  op$rubric <- list(rub, rub)
  add_items(mv_pipeline(verbose = FALSE), op)
}

oe_responses <- function(n = 300, noise = 0.4, seed = 1) {
  set.seed(seed)
  true <- sample(0:3, n, replace = TRUE)
  h <- function() pmin(3, pmax(0, round(true + stats::rnorm(n, 0, noise))))
  data.frame(person = sprintf("P%03d", seq_len(n)), item = "E1",
             response = paste("answer with words", true, "level"),
             true = true, human1 = h(), human2 = h(),
             group = rep(c("a", "b"), length.out = n), stringsAsFactors = FALSE)
}

# a stand-in for a model trained on human scores
fake_model <- function(noise, bias = 0) structure(list(noise = noise, bias = bias),
                                                   class = "fake_scorer")
predict.fake_scorer <- function(object, newdata, ...)
  newdata$true + object$bias + stats::rnorm(nrow(newdata), 0, object$noise)
registerS3method("predict", "fake_scorer", predict.fake_scorer)
registerS3method("predict", "group_biased", function(object, newdata, ...)
  newdata$true + ifelse(newdata$group == "b", 0.8, 0))

test_that("qwk() matches a hand computation and is 1 for perfect agreement", {
  expect_equal(qwk(c(0, 1, 2, 3), c(0, 1, 2, 3)), 1)
  x <- c(0, 0, 1, 1, 2, 2); y <- c(0, 1, 1, 2, 2, 2)
  lv <- 0:2
  O <- table(factor(x, lv), factor(y, lv)) / 6
  E <- outer(rowSums(O), colSums(O))
  W <- outer(1:3, 1:3, function(i, j) (i - j)^2) / 4
  expect_equal(qwk(x, y), 1 - sum(W * O) / sum(W * E))
  expect_true(is.na(qwk(1, 1)))
})

test_that("score_open() with a trained model passes the gate when it agrees with people", {
  set.seed(2)
  p <- score_open(oe_pipe(), oe_responses(), scorer = fake_model(0.3))
  a <- p$agreement
  expect_equal(a$item, "E1")
  expect_equal(a$double_scored, 300L)
  expect_gt(a$qwk_machine, 0.85)
  expect_true(all(p$open_scores$machine %in% 0:3))
  f <- flags(p, stage = "scoring")
  expect_false(any(c("machine_agreement", "human_agreement", "validation_n",
                     "score_distribution") %in% f$check))
  expect_match(p$stages$summary[p$stages$stage == "scoring"], "trained model \\(fake_scorer\\)")
})

test_that("score_open() blocks a biased or noisy scorer and checks subgroups", {
  set.seed(3)
  p <- score_open(oe_pipe(), oe_responses(), scorer = fake_model(1.5))
  expect_true("machine_agreement" %in% flags(p)$check)
  set.seed(3)
  rs <- oe_responses()
  q <- score_open(oe_pipe(), rs, scorer = structure(list(), class = "group_biased"))
  expect_true("subgroup_fairness" %in% flags(q)$check)
  rs2 <- oe_responses(n = 120, noise = 1.2)
  q2 <- score_open(oe_pipe(), rs2, scorer = fake_model(0.2))
  f <- flags(q2)
  expect_true(all(c("validation_n", "human_agreement") %in% f$check))
})

test_that("score_open() routes short, off-topic and unsure responses to people", {
  skip_if_not_installed("ellmer")
  rs <- oe_responses(n = 6)
  rs$response[2] <- "idk"
  local_mocked_bindings(
    item_llm = function(provider, model) list(provider = "claude", model = "m"),
    llm_score_batch = function(llm, stem, rubric, responses) {
      n <- length(responses)
      data.frame(score = rep(2, n), rationale = "fits level 2", confidence = c(0.9, 0.9, 0.2, 0.9, 0.9, 0.9)[seq_len(n)],
                 off_topic = c(FALSE, FALSE, FALSE, TRUE, FALSE, FALSE)[seq_len(n)])
    })
  p <- score_open(oe_pipe(), rs, scorer = "llm")
  s <- p$open_scores
  expect_equal(which(s$routed), c(2L, 3L, 4L))
  expect_equal(s$final[2:4], s$human1[2:4])
  expect_equal(s$final[1], 2)
  expect_equal(flags(p)$value[flags(p)$check == "low_confidence"], "3 responses routed to humans")
  expect_match(s$rationale[1], "level 2")
})

test_that("score_open() checks its inputs", {
  expect_error(score_open(oe_pipe(), data.frame(person = 1, item = "E1")), "columns")
  expect_error(score_open(oe_pipe(), data.frame(person = 1, item = "Z", response = "x"),
                          scorer = fake_model(0)), "not in the pool")
  expect_error(score_open(oe_pipe(), oe_responses(5), scorer = structure(list(), class = "bad")),
               "predict")
})

test_that("open scores join the response data for a mixed calibration", {
  set.seed(5)
  dat <- expand.table(LSAT7)[1:300, ]
  p <- suppressWarnings(add_responses(oe_pipe(), dat, id = sprintf("P%03d", 1:300)))
  p <- suppressWarnings(score_open(p, oe_responses(), scorer = fake_model(0.3), add_to_data = TRUE))
  expect_true("E1" %in% names(p$data$responses))
  expect_equal(p$data$responses$E1, p$open_scores$final)
  p <- suppressWarnings(calibrate(p, model = "graded"))
  expect_true("E1" %in% colnames(p$model@Data$data))
})

test_that("score_persons() estimates abilities and flags imprecise scores", {
  p <- suppressWarnings(calibrate(add_responses(mv_pipeline(verbose = FALSE),
                                                expand.table(LSAT7)), model = "2PL"))
  p <- suppressWarnings(score_persons(p, method = "ML"))
  expect_equal(nrow(p$scores), 1000L)
  f <- flags(p, stage = "scoring")
  expect_true(all(c("score_reliability", "extreme_scores") %in% f$check))
  expect_match(f$advice[f$check == "extreme_scores"], "EAP or WLE")
  p <- suppressWarnings(score_persons(p))
  expect_true(all(is.finite(p$scores$theta)))
  p <- suppressWarnings(calibrate(p, model = "2PL"))
  expect_null(p$scores)
  expect_equal(p$stages$status[p$stages$stage == "scoring"], "needs rerun")
})

test_that("the report shows the scoring section", {
  set.seed(6)
  dat <- expand.table(LSAT7)[1:300, ]
  p <- suppressWarnings(add_responses(oe_pipe(), dat, id = sprintf("P%03d", 1:300)))
  p <- suppressWarnings(calibrate(p, model = "2PL"))
  p <- suppressWarnings(score_open(p, oe_responses(), scorer = fake_model(0.3)))
  p <- suppressWarnings(score_persons(p))
  f <- tempfile(fileext = ".html")
  p <- suppressWarnings(pipeline_report(p, file = f, open = FALSE, cards = FALSE))
  html <- paste(readLines(f, warn = FALSE), collapse = "\n")
  expect_match(html, "<h2>Scoring</h2>")
  expect_match(html, "quadratic weighted kappa")
  expect_match(html, "scored by EAP")
})
