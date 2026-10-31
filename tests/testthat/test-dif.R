sim_dif_data <- function(n = 600, seed = 11) {
  set.seed(seed)
  a <- matrix(rlnorm(10, 0.2, 0.25))
  d <- matrix(rnorm(10))
  d2 <- d
  d2[1:2] <- d2[1:2] - 1.2
  dat <- rbind(simdata(a, d, n, itemtype = "2PL"),
               simdata(a, d2, n, itemtype = "2PL", mu = 0.3))
  data.frame(dat, gender = rep(c("F", "M"), each = n))
}
dif_dat <- sim_dif_data()
dif_res <- dif(dif_dat, group = "gender")

test_that("dif() finds the simulated DIF items and returns a tidy table", {
  expect_s3_class(dif_res, "mv_dif")
  tab <- tidy(dif_res)
  expect_s3_class(tab, "tbl_df")
  expect_equal(nrow(tab), 10)
  expect_false("gender" %in% tab$item)
  expect_setequal(tab$item[tab$flag], c("Item_1", "Item_2"))
  # items are harder for the focal group (M), so the signed difference is negative
  expect_true(all(tab$esd[1:2] < -0.1))
  expect_true(all(tab$uesd >= abs(tab$esd) - 1e-8))
  expect_true(all(tab$converged))
  expect_equal(dif_res$reference, "F")
  expect_equal(dif_res$which.par, c("a1", "d"))
})

test_that("dif() likelihood-ratio tests agree with mirt::DIF()", {
  ref <- DIF(dif_res$baseline, c("a1", "d"), scheme = "drop", p.adjust = "BH", verbose = FALSE)
  tab <- tidy(dif_res)
  expect_equal(tab$X2, unname(ref$X2), tolerance = 1e-4)
  expect_equal(tab$p.adjusted, unname(ref$adj_p), tolerance = 1e-4)
})

test_that("dif() accepts a grouping vector, a model and a subset of items", {
  items <- dif_dat[, 1:10]
  r1 <- dif(items, group = dif_dat$gender, items = c("Item_1", "Item_5"))
  expect_equal(tidy(r1)$item, c("Item_1", "Item_5"))
  r_fac <- dif(items, group = factor(dif_dat$gender, levels = c("M", "F")), items = "Item_1")
  expect_equal(r_fac$reference, "M")
  expect_gt(tidy(r_fac)$esd, 0.1)
  r2 <- dif(dif_res$baseline, items = 1:3)
  expect_equal(nrow(tidy(r2)), 3)
  expect_error(dif(items), "group")
  expect_error(dif(dif_dat, group = "sex"), "not in the data")
  expect_error(dif(mod_2pl, group = "x"), "multipleGroup")
})

test_that("dif() output prints, plots, interprets and goes into the report", {
  expect_output(print(dif_res), "DIF analysis")
  expect_s3_class(gg_dif(dif_res), "ggplot")
  expect_s3_class(gg_dif(dif_res, type = "curves"), "ggplot")
  txt <- as.character(interpret(dif_res))
  expect_true(any(grepl("2 of 10 items show DIF", txt)))
  expect_true(any(grepl("favours F", txt)))
  mod <- mirt(dif_dat[, 1:10], 1, verbose = FALSE)
  f <- tempfile(fileext = ".html")
  mv_report(mod, file = f, dif = dif_res, cards = FALSE, open = FALSE)
  html <- paste(readLines(f, warn = FALSE), collapse = "\n")
  expect_match(html, "DIF items")
})
