tk_course <- function() {
  path <- file.path(withr::local_tempdir(.local_envir = parent.frame()), "course")
  new_course(path, title = "Test course", instructor = "A. Teacher")
  path
}

test_that("tk_prepare_data() warns about small samples", {
  expect_warning(mirtverse:::tk_prepare_data(expand.table(LSAT7)[1:150, ]), "fewer than about 200")
})

test_that("tk_prepare_data() expands frequency tables", {
  p <- mirtverse:::tk_prepare_data(LSAT7)
  expect_equal(dim(p$responses), c(1000L, 5L))
  expect_equal(colMeans(p$responses), colMeans(expand.table(LSAT7)), ignore_attr = TRUE)
})

test_that("new_course() writes the layout and refuses to overwrite", {
  course <- tk_course()
  expect_true(all(dir.exists(file.path(course, c("labs", "chapters", "data")))))
  info <- jsonlite::read_json(file.path(course, "course.json"))
  expect_equal(info$title, "Test course")
  expect_match(paste(readLines(file.path(course, "README.md")), collapse = "\n"), "A. Teacher")
  expect_error(new_course(course), "already exists")
  expect_silent(new_course(course, title = "New", overwrite = TRUE))
  expect_equal(nrow(course_materials(course)), 0)
})

test_that("tk_prepare_data() finds items, scores with a key and checks the group", {
  d <- data.frame(id = 1:300, sex = rep(c("F", "M"), 150),
                  expand.table(LSAT7)[1:300, ])
  p <- mirtverse:::tk_prepare_data(d, group = "sex")
  expect_equal(p$items, paste0("Item.", 1:5))
  expect_equal(levels(p$group), c("F", "M"))
  expect_error(mirtverse:::tk_prepare_data(d, items = 3:4), "at least 4")
  expect_error(mirtverse:::tk_prepare_data(d, group = rep(1:3, 100)), "exactly two")
  cert <- mirtverse:::tk_prepare_data(certexam, key = certexam_key, group = "language")
  expect_equal(ncol(cert$responses), 32)
  expect_true(all(unlist(cert$responses) %in% 0:1))
  expect_error(mirtverse:::tk_prepare_data(certexam[, -(1:2)], items = names(certexam_key)),
               "whole numbers")
})

test_that("new_lab() builds a lab whose exercises pass their own checks", {
  skip_if_not_installed("learnr")
  course <- tk_course()
  lab <- new_lab("lsat", expand.table(LSAT7), course, data_title = "the LSAT7 items",
                 sections = c("intro", "classical", "models", "scoring", "wrap-up"))
  expect_true(file.exists(file.path(lab, "lsat.Rmd")))
  d <- lab_data(file.path(lab, "data"))
  expect_equal(dim(d$responses), c(1000L, 5L))
  expect_equal(d$models, c("Rasch", "2PL"))
  expect_equal(d$info$data_title, "the LSAT7 items")
  out <- lab_outline(lab)
  expect_equal(out$id, c("intro", "classical", "models", "scoring", "wrap-up"))
  expect_equal(out$exercises, c(1L, 2L, 2L, 2L, 0L))
  res <- check_material(lab)
  expect_true(all(res$status == "pass"), info = paste(res$label, res$message, collapse = "\n"))
  expect_true(all(c("structure", "data", "chunk", "exercise") %in% res$check))
  m <- course_materials(course)
  expect_equal(m$source, "toolkit")
  expect_equal(m$data, "the LSAT7 items")
  expect_error(new_lab("lsat", expand.table(LSAT7), course), "already exists")
  expect_error(new_lab("bad name", expand.table(LSAT7), course), "letters, digits")
  expect_error(new_lab("x", expand.table(LSAT7), course, sections = "dif"), "needs a `group`")
})

