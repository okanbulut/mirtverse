#' Compare knowledge tracing with IRT
#'
#' **Experimental.** Puts Bayesian knowledge tracing and a Rasch (1PL) IRT
#' model side by side on the same practice logs, as in the second and third
#' case studies of Bulut et al. (2023):
#'
#' * **Forecasting.** For every student and skill, the last `holdout` share
#'   of the attempts is held out. Both models are fitted to the earlier
#'   attempts. BKT predicts each held-out answer from the student's answers
#'   up to it (it updates after every answer, which is the point of
#'   knowledge tracing); IRT predicts from the student's ability and the
#'   item's difficulty, which stay fixed. RMSE, accuracy and AUC are
#'   reported per skill.
#' * **Item difficulty.** Per skill, the correlation between the IRT item
#'   difficulties and the log of the BKT item guess parameters (from a
#'   `multigs` model): Items that are easy to guess should be easy items.
#'
#' The IRT model is fitted per skill as a crossed random effects logistic
#' model (`correct ~ 1 + (1 | student) + (1 | item)`) with the lme4 package,
#' which suits sparse logs where most students see only some items.
#'
#' @param data,... practice logs and the arguments of [mv_kt_fit()] (such
#'   as `kg`, `skills` or the column names). The logs need an item column.
#' @param holdout share of each student's attempts on a skill held out for
#'   forecasting (students with fewer than three attempts on a skill are
#'   used for fitting only).
#' @return An `mv_kt_irt` object: A list with `accuracy` (one row per skill
#'   and model: `skill`, `model`, `n_test`, `rmse`, `accuracy`, `auc`) and
#'   `items` (one row per skill: `n_items`, the `correlation` between IRT
#'   difficulty and the log of the BKT guess, and the item table in
#'   `tidy(x, "difficulty")`). Use `print()`, `tidy()` and `glance()`.
#' @references
#' Bulut, O., Shin, J., Yildirim-Erbasli, S. N., Gorgun, G., & Pardos, Z. A.
#' (2023). An introduction to Bayesian knowledge tracing with pyBKT.
#' *Psych, 5*(3), 770-786. \doi{10.3390/psych5030050}
#' @examples
#' \donttest{
#' if (requireNamespace("lme4", quietly = TRUE)) {
#'   cmp <- mv_kt_irt(cognitive_tutor, item = "problem",
#'                    skills = c("Plot pi", "Plot imperfect radical"))
#'   cmp
#' }
#' }
#' @export
mv_kt_irt <- function(data, ..., holdout = 0.3) {
  if (!requireNamespace("lme4", quietly = TRUE))
    stop("mv_kt_irt() needs the lme4 package: install.packages(\"lme4\").", call. = FALSE)
  if (!is.numeric(holdout) || holdout <= 0 || holdout >= 1)
    stop("`holdout` must be between 0 and 1.", call. = FALSE)
  args <- list(...)
  args$multigs <- NULL
  a <- function(nm, def) args[[nm]] %||% def
  logs <- kt_prepare(data, a("kg", NULL), a("student", "student"), a("item", "item"),
                     a("skill", "skill"), a("correct", "correct"), a("order", NULL),
                     a("skills", NULL), need_item = TRUE)
  # the last `holdout` share of each student's attempts on each skill
  key <- paste(logs$student, logs$skill, sep = "\r")
  pos <- stats::ave(seq_len(nrow(logs)), key, FUN = seq_along)
  len <- stats::ave(seq_len(nrow(logs)), key, FUN = length)
  n_test <- ifelse(len >= 3, pmax(1, floor(holdout * len)), 0)
  test <- pos > len - n_test
  std <- data.frame(student = logs$student, item = logs$item, skill = logs$skill,
                    correct = logs$correct, stringsAsFactors = FALSE)
  fit_args <- args[setdiff(names(args), c("kg", "student", "item", "skill", "correct", "order"))]
  kt <- do.call(mv_kt_fit, c(list(data = std[!test, , drop = FALSE]), fit_args))
  ktg <- do.call(mv_kt_fit, c(list(data = std[!test, , drop = FALSE], multigs = TRUE), fit_args))
  # BKT forecasts: Run the model over all attempts, score the held-out ones
  pr <- kt_filter(kt, transform(logs, .row = seq_len(nrow(logs))))
  acc <- list(); items <- list(); diff <- list()
  for (s in kt$params$skill) {
    ins <- logs$skill == s
    tr <- std[ins & !test, , drop = FALSE]
    te <- std[ins & test, , drop = FALSE]
    if (!nrow(te)) next
    bkt_p <- pr$p_correct[pr$skill == s][test[ins]]
    m <- tryCatch(suppressMessages(suppressWarnings(lme4::glmer(
      correct ~ 1 + (1 | student) + (1 | item), data = tr, family = stats::binomial,
      control = lme4::glmerControl(calc.derivs = FALSE)))), error = function(e) NULL)
    irt_p <- if (is.null(m)) rep(NA_real_, nrow(te)) else
      as.numeric(stats::predict(m, newdata = te, type = "response", allow.new.levels = TRUE))
    for (k in list(list("BKT", bkt_p), list("IRT (1PL)", irt_p))) {
      mt <- kt_metrics(te$correct, k[[2]])
      acc[[length(acc) + 1]] <- data.frame(skill = s, model = k[[1]], n_test = nrow(te),
                                           rmse = mt[["rmse"]], accuracy = mt[["accuracy"]],
                                           auc = mt[["auc"]], stringsAsFactors = FALSE)
    }
    if (!is.null(m)) {
      re <- lme4::ranef(m)$item
      b <- -(lme4::fixef(m)[[1]] + re[, 1])
      gi <- ktg$items[ktg$items$skill == s, , drop = FALSE]
      d <- data.frame(skill = s, item = rownames(re), difficulty = b,
                      guess = gi$guess[match(rownames(re), gi$item)], stringsAsFactors = FALSE)
      d <- d[!is.na(d$guess), , drop = FALSE]
      diff[[length(diff) + 1]] <- d
      r <- if (nrow(d) >= 5 && stats::sd(d$difficulty) > 0) stats::cor(d$difficulty, log(d$guess)) else NA_real_
      items[[length(items) + 1]] <- data.frame(skill = s, n_items = nrow(d), correlation = r,
                                               stringsAsFactors = FALSE)
    }
  }
  if (!length(acc)) stop("No skill has students with three or more attempts to hold out.", call. = FALSE)
  out <- list(accuracy = as_tbl(do.call(rbind, acc)),
              items = if (length(items)) as_tbl(do.call(rbind, items)),
              difficulty = if (length(diff)) as_tbl(do.call(rbind, diff)),
              settings = list(holdout = holdout))
  class(out) <- "mv_kt_irt"
  out
}

