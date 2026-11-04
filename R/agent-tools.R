# Tools of the analysis agent server (mv_agent_server(), mode "analysis").
# Each tool runs a mirtverse step on the project's data, keeps the result in
# the server's R session, and appends the equivalent R code to ctx$script so
# save_script can write a reproducible analysis.

agent_tool <- function(...) mcp_tool(..., modes = "analysis")

p_nums <- function(description) list(type = "array", items = list(type = "number"),
                                     description = description)

agent_models <- c("auto", "Rasch", "2PL", "3PL", "graded", "gpcm")
agent_plots <- c("trace", "info", "test_info", "se", "itemfit", "wright", "scores", "dif")

agent_tools <- function() {
  model_arg <- p_str("Model name from fit_model (default: the most recent model).")
  list(
    agent_tool("project_overview",
      "Start here. Lists the data files in the project folder, the models fitted so far (in this session or saved by an earlier one), and the files written to mirtverse-output.",
      handler = tool_project_overview, title = "Project overview", read_only = TRUE),
    agent_tool("guide",
      "Returns a guide for analyzing test data with these tools. Topics: 'analysis' (the workflow, which model and which checks, how to ask the user about columns; read before the first analysis) and 'interpreting' (rules of thumb for model fit, item fit, discrimination, reliability, DIF effect sizes, and how to explain them in plain language).",
      list(topic = p_str("Guide to read.", names(agent_guide_topics))),
      "topic", function(args, ctx) guide_text(args$topic %||% "analysis"),
      title = "Guide", read_only = TRUE),
    agent_tool("fit_model",
      "Fits an IRT model to item responses and keeps it under a name. With model = 'auto' (default) it compares the Rasch, 2PL and 3PL models (graded and GPCM for polytomous items) with select_model() and keeps the best by BIC, explaining the choice. Returns overall fit, reliability and item parameters. Run describe_dataset first to pick the item columns.",
      list(data = p_str("A data file relative to the project folder (.csv, .tsv, .xlsx, .sav, .dta, .rds, .rda) or a dataset from mirtverse or mirt, e.g. 'SAT12'."),
           items = p_strs("Item columns. Default: the columns describe_dataset marks as items."),
           model = p_str("Model to fit.", agent_models),
           nfact = p_int("Number of dimensions, 1 to 3 (default 1). Plots and item checks need 1."),
           missing = p_nums("Codes that mean 'missing', e.g. [9, 99]. NA and empty cells are already missing."),
           key = p_strs("Answer key, one entry per item, when the responses are unscored (letters or option numbers)."),
           name = p_str("Name to keep the model under (default 'model', or 'model2' ... when taken)."),
           object = p_str("For .rda files with several objects: which one.")),
      "data", tool_fit_model, title = "Fit model"),
    agent_tool("check_items",
      "Item-by-item health check of a unidimensional model: proportion correct or mean score, item-total correlation, discrimination, location (difficulty), S-X2 item fit with RMSEA, and flags (misfit, low discrimination, extreme difficulty, negative item-total correlation).",
      list(model = model_arg,
           alpha = list(type = "number", description = "Significance level for item misfit (default 0.01)."),
           p_adjust = p_str("P-value adjustment across items (default 'none').", c("none", "BH", "holm", "bonferroni"))),
      handler = tool_check_items, title = "Check items", read_only = TRUE),
    agent_tool("check_dif",
      "Tests every item for differential item functioning (DIF) across the groups of a column of the model's data, with likelihood-ratio tests against an all-items-equal baseline and effect sizes on the score scale (ESD signed, UESD unsigned). Needs at least about 200 people per group for stable results.",
      list(model = model_arg,
           group = p_str("The grouping column in the model's data."),
           items = p_strs("Items to test (default all; untested items act as anchors)."),
           p_adjust = p_str("P-value adjustment (default 'BH').", c("BH", "holm", "bonferroni", "none")),
           alpha = list(type = "number", description = "Significance level (default 0.05).")),
      "group", tool_check_dif, title = "Check DIF"),
    agent_tool("score_people",
      "Estimates each person's ability (theta) with its standard error, writes them to a CSV in mirtverse-output (with the ID columns of the data), and reports the score distribution and reliability.",
      list(model = model_arg,
           method = p_str("Scoring method (default EAP).", c("EAP", "MAP", "ML", "WLE")),
           id = p_strs("ID or background columns to keep next to the scores (default: columns that look like IDs)."),
           file = p_str("File name inside mirtverse-output (default '<model>-scores.csv').")),
      handler = tool_score_people, title = "Score people"),
    agent_tool("plot_model",
      "Draws a plot of a unidimensional model, saves it as a PNG in mirtverse-output/plots and returns the image. Types: 'trace' (item characteristic curves), 'info' (item information), 'test_info' (test information), 'se' (standard error of measurement), 'itemfit' (item fit), 'wright' (persons and items on one scale), 'scores' (score distribution), 'dif' (DIF effect sizes; run check_dif first).",
      list(model = model_arg, type = p_str("Plot type.", agent_plots),
           items = p_strs("Items to show for 'trace', 'info' and 'dif' (default all; pick a few for long tests).")),
      "type", tool_plot_model, title = "Plot model"),
    agent_tool("interpret_model",
      "Plain-language interpretation of a model: overall fit, reliability, targeting, problem items, local dependence and person fit, plus the model comparison and DIF results when there are any. Use it as a basis and adapt the wording to the user.",
      list(model = model_arg),
      handler = tool_interpret_model, title = "Interpret model", read_only = TRUE),
    agent_tool("write_report",
      "Writes a self-contained HTML technical report of a unidimensional model (data summary, model choice, fit, items with health cards, DIF if checked, scores, and the R code) to mirtverse-output.",
      list(model = model_arg, title = p_str("Report title."), author = p_str("Author line."),
           file = p_str("File name inside mirtverse-output (default '<model>-report.html').")),
      handler = tool_write_report, title = "Write report"),
    agent_tool("save_script",
      "Writes the R code of every step run in this session (data, models, checks, plots, scores, reports and run_r code) to an .R file in mirtverse-output, so the analysis can be rerun or shared. Call it at the end.",
      list(file = p_str("File name inside mirtverse-output (default 'analysis.R').")),
      handler = tool_save_script, title = "Save R script"),
    agent_tool("run_r",
      "Runs R code in the server's R session, in the project folder, with mirtverse loaded. Fitted models are available under their names, with their data as <name>_data and the item responses as <name>_items. Returns the printed output and any plots. Use it only for what the other tools do not cover; look functions up with mirtverse_help first. The code is added to the saved script.",
      list(code = p_str("R code to run.")),
      "code", tool_run_r, title = "Run R code")
  )
}

