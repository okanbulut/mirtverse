parse_dat <- local({
  set.seed(7)
  a <- matrix(rlnorm(6, 0.2, 0.25)); d <- matrix(rnorm(6))
  x <- as.data.frame(simdata(a, d, 400, itemtype = "2PL"))
  names(x) <- paste0("Q", 1:6)
  data.frame(id = seq_len(400), name = paste0("Person", seq_len(400)), x,
             gender = rep(c("F", "M"), 200), grade = rep(c(4, 5), each = 200))
})
prof <- profile_data(parse_dat)
rules <- function(req, prev = NULL) mirtverse:::parse_request_rules(req, prof, prev)

test_that("the keyword parser reads models, steps, groups and codes", {
  r <- rules("Fit a 2PL to my data, check DIF by gender, and make a report")
  expect_equal(r$fields$model, "2PL")
  expect_equal(r$fields$group, "gender")
  expect_setequal(r$fields$steps, c("dif", "report"))
  r <- rules("Rasch model for Q2 to Q5; missing values are coded 9 and 99. Save EAP scores to scores.csv")
  expect_equal(r$fields$model, "Rasch")
  expect_equal(r$fields$items, "Q2:Q5")
  expect_equal(r$fields$missing, c(9, 99))
  expect_equal(r$fields$options$scores$file, "scores.csv")
  expect_true("scores" %in% r$fields$steps)
  r <- rules("which model fits best? two factors please, and a Wright map")
  expect_equal(r$fields$model, "auto")
  expect_equal(r$fields$nfact, 2)
  expect_true("plots" %in% r$fields$steps)
  expect_null(r$fields$options$scores$method)
  expect_equal(rules("treat 9 as missing")$fields$missing, 9)
  expect_null(rules("fit a 3PL with missing data")$fields$missing)
  expect_false("fitcheck" %in% rules("fit a 2PL and check DIF by grade")$fields$steps)
})

test_that("the keyword parser asks when the DIF group is unclear", {
  r <- rules("is there any item bias?")
  expect_named(r$questions, "group")
  expect_setequal(r$questions$group$choices, c("gender", "grade"))
  expect_error(mirtverse:::resolve_questions(r, ask = FALSE), "Which column holds the groups")
  one <- profile_data(parse_dat[, c(paste0("Q", 1:6), "gender")])
  r1 <- mirtverse:::parse_request_rules("check fairness", one)
  expect_equal(r1$fields$group, "gender")
  expect_match(r1$notes, "only column")
})

test_that("mv_ask() works offline from a plain-language request and refines it", {
  scr <- mv_ask("Fit a 2PL, check DIF by gender and make a report", data = parse_dat,
                provider = "none", ask = FALSE)
  expect_equal(scr$parser, "the built-in keyword parser")
  expect_equal(scr$plan$items, paste0("Q", 1:6))
  expect_true(all(c("dif", "report") %in% scr$plan$steps))
  expect_match(paste(scr$script, collapse = "\n"), "group <- raw$gender", fixed = TRUE)
  scr2 <- mv_ask(scr, "use a 3PL instead and no report")
  expect_equal(scr2$plan$model, "3PL")
  expect_false("report" %in% scr2$plan$steps)
  expect_equal(scr2$plan$group, "gender")
  expect_match(scr2$request, "Then: use a 3PL")
  scr3 <- mv_ask(scr2, "save the scores to scores.csv")
  expect_equal(scr3$plan$options$scores$file, "scores.csv")
  vague <- mv_ask("analyse my test", data = parse_dat, provider = "none", ask = FALSE)
  expect_equal(vague$plan$steps, c("describe", "fitcheck", "interpret"))
  expect_equal(vague$plan$model, "auto")
  expect_output(print(scr2), "Understood by the built-in keyword parser")
})

test_that("the AI payload holds only the column summary", {
  pay <- mirtverse:::ask_payload("DIF by gender please", prof)
  expect_match(pay, "gender | integer|gender | text")
  expect_match(pay, "F, M", fixed = TRUE)
  expect_false(grepl("Person17", pay))
  expect_false(grepl("Person1\\b", pay, perl = TRUE))
  anon <- mirtverse:::ask_payload("DIF by Gender for Q1 to Q6", prof, anonymize = TRUE)
  expect_false(grepl("gender", anon, ignore.case = TRUE))
  expect_false(grepl("F, M", anon, fixed = TRUE))
  expect_match(anon, "Request: DIF by V9 for V3 to V8", fixed = TRUE)
  expect_output(out <- mv_ask("DIF by gender", data = parse_dat, provider = "none", dry_run = TRUE),
                "nothing would be sent")
  expect_type(out, "character")
})

