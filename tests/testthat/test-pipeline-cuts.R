cuts_p <- local({
  set.seed(8)
  a <- matrix(rlnorm(20, 0.2, 0.25)); d <- matrix(rnorm(20))
  dat <- simdata(a, d, 800, itemtype = "2PL")
  colnames(dat) <- sprintf("I%02d", 1:20)
  suppressWarnings(calibrate(add_responses(mv_pipeline("Cuts", verbose = FALSE), dat),
                             model = "2PL"))
})

test_that("lord_wingersky() matches full enumeration of response patterns", {
  m <- mirt(Science, 1, "graded", verbose = FALSE)
  p <- suppressWarnings(calibrate(add_responses(mv_pipeline(verbose = FALSE), Science),
                                  model = "graded"))
  items <- cut_items(p, NULL)
  th <- c(-1, 0.5)
  lw <- lord_wingersky(items, th)
  expect_equal(rowSums(lw), c(1, 1))
  probs <- lapply(seq_len(nrow(items)), function(j)
    item_probs(items$pars[[j]], items$itemtype[j], th))
  pats <- expand.grid(rep(list(0:3), 4))
  brute <- matrix(0, 2, 13)
  for (r in seq_len(nrow(pats))) {
    x <- unlist(pats[r, ])
    pr <- Reduce(`*`, lapply(1:4, function(j) probs[[j]][, x[j] + 1]))
    brute[, sum(x) + 1] <- brute[, sum(x) + 1] + pr
  }
  expect_equal(lw, brute, tolerance = 1e-12)
})

test_that("decision_quality() gives the textbook values", {
  probs <- rbind(c(0.9, 0.1), c(0.2, 0.8))
  q <- decision_quality(probs, c(1L, 2L))
  expect_equal(q$summary$accuracy, 0.85)
  expect_equal(q$summary$consistency, mean(c(0.82, 0.68)))
  expect_equal(q$by_cut$false_positive, 0.05)
  expect_equal(q$by_cut$false_negative, 0.1)
})

test_that("set_cuts() estimates decision quality on the raw-score scale (Lee)", {
  p <- set_cuts(cuts_p, cuts = c(8, 14), scale = "raw", labels = c("Low", "Mid", "High"))
  cu <- p$cuts
  expect_equal(cu$method, "Lee (2010)")
  expect_equal(cu$table$raw, c(8, 14))
  expect_equal(test_tcc(cut_items(p, NULL), cu$table$theta), c(8, 14), tolerance = 1e-6,
               ignore_attr = TRUE)
  expect_true(cu$summary$accuracy > 0.5 && cu$summary$accuracy < 1)
  expect_true(all(cu$by_cut$accuracy >= cu$summary$accuracy))
  expect_equal(sum(cu$categories$expected), 1)
  expect_equal(p$stages$status[p$stages$stage == "cuts"], "done")
  expect_error(set_cuts(cuts_p, cuts = c(14, 8), scale = "raw"), "increasing")
  expect_error(set_cuts(cuts_p, cuts = 30, scale = "raw"), "maximum score")
  expect_error(set_cuts(cuts_p, cuts = 0, labels = c("a", "b", "c")), "labels")
  expect_error(set_cuts(cuts_p), "cut scores")
})

test_that("set_cuts() flags imprecise cuts and panel disagreement (Rudner)", {
  p <- set_cuts(cuts_p, cuts = c(-2.5, 0))
  f <- flags(p, stage = "cuts")
  expect_equal(p$cuts$method, "Rudner (2001)")
  expect_true("cut 1 (Level 2)" %in% f$target[f$check == "cut_precision"])
  panel <- cbind(c(-0.2, 0.1, 0.9, -0.8), c(1, 1.1, 0.9, 1.2))
  p <- set_cuts(cuts_p, panel = panel)
  expect_equal(p$cuts$table$theta, colMeans(panel))
  f <- flags(p, stage = "cuts")
  expect_equal(f$target[f$check == "panel_agreement"], "cut 1 (Level 2)")
  # a more accurate test raises fewer flags under looser rules
  q <- cuts_p
  q$rules <- mv_rules(cut_accuracy = 0.5, cut_consistency = 0.5, cut_sem = 2)
  q <- set_cuts(q, cuts = 0)
  expect_equal(nrow(flags(q, stage = "cuts")), 0L)
})

test_that("item_map() places items at the response probability", {
  m <- item_map(cuts_p, rp = 0.67)
  expect_equal(nrow(m), 20L)
  expect_false(is.unsorted(m$theta))
  it <- cut_items(cuts_p, NULL)
  j <- match(m$item[1], it$item)
  expect_equal(item_probs(it$pars[[j]], it$itemtype[j], m$theta[1])[1, 2], 0.67, tolerance = 1e-6,
               ignore_attr = TRUE)
  expect_error(item_map(cuts_p, rp = 1), "probability")
})

test_that("cuts can be set on a fixed form, and recalibration resets them", {
  skip_if_not_installed("eatATA")
  p <- suppressWarnings(assemble_forms(cuts_p, length = 10, theta = 0, time_limit = 5))
  p <- suppressWarnings(set_cuts(p, cuts = 6, scale = "raw", form = 1))
  expect_equal(p$cuts$form, 1)
  expect_equal(p$cuts$max_raw, 10L)
  expect_error(suppressWarnings(set_cuts(p, cuts = 0, form = 3)), "no form 3")
  f <- tempfile(fileext = ".html")
  p <- suppressWarnings(pipeline_report(p, file = f, open = FALSE, cards = FALSE))
  html <- paste(readLines(f, warn = FALSE), collapse = "\n")
  expect_match(html, "<h2>Cut scores</h2>")
  expect_match(html, "Lee \\(2010\\)")
  p <- suppressWarnings(calibrate(p, model = "2PL"))
  expect_null(p$cuts)
  expect_equal(p$stages$status[p$stages$stage == "cuts"], "needs rerun")
})
