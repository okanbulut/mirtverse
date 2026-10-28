test_that("graphics return ggplot objects that render", {
  plots <- list(gg_trace(mod_2pl), gg_trace(mod_grm), gg_trace(mod_grm, type = "expected", facet = FALSE),
                gg_info(mod_2pl), gg_info(mod_grm, "items"), gg_info(mod_2pl, "se"),
                gg_itemfit(mod_2pl), gg_q3(mod_grm), gg_scores(mod_2pl), gg_empirical(mod_grm, "Work"))
  for (p in plots) {
    expect_s3_class(p, "ggplot")
    expect_no_error(ggplot2::ggplot_build(p))
  }
  expect_s3_class(gg_wright(mod_grm), "patchwork")
  expect_s3_class(ggplot2::autoplot(mod_2pl, "info"), "ggplot")
})

test_that("trace data use the observed response categories", {
  td <- mirtverse:::trace_data(mod_grm, "Work")
  expect_equal(levels(td$category), c("1", "2", "3", "4"))
  expect_true(all(abs(tapply(td$prob, td$theta, sum) - 1) < 1e-8))
})

test_that("plots reject unsuitable models", {
  expect_error(gg_trace(mirt(lsat, 2, verbose = FALSE)), "unidimensional")
  expect_error(gg_trace(lsat), "single-group")
  expect_error(gg_trace(mod_2pl, which.items = "nope"), "Unknown item")
})
