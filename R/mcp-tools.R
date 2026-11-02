# Tools, prompts and resources of the instructor MCP server (see mcp-server.R)

# ---------------------------------------------------------------------------
# Tool registry

mcp_tool <- function(name, description, properties = list(), required = character(),
                     handler, needs = NULL, title = NULL, read_only = FALSE) {
  schema <- list(type = "object",
                 properties = if (length(properties)) properties else
                   structure(list(), names = character()))
  if (length(required)) schema$required <- as.list(required)
  list(name = name, title = title, description = description, inputSchema = schema,
       handler = handler, needs = needs, read_only = read_only)
}

p_str <- function(description, enum = NULL) {
  out <- list(type = "string", description = description)
  if (!is.null(enum)) out$enum <- as.list(enum)
  out
}
p_int <- function(description) list(type = "integer", description = description)
p_bool <- function(description) list(type = "boolean", description = description)
p_strs <- function(description) list(type = "array", items = list(type = "string"),
                                     description = description)

# Functions of the instructor toolkit that a tool needs. The tools appear only
# when the installed mirtverse has them.
toolkit_fn <- function(name) {
  ns <- asNamespace("mirtverse")
  if (exists(name, envir = ns, inherits = FALSE)) get(name, envir = ns) else NULL
}
has_toolkit <- function(needs) {
  is.null(needs) || all(vapply(needs, function(n) !is.null(toolkit_fn(n)), logical(1)))
}

mcp_tools <- function() {
  list(
    mcp_tool("course_overview",
      "Start here. Summarizes the course folder: its manifest (title, instructor, materials), the files in it, the built-in labs that can be copied in, and recent changes made through this server.",
      handler = tool_course_overview, title = "Course overview", read_only = TRUE),
    mcp_tool("list_materials",
      "Lists the teaching materials in the course folder (labs, chapters, notes, slides, R scripts, data files) with their titles and paths relative to the course folder.",
      list(kind = p_str("Optional filter.", c("all", "lab", "chapter", "document", "script", "data"))),
      handler = tool_list_materials, title = "List materials", read_only = TRUE),
    mcp_tool("read_material",
      "Reads a text file in the course folder (R Markdown, Quarto, Markdown, R, YAML, JSON, CSV ...). Lines are numbered so you can refer to them. Use from_line/to_line for long files.",
      list(path = p_str("Path relative to the course folder."),
           from_line = p_int("First line to return (default 1)."),
           to_line = p_int("Last line to return (default: end, at most 600 lines per call).")),
      "path", tool_read_material, title = "Read material", read_only = TRUE),
    mcp_tool("write_material",
      "Creates a file or replaces its whole content. Prefer edit_material for changes to part of an existing file. The old version is backed up and a diff is returned.",
      list(path = p_str("Path relative to the course folder. Folders are created as needed."),
           content = p_str("The complete new content of the file.")),
      c("path", "content"), tool_write_material, title = "Write material"),
    mcp_tool("edit_material",
      "Replaces an exact piece of text in a file with new text. old_text must match the file exactly (including spaces and line breaks) and, unless replace_all is true, occur exactly once. Read the file first. The old version is backed up and a diff is returned.",
      list(path = p_str("Path relative to the course folder."),
           old_text = p_str("Exact text to replace. Use an empty string with insert_at_line to insert."),
           new_text = p_str("Replacement text."),
           replace_all = p_bool("Replace every occurrence (default false)."),
           insert_at_line = p_int("With empty old_text: insert new_text before this line number (use one more than the number of lines to append).")),
      c("path", "old_text", "new_text"), tool_edit_material, title = "Edit material"),
    mcp_tool("undo_last_change",
      "Undoes the most recent change made through this server (a write, an edit, or a toolkit operation such as copying a lab or swapping its data), restoring every file it touched. Give a path to undo the most recent change to that file or folder instead.",
      list(path = p_str("Optional path relative to the course folder.")),
      handler = tool_undo, title = "Undo last change"),
    mcp_tool("describe_dataset",
      "Describes a dataset so a lab or chapter can be built on it: size, each column's type, missing values and values, which columns look like scored items (dichotomous or polytomous), group variables and ID columns. Accepts a file in the course folder (.csv, .tsv, .xlsx, .sav, .dta, .rds, .rda) or the name of a dataset that ships with mirtverse or mirt (for example certexam, numeracy, SAT12, LSAT7).",
      list(source = p_str("A path relative to the course folder, or a dataset name."),
           object = p_str("For .rda files with several objects: which one.")),
      "source", tool_describe_dataset, title = "Describe dataset", read_only = TRUE),
    mcp_tool("mirtverse_help",
      "Looks up mirtverse functions. With no arguments, lists every exported function with a one-line title. With topic, returns that function's help page (usage, arguments, value, examples). With search, lists functions whose help mentions the words. Use this instead of guessing function names or arguments.",
      list(topic = p_str("A function or dataset name, e.g. 'gg_trace' or 'certexam'."),
           search = p_str("Words to search for in the help pages.")),
      handler = tool_help, title = "mirtverse help", read_only = TRUE),
    mcp_tool("guide",
      "Returns a guide for working on mirtverse teaching materials. Topics: 'workflow' (how to handle an instructor's request), 'lab-style' (structure and conventions of a mirtverse learnr lab, required before writing or editing labs), 'chapter-style' (book chapters and lecture notes), 'adapting' (converting existing materials and code from other IRT packages to mirtverse), 'ai-content' (teaching AI in measurement: the AI section types, their data, the AI chapters and labs, and the checks every AI example needs).",
      list(topic = p_str("Guide to read.", c("workflow", "lab-style", "chapter-style", "adapting", "ai-content"))),
      "topic", tool_guide, title = "Guide", read_only = TRUE),
    mcp_tool("scan_material",
      "Scans the R code in a material (or any .R/.Rmd/.qmd/.md file) for code that mirtverse can replace: models fitted with ltm, eRm, TAM or irtQ (which translate_code converts), base mirt calls that have a friendlier mirtverse equivalent (plots, tidy tables, model comparison, DIF, interpretation), and other packages. Returns each finding with its line number and the suggested replacement.",
      list(path = p_str("Path relative to the course folder.")),
      "path", tool_scan_material, title = "Scan material", read_only = TRUE),
    mcp_tool("translate_code",
      "Translates R code written for ltm, eRm, TAM or irtQ into mirt and mirtverse code with mirtify(), with notes on what differs between the packages (estimation method, scaling constant, defaults). Give the code directly or a path to an .R file.",
      list(code = p_str("R code to translate."),
           path = p_str("Or: an .R file in the course folder.")),
      handler = tool_translate_code, title = "Translate code", read_only = TRUE),
    mcp_tool("check_material",
      "Checks that a material works: R chunks parse, and for labs every exercise solution passes its checker. With render = true the material is also rendered (slower, catches errors in text chunks and setup). Run it after every change. Runs in a separate R process.",
      list(path = p_str("Path relative to the course folder: a lab folder or file, a chapter, or an R script."),
           render = p_bool("Also render the document (default false).")),
      "path", tool_check_material, title = "Check material", read_only = TRUE),

    # Instructor toolkit
    mcp_tool("start_course",
      "Turns the course folder into a mirtverse course: writes course.json (the manifest) and a README, and creates labs/, chapters/ and data/. Use once, when course_overview shows no manifest.",
      list(title = p_str("Course title, e.g. 'EDPY 507: Measurement Theory II'."),
           instructor = p_str("Instructor name.")),
      handler = tool_start_course, needs = "new_course", title = "Start course"),
    mcp_tool("list_templates",
      "Lists what can be added to the course: the built-in mirtverse labs (copy with copy_lab), the section types that can be added to a lab (add_lab_section), and the book chapters (copy_chapter).",
      handler = tool_list_templates, needs = "lab_section_types", title = "List templates",
      read_only = TRUE),
    mcp_tool("copy_lab",
      "Copies a built-in mirtverse lab (see list_templates) into the course's labs/ folder so it can be customized.",
      list(name = p_str("Built-in lab name, e.g. 'model-choice', 'fairness'."),
           as = p_str("Optional new name for the copy.")),
      "name", tool_copy_lab, needs = "copy_lab", title = "Copy lab"),
    mcp_tool("new_lab",
      "Builds a new lab on the instructor's own data with the standard sections (data, item analysis, model choice, interpretation ...). Run describe_dataset on the data first to choose items, group and key.",
      list(name = p_str("Lab name (folder name, lowercase with dashes)."),
           data = p_str("Data file relative to the course folder, or a dataset name."),
           items = p_strs("Item columns (default: detected)."),
           group = p_str("Optional grouping column for DIF sections."),
           key = p_strs("Optional answer key, one entry per item, if the items are unscored."),
           item_info = p_str("Optional file or dataset with one row per item (columns item, and stem/options/key for item-features or family for aig). See guide('ai-content')."),
           scores = p_str("Optional file or dataset of machine and human scores (columns machine, human1, optional human2, group, item, period) for the ai-scoring section. See guide('ai-content')."),
           title = p_str("Lab title."),
           data_title = p_str("How the lab describes the data, e.g. 'a 40-item statistics final exam'."),
           story = p_str("Optional opening scenario for the lab (Markdown)."),
           sections = p_strs("Optional section types in order (see list_templates)."),
           overwrite = p_bool("Replace an existing lab with this name (default false).")),
      c("name", "data"), tool_new_lab, needs = "new_lab", title = "New lab from data"),
    mcp_tool("lab_outline",
      "Shows a lab's sections in order with their ids, types and titles. Use the ids with add_lab_section, add_lab_exercise, add_lab_question (after) and remove_lab_section.",
      list(lab = p_str("The lab folder relative to the course folder, e.g. 'labs/fairness'.")),
      "lab", tool_lab_outline, needs = "lab_outline", title = "Lab outline", read_only = TRUE),
    mcp_tool("add_lab_section",
      "Adds a ready-made section (see list_templates for the types) to a lab.",
      list(lab = p_str("The lab folder."), type = p_str("Section type."),
           after = p_str("Id of the section to insert after (default: at the end, before the answer key).")),
      c("lab", "type"), tool_add_lab_section, needs = "add_lab_section", title = "Add lab section"),
    mcp_tool("add_lab_exercise",
      "Adds a coding exercise to a lab: a prompt, the solution code, and optionally a check and a hint. The check is R code that uses lab_need(condition, message) and .result (the value of the student's last expression); it ends with the feedback string shown when the answer is right.",
      list(lab = p_str("The lab folder."), title = p_str("Exercise title."),
           prompt = p_str("What the student is asked to do (Markdown)."),
           solution = p_str("Solution code."),
           starter = p_str("Optional starting code with blanks shown to the student."),
           check = p_str("Optional check code."),
           hint = p_str("Optional hint code or text."),
           use_fit = p_bool("Give the exercise the lab's fitted model (default false)."),
           after = p_str("Id of the section to insert after."),
           id = p_str("Optional id (chunk label stem) for the exercise.")),
      c("lab", "title", "prompt", "solution"), tool_add_lab_exercise,
      needs = "add_lab_exercise", title = "Add lab exercise"),
    mcp_tool("add_lab_question",
      "Adds a multiple-choice question to a lab.",
      list(lab = p_str("The lab folder."), question = p_str("Question text."),
           answers = p_strs("Answer options."),
           correct = p_strs("The correct option(s), copied exactly from answers."),
           messages = p_strs("Optional feedback for each answer, in the same order as answers."),
           title = p_str("Optional section title."),
           after = p_str("Id of the section to insert after."),
           id = p_str("Optional id for the question.")),
      c("lab", "question", "answers", "correct"), tool_add_lab_question,
      needs = "add_lab_question", title = "Add lab question"),
    mcp_tool("remove_lab_section",
      "Removes a section from a lab by its id (see lab_outline).",
      list(lab = p_str("The lab folder."), id = p_str("Section id.")),
      c("lab", "id"), tool_remove_lab_section, needs = "remove_lab_section",
      title = "Remove lab section"),
    mcp_tool("swap_lab_data",
      "Replaces the data of a lab built with new_lab (or copied and prepared by the toolkit) with the instructor's own data. The lab's text and checks adapt automatically.",
      list(lab = p_str("The lab folder."),
           data = p_str("Data file relative to the course folder, or a dataset name."),
           items = p_strs("Item columns (default: detected)."),
           group = p_str("Optional grouping column."),
           key = p_strs("Optional answer key."),
           item_info = p_str("Optional new item information for the AI sections (file or dataset)."),
           scores = p_str("Optional new machine and human scores for the ai-scoring section (file or dataset)."),
           data_title = p_str("How the lab describes the data.")),
      c("lab", "data"), tool_swap_lab_data, needs = "swap_lab_data", title = "Swap lab data"),
    mcp_tool("copy_chapter",
      "Copies a chapter of the mirtverse book into the course's chapters/ folder so it can be customized.",
      list(id = p_str("Chapter id (see list_templates)."),
           from = p_str("Optional source folder of the book."),
           overwrite = p_bool("Replace an existing copy (default false).")),
      "id", tool_copy_chapter, needs = "copy_chapter", title = "Copy chapter"),
    mcp_tool("new_chapter",
      "Creates a new chapter or set of lecture notes with the book's standard headings.",
      list(id = p_str("Chapter id (file name without extension)."), title = p_str("Chapter title."),
           data_code = p_str("Optional R code for the chapter's data chunk."),
           overwrite = p_bool("Replace an existing chapter (default false).")),
      c("id", "title"), tool_new_chapter, needs = "new_chapter", title = "New chapter"),
    mcp_tool("swap_chapter_data",
      "Replaces the code of a chapter's data chunk (named data-<chapter>-<n>) so the chapter's examples use the instructor's data.",
      list(chapter = p_str("The chapter file relative to the course folder."),
           chunk = p_str("Chunk label; leave out to replace every data- chunk."),
           code = p_str("New R code for the chunk.")),
      c("chapter", "code"), tool_swap_chapter_data, needs = "swap_chapter_data",
      title = "Swap chapter data")
  )
}

