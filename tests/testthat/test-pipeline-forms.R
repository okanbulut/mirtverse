forms_pool <- local({
  set.seed(5)
  a <- matrix(rlnorm(40, 0.2, 0.25)); d <- matrix(rnorm(40, 0, 1.2))
  dat <- simdata(a, d, 1000, itemtype = "2PL")
  colnames(dat) <- sprintf("I%02d", 1:40)
  p <- suppressWarnings(calibrate(add_responses(mv_pipeline("Pool", verbose = FALSE), dat),
                                  model = "2PL"))
  list(p = p, content = stats::setNames(rep(c("A", "B"), 20), colnames(dat)))
})

test_that("assemble_forms() meets the blueprint and keeps enemies apart", {
  skip_if_not_installed("eatATA")
  p <- suppressWarnings(assemble_forms(forms_pool$p, length = 10, n_forms = 2, theta = 0,
                                       content = forms_pool$content, blueprint = c(A = 6, B = 4),
                                       enemies = list(c("I01", "I03")), time_limit = 10))
  it <- p$forms$items
  expect_equal(p$forms$method, "ata")
  expect_equal(as.integer(table(it$form)), c(10L, 10L))
  expect_false(anyDuplicated(it$item) > 0)
  for (f in 1:2) {
    expect_equal(sum(forms_pool$content[it$item[it$form == f]] == "A"), 6L)
    expect_false(all(c("I01", "I03") %in% it$item[it$form == f]))
  }
  expect_equal(nrow(p$forms$info), 2L)
  expect_false(any(c("no_solution", "blueprint", "enemy_items") %in% flags(p)$check))
  expect_equal(p$stages$status[p$stages$stage == "forms"], "done")
})

test_that("assemble_forms() flags forms that cannot be built", {
  skip_if_not_installed("eatATA")
  p <- suppressWarnings(assemble_forms(forms_pool$p, length = 25, content = forms_pool$content,
                                       blueprint = c(A = 24, B = 1), time_limit = 5))
  f <- flags(p, stage = "forms")
  expect_equal(f$check, "no_solution")
  expect_match(f$value, "too few items in A")
  expect_null(p$forms)
  bp <- data.frame(category = c("A", "B"), min = c(6, 6), max = c(6, 6))
  p <- suppressWarnings(assemble_forms(forms_pool$p, length = 10, content = forms_pool$content,
                                       blueprint = bp, time_limit = 5))
  expect_equal(flags(p, stage = "forms")$check, "no_solution")
  expect_error(assemble_forms(forms_pool$p, length = 30, n_forms = 2), "too few")
})

test_that("ata_solution() accepts feasible forms the solver could not prove optimal", {
  im <- matrix(c(1, 1, 0, 0, 0, 1, 1, 0), 4)
  ok <- ata_solution(list(solution_found = FALSE, item_matrix = im,
                          solution_status = "The solution is feasible, but may not be optimal"), 2)
  expect_true(ok$ok)
  expect_false(ok$optimal)
  expect_false(ata_solution(list(solution_found = FALSE, item_matrix = im * 0,
                                 solution_status = "No feasible solution"), 2)$ok)
  expect_false(ata_solution(NULL, 2)$ok)
})

test_that("simulate_cat() summarizes precision and exposure", {
  skip_if_not_installed("mirtCAT")
  p <- suppressWarnings(simulate_cat(forms_pool$p, n = 100, max_items = 10, seed = 1))
  s <- p$forms$summary
  expect_equal(p$forms$method, "cat")
  expect_equal(nrow(p$forms$persons), 100L)
  expect_lte(s$mean_items, 10)
  expect_lt(abs(s$bias), 0.3)
  expect_equal(nrow(p$forms$exposure), 40L)
  expect_true(all(flags(p, stage = "forms")$check %in%
                    c("cat_precision", "cat_exposure", "unused_items", "bank_depth")))
  expect_true("bank_depth" %in% flags(p)$check)
})

test_that("assemble_mst() builds disjoint modules and simulates routing", {
  skip_if_not_installed("eatATA")
  p <- suppressWarnings(assemble_mst(forms_pool$p, router_length = 6, module_length = 6,
                                     n_modules = 3, n = 200, seed = 1))
  m <- p$forms$modules
  expect_equal(p$forms$method, "mst")
  expect_equal(nrow(m), 24L)
  expect_false(anyDuplicated(m$item) > 0)
  expect_equal(nrow(p$forms$persons), 200L)
  expect_equal(sum(p$forms$summary$routed), 1)
})

test_that("the report shows the forms, and recalibration resets them", {
  skip_if_not_installed("eatATA")
  p <- suppressWarnings(assemble_forms(forms_pool$p, length = 8, theta = 0, time_limit = 5))
  f <- tempfile(fileext = ".html")
  p <- suppressWarnings(pipeline_report(p, file = f, open = FALSE, cards = FALSE))
  html <- paste(readLines(f, warn = FALSE), collapse = "\n")
  expect_match(html, "<h2>Forms</h2>")
  p <- suppressWarnings(calibrate(p, model = "2PL"))
  expect_null(p$forms)
  expect_equal(p$stages$status[p$stages$stage == "forms"], "needs rerun")
})
