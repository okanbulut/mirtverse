mcp_course <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  dir.create(file.path(dir, "notes"))
  writeLines(c("---", "title: \"Rasch with ltm\"", "---", "", "Some text about LSAT data.", "",
               "```{r fit}", "library(ltm)", "fit <- rasch(LSAT)", "factor.scores(fit)", "```", "",
               "```{r m}", "m <- mirt(LSAT7, 1)", "coef(m, IRTpars = TRUE, simplify = TRUE)", "```"),
             file.path(dir, "notes", "ltm-notes.Rmd"))
  utils::write.csv(data.frame(id = 1:6, grp = rep(c("north", "south"), 3),
                              i1 = c(0, 1, 1, 0, 1, 1), i2 = c(1, 1, 0, 0, 1, NA)),
                   file.path(dir, "exam.csv"), row.names = FALSE)
  mcp_context(dir)
}

call_tool <- function(.ctx, .tool, ...) {
  res <- mcp_dispatch(list(jsonrpc = "2.0", id = 1, method = "tools/call",
                           params = list(name = .tool, arguments = list(...))), .ctx)
  res$result
}
tool_text <- function(res) res$content[[1]]$text

test_that("initialize negotiates the protocol version", {
  ctx <- mcp_course()
  r <- mcp_dispatch(list(jsonrpc = "2.0", id = 1, method = "initialize",
                         params = list(protocolVersion = "2025-03-26")), ctx)
  expect_equal(r$result$protocolVersion, "2025-03-26")
  expect_equal(r$result$serverInfo$name, "mirtverse")
  r <- mcp_dispatch(list(jsonrpc = "2.0", id = 2, method = "initialize",
                         params = list(protocolVersion = "1999-01-01")), ctx)
  expect_equal(r$result$protocolVersion, mcp_protocol_versions[1])
  expect_null(mcp_dispatch(list(jsonrpc = "2.0", method = "notifications/initialized"), ctx))
  r <- mcp_dispatch(list(jsonrpc = "2.0", id = 3, method = "no/such"), ctx)
  expect_equal(r$error$code, -32601)
  expect_equal(mcp_handle_text("{not json", ctx)$error$code, -32700)
})

test_that("tools/list hides toolkit tools until the toolkit exists", {
  ctx <- mcp_course()
  names_of <- function() vapply(mcp_dispatch(list(jsonrpc = "2.0", id = 1, method = "tools/list"),
                                             ctx)$result$tools, `[[`, "", "name")
  core <- c("course_overview", "read_material", "write_material", "edit_material",
            "undo_last_change", "describe_dataset", "mirtverse_help", "guide",
            "scan_material", "translate_code", "check_material")
  local_mocked_bindings(toolkit_fn = function(name) NULL)
  expect_true(all(core %in% names_of()))
  expect_false("copy_lab" %in% names_of())
  local_mocked_bindings(toolkit_fn = function(name) function(...) NULL)
  expect_true(all(c("copy_lab", "swap_lab_data", "add_lab_exercise") %in% names_of()))
  tools <- mcp_tool_list(ctx)
  expect_true(all(vapply(tools, function(t) identical(t$inputSchema$type, "object"), logical(1))))
  r <- mcp_dispatch(list(jsonrpc = "2.0", id = 1, method = "tools/call",
                         params = list(name = "nope")), ctx)
  expect_equal(r$error$code, -32602)
})

test_that("paths are confined to the course folder", {
  ctx <- mcp_course()
  for (p in c("../x.Rmd", "/etc/passwd", "notes/../../x", ".mirtverse-mcp/journal.json")) {
    res <- call_tool(ctx, "read_material", path = p)
    expect_true(res$isError, info = p)
  }
  expect_match(tool_text(call_tool(ctx, "read_material", path = "missing.Rmd")), "No file")
})

