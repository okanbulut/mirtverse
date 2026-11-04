agent_project_dir <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  set.seed(11)
  d <- mirt::expand.table(mirt::LSAT7)
  d <- cbind(id = seq_len(nrow(d)), grp = sample(c("A", "B"), nrow(d), TRUE), d)
  d$Item.5[1:3] <- 9
  utils::write.csv(d, file.path(dir, "exam.csv"), row.names = FALSE)
  dir
}

agent_call <- function(.ctx, .tool, ...) {
  res <- mcp_dispatch(list(jsonrpc = "2.0", id = 1, method = "tools/call",
                           params = list(name = .tool, arguments = list(...))), .ctx)
  res$result
}
agent_text <- function(res) res$content[[1]]$text

test_that("analysis mode lists its own tools, prompts and guides", {
  ctx <- mcp_context(agent_project_dir(), mode = "analysis")
  tools <- vapply(mcp_tool_list(ctx), `[[`, "", "name")
  expect_true(all(c("project_overview", "fit_model", "check_items", "check_dif", "score_people",
                    "plot_model", "interpret_model", "write_report", "save_script", "run_r",
                    "describe_dataset", "mirtverse_help", "guide") %in% tools))
  expect_false(any(c("edit_material", "copy_lab", "course_overview") %in% tools))
  expect_false(anyDuplicated(tools) > 0)
  # the course server is unchanged
  course <- vapply(mcp_tool_list(mcp_context(withr::local_tempdir())), `[[`, "", "name")
  expect_false(any(c("fit_model", "run_r") %in% course))
  expect_true("course_overview" %in% course)

  init <- mcp_dispatch(list(jsonrpc = "2.0", id = 1, method = "initialize", params = list()), ctx)
  expect_match(init$result$serverInfo$title, "analysis")
  expect_match(init$result$instructions, "project_overview")
  prompts <- vapply(mcp_dispatch(list(jsonrpc = "2.0", id = 1, method = "prompts/list"),
                                 ctx)$result$prompts, `[[`, "", "name")
  expect_setequal(prompts, c("analyze_test", "check_fairness", "write_report"))
  p <- mcp_dispatch(list(jsonrpc = "2.0", id = 1, method = "prompts/get",
                         params = list(name = "analyze_test", arguments = list(data = "exam.csv"))), ctx)
  expect_match(p$result$messages[[1]]$content$text, "exam.csv")
  res <- mcp_dispatch(list(jsonrpc = "2.0", id = 1, method = "resources/list"), ctx)$result$resources
  expect_setequal(vapply(res, `[[`, "", "name"), names(agent_guide_topics))
  for (t in names(agent_guide_topics)) expect_gt(nchar(guide_text(t)), 500)
  expect_match(agent_text(agent_call(ctx, "guide", topic = "interpreting")), "DIF")
})

test_that("a full analysis runs through the tools and its script reproduces it", {
  skip_on_cran()
  dir <- agent_project_dir()
  ctx <- mcp_context(dir, mode = "analysis")
  expect_match(agent_text(agent_call(ctx, "project_overview")), "exam.csv")
  expect_true(agent_call(ctx, "check_items")$isError)

  res <- agent_call(ctx, "fit_model", data = "exam.csv", model = "2PL", missing = list(9))
  expect_false(res$isError)
  txt <- agent_text(res)
  expect_match(txt, "Fitted model 'model'")
  expect_match(txt, "5 items")   # id and grp are not taken as items
  rec <- get("model", envir = ctx$models)
  expect_equal(rec$item_cols, paste0("Item.", 1:5))
  expect_equal(sum(is.na(rec$items_df$Item.5)), 3)
  expect_true(file.exists(file.path(dir, ".mirtverse-mcp", "models", "model.rds")))

  expect_match(agent_text(agent_call(ctx, "check_items")), "Item.1")
  dif <- agent_call(ctx, "check_dif", group = "grp")
  expect_false(dif$isError)
  expect_match(agent_text(dif), "Group sizes")
  expect_true(agent_call(ctx, "check_dif", group = "nope")$isError)

  sc <- agent_call(ctx, "score_people")
  expect_match(agent_text(sc), "model-scores.csv")
  scores <- utils::read.csv(file.path(dir, "mirtverse-output", "model-scores.csv"))
  expect_equal(nrow(scores), 1000)
  expect_true(all(c("id", "F1", "SE_F1") %in% names(scores)))

  pl <- agent_call(ctx, "plot_model", type = "test_info")
  expect_false(pl$isError)
  expect_equal(pl$content[[2]]$type, "image")
  expect_gt(nchar(pl$content[[2]]$data), 1000)
  expect_true(file.exists(file.path(dir, "mirtverse-output", "plots", "model-test_info.png")))

  expect_match(agent_text(agent_call(ctx, "interpret_model")), "DIF across grp")
  rep <- agent_call(ctx, "write_report", title = "Test report")
  expect_false(rep$isError)
  expect_true(file.exists(file.path(dir, "mirtverse-output", "model-report.html")))

  rr <- agent_call(ctx, "run_r", code = "nrow(model_items)\nsum(model_data$grp == 'A')")
  expect_match(agent_text(rr), "1000")

  sv <- agent_call(ctx, "save_script")
  script <- file.path(dir, "mirtverse-output", "analysis.R")
  expect_true(file.exists(script))
  code <- readLines(script)
  expect_true(any(grepl("model <- mirt(model_items, 1, itemtype = \"2PL\")", code, fixed = TRUE)))
  expect_true(any(grepl("model_items[model_items == 9] <- NA", code, fixed = TRUE)))

  # the saved script reruns on its own
  env <- new.env(parent = globalenv())
  withr::with_dir(dir, suppressMessages(sys.source(script, envir = env)))
  expect_equal(mirt::coef(env$model, simplify = TRUE)$items,
               mirt::coef(rec$fit, simplify = TRUE)$items, tolerance = 1e-4)

  # a new session finds the saved model
  ctx2 <- mcp_context(dir, mode = "analysis")
  expect_match(agent_text(agent_call(ctx2, "project_overview")), "saved")
  expect_false(agent_call(ctx2, "check_items", model = "model")$isError)
})

