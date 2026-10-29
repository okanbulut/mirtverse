#' Set up an AI model for mv_ask()
#'
#' Chooses which AI model [mv_ask()] uses to understand plain-language
#' requests and stores the API key so you only do this once. Three providers
#' are supported through the ellmer package:
#'
#' * `"claude"`: Anthropic's Claude, with your own key from
#'   <https://console.anthropic.com> (stored as `ANTHROPIC_API_KEY`).
#' * `"openai"`: OpenAI's GPT models, with your own key from
#'   <https://platform.openai.com> (stored as `OPENAI_API_KEY`).
#' * `"ollama"`: a free model running on your own computer with Ollama
#'   (<https://ollama.com>). Install Ollama, run `ollama pull qwen2.5` (or
#'   another model) once, and nothing ever leaves your machine.
#'
#' Use `provider = "none"` to always use the built-in keyword parser, which
#' needs no AI model and no internet connection.
#'
#' Only a summary of your columns (see [profile_data()]) and your request are
#' sent; never individual responses. Keys are never written into scripts,
#' reports or `mv_script` objects.
#'
#' @param provider `"claude"`, `"openai"`, `"ollama"` or `"none"`.
#' @param model model name; defaults to `"claude-opus-5-5"` for Claude, the
#'   ellmer default for OpenAI and the first installed model for Ollama.
#' @param key the API key. If `NULL` and none is set, you are asked for it
#'   with a masked prompt.
#' @param save where to keep the key and settings for future sessions:
#'   `"ask"` (choose interactively), `"renviron"` (your `.Renviron` file),
#'   `"keyring"` (the system keychain, needs the keyring package) or `"none"`
#'   (this session only).
#' @param test logical; send one tiny test request to check the setup.
#' @return The provider and model, invisibly.
#' @examples
#' \dontrun{
#' mv_ask_setup("claude")
#' mv_ask_setup("ollama", model = "qwen2.5")
#' }
#' @export
mv_ask_setup <- function(provider = c("claude", "openai", "ollama", "none"), model = NULL,
                         key = NULL, save = c("ask", "renviron", "keyring", "none"),
                         test = TRUE) {
  provider <- match.arg(provider)
  save <- match.arg(save)
  if (provider != "none" && !requireNamespace("ellmer", quietly = TRUE))
    stop("Install the ellmer package to use an AI model: install.packages(\"ellmer\").", call. = FALSE)
  if (provider == "ollama") {
    installed <- ollama_models()
    if (is.null(installed))
      stop("Ollama is not running. Install it from https://ollama.com, start it, then run ",
           "`ollama pull qwen2.5` in a terminal to download a model.", call. = FALSE)
    if (!length(installed))
      stop("Ollama is running but has no models. Run `ollama pull qwen2.5` in a terminal.", call. = FALSE)
    if (is.null(model)) model <- installed[1]
    if (!model %in% installed && !paste0(model, ":latest") %in% installed)
      stop(sprintf("Model \"%s\" is not installed in Ollama. Installed: %s.", model,
                   paste(installed, collapse = ", ")), call. = FALSE)
  }
  var <- key_vars[provider]
  if (!is.na(var)) {
    if (is.null(key)) key <- provider_key(provider)
    if (!nzchar(key %||% "")) {
      if (!interactive())
        stop(sprintf("No API key found. Pass `key = ` or set %s.", var), call. = FALSE)
      key <- ask_secret(sprintf("Paste your %s API key", provider_label(provider)))
    }
    if (!nzchar(key %||% "")) stop("No key entered.", call. = FALSE)
    do.call(Sys.setenv, stats::setNames(list(key), var))
  }
  options(mirtverse.provider = provider, mirtverse.model = model)

  if (test && provider != "none") {
    ok <- tryCatch({
      ch <- make_chat(provider, model, "Reply with the single word OK.")
      nzchar(ch$chat("Test", echo = "none"))
    }, error = function(e) stop("The test request failed: ", conditionMessage(e), call. = FALSE))
    if (isTRUE(ok)) message(sprintf("%s is working.", provider_label(provider, model)))
  }

  if (save == "ask") {
    save <- if (!interactive()) "none" else {
      choices <- c("my .Renviron file (plain text in your home folder)",
                   if (!is.na(var) && requireNamespace("keyring", quietly = TRUE))
                     "the system keychain (keyring package)",
                   "don't save; ask again next session")
      pick <- utils::menu(choices, title = "Where should these settings be saved?")
      if (pick == 0) "none" else c("renviron", if (length(choices) == 3) "keyring", "none")[pick]
    }
  }
  if (save == "keyring") {
    if (is.na(var)) save <- "renviron" else {
      if (!requireNamespace("keyring", quietly = TRUE))
        stop("Install the keyring package to save the key in the system keychain.", call. = FALSE)
      keyring::key_set_with_value("mirtverse", provider, key)
      set_renviron(c(MIRTVERSE_PROVIDER = provider, MIRTVERSE_MODEL = model %||% ""))
      message("Key saved in the system keychain; provider saved in .Renviron.")
    }
  }
  if (save == "renviron") {
    vals <- c(MIRTVERSE_PROVIDER = provider, MIRTVERSE_MODEL = model %||% "")
    if (!is.na(var)) vals[var] <- key
    f <- set_renviron(vals)
    message(sprintf("Settings saved in %s.", f))
  }
  invisible(list(provider = provider, model = model))
}

