#' Build a lab from your own data
#'
#' `new_lab()` writes an interactive lab (a learnr tutorial) that walks
#' students through an IRT analysis of *your* dataset: the data, classical
#' item statistics, dimensionality, model comparison, item fit, information,
#' scoring and, when you give a grouping variable, DIF. Every number in the
#' text, every answer check and every multiple-choice question is computed
#' from the data when the lab is rendered, so the same lab works with any
#' dataset and [swap_lab_data()] can replace the data later without touching
#' the text.
#'
#' The lab is a folder `labs/<name>/` inside the course folder, holding
#' `<name>.Rmd` and a `data/` folder (`responses.rds` and `lab.json`). Edit
#' the `.Rmd` freely; [add_lab_section()], [add_lab_exercise()] and
#' [add_lab_question()] add content, and [check_material()] runs every
#' exercise's solution through its check.
#'
#' @param name the lab's name: letters, digits, `-` and `_`.
#' @param data the responses: a data frame or matrix, or the path of a file
#'   (`.csv`, `.tsv`, `.txt`, `.xlsx`, `.xls`, `.sav`, `.dta`, `.sas7bdat` or
#'   `.rds`). Items must be scored 0/1 or in ordered integer categories,
#'   unless you give a `key`. A frequency table (one row per response pattern
#'   with a `freq` or `count` column, such as [mirt::LSAT7]) is expanded to
#'   one row per person.
#' @param course the course folder (see [new_course()]); the lab goes in its
#'   `labs/` folder.
#' @param items the item columns, by name or position. By default, every
#'   column whose values are whole numbers from 0 to 9 (other than `group`
#'   and ID-like columns), or the names of a named `key`.
#' @param group optional grouping variable with two values, for the DIF
#'   section: a column name of `data`, or a vector with one value per row.
#' @param key optional answer key for unscored multiple-choice responses, one
#'   value per item; the items are scored with [mirt::key2binary()].
#' @param title the lab's title.
#' @param data_title a short name for the data used in the lab's text, for
#'   example `"the Grade 8 science test"`.
#' @param story a paragraph that sets the scene, shown at the start of the
#'   lab.
#' @param sections the sections to include, in order; see
#'   [lab_section_types()]. The default includes every section that suits the
#'   data (`"dif"` only with a `group`).
#' @param overwrite replace an existing lab of the same name.
#' @return The path of the lab folder, invisibly.
#' @seealso [new_course()], [swap_lab_data()], [add_lab_section()],
#'   [check_material()], [preview_lab()]
#' @examples
#' course <- file.path(tempdir(), "lab-demo")
#' new_course(course)
#' lab <- new_lab("lsat", data = expand.table(LSAT7), course = course,
#'                data_title = "the LSAT section 7 items",
#'                sections = c("intro", "classical", "models", "wrap-up"))
#' lab_outline(lab)
#' @export
new_lab <- function(name, data, course = ".", items = NULL, group = NULL, key = NULL,
                    title = NULL, data_title = NULL, story = NULL, sections = NULL,
                    overwrite = FALSE) {
  tk_check_name(name)
  prep <- tk_prepare_data(data, items = items, group = group, key = key)
  sections <- sections %||% tk_default_sections(!is.null(prep$group))
  tk_check_sections(sections, has_group = !is.null(prep$group))
  data_title <- data_title %||% (if (is.character(data) && length(data) == 1L)
    paste0("the data in ", basename(data)) else "the test data")
  title <- title %||% paste("An IRT analysis of", data_title)
  dest <- file.path(course, "labs", name)
  tk_prepare_dest(dest, overwrite)
  tk_write_data(dest, prep, data_title = data_title,
                story = story %||% tk_default_story(data_title), title = title)
  head <- tk_fill(tk_template("lab.Rmd"), list(
    title = gsub("\"", "'", title),
    description = paste0("An IRT analysis of ", data_title, ", from the raw responses to a recommendation."),
    made_with = tk_made_with()))
  body <- unlist(lapply(tk_unique_ids(sections), function(s)
    tk_fill(tk_template(file.path("sections", paste0(s$type, ".Rmd"))), list(id = s$id))))
  writeLines(c(head, body), file.path(dest, paste0(name, ".Rmd")))
  invisible(dest)
}

