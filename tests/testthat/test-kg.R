test_that("mv_kg_build() stores concepts, items and edges", {
  kg <- mv_kg_build(
    concepts = data.frame(concept = c("a", "b", "c"), label = c("A", "B", NA)),
    edges = data.frame(from = c("a", "b"), to = c("b", "c")),
    items = data.frame(item = c("Q1", "Q2", "Q3", "Q3"), concept = c("a", "b", "c", "b")),
    name = "toy")
  expect_s3_class(kg, "mv_kg")
  expect_equal(sum(kg$nodes$kind == "concept"), 3)
  expect_equal(sum(kg$nodes$kind == "item"), 3)
  expect_equal(kg$nodes$label[kg$nodes$node == "c"], "c")
  expect_equal(sum(kg$edges$type == "prerequisite"), 2)
  expect_equal(sum(kg$edges$type == "measures"), 4)
  g <- glance(kg)
  expect_equal(g$depth, 2)
  expect_true(g$acyclic)
  expect_output(print(kg), "toy: 3 concept")
})

test_that("mv_kg_build() rejects bad input", {
  expect_error(mv_kg_build(c("a", "a")), "unique")
  expect_error(mv_kg_build("a", edges = data.frame(from = "a", to = "z")), "not in `concepts`")
  expect_error(mv_kg_build("a", items = data.frame(item = "Q1", concept = "z")), "not in `concepts`")
  expect_error(mv_kg_build("a", items = data.frame(item = "a", concept = "a")), "different names")
  expect_error(mv_kg_build(c("a", "b"), edges = data.frame(from = "a", to = "b", type = "measures")),
               "prerequisite")
})

test_that("a Q-matrix and an edge list convert to the same graph", {
  q <- matrix(c(1, 0, 1, 0, 0, 1, 1, 1), ncol = 2, byrow = TRUE,
              dimnames = list(paste0("Q", 1:4), c("x", "y")))
  kg1 <- as_mv_kg(q)
  el <- data.frame(from = c("Q1", "Q2", "Q3", "Q4", "Q4"), to = c("x", "x", "y", "x", "y"),
                   type = "measures")
  kg2 <- as_mv_kg(el)
  key <- function(k) sort(paste(k$edges$from, k$edges$to))
  expect_equal(key(kg1), key(kg2))
  qdf <- data.frame(item = rownames(q), q)
  expect_equal(key(as_mv_kg(qdf)), key(kg1))
  expect_identical(as_mv_kg(kg1), kg1)
})

test_that("as_mv_kg() reads the loading pattern of a confirmatory model", {
  dat <- fractions[, c("F01", "F02", "F03", "F04", "F05", "F06", "F07", "F08")]
  spec <- mirt::mirt.model("meaning = 1-4\nequivalent = 5-8\nCOV = meaning*equivalent")
  mod <- mirt::mirt(dat, spec, verbose = FALSE, TOL = 0.01)
  kg <- as_mv_kg(mod)
  expect_setequal(kg$nodes$node[kg$nodes$kind == "concept"], c("meaning", "equivalent"))
  expect_equal(sum(kg$edges$type == "measures"), 8)
})

test_that("as_mv_kg() converts igraph objects", {
  skip_if_not_installed("igraph")
  g <- igraph::graph_from_data_frame(
    data.frame(from = c("a", "Q1", "Q2"), to = c("b", "a", "b")),
    vertices = data.frame(name = c("a", "b", "Q1", "Q2"),
                          kind = c("concept", "concept", "item", "item")))
  kg <- as_mv_kg(g)
  expect_equal(sum(kg$edges$type == "prerequisite"), 1)
  expect_equal(sum(kg$edges$type == "measures"), 2)
})

test_that("mv_kg_check() finds cycles, thin concepts and redundancy", {
  kg <- mv_kg_build(c("a", "b", "c"),
                    edges = data.frame(from = c("a", "b", "c"), to = c("b", "c", "a")),
                    items = data.frame(item = paste0("Q", 1:4), concept = c("a", "a", "a", "b")))
  chk <- mv_kg_check(kg)
  expect_s3_class(chk, "mv_kg_check")
  expect_true("cycle" %in% chk$check)
  expect_true(all(c("few_items", "unmeasured") %in% chk$check))
  expect_equal(chk$level[1], "block")
  expect_false(glance(kg)$acyclic)
  expect_output(print(kg), "cycle")

  kg2 <- mv_kg_build(c("a", "b", "c", "d"),
                     edges = data.frame(from = c("a", "b", "a", "a"), to = c("b", "c", "c", "b")),
                     items = data.frame(item = paste0("Q", 1:6),
                                        concept = c("a", "a", "a", "b", "b", "b")))
  chk2 <- mv_kg_check(kg2)
  expect_true("redundant_prerequisite" %in% chk2$check)
  expect_true("duplicate_edge" %in% chk2$check)
  expect_true("isolated" %in% chk2$check)
  q <- matrix(1, 3, 2, dimnames = list(paste0("Q", 1:3), c("x", "y")))
  expect_true("same_items" %in% mv_kg_check(as_mv_kg(q))$check)
  expect_output(print(mv_kg_check(mv_kg_build("a"))), "No problems")
})

test_that("the example graphs are valid and match their data", {
  expect_s3_class(fractions_kg, "mv_kg")
  expect_equal(ncol(fractions) - 1, sum(fractions_kg$nodes$kind == "item"))
  expect_setequal(names(fractions)[-1], fractions_kg$nodes$node[fractions_kg$nodes$kind == "item"])
  expect_false(any(mv_kg_check(fractions_kg)$level == "block"))
  expect_equal(dim(fraction_subtraction), c(536L, 20L))
  expect_setequal(names(fraction_subtraction),
                  fraction_subtraction_kg$nodes$node[fraction_subtraction_kg$nodes$kind == "item"])
  expect_equal(sum(fraction_subtraction_kg$edges$type == "measures"), 56)
  truth <- lab_truth("fractions")
  expect_equal(nrow(truth$planted), 2)
  expect_equal(glance(truth$graph)$prerequisite, glance(fractions_kg)$prerequisite + 1)
})

test_that("tidy() and gg_kg() work", {
  nd <- tidy(fractions_kg)
  expect_true(all(c("node", "kind", "links", "depth") %in% names(nd)))
  expect_equal(nd$links[nd$node == "meaning"], 4)
  expect_equal(nrow(tidy(fractions_kg, "edges")), nrow(fractions_kg$edges))
  expect_s3_class(gg_kg(fractions_kg), "ggplot")
  expect_s3_class(gg_kg(fractions_kg, items = FALSE, highlight = "compare", labels = "node"), "ggplot")
  expect_s3_class(gg_kg(fraction_subtraction_kg), "ggplot")
  expect_s3_class(gg_kg(mv_kg_build("a")), "ggplot")
})