test_that("answer keys, dataset names and auto model choice work", {
  skip_on_cran()
  ctx <- mcp_context(withr::local_tempdir(), mode = "analysis")
  key <- c(1, 4, 5, 2, 3, 1, 2, 1, 3, 1, 2, 4, 2, 1, 5, 3, 4, 4, 1, 4, 3, 3, 4, 1, 3, 5, 1, 3,
           1, 5, 4, 5)
  res <- agent_call(ctx, "fit_model", data = "SAT12", key = as.list(key), missing = list(8),
                    model = "Rasch", name = "sat")
  expect_false(res$isError)
  expect_match(agent_text(res), "32 items")
  expect_true(any(grepl("key2binary(sat_items, key = c(1, 4, 5", ctx$script, fixed = TRUE)))
  # unscored letters are not taken as items without a key
  utils::write.csv(data.frame(id = 1:5, q1 = c("A", "B", "A", "C", "A"), q2 = c(1, 0, 1, 1, 0)),
                   file.path(ctx$root, "letters.csv"), row.names = FALSE)
  expect_match(agent_text(agent_call(ctx, "fit_model", data = "letters.csv")), "Could not find item columns")
  sci <- agent_call(ctx, "fit_model", data = "Science", name = "sci")
  expect_match(agent_text(sci), "Model comparison")
  expect_false(is.null(get("sci", envir = ctx$models)$selection))
})

test_that("run_r is off when allow_run is FALSE and paths stay in the project", {
  ctx <- mcp_context(agent_project_dir(), mode = "analysis", allow_run = FALSE)
  res <- agent_call(ctx, "run_r", code = "1 + 1")
  expect_true(res$isError)
  expect_match(agent_text(res), "turned off")
  expect_true(agent_call(ctx, "describe_dataset", source = "../exam.csv")$isError)
  expect_match(agent_text(agent_call(ctx, "describe_dataset", source = "nope.csv")), "project folder")
})

test_that("agent_project and mv_agent_init set up a folder", {
  withr::local_envvar(MIRTVERSE_PROJECT = "${CLAUDE_PROJECT_DIR}")
  expect_equal(agent_project(), getwd())
  withr::local_envvar(MIRTVERSE_PROJECT = "/some/where")
  expect_equal(agent_project(), "/some/where")
  expect_equal(agent_project("x"), "x")

  dir <- file.path(withr::local_tempdir(), "proj")
  expect_message(files <- mv_agent_init(dir, title = "Math test"), "CLAUDE.md")
  expect_setequal(basename(files), c("CLAUDE.md", ".mcp.json"))
  expect_equal(readLines(file.path(dir, "CLAUDE.md"))[1], "# Math test")
  cfg <- jsonlite::read_json(file.path(dir, ".mcp.json"))
  expect_equal(cfg$mcpServers$mirtverse$args[[2]], "mirtverse::mv_agent_server()")
  expect_equal(cfg$mcpServers$mirtverse$env$MIRTVERSE_PROJECT,
               normalizePath(dir, winslash = "/"))
  expect_true(dir.exists(file.path(dir, "mirtverse-output")))
  expect_message(again <- mv_agent_init(dir), "already exists")
  expect_length(again, 0)

  txt <- utils::capture.output(mv_mcp_config(dir, client = "claude-code", mode = "analysis"))
  expect_true(any(grepl("mv_agent_server", txt)))
})

test_that("the plugin files are consistent with the server", {
  root <- testthat::test_path("..", "..")
  plugin <- file.path(root, "claude-plugin")
  skip_if_not(dir.exists(plugin))  # not in the built package
  mcp <- jsonlite::read_json(file.path(plugin, ".mcp.json"))
  # the directory validator only follows literal paths under the plugin root
  expect_equal(mcp$mcpServers$mirtverse$command, "Rscript")
  expect_equal(unlist(mcp$mcpServers$mirtverse$args), "${CLAUDE_PLUGIN_ROOT}/server/mirtverse-server.R")
  expect_null(mcp$mcpServers$mirtverse$env)
  script <- file.path(plugin, "server", "mirtverse-server.R")
  expect_true(any(grepl("mirtverse::mv_agent_server()", readLines(script), fixed = TRUE)))
  manifest <- jsonlite::read_json(file.path(plugin, ".claude-plugin", "plugin.json"))
  expect_equal(manifest$name, "mirtverse")
  tools <- vapply(agent_tools(), `[[`, "", "name")
  for (f in list.files(file.path(plugin, "skills"), "SKILL.md", recursive = TRUE, full.names = TRUE)) {
    txt <- paste(readLines(f), collapse = "\n")
    expect_match(txt, "^---\nname: ", info = f)
    used <- unique(regmatches(txt, gregexpr("`[a-z_]+`", txt))[[1]])
    used <- gsub("`", "", used)
    # every snake_case tool-like name in a skill is a real tool or an argument
    unknown <- setdiff(used[grepl("^[a-z]+_[a-z_]+$", used)],
                       c(tools, "describe_dataset", "mirtverse_help", "test_info", "p_adjust"))
    expect_length(unknown, 0)
  }
})
