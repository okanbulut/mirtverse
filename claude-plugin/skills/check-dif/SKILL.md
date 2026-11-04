---
name: check-dif
description: Check test items for fairness with differential item functioning (DIF) analysis in mirtverse. Use when the user asks whether items are biased or unfair, work differently for groups (gender, language, country, school, accommodations), or asks for DIF or measurement invariance at the item level.
---

# Check items for DIF

Use the `mirtverse` MCP tools. If they are missing, follow the `setup`
skill first.

1. `project_overview`; if no model is fitted on the data yet, run
   `describe_dataset` and `fit_model` (see the `analyze-test` skill, steps
   1-3). Confirm the grouping column with the user if more than one is
   plausible.
2. Check group sizes in `describe_dataset`. Warn when a group has fewer than
   about 200 people: The tests lose power and effect sizes are unstable.
   With more than two groups, explain that the effect sizes compare each
   focal group with the reference group.
3. `check_dif` with `group`. Keep the default BH adjustment unless the user
   asks otherwise.
4. `plot_model` with `type = "dif"`; for flagged items also with
   `items = [...]` to draw their curves by group. View the images.
5. Read `guide` topic `interpreting` (DIF section), then explain:
   - Which items are flagged, the direction (which group the item favours at
     equal ability) and the size (ESD/UESD; negligible, moderate or large).
   - Statistical versus practical importance.
   - That DIF is a reason for content review, not proof of bias, and what a
     review panel should look at (language load, cultural context,
     curriculum exposure, item format).
   - Whether several items favour the same group (possible test-level
     impact).
6. `save_script`, and offer `write_report` (it includes the DIF section).
