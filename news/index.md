# Changelog

## mirtverse (development version)

- Knowledge graphs:
  [`mv_kg_build()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_build.md)
  describes what a test measures as a graph of concepts, the
  prerequisite and related edges between them, and the items that
  measure each concept.
  [`as_mv_kg()`](https://www.okanbulut.com/mirtverse/reference/as_mv_kg.md)
  builds one from a Q-matrix, an edge list, a fitted confirmatory mirt
  model or an igraph object.
  [`mv_kg_check()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_check.md)
  flags prerequisite cycles, concepts with too few items or the same
  items, redundant prerequisites and isolated concepts, with the block,
  review and info levels of the assessment pipeline.
  [`gg_kg()`](https://www.okanbulut.com/mirtverse/reference/gg_kg.md)
  draws the graph with concepts in columns by learning order and items
  in a column on the right, and
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html) and
  [`glance()`](https://generics.r-lib.org/reference/glance.html) return
  its nodes, edges and a summary.
- Knowledge graphs to models:
  [`mv_kg_qmatrix()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_qmatrix.md)
  returns the graph’s Q-matrix,
  [`mv_kg_model()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_model.md)
  writes a confirmatory
  [`mirt.model()`](https://philchalmers.github.io/mirt/reference/mirt.model.html)
  with one factor per concept (all concepts correlated, only neighbours
  in the graph correlated, or none), and
  [`mv_kg_irt()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_irt.md)
  fits it with mirt (quasi-Monte Carlo EM with more than three concepts)
  and keeps the graph with the fitted model.
  [`mv_kg_hierarchy()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_hierarchy.md)
  lists the mastery patterns the prerequisite edges allow (the attribute
  hierarchy), for diagnostic models such as
  [`mirt::mdirt()`](https://philchalmers.github.io/mirt/reference/mdirt.html).
- Checking a knowledge graph against data:
  [`mv_kg_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_fit.md)
  finds items that agree more with another concept than with the ones
  they are linked to (disattenuated rest-score correlations), concept
  pairs with a large partial correlation but no edge, edges the data
  barely support, and prerequisites whose items are harder than those of
  the concept they lead to. Each flag comes with a suggested change,
  [`mv_kg_refine()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_refine.md)
  applies the ones you accept, and
  [`gg_kg_fit()`](https://www.okanbulut.com/mirtverse/reference/gg_kg_fit.md)
  draws the evidence on the graph. On the simulated `fractions` data it
  finds both planted errors, and the refined graph is the true one.
- [`mv_kg_explain()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_explain.md)
  explains item difficulty with the graph in an explanatory Rasch model
  fitted with eirm: One difficulty per concept (a linear logistic test
  model with a random item effect), or the item’s depth in the learning
  order. It reports how much of the item variance the graph explains and
  which items it predicts poorly.
- Lab 11, “Repairing a knowledge graph” (`run_lab("kg-repair")`):
  Students check a curriculum team’s graph for a Grade 5 fractions test
  against the answers, find an item linked to the wrong concept and a
  missing prerequisite, repair the graph and show what the repair
  changes. The book chapter “Knowledge graphs and IRT” has a new section
  on checking a graph against data and explaining item difficulty with
  it.
- [`mv_kg_subset()`](https://www.okanbulut.com/mirtverse/reference/mv_kg_subset.md)
  keeps chosen concepts of a graph, the relations among them and the
  items that measure them.
- The workbench has a Knowledge graph tab: It draws and checks an
  example graph or an uploaded Q-matrix (with optional prerequisites),
  and fits the confirmatory model for chosen concepts to the data from
  the Data tab, with the R code. The fraction subtraction data are a new
  example dataset.
- The online book has a new part, Knowledge graphs, starting with the
  chapter “Knowledge graphs and IRT” on Tatsuoka’s fraction subtraction
  data, and the glossary has entries for knowledge graph, Q-matrix and
  attribute hierarchy.
- New datasets: `fractions` and `fractions_kg`, a simulated Grade 5
  fractions test with its knowledge graph and two planted differences
  from the true graph (`lab_truth("fractions")`), and
  `fraction_subtraction` and `fraction_subtraction_kg`, Tatsuoka’s
  fraction subtraction data with its 8-attribute Q-matrix, copied from
  the CDM package.

## mirtverse 0.4.0

- Coverage strips for synthetic respondents (experimental):
  [`synthetic_coverage()`](https://www.okanbulut.com/mirtverse/reference/synthetic_coverage.md)
  compares synthetic respondents from one or more language models, over
  several attempts, with real responses to the same items, and
  [`gg_coverage()`](https://www.okanbulut.com/mirtverse/reference/gg_coverage.md)
  draws one row per model and attempt and one column per slice of the
  real population: Deciles of the real total score (the default) or of
  theta, groups or personas (alone or with deciles within each), or
  items and their answer categories (right/wrong and Likert items). Blue
  cells hold too many synthetic respondents, red cells too few, and gaps
  a real sample of the same size would show by chance stay pale. On the
  right, Overlap (the share of synthetic respondents in the same slices
  as real ones) and Structure (how closely the inter-item correlations
  match) give the Overall, Lowest and Highest attempt. With two or more
  models,
  [`blend_llms()`](https://www.okanbulut.com/mirtverse/reference/blend_llms.md)
  finds the Best Blend, the mix of models whose respondents match the
  real population best; with four or more attempts it is chosen on half
  of them and reported on the other half. Large tests are split into
  pages of at most 40 columns, worst-matching items first. With groups
  (for example personas or countries), `within_group = TRUE` compares
  each group’s respondents with that group’s real respondents only, so a
  mix of groups set by design (such as the same number per country) does
  not count. Strips with many score slices (such as deciles within
  several groups) get angled column labels. polycor is a new suggested
  package.

- Wright maps for automated scoring:
  [`rater_facets()`](https://www.okanbulut.com/mirtverse/reference/rater_facets.md)
  fits a many-facet Rasch model with the eirm package, so human raters
  and an AI scoring engine get a severity on the same logit scale as the
  test takers and the items, overall or by item and by group (a language
  group, or a year for drift). It flags an engine that is harsher or
  more lenient than the human raters (`rater_bias` in
  [`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md),
  new), and one that is so for one group more than another.
  [`scoring_shift()`](https://www.okanbulut.com/mirtverse/reference/scoring_shift.md)
  calibrates the AI-scored items with human and with machine scores,
  links the two calibrations through the other items, and flags
  thresholds that move (`drift_b`) and test scores that move overall or
  for one group.
  [`gg_wright()`](https://www.okanbulut.com/mirtverse/reference/gg_wright.md)
  draws both: A Wright map with a rater column, and one with human and
  machine thresholds side by side. `ai_audit(components = )` takes both
  results, and
  [`validity_argument()`](https://www.okanbulut.com/mirtverse/reference/validity_argument.md)
  maps their checks to the scoring and extrapolation inferences. Chapter
  16 of the book has a new example, Lab 7 places its engine on the
  Wright map, and Lab 10 has a new section, “The audit on the Wright
  map”. eirm and lme4 are new suggested packages.

- Site navigation: The “Get started” menu item is now “Tutorial”, and
  the article it opens is retitled “Tutorial: A first analysis with
  mirtverse”, so it no longer sits next to “Start here” with a similar
  name. The Articles menu no longer repeats the audience pages that are
  already in the “Start here” menu.

- New datasets from a study of synthetic HEXACO respondents:
  `hexaco_real` (17,874 real people from Canada, Great Britain and the
  United States, 240 IPIP-HEXACO items, Open-Source Psychometrics
  Project), `hexaco_llm` (59,611 synthetic respondents to the same items
  from Gemma 4 26B, GPT-OSS-120B, Qwen 3.8 27B and Qwen 3.5 122B, 10
  attempts per country) and `hexaco_items` (item text, trait, facet and
  keying).

- New article “Checking synthetic respondents: The coverage strip” shows
  [`synthetic_coverage()`](https://www.okanbulut.com/mirtverse/reference/synthetic_coverage.md)
  and
  [`gg_coverage()`](https://www.okanbulut.com/mirtverse/reference/gg_coverage.md)
  with the HEXACO data: Models, countries (`within_group = TRUE`) and
  items.

- The mirtverse plugin for Claude Code (version 0.2.0) no longer starts
  the analysis server itself, so it meets the Claude plugin directory’s
  rules (only Markdown, JSON and images; no MCP server that runs on the
  user’s computer). Connect the server once with
  `claude mcp add --scope user mirtverse -- Rscript -e "mirtverse::mv_agent_server()"`;
  the `setup` skill walks through it, and
  `mv_mcp_config(NULL, client = "claude-code", mode = "analysis")`
  prints the command with the full path to Rscript.

## mirtverse 0.3.0

- The paper describing mirtverse is out as a preprint on PsyArXiv
  (<https://doi.org/10.31234/osf.io/j9ya7_v1>). It is cited in the
  README, in `citation("mirtverse")` and in `CITATION.cff`.

- Turkish materials: A Turkish introduction page (`articles/tr`, linked
  as “Türkçe” in the navbar and from the README) and a Turkish version
  of the two-page cheat sheet
  (`cheatsheet/mirtverse-cheatsheet-tr.pdf`). The cheat sheet source is
  `data-raw/cheatsheet/cheatsheet-tr.html`, and
  `data-raw/cheatsheet/build.js` now renders both languages.

- New article and printable poster, “Which IRT model?”: A one-page
  flowchart from what one item score looks like (0/1, ordered
  categories, unordered options or ideal-point items) to a model and its
  `itemtype`, with structure questions (dimensions, testlets, groups,
  item features, response times, latent classes), fit checks and a QR
  code back to the article. The poster source is in
  `data-raw/which-model/`.

- The mirtverse agent: A plugin for Claude Code that lets Claude analyze
  test data with mirtverse on the user’s computer. Install it in Claude
  Code with `/plugin marketplace add okanbulut/mirtverse` and
  `/plugin install mirtverse@mirtverse`. It brings five skills
  (`analyze-test`, `check-dif`, `review-items`, `write-report`,
  `setup`), an `irt-analyst` subagent, and a new MCP server,
  [`mv_agent_server()`](https://www.okanbulut.com/mirtverse/reference/mv_agent_server.md),
  whose tools fit and compare models, check items, test DIF, score
  people, draw plots that Claude can see, interpret the results, write
  the HTML report, run other R code, and save every step as one
  reproducible R script. Models are kept between sessions. New
  [`mv_agent_init()`](https://www.okanbulut.com/mirtverse/reference/mv_agent_init.md)
  sets up a folder without the plugin (a `CLAUDE.md` with the agent’s
  instructions and a `.mcp.json`), and
  [`mv_mcp_config()`](https://www.okanbulut.com/mirtverse/reference/mv_mcp_config.md)
  has a new `mode = "analysis"` for Claude Desktop, Codex and other MCP
  clients. A new article, “The mirtverse agent for Claude”, explains it.

- Three narrated video demos (about 90 seconds each, with captions): The
  workbench tour, the AI Hub and the thesis kit. They are on the home
  page, on a new “Video demos” page (Start here menu) and in the AI Hub,
  thesis kit and “New to R” articles.

- New
  [`cite_methods()`](https://www.okanbulut.com/mirtverse/reference/cite_methods.md)
  drafts the Methods paragraph of an IRT analysis in APA style: Software
  versions, the model and estimation method, the model comparison from
  [`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md),
  overall and item fit, reliability and removed items, with an
  alphabetical reference list. It prints, returns text, or writes
  Markdown or a Word file. A new “Thesis kit” article walks from item
  responses to that paragraph.

- Workbench: The “Test summary” table on the Explore tab no longer
  errors with current mirt, which renamed the total-score columns of
  [`itemstats()`](https://philchalmers.github.io/mirt/reference/itemstats.html).

- New article “Adopt mirtverse for your course” with a sample 12-week
  syllabus to edit (Word and PDF), a setup checklist and a GitHub form
  for instructors to tell us about their course. New article “Case
  study: A certification exam, from field test to pass/fail” follows a
  fictional board through eight recorded decisions and links a
  downloadable technical report (PDF and HTML). The home page now
  highlights the AI in measurement hub with an animated graphic.

- The website has a new front door. The home page opens with a one-line
  summary, a four-step workflow diagram, a grid of real outputs
  (dashboard, item health card, Wright map, DIF plot) and a “Find your
  way in” table, and a new “Start here” menu has a short path for
  students, instructors, testing programs, researchers and people new
  to R. A new Gallery article shows every figure and output with its
  code. Links to the site now show a share image on LinkedIn, Bluesky
  and X, and the README has a “How to cite” box near the top.

- New, experimental
  [`simulate_llm_respondents()`](https://www.okanbulut.com/mirtverse/reference/simulate_llm_respondents.md)
  asks a language model to answer multiple-choice items as described
  respondents (“personas”) would, and new
  [`compare_synthetic()`](https://www.okanbulut.com/mirtverse/reference/compare_synthetic.md)
  checks the answers against real data: Difficulty, its order across
  items, the variety of response patterns and item-total correlations.
  The example recordings for
  [`mv_llm_replay()`](https://www.okanbulut.com/mirtverse/reference/mv_llm_replay.md)
  include a run on `itemtext` that shows the usual problems (items too
  easy, alike personas answering alike, stereotyped groups), and chapter
  17 of the book has a box on it.

- New
  [`copy_workshop()`](https://www.okanbulut.com/mirtverse/reference/copy_workshop.md)
  copies a kit for a one-day workshop on AI in measurement: Slides, a
  facilitator’s guide and a README, built around Labs 7 to 10. A new
  article, “AI in measurement: A one-day workshop”, describes it.

- The instructor toolkit can teach AI in measurement on an instructor’s
  own data.
  [`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md)
  and
  [`swap_lab_data()`](https://www.okanbulut.com/mirtverse/reference/swap_lab_data.md)
  take `item_info` (one row per item, with its text or its item family)
  and `scores` (machine and human scores of written answers), and
  [`lab_section_types()`](https://www.okanbulut.com/mirtverse/reference/lab_section_types.md)
  has three new sections: `"item-features"`
  ([`item_features()`](https://www.okanbulut.com/mirtverse/reference/item_features.md)
  and
  [`predict_difficulty()`](https://www.okanbulut.com/mirtverse/reference/predict_difficulty.md)),
  `"aig"`
  ([`calibrate_families()`](https://www.okanbulut.com/mirtverse/reference/calibrate_families.md))
  and `"ai-scoring"`
  ([`agreement_report()`](https://www.okanbulut.com/mirtverse/reference/agreement_report.md)
  and
  [`ai_audit()`](https://www.okanbulut.com/mirtverse/reference/ai_audit.md)).
  As in the other sections, every answer is computed from the data.
  [`lab_data()`](https://www.okanbulut.com/mirtverse/reference/lab_data.md)
  returns the new tables.

- The instructor MCP server has a new guide, `guide("ai-content")`, on
  teaching AI in measurement, a new prompt, “Teach AI in measurement”,
  and the new `item_info` and `scores` arguments in its `new_lab` and
  `swap_lab_data` tools.

- The course map has an optional four-week module on AI in measurement
  (weeks 13 to 16, Labs 7 to 10 and book chapters 13 to 18) and a
  one-day workshop schedule.

- New
  [`ai_audit()`](https://www.okanbulut.com/mirtverse/reference/ai_audit.md)
  audits an AI component in one call and returns flags in the pipeline’s
  block / review / info style: Human and machine agreement, overall
  bias, agreement within groups, differential scoring (machine minus
  human at the same human score, against a reference group, beyond
  sampling error), drift across administrations or engine versions, DIF
  on the test as scored (on AI-scored items for review, on others for
  information), and results of
  [`predict_difficulty()`](https://www.okanbulut.com/mirtverse/reference/predict_difficulty.md)
  (leakage),
  [`calibrate_families()`](https://www.okanbulut.com/mirtverse/reference/calibrate_families.md)
  (isomorphism) and
  [`agreement_report()`](https://www.okanbulut.com/mirtverse/reference/agreement_report.md).
  It has [`print()`](https://rdrr.io/r/base/print.html),
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html) and
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  methods.

- New
  [`validity_argument()`](https://www.okanbulut.com/mirtverse/reference/validity_argument.md)
  drafts a Kane-style validity argument from an audit: Claims,
  AI-specific threats, evidence and a status for the scoring,
  generalization, extrapolation and decision inferences, with what is
  still owed. [`format()`](https://rdrr.io/r/base/format.html) gives
  HTML or Markdown, and
  [`mv_report()`](https://www.okanbulut.com/mirtverse/reference/mv_report.md)
  takes it directly as an extra section.

- New Lab 10, `run_lab("ai-audit")`: Students audit an engine-scored
  science test over two years (the new `aiscored` and `aiscored_cr`
  data) before its scores are released. The book has a new chapter,
  “Validity, fairness and governance of AI” (`ai-validity` in
  [`book_chapters()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md)).

- New
  [`item_model()`](https://www.okanbulut.com/mirtverse/reference/item_model.md)
  writes an item model for automatic item generation: A stem, key and
  distractors as templates with R expressions in braces, the values of
  each variable and constraints. Printing it shows how many combinations
  meet the constraints and how many give four different options. New
  [`generate_isomorphs()`](https://www.okanbulut.com/mirtverse/reference/generate_isomorphs.md)
  fills one or more models, leaves out (or flags) combinations with
  identical options, and returns the items with the values they came
  from. New
  [`calibrate_families()`](https://www.okanbulut.com/mirtverse/reference/calibrate_families.md)
  summarizes the calibrated difficulties of each family: Mean,
  within-family SD corrected for estimation error, a 95% interval for a
  new isomorph, the field-test size the family mean can replace, and
  whether the family is isomorphic.

- New Lab 9, `run_lab("aig")`: Students fix an item model, calibrate a
  field test of 60 generated items (the new `aigfield` and
  `aigfield_items` data), find a family split by regrouping and two
  items with identical options, and test family means on held-out items.
  The book has a new chapter, “Generating items” (`aig` in
  [`book_chapters()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md)),
  with one-step family calibration in mirt
  ([`mixedmirt()`](https://philchalmers.github.io/mirt/reference/mixedmirt.html))
  and eirm.

- New
  [`item_features()`](https://www.okanbulut.com/mirtverse/reference/item_features.md)
  describes items by features of their text: Length, sentences and
  readability of the stem, its numbers, decimals and negations, the
  length of the options, whether the key is the longest option, how far
  numeric distractors are from the key, and each item’s most similar
  other item, to find near-duplicates. Everything runs in base

  18. 

- New
  [`predict_difficulty()`](https://www.okanbulut.com/mirtverse/reference/predict_difficulty.md)
  predicts item difficulty from features with an LLTM (two-step
  explanatory IRT), a lasso and a random forest, all in base R, and
  compares them by cross-validation, with random folds or whole groups
  (such as item families) held out. It flags features that look leaked
  from the field test, shows the estimation error in `b` as a floor, and
  has [`tidy()`](https://generics.r-lib.org/reference/tidy.html),
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  and [`predict()`](https://rdrr.io/r/stats/predict.html) methods.

- New Lab 8, `run_lab("item-text")`: Students predict the difficulty of
  the 192 `itemtext` items from their text, find miskeyed items and
  near-duplicates, catch a leaky feature, hold out whole item models,
  and decide what predictions can replace. The book has a new chapter,
  “What item text tells us” (`item-text` in
  [`book_chapters()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md)),
  with the one-step LLTM in mirt.

- New
  [`train_scorer()`](https://www.okanbulut.com/mirtverse/reference/train_scorer.md)
  trains an automated scoring engine on human-scored text: A ridge
  regression on words and two-word phrases, in base R, with the penalty
  chosen by cross-validation. It runs offline,
  [`predict()`](https://rdrr.io/r/stats/predict.html) scores new
  answers, [`tidy()`](https://generics.r-lib.org/reference/tidy.html)
  shows the word weights, and it plugs into
  [`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md).
  New
  [`agreement_report()`](https://www.okanbulut.com/mirtverse/reference/agreement_report.md)
  compares machine and human scores overall, by group and by item: Exact
  and adjacent agreement, QWK, SMD, correlation and PRMSE, with a
  verdict against
  [`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)
  and an
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  method.

- New Lab 7, `run_lab("auto-scoring")`: Students train an engine on
  `essays`, judge it on new students, find why it underscores English
  language learners, and decide how much of the scoring it should do.
  The book has a new chapter, “Automated scoring” (`auto-scoring` in
  [`book_chapters()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md)).

- `essays` is harder to score by machine, as real answers are: Language
  learners misspell more content words and drop articles, some answers
  state an idea the wrong way round with the right words, and raters are
  a little less consistent (human-human QWK about 0.8). The example
  recordings were rebuilt to match.

- The online book has a new part, *AI in measurement*, with two
  chapters: “Machine learning through an IRT lens” (prediction versus
  measurement, the 2PL as a logistic regression on a latent predictor,
  overfitting and cross-validation) and “Large language models as a
  colleague” (what is sent to a model, checking generated items,
  reproducibility with recorded responses). Both build offline with
  [`mv_llm_replay()`](https://www.okanbulut.com/mirtverse/reference/mv_llm_replay.md).
  [`book_chapters()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md)
  lists them as `ml-lens` and `llms`, and the AI Hub menu links to them.

- New
  [`mv_llm_replay()`](https://www.okanbulut.com/mirtverse/reference/mv_llm_replay.md)
  answers every language model request
  ([`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md),
  [`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md),
  [`verify_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md),
  [`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md),
  `review_packet(ai_screen = TRUE)`) from a file of recorded responses,
  so lessons and examples run with no API key or internet connection and
  give the same result every time.
  [`mv_llm_record()`](https://www.okanbulut.com/mirtverse/reference/mv_llm_replay.md)
  records a live session for later replay and
  [`mv_llm_recordings()`](https://www.okanbulut.com/mirtverse/reference/mv_llm_replay.md)
  lists what a file covers. The package ships example recordings for the
  calls in `system.file("replay", "examples.R", package = "mirtverse")`;
  their responses were written by hand and include deliberate mistakes
  for the checks to catch.

- Two new teaching datasets for the AI Hub. `itemtext` has the text and
  2PL field-test statistics of 192 simulated numeracy items from 12 item
  families, for predicting difficulty from item text and calibrating
  item families. `essays` has 1,600 short science explanations by 400
  students, scored 0 to 4 by raters, for automated scoring. Both have
  planted problems that `lab_truth("itemtext")` and
  `lab_truth("essays")` reveal.

- New AI Hub for psychometricians who want to learn how artificial
  intelligence fits into measurement, with its own menu in the site
  navbar. It has a landing page with a learning path and examples of the
  AI features already in mirtverse (“AI Hub: Artificial intelligence for
  psychometricians”), a table that translates more than 40 machine
  learning terms into their closest psychometric ideas (“Machine
  learning for psychometricians: A translation table”), and an annotated
  reading list. The glossary has a new “AI in measurement” section with
  13 terms.

- New online book, *Item Response Theory with mirt and mirtverse*, at
  <https://www.okanbulut.com/mirtverse/book/>. Twelve chapters follow
  the weeks of the course map, from classical item analysis to cut
  scores and reporting. Each has learning goals, glossary links, two
  worked examples on different data, exercises with solutions and a
  pointer to the matching lab. The bookdown source is in `book/`, every
  example loads its data in one labelled chunk so instructors can swap
  in their own, and the pkgdown workflow builds the book into the site.
  The site navbar links to it.

- New instructor toolkit for teaching with your own data, with a guide
  on the website (“The instructor toolkit”).
  [`new_course()`](https://www.okanbulut.com/mirtverse/reference/new_course.md)
  sets up a course folder and
  [`course_materials()`](https://www.okanbulut.com/mirtverse/reference/new_course.md)
  lists what is in it.
  [`new_lab()`](https://www.okanbulut.com/mirtverse/reference/new_lab.md)
  builds an interactive learnr lab on any response dataset (a data frame
  or a CSV, Excel, SPSS, Stata or SAS file), with sections from
  [`lab_section_types()`](https://www.okanbulut.com/mirtverse/reference/lab_section_types.md)
  whose text, answer checks and quiz answers are computed from the data,
  so
  [`swap_lab_data()`](https://www.okanbulut.com/mirtverse/reference/swap_lab_data.md)
  can replace the data later.
  [`add_lab_section()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md),
  [`add_lab_exercise()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md),
  [`add_lab_question()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md),
  [`remove_lab_section()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md)
  and
  [`lab_outline()`](https://www.okanbulut.com/mirtverse/reference/add_lab_section.md)
  edit a lab;
  [`copy_lab()`](https://www.okanbulut.com/mirtverse/reference/copy_lab.md)
  makes an editable copy of a built-in lab;
  [`copy_chapter()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md),
  [`new_chapter()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md)
  and
  [`swap_chapter_data()`](https://www.okanbulut.com/mirtverse/reference/copy_chapter.md)
  do the same for chapters of the mirtverse book.
  [`check_material()`](https://www.okanbulut.com/mirtverse/reference/check_material.md)
  runs every exercise’s solution through its check (and can render the
  lab) before students see it, and
  [`preview_lab()`](https://www.okanbulut.com/mirtverse/reference/preview_lab.md)
  opens it.

- New MCP server for instructors:
  [`mv_mcp_server()`](https://www.okanbulut.com/mirtverse/reference/mv_mcp_server.md)
  connects an AI assistant (Claude Desktop, Claude Code, OpenAI Codex,
  the OpenAI Agents SDK or ChatGPT) to a course folder, so instructors
  can revise labs, chapters and notes, build labs on their own data, and
  adapt existing materials (including ltm, eRm, TAM and irtQ code) to
  mirtverse by describing what they want. The assistant reads and edits
  files only inside the course folder, every change is backed up and can
  be undone, it looks up real mirtverse functions instead of guessing,
  and it runs `check_material` after each change. Lab and chapter tools
  wrap the instructor toolkit.
  [`mv_mcp_config()`](https://www.okanbulut.com/mirtverse/reference/mv_mcp_config.md)
  prints the settings to paste into each client. See the new article “An
  AI assistant for your course materials”.

- New teaching lab, “Scoring open-ended responses”:
  `run_lab("open-ended")`. Six science tasks were scored 0-4 by two
  human raters each and by an automated scoring engine. Students check
  rater agreement (exact, adjacent, quadratic weighted kappa), find a
  severe and an inconsistent rater, resolve final scores with third
  reads, compare the PCM, GPCM and GRM, collapse rubric categories with
  disordered steps, and decide whether the engine can replace a human
  reader, including a subgroup fairness check. The new `openended` data
  come with `lab_truth("openended")`.

- New teaching lab, “Designing an adaptive test”:
  `run_lab("cat-design")`. A college wants to replace its 40-item
  placement test with a CAT. Students look at where the item bank is
  informative, run one CAT by hand, simulate 500 students, and weigh
  test length and precision against item exposure (randomesque
  selection), content balancing and the stopping rule. The new `catbank`
  data (a 180-item calibrated bank) come with `lab_truth("catbank")`.

- New teaching lab, “Linking two forms”: `run_lab("linking")`. A
  licensure exam’s pass rate jumps on a new form, and students find out
  why: They calibrate both forms, link them through common items with
  the mean-sigma method, catch an anchor item that drifted, compare
  separate and concurrent calibration, and carry the pass mark over to
  the new form with IRT true-score equating. The new `linking` data (two
  forms in a common-item nonequivalent groups design) come with
  `lab_truth("linking")`.

## mirtverse 0.2.0

### Assessment pipeline

- New assessment pipeline (first phase).
  [`mv_pipeline()`](https://www.okanbulut.com/mirtverse/reference/mv_pipeline.md)
  starts a pipeline that takes a test from response data to a technical
  report in stages, with a gate of checks after each stage:
  [`add_responses()`](https://www.okanbulut.com/mirtverse/reference/add_responses.md)
  scores and screens the data (miskeyed items, missing data,
  straight-lining, rapid guessing, sparse categories),
  [`calibrate()`](https://www.okanbulut.com/mirtverse/reference/calibrate.md)
  fits the model and checks convergence, model fit, local dependence,
  item fit, parameter ranges, DIF (Mantel-Haenszel and standardized mean
  difference with the ETS A/B/C rules) and reliability, and
  [`pipeline_report()`](https://www.okanbulut.com/mirtverse/reference/pipeline_report.md)
  writes the HTML report with a section listing every flag and decision.
  Flags are `info`, `review` or `block`; they warn by default, and with
  `strict = TRUE` open review and block flags stop the next stage until
  a decision is recorded with
  [`acknowledge()`](https://www.okanbulut.com/mirtverse/reference/acknowledge.md)
  or
  [`override()`](https://www.okanbulut.com/mirtverse/reference/acknowledge.md),
  or the item is removed with
  [`drop_items()`](https://www.okanbulut.com/mirtverse/reference/drop_items.md).
  [`flags()`](https://www.okanbulut.com/mirtverse/reference/flags.md)
  lists them, and
  [`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)
  holds every threshold, which users can change by name.
  [`mv_report()`](https://www.okanbulut.com/mirtverse/reference/mv_report.md)
  gains an `extra` argument for additional sections.

- Blueprint and item generation for the assessment pipeline (stages 0
  and 1).
  [`set_blueprint()`](https://www.okanbulut.com/mirtverse/reference/set_blueprint.md)
  records the construct, content cells with target counts, item types,
  score use and target reliability, and flags empty cells and a missing
  score use.
  [`generate_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
  writes multiple-choice items (with keys and option rationales) and
  open-ended items (with rubrics and anchor responses) for each cell
  through ellmer, using the provider set up with
  [`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md),
  and
  [`verify_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
  has an independent model call answer each item without the key.
  [`add_items()`](https://www.okanbulut.com/mirtverse/reference/generate_items.md)
  adds items written by people. The checks flag invalid or disputed
  keys, weak distractors, incomplete rubrics, near-duplicates, thin
  blueprint coverage and hard reading levels, and the pipeline report
  gains blueprint and item development sections.
  [`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)
  gains `duplicate_sim` and `coverage_ratio`.

- Item review and field-test design for the assessment pipeline (stages
  2 and 3).
  [`review_packet()`](https://www.okanbulut.com/mirtverse/reference/review_packet.md)
  writes a review form with one row per item and reviewer (optionally
  after an AI bias and accessibility screen), and
  [`read_reviews()`](https://www.okanbulut.com/mirtverse/reference/review_packet.md)
  reads the decisions back, sets each item’s status by majority and
  flags items with too few reviewers, alignment disagreements,
  sensitivity concerns, revision requests, low reviewer agreement
  (Fleiss’ kappa) and missing provenance.
  [`design_field_test()`](https://www.okanbulut.com/mirtverse/reference/design_field_test.md)
  spreads the approved items over forms with anchor items, and flags
  small samples per item, too few anchors, cells without an anchor and
  poor simulated parameter recovery.
  [`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)
  gains `min_reviewers`, `review_kappa`, `n_rasch`, `n_2pl`, `n_3pl` and
  `recovery_rmse`.

- Item banks and linking for the assessment pipeline (stage 6).
  [`mv_bank()`](https://www.okanbulut.com/mirtverse/reference/mv_bank.md)
  starts an item bank from a calibrated model or pipeline,
  [`link_to_bank()`](https://www.okanbulut.com/mirtverse/reference/link_to_bank.md)
  puts a new calibration on the bank’s scale through anchor items
  (Stocking-Lord, Haebara, mean-sigma, mean-mean or fixed-anchor
  calibration) and flags drifting anchors, too few anchors and unusual
  linking constants, and
  [`bank_items()`](https://www.okanbulut.com/mirtverse/reference/bank_items.md)
  adds the new items to the bank. The pipeline report gains a linking
  section, and
  [`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)
  gains `min_anchors`, `min_anchor_share`, `anchor_displacement`,
  `link_slope_min` and `link_slope_max`.

- Test forms for the assessment pipeline (stage 7).
  [`assemble_forms()`](https://www.okanbulut.com/mirtverse/reference/assemble_forms.md)
  builds one or more fixed forms by automated test assembly (eatATA),
  with a content blueprint, enemy items and parallel forms;
  [`simulate_cat()`](https://www.okanbulut.com/mirtverse/reference/simulate_cat.md)
  simulates a computerized adaptive test with mirtCAT; and
  [`assemble_mst()`](https://www.okanbulut.com/mirtverse/reference/assemble_mst.md)
  assembles a two-stage multistage test and simulates its routing. The
  checks flag unbuildable forms, blueprint and enemy violations,
  non-parallel forms, imprecise forms or CATs, over-exposed and unused
  items, shallow banks and misrouting. The pipeline report gains a forms
  section, and
  [`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)
  gains `parallel_tol`, `cat_sem`, `cat_bias`, `max_exposure`,
  `unused_share`, `bank_depth`, `mst_routing` and `min_group_n`. eatATA
  and mirtCAT are suggested packages.

- Cut scores for the assessment pipeline (stage 8).
  [`set_cuts()`](https://www.okanbulut.com/mirtverse/reference/set_cuts.md)
  records cut scores on the ability or summed-score scale (or from a
  standard-setting panel’s ratings) and estimates classification
  accuracy and consistency, overall and by cut, with kappa and false
  positive and negative rates: By Lee’s (2010) method for summed-score
  cuts and Rudner’s (2001) method for ability cuts, for the calibrated
  test or a fixed form. It flags low accuracy or consistency, imprecise
  cuts and panel disagreement, and the pipeline report gains a cut score
  section.
  [`item_map()`](https://www.okanbulut.com/mirtverse/reference/item_map.md)
  gives the ordered item booklet for Bookmark standard setting.
  [`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)
  gains `cut_accuracy`, `cut_consistency`, `cut_sem` and `panel_sd`.

- Scoring for the assessment pipeline (stage 9).
  [`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md)
  scores open-ended responses against their rubrics with a language
  model through ellmer, or with any trained model that has a
  [`predict()`](https://rdrr.io/r/stats/predict.html) method, and checks
  the machine scores against human scores (Williamson, Xi and Breyer,
  2012): Too few double-scored responses, low human-human or
  machine-human quadratic weighted kappa, shifted score distributions
  and subgroup differences. Short, off-topic and low-confidence
  responses are routed to human scoring, and the final scores can join
  the response data for a mixed-format calibration.
  [`score_persons()`](https://www.okanbulut.com/mirtverse/reference/score_persons.md)
  estimates abilities and flags low reliability and extreme scores.
  [`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)
  gains `n_validation`, `qwk_min`, `qwk_drop`, `score_smd`,
  `subgroup_smd`, `min_confidence`, `min_words` and `max_se`.

- Test security for the assessment pipeline (stage 10).
  [`check_security()`](https://www.okanbulut.com/mirtverse/reference/check_security.md)
  looks for item preknowledge (a likelihood ratio test of leaked against
  secure items), item leakage across administration windows (proportion
  correct up, response times down), parameter drift from the bank,
  answer copying (identical incorrect answers against their expected
  number), aberrant response times (lognormal residuals), sites with too
  many flagged test takers and unusual score gains. Respondent-level
  evidence stays in `p$security$persons`; flags and the report give
  counts only.
  [`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)
  gains `preknowledge_alpha`, `leak_p`, `leak_rt`, `drift_a`, `drift_b`,
  `copy_alpha`, `rt_resid`, `rt_share`, `site_alpha` and `gain_sem`.

- Bank monitoring for the assessment pipeline (stage 12).
  [`monitor_bank()`](https://www.okanbulut.com/mirtverse/reference/monitor_bank.md)
  records each administration in the item bank (item exposure and
  marginal reliability by window) and checks the bank over time: Items
  over-exposed in consecutive windows, content cells with too few active
  items, reliability falling from its first value, and items unused for
  a year.
  [`retire_items()`](https://www.okanbulut.com/mirtverse/reference/retire_items.md)
  retires bank items or sends them back to review.
  [`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)
  gains `exposure_windows`, `cell_depth`, `reliability_drop` and
  `unused_days`.

- The workbench gains a Pipeline tab: Run the data through the
  assessment pipeline’s intake and calibration gates (or load a saved
  pipeline), follow the stage tracker, record decisions on flags, drop
  items and recalibrate, and download the pipeline and its report. The
  SAT12 example in the workbench now loads correctly.

- New article, “An assessment pipeline from blueprint to bank
  monitoring”, takes the `certexam` data through every stage of the
  pipeline.

### Coming from other IRT packages

- New
  [`mirtify()`](https://www.okanbulut.com/mirtverse/reference/mirtify.md)
  translates code written for ltm, eRm, TAM and irtQ into mirt code,
  with a note on every difference between the packages (for example CML
  versus MML in eRm, the scaling constant `D` in irtQ, and the number of
  quadrature points). It covers the model functions and their
  follow-ups: Person scores, item and person fit, information, plots and
  Andersen’s likelihood-ratio test. `run = TRUE` also runs the
  translated code.
  [`mirtify_crosswalk()`](https://www.okanbulut.com/mirtverse/reference/mirtify_crosswalk.md)
  lists every supported function, and the new article “Moving from ltm,
  eRm, TAM or irtQ to mirt” walks through examples and shows how closely
  the translated models match the originals.

- The homepage has a
  [`mirtify()`](https://www.okanbulut.com/mirtverse/reference/mirtify.md)
  section with a short example.

### Teaching and learning

- New interactive teaching labs for measurement courses, built with
  learnr. `run_lab("model-choice")` opens Lab 1, “Choosing a model the
  board can defend”: Students score a certification exam, find a
  miskeyed item, check dimensionality, compare the Rasch, 2PL and 3PL
  models, check item fit and local dependence, and justify a model, with
  feedback on every decision and a summary of their choices at the end.
  `run_lab("decisions")` opens Lab 2, “From parameters to decisions”:
  Reading item parameters, precision at the pass mark, choosing a
  scoring method, classification accuracy, DIF between English and
  French candidates, a memo to the board, and a reveal of the truth
  behind the data.
  [`list_labs()`](https://www.okanbulut.com/mirtverse/reference/run_lab.md)
  lists the labs. The new `certexam` data (with `certexam_key`) are
  simulated with known problems planted for the labs;
  [`lab_truth()`](https://www.okanbulut.com/mirtverse/reference/lab_truth.md)
  reveals them for instructors. The article “Teaching labs for
  measurement courses” introduces the labs for students, followed by an
  instructor guide and an answer key.

- New article, “A course map for instructors”: A suggested 12-week IRT
  syllabus that links each week to articles, labs, functions and
  datasets.

- New teaching lab, “Is the test fair? Detecting DIF”:
  `run_lab("fairness")`. Students investigate a complaint that a
  provincial numeracy test is biased against English language learners:
  They separate impact from DIF, run Mantel-Haenszel and IRT
  likelihood-ratio DIF tests, purify the anchor, judge how much the DIF
  matters for students’ scores with differential test functioning, and
  plan a content review. The new `numeracy` data (with `numeracy_items`)
  have DIF planted on purpose, and `lab_truth("numeracy")` reveals it.
  The “Teaching labs” article covers the new lab, with its answers in
  the answer key at the end.

- New article, “Glossary of IRT terms”: 87 terms in plain language,
  grouped from the basic ideas to test design, each with the mirtverse
  or mirt function that computes it and a figure where one helps. Every
  term has a stable anchor (for example `glossary.html#discrimination`)
  for linking from course materials.

- A printable two-page cheat sheet (PDF), linked from the navbar and the
  README: Page 1 covers analysis and sharing by task, page 2 the
  assessment pipeline stages, gates and flags.

### Sharing results

- New
  [`mv_dashboard()`](https://www.okanbulut.com/mirtverse/reference/mv_dashboard.md)
  builds a read-only ‘shiny’ dashboard of your results for people who do
  not use R. Choose the panels (summary, items with health cards, item
  curves with an ability slider, information, Wright map, score
  distribution and conversion table, and optionally person scores, DIF
  and response times), add a title and logo, and run it.
  [`export_dashboard()`](https://www.okanbulut.com/mirtverse/reference/export_dashboard.md)
  saves it as an `app.R` folder ready for shinyapps.io or Posit Connect.
  The saved dashboard holds summaries only, never the item responses,
  and holds individual scores only when you add the `"persons"` panel.

- `export_dashboard(format = "html")` saves the dashboard as one
  self-contained HTML file that needs no server, no R and no internet
  connection. The item table, item curves with the ability slider, item
  information and person lookup stay interactive.

- The article “Sharing results with a dashboard” is now a full guide:
  When to use a dashboard rather than the workbench or the report, every
  panel, sharing as one HTML file or as a Shiny app, privacy, and a live
  example dashboard to open.

### Scripts from plain language

- New
  [`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
  writes a complete, commented analysis script from a plain-language
  request such as “fit a 2PL, check DIF by gender and make a report”.
  Requests are understood by Claude, OpenAI GPT or a local Ollama model
  (set up once with
  [`mv_ask_setup()`](https://www.okanbulut.com/mirtverse/reference/mv_ask_setup.md)),
  or offline by a built-in keyword parser that asks follow-up questions.
  Only a column summary is ever sent; `anonymize = TRUE` hides column
  names and `dry_run = TRUE` shows exactly what would be sent. Scripts
  can be refined (`mv_ask(scr, "use a 3PL instead")`) and are built from
  an analysis plan
  ([`mv_plan()`](https://www.okanbulut.com/mirtverse/reference/mv_plan.md)):
  Data preparation, model fitting or selection, fit checks, DIF, scores,
  graphics, item cards, reports and response times.
  [`run_script()`](https://www.okanbulut.com/mirtverse/reference/run_script.md)
  runs it, optionally after a dry run on simulated data with the same
  structure, and
  [`save_script()`](https://www.okanbulut.com/mirtverse/reference/run_script.md)
  writes it to a file.
  [`profile_data()`](https://www.okanbulut.com/mirtverse/reference/profile_data.md)
  shows the column summary that is the only information shared with an
  AI model. The workbench now writes its code with the same templates.

- [`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
  reads plans from local models that write text before the JSON (such as
  Qwen on Ollama), and accepts a plan with no extra steps (for example
  DIF requested without a grouping variable), instead of falling back to
  the keyword parser.

- The internal request benchmark (`mirtverse:::ask_benchmark()`) no
  longer stops when a provider cannot be reached; those requests are
  scored as wrong and the reason is printed.

- New article, “mv_ask(): From a sentence to a tested R script”, shows
  the workflow and benchmarks Claude, GPT and local Qwen models against
  the keyword parser.

### Differential item functioning

- New [`dif()`](https://www.okanbulut.com/mirtverse/reference/dif.md)
  tests every item for differential item functioning between groups in
  one call, with likelihood-ratio tests, adjusted p-values and
  expected-score effect sizes.
  [`gg_dif()`](https://www.okanbulut.com/mirtverse/reference/gg_dif.md)
  plots the effects or the item curves by group,
  [`interpret()`](https://www.okanbulut.com/mirtverse/reference/interpret.md)
  describes the results, and `mv_report(dif = )` adds a DIF section to
  the report.

- [`dif()`](https://www.okanbulut.com/mirtverse/reference/dif.md) keeps
  the order of a factor’s levels, so the first level is the reference
  group (earlier development versions sorted the groups alphabetically).

### Response times

- [`fit_rt()`](https://www.okanbulut.com/mirtverse/reference/fit_rt.md)
  gains the normative threshold rules `flag_method = "nt15"` and
  `"nt20"` for rapid guessing (15% and 20% of each item’s mean response
  time), next to `"nt10"`, and the workbench offers all three. Following
  Wise and Ma (2012), the item thresholds of all three rules are now
  capped at 10 seconds; change the cap with the new `nt_max` argument
  (`nt_max = Inf` removes it). The thresholds used are returned in
  `$thresholds`.

- [`fit_rt()`](https://www.okanbulut.com/mirtverse/reference/fit_rt.md)
  no longer fails when some persons have no item responses. mirt drops
  those rows from the fitted data;
  [`fit_rt()`](https://www.okanbulut.com/mirtverse/reference/fit_rt.md)
  now keeps them, and their response times still inform speed.

### Other changes

- The package website moved to <https://www.okanbulut.com/mirtverse/>.

- mirtverse can be cited through its Zenodo DOI; see
  `citation("mirtverse")` or `CITATION.cff`.

- “Get started” gains sections on dashboards,
  [`mv_ask()`](https://www.okanbulut.com/mirtverse/reference/mv_ask.md)
  and the teaching labs, and the workbench article covers the NT10, NT15
  and NT20 rules.

## mirtverse 0.1.0

First release.

- [`launch_workbench()`](https://www.okanbulut.com/mirtverse/reference/launch_workbench.md):
  A seven-step Shiny app that writes reproducible R code.
- [`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md):
  Compares candidate IRT models and explains the recommendation.
- [`interpret()`](https://www.okanbulut.com/mirtverse/reference/interpret.md)
  and
  [`interpret_prompt()`](https://www.okanbulut.com/mirtverse/reference/interpret_prompt.md):
  Plain-language summaries of mirt results.
- [`tidy()`](https://generics.r-lib.org/reference/tidy.html),
  [`glance()`](https://generics.r-lib.org/reference/glance.html),
  [`augment()`](https://generics.r-lib.org/reference/augment.html) and
  [`item_table()`](https://www.okanbulut.com/mirtverse/reference/item_table.md)
  for mirt models.
- ggplot2 graphics:
  [`gg_trace()`](https://www.okanbulut.com/mirtverse/reference/gg_trace.md),
  [`gg_info()`](https://www.okanbulut.com/mirtverse/reference/gg_info.md),
  [`gg_wright()`](https://www.okanbulut.com/mirtverse/reference/gg_wright.md),
  [`gg_itemfit()`](https://www.okanbulut.com/mirtverse/reference/gg_itemfit.md),
  [`gg_q3()`](https://www.okanbulut.com/mirtverse/reference/gg_q3.md),
  [`gg_scores()`](https://www.okanbulut.com/mirtverse/reference/gg_scores.md),
  [`gg_empirical()`](https://www.okanbulut.com/mirtverse/reference/gg_empirical.md)
  and
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html).
- [`item_card()`](https://www.okanbulut.com/mirtverse/reference/item_card.md)
  and
  [`item_cards()`](https://www.okanbulut.com/mirtverse/reference/item_cards.md):
  Item health cards with a traffic-light status.
- [`mv_report()`](https://www.okanbulut.com/mirtverse/reference/mv_report.md):
  A self-contained HTML report.
- [`fit_rt()`](https://www.okanbulut.com/mirtverse/reference/fit_rt.md)
  and
  [`sim_rt()`](https://www.okanbulut.com/mirtverse/reference/sim_rt.md):
  Joint modelling of responses and response times with rapid-guessing
  flags, response time effort and l_t person fit.
