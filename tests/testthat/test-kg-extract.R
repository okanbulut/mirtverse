test_that("mv_kg_extract() drafts links from item text and checks the answer", {
  skip_if_not_installed("ellmer")
  old <- suppressMessages(mv_llm_replay())
  on.exit(options(old))
  draft <- mv_kg_extract(fraction_subtraction_kg, subject = "Middle school fraction subtraction")
  expect_s3_class(draft, c("mv_kg_draft", "mv_kg"))
  expect_equal(kg_concept_names(draft), kg_concept_names(fraction_subtraction_kg))
  expect_equal(length(kg_item_names(draft)), 20)
  expect_equal(draft$meta$text, fraction_subtraction_kg$meta$text)
  f <- tidy(draft, "flags")
  expect_setequal(f$check, c("unknown_item", "unknown_concept", "two_way", "cycle", "new_concept"))
  expect_equal(sum(f$check == "two_way"), 1)
  expect_true(glance(draft)$acyclic)
  expect_false(any(kg_prereq(draft)$from == "column_borrow" & kg_prereq(draft)$to == "subtract_numerators"))
  r <- tidy(draft, "reasons")
  expect_equal(sum(!r$kept), 4)
  expect_true(all(c("measures", "prerequisite") %in% r$type))
  expect_equal(nrow(tidy(draft, "items")), 20)
  expect_output(print(draft), "EXPERIMENTAL")

  cmp <- mv_kg_compare(draft, fraction_subtraction_kg)
  expect_s3_class(cmp, "mv_kg_compare")
  g <- glance(cmp)
  expect_equal(g$match, "name")
  expect_equal(g$items_agree, 16)
  expect_equal(round(g$link_recall, 3), round(53 / 56, 3))
  expect_true(is.na(g$prerequisite_recall))
  it <- tidy(cmp, "items")
  expect_equal(it$missing[it$item == "FS01"], "column_borrow")
  expect_equal(it$extra[it$item == "FS08"], "reduce_answer")
  expect_output(print(cmp), "16 of 20 items")
})

test_that("mv_kg_extract() can propose the concepts", {
  skip_if_not_installed("ellmer")
  old <- suppressMessages(mv_llm_replay())
  on.exit(options(old))
  items <- itemtext[endsWith(itemtext$id, "-01"), c("id", "domain", "stem")]
  d <- mv_kg_extract(items, subject = "Grade 7 numeracy")
  expect_equal(length(kg_concept_names(d)), 6)
  expect_equal(tidy(d, "flags")$check, "unknown_item")
  # a link given by the concept's label is kept
  it <- tidy(d, "items")
  expect_match(it$concepts[it$item == "N05-01"], "data_chance")
  expect_equal(names(d$meta), c("item", "domain", "stem"))
  expect_s3_class(gg_kg(d, colour = "domain"), "ggplot")
  ref <- mv_kg_build(unique(items$domain), items = data.frame(item = items$id, concept = items$domain))
  cmp <- mv_kg_compare(d, ref)
  expect_equal(cmp$match, "items")
  cm <- tidy(cmp, "concepts")
  expect_equal(cm$matched[cm$concept == "measurement"], "Measurement")
  expect_equal(glance(cmp)$link_recall, 1)
  expect_output(print(cmp), "matched by their items")
})

test_that("mv_kg_extract() checks its input", {
  expect_error(mv_kg_extract(fractions_kg), "no item metadata")
  expect_error(mv_kg_extract(data.frame(x = 1)), "id column")
  expect_error(mv_kg_extract(data.frame(id = "a", y = 1)), "text column")
  expect_error(mv_kg_extract(data.frame(id = c("a", "a"), text = "x")), "unique")
  expect_error(mv_kg_extract(data.frame(id = "a", text = "")), "no text")
  expect_error(mv_kg_extract(data.frame(id = "a", text = "x"), concepts = "a"), "different names")
  expect_error(mv_kg_extract(data.frame(id = "a", text = "x"), provider = "none"), "language model")
  expect_error(mv_kg_compare(fractions_kg, fraction_subtraction_kg), "no items in common")
})

test_that("the answer checks handle odd model output", {
  res <- list(concepts = list(),
              links = data.frame(item = c("[A]", "B", "B"), concept = c("x", "x", "x"),
                                 reason = "r"),
              prerequisites = data.frame(from = c("x", "x", "y", "q"), to = c("y", "x", "z", "x"),
                                         confidence = c(0.5, 0.9, 0.2, 0.3), reason = "r"))
  given <- data.frame(concept = c("x", "y", "z"), label = c("x", "y", "z"), description = NA)
  d <- kg_extract_assemble(res, c("A", "B", "C"), given, TRUE)
  expect_equal(d$links$item, c("A", "B"))
  expect_equal(d$prereq$from, c("x", "y"))
  expect_setequal(d$flags$check, c("unlinked_item", "self_loop", "unknown_concept"))
  # proposed concepts are cleaned and made unique
  res2 <- list(concepts = data.frame(concept = c("Unit Rate", "unit rate", "3d"),
                                     label = c("Unit rate", "", ""), description = ""),
               links = list(list(item = "A", concept = "Unit Rate", reason = "")),
               prerequisites = list())
  d2 <- kg_extract_assemble(res2, c("A"), NULL, TRUE)
  expect_equal(d2$concepts$concept, c("unit_rate", "c_3d"))
  expect_equal(d2$links$concept, "unit_rate")
  expect_equal(d2$flags$check, "duplicate_concept")
})
