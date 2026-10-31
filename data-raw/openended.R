# Builds the `openended` teaching dataset used by the open-ended scoring lab.
#
# A fictional Grade 9 science assessment with six open-ended tasks (T1-T6),
# each scored 0-4 against a rubric. 1,200 students wrote all six tasks. Every
# response was read by two of eight trained raters (R1-R8, assigned at
# random), and an expert gave a third read when the two scores were two or
# more points apart. An automated scoring engine also scored every response.
# The true model is the generalized partial credit model. Planted on purpose:
#   * rater R5 is severe: about 0.6 of a point below the others
#   * rater R8 is inconsistent: much noisier than the others
#   * task T6 has a vague rubric, so human agreement on it is low
#   * task T4's rubric levels 1 and 2 are hard to tell apart: category 1 is
#     rarely the most likely score (disordered thresholds), so 1 and 2
#     should be collapsed
#   * the engine scores English language learners (ELL) about 0.4 of a point
#     too low on every task, although its overall agreement looks fine
# ELL students are 0.3 SD lower on average (real impact).
# The generating values are stored internally as `openended_truth`.
#
# Run from the package root after the other data-raw scripts:
# source("data-raw/openended.R")

set.seed(926)
N <- 1200L
tasks <- sprintf("T%d", 1:6)
raters <- sprintf("R%d", 1:8)

ell <- factor(ifelse(seq_len(N) <= 300, "ELL", "Fluent"), levels = c("Fluent", "ELL"))
ell <- ell[sample.int(N)]
theta <- stats::rnorm(N, ifelse(ell == "ELL", -0.3, 0), 1)

a <- c(T1 = 1.4, T2 = 0.9, T3 = 1.9, T4 = 1.3, T5 = 0.8, T6 = 1.2)
steps <- rbind(T1 = c(-1.8, -0.7, 0.3, 1.4),
               T2 = c(-1.5, -0.4, 0.6, 1.7),
               T3 = c(-2.0, -0.9, 0.0, 1.0),
               T4 = c(0.3, -1.5, 0.5, 1.5),    # disordered: category 1 rarely modal
               T5 = c(-1.6, -0.5, 0.4, 1.8),
               T6 = c(-1.7, -0.6, 0.5, 1.5))

gpcm_draw <- function(th, a, b) {
  z <- outer(th, 0:4) * a - matrix(c(0, cumsum(a * b)), length(th), 5, byrow = TRUE)
  p <- exp(z - apply(z, 1, max))
  p <- p / rowSums(p)
  apply(p, 1, function(pr) sample.int(5, 1, prob = pr) - 1L)
}
true <- sapply(tasks, function(t) gpcm_draw(theta, a[t], steps[t, ]))

severity <- c(R1 = 0, R2 = 0.1, R3 = -0.1, R4 = 0.05, R5 = -0.6, R6 = 0, R7 = 0.1, R8 = 0)
noise <- c(R1 = 0.35, R2 = 0.35, R3 = 0.4, R4 = 0.35, R5 = 0.35, R6 = 0.4, R7 = 0.35, R8 = 0.85)
task_noise <- c(T1 = 0, T2 = 0, T3 = 0, T4 = 0, T5 = 0, T6 = 0.55)
rate <- function(tr, r, t) {
  x <- tr + severity[r] + stats::rnorm(length(tr), 0, sqrt(noise[r]^2 + task_noise[t]^2))
  as.integer(pmin(4, pmax(0, round(x))))
}

rows <- expand.grid(student = seq_len(N), task = tasks, stringsAsFactors = FALSE)
rows <- rows[order(rows$student, rows$task), ]
n <- nrow(rows)
r1 <- sample(raters, n, replace = TRUE)
r2 <- vapply(r1, function(r) sample(setdiff(raters, r), 1), character(1))
tr <- true[cbind(rows$student, match(rows$task, tasks))]
s1 <- s2 <- integer(n)
for (r in raters) {
  for (t in tasks) {
    i <- r1 == r & rows$task == t; s1[i] <- rate(tr[i], r, t)
    j <- r2 == r & rows$task == t; s2[j] <- rate(tr[j], r, t)
  }
}
s3 <- rep(NA_integer_, n)
disc <- abs(s1 - s2) >= 2
s3[disc] <- as.integer(pmin(4, pmax(0, round(tr[disc] + stats::rnorm(sum(disc), 0, 0.3)))))

el <- ell[rows$student] == "ELL"
machine <- tr + 0.12 + stats::rnorm(n, 0, 0.45) - ifelse(el, 0.4, 0)
machine <- as.integer(pmin(4, pmax(0, round(machine))))

openended <- data.frame(student = sprintf("S%04d", rows$student),
                        ell = ell[rows$student],
                        task = rows$task,
                        rater1 = unname(r1), score1 = s1,
                        rater2 = unname(r2), score2 = s2,
                        score3 = s3, machine = machine,
                        stringsAsFactors = FALSE)
rownames(openended) <- NULL

openended_truth <- list(
  model = "gpcm",
  severe_rater = c(R5 = -0.6),
  inconsistent_rater = "R8",
  vague_rubric = "T6",
  collapse = c(T4 = "categories 1 and 2"),
  engine_bias = c(ELL = -0.4),
  impact = c(Fluent = 0, ELL = -0.3),
  pars = data.frame(task = tasks, a = unname(a), steps, row.names = NULL)
)
names(openended_truth$pars)[3:6] <- paste0("b", 1:4)

save(openended, file = "data/openended.rda", compress = "xz")
sysdata <- new.env()
load("R/sysdata.rda", envir = sysdata)
assign("openended_truth", openended_truth, envir = sysdata)
save(list = ls(sysdata), envir = sysdata, file = "R/sysdata.rda", compress = "xz")
