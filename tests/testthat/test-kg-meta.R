meta24 <- function() data.frame(item = sprintf("F%02d", 1:24),
                                format = rep(c("choice", "open"), 12), words = 1:24)

test_that("mv_kg_annotate() adds item metadata that tidy() returns", {
  kg <- mv_kg_annotate(fractions_kg, meta24())
  expect_equal(names(kg$meta), c("item", "format", "words"))
  expect_equal(kg$meta$item, kg_item_names(kg))
  it <- tidy(kg, "items")
  expect_equal(names(it), c("item", "concepts", "n_concepts", "format", "words"))
  expect_equal(sum(it$n_concepts), glance(kg)$measures)
  expect_output(print(kg), "Item metadata: format, words")
  # a second call adds and replaces columns
  kg2 <- mv_kg_annotate(kg, data.frame(id = "F01", format = "essay", time = 30))
  expect_equal(kg2$meta$format[1:2], c("essay", NA))
  expect_equal(kg2$meta$words, 1:24)
  expect_equal(sum(!is.na(kg2$meta$time)), 1)
  # build takes it too, and subset and refine keep it
  expect_equal(fraction_subtraction_kg$meta$text[1], "5/3 - 3/4")
  sub <- mv_kg_subset(kg, c("meaning", "equivalent"))
  expect_equal(sub$meta$item, kg_item_names(sub))
  expect_equal(sub$meta$words, as.integer(sub("F", "", sub$meta$item)))
})

test_that("mv_kg_annotate() checks its input", {
  expect_error(mv_kg_annotate(fractions_kg, data.frame(x = 1)), "item id column")
  expect_error(mv_kg_annotate(fractions_kg, data.frame(item = c("F01", "F01"), a = 1:2)), "unique")
  expect_error(mv_kg_annotate(fractions_kg, data.frame(item = "F01")), "no columns")
  expect_error(mv_kg_annotate(fractions_kg, data.frame(item = "F01", concepts = 1)), "used by the graph")
  expect_error(mv_kg_annotate(fractions_kg, data.frame(item = "Z", a = 1)), "None of the ids")
  expect_warning(mv_kg_annotate(fractions_kg, data.frame(item = c("F01", "Z"), a = 1:2)), "skipped: Z")
  expect_error(mv_kg_annotate(list(), meta24()), "knowledge graph")
})

test_that("gg_kg() colours items by metadata", {
  kg <- mv_kg_annotate(fractions_kg, meta24())
  expect_s3_class(gg_kg(kg, colour = "format"), "ggplot")
  expect_s3_class(gg_kg(kg, colour = "words"), "ggplot")
  expect_error(gg_kg(kg, colour = "nope"), "available: format, words")
  expect_error(gg_kg(fractions_kg, colour = "format"), "has none")
  expect_error(gg_kg(kg, items = FALSE, colour = "format"), "items drawn")
})

test_that("mv_kg_explain() uses metadata as covariates", {
  skip_if_not_installed("eirm")
  skip_if_not_installed("lme4")
  kg <- mv_kg_subset(mv_kg_annotate(fractions_kg, meta24()), c("meaning", "equivalent", "mixed"))
  ex <- mv_kg_explain(kg, fractions, covariates = c("format", "words"))
  e <- tidy(ex)
  expect_equal(e$term, c("meaning", "equivalent", "mixed", "format_open", "words"))
  expect_equal(e$label[4], "format: open (vs choice)")
  expect_equal(glance(ex)$predictors, "concepts + format + words")
  expect_output(print(ex), "concepts and item metadata")
  expect_error(mv_kg_explain(kg, fractions, covariates = "nope"), "Available: format, words")
})
