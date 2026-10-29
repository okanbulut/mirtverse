#' Results dashboard for sharing
#'
#' Builds a small, read-only 'shiny' dashboard of a fitted model for people
#' who do not use R: teachers, clients, committees or students. Where the
#' [workbench][launch_workbench] is for doing an analysis, the dashboard is for
#' showing one. Pick the panels you want, give it a title, and run it, or save
#' it as a ready-to-deploy app with [export_dashboard()].
#'
#' Everything the dashboard shows is computed once when it is built and kept
#' in a summary object; the app never refits or rescores anything. That
#' summary holds no item responses. Individual person scores are included only
#' when you ask for the `"persons"` panel, so check that you may share them
#' before you deploy a dashboard that has it.
#'
#' Available panels:
#' * `"summary"`: headline numbers (respondents, items, reliability, flagged
#'   items) and the plain-language interpretation from [interpret()].
#' * `"items"`: the item table with traffic-light status; select a row to see
#'   that item's health card ([item_card()]).
#' * `"curves"`: trace curves for chosen items, with a slider that reads off
#'   the probabilities at any ability level.
#' * `"information"`: test information and standard error, plus item
#'   information curves.
#' * `"wright"`: the Wright map.
#' * `"scores"`: the distribution of ability estimates and the sum-score
#'   conversion table (no individual scores).
#' * `"persons"`: a searchable table of every person's score, standard error
#'   and percentile.
#' * `"dif"`: differential item functioning results (needs `dif`).
#' * `"rt"`: response-time results (needs `rt`).
#'
#' `"curves"`, `"information"`, `"wright"`, `"scores"` and `"persons"` need a
#' unidimensional model and are dropped, with a message, for other models.
#'
#' @param x a model from [mirt::mirt()], an `mv_model_selection` object from
#'   [select_model()] (its recommended model is shown), or a dashboard object
#'   saved by [export_dashboard()].
#' @param panels character vector of panels to show, in order. The default
#'   shows `"summary"`, `"items"`, `"curves"`, `"information"`, `"wright"` and
#'   `"scores"`, plus `"dif"` and `"rt"` when those results are supplied.
#' @param title,subtitle text for the dashboard header.
#' @param logo optional path to a PNG, JPEG or SVG image shown in the header.
#' @param dif optional `mv_dif` object from [dif()].
#' @param rt optional `mv_rt` object from [fit_rt()].
#' @param ids optional vector of person identifiers for the `"persons"`
#'   panel, one per row of the data the model was fitted to. Defaults to row
#'   numbers.
#' @param method scoring method for person scores, passed to [mirt::fscores()].
#' @param cards logical; prepare an item health card for every item (shown
#'   when you select an item). Defaults to `TRUE` for unidimensional tests of
#'   up to 40 items, because each card takes a moment to draw.
#' @param alpha significance level for item misfit flags.
#' @return A 'shiny' app object. Printing it (or calling the function at the
#'   console) opens the dashboard; [shiny::runApp()] accepts it too. The
#'   summary object is stored in its `"mv_dashboard"` attribute.
#' @seealso [export_dashboard()] to save a dashboard for deployment,
#'   [mv_report()] for a static HTML report.
#' @examples
#' \donttest{
#' mod <- mirt(Science, 1, verbose = FALSE)
#' app <- mv_dashboard(mod, title = "Science attitudes survey",
#'                     panels = c("summary", "items", "curves"))
#' if (interactive()) app
#' }
#' @export
mv_dashboard <- function(x, panels = NULL, title = "Assessment results", subtitle = NULL,
                         logo = NULL, dif = NULL, rt = NULL, ids = NULL, method = "EAP",
                         cards = NULL, alpha = 0.01) {
  d <- if (inherits(x, "mv_dashboard")) x
       else dashboard_data(x, panels = panels, title = title, subtitle = subtitle, logo = logo,
                           dif = dif, rt = rt, ids = ids, method = method, cards = cards,
                           alpha = alpha)
  app <- shiny::shinyApp(dashboard_ui(d), dashboard_server(d))
  attr(app, "mv_dashboard") <- d
  app
}

