ask_dat <- local({
  set.seed(5)
  a <- matrix(rlnorm(8, 0.2, 0.25)); d <- matrix(rnorm(8))
  x <- as.data.frame(simdata(a, d, 600, itemtype = "2PL"))
  names(x) <- paste0("Q", 1:8)
  data.frame(student_id = seq_len(600), x,
             gender = rep(c("F", "M"), 300), stringsAsFactors = FALSE)
})

test_that("profile_data() guesses column roles and keeps no data values", {
  p <- profile_data(ask_dat)
  expect_s3_class(p, "mv_profile")
  expect_equal(attr(p, "n"), 600)
  role <- setNames(p$role, p$column)
  expect_equal(unname(role[paste0("Q", 1:8)]), rep("item", 8))
  expect_equal(role[["gender"]], "group")
  expect_equal(role[["student_id"]], "id")
  expect_equal(p$levels[p$column == "gender"], "F, M")
  expect_true(all(is.na(p$levels[p$role != "group"])))
  expect_output(print(p), "8 look like items")
  expect_equal(mirtverse:::guess_role("performance1", c(0, 1), TRUE, TRUE, 2, 100), "item")
  expect_equal(mirtverse:::guess_role("examTime", c(12.5, 30.1), TRUE, FALSE, 500, 600), "rt")
})

test_that("mv_plan() normalises models and adds implied steps", {
  pl <- mv_plan(model = "GRM", group = "gender", steps = "report")
  expect_equal(pl$model, "graded")
  expect_equal(pl$steps, c("dif", "report"))
  expect_equal(mv_plan(model = "1PL")$model, "Rasch")
  expect_error(mv_plan(model = "probit"), "Unknown model")
  expect_error(mv_plan(nfact = 5), "nfact")
  up <- update_plan(pl, model = "2PL", group = NULL)
  expect_equal(up$model, "2PL")
  expect_null(up$group)
  expect_error(update_plan(pl, colour = "red"), "Unknown plan field")
  expect_output(print(pl), "DIF by: gender")
})

test_that("check_plan() resolves items and catches problems", {
  p <- profile_data(ask_dat)
  ok <- mirtverse:::check_plan(mv_plan(group = "gender"), p)
  expect_equal(ok$items, paste0("Q", 1:8))
  expect_length(ok$errors, 0)
  rng <- mirtverse:::check_plan(mv_plan(items = "Q2:Q5"), p)
  expect_equal(rng$items, paste0("Q", 2:5))
  bad <- mirtverse:::check_plan(mv_plan(items = c("Q1", "Q2", "Z9"), group = "sex"), p)
  expect_match(bad$errors[1], "Z9, sex")
  dif_no_group <- mirtverse:::check_plan(mv_plan(steps = "dif"), p)
  expect_true(any(grepl("grouping column", dif_no_group$errors)))
  poly <- profile_data(Science)
  wrong <- mirtverse:::check_plan(mv_plan(model = "2PL"), poly)
  expect_true(any(grepl("needs items scored 0/1", wrong$errors)))
  key <- mirtverse:::check_plan(mv_plan(model = "2PL", key = c(1, 2)), poly)
  expect_true(any(grepl("answer key has 2 entries", key$errors)))
})

test_that("mv_ask() writes a script that parses and runs", {
  scr <- mv_ask(data = ask_dat,
                plan = mv_plan(model = "2PL", group = "gender",
                               steps = c("describe", "fitcheck", "scores", "interpret", "report"),
                               options = list(report = list(file = "rep.html"))))
  expect_s3_class(scr, "mv_script")
  code <- paste(scr$script, collapse = "\n")
  expect_match(code, "raw <- ask_dat", fixed = TRUE)
  expect_match(code, "mod <- mirt(items, 1, itemtype = \"2PL\")", fixed = TRUE)
  expect_match(code, "dif_res <- dif(items, group = group, model = \"2PL\")", fixed = TRUE)
  expect_match(code, "mv_report(mod, file = \"rep.html\", dif = dif_res)", fixed = TRUE)
  expect_false(grepl("student_id\"", code))
  expect_silent(parse(text = scr$script))
  expect_output(print(scr), "R script")
  dir <- tempfile(); dir.create(dir)
  res <- withr::with_dir(dir, run_script(scr, echo = FALSE))
  expect_s4_class(res$mod, "SingleGroupClass")
  expect_s3_class(res$dif_res, "mv_dif")
  expect_true(file.exists(file.path(dir, "rep.html")))
  f <- save_script(scr, tempfile(fileext = ".R"))
  expect_equal(readLines(f), scr$script)
})

test_that("every template step renders, parses and runs, including the dry run", {
  scr <- mv_ask(data = Science,
                plan = mv_plan(model = "auto", missing = 9,
                               steps = c("describe", "fitcheck", "scores", "plots",
                                         "interpret", "cards", "report")))
  expect_match(paste(scr$script, collapse = "\n"), "sel <- select_model(items)", fixed = TRUE)
  expect_match(paste(scr$script, collapse = "\n"), "items[items == 9] <- NA", fixed = TRUE)
  dir <- tempfile(); dir.create(dir)
  expect_message(res <- withr::with_dir(dir, run_script(scr, check = TRUE, echo = FALSE)),
                 "Dry run")
  expect_s3_class(res$sel, "mv_model_selection")
  expect_true(file.exists(file.path(dir, "item-cards.html")))
})

test_that("scripts read data files and refine earlier scripts", {
  f <- tempfile(fileext = ".csv")
  write.csv(ask_dat, f, row.names = FALSE)
  scr <- mv_ask(data = f, plan = mv_plan(model = "Rasch", steps = "interpret"))
  expect_match(scr$script, "read.csv", all = FALSE, fixed = TRUE)
  res <- run_script(scr, echo = FALSE)
  expect_s4_class(res$mod, "SingleGroupClass")
  scr2 <- mv_ask(scr, plan = update_plan(scr$plan, model = "2PL"))
  expect_match(scr2$script, "itemtype = \"2PL\"", all = FALSE, fixed = TRUE)
  expect_error(mv_ask(data = ask_dat, plan = mv_plan(model = "2PL", items = "nothing")),
               "cannot be run")
})

test_that("the dry-run simulator keeps the data structure", {
  pl <- mirtverse:::check_plan(mv_plan(), profile_data(Science))
  sim <- mirtverse:::simulate_like(Science, pl, n = 300)
  expect_equal(names(sim), names(Science))
  expect_equal(nrow(sim), 300)
  for (j in names(Science))
    expect_true(all(sim[[j]] %in% unique(Science[[j]])))
})

test_that("a plan with no extra steps still fits a model", {
  p <- mv_plan(model = "2PL", steps = character())
  expect_identical(p$steps, character())
  lsat <- expand.table(LSAT7)
  scr <- mv_ask(data = lsat, plan = mv_plan(model = "2PL", steps = NULL))
  expect_true(any(grepl("^mod <- mirt\\(", scr$script)))
})
