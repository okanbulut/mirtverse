# Builds the `aigfield` and `aigfield_items` teaching datasets: a field test
# of 60 Grade 6 mathematics items generated from six item models (10
# isomorphs each), answered by 1,000 students, for Lab 9 of the AI Hub.
#
# Each item's true difficulty is its model's difficulty plus item-specific
# noise (SD 0.15), so five of the six models are isomorphic. Planted on
# purpose:
#   * SUB (subtracting three-digit numbers) is not isomorphic: items that
#     need regrouping (borrowing) are 1.0 logit harder than items that do
#     not, so the family's spread is large. The variables `top` and
#     `bottom` reveal it.
#   * TRI (area of a triangle) was generated without a constraint that keeps
#     the options different. Two of its items have two identical options;
#     students who know the answer pick either one, but only one is keyed,
#     so those items look harder and discriminate less: TRI-02 and TRI-06.
# The generating values are stored internally as `aigfield_truth`.
#
# Run from the package root after installing mirtverse:
#   source("data-raw/aigfield.R")

library(mirtverse)

models <- list(
  item_model(
    stem = "A garden is {len} m long and {wid} m wide. What is its perimeter?",
    key = "{2 * (len + wid)} m",
    distractors = c(area = "{len * wid} m", one_length_one_width = "{len + wid} m",
                    two_lengths_only = "{2 * len + wid} m"),
    values = list(len = 6:15, wid = 2:9), constraints = "len > wid", name = "PER"),
  item_model(
    stem = "If {coef}x - {sub} = {coef * sol - sub}, what is the value of x?",
    key = "{sol}",
    distractors = c(subtracted_instead = "{(coef * sol - 2 * sub) / coef}",
                    ignored_constant = "{(coef * sol - sub) / coef}",
                    multiplied = "{coef * sol}"),
    values = list(coef = 2:6, sol = 3:12, sub = c(2, 3, 4, 6, 8, 9, 10, 12)),
    constraints = c("sub %% coef == 0", "coef * sol - 2 * sub > 0"), name = "EQN"),
  item_model(
    stem = "A jacket costs {money(price)}. Its price rises by {rate}%. What is the new price?",
    key = "{money(price * (1 + rate / 100))}",
    distractors = c(increase_only = "{money(price * rate / 100)}",
                    added_percent = "{money(price + rate)}",
                    decreased = "{money(price * (1 - rate / 100))}"),
    values = list(price = c(20, 40, 60, 80, 120, 150, 200), rate = c(10, 15, 20, 25, 30)),
    name = "PCT"),
  item_model(
    stem = "What is {top} - {bottom}?",
    key = "{top - bottom}",
    distractors = c(added = "{top + bottom}", off_by_ten = "{top - bottom + 10}",
                    off_by_hundred = "{top - bottom + 100}"),
    values = list(top = c(352, 418, 507, 584, 624, 731, 846, 963, 795, 679),
                  bottom = c(127, 145, 236, 213, 162, 324, 251, 143, 318)),
    constraints = "top - bottom > 150", name = "SUB"),
  item_model(
    stem = "What is {n1} + {n2} x {n3}?",
    key = "{n1 + n2 * n3}",
    distractors = c(left_to_right = "{(n1 + n2) * n3}", multiplied_first_two = "{n1 * n2 + n3}",
                    added_all = "{n1 + n2 + n3}"),
    values = list(n1 = 2:9, n2 = 2:9, n3 = 2:9), name = "OOO"),
  item_model(
    stem = "A triangle has a base of {base} cm and a height of {height} cm. What is its area?",
    key = "{base * height / 2} square cm",
    distractors = c(forgot_half = "{base * height} square cm",
                    added = "{base + height} square cm",
                    perimeter_like = "{2 * (base + height)} square cm"),
    values = list(base = 2:12, height = 2:10),
    constraints = "(base * height) %% 2 == 0", name = "TRI"))

# the first five models with the usual checks; TRI as the old tool made it,
# without dropping items whose options are not all different
items <- mirtverse:::bind_rows_fill(list(
  as.data.frame(generate_isomorphs(models[1:5], n = 10, seed = 2029)),
  as.data.frame(generate_isomorphs(models[[6]], n = 10, seed = 20, drop_flawed = FALSE))))
stopifnot(nrow(items) == 60)
flawed <- items$id[items$flag != ""]
stopifnot(identical(flawed, c("TRI-02", "TRI-06")))
items$flag <- NULL
items <- as.data.frame(items)
items$values <- vapply(seq_len(nrow(items)), function(i) {
  v <- c("len", "wid", "coef", "sol", "sub", "price", "rate", "top", "bottom", "n1", "n2", "n3",
         "base", "height")
  v <- v[!is.na(unlist(items[i, v]))]
  paste(sprintf("%s = %s", v, unlist(items[i, v])), collapse = ", ")
}, "")

set.seed(2609)
model_b <- c(PER = -1.0, EQN = 0.6, PCT = 0.8, SUB = -0.9, OOO = 0.3, TRI = 0.1)
regroup <- with(items, !is.na(top) & ((top %% 10 < bottom %% 10) |
                                        ((top %/% 10) %% 10 < (bottom %/% 10) %% 10)))
b_true <- model_b[items$model] + 1.0 * regroup + stats::rnorm(nrow(items), 0, 0.15)
a_true <- round(stats::rlnorm(nrow(items), log(1.1), 0.2), 2)
names(b_true) <- names(a_true) <- items$id

N <- 1000L
theta <- stats::rnorm(N)
resp <- sapply(seq_len(nrow(items)), function(j) {
  p <- stats::plogis(a_true[j] * (theta - b_true[j]))
  correct <- stats::runif(N) < p
  if (items$id[j] %in% flawed) correct <- correct & stats::runif(N) < 0.5  # half pick the twin
  as.integer(correct)
})
colnames(resp) <- items$id
aigfield <- as.data.frame(resp)
aigfield_items <- items
rownames(aigfield_items) <- NULL

aigfield_truth <- list(
  b = round(b_true, 3), a = a_true, model_b = model_b, sd_within = 0.15,
  regroup = stats::setNames(regroup, items$id), regroup_effect = 1.0,
  flawed = flawed,
  planted = data.frame(
    problem = c("SUB is not isomorphic: regrouping adds 1.0 logit",
                "TRI-02 and TRI-06 have two identical options"),
    where = c("SUB items", "TRI-02, TRI-06"), stringsAsFactors = FALSE))

save(aigfield, file = "data/aigfield.rda", compress = "xz")
save(aigfield_items, file = "data/aigfield_items.rda", compress = "xz")
sysdata <- new.env()
load("R/sysdata.rda", envir = sysdata)
assign("aigfield_truth", aigfield_truth, envir = sysdata)
save(list = ls(sysdata), envir = sysdata, file = "R/sysdata.rda", compress = "xz")
