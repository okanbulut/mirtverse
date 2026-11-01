#' Check a lab, a chapter or a whole course
#'
#' Runs a teaching material the way students will meet it and reports what
#' works. Run it after every edit, and after [swap_lab_data()].
#'
#' For a **lab** (a folder with a learnr `.Rmd`), it checks that chunk labels
#' are unique and that every `-solution`, `-hint` and `-check` chunk belongs
#' to an exercise; runs the setup chunk and every chunk that runs when the lab
#' is rendered (including the multiple-choice questions); and runs each
#' exercise's solution (or its starting code, when there is no solution)
#' followed by its `-check` chunk through [lab_checker()], so a solution that
#' its own check rejects is reported. For a **chapter** (an `.Rmd` file), it
#' runs every chunk in order. For a **course** folder (with `course.json`),
#' it checks every material in [course_materials()].
#'
#' Everything runs in a temporary copy, so nothing in your folder changes.
#'
#' @param path a lab folder, a chapter `.Rmd` file or a course folder.
#' @param render also render the material with [rmarkdown::render()], which
#'   catches problems in the Markdown and YAML as well as the code. Slower.
#' @param quiet suppress the progress messages.
#' @return A tibble with one row per check: `material`, `check`
#'   (`"structure"`, `"data"`, `"chunk"`, `"exercise"` or `"render"`),
#'   `label`, `status` (`"pass"`, `"fail"` or `"skip"`) and `message`.
#'   `all(result$status != "fail")` is `TRUE` when the material is ready.
#' @seealso [new_lab()], [preview_lab()]
#' @examples
#' \donttest{
#' course <- file.path(tempdir(), "check-demo")
#' lab <- new_lab("demo", data = expand.table(LSAT7), course = course,
#'                sections = c("intro", "classical"))
#' check_material(lab)
#' }
#' @export
check_material <- function(path, render = FALSE, quiet = TRUE) {
  check_string(path, "path")
  if (dir.exists(path) && file.exists(file.path(path, "course.json"))) {
    mats <- course_materials(path)
    res <- lapply(mats$path, check_material, render = render, quiet = quiet)
    return(if (length(res)) as_tbl(do.call(rbind, res)) else tk_result())
  }
  if (dir.exists(path)) return(tk_check_lab(path, render, quiet))
  if (file.exists(path) && grepl("\\.[Rr]md$", path)) {
    if (file.exists(file.path(dirname(path), "data", "lab.json")) ||
        any(grepl("learnr::tutorial", readLines(path, n = 30L, warn = FALSE), fixed = TRUE)))
      return(tk_check_lab(dirname(path), render, quiet))
    return(tk_check_chapter(path, render, quiet))
  }
  stop("No lab folder, chapter or course at ", path, ".", call. = FALSE)
}

tk_result <- function(material = character(), check = character(), label = character(),
                      status = character(), message = character()) {
  data.frame(material = material, check = check, label = label, status = status,
             message = message, stringsAsFactors = FALSE)
}