test_that("polytomous data get the partial credit and graded models", {
  skip_if_not_installed("learnr")
  course <- tk_course()
  lab <- new_lab("sci", Science, course, sections = c("classical", "models"))
  expect_equal(lab_data(file.path(lab, "data"))$models, c("Rasch", "graded"))
  res <- check_material(lab)
  expect_true(all(res$status == "pass"), info = paste(res$label, res$message, collapse = "\n"))
})

test_that("sections, exercises and questions can be added, listed and removed", {
  skip_if_not_installed("learnr")
  course <- tk_course()
  lab <- new_lab("demo", expand.table(LSAT7), course, sections = c("intro", "wrap-up"))
  add_lab_section(lab, "classical")
  add_lab_section(lab, "classical")
  add_lab_exercise(lab, title = "Total scores", prompt = "Save the totals as `total`.",
                   starter = "total <- ", solution = "total <- rowSums(resp)",
                   check = c("lab_need(length(total) == nrow(resp), 'One total per person.')",
                             "'Good.'"),
                   hint = "# rowSums()", after = "intro")
  add_lab_exercise(lab, title = "Broken", prompt = "x", solution = "y <- 1",
                   check = "lab_need(FALSE, 'This check always fails.')", use_fit = TRUE)
  add_lab_question(lab, "Isn't a low mean a hard item?", c("Yes", "No"), correct = "Yes",
                   messages = c("Right.", "Look again."))
  add_lab_question(lab, "Pick the 0/1 models", c("Rasch", "2PL", "graded"), correct = 1:2)
  out <- lab_outline(lab)
  expect_equal(out$id, c("intro", "total-scores", "classical", "classical-2", "broken",
                         "q-isn-t-a-low-mean-a-hard-item", "q-pick-the-0-1-models", "wrap-up"))
  expect_equal(out$questions[out$type == "question"], c(1L, 1L))
  rmd <- readLines(file.path(lab, "demo.Rmd"), encoding = "UTF-8")
  expect_true(any(grepl("Isn\u2019t", rmd)))
  expect_true(any(grepl("question_checkbox", rmd)))
  res <- check_material(lab)
  expect_equal(res$label[res$status == "fail"], "broken")
  expect_match(res$message[res$label == "broken"], "always fails")
  expect_true(all(res$status[res$label != "broken"] == "pass"))
  remove_lab_section(lab, "broken")
  expect_false("broken" %in% lab_outline(lab)$id)
  expect_error(remove_lab_section(lab, "nope"), "No section")
  expect_error(add_lab_section(lab, "nope"), "Unknown section type")
  expect_error(add_lab_section(lab, "dif"), "grouping variable")
  expect_error(add_lab_question(lab, "Q?", c("a", "b"), correct = "c"), "at least one")
})

test_that("swap_lab_data() replaces the data and keeps the settings", {
  skip_if_not_installed("learnr")
  course <- tk_course()
  d <- data.frame(g = rep(c("A", "B"), 500), expand.table(LSAT7))
  lab <- new_lab("demo", d, course, group = "g", data_title = "first",
                 sections = c("intro", "classical"))
  d2 <- data.frame(g = rep(c("A", "B"), 500), expand.table(LSAT6))
  swap_lab_data(lab, d2)
  new <- lab_data(file.path(lab, "data"))
  expect_equal(new$info$data_title, "first")
  expect_equal(levels(new$group), c("A", "B"))
  expect_equal(colMeans(new$responses), colMeans(expand.table(LSAT6)), ignore_attr = TRUE)
  expect_true(all(check_material(lab)$status == "pass"))
  cl <- copy_lab("model-choice", course)
  expect_error(swap_lab_data(cl, d2), "not made with new_lab")
})