# ---------------------------------------------------------------------------
# Helpers

agent_out <- function(ctx, ...) {
  dir <- file.path(ctx$root, agent_output_dir, ...)
  dir.create(if (length(list(...))) dirname(dir) else dir, recursive = TRUE, showWarnings = FALSE)
  dir
}

agent_out_file <- function(ctx, file, default) {
  file <- if (is.null(file) || !nzchar(file)) default else basename(file)
  agent_out(ctx, file)
}

agent_model_dir <- function(ctx) file.path(ctx$root, mcp_state_dir, "models")

agent_log <- function(ctx, ...) {
  if (!length(ctx$script)) ctx$script <- c("library(mirtverse)", "")
  ctx$script <- c(ctx$script, ..., "")
}

agent_saved_models <- function(ctx) {
  f <- list.files(agent_model_dir(ctx), pattern = "\\.rds$")
  sub("\\.rds$", "", f)
}

agent_model_names <- function(ctx) unique(c(ls(ctx$models), agent_saved_models(ctx)))

agent_get <- function(ctx, name = NULL) {
  if (is.null(name) || !nzchar(name)) {
    name <- ctx$last
    if (is.null(name)) {
      saved <- agent_saved_models(ctx)
      if (!length(saved)) stop("No model yet. Fit one with fit_model.", call. = FALSE)
      info <- file.info(file.path(agent_model_dir(ctx), paste0(saved, ".rds")))
      name <- saved[which.max(info$mtime)]
    }
  }
  if (!exists(name, envir = ctx$models, inherits = FALSE)) {
    f <- file.path(agent_model_dir(ctx), paste0(name, ".rds"))
    if (!file.exists(f))
      stop("No model called '", name, "'. Models: ",
           paste(agent_model_names(ctx), collapse = ", "), ".", call. = FALSE)
    rec <- readRDS(f)
    assign(name, rec, envir = ctx$models)
    agent_expose(ctx, rec)
    # a model from an earlier session: put its code first in the script
    agent_log(ctx, rec$code)
  }
  get(name, envir = ctx$models)
}

