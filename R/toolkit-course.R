#' Start a course folder for the instructor toolkit
#'
#' The instructor toolkit keeps a course's teaching materials in one folder
#' that you can edit, extend and re-run with your own data. `new_course()`
#' creates the folder:
#'
#' * `course.json`: the course title and instructor.
#' * `README.md`: a short how-to for whoever opens the folder next.
#' * `labs/`: interactive labs (learnr tutorials), one folder each, made with
#'   [new_lab()] or [copy_lab()].
#' * `chapters/`: notes chapters (R Markdown), made with [new_chapter()] or
#'   [copy_chapter()].
#' * `data/`: your raw data files, for reference.
#'
#' `course_materials()` lists the labs and chapters in a course folder. It
#' scans `labs/` and `chapters/`, so materials you add by hand are listed too.
#'
#' All toolkit functions take paths, never ask questions, and return the path
#' they wrote (invisibly) or a tibble, so they can be scripted.
#'
#' @param path the folder to create. It may exist already, but must not
#'   already hold a `course.json` unless `overwrite = TRUE`.
#' @param title course title. Defaults to the folder name.
#' @param instructor instructor name(s), optional.
#' @param overwrite replace an existing `course.json` and `README.md`.
#' @param course the course folder.
#' @return `new_course()` returns the course path, invisibly.
#'   `course_materials()` returns a tibble with one row per material: `name`,
#'   `type` (`"lab"` or `"chapter"`), `title`, `path`, `source` (`"toolkit"`
#'   for labs built with [new_lab()], `"built-in"` for copies of the package's
#'   labs, `"book"` for chapters copied from the mirtverse book, `"own"`
#'   otherwise) and `data` (the data a toolkit lab uses).
#' @seealso [new_lab()], [copy_lab()], [copy_chapter()], [check_material()]
#' @examples
#' course <- file.path(tempdir(), "irt-course")
#' new_course(course, title = "EDPY 507: Item response theory")
#' copy_lab("model-choice", course)
#' course_materials(course)
#' @export
new_course <- function(path, title = NULL, instructor = NULL, overwrite = FALSE) {
  check_string(path, "path")
  manifest <- file.path(path, "course.json")
  if (file.exists(manifest) && !overwrite)
    stop("A course already exists in ", path, ". Use overwrite = TRUE to replace its course.json.",
         call. = FALSE)
  for (d in c("", "labs", "chapters", "data"))
    dir.create(file.path(path, d), recursive = TRUE, showWarnings = FALSE)
  title <- title %||% basename(normalizePath(path))
  info <- list(title = title, instructor = instructor %||% "",
               created = format(Sys.Date()), made_with = tk_made_with(), toolkit = 1L)
  jsonlite::write_json(info, manifest, auto_unbox = TRUE, pretty = TRUE)
  readme <- tk_fill(tk_template("course-README.md"), list(
    title = title, made_with = tk_made_with(),
    instructor_line = if (is.null(instructor) || !nzchar(instructor)) "" else
      paste0("Instructor: ", instructor, ".\n\n")))
  writeLines(readme, file.path(path, "README.md"))
  invisible(path)
}

#' @rdname new_course
#' @export
course_materials <- function(course = ".") {
  check_string(course, "course")
  if (!dir.exists(course)) stop("No folder ", course, ".", call. = FALSE)
  labs <- list.dirs(file.path(course, "labs"), recursive = FALSE)
  lab_rows <- lapply(labs, function(dir) {
    rmd <- tk_lab_rmd(dir, must = FALSE)
    if (is.null(rmd)) return(NULL)
    meta <- lab_meta(rmd)
    info <- tk_lab_info(dir)
    src <- if (!is.null(info)) "toolkit" else if (file.exists(file.path(dir, ".mirtverse-lab")))
      "built-in" else "own"
    data.frame(name = basename(dir), type = "lab", title = meta$title %||% basename(dir),
               path = dir, source = src, data = if (is.null(info)) NA_character_ else
                 info$data_title %||% NA_character_, stringsAsFactors = FALSE)
  })
  chapters <- list.files(file.path(course, "chapters"), pattern = "\\.[Rr]md$", full.names = TRUE)
  ch_rows <- lapply(chapters, function(f) {
    lines <- readLines(f, warn = FALSE)
    data.frame(name = tools::file_path_sans_ext(basename(f)), type = "chapter",
               title = tk_chapter_title(lines) %||% basename(f), path = f,
               source = if (any(grepl("mirtverse-book-chapter", lines, fixed = TRUE))) "book" else
                 if (any(grepl("mirtverse instructor toolkit", lines, fixed = TRUE))) "toolkit" else "own",
               data = NA_character_, stringsAsFactors = FALSE)
  })
  rows <- c(lab_rows, ch_rows)
  rows <- rows[!vapply(rows, is.null, logical(1))]
  out <- if (length(rows)) do.call(rbind, rows) else
    data.frame(name = character(), type = character(), title = character(), path = character(),
               source = character(), data = character(), stringsAsFactors = FALSE)
  as_tbl(out)
}

