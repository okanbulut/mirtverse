#' Notes chapters for a course
#'
#' `copy_chapter()` copies a chapter of the mirtverse online book into the
#' course's `chapters/` folder so you can edit it. `new_chapter()` starts a
#' blank chapter with the same headings as the book's chapters ("Learning
#' goals", "Key terms", "Example 1", "Example 2", "Your turn", "In the lab",
#' "Further reading"). `swap_chapter_data()` replaces the code that loads an
#' example's data.
#'
#' Each example in a book chapter opens with a chunk labelled
#' `data-<chapter>-<n>` that loads its data, and the rest of the example uses
#' what that chunk defines. To use your own data, rewrite that chunk; the
#' easiest way is `swap_chapter_data()`.
#'
#' @param id the chapter's id. For `copy_chapter()`, one of
#'   `book_chapters()$id`; for `new_chapter()`, a new id (letters, digits, -
#'   and _).
#' @param course the course folder.
#' @param from where to copy from: a local copy of the book's source folder
#'   (`book/` in the package's GitHub repository), or `NULL` (the default) to
#'   download the chapter from GitHub.
#' @param overwrite replace an existing file.
#' `copy_chapter()` also copies the book's `_common.R` (packages, chunk
#' options and seed, sourced before each chapter) into `chapters/` the first
#' time, and [check_material()] runs it before a chapter's chunks.
#'
#' @return `copy_chapter()` and `new_chapter()` return the chapter's path,
#'   invisibly. `book_chapters()` returns a tibble with the `id`, `file` and
#'   `title` of each book chapter.
#' @seealso [new_course()], [check_material()]
#' @examples
#' book_chapters()
#' course <- file.path(tempdir(), "chapter-demo")
#' ch <- new_chapter("my-week", course, title = "Our own data",
#'                   data_code = "resp <- expand.table(LSAT7)")
#' swap_chapter_data(ch, code = "resp <- expand.table(LSAT6)")
#' \dontrun{
#' copy_chapter("dif", course)   # downloads from GitHub
#' }
#' @export
copy_chapter <- function(id, course = ".", from = NULL, overwrite = FALSE) {
  chapters <- book_chapters()
  if (!is.character(id) || length(id) != 1L || !id %in% chapters$id)
    stop("Unknown chapter \"", paste(id, collapse = ", "), "\". Chapters: ",
         paste(chapters$id, collapse = ", "), ".", call. = FALSE)
  file <- chapters$file[chapters$id == id]
  dest <- file.path(course, "chapters", file)
  if (file.exists(dest) && !overwrite)
    stop(dest, " already exists. Use overwrite = TRUE to replace it.", call. = FALSE)
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  fetch <- function(f) {
    if (is.null(from)) {
      url <- paste0(tk_book_url, f)
      tryCatch(readLines(url, warn = FALSE, encoding = "UTF-8"),
               error = function(e) stop("Could not download ", url, ": ", conditionMessage(e),
                                        ". Pass `from` = a local copy of the book folder.", call. = FALSE))
    } else {
      src <- file.path(from, f)
      if (!file.exists(src)) stop("No ", f, " in ", from, ".", call. = FALSE)
      readLines(src, warn = FALSE, encoding = "UTF-8")
    }
  }
  lines <- fetch(file)
  # the book sources _common.R (packages, chunk options, seed) before each chapter
  common <- file.path(course, "chapters", "_common.R")
  if (!file.exists(common)) {
    cl <- tryCatch(fetch("_common.R"), error = function(e) NULL)
    if (!is.null(cl)) writeLines(cl, common, useBytes = TRUE)
  }
  stamp <- sprintf("<!-- mirtverse-book-chapter: %s, copied %s with %s -->", id, format(Sys.Date()),
                   tk_made_with())
  writeLines(c(stamp, lines), dest, useBytes = TRUE)
  invisible(dest)
}

#' @rdname copy_chapter
#' @param title the chapter title.
#' @param data_code R code that loads the examples' data. It should define
#'   `resp`, a data frame of scored item responses. Defaults to the LSAT7
#'   data from mirt.
#' @export
new_chapter <- function(id, course = ".", title = NULL, data_code = NULL, overwrite = FALSE) {
  tk_check_name(id)
  dest <- file.path(course, "chapters", paste0(id, ".Rmd"))
  if (file.exists(dest) && !overwrite)
    stop(dest, " already exists. Use overwrite = TRUE to replace it.", call. = FALSE)
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  lines <- tk_fill(tk_template("chapter.Rmd"), list(
    id = id, title = title %||% id, made_with = tk_made_with(),
    data_code = paste(tk_lines(data_code %||% "resp <- expand.table(LSAT7)"), collapse = "\n")))
  writeLines(unlist(strsplit(lines, "\n", fixed = TRUE)), dest)
  invisible(dest)
}

