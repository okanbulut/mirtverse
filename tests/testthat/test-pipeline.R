sim_dich <- function(n = 600, j = 10, seed = 1) {
  set.seed(seed)
  a <- matrix(rlnorm(j, 0.2, 0.2)); d <- matrix(rnorm(j))
  dat <- as.data.frame(simdata(a, d, n, itemtype = "2PL"))
  names(dat) <- sprintf("I%02d", seq_len(j))
  dat
}

exam <- certexam[1:800, ]
p_exam <- suppressWarnings(add_responses(mv_pipeline(), exam, items = 3:34, key = certexam_key,
                                         id = "id", group = "language"))
p_exam_cal <- suppressWarnings(calibrate(drop_items(p_exam, "Q14"), model = "2PL"))

test_that("mv_rules() changes rules by name and checks them", {
  r <- mv_rules()
  expect_s3_class(r, "mv_rules")
  expect_equal(r$q3, 0.20)
  expect_equal(mv_rules(q3 = 0.25)$q3, 0.25)
  expect_equal(attr(mv_rules(q3 = 0.25), "changed"), "q3")
  expect_equal(mv_rules(preset = "lenient")$reliability, 0.70)
  expect_equal(mv_rules(reliability = 0.9, preset = "lenient")$reliability, 0.9)
  expect_error(mv_rules(q4 = 1), "Unknown rule")
  expect_error(mv_rules(q3 = "high"), "must be a number")
  expect_error(mv_rules(0.3), "by name")
  expect_output(print(r), "preset: standards")
})

test_that("add_responses() scores with a key and finds the miskeyed item", {
  expect_equal(dim(p_exam$data$responses), c(800L, 32L))
  expect_true(all(unlist(p_exam$data$responses) %in% c(0, 1, NA)))
  f <- flags(p_exam)
  expect_equal(f$target[f$check == "possible_miskey"], "Q14")
  expect_equal(f$level[f$check == "possible_miskey"], "block")
  expect_equal(p_exam$stages$status[1], "done")
})

test_that("add_responses() checks its input", {
  expect_error(add_responses(mv_pipeline(), exam, items = 3:34, key = certexam_key[1:5]),
               "32 items")
  expect_error(add_responses(mv_pipeline(), exam, items = 3:34), "must be numbers")
  expect_error(add_responses(mv_pipeline(), exam, items = 3:34, key = certexam_key,
                             group = "nope"), "not in the data")
  expect_error(add_responses(mv_pipeline(), exam, items = c("Q01", "Q99", "Q02"),
                             key = certexam_key[1:3]), "Unknown item")
})

test_that("intake flags missing data, zero variance and sparse categories", {
  dat <- sim_dich()
  dat$I01[1:200] <- NA
  dat[1:5, 2:10] <- NA
  dat$I10 <- 1
  p <- add_responses(mv_pipeline(), dat)
  f <- flags(p)
  expect_true("I01" %in% f$target[f$check == "item_missing"])
  expect_equal(f$target[f$check == "person_missing"], "5 respondents")
  expect_equal(sum(p$persons$check == "person_missing"), 5L)
  expect_equal(f$target[f$check == "zero_variance"], "I10")

  set.seed(2)
  lik <- as.data.frame(simdata(matrix(rep(1.5, 6)), matrix(rep(c(2, 0.5, -0.5, -2), each = 6), 6),
                                 300, itemtype = "graded"))
  lik[1:8, ] <- 2
  lik$Item_1[lik$Item_1 == 0][-(1:3)] <- 1
  p <- add_responses(mv_pipeline(), lik)
  f <- flags(p)
  expect_length(f$target[f$check == "straight_lining"], 1L)
  expect_true(all(1:8 %in% p$persons$row[p$persons$check == "straight_lining"]))
  expect_true("Item_1" %in% f$target[f$check == "sparse_category"])
})

test_that("intake flags rapid guessing from response times", {
  dat <- sim_dich(300)
  set.seed(3)
  rt <- matrix(rlnorm(300 * 10, 3, 0.3), 300, 10)
  rt[1:6, ] <- 0.5
  p <- add_responses(mv_pipeline(), dat, rt = rt)
  f <- flags(p)
  expect_equal(f$target[f$check == "rapid_guessing"], "6 respondents")
  expect_error(add_responses(mv_pipeline(), dat, rt = rt[, 1:3]), "one column per item")
})

