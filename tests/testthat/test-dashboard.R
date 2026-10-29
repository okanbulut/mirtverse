test_that("dashboard data hold summaries but no responses", {
  d <- mirtverse:::dashboard_data(mod_grm, panels = c("summary", "items", "curves", "information",
                                                      "wright", "scores"))
  expect_s3_class(d, "mv_dashboard")
  expect_equal(d$panels, c("summary", "items", "curves", "information", "wright", "scores"))
  expect_equal(nrow(d$items), 4)
  expect_length(d$cards, 4)
  expect_match(d$cards[[1]], "^data:image/png;base64,")
  expect_null(d$persons)
  expect_false(any(vapply(d, function(el) inherits(el, "SingleGroupClass"), logical(1))))
  expect_output(print(d), "Item curves")
})

test_that("persons panel needs matching ids and DIF/RT panels need results", {
  d <- mirtverse:::dashboard_data(mod_2pl, panels = c("summary", "persons"), ids = paste0("p", 1:1000))
  expect_equal(nrow(d$persons), 1000)
  expect_equal(d$persons$id[1], "p1")
  expect_error(mirtverse:::dashboard_data(mod_2pl, panels = "persons", ids = 1:3), "ids")
  expect_error(mirtverse:::dashboard_data(mod_2pl, panels = "dif"), "dif\\(\\)")
  expect_error(mirtverse:::dashboard_data(mod_2pl, panels = "nope"), "Unknown panel")
})

test_that("multidimensional models keep only the panels that apply", {
  mod2 <- mirt(lsat, 2, verbose = FALSE)
  expect_message(d <- mirtverse:::dashboard_data(mod2), "unidimensional")
  expect_equal(d$panels, c("summary", "items"))
  expect_null(d$cards)
})

test_that("dashboard app builds and its server renders", {
  app <- mv_dashboard(mod_2pl, cards = FALSE)
  expect_s3_class(app, "shiny.appobj")
  d <- attr(app, "mv_dashboard")
  shiny::testServer(mirtverse:::dashboard_server(d), {
    session$setInputs(dash_curve_items = c("Item.1", "Item.2"), dash_curve_type = "prob",
                      dash_theta = 0.5, dash_info_items = "Item.1", dash_items_rows_selected = 2)
    expect_equal(nrow(curves()), 2 * 2 * 121)
    expect_type(output$dash_curves, "list")
    expect_match(output$dash_at_theta, "Expected score")
    expect_match(output$dash_glance, "Respondents")
  })
})

test_that("export_dashboard writes a deployable folder", {
  dir <- file.path(tempdir(), "dash-test")
  on.exit(unlink(dir, recursive = TRUE))
  export_dashboard(mod_2pl, dir, title = "LSAT", cards = FALSE,
                   panels = c("summary", "items", "persons"))
  expect_setequal(list.files(dir), c("app.R", "dashboard.rds"))
  expect_match(paste(readLines(file.path(dir, "app.R")), collapse = "\n"), "mv_dashboard\\(readRDS")
  expect_error(export_dashboard(mod_2pl, dir), "overwrite")
  d <- readRDS(file.path(dir, "dashboard.rds"))
  expect_equal(d$meta$title, "LSAT")
  expect_s3_class(mv_dashboard(d), "shiny.appobj")
  expect_message(export_dashboard(mv_dashboard(d), dir, overwrite = TRUE), "person scores")
})
