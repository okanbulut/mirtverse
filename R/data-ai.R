#' Numeracy items with their text, for the AI Hub
#'
#' The text and field-test statistics of 192 simulated Grade 7 numeracy
#' multiple-choice items, written from 12 item models (families) of 16 items
#' each, such as unit rates, percents, elapsed time and simple equations.
#' Within a family the items differ in their numbers, names and contexts, so
#' the data show how far surface features move item difficulty. The items
#' were calibrated with the 2PL on a simulated field test of 1,500 test
#' takers.
#'
#' The dataset is for learning to predict item difficulty from item text and
#' to calibrate item families from automatic item generation. Some problems
#' were planted on purpose; `lab_truth("itemtext")` lists them and the true
#' item parameters. Some families repeat a stem with different options (for
#' example "Which number is the greatest?"); the extra context sentences are
#' deliberately unrelated to the question, to add reading load.
#'
#' @format A data frame with 192 rows (one per item) and 17 columns:
#'   `id` (`N01-01` to `N12-16`: family and item number), `family` (the item
#'   model), `domain` (content area), `stem` (the question), `A` to `D` (the
#'   options), `key` (the keyed option), `decimal` (1 if the item uses
#'   decimals or fractions), `digits` (digits in the largest number),
#'   `context` (1 if the stem starts with a context sentence), `a` and `b`
#'   (2PL discrimination and difficulty from the field test), `a_se` and
#'   `b_se` (their standard errors) and `p_field` (share correct in the field
#'   test).
#' @source Simulated; the script is `data-raw/itemtext.R` in the package's
#'   GitHub repository.
#' @seealso [essays] and [aigfield], the other AI Hub datasets; the
#'   [AI Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.html).
#' @examples
#' head(itemtext[, c("id", "family", "stem", "key", "b")])
#' # family means of difficulty
#' sort(tapply(itemtext$b, itemtext$family, mean))
#' # surface features and difficulty
#' summary(lm(b ~ family + decimal + digits + context, data = itemtext))
"itemtext"

#' Short science explanations scored by raters, for the AI Hub
#'
#' 1,600 simulated written answers of 400 Grade 8 students (100 of them
#' English language learners, ELL) to four science prompts, each scored 0 to
#' 4 by trained raters. A response's true score is the number of the prompt's
#' four key ideas it states correctly. The prompts are E1 (why ice floats),
#' E2 (why Earth has seasons), E3 (how plants make food) and E4 (why a metal
#' spoon feels colder than a wooden one).
#'
#' The dataset is for learning automated scoring: training a scorer on the
#' text, checking machine-human agreement, and checking that the scorer is
#' fair to ELL students. Some problems were planted on purpose;
#' `lab_truth("essays")` lists them and the true scores. Every response has
#' one human score (`human1`); 40% were scored again (`human2`) so that
#' human-human agreement can be compared with machine-human agreement.
#'
#' @format A data frame with 1,600 rows (one per response) and 8 columns:
#'   `id` (response ID), `student` (student ID), `prompt` (`E1` to `E4`),
#'   `group` (factor, `Fluent` or `ELL`), `response` (the text), `words`
#'   (number of words), `human1` (first rater's score, 0 to 4) and `human2`
#'   (second rater's score, `NA` when the response was read once).
#' @source Simulated; the script is `data-raw/essays.R` in the package's
#'   GitHub repository.
#' @seealso [itemtext] and [aigfield], the other AI Hub datasets; [score_open()] to score
#'   responses and check them against human scores.
#' @examples
#' essays$response[1:3]
#' table(essays$prompt, essays$human1)
#' # human-human agreement on the double-scored responses
#' with(essays, mean(human1 == human2, na.rm = TRUE))
"essays"