key_vars <- c(claude = "ANTHROPIC_API_KEY", openai = "OPENAI_API_KEY", ollama = NA, none = NA)

`%||%` <- function(x, y) if (is.null(x) || (length(x) == 1L && is.na(x))) y else x

provider_label <- function(provider, model = NULL) {
  lab <- switch(provider, claude = "Claude", openai = "OpenAI GPT", ollama = "Ollama",
                none = , rules = "the built-in keyword parser")
  if (!is.null(model) && nzchar(model) && provider %in% c("claude", "openai", "ollama"))
    sprintf("%s (%s)", lab, model) else lab
}

provider_key <- function(provider) {
  var <- key_vars[[provider]]
  if (is.na(var)) return("")
  key <- Sys.getenv(var)
  if (!nzchar(key) && requireNamespace("keyring", quietly = TRUE))
    key <- tryCatch(suppressWarnings(suppressMessages(keyring::key_get("mirtverse", provider))),
                    error = function(e) "")
  key
}

ask_secret <- function(prompt) {
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable())
    return(rstudioapi::askForPassword(prompt))
  readline(paste0(prompt, ": "))
}

set_renviron <- function(vals, file = getOption("mirtverse.renviron",
                                                Sys.getenv("R_ENVIRON_USER", "~/.Renviron"))) {
  file <- path.expand(file)
  lines <- if (file.exists(file)) readLines(file, warn = FALSE) else character()
  keep <- !grepl(sprintf("^(%s)=", paste(names(vals), collapse = "|")), lines)
  writeLines(c(lines[keep], sprintf("%s=%s", names(vals), vals)), file)
  invisible(file)
}

ollama_models <- function(base_url = Sys.getenv("OLLAMA_BASE_URL", "http://localhost:11434")) {
  out <- tryCatch(suppressWarnings(ellmer::models_ollama(base_url = base_url)),
                  error = function(e) NULL)
  if (is.null(out)) return(NULL)
  as.character(out$id %||% out$name %||% out[[1]])
}

# Which provider to use: explicit argument, then session option, then
# .Renviron setting, then whichever API key is available; otherwise rules
ask_provider <- function(provider = NULL) {
  p <- provider %||% getOption("mirtverse.provider") %||%
    (if (nzchar(Sys.getenv("MIRTVERSE_PROVIDER"))) Sys.getenv("MIRTVERSE_PROVIDER"))
  if (is.null(p)) {
    p <- if (nzchar(Sys.getenv("ANTHROPIC_API_KEY"))) "claude" else
      if (nzchar(Sys.getenv("OPENAI_API_KEY"))) "openai" else "rules"
  }
  p <- match.arg(p, c("claude", "openai", "ollama", "none", "rules"))
  if (p == "none") p <- "rules"
  if (p != "rules" && !requireNamespace("ellmer", quietly = TRUE)) {
    message("The ellmer package is not installed, so the built-in keyword parser is used.")
    p <- "rules"
  }
  p
}