agent_put <- function(ctx, rec) {
  assign(rec$name, rec, envir = ctx$models)
  dir.create(agent_model_dir(ctx), recursive = TRUE, showWarnings = FALSE)
  saveRDS(rec, file.path(agent_model_dir(ctx), paste0(rec$name, ".rds")))
  agent_expose(ctx, rec)
  ctx$last <- rec$name
  invisible(rec)
}

# Code run in the session (run_r, plots) sees mirtverse and mirt as in a
# user's script
agent_session_ready <- function(ctx) {
  if (is.null(ctx$session_ready)) {
    suppressPackageStartupMessages(eval(quote(library(mirtverse)), ctx$session))
    ctx$session_ready <- TRUE
  }
  invisible(ctx)
}

# Make a model and its data visible to run_r under the names the script uses
agent_expose <- function(ctx, rec) {
  assign(rec$name, rec$fit, envir = ctx$session)
  assign(paste0(rec$name, "_data"), rec$data, envir = ctx$session)
  assign(paste0(rec$name, "_items"), rec$items_df, envir = ctx$session)
  if (!is.null(rec$selection)) assign(paste0(rec$name, "_sel"), rec$selection, envir = ctx$session)
  if (!is.null(rec$dif)) assign(paste0(rec$name, "_dif"), rec$dif, envir = ctx$session)
}

fmt_df <- function(df, digits = 3) {
  df <- as.data.frame(df)
  for (j in seq_along(df)) {
    v <- df[[j]]
    if (is.numeric(v)) df[[j]] <- fmt_num(v, digits)
    if (is.logical(v)) df[[j]] <- ifelse(v, "yes", "no")
  }
  df
}

fmt_num <- function(v, digits = 3) {
  out <- formatC(signif(v, digits), digits = digits, format = "fg")
  big <- !is.na(v) & abs(v) >= 100
  out[big] <- sprintf("%.1f", v[big])
  whole <- !is.na(v) & v == round(v) & abs(v) < 1e7
  out[whole] <- sprintf("%.0f", v[whole])
  tiny <- !is.na(v) & v != 0 & abs(v) < 0.001
  out[tiny] <- formatC(v[tiny], digits = 2, format = "e")
  out[is.na(v)] <- ""
  trimws(out)
}

# Code that reads the data, for the script
agent_read_code <- function(source, label, obj, object = NULL) {
  if (grepl("package)$", label)) {
    pkg <- sub("^.*\\((.*) package\\)$", "\\1", label)
    return(sprintf("%s <- as.data.frame(%s::%s)", obj, pkg, source))
  }
  ext <- tolower(tools::file_ext(label))
  if (ext %in% c("rda", "rdata"))
    return(sprintf("%s <- local({ e <- new.env(); objs <- load(\"%s\", envir = e); as.data.frame(get(%s, envir = e)) })",
                   obj, label, if (is.null(object)) "objs[1]" else sprintf("\"%s\"", object)))
  code_read(label, obj)
}

resolve_item_cols <- function(df, items, unscored = FALSE) {
  if (length(items)) {
    items <- unlist(items)
    if (length(items) == 1L && grepl(":", items)) items <- expand_ranges(items, names(df))
    bad <- setdiff(items, names(df))
    if (length(bad)) stop("Not columns of the data: ", paste(bad, collapse = ", "), call. = FALSE)
    return(items)
  }
  cols <- describe_columns(df)
  roles <- c("item (dichotomous)", "item (polytomous)", if (unscored) "item (unscored responses?)")
  items <- cols$column[cols$role %in% roles]
  if (length(items) < 3L)
    stop("Could not find item columns. Give them with `items` (see describe_dataset).", call. = FALSE)
  items
}

model_itemtype <- function(fit) {
  it <- unique(mirt::extract.mirt(fit, "itemtype"))
  if (length(it) == 1L) it else "mixed"
}

# ---------------------------------------------------------------------------
# Tools