#' Replace the data in a toolkit lab
#'
#' Swaps the responses behind a lab made with [new_lab()] for another
#' dataset, for example next year's class or your own test. The lab's text,
#' answer checks and questions are computed from the data, so nothing else
#' needs to change. Settings you leave out (`group`, `data_title`, `story`)
#' are kept from the current data, except that `items` and `key` are always
#' worked out again. Run [check_material()] afterwards.
#'
#' If the lab has a DIF section and the new data have no `group`, the DIF
#' section will fail; remove it with [remove_lab_section()].
#'
#' @param lab the lab folder.
#' @inheritParams new_lab
#' @return The lab folder, invisibly.
#' @seealso [new_lab()], [lab_data()]
#' @examples
#' course <- file.path(tempdir(), "swap-demo")
#' lab <- new_lab("demo", data = expand.table(LSAT7), course = course,
#'                sections = c("intro", "classical"))
#' swap_lab_data(lab, data = expand.table(LSAT6), data_title = "the LSAT section 6 items")
#' lab_data(file.path(lab, "data"))$info$data_title
#' @export
swap_lab_data <- function(lab, data, items = NULL, group = NULL, key = NULL,
                          data_title = NULL, story = NULL) {
  dir <- tk_lab_dir(lab)
  old <- tk_lab_info(dir)
  if (is.null(old))
    stop(lab, " was not made with new_lab(), so its text is written for its own data. ",
         "Build a lab on the new data with new_lab() instead.", call. = FALSE)
  if (is.null(group) && !is.null(old$group) && is.data.frame(data) && old$group %in% names(data))
    group <- old$group
  prep <- tk_prepare_data(data, items = items, group = group, key = key)
  rmd <- readLines(tk_lab_rmd(dir), warn = FALSE)
  if (is.null(prep$group) && any(grepl("type=dif", rmd, fixed = TRUE)))
    warning("The lab has a DIF section but the new data have no `group`; ",
            "remove the section with remove_lab_section().", call. = FALSE)
  tk_write_data(dir, prep, data_title = data_title %||% old$data_title,
                story = story %||% old$story, title = old$title)
  invisible(dir)
}

#' Load the data of a toolkit lab
#'
#' Used in the setup chunk of labs made with [new_lab()]: reads
#' `data/responses.rds` and `data/lab.json`. You can also call it yourself to
#' see what a lab will use.
#'
#' @param dir the lab's `data/` folder. Inside a running lab this is the
#'   default, `"data"`.
#' @return A list with `responses` (a data frame of scored item responses),
#'   `group` (a factor, or `NULL`), `polytomous` (logical), `models` (the
#'   two item types the lab compares: `c("Rasch", "2PL")` for 0/1 items,
#'   `c("Rasch", "graded")` otherwise) and `info` (the settings in
#'   `lab.json`).
#' @export
lab_data <- function(dir = "data") {
  rds <- file.path(dir, "responses.rds")
  if (!file.exists(rds))
    stop("No lab data in ", normalizePath(dir, mustWork = FALSE),
         ". Labs made with new_lab() keep their data in data/responses.rds.", call. = FALSE)
  d <- readRDS(rds)
  info <- jsonlite::read_json(file.path(dir, "lab.json"), simplifyVector = TRUE)
  poly <- any(vapply(d$responses, function(v) max(v, na.rm = TRUE) > 1, logical(1)))
  list(responses = d$responses, group = d$group, polytomous = poly,
       models = if (poly) c("Rasch", "graded") else c("Rasch", "2PL"), info = info)
}

#' Sections you can add to a toolkit lab
#'
#' The ready-made sections that [new_lab()] and [add_lab_section()] use. Each
#' works with any dataset: its numbers, checks and questions are computed
#' from the lab's data.
#'
#' @return A tibble with the section `type`, its `title`, a `description`, and
#'   `needs` (`"group"` when the section needs a grouping variable).
#' @examples
#' lab_section_types()
#' @export
lab_section_types <- function() {
  as_tbl(data.frame(
    type = c("intro", "classical", "dimensionality", "models", "item-fit", "information",
             "scoring", "dif", "reflection", "wrap-up"),
    title = c("Meet the data", "Classical item statistics", "How many dimensions?",
              "Compare IRT models", "Item fit", "Information and precision", "Scoring people",
              "Are the items fair?", "Your recommendation", "Where to next"),
    description = c(
      "The story, the size of the data and a first look at the responses.",
      "Item means and item-total correlations; find the weakest item.",
      "Compare one- and two-factor models with anova() and BIC.",
      "Compare the Rasch model with the 2PL (or graded) model; select_model().",
      "S-X2 item fit with itemfit() and gg_itemfit(); count the misfitting items.",
      "Test information and standard error with gg_info(); where the test is precise.",
      "EAP scores with fscores(), compared with sum scores; why patterns matter.",
      "Likelihood-ratio DIF tests between two groups with dif().",
      "A written recommendation (free text).",
      "A summary and pointers to reports and further labs."),
    needs = c(rep("", 7), "group", "", ""),
    stringsAsFactors = FALSE))
}

