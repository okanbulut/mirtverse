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
  : Pipeline stage: Test blueprint and construct definition
- [`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
  [`add_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
  [`verify_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
  : Pipeline stage: Item generation
- [`review_packet()`](https://www.okanbulut.com/mirtverse/reference/review_packet.md)
  [`read_reviews()`](https://www.okanbulut.com/mirtverse/reference/review_packet.md)
  : Pipeline stage: Item review
- [`design_field_test()`](https://www.okanbulut.com/mirtverse/reference/design_field_test.md)
  : Pipeline stage: Field-test design
- [`add_responses()`](https://www.okanbulut.com/mirtverse/reference/add_responses.md)
  : Pipeline stage: Data intake and cleaning
- [`calibrate()`](https://www.okanbulut.com/mirtverse/reference/calibrate.md)
  : Pipeline stage: Calibration
- [`link_to_bank()`](https://www.okanbulut.com/mirtverse/reference/link_to_bank.md)
  : Pipeline stage: Link a calibration to an item bank
- [`bank_items()`](https://www.okanbulut.com/mirtverse/reference/bank_items.md)
  : Pipeline stage: Add items to a bank
- [`mv_bank()`](https://www.okanbulut.com/mirtverse/reference/mv_bank.md)
  [`tidy(`*`<mv_bank>`*`)`](https://www.okanbulut.com/mirtverse/reference/mv_bank.md)
  : An item bank
- [`assemble_forms()`](https://www.okanbulut.com/mirtverse/reference/assemble_forms.md)
  : Pipeline stage: Assemble fixed test forms
- [`simulate_cat()`](https://www.okanbulut.com/mirtverse/reference/simulate_cat.md)
  : Pipeline stage: Simulate a computerized adaptive test
- [`assemble_mst()`](https://www.okanbulut.com/mirtverse/reference/assemble_mst.md)
  : Pipeline stage: Assemble and simulate a multistage test
- [`set_cuts()`](https://www.okanbulut.com/mirtverse/reference/set_cuts.md)
  : Pipeline stage: Cut scores and decision quality
- [`item_map()`](https://www.okanbulut.com/mirtverse/reference/item_map.md)
  : Item map for Bookmark standard setting
- [`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md)
  : Pipeline stage: Scoring open-ended responses
- [`score_persons()`](https://www.okanbulut.com/mirtverse/reference/score_persons.md)
  : Pipeline stage: Score test takers
- [`check_security()`](https://www.okanbulut.com/mirtverse/reference/check_security.md)
  : Pipeline stage: Test security
- [`pipeline_report()`](https://www.okanbulut.com/mirtverse/reference/pipeline_report.md)
  : Pipeline stage: Technical report
- [`monitor_bank()`](https://www.okanbulut.com/mirtverse/reference/monitor_bank.md)
  : Pipeline stage: Bank monitoring
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

## AI in measurement

Run the language model features offline from recorded responses,
describe items by their text and predict their difficulty, generate
items from item models and calibrate their families, train and check an
automated scoring engine, audit AI components and draft a validity
argument, simulate respondents with a language model (experimental),
check where synthetic respondents land in the real population, and
teaching datasets with item text, written answers, a field test of
generated items, an AI-scored test and HEXACO answers of real people and
four language models.

- [`mv_llm_replay()`](https://www.okanbulut.com/mirtverse/reference/mv_llm_replay.md)
  [`mv_llm_record()`](https://www.okanbulut.com/mirtverse/reference/mv_llm_replay.md)
  [`mv_llm_recordings()`](https://www.okanbulut.com/mirtverse/reference/mv_llm_replay.md)
  : Replay or record language model responses
- [`item_features()`](https://www.okanbulut.com/mirtverse/reference/item_features.md)
  : Text features of test items
- [`predict_difficulty()`](https://www.okanbulut.com/mirtverse/reference/predict_difficulty.md)
  [`tidy(`*`<mv_difficulty>`*`)`](https://www.okanbulut.com/mirtverse/reference/predict_difficulty.md)
  [`autoplot(`*`<mv_difficulty>`*`)`](https://www.okanbulut.com/mirtverse/reference/predict_difficulty.md)
  [`predict(`*`<mv_difficulty>`*`)`](https://www.okanbulut.com/mirtverse/reference/predict_difficulty.md)
  : Predict item difficulty from item features
- [`item_model()`](https://www.okanbulut.com/mirtverse/reference/item_model.md)
  : Write an item model for automatic item generation
- [`generate_isomorphs()`](https://www.okanbulut.com/mirtverse/reference/generate_isomorphs.md)
  : Generate isomorphs from item models
- [`calibrate_families()`](https://www.okanbulut.com/mirtverse/reference/calibrate_families.md)
  [`autoplot(`*`<mv_families>`*`)`](https://www.okanbulut.com/mirtverse/reference/calibrate_families.md)
  : Calibrate item families
- [`train_scorer()`](https://www.okanbulut.com/mirtverse/reference/train_scorer.md)
  [`tidy(`*`<mv_scorer>`*`)`](https://www.okanbulut.com/mirtverse/reference/train_scorer.md)
  : Train an automated scorer on human-scored text
- [`predict(`*`<mv_scorer>`*`)`](https://www.okanbulut.com/mirtverse/reference/predict.mv_scorer.md)
  : Score new responses with a trained scorer
- [`agreement_report()`](https://www.okanbulut.com/mirtverse/reference/agreement_report.md)
  [`autoplot(`*`<mv_agreement>`*`)`](https://www.okanbulut.com/mirtverse/reference/agreement_report.md)
  : Agreement between machine and human scores
- [`rater_facets()`](https://www.okanbulut.com/mirtverse/reference/rater_facets.md)
  [`tidy(`*`<mv_facets>`*`)`](https://www.okanbulut.com/mirtverse/reference/rater_facets.md)
  [`autoplot(`*`<mv_facets>`*`)`](https://www.okanbulut.com/mirtverse/reference/rater_facets.md)
  : Place human and AI raters on the Wright map
- [`scoring_shift()`](https://www.okanbulut.com/mirtverse/reference/scoring_shift.md)
  [`tidy(`*`<mv_shift>`*`)`](https://www.okanbulut.com/mirtverse/reference/scoring_shift.md)
  [`autoplot(`*`<mv_shift>`*`)`](https://www.okanbulut.com/mirtverse/reference/scoring_shift.md)
  : Compare item thresholds and scores under human and AI scoring
- [`ai_audit()`](https://www.okanbulut.com/mirtverse/reference/ai_audit.md)
  [`tidy(`*`<mv_audit>`*`)`](https://www.okanbulut.com/mirtverse/reference/ai_audit.md)
  [`autoplot(`*`<mv_audit>`*`)`](https://www.okanbulut.com/mirtverse/reference/ai_audit.md)
  : Audit an AI component before its results are used
- [`validity_argument()`](https://www.okanbulut.com/mirtverse/reference/validity_argument.md)
  [`format(`*`<mv_validity>`*`)`](https://www.okanbulut.com/mirtverse/reference/validity_argument.md)
  : Draft a validity argument for an AI component
- [`simulate_llm_respondents()`](https://www.okanbulut.com/mirtverse/reference/simulate_llm_respondents.md)
  : Simulate respondents with a language model (experimental)
- [`compare_synthetic()`](https://www.okanbulut.com/mirtverse/reference/compare_synthetic.md)
  : Compare simulated respondents with real ones (experimental)
- [`synthetic_coverage()`](https://www.okanbulut.com/mirtverse/reference/synthetic_coverage.md)
  : How well do synthetic respondents cover the real population?
- [`blend_llms()`](https://www.okanbulut.com/mirtverse/reference/blend_llms.md)
  : Find the best blend of language models
- [`gg_coverage()`](https://www.okanbulut.com/mirtverse/reference/gg_coverage.md)
  : Draw the coverage strip
- [`hexaco_real`](https://www.okanbulut.com/mirtverse/reference/hexaco_real.md)
  : HEXACO responses of real people, for checking synthetic respondents
- [`hexaco_llm`](https://www.okanbulut.com/mirtverse/reference/hexaco_llm.md)
  : HEXACO responses generated by four language models
- [`hexaco_items`](https://www.okanbulut.com/mirtverse/reference/hexaco_items.md)
  : The 240 IPIP-HEXACO items and their keys
- [`itemtext`](https://www.okanbulut.com/mirtverse/reference/itemtext.md)
  : Numeracy items with their text, for the AI Hub
- [`essays`](https://www.okanbulut.com/mirtverse/reference/essays.md) :
  Short science explanations scored by raters, for the AI Hub
- [`aigfield`](https://www.okanbulut.com/mirtverse/reference/aigfield.md)
  : A field test of generated mathematics items, for the AI Hub
- [`aigfield_items`](https://www.okanbulut.com/mirtverse/reference/aigfield_items.md)
  : The generated items of the AIG field test
- [`aiscored`](https://www.okanbulut.com/mirtverse/reference/aiscored.md)
  : An AI-scored science test over two years, for the AI Hub
- [`aiscored_cr`](https://www.okanbulut.com/mirtverse/reference/aiscored_cr.md)
  : Machine and human scores of the AI-scored test

## Choosing and understanding a model

- [`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md)
  : Model selection assistant
- [`interpret()`](https://www.okanbulut.com/mirtverse/reference/interpret.md)
  : Plain-language interpretation of IRT results
- [`interpret_prompt()`](https://www.okanbulut.com/mirtverse/reference/interpret_prompt.md)
  : Build a prompt for an AI assistant from a fitted model
- [`cite_methods()`](https://www.okanbulut.com/mirtverse/reference/cite_methods.md)
  : Write the Methods paragraph for an IRT analysis

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

- [`gg_coverage()`](https://www.okanbulut.com/mirtverse/reference/gg_coverage.md)
  : Draw the coverage strip
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
- [`catbank`](https://www.okanbulut.com/mirtverse/reference/catbank.md)
  : Math placement item bank for the CAT design lab
- [`openended`](https://www.okanbulut.com/mirtverse/reference/openended.md)
  : Rater-scored science tasks for the open-ended scoring lab

## Instructor toolkit

Build labs on your own data, adapt the built-in labs and the book’s
chapters, swap datasets and check materials before class.

- [`new_course()`](https://www.okanbulut.com/mirtverse/reference/new_course.md)
  [`course_materials()`](https://www.okanbulut.com/mirtverse/reference/new_course.md)
  : Start a course folder for the instructor toolkit
- [`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md)
  : Build a lab from your own data
- [`copy_lab()`](https://www.okanbulut.com/mirtverse/reference/copy_lab.md)
  : Copy a built-in lab into a course to edit it
- [`lab_section_types()`](https://www.okanbulut.com/mirtverse/reference/lab_section_types.md)
  : Sections you can add to a toolkit lab
- [`add_lab_section()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md)
  [`add_lab_exercise()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md)
  [`add_lab_question()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md)
  [`remove_lab_section()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md)
  [`lab_outline()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md)
  : Add, remove and list the sections of a lab
- [`swap_lab_data()`](https://www.okanbulut.com/mirtverse/reference/swap_lab_data.md)
  : Replace the data in a toolkit lab
- [`lab_data()`](https://www.okanbulut.com/mirtverse/reference/lab_data.md)
  : Load the data of a toolkit lab
- [`copy_chapter()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md)
  [`new_chapter()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md)
  [`swap_chapter_data()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md)
  [`book_chapters()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md)
  : Notes chapters for a course
- [`copy_workshop()`](https://www.okanbulut.com/mirtverse/reference/copy_workshop.md)
  : Copy the AI in measurement workshop kit
- [`check_material()`](https://www.okanbulut.com/mirtverse/reference/check_material.md)
  : Check a lab, a chapter or a whole course
- [`preview_lab()`](https://www.okanbulut.com/mirtverse/reference/preview_lab.md)
  : Open a lab in the browser

## AI assistant for instructors

Connect Claude or an OpenAI assistant to your course materials.

- [`mv_mcp_server()`](https://www.okanbulut.com/mirtverse/reference/mv_mcp_server.md)
  : MCP server for instructors
- [`mv_mcp_config()`](https://www.okanbulut.com/mirtverse/reference/mv_mcp_config.md)
  : Settings to connect an AI client to a mirtverse MCP server

## mirtverse agent for Claude

Let Claude run IRT analyses on your data with the mirtverse plugin for
Claude Code, or set up a folder by hand.

- [`mv_agent_server()`](https://www.okanbulut.com/mirtverse/reference/mv_agent_server.md)
  : Run the mirtverse analysis agent server
- [`mv_agent_init()`](https://www.okanbulut.com/mirtverse/reference/mv_agent_init.md)
  : Set up a folder for the mirtverse agent in Claude Code

## Package

- [`mirtverse`](https://www.okanbulut.com/mirtverse/reference/mirtverse-package.md)
  [`mirtverse-package`](https://www.okanbulut.com/mirtverse/reference/mirtverse-package.md)
  : mirtverse: A friendly workflow and reporting layer for mirt
- [`reexports`](https://www.okanbulut.com/mirtverse/reference/reexports.md)
  [`tidy`](https://www.okanbulut.com/mirtverse/reference/reexports.md)
  [`glance`](https://www.okanbulut.com/mirtverse/reference/reexports.md)
  [`augment`](https://www.okanbulut.com/mirtverse/reference/reexports.md)
  [`autoplot`](https://www.okanbulut.com/mirtverse/reference/reexports.md)
  : Objects exported from other packages
