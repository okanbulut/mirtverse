# Builds the `catbank` teaching dataset used by the CAT design lab.
#
# A fictional calibrated 2PL item bank of 180 items for a college math
# placement test, in four content areas of 45 items each. 40 of the items
# make up the college's current fixed-length placement test (`fixed`).
# Problems are planted on purpose so the lab has something to find:
#   * the bank is thin at the top: few items are harder than b = 1.5
#   * Algebra items discriminate better than the others, so a CAT that picks
#     items by maximum information over-uses Algebra
#   * five Algebra items (M012, M024, M051, M076, M082) are exceptionally
#     discriminating near the middle, so a CAT without exposure control gives
#     them to almost everyone
# Placement students are assumed to be N(0, 1) on the bank scale.
#
# Run from the package root after the other data-raw scripts:
# source("data-raw/catbank.R")

set.seed(1189)
n_area <- 45L
areas <- c("Algebra", "Functions", "Geometry", "Statistics")
J <- n_area * length(areas)
area <- rep(areas, each = n_area)
area <- area[sample.int(J)]
item <- sprintf("M%03d", seq_len(J))

a <- stats::rlnorm(J, log(ifelse(area == "Algebra", 1.6, 1.05)), 0.22)
b <- stats::rnorm(J, -0.4, 0.85)
# thin top: pull most of the hardest items back below 1.5
hard <- which(b > 1.5)
hard <- hard[order(-b[hard])]
if (length(hard) > 4) b[hard[-(1:4)]] <- stats::runif(length(hard) - 4, 0.6, 1.4)
stars <- which(area == "Algebra")[c(2, 5, 9, 12, 15)]
a[stars] <- c(2.7, 2.6, 2.8, 2.5, 2.6)
b[stars] <- c(-0.2, 0.1, 0.3, -0.5, 0.0)
names(a) <- names(b) <- item

# the current fixed form: 10 items per area, chosen for medium difficulty,
# avoiding the five star items
fixed <- logical(J)
for (ar in areas) {
  idx <- setdiff(which(area == ar), stars)
  idx <- idx[order(abs(b[idx] + 0.1))][1:10]
  fixed[idx] <- TRUE
}

catbank <- data.frame(item = item, area = factor(area, levels = areas),
                      a = round(unname(a), 2), b = round(unname(b), 2), fixed = fixed,
                      stringsAsFactors = FALSE)

catbank_truth <- list(
  stars = item[stars],
  thin_top = sum(catbank$b > 1.5),
  population = c(mean = 0, sd = 1),
  notes = c("Algebra items have higher discriminations on purpose.",
            "Few items are harder than b = 1.5, so high-ability students get long, imprecise CATs.")
)

save(catbank, file = "data/catbank.rda", compress = "xz")
sysdata <- new.env()
load("R/sysdata.rda", envir = sysdata)
assign("catbank_truth", catbank_truth, envir = sysdata)
save(list = ls(sysdata), envir = sysdata, file = "R/sysdata.rda", compress = "xz")