#' Add, remove and list the sections of a lab
#'
#' `add_lab_section()` adds one of the ready-made sections in
#' [lab_section_types()]. `add_lab_exercise()` adds a coding exercise you
#' write yourself, and `add_lab_question()` a multiple-choice question.
#' `remove_lab_section()` deletes a section and `lab_outline()` lists them.
#'
#' Sections start with a level-2 heading (`## `), marked by an
#' `<!-- mv-section: ... -->` comment in labs made with the toolkit. These
#' functions also work on copies of the built-in labs made with [copy_lab()],
#' whose sections are identified by their headings.
#'
#' New content goes before the lab's `"wrap-up"` section if it has one,
#' otherwise at the end, unless you name a section in `after`.
#'
#' @param lab the lab folder (or its `.Rmd` file).
#' @param type the kind of section; see [lab_section_types()].
#' @param after the `id` of the section to put the new one after (see
#'   `lab_outline()`).
#' @param id the new section's id, used in its chunk labels. Defaults to the
#'   type (for `add_lab_section()`) or a slug of the title, made unique.
#' @return `lab_outline()` returns a tibble with one row per section: `id`,
#'   `type` (`"built-in"` for unmarked sections), `title`, and the number of
#'   `exercises` and `questions` in it. The other functions return the
#'   `.Rmd` path, invisibly.
#' @seealso [new_lab()], [check_material()]
#' @examples
#' course <- file.path(tempdir(), "sections-demo")
#' lab <- new_lab("demo", data = expand.table(LSAT7), course = course,
#'                sections = c("intro", "wrap-up"))
#' add_lab_section(lab, "classical")
#' add_lab_exercise(lab, title = "Total scores",
#'   prompt = "Compute each person's total score and save it as `total`.",
#'   solution = "total <- rowSums(resp)",
#'   check = c("lab_need(exists('total'), 'Save the totals as `total`.')",
#'             "lab_need(length(total) == nrow(resp), 'One total per person.')",
#'             "'Well done.'"))
#' add_lab_question(lab, "What does a low item mean tell you?",
#'   answers = c("The item is hard", "The item is easy"), correct = 1)
#' lab_outline(lab)
#' remove_lab_section(lab, "classical")
#' @export
add_lab_section <- function(lab, type, after = NULL, id = NULL) {
  rmd <- tk_lab_rmd(tk_lab_dir(lab))
  types <- lab_section_types()
  if (!is.character(type) || length(type) != 1L || !type %in% types$type)
    stop("Unknown section type \"", paste(type, collapse = ", "), "\". Available: ",
         paste(types$type, collapse = ", "), ".", call. = FALSE)
  if (is.null(tk_lab_info(dirname(rmd))))
    stop("Ready-made sections need a lab made with new_lab(); for other labs use ",
         "add_lab_exercise() or add_lab_question().", call. = FALSE)
  lines <- readLines(rmd, warn = FALSE, encoding = "UTF-8")
  if (identical(type, "dif") && is.null(lab_data(file.path(dirname(rmd), "data"))$group))
    stop("The DIF section needs a grouping variable. Add one with swap_lab_data(lab, data, group = ...).",
         call. = FALSE)
  id <- tk_new_id(id %||% type, lines)
  block <- tk_fill(tk_template(file.path("sections", paste0(type, ".Rmd"))), list(id = id))
  tk_insert(rmd, lines, block, after)
}

