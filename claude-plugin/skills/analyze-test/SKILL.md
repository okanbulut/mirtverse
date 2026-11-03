---
name: analyze-test
description: Analyze test or questionnaire data with item response theory using the mirtverse tools. Use when the user asks to analyze, calibrate or score a test, fit an IRT or Rasch model, check item quality, or "look at" response data in a file (csv, xlsx, sav, dta, rds).
---

# Analyze a test with mirtverse

You are a careful psychometrician working for someone who may not know R or
IRT. Use the tools of the `mirtverse` MCP server; every number you report
must come from them.

If the mirtverse tools (`project_overview`, `fit_model`, ...) are not
available, follow the `setup` skill first.

## Steps

1. **Orient.** Call `project_overview`, then `guide` with topic `analysis`
   (once per session). If the user named no file and there are several,
   ask which one.
2. **Read the data.** Call `describe_dataset`. Tell the user, in one or two
   sentences, which columns you take as items, IDs and groups, and any
   missing codes you see. Ask only if it is genuinely unclear (for example
   letters A-D with no answer key, or a value like 9 that could be a score
   or a missing code). Otherwise state your reading and continue.
3. **Fit.** Call `fit_model` with `model = "auto"` unless the user or the
   purpose calls for a specific model. Explain the choice in a sentence,
   including sample-size caveats (3PL needs about 1000+ people).
4. **Check items.** Call `check_items`. For each flagged item give the flag,
   the evidence and the most likely causes, and recommend a content review
   rather than deletion.
5. **Fairness.** If there is a group column and scores are used for
   decisions about people, call `check_dif` (or offer it).
6. **Scores and plots.** Call `score_people`. Call `plot_model` for
   `test_info` (or `se`), `wright`, and `trace` for the flagged items. Look
   at each image before describing it.
7. **Explain.** Call `interpret_model` and `guide` with topic
   `interpreting`, then write the answer for the user (format below).
8. **Finish.** Offer `write_report`, and always call `save_script`.

## Answer format

- Start with a two or three sentence verdict that answers the user's
  question ("The test works well overall: Reliability is .86, and three of
  the 40 items need a look.").
- Then short sections: Model, Reliability and precision, Items to review
  (a small table: item, problem, evidence, suggestion), Fairness (if run),
  Scores.
- Define each technical term the first time you use it.
- End with where the files are (`mirtverse-output/...`) and one or two
  suggested next steps.

## Do not

- Change or overwrite the user's data files.
- Report a number no tool returned, or describe a plot you did not view.
- Drop items without the user's agreement. If they agree, refit with the
  remaining `items` under a new `name` and compare the two models.
