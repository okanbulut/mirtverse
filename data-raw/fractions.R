# Builds the knowledge graph example datasets:
#
#   * `fractions` and `fractions_kg`: A simulated Grade 5 fractions test of
#     24 items given to 1,200 students, and the knowledge graph the
#     curriculum team wrote for it (6 concepts, prerequisite edges and the
#     item-to-concept links).
#   * `fraction_subtraction` and `fraction_subtraction_kg`: Tatsuoka's
#     fraction subtraction data (536 students, 20 items) and its 8-attribute
#     Q-matrix (DeCarlo, 2011), copied from the CDM package (GPL), with no
#     prerequisite edges because none were published with the Q-matrix.
#
# Simulation: Each concept has its own proficiency. A concept's proficiency
# is built from the proficiencies of its prerequisites plus new learning, so
# students are better at concepts early in the learning order. Responses
# follow a compensatory multidimensional 2PL in which each item loads on the
# concepts it truly measures; items deeper in the learning order are harder.
#
# Planted on purpose (the published graph differs from the true one):
#   * F14 is listed under `compare`, but it truly measures
#     `common_denominator` (comparing 3/4 and 5/6 needs a common denominator).
#   * The prerequisite edge equivalent -> compare is missing from the
#     published graph.
# The generating values and the true graph are stored internally as
# `fractions_truth`; `lab_truth("fractions")` returns them.
#
# Run from the package root:
#   source("data-raw/fractions.R")

devtools::load_all(quiet = TRUE)
set.seed(509)

concepts <- data.frame(
  concept = c("meaning", "equivalent", "mixed", "compare", "common_denominator",
              "add_subtract"),
  label = c("Fraction meaning", "Equivalent fractions", "Mixed numbers",
            "Comparing fractions", "Common denominators", "Adding and subtracting"),
  description = c(
    "A fraction names equal parts of a whole or a point on the number line.",
    "Different fractions can name the same amount (2/3 = 4/6).",
    "Moving between mixed numbers and improper fractions.",
    "Ordering fractions by size.",
    "Rewriting fractions with a shared denominator.",
    "Adding and subtracting fractions and mixed numbers with unlike denominators."),
  stringsAsFactors = FALSE)

true_edges <- data.frame(
  from = c("meaning", "meaning", "equivalent", "equivalent", "common_denominator", "mixed"),
  to = c("equivalent", "mixed", "compare", "common_denominator", "add_subtract",
         "add_subtract"),
  stringsAsFactors = FALSE)

item_ids <- sprintf("F%02d", 1:24)
true_links <- data.frame(
  item = c(item_ids[1:13], "F14", item_ids[15:21], "F22", "F22", "F23", "F23", "F24", "F24"),
  concept = c(rep("meaning", 4), rep("equivalent", 4), rep("mixed", 4), "compare",
              "common_denominator", "compare", "compare", rep("common_denominator", 3),
              "add_subtract", "add_subtract",
              "add_subtract", "common_denominator", "add_subtract", "mixed",
              "add_subtract", "common_denominator"),
  stringsAsFactors = FALSE)
true_kg <- mv_kg_build(concepts, edges = true_edges, items = true_links,
                       name = "Grade 5 fractions (true graph)")

published_edges <- true_edges[!(true_edges$from == "equivalent" & true_edges$to == "compare"), ]
published_links <- true_links
published_links$concept[published_links$item == "F14"] <- "compare"
fractions_kg <- mv_kg_build(concepts, edges = published_edges, items = published_links,
                            name = "Grade 5 fractions")

# proficiencies built along the true learning order
N <- 1200L
cn <- concepts$concept
theta <- matrix(NA_real_, N, length(cn), dimnames = list(NULL, cn))
depth <- mirtverse:::kg_depth(true_kg)
for (k in names(sort(depth))) {
  parents <- true_edges$from[true_edges$to == k]
  new <- stats::rnorm(N)
  theta[, k] <- if (length(parents)) {
    base <- rowMeans(theta[, parents, drop = FALSE])
    as.numeric(scale(0.75 * as.numeric(scale(base)) + sqrt(1 - 0.75^2) * new))
  } else new
}

# item parameters: slopes split across the concepts an item measures
a_total <- round(stats::rlnorm(24, log(1.4), 0.2), 2)
names(a_total) <- item_ids
item_depth <- vapply(item_ids, function(j) max(depth[true_links$concept[true_links$item == j]]),
                     numeric(1))
b <- round(-0.9 + 0.45 * item_depth + stats::rnorm(24, 0, 0.3), 2)
A <- matrix(0, 24, length(cn), dimnames = list(item_ids, cn))
for (j in item_ids) {
  ks <- true_links$concept[true_links$item == j]
  A[j, ks] <- round(a_total[j] / sqrt(length(ks)), 2)
}
d <- round(-rowSums(A) * b, 2)
eta <- theta %*% t(A) + matrix(d, N, 24, byrow = TRUE)
resp <- matrix(as.integer(stats::runif(N * 24) < stats::plogis(eta)), N, 24,
               dimnames = list(NULL, item_ids))
fractions <- data.frame(id = sprintf("S%04d", seq_len(N)), resp, stringsAsFactors = FALSE)

fractions_truth <- list(
  planted = data.frame(
    problem = c("wrong_link", "missing_prerequisite"),
    nodes = c("F14", "equivalent -> compare"),
    detail = c("F14 is listed under compare but truly measures common_denominator.",
               "The published graph leaves out the prerequisite edge equivalent -> compare."),
    stringsAsFactors = FALSE),
  graph = true_kg,
  items = data.frame(item = item_ids, A, d = d, b = b, stringsAsFactors = FALSE,
                     row.names = NULL),
  theta = round(theta, 3))

# Tatsuoka's fraction subtraction data (from the CDM package)
load("data-raw/cdm/fraction.subtraction.data.rda")
load("data-raw/cdm/fraction.subtraction.qmatrix.rda")
fs_items <- sprintf("FS%02d", 1:20)
fraction_subtraction <- fraction.subtraction.data
names(fraction_subtraction) <- fs_items
rownames(fraction_subtraction) <- NULL
fs_q <- as.matrix(fraction.subtraction.qmatrix)
rownames(fs_q) <- fs_items
fs_concepts <- data.frame(
  concept = c("convert_whole", "separate_whole", "simplify_first", "common_denominator",
              "borrow_whole", "column_borrow", "subtract_numerators", "reduce_answer"),
  label = c("Convert a whole number to a fraction", "Separate a whole number from a fraction",
            "Simplify before subtracting", "Find a common denominator",
            "Borrow from the whole number part",
            "Column borrow to subtract the numerators", "Subtract numerators",
            "Reduce answers to simplest form"),
  stringsAsFactors = FALSE)
fs_concepts$description <- paste0("Attribute alpha", 1:8, " in DeCarlo (2011).")
colnames(fs_q) <- fs_concepts$concept
fraction_subtraction_kg <- mv_kg_build(fs_concepts, items = fs_q,
                                       name = "Fraction subtraction (Tatsuoka)")

usethis::use_data(fractions, fractions_kg, fraction_subtraction, fraction_subtraction_kg,
                  overwrite = TRUE, compress = "xz")
sysdata <- new.env()
load("R/sysdata.rda", envir = sysdata)
assign("fractions_truth", fractions_truth, envir = sysdata)
save(list = ls(sysdata), envir = sysdata, file = "R/sysdata.rda", compress = "xz")