#' @rdname add_lab_section
#' @param title the section heading.
#' @param prompt the instructions students read, in Markdown (a character
#'   vector is joined with line breaks).
#' @param solution R code that solves the exercise.
#' @param starter R code students start from, for example with a blank to
#'   fill. Defaults to an empty exercise box.
#' @param check R code that checks the student's result, run after their
#'   code. Use `lab_need(condition, "message")` to fail with a message, and
#'   `.result` for the value of the student's last line; the last value, if a
#'   string, is shown on success. Defaults to accepting any code that runs.
#' @param hint optional hint (R code or comments).
#' @param use_fit logical; start from the lab's fitted one-factor model `fit`
#'   (labs made with [new_lab()] only).
#' @export
add_lab_exercise <- function(lab, title, prompt, solution, starter = NULL, check = NULL,
                             hint = NULL, use_fit = FALSE, after = NULL, id = NULL) {
  rmd <- tk_lab_rmd(tk_lab_dir(lab))
  check_string(title, "title")
  lines <- readLines(rmd, warn = FALSE, encoding = "UTF-8")
  if (use_fit && !any(grepl("^```\\{r setup-fit", lines)))
    stop("This lab has no `setup-fit` chunk, so use_fit = TRUE is not available.", call. = FALSE)
  id <- tk_new_id(id %||% tk_slug(title), lines)
  opts <- paste0("exercise = TRUE", if (use_fit) ", exercise.setup = \"setup-fit\"",
                 ", exercise.lines = ", max(6L, length(tk_lines(solution)) + 2L))
  block <- c(
    sprintf("<!-- mv-section: id=%s type=exercise -->", id),
    paste("##", title), "",
    tk_lines(prompt), "",
    sprintf("```{r %s, %s}", id, opts), tk_lines(starter %||% ""), "```", "",
    if (!is.null(hint)) c(sprintf("```{r %s-hint}", id), tk_lines(hint), "```", ""),
    sprintf("```{r %s-solution}", id), tk_lines(solution), "```", "",
    sprintf("```{r %s-check}", id), tk_lines(check %||% "\"Well done.\""), "```", "")
  tk_insert(rmd, lines, block, after)
}

#' @rdname add_lab_section
#' @param question the question text.
#' @param answers the answer options (character).
#' @param correct which answers are correct: their positions in `answers`, or
#'   the answers themselves. More than one makes a check-all-that-apply
#'   question.
#' @param messages optional feedback for each answer, in the same order.
#' @export
add_lab_question <- function(lab, question, answers, correct, messages = NULL,
                             title = NULL, after = NULL, id = NULL) {
  rmd <- tk_lab_rmd(tk_lab_dir(lab))
  check_string(question, "question")
  if (!is.character(answers) || length(answers) < 2L)
    stop("Give at least two `answers`.", call. = FALSE)
  ok <- if (is.character(correct)) answers %in% correct else seq_along(answers) %in% correct
  if (!any(ok)) stop("`correct` must name at least one of the `answers`.", call. = FALSE)
  if (!is.null(messages) && length(messages) != length(answers))
    stop("Give one message per answer, or none.", call. = FALSE)
  lines <- readLines(rmd, warn = FALSE, encoding = "UTF-8")
  title <- title %||% "Check your understanding"
  id <- tk_new_id(id %||% paste0("q-", tk_slug(question)), lines)
  # learnr drops straight apostrophes from question text, so use the typographic one
  q <- function(x) {
    x <- gsub("'", "\u2019", x, fixed = TRUE)
    x <- gsub("\\", "\\\\", x, fixed = TRUE)
    x <- gsub("\"", "\\\"", x, fixed = TRUE)
    paste0("\"", gsub("\n", " ", x, fixed = TRUE), "\"")
  }
  ans <- vapply(seq_along(answers), function(i) {
    paste0("  answer(", q(answers[i]), if (ok[i]) ", correct = TRUE",
           if (!is.null(messages) && nzchar(messages[i])) paste0(", message = ", q(messages[i])), "),")
  }, character(1))
  fun <- if (sum(ok) > 1L) "question_checkbox" else "question_radio"
  block <- c(
    sprintf("<!-- mv-section: id=%s type=question -->", id),
    paste("##", title), "",
    sprintf("```{r %s}", id),
    paste0(fun, "("), paste0("  ", q(question), ","), ans,
    "  allow_retry = TRUE, random_answer_order = TRUE)", "```", "")
  tk_insert(rmd, lines, block, after)
}

