test_that("item cards and reports are written", {
  expect_s3_class(item_card(mod_grm, 1), "patchwork")
  f <- tempfile(fileext = ".html")
  item_cards(mod_grm, file = f)
  expect_true(file.exists(f))
  r <- tempfile(fileext = ".html")
  mv_report(mod_grm, file = r, open = FALSE)
  html <- readLines(r, warn = FALSE)
  expect_true(any(grepl("<style>", html, fixed = TRUE)))
  expect_true(any(grepl("Sum score conversion table", html, fixed = TRUE)))
  expect_true(any(grepl("data:image/png;base64", html, fixed = TRUE)))
})

test_that("item status follows the documented rules", {
  expect_equal(mirtverse:::item_status(data.frame(flag = "", item_total_r = 0.3)), "green")
  expect_equal(mirtverse:::item_status(data.frame(flag = "extreme location", item_total_r = 0.3)), "amber")
  expect_equal(mirtverse:::item_status(data.frame(flag = "misfit", item_total_r = 0.3)), "red")
})
