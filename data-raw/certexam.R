# Builds the `certexam` teaching dataset used by the mirtverse labs.
#
# A fictional 32-item, five-option certification exam taken by 1,200
# candidates in English or French. Item parameters are a shrunken version of
# a 3PL calibration of mirt's SAT12 data, so the items behave like real ones.
# Problems are planted on purpose so the labs have something to find:
#   * Q14 is miskeyed in the published key (`certexam_key`)
#   * Q21 and Q22 share a reading passage (local dependence)
#   * Q09 (uniform) and Q27 (non-uniform) show DIF against French candidates
#   * French candidates are 0.35 SD lower on average (impact, not DIF)
# The generating values are stored internally as `certexam_truth` for the
# reveal at the end of the labs.
#
# Run from the package root: source("data-raw/certexam.R")

set.seed(2026)
J <- 32L
N <- 1200L
items <- sprintf("Q%02d", seq_len(J))

a <- c(1.79, 1.66, 1.72, 1.56, 1.05, 1.97, 1, 1.78, 0.72, 1.19, 1.34,
       2.2, 1.04, 1.48, 1.16, 1.72, 1.26, 1.74, 1.13, 1.55, 0.78, 1.2,
       1.25, 1.25, 1.34, 2.08, 1.54, 1.04, 1.81, 0.66, 1.76, 2.2)
b <- c(1.14, 0.09, 0.94, 1.06, -0.25, 1.22, -1.1, 1.37, -2.3, 0.53,
       -2.3, 1.8, -0.62, 0.03, -1.17, 0.92, -2.27, 0.53, 0.37, -0.71,
       -2.3, -1.99, 1.2, -0.47, 0.9, 0.4, -0.96, -0.1, 0.93, 0.61, -0.85, 2)
g <- round(stats::runif(J, 0.12, 0.25), 2)
names(a) <- names(b) <- names(g) <- items

language <- rep(c("English", "French"), c(750L, 450L))
theta <- stats::rnorm(N, ifelse(language == "French", -0.35, 0), 1)

testlet <- c("Q21", "Q22")
passage <- stats::rnorm(N)
aF <- a; bF <- b
bF["Q09"] <- b["Q09"] + 0.7    # harder for French candidates at equal ability
aF["Q27"] <- a["Q27"] * 0.35   # discriminates poorly in French

fr <- language == "French"
scored <- matrix(0L, N, J, dimnames = list(NULL, items))
for (j in items) {
  z <- ifelse(fr, aF[j] * (theta - bF[j]), a[j] * (theta - b[j]))
  if (j %in% testlet) z <- z + 2.2 * passage
  p <- g[j] + (1 - g[j]) * stats::plogis(z)
  scored[, j] <- as.integer(stats::runif(N) < p)
}

opts <- LETTERS[1:5]
true_key <- sample(opts, J, replace = TRUE)
names(true_key) <- items
raw <- as.data.frame(matrix("", N, J, dimnames = list(NULL, items)), stringsAsFactors = FALSE)
distractor_probs <- c(0.45, 0.25, 0.18, 0.12)
first_distractor <- character(J)
for (k in seq_len(J)) {
  dis <- sample(setdiff(opts, true_key[k]))
  first_distractor[k] <- dis[1]
  wrong <- sample(dis, N, replace = TRUE, prob = distractor_probs)
  raw[[k]] <- ifelse(scored[, k] == 1L, true_key[k], wrong)
}

# Q14's published key points at its most popular distractor
certexam_key <- true_key
certexam_key["Q14"] <- first_distractor[14]

certexam <- data.frame(id = sprintf("C%04d", seq_len(N)),
                       language = factor(language, levels = c("English", "French")),
                       raw, stringsAsFactors = FALSE)
# shuffle so the language groups are not in blocks
certexam <- certexam[sample.int(N), ]
certexam$id <- sprintf("C%04d", seq_len(N))
rownames(certexam) <- NULL

certexam_truth <- list(
  model = "3PL",
  key = true_key,
  miskeyed = "Q14",
  testlet = testlet,
  dif = c(Q09 = "uniform", Q27 = "non-uniform"),
  impact = c(English = 0, French = -0.35),
  pars = data.frame(item = items, a = unname(a), b = unname(b), g = unname(g),
                    a_french = unname(aF), b_french = unname(bF)),
  cut_raw = 18L
)

save(certexam, file = "data/certexam.rda", compress = "xz")
save(certexam_key, file = "data/certexam_key.rda", compress = "xz")
save(certexam_truth, file = "R/sysdata.rda", compress = "xz")