#' @rdname add_lab_section
#' @export
remove_lab_section <- function(lab, id) {
  rmd <- tk_lab_rmd(tk_lab_dir(lab))
  lines <- readLines(rmd, warn = FALSE, encoding = "UTF-8")
  secs <- tk_sections(lines)
  i <- match(id, secs$id)
  if (is.na(i))
    stop("No section \"", id, "\". Sections: ", paste(secs$id, collapse = ", "), ".", call. = FALSE)
  writeLines(enc2utf8(lines[-(secs$start[i]:secs$end[i])]), rmd, useBytes = TRUE)
  invisible(rmd)
}

#' @rdname add_lab_section
#' @export
lab_outline <- function(lab) {
  rmd <- tk_lab_rmd(tk_lab_dir(lab))
  lines <- readLines(rmd, warn = FALSE, encoding = "UTF-8")
  secs <- tk_sections(lines)
  ex <- grepl("^```\\{r [^,}]+,.*exercise\\s*=\\s*TRUE", lines)
  qs <- grepl("^\\s*(do\\.call\\()?question_[a-z]+", lines)
  secs$exercises <- vapply(seq_len(nrow(secs)), function(i) sum(ex[secs$start[i]:secs$end[i]]), integer(1))
  secs$questions <- vapply(seq_len(nrow(secs)), function(i) sum(qs[secs$start[i]:secs$end[i]]), integer(1))
  as_tbl(secs[c("id", "type", "title", "exercises", "questions")])
}

#' Open a lab in the browser
#'
#' Runs a lab folder with [learnr::run_tutorial()] so you can try it as a
#' student would. Run [check_material()] first to catch errors quickly.
#'
#' @param lab the lab folder.
#' @param ... passed to [learnr::run_tutorial()].
#' @return Nothing useful; called for its side effect.
#' @export
preview_lab <- function(lab, ...) {
  dir <- tk_lab_dir(lab)
  if (!requireNamespace("learnr", quietly = TRUE))
    stop("Previewing a lab needs the learnr package. Install it with install.packages(\"learnr\").",
         call. = FALSE)
  learnr::run_tutorial(normalizePath(dir), ...)
}

# ---- internal helpers ---------------------------------------------------

tk_default_sections <- function(has_group) {
  c("intro", "classical", "dimensionality", "models", "item-fit", "information", "scoring",
    if (has_group) "dif", "reflection", "wrap-up")
}

tk_check_sections <- function(sections, has_group) {
  bad <- setdiff(sections, lab_section_types()$type)
  if (length(bad))
    stop("Unknown section type(s): ", paste(bad, collapse = ", "), ". Available: ",
         paste(lab_section_types()$type, collapse = ", "), ".", call. = FALSE)
  if ("dif" %in% sections && !has_group)
    stop("The \"dif\" section needs a `group`.", call. = FALSE)
  invisible(TRUE)
}

tk_unique_ids <- function(types) {
  seen <- character()
  lapply(types, function(t) {
    id <- t; k <- 1L
    while (id %in% seen) { k <- k + 1L; id <- paste0(t, "-", k) }
    seen <<- c(seen, id)
    list(type = t, id = id)
  })
}

tk_default_story <- function(data_title) {
  paste0("You have been asked to analyse ", data_title, " with item response theory (IRT). ",
         "The people who own the test want to know whether its items work, which IRT model ",
         "to report scores with, and how precise those scores are. In this lab you will ",
         "work through the analysis step by step and end with a written recommendation.")
}

tk_read_data <- function(data) {
  if (is.character(data) && length(data) == 1L) {
    if (!file.exists(data)) stop("No file ", data, ".", call. = FALSE)
    return(read_any(data, data))
  }
  if (is.matrix(data)) data <- as.data.frame(data)
  if (!is.data.frame(data)) stop("`data` must be a data frame, a matrix or a file path.", call. = FALSE)
  data
}

