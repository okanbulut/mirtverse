#' Launch the mirtverse workbench
#'
#' Opens a point-and-click application for a complete IRT analysis: load and
#' score data, explore items, let mirtverse pick a model or choose one
#' yourself, read the plain-language interpretation, inspect item health
#' cards and graphics, score examinees, analyse response times, and download
#' an HTML report. Every step is written into an R script you can download,
#' so the analysis is reproducible and a good way to learn the R code.
#'
#' @param data optional data frame of item responses to start with.
#' @param ... passed to [shiny::runApp()] (e.g. `launch.browser`, `port`).
#' @return Runs the app; returns nothing useful.
#' @examples
#' if (interactive()) {
#'   launch_workbench()
#'   launch_workbench(expand.table(LSAT7))
#' }
#' @export
launch_workbench <- function(data = NULL, ...) {
  shiny::runApp(workbench_app(data), ...)
}

#' @rdname launch_workbench
#' @export
workbench_app <- function(data = NULL) {
  shiny::shinyApp(workbench_ui(), workbench_server(data))
}

example_datasets <- function() {
  list(
    "LSAT7 (5 dichotomous items, N = 1000)" = list(
      data = function() mirt::expand.table(mirt::LSAT7),
      code = "data <- expand.table(LSAT7)"),
    "Science (4 polytomous items, N = 392)" = list(
      data = function() mirt::Science, code = "data <- Science"),
    "SAT12 (32 multiple-choice items, scored)" = list(
      data = function() mirt::key2binary(mirt::SAT12, key = sat12_key()),
      code = sprintf("data <- key2binary(SAT12, key = c(%s))", paste(sat12_key(), collapse = ","))),
    "Simulated with response times (20 items, N = 1000)" = list(
      data = function() sim_rt(N = 1000, J = 20, rapid = 0.08, seed = 2026)$responses,
      code = "sim <- sim_rt(N = 1000, J = 20, rapid = 0.08, seed = 2026)\ndata <- sim$responses",
      rt = function() sim_rt(N = 1000, J = 20, rapid = 0.08, seed = 2026)$rt)
  )
}

sat12_key <- function() c(1, 4, 5, 2, 3, 1, 2, 1, 3, 1, 2, 4, 2, 1, 5, 3, 4, 4, 1, 4, 3, 3,
                          4, 1, 3, 5, 1, 3, 1, 5, 4, 5)

read_any <- function(path, name) {
  ext <- tolower(tools::file_ext(name))
  switch(ext,
         csv = utils::read.csv(path, check.names = FALSE),
         tsv = , txt = utils::read.delim(path, check.names = FALSE),
         xlsx = , xls = {
           if (!requireNamespace("readxl", quietly = TRUE))
             stop("Install the readxl package to read Excel files.")
           as.data.frame(readxl::read_excel(path))
         },
         sav = , dta = , sas7bdat = {
           if (!requireNamespace("haven", quietly = TRUE))
             stop("Install the haven package to read SPSS, Stata or SAS files.")
           fn <- switch(ext, sav = haven::read_sav, dta = haven::read_dta,
                        sas7bdat = haven::read_sas)
           as.data.frame(haven::zap_labels(fn(path)))
         },
         rds = as.data.frame(readRDS(path)),
         stop("Unsupported file type: ", ext))
}

read_code <- function(name) {
  ext <- tolower(tools::file_ext(name))
  switch(ext,
         csv = sprintf("data <- read.csv(\"%s\", check.names = FALSE)", name),
         tsv = , txt = sprintf("data <- read.delim(\"%s\", check.names = FALSE)", name),
         xlsx = , xls = sprintf("data <- as.data.frame(readxl::read_excel(\"%s\"))", name),
         sav = sprintf("data <- as.data.frame(haven::zap_labels(haven::read_sav(\"%s\")))", name),
         dta = sprintf("data <- as.data.frame(haven::zap_labels(haven::read_dta(\"%s\")))", name),
         sas7bdat = sprintf("data <- as.data.frame(haven::zap_labels(haven::read_sas(\"%s\")))", name),
         rds = sprintf("data <- as.data.frame(readRDS(\"%s\"))", name))
}

