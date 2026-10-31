# Builds the `numeracy` teaching dataset used by the DIF and fairness lab.
#
# A fictional Grade 6 provincial numeracy assessment: 30 short-answer items
# scored right or wrong, taken by 2,000 students, 500 of whom are English
# language learners (ELL). The true model is the 2PL. Problems are planted on
# purpose so the lab has something to find:
#   * ELL students are 0.5 SD lower on average (impact, not DIF)
#   * N07, N18, N20, N25 and N30, long word problems, are harder for ELL
#     students at the same ability (uniform DIF)
#   * N02, a word problem built around an idiom, discriminates poorly for ELL
#     students (non-uniform DIF: the curves cross)
#   * N21, a symbolic division item, is easier for ELL students (DIF that
#     favours the focal group)
#   * N03 has a tiny uniform shift that is negligible in size
#   * N10, N12 and N28 are just as long as the DIF word problems but show no DIF
#   * gender shows neither impact nor DIF
# The generating values are stored internally as `numeracy_truth` for the
# reveal at the end of the lab.
#
# Run from the package root after data-raw/certexam.R:
# source("data-raw/numeracy.R")

set.seed(615)
J <- 30L
N <- 2000L
items <- sprintf("N%02d", seq_len(J))

a <- round(stats::rlnorm(J, log(1.3), 0.25), 2)
b <- round(seq(-1.9, 1.9, length.out = J)[sample.int(J)], 2)
names(a) <- names(b) <- items

strand <- rep(c("Number", "Patterns and relations", "Shape and space",
                "Measurement", "Statistics and probability"), length.out = J)
word_problem <- items %in% c("N02", "N05", "N07", "N10", "N12", "N15", "N18",
                             "N20", "N23", "N25", "N28", "N30")
words <- ifelse(word_problem, sample(26:40, J, replace = TRUE),
                sample(6:16, J, replace = TRUE))
long <- c(N02 = 46, N07 = 62, N10 = 60, N12 = 58, N18 = 55, N20 = 57, N25 = 61,
          N28 = 64, N30 = 53)
words[match(names(long), items)] <- long
numeracy_items <- data.frame(
  item = items, strand = strand,
  format = ifelse(word_problem, "Word problem", "Symbolic"),
  words = as.integer(words),
  stringsAsFactors = FALSE)

ell <- rep(c("Fluent", "ELL"), c(1500L, 500L))
gender <- sample(c("Girl", "Boy"), N, replace = TRUE)
theta <- stats::rnorm(N, ifelse(ell == "ELL", -0.5, 0), 1)

aF <- a; bF <- b
uniform <- c(N07 = 0.9, N18 = 0.8, N20 = 0.85, N25 = 0.9, N30 = 0.75)
bF[names(uniform)] <- b[names(uniform)] + uniform
aF["N02"] <- a["N02"] * 0.3
bF["N21"] <- b["N21"] - 0.6
bF["N03"] <- b["N03"] + 0.15

focal <- ell == "ELL"
scored <- matrix(0L, N, J, dimnames = list(NULL, items))
for (j in items) {
  z <- ifelse(focal, aF[j] * (theta - bF[j]), a[j] * (theta - b[j]))
  scored[, j] <- as.integer(stats::runif(N) < stats::plogis(z))
}

numeracy <- data.frame(id = sprintf("S%04d", seq_len(N)),
                       ell = factor(ell, levels = c("Fluent", "ELL")),
                       gender = factor(gender, levels = c("Girl", "Boy")),
                       scored, stringsAsFactors = FALSE)
numeracy <- numeracy[sample.int(N), ]
numeracy$id <- sprintf("S%04d", seq_len(N))
rownames(numeracy) <- NULL

numeracy_truth <- list(
  model = "2PL",
  dif = c(N07 = "uniform", N18 = "uniform", N20 = "uniform", N25 = "uniform",
          N30 = "uniform", N02 = "non-uniform", N21 = "uniform (favours ELL)",
          N03 = "negligible"),
  impact = c(Fluent = 0, ELL = -0.5),
  pars = data.frame(item = items, a = unname(a), b = unname(b),
                    a_ell = unname(aF), b_ell = unname(bF)),
  no_dif_long = c("N10", "N12", "N28")
)

save(numeracy, file = "data/numeracy.rda", compress = "xz")
save(numeracy_items, file = "data/numeracy_items.rda", compress = "xz")
sysdata <- new.env()
load("R/sysdata.rda", envir = sysdata)
assign("numeracy_truth", numeracy_truth, envir = sysdata)
save(list = ls(sysdata), envir = sysdata, file = "R/sysdata.rda", compress = "xz")
