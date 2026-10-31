mon_data <- local({
  set.seed(31)
  J <- 20; N <- 600
  a <- matrix(rlnorm(J, 0.2, 0.2)); d <- matrix(rnorm(J))
  sim <- function(n) {
    x <- as.data.frame(simdata(a, d, n, itemtype = "2PL"))
    names(x) <- sprintf("Q%02d", 1:J)
    x
  }
  fit <- function(x, title) suppressWarnings(
    calibrate(add_responses(mv_pipeline(title, verbose = FALSE), x, items = names(x)),
              model = "2PL"))
  x2 <- sim(N)
  x2[1:300, 11:20] <- NA                     # a second window where half the takers skip Q11-Q20
  content <- setNames(rep(c("Algebra", "Geometry", "Data"), c(10, 7, 3)), sprintf("Q%02d", 1:J))
  list(p1 = fit(sim(N), "Spring"), p2 = fit(x2, "Fall"), content = content)
})

test_that("monitor_bank records windows and flags items over-exposed twice", {
  p1 <- bank_items(mon_data$p1, name = "Test bank")
  p1 <- monitor_bank(p1, window = "2025 spring", date = "2025-04-01",
                     content = mon_data$content)
  expect_equal(p1$stages$status[p1$stages$stage == "monitoring"], "done")
  expect_equal(nrow(p1$monitoring$windows), 1L)
  expect_equal(nrow(p1$bank$usage), 20L)
  expect_true(all(p1$bank$usage$exposure == 1))
  expect_false("over_exposure" %in% flags(p1)$check)        # one window only
  expect_equal(unname(p1$bank$items$content[1:3]), rep("Algebra", 3))

  p2 <- suppressWarnings(monitor_bank(mon_data$p2, bank = p1$bank, window = "2025 fall",
                                      date = "2025-10-01"))
  expect_equal(nrow(p2$monitoring$windows), 2L)
  f <- flags(p2, stage = "monitoring")
  ox <- f$target[f$check == "over_exposure"]
  expect_setequal(ox, sprintf("Q%02d", 1:20))
  ex <- p2$bank$usage
  expect_equal(ex$exposure[ex$window == "2025 fall" & ex$item == "Q15"], 0.5)
  expect_equal(unname(p2$bank$items$content[20]), "Data")  # content kept in the bank

  # recording the same window again replaces it
  p3 <- suppressWarnings(monitor_bank(mon_data$p2, bank = p2$bank, window = "2025 fall",
                                      date = "2025-10-01"))
  expect_equal(nrow(p3$monitoring$windows), 2L)
  expect_equal(nrow(p3$bank$usage), 40L)

  # a stricter max_exposure share means fewer windows count
  p4 <- mon_data$p2
  p4$rules <- mv_rules(max_exposure = 0.6)
  p4 <- suppressWarnings(monitor_bank(p4, bank = p1$bank, window = "2025 fall",
                                      date = "2025-10-01"))
  ox4 <- flags(p4, stage = "monitoring")$target
  expect_setequal(ox4, sprintf("Q%02d", 1:10))
})

test_that("bank depth, reliability trend and unused items are flagged", {
  p <- bank_items(mon_data$p1, name = "Test bank")
  p <- monitor_bank(p, window = "w1", date = "2025-01-15", content = mon_data$content)
  bank <- p$bank
  bank$windows <- rbind(bank$windows, data.frame(window = "w2", date = as.Date("2026-03-01"),
                                                 n = 600L, reliability = bank$windows$reliability - 0.08))
  bank$usage <- rbind(bank$usage, data.frame(window = "w2", item = sprintf("Q%02d", 1:20),
                                             n = c(rep(600L, 14), rep(0L, 6)),
                                             exposure = c(rep(0.2, 14), rep(0, 6))))
  bank$items$added <- "2024-06-01"
  p <- monitor_bank(p, bank = bank, record = FALSE, min_items = c(Data = 4, Algebra = 5))
  f <- flags(p, stage = "monitoring")
  expect_equal(f$target[f$check == "bank_depth"], "Data")
  expect_true("reliability_trend" %in% f$check)
  expect_equal(f$level[f$check == "unused_items"], "info")    # Q15-Q20 last used Jan 2025
  expect_match(f$value[f$check == "unused_items"], "6 of 20")
  expect_false("over_exposure" %in% f$check)                  # w2 exposure 0.2
  use <- p$monitoring$items
  expect_equal(use$windows_used[use$item == "Q20"], 1L)
  expect_equal(use$last_used[use$item == "Q01"], as.Date("2026-03-01"))
  cells <- p$monitoring$cells
  expect_equal(cells$active[cells$cell == "Geometry"], 7L)
  expect_true(is.na(cells$minimum[cells$cell == "Geometry"]))

  # retiring items moves them out of use and deepens the shortage
  p2 <- retire_items(p, c("Q01", "Q02", "Q03", "Q04", "Q05", "Q06"), note = "Exposed")
  expect_equal(sum(p2$bank$items$status == "retired"), 6L)
  expect_equal(p2$stages$status[p2$stages$stage == "monitoring"], "needs rerun")
  p2 <- monitor_bank(p2, record = FALSE, min_items = c(Data = 4, Algebra = 5))
  expect_setequal(flags(p2, stage = "monitoring")$target[flags(p2, stage = "monitoring")$check ==
                                                           "bank_depth"], c("Algebra", "Data"))
  expect_match(utils::tail(p2$bank$history$detail, 2L)[1], "Exposed")

  # blueprint counts set the default minimum
  pb <- set_blueprint(p2, c(Algebra = 3, Geometry = 4, Data = 2))
  pb <- suppressWarnings(monitor_bank(pb, record = FALSE))
  cells <- pb$monitoring$cells
  expect_equal(cells$minimum[cells$cell == "Geometry"], 8)
  expect_setequal(flags(pb, stage = "monitoring")$target[flags(pb, stage = "monitoring")$check ==
                                                           "bank_depth"], c("Algebra", "Geometry", "Data"))
})

test_that("retire_items works on a bank and checks its input", {
  bank <- mv_bank(mon_data$p1$model)
  b2 <- retire_items(bank, "Q01", status = "review", note = "Check wording")
  expect_equal(b2$items$status[b2$items$item == "Q01"], "review")
  b3 <- retire_items(b2, "Q01", status = "active")
  expect_equal(b3$items$status[b3$items$item == "Q01"], "active")
  expect_error(retire_items(bank, "Z99"), "not in the bank")
  expect_error(monitor_bank(mv_pipeline(verbose = FALSE)), "item bank")
  expect_error(monitor_bank(mv_pipeline(verbose = FALSE), bank = bank), "calibrated pipeline")
  p <- monitor_bank(mv_pipeline(verbose = FALSE), bank = bank, record = FALSE)
  expect_equal(nrow(p$monitoring$windows), 0L)
  expect_equal(nrow(flags(p, stage = "monitoring")), 0L)
})

test_that("the report includes bank monitoring", {
  skip_if_not_installed("htmltools")
  p <- bank_items(mon_data$p1, name = "Test bank")
  p <- monitor_bank(p, window = "w1", date = "2025-01-15", content = mon_data$content)
  f <- tempfile(fileext = ".html")
  p <- suppressWarnings(pipeline_report(p, file = f, open = FALSE, cards = FALSE))
  html <- paste(readLines(f, warn = FALSE), collapse = "\n")
  expect_match(html, "<h2>Bank monitoring</h2>")
  expect_match(html, "Active items per content cell")
})
