# Draft a validity argument for an AI component

Drafts the interpretation-and-use argument (Kane, 2013) for test scores
that an AI component helps produce, organized by the four inferences of
the argument-based approach: **Scoring** (the scores follow the rubric),
**generalization** (they would be the same on another occasion, form or
engine version), **extrapolation** (they reflect the construct, equally
for all groups) and **decision** (the decisions made with them are
appropriate). For each inference it states the claim, the threats an AI
component adds, the evidence from an
[`ai_audit()`](https://www.okanbulut.com/mirtverse/reference/ai_audit.md)
and a status.

## Usage

``` r
validity_argument(
  audit = NULL,
  construct = "the construct",
  use = "the intended use",
  population = "the test takers",
  component = "automated scoring of constructed responses"
)

# S3 method for class 'mv_validity'
format(x, type = c("html", "markdown"), ...)
```

## Arguments

- audit:

  an
  [`ai_audit()`](https://www.okanbulut.com/mirtverse/reference/ai_audit.md)
  result, or `NULL` for an argument with no evidence yet.

- construct:

  what the test measures, e.g. `"Grade 8 science"`.

- use:

  the intended use of the scores, e.g. `"school accountability"`.

- population:

  the test takers.

- component:

  what the AI component does, e.g.
  `"automated scoring of constructed responses"`.

- x:

  an `mv_validity` object.

- type:

  `"html"` or `"markdown"`.

- ...:

  not used.

## Value

A tibble of class `mv_validity` with one row per inference: `inference`,
`claim`, `threats`, `evidence`, `status` (`"supported"`,
`"partly supported"`, `"threatened"` or `"needs evidence"`) and `todo`.
It has [`print()`](https://rdrr.io/r/base/print.html) and
[`format()`](https://rdrr.io/r/base/format.html) methods
(`format(x, "html")` or `format(x, "markdown")`).

## Details

The draft is a starting point, not a verdict: It shows which claims the
audit supports, which it calls into question, and which no audit can
settle (such as human oversight, disclosure to test takers and appeals),
so that the evidence still owed is explicit. Add it to an HTML report
with
`mv_report(model, extra = list("Validity argument" = format(va, "html")))`
or simply `extra = list("Validity argument" = va)`.

## References

Kane, M. T. (2013). Validating the interpretations and uses of test
scores. *Journal of Educational Measurement, 50*(1), 1-73.

American Educational Research Association, American Psychological
Association, & National Council on Measurement in Education. (2014).
*Standards for educational and psychological testing.* AERA.

## See also

[`ai_audit()`](https://www.okanbulut.com/mirtverse/reference/ai_audit.md),
[`mv_report()`](https://www.okanbulut.com/mirtverse/reference/mv_report.md).

## Examples

``` r
cr <- aiscored_cr[aiscored_cr$year == 2026, ]
audit <- ai_audit(cr, human2 = "human2", group = "group", item = "item")
va <- validity_argument(audit, construct = "Grade 8 science",
                        use = "school accountability",
                        population = "Grade 8 students")
va
#> Validity argument: Grade 8 science scores for school accountability
#> AI component: automated scoring of constructed responses
#> 
#> Scoring [THREATENED]
#>   Claim: Scores from automated scoring of constructed responses follow
#>     the scoring rubric as trained human raters apply it.
#>   Threats: The engine rewards surface features (length, vocabulary,
#>     spelling) rather than the ideas in the rubric; human scores used to
#>     train or check it are unreliable.
#>   Evidence: Human agreement: 4 tested, flagged CR4 [human QWK 0.63].
#>     Machine agreement: 4 tested, flagged CR4 [QWK 0.66, human QWK
#>     0.63]. Overall bias: 4 tested, flagged CR3 [SMD +0.29].
#>   To do: Resolve the flags, then rerun the audit before the scores are
#>     used.
#> 
#> Generalization [NEEDS EVIDENCE]
#>   Claim: Scores would be the same on another occasion, form, rater or
#>     engine version, so they mean the same across administrations.
#>   Threats: An engine update, a new prompt or a change in the population
#>     shifts machine scores; agreement holds in one year only.
#>   Evidence: None yet.
#>   To do: Check drift across administrations and engine versions with
#>     ai_audit(period = ).
#> 
#> Extrapolation [THREATENED]
#>   Claim: Scores reflect Grade 8 science, and do so equally for all
#>     groups of Grade 8 students.
#>   Threats: Features unrelated to the construct, such as language
#>     proficiency, lower machine scores for some groups; DIF on AI-scored
#>     items.
#>   Evidence: Subgroup agreement: 8 tested, flagged CR3, ELL [QWK 0.68];
#>     CR4, Fluent [QWK 0.67]; CR4, ELL [QWK 0.60]. Differential scoring:
#>     4 tested, flagged CR2, ELL [gap -0.23 SD, SE 0.07].
#>   To do: Resolve the flags, then rerun the audit before the scores are
#>     used. Not checked yet: DIF.
#> 
#> Decision [NEEDS EVIDENCE]
#>   Claim: Using the scores for school accountability is appropriate,
#>     with the human oversight, disclosure and appeals the use requires.
#>   Threats: Machine scores are used without human review where stakes
#>     are high; test takers are not told how they were scored; errors
#>     cannot be appealed.
#>   Evidence: None yet.
#>   To do: Document human review of flagged and low-confidence responses,
#>     disclosure to test takers, and an appeals process. No audit can
#>     supply this evidence.
#> 
cat(format(va, "markdown"))
#> The argument for using Grade 8 science scores for school accountability, with automated scoring of constructed responses, by the four inferences of the argument-based approach (Kane, 2013).
#> 
#> ### Scoring (threatened)
#> 
#> - **Claim:** Scores from automated scoring of constructed responses follow the scoring rubric as trained human raters apply it.
#> - **Threats:** The engine rewards surface features (length, vocabulary, spelling) rather than the ideas in the rubric; human scores used to train or check it are unreliable.
#> - **Evidence:** Human agreement: 4 tested, flagged CR4 [human QWK 0.63]. Machine agreement: 4 tested, flagged CR4 [QWK 0.66, human QWK 0.63]. Overall bias: 4 tested, flagged CR3 [SMD +0.29].
#> - **To do:** Resolve the flags, then rerun the audit before the scores are used.
#> 
#> ### Generalization (needs evidence)
#> 
#> - **Claim:** Scores would be the same on another occasion, form, rater or engine version, so they mean the same across administrations.
#> - **Threats:** An engine update, a new prompt or a change in the population shifts machine scores; agreement holds in one year only.
#> - **Evidence:** None yet.
#> - **To do:** Check drift across administrations and engine versions with ai_audit(period = ).
#> 
#> ### Extrapolation (threatened)
#> 
#> - **Claim:** Scores reflect Grade 8 science, and do so equally for all groups of Grade 8 students.
#> - **Threats:** Features unrelated to the construct, such as language proficiency, lower machine scores for some groups; DIF on AI-scored items.
#> - **Evidence:** Subgroup agreement: 8 tested, flagged CR3, ELL [QWK 0.68]; CR4, Fluent [QWK 0.67]; CR4, ELL [QWK 0.60]. Differential scoring: 4 tested, flagged CR2, ELL [gap -0.23 SD, SE 0.07].
#> - **To do:** Resolve the flags, then rerun the audit before the scores are used. Not checked yet: DIF.
#> 
#> ### Decision (needs evidence)
#> 
#> - **Claim:** Using the scores for school accountability is appropriate, with the human oversight, disclosure and appeals the use requires.
#> - **Threats:** Machine scores are used without human review where stakes are high; test takers are not told how they were scored; errors cannot be appealed.
#> - **Evidence:** None yet.
#> - **To do:** Document human review of flagged and low-confidence responses, disclosure to test takers, and an appeals process. No audit can supply this evidence.
```
