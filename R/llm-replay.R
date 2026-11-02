#' Replay or record language model responses
#'
#' `mv_llm_replay()` makes every mirtverse function that calls a language
#' model ([mv_ask()], [generate_items()], [verify_items()], [score_open()]
#' and [review_packet()] with `ai_screen = TRUE`) answer from a file of
#' recorded responses instead of a live model. Nothing is sent anywhere, no
#' API key is needed, and the same request always gets the same answer, so
#' examples, labs and lessons run offline and give the same results for
#' every student.
#'
#' `mv_llm_record()` does the opposite: while it is on, every request sent to
#' a live model and the model's answer are saved to a file, which
#' `mv_llm_replay()` can play back later. Use it to capture a session once
#' and teach from it many times.
#'
#' A recording answers only the exact requests it was made from: the same
#' instructions to the model and the same prompt, which follow from the same
#' function call on the same data. A request that is not in the file stops
#' with an error that says so; run it with a live model, or record it.
#'
#' mirtverse comes with a small example file used in the AI Hub articles and
#' the online book. Its responses were written by the package authors to show
#' what a model returns, including a few deliberate mistakes for the checks
#' to catch; they were not produced by a live model. The calls they answer
#' are in `system.file("replay", "examples.R", package = "mirtverse")`.
#'
#' @param file path to a recording (a `.json` file). For `mv_llm_replay()`
#'   the default is the example file that comes with mirtverse; `FALSE`
#'   turns replay off. For `mv_llm_record()`, `NULL` stops recording.
#' @param append logical; add to an existing recording rather than start a
#'   new one.
#' @return `mv_llm_replay()` returns the previous settings invisibly, so you
#'   can restore them with [options()]. `mv_llm_record()` returns the file
#'   path invisibly. `mv_llm_recordings()` returns a data frame with one row
#'   per recorded request.
#' @seealso [mv_ask_setup()] to use a live model.
#' @examples
#' # answer from the example recordings that come with mirtverse
#' old <- mv_llm_replay()
#' head(mv_llm_recordings()[, c("function_name", "prompt_start")])
#' options(old)
#'
#' \dontrun{
#' # record a live session, then replay it offline
#' mv_ask_setup("claude")
#' mv_llm_record("my-session.json")
#' p <- generate_items(p, n = 10)
#' mv_llm_record(NULL)
#' mv_llm_replay("my-session.json")
#' p2 <- generate_items(p0, n = 10)   # same items, no model called
#' }
#' @export
mv_llm_replay <- function(file = NULL) {
  old <- options(mirtverse.provider = getOption("mirtverse.provider"),
                 mirtverse.replay = getOption("mirtverse.replay"))
  if (isFALSE(file)) {
    if (identical(getOption("mirtverse.provider"), "replay"))
      options(mirtverse.provider = NULL)
    options(mirtverse.replay = NULL)
    return(invisible(old))
  }
  file <- file %||% replay_example_file()
  if (!file.exists(file)) stop(sprintf("No recording at %s.", file), call. = FALSE)
  if (!requireNamespace("ellmer", quietly = TRUE))
    stop("Install the ellmer package to use recorded responses: install.packages(\"ellmer\").",
         call. = FALSE)
  replay_cache$file <- NULL
  options(mirtverse.provider = "replay", mirtverse.replay = normalizePath(file))
  message(sprintf("Language model calls now answer from %s (%d recorded requests).",
                  basename(file), length(replay_read(file)$recordings)))
  invisible(old)
}

#' @rdname mv_llm_replay
#' @export
mv_llm_record <- function(file, append = TRUE) {
  if (is.null(file)) {
    f <- getOption("mirtverse.record")
    options(mirtverse.record = NULL)
    if (!is.null(f)) message(sprintf("Stopped recording to %s.", f))
    return(invisible(f))
  }
  if (!append || !file.exists(file))
    replay_write(list(version = 1L, source = "Recorded with mirtverse::mv_llm_record().",
                      recordings = list()), file)
  file <- normalizePath(file)
  options(mirtverse.record = file)
  message(sprintf("Recording language model requests and responses to %s.", file))
  invisible(file)
}