tool_project_overview <- function(args, ctx) {
  files <- course_files(ctx)
  rel <- vapply(files, function(f) rel_path(ctx, f), "", USE.NAMES = FALSE)
  is_out <- startsWith(rel, paste0(agent_output_dir, "/"))
  is_data <- !is_out & tolower(tools::file_ext(rel)) %in%
    c("csv", "tsv", "txt", "xlsx", "xls", "sav", "dta", "sas7bdat", "rds", "rda", "rdata")
  size <- function(f) vapply(file.size(f), format_size, "")
  data_tab <- if (any(is_data)) data.frame(file = rel[is_data], size = size(files[is_data])) else NULL
  models <- agent_model_names(ctx)
  model_tab <- if (length(models)) do.call(rbind, lapply(models, function(m) {
    rec <- agent_get_quiet(ctx, m)
    if (is.null(rec)) return(NULL)
    data.frame(model = m, type = rec$itemtype, dimensions = rec$nfact, items = length(rec$item_cols),
               people = nrow(rec$items_df), data = rec$label,
               in_session = if (exists(m, envir = ctx$models, inherits = FALSE)) "yes" else "saved",
               stringsAsFactors = FALSE)
  })) else NULL
  out_tab <- if (any(is_out)) data.frame(file = rel[is_out], size = size(files[is_out])) else NULL
  paste0(
    "Project folder: ", ctx$root, "\n\n",
    "Data files:\n", if (is.null(data_tab)) "(none; datasets from mirtverse or mirt such as SAT12 or LSAT7 can be used by name)\n" else md_table(data_tab), "\n",
    "Models:\n", if (is.null(model_tab)) "(none yet)\n" else md_table(model_tab), "\n",
    "Output files (", agent_output_dir, "):\n", if (is.null(out_tab)) "(none yet)\n" else md_table(out_tab),
    if (!ctx$allow_run) "\nrun_r is turned off for this server.\n" else "")
}

agent_get_quiet <- function(ctx, name) {
  if (exists(name, envir = ctx$models, inherits = FALSE)) return(get(name, envir = ctx$models))
  tryCatch(readRDS(file.path(agent_model_dir(ctx), paste0(name, ".rds"))), error = function(e) NULL)
}

