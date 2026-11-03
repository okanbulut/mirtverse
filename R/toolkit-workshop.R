#' Copy the AI in measurement workshop kit
#'
#' Copies the kit for a one-day workshop on AI in measurement into a folder
#' you can edit: The slides (`slides.Rmd`, an ioslides presentation), a
#' facilitator's guide (`facilitator-guide.Rmd`) and a `README.md`. The day
#' uses Labs 7 to 10 ([run_lab()]) and runs offline. Render the slides and
#' the guide with [rmarkdown::render()].
#'
#' @param dest the folder to copy the kit into. Inside a course folder made
#'   with [new_course()], use `file.path(course, "workshop")`.
#' @param overwrite replace files that already exist in `dest`.
#' @return The path of the folder, invisibly.
#' @seealso The course map's AI module and workshop schedule, and the
#'   [workshop article](https://www.okanbulut.com/mirtverse/articles/ai-workshop.html).
#' @examples
#' kit <- copy_workshop(file.path(tempdir(), "ai-workshop"))
#' list.files(kit)
#' @export
copy_workshop <- function(dest = "ai-workshop", overwrite = FALSE) {
  check_string(dest, "dest")
  src <- system.file("workshop", "ai-in-measurement", package = "mirtverse")
  if (!nzchar(src)) stop("The workshop kit is missing from this installation.", call. = FALSE)
  files <- list.files(src)
  there <- file.exists(file.path(dest, files))
  if (any(there) && !overwrite)
    stop(dest, " already has ", paste(files[there], collapse = ", "),
         ". Use overwrite = TRUE to replace them.", call. = FALSE)
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  file.copy(file.path(src, files), dest, overwrite = TRUE)
  invisible(dest)
}