mcp_tool_list <- function(ctx) {
  tools <- Filter(function(t) has_toolkit(t$needs), mcp_tools())
  lapply(tools, function(t) {
    out <- list(name = t$name, title = t$title, description = t$description,
                inputSchema = t$inputSchema)
    out$annotations <- list(title = t$title, readOnlyHint = isTRUE(t$read_only),
                            destructiveHint = FALSE, openWorldHint = FALSE)
    out
  })
}

mcp_call_tool <- function(params, ctx) {
  name <- params$name %||% ""
  args <- params$arguments %||% list()
  tool <- Filter(function(t) identical(t$name, name), mcp_tools())
  if (!length(tool) || !has_toolkit(tool[[1]]$needs))
    stop(structure(class = c("mcp_rpc_condition", "error", "condition"),
                   list(message = paste("Unknown tool:", name), call = NULL, code = -32602)))
  tool <- tool[[1]]
  printed <- character()
  res <- tryCatch({
    printed <- utils::capture.output(
      val <- withCallingHandlers(tool$handler(args, ctx),
                                 message = function(m) invokeRestart("muffleMessage"),
                                 warning = function(w) {
                                   if (!grepl("native encoding", conditionMessage(w)))
                                     ctx$warnings <- c(ctx$warnings, conditionMessage(w))
                                   invokeRestart("muffleWarning")
                                 }))
    val
  }, error = function(e) structure(conditionMessage(e), class = "mcp_tool_error"))
  warns <- unique(ctx$warnings)
  ctx$warnings <- NULL
  if (inherits(res, "mcp_tool_error"))
    return(list(content = list(list(type = "text", text = paste("Error:", unclass(res)))),
                isError = TRUE))
  text <- if (is.list(res)) res$text else res
  text <- paste(c(text, if (length(warns)) paste0("\nWarnings:\n- ", paste(warns, collapse = "\n- "))),
                collapse = "\n")
  out <- list(content = list(list(type = "text", text = text)), isError = FALSE)
  if (is.list(res) && !is.null(res$structured)) out$structuredContent <- res$structured
  out
}

# ---------------------------------------------------------------------------
# Paths, backups and the change journal

mcp_state_dir <- ".mirtverse-mcp"

mcp_path <- function(ctx, path, must_exist = TRUE) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path))
    stop("`path` must be a path relative to the course folder.", call. = FALSE)
  path <- gsub("\\\\", "/", path)
  full <- if (grepl("^(/|[A-Za-z]:/|~)", path)) path.expand(path) else file.path(ctx$root, path)
  # normalize the deepest part that exists, then add the rest
  rest <- character()
  base <- full
  while (!file.exists(base) && !identical(dirname(base), base)) {
    rest <- c(basename(base), rest)
    base <- dirname(base)
  }
  if (any(rest %in% c("..", ".")))
    stop("Paths may not contain '..'.", call. = FALSE)
  norm <- normalizePath(base, winslash = "/", mustWork = TRUE)
  norm <- if (length(rest)) paste(c(norm, rest), collapse = "/") else norm
  if (!(identical(norm, ctx$root) || startsWith(norm, paste0(ctx$root, "/"))))
    stop("The server can only use files inside the course folder (", ctx$root, ").",
         call. = FALSE)
  rel <- if (identical(norm, ctx$root)) "." else substring(norm, nchar(ctx$root) + 2L)
  if (identical(strsplit(rel, "/")[[1]][1], mcp_state_dir))
    stop("The ", mcp_state_dir, " folder holds the server's backups and cannot be used.",
         call. = FALSE)
  if (must_exist && !file.exists(norm))
    stop("No file or folder '", rel, "' in the course folder. Use list_materials to see what is there.",
         call. = FALSE)
  structure(norm, rel = rel)
}