tool_fit_model <- function(args, ctx) {
  d <- load_dataset(args$data, ctx, args$object)
  df <- d$data
  item_cols <- resolve_item_cols(df, args$items, unscored = length(unlist(args$key)) > 0)
  model <- args$model %||% "auto"
  if (!model %in% agent_models) stop("`model` must be one of ", paste(agent_models, collapse = ", "), ".", call. = FALSE)
  nfact <- as.integer(args$nfact %||% 1L)
  if (is.na(nfact) || nfact < 1L || nfact > 3L) stop("`nfact` must be 1, 2 or 3.", call. = FALSE)
  name <- args$name %||% ""
  if (!nzchar(name)) {
    taken <- agent_model_names(ctx)
    name <- if (!"model" %in% taken) "model" else {
      k <- 2L
      while (paste0("model", k) %in% taken) k <- k + 1L
      paste0("model", k)
    }
  }
  name <- make.names(name)
  obj_data <- paste0(name, "_data")
  obj_items <- paste0(name, "_items")

  resp <- df[item_cols]
  code <- c(sprintf("# Model \"%s\" on %s", name, d$label),
            agent_read_code(args$data, d$label, obj_data, args$object),
            sprintf("%s <- %s[, %s]", obj_items, obj_data, code_names(item_cols)))
  miss <- unlist(args$missing)
  for (m in miss) {
    resp[!is.na(resp) & resp == m] <- NA
    code <- c(code, sprintf("%s[%s == %s] <- NA", obj_items, obj_items, m))
  }
  key <- unlist(args$key)
  if (length(key)) {
    if (length(key) != length(item_cols))
      stop("`key` needs one entry per item (", length(item_cols), ").", call. = FALSE)
    numeric_key <- all(grepl("^-?[0-9.]+$", key))
    if (numeric_key) key <- as.numeric(key)
    resp <- as.data.frame(mirt::key2binary(resp, key = key))
    names(resp) <- item_cols
    key_code <- if (numeric_key) paste(strwrap(sprintf("c(%s)", paste(key, collapse = ", ")),
                                               width = 72, exdent = 2), collapse = "\n") else code_names(key)
    code <- c(code, sprintf("%s <- as.data.frame(key2binary(%s, key = %s))", obj_items, obj_items,
                            key_code))
  }
  bad <- vapply(resp, function(v) !is.numeric(v), logical(1))
  if (any(bad))
    stop("These item columns are not numeric: ", paste(names(resp)[bad], collapse = ", "),
         ". Give an answer key with `key`, or leave them out of `items`.", call. = FALSE)
  keep <- rowSums(!is.na(resp)) > 0
  if (!all(keep)) {
    resp <- resp[keep, , drop = FALSE]
    df <- df[keep, , drop = FALSE]
    code <- c(code, sprintf("keep <- rowSums(!is.na(%s)) > 0  # drop people with no responses", obj_items),
              sprintf("%s <- %s[keep, ]", obj_items, obj_items), sprintf("%s <- %s[keep, ]", obj_data, obj_data))
  }
  resp <- as.data.frame(resp)
  rownames(resp) <- NULL
  sel <- NULL
  if (identical(model, "auto")) {
    sel <- select_model(resp, dims = nfact, verbose = FALSE)
    fit <- sel$best
    code <- c(code, sprintf("%s_sel <- select_model(%s%s)", name, obj_items,
                            if (nfact != 1L) sprintf(", dims = %d", nfact) else ""),
              sprintf("%s <- %s_sel$best", name, name))
  } else {
    fit <- mirt::mirt(resp, nfact, itemtype = model, verbose = FALSE)
    code <- c(code, sprintf("%s <- mirt(%s, %d, itemtype = \"%s\")", name, obj_items, nfact, model))
  }
  code <- c(code, sprintf("glance(%s)", name))
  rec <- list(name = name, fit = fit, selection = sel, data = df, items_df = resp,
              item_cols = item_cols, label = d$label, itemtype = model_itemtype(fit),
              nfact = nfact, code = code, dif = NULL)
  agent_put(ctx, rec)
  agent_log(ctx, code)

  g <- glance(fit)
  conv <- isTRUE(g$converged)
  overall <- fmt_df(g[intersect(c("nobs", "nitems", "nfact", "itemtype", "logLik", "AIC", "BIC",
                                  "M2", "df", "p.value", "RMSEA", "SRMSR", "CFI", "TLI",
                                  "reliability"), names(g))])
  pars <- tidy(fit)
  wide <- stats::reshape(as.data.frame(pars[c("item", "term", "estimate")]), idvar = "item",
                         timevar = "term", direction = "wide")
  names(wide) <- sub("^estimate\\.", "", names(wide))
  rownames(wide) <- NULL
  shown <- if (nrow(wide) > 60) utils::head(wide, 60) else wide
  paste0(
    "Fitted model '", name, "' on ", d$label, ": ", nrow(resp), " people, ", length(item_cols),
    " items, ", nfact, " dimension", if (nfact > 1) "s", ", item type ", rec$itemtype, ".\n",
    if (!conv) "WARNING: The model did not converge; treat the estimates with caution.\n" else "",
    if (!all(keep)) sprintf("%d people with no responses were left out.\n", sum(!keep)) else "",
    if (!is.null(sel)) paste0("\nModel comparison:\n", md_table(fmt_df(sel$table)), "\n",
                             paste(sel$explanation, collapse = " "), "\n") else "",
    "\nOverall fit:\n", md_table(overall), "\n",
    "Item parameters (IRT parameterization; b = location, a = discrimination):\n", md_table(fmt_df(shown)),
    if (nrow(wide) > 60) sprintf("... %d more items (use check_items or run_r).\n", nrow(wide) - 60) else "",
    "\nNext: check_items", if (nfact > 1) " (needs a unidimensional model)" else "",
    ", then check_dif if there is a group column, score_people, plot_model, interpret_model.")
}

tool_check_items <- function(args, ctx) {
  rec <- agent_get(ctx, args$model)
  alpha <- args$alpha %||% 0.01
  adj <- args$p_adjust %||% "none"
  tab <- item_table(rec$fit, p_adjust = adj, alpha = alpha)
  agent_log(ctx, sprintf("item_table(%s%s%s)", rec$name,
                         if (adj != "none") sprintf(", p_adjust = \"%s\"", adj) else "",
                         if (alpha != 0.01) sprintf(", alpha = %s", alpha) else ""))
  flagged <- tab[nzchar(tab$flag), , drop = FALSE]
  paste0("Item check for model '", rec$name, "' (", nrow(tab), " items, misfit at alpha = ", alpha,
         if (adj != "none") paste0(", ", adj, " adjusted") else "", "):\n\n",
         md_table(fmt_df(tab)), "\n",
         if (nrow(flagged)) paste0(nrow(flagged), " flagged: ",
                                   paste(sprintf("%s (%s)", flagged$item, flagged$flag), collapse = "; "), ".")
         else "No item is flagged.",
         "\nSee guide('interpreting') for what the flags mean and what to do.")
}