ask_model <- function(provider, model = NULL) {
  model <- model %||% getOption("mirtverse.model") %||%
    (if (nzchar(Sys.getenv("MIRTVERSE_MODEL"))) Sys.getenv("MIRTVERSE_MODEL"))
  if (is.null(model) && provider == "claude") model <- "claude-opus-5-5"
  if (is.null(model) && provider == "ollama") {
    installed <- ollama_models()
    if (!length(installed))
      stop("No Ollama model is available; run mv_ask_setup(\"ollama\").", call. = FALSE)
    model <- installed[1]
  }
  model
}

make_chat <- function(provider, model, system_prompt) {
  key <- provider_key(provider)
  var <- key_vars[[provider]]
  if (!is.na(var) && !nzchar(key))
    stop(sprintf("No %s API key; run mv_ask_setup(\"%s\").", provider_label(provider), provider),
         call. = FALSE)
  if (!is.na(var) && !nzchar(Sys.getenv(var))) {
    old <- Sys.getenv(var, unset = NA)
    do.call(Sys.setenv, stats::setNames(list(key), var))
    on.exit(if (is.na(old)) Sys.unsetenv(var), add = TRUE)
  }
  switch(provider,
    claude = ellmer::chat_anthropic(system_prompt = system_prompt, model = model, echo = "none"),
    openai = suppressMessages(ellmer::chat_openai(system_prompt = system_prompt, model = model,
                                                   echo = "none")),
    ollama = ellmer::chat_ollama(system_prompt = system_prompt, model = model, echo = "none"))
}

# ---- What the model sees -----------------------------------------------------

ask_system_prompt <- function() paste(
  "You turn a researcher's plain-language request into an analysis plan for item response theory (IRT) in R.",
  "You never see the data, only a summary of its columns. Fill in the plan; do not write code.",
  "",
  "Rules:",
  "- Use column names exactly as listed. Never invent columns.",
  "- items: the item columns. Leave empty to use every column whose guessed role is 'item'. A grouping column is never an item.",
  "- model: 'auto' compares candidate models; use it unless the request names a model. Rasch = 1PL. 2PL and 3PL need items scored 0/1; for items with more than two categories use 'graded' (graded response) or 'gpcm' (generalized partial credit).",
  "- nfact: number of dimensions; 1 unless the request asks for more.",
  "- group: the column to compare for differential item functioning (DIF, bias, fairness, invariance). Only set it when DIF is requested.",
  "- missing: numeric codes that the request says mean missing.",
  "- rt: response-time columns, one per item in item order, only if response times are requested.",
  "- steps: describe (item statistics), fitcheck (model and item fit, local dependence), dif, scores (person ability estimates), plots (item and test curves, Wright map), interpret (plain-language summary), cards (item health cards), report (HTML report), rt (response-time model). If the request does not say what output it wants, use describe, fitcheck and interpret. A model is always fitted, so it is not a step.",
  "- When a current plan is given, the request is a change to it: return the whole updated plan, changing only what the request asks.",
  "- assumptions: one short sentence for each choice the request did not state explicitly, e.g. which column you took as the group.",
  "- questions: anything essential you could not determine (for example DIF is requested but no column could be the group). Do not guess in that case.",
  sep = "\n")

ask_payload <- function(request, profile, prev = NULL, anonymize = FALSE) {
  cols <- profile$column
  code <- if (anonymize) stats::setNames(sprintf("V%d", seq_along(cols)), cols) else
    stats::setNames(cols, cols)
  p <- as.data.frame(profile)
  num <- function(v) ifelse(is.na(v), "", format(signif(v, 4), trim = TRUE))
  lines <- sprintf("- %s | %s | %d | %s | %s | %s | %s | %s", code[p$column], p$type, p$n_distinct,
                   num(p$min), num(p$max), formatC(p$prop_missing, format = "f", digits = 2),
                   p$role, if (anonymize) "" else ifelse(is.na(p$levels), "", p$levels))
  req <- if (anonymize) anonymize_text(request, code) else request
  cur <- if (!is.null(prev)) {
    pl <- prev
    if (anonymize) {
      pl$items <- unname(code[pl$items] %||% pl$items)
      if (!is.null(pl$group)) pl$group <- unname(code[pl$group])
      if (length(pl$rt)) pl$rt <- unname(code[pl$rt])
    }
    c("", "Current plan (the request changes it):",
      sprintf("items: %s", paste(pl$items, collapse = ", ")),
      sprintf("model: %s; nfact: %d", pl$model, pl$nfact),
      sprintf("group: %s", pl$group %||% "none"),
      sprintf("missing: %s", if (length(pl$missing)) paste(pl$missing, collapse = ", ") else "none"),
      sprintf("rt: %s", if (length(pl$rt)) paste(pl$rt, collapse = ", ") else "none"),
      sprintf("steps: %s", paste(pl$steps, collapse = ", ")))
  }
  structure(paste(c(
    sprintf("Request: %s", req), "",
    sprintf("Data: %d rows, %d columns.", attr(profile, "n"), length(cols)),
    "Columns (name | type | distinct values | min | max | share missing | guessed role | categories):",
    lines, cur), collapse = "\n"),
    code = code)
}

