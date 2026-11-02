# Builds the `aiscored` and `aiscored_cr` teaching datasets: a Grade 8
# science test with 16 multiple-choice items and 4 constructed-response
# items scored 0 to 3 by an automated scoring engine, given in 2025 and 2026
# to 1,500 students each, for Lab 10 of the AI Hub. Every constructed
# response is scored by the engine; a validity sample of 20% of students is
# also scored by a human rater, and half of those by a second one.
#
# Planted on purpose:
#   * CR2: The engine under-scores English language learners (ELL): for 45%
#     of their responses above 0 it gives one point less than the true score.
#   * CR3: The engine was updated before 2026, and the new version is more
#     generous: for 40% of responses below 3 it gives one point more.
#   * CR4: The rubric is vague, so human raters disagree with each other
#     (half of their scores are off by a point, some by two). The engine
#     itself is as accurate as on the other items, but the human scores it
#     is checked against are weak evidence.
#   * MC07: A language-heavy multiple-choice item with real DIF against ELL
#     students (0.6 logits harder), which has nothing to do with the engine.
# The generating values are stored internally as `aiscored_truth`.
#
# Run from the package root after installing mirtverse:
#   source("data-raw/aiscored.R")

set.seed(16)
n_year <- 1500L
years <- c(2025L, 2026L)
N <- n_year * length(years)
year <- rep(years, each = n_year)
group <- factor(ifelse(stats::runif(N) < 0.25, "ELL", "Fluent"), levels = c("Fluent", "ELL"))
ell <- group == "ELL"
theta <- stats::rnorm(N, ifelse(ell, -0.3, 0), 1)

# multiple-choice items, 2PL
n_mc <- 16L
mc_id <- sprintf("MC%02d", seq_len(n_mc))
mc_a <- round(stats::rlnorm(n_mc, log(1.1), 0.2), 2)
mc_b <- round(sort(stats::rnorm(n_mc, 0, 0.8)), 2)
names(mc_a) <- names(mc_b) <- mc_id
dif_item <- "MC07"
dif_size <- 0.6
mc <- sapply(mc_id, function(j) {
  b <- mc_b[j] + if (j == dif_item) dif_size * ell else 0
  as.integer(stats::runif(N) < stats::plogis(mc_a[j] * (theta - b)))
})

# constructed-response items, graded response model, scores 0 to 3
cr_id <- sprintf("CR%d", 1:4)
cr_a <- c(CR1 = 1.6, CR2 = 1.5, CR3 = 1.7, CR4 = 1.4)
cr_b <- rbind(CR1 = c(-1.2, 0, 1.1), CR2 = c(-1, 0.2, 1.3), CR3 = c(-1.4, -0.2, 0.9),
              CR4 = c(-1.1, 0.1, 1.2))
true_cr <- sapply(cr_id, function(j) {
  p_ge <- sapply(1:3, function(k) stats::plogis(cr_a[j] * (theta - cr_b[j, k])))
  rowSums(stats::runif(N) < p_ge)   # P(score >= k) is decreasing in k
})
clip <- function(x) pmin(pmax(x, 0L), 3L)
jitter <- function(x, p, p2 = 0) {
  u <- stats::runif(length(x))
  step <- ifelse(u < p2, 2L, ifelse(u < p, 1L, 0L)) * sample(c(-1L, 1L), length(x), TRUE)
  clip(x + step)
}
rater_p <- c(CR1 = 0.22, CR2 = 0.22, CR3 = 0.22, CR4 = 0.50)
rater_p2 <- c(CR1 = 0, CR2 = 0, CR3 = 0, CR4 = 0.12)
engine_p <- c(CR1 = 0.22, CR2 = 0.22, CR3 = 0.22, CR4 = 0.25)
engine_p2 <- c(CR1 = 0, CR2 = 0, CR3 = 0, CR4 = 0)
human1 <- human2 <- machine <- true_cr
for (j in cr_id) {
  human1[, j] <- jitter(true_cr[, j], rater_p[j], rater_p2[j])
  human2[, j] <- jitter(true_cr[, j], rater_p[j], rater_p2[j])
  machine[, j] <- jitter(true_cr[, j], engine_p[j], engine_p2[j])
}
# planted engine problems
under <- ell & true_cr[, "CR2"] > 0 & stats::runif(N) < 0.45
machine[under, "CR2"] <- true_cr[under, "CR2"] - 1L
over <- year == 2026L & true_cr[, "CR3"] < 3 & stats::runif(N) < 0.40
machine[over, "CR3"] <- true_cr[over, "CR3"] + 1L

# validity sample: 20% of students read by a person, half of them twice
read1 <- stats::runif(N) < 0.20
read2 <- read1 & stats::runif(N) < 0.5
student <- sprintf("S%04d", seq_len(N))

aiscored <- data.frame(student = student, year = year, group = group, mc, machine,
                       stringsAsFactors = FALSE)
names(aiscored)[-(1:3)] <- c(mc_id, cr_id)
rownames(aiscored) <- NULL

aiscored_cr <- do.call(rbind, lapply(cr_id, function(j) {
  data.frame(student = student, year = year, group = group, item = j,
             machine = machine[, j],
             human1 = ifelse(read1, human1[, j], NA_integer_),
             human2 = ifelse(read2, human2[, j], NA_integer_),
             stringsAsFactors = FALSE)
}))
aiscored_cr <- aiscored_cr[order(aiscored_cr$student, aiscored_cr$item), ]
rownames(aiscored_cr) <- NULL

aiscored_truth <- list(
  theta = stats::setNames(round(theta, 3), student),
  true_cr = `rownames<-`(true_cr, student),
  mc_a = mc_a, mc_b = mc_b, cr_a = cr_a, cr_b = cr_b, impact = -0.3,
  dif_item = dif_item, dif_size = dif_size,
  rater_error = rater_p, engine_error = engine_p,
  planted = data.frame(
    problem = c("The engine under-scores ELL students on CR2 (one point less on 45% of their responses above 0)",
                "The 2026 engine update is more generous on CR3 (one point more on 40% of responses below 3)",
                "CR4's rubric is vague: Human raters disagree, so the human scores are weak evidence about the engine",
                "MC07 has real DIF against ELL students (0.6 logits), unrelated to the engine"),
    where = c("CR2, ELL", "CR3, 2026", "CR4", "MC07"), stringsAsFactors = FALSE))

save(aiscored, file = "data/aiscored.rda", compress = "xz")
save(aiscored_cr, file = "data/aiscored_cr.rda", compress = "xz")
sysdata <- new.env()
load("R/sysdata.rda", envir = sysdata)
assign("aiscored_truth", aiscored_truth, envir = sysdata)
save(list = ls(sysdata), envir = sysdata, file = "R/sysdata.rda", compress = "xz")
