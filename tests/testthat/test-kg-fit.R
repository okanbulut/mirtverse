kg_wrong_link <- function() {
  kg <- mv_kg_subset(fractions_kg, c("meaning", "equivalent", "mixed"))
  e <- as.data.frame(kg$edges, stringsAsFactors = FALSE)
  e$to[e$from == "F05"] <- "meaning"
  mv_kg_build(c("meaning", "equivalent", "mixed"),
              edges = e[e$type == "prerequisite", c("from", "to")],
              items = data.frame(item = e$from[e$type == "measures"],
                                 concept = e$to[e$type == "measures"]),
              name = "toy")
}

test_that("mv_kg_fit() finds an item linked to the wrong concept", {
  kgw <- kg_wrong_link()
  fit <- suppressWarnings(mv_kg_fit(kgw, fractions, TOL = 0.01))
  expect_s3_class(fit, "mv_kg_fit")
  f <- tidy(fit)
  expect_equal(f$check, "wrong_link")
  expect_equal(f$action, "relink")
  expect_equal(c(f$from, f$to), c("F05", "equivalent"))
  it <- tidy(fit, "items")
  expect_equal(nrow(it), 13)
  expect_true(all(it$gap[it$item != "F05"] < 0.1))
  expect_equal(nrow(tidy(fit, "relations")), 3)
  g <- glance(fit)
  expect_equal(g$wrong_link, 1)
  expect_equal(g$n, 1200)
  expect_output(print(fit), "wrong_link: F05")

  refined <- mv_kg_refine(fit)
  q <- mv_kg_qmatrix(refined)
  expect_equal(unname(q["F05", c("meaning", "equivalent")]), c(0, 1))
  expect_match(refined$name, "\\(refined\\)$")
  expect_identical(mv_kg_refine(fit, "relations")$edges, mv_kg_refine(fit, integer())$edges)
  expect_error(mv_kg_refine(fit, 5), "outside")
  expect_s3_class(gg_kg_fit(fit), "ggplot")
  expect_s3_class(gg_kg_fit(fit, items = "all"), "ggplot")
  expect_s3_class(gg_kg_fit(fit, items = "none"), "ggplot")
})

test_that("mv_kg_fit() suggests a missing prerequisite in the easier-first direction", {
  kg3 <- mv_kg_subset(fractions_kg, c("meaning", "equivalent", "compare"))
  fit <- suppressWarnings(mv_kg_fit(kg3, fractions, TOL = 0.01))
  f <- tidy(fit)
  expect_equal(f$check, "missing_relation")
  expect_equal(c(f$action, f$from, f$to), c("add_prerequisite", "equivalent", "compare"))
  refined <- mv_kg_refine(fit)
  expect_equal(glance(refined)$prerequisite, glance(kg3)$prerequisite + 1)
  expect_s3_class(gg_kg_fit(fit), "ggplot")
  # the model can be passed in, and a stricter threshold removes the flag
  fit2 <- mv_kg_fit(kg3, fractions, model = fit$model, min_partial = 0.9)
  expect_equal(nrow(tidy(fit2)), 0)
  expect_output(print(fit2), "No flags")
})

test_that("mv_kg_fit() works on one concept and rejects other input", {
  kg1 <- mv_kg_subset(fractions_kg, "meaning")
  fit <- mv_kg_fit(kg1, fractions)
  expect_null(fit$relations)
  expect_equal(nrow(tidy(fit, "items")), 4)
  expect_error(mv_kg_refine(list()), "mv_kg_fit")
  expect_error(gg_kg_fit(list()), "mv_kg_fit")
})

test_that("mv_kg_explain() predicts item difficulty from the graph", {
  skip_if_not_installed("eirm")
  skip_if_not_installed("lme4")
  kg <- mv_kg_subset(fractions_kg, c("meaning", "equivalent", "mixed"))
  ex <- mv_kg_explain(kg, fractions)
  expect_s3_class(ex, "mv_kg_explain")
  e <- tidy(ex)
  expect_equal(e$term, c("meaning", "equivalent", "mixed"))
  # meaning items are the easiest in the simulation
  expect_equal(e$term[which.min(e$difficulty)], "meaning")
  it <- tidy(ex, "items")
  expect_equal(nrow(it), 13)
  expect_equal(it$residual, it$difficulty - it$predicted)
  g <- glance(ex)
  expect_true(g$explained > 0.5 && g$explained <= 1)
  expect_output(print(ex), "explains")
  exd <- mv_kg_explain(kg, fractions, predictors = "depth")
  expect_equal(tidy(exd)$term[1], "depth")
  expect_gt(tidy(exd)$difficulty[1], 0)
})

test_that("mv_kg_explain() checks its input", {
  skip_if_not_installed("eirm")
  skip_if_not_installed("lme4")
  poly <- fractions[, c("F01", "F02")]
  poly$F01[1] <- 2
  expect_error(mv_kg_explain(fractions_kg, poly), "0/1")
  flat <- mv_kg_subset(fractions_kg, c("meaning", "compare"))
  expect_error(mv_kg_explain(flat, fractions, "depth"), "same depth")
})

test_that("mv_kg_fit() flags a weak extra link and mv_kg_refine() drops it", {
  kg <- mv_kg_subset(fractions_kg, c("meaning", "equivalent", "mixed"))
  kgx <- mv_kg_edit(kg, add = data.frame(from = "F01", to = "equivalent"))
  fit <- suppressWarnings(mv_kg_fit(kgx, fractions, TOL = 0.01))
  f <- tidy(fit)
  expect_true("weak_link" %in% f$check)
  w <- f[f$check == "weak_link", ]
  expect_equal(c(w$from, w$to, w$action), c("F01", "equivalent", "drop_link"))
  it <- tidy(fit, "items")
  expect_equal(it$weakest_linked[it$item == "F01"], "equivalent")
  expect_equal(glance(fit)$weak_link, 1)
  expect_output(print(fit), "weak_link: F01")
  expect_s3_class(gg_kg_fit(fit), "ggplot")
  refined <- mv_kg_refine(fit, "items")
  q <- mv_kg_qmatrix(refined)
  expect_equal(unname(q["F01", c("meaning", "equivalent")]), c(1, 0))
})
