# Code templates shared by mv_ask() and the workbench. Each helper returns
# lines of R code; render_script() assembles them from an analysis plan.

code_read <- function(name, obj = "data") {
  ext <- tolower(tools::file_ext(name))
  rhs <- switch(ext,
    csv = sprintf("read.csv(\"%s\", check.names = FALSE)", name),
    tsv = , txt = sprintf("read.delim(\"%s\", check.names = FALSE)", name),
    xlsx = , xls = sprintf("as.data.frame(readxl::read_excel(\"%s\"))", name),
    sav = sprintf("as.data.frame(haven::zap_labels(haven::read_sav(\"%s\")))", name),
    dta = sprintf("as.data.frame(haven::zap_labels(haven::read_dta(\"%s\")))", name),
    sas7bdat = sprintf("as.data.frame(haven::zap_labels(haven::read_sas(\"%s\")))", name),
    rds = sprintf("as.data.frame(readRDS(\"%s\"))", name),
    stop("Unsupported file type: ", ext, call. = FALSE))
  sprintf("%s <- %s", obj, rhs)
}

code_missing <- function(obj, miss) sprintf("%s[%s == %s] <- NA", obj, obj, miss)

code_key <- function(obj, key)
  sprintf("%s <- as.data.frame(key2binary(%s, key = c(%s)))", obj, obj,
          paste(key, collapse = ", "))

code_select_model <- function(obj, dims = 1, criterion = "BIC")
  c(sprintf("sel <- select_model(%s%s%s)", obj,
            if (length(dims) > 1 || dims != 1) sprintf(", dims = %s", deparse(as.integer(dims))) else "",
            if (criterion != "BIC") sprintf(", criterion = \"%s\"", criterion) else ""),
    "sel", "mod <- sel$best")

code_mirt <- function(obj, nfact, itemtype)
  sprintf("mod <- mirt(%s, %d, itemtype = \"%s\")", obj, as.integer(nfact), itemtype)

# Quote a column name for use after `$` when it is not syntactic
code_name <- function(x) ifelse(make.names(x) == x, x, sprintf("`%s`", x))

code_names <- function(x) {
  s <- sprintf("c(%s)", paste(sprintf("\"%s\"", x), collapse = ", "))
  if (nchar(s) <= 70) return(s)
  paste(strwrap(s, width = 72, exdent = 2), collapse = "\n")
}

# Assemble the full script for a checked plan
render_script <- function(plan, request = NULL) {
  steps <- plan$steps
  opt <- function(step, name, default) {
    v <- plan$options[[step]][[name]]
    if (is.null(v)) default else v
  }
  sec <- function(title, ...) c("", paste("#", title), ...)
  unidim <- plan$nfact == 1L
  src <- plan$data
  out <- c("# Analysis script written by mirtverse::mv_ask()",
           sprintf("# %s", format(Sys.time(), "%Y-%m-%d %H:%M")),
           if (!is.null(request)) paste("# Request:", strwrap(request, 70, exdent = 2, prefix = "")),
           if (length(plan$assumptions))
             c("# Assumptions:", paste("#  -", plan$assumptions)),
           "library(mirtverse)")

  out <- c(out, sec("Data",
    if (is_file_path(src)) code_read(src, "raw") else sprintf("raw <- %s", src),
    if (setequal(plan$items, plan$columns)) "items <- raw"
    else sprintf("items <- raw[, %s]", code_names(plan$items)),
    if (length(plan$missing)) code_missing("items", plan$missing),
    if (length(plan$key)) code_key("items", plan$key),
    if (!is.null(plan$group)) sprintf("group <- raw$%s", code_name(plan$group)),
    if (length(plan$rt)) sprintf("rt <- raw[, %s]", code_names(plan$rt))))

  if ("describe" %in% steps)
    out <- c(out, sec("Describe the items", "itemstats(items)"))

  if (plan$model == "auto") {
    out <- c(out, sec("Choose and fit a model",
      code_select_model("items", seq_len(plan$nfact), opt("fit", "criterion", "BIC"))))
  } else {
    out <- c(out, sec(sprintf("Fit the %s model", model_label(plan$model)),
                      code_mirt("items", plan$nfact, plan$model), "glance(mod)"))
  }

  if ("fitcheck" %in% steps)
    out <- c(out, sec("Check model and item fit", "item_table(mod)",
                      if (unidim) c("gg_itemfit(mod)", "gg_q3(mod)")))

  if ("dif" %in% steps) {
    model <- if (plan$model == "auto") "extract.mirt(mod, \"itemtype\")[1]"
             else sprintf("\"%s\"", plan$model)
    out <- c(out, sec(sprintf("Differential item functioning by %s", plan$group),
                      sprintf("dif_res <- dif(items, group = group, model = %s)", model),
                      "dif_res", "gg_dif(dif_res)", "interpret(dif_res)"))
  }

  if ("scores" %in% steps) {
    method <- opt("scores", "method", "EAP")
    file <- opt("scores", "file", NULL)
    out <- c(out, sec("Person scores",
      sprintf("scores <- augment(mod, method = \"%s\")", method),
      if (unidim) "gg_scores(mod)",
      if (!is.null(file)) sprintf("write.csv(scores, \"%s\", row.names = FALSE)", file)))
  }

  if ("plots" %in% steps && unidim)
    out <- c(out, sec("Graphics", "gg_trace(mod)", "gg_info(mod)", "gg_wright(mod)"))

  if ("interpret" %in% steps)
    out <- c(out, sec("Plain-language summary", "interpret(mod)"))

  if ("cards" %in% steps)
    out <- c(out, sec("Item health cards",
      sprintf("item_cards(mod, file = \"%s\")", opt("cards", "file", "item-cards.html"))))

  if ("rt" %in% steps)
    out <- c(out, sec("Response times",
                      "rt_fit <- fit_rt(mod, rt)", "rt_fit", "interpret(rt_fit)"))

  if ("report" %in% steps)
    out <- c(out, sec("Report",
      sprintf("mv_report(%s, file = \"%s\"%s)",
              if (plan$model == "auto") "sel" else "mod",
              opt("report", "file", "mirtverse-report.html"),
              if ("dif" %in% steps) ", dif = dif_res" else "")))
  out
}

data_exts <- c("csv", "tsv", "txt", "xlsx", "xls", "sav", "dta", "sas7bdat", "rds")

is_file_path <- function(x) tolower(tools::file_ext(x)) %in% data_exts

model_label <- function(model)
  switch(model, Rasch = "Rasch", graded = "graded response", gpcm = "generalized partial credit",
         model)
