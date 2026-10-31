# Chunks of a learnr tutorial, keyed by label: list(options = <string>, code = <character>)
lab_chunks <- function(name) {
  path <- testthat::test_path("..", "..", "inst", "tutorials", name, paste0(name, ".Rmd"))
  if (!file.exists(path))
    path <- system.file("tutorials", name, paste0(name, ".Rmd"), package = "mirtverse")
  lines <- readLines(path, warn = FALSE)
  starts <- grep("^```\\{r", lines)
  ends <- grep("^```\\s*$", lines)
  out <- list()
  for (s in starts) {
    e <- ends[ends > s][1]
    header <- sub("^```\\{r\\s*", "", sub("\\}\\s*$", "", lines[s]))
    label <- trimws(sub(",.*$", "", header))
    opts <- if (grepl(",", header)) sub("^[^,]*,", "", header) else ""
    out[[label]] <- list(options = opts, code = lines[seq_len(e - s - 1L) + s])
  }
  out
}

# Runs an exercise's solution after its setup, then its -check chunk through lab_checker()
run_solution <- function(chunks, label) {
  env <- new.env(parent = globalenv())
  env$tutorial_options <- function(...) invisible(NULL)
  eval(parse(text = chunks$setup$code), envir = env)
  setup <- regmatches(chunks[[label]]$options,
                      regexec("exercise.setup\\s*=\\s*\"([^\"]+)\"", chunks[[label]]$options))[[1]]
  if (length(setup)) eval(parse(text = chunks[[setup[2]]]$code), envir = env)
  sol <- chunks[[paste0(label, "-solution")]]$code %||% chunks[[label]]$code
  value <- withr::with_output_sink(tempfile(), eval(parse(text = sol), envir = env))
  lab_checker(label = label, check_code = paste(chunks[[paste0(label, "-check")]]$code, collapse = "\n"),
              envir_result = env, last_value = value, stage = "check")
}

test_that("list_labs() finds the installed labs and run_lab() rejects unknown names", {
  labs <- list_labs()
  expect_setequal(labs$name, c("cat-design", "decisions", "fairness", "linking", "model-choice"))
  expect_match(labs$title[labs$name == "model-choice"], "Choosing a model")
  expect_true(nchar(labs$description[labs$name == "model-choice"]) > 50)
  expect_error(run_lab("nope"), "Unknown lab")
})

test_that("lab_checker() passes, fails and explains", {
  # learnr can rebuild the checker outside the package namespace
  lab_checker <- lab_checker
  environment(lab_checker) <- globalenv()
  env <- new.env()
  env$x <- 1:3
  ok <- lab_checker(check_code = "lab_need(length(x) == 3, 'three')\n'Nice.'",
                    envir_result = env, stage = "check")
  expect_true(ok$correct)
  expect_equal(ok$message, "Nice.")
  bad <- lab_checker(check_code = "lab_need(length(x) == 4, 'Need four.')",
                     envir_result = env, stage = "check")
  expect_false(bad$correct)
  expect_equal(bad$message, "Need four.")
  err <- lab_checker(check_code = "stop('boom')", envir_result = env, stage = "check")
  expect_false(err$correct)
  expect_match(err$message, "boom")
  expect_null(lab_checker(check_code = "TRUE", envir_result = env, stage = "code_check"))
})

test_that("lab_decisions() tabulates answered and unanswered questions", {
  state <- list(q1 = list(type = "question", answer = "*2PL*", correct = TRUE),
                q2 = list(type = "question", answer = "Rasch", correct = FALSE))
  out <- lab_decisions(state, c(q1 = "Model", q2 = "Again", q3 = "Later"))
  expect_equal(out$Decision, c("Model", "Again", "Later"))
  expect_equal(out$Verdict, c("Defensible", "Revisit", ""))
  expect_equal(out$`Your answer`[c(1, 3)], c("2PL", "(not answered yet)"))
})

test_that("certexam has the problems the labs rely on", {
  truth <- lab_truth()
  expect_equal(dim(certexam), c(1200L, 34L))
  expect_equal(names(certexam_key), sprintf("Q%02d", 1:32))
  expect_equal(names(which(certexam_key != truth$key)), "Q14")
  expect_equal(truth$key[["Q14"]], "A")  # hard-coded in the labs
  bad <- key2binary(certexam[, -(1:2)], certexam_key)
  rest_r <- vapply(seq_len(ncol(bad)), function(j) cor(bad[, j], rowSums(bad[, -j])), numeric(1))
  expect_equal(colnames(bad)[which.min(rest_r)], "Q14")
  expect_lt(min(rest_r), 0)
  scored <- key2binary(certexam[, -(1:2)], truth$key)
  m <- mirt(scored, 1, itemtype = "2PL", verbose = FALSE)
  q3 <- residuals(m, type = "Q3", verbose = FALSE)
  diag(q3) <- 0
  expect_gt(q3["Q21", "Q22"], 0.2)
  q3[c("Q21", "Q22"), c("Q21", "Q22")] <- 0
  expect_lt(max(abs(q3)), 0.2)
})