# list(responses = <scored item data frame>, group = <factor or NULL>, items, group_name, key)
tk_prepare_data <- function(data, items = NULL, group = NULL, key = NULL) {
  df <- tk_read_data(data)
  # a frequency table (one row per response pattern, e.g. mirt's LSAT7):
  # expand it to one row per person
  fcol <- grep("^(freq|frequency|count|counts)$", names(df), ignore.case = TRUE, value = TRUE)
  if (length(fcol) == 1L && !fcol %in% items && is.numeric(df[[fcol]]) &&
      all(df[[fcol]] >= 0 & df[[fcol]] == round(df[[fcol]]), na.rm = TRUE) && !anyNA(df[[fcol]])) {
    reps <- rep(seq_len(nrow(df)), df[[fcol]])
    df <- df[reps, setdiff(names(df), fcol), drop = FALSE]
    if (!is.null(group) && !(is.character(group) && length(group) == 1L)) group <- group[reps]
    rownames(df) <- NULL
  }
  group_name <- NULL
  if (is.character(group) && length(group) == 1L && group %in% names(df)) {
    group_name <- group
    group <- df[[group]]
  } else if (!is.null(group) && length(group) != nrow(df)) {
    stop("`group` must be a column of `data` or have one value per row (", nrow(df), ").",
         call. = FALSE)
  }
  if (is.null(items)) {
    if (!is.null(key) && !is.null(names(key))) items <- names(key)
    else {
      cand <- setdiff(names(df), group_name)
      items <- cand[vapply(cand, function(v) tk_is_item(df[[v]], scored = is.null(key)), logical(1))]
    }
  }
  if (is.numeric(items)) items <- names(df)[items]
  miss <- setdiff(items, names(df))
  if (length(miss)) stop("These items are not columns of `data`: ", paste(miss, collapse = ", "), ".",
                         call. = FALSE)
  if (length(items) < 4L)
    stop("Found ", length(items), " item column(s); a lab needs at least 4. Name them with `items`.",
         call. = FALSE)
  resp <- df[items]
  if (!is.null(key)) {
    if (length(key) != length(items)) stop("`key` needs one value per item (", length(items), ").",
                                            call. = FALSE)
    resp <- as.data.frame(mirt::key2binary(resp, unname(key)))
    names(resp) <- items
  }
  resp[] <- lapply(resp, function(v) {
    if (is.factor(v)) v <- as.character(v)
    out <- suppressWarnings(as.integer(v))
    if (any(is.na(out) & !is.na(v)) || any(out < 0, na.rm = TRUE) || any(out != v, na.rm = TRUE))
      stop("Item responses must be whole numbers of 0 or more; score them first or give a `key`.",
           call. = FALSE)
    out
  })
  keep <- rowSums(!is.na(resp)) > 0
  flat <- vapply(resp, function(v) length(unique(v[!is.na(v)])) < 2L, logical(1))
  if (any(flat)) stop("Every item needs at least two different scores; these have one: ",
                      paste(items[flat], collapse = ", "), ".", call. = FALSE)
  if (!is.null(group)) {
    if (anyNA(group[keep])) stop("`group` has missing values.", call. = FALSE)
    group <- droplevels(factor(group[keep]))
    if (nlevels(group) != 2L) stop("`group` must have exactly two values; it has ", nlevels(group), ".",
                                   call. = FALSE)
  }
  resp <- resp[keep, , drop = FALSE]
  rownames(resp) <- NULL
  if (nrow(resp) < 200L)
    warning("Only ", nrow(resp), " people have responses; IRT estimates will be unstable ",
            "with fewer than about 200.", call. = FALSE)
  list(responses = resp, group = group, items = items,
       group_name = group_name %||% if (!is.null(group)) "group", key = !is.null(key))
}

tk_is_item <- function(v, scored = TRUE) {
  x <- v[!is.na(v)]
  if (!length(x)) return(FALSE)
  if (!scored) return(length(unique(x)) <= 10L)
  if (!is.numeric(x)) return(FALSE)
  all(x == round(x)) && min(x) >= 0 && max(x) <= 9 && length(unique(x)) >= 2L &&
    length(unique(x)) < length(x)
}