test_that("copy_lab() copies a built-in lab that the outline functions can read", {
  course <- tk_course()
  lab <- copy_lab("fairness", course, as = "week9")
  expect_true(file.exists(file.path(lab, "week9.Rmd")))
  out <- lab_outline(lab)
  expect_true(nrow(out) > 5)
  expect_true(all(out$type == "built-in"))
  expect_true(sum(out$exercises) > 5)
  add_lab_question(lab, "A question?", c("a", "b"), correct = 1, after = out$id[1])
  expect_equal(lab_outline(lab)$type[2], "question")
  expect_equal(course_materials(course)$source, "built-in")
  expect_error(copy_lab("nope", course), "Unknown lab")
  expect_error(copy_lab("fairness", course, as = "week9"), "already exists")
  expect_error(add_lab_section(lab, "classical"), "made with new_lab")
})

test_that("chapters can be created, copied from a local book, swapped and checked", {
  course <- tk_course()
  ch <- new_chapter("my-week", course, title = "My week")
  lines <- readLines(ch)
  expect_true(any(grepl("{#my-week}", lines, fixed = TRUE)))
  expect_equal(sum(grepl("^```\\{r data-my-week-", lines)), 2)
  res <- check_material(ch)
  expect_true(all(res$status == "pass"), info = paste(res$label, res$message, collapse = "\n"))
  swap_chapter_data(ch, chunk = "data-my-week-2", code = c("resp <- expand.table(LSAT6)", "stopifnot(ncol(resp) == 5)"))
  lines <- readLines(ch)
  i <- grep("^```\\{r data-my-week-2", lines)
  expect_equal(lines[i + 1:2], c("resp <- expand.table(LSAT6)", "stopifnot(ncol(resp) == 5)"))
  expect_equal(lines[i + 3], "```")
  swap_chapter_data(ch, code = "resp <- expand.table(LSAT7)[1:400, ]")
  expect_equal(sum(readLines(ch) == "resp <- expand.table(LSAT7)[1:400, ]"), 2)
  expect_error(swap_chapter_data(ch, chunk = "nope", code = "x"), "No chunk")

  book <- withr::local_tempdir()
  writeLines(c("# DIF {#dif}", "", "```{r data-dif-1}", "resp <- expand.table(LSAT7)", "```", "",
               "```{r}", "stopifnot(exists('common_ran'))", "```"), file.path(book, "09-dif.Rmd"))
  writeLines("common_ran <- TRUE", file.path(book, "_common.R"))
  copied <- copy_chapter("dif", course, from = book)
  expect_true(file.exists(file.path(course, "chapters", "_common.R")))
  expect_match(readLines(copied)[1], "mirtverse-book-chapter: dif")
  expect_true(all(check_material(copied)$status == "pass"))
  m <- course_materials(course)
  expect_setequal(m$source, c("toolkit", "book"))
  expect_error(copy_chapter("nope", course), "Unknown chapter")
  expect_error(copy_chapter("dif", course, from = book), "already exists")
})

test_that("check_material() reports broken structure and checks a whole course", {
  skip_if_not_installed("learnr")
  course <- tk_course()
  lab <- new_lab("demo", expand.table(LSAT7), course, sections = c("intro"))
  rmd <- file.path(lab, "demo.Rmd")
  writeLines(c(readLines(rmd), "", "```{r intro-look}", "1", "```", "", "```{r ghost-check}", "1", "```"), rmd)
  res <- check_material(lab)
  expect_equal(res$status[res$label == "labels"], "fail")
  expect_equal(res$status[res$label == "orphans"], "fail")
  new_chapter("ch", course, data_code = "stop('no data here')")
  all <- check_material(course)
  expect_setequal(unique(all$material), c("demo", "ch"))
  expect_true(any(all$material == "ch" & all$status == "fail"))
})

