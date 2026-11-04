---
name: write-report
description: Write an IRT technical report or a plain-language results summary from a mirtverse analysis. Use when the user asks for a report, write-up, summary for stakeholders, methods and results text for a thesis or paper, or something to share with a committee, school board or client.
---

# Write a report

Use the `mirtverse` MCP tools. If no model exists yet, run the
`analyze-test` skill first.

1. Ask, if not stated, who the audience is (psychometric reviewers,
   teachers, a school board, a thesis committee) and what decisions the
   scores support. It decides the tone and the level of detail.
2. `project_overview`, `interpret_model` and `check_items` so you know the
   findings; `check_dif` if a group column exists and it has not been run.
3. `write_report` for the HTML technical report (fit, items with health
   cards, DIF, scores and the R code).
4. Write the summary in the conversation (or as a Markdown file in
   `mirtverse-output/` if the user wants a file):
   - Technical audience: Methods (data, model and why, estimation, fit
     indices, DIF method) and Results (fit, reliability, item findings, DIF,
     score distribution), with numbers and software versions. For a thesis
     or paper, draft the Methods paragraph with `run_r` and
     `cite_methods(<name>_sel)` (or `cite_methods(<name>)` when the model
     was not chosen with `model = "auto"`); it writes APA-style text with
     references. Adapt it rather than pasting it unchanged.
   - Non-technical audience: What was checked, the verdict, what it means
     for the scores, and what to do next, with the few numbers that matter.
5. `save_script`, and list the files the user can share.

Every number must come from a tool. Mention limitations honestly (sample
size, convergence, DIF anchors, what the analysis cannot show about
validity).