wb_table <- function(df, digits = 3, page = 10) {
  df <- as.data.frame(df)
  num <- vapply(df, is.numeric, logical(1))
  df[num] <- lapply(df[num], function(v) round(v, digits))
  DT::datatable(df, rownames = FALSE, filter = "none",
                options = list(pageLength = page, scrollX = TRUE, dom = "tip"))
}

workbench_ui <- function() {
  b <- bslib::bs_theme(version = 5, primary = "#2C5F8A", secondary = "#D1495B",
                       base_font = bslib::font_collection("system-ui", "-apple-system",
                                                          "Segoe UI", "Roboto", "sans-serif"))
  card <- function(title, ...) bslib::card(bslib::card_header(title), bslib::card_body(...))
  bslib::page_navbar(
    title = "mirtverse workbench", theme = b, id = "nav", fillable = FALSE,
    bslib::nav_panel("1. Data", bslib::layout_sidebar(
      sidebar = bslib::sidebar(width = 330,
        shiny::radioButtons("source", "Data source", c("Example data" = "example",
                                                       "Upload a file" = "upload")),
        shiny::conditionalPanel("input.source == 'example'",
          shiny::selectInput("example", NULL, names(example_datasets()))),
        shiny::conditionalPanel("input.source == 'upload'",
          shiny::fileInput("file", NULL, accept = c(".csv", ".tsv", ".txt", ".xlsx",
                                                    ".xls", ".sav", ".dta", ".rds")),
          shiny::helpText("CSV, Excel, SPSS, Stata or RDS. One row per person, one column per item.")),
        shiny::selectizeInput("items", "Item columns", choices = NULL, multiple = TRUE),
        shiny::textInput("key", "Answer key (optional)",
                         placeholder = "e.g. 1,4,5,2 - scores multiple-choice items as 0/1"),
        shiny::textInput("missing", "Missing-value codes (optional)", placeholder = "e.g. 9,99")),
      card("Data preview", shiny::uiOutput("data_msg"), DT::DTOutput("preview")))),
    bslib::nav_panel("2. Explore",
      bslib::layout_columns(col_widths = c(5, 7),
        card("Test summary", shiny::tableOutput("overall"),
             shiny::plotOutput("sum_hist", height = 260)),
        card("Classical item statistics", DT::DTOutput("itemstats")))),
    bslib::nav_panel("3. Model", bslib::layout_sidebar(
      sidebar = bslib::sidebar(width = 330,
        shiny::radioButtons("mode", "How should the model be chosen?",
                            c("Compare models and recommend one" = "auto",
                              "I will choose" = "manual")),
        shiny::conditionalPanel("input.mode == 'auto'",
          shiny::checkboxInput("try2", "Also try a two-factor model", FALSE),
          shiny::selectInput("criterion", "Rank models by", c("BIC", "AIC", "SABIC"))),
        shiny::conditionalPanel("input.mode == 'manual'",
          shiny::selectInput("itemtype", "Item type",
                             c("Rasch", "2PL", "3PL", "4PL", "graded", "gpcm", "rsm", "nominal")),
          shiny::numericInput("nfact", "Number of dimensions", 1, min = 1, max = 5)),
        shiny::actionButton("fit", "Fit model", class = "btn-primary w-100")),
      shiny::uiOutput("fit_msg"),
      card("Model summary", shiny::tableOutput("glance")),
      shiny::conditionalPanel("input.mode == 'auto'",
        card("Model comparison", shiny::uiOutput("sel_text"),
             shiny::plotOutput("sel_plot", height = 240), DT::DTOutput("sel_table"))))),
    bslib::nav_panel("4. Results", bslib::navset_card_underline(
      bslib::nav_panel("Interpretation", shiny::uiOutput("interp")),
      bslib::nav_panel("Items", DT::DTOutput("item_tab")),
      bslib::nav_panel("Parameters", DT::DTOutput("pars")),
      bslib::nav_panel("Graphics",
        shiny::selectInput("plot_type", NULL, width = 300,
          c("Item characteristic curves" = "trace", "Expected scores" = "expected",
            "Test information" = "info", "Item information" = "iteminfo",
            "Standard error" = "se", "Wright map" = "wright", "Item fit" = "itemfit",
            "Local dependence (Q3)" = "q3", "Score distribution" = "scores")),
        shiny::plotOutput("plot", height = 560)),
      bslib::nav_panel("Item health cards",
        shiny::selectInput("card_item", NULL, choices = NULL, width = 300),
        shiny::plotOutput("card", height = 600)))),
    bslib::nav_panel("5. Scores",
      card("Person scores",
           shiny::selectInput("score_method", "Scoring method", width = 300,
                              c("EAP", "MAP", "ML", "WLE")),
           shiny::downloadButton("dl_scores", "Download scores (CSV)"),
           DT::DTOutput("scores")),
      card("Sum score conversion table", DT::DTOutput("conv"))),
    bslib::nav_panel("6. Response times", bslib::layout_sidebar(
      sidebar = bslib::sidebar(width = 330,
        shiny::helpText("Upload response times with the same rows and item columns as the responses. The simulated example data come with response times."),
        shiny::fileInput("rt_file", "Response-time file",
                         accept = c(".csv", ".tsv", ".txt", ".xlsx", ".xls", ".sav", ".dta", ".rds")),
        shiny::radioButtons("rt_flag", "Rapid-guessing rule",
                            c("Residual (person-specific)" = "residual",
                              "10% of mean item time (NT10)" = "nt10")),
        shiny::actionButton("fit_rt", "Fit response-time model", class = "btn-primary w-100")),
      shiny::uiOutput("rt_msg"),
      bslib::layout_columns(col_widths = c(6, 6),
        card("Interpretation", shiny::uiOutput("rt_interp")),
        card("Plots", shiny::selectInput("rt_plot_type", NULL,
                                         c("Item parameters" = "items", "Ability vs. speed" = "persons",
                                           "Rapid responding by item" = "rapid",
                                           "Response time effort" = "rte")),
             shiny::plotOutput("rt_plot", height = 360))),
      card("Item response-time parameters", DT::DTOutput("rt_items")))),
    bslib::nav_panel("7. Report & code",
      bslib::layout_columns(col_widths = c(4, 8),
        card("Downloads",
             shiny::textInput("rep_title", "Report title", "IRT analysis report"),
             shiny::textInput("rep_author", "Author", ""),
             shiny::checkboxInput("rep_cards", "Include item health cards", TRUE),
             shiny::downloadButton("dl_report", "Download HTML report", class = "btn-primary"),
             shiny::tags$hr(),
             shiny::downloadButton("dl_code", "Download R script")),
        card("Reproducible R code", shiny::verbatimTextOutput("code")))),
    bslib::nav_spacer(),
    bslib::nav_item(shiny::tags$a("mirt docs", href = "https://philchalmers.github.io/mirt/",
                                  target = "_blank"))
  )
}