tool_check_dif <- function(args, ctx) {
  rec <- agent_get(ctx, args$model)
  group <- args$group
  if (!group %in% names(rec$data))
    stop("'", group, "' is not a column of the model's data. Columns: ",
         paste(setdiff(names(rec$data), rec$item_cols), collapse = ", "), ".", call. = FALSE)
  g <- rec$data[[group]]
  ok <- !is.na(g)
  sizes <- table(g[ok])
  if (length(sizes) < 2) stop("'", group, "' has fewer than two groups.", call. = FALSE)
  itype <- if (rec$itemtype %in% c("Rasch", "2PL", "3PL", "graded", "gpcm")) rec$itemtype else "2PL"
  items <- unlist(args$items)
  adj <- args$p_adjust %||% "BH"
  alpha <- args$alpha %||% 0.05
  res <- dif(rec$items_df[ok, , drop = FALSE], group = g[ok], model = itype,
             items = if (length(items)) items, p_adjust = adj, alpha = alpha)
  rec$dif <- res
  rec$dif_group <- group
  agent_put(ctx, rec)
  agent_log(ctx, sprintf("%s_dif <- dif(%s, group = %s[[\"%s\"]], model = \"%s\"%s%s%s)", rec$name,
                         paste0(rec$name, "_items"), paste0(rec$name, "_data"), group, itype,
                         if (length(items)) sprintf(", items = %s", code_names(items)) else "",
                         if (adj != "BH") sprintf(", p_adjust = \"%s\"", adj) else "",
                         if (alpha != 0.05) sprintf(", alpha = %s", alpha) else ""),
            sprintf("tidy(%s_dif)", rec$name))
  if (any(!ok)) agent_log(ctx, "# note: people with a missing group value were left out of the DIF analysis")
  small <- sizes[sizes < 200]
  paste0("DIF across '", group, "' for model '", rec$name, "' (", itype, "; reference group ",
         res$reference, "):\n",
         "Group sizes: ", paste(sprintf("%s = %d", names(sizes), as.integer(sizes)), collapse = ", "), "\n",
         if (length(small)) "WARNING: Some groups have fewer than 200 people, so the tests have little power and the effect sizes are unstable.\n" else "",
         if (any(!ok)) sprintf("%d people with a missing group value were left out.\n", sum(!ok)) else "",
         "\n", md_table(fmt_df(tidy(res))), "\n",
         paste(unlist(interpret(res)), collapse = "\n\n"),
         "\n\nplot_model with type = 'dif' shows the effect sizes.")
}

