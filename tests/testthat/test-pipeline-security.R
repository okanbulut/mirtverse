sec_data <- local({
  set.seed(21)
  J <- 30; N <- 1000
  a <- matrix(rlnorm(J, 0.2, 0.2)); d <- matrix(rnorm(J))
  theta <- matrix(rnorm(N))
  x <- simdata(a, d, N, itemtype = "2PL", Theta = theta)
  leaked <- sprintf("Q%02d", 1:6)
  cheat <- order(theta)[seq(50, 250, by = 10)]          # 21 weak test takers
  x[cheat, 1:6] <- 1
  key <- rep("A", J)
  raw <- matrix(ifelse(x == 1, "A", sample(c("B", "C", "D"), N * J, replace = TRUE)), N)
  low <- order(theta)[5]
  raw[low + 0, ] <- raw[low, ]
  copier <- order(theta)[6]
  raw[copier, ] <- raw[low, ]                           # copies every answer of a weak test taker
  colnames(raw) <- sprintf("Q%02d", 1:J)
  rt <- matrix(rlnorm(N * J, 3, 0.4), N)
  fast <- order(theta)[300:309]
  rt[fast, 1:15] <- rt[fast, 1:15] / 40
  site <- sprintf("S%02d", rep(1:20, each = 50))
  site[cheat] <- "S99"
  dat <- data.frame(id = sprintf("P%04d", 1:N), raw, stringsAsFactors = FALSE)
  rtd <- as.data.frame(rt); names(rtd) <- paste0("t", 1:J)
  dat <- cbind(dat, rtd)
  p <- suppressWarnings(calibrate(add_responses(mv_pipeline(verbose = FALSE), dat,
                                                items = sprintf("Q%02d", 1:J), key = key,
                                                id = "id", rt = paste0("t", 1:J)),
                                  model = "2PL"))
  list(p = p, leaked = leaked, cheat = cheat, copy = c(low, copier), fast = fast, site = site)
})

test_that("check_security() finds planted preknowledge, copying, timing and site problems", {
  p <- suppressWarnings(check_security(sec_data$p, leaked = sec_data$leaked, site = sec_data$site))
  sp <- p$security$persons
  pk <- sp$row[sp$check == "preknowledge"]
  expect_gt(mean(sec_data$cheat %in% pk), 0.6)
  expect_lt(length(setdiff(pk, sec_data$cheat)), 5)
  cp <- p$security$copying
  expect_true(any(cp$row_a == min(sec_data$copy) & cp$row_b == max(sec_data$copy)))
  tm <- sp$row[sp$check == "aberrant_timing"]
  expect_true(all(sec_data$fast %in% tm))
  expect_lt(length(setdiff(tm, sec_data$fast)), 5)
  f <- flags(p, stage = "security")
  expect_true(all(c("preknowledge", "answer_copying", "aberrant_timing", "site_anomaly") %in% f$check))
  expect_equal(f$target[f$check == "site_anomaly"], "S99")
  # flags hold counts, never respondent ids
  expect_false(any(grepl("P0", f$target)))
  expect_equal(p$stages$status[p$stages$stage == "security"], "done")
})

test_that("preknowledge_lr() is null for consistent responders", {
  items <- pipeline_bank_rows(sec_data$p, "x")
  set.seed(1)
  resp <- as.matrix(sec_data$p$data$responses)
  pk <- preknowledge_lr(items, resp[-sec_data$cheat, ], items$item %in% sec_data$leaked)
  expect_lt(mean(pk$p < 0.001), 0.01)
})

test_that("check_security() flags item leakage across windows", {
  p <- sec_data$p
  window <- rep(1:2, each = 500)
  p$data$responses$Q20[501:1000] <- ifelse(runif(500) < 0.5, 1, p$data$responses$Q20[501:1000])
  p$data$rt$Q20[501:1000] <- p$data$rt$Q20[501:1000] / 3
  q <- suppressWarnings(check_security(p, window = window))
  f <- flags(q, stage = "security")
  expect_true("Q20" %in% f$target[f$check == "item_leakage"])
  expect_lt(sum(f$check == "item_leakage"), 3)
  expect_error(suppressWarnings(check_security(p, window = 1:3)), "one value per respondent")
})

test_that("check_security() flags parameter drift from the bank and large score gains", {
  set.seed(4)
  a <- matrix(rlnorm(20, 0.2, 0.2)); d <- matrix(rnorm(20))
  d2 <- d; d2[7] <- d2[7] - 1
  x1 <- simdata(a, d, 1500, itemtype = "2PL"); x2 <- simdata(a, d2, 1500, itemtype = "2PL")
  colnames(x1) <- colnames(x2) <- sprintf("I%02d", 1:20)
  old <- suppressWarnings(calibrate(add_responses(mv_pipeline("Old", verbose = FALSE), x1),
                                    model = "2PL"))
  bank <- bank_items(old)$bank
  new <- suppressWarnings(calibrate(add_responses(mv_pipeline("New", verbose = FALSE), x2,
                                                  id = sprintf("R%04d", 1:1500)), model = "2PL"))
  new <- suppressWarnings(link_to_bank(new, bank, anchors = sprintf("I%02d", c(1:6, 8:20))))
  new$bank <- bank
  prior <- data.frame(id = sprintf("R%04d", 1:1500), theta = 0, se = 0.3)
  prior$theta[1:5] <- -4
  q <- suppressWarnings(check_security(new, prior = prior))
  f <- flags(q, stage = "security")
  expect_equal(f$target[f$check == "parameter_drift"], "I07")
  expect_true("score_gain" %in% f$check)
  expect_true(all(1:5 %in% q$security$persons$row[q$security$persons$check == "score_gain"]))
})

test_that("check_security() needs something to check", {
  p <- suppressWarnings(calibrate(add_responses(mv_pipeline(verbose = FALSE),
                                                expand.table(LSAT7)), model = "2PL"))
  expect_error(suppressWarnings(check_security(p)), "No security check")
  expect_error(suppressWarnings(check_security(p, leaked = "Nope")), "not in the model")
})

test_that("rt_residuals() is centred for ordinary test takers", {
  set.seed(9)
  rt <- matrix(rlnorm(200 * 10, 3, 0.5), 200)
  z <- rt_residuals(rt)
  expect_lt(abs(mean(z)), 0.05)
  expect_lt(abs(stats::sd(as.vector(z)) - 1), 0.1)
})

test_that("the report summarizes security checks without naming anyone", {
  p <- suppressWarnings(check_security(sec_data$p, leaked = sec_data$leaked))
  f <- tempfile(fileext = ".html")
  p <- suppressWarnings(pipeline_report(p, file = f, open = FALSE, cards = FALSE))
  html <- paste(readLines(f, warn = FALSE), collapse = "\n")
  expect_match(html, "<h2>Test security</h2>")
  expect_false(grepl(sec_data$p$data$id[sec_data$cheat[1]], html, fixed = TRUE))
})
