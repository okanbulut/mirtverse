# Interpreting and explaining IRT results

These are common rules of thumb, not laws. Say "by a common rule of thumb"
when you use them, and weigh them against the purpose of the test and the
sample size.

## Model fit

| Statistic | Good | Acceptable | Concern |
|---|---|---|---|
| RMSEA (M2) | < .05 | .05 to .08 | > .08 |
| SRMSR | < .05 | .05 to .08 | > .08 |
| CFI / TLI | > .95 | .90 to .95 | < .90 |

- The M2 p-value is almost always significant in large samples; rely on the
  effect-size indices above.
- Comparing models: Lower AIC/BIC is better. A BIC difference above 10 is
  strong evidence; below 2 the models are practically equivalent, so prefer
  the simpler one.

## Reliability and precision

- Marginal or empirical reliability: .90+ for high-stakes decisions about
  individuals, .80+ for most individual reporting, .70 for group-level or
  low-stakes use.
- The standard error varies with ability. Use the test information or SE
  plot to say where the test measures well (for example "most precise
  around theta = -0.5, near the pass mark") and where it does not.
- Targeting: Compare the mean person location with the mean item location
  (Wright map). A gap of more than about 1 logit means the test is too easy
  or too hard for this group.

## Items

- **Discrimination (a)**: Below 0.5 is weak, 0.5 to 1.0 moderate, 1.0 to 1.7
  good, above 2.5 unusually high (check for local dependence or a
  near-duplicate item).
- **Location (b)**: Items between -2 and 2 are typical. Beyond +/-3 the item
  tells little about most people.
- **Guessing (c, 3PL)**: Near 1/(number of options) is expected; much higher
  suggests a cueing problem.
- **Item-total correlation**: Below .20 is weak; negative suggests a wrong
  key or reversed scoring.
- **Item fit (S-X2)**: A significant p-value with RMSEA above about .05 is
  practical misfit. With many items, adjust p-values (BH) or expect some
  false alarms.
- **Local dependence**: Large residual correlations point to items that share
  a stem, a passage or wording; consider a testlet model or review.

Typical causes to suggest for a flagged item: A miskeyed answer, two
defensible answers, ambiguous wording, content outside the construct, a
clue in the stem, or an item that is far too easy or hard.

## DIF

- The likelihood-ratio test flags statistical DIF. Judge practical size with
  the expected score difference: ESD (signed, focal minus reference;
  positive means the item favours the focal group) and UESD (unsigned, also catches crossing DIF).
- For 0/1 items, |ESD| below about .05 is negligible, .05 to .10 moderate,
  above .10 large (roughly the ETS A/B/C idea in the probability metric).
- DIF is a reason for content review, not proof of bias. Report the
  direction ("harder for the focal group at the same ability") and size.
- Several items favouring the same group can add up at the test level, and
  DIF results depend on the anchor items being DIF-free.

## Explaining to non-specialists

- Lead with the answer: "The test works well overall; three items need a
  look." Then give the evidence.
- Translate terms the first time: theta = ability on the test's scale
  (mean 0, SD 1 in this group); discrimination = how sharply an item
  separates lower from higher scorers; information = measurement precision.
- Give numbers with their meaning: "Reliability is .86, good enough for
  reporting individual scores."
- Offer next steps: Content review of flagged items, refit without them,
  check DIF, or collect more data.
- Be honest about limits: Small samples, convergence warnings, and what the
  analysis cannot show (validity of score use, causes of DIF).
