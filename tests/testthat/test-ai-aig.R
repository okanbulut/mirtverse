perimeter <- function(constraints = "l > w") {
  item_model(
    stem = "A garden is {l} m long and {w} m wide. What is its perimeter?",
    key = "{2 * (l + w)} m",
    distractors = c(area = "{l * w} m", one_each = "{l + w} m", two_lengths = "{2 * l + w} m"),
    values = list(l = 5:15, w = 2:9), constraints = constraints, name = "PER")
}

test_that("item_model() checks its inputs and prints what it can generate", {
  m <- perimeter()
  expect_s3_class(m, "mv_item_model")
  expect_error(item_model("{x} + {y}", "{x + y}", "{x - y}", list(x = 1:3)), "`y`")
  expect_error(item_model(c("a", "b"), "k", "d", list(x = 1)), "one template")
  expect_error(item_model("s", "k", "d", list(1:3)), "named list")
  expect_error(item_model("{x}", "{x}", "{x}", list(x = 1), constraints = "z > 1"), "`z`")
  out <- capture.output(print(m))
  expect_match(paste(out, collapse = " "), "combinations of values meet the constraints")
  expect_match(paste(out, collapse = " "), "\\(area\\)")
})

test_that("generate_isomorphs() fills templates, keys correctly and is reproducible", {
  m <- perimeter()
  # a 6 by 3 garden has an area equal to its perimeter, so one combination is dropped
  expect_message(x <- generate_isomorphs(m, n = 5, seed = 3), "1 of 73")
  expect_s3_class(x, "tbl_df")
  expect_equal(nrow(x), 5)
  expect_equal(x$id, sprintf("PER-%02d", 1:5))
  expect_true(all(c("id", "model", "stem", "A", "B", "C", "D", "key", "l", "w", "flag") %in% names(x)))
  expect_true(all(x$l > x$w))
  keyed <- vapply(seq_len(nrow(x)), function(i) x[[x$key[i]]][i], "")
  expect_equal(keyed, paste(2 * (x$l + x$w), "m"))
  expect_equal(suppressMessages(generate_isomorphs(m, n = 5, seed = 3)), x)
  expect_true(all(grepl(" m long", x$stem)))
  unsh <- suppressMessages(generate_isomorphs(m, n = 3, shuffle = FALSE))
  expect_true(all(unsh$key == "A"))
  # every combination
  expect_equal(nrow(suppressMessages(generate_isomorphs(m, n = NULL))), sum(outer(5:15, 2:9, ">")) - 1)
})

test_that("generate_isomorphs() drops or flags combinations with identical options", {
  tri <- item_model(
    stem = "Base {b} cm, height {h} cm. Area?", key = "{b * h / 2}",
    distractors = c("{b * h}", "{b + h}", "{2 * (b + h)}"),
    values = list(b = 2:12, h = 2:10), constraints = "(b * h) %% 2 == 0", name = "TRI")
  expect_message(x <- generate_isomorphs(tri, n = NULL), "6 of 79 combinations")
  expect_equal(nrow(x), 73)
  expect_true(all(x$flag == ""))
  y <- generate_isomorphs(tri, n = NULL, drop_flawed = FALSE)
  expect_equal(nrow(y), 79)
  expect_equal(sum(y$flag != ""), 6)
  expect_true(all(apply(y[y$flag != "", c("A", "B", "C", "D")], 1, anyDuplicated) > 0))
})

test_that("generate_isomorphs() formats numbers and money, and combines models", {
  pct <- item_model(
    stem = "A coat costs {money(p)}. It rises by {r}%. New price?",
    key = "{money(p * (1 + r / 100))}", distractors = c("{money(p * r / 100)}", "{money(p + r)}"),
    values = list(p = 1250, r = 10), name = "PCT")
  x <- generate_isomorphs(pct, n = 1, shuffle = FALSE)
  expect_match(x$stem, "\\$1,250.00")
  expect_equal(x$A, "$1,375.00")
  div <- item_model("{a} / {b}?", "{a / b}", "{a * b}", list(a = 10, b = 4), name = "DIV")
  expect_equal(generate_isomorphs(div, shuffle = FALSE)$A, "2.5")
  expect_message(generate_isomorphs(div, n = 2), "DIV can only generate 1 isomorph\\.")
  both <- suppressMessages(generate_isomorphs(list(perimeter(), div), n = 2))
  expect_equal(sort(unique(both$model)), c("DIV", "PER"))
  expect_true(is.na(both$a[both$model == "PER"][1]))
  expect_error(generate_isomorphs(list(1)), "item model")
  expect_error(generate_isomorphs(perimeter("l > 100")), "No combination")
  expect_message(generate_isomorphs(perimeter("l > w & l * w != 2 * (l + w)"), n = 1), NA)
})

test_that("calibrate_families() recovers known families and flags spread", {
  set.seed(4)
  d <- data.frame(family = rep(c("tight", "loose"), each = 20),
                  b = c(rnorm(20, -1, 0.1), rnorm(20, 1, 0.8)), se = 0.05)
  cal <- calibrate_families(d, family = "family", se = "se")
  expect_s3_class(cal, "mv_families")
  expect_equal(cal$family, c("tight", "loose"))
  expect_equal(cal$isomorphic, c(TRUE, FALSE))
  expect_true(all(cal$sd_within <= cal$sd_b))
  expect_true(all(cal$lower < cal$mean_b & cal$upper > cal$mean_b))
  expect_gt(cal$field_test_n[1], cal$field_test_n[2])
  out <- capture.output(print(cal))
  expect_match(paste(out, collapse = " "), "corrected for estimation error")
  expect_s3_class(autoplot(cal), "ggplot")
  nose <- calibrate_families(d, family = "family")
  expect_equal(nose$sd_within, nose$sd_b)
  expect_error(calibrate_families(d, family = "fam"), "no column `fam`")
})

test_that("the aigfield data recover the planted problems", {
  skip_on_cran()
  truth <- lab_truth("aigfield")
  expect_equal(dim(aigfield), c(1000L, 60L))
  expect_equal(names(aigfield), aigfield_items$id)
  same <- apply(aigfield_items[, c("A", "B", "C", "D")], 1, anyDuplicated) > 0
  expect_equal(aigfield_items$id[same], truth$flawed)
  fit <- mirt::mirt(aigfield, 1, "2PL", SE = TRUE, verbose = FALSE)
  pars <- tidy(fit)
  items <- aigfield_items
  p <- pars[pars$term == "b", ]
  items$b <- p$estimate[match(items$id, p$item)]
  items$b_se <- p$std.error[match(items$id, p$item)]
  cal <- calibrate_families(items, family = "model", se = "b_se")
  expect_setequal(cal$family[!cal$isomorphic], c("SUB", "TRI"))
  expect_lt(max(abs(cal$mean_b[cal$isomorphic] -
                      truth$model_b[cal$family[cal$isomorphic]])), 0.2)
  sub <- items[items$model == "SUB", ]
  expect_gt(mean(sub$b[truth$regroup[sub$id]]) - mean(sub$b[!truth$regroup[sub$id]]), 0.6)
})
