# Builds the `linking` teaching dataset used by the linking lab.
#
# A fictional 40-item licensure exam with two forms in a common-item
# nonequivalent groups (NEAT) design. Form A was given in 2025 and Form B in
# 2026, each to 1,000 candidates. Each form has 28 unique items (A01-A28,
# B01-B28) and the 12 common anchor items C01-C12. Responses to items a
# candidate did not see are NA. The true model is the 2PL. Planted on purpose:
#   * the 2026 candidates are more able: mean 0.3, SD 1.1 on the Form A scale
#   * Form B's unique items are easier than Form A's (mean b 0.35 lower)
#   * anchor C07 drifted: it leaked after 2025 and is 1.3 easier on Form B
# The pass mark on Form A is a raw score of 22.
# The generating values are stored internally as `linking_truth`.
#
# Run from the package root after data-raw/certexam.R and data-raw/numeracy.R:
# source("data-raw/linking.R")

set.seed(404)
N <- 1000L
uA <- sprintf("A%02d", 1:28)
uB <- sprintf("B%02d", 1:28)
cc <- sprintf("C%02d", 1:12)
items <- c(uA, uB, cc)

a <- round(stats::rlnorm(length(items), log(1.25), 0.25), 2)
b <- round(c(stats::rnorm(28, -0.35, 0.8), stats::rnorm(28, -0.7, 0.8),
             seq(-1.6, 1.4, length.out = 12)), 2)
names(a) <- names(b) <- items
b_formB <- b
b_formB["C07"] <- b["C07"] - 1.3

theta_A <- stats::rnorm(N, 0, 1)
theta_B <- stats::rnorm(N, 0.3, 1.1)

sim_form <- function(theta, its, bb) {
  out <- vapply(its, function(j) {
    p <- stats::plogis(a[j] * (theta - bb[j]))
    as.integer(stats::runif(length(theta)) < p)
  }, integer(length(theta)))
  out
}
resp_A <- sim_form(theta_A, c(uA, cc), b)
resp_B <- sim_form(theta_B, c(uB, cc), b_formB)

full <- matrix(NA_integer_, 2L * N, length(items), dimnames = list(NULL, items))
full[seq_len(N), colnames(resp_A)] <- resp_A
full[N + seq_len(N), colnames(resp_B)] <- resp_B

linking <- data.frame(id = c(sprintf("A%04d", seq_len(N)), sprintf("B%04d", seq_len(N))),
                      form = factor(rep(c("A", "B"), each = N), levels = c("A", "B")),
                      full, stringsAsFactors = FALSE)
rownames(linking) <- NULL

linking_truth <- list(
  model = "2PL",
  anchors = cc,
  drift = c(C07 = -1.3),
  ability = data.frame(form = c("A", "B"), mean = c(0, 0.3), sd = c(1, 1.1)),
  pars = data.frame(item = items, a = unname(a), b = unname(b), b_formB = unname(b_formB)),
  cut_A = 22L
)

save(linking, file = "data/linking.rda", compress = "xz")
sysdata <- new.env()
load("R/sysdata.rda", envir = sysdata)
assign("linking_truth", linking_truth, envir = sysdata)
save(list = ls(sysdata), envir = sysdata, file = "R/sysdata.rda", compress = "xz")