#' Save a results dashboard as a deployable app
#'
#' Writes a folder with an `app.R` file and the dashboard summary
#' (`dashboard.rds`). Run it locally with `shiny::runApp(dir)`, or publish the
#' folder to [shinyapps.io](https://www.shinyapps.io) or Posit Connect with
#' `rsconnect::deployApp(dir)`. The server installs mirtverse the way you
#' installed it, so install it from GitHub or r-universe (not from a local
#' folder) before you deploy.
#'
#' The folder holds no item responses. It holds individual scores only if the
#' dashboard has the `"persons"` panel.
#'
#' @param x a model, `mv_model_selection` object, or the app returned by
#'   [mv_dashboard()].
#' @param dir folder to write. Created if needed.
#' @param ... arguments passed to [mv_dashboard()] when `x` is a model, such
#'   as `panels`, `title` or `dif`.
#' @param overwrite logical; replace an existing `app.R` or `dashboard.rds`.
#' @return The folder path, invisibly.
#' @examples
#' \donttest{
#' mod <- mirt(Science, 1, verbose = FALSE)
#' dir <- export_dashboard(mod, file.path(tempdir(), "science-dashboard"),
#'                         title = "Science attitudes survey")
#' list.files(dir)
#' if (interactive()) shiny::runApp(dir)
#' }
#' @export
export_dashboard <- function(x, dir = "mirtverse-dashboard", ..., overwrite = FALSE) {
  files <- file.path(dir, c("app.R", "dashboard.rds"))
  if (!overwrite && any(file.exists(files)))
    stop("`", dir, "` already contains a dashboard. Use `overwrite = TRUE` to replace it.",
         call. = FALSE)
  d <- if (inherits(x, "shiny.appobj") && !is.null(attr(x, "mv_dashboard")))
         attr(x, "mv_dashboard")
       else if (inherits(x, "mv_dashboard")) x
       else attr(mv_dashboard(x, ...), "mv_dashboard")
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(d, files[2])
  writeLines(c(
    sprintf("# mirtverse results dashboard: %s", d$meta$title),
    sprintf("# Created %s with mirtverse %s.", d$meta$created, d$meta$version),
    "# Run locally with shiny::runApp() or deploy with rsconnect::deployApp().",
    "library(shiny)",
    "library(mirtverse)",
    "mv_dashboard(readRDS(\"dashboard.rds\"))"), files[1])
  if ("persons" %in% d$panels)
    message("This dashboard includes individual person scores. Check that you may share them before deploying it.")
  invisible(dir)
}

dashboard_panels <- c(summary = "Summary", items = "Items", curves = "Item curves",
                      information = "Information", wright = "Wright map", scores = "Scores",
                      persons = "Persons", dif = "DIF", rt = "Response times")

