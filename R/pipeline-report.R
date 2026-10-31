#' Pipeline stage: technical report
#'
#' Writes the HTML technical report for a calibrated pipeline: everything
#' [mv_report()] shows (summary, model fit, items, graphics, scores, item
#' health cards), plus a *Pipeline decisions* section with the stages, every
#' flag and its status, the decision log with notes, and the rules in effect,
#' and a *Groups* section with score summaries by group. The reproducibility
#' section lists the pipeline code that was run.
#'
#' Before writing, the report gate checks one thing (threshold from
#' [mv_rules()]):
#'
#' * `small_group` (block): a group with fewer than `min_group_n`
#'   respondents. Its summary is left out of the report so that individuals
#'   cannot be identified.
#'
#' Flags from earlier stages that are still open are listed in the report as
#' open.
#'
#' @param p a calibrated pipeline from [calibrate()].
#' @param file path of the `.html` file to write.
#' @param title report title; defaults to the pipeline title.
#' @param author optional author line.
#' @param open logical; open the report in a browser afterwards.
#' @param ... further arguments passed to [mv_report()], such as `cards`.
#' @return The pipeline, invisibly, with the reporting stage recorded. The
#'   report path is stored in `p$report`.
#' @examples
#' \donttest{
#' p <- add_responses(mv_pipeline("Certification exam"), certexam, items = 3:34,
#'                    key = certexam_key, group = "language")
#' p <- calibrate(p, model = "3PL")
#' p <- pipeline_report(p, file = tempfile(fileext = ".html"))
#' }
#' @export
pipeline_report <- function(p, file = "pipeline-report.html", title = p$title, author = NULL,
                            open = interactive() && !isTRUE(getOption("mirtverse.dry_run")),
                            ...) {
  check_pipeline(p)
  cl <- match.call()
  if (is.null(p$model)) stop("Calibrate the pipeline with calibrate() first.", call. = FALSE)
  enforce_gate(p, "reporting")

  groups <- NULL
  new <- empty_flags()
  if (!is.null(p$data$group)) {
    sizes <- table(p$data$group)
    small <- sizes < p$rules$min_group_n
    new <- new_flag("reporting", "small_group", names(sizes)[small],
                    sprintf("n = %d", as.integer(sizes[small])),
                    sprintf("fewer than %d respondents", p$rules$min_group_n), "block",
                    "The group's summary is left out of the report; combine small groups to report them.")
    groups <- group_summary(p, names(sizes)[!small])
  }
  p <- set_stage_flags(p, "reporting", new)
  p <- set_stage(p, "reporting", "done", sprintf("written to %s", basename(file)))
  p <- log_event(p, "report", file)
  p <- add_code(p, cl)

  extra <- list()
  if (!is.null(p$blueprint)) extra[["Blueprint"]] <- blueprint_html(p)
  if (!is.null(p$items)) extra[["Item development"]] <- items_html(p)
  if (!is.null(p$field_test)) extra[["Field-test design"]] <- field_test_html(p)
  if (!is.null(groups)) extra[["Groups"]] <- groups_html(groups, p)
  if (!is.null(p$link)) extra[["Linking"]] <- linking_html(p)
  if (!is.null(p$forms)) extra[["Forms"]] <- forms_html(p)
  if (!is.null(p$cuts)) extra[["Cut scores"]] <- cuts_html(p)
  if (!is.null(p$open_scores) || !is.null(p$scores)) extra[["Scoring"]] <- scoring_html(p)
  if (!is.null(p$security)) extra[["Test security"]] <- security_html(p)
  if (!is.null(p$monitoring)) extra[["Bank monitoring"]] <- monitoring_html(p)
  extra[["Pipeline decisions"]] <- decisions_html(p)
  x <- if (!is.null(p$selection)) p$selection else p$model
  mv_report(x, file = file, title = title, author = author, code = p$code, extra = extra,
            open = open, ...)
  p$report <- file
  report_stage_flags(p, "reporting")
  invisible(p)
}