tk_check_lab <- function(dir, render, quiet) {
  if (!requireNamespace("learnr", quietly = TRUE))
    stop("Checking a lab needs the learnr package. Install it with install.packages(\"learnr\").",
         call. = FALSE)
  rmd <- tk_lab_rmd(dir)
  name <- basename(dir)
  rows <- list()
  add <- function(check, label, status, message = "")
    rows[[length(rows) + 1L]] <<- tk_result(name, check, label, status, message)
  say <- function(...) if (!quiet) message(...)

  # work in a temporary copy so the instructor's folder is untouched
  tmp <- file.path(tempfile("mv-check-"), name)
  dir.create(tmp, recursive = TRUE)
  file.copy(list.files(dir, full.names = TRUE, all.files = FALSE), tmp, recursive = TRUE)
  old_wd <- setwd(tmp)
  on.exit(setwd(old_wd), add = TRUE)

  lines <- readLines(basename(rmd), warn = FALSE, encoding = "UTF-8")
  chunks <- tk_parse_chunks(lines)
  labels <- vapply(chunks, `[[`, "", "label")
  names(chunks) <- labels

  # structure
  dup <- unique(labels[duplicated(labels)])
  add("structure", "labels", if (length(dup)) "fail" else "pass",
      if (length(dup)) paste("Duplicated chunk labels:", paste(dup, collapse = ", ")) else
        paste(length(labels), "chunks, all labels unique."))
  is_ex <- vapply(chunks, function(ch) isTRUE(ch$opts$exercise), logical(1))
  support <- grepl("-(solution|hint|hint-[0-9]+|check|code-check|error-check|setup)$", labels)
  orphans <- labels[support & !sub("-(solution|hint|hint-[0-9]+|check|code-check|error-check|setup)$", "",
                                   labels) %in% labels[is_ex]]
  if (length(orphans))
    add("structure", "orphans", "fail",
        paste("These chunks have no matching exercise:", paste(orphans, collapse = ", ")))
  if (!"setup" %in% labels) add("structure", "setup", "fail", "The lab has no `setup` chunk.")
  if (file.exists(file.path("data", "lab.json"))) {
    d <- tryCatch(lab_data("data"), error = function(e) e)
    if (inherits(d, "error")) add("data", "data", "fail", conditionMessage(d))
    else add("data", "data", "pass", sprintf("%d people, %d items%s.", nrow(d$responses),
                                             ncol(d$responses),
                                             if (is.null(d$group)) "" else ", with a group"))
  }

  # the render pass: setup, then every chunk knitr would run, in order
  render_env <- new.env(parent = globalenv())
  setup_code <- if ("setup" %in% labels) chunks$setup$code else character()
  for (ch in chunks) {
    skip <- is_ex[[ch$label]] || ch$label %in% labels[support] ||
      identical(ch$opts$context, "server") || identical(ch$opts$eval, FALSE) ||
      (!identical(ch$label, "setup") && startsWith(ch$label, "setup"))
    if (skip) next
    say("chunk ", ch$label)
    err <- tk_eval(ch$code, render_env)
    if (identical(ch$label, "setup") || !is.null(err))
      add("chunk", ch$label, if (is.null(err)) "pass" else "fail", err %||% "Runs.")
    if (identical(ch$label, "setup") && !is.null(err)) break
  }
  if (!any(vapply(rows, function(r) r$check == "chunk" && r$label != "setup", logical(1))) &&
      !any(vapply(rows, function(r) r$status == "fail", logical(1))))
    add("chunk", "all", "pass", "Every chunk that runs at render time runs.")

  # exercises: global setup + exercise.setup + solution, then the check
  for (lab in labels[is_ex]) {
    ch <- chunks[[lab]]
    sol <- chunks[[paste0(lab, "-solution")]]$code
    code <- sol %||% ch$code
    chk <- chunks[[paste0(lab, "-check")]]$code
    if (is.null(sol) && inherits(try(parse(text = code), silent = TRUE), "try-error")) {
      add("exercise", lab, "skip", "Has no -solution chunk and its starting code is incomplete.")
      next
    }
    say("exercise ", lab)
    env <- new.env(parent = globalenv())
    err <- tk_eval(setup_code, env)
    pre <- c(ch$opts$exercise.setup, if (paste0(lab, "-setup") %in% labels) paste0(lab, "-setup"))
    for (p in pre) if (is.null(err)) {
      err <- if (p %in% labels) tk_eval(chunks[[p]]$code, env) else
        paste0("Its exercise.setup chunk \"", p, "\" does not exist.")
    }
    value <- NULL
    if (is.null(err)) {
      out <- tryCatch(withVisible_eval(code, env), error = function(e) e)
      if (inherits(out, "error")) err <- paste("The solution fails:", conditionMessage(out))
      else value <- out
    }
    if (!is.null(err)) { add("exercise", lab, "fail", err); next }
    if (is.null(chk)) { add("exercise", lab, "pass", "The solution runs (no -check chunk)."); next }
    res <- lab_checker(label = lab, check_code = paste(chk, collapse = "\n"), envir_result = env,
                       last_value = value, stage = "check")
    add("exercise", lab, if (isTRUE(res$correct)) "pass" else "fail",
        if (isTRUE(res$correct)) res$message else paste("The check rejects the solution:", res$message))
  }

  if (render) {
    say("render")
    err <- tryCatch({
      suppressMessages(rmarkdown::render(basename(rmd), quiet = TRUE, envir = new.env()))
      NULL
    }, error = function(e) conditionMessage(e))
    add("render", basename(rmd), if (is.null(err)) "pass" else "fail", err %||% "Renders.")
  }
  as_tbl(do.call(rbind, rows))
}

tk_check_chapter <- function(path, render, quiet) {
  name <- tools::file_path_sans_ext(basename(path))
  # keep the chapter's place next to the course's data/ folder, so paths such
  # as "../data/file.csv" work in the copy too
  root <- tempfile("mv-check-")
  tmp <- file.path(root, basename(dirname(normalizePath(path))))
  dir.create(tmp, recursive = TRUE)
  file.copy(path, tmp)
  common <- file.path(dirname(path), "_common.R")
  if (file.exists(common)) file.copy(common, tmp)
  for (d in c(file.path(dirname(path), "data"), file.path(dirname(dirname(path)), "data")))
    if (dir.exists(d)) file.copy(d, if (d == file.path(dirname(path), "data")) tmp else root,
                                 recursive = TRUE)
  old_wd <- setwd(tmp)
  on.exit(setwd(old_wd), add = TRUE)
  lines <- readLines(basename(path), warn = FALSE, encoding = "UTF-8")
  chunks <- tk_parse_chunks(lines)
  env <- new.env(parent = globalenv())
  rows <- list()
  if (file.exists("_common.R")) {
    err <- tk_eval(readLines("_common.R", warn = FALSE), env)
    rows[[1]] <- tk_result(name, "chunk", "_common.R", if (is.null(err)) "pass" else "fail",
                           err %||% "Runs.")
  }
  for (ch in chunks) {
    if (identical(ch$opts$eval, FALSE)) next
    if (!quiet) message("chunk ", ch$label)
    err <- tk_eval(ch$code, env)
    rows[[length(rows) + 1L]] <- tk_result(name, "chunk", ch$label,
                                           if (is.null(err)) "pass" else "fail", err %||% "Runs.")
  }
  if (!length(chunks)) rows[[1]] <- tk_result(name, "chunk", "", "skip", "No R chunks.")
  if (render) {
    err <- tryCatch({
      suppressMessages(rmarkdown::render(basename(path), output_format = "html_document",
                                         quiet = TRUE, envir = new.env()))
      NULL
    }, error = function(e) conditionMessage(e))
    rows[[length(rows) + 1L]] <- tk_result(name, "render", basename(path),
                                           if (is.null(err)) "pass" else "fail", err %||% "Renders.")
  }
  as_tbl(do.call(rbind, rows))
}

# evaluate code lines; NULL on success, the error message otherwise
tk_eval <- function(code, env) {
  tryCatch({
    withVisible_eval(code, env)
    NULL
  }, error = function(e) conditionMessage(e))
}

# value of the last expression, with printed output, messages and warnings silenced
withVisible_eval <- function(code, env) {
  value <- NULL
  utils::capture.output(value <- suppressWarnings(suppressMessages(
    eval(parse(text = code), envir = env))))
  value
}
