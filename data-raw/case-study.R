# Runs the certification case study (vignettes/articles/case-study.Rmd)
# through the assessment pipeline and writes its technical report to
# pkgdown/assets/case-study/. The PDF is printed from the HTML by
# data-raw/case-study-pdf.js. Run from the package root:
#   Rscript data-raw/case-study.R && node data-raw/case-study-pdf.js
library(mirtverse)
options(mirtverse.dry_run = TRUE)

p <- mv_pipeline("Certification exam: Form A field test")
p <- set_blueprint(p, c(Ethics = 4, Practice = 5, Law = 3),
                   construct = "Professional knowledge for certification",
                   use = "pass/fail certification", reliability = 0.85)
p <- design_field_test(p, n_forms = 2, n_per_form = 600, items = 32,
                       reps = 2, seed = 1)
p <- acknowledge(p, check = "recovery",
                 note = "Sample fixed by the testing window")
p <- add_responses(p, certexam, items = 3:34, key = certexam_key,
                   id = "id", group = "language")
p <- drop_items(p, "Q14", note = "Key confirmed wrong by the item writer")
p <- calibrate(p, model = "2PL")
p <- acknowledge(p, check = "local_dependence",
                 note = "Q21 and Q22 share a case; keep them apart on forms")
p <- override(p, check = "dif_large",
              note = "Translation reviewed; French version revised")
p <- acknowledge(p, check = "dif_moderate", note = "Sent to the bias panel")
p <- acknowledge(p, check = "low_reliability",
                 note = "Operational forms will be longer than the field test")
p <- bank_items(p, name = "Certification bank")
content <- setNames(rep(c("Ethics", "Practice", "Law"), c(10, 12, 10)),
                    sprintf("Q%02d", 1:32))
# Form assembly needs the eatATA package; the report skips that stage
# when it is not installed.
if (requireNamespace("eatATA", quietly = TRUE))
  p <- assemble_forms(p, length = 12, n_forms = 2, theta = c(-1, 0, 1),
                      content = content[names(content) != "Q14"],
                      blueprint = c(Ethics = 4, Practice = 5, Law = 3),
                      enemies = list(c("Q21", "Q22")))
p <- set_cuts(p, cuts = 18, scale = "raw", labels = c("Fail", "Pass"))
p <- score_persons(p)
p <- acknowledge(p, check = "cut_precision",
                 note = "Add items near the cut to the operational forms")
p <- acknowledge(p, check = "score_reliability",
                 note = "Field-test scores are not reported to candidates")
p <- check_security(p, leaked = c("Q01", "Q02", "Q03", "Q04", "Q05"))

pipeline_report(p, file = "pkgdown/assets/case-study/certification-technical-report.html",
                title = "Certification exam, Form A: Technical report",
                author = "Psychometrics team (fictional example)", open = FALSE)
dir.create("data-raw/home", showWarnings = FALSE)
saveRDS(list(flags = flags(p, status = "all"), cuts = p$cuts$summary,
             forms = p$forms$info, n = nrow(p$data)),
        "data-raw/home/case-study-summary.rds")