#' @export
print.mv_kt_irt <- function(x, ...) {
  cat("<mv_kt_irt> (EXPERIMENTAL) Knowledge tracing vs IRT on the same logs\n")
  g <- glance(x)
  cat(sprintf("Forecasts of the last %.0f%% of each student's attempts (%d skill(s)):\n",
              100 * x$settings$holdout, g$n_skills))
  cat(sprintf("  BKT:       RMSE %.3f, accuracy %.3f, AUC %.3f\n", g$bkt_rmse, g$bkt_accuracy, g$bkt_auc))
  cat(sprintf("  IRT (1PL): RMSE %.3f, accuracy %.3f, AUC %.3f\n", g$irt_rmse, g$irt_accuracy, g$irt_auc))
  cat("(means over skills)\n")
  if (!is.null(x$items) && any(!is.na(x$items$correlation)))
    cat(sprintf("IRT item difficulty vs log BKT guess: Median correlation %.2f over %d skill(s)\n",
                stats::median(x$items$correlation, na.rm = TRUE), sum(!is.na(x$items$correlation))))
  invisible(x)
}

#' Tidy a comparison of knowledge tracing and IRT
#'
#' @param x a result of [mv_kt_irt()].
#' @param what `"accuracy"` (one row per skill and model, the default),
#'   `"items"` (one row per skill: The correlation between IRT difficulty
#'   and the log of the BKT guess) or `"difficulty"` (one row per item).
#' @param ... unused.
#' @return A tibble. `glance()` gives the mean RMSE, accuracy and AUC of
#'   each model over skills.
#' @name tidy_mv_kt_irt
#' @export
tidy.mv_kt_irt <- function(x, what = c("accuracy", "items", "difficulty"), ...) {
  what <- match.arg(what)
  x[[what]]
}

#' @rdname tidy_mv_kt_irt
#' @export
glance.mv_kt_irt <- function(x, ...) {
  a <- as.data.frame(x$accuracy)
  f <- function(model, col) mean(a[[col]][a$model == model], na.rm = TRUE)
  as_tbl(data.frame(n_skills = length(unique(a$skill)),
                    bkt_rmse = f("BKT", "rmse"), bkt_accuracy = f("BKT", "accuracy"),
                    bkt_auc = f("BKT", "auc"), irt_rmse = f("IRT (1PL)", "rmse"),
                    irt_accuracy = f("IRT (1PL)", "accuracy"), irt_auc = f("IRT (1PL)", "auc")))
}
