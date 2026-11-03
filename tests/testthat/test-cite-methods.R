test_that("cite_methods describes a 2PL model with fit and references", {
  m <- cite_methods(mod_2pl, sample = "law school applicants")
  expect_s3_class(m, "mv_methods")
  txt <- paste(m$text, collapse = " ")
  expect_match(txt, "two-parameter logistic \\(2PL\\) model \\(Birnbaum, 1968\\)")
  expect_match(txt, "1,000 law school applicants to 5 dichotomously scored items")
  expect_match(txt, "M2\\(5\\) = ")
  expect_match(txt, "Bock & Aitkin, 1981")
  expect_match(txt, "Marginal reliability was \\.")
  # APA style: no leading zero for bounded statistics
  expect_false(grepl("RMSEA = 0\\.", txt))
  refs <- paste(m$references, collapse = " ")
  expect_match(refs, "Chalmers, R. P. \\(2012\\)")
  expect_match(refs, "Maydeu-Olivares")
  expect_match(refs, "zenodo.23719384")
  # references are alphabetical
  expect_identical(m$references, sort(m$references))
})

test_that("cite_methods uses C2 and the graded response model for polytomous items", {
  m <- cite_methods(mod_grm, item_fit = FALSE)
  txt <- paste(m$text, collapse = " ")
  expect_match(txt, "graded response model \\(Samejima, 1969\\)")
  expect_match(txt, "scored in 4 categories")
  expect_match(txt, "C2\\(")
  expect_true(any(grepl("Samejima", m$references)))
  expect_true(any(grepl("Cai, L., & Monroe", m$references)))
  expect_false(any(grepl("Orlando", m$references)))
})

test_that("cite_methods describes model selection and dropped items", {
  sel <- select_model(lsat, fit = FALSE, verbose = FALSE)
  m <- cite_methods(sel, fit = FALSE, item_fit = FALSE, dropped = c("Q3", "Q9"),
                    dropped_reason = "negative item-total correlations")
  txt <- paste(m$text, collapse = " ")
  expect_match(txt, "Bayesian information criterion \\(Schwarz, 1978\\)")
  expect_match(txt, sprintf("the %s model had the lowest value", sel$best_name), fixed = TRUE)
  expect_match(txt, "Likelihood-ratio tests between nested models")
  expect_match(txt, "Q3 and Q9 were removed before the final calibration because of negative")
  expect_true(any(grepl("^Schwarz", m$references)))
})

test_that("cite_methods prints, formats and writes files", {
  m <- cite_methods(mod_2pl, fit = FALSE, item_fit = FALSE)
  expect_output(print(m), "References")
  expect_type(format(m), "character")
  expect_length(format(m), 1)
  f <- tempfile(fileext = ".md")
  cite_methods(mod_2pl, fit = FALSE, item_fit = FALSE, file = f)
  expect_true(any(grepl("^## Method", readLines(f))))
  skip_if_not(rmarkdown::pandoc_available())
  d <- tempfile(fileext = ".docx")
  cite_methods(mod_2pl, fit = FALSE, item_fit = FALSE, file = d)
  expect_true(file.exists(d))
  # a relative path is written to the working directory, not pandoc's temp folder
  withr::with_tempfile("dir", {
    dir.create(dir)
    withr::with_dir(dir, cite_methods(mod_2pl, fit = FALSE, item_fit = FALSE, file = "m.docx"))
    expect_true(file.exists(file.path(dir, "m.docx")))
  })
})

test_that("cite_methods rejects objects that are not mirt models", {
  expect_error(cite_methods(lm(dist ~ speed, cars)), "single-group model")
})
