# Teaching AI in measurement with mirtverse

Instructors trained in item response theory (IRT) often want to add AI to a
course: Automated scoring, predicting item difficulty from item text,
automatic item generation (AIG), large language models (LLMs), and the
validity and fairness of all of these. mirtverse teaches each topic next to
the psychometric check that goes with it. Keep that pairing in everything
you write: **No AI output counts until a psychometric check has passed.**

## What exists

| Topic | Book chapter (copy_chapter) | Built-in lab (copy_lab) | Toolkit section (add_lab_section) | Functions |
|---|---|---|---|---|
| ML vocabulary and thinking | `ml-lens` | — | — | — |
| Item text and difficulty | `item-text` | `item-text` (Lab 8) | `item-features` | `item_features()`, `predict_difficulty()` |
| Automatic item generation | `aig` | `aig` (Lab 9) | `aig` | `item_model()`, `generate_isomorphs()`, `calibrate_families()` |
| Automated scoring | `auto-scoring` | `auto-scoring` (Lab 7), `open-ended` (Lab 6) | `ai-scoring` | `train_scorer()`, `agreement_report()`, `score_open()` |
| LLMs as a colleague | `llms` | — | — | `mv_ask()`, `mv_llm_replay()` |
| Validity, fairness, governance | `ai-validity` | `ai-audit` (Lab 10) | `ai-scoring` (its audit part) | `ai_audit()`, `validity_argument()` |

Call `list_templates` for the current list and look up every function with
`mirtverse_help` before you use it.

## Choosing the form

- **The instructor has their own data** (item text, item families, or
  machine scores of written answers): Build a lab with `new_lab` and the AI
  section types below. Every number and answer check is computed from their
  data, so nothing is hard-coded.
- **The instructor wants a complete, story-driven lab** with planted
  problems for students to find: Copy the closest built-in lab
  (`copy_lab`). Its text is written for its own simulated data, so do not
  swap that data; change the story, the questions and the setting instead.
- **The instructor wants readings or lecture notes:** Copy the AI chapter
  (`copy_chapter`) and adapt it. All AI chapters run offline.

## The AI section types and their data

`new_lab` takes the responses as usual and, for the AI sections, one or two
extra tables. Check each file with `describe_dataset` and rename columns to
these names first (write the renamed copy under `data/`; never change the
instructor's original).

- **`item_info`** (one row per item):
  - `item`: The item names, exactly as in the response columns.
  - `stem`, and for multiple-choice items `A` to `E` and `key` (the letter
    of the keyed option): Enables **`item-features`**, which measures the
    wording with `item_features()` and predicts the items' IRT difficulty
    with `predict_difficulty()`.
  - `family`: The item model or family of each item. Enables **`aig`**,
    which checks with `calibrate_families()` whether the items of each
    family are equally difficult.
- **`scores`** (one row per scored written response): `machine` and
  `human1` (`NA` where no person read the response), and optionally
  `human2`, `group`, `item` and `period`. Enables **`ai-scoring`**, which
  runs `agreement_report()` and `ai_audit()`. The `scores` can come from any
  engine, an LLM or a trained model; the responses can be the test's other
  items.

`new_lab` adds the AI sections by default when the data for them are
given; name `sections` to choose. `add_lab_section` refuses an AI section
whose data are missing, and `swap_lab_data` keeps the extra tables unless
new ones are given.

For a sensible size, `item-features` needs at least 20 items with text
(cross-validation with fewer is unstable), `aig` needs families of at least
3 items each, and `ai-scoring` needs a validity sample of at least a few
hundred human-scored responses.

## Writing AI content

- **Name the classical twin.** Every AI method has a measurement
  counterpart: Item features and the LLTM, an engine and a rater, item
  families and isomorphs, an audit and a validity argument. Say which, in
  the first paragraph.
- **Check before trusting.** Generated items are verified and calibrated;
  machine scores are compared with human scores overall and within groups;
  predicted difficulties are cross-validated. Show the check in the same
  section as the method.
- **Use the words carefully.** "Bias" means a systematic difference for a
  group at the same level of what is measured, not any difference between
  groups. "Accuracy" of an engine is agreement with people, which is only
  as good as the people. Use the glossary terms (`glossary.html#ai`).
- **No live model calls in labs.** Labs and chapters must run offline and
  give the same answer every time. For an LLM example use the replay mode
  (`mv_llm_replay()`) or show the code with `eval = FALSE`.
- **No real student text.** Use simulated data or text the instructor has
  the right to share; written answers can identify students.
- **End with a decision.** A lab ends with what the program should do, who
  is accountable, and what to monitor; `validity_argument()` turns an audit
  into that structure.

## Course-level material

The course map (`course-map.html` on the mirtverse site) has an optional
four-week AI module and a one-day workshop schedule built from the chapters
and labs above. Point instructors to it when they ask how to fit AI into a
semester. For a workshop, `copy_workshop(file.path(course, "workshop"))`
copies editable slides and a facilitator's guide into the course folder
(run it through the instructor's R session or ask them to; it is not one of
your tools).

`simulate_llm_respondents()` and `compare_synthetic()` are experimental.
Use them only to show what simulated respondents get wrong, never to
estimate item parameters or to stand in for real data.
