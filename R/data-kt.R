#' Cognitive Tutor practice logs
#'
#' Practice logs from a Cognitive Tutor for middle and high school
#' mathematics: 587 students' first attempts at 16,857 problem steps, each
#' tagged with one of 12 knowledge components (such as "Calculate unit rate"
#' or "Plot pi"). This is the sample used in the pyBKT examples and in Bulut
#' et al. (2023), and it fits [mv_kt_fit()] as it is.
#'
#' @format A tibble with 16,857 rows and 7 columns:
#' \describe{
#'   \item{student}{anonymized student id.}
#'   \item{problem}{the problem the step belongs to.}
#'   \item{step}{the step of the problem.}
#'   \item{skill}{the knowledge component of the step.}
#'   \item{correct}{1 if the first attempt at the step was correct, 0
#'     otherwise.}
#'   \item{opportunity}{the student's attempt number on the skill.}
#'   \item{time}{the time of the first attempt (UTC).}
#' }
#' @source `data/ct.csv` of the pyBKT-examples repository
#'   (<https://github.com/CAHLR/pyBKT-examples>), a sample of the Cognitive
#'   Tutor data released through the PSLC DataShop for the KDD Cup 2010
#'   (Stamper et al., 2010). The script is `data-raw/kt.R` in the package's
#'   GitHub repository.
#' @references
#' Bulut, O., Shin, J., Yildirim-Erbasli, S. N., Gorgun, G., & Pardos, Z. A.
#' (2023). An introduction to Bayesian knowledge tracing with pyBKT.
#' *Psych, 5*(3), 770-786. \doi{10.3390/psych5030050}
#'
#' Stamper, J., Niculescu-Mizil, A., Ritter, S., Gordon, G. J., &
#' Koedinger, K. R. (2010). *Challenge data sets from KDD Cup 2010*.
#' PSLC DataShop. <https://pslcdatashop.web.cmu.edu/KDDCup/>
#' @seealso [mv_kt_fit()]
#' @examples
#' head(cognitive_tutor)
#' sort(table(cognitive_tutor$skill), decreasing = TRUE)
"cognitive_tutor"

#' Practice logs for the fractions knowledge graph
#'
#' Simulated practice logs of 400 students on the Grade 5 fractions items
#' of [fractions_kg]. Students practise the six concepts in blocks, mostly
#' in the curriculum order; a block ends after three correct answers in a
#' row or 15 attempts. The logs follow a Bayesian knowledge tracing model
#' in which a concept is learned much more slowly while its prerequisites
#' are not yet known. [lab_truth()] (`"fractions_logs"`) returns the
#' generating values and each student's true state at every attempt.
#'
#' @format A tibble with one row per attempt and 4 columns: `student`
#'   (`P001` to `P400`), `attempt` (the student's attempt number over the
#'   whole session), `item` (an item of [fractions_kg]; F14 is not
#'   practised) and `correct` (1 = correct, 0 = wrong). There is no skill
#'   column: Fit it with `mv_kt_fit(fractions_logs, kg = fractions_kg)`.
#' @source Simulated; the script is `data-raw/kt.R` in the package's
#'   GitHub repository.
#' @seealso [mv_kt_fit()], [fractions]
#' @examples
#' head(fractions_logs)
#' table(table(fractions_logs$student))
"fractions_logs"
