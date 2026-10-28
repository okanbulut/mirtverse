test_that("tidy returns IRT parameters with SEs", {
  td <- tidy(mod_2pl)
  expect_s3_class(td, "tbl_df")
  expect_equal(nrow(td), 10)
  expect_setequal(unique(td$term), c("a", "b"))
  expect_false(anyNA(td$std.error))
  ci <- tidy(mod_2pl, conf.int = TRUE)
  expect_true(all(ci$conf.low < ci$estimate & ci$estimate < ci$conf.high))
  cf <- coef(mod_2pl, IRTpars = TRUE, simplify = TRUE)$items
  expect_equal(td$estimate[td$item == "Item.1" & td$term == "b"], unname(cf["Item.1", "b"]))
})

test_that("tidy handles polytomous, multidimensional and multiple-group models", {
  expect_equal(nrow(tidy(mod_grm)), 16)
  m2 <- mirt(lsat, 2, verbose = FALSE)
  expect_true(all(c("a1", "a2", "d") %in% tidy(m2)$term))
  mg <- multipleGroup(lsat, 1, group = rep(c("A", "B"), 500), verbose = FALSE)
  tg <- tidy(mg)
  expect_true("group" %in% names(tg))
  expect_setequal(unique(tg$group), c("A", "B"))
})

test_that("glance gives one row with fit and reliability", {
  g <- glance(mod_2pl)
  expect_equal(nrow(g), 1)
  expect_equal(g$nobs, 1000)
  expect_equal(g$fit_stat, "M2")
  expect_true(g$reliability > 0 && g$reliability < 1)
  expect_equal(glance(mod_grm)$fit_stat, "C2")
})

test_that("augment adds scores and person fit", {
  a <- augment(mod_2pl, person_fit = TRUE)
  expect_equal(nrow(a), 1000)
  expect_true(all(c(".F1", ".se_F1", ".Zh") %in% names(a)))
  expect_error(augment(mod_2pl, data = data.frame(x = 1:3)), "one row per respondent")
})

test_that("item_table flags misfit and weak items", {
  it <- item_table(mod_2pl)
  expect_equal(nrow(it), 5)
  expect_true(all(c("discrimination", "location", "S_X2", "p.value", "flag") %in% names(it)))
  expect_match(it$flag[it$item == "Item.2"], "misfit")
})