#' @rdname copy_chapter
#' @param chapter the chapter's `.Rmd` file.
#' @param chunk the label of the data chunk to replace, for example
#'   `"data-dif-1"`. `NULL` (the default) replaces every `data-` chunk.
#' @param code the new R code for the chunk(s).
#' @export
swap_chapter_data <- function(chapter, chunk = NULL, code) {
  check_string(chapter, "chapter")
  if (!file.exists(chapter)) stop("No file ", chapter, ".", call. = FALSE)
  if (missing(code) || !is.character(code) || !length(code))
    stop("Give the new data code in `code`.", call. = FALSE)
  lines <- readLines(chapter, warn = FALSE, encoding = "UTF-8")
  chunks <- tk_parse_chunks(lines)
  labels <- vapply(chunks, `[[`, "", "label")
  targets <- if (is.null(chunk)) which(startsWith(labels, "data-")) else match(chunk, labels)
  if (!length(targets) || anyNA(targets))
    stop("No ", if (is.null(chunk)) "data- chunks" else paste0("chunk \"", chunk, "\""), " in ",
         chapter, ". Data chunks: ", paste(labels[startsWith(labels, "data-")], collapse = ", "), ".",
         call. = FALSE)
  # replace from the last chunk so earlier line numbers stay valid
  for (i in rev(targets)) {
    ch <- chunks[[i]]
    body <- if (ch$end > ch$start + 1L) (ch$start + 1L):(ch$end - 1L) else integer()
    lines <- append(if (length(body)) lines[-body] else lines, tk_lines(code), after = ch$start)
  }
  writeLines(lines, chapter, useBytes = TRUE)
  invisible(chapter)
}

#' @rdname copy_chapter
#' @export
book_chapters <- function() {
  as_tbl(data.frame(
    id = c("measurement", "irt-models", "estimation", "dimensionality", "fit", "information",
           "scoring", "polytomous", "dif", "linking", "banks-cat", "reporting", "ml-lens", "auto-scoring", "llms",
           "datasets", "adapting"),
    file = c("01-measurement.Rmd", "02-irt-models.Rmd", "03-estimation.Rmd",
             "04-dimensionality.Rmd", "05-fit.Rmd", "06-information.Rmd", "07-scoring.Rmd",
             "08-polytomous.Rmd", "09-dif.Rmd", "10-linking.Rmd", "11-banks-cat.Rmd",
             "12-reporting.Rmd", "13-ml-lens.Rmd", "16-auto-scoring.Rmd", "17-llms.Rmd", "90-datasets.Rmd",
             "91-adapting.Rmd"),
    title = c("Measurement, scoring and classical item analysis",
              "From classical test theory to IRT", "Estimation and comparing models",
              "Dimensionality and local independence", "Item fit, person fit and item quality",
              "Information, precision and reliability", "Scoring people",
              "Polytomous items and open-ended responses",
              "Differential item functioning and fairness", "Linking and equating",
              "Item banks, test assembly and adaptive testing",
              "Cut scores, reporting and communicating results",
              "Machine learning through an IRT lens", "Automated scoring",
              "Large language models as a colleague",
              "Appendix: the datasets", "Appendix: adapting the book"),
    stringsAsFactors = FALSE))
}

tk_book_url <- "https://raw.githubusercontent.com/okanbulut/mirtverse/main/book/"

# code chunks of an R Markdown file: label, options (text and parsed), code, start/end lines
tk_parse_chunks <- function(lines) {
  starts <- grep("^```\\{r", lines)
  ends <- grep("^```\\s*$", lines)
  out <- list(); k <- 0L
  # `r ''` after a chunk header shows the chunk verbatim; knitr does not run it
  starts <- starts[!grepl("`r ''`", lines[starts], fixed = TRUE)]
  for (s in starts) {
    e <- ends[ends > s][1]
    if (is.na(e)) break
    header <- sub("\\}\\s*$", "", sub("^```\\{r\\s*,?\\s*", "", lines[s]))
    first <- trimws(sub(",.*$", "", header))
    if (!nzchar(first) || grepl("=", first)) {
      k <- k + 1L; label <- paste0("unnamed-chunk-", k); opts_text <- header
    } else {
      label <- first
      opts_text <- if (grepl(",", header)) sub("^[^,]*,", "", header) else ""
    }
    opts <- tryCatch(eval(parse(text = paste0("list(", opts_text, ")")), envir = baseenv()),
                     error = function(e) list())
    out[[length(out) + 1L]] <- list(label = label, opts_text = opts_text, opts = opts,
                                    code = if (e > s + 1L) lines[(s + 1L):(e - 1L)] else character(),
                                    start = s, end = e)
  }
  out
}
