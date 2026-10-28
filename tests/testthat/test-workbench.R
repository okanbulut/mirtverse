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

test_that("helpers parse inputs", {
  expect_equal(mirtverse:::parse_num_list("1, 2;3"), c(1, 2, 3))
  expect_equal(mirtverse:::parse_num_list(""), numeric())
  expect_match(mirtverse:::read_code("x.xlsx"), "read_excel")
})