tk_write_data <- function(dir, prep, data_title, story, title) {
  ddir <- file.path(dir, "data")
  dir.create(ddir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(list(responses = prep$responses, group = prep$group), file.path(ddir, "responses.rds"))
  info <- list(title = title, data_title = data_title, story = story,
               n = nrow(prep$responses), items = prep$items, group = prep$group_name,
               groups = if (!is.null(prep$group)) levels(prep$group),
               scored_with_key = prep$key, made_with = tk_made_with(),
               updated = format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
  jsonlite::write_json(info[!vapply(info, is.null, logical(1))], file.path(ddir, "lab.json"),
                       auto_unbox = TRUE, pretty = TRUE)
}

tk_lab_dir <- function(lab) {
  check_string(lab, "lab")
  if (grepl("\\.[Rr]md$", lab) && file.exists(lab)) return(dirname(lab))
  if (!dir.exists(lab)) stop("No lab folder ", lab, ".", call. = FALSE)
  lab
}

tk_lab_rmd <- function(dir, must = TRUE) {
  rmds <- list.files(dir, pattern = "\\.[Rr]md$", full.names = TRUE)
  pref <- file.path(dir, paste0(basename(dir), ".Rmd"))
  if (file.exists(pref)) return(pref)
  if (length(rmds) == 1L) return(rmds)
  if (!must) return(NULL)
  stop(if (length(rmds)) "More than one .Rmd file in " else "No .Rmd file in ", dir, ".", call. = FALSE)
}

tk_lab_info <- function(dir) {
  f <- file.path(dir, "data", "lab.json")
  if (!file.exists(f)) return(NULL)
  jsonlite::read_json(f, simplifyVector = TRUE)
}

tk_lines <- function(x) if (is.null(x)) character() else unlist(strsplit(paste(x, collapse = "\n"), "\n", fixed = TRUE))

tk_slug <- function(x) {
  s <- tolower(gsub("[^A-Za-z0-9]+", "-", x))
  s <- gsub("^-+|-+$", "", s)
  s <- substr(s, 1, 30)
  s <- sub("-+$", "", s)
  if (!nzchar(s) || !grepl("^[a-z]", s)) s <- paste0("s-", s)
  s
}

tk_chunk_labels <- function(lines) {
  h <- grep("^```\\{r", lines, value = TRUE)
  trimws(sub(",.*$", "", sub("\\}\\s*$", "", sub("^```\\{r\\s*", "", h))))
}

# a section id not used as a section id or chunk label (prefix) yet
tk_new_id <- function(id, lines) {
  if (!grepl("^[A-Za-z][A-Za-z0-9_-]*$", id))
    stop("Section ids use letters, digits, - and _, starting with a letter.", call. = FALSE)
  used <- c(tk_sections(lines)$id, tk_chunk_labels(lines))
  clash <- function(x) x %in% used || any(startsWith(used, paste0(x, "-")))
  base <- id; k <- 1L
  while (clash(id)) { k <- k + 1L; id <- paste0(base, "-", k) }
  id
}

# sections: level-2 headings outside code chunks, with an optional marker comment before them
tk_sections <- function(lines) {
  fence <- grepl("^```", lines)
  inside <- (cumsum(fence) %% 2 == 1) & !fence
  heads <- which(grepl("^## ", lines) & !inside & !fence)
  marker_re <- "^<!-- mv-section: id=([^ ]+) type=([^ ]+) -->"
  rows <- lapply(heads, function(h) {
    prev <- h - 1L
    while (prev > 0L && !nzchar(trimws(lines[prev]))) prev <- prev - 1L
    m <- if (prev > 0L) regmatches(lines[prev], regexec(marker_re, lines[prev]))[[1]] else character()
    title <- trimws(sub("\\{#[^}]*\\}", "", sub("^## ", "", lines[h])))
    if (length(m)) data.frame(id = m[2], type = m[3], title = title, start = prev, stringsAsFactors = FALSE)
    else data.frame(id = tk_slug(title), type = "built-in", title = title, start = h, stringsAsFactors = FALSE)
  })
  if (!length(rows))
    return(data.frame(id = character(), type = character(), title = character(),
                      start = integer(), end = integer(), stringsAsFactors = FALSE))
  out <- do.call(rbind, rows)
  out$end <- c(out$start[-1] - 1L, length(lines))
  out
}

tk_insert <- function(rmd, lines, block, after) {
  secs <- tk_sections(lines)
  pos <- if (!is.null(after)) {
    i <- match(after, secs$id)
    if (is.na(i)) stop("No section \"", after, "\". Sections: ", paste(secs$id, collapse = ", "), ".",
                       call. = FALSE)
    secs$end[i]
  } else if ("wrap-up" %in% secs$type) {
    secs$start[match("wrap-up", secs$type)] - 1L
  } else length(lines)
  if (pos > 0L && nzchar(trimws(lines[pos]))) block <- c("", block)
  writeLines(enc2utf8(append(lines, block, after = pos)), rmd, useBytes = TRUE)
  invisible(rmd)
}