# Everything the app shows, computed once. Holds no response data so the
# object can be saved and deployed; person scores only for the persons panel.
dashboard_data <- function(x, panels = NULL, title = "Assessment results", subtitle = NULL,
                           logo = NULL, dif = NULL, rt = NULL, ids = NULL, method = "EAP",
                           cards = NULL, alpha = 0.01) {
  if (inherits(x, "mv_model_selection")) x <- x$best
  check_single(x)
  if (!is.null(dif) && !inherits(dif, "mv_dif"))
    stop("`dif` must be the result of dif().", call. = FALSE)
  if (!is.null(rt) && !inherits(rt, "mv_rt"))
    stop("`rt` must be the result of fit_rt().", call. = FALSE)
  unidim <- mirt::extract.mirt(x, "nfact") == 1L
  nitems <- mirt::extract.mirt(x, "nitems")

  if (is.null(panels))
    panels <- c("summary", "items", "curves", "information", "wright", "scores",
                if (!is.null(dif)) "dif", if (!is.null(rt)) "rt")
  bad <- setdiff(panels, names(dashboard_panels))
  if (length(bad))
    stop("Unknown panel(s): ", paste(bad, collapse = ", "), ". Choose from ",
         paste(names(dashboard_panels), collapse = ", "), ".", call. = FALSE)
  panels <- unique(panels)
  if (!length(panels)) stop("Choose at least one panel.", call. = FALSE)
  if ("dif" %in% panels && is.null(dif))
    stop("The \"dif\" panel needs `dif`, the result of dif().", call. = FALSE)
  if ("rt" %in% panels && is.null(rt))
    stop("The \"rt\" panel needs `rt`, the result of fit_rt().", call. = FALSE)
  need_uni <- intersect(panels, c("curves", "information", "wright", "scores", "persons"))
  if (!unidim && length(need_uni)) {
    message("Dropping panel(s) that need a unidimensional model: ",
            paste(need_uni, collapse = ", "), ".")
    panels <- setdiff(panels, need_uni)
  }
  if (is.null(cards)) cards <- unidim && nitems <= 40
  cards <- isTRUE(cards) && unidim && "items" %in% panels

  it <- as.data.frame(item_table(x, alpha = alpha))
  it$status <- vapply(seq_len(nrow(it)), function(i) item_status(it[i, ]), character(1))
  g <- as.data.frame(glance(x))

  d <- list(
    meta = list(title = title, subtitle = subtitle, logo = logo_uri(logo),
                created = format(Sys.Date()),
                version = as.character(utils::packageVersion("mirtverse")),
                mirt = as.character(utils::packageVersion("mirt")),
                unidim = unidim, nitems = nitems, nobs = g$nobs,
                itemtype = g$itemtype, method = method),
    panels = panels, glance = g, interp = interpret(x, alpha = alpha),
    items = it, pars = wide_pars(x))

  if (cards) {
    message(sprintf("Drawing %d item health cards...", nitems))
    d$cards <- stats::setNames(lapply(seq_len(nitems), function(j)
      plot_img(item_card(x, j, alpha = alpha, tab = it), 11, 6.5)$attribs$src), it$item)
  }
  if (any(c("curves", "items") %in% panels) && unidim) {
    d$trace <- trace_data(x, theta_lim = c(-4, 4), n = 121)
    d$dich <- stats::setNames(mirt::extract.mirt(x, "K") == 2L, it$item)
  }
  if ("information" %in% panels) {
    Theta <- matrix(theta_grid(c(-4, 4), 121))
    ti <- mirt::testinfo(x, Theta)
    d$testinfo <- data.frame(theta = Theta[, 1], info = ti, se = 1 / sqrt(ti))
    d$iteminfo <- info_data(x, theta_lim = c(-4, 4), n = 121)
  }
  if (any(c("wright", "scores", "persons") %in% panels)) {
    fs <- mirt::fscores(x, method = method, full.scores.SE = TRUE, verbose = FALSE)
    th <- fs[, 1]
    fin <- is.finite(th)
    if ("wright" %in% panels) {
      d$wright <- list(persons = wright_bins(th[fin]), items = wright_items(x))
    }
    if ("scores" %in% panels) {
      d$score_bins <- wright_bins(th[fin], 30)
      d$score_summary <- c(mean = mean(th[fin]), sd = stats::sd(th[fin]),
                           median = stats::median(th[fin]))
      d$conv <- safe(as.data.frame(mirt::fscores(x, method = "EAPsum", full.scores = FALSE,
                                                 verbose = FALSE)))
    }
    if ("persons" %in% panels) {
      if (is.null(ids)) ids <- seq_along(th)
      if (length(ids) != length(th))
        stop(sprintf("`ids` has %d values but the model has %d respondents.",
                     length(ids), length(th)), call. = FALSE)
      d$persons <- data.frame(id = ids, score = round(th, 3), se = round(fs[, 2], 3),
                              percentile = round(100 * stats::ecdf(th[fin])(th)),
                              stringsAsFactors = FALSE)
    }
  }
  if ("dif" %in% panels) {
    two <- length(dif$groups) == 2L
    d$dif <- list(table = as.data.frame(dif$table), interp = interpret(dif),
                  groups = dif$groups,
                  effect = if (two) plot_img(gg_dif(dif), 7,
                                             max(3, 0.28 * nrow(dif$table) + 1.5))$attribs$src,
                  curves = if (any(dif$table$flag))
                    plot_img(gg_dif(dif, type = "curves"), 8,
                             max(3, 2.4 * ceiling(sum(dif$table$flag) / 3)))$attribs$src)
  }
  if ("rt" %in% panels) {
    d$rt <- list(items = as.data.frame(rt$items), interp = interpret(rt),
                 plots = lapply(c(items = "items", rapid = "rapid", rte = "rte"), function(tp)
                   plot_img(autoplot(rt, tp), 7, 4.5)$attribs$src))
  }
  structure(d, class = "mv_dashboard")
}

#' @export
print.mv_dashboard <- function(x, ...) {
  cat(sprintf("<mirtverse dashboard> %s\n", x$meta$title))
  cat(sprintf("%s respondents, %d items, created %s\n", format(x$meta$nobs), x$meta$nitems,
              x$meta$created))
  cat("Panels:", paste(dashboard_panels[x$panels], collapse = ", "), "\n")
  invisible(x)
}

