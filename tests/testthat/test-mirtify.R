# Translation tests run without the source packages. Parameter-match tests
# fit the original model and the translated mirt model and compare them.

LSAT <- mirt::expand.table(mirt::LSAT6)
colnames(LSAT) <- paste0("Item", 1:5)
Sci <- mirt::Science

tr <- function(code, ...) mirtify(code, ..., envir = parent.frame())

test_that("mirtify accepts strings, unquoted code and files", {
  a <- mirtify("fit <- ltm::rasch(LSAT)")
  b <- mirtify(fit <- ltm::rasch(LSAT))
  expect_identical(as.character(a), as.character(b))
  f <- tempfile(fileext = ".R")
  writeLines(c("library(ltm)", "fit <- rasch(LSAT)"), f)
  c1 <- mirtify(f)
  expect_match(as.character(c1), "library(mirtverse)", fixed = TRUE)
  expect_s3_class(a, "mv_mirtify")
  expect_output(print(a), "1 of 1 statements translated from ltm")
  out <- tempfile(fileext = ".R")
  mirtify("fit <- ltm::rasch(LSAT)", file = out)
  expect_true(any(grepl("mirt(LSAT", readLines(out), fixed = TRUE)))
})

test_that("ltm translations write the right mirt code", {
  x <- tr("library(ltm)
           fit <- rasch(LSAT)
           fit1 <- rasch(LSAT, constraint = cbind(ncol(LSAT) + 1, 1))
           fit2 <- ltm(LSAT ~ z1 + z2)
           fit3 <- grm(Sci, constrained = TRUE)
           summary(fit)
           factor.scores(fit, method = 'EAP')
           plot(fit, type = 'IIC', items = 0)
           y <- 1 + 2")
  s <- as.character(x)
  expect_match(s, "CONSTRAIN = (1-5, a1)", fixed = TRUE)
  expect_match(s, "FIXED = (1-5, a1)", fixed = TRUE)
  expect_match(s, "fit2 <- mirt(LSAT, 2, itemtype = \"2PL\", SE = TRUE)", fixed = TRUE)
  expect_match(s, "itemtype = \"graded\"", fixed = TRUE)
  expect_match(s, "tidy(fit)", fixed = TRUE)
  expect_match(s, "fscores(fit, method = \"EAP\", full.scores = FALSE)", fixed = TRUE)
  expect_match(s, "gg_info(fit)", fixed = TRUE)
  expect_equal(x$steps$status[nrow(x$steps)], "unchanged")
  expect_equal(sum(grepl("^library", strsplit(s, "\n")[[1]])), 1)
  # without the data in scope the item count is computed at run time
  y <- mirtify("fit <- ltm::rasch(unknown_data)", envir = new.env())
  expect_match(as.character(y), "ncol(unknown_data)", fixed = TRUE)
  expect_silent(parse(text = as.character(x)))
})

test_that("eRm translations cover follow-up functions", {
  x <- mirtify({
    library(eRm)
    fit <- RM(X)
    pp <- person.parameter(fit)
    itemfit(pp)
    LRtest(fit, splitcr = "mean")
    plotPImap(fit)
    coef(fit)
    fit$betapar
    lp <- LPCM(X, W)
  })
  s <- as.character(x)
  expect_match(s, "fit <- mirt(X, 1, itemtype = \"Rasch\", SE = TRUE)", fixed = TRUE)
  expect_match(s, "pp <- fscores(fit, method = \"ML\"", fixed = TRUE)
  expect_match(s, "itemfit(fit, fit_stats = \"infit\")", fixed = TRUE)
  expect_match(s, "ifelse(fit_score > mean(fit_score)", fixed = TRUE)
  expect_match(s, "anova(fit_equal, fit_free)", fixed = TRUE)
  expect_match(s, "gg_wright(fit)", fixed = TRUE)
  # the easiness helper is written once
  expect_equal(lengths(regmatches(s, gregexpr("fit_b <-", s, fixed = TRUE))), 1)
  expect_equal(tail(x$steps$status, 1), "unsupported")
  expect_match(s, "# lp <- LPCM(X, W)", fixed = TRUE)
})

test_that("TAM and irtQ translations handle their main arguments", {
  x <- mirtify("library(TAM)
                m1 <- tam.mml(resp, irtmodel = 'RSM')
                m2 <- tam.mml.2pl(resp, Q = Q, group = g)
                m3 <- tam.mml(resp, Y = Y, pweights = w)
                w <- tam.wle(m1)
                w$WLE.rel
                IRT.compareModels(m1, m3)")
  s <- as.character(x)
  expect_match(s, "itemtype = \"rsm\"", fixed = TRUE)
  expect_match(s, "m2_model <- mirt.model(Q, COV = upper.tri(diag(ncol(Q))))", fixed = TRUE)
  expect_match(s, "multipleGroup(resp, m2_model, group = g", fixed = TRUE)
  expect_match(s, "covdata = m3_covdata", fixed = TRUE)
  expect_match(s, "survey.weights = w", fixed = TRUE)
  expect_match(s, "empirical_rxx(w)", fixed = TRUE)
  expect_match(s, "anova(m1, m3)", fixed = TRUE)

  y <- mirtify("library(irtQ)
                mod <- est_irt(data = resp, D = 1.702,
                               model = c('1PLM', '1PLM', '3PLM', '3PLM', 'GRM'),
                               cats = c(2, 2, 2, 2, 4))
                summary(mod)
                est_score(mod, method = 'WL')
                sx2_fit(mod)")
  s <- as.character(y)
  expect_match(s, "CONSTRAIN = (1-2, a1)", fixed = TRUE)
  expect_match(s, "PRIOR = (3-4, g, expbeta, 5, 16)", fixed = TRUE)
  expect_match(s, "itemtype = c(rep(\"2PL\", 2), rep(\"3PL\", 2), \"graded\")", fixed = TRUE)
  expect_match(s, "quadpts = 49, theta_lim = c(-6, 6)", fixed = TRUE)
  expect_match(s, "/ 1.702", fixed = TRUE)
  expect_match(s, "method = \"WLE\"", fixed = TRUE)
  expect_match(s, "fit_stats = \"S_X2\"", fixed = TRUE)
})

test_that("mirtify_crosswalk lists the four packages", {
  cw <- mirtify_crosswalk()
  expect_setequal(unique(cw$package), c("ltm", "eRm", "TAM", "irtQ"))
  expect_true(all(mirtify_crosswalk("eRm")$package == "eRm"))
})

pars <- function(fit) coef(fit, IRTpars = TRUE, simplify = TRUE)$items

test_that("ltm models match their mirt translations", {
  skip_if_not_installed("ltm")
  skip_on_cran()
  o <- ltm::rasch(LSAT)
  r <- tr("fit <- ltm::rasch(LSAT)", run = TRUE)$env$fit
  expect_equal(unname(coef(o)[, 1]), unname(pars(r)[, "b"]), tolerance = 0.01)
  expect_equal(unname(coef(o)[1, 2]), unname(pars(r)[1, "a"]), tolerance = 0.01)

  o <- ltm::ltm(LSAT ~ z1)
  r <- tr("fit <- ltm::ltm(LSAT ~ z1)", run = TRUE)$env$fit
  expect_equal(unname(coef(o)[, 2]), unname(pars(r)[, "a"]), tolerance = 0.01)

  o <- ltm::grm(Sci)
  r <- tr("fit <- ltm::grm(Sci)", run = TRUE)$env$fit
  expect_equal(as.vector(t(coef(o))), as.vector(t(pars(r)[, c("b1", "b2", "b3", "a")])),
               tolerance = 0.01)

  o <- ltm::gpcm(Sci, constraint = "rasch")
  r <- tr("fit <- ltm::gpcm(Sci, constraint = 'rasch')", run = TRUE)$env$fit
  expect_equal(as.vector(t(coef(o)[, 1:3])), as.vector(t(pars(r)[, c("b1", "b2", "b3")])),
               tolerance = 0.01)
})

test_that("eRm models match their mirt translations", {
  skip_if_not_installed("eRm")
  skip_on_cran()
  X <- eRm::raschdat1
  o <- eRm::RM(X)
  res <- tr("library(eRm)\nfit <- RM(X)\neasy <- coef(fit)\nlr <- LRtest(fit)", run = TRUE)
  # CML and MML estimates agree closely for the Rasch model
  expect_equal(unname(o$betapar), unname(res$env$easy), tolerance = 0.02)
  lr_erm <- eRm::LRtest(o)
  lr_mirt <- res$env$lr
  expect_equal(lr_mirt$df[2], lr_erm$df)
  expect_equal(lr_mirt$X2[2], lr_erm$LR, tolerance = 0.1)
})

test_that("TAM models match their mirt translations", {
  skip_if_not_installed("TAM")
  skip_on_cran()
  utils::data(data.sim.rasch, package = "TAM", envir = environment())
  D <- data.sim.rasch[1:1000, 1:20]
  o <- TAM::tam.mml(D, verbose = FALSE)
  r <- tr("fit <- TAM::tam.mml(D)", run = TRUE)$env$fit
  expect_equal(unname(o$xsi$xsi), unname(pars(r)[, "b"]), tolerance = 0.01)
  expect_equal(as.numeric(o$variance), as.numeric(coef(r, simplify = TRUE)$cov),
               tolerance = 0.01)

  o <- TAM::tam.mml.2pl(D, verbose = FALSE)
  r <- tr("fit <- TAM::tam.mml.2pl(D)", run = TRUE)$env$fit
  expect_equal(unname(o$B[, 2, 1]), unname(coef(r, simplify = TRUE)$items[, "a1"]),
               tolerance = 0.01)

  o <- TAM::tam.mml(Sci - 1, verbose = FALSE)
  r <- tr("fit <- TAM::tam.mml(Sci - 1)", run = TRUE)$env$fit
  expect_equal(-o$deviance / 2, mirt::extract.mirt(r, "logLik"), tolerance = 1e-4)
})

test_that("irtQ models match their mirt translations", {
  skip_if_not_installed("irtQ")
  skip_on_cran()
  o <- irtQ::est_irt(data = LSAT, D = 1, model = c("1PLM", "1PLM", "1PLM", "2PLM", "2PLM"),
                     verbose = FALSE)
  r <- tr("fit <- irtQ::est_irt(data = LSAT, model = c('1PLM', '1PLM', '1PLM', '2PLM', '2PLM'))",
          run = TRUE)$env$fit
  expect_equal(o$par.est$par.1, unname(pars(r)[, "a"]), tolerance = 0.01)
  expect_equal(o$par.est$par.2, unname(pars(r)[, "b"]), tolerance = 0.01)

  # D = 1.702 with guessing fixed at 0.2: slopes are rescaled by summary()
  set.seed(11)
  sim <- mirt::simdata(a = matrix(runif(10, 1.4, 2.6)), d = matrix(rnorm(10)), N = 2000,
                       itemtype = "3PL", guess = rep(0.2, 10))
  o <- irtQ::est_irt(data = sim, D = 1.702, model = "3PLM", fix.g = TRUE, g.val = 0.2,
                     verbose = FALSE)
  res <- tr("fit <- irtQ::est_irt(data = sim, D = 1.702, model = '3PLM', fix.g = TRUE)
             p <- summary(fit)", run = TRUE)
  expect_equal(o$par.est$par.1, unname(res$env$p[, "a"]), tolerance = 0.01)
  expect_equal(o$par.est$par.2, unname(res$env$p[, "b"]), tolerance = 0.01)
})