test_that("AI answers become checked plans, with names restored after anonymizing", {
  skip_if_not_installed("ellmer")
  # a recorded structured answer, so no AI service is called
  fake <- function(provider, model, payload) list(
    items = list(), model = "2PL", nfact = 1L, group = "V9", missing = list(),
    rt = list(), steps = list("describe", "dif", "report"), score_method = NULL,
    scores_file = NULL, report_file = "dif.html",
    assumptions = list("Took V9 as the grouping variable."), questions = list())
  local_mocked_bindings(llm_call = fake)
  scr <- mv_ask("check DIF by gender with a 2PL and a report", data = parse_dat,
                provider = "claude", model = "test-model", anonymize = TRUE)
  expect_equal(scr$parser, "Claude (test-model)")
  expect_equal(scr$plan$group, "gender")
  expect_match(scr$plan$assumptions, "Took gender as the grouping variable", all = FALSE)
  expect_match(paste(scr$script, collapse = "\n"), "mv_report(mod, file = \"dif.html\", dif = dif_res)",
               fixed = TRUE)

  bad <- function(provider, model, payload) list(
    model = "2PL", nfact = 1L, group = "region", steps = list("dif"),
    questions = list("No column identifies the groups."))
  local_mocked_bindings(llm_call = bad)
  expect_error(mv_ask("check DIF", data = parse_dat, provider = "openai"),
               "No column identifies the groups")

  down <- function(provider, model, payload) stop("timeout")
  local_mocked_bindings(llm_call = down)
  expect_message(scr <- mv_ask("fit a Rasch model", data = parse_dat, provider = "ollama",
                               model = "qwen2.5", ask = FALSE),
                 "using the built-in keyword parser")
  expect_equal(scr$plan$model, "Rasch")
})

test_that("provider resolution and settings storage", {
  withr::local_envvar(ANTHROPIC_API_KEY = "", OPENAI_API_KEY = "", MIRTVERSE_PROVIDER = "")
  withr::local_options(mirtverse.provider = NULL)
  expect_equal(mirtverse:::ask_provider(), "rules")
  withr::local_envvar(OPENAI_API_KEY = "sk-test")
  skip_if_not_installed("ellmer")
  expect_equal(mirtverse:::ask_provider(), "openai")
  expect_equal(mirtverse:::ask_provider("none"), "rules")
  expect_equal(mirtverse:::ask_model("claude"), "claude-opus-5-5")
  f <- tempfile()
  writeLines(c("OTHER=1", "MIRTVERSE_PROVIDER=openai"), f)
  mirtverse:::set_renviron(c(MIRTVERSE_PROVIDER = "claude", ANTHROPIC_API_KEY = "k"), f)
  expect_equal(readLines(f), c("OTHER=1", "MIRTVERSE_PROVIDER=claude", "ANTHROPIC_API_KEY=k"))
  expect_error(mv_ask_setup("claude", save = "none", test = FALSE), "No API key")
  withr::local_options(mirtverse.renviron = f)
  expect_message(mv_ask_setup("openai", key = "sk-x", save = "renviron", test = FALSE), "saved")
  expect_true("OPENAI_API_KEY=sk-x" %in% readLines(f))
  expect_equal(getOption("mirtverse.provider"), "openai")
})

test_that("the structured-output type and Ollama probe work without a network", {
  skip_if_not_installed("ellmer")
  ty <- mirtverse:::plan_type()
  expect_true(inherits(ty, "ellmer::TypeObject") || methods::is(ty, "TypeObject"))
  expect_null(mirtverse:::ollama_models("http://127.0.0.1:9"))
  expect_error(mv_ask_setup("ollama", test = FALSE, save = "none"), "Ollama is not running")
})

test_that("the keyword parser keeps its accuracy on the request benchmark", {
  res <- mirtverse:::ask_benchmark("none", verbose = FALSE)
  expect_equal(nrow(res), 100)
  expect_gte(mean(res$correct), 0.9)
  expect_true(all(attr(res, "accuracy") >= 0.9))
})

test_that("the benchmark counts provider failures as wrong instead of erroring", {
  skip_if_not_installed("ellmer")
  withr::local_envvar(OPENAI_API_KEY = "sk-test")
  local_mocked_bindings(llm_call = function(provider, model, payload) stop("HTTP 401"))
  reqs <- utils::read.csv(system.file("benchmark", "ask-requests.csv", package = "mirtverse"),
                          stringsAsFactors = FALSE, na.strings = character())[1:3, ]
  out <- capture.output(res <- mirtverse:::ask_benchmark("openai", requests = reqs))
  expect_true(any(grepl("fell back to the keyword parser", out)))
  expect_true(any(grepl("HTTP 401", out)))
  expect_false(any(res$correct[nzchar(res$fallback)]))
})

test_that("an AI plan whose only step is dropped still works", {
  skip_if_not_installed("ellmer")
  withr::local_envvar(OPENAI_API_KEY = "sk-test")
  local_mocked_bindings(llm_call = function(provider, model, payload)
    list(model = "2PL", nfact = 1L, steps = list("dif")))
  expect_no_message(scr <- mv_ask("fit a 2PL", data = parse_dat, provider = "openai", ask = FALSE))
  expect_equal(scr$plan$model, "2PL")
})

test_that("a plan with text before the JSON is still read", {
  skip_if_not_installed("jsonlite")
  fake_chat <- function(provider, model, system_prompt) list(
    chat_structured = function(...) stop("lexical error: invalid char in json text."),
    chat = function(...) 'Plan{ "items": [], "model": "2PL", "nfact": 1, "group": "gender", "steps": ["dif"] }')
  local_mocked_bindings(make_chat = fake_chat)
  res <- mirtverse:::llm_call("ollama", "qwen", "payload")
  expect_equal(res$model, "2PL")
  expect_equal(res$steps, "dif")
  expect_error(mirtverse:::parse_plan_json("no plan here"), "did not return a plan")

  local_mocked_bindings(make_chat = function(...) list(
    chat_structured = function(...) stop("HTTP 500")))
  expect_error(mirtverse:::llm_call("ollama", "qwen", "payload"), "HTTP 500")
})
