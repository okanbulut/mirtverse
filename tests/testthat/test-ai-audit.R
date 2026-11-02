sim_scores <- function(n = 1200, bias = 0, drift = 0, seed = 1) {
  set.seed(seed)
  g <- factor(sample(c("A", "B"), n, TRUE, prob = c(0.6, 0.4)), levels = c("A", "B"))
  per <- rep(c("P1", "P2"), length.out = n)
  true <- sample(0:3, n, TRUE)
  noisy <- function(x) pmin(pmax(x + sample(c(-1, 0, 0, 0, 1), length(x), TRUE), 0), 3)
  m <- noisy(true)
  hit <- g == "B" & true > 0 & stats::runif(n) < bias
  m[hit] <- true[hit] - 1
  up <- per == "P2" & true < 3 & stats::runif(n) < drift
  m[up] <- true[up] + 1
  data.frame(machine = m, human1 = noisy(true),
             human2 = ifelse(stats::runif(n) < 0.5, noisy(true), NA),
             group = g, item = "Q1", period = per, stringsAsFactors = FALSE)
}

test_that("ai_audit() passes a fair, stable engine", {
  a <- ai_audit(sim_scores(), human2 = "human2", group = "group", item = "item",
                period = "period")
  expect_s3_class(a, "mv_audit")
  expect_equal(nrow(a$flags), 0)
  expect_true(all(a$checks$status == "pass"))
  expect_setequal(a$checks$check, c("human agreement", "machine agreement", "overall bias",
                                    "subgroup agreement", "differential scoring", "drift"))
  expect_output(print(a), "AI audit: 6 checks, 0 flags")
  expect_equal(nrow(tidy(a)), 0)
})

test_that("ai_audit() finds differential scoring and drift", {
  a <- ai_audit(sim_scores(bias = 0.5, drift = 0.5), human2 = "human2", group = "group",
                item = "item", period = "period")
  expect_true("differential scoring" %in% a$flags$check)
  expect_equal(a$flags$target[a$flags$check == "differential scoring"], "Q1, B")
  expect_lt(a$differential$gap, -0.1)
  expect_true("drift" %in% a$flags$check)
  expect_true(all(a$flags$level[a$flags$check %in% c("differential scoring", "drift")] == "block"))
  expect_s3_class(autoplot(a), "ggplot")
  expect_output(print(a), "BLOCK")
})

test_that("ai_audit() needs inputs and checks column names", {
  expect_error(ai_audit(), "Give `scores`")
  expect_error(ai_audit(sim_scores(), group = "grp"), "no column `grp`")
  expect_error(ai_audit(components = list(1)), "components")
  a <- ai_audit(sim_scores())
  expect_false("differential scoring" %in% a$checks$check)
})

test_that("ai_audit() audits components", {
  set.seed(3)
  items <- data.frame(id = sprintf("I%02d", 1:40), fam = rep(c("F1", "F2"), each = 20),
                      b = c(rnorm(20, -1, 0.1), rnorm(20, 1, 0.6)), b_se = 0.05)
  items$x <- rnorm(40)
  items$leak <- -items$b + rnorm(40, 0, 0.01)
  m <- predict_difficulty(items, c("x", "leak"), se = "b_se", methods = "lltm")
  cal <- calibrate_families(items, family = "fam", se = "b_se")
  a <- ai_audit(components = list(m, cal))
  expect_equal(a$flags$target[a$flags$check == "leakage"], "leak")
  expect_equal(a$flags$target[a$flags$check == "isomorphism"], "F2")
  ag <- agreement_report(c(0, 1, 2, 3, 3, 0), c(3, 2, 1, 0, 0, 3))
  expect_true("agreement report" %in% ai_audit(components = ag)$flags$check)
})

test_that("validity_argument() maps the audit to inferences", {
  a <- ai_audit(sim_scores(bias = 0.5), human2 = "human2", group = "group", item = "item")
  va <- validity_argument(a, construct = "science", use = "reporting")
  expect_s3_class(va, "mv_validity")
  expect_equal(va$inference, c("Scoring", "Generalization", "Extrapolation", "Decision"))
  expect_equal(va$status, c("supported", "needs evidence", "threatened", "needs evidence"))
  expect_match(va$evidence[3], "Differential scoring")
  expect_output(print(va), "Extrapolation \\[THREATENED\\]")
  expect_match(format(va, "markdown"), "### Decision \\(needs evidence\\)")
  expect_match(format(va, "html"), "<table")
  expect_equal(validity_argument()$status, rep("needs evidence", 4))
  expect_error(validity_argument(1), "ai_audit")
  sub <- va[, c("inference", "status")]
  expect_output(print(sub), "inference")
})

test_that("mv_report() takes a validity argument as a section", {
  skip_on_cran()
  fit <- mirt::mirt(mirt::Science, 1, verbose = FALSE)
  va <- validity_argument(construct = "science attitudes", use = "research")
  f <- mv_report(fit, file = tempfile(fileext = ".html"), cards = FALSE,
                 extra = list("Validity argument" = va), open = FALSE)
  expect_match(paste(readLines(f), collapse = "\n"), "argument-based approach")
})

test_that("the aiscored data recover the planted problems", {
  skip_on_cran()
  truth <- lab_truth("aiscored")
  expect_equal(nrow(aiscored), 3000)
  expect_equal(nrow(aiscored_cr), 12000)
  a <- ai_audit(aiscored_cr, human2 = "human2", group = "group", item = "item",
                period = "year")
  fl <- a$flags
  expect_equal(fl$target[fl$check == "differential scoring"], "CR2, ELL")
  expect_equal(fl$target[fl$check == "drift"], "CR3, 2026")
  expect_equal(fl$target[fl$check == "human agreement"], "CR4")
  expect_equal(truth$dif_item, "MC07")
})
