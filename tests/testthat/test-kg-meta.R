# fractions_kg without its item text
bare_kg <- function() {
  kg <- fractions_kg
  kg$meta <- NULL
  kg
}

meta24 <- function() data.frame(item = sprintf("F%02d", 1:24),
                                format = rep(c("choice", "open"), 12), words = 1:24)

test_that("mv_kg_annotate() adds item metadata that tidy() returns", {
  kg <- mv_kg_annotate(bare_kg(), meta24())
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
  kg <- mv_kg_annotate(bare_kg(), meta24())
  expect_s3_class(gg_kg(kg, colour = "format"), "ggplot")
  expect_s3_class(gg_kg(kg, colour = "words"), "ggplot")
  expect_error(gg_kg(kg, colour = "nope"), "available: format, words")
  expect_error(gg_kg(bare_kg(), colour = "format"), "has none")
  expect_error(gg_kg(kg, items = FALSE, colour = "format"), "items drawn")
})

test_that("mv_kg_explain() uses metadata as covariates", {
  skip_if_not_installed("eirm")
  skip_if_not_installed("lme4")
  kg <- mv_kg_subset(mv_kg_annotate(bare_kg(), meta24()), c("meaning", "equivalent", "mixed"))
  ex <- mv_kg_explain(kg, fractions, covariates = c("format", "words"))
  e <- tidy(ex)
  expect_equal(e$term, c("meaning", "equivalent", "mixed", "format_open", "words"))
  expect_equal(e$label[4], "format: open (vs choice)")
  expect_equal(glance(ex)$predictors, "concepts + format + words")
  expect_output(print(ex), "concepts and item metadata")
  expect_error(mv_kg_explain(kg, fractions, covariates = "nope"), "Available: format, words")
})

test_that("mv_kg_edit() adds and drops edges and keeps metadata", {
  kg <- mv_kg_edit(fractions_kg,
    add = data.frame(from = c("equivalent", "F14"), to = c("compare", "common_denominator")),
    drop = data.frame(from = "F14", to = "compare"))
  expect_s3_class(kg, "mv_kg")
  expect_equal(kg$name, fractions_kg$name)
  cmp <- mv_kg_compare(kg, lab_truth("fractions")$graph)
  expect_equal(glance(cmp)$items_agree, 24)
  expect_equal(glance(cmp)$prerequisite_recall, 1)
  expect_identical(tidy(kg, "items")$item, sprintf("F%02d", 1:24))
  expect_equal(tidy(kg, "items")$text, tidy(fractions_kg, "items")$text)
  r <- mv_kg_edit(fractions_kg, add = data.frame(from = "meaning", to = "compare", type = "related"))
  expect_equal(sum(r$edges$type == "related"), 1)
  expect_equal(sum(mv_kg_edit(r, drop = data.frame(from = "compare", to = "meaning", type = "related"))$edges$type == "related"), 0)
  # adding an edge that is already there changes nothing
  expect_equal(nrow(mv_kg_edit(fractions_kg, add = data.frame(from = "F01", to = "meaning"))$edges),
               nrow(fractions_kg$edges))
  expect_warning(mv_kg_edit(fractions_kg, drop = data.frame(from = "F01", to = "meaning")), "F01 no longer")
  expect_error(mv_kg_edit(fractions_kg, drop = data.frame(from = "F01", to = "mixed")), "no measures edge")
  expect_error(mv_kg_edit(fractions_kg, add = data.frame(from = "F01", to = "nope")), "not in the graph")
  expect_error(mv_kg_edit(fractions_kg, add = data.frame(a = 1)), "needs columns")
  expect_error(mv_kg_edit(fractions_kg, add = data.frame(from = "meaning", to = "mixed", type = "x")),
               "Unknown edge type")
  expect_equal(mv_kg_edit(fractions_kg, name = "new")$name, "new")
})

test_that("fractions_kg has the text of its items", {
  it <- tidy(fractions_kg, "items")
  expect_false(anyNA(it$text))
  expect_equal(it$text[it$item == "F14"], "Which is larger, 3/4 or 5/6?")  # quoted in Labs 11 and 12
})