#' A field test of generated mathematics items, for the AI Hub
#'
#' Scored responses (1 correct, 0 incorrect) of 1,000 simulated Grade 6
#' students to 60 multiple-choice items, generated with [generate_isomorphs()]
#' from six item models of 10 isomorphs each. The items, their options and the
#' values they were generated from are in [aigfield_items].
#'
#' The dataset is for learning to calibrate item families from automatic
#' item generation: Checking that the isomorphs of a model are equally
#' difficult, so that the family mean can stand in for field testing new
#' items. Some problems were planted on purpose; `lab_truth("aigfield")` lists
#' them and the true item parameters.
#'
#' @format A data frame with 1,000 rows (one per student) and 60 columns
#'   named by item id, `PER-01` to `TRI-10`.
#' @source Simulated; the script is `data-raw/aigfield.R` in the package's
#'   GitHub repository.
#' @seealso [aigfield_items]; [calibrate_families()].
#' @examples
#' dim(aigfield)
#' # share correct by item model
#' round(tapply(colMeans(aigfield), sub("-.*", "", names(aigfield)), mean), 2)
"aigfield"

#' The generated items of the AIG field test
#'
#' The 60 items answered in [aigfield], generated from six item models: PER
#' (perimeter of a rectangle), EQN (a two-step equation), PCT (a percent
#' increase), SUB (subtracting three-digit numbers), OOO (order of
#' operations) and TRI (area of a triangle).
#'
#' @format A data frame with 60 rows (one per item) and 23 columns: `id`,
#'   `model`, `stem`, the options `A` to `D`, `key` (the keyed option), the
#'   values each item was generated from (`len` and `wid` for PER; `coef`,
#'   `sol` and `sub` for EQN; `price` and `rate` for PCT; `top` and `bottom`
#'   for SUB; `n1`, `n2` and `n3` for OOO; `base` and `height` for TRI; `NA`
#'   for the variables of other models) and `values` (the same values as
#'   text).
#' @source Simulated; the script is `data-raw/aigfield.R` in the package's
#'   GitHub repository.
#' @seealso [aigfield]; [item_model()] and [generate_isomorphs()].
#' @examples
#' aigfield_items[c(1, 11, 21), c("id", "stem", "A", "B", "C", "D", "key")]
"aigfield_items"

#' An AI-scored science test over two years, for the AI Hub
#'
#' Simulated scores of 3,000 Grade 8 students (1,500 in 2025 and 1,500 in
#' 2026, a quarter of them English language learners, ELL) on a science test
#' with 16 multiple-choice items and 4 constructed-response items, as scored
#' operationally: The constructed responses (`CR1` to `CR4`, 0 to 3 points)
#' are scored by an automated scoring engine. The human scores of the
#' validity sample are in [aiscored_cr].
#'
#' The dataset is for learning to audit an AI component with [ai_audit()].
#' Some problems were planted on purpose; `lab_truth("aiscored")` lists them
#' and the true scores.
#'
#' @format A data frame with 3,000 rows (one per student) and 23 columns:
#'   `student`, `year` (2025 or 2026), `group` (factor, `Fluent` or `ELL`),
#'   `MC01` to `MC16` (0/1) and `CR1` to `CR4` (machine scores, 0 to 3).
#' @source Simulated; the script is `data-raw/aiscored.R` in the package's
#'   GitHub repository.
#' @seealso [aiscored_cr]; [ai_audit()].
#' @examples
#' table(aiscored$year, aiscored$group)
#' colMeans(aiscored[, c("CR1", "CR2", "CR3", "CR4")])
"aiscored"

#' Machine and human scores of the AI-scored test
#'
#' The constructed responses of [aiscored], one row per student and item,
#' with the engine's score and, for the validity sample, human scores: 20%
#' of students were scored by a human rater as well, and half of those by a
#' second rater.
#'
#' @format A data frame with 12,000 rows and 7 columns: `student`, `year`,
#'   `group`, `item` (`CR1` to `CR4`), `machine` (the engine's score, 0 to
#'   3), `human1` and `human2` (the human scores, `NA` when the response was
#'   not read).
#' @source Simulated; the script is `data-raw/aiscored.R` in the package's
#'   GitHub repository.
#' @seealso [aiscored]; [ai_audit()], [agreement_report()].
#' @examples
#' cr <- aiscored_cr[!is.na(aiscored_cr$human1), ]
#' agreement_report(cr$machine, cr$human1, cr$human2, by = cr$item)
"aiscored_cr"
