# Builds the knowledge tracing example datasets:
#
#   * `cognitive_tutor`: The Cognitive Tutor practice logs used in the pyBKT
#     examples and in Bulut et al. (2023): 587 students' first attempts at
#     the steps of middle and high school mathematics problems, tagged with
#     12 knowledge components. The file is `data/ct.csv` of the pyBKT-examples
#     repository (https://github.com/CAHLR/pyBKT-examples), a sample of the
#     Cognitive Tutor data released through the PSLC DataShop for the
#     KDD Cup 2010 (Stamper et al., 2010).
#   * `fractions_logs`: Simulated practice logs of 400 students on the Grade
#     5 fractions items of `fractions_kg`, generated from the true graph of
#     `lab_truth("fractions")` with a known BKT model per concept.
#
# Simulation of `fractions_logs`: Students practise the six concepts in
# blocks, in the curriculum order with some neighbouring blocks swapped, so
# some students meet a concept before its prerequisites. A block ends after
# three correct answers in a row (a common mastery rule in tutors) or 15
# attempts. Each concept has a prior, a learn rate, and per-item guess and
# slip. A student can only know a concept at the start, or learn it, at the
# full rate if all its true prerequisites are known; otherwise the learn
# rate is a tenth. F14 is left out of practice (the published graph links
# it to the wrong concept, see Lab 11). The generating values are stored
# internally as `fractions_logs_truth`; `lab_truth("fractions_logs")`
# returns them.
#
# Run from the package root:
#   source("data-raw/kt.R")

devtools::load_all(quiet = TRUE)

# Cognitive Tutor ----------------------------------------------------------
url <- "https://raw.githubusercontent.com/CAHLR/pyBKT-examples/master/data/ct.csv"
ct_file <- tempfile(fileext = ".csv")
utils::download.file(url, ct_file, quiet = TRUE)
ct <- utils::read.csv(ct_file, fileEncoding = "latin1", check.names = FALSE,
                      stringsAsFactors = FALSE)
ct <- ct[order(ct$Row), ]
cognitive_tutor <- data.frame(
  student = ct[["Anon Student Id"]],
  problem = ct[["Problem Name"]],
  step = ct[["Step Name"]],
  skill = ct[["KC(Default)"]],
  correct = as.integer(ct[["Correct First Attempt"]]),
  opportunity = as.integer(ct[["Opportunity(Default)"]]),
  time = as.POSIXct(ct[["First Transaction Time"]], tz = "UTC", format = "%Y-%m-%d %H:%M:%OS"),
  stringsAsFactors = FALSE)
rownames(cognitive_tutor) <- NULL
cognitive_tutor <- tibble::as_tibble(cognitive_tutor)

# Fractions practice logs --------------------------------------------------
set.seed(1105)
truth_kg <- lab_truth("fractions")$graph
e <- as.data.frame(truth_kg$edges, stringsAsFactors = FALSE)
pre <- e[e$type == "prerequisite", ]
meas <- e[e$type == "measures", ]
cn <- c("meaning", "equivalent", "mixed", "compare", "common_denominator", "add_subtract")
single <- names(which(table(meas$from) == 1))
pool <- lapply(cn, function(k) setdiff(sort(meas$from[meas$to == k & meas$from %in% single]), "F14"))
names(pool) <- cn

par <- data.frame(concept = cn,
                  prior = c(0.45, 0.25, 0.20, 0.15, 0.10, 0.05),
                  learn = c(0.30, 0.22, 0.20, 0.20, 0.16, 0.14),
                  stringsAsFactors = FALSE)
items <- unlist(pool)
item_par <- data.frame(item = items, concept = rep(names(pool), lengths(pool)),
                       guess = round(stats::runif(length(items), 0.08, 0.30), 3),
                       slip = round(stats::runif(length(items), 0.04, 0.16), 3),
                       stringsAsFactors = FALSE)
gate <- 0.1

N <- 400L
rows <- list()
for (i in seq_len(N)) {
  id <- sprintf("P%03d", i)
  ord <- cn
  for (j in 1:5) if (stats::runif(1) < 0.3) ord[c(j, j + 1)] <- ord[c(j + 1, j)]
  known <- stats::setNames(rep(FALSE, 6), cn)
  # knowledge at the start follows the learning order
  for (k in cn) {
    ok <- all(known[pre$from[pre$to == k]])
    known[k] <- ok && stats::runif(1) < par$prior[par$concept == k]
  }
  t <- 0L
  for (k in ord) {
    run <- 0L; n <- 0L
    while (n < 15L && run < 3L) {
      n <- n + 1L; t <- t + 1L
      it <- sample(pool[[k]], 1)
      ip <- item_par[item_par$item == it, ]
      y <- as.integer(stats::runif(1) < if (known[k]) 1 - ip$slip else ip$guess)
      rows[[length(rows) + 1]] <- data.frame(student = id, attempt = t, item = it, correct = y,
                                             concept = k, known = known[k],
                                             stringsAsFactors = FALSE)
      run <- if (y == 1L) run + 1L else 0L
      if (!known[k]) {
        rate <- par$learn[par$concept == k] * if (all(known[pre$from[pre$to == k]])) 1 else gate
        known[k] <- stats::runif(1) < rate
      }
    }
  }
}
sim <- do.call(rbind, rows)
fractions_logs <- tibble::as_tibble(sim[c("student", "attempt", "item", "correct")])

fractions_logs_truth <- list(
  concepts = par, items = item_par, gate = gate,
  description = paste("Learning a concept whose true prerequisites are not all known happens",
                      "at a tenth of its learn rate; the published graph fractions_kg",
                      "misses the prerequisite equivalent -> compare."),
  known = sim[c("student", "attempt", "concept", "known")])

usethis::use_data(cognitive_tutor, fractions_logs, overwrite = TRUE, compress = "xz")
sysdata <- new.env()
load("R/sysdata.rda", envir = sysdata)
assign("fractions_logs_truth", fractions_logs_truth, envir = sysdata)
save(list = ls(sysdata), envir = sysdata, file = "R/sysdata.rda", compress = "xz")