test_that("read, write, edit and undo work together", {
  ctx <- mcp_course()
  r <- call_tool(ctx, "read_material", path = "notes/ltm-notes.Rmd", from_line = 5, to_line = 5)
  expect_match(tool_text(r), "5  Some text about LSAT data.", fixed = TRUE)

  r <- call_tool(ctx, "edit_material", path = "notes/ltm-notes.Rmd",
                 old_text = "LSAT data", new_text = "LSAT section 7 data")
  expect_false(r$isError)
  expect_match(tool_text(r), "+Some text about LSAT section 7 data.", fixed = TRUE)
  f <- file.path(ctx$root, "notes", "ltm-notes.Rmd")
  expect_true(any(grepl("section 7", readLines(f))))

  r <- call_tool(ctx, "edit_material", path = "notes/ltm-notes.Rmd", old_text = "nothing like this",
                 new_text = "x")
  expect_true(r$isError)
  r <- call_tool(ctx, "edit_material", path = "notes/ltm-notes.Rmd", old_text = "```", new_text = "~~~")
  expect_match(tool_text(r), "occurs 4 times")
  r <- call_tool(ctx, "edit_material", path = "notes/ltm-notes.Rmd", old_text = "",
                 new_text = "Inserted line", insert_at_line = 4)
  expect_equal(readLines(f)[4], "Inserted line")

  r <- call_tool(ctx, "write_material", path = "new/dir/script.R", content = "x <- 1\ny <- 2\n")
  expect_match(tool_text(r), "Created new/dir/script.R")
  expect_equal(readLines(file.path(ctx$root, "new/dir/script.R")), c("x <- 1", "y <- 2"))

  expect_match(tool_text(call_tool(ctx, "undo_last_change")), "removed")
  expect_false(dir.exists(file.path(ctx$root, "new")))
  call_tool(ctx, "undo_last_change", path = "notes/ltm-notes.Rmd")
  call_tool(ctx, "undo_last_change", path = "notes/ltm-notes.Rmd")
  expect_false(any(grepl("section 7|Inserted", readLines(f))))
  expect_match(tool_text(call_tool(ctx, "undo_last_change")), "no changes")
})

test_that("course overview and materials list the files", {
  ctx <- mcp_course()
  txt <- tool_text(call_tool(ctx, "course_overview"))
  expect_match(txt, "notes/ltm-notes.Rmd")
  expect_match(txt, "model-choice")
  r <- call_tool(ctx, "list_materials", kind = "data")
  expect_match(tool_text(r), "exam.csv")
  expect_false(grepl("ltm-notes", tool_text(r)))
  expect_equal(doc_title(file.path(ctx$root, "notes", "ltm-notes.Rmd")), "Rasch with ltm")
})

test_that("describe_dataset reads course files and bundled data", {
  ctx <- mcp_course()
  r <- call_tool(ctx, "describe_dataset", source = "exam.csv")
  expect_equal(r$structuredContent$items, c("i1", "i2"))
  expect_equal(r$structuredContent$groups, "grp")
  r <- call_tool(ctx, "describe_dataset", source = "certexam")
  expect_length(r$structuredContent$items, 32L)
  expect_match(tool_text(r), "more item columns")
  expect_true(call_tool(ctx, "describe_dataset", source = "no_such_data")$isError)
})

test_that("scan_material and translate_code help adapt old code", {
  ctx <- mcp_course()
  txt <- tool_text(call_tool(ctx, "scan_material", path = "notes/ltm-notes.Rmd"))
  expect_match(txt, "uses ltm")
  expect_match(txt, "ltm::rasch")
  expect_match(txt, "tidy(model)", fixed = TRUE)
  txt <- tool_text(call_tool(ctx, "translate_code", code = "library(ltm)\nfit <- rasch(LSAT)"))
  expect_match(txt, "mirt(LSAT", fixed = TRUE)
  txt <- tool_text(call_tool(ctx, "translate_code", path = "notes/ltm-notes.Rmd"))
  expect_match(txt, "library(mirtverse)", fixed = TRUE)
})