logo_uri <- function(logo) {
  if (is.null(logo)) return(NULL)
  if (!file.exists(logo)) stop("Logo file not found: ", logo, call. = FALSE)
  type <- switch(tolower(tools::file_ext(logo)), png = "image/png", jpg = , jpeg = "image/jpeg",
                 svg = "image/svg+xml", stop("The logo must be a PNG, JPEG or SVG file.", call. = FALSE))
  paste0("data:", type, ";base64,", base64enc::base64encode(logo))
}

dashboard_ui <- function(d) {
  b <- bslib::bs_theme(version = 5, primary = "#2C5F8A", secondary = "#D1495B",
                       base_font = bslib::font_collection("system-ui", "-apple-system",
                                                          "Segoe UI", "Roboto", "sans-serif"))
  card <- function(title, ...) bslib::card(fill = FALSE, bslib::card_header(title),
                                           bslib::card_body(fillable = FALSE, ...))
  items <- d$items$item
  brand <- shiny::tags$span(
    if (!is.null(d$meta$logo)) shiny::tags$img(src = d$meta$logo, height = "32px",
                                               style = "margin-right:10px;vertical-align:middle;"),
    d$meta$title)

  panel <- function(id) switch(id,
    summary = bslib::nav_panel(dashboard_panels[["summary"]],
      if (!is.null(d$meta$subtitle)) shiny::tags$p(class = "lead text-muted", d$meta$subtitle),
      do.call(bslib::layout_column_wrap, c(list(width = "200px", fill = FALSE), summary_boxes(d))),
      bslib::layout_columns(col_widths = c(7, 5),
        card("What the results say", interp_html(d$interp)),
        card("Model details", shiny::tableOutput("dash_glance")))),
    items = bslib::nav_panel(dashboard_panels[["items"]],
      card("Items", shiny::tags$p(class = "text-muted",
        "Status: red for misfit or low discrimination, amber for other flags, green otherwise. Select a row to see the item in detail."),
        DT::DTOutput("dash_items")),
      card("Selected item", shiny::uiOutput("dash_item_detail"))),
    curves = bslib::nav_panel(dashboard_panels[["curves"]], bslib::layout_sidebar(
      sidebar = bslib::sidebar(width = 300,
        shiny::selectizeInput("dash_curve_items", "Items", items, selected = utils::head(items, 4),
                              multiple = TRUE),
        shiny::radioButtons("dash_curve_type", "Show",
                            c("Response probabilities" = "prob", "Expected item score" = "expected")),
        shiny::sliderInput("dash_theta", "Ability level", min = -4, max = 4, value = 0, step = 0.1),
        shiny::helpText("Ability is on a standard scale: 0 is average, and most people fall between -2 and 2.")),
      card("Item characteristic curves", shiny::plotOutput("dash_curves", height = 460)),
      card("At the chosen ability level", shiny::tableOutput("dash_at_theta")))),
    information = bslib::nav_panel(dashboard_panels[["information"]],
      bslib::layout_columns(col_widths = c(6, 6),
        card("Test information",
             shiny::tags$p(class = "text-muted", "The test measures most precisely where information is high and the standard error is low."),
             shiny::plotOutput("dash_testinfo", height = 380)),
        card("Item information",
             shiny::selectizeInput("dash_info_items", NULL, items, selected = utils::head(items, 5),
                                   multiple = TRUE, width = "100%"),
             shiny::plotOutput("dash_iteminfo", height = 330)))),
    wright = bslib::nav_panel(dashboard_panels[["wright"]],
      card("Wright map", shiny::tags$p(class = "text-muted",
        "People (left) and items (right) on the same scale. A well-targeted test has items spread where most people are."),
        shiny::plotOutput("dash_wright", height = 520))),
    scores = bslib::nav_panel(dashboard_panels[["scores"]],
      bslib::layout_columns(col_widths = c(6, 6),
        card("Distribution of ability estimates", shiny::plotOutput("dash_scores", height = 360),
             shiny::tableOutput("dash_score_summary")),
        card("Sum score conversion table", shiny::tags$p(class = "text-muted",
          "The ability estimate and its standard error for each total score."),
          DT::DTOutput("dash_conv")))),
    persons = bslib::nav_panel(dashboard_panels[["persons"]],
      card("Person scores", shiny::tags$p(class = "text-muted",
        sprintf("%s ability estimates with standard errors. Search for an ID to look someone up.",
                d$meta$method)),
        DT::DTOutput("dash_persons"))),
    dif = bslib::nav_panel(dashboard_panels[["dif"]],
      card("Differential item functioning", interp_html(d$dif$interp),
           DT::DTOutput("dash_dif")),
      if (!is.null(d$dif$effect)) card("Effect sizes", shiny::tags$img(src = d$dif$effect, style = "max-width:100%;")),
      if (!is.null(d$dif$curves)) card("Flagged items by group", shiny::tags$img(src = d$dif$curves, style = "max-width:100%;"))),
    rt = bslib::nav_panel(dashboard_panels[["rt"]],
      bslib::layout_columns(col_widths = c(6, 6),
        card("What the response times say", interp_html(d$rt$interp)),
        card("Plots", shiny::selectInput("dash_rt_plot", NULL,
                                         c("Item parameters" = "items", "Rapid responding by item" = "rapid",
                                           "Response time effort" = "rte")),
             shiny::uiOutput("dash_rt_img"))),
      card("Item response-time parameters", DT::DTOutput("dash_rt_items")))
  )

  do.call(bslib::page_navbar, c(
    list(title = brand, window_title = d$meta$title, theme = b, fillable = FALSE),
    lapply(d$panels, panel),
    list(bslib::nav_spacer(),
         bslib::nav_item(shiny::tags$small(class = "text-muted",
           sprintf("Made with mirtverse %s, %s", d$meta$version, d$meta$created))))))
}

