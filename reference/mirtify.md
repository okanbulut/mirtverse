# Translate ltm, eRm, TAM and irtQ code into mirt code

`mirtify()` reads R code written for the ltm, eRm, TAM or irtQ packages
and writes the equivalent mirt code. It parses the code without running
it, so the original package does not have to be installed. Model calls
(for example [`ltm::rasch()`](https://rdrr.io/pkg/ltm/man/rasch.html),
[`eRm::RM()`](https://rdrr.io/pkg/eRm/man/RM.html),
[`TAM::tam.mml()`](https://rdrr.io/pkg/TAM/man/tam.mml.html) and
[`irtQ::est_irt()`](https://hwangQ.github.io/irtQ/reference/est_irt.html))
become
[`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html)
calls with the same model, and follow-up calls on the fitted object
(person scores, item fit, person fit, information, plots, Andersen's
likelihood-ratio test and so on) become their mirt or mirtverse
equivalents.

## Usage

``` r
mirtify(code, run = FALSE, notes = TRUE, file = NULL, envir = parent.frame())
```

## Arguments

- code:

  the code to translate. One of: a character string or vector of code
  lines, the path to an `.R` file, or the unquoted code itself (a single
  call, or several statements wrapped in
  [`{ }`](https://rdrr.io/r/base/Paren.html)).

- run:

  logical; if `TRUE`, run the translated code and keep the objects it
  creates in the `env` element of the result.

- notes:

  logical; include the notes as comments in the translated script.

- file:

  optional path of an `.R` file to write the translated script to.

- envir:

  environment in which data objects are looked up (to count items and
  categories) and in which `run = TRUE` evaluates the code.

## Value

An object of class `mv_mirtify` with elements `script` (the translated
code as a single string), `steps` (a tibble with one row per statement:
`original`, `mirt`, `package`, `status` and `notes`) and, when
`run = TRUE`, `env`. Use
[`as.character()`](https://rdrr.io/r/base/character.html) to get the
script and [`print()`](https://rdrr.io/r/base/print.html) to show it.

## Details

Each translated statement comes with notes on what differs between the
two packages, such as conditional versus marginal maximum likelihood in
eRm, the scaling constant `D` in irtQ, or the number of quadrature
points. Statements that do not involve these packages are kept as they
are. Statements with no mirt equivalent are kept as comments and
explained in the notes.

Translation follows the defaults of ltm 1.2-0, eRm 1.0-10, TAM 4.3 and
irtQ 1.3.
[`mirtify_crosswalk()`](https://www.okanbulut.com/mirtverse/reference/mirtify_crosswalk.md)
lists every function that `mirtify()` knows.

## See also

[`mirtify_crosswalk()`](https://www.okanbulut.com/mirtverse/reference/mirtify_crosswalk.md)
for the table of supported functions.

## Examples

``` r
mirtify("library(ltm)
         fit <- rasch(LSAT)
         summary(fit)
         factor.scores(fit)")
#> mirtify: 4 of 4 statements translated from ltm
#> 
#> # mirtverse loads mirt, so one library() call covers both.
#> library(mirtverse)
#> # ltm::rasch() estimates one common discrimination for all items; the
#> # CONSTRAIN line does the same in mirt.
#> # ltm integrates over 21 Gauss-Hermite points and mirt over 61 points, so
#> # estimates can differ slightly (usually in the second or third decimal).
#> fit_model <- mirt.model(sprintf("F = 1-%1$d
#>                                  CONSTRAIN = (1-%1$d, a1)", ncol(LSAT)))
#> fit <- mirt(LSAT, fit_model, itemtype = "2PL", SE = TRUE)
#> # tidy() lists every parameter with its standard error, on the IRT scale.
#> tidy(fit)
#> # ltm's empirical Bayes scores are the posterior modes, which mirt calls MAP.
#> # Like ltm, full.scores = FALSE returns one row per observed response
#> # pattern; drop it to get one score per person.
#> fscores(fit, method = "MAP", full.scores = FALSE)

# Unquoted code works too
mirtify({
  library(eRm)
  fit <- RM(raschdat1)
  pp <- person.parameter(fit)
  itemfit(pp)
  LRtest(fit)
})
#> mirtify: 5 of 5 statements translated from eRm
#> 
#> # mirtverse loads mirt, so one library() call covers both.
#> library(mirtverse)
#> # eRm uses conditional maximum likelihood (CML); mirt uses marginal maximum
#> # likelihood with a normal latent trait, so estimates are close but not
#> # identical.
#> # eRm reports item easiness (beta = -difficulty) centred to sum to zero;
#> # coef() and summary() below convert mirt's difficulties to the same form.
#> fit <- mirt(raschdat1, 1, itemtype = "Rasch", SE = TRUE)
#> # eRm's person parameters are maximum likelihood estimates. For all-correct
#> # or all-wrong patterns mirt returns -Inf or Inf where eRm extrapolates;
#> # method = "WLE" gives finite values for everyone.
#> pp <- fscores(fit, method = "ML", full.scores.SE = TRUE)
#> # mirt's infit and outfit mean squares use EAP person estimates while eRm
#> # uses ML estimates, so values differ a little.
#> itemfit(fit, fit_stats = "infit")
#> # Andersen's test compares item parameters across score groups. Here the same
#> # comparison is a likelihood-ratio test between a model with equal item
#> # parameters in both groups and one with separate parameters. It uses
#> # marginal rather than conditional likelihood, so the statistic differs from
#> # eRm's.
#> fit_score <- rowSums(raschdat1, na.rm = TRUE)
#> fit_split <- ifelse(fit_score > median(fit_score), "high", "low")
#> fit_free <- multipleGroup(raschdat1, 1, group = fit_split,
#>                           itemtype = "Rasch")
#> fit_equal <- multipleGroup(raschdat1, 1, group = fit_split,
#>                            itemtype = "Rasch",
#>                            invariance = c("slopes", "intercepts", "free_means", "free_var"))
#> anova(fit_equal, fit_free)

mirtify("mod <- irtQ::est_irt(data = resp, D = 1.702, model = '3PLM')")
#> mirtify: 1 of 1 statements translated from irtQ
#> 
#> library(mirtverse)
#> # irtQ puts a Beta(5, 16) prior on the guessing parameters by default; the
#> # PRIOR line does the same in mirt.
#> # With guessing parameters the likelihood can have more than one peak, so
#> # mirt and irtQ can stop at slightly different estimates. Compare the
#> # log-likelihoods if the estimates differ.
#> # quadpts and theta_lim use irtQ's quadrature (49 points from -6 to 6).
#> # irtQ multiplies the slopes by D = 1.702; mirt does not. mirt's slopes equal
#> # irtQ's times 1.702, and coef() and summary() below rescale them.
#> mod_model <- mirt.model(sprintf("F = 1-%1$d
#>                                  PRIOR = (1-%1$d, g, expbeta, 5, 16)", ncol(resp)))
#> mod <- mirt(resp, mod_model, itemtype = "3PL", quadpts = 49,
#>             theta_lim = c(-6, 6), SE = TRUE)
```
