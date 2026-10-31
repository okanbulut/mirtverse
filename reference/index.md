# Package index

## Workbench

Point-and-click analysis with reproducible code.

- [`launch_workbench()`](https://www.okanbulut.com/mirtverse/reference/launch_workbench.md)
  [`workbench_app()`](https://www.okanbulut.com/mirtverse/reference/launch_workbench.md)
  : Launch the mirtverse workbench

## Scripts from plain language

Describe an analysis in words and get a complete, tested R script.

- [`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
  : Write an analysis script from a plain-language request
- [`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md)
  : Set up an AI model for mv_ask()
- [`mv_plan()`](https://www.okanbulut.com/mirtverse/reference/mv_plan.md)
  [`update_plan()`](https://www.okanbulut.com/mirtverse/reference/mv_plan.md)
  : An analysis plan for mv_ask()
- [`run_script()`](https://www.okanbulut.com/mirtverse/reference/run_script.md)
  [`save_script()`](https://www.okanbulut.com/mirtverse/reference/run_script.md)
  : Run or save a script written by mv_ask()
- [`profile_data()`](https://www.okanbulut.com/mirtverse/reference/profile_data.md)
  : Summarise a data set without revealing its values

## Coming from other IRT packages

Translate ltm, eRm, TAM and irtQ code into mirt code.

- [`mirtify()`](https://www.okanbulut.com/mirtverse/reference/mirtify.md)
  : Translate ltm, eRm, TAM and irtQ code into mirt code
- [`mirtify_crosswalk()`](https://www.okanbulut.com/mirtverse/reference/mirtify_crosswalk.md)
  : The ltm, eRm, TAM and irtQ to mirt crosswalk

## Assessment pipeline

Take a test from response data to a technical report in stages, with
checks and flags to consider before each next stage.

- [`mv_pipeline()`](https://www.okanbulut.com/mirtverse/reference/mv_pipeline.md)
  [`tidy(`*`<mv_pipeline>`*`)`](https://www.okanbulut.com/mirtverse/reference/mv_pipeline.md)
  : Start an assessment pipeline
- [`set_blueprint()`](https://www.okanbulut.com/mirtverse/reference/set_blueprint.md)
  : Pipeline stage: test blueprint and construct definition
- [`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
  [`add_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
  [`verify_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
  : Pipeline stage: item generation
- [`review_packet()`](https://www.okanbulut.com/mirtverse/reference/review_packet.md)
  [`read_reviews()`](https://www.okanbulut.com/mirtverse/reference/review_packet.md)
  : Pipeline stage: item review
- [`design_field_test()`](https://www.okanbulut.com/mirtverse/reference/design_field_test.md)
  : Pipeline stage: field-test design
- [`add_responses()`](https://www.okanbulut.com/mirtverse/reference/add_responses.md)
  : Pipeline stage: data intake and cleaning
- [`calibrate()`](https://www.okanbulut.com/mirtverse/reference/calibrate.md)
  : Pipeline stage: calibration
- [`link_to_bank()`](https://www.okanbulut.com/mirtverse/reference/link_to_bank.md)
  : Pipeline stage: link a calibration to an item bank
- [`bank_items()`](https://www.okanbulut.com/mirtverse/reference/bank_items.md)
  : Pipeline stage: add items to a bank
- [`mv_bank()`](https://www.okanbulut.com/mirtverse/reference/mv_bank.md)
  [`tidy(`*`<mv_bank>`*`)`](https://www.okanbulut.com/mirtverse/reference/mv_bank.md)
  : An item bank
- [`assemble_forms()`](https://www.okanbulut.com/mirtverse/reference/assemble_forms.md)
  : Pipeline stage: assemble fixed test forms
- [`simulate_cat()`](https://www.okanbulut.com/mirtverse/reference/simulate_cat.md)
  : Pipeline stage: simulate a computerized adaptive test
- [`assemble_mst()`](https://www.okanbulut.com/mirtverse/reference/assemble_mst.md)
  : Pipeline stage: assemble and simulate a multistage test
- [`set_cuts()`](https://www.okanbulut.com/mirtverse/reference/set_cuts.md)
  : Pipeline stage: cut scores and decision quality
- [`item_map()`](https://www.okanbulut.com/mirtverse/reference/item_map.md)
  : Item map for Bookmark standard setting
- [`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md)
  : Pipeline stage: scoring open-ended responses
- [`score_persons()`](https://www.okanbulut.com/mirtverse/reference/score_persons.md)
  : Pipeline stage: score test takers
- [`check_security()`](https://www.okanbulut.com/mirtverse/reference/check_security.md)
  : Pipeline stage: test security
- [`pipeline_report()`](https://www.okanbulut.com/mirtverse/reference/pipeline_report.md)
  : Pipeline stage: technical report
- [`monitor_bank()`](https://www.okanbulut.com/mirtverse/reference/monitor_bank.md)
  : Pipeline stage: bank monitoring
- [`retire_items()`](https://www.okanbulut.com/mirtverse/reference/retire_items.md)
  : Retire bank items or send them back to review
- [`flags()`](https://www.okanbulut.com/mirtverse/reference/flags.md) :
  List the flags raised by a pipeline
- [`acknowledge()`](https://www.okanbulut.com/mirtverse/reference/acknowledge.md)
  [`override()`](https://www.okanbulut.com/mirtverse/reference/acknowledge.md)
  : Record a decision about a flag
- [`drop_items()`](https://www.okanbulut.com/mirtverse/reference/drop_items.md)
  : Remove items from a pipeline
- [`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)
  : Thresholds for the pipeline checks

## Choosing and understanding a model

- [`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md)
  : Model selection assistant
- [`interpret()`](https://www.okanbulut.com/mirtverse/reference/interpret.md)
  : Plain-language interpretation of IRT results
- [`interpret_prompt()`](https://www.okanbulut.com/mirtverse/reference/interpret_prompt.md)
  : Build a prompt for an AI assistant from a fitted model

## Tidy outputs

- [`tidy(`*`<SingleGroupClass>`*`)`](https://www.okanbulut.com/mirtverse/reference/tidy_mirt.md)
  [`tidy(`*`<MultipleGroupClass>`*`)`](https://www.okanbulut.com/mirtverse/reference/tidy_mirt.md)
  : Tidy a mirt model into a data frame of parameters
- [`glance(`*`<SingleGroupClass>`*`)`](https://www.okanbulut.com/mirtverse/reference/glance_mirt.md)
  [`glance(`*`<MultipleGroupClass>`*`)`](https://www.okanbulut.com/mirtverse/reference/glance_mirt.md)
  : One-row model summary
- [`augment(`*`<SingleGroupClass>`*`)`](https://www.okanbulut.com/mirtverse/reference/augment_mirt.md)
  : Add person scores to the response data
- [`item_table()`](https://www.okanbulut.com/mirtverse/reference/item_table.md)
  : Tidy item statistics and item fit in one table

## Graphics

- [`gg_dif()`](https://www.okanbulut.com/mirtverse/reference/gg_dif.md)
  : DIF effect sizes plot
- [`gg_empirical()`](https://www.okanbulut.com/mirtverse/reference/gg_empirical.md)
  : Empirical versus model-implied item curve
- [`gg_info()`](https://www.okanbulut.com/mirtverse/reference/gg_info.md)
  : Test and item information curves
- [`gg_itemfit()`](https://www.okanbulut.com/mirtverse/reference/gg_itemfit.md)
  : Item fit plot
- [`gg_q3()`](https://www.okanbulut.com/mirtverse/reference/gg_q3.md) :
  Local dependence heatmap (Yen's Q3)
- [`gg_scores()`](https://www.okanbulut.com/mirtverse/reference/gg_scores.md)
  : Distribution of person scores
- [`gg_trace()`](https://www.okanbulut.com/mirtverse/reference/gg_trace.md)
  : Item characteristic (trace) curves
- [`gg_wright()`](https://www.okanbulut.com/mirtverse/reference/gg_wright.md)
  : Wright map (person-item map)
- [`autoplot(`*`<SingleGroupClass>`*`)`](https://www.okanbulut.com/mirtverse/reference/autoplot.SingleGroupClass.md)
  : Plot a mirt model with ggplot2
- [`theme_mirtverse()`](https://www.okanbulut.com/mirtverse/reference/theme_mirtverse.md)
  : A clean ggplot2 theme for psychometric graphics

## Differential item functioning

- [`dif()`](https://www.okanbulut.com/mirtverse/reference/dif.md) :
  Differential item functioning (DIF) in one call

## Item health cards and reports

- [`item_card()`](https://www.okanbulut.com/mirtverse/reference/item_card.md)
  : Item health card
- [`item_cards()`](https://www.okanbulut.com/mirtverse/reference/item_cards.md)
  : Health cards for many items
- [`mv_report()`](https://www.okanbulut.com/mirtverse/reference/mv_report.md)
  : One-call HTML report

## Dashboards

Interactive results dashboards to share with people who do not use R.

- [`mv_dashboard()`](https://www.okanbulut.com/mirtverse/reference/mv_dashboard.md)
  : Results dashboard for sharing
- [`export_dashboard()`](https://www.okanbulut.com/mirtverse/reference/export_dashboard.md)
  : Save a results dashboard to share

## Response times

- [`fit_rt()`](https://www.okanbulut.com/mirtverse/reference/fit_rt.md)
  : Joint model for responses and response times
- [`sim_rt()`](https://www.okanbulut.com/mirtverse/reference/sim_rt.md)
  : Simulate responses and response times

## Teaching labs

Interactive tutorials for measurement courses.

- [`run_lab()`](https://www.okanbulut.com/mirtverse/reference/run_lab.md)
  [`list_labs()`](https://www.okanbulut.com/mirtverse/reference/run_lab.md)
  : Interactive IRT teaching labs
- [`lab_truth()`](https://www.okanbulut.com/mirtverse/reference/lab_truth.md)
  : Answer key and true values for the lab datasets
- [`certexam`](https://www.okanbulut.com/mirtverse/reference/certexam.md)
  [`certexam_key`](https://www.okanbulut.com/mirtverse/reference/certexam.md)
  : Certification exam data for the teaching labs
- [`numeracy`](https://www.okanbulut.com/mirtverse/reference/numeracy.md)
  [`numeracy_items`](https://www.okanbulut.com/mirtverse/reference/numeracy.md)
  : Numeracy test data for the DIF and fairness lab
- [`linking`](https://www.okanbulut.com/mirtverse/reference/linking.md)
  : Two-form licensure exam data for the linking lab

## Package

- [`mirtverse`](https://www.okanbulut.com/mirtverse/reference/mirtverse-package.md)
  [`mirtverse-package`](https://www.okanbulut.com/mirtverse/reference/mirtverse-package.md)
  : mirtverse: a friendly workflow and reporting layer for mirt
- [`reexports`](https://www.okanbulut.com/mirtverse/reference/reexports.md)
  [`tidy`](https://www.okanbulut.com/mirtverse/reference/reexports.md)
  [`glance`](https://www.okanbulut.com/mirtverse/reference/reexports.md)
  [`augment`](https://www.okanbulut.com/mirtverse/reference/reexports.md)
  [`autoplot`](https://www.okanbulut.com/mirtverse/reference/reexports.md)
  : Objects exported from other packages
