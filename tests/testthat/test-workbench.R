test_that("workbench app builds and its server runs the main path", {
  skip_if_not_installed("shiny")
  app <- workbench_app()
  expect_s3_class(app, "shiny.appobj")
  shiny::testServer(workbench_server(), {
    session$setInputs(source = "example", example = names(example_datasets())[1],
                      items = paste0("Item.", 1:5), key = "", missing = "",
                      mode = "manual", itemtype = "2PL", nfact = 1, score_method = "EAP")
    expect_equal(ncol(resp()$data), 5)
    session$setInputs(fit = 1)
    expect_s4_class(rv$model, "SingleGroupClass")
    expect_match(paste(script(), collapse = "\n"), "mirt\\(data, 1, itemtype = \"2PL\"\\)")
    expect_equal(nrow(scores()), 1000)
  })
})

test_that("the pipeline tab runs the gates and records decisions", {
  skip_if_not_installed("shiny")
  shiny::testServer(workbench_server(), {
    session$setInputs(source = "example", example = names(example_datasets())[3],
                      items = names(mirt::SAT12), key = "", missing = "",
                      pipe_title = "SAT12", pipe_model = "2PL", pipe_strict = FALSE,
                      pipe_all = FALSE, pipe_note = "")
    session$setInputs(pipe_run = 1)
    expect_s3_class(rv$pipe, "mv_pipeline")
    expect_equal(rv$pipe$stages$status[rv$pipe$stages$stage == "calibration"], "done")
    expect_null(rv$pipe_msg$error)
    tab <- pipe_tab()
    expect_true(nrow(tab) > 0)
    code <- paste(pipe_code(), collapse = "\n")
    expect_match(code, "key2binary")
    expect_match(code, "calibrate\\(p, model = \"2PL\"\\)")

    # a decision on the first open flag
    first <- tab$id[1]
    session$setInputs(pipe_flags_rows_selected = 1, pipe_note = "Checked")
    if (tab$level[1] == "block") session$setInputs(pipe_override = 1) else
      session$setInputs(pipe_ack = 1)
    expect_true(rv$pipe$flags$status[rv$pipe$flags$id == first] %in% c("acknowledged", "overridden"))
    expect_match(paste(pipe_code(), collapse = "\n"), "note = \"Checked\"")

    # nothing selected gives a message, not an error
    session$setInputs(pipe_flags_rows_selected = NULL, pipe_ack = 2)
    expect_match(rv$pipe_msg$error, "Select one or more flags")

    # drop an item, then recalibrate
    open_tab <- pipe_tab()
    item <- open_tab$target[open_tab$target %in% names(rv$pipe$data$responses)][1]
    if (!is.na(item)) {
      row <- match(item, open_tab$target)
      session$setInputs(pipe_flags_rows_selected = row, pipe_drop = 1)
      expect_false(item %in% names(rv$pipe$data$responses))
      session$setInputs(pipe_recal = 1)
      expect_equal(rv$pipe$stages$status[rv$pipe$stages$stage == "calibration"], "done")
    }
    expect_s3_class(wb_stage_table(rv$pipe), "shiny.tag")
  })
})

test_that("pipeline steps keep warnings and errors", {
  r <- mirtverse:::wb_pipe_eval(quote(warning("careful")), list())
  expect_equal(r$warnings, "careful")
  r <- mirtverse:::wb_pipe_eval(quote(stop("no")), list())
  expect_equal(r$error, "no")
  expect_null(r$value)
})

test_that("helpers parse inputs", {
  expect_equal(mirtverse:::parse_num_list("1, 2;3"), c(1, 2, 3))
  expect_equal(mirtverse:::parse_num_list(""), numeric())
  expect_match(mirtverse:::read_code("x.xlsx"), "read_excel")
})
