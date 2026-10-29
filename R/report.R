#' One-call HTML report
#'
#' Writes a self-contained HTML report (no internet connection or extra
#' software needed to open it) covering the plain-language summary, model fit,
#' item statistics and parameters, graphics, a sum-score conversion table,
#' optional item health cards and the R code needed to reproduce the analysis.
#'
#' @param x a unidimensional model from [mirt::mirt()], or an
#'   `mv_model_selection` object from [select_model()] (the report then adds
#'   the model comparison and describes the recommended model).
#' @param file path of the `.html` file to write.
#' @param title report title.
#' @param author optional author line.
#' @param cards logical; include an item health card for every item. Defaults
#'   to `TRUE` for tests of up to 40 items.
#' @param alpha significance level for item misfit.
#' @param dif optional `mv_dif` object from [dif()]; adds a section on
#'   differential item functioning.
#' @param code optional character vector of R code to show in the
#'   reproducibility section (the workbench fills this in automatically).
#' @param open logical; open the report in a browser afterwards.
#' @return The path to the report, invisibly.
#' @examples
#' \donttest{
#' mod <- mirt(Science, 1, verbose = FALSE)
#' f <- mv_report(mod, file = tempfile(fileext = ".html"))
#' }
#' @export
mv_report <- function(x, file = "mirtverse-report.html", title = "IRT analysis report",
                      author = NULL, cards = NULL, alpha = 0.01, dif = NULL, code = NULL,
                      open = interactive() && !isTRUE(getOption("mirtverse.dry_run"))) {
  sel <- NULL
  if (inherits(x, "mv_model_selection")) {
    sel <- x
    x <- sel$best
  }
  check_single(x)
  if (!is.null(dif) && !inherits(dif, "mv_dif"))
    stop("`dif` must be the result of dif().", call. = FALSE)
  unidim <- mirt::extract.mirt(x, "nfact") == 1L
  nitems <- mirt::extract.mirt(x, "nitems")
  if (is.null(cards)) cards <- unidim && nitems <= 40
  interp <- interpret(x, alpha = alpha)
  g <- as.data.frame(glance(x))
  it <- as.data.frame(item_table(x, alpha = alpha))
  it$status <- vapply(seq_len(nrow(it)), function(i) item_status(it[i, ]), character(1))
  pars <- wide_pars(x)

  h <- htmltools::tags
  sections <- list(
    h$header(h$h1(title),
             h$p(class = "meta", paste(c(author, format(Sys.time(), "%B %d, %Y"),
                                         paste("mirt", utils::packageVersion("mirt")),
                                         paste("mirtverse", utils::packageVersion("mirtverse"))),
                                       collapse = " | "))),
    h$nav(class = "toc", h$strong("Contents"),
          h$ol(lapply(c(if (!is.null(sel)) "Model selection", "Summary", "Model",
                        "Items", if (!is.null(dif)) "DIF", if (unidim) "Graphics", if (unidim) "Scores",
                        if (cards) "Item health cards", "Reproducibility"),
                      function(s) h$li(h$a(href = paste0("#", anchor(s)), s))))))

  if (!is.null(sel)) {
    tab <- as.data.frame(sel$table)
    sections <- c(sections, list(section("Model selection",
      h$p(paste(sel$explanation, collapse = " ")),
      html_table(tab[, c("model", "npar", "logLik", "AIC", "BIC", "SABIC", "RMSEA", "CFI", "delta")]),
      plot_img(autoplot(sel), 7, 3.2))))
  }

  sections <- c(sections, list(
    section("Summary", interp_html(interp)),
    section("Model",
            html_table(data.frame(Statistic = names(g),
                                  Value = vapply(g, function(v) format_cell(v[[1]]), character(1))),
                       header = TRUE)),
    section("Items",
            h$p("Status uses the item health rules: red for misfit or low discrimination, amber for other flags, green otherwise."),
            html_table(it[, intersect(c("item", "status", "itemtype", "N", "mean", "item_total_r",
                                        "S_X2", "df", "RMSEA", "p.value", "flag"), names(it))],
                       status_col = "status"),
            h$h3("Item parameters"),
            h$p(sprintf("Parameterization: %s.", attr(pars, "parameterization"))),
            html_table(pars))))

  if (!is.null(dif)) {
    dt <- as.data.frame(dif$table)
    dt$flag <- ifelse(dt$flag, "DIF", "")
    two <- length(dif$groups) == 2L
    sections <- c(sections, list(section("DIF",
      interp_html(interpret(dif)),
      html_table(dt[, c("item", "flag", "X2", "df", "p.value", "p.adjusted",
                        if (two) c("esd", "uesd"))]),
      if (two) plot_img(gg_dif(dif), 7, max(3, 0.28 * nrow(dt) + 1.5)),
      if (any(dif$table$flag)) plot_img(gg_dif(dif, type = "curves"), 8,
                                        max(3, 2.4 * ceiling(sum(dif$table$flag) / 3))))))
  }

  if (unidim) {
    sections <- c(sections, list(section("Graphics",
      h$h3("Test information"), plot_img(gg_info(x), 7, 4),
      h$h3("Wright map"), plot_img(gg_wright(x), 8, 5),
      h$h3("Item characteristic curves"),
      plot_img(gg_trace(x), 9, max(3, 2.2 * ceiling(nitems / 4))),
      h$h3("Item fit"), plot_img(gg_itemfit(x, alpha = alpha), 7, max(3, 0.28 * nitems + 1.5)),
      if (nitems <= 60) list(h$h3("Local dependence"), plot_img(gg_q3(x), 7, 6)))))
    conv <- safe(as.data.frame(mirt::fscores(x, method = "EAPsum", full.scores = FALSE,
                                             verbose = FALSE)))
    sections <- c(sections, list(section("Scores",
      plot_img(gg_scores(x), 7, 3.5),
      if (!is.null(conv)) list(
        h$h3("Sum score conversion table"),
        h$p("Expected a posteriori (EAP) ability for each total score, with its standard error. Observed and expected counts show how well the model reproduces the score distribution."),
        html_table(conv[, intersect(c("Sum.Scores", "F1", "SE_F1", "observed", "expected"), names(conv))])))))
  }

  if (cards) {
    sections <- c(sections, list(section("Item health cards",
      lapply(seq_len(nitems), function(j)
        htmltools::div(class = "card", plot_img(item_card(x, j, alpha = alpha, tab = it), 11, 6.5))))))
  }

  call_txt <- paste(deparse(mirt::extract.mirt(x, "model")), collapse = "\n")
  code <- if (is.null(code)) c(
    "library(mirtverse)",
    "# data <- read.csv(\"your-data.csv\")",
    sprintf("mod <- mirt(data, %s, itemtype = %s)",
            if (unidim) "1" else call_txt,
            deparse(unique(mirt::extract.mirt(x, "itemtype")))),
    "interpret(mod)", "item_table(mod)",
    sprintf("mv_report(mod, file = \"%s\")", basename(file))) else code
  sections <- c(sections, list(section("Reproducibility",
    h$p("Run this code to reproduce the analysis:"),
    pre_block(code, code = TRUE),
    h$details(h$summary("Session information"),
              pre_block(utils::capture.output(print(utils::sessionInfo())))))))

  save_page(htmltools::tagList(sections), file, title = title)
  if (open) utils::browseURL(file)
  invisible(file)
}

