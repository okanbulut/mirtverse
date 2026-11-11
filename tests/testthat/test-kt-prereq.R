test_that("mv_kt_prereq() finds the prerequisite the published graph misses", {
  kt <- mv_kt_fit(fractions_logs, kg = fractions_kg, seed = 1)
  ch <- mv_kt_prereq(kt)
  expect_s3_class(ch, "mv_kt_prereq")
  f <- tidy(ch, "flags")
  expect_equal(f$check, "missing_prerequisite")
  expect_equal(c(f$from, f$to), c("equivalent", "compare"))
  p <- tidy(ch)
  expect_equal(nrow(p), 30)
  expect_equal(p$from[1], "equivalent")
  expect_equal(p$to[1], "compare")
  expect_true(all(p$verdict[p$edge] == "supported"))
  g <- glance(ch)
  expect_equal(c(g$edges, g$supported, g$missing), c(5, 5, 1))
  expect_output(print(ch), "missing_prerequisite")

  # with the edge added, the logs agree with the graph
  kg2 <- mv_kg_edit(fractions_kg, add = data.frame(from = "equivalent", to = "compare"))
  ch2 <- mv_kt_prereq(kt, kg = kg2)
  expect_equal(nrow(tidy(ch2, "flags")), 0)
  expect_output(print(ch2), "No flags")
})

test_that("mv_kt_prereq() flags an edge the logs do not support", {
  kt <- mv_kt_fit(fractions_logs, kg = fractions_kg, seed = 1)
  kg <- mv_kg_edit(fractions_kg, add = data.frame(from = c("equivalent", "mixed"),
                                                  to = c("compare", "compare")))
  ch <- mv_kt_prereq(kt, kg = kg)
  f <- tidy(ch, "flags")
  expect_true("weak_prerequisite" %in% f$check)
  expect_equal(f$from[f$check == "weak_prerequisite"], "mixed")
})

test_that("mv_kt_prereq() checks its input", {
  expect_error(mv_kt_prereq(list()), "mv_kt_fit")
  kt <- mv_kt_fit(cognitive_tutor, skills = "Plot pi", seed = 1)
  expect_error(mv_kt_prereq(kt), "knowledge graph")
  expect_error(mv_kt_prereq(kt, kg = fractions_kg), "two of the model's skills")
})

test_that("mv_kt_irt() compares forecasts and item difficulty", {
  skip_if_not_installed("lme4")
  cmp <- mv_kt_irt(cognitive_tutor, item = "problem",
                   skills = c("Plot pi", "Plot imperfect radical"), seed = 1)
  expect_s3_class(cmp, "mv_kt_irt")
  a <- tidy(cmp)
  expect_equal(nrow(a), 4)
  expect_setequal(a$model, c("BKT", "IRT (1PL)"))
  it <- tidy(cmp, "items")
  expect_true(all(it$correlation < -0.5))
  expect_true(all(c("item", "difficulty", "guess") %in% names(tidy(cmp, "difficulty"))))
  g <- glance(cmp)
  expect_equal(g$n_skills, 2)
  expect_output(print(cmp), "IRT item difficulty vs log BKT guess")
  expect_error(mv_kt_irt(cognitive_tutor, holdout = 2), "between 0 and 1")
})