tool_score_people <- function(args, ctx) {
  rec <- agent_get(ctx, args$model)
  method <- args$method %||% "EAP"
  fs <- mirt::fscores(rec$fit, method = method, full.scores.SE = TRUE, verbose = FALSE)
  nf <- rec$nfact
  sc <- as.data.frame(fs)
  ids <- unlist(args$id)
  if (!length(ids)) {
    cols <- describe_columns(rec$data)
    ids <- cols$column[cols$role %in% c("id?", "group?")]
  }
  ids <- setdiff(intersect(ids, names(rec$data)), rec$item_cols)
  out <- cbind(rec$data[ids], sc)
  file <- agent_out_file(ctx, args$file, paste0(rec$name, "-scores.csv"))
  utils::write.csv(out, file, row.names = FALSE)
  rel <- rel_path(ctx, file)
  agent_log(ctx,
            sprintf("%s_scores <- fscores(%s, method = \"%s\", full.scores.SE = TRUE)", rec$name, rec$name, method),
            sprintf("write.csv(cbind(%s, %s_scores), \"%s\", row.names = FALSE)",
                    if (length(ids)) sprintf("%s_data[, %s, drop = FALSE]", rec$name, code_names(ids)) else
                      sprintf("data.frame(row = seq_len(nrow(%s_scores)))", rec$name),
                    rec$name, rel))
  th <- sc[[1]]
  se <- sc[[nf + 1]]
  rxx <- tryCatch(mirt::empirical_rxx(as.matrix(sc[c(1, nf + 1)])), error = function(e) NA)
  q <- stats::quantile(th, c(0, .25, .5, .75, 1), na.rm = TRUE)
  paste0("Scored ", nrow(sc), " people with ", method, " on model '", rec$name, "'; saved to ", rel,
         if (length(ids)) paste0(" with ", paste(ids, collapse = ", ")) else "", ".\n\n",
         sprintf("Theta%s: mean %.2f, SD %.2f; min %.2f, quartiles %.2f / %.2f / %.2f, max %.2f.\n",
                 if (nf > 1) " (first dimension)" else "", mean(th, na.rm = TRUE), stats::sd(th, na.rm = TRUE),
                 q[1], q[2], q[3], q[4], q[5]),
         sprintf("Standard error: median %.2f (range %.2f to %.2f).\n", stats::median(se, na.rm = TRUE),
                 min(se, na.rm = TRUE), max(se, na.rm = TRUE)),
         if (is.finite(rxx)) sprintf("Empirical reliability of the scores: %.2f.\n", rxx) else "",
         "Columns: ", paste(names(out), collapse = ", "), ".")
}

tool_plot_model <- function(args, ctx) {
  rec <- agent_get(ctx, args$model)
  type <- args$type %||% "trace"
  if (!type %in% agent_plots) stop("`type` must be one of ", paste(agent_plots, collapse = ", "), ".", call. = FALSE)
  items <- unlist(args$items)
  it_arg <- if (length(items)) sprintf(", which.items = %s", code_names(items)) else ""
  if (identical(type, "dif") && is.null(rec$dif)) stop("Run check_dif first.", call. = FALSE)
  call_code <- switch(type,
    trace = sprintf("gg_trace(%s%s)", rec$name, it_arg),
    info = sprintf("gg_info(%s, type = \"items\"%s)", rec$name, it_arg),
    test_info = sprintf("gg_info(%s, type = \"test\")", rec$name),
    se = sprintf("gg_info(%s, type = \"se\")", rec$name),
    itemfit = sprintf("gg_itemfit(%s)", rec$name),
    wright = sprintf("gg_wright(%s)", rec$name),
    scores = sprintf("gg_scores(%s)", rec$name),
    dif = sprintf("gg_dif(%s_dif%s)", rec$name,
                  if (length(items)) sprintf(", type = \"curves\", which.items = %s", code_names(items)) else ""))
  agent_session_ready(ctx)
  p <- eval(parse(text = call_code)[[1]], envir = ctx$session)
  n_panels <- if (type %in% c("trace", "info") && is.null(items)) length(rec$item_cols) else 1
  height <- if (n_panels > 12) min(4 + ceiling(n_panels / 4) * 1.6, 14) else 5
  file <- agent_out(ctx, "plots", sprintf("%s-%s.png", rec$name, type))
  ggplot2::ggsave(file, p, width = 8, height = height, dpi = 110, device = ragg::agg_png)
  rel <- rel_path(ctx, file)
  agent_log(ctx, sprintf("ggplot2::ggsave(\"%s\", %s, width = 8, height = %s)", rel, call_code, height))
  list(text = paste0("Saved ", rel, " (", call_code, ")."), images = file)
}

tool_interpret_model <- function(args, ctx) {
  rec <- agent_get(ctx, args$model)
  parts <- character()
  if (!is.null(rec$selection))
    parts <- c(parts, paste0("## Model selection\n", paste(unlist(interpret(rec$selection)), collapse = " ")))
  it <- tryCatch(interpret(rec$fit), error = function(e) NULL)
  if (!is.null(it))
    parts <- c(parts, vapply(names(it), function(n) paste0("## ", n, "\n", paste(it[[n]], collapse = "\n")), ""))
  else parts <- c(parts, "(A detailed interpretation needs a unidimensional model.)")
  if (!is.null(rec$dif))
    parts <- c(parts, paste0("## DIF across ", rec$dif_group, "\n", paste(unlist(interpret(rec$dif)), collapse = "\n\n")))
  agent_log(ctx, sprintf("interpret(%s)", rec$name))
  paste0("Interpretation of model '", rec$name, "' (", rec$label, "):\n\n", paste(parts, collapse = "\n\n"))
}