wide_pars <- function(x) {
  td <- as.data.frame(tidy(x))
  terms <- unique(td$term)
  w <- stats::reshape(td[, c("item", "term", "estimate")], idvar = "item",
                      timevar = "term", direction = "wide")
  names(w) <- sub("^estimate\\.", "", names(w))
  w <- w[, c("item", terms)]
  if (any(!is.na(td$std.error))) {
    s <- stats::reshape(td[, c("item", "term", "std.error")], idvar = "item",
                        timevar = "term", direction = "wide")
    names(s) <- sub("^std\\.error\\.", "SE_", names(s))
    w <- merge(w, s, by = "item", sort = FALSE)
  }
  rownames(w) <- NULL
  attr(w, "parameterization") <- attr(tidy_pars(x), "parameterization")
  w
}

anchor <- function(s) gsub("[^a-z0-9]+", "-", tolower(s))

# Written as raw HTML: htmltools indents nested tags when it prints them, and
# inside <pre> that indentation would show up as leading spaces.
pre_block <- function(lines, code = FALSE) {
  txt <- htmltools::htmlEscape(paste(lines, collapse = "\n"))
  htmltools::HTML(if (code) paste0("<pre><code>", txt, "</code></pre>")
                  else paste0("<pre>", txt, "</pre>"))
}

section <- function(title, ...) {
  htmltools::tags$section(id = anchor(title), htmltools::tags$h2(title), ...)
}

interp_html <- function(interp) {
  htmltools::tagList(lapply(names(interp), function(nm)
    htmltools::div(class = "interp", htmltools::tags$h3(nm),
                   htmltools::tags$ul(lapply(interp[[nm]], htmltools::tags$li)))))
}

format_cell <- function(v) {
  if (is.null(v) || length(v) == 0) return("")
  if (is.logical(v)) return(ifelse(is.na(v), "", ifelse(v, "yes", "no")))
  if (is.numeric(v)) {
    if (is.na(v)) return("")
    if (abs(v - round(v)) < 1e-9 && abs(v) < 1e7) return(format(round(v)))
    return(formatC(v, format = "f", digits = if (abs(v) >= 100) 1 else 3))
  }
  as.character(v)
}

