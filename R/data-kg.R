#' Grade 5 fractions test with its knowledge graph
#'
#' Simulated right/wrong responses of 1,200 Grade 5 students to a fictional
#' 24-item fractions test, and the knowledge graph the curriculum team wrote
#' for it. The graph has six concepts (fraction meaning, equivalent
#' fractions, mixed numbers, comparing fractions, common denominators, and
#' adding and subtracting), the prerequisite edges between them, and the
#' concepts each item measures; three items measure two concepts.
#'
#' Students' proficiency in a concept was simulated from their proficiency
#' in its prerequisites plus new learning, and items deeper in the learning
#' order are harder, so the data carry the structure of a real learning
#' progression. The published graph is not quite the graph the data were
#' simulated from: Some problems were planted on purpose for practice in
#' checking a graph against data; `lab_truth("fractions")` lists them and
#' returns the true graph and parameters.
#'
#' @format `fractions` is a data frame with 1,200 rows and 25 columns: `id`
#'   (student ID) and `F01` to `F24` (1 = correct, 0 = incorrect).
#'   `fractions_kg` is an [mv_kg][mv_kg_build] knowledge graph with 6
#'   concepts, 24 items, 5 prerequisite edges and 27 item-to-concept links.
#' @source Simulated; the script is `data-raw/fractions.R` in the package's
#'   GitHub repository.
#' @seealso [fraction_subtraction] for real data with a Q-matrix;
#'   [mv_kg_check()] and [gg_kg()].
#' @examples
#' fractions_kg
#' gg_kg(fractions_kg)
#' colMeans(fractions[, -1])
#' @name fractions
"fractions"

#' @rdname fractions
"fractions_kg"

#' Tatsuoka's fraction subtraction data with its Q-matrix
#'
#' Right/wrong responses of 536 middle school students to 20 fraction
#' subtraction items (Tatsuoka, 1984), with the 8-attribute Q-matrix used by
#' de la Torre and Douglas (2004) and DeCarlo (2011), stored as a knowledge
#' graph. It is the best-known real dataset in cognitive diagnosis, and it
#' is the real-data example for the knowledge graph functions.
#'
#' The eight attributes are: Convert a whole number to a fraction
#' (`convert_whole`), separate a whole number from a fraction
#' (`separate_whole`), simplify before subtracting (`simplify_first`), find a
#' common denominator (`common_denominator`), borrow from the whole number
#' part (`borrow_whole`), column borrow to subtract the second numerator
#' from the first (`column_borrow`), subtract numerators
#' (`subtract_numerators`) and reduce answers to simplest form
#' (`reduce_answer`). No prerequisite relations between the attributes were
#' published with the Q-matrix, so the graph has none; add your own with
#' [mv_kg_build()].
#'
#' @format `fraction_subtraction` is a data frame with 536 rows and 20
#'   columns, `FS01` to `FS20` (1 = correct, 0 = incorrect), in the order of
#'   `Item1` to `Item20` in the CDM package. `fraction_subtraction_kg` is an
#'   [mv_kg][mv_kg_build] knowledge graph with 8 concepts, 20 items and the
#'   item-to-attribute links of the Q-matrix. Its item metadata (see
#'   [mv_kg_annotate()]) has the problem each item asks, in a column `text`
#'   (for example `"3 1/2 - 2 3/2"`), which [mv_kg_extract()] can read.
#' @source Copied from the `fraction.subtraction.data` and
#'   `fraction.subtraction.qmatrix` datasets of the CDM package (Robitzsch,
#'   Kiefer, George and Uenlue; GPL). The data first appeared in Tatsuoka
#'   (1984) and are published in Tatsuoka (2002). The item text follows the
#'   problems as listed by de la Torre and Douglas (2004).
#' @references
#' DeCarlo, L. T. (2011). On the analysis of fraction subtraction data: The
#' DINA model, classification, latent class sizes, and the Q-matrix.
#' *Applied Psychological Measurement, 35*, 8-26.
#'
#' de la Torre, J., & Douglas, J. (2004). Higher-order latent trait models
#' for cognitive diagnosis. *Psychometrika, 69*, 333-353.
#'
#' Tatsuoka, C. (2002). Data analytic methods for latent partially ordered
#' classification models. *Journal of the Royal Statistical Society, Series
#' C, 51*, 337-350.
#'
#' Tatsuoka, K. K. (1984). *Analysis of errors in fraction addition and
#' subtraction problems* (Final report for NIE-G-81-0002). University of
#' Illinois, Urbana-Champaign.
#' @examples
#' fraction_subtraction_kg
#' mv_kg_check(fraction_subtraction_kg)
#' tidy(fraction_subtraction_kg, "items")
#' gg_kg(fraction_subtraction_kg)
#' @name fraction_subtraction
"fraction_subtraction"

#' @rdname fraction_subtraction
"fraction_subtraction_kg"