anonymize_text <- function(text, code) {
  for (nm in names(code)[order(-nchar(names(code)))]) {
    pat <- sprintf("(?<![A-Za-z0-9_.])\\Q%s\\E(?![A-Za-z0-9_])", nm)
    text <- gsub(pat, code[[nm]], text, perl = TRUE, ignore.case = TRUE)
  }
  text
}

plan_type <- function() {
  ellmer::type_object(
    "An IRT analysis plan.",
    items = ellmer::type_array(ellmer::type_string(), "Item column names; empty for all likely items.",
                               required = FALSE),
    model = ellmer::type_enum(plan_models, "IRT model."),
    nfact = ellmer::type_integer("Number of latent dimensions (1 to 3)."),
    group = ellmer::type_string("Grouping column for DIF, or empty.", required = FALSE),
    missing = ellmer::type_array(ellmer::type_number(), "Missing-value codes.", required = FALSE),
    rt = ellmer::type_array(ellmer::type_string(), "Response-time columns in item order.",
                            required = FALSE),
    steps = ellmer::type_array(ellmer::type_enum(plan_steps), "Analysis steps."),
    score_method = ellmer::type_enum(c("EAP", "MAP", "ML", "WLE"), "Scoring method if requested.",
                                     required = FALSE),
    scores_file = ellmer::type_string("File name for the scores, if requested.", required = FALSE),
    report_file = ellmer::type_string("File name for the report, if requested.", required = FALSE),
    assumptions = ellmer::type_array(ellmer::type_string(), "Choices not stated in the request.",
                                     required = FALSE),
    questions = ellmer::type_array(ellmer::type_string(), "Essential information that is missing.",
                                   required = FALSE))
}

llm_call <- function(provider, model, payload) {
  chat <- make_chat(provider, model, ask_system_prompt())
  chat$chat_structured(payload, type = plan_type(), echo = "none")
}

# Ask the model for a plan and turn its answer into an mv_plan
llm_plan <- function(request, profile, provider, model, prev = NULL, anonymize = FALSE) {
  payload <- ask_payload(request, profile, prev, anonymize)
  res <- llm_call(provider, model, as.character(payload))
  code <- attr(payload, "code")
  back <- stats::setNames(names(code), code)
  unmap <- function(x) {
    x <- as.character(unlist(x))
    x <- x[nzchar(x)]
    if (!length(x)) return(NULL)
    unname(ifelse(x %in% names(back), back[x], x))
  }
  text_back <- function(x) {
    x <- as.character(unlist(x))
    if (!anonymize) return(x)
    for (v in names(back)[order(-nchar(names(back)))])
      x <- gsub(sprintf("\\b%s\\b", v), back[[v]], x, perl = TRUE)
    x
  }
  opts <- if (!is.null(prev)) prev$options else list()
  if (length(res$score_method)) opts$scores$method <- res$score_method
  if (length(res$scores_file) && nzchar(res$scores_file)) opts$scores$file <- res$scores_file
  if (length(res$report_file) && nzchar(res$report_file)) opts$report$file <- res$report_file
  group <- unmap(res$group)
  steps <- as.character(unlist(res$steps))
  if (is.null(group)) steps <- setdiff(steps, "dif")
  plan <- mv_plan(items = unmap(res$items), model = res$model %||% "auto",
                  nfact = res$nfact %||% 1, group = group,
                  missing = unlist(res$missing), rt = unmap(res$rt), steps = steps,
                  options = opts,
                  assumptions = text_back(c(if (!is.null(prev)) prev$assumptions, res$assumptions)))
  attr(plan, "questions") <- text_back(res$questions)
  plan
}