test_that("the AI section types need their data", {
  types <- lab_section_types()
  expect_true(all(c("item-features", "aig", "ai-scoring") %in% types$type))
  expect_equal(types$needs[match(c("item-features", "aig", "ai-scoring"), types$type)],
               c("item text", "item families", "scores"))
  expect_equal(mirtverse:::tk_default_sections(c("item text", "scores")),
               c("intro", "classical", "dimensionality", "models", "item-fit", "information",
                 "scoring", "item-features", "ai-scoring", "reflection", "wrap-up"))
  course <- tk_course()
  expect_error(new_lab("x", aigfield, course, sections = "aig"), "`item_info` with a `family`")
  expect_error(new_lab("x", aigfield, course, item_info = aigfield_items, sections = "aig"),
               "`family` column")
  expect_error(new_lab("x", aigfield, course, sections = "ai-scoring"), "`scores`")
  expect_error(mirtverse:::tk_prepare_item_info(data.frame(name = "a"), "a"), "column `item`")
  expect_error(mirtverse:::tk_prepare_item_info(aigfield_items, paste0("Q", 1:5)), "at least 4")
  expect_warning(ii <- mirtverse:::tk_prepare_item_info(aigfield_items, c(names(aigfield)[1:5], "Q9")),
                 "no row for 1")
  expect_equal(names(ii)[1], "item")
  expect_error(mirtverse:::tk_prepare_scores(data.frame(machine = 1:60)), "`human1`")
  sc <- mirtverse:::tk_prepare_scores(transform(aiscored_cr, period = year))
  expect_setequal(names(sc), c("machine", "human1", "human2", "group", "item", "period"))
})

test_that("labs with the item-features and aig sections pass their own checks", {
  skip_if_not_installed("learnr")
  course <- tk_course()
  items <- transform(aigfield_items, family = model)
  lab <- new_lab("factory", aigfield, course, item_info = items,
                 sections = c("intro", "item-features", "aig", "wrap-up"))
  d <- lab_data(file.path(lab, "data"))
  expect_equal(nrow(d$item_info), 60L)
  expect_null(d$scores)
  expect_equal(lab_outline(lab)$exercises, c(1L, 2L, 2L, 0L))
  res <- check_material(lab)
  expect_true(all(res$status == "pass"), info = paste(res$label, res$message, collapse = "\n"))
  expect_match(res$message[res$label == "aig-cal"], "SUB, TRI")
  expect_error(add_lab_section(lab, "ai-scoring"), "needs scores")
  # swapping the responses keeps the item information
  swap_lab_data(lab, aigfield[1:600, ])
  expect_equal(nrow(lab_data(file.path(lab, "data"))$item_info), 60L)
})

test_that("a lab with the ai-scoring section passes its own checks", {
  skip_if_not_installed("learnr")
  course <- tk_course()
  sc <- aiscored_cr[aiscored_cr$year == 2025, c("machine", "human1", "group", "item")]
  lab <- new_lab("engine", aiscored[aiscored$year == 2025, ], course,
                 items = sprintf("MC%02d", 1:16), scores = sc,
                 sections = c("intro", "ai-scoring", "wrap-up"))
  rmd <- paste(readLines(file.path(lab, "engine.Rmd")), collapse = "\n")
  expect_match(rmd, 'ai_audit(scores, group = "group", item = "item")', fixed = TRUE)
  expect_false(grepl("human2", rmd))
  res <- check_material(lab)
  expect_true(all(res$status == "pass"), info = paste(res$label, res$message, collapse = "\n"))
  expect_warning(swap_lab_data(lab, aiscored[aiscored$year == 2026, ],
                               scores = aiscored_cr[aiscored_cr$year == 2026, ]),
                 "different columns")
})

test_that("copy_workshop() copies the kit, which renders", {
  dest <- file.path(withr::local_tempdir(), "kit")
  copy_workshop(dest)
  expect_setequal(list.files(dest), c("README.md", "slides.Rmd", "facilitator-guide.Rmd"))
  expect_error(copy_workshop(dest), "overwrite = TRUE")
  expect_silent(copy_workshop(dest, overwrite = TRUE))
  skip_on_cran()
  skip_if_not(rmarkdown::pandoc_available())
  for (f in c("slides.Rmd", "facilitator-guide.Rmd")) {
    out <- rmarkdown::render(file.path(dest, f), quiet = TRUE, envir = new.env())
    expect_true(file.exists(out))
  }
})