rel_path <- function(ctx, full) {
  full <- normalizePath(full, winslash = "/", mustWork = FALSE)
  if (startsWith(full, paste0(ctx$root, "/"))) substring(full, nchar(ctx$root) + 2L) else full
}

course_files <- function(ctx, dir = ctx$root) {
  if (!dir.exists(dir)) return(if (file.exists(dir)) dir else character())
  f <- list.files(dir, recursive = TRUE, full.names = TRUE, all.files = FALSE)
  rel <- vapply(f, function(x) rel_path(ctx, x), "", USE.NAMES = FALSE)
  skip <- grepl(paste0("(^|/)(", mcp_state_dir, "|renv|_book|_site|docs|_freeze|",
                       "\\.Rproj\\.user|.*_cache|.*_files)(/|$)"), rel)
  f[!skip]
}

journal_file <- function(ctx) file.path(ctx$root, mcp_state_dir, "journal.json")

read_journal <- function(ctx) {
  f <- journal_file(ctx)
  if (!file.exists(f)) return(list())
  tryCatch(jsonlite::read_json(f, simplifyVector = FALSE), error = function(e) list())
}

write_journal <- function(ctx, j) {
  dir.create(dirname(journal_file(ctx)), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(j, journal_file(ctx), auto_unbox = TRUE, pretty = TRUE, null = "null")
}

# Run `expr` and record every file it creates, changes or deletes under
# `targets` (full paths of files or folders) so the change can be undone.
with_snapshot <- function(ctx, targets, action, expr) {
  targets <- unique(targets)
  list_targets <- function() unique(unlist(lapply(targets, function(t) {
    if (dir.exists(t)) course_files(ctx, t) else if (file.exists(t)) t else character()
  })))
  before <- list_targets()
  id <- format(Sys.time(), "%Y%m%d-%H%M%OS3")
  id <- gsub("[^0-9-]", "", id)
  bdir <- file.path(ctx$root, mcp_state_dir, "backups", id)
  sums <- if (length(before)) tools::md5sum(before) else character()
  for (f in before) {
    dest <- file.path(bdir, rel_path(ctx, f))
    dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
    file.copy(f, dest, overwrite = TRUE, copy.date = TRUE)
  }
  val <- force(expr)
  after <- list_targets()
  changed <- before[!file.exists(before) |
                      tools::md5sum(before) != sums[before]]
  created <- setdiff(after, before)
  entries <- c(lapply(changed, function(f) list(path = rel_path(ctx, f),
                                                backup = file.path("backups", id, rel_path(ctx, f)))),
               lapply(created, function(f) list(path = rel_path(ctx, f), backup = NULL)))
  unchanged <- setdiff(before, changed)
  if (length(unchanged)) unlink(file.path(bdir, vapply(unchanged, function(f) rel_path(ctx, f), "")))
  if (length(entries)) {
    j <- read_journal(ctx)
    j[[length(j) + 1L]] <- list(id = id, time = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                               action = action, files = entries)
    write_journal(ctx, j)
  } else unlink(bdir, recursive = TRUE)
  list(value = val, files = vapply(entries, `[[`, "", "path"))
}

tool_undo <- function(args, ctx) {
  j <- read_journal(ctx)
  if (!length(j)) return("There are no changes to undo.")
  pick <- length(j)
  if (!is.null(args$path) && nzchar(args$path)) {
    target <- attr(mcp_path(ctx, args$path, must_exist = FALSE), "rel")
    hits <- which(vapply(j, function(e) any(vapply(e$files, function(f)
      identical(f$path, target) || startsWith(f$path, paste0(target, "/")), logical(1))),
      logical(1)))
    if (!length(hits)) return(paste0("No recorded change touches '", target, "'."))
    pick <- max(hits)
  }
  e <- j[[pick]]
  for (f in e$files) {
    full <- file.path(ctx$root, f$path)
    if (is.null(f$backup)) {
      unlink(full)
    } else {
      dir.create(dirname(full), recursive = TRUE, showWarnings = FALSE)
      file.copy(file.path(ctx$root, mcp_state_dir, f$backup), full, overwrite = TRUE)
    }
  }
  # remove folders left empty by deleting created files
  for (f in e$files) if (is.null(f$backup)) {
    d <- dirname(file.path(ctx$root, f$path))
    while (!identical(normalizePath(d, winslash = "/", mustWork = FALSE), ctx$root) &&
           dir.exists(d) && !length(list.files(d, all.files = TRUE, no.. = TRUE))) {
      unlink(d, recursive = TRUE)
      d <- dirname(d)
    }
  }
  j[[pick]] <- NULL
  write_journal(ctx, j)
  paste0("Undid \"", e$action, "\" (", e$time, "): restored ",
         paste(vapply(e$files, function(f) paste0(f$path, if (is.null(f$backup)) " (removed)" else ""), ""),
               collapse = ", "), ".")
}

text_diff <- function(old, new, label, max_lines = 150L) {
  if (identical(old, new)) return("No change.")
  diff_bin <- Sys.which("diff")
  if (nzchar(diff_bin)) {
    a <- tempfile(); b <- tempfile()
    on.exit(unlink(c(a, b)), add = TRUE)
    writeLines(old, a, useBytes = TRUE); writeLines(new, b, useBytes = TRUE)
    out <- suppressWarnings(system2(diff_bin, c("-u", "--label", shQuote(paste0("a/", label)),
                                                "--label", shQuote(paste0("b/", label)),
                                                shQuote(a), shQuote(b)),
                                    stdout = TRUE, stderr = TRUE))
    if (length(out) > max_lines)
      out <- c(out[seq_len(max_lines)], sprintf("... (%d more diff lines)", length(out) - max_lines))
    return(paste(out, collapse = "\n"))
  }
  sprintf("%d lines before, %d lines after.", length(old), length(new))
}

read_lines_utf8 <- function(path) {
  x <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (length(x) && startsWith(x[1], "\ufeff")) x[1] <- substring(x[1], 2L)
  x
}

write_lines_utf8 <- function(x, path) {
  con <- file(path, open = "wb")
  on.exit(close(con))
  writeBin(charToRaw(enc2utf8(paste0(paste(x, collapse = "\n"), "\n"))), con)
}

is_text_file <- function(path) {
  tolower(tools::file_ext(path)) %in% c("rmd", "qmd", "md", "r", "txt", "yml", "yaml", "json",
                                        "csv", "tsv", "tex", "rnw", "bib", "css", "html", "js",
                                        "lua", "toml", "cff", "") &&
    !grepl("\\.(rds|rda|rdata|png|jpe?g|pdf|xlsx|sav|dta)$", path, ignore.case = TRUE)
}

# ---------------------------------------------------------------------------
# Reading and writing

material_kind <- function(rel) {
  ext <- tolower(tools::file_ext(rel))
  top <- strsplit(rel, "/")[[1]][1]
  if (ext %in% c("rmd", "qmd") && (identical(top, "labs") || identical(top, "tutorials")))
    return("lab")
  if (ext %in% c("rmd", "qmd") && identical(top, "chapters")) return("chapter")
  if (ext %in% c("rmd", "qmd", "md", "rnw", "tex", "html", "pptx", "docx", "pdf")) return("document")
  if (ext == "r") return("script")
  if (ext %in% c("csv", "tsv", "xlsx", "xls", "sav", "dta", "sas7bdat", "rds", "rda", "rdata"))
    return("data")
  "other"
}

doc_title <- function(path) {
  if (!tolower(tools::file_ext(path)) %in% c("rmd", "qmd", "md")) return("")
  lines <- utils::head(read_lines_utf8(path), 40L)
  t <- grep("^title:", lines, value = TRUE)
  if (length(t)) return(gsub("^[\"']|[\"']$", "", trimws(sub("^title:", "", t[1]))))
  h <- grep("^# ", lines, value = TRUE)
  if (length(h)) sub("^# ", "", h[1]) else ""
}

materials_table <- function(ctx) {
  files <- course_files(ctx)
  rel <- vapply(files, function(f) rel_path(ctx, f), "", USE.NAMES = FALSE)
  kind <- vapply(rel, material_kind, "", USE.NAMES = FALSE)
  keep <- kind != "other" | basename(rel) %in% c("course.json", "README.md", "_bookdown.yml")
  data.frame(path = rel[keep], kind = kind[keep],
             title = vapply(files[keep], doc_title, "", USE.NAMES = FALSE),
             size = format_size(file.size(files[keep])), stringsAsFactors = FALSE)
}

format_size <- function(b) {
  ifelse(b < 1024, paste(b, "B"), ifelse(b < 1024^2, sprintf("%.1f KB", b / 1024),
                                         sprintf("%.1f MB", b / 1024^2)))
}

md_table <- function(df) {
  if (!nrow(df)) return("(none)")
  df[] <- lapply(df, function(v) gsub("\\|", "/", gsub("\n", " ", as.character(v))))
  paste(c(paste0("| ", paste(names(df), collapse = " | "), " |"),
          paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|"),
          apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |"))),
        collapse = "\n")
}

tool_list_materials <- function(args, ctx) {
  tab <- toolkit_materials(ctx)
  if (is.null(tab)) tab <- materials_table(ctx)
  kind <- args$kind %||% "all"
  if (!identical(kind, "all") && "kind" %in% names(tab)) tab <- tab[tab$kind == kind, , drop = FALSE]
  list(text = paste0("Materials in ", ctx$root, ":\n\n", md_table(tab)),
       structured = list(materials = tab))
}

# The toolkit's own listing, when available and the folder is a course
toolkit_materials <- function(ctx) {
  fn <- toolkit_fn("course_materials")
  if (is.null(fn) || !file.exists(file.path(ctx$root, "course.json"))) return(NULL)
  tab <- tryCatch(as.data.frame(fn(ctx$root)), error = function(e) NULL)
  if (is.null(tab)) return(NULL)
  if ("type" %in% names(tab) && !"kind" %in% names(tab)) names(tab)[names(tab) == "type"] <- "kind"
  tab[] <- lapply(tab, function(v) if (is.list(v)) vapply(v, function(z) paste(format(z), collapse = ", "), "") else v)
  if ("path" %in% names(tab))
    tab$path <- vapply(tab$path, function(x) rel_path(ctx, x), "", USE.NAMES = FALSE)
  files <- materials_table(ctx)
  other <- files[!files$path %in% tab$path & !startsWith(files$path, "labs/") &
                   !startsWith(files$path, "chapters/"), , drop = FALSE]
  if (nrow(other)) {
    extra <- as.data.frame(lapply(names(tab), function(n)
      if (n %in% names(other)) other[[n]] else rep("", nrow(other))), stringsAsFactors = FALSE)
    names(extra) <- names(tab)
    tab <- rbind(tab, extra)
  }
  tab
}

tool_read_material <- function(args, ctx) {
  p <- mcp_path(ctx, args$path)
  if (dir.exists(p)) {
    files <- vapply(course_files(ctx, p), function(f) rel_path(ctx, f), "")
    return(paste0("'", attr(p, "rel"), "' is a folder containing:\n", paste("-", files, collapse = "\n")))
  }
  if (!is_text_file(p))
    return(paste0("'", attr(p, "rel"), "' is not a text file (", format_size(file.size(p)),
                  "). Use describe_dataset for data files."))
  lines <- read_lines_utf8(p)
  n <- length(lines)
  from <- max(1L, as.integer(args$from_line %||% 1L))
  to <- min(n, as.integer(args$to_line %||% n), from + 599L)
  if (n == 0L) return(paste0(attr(p, "rel"), " is empty."))
  if (from > n) return(sprintf("%s has only %d lines.", attr(p, "rel"), n))
  body <- sprintf("%*d  %s", nchar(n), from:to, lines[from:to])
  head <- sprintf("%s (lines %d-%d of %d):", attr(p, "rel"), from, to, n)
  tail <- if (to < n) sprintf("\n... %d more lines; call again with from_line = %d.", n - to, to + 1L) else ""
  paste0(head, "\n", paste(body, collapse = "\n"), tail)
}

tool_write_material <- function(args, ctx) {
  p <- mcp_path(ctx, args$path, must_exist = FALSE)
  if (dir.exists(p)) stop("'", attr(p, "rel"), "' is a folder.", call. = FALSE)
  if (!is.character(args$content)) stop("`content` must be text.", call. = FALSE)
  old <- if (file.exists(p)) read_lines_utf8(p) else character()
  new <- strsplit(gsub("\r\n", "\n", args$content), "\n", fixed = TRUE)[[1]]
  existed <- file.exists(p)
  with_snapshot(ctx, p, paste(if (existed) "Rewrite" else "Create", attr(p, "rel")), {
    dir.create(dirname(p), recursive = TRUE, showWarnings = FALSE)
    write_lines_utf8(new, p)
  })
  paste0(if (existed) "Updated " else "Created ", attr(p, "rel"), " (", length(new), " lines).\n\n",
         text_diff(old, new, attr(p, "rel")))
}

tool_edit_material <- function(args, ctx) {
  p <- mcp_path(ctx, args$path)
  if (!is_text_file(p) || dir.exists(p)) stop("'", attr(p, "rel"), "' is not a text file.", call. = FALSE)
  old_lines <- read_lines_utf8(p)
  txt <- paste(old_lines, collapse = "\n")
  old <- gsub("\r\n", "\n", args$old_text %||% "")
  new <- gsub("\r\n", "\n", args$new_text %||% "")
  if (!nzchar(old)) {
    at <- args$insert_at_line
    if (is.null(at)) stop("Give old_text, or insert_at_line to insert new text.", call. = FALSE)
    at <- as.integer(at)
    if (at < 1L || at > length(old_lines) + 1L)
      stop("insert_at_line must be between 1 and ", length(old_lines) + 1L, ".", call. = FALSE)
    ins <- strsplit(new, "\n", fixed = TRUE)[[1]]
    new_lines <- append(old_lines, ins, after = at - 1L)
  } else {
    hits <- gregexpr(old, txt, fixed = TRUE)[[1]]
    n_hits <- if (hits[1] == -1L) 0L else length(hits)
    if (n_hits == 0L)
      stop("old_text was not found in ", attr(p, "rel"),
           ". Read the file again and copy the text exactly (spaces, quotes and line breaks matter).",
           call. = FALSE)
    if (n_hits > 1L && !isTRUE(args$replace_all))
      stop("old_text occurs ", n_hits, " times in ", attr(p, "rel"),
           ". Include more surrounding text so it is unique, or set replace_all = true.", call. = FALSE)
    out <- if (isTRUE(args$replace_all)) gsub(old, new, txt, fixed = TRUE) else
      sub(old, new, txt, fixed = TRUE)
    new_lines <- strsplit(out, "\n", fixed = TRUE)[[1]]
  }
  with_snapshot(ctx, p, paste("Edit", attr(p, "rel")), write_lines_utf8(new_lines, p))
  paste0("Edited ", attr(p, "rel"), ".\n\n", text_diff(old_lines, new_lines, attr(p, "rel")))
}

tool_course_overview <- function(args, ctx) {
  manifest <- file.path(ctx$root, "course.json")
  man_txt <- if (file.exists(manifest)) {
    m <- tryCatch(jsonlite::read_json(manifest), error = function(e) NULL)
    if (is.null(m)) "course.json exists but could not be read." else
      paste0("Course: ", m$title %||% "(untitled)",
             if (!is.null(m$instructor)) paste0(" | Instructor: ", m$instructor) else "")
  } else if (!is.null(toolkit_fn("new_course"))) {
    "This folder is not set up as a mirtverse course yet (no course.json). Use start_course to set it up, or work with the files as they are."
  } else "No course.json manifest; working with the files as they are."
  mats <- toolkit_materials(ctx) %||% materials_table(ctx)
  labs <- tryCatch(list_labs(), error = function(e) NULL)
  j <- read_journal(ctx)
  recent <- utils::tail(j, 5L)
  paste0(
    "Course folder: ", ctx$root, "\n", man_txt, "\n",
    "mirtverse ", as.character(utils::packageVersion("mirtverse")),
    ", mirt ", as.character(utils::packageVersion("mirt")), "; running R code is ",
    if (ctx$allow_run) "allowed" else "turned off", ".\n\n",
    "## Materials\n\n", md_table(mats), "\n\n",
    "## Built-in labs (copy_lab)\n\n",
    if (is.null(labs)) "(unavailable)" else md_table(as.data.frame(labs)[, c("name", "title")]),
    "\n\n## Recent changes\n\n",
    if (!length(recent)) "(none)" else paste(vapply(rev(recent), function(e)
      paste0("- ", e$time, ": ", e$action), ""), collapse = "\n"))
}

# ---------------------------------------------------------------------------
# Datasets

load_dataset <- function(source, ctx, object = NULL) {
  looks_like_path <- grepl("[/\\\\]|\\.[A-Za-z0-9]+$", source)
  if (looks_like_path) {
    p <- mcp_path(ctx, source)
    ext <- tolower(tools::file_ext(p))
    if (ext %in% c("rda", "rdata")) {
      e <- new.env()
      objs <- load(p, envir = e)
      pick <- object %||% objs[1]
      if (!pick %in% objs) stop("Objects in ", basename(p), ": ", paste(objs, collapse = ", "), call. = FALSE)
      return(list(data = as.data.frame(get(pick, envir = e)), label = attr(p, "rel"),
                  note = if (length(objs) > 1) paste("Other objects in the file:",
                                                      paste(setdiff(objs, pick), collapse = ", "))))
    }
    return(list(data = as.data.frame(read_any(p, p)), label = attr(p, "rel")))
  }
  for (pkg in c("mirtverse", "mirt")) {
    e <- new.env()
    ok <- tryCatch({
      utils::data(list = source, package = pkg, envir = e)
      exists(source, envir = e, inherits = FALSE)
    }, warning = function(w) FALSE, error = function(err) FALSE)
    if (ok) return(list(data = as.data.frame(get(source, envir = e)),
                        label = paste0(source, " (", pkg, " package)")))
  }
  stop("No file or dataset called '", source, "'. Give a path inside the course folder or a dataset from mirtverse or mirt.",
       call. = FALSE)
}

describe_columns <- function(df) {
  n <- nrow(df)
  rows <- lapply(names(df), function(nm) {
    v <- df[[nm]]
    miss <- sum(is.na(v))
    vals <- unique(v[!is.na(v)])
    k <- length(vals)
    role <- "other"
    if (grepl("(^|[._ ])(id|ids)$|^id[._ ]|identifier|^(student|person|candidate|examinee)", nm,
              ignore.case = TRUE) && k >= 0.9 * (n - miss)) {
      role <- "id?"
    } else if (is.numeric(v) && k <= 10 && k >= 2 && all(vals == round(vals))) {
      role <- if (k == 2) "item (dichotomous)" else "item (polytomous)"
    } else if (is.character(v) && k <= 10 && k >= 2 && all(nchar(vals) <= 1)) {
      role <- "item (unscored responses?)"
    } else if ((is.factor(v) || is.character(v) || is.logical(v)) && k >= 2 && k <= 6) {
      role <- "group?"
    } else if (k == n - miss && n > 1) role <- "id?"
    shown <- if (is.numeric(v) && k > 10) sprintf("%.3g to %.3g", min(vals), max(vals)) else
      paste(utils::head(sort(as.character(vals)), 8L), collapse = ", ")
    if (!is.numeric(v) || k <= 10) if (k > 8) shown <- paste0(shown, ", ... (", k, " values)")
    data.frame(column = nm, type = class(v)[1], missing = miss, values = shown, role = role,
               stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

# Show at most a few item columns in full when there are many
compact_columns <- function(cols, show = 6L) {
  is_item <- startsWith(cols$role, "item")
  if (sum(is_item) <= show + 2L) return(cols)
  idx <- which(is_item)
  hidden <- idx[-seq_len(show)]
  out <- cols[-hidden, , drop = FALSE]
  extra <- data.frame(column = sprintf("... %d more item columns (%s to %s)", length(hidden),
                                       cols$column[hidden[1]], cols$column[utils::tail(hidden, 1)]),
                      type = "", missing = sum(cols$missing[hidden]), values = "",
                      role = "item", stringsAsFactors = FALSE)
  pos <- sum(seq_len(nrow(out)) <= match(cols$column[idx[show]], out$column))
  rbind(out[seq_len(pos), , drop = FALSE], extra, out[-seq_len(pos), , drop = FALSE])
}

tool_describe_dataset <- function(args, ctx) {
  d <- load_dataset(args$source, ctx, args$object)
  df <- d$data
  cols <- describe_columns(df)
  items <- cols$column[startsWith(cols$role, "item")]
  groups <- cols$column[cols$role == "group?"]
  text <- paste0(
    d$label, ": ", nrow(df), " rows, ", ncol(df), " columns.\n",
    if (!is.null(d$note)) paste0(d$note, "\n"),
    "\nLikely item columns (", length(items), "): ",
    if (length(items)) paste(items, collapse = ", ") else "none found", "\n",
    "Possible group variables: ", if (length(groups)) paste(groups, collapse = ", ") else "none", "\n",
    if (length(items)) sprintf("Missing responses among items: %.1f%%\n",
                               100 * mean(is.na(as.matrix(df[items])))) else "",
    "\n", md_table(compact_columns(cols)))
  list(text = text, structured = list(rows = nrow(df), columns = cols, items = items,
                                      groups = groups))
}

# ---------------------------------------------------------------------------
# Help and guides

mv_rd_db <- function() {
  db <- tryCatch(tools::Rd_db("mirtverse"), error = function(e) list())
  if (!length(db)) {
    man <- file.path(find.package("mirtverse"), "man")
    files <- list.files(man, pattern = "\\.Rd$", full.names = TRUE)
    db <- stats::setNames(lapply(files, tools::parse_Rd), basename(files))
  }
  db
}

rd_field <- function(rd, tag) {
  tags <- vapply(rd, function(x) attr(x, "Rd_tag") %||% "", "")
  hit <- rd[tags == paste0("\\", tag)]
  vapply(hit, function(x) trimws(paste(unlist(x), collapse = "")), "")
}

tool_help <- function(args, ctx) {
  db <- mv_rd_db()
  info <- lapply(db, function(rd) list(name = rd_field(rd, "name")[1],
                                        alias = rd_field(rd, "alias"),
                                        title = gsub("\\s+", " ", rd_field(rd, "title")[1]),
                                        internal = any(grepl("internal", rd_field(rd, "keyword")))))
  topic <- args$topic %||% ""
  search <- args$search %||% ""
  if (nzchar(topic)) {
    hit <- which(vapply(info, function(i) topic %in% c(i$name, i$alias), logical(1)))
    if (!length(hit))
      stop("No help page for '", topic, "'. Call mirtverse_help with no arguments to list the functions.",
           call. = FALSE)
    out <- utils::capture.output(tools::Rd2txt(db[[hit[1]]], out = stdout(),
                                               options = list(underline_titles = FALSE)))
    return(paste(out, collapse = "\n"))
  }
  info <- Filter(function(i) !isTRUE(i$internal), info)
  if (nzchar(search)) {
    words <- tolower(strsplit(search, "\\s+")[[1]])
    texts <- vapply(names(info), function(n) tolower(paste(unlist(db[[n]]), collapse = " ")), "")
    keep <- vapply(texts, function(t) all(vapply(words, function(w) grepl(w, t, fixed = TRUE), logical(1))),
                   logical(1))
    info <- info[keep]
    if (!length(info)) return(paste0("No help page mentions '", search, "'."))
  }
  tab <- data.frame(topic = vapply(info, `[[`, "", "name"),
                    title = vapply(info, `[[`, "", "title"), stringsAsFactors = FALSE)
  tab <- tab[order(tab$topic), , drop = FALSE]
  paste0("mirtverse help topics (use topic = <name> for the full page):\n\n", md_table(tab))
}

guide_text <- function(topic) {
  f <- system.file("mcp", "guides", paste0(topic, ".md"), package = "mirtverse")
  if (!nzchar(f)) stop("Unknown guide '", topic, "'.", call. = FALSE)
  paste(read_lines_utf8(f), collapse = "\n")
}

tool_guide <- function(args, ctx) guide_text(args$topic %||% "workflow")

# ---------------------------------------------------------------------------
# Adapting existing materials

# Code chunks of a document with their starting line numbers
extract_code <- function(path) {
  lines <- read_lines_utf8(path)
  ext <- tolower(tools::file_ext(path))
  if (ext == "r") return(list(list(label = basename(path), start = 1L, code = lines)))
  open <- grep("^\\s*```+\\s*\\{?\\s*[rR]\\b", lines)
  chunks <- list()
  for (i in open) {
    close <- which(grepl("^\\s*```+\\s*$", lines) & seq_along(lines) > i)
    if (!length(close)) next
    close <- close[1]
    hdr <- lines[i]
    label <- sub("^\\s*```+\\s*\\{?\\s*[rR][ ,]*([^ ,}=]*).*$", "\\1", hdr)
    if (!nzchar(label) || grepl("=", label)) label <- paste0("chunk at line ", i)
    code <- if (close > i + 1L) lines[(i + 1L):(close - 1L)] else character()
    chunks[[length(chunks) + 1L]] <- list(label = label, start = i + 1L, code = code)
  }
  chunks
}

# Base mirt calls with a friendlier mirtverse equivalent
mirt_upgrades <- function() {
  data.frame(
    pattern = c("coef", "itemplot", "plot", "itemfit", "residuals", "fscores", "anova", "M2",
                "DIF", "summary", "empirical_plot", "itemstats", "marginal_rxx", "extract.item",
                "key2binary", "testinfo", "iteminfo", "personfit"),
    suggestion = c(
      "tidy(model) gives the item parameters as a data frame (IRT parameterization by default).",
      "gg_trace(model, which.items = ...) draws trace lines with ggplot2.",
      "gg_trace(), gg_info() (type = 'info' / 'infoSE'), gg_scores() or gg_wright() replace the lattice plots; autoplot(model) also works.",
      "item_table(model) combines item statistics and fit; gg_itemfit(model) plots it.",
      "gg_q3(model) shows the Q3 / LD matrix as a heatmap.",
      "augment(model, data) adds person scores (and person fit) to the data; gg_scores(model) plots them.",
      "select_model(data) fits and compares Rasch, 2PL, 3PL (and polytomous) models and recommends one.",
      "select_model() reports M2-based fit alongside information criteria; glance(model) gives one-row fit summaries.",
      "dif(data, group) runs DIF in one call with a tidy result; gg_dif() plots it and interpret() explains it.",
      "interpret(model) explains the results in plain language for students.",
      "gg_empirical(model, item) compares empirical and model-implied curves.",
      "item_table(model) adds classical item statistics to the IRT parameters.",
      "glance(model) reports marginal reliability with other model summaries.",
      "item_card(model, item) gives a one-page health card for an item.",
      "Keep key2binary(); for open-ended items see score_open().",
      "gg_info(model) plots test information and standard error.",
      "gg_info(model, which.items = ...) plots item information.",
      "augment(model, data, person_fit = TRUE) adds person fit statistics to the data."),
    stringsAsFactors = FALSE)
}

other_packages <- c(
  ltm = "translate_code converts ltm models to mirt.",
  eRm = "translate_code converts eRm models to mirt (note: eRm uses conditional ML).",
  TAM = "translate_code converts TAM models to mirt.",
  irtQ = "translate_code converts irtQ models to mirt.",
  psych = "Keep psych for classical statistics, or use item_table(model) for item statistics next to the IRT results.",
  CTT = "item_table(model) reports classical item statistics.",
  ShinyItemAnalysis = "launch_workbench() is the point-and-click mirtverse alternative.",
  ggmirt = "gg_trace(), gg_info(), gg_itemfit(), gg_scores() and gg_wright() cover ggmirt's plots.",
  difR = "dif() runs IRT likelihood-ratio DIF; keep difR for Mantel-Haenszel if you teach it.",
  lavaan = "Fine to keep for CFA; mirt handles item factor analysis directly.",
  equateIRT = "Lab 4 (linking) shows linking and true-score equating with mirt.",
  mirtCAT = "Lab 5 (cat-design) and simulate_cat() cover adaptive testing.")

scan_code_calls <- function(code) {
  pd <- tryCatch({
    exprs <- parse(text = code, keep.source = TRUE)
    utils::getParseData(exprs)
  }, error = function(e) e)
  if (inherits(pd, "error")) return(pd)
  if (is.null(pd)) return(data.frame(fun = character(), pkg = character(), line = integer()))
  calls <- pd[pd$token == "SYMBOL_FUNCTION_CALL", c("line1", "text", "parent")]
  pkg <- vapply(seq_len(nrow(calls)), function(i) {
    par <- pd[pd$id == calls$parent[i], ]
    sib <- pd[pd$parent == calls$parent[i] & pd$token == "SYMBOL_PACKAGE", "text"]
    if (length(sib)) sib[1] else ""
  }, "")
  libs <- pd[pd$token == "SYMBOL_FUNCTION_CALL" & pd$text %in% c("library", "require"), ]
  lib_pkgs <- character()
  out <- data.frame(fun = calls$text, pkg = pkg, line = calls$line1, stringsAsFactors = FALSE)
  # library(x) / require(x) arguments
  lib_lines <- grep("^\\s*(library|require|requireNamespace)\\(", code)
  for (l in lib_lines) {
    p <- sub("^\\s*(library|require|requireNamespace)\\(\\s*[\"']?([A-Za-z0-9.]+).*$", "\\2", code[l])
    out <- rbind(out, data.frame(fun = "library", pkg = p, line = l, stringsAsFactors = FALSE))
  }
  out
}

tool_scan_material <- function(args, ctx) {
  p <- mcp_path(ctx, args$path)
  if (!is_text_file(p)) stop("scan_material reads .R, .Rmd, .qmd and .md files.", call. = FALSE)
  chunks <- extract_code(p)
  if (!length(chunks)) return(paste0("No R code found in ", attr(p, "rel"), "."))
  cw <- as.data.frame(mirtify_crosswalk())
  # one row per function name ("RM(), PCM()" lists two)
  parts <- strsplit(cw[["function"]], ",\\s*")
  cw <- cw[rep(seq_len(nrow(cw)), lengths(parts)), , drop = FALSE]
  cw_fun <- sub("\\(\\)$", "", unlist(parts))
  keep <- grepl("^[A-Za-z.][A-Za-z0-9._]*$", cw_fun)
  cw <- cw[keep, , drop = FALSE]
  cw_fun <- cw_fun[keep]
  # packages attached anywhere in the file: their bare calls are translated
  attached <- unlist(lapply(chunks, function(ch) {
    l <- grep("^\\s*(library|require)\\(", ch$code, value = TRUE)
    sub("^\\s*(library|require)\\(\\s*[\"']?([A-Za-z0-9.]+).*$", "\\2", l)
  }))
  upg <- mirt_upgrades()
  findings <- list()
  add <- function(line, kind, code, suggestion)
    findings[[length(findings) + 1L]] <<- data.frame(line = line, kind = kind, code = code,
                                                    suggestion = suggestion, stringsAsFactors = FALSE)
  parse_errors <- character()
  for (ch in chunks) {
    calls <- scan_code_calls(ch$code)
    if (inherits(calls, "error")) {
      parse_errors <- c(parse_errors, sprintf("%s (line %d): %s", ch$label, ch$start,
                                              gsub("\n", " ", conditionMessage(calls))))
      next
    }
    for (i in seq_len(nrow(calls))) {
      fun <- calls$fun[i]; pkg <- calls$pkg[i]
      line <- ch$start + calls$line[i] - 1L
      src <- trimws(ch$code[calls$line[i]])
      if (identical(fun, "library")) {
        if (pkg %in% names(other_packages)) add(line, paste("uses", pkg), src, other_packages[[pkg]])
        next
      }
      hit <- cw[cw_fun == fun & ((pkg == "" & cw$package %in% attached) | cw$package == pkg), ,
                drop = FALSE]
      if (nrow(hit)) {
        add(line, paste0(hit$package[1], "::", fun), src,
            paste0("Becomes: ", hit$mirt[1], ". ", hit$notes[1], " (translate_code converts it)."))
        next
      }
      if (pkg %in% c("", "mirt") && fun %in% upg$pattern)
        add(line, paste0("mirt::", fun), src, upg$suggestion[upg$pattern == fun])
    }
  }
  tab <- if (length(findings)) do.call(rbind, findings) else
    data.frame(line = integer(), kind = character(), code = character(), suggestion = character())
  tab <- tab[!duplicated(tab[c("line", "kind")]), , drop = FALSE]
  tab <- tab[order(tab$line), , drop = FALSE]
  head <- sprintf("%s: %d code chunk(s), %d finding(s).", attr(p, "rel"), length(chunks), nrow(tab))
  paste0(head,
         if (length(parse_errors)) paste0("\nCode that does not parse:\n- ", paste(parse_errors, collapse = "\n- ")) else "",
         "\n\n", md_table(tab),
         if (nrow(tab)) "\n\nThese are suggestions: keep base mirt code where the course teaches mirt itself." else "")
}

tool_translate_code <- function(args, ctx) {
  code <- args$code
  if (is.null(code) || !nzchar(code)) {
    if (is.null(args$path)) stop("Give `code` or `path`.", call. = FALSE)
    p <- mcp_path(ctx, args$path)
    chunks <- extract_code(p)
    code <- unlist(lapply(chunks, `[[`, "code"))
  }
  res <- mirtify(code, run = FALSE, notes = TRUE)
  st <- as.data.frame(res$steps)
  st$notes <- vapply(st$notes, function(n) paste(n, collapse = " "), "")
  counts <- table(factor(st$status, c("translated", "partial", "unchanged", "unsupported")))
  paste0("Translated ", counts[["translated"]] + counts[["partial"]], " of ", nrow(st),
         " statements (", counts[["partial"]], " with caveats, ", counts[["unsupported"]],
         " without a mirt equivalent).\n\n```r\n", res$script, "\n```\n\n",
         "Step by step:\n\n", md_table(st[c("original", "status", "notes")]))
}

# ---------------------------------------------------------------------------
# Checking materials (in a separate R process)

run_r_subprocess <- function(ctx, code, wd) {
  if (!ctx$allow_run)
    stop("Running R code is turned off for this server (allow_run = FALSE). Restart it with allow_run = TRUE to check materials.",
         call. = FALSE)
  script <- tempfile(fileext = ".R")
  result <- tempfile(fileext = ".json")
  log <- tempfile(fileext = ".log")
  on.exit(unlink(c(script, result)), add = TRUE)
  writeLines(c(
    sprintf("setwd(%s)", deparse(wd)),
    "options(warn = 1)",
    "suppressPackageStartupMessages(library(mirtverse))",
    sprintf(".mcp_result <- %s", deparse(result)),
    code), script)
  rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
  status <- suppressWarnings(system2(rscript, c("--vanilla", shQuote(script)), stdout = log,
                                     stderr = log, timeout = ctx$timeout))
  out <- if (file.exists(result)) jsonlite::read_json(result, simplifyVector = TRUE) else NULL
  log_txt <- if (file.exists(log)) utils::tail(read_lines_utf8(log), 40L) else character()
  unlink(log)
  list(status = status, result = out, log = log_txt,
       timed_out = identical(as.integer(status), 124L))
}

tool_check_material <- function(args, ctx) {
  p <- mcp_path(ctx, args$path)
  # the toolkit checks lab folders and whole courses; the basic check needs a file
  target <- if (dir.exists(p) && is.null(toolkit_fn("check_material"))) {
    rmd <- list.files(p, pattern = "\\.(Rmd|qmd)$", full.names = TRUE)
    if (!length(rmd)) stop("No .Rmd or .qmd file in '", attr(p, "rel"), "'.", call. = FALSE)
    rmd[1]
  } else as.character(p)
  render <- isTRUE(args$render)
  code <- c(
    sprintf(".path <- %s", deparse(target)),
    sprintf(".render <- %s", render),
    ".ns <- asNamespace('mirtverse')",
    ".res <- tryCatch({",
    "  if (exists('check_material', envir = .ns, inherits = FALSE)) {",
    "    as.data.frame(get('check_material', envir = .ns)(.path, render = .render))",
    "  } else mirtverse:::mcp_basic_check(.path, render = .render)",
    "}, error = function(e) data.frame(check = 'check', label = '', status = 'error',",
    "                                  message = conditionMessage(e)))",
    "jsonlite::write_json(.res, .mcp_result, auto_unbox = TRUE, null = 'null')")
  r <- run_r_subprocess(ctx, code, if (dir.exists(target)) target else dirname(target))
  rel <- rel_path(ctx, target)
  if (r$timed_out)
    return(paste0("The check of ", rel, " did not finish within ", ctx$timeout, " seconds."))
  if (is.null(r$result))
    return(paste0("The check of ", rel, " failed before producing a result. Last output:\n",
                  paste(r$log, collapse = "\n")))
  tab <- as.data.frame(r$result)
  bad <- if ("status" %in% names(tab)) grepl("^(error|fail)", tolower(tab$status)) else logical(nrow(tab))
  verdict <- if (!nrow(tab)) "Nothing to check." else if (any(bad))
    sprintf("%d of %d checks FAILED.", sum(bad), nrow(tab)) else sprintf("All %d checks passed.", nrow(tab))
  shown <- if (any(bad)) tab[bad, , drop = FALSE] else NULL
  list(text = paste0(rel, ": ", verdict,
                     if (!is.null(shown)) paste0("\n\nFailures:\n\n", md_table(shown)) else ""),
       structured = list(passed = !any(bad), checks = tab))
}

#' @noRd
mcp_basic_check <- function(path, render = FALSE) {
  rows <- list()
  add <- function(check, label, status, message = "")
    rows[[length(rows) + 1L]] <<- data.frame(check = check, label = label, status = status,
                                            message = message, stringsAsFactors = FALSE)
  for (ch in extract_code(path)) {
    code <- ch$code
    code <- code[!grepl("^\\s*#\\|", code)]
    res <- tryCatch({ parse(text = code); "ok" }, error = function(e) conditionMessage(e))
    if (identical(res, "ok")) add("parse", ch$label, "ok") else
      if (grepl("____|___", paste(code, collapse = "\n"))) add("parse", ch$label, "ok", "exercise blanks") else
        add("parse", ch$label, "error", gsub("\n", " ", res))
  }
  ext <- tolower(tools::file_ext(path))
  if (render) {
    if (ext == "r") {
      res <- tryCatch({ source(path, local = new.env()); "ok" }, error = function(e) conditionMessage(e))
      add("run", basename(path), if (identical(res, "ok")) "ok" else "error",
          if (identical(res, "ok")) "" else res)
    } else if (ext %in% c("rmd", "qmd", "md")) {
      out <- tempfile()
      res <- tryCatch({
        rmarkdown::render(path, output_dir = out, intermediates_dir = out, quiet = TRUE,
                          envir = new.env())
        "ok"
      }, error = function(e) conditionMessage(e))
      add("render", basename(path), if (identical(res, "ok")) "ok" else "error",
          if (identical(res, "ok")) "" else res)
    }
  }
  if (!length(rows)) return(data.frame(check = character(), label = character(),
                                       status = character(), message = character()))
  do.call(rbind, rows)
}

# ---------------------------------------------------------------------------
# Instructor toolkit wrappers

toolkit_call <- function(ctx, fn_name, args, targets, action) {
  fn <- toolkit_fn(fn_name)
  with_snapshot(ctx, targets, action, do.call(fn, args))
}

data_arg <- function(ctx, data) {
  if (is.null(data)) return(NULL)
  if (grepl("[/\\\\]|\\.[A-Za-z0-9]+$", data)) return(as.character(mcp_path(ctx, data)))
  load_dataset(data, ctx)$data
}

changed_files_text <- function(files) {
  if (!length(files)) return("No files changed.")
  paste0("Files changed:\n", paste("-", files, collapse = "\n"))
}

value_text <- function(val) {
  if (is.data.frame(val)) return(md_table(as.data.frame(val)))
  if (is.character(val) && length(val) == 1L) return("")
  ""
}

lab_dir <- function(ctx, lab) {
  p <- mcp_path(ctx, lab)
  if (!dir.exists(p)) p <- structure(dirname(p), rel = dirname(attr(p, "rel")))
  p
}

tool_start_course <- function(args, ctx) {
  if (file.exists(file.path(ctx$root, "course.json")))
    return("This folder is already a mirtverse course (course.json exists).")
  r <- toolkit_call(ctx, "new_course", list(path = ctx$root, title = args$title,
                                            instructor = args$instructor, overwrite = TRUE),
                    ctx$root, "Start course")
  paste0("Set up the course in ", ctx$root, ".\n", changed_files_text(r$files))
}

tool_list_templates <- function(args, ctx) {
  labs <- as.data.frame(list_labs())
  sec <- tryCatch(as.data.frame(toolkit_fn("lab_section_types")()), error = function(e) NULL)
  ch_fn <- toolkit_fn("book_chapters")
  ch <- if (!is.null(ch_fn)) tryCatch(as.data.frame(ch_fn()), error = function(e) NULL)
  paste0("## Built-in labs (copy_lab)\n\n", md_table(labs),
         "\n\n## Lab section types (add_lab_section)\n\n",
         if (is.null(sec)) "(unavailable)" else md_table(sec),
         if (!is.null(ch)) paste0("\n\n## Book chapters (copy_chapter)\n\n", md_table(ch)) else "")
}

tool_copy_lab <- function(args, ctx) {
  as <- args$as %||% args$name
  dest <- mcp_path(ctx, file.path("labs", as), must_exist = FALSE)
  r <- toolkit_call(ctx, "copy_lab", list(name = args$name, course = ctx$root, as = as),
                    dest, paste("Copy lab", args$name, "as", as))
  paste0("Copied the built-in lab '", args$name, "' to labs/", as, ".\n", changed_files_text(r$files))
}

tool_new_lab <- function(args, ctx) {
  dest <- mcp_path(ctx, file.path("labs", args$name), must_exist = FALSE)
  a <- list(name = args$name, data = data_arg(ctx, args$data), course = ctx$root,
            items = unlist(args$items), group = args$group, key = unlist(args$key),
            item_info = data_arg(ctx, args$item_info), scores = data_arg(ctx, args$scores),
            title = args$title, data_title = args$data_title)
  if (!is.null(args$sections)) a$sections <- unlist(args$sections)
  if (!is.null(args$story)) a$story <- args$story
  if (!is.null(args$overwrite)) a$overwrite <- isTRUE(args$overwrite)
  a <- a[!vapply(a, is.null, logical(1))]
  r <- toolkit_call(ctx, "new_lab", a, dest, paste("New lab", args$name))
  paste0("Built the lab labs/", args$name, ".\n", changed_files_text(r$files),
         "\n\nNext: lab_outline to see its sections, then check_material.")
}

tool_lab_outline <- function(args, ctx) {
  p <- lab_dir(ctx, args$lab)
  md_table(as.data.frame(toolkit_fn("lab_outline")(as.character(p))))
}

lab_change <- function(ctx, fn, args, verb) {
  p <- lab_dir(ctx, args$lab)
  a <- args; a$lab <- as.character(p)
  a <- lapply(a, function(v) if (is.list(v)) unlist(v) else v)
  r <- toolkit_call(ctx, fn, a, p, paste(verb, "in", attr(p, "rel")))
  outline <- tryCatch(md_table(as.data.frame(toolkit_fn("lab_outline")(as.character(p)))),
                      error = function(e) "")
  paste0(verb, " in ", attr(p, "rel"), ".\n", changed_files_text(r$files),
         if (nzchar(outline)) paste0("\n\nOutline now:\n\n", outline) else "")
}

tool_add_lab_section <- function(args, ctx) lab_change(ctx, "add_lab_section", args, "Added a section")
tool_add_lab_exercise <- function(args, ctx) lab_change(ctx, "add_lab_exercise", args, "Added an exercise")
tool_add_lab_question <- function(args, ctx) lab_change(ctx, "add_lab_question", args, "Added a question")
tool_remove_lab_section <- function(args, ctx) lab_change(ctx, "remove_lab_section", args, "Removed a section")

tool_swap_lab_data <- function(args, ctx) {
  p <- lab_dir(ctx, args$lab)
  a <- list(lab = as.character(p), data = data_arg(ctx, args$data), items = unlist(args$items),
            group = args$group, key = unlist(args$key), item_info = data_arg(ctx, args$item_info),
            scores = data_arg(ctx, args$scores), data_title = args$data_title)
  a <- a[!vapply(a, is.null, logical(1))]
  r <- toolkit_call(ctx, "swap_lab_data", a, p, paste("Swap data in", attr(p, "rel")))
  paste0("Replaced the data of ", attr(p, "rel"), ".\n", changed_files_text(r$files),
         "\n\nRun check_material on the lab to confirm every exercise still passes.")
}

tool_copy_chapter <- function(args, ctx) {
  dest <- mcp_path(ctx, "chapters", must_exist = FALSE)
  a <- list(id = args$id, course = ctx$root, from = args$from, overwrite = args$overwrite)
  a <- a[!vapply(a, is.null, logical(1))]
  r <- toolkit_call(ctx, "copy_chapter", a, dest, paste("Copy chapter", args$id))
  paste0("Copied chapter '", args$id, "'.\n", changed_files_text(r$files))
}

tool_new_chapter <- function(args, ctx) {
  dest <- mcp_path(ctx, "chapters", must_exist = FALSE)
  a <- list(id = args$id, course = ctx$root, title = args$title, data_code = args$data_code,
            overwrite = args$overwrite)
  a <- a[!vapply(a, is.null, logical(1))]
  r <- toolkit_call(ctx, "new_chapter", a, dest, paste("New chapter", args$id))
  paste0("Created chapter '", args$id, "'.\n", changed_files_text(r$files))
}

tool_swap_chapter_data <- function(args, ctx) {
  p <- mcp_path(ctx, args$chapter)
  r <- toolkit_call(ctx, "swap_chapter_data",
                    list(chapter = as.character(p), chunk = args$chunk, code = args$code),
                    p, paste("Swap data in", attr(p, "rel")))
  paste0("Replaced ", if (is.null(args$chunk)) "the data chunks" else paste("chunk", args$chunk),
         " in ", attr(p, "rel"), ".\n", changed_files_text(r$files))
}

# ---------------------------------------------------------------------------
# Prompts and resources

mcp_prompts <- function() {
  list(
    list(name = "revise_material", title = "Revise a teaching material",
         description = "Change a lab, chapter or notes by describing what you want.",
         arguments = list(
           list(name = "path", description = "The material to revise (relative to the course folder).", required = TRUE),
           list(name = "request", description = "What to add, remove or change.", required = TRUE)),
         text = function(a) paste0(
           "Revise my mirtverse teaching material `", a$path, "`.\n\nWhat I want: ", a$request, "\n\n",
           "Please: (1) call guide('workflow') and the style guide for this kind of material; ",
           "(2) read the material (lab_outline first if it is a lab); (3) tell me briefly what you plan to change; ",
           "(4) make the change with the lab tools or edit_material, looking up any mirtverse function you use with mirtverse_help; ",
           "(5) run check_material and fix any failure; (6) summarize what changed and remind me that undo_last_change reverts it.")),
    list(name = "adapt_material", title = "Adapt my materials to mirtverse",
         description = "Convert existing lecture notes, labs or scripts (for example ltm, eRm, TAM or plain mirt code) into mirtverse materials.",
         arguments = list(
           list(name = "path", description = "The existing material (relative to the course folder).", required = TRUE),
           list(name = "goal", description = "Optional: what the adapted version should be (lab, chapter, notes) and anything to keep.", required = FALSE)),
         text = function(a) paste0(
           "Adapt my existing material `", a$path, "` to mirtverse.",
           if (!is.null(a$goal) && nzchar(a$goal)) paste0("\n\nGoal: ", a$goal) else "", "\n\n",
           "Please: (1) call guide('adapting'); (2) read the material and run scan_material on it; ",
           "(3) propose a plan: what stays, what changes, which code translate_code converts, and where the result will be saved ",
           "(never overwrite my original; write a new file unless I say otherwise); (4) write the adapted version; ",
           "(5) run check_material and fix failures; (6) list what you changed and anything I should review by hand.")),
    list(name = "lab_from_my_data", title = "Build a lab on my data",
         description = "Create a new lab, or retarget a built-in one, using your own dataset.",
         arguments = list(
           list(name = "data", description = "Your data file (relative to the course folder).", required = TRUE),
           list(name = "topic", description = "What the lab should teach, or which built-in lab to start from.", required = FALSE)),
         text = function(a) paste0(
           "Build a mirtverse lab on my data `", a$data, "`",
           if (!is.null(a$topic) && nzchar(a$topic)) paste0(" about: ", a$topic) else "", ".\n\n",
           "Please: (1) call describe_dataset and tell me which columns you take as items, groups and IDs; ",
           "(2) call guide('lab-style') and list_templates; (3) build it with new_lab (or copy_lab then swap_lab_data); ",
           "(4) tailor the story and questions to my data; (5) run check_material until every exercise passes; ",
           "(6) tell me how to preview it.")),
    list(name = "ai_material", title = "Teach AI in measurement",
         description = "Add AI in measurement to a course: A lab on your own item text, item families or machine scores, a built-in AI lab, or an AI chapter of the book.",
         arguments = list(
           list(name = "goal", description = "What students should learn, e.g. 'audit our essay-scoring engine' or 'predict item difficulty from our item text'.", required = TRUE),
           list(name = "data", description = "Optional: Your data files (relative to the course folder), such as responses, item text or machine scores.", required = FALSE)),
         text = function(a) paste0(
           "Help me teach AI in measurement in my mirtverse course. Goal: ", a$goal, ".",
           if (!is.null(a$data) && nzchar(a$data)) paste0("\n\nMy data: ", a$data, ".") else "", "\n\n",
           "Please: (1) call guide('ai-content') and guide('workflow'); (2) call list_templates and propose the best fit: ",
           "a toolkit lab with the AI section types on my data, a copy of a built-in AI lab, or a copy of an AI book chapter, ",
           "and say which columns you would use (describe_dataset on each file); (3) build it; ",
           "(4) run check_material until every exercise passes; (5) tell me what the material teaches, what students decide at the end, ",
           "and what I should check by hand, such as whether the story fits my students.")))
}

mcp_prompt_list <- function() {
  lapply(mcp_prompts(), function(p) p[c("name", "title", "description", "arguments")])
}

mcp_get_prompt <- function(params) {
  p <- Filter(function(x) identical(x$name, params$name), mcp_prompts())
  if (!length(p)) stop("Unknown prompt: ", params$name, call. = FALSE)
  p <- p[[1]]
  a <- params$arguments %||% list()
  for (arg in p$arguments) if (isTRUE(arg$required) && is.null(a[[arg$name]]))
    stop("Missing prompt argument: ", arg$name, call. = FALSE)
  list(description = p$description,
       messages = list(list(role = "user", content = list(type = "text", text = p$text(a)))))
}

mcp_guide_topics <- c(workflow = "How to handle an instructor's request",
                      `lab-style` = "Conventions of mirtverse learnr labs",
                      `chapter-style` = "Conventions of book chapters and lecture notes",
                      adapting = "Adapting existing materials to mirtverse",
                      `ai-content` = "Teaching AI in measurement with mirtverse")

mcp_resource_list <- function() {
  lapply(names(mcp_guide_topics), function(t)
    list(uri = paste0("mirtverse://guide/", t), name = t, title = mcp_guide_topics[[t]],
         mimeType = "text/markdown"))
}

mcp_read_resource <- function(params) {
  uri <- params$uri %||% ""
  topic <- sub("^mirtverse://guide/", "", uri)
  if (!topic %in% names(mcp_guide_topics)) stop("Unknown resource: ", uri, call. = FALSE)
  list(contents = list(list(uri = uri, mimeType = "text/markdown", text = guide_text(topic))))
}
