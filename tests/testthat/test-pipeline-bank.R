two_forms <- local({
  set.seed(11)
  a <- matrix(rlnorm(40, 0.2, 0.2)); d <- matrix(rnorm(40))
  d2 <- d; d2[18] <- d2[18] - 1.2  # anchor I18 drifts on form Y
  fx <- simdata(a[1:25, , drop = FALSE], d[1:25, , drop = FALSE], 1500, itemtype = "2PL")
  fy <- simdata(a[16:40, , drop = FALSE], d2[16:40, , drop = FALSE], 1500, itemtype = "2PL",
                Theta = matrix(rnorm(1500, 0.5, 1.2)))
  colnames(fx) <- sprintf("I%02d", 1:25)
  colnames(fy) <- sprintf("I%02d", 16:40)
  px <- calibrate(add_responses(mv_pipeline("Form X"), fx), model = "2PL")
  py <- calibrate(add_responses(mv_pipeline("Form Y"), fy), model = "2PL")
  list(px = px, py = py, bank = bank_items(px, name = "Test bank")$bank, b_true = -d / a)
})

test_that("item_probs() matches mirt for every bank item type", {
  th <- seq(-3, 3, length.out = 7)
  for (tp in c("Rasch", "2PL", "3PL")) {
    m <- mirt(expand.table(LSAT7), 1, tp, verbose = FALSE)
    expect_equal(item_probs(coef(m)[[2]][1, ], tp, th), probtrace(extract.item(m, 2), th),
                 ignore_attr = TRUE, tolerance = 1e-8)
  }
  for (tp in c("graded", "gpcm")) {
    m <- mirt(Science, 1, tp, verbose = FALSE)
    expect_equal(item_probs(coef(m)[[2]][1, ], tp, th), probtrace(extract.item(m, 2), th),
                 ignore_attr = TRUE, tolerance = 1e-8)
  }
})

test_that("transform_pars() changes the scale of every item type", {
  th <- seq(-2, 2, length.out = 5)
  A <- 1.3; B <- -0.4
  for (tp in c("2PL", "3PL", "graded", "gpcm")) {
    m <- if (tp %in% c("2PL", "3PL")) mirt(expand.table(LSAT7), 1, tp, verbose = FALSE) else
      mirt(Science, 1, tp, verbose = FALSE)
    par <- coef(m)[[1]][1, ]
    # an item on the new scale at theta behaves like the transformed item at A * theta + B
    expect_equal(item_probs(transform_pars(par, tp, A, B), tp, A * th + B),
                 item_probs(par[!is.na(par)], tp, th), tolerance = 1e-10)
  }
})

test_that("mv_bank() builds a bank from a model or a pipeline", {
  b <- two_forms$bank
  expect_s3_class(b, "mv_bank")
  expect_equal(nrow(b$items), 25L)
  expect_equal(b$items$source[1], "Form X")
  expect_true(all(b$items$status == "active"))
  expect_output(print(b), "25 items")
  expect_false("pars" %in% names(tidy(b)))
  expect_s3_class(mv_bank(mod_grm), "mv_bank")
  expect_error(mv_bank(mv_pipeline()), "calibrate")
})

test_that("link_to_bank() recovers the scale and flags the drifting anchor", {
  py <- link_to_bank(two_forms$py, two_forms$bank)
  expect_equal(py$link$method, "stocking-lord")
  expect_equal(nrow(py$link$anchors), 10L)
  f <- flags(py, stage = "linking")
  expect_equal(f$target[f$check == "anchor_drift"], "I18")
  py2 <- link_to_bank(two_forms$py, two_forms$bank,
                      anchors = setdiff(sprintf("I%02d", 16:25), "I18"))
  expect_lt(abs(py2$link$A - 1.2), 0.15)
  expect_lt(abs(py2$link$B - 0.5), 0.15)
  expect_false("anchor_drift" %in% flags(py2)$check)
  for (m in c("haebara", "mean-mean", "mean-sigma")) {
    q <- link_to_bank(two_forms$py, two_forms$bank, method = m,
                      anchors = setdiff(sprintf("I%02d", 16:25), "I18"))
    expect_lt(abs(q$link$B - 0.5), 0.15)
  }
  expect_error(link_to_bank(two_forms$py, two_forms$bank, anchors = "I40"), "Not usable")
  expect_error(link_to_bank(two_forms$py, list()), "mv_bank")
})

test_that("fixed-anchor linking puts the model on the bank scale", {
  py <- link_to_bank(two_forms$py, two_forms$bank, method = "fixed",
                     anchors = setdiff(sprintf("I%02d", 16:25), "I18"))
  gp <- coef(py$model)$GroupPars
  expect_lt(abs(gp[1, "MEAN_1"] - 0.5), 0.15)
  expect_lt(abs(sqrt(gp[1, "COV_11"]) - 1.2), 0.15)
  expect_equal(unname(coef(py$model)$I16[1, "a1"]),
               two_forms$bank$items$pars[[16]][["a1"]])
})

test_that("bank_items() adds new items on the bank scale", {
  py <- link_to_bank(two_forms$py, two_forms$bank,
                     anchors = setdiff(sprintf("I%02d", 16:25), "I18"))
  py <- bank_items(py, two_forms$bank)
  it <- py$bank$items
  expect_equal(nrow(it), 40L)
  new <- it[match(sprintf("I%02d", 26:40), it$item), ]
  expect_lt(abs(mean(new$b - two_forms$b_true[26:40])), 0.15)
  expect_gt(cor(new$b, two_forms$b_true[26:40]), 0.98)
  # anchors keep their bank values
  expect_equal(it$b[it$item == "I18"], two_forms$bank$items$b[two_forms$bank$items$item == "I18"])
  expect_equal(py$stages$status[py$stages$stage == "linking"], "done")
  expect_equal(nrow(py$bank$history), 2L)
  expect_warning(bank_items(two_forms$py, two_forms$bank), "not linked")
  upd <- bank_items(py, two_forms$bank, update_anchors = TRUE)
  expect_false(isTRUE(all.equal(upd$bank$items$b[upd$bank$items$item == "I18"],
                                two_forms$bank$items$b[two_forms$bank$items$item == "I18"])))
})

test_that("the report shows the linking section, and recalibration resets the link", {
  py <- link_to_bank(two_forms$py, two_forms$bank)
  f <- tempfile(fileext = ".html")
  py <- suppressWarnings(pipeline_report(py, file = f, open = FALSE, cards = FALSE))
  html <- paste(readLines(f, warn = FALSE), collapse = "\n")
  expect_match(html, "<h2>Linking</h2>")
  expect_match(html, "stocking-lord")
  py <- suppressWarnings(calibrate(py, model = "2PL"))
  expect_null(py$link)
  expect_equal(py$stages$status[py$stages$stage == "linking"], "needs rerun")
})