#' @rdname mv_llm_replay
#' @export
mv_llm_recordings <- function(file = NULL) {
  file <- file %||% getOption("mirtverse.replay") %||% replay_example_file()
  recs <- replay_read(file)$recordings
  if (!length(recs))
    return(as_tbl(data.frame(function_name = character(), prompt_start = character(),
                             structured = logical(), provider = character(), model = character(),
                             key = character())))
  one <- function(r, nm) as.character(r[[nm]] %||% NA)
  as_tbl(data.frame(
    function_name = vapply(recs, one, "", nm = "function_name"),
    prompt_start = vapply(recs, function(r) substr(gsub("\\s+", " ", r$prompt), 1, 60), ""),
    structured = vapply(recs, function(r) isTRUE(r$structured), NA),
    provider = vapply(recs, one, "", nm = "provider"),
    model = vapply(recs, one, "", nm = "model"),
    key = vapply(recs, one, "", nm = "key"),
    stringsAsFactors = FALSE))
}

# ---- Internals ----------------------------------------------------------------

replay_example_file <- function() {
  f <- system.file("replay", "examples.json", package = "mirtverse")
  if (!nzchar(f)) stop("The example recordings are missing from this installation.", call. = FALSE)
  f
}

replay_cache <- new.env(parent = emptyenv())

replay_key <- function(system_prompt, prompt, structured) {
  txt <- paste(if (structured) "structured" else "text", system_prompt %||% "", prompt,
               sep = "\n<<mirtverse>>\n")
  f <- tempfile()
  on.exit(unlink(f))
  writeBin(charToRaw(enc2utf8(txt)), f)
  unname(tools::md5sum(f))
}

replay_read <- function(file) {
  if (identical(replay_cache$file, file) &&
      identical(replay_cache$mtime, file.mtime(file))) return(replay_cache$data)
  data <- jsonlite::fromJSON(file, simplifyVector = FALSE)
  replay_cache$file <- file
  replay_cache$mtime <- file.mtime(file)
  replay_cache$data <- data
  data
}

replay_write <- function(data, file) {
  writeLines(jsonlite::toJSON(data, auto_unbox = TRUE, pretty = TRUE, null = "null",
                              na = "null", digits = NA, dataframe = "rows"),
             file, useBytes = TRUE)
  replay_cache$file <- NULL
  invisible(file)
}

# a response as ellmer returns it: arrays of objects become data frames
replay_response <- function(x, structured) {
  if (!structured) return(as.character(x))
  jsonlite::fromJSON(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", digits = NA),
                     simplifyVector = TRUE)
}

# which exported function made the request, for the recording's index
replay_caller <- function() {
  calls <- sys.calls()
  fns <- vapply(calls, function(cl) {
    f <- cl[[1]]
    if (is.call(f) && identical(f[[1]], as.name("::"))) f <- f[[3]]
    if (is.name(f)) as.character(f) else ""
  }, "")
  hit <- fns[fns %in% c("mv_ask", "generate_items", "verify_items", "score_open",
                        "review_packet")]
  if (length(hit)) hit[length(hit)] else NA_character_
}

replay_chat <- function(system_prompt) {
  file <- getOption("mirtverse.replay") %||% replay_example_file()
  answer <- function(prompt, structured) {
    key <- replay_key(system_prompt, prompt, structured)
    recs <- replay_read(file)$recordings
    hit <- Find(function(r) identical(r$key, key), recs)
    if (is.null(hit))
      stop(paste0("This request is not in the recording ", basename(file), ". ",
                  "A recording answers only the exact calls it was made from. ",
                  "Use a live model (mv_llm_replay(FALSE), then mv_ask_setup()), ",
                  "or record the call with mv_llm_record()."), call. = FALSE)
    replay_response(hit$response, structured)
  }
  list(chat = function(prompt, ..., echo = "none") answer(prompt, FALSE),
       chat_structured = function(prompt, ..., type = NULL, echo = "none") answer(prompt, TRUE))
}

record_chat <- function(chat, provider, model, system_prompt, file) {
  force(chat)
  save <- function(prompt, structured, response) {
    data <- if (file.exists(file)) replay_read(file) else
      list(version = 1L, source = "Recorded with mirtverse::mv_llm_record().", recordings = list())
    key <- replay_key(system_prompt, prompt, structured)
    keep <- !vapply(data$recordings, function(r) identical(r$key, key), NA)
    data$recordings <- c(data$recordings[keep], list(list(
      key = key, function_name = replay_caller(), provider = provider, model = model %||% "",
      recorded = format(Sys.time(), "%Y-%m-%d"), structured = structured,
      system = system_prompt %||% "", prompt = prompt, response = response)))
    replay_write(data, file)
  }
  list(chat = function(prompt, ..., echo = "none") {
         res <- chat$chat(prompt, ..., echo = echo)
         save(prompt, FALSE, as.character(res))
         res
       },
       chat_structured = function(prompt, ..., type = NULL, echo = "none") {
         res <- chat$chat_structured(prompt, ..., type = type, echo = echo)
         save(prompt, TRUE, res)
         res
       })
}