test_that("help and guides are available", {
  ctx <- mcp_course()
  expect_match(tool_text(call_tool(ctx, "mirtverse_help")), "gg_trace")
  expect_match(tool_text(call_tool(ctx, "mirtverse_help", topic = "gg_trace")), "which.items")
  expect_match(tool_text(call_tool(ctx, "mirtverse_help", search = "differential item")), "dif")
  expect_true(call_tool(ctx, "mirtverse_help", topic = "not_a_function")$isError)
  for (t in names(mcp_guide_topics))
    expect_gt(nchar(tool_text(call_tool(ctx, "guide", topic = t))), 500)
  r <- mcp_dispatch(list(jsonrpc = "2.0", id = 1, method = "resources/read",
                         params = list(uri = "mirtverse://guide/lab-style")), ctx)
  expect_match(r$result$contents[[1]]$text, "lab_need")
})

test_that("prompts render with their arguments", {
  ctx <- mcp_course()
  r <- mcp_dispatch(list(jsonrpc = "2.0", id = 1, method = "prompts/list"), ctx)
  expect_setequal(vapply(r$result$prompts, `[[`, "", "name"),
                  c("revise_material", "adapt_material", "lab_from_my_data"))
  r <- mcp_dispatch(list(jsonrpc = "2.0", id = 1, method = "prompts/get",
                         params = list(name = "adapt_material", arguments = list(path = "notes/a.Rmd"))), ctx)
  expect_match(r$result$messages[[1]]$content$text, "notes/a.Rmd")
  r <- mcp_dispatch(list(jsonrpc = "2.0", id = 1, method = "prompts/get",
                         params = list(name = "revise_material", arguments = list(path = "x"))), ctx)
  expect_match(r$error$message, "request")
})

test_that("the basic check finds parse errors", {
  ctx <- mcp_course()
  bad <- file.path(ctx$root, "bad.R")
  writeLines(c("x <- 1 +"), bad)
  res <- mcp_basic_check(bad)
  expect_equal(res$status, "error")
  res <- mcp_basic_check(file.path(ctx$root, "notes", "ltm-notes.Rmd"))
  expect_equal(res$status, c("ok", "ok"))
})

test_that("check_material refuses to run code when running is off", {
  ctx <- mcp_course()
  ctx$allow_run <- FALSE
  r <- call_tool(ctx, "check_material", path = "notes/ltm-notes.Rmd")
  expect_true(r$isError)
  expect_match(tool_text(r), "allow_run")
})

test_that("check_material runs in a separate R process", {
  skip_on_cran()
  skip_if_not(exists("mcp_basic_check", envir = asNamespace("mirtverse")) &&
                nzchar(system.file(package = "mirtverse")))
  ctx <- mcp_course()
  ctx$timeout <- 120
  writeLines("x <- (1 + ", file.path(ctx$root, "bad.R"))
  r <- call_tool(ctx, "check_material", path = "bad.R")
  expect_false(isTRUE(r$structuredContent$passed))
})

test_that("toolkit tools call the toolkit and can be undone", {
  ctx <- mcp_course()
  calls <- list()
  fake <- list(
    copy_lab = function(name, course, as) {
      calls$copy_lab <<- list(name = name, as = as)
      d <- file.path(course, "labs", as)
      dir.create(d, recursive = TRUE)
      writeLines("lab", file.path(d, paste0(as, ".Rmd")))
      invisible(d)
    },
    swap_lab_data = function(lab, data, items = NULL, group = NULL, key = NULL, data_title = NULL) {
      calls$swap <<- list(lab = lab, data = data, items = items)
      writeLines("new data", file.path(lab, "data.txt"))
      invisible(lab)
    },
    lab_outline = function(lab) data.frame(id = "s1", type = "intro", title = "Intro"),
    add_lab_question = function(lab, question, answers, correct, messages = NULL, title = NULL, after = NULL, id = NULL) {
      calls$question <<- list(answers = answers, correct = correct)
      cat("Q:", question, "\n", file = file.path(lab, basename(paste0(basename(lab), ".Rmd"))),
          append = TRUE)
      invisible(lab)
    })
  local_mocked_bindings(toolkit_fn = function(name) fake[[name]])

  r <- call_tool(ctx, "copy_lab", name = "fairness", as = "my-fairness")
  expect_false(r$isError)
  expect_equal(calls$copy_lab$as, "my-fairness")
  expect_match(tool_text(r), "labs/my-fairness/my-fairness.Rmd")

  r <- call_tool(ctx, "swap_lab_data", lab = "labs/my-fairness", data = "exam.csv",
                 items = list("i1", "i2"))
  expect_false(r$isError)
  expect_equal(calls$swap$items, c("i1", "i2"))
  expect_true(file.exists(calls$swap$data))

  r <- call_tool(ctx, "add_lab_question", lab = "labs/my-fairness", question = "Why?",
                 answers = list("A", "B"), correct = list("A"))
  expect_match(tool_text(r), "Outline now")
  expect_equal(calls$question$answers, c("A", "B"))

  call_tool(ctx, "undo_last_change")
  expect_false(any(grepl("Q: Why", readLines(file.path(ctx$root, "labs/my-fairness/my-fairness.Rmd")))))
  call_tool(ctx, "undo_last_change")
  expect_false(file.exists(file.path(ctx$root, "labs/my-fairness/data.txt")))
  call_tool(ctx, "undo_last_change")
  expect_false(dir.exists(file.path(ctx$root, "labs")))
})