html_table <- function(df, status_col = NULL, header = TRUE) {
  df <- as.data.frame(df)
  h <- htmltools::tags
  rows <- lapply(seq_len(nrow(df)), function(i) {
    h$tr(lapply(names(df), function(nm) {
      v <- format_cell(df[[nm]][i])
      if (!is.null(status_col) && nm == status_col)
        h$td(h$span(class = paste("pill", v), v))
      else h$td(class = if (is.numeric(df[[nm]])) "num", v)
    }))
  })
  h$div(class = "table-wrap",
        h$table(if (header) h$thead(h$tr(lapply(names(df), h$th))), h$tbody(rows)))
}

plot_img <- function(p, width = 7, height = 4, dpi = 110) {
  f <- tempfile(fileext = ".png")
  on.exit(unlink(f))
  if (!render_png(p, f, width, height, dpi))
    stop("Could not save a plot as PNG on this system. Reinstalling the 'ragg' ",
         "package usually fixes this: install.packages(\"ragg\")", call. = FALSE)
  htmltools::tags$img(src = paste0("data:image/png;base64,", base64enc::base64encode(f)),
                      style = "max-width:100%;height:auto;", alt = "")
}

# Try PNG devices in turn until one writes the file. ragg is tried first
# because it needs no system libraries; the base png() types differ by platform (quartz on macOS, cairo
# or Xlib elsewhere), and some, such as cairo on macOS without XQuartz, fail.
render_png <- function(p, f, width, height, dpi) {
  devices <- list()
  devices$ragg <- function() ragg::agg_png(f, width = width, height = height,
                                             units = "in", res = dpi)
  devices$default <- function() grDevices::png(f, width = width, height = height,
                                               units = "in", res = dpi)
  for (type in c("quartz", "cairo", "Xlib"))
    devices[[type]] <- local({
      tp <- type
      function() grDevices::png(f, width = width, height = height, units = "in",
                                res = dpi, type = tp)
    })
  for (open_dev in devices) {
    unlink(f)
    ok <- tryCatch({
      before <- grDevices::dev.list()
      suppressWarnings(open_dev())
      dev <- setdiff(grDevices::dev.list(), before)
      if (!length(dev)) stop("no device opened")
      dev <- dev[1]
      tryCatch(print(p), finally = grDevices::dev.off(dev))
      file.exists(f) && file.size(f) > 0
    }, error = function(e) FALSE)
    if (isTRUE(ok)) return(TRUE)
  }
  FALSE
}

report_css <- "
:root{--bg:#ffffff;--fg:#1d2733;--muted:#5b6876;--line:#e3e8ee;--accent:#2C5F8A;--soft:#f5f8fb}
@media (prefers-color-scheme: dark){:root{--bg:#14191f;--fg:#e6ebf0;--muted:#9aa7b4;--line:#2a333d;--accent:#8db8de;--soft:#1b222a}
img{background:#fff;border-radius:6px}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.55 system-ui,-apple-system,'Segoe UI',Roboto,sans-serif}
main{max-width:1040px;margin:0 auto;padding:32px 20px 80px}
h1{font-size:30px;margin:0 0 4px;color:var(--accent)}
h2{font-size:22px;margin:44px 0 12px;padding-bottom:6px;border-bottom:2px solid var(--line)}
h3{font-size:16px;margin:22px 0 8px}
.meta{color:var(--muted);margin:0 0 20px}
.toc{background:var(--soft);border:1px solid var(--line);border-radius:8px;padding:12px 18px}
.toc ol{margin:6px 0 0;padding-left:20px;columns:2}
a{color:var(--accent)}
.table-wrap{overflow-x:auto;margin:8px 0 16px}
table{border-collapse:collapse;font-size:13.5px;min-width:50%}
th,td{padding:6px 10px;border-bottom:1px solid var(--line);text-align:left;white-space:nowrap}
th{background:var(--soft);font-weight:600}
td.num{text-align:right;font-variant-numeric:tabular-nums}
.pill{display:inline-block;padding:1px 9px;border-radius:10px;color:#fff;font-size:12px;font-weight:600;text-transform:uppercase}
.pill.green{background:#2E8B57}.pill.amber{background:#C9861F}.pill.red{background:#C23B4E}
.interp ul{margin:4px 0 10px;padding-left:20px}
.card{border:1px solid var(--line);border-radius:10px;padding:10px;margin:14px 0}
pre{background:var(--soft);border:1px solid var(--line);border-radius:8px;padding:12px;overflow-x:auto;font-size:13px}
details summary{cursor:pointer;color:var(--muted)}
"

save_page <- function(body, file, title) {
  html <- c("<!DOCTYPE html>", "<html lang=\"en\">", "<head>",
            "<meta charset=\"utf-8\">",
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
            paste0("<title>", htmltools::htmlEscape(title), "</title>"),
            "<style>", report_css, "</style>", "</head>", "<body>", "<main>",
            enc2utf8(as.character(body)), "</main>", "</body>", "</html>")
  con <- file(file, open = "w", encoding = "UTF-8")
  on.exit(close(con))
  writeLines(html, con)
  invisible(file)
}