group_summary <- function(p, keep) {
  th <- mirt::fscores(p$model, method = "EAP", full.scores.SE = TRUE, verbose = FALSE)
  g <- as.character(p$data$group)
  rows <- lapply(keep, function(lv) {
    i <- which(g == lv)
    data.frame(group = lv, n = length(i), mean_theta = mean(th[i, 1]),
               sd_theta = stats::sd(th[i, 1]), mean_se = mean(th[i, 2]),
               stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

groups_html <- function(groups, p) {
  h <- htmltools::tags
  htmltools::tagList(
    h$p(sprintf(paste("Ability estimates (EAP) by group, with the average standard error.",
                      "Groups with fewer than %d respondents are left out."),
                p$rules$min_group_n)),
    html_table(groups))
}

decisions_html <- function(p) {
  h <- htmltools::tags
  st <- data.frame(stage = paste(pipeline_stages$number, pipeline_stages$label),
                   status = p$stages$status, summary = p$stages$summary,
                   stringsAsFactors = FALSE)
  f <- as.data.frame(flags(p, status = "all"))
  open <- f[f$status == "open", , drop = FALSE]
  intro <- sprintf(paste("Every stage ran its checks and raised flags for review.",
                         "%s %d flag(s) were raised; %d are still open and %d were",
                         "acknowledged, overridden or fixed."),
                   if (p$strict) "The pipeline ran in strict mode, so open review and block flags stopped later stages until a decision was recorded."
                   else "Flags only warned (strict = FALSE).",
                   nrow(f), nrow(open), nrow(f) - nrow(open))
  rt <- rules_table(p$rules)
  rt$changed <- ifelse(rt$changed, "changed", "default")
  htmltools::tagList(
    h$p(intro),
    h$h3("Stages"), html_table(st),
    h$h3("Flags"),
    if (nrow(f)) html_table(f[, c("id", "level", "stage", "check", "target", "value", "rule",
                                  "status", "note", "advice")], status_col = "level")
    else h$p("No flags were raised."),
    h$h3("Decision log"),
    html_table(p$log),
    if (nrow(p$persons)) list(
      h$h3("Respondents flagged"),
      h$p("Counts only; the respondents are listed in p$persons in R."),
      html_table(as.data.frame(table(check = p$persons$check), responseName = "respondents"))),
    h$h3("Rules in effect"),
    h$p(sprintf("Preset: %s; %d rule(s) changed by the user.", attr(p$rules, "preset"),
                sum(rt$changed == "changed"))),
    h$details(h$summary("Show all rules"), html_table(rt)))
}

linking_html <- function(p) {
  h <- htmltools::tags
  l <- p$link
  tab <- as.data.frame(l$anchors)
  tab$drift <- ifelse(abs(tab$displacement) > p$rules$anchor_displacement, "drift", "")
  htmltools::tagList(
    h$p(sprintf(paste("The calibration was put on the scale of the item bank \"%s\" by the %s",
                      "method through %d anchor items. Ability on the bank scale = %.3f x ability",
                      "+ %.3f."), l$bank, l$method, nrow(tab), l$A, l$B)),
    h$p(sprintf(paste("Displacement is the anchor's location after linking minus its bank",
                      "location; values beyond %s logits are marked as drift."),
                p$rules$anchor_displacement)),
    html_table(tab[, c("item", "bank_b", "new_b", "linked_b", "displacement", "drift")]),
    if (!is.null(p$bank)) h$p(sprintf("The bank now holds %d items.", nrow(p$bank$items))))
}

forms_html <- function(p) {
  h <- htmltools::tags
  fm <- p$forms
  if (fm$method == "ata") {
    per <- stats::aggregate(item ~ form, data = as.data.frame(fm$items),
                            FUN = function(x) paste(x, collapse = ", "))
    names(per) <- c("form", "items")
    return(htmltools::tagList(
      h$p(sprintf(paste("%d fixed form(s) were assembled by automated test assembly to be",
                        "most informative at ability %s."), length(unique(fm$items$form)),
                  paste(fm$theta, collapse = ", "))),
      html_table(per),
      h$h3("Information and precision"),
      html_table(as.data.frame(fm$info))))
  }
  s <- fm$summary
  if (fm$method == "cat") {
    ex <- as.data.frame(fm$exposure)
    ex <- utils::head(ex[order(-ex$exposure), , drop = FALSE], 10L)
    return(htmltools::tagList(
      h$p(sprintf(paste("A computerized adaptive test was simulated for %d simulees (stop at SE",
                        "%s or %d items). On average a test had %.1f items; the mean standard",
                        "error was %.2f, the bias %+.3f and the RMSE %.3f. %.0f%% of the bank",
                        "was never used."), s$n, fm$design$min_SEM, fm$design$max_items,
                  s$mean_items, s$mean_se, s$bias, s$rmse, 100 * s$unused)),
      h$h3("Most exposed items"), html_table(ex)))
  }
  per <- stats::aggregate(item ~ module, data = as.data.frame(fm$modules),
                          FUN = function(x) paste(x, collapse = ", "))
  htmltools::tagList(
    h$p(sprintf(paste("A two-stage multistage test was assembled: a routing module and %d",
                      "second-stage modules targeted at ability %s, with routing cuts at %s. In",
                      "a simulation of %d simulees, %.0f%% were routed to a different module",
                      "than their true ability calls for; the mean standard error was %.2f and",
                      "the bias %+.3f."),
                length(fm$targets), paste(round(fm$targets, 2), collapse = ", "),
                paste(round(fm$cuts, 2), collapse = ", "), s$n, 100 * s$misrouted,
                s$mean_se, s$bias)),
    html_table(per))
}

cuts_html <- function(p) {
  h <- htmltools::tags
  cu <- p$cuts
  s <- cu$summary
  tab <- as.data.frame(cu$table)
  if (!is.null(cu$panel_sd)) tab$panel_sd <- cu$panel_sd
  htmltools::tagList(
    h$p(sprintf(paste("%d cut score(s) on the %s scale divide test takers into %s. Decision",
                      "quality was estimated by the method of %s for %s, over %s abilities:",
                      "classification accuracy %.3f, consistency %.3f (kappa %.2f)."),
                nrow(tab), if (cu$scale == "raw") "summed-score" else "ability",
                paste(cu$labels, collapse = ", "), cu$method,
                if (is.null(cu$form)) "the calibrated test" else paste("form", cu$form),
                format(cu$n_theta, big.mark = ","), s$accuracy, s$consistency, s$kappa)),
    h$h3("Cuts"), html_table(tab),
    h$h3("Decision quality by cut"), html_table(as.data.frame(cu$by_cut)),
    h$h3("Expected share in each category"), html_table(as.data.frame(cu$categories)))
}

blueprint_html <- function(p) {
  h <- htmltools::tags
  b <- p$blueprint
  htmltools::tagList(
    h$p(sprintf("Construct: %s. Test takers: %s. Score use: %s. Forms have %d items (%s); target reliability %s%s.",
                b$construct %||% "not stated", b$population %||% "not stated",
                b$use %||% "not stated", b$length,
                paste(c(mc = "multiple choice", open = "open-ended")[b$item_types], collapse = " and "),
                b$reliability,
                if (!is.null(b$grade_level)) sprintf(", reading grade %s", b$grade_level) else "")),
    html_table(as.data.frame(b$cells)[, c("content", "cognitive", "n")]))
}

items_html <- function(p) {
  h <- htmltools::tags
  it <- p$items
  tab <- as.data.frame(table(cell = it$cell, type = it$type, status = it$status),
                       responseName = "items")
  tab <- tab[tab$items > 0, , drop = FALSE]
  src <- as.data.frame(table(source = it$source), responseName = "items")
  htmltools::tagList(
    h$p(sprintf(paste("The item pool holds %d items. Multiple-choice keys were checked by an",
                      "independent answer for %d items; %d disagreed with the key."),
                nrow(it), sum(!is.na(it$key_check)),
                sum(it$key_check == "disagree", na.rm = TRUE))),
    html_table(tab), h$h3("Item sources"), html_table(src),
    if (!is.null(p$reviews)) {
      ag <- p$review_agreement
      list(h$h3("Review"),
           h$p(sprintf(paste("%d reviews from %d reviewers. On the %d items with two or more",
                             "reviews, the reviewers' decisions agreed %s of the time (Fleiss'",
                             "kappa %s)."),
                       nrow(p$reviews), length(unique(p$reviews$reviewer)), ag$items,
                       if (is.na(ag$agreement)) "n/a" else sprintf("%.0f%%", 100 * ag$agreement),
                       if (is.na(ag$kappa)) "n/a" else sprintf("%.2f", ag$kappa))))
    })
}

field_test_html <- function(p) {
  h <- htmltools::tags
  ft <- p$field_test
  rec <- ft$recovery
  htmltools::tagList(
    h$p(sprintf(paste("The field test uses %d form(s) of %s items, each taken by %s test takers,",
                      "with %d anchor items on every form, for calibration with the %s model."),
                ft$n_forms, paste(unique(ft$form_length), collapse = "/"),
                format(ft$n_per_form, big.mark = ","), length(ft$anchors), ft$model)),
    if (!is.null(rec))
      h$p(sprintf(paste("In %d simulated field tests the slopes were recovered with an RMSE of",
                        "%s and the intercepts with an RMSE of %.2f."), rec$reps,
                  if (is.na(rec$rmse_a)) "n/a (Rasch)" else sprintf("%.2f", rec$rmse_a),
                  rec$rmse_d)),
    html_table(as.data.frame(stats::aggregate(item ~ form + role, data = as.data.frame(ft$forms),
                                              FUN = length))))
}

scoring_html <- function(p) {
  h <- htmltools::tags
  htmltools::tagList(
    if (!is.null(p$open_scores)) {
      a <- as.data.frame(p$agreement)
      list(h$p(sprintf(paste("%d open-ended responses were scored by %s. Agreement with human",
                             "scores (quadratic weighted kappa, QWK) and the standardized mean",
                             "difference (SMD) between machine and human scores, by item:"),
                       nrow(p$open_scores), p$scoring$method)),
           html_table(a))
    },
    if (!is.null(p$scores)) {
      s <- p$scores
      list(h$p(sprintf(paste("Test takers were scored by %s: mean ability %.2f (SD %.2f),",
                             "median standard error %.2f."), p$score_method,
                       mean(s$theta[is.finite(s$theta)]), stats::sd(s$theta[is.finite(s$theta)]),
                       stats::median(s$se[is.finite(s$se)]))))
    })
}

security_html <- function(p) {
  h <- htmltools::tags
  sec <- p$security
  pers <- sec$persons
  counts <- if (nrow(pers)) as.data.frame(table(check = pers$check), responseName = "test_takers")
  htmltools::tagList(
    h$p(sprintf(paste("Security checks run: %s. Security flags are evidence for an",
                      "investigation, not proof of misconduct; individual test takers are not",
                      "named in this report."),
                paste(gsub("_", " ", sec$checks), collapse = ", "))),
    if (!is.null(counts)) html_table(counts) else h$p("No test taker showed evidence."),
    if (!is.null(sec$drift)) list(h$h3("Parameter drift"),
                                  html_table(as.data.frame(sec$drift))),
    if (!is.null(sec$leakage)) {
      lk <- as.data.frame(sec$leakage)
      lk <- lk[order(-lk$p_change), , drop = FALSE]
      list(h$h3("Change in the latest window"), html_table(utils::head(lk, 10L)))
    })
}

monitoring_html <- function(p) {
  h <- htmltools::tags
  m <- p$monitoring
  it <- m$items
  wins <- as.data.frame(m$windows)
  wins$date <- format(wins$date)
  wins$reliability <- round(wins$reliability, 3)
  st <- table(factor(it$status, levels = c("active", "review", "retired")))
  top <- it[it$status == "active" & !is.na(it$latest_exposure), , drop = FALSE]
  top <- utils::head(top[order(-top$latest_exposure), c("item", "content", "windows_used",
                                                         "latest_exposure")], 10L)
  top$latest_exposure <- round(top$latest_exposure, 3)
  htmltools::tagList(
    h$p(sprintf("%s: %d items (%d active, %d in review, %d retired).", p$bank$name, nrow(it),
                st[["active"]], st[["review"]], st[["retired"]])),
    if (nrow(wins)) list(h$h3("Administrations"), html_table(wins)),
    if (!is.null(m$cells)) list(h$h3("Active items per content cell"),
                                html_table(as.data.frame(m$cells))),
    if (nrow(top)) list(h$h3("Most exposed items in the latest window"),
                        html_table(as.data.frame(top))))
}