test_that("the stdio transport answers line by line", {
  ctx <- mcp_course()
  input <- textConnection(c(
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18"}}',
    '{"jsonrpc":"2.0","method":"notifications/initialized"}',
    "",
    '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"guide","arguments":{"topic":"workflow"}}}'))
  out <- character()
  output <- textConnection("out", "w", local = TRUE)
  mcp_serve_stdio(ctx, input = input, output = output)
  close(output)
  expect_length(out, 2L)
  res <- lapply(out, jsonlite::fromJSON, simplifyVector = FALSE)
  expect_equal(res[[1]]$result$protocolVersion, "2025-06-18")
  expect_match(res[[2]]$result$content[[1]]$text, "Working on an instructor")
})

test_that("the HTTP handler routes by path and method", {
  ctx <- mcp_course()
  req <- function(path, method = "POST", body = "") {
    input <- list(read = function() charToRaw(body))
    list(PATH_INFO = path, REQUEST_METHOD = method, rook.input = input)
  }
  expect_equal(mcp_http_call(req("/mcp/other"), ctx, "/mcp/tok")$status, 404L)
  expect_equal(mcp_http_call(req("/mcp/tok", "GET"), ctx, "/mcp/tok")$status, 405L)
  r <- mcp_http_call(req("/mcp/tok", body = '{"jsonrpc":"2.0","id":1,"method":"ping"}'), ctx, "/mcp/tok")
  expect_equal(r$status, 200L)
  expect_equal(mcp_http_call(req("/mcp/tok", body = '{"jsonrpc":"2.0","method":"notifications/initialized"}'),
                             ctx, "/mcp/tok")$status, 202L)
})

test_that("mv_mcp_config prints client settings", {
  for (client in c("claude-desktop", "claude-code", "codex", "openai-agents", "chatgpt")) {
    txt <- NULL
    expect_output(txt <- mv_mcp_config("~/course", client = client))
    expect_match(txt, "mv_mcp_server", info = client)
  }
  txt <- utils::capture.output(x <- mv_mcp_config("~/course", "claude-desktop"))
  json <- sub("^[^{]*", "", paste(x, collapse = "\n"))
  expect_silent(jsonlite::fromJSON(json))
})

test_that("scan_material only flags calls of attached packages", {
  ctx <- mcp_course()
  writeLines(c("library(mirt)", "m <- mirt(LSAT7, 1)", "itemfit(m)",
               "f <- eRm::RM(raschdat1)", "pp <- eRm::person.parameter(f)"),
             file.path(ctx$root, "s.R"))
  txt <- tool_text(call_tool(ctx, "scan_material", path = "s.R"))
  expect_match(txt, "eRm::RM")
  expect_match(txt, "eRm::person.parameter")
  expect_match(txt, "mirt::itemfit")
  expect_false(grepl("eRm::itemfit", txt))
})