workbench_server <- function(init_data = NULL) {
  function(input, output, session) {
    rv <- shiny::reactiveValues(model = NULL, sel = NULL, rt = NULL, rt_data = NULL,
                                fit_code = NULL, rt_code = NULL, error = NULL)

    raw <- shiny::reactive({
      if (!is.null(init_data) && input$source == "example") {
        return(list(data = as.data.frame(init_data), code = "# data supplied to launch_workbench()"))
      }
      if (input$source == "upload") {
        shiny::req(input$file)
        d <- tryCatch(read_any(input$file$datapath, input$file$name),
                      error = function(e) structure(list(msg = conditionMessage(e)), class = "wb_error"))
        if (inherits(d, "wb_error")) return(list(data = NULL, code = NULL, error = d$msg))
        return(list(data = d, code = read_code(input$file$name)))
      }
      ex <- example_datasets()[[input$example]]
      list(data = ex$data(), code = ex$code, rt = if (!is.null(ex$rt)) ex$rt())
    })

    if (!is.null(init_data)) {
      shiny::updateRadioButtons(session, "source", choices = c(
        "Data supplied to launch_workbench()" = "example", "Upload a file" = "upload"))
    }

    shiny::observeEvent(raw(), {
      d <- raw()$data
      if (is.null(d)) return()
      num <- names(d)[vapply(d, function(v) is.numeric(v) || is.integer(v), logical(1))]
      shiny::updateSelectizeInput(session, "items", choices = names(d), selected = num)
      rv$model <- NULL; rv$sel <- NULL; rv$rt <- NULL
      rv$rt_data <- raw()$rt
    })

    resp <- shiny::reactive({
      r <- raw()
      shiny::validate(shiny::need(is.null(r$error), r$error))
      d <- r$data
      shiny::req(d, input$items)
      items <- intersect(input$items, names(d))
      shiny::validate(shiny::need(length(items) >= 3, "Select at least three item columns."))
      x <- d[, items, drop = FALSE]
      code <- c(r$code, if (!setequal(items, names(d)))
        sprintf("data <- data[, c(%s)]", paste(sprintf("\"%s\"", items), collapse = ", ")))
      miss <- parse_num_list(input$missing)
      if (length(miss)) {
        x[] <- lapply(x, function(v) replace(v, v %in% miss, NA))
        code <- c(code, sprintf("data[data == %s] <- NA", miss))
      }
      key <- parse_num_list(input$key)
      if (length(key)) {
        shiny::validate(shiny::need(length(key) == ncol(x),
          sprintf("The key has %d entries but %d items are selected.", length(key), ncol(x))))
        x <- as.data.frame(mirt::key2binary(x, key))
        code <- c(code, sprintf("data <- as.data.frame(key2binary(data, key = c(%s)))",
                                paste(key, collapse = ", ")))
      }
      bad <- vapply(x, function(v) length(unique(stats::na.omit(v))) < 2, logical(1))
      if (any(bad)) {
        x <- x[, !bad, drop = FALSE]
        code <- c(code, sprintf("data <- data[, !names(data) %%in%% c(%s)]  # no variance",
                                paste(sprintf("\"%s\"", names(bad)[bad]), collapse = ", ")))
      }
      list(data = x, code = code, dropped = names(bad)[bad])
    })

    output$data_msg <- shiny::renderUI({
      r <- resp()
      msg <- sprintf("%d respondents, %d items.", nrow(r$data), ncol(r$data))
      if (length(r$dropped))
        msg <- paste(msg, "Dropped (no variance):", paste(r$dropped, collapse = ", "))
      shiny::tags$p(class = "text-muted", msg)
    })
    output$preview <- DT::renderDT(wb_table(utils::head(resp()$data, 200)))

    ist <- shiny::reactive(mirt::itemstats(resp()$data))
    output$overall <- shiny::renderTable({
      o <- ist()$overall
      data.frame(Statistic = c("Respondents", "Mean total score", "SD total score",
                               "Cronbach's alpha", "SEM"),
                 Value = c(o$N, round(o$mean.total, 2), round(o$sd.total, 2),
                           round(o$alpha, 3), round(o$SEM.alpha, 3)))
    })
    output$sum_hist <- shiny::renderPlot({
      tot <- rowSums(resp()$data, na.rm = TRUE)
      ggplot2::ggplot(data.frame(score = tot), ggplot2::aes(score)) +
        ggplot2::geom_bar(fill = mv_colours[["primary"]]) +
        ggplot2::labs(x = "Total score", y = "Respondents") + theme_mirtverse()
    })
    output$itemstats <- DT::renderDT({
      s <- ist()$itemstats
      wb_table(cbind(item = rownames(s), s))
    })

    shiny::observeEvent(input$fit, {
      d <- resp()$data
      rv$error <- NULL
      shiny::withProgress(message = "Fitting...", value = 0.3, {
        res <- tryCatch({
          if (input$mode == "auto") {
            dims <- if (isTRUE(input$try2)) 1:2 else 1
            sel <- select_model(d, dims = dims, criterion = input$criterion, verbose = FALSE)
            rv$sel <- sel; rv$model <- sel$best
            rv$fit_code <- c(sprintf("sel <- select_model(data%s%s)",
                                     if (isTRUE(input$try2)) ", dims = 1:2" else "",
                                     if (input$criterion != "BIC") sprintf(", criterion = \"%s\"", input$criterion) else ""),
                             "sel", "mod <- sel$best")
          } else {
            mod <- mirt::mirt(d, input$nfact, itemtype = input$itemtype, verbose = FALSE)
            rv$sel <- NULL; rv$model <- mod
            rv$fit_code <- sprintf("mod <- mirt(data, %d, itemtype = \"%s\")", input$nfact, input$itemtype)
          }
          TRUE
        }, error = function(e) conditionMessage(e))
        if (!isTRUE(res)) { rv$error <- res; rv$model <- NULL }
        rv$rt <- NULL
      })
      if (!is.null(rv$model))
        shiny::updateSelectInput(session, "card_item",
                                 choices = mirt::extract.mirt(rv$model, "itemnames"))
    })

    model <- shiny::reactive({
      shiny::validate(shiny::need(is.null(rv$error), paste("The model could not be fitted:", rv$error)))
      shiny::validate(shiny::need(rv$model, "Fit a model on the Model tab first."))
      rv$model
    })
    unidim <- shiny::reactive(mirt::extract.mirt(model(), "nfact") == 1L)

    output$fit_msg <- shiny::renderUI({
      if (!is.null(rv$error)) return(shiny::div(class = "alert alert-danger", rv$error))
      if (is.null(rv$model)) return(shiny::div(class = "alert alert-info",
                                               "Choose how to pick the model, then press Fit model."))
      conv <- isTRUE(mirt::extract.mirt(rv$model, "converged"))
      shiny::div(class = if (conv) "alert alert-success" else "alert alert-warning",
                 if (conv) "Model fitted and converged. Continue to Results."
                 else "The model did not converge; interpret with care.")
    })
    output$glance <- shiny::renderTable({
      g <- as.data.frame(glance(model()))
      data.frame(Statistic = names(g), Value = vapply(g, function(v) format_cell(v[[1]]), ""))
    })
    output$sel_text <- shiny::renderUI({
      shiny::req(rv$sel)
      shiny::tags$p(paste(rv$sel$explanation, collapse = " "))
    })
    output$sel_plot <- shiny::renderPlot({ shiny::req(rv$sel); autoplot(rv$sel) })
    output$sel_table <- DT::renderDT({
      shiny::req(rv$sel)
      wb_table(rv$sel$table[, c("model", "npar", "logLik", "AIC", "BIC", "SABIC", "RMSEA", "CFI", "delta")])
    })

    output$interp <- shiny::renderUI(interp_html(interpret(model())))
    output$item_tab <- DT::renderDT(wb_table(item_table(model())))
    output$pars <- DT::renderDT(wb_table(tidy(model())))
    output$plot <- shiny::renderPlot({
      shiny::validate(shiny::need(unidim() || input$plot_type %in% c("itemfit", "q3", "scores"),
                                  "This plot needs a unidimensional model."))
      autoplot(model(), input$plot_type)
    })
    output$card <- shiny::renderPlot({
      shiny::validate(shiny::need(unidim(), "Item health cards need a unidimensional model."))
      shiny::req(input$card_item)
      item_card(model(), input$card_item)
    })

    scores <- shiny::reactive(augment(model(), data = data.frame(row = seq_len(nrow(resp()$data))),
                                      method = input$score_method))
    output$scores <- DT::renderDT(wb_table(scores()))
    output$dl_scores <- shiny::downloadHandler(
      filename = function() "mirtverse-scores.csv",
      content = function(file) utils::write.csv(scores(), file, row.names = FALSE))
    output$conv <- DT::renderDT({
      shiny::validate(shiny::need(unidim(), "Available for unidimensional models."))
      conv <- mirt::fscores(model(), method = "EAPsum", full.scores = FALSE, verbose = FALSE)
      wb_table(as.data.frame(conv))
    })

    shiny::observeEvent(input$rt_file, {
      rv$rt_data <- tryCatch(read_any(input$rt_file$datapath, input$rt_file$name),
                             error = function(e) NULL)
    })
    shiny::observeEvent(input$fit_rt, {
      shiny::req(model())
      rv$rt <- NULL
      rt <- rv$rt_data
      if (is.null(rt)) { rv$rt <- "Upload a response-time file first."; return() }
      items <- mirt::extract.mirt(model(), "itemnames")
      if (!all(items %in% names(rt))) {
        rv$rt <- "The response-time file must contain the same item columns as the responses."
        return()
      }
      shiny::withProgress(message = "Fitting response-time model...", value = 0.4, {
        rv$rt <- tryCatch(fit_rt(model(), rt[, items], flag_method = input$rt_flag),
                          error = function(e) conditionMessage(e))
      })
      rv$rt_code <- c(if (!is.null(input$rt_file)) sub("^data <-", "rt <-", read_code(input$rt_file$name))
                      else "rt <- sim$rt",
                      sprintf("rt_fit <- fit_rt(mod, rt[, extract.mirt(mod, \"itemnames\")]%s)",
                              if (input$rt_flag != "residual") ", flag_method = \"nt10\"" else ""),
                      "interpret(rt_fit)")
    })
    rt_fit <- shiny::reactive({
      shiny::validate(shiny::need(!is.null(rv$rt), "Fit the response-time model to see results."))
      shiny::validate(shiny::need(inherits(rv$rt, "mv_rt"), rv$rt))
      rv$rt
    })
    output$rt_msg <- shiny::renderUI({
      if (is.character(rv$rt)) shiny::div(class = "alert alert-danger", rv$rt)
    })
    output$rt_interp <- shiny::renderUI(interp_html(interpret(rt_fit())))
    output$rt_plot <- shiny::renderPlot(autoplot(rt_fit(), input$rt_plot_type))
    output$rt_items <- DT::renderDT(wb_table(rt_fit()$items))

    script <- shiny::reactive({
      c("# Analysis generated by the mirtverse workbench",
        sprintf("# %s", format(Sys.time(), "%Y-%m-%d %H:%M")),
        "library(mirtverse)", "",
        "# 1. Data", resp()$code, "itemstats(data)", "",
        "# 2. Model", if (is.null(rv$fit_code)) "# (no model fitted yet)" else rv$fit_code,
        "glance(mod)", "",
        "# 3. Results", "interpret(mod)", "item_table(mod)", "tidy(mod)",
        "gg_wright(mod)", "gg_info(mod)", "item_card(mod, 1)", "",
        "# 4. Scores", sprintf("scores <- augment(mod, method = \"%s\")", input$score_method),
        "write.csv(scores, \"mirtverse-scores.csv\", row.names = FALSE)",
        if (!is.null(rv$rt_code)) c("", "# 5. Response times", rv$rt_code), "",
        "# Report", sprintf("mv_report(%s, file = \"mirtverse-report.html\")",
                            if (!is.null(rv$sel)) "sel" else "mod"))
    })
    output$code <- shiny::renderText(paste(script(), collapse = "\n"))
    output$dl_code <- shiny::downloadHandler(
      filename = function() "mirtverse-analysis.R",
      content = function(file) writeLines(script(), file))
    output$dl_report <- shiny::downloadHandler(
      filename = function() "mirtverse-report.html",
      content = function(file) {
        shiny::withProgress(message = "Building report...", value = 0.5, {
          mv_report(if (!is.null(rv$sel)) rv$sel else model(), file = file,
                    title = input$rep_title,
                    author = if (nzchar(input$rep_author)) input$rep_author,
                    cards = isTRUE(input$rep_cards) && unidim(),
                    code = script(), open = FALSE)
        })
      })
  }
}

parse_num_list <- function(txt) {
  if (is.null(txt) || !nzchar(trimws(txt))) return(numeric())
  v <- suppressWarnings(as.numeric(strsplit(gsub("\\s", "", txt), "[,;]")[[1]]))
  v[!is.na(v)]
}