#' Copy a built-in lab into a course to edit it
#'
#' Copies one of the package's teaching labs (see [list_labs()]) into the
#' course's `labs/` folder. The copy is yours: change the story, cut
#' sections, add exercises with [add_lab_exercise()] or questions with
#' [add_lab_question()], then run [check_material()] and [preview_lab()].
#'
#' The built-in labs' feedback is written for their own datasets (each has
#' problems planted on purpose), so to teach with your own data, start from
#' [new_lab()] instead: its text and answer checks adapt to any dataset.
#'
#' @param name the built-in lab, e.g. `"model-choice"`.
#' @param course the course folder (it need not have a `course.json`).
#' @param as the name of the copy. Defaults to `name`.
#' @param overwrite replace an existing copy.
#' @return The path of the copied lab folder, invisibly.
#' @seealso [new_course()], [new_lab()]
#' @examples
#' course <- file.path(tempdir(), "copy-demo")
#' lab <- copy_lab("fairness", course, as = "week9-fairness")
#' lab_outline(lab)
#' @export
copy_lab <- function(name, course = ".", as = name, overwrite = FALSE) {
  labs <- list_labs()
  if (!is.character(name) || length(name) != 1L || !name %in% labs$name)
    stop("Unknown lab \"", paste(name, collapse = ", "), "\". Available labs: ",
         paste(labs$name, collapse = ", "), ".", call. = FALSE)
  tk_check_name(as)
  src <- system.file("tutorials", name, package = "mirtverse")
  dest <- file.path(course, "labs", as)
  tk_prepare_dest(dest, overwrite)
  files <- list.files(src, recursive = TRUE, all.files = FALSE)
  files <- files[!grepl("\\.html$|_files/|\\.rds$", files)]
  for (f in files) {
    to <- file.path(dest, if (f == paste0(name, ".Rmd")) paste0(as, ".Rmd") else f)
    dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
    file.copy(file.path(src, f), to, overwrite = TRUE)
  }
  writeLines(c(paste("Copied from the mirtverse lab", name), tk_made_with()),
             file.path(dest, ".mirtverse-lab"))
  invisible(dest)
}

# ---- internal helpers ---------------------------------------------------

tk_made_with <- function() paste0("mirtverse ", utils::packageVersion("mirtverse"))

tk_template <- function(file) {
  path <- system.file("toolkit", file, package = "mirtverse")
  if (!nzchar(path)) stop("Toolkit template ", file, " is missing.", call. = FALSE)
  readLines(path, warn = FALSE)
}

# replace {{key}} placeholders
tk_fill <- function(lines, values) {
  for (k in names(values))
    lines <- gsub(paste0("{{", k, "}}"), values[[k]], lines, fixed = TRUE)
  lines
}

check_string <- function(x, arg) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x))
    stop("`", arg, "` must be a single non-empty string.", call. = FALSE)
  invisible(TRUE)
}

tk_check_name <- function(name) {
  check_string(name, "name")
  if (!grepl("^[A-Za-z][A-Za-z0-9_-]*$", name))
    stop("Use letters, digits, - and _ in a material name (starting with a letter), not \"",
         name, "\".", call. = FALSE)
  invisible(TRUE)
}

tk_prepare_dest <- function(dest, overwrite) {
  if (dir.exists(dest) && length(list.files(dest))) {
    if (!overwrite) stop(dest, " already exists. Use overwrite = TRUE to replace it.", call. = FALSE)
    unlink(dest, recursive = TRUE)
  }
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
}

tk_chapter_title <- function(lines) {
  h <- grep("^# ", lines, value = TRUE)
  if (!length(h)) return(NULL)
  trimws(sub("\\{#[^}]*\\}", "", sub("^# ", "", h[1])))
}