test_that("numeracy has the DIF the fairness lab relies on", {
  truth <- lab_truth("numeracy")
  expect_identical(lab_truth(), lab_truth("certexam"))
  expect_equal(dim(numeracy), c(2000L, 33L))
  expect_equal(levels(numeracy$ell), c("Fluent", "ELL"))
  expect_equal(numeracy_items$item, sprintf("N%02d", 1:30))
  expect_setequal(names(truth$dif), c("N02", "N03", "N07", "N18", "N20", "N21", "N25", "N30"))
  scored <- numeracy[, -(1:3)]
  gap <- colMeans(scored[numeracy$ell == "ELL", ]) - colMeans(scored[numeracy$ell == "Fluent", ])
  expect_equal(names(which(gap > 0)), "N21")  # quoted in the lab
  expect_true(all(numeracy_items$format[match(truth$no_dif_long, numeracy_items$item)] == "Word problem"))
})

test_that("linking has the NEAT design and drift the linking lab relies on", {
  truth <- lab_truth("linking")
  expect_equal(dim(linking), c(2000L, 70L))
  expect_equal(levels(linking$form), c("A", "B"))
  a_rows <- linking$form == "A"
  expect_true(all(is.na(linking[a_rows, sprintf("B%02d", 1:28)])))
  expect_true(all(is.na(linking[!a_rows, sprintf("A%02d", 1:28)])))
  expect_false(anyNA(linking[, truth$anchors]))
  expect_equal(names(truth$drift), "C07")
  expect_equal(truth$cut_A, 22L)  # hard-coded in the lab
})

test_that("catbank has the weaknesses the CAT lab relies on", {
  truth <- lab_truth("catbank")
  expect_equal(dim(catbank), c(180L, 5L))
  expect_equal(sum(catbank$fixed), 40L)
  expect_equal(as.vector(table(catbank$area)), rep(45L, 4))
  expect_lte(sum(catbank$b > 1.5), 2L)
  info0 <- catbank$a^2 * plogis(-catbank$a * catbank$b) * (1 - plogis(-catbank$a * catbank$b))
  expect_equal(catbank$item[which.max(info0)], "M012")  # hard-coded in the lab
  expect_true(all(truth$stars %in% catbank$item[catbank$area == "Algebra"]))
})

for (lab in c("model-choice", "decisions", "fairness", "linking", "cat-design")) {
  test_that(paste("every", lab, "solution passes its own check"), {
    skip_on_cran()
    chunks <- lab_chunks(lab)
    checked <- sub("-check$", "", grep("-check$", names(chunks), value = TRUE))
    expect_gt(length(checked), 1L)
    for (label in checked) {
      res <- run_solution(chunks, label)
      expect_true(res$correct, info = paste(lab, label, ":", res$message))
    }
  })

  test_that(paste(lab, "exercises without checks run without error"), {
    skip_on_cran()
    withr::local_pdf(NULL)
    chunks <- lab_chunks(lab)
    runnable <- names(chunks)[grepl("exercise\\s*=\\s*TRUE", vapply(chunks, `[[`, "", "options"))]
    plain <- setdiff(runnable, sub("-check$", "", grep("-check$", names(chunks), value = TRUE)))
    for (label in plain) {
      env <- new.env(parent = globalenv())
      env$tutorial_options <- function(...) invisible(NULL)
      eval(parse(text = chunks$setup$code), envir = env)
      setup <- regmatches(chunks[[label]]$options,
                          regexec("exercise.setup\\s*=\\s*\"([^\"]+)\"", chunks[[label]]$options))[[1]]
      if (length(setup)) eval(parse(text = chunks[[setup[2]]]$code), envir = env)
      code <- chunks[[paste0(label, "-solution")]]$code %||% chunks[[label]]$code
      res <- tryCatch({
        withr::with_output_sink(tempfile(), print(eval(parse(text = code), envir = env)))
        NULL
      }, error = function(e) conditionMessage(e))
      expect_null(res, label = paste(lab, label))
    }
  })
}