tool_write_report <- function(args, ctx) {
  rec <- agent_get(ctx, args$model)
  if (rec$nfact > 1) stop("The report needs a unidimensional model.", call. = FALSE)
  file <- agent_out_file(ctx, args$file, paste0(rec$name, "-report.html"))
  if (!grepl("\\.html?$", file)) file <- paste0(file, ".html")
  title <- args$title %||% paste("IRT analysis of", rec$label)
  x <- rec$selection %||% rec$fit
  code <- c(if (length(ctx$script)) ctx$script else c("library(mirtverse)", rec$code))
  mv_report(x, file = file, title = title, author = args$author, dif = rec$dif,
            code = code, open = FALSE)
  rel <- rel_path(ctx, file)
  agent_log(ctx, sprintf("mv_report(%s, file = \"%s\", title = \"%s\"%s%s)",
                         if (is.null(rec$selection)) rec$name else paste0(rec$name, "_sel"),
                         rel, gsub("\"", "\\\\\"", title),
                         if (!is.null(args$author)) sprintf(", author = \"%s\"", args$author) else "",
                         if (!is.null(rec$dif)) sprintf(", dif = %s_dif", rec$name) else ""))
  paste0("Wrote the report to ", rel, " (", format_size(file.size(file)), "). It opens in any web browser.")
}

tool_save_script <- function(args, ctx) {
  if (!length(ctx$script)) stop("Nothing has been run in this session yet.", call. = FALSE)
  file <- agent_out_file(ctx, args$file, "analysis.R")
  if (!grepl("\\.R$", file, ignore.case = TRUE)) file <- paste0(file, ".R")
  head <- c("# mirtverse analysis written by the mirtverse agent",
            sprintf("# %s. Run it from the project folder: %s", format(Sys.Date()), ctx$root), "")
  write_lines_utf8(c(head, ctx$script), file)
  rel <- rel_path(ctx, file)
  paste0("Saved ", length(ctx$script), " lines of R code to ", rel,
         ". Run it from the project folder with source(\"", rel, "\") to reproduce the analysis.")
}

tool_run_r <- function(args, ctx) {
  if (!ctx$allow_run) stop("Running R code is turned off for this server (allow_run = FALSE).", call. = FALSE)
  code <- args$code %||% ""
  exprs <- parse(text = code, keep.source = FALSE)
  agent_session_ready(ctx)
  plot_dir <- tempfile("mvplots")
  dir.create(plot_dir)
  ragg::agg_png(file.path(plot_dir, "plot-%03d.png"), width = 880, height = 560, res = 110)
  dev <- grDevices::dev.cur()
  old <- setwd(ctx$root)
  on.exit({
    setwd(old)
    if (dev %in% grDevices::dev.list()) grDevices::dev.off(dev)
  }, add = TRUE)
  setTimeLimit(elapsed = ctx$timeout, transient = TRUE)
  on.exit(setTimeLimit(elapsed = Inf), add = TRUE)
  out <- utils::capture.output({
    for (e in exprs) {
      r <- withVisible(eval(e, ctx$session))
      if (r$visible) print(r$value)
    }
  })
  grDevices::dev.off(dev)
  plots <- list.files(plot_dir, full.names = TRUE)
  plots <- plots[file.size(plots) > 0]
  saved <- character()
  if (length(plots)) {
    stamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
    for (i in seq_along(plots)) {
      dest <- agent_out(ctx, "plots", sprintf("run-%s-%d.png", stamp, i))
      file.copy(plots[i], dest, overwrite = TRUE)
      saved <- c(saved, dest)
    }
  }
  agent_log(ctx, "# run_r", code)
  if (length(out) > 400) out <- c(utils::head(out, 400), sprintf("... (%d more lines)", length(out) - 400))
  list(text = paste0(if (length(out)) paste(out, collapse = "\n") else "(no printed output)",
                     if (length(saved)) paste0("\n\nPlots saved: ",
                                               paste(vapply(saved, function(f) rel_path(ctx, f), ""),
                                                     collapse = ", ")) else ""),
       images = saved)
}