summary_boxes <- function(d) {
  rel <- d$glance$reliability
  st <- table(factor(d$items$status, levels = c("green", "amber", "red")))
  box <- function(title, value, sub = NULL, theme = "primary")
    bslib::value_box(title = title, value = value, if (!is.null(sub)) shiny::tags$p(sub),
                     theme = theme)
  list(
    box("Respondents", format(d$meta$nobs, big.mark = ",")),
    box("Items", d$meta$nitems, d$meta$itemtype),
    if (!is.null(rel) && !is.na(rel))
      box("Reliability", formatC(rel, format = "f", digits = 2), "marginal reliability"),
    box("Items to review", st[["red"]] + st[["amber"]],
        sprintf("%d red, %d amber", st[["red"]], st[["amber"]]),
        theme = if (st[["red"]] > 0) "danger" else if (st[["amber"]] > 0) "warning" else "success"))
}

dashboard_server <- function(d) {
  function(input, output, session) {
    output$dash_glance <- shiny::renderTable({
      g <- d$glance
      keep <- intersect(c("nobs", "nitems", "itemtype", "logLik", "AIC", "BIC", "M2", "df", "p.value",
                          "RMSEA", "CFI", "TLI", "SRMSR", "reliability", "converged"), names(g))
      labs <- c(nobs = "Respondents", nitems = "Items", itemtype = "Item type",
                logLik = "Log-likelihood", M2 = "M2 (limited-information fit)", df = "M2 df",
                p.value = "M2 p-value", reliability = "Reliability",
                converged = "Converged")
      data.frame(Statistic = ifelse(keep %in% names(labs), labs[keep], keep),
                 Value = vapply(keep, function(nm) format_cell(g[[nm]][[1]]), ""))
    })

    items_view <- d$items[, intersect(c("item", "status", "itemtype", "mean", "item_total_r",
                                        "discrimination", "location", "RMSEA", "p.value",
                                        "flag"), names(d$items))]
    output$dash_items <- DT::renderDT({
      df <- items_view
      num <- vapply(df, is.numeric, logical(1))
      df[num] <- lapply(df[num], round, 3)
      DT::formatStyle(
        DT::datatable(df, rownames = FALSE, selection = list(mode = "single", selected = 1),
                      options = list(pageLength = 15, scrollX = TRUE, dom = "ftip")),
        "status", color = "white", fontWeight = "bold",
        backgroundColor = DT::styleEqual(c("green", "amber", "red"), c("#2E8B57", "#C9861F", "#C23B4E")))
    })
    output$dash_item_detail <- shiny::renderUI({
      i <- input$dash_items_rows_selected
      if (!length(i)) return(shiny::tags$p(class = "text-muted", "Select an item in the table."))
      nm <- d$items$item[i]
      if (!is.null(d$cards)) return(shiny::tags$img(src = d$cards[[nm]], style = "max-width:100%;",
                                                    alt = paste("Item health card for", nm)))
      if (is.null(d$trace)) return(shiny::tags$p(class = "text-muted", "No item curves for this model."))
      shiny::plotOutput("dash_item_curve", height = 360)
    })
    output$dash_item_curve <- shiny::renderPlot({
      i <- input$dash_items_rows_selected
      shiny::req(length(i))
      nm <- d$items$item[i]
      plot_trace(d$trace[d$trace$item == nm, ], d$dich[[nm]])
    }, res = 96)

    curves <- shiny::reactive({
      shiny::validate(shiny::need(length(input$dash_curve_items), "Choose at least one item."))
      df <- d$trace[d$trace$item %in% input$dash_curve_items, ]
      df$item <- droplevels(df$item)
      df
    })
    output$dash_curves <- shiny::renderPlot({
      df <- curves()
      plot_trace(df, all(d$dich[input$dash_curve_items]), input$dash_curve_type) +
        ggplot2::geom_vline(xintercept = input$dash_theta, linetype = "dashed",
                            colour = mv_colours[["grey"]])
    }, res = 96)
    output$dash_at_theta <- shiny::renderTable({
      df <- curves()
      at <- df[abs(df$theta - input$dash_theta) == min(abs(df$theta - input$dash_theta)), ]
      at <- at[!duplicated(at[, c("item", "category")]), ]
      exp <- at[at$first, c("item", "expected")]
      probs <- stats::reshape(at[, c("item", "category", "prob")], idvar = "item",
                              timevar = "category", direction = "wide")
      names(probs) <- sub("^prob\\.", "P(", names(probs))
      names(probs)[-1] <- paste0(names(probs)[-1], ")")
      out <- merge(exp, probs, by = "item", sort = FALSE)
      names(out)[1:2] <- c("Item", "Expected score")
      out
    }, digits = 3)

    output$dash_testinfo <- shiny::renderPlot(plot_test_info(d$testinfo), res = 96)
    output$dash_iteminfo <- shiny::renderPlot({
      shiny::validate(shiny::need(length(input$dash_info_items), "Choose at least one item."))
      df <- d$iteminfo[d$iteminfo$item %in% input$dash_info_items, ]
      ggplot2::ggplot(df, ggplot2::aes(theta, info, colour = item)) +
        ggplot2::geom_line(linewidth = 0.9) +
        ggplot2::scale_colour_viridis_d(end = 0.9) +
        ggplot2::labs(x = expression(theta), y = "Information", colour = NULL) +
        theme_mirtverse()
    }, res = 96)

    output$dash_wright <- shiny::renderPlot(plot_wright(d$wright$persons, d$wright$items), res = 96)

    output$dash_scores <- shiny::renderPlot({
      ggplot2::ggplot(d$score_bins) +
        ggplot2::geom_rect(ggplot2::aes(xmin = lo, xmax = hi, ymin = 0, ymax = count),
                           fill = mv_colours[["primary"]], colour = "white") +
        ggplot2::labs(x = sprintf("%s estimate of ability", d$meta$method), y = "Respondents") +
        theme_mirtverse()
    }, res = 96)
    output$dash_score_summary <- shiny::renderTable({
      s <- d$score_summary
      data.frame(Mean = s[["mean"]], SD = s[["sd"]], Median = s[["median"]])
    }, digits = 2)
    output$dash_conv <- DT::renderDT({
      shiny::validate(shiny::need(!is.null(d$conv), "Not available for this model."))
      cv <- d$conv[, intersect(c("Sum.Scores", "F1", "SE_F1"), names(d$conv))]
      names(cv) <- c("Total score", "Ability", "SE")[seq_along(cv)]
      wb_table(cv, page = 15)
    })

    output$dash_persons <- DT::renderDT({
      df <- d$persons
      names(df) <- c("ID", "Ability", "SE", "Percentile")
      DT::datatable(df, rownames = FALSE, options = list(pageLength = 15, dom = "ftip"))
    })

    output$dash_dif <- DT::renderDT({
      dt <- d$dif$table
      dt$flag <- ifelse(dt$flag, "DIF", "")
      wb_table(dt[, intersect(c("item", "flag", "X2", "df", "p.value", "p.adjusted", "esd", "uesd"),
                             names(dt))], page = 15)
    })

    output$dash_rt_img <- shiny::renderUI(
      shiny::tags$img(src = d$rt$plots[[input$dash_rt_plot]], style = "max-width:100%;"))
    output$dash_rt_items <- DT::renderDT(wb_table(d$rt$items))
  }
}