test_that("gates warn by default and stop in strict mode", {
  expect_warning(calibrate(p_exam, model = "Rasch"), "1 block open flag")
  ps <- p_exam
  ps$strict <- TRUE
  expect_error(calibrate(ps, model = "Rasch"), "cannot start")
  expect_error(acknowledge(ps, check = "possible_miskey"), "override")
  expect_error(override(ps, check = "possible_miskey"), "needs a `note`")
  ps <- override(ps, check = "possible_miskey", note = "Key confirmed")
  expect_equal(flags(ps, status = "overridden")$note, "Key confirmed")
  expect_true(any(ps$log$action == "override"))
  expect_s3_class(calibrate(ps, model = "Rasch"), "mv_pipeline")
  expect_warning(acknowledge(ps, check = "nothing_here"), "No open flags")
})

test_that("acknowledge() by level skips block flags", {
  dat <- sim_dich()
  dat$I01[1:200] <- NA
  dat$I10 <- 1
  p <- add_responses(mv_pipeline(), dat)
  p <- acknowledge(p, note = "seen")
  expect_equal(flags(p)$check, "zero_variance")
  expect_true(all(flags(p, status = "acknowledged")$note == "seen"))
})

test_that("drop_items() fixes flags and asks for recalibration", {
  p <- drop_items(p_exam, "Q14", note = "Miskeyed")
  expect_false("Q14" %in% names(p$data$responses))
  expect_equal(flags(p, status = "fixed")$target, "Q14")
  expect_equal(nrow(flags(p)), 0L)
  p2 <- drop_items(p_exam_cal, c("Q21"), note = "testlet")
  expect_null(p2$model)
  expect_equal(p2$stages$status[2], "needs rerun")
  expect_true("Q21 & Q22" %in% flags(p2, status = "fixed")$target)
  expect_error(drop_items(p_exam, "Q99"), "Unknown item")
})

test_that("calibrate() finds planted DIF and local dependence", {
  p <- p_exam_cal
  expect_true(is_mirt_model(p$model))
  f <- flags(p, stage = "calibration")
  expect_true("Q09" %in% f$target[f$check == "dif_large"])
  expect_true("Q21 & Q22" %in% f$target[f$check == "local_dependence"])
  expect_equal(p$dif$ets[p$dif$item == "Q09"], "C")
  expect_equal(p$dif$favours[p$dif$item == "Q09"], "reference")
  expect_match(p$stages$summary[2], "^2PL, converged, reliability")
  expect_error(calibrate(mv_pipeline()), "add_responses")
})

test_that("decisions carry over when a stage is rerun", {
  p <- override(p_exam_cal, check = "dif_large", target = "Q09", note = "Panel kept it")
  p <- suppressWarnings(calibrate(p, model = "2PL"))
  f <- flags(p, status = "all")
  expect_equal(f$status[f$check == "dif_large" & f$target == "Q09"], "overridden")
  expect_equal(f$note[f$check == "dif_large" & f$target == "Q09"], "Panel kept it")
})

test_that("mh_dif() handles polytomous items", {
  set.seed(4)
  a <- matrix(rep(1.4, 8)); d <- matrix(rep(c(1.5, 0, -1.5), each = 8), 8)
  d2 <- d; d2[1, ] <- d2[1, ] - 1
  dat <- rbind(simdata(a, d, 500, itemtype = "graded"), simdata(a, d2, 500, itemtype = "graded"))
  grp <- rep(c("ref", "foc"), each = 500)
  res <- mh_dif(as.data.frame(dat), grp, "ref", mv_rules())
  expect_equal(res$statistic[1], "SMD/SD")
  expect_equal(res$ets[1], "C")
  expect_true(all(res$ets[-1] == "A" | res$ets[-1] == "B"))
  expect_error(mh_dif(as.data.frame(dat), grp, "zzz", mv_rules()), "not in the data")
})

test_that("pipeline_report() writes the report with the decisions section", {
  f <- tempfile(fileext = ".html")
  p <- p_exam_cal
  p$data$group <- as.character(p$data$group)
  p$data$group[1:5] <- "Other"
  p <- suppressWarnings(pipeline_report(p, file = f, open = FALSE, cards = FALSE))
  expect_true(file.exists(f))
  html <- paste(readLines(f, warn = FALSE), collapse = "\n")
  expect_match(html, "Pipeline decisions")
  expect_match(html, "Rules in effect")
  expect_match(html, "add_responses\\(p, data = exam")
  expect_equal(flags(p, stage = "reporting")$target, "Other")
  groups <- regmatches(html, regexpr("<section id=\"groups\">.*?</section>", html))
  expect_match(groups, "English")
  expect_false(grepl("Other", groups))
  expect_equal(p$stages$status[3], "done")
  expect_error(pipeline_report(mv_pipeline()), "calibrate")
})

test_that("print and tidy work on a pipeline", {
  expect_output(print(p_exam_cal), "Calibration")
  expect_output(print(p_exam_cal), "Open flags")
  expect_s3_class(tidy(p_exam_cal), "tbl_df")
  expect_error(flags(list()), "mv_pipeline")
})
