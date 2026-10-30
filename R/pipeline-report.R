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
  if (!is.null(groups)) extra[["Groups"]] <- groups_html(groups, p)
  if (!is.null(p$link)) extra[["Linking"]] <- linking_html(p)
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
