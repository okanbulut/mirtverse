# Moving from ltm, eRm, TAM or irtQ to mirt

Many people learn item response theory with one package and later want
to move to another. If your scripts were written for **ltm**, **eRm**,
**TAM** or **irtQ**,
[`mirtify()`](https://www.okanbulut.com/mirtverse/reference/mirtify.md)
rewrites them as **mirt** code. It reads the code without running it, so
the original package does not even need to be installed, and it explains
every place where the two packages differ.

``` r

library(mirtverse)
#> Loading required package: mirt
#> Loading required package: stats4
#> Loading required package: lattice
LSAT <- expand.table(LSAT6)   # the LSAT data used in the ltm examples
```

## A first translation

Give
[`mirtify()`](https://www.okanbulut.com/mirtverse/reference/mirtify.md)
your code as a string, as the path to an `.R` file, or unquoted inside
[`{ }`](https://rdrr.io/r/base/Paren.html):

``` r

mirtify({
  library(ltm)
  fit <- rasch(LSAT)
  summary(fit)
  factor.scores(fit)
  item.fit(fit)
})
#> mirtify: 5 of 5 statements translated from ltm
#> 
#> # mirtverse loads mirt, so one library() call covers both.
#> library(mirtverse)
#> # ltm::rasch() estimates one common discrimination for all items; the
#> # CONSTRAIN line does the same in mirt.
#> # ltm integrates over 21 Gauss-Hermite points and mirt over 61 points, so
#> # estimates can differ slightly (usually in the second or third decimal).
#> fit_model <- mirt.model("F = 1-5
#>                          CONSTRAIN = (1-5, a1)")
#> fit <- mirt(LSAT, fit_model, itemtype = "2PL", SE = TRUE)
#> # tidy() lists every parameter with its standard error, on the IRT scale.
#> tidy(fit)
#> # ltm's empirical Bayes scores are the posterior modes, which mirt calls MAP.
#> # Like ltm, full.scores = FALSE returns one row per observed response
#> # pattern; drop it to get one score per person.
#> fscores(fit, method = "MAP", full.scores = FALSE)
#> # Both use Yen's Q1-type chi-square with 10 ability groups, but the groups
#> # are formed differently, so the statistics differ a little. fit_stats =
#> # "S_X2" is usually preferred in mirt.
#> itemfit(fit, fit_stats = "X2")
```

Three things happen:

- **Model calls become
  [`mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html)
  calls with the same model.**
  [`ltm::rasch()`](https://rdrr.io/pkg/ltm/man/rasch.html) estimates one
  common discrimination for all items, so the translation adds a
  `CONSTRAIN` line rather than using mirt’s `itemtype = "Rasch"` (which
  fixes the slopes at 1 and frees the latent variance instead).
- **Follow-up calls on the fitted object are translated too.**
  [`mirtify()`](https://www.okanbulut.com/mirtverse/reference/mirtify.md)
  remembers that `fit` came from
  [`rasch()`](https://rdrr.io/pkg/ltm/man/rasch.html), so
  `factor.scores(fit)` becomes
  [`fscores()`](https://philchalmers.github.io/mirt/reference/fscores.html)
  with the matching method (ltm’s empirical Bayes scores are posterior
  modes, which mirt calls MAP).
- **Each difference gets a note**, written as a comment above the line.
  Turn them off with `notes = FALSE`.

Code that does not involve these packages is left as it is. Calls that
have no mirt equivalent are kept as comments, with a note on what to use
instead.

## Running the translation

`run = TRUE` also runs the translated code and keeps what it creates in
`$env`, so you can check the results straight away:

``` r

res <- mirtify("fit <- ltm::rasch(LSAT)", run = TRUE)
coef(res$env$fit, IRTpars = TRUE, simplify = TRUE)$items
#>                a         b g u
#> Item_1 0.7554128 -3.614579 0 1
#> Item_2 0.7554128 -1.322108 0 1
#> Item_3 0.7554128 -0.317661 0 1
#> Item_4 0.7554128 -1.729674 0 1
#> Item_5 0.7554128 -2.779569 0 1
```

Use `file = "analysis-mirt.R"` to save the script, or
[`as.character()`](https://rdrr.io/r/base/character.html) to get it as a
string.

## eRm: conditional and marginal likelihood

eRm estimates Rasch models by conditional maximum likelihood (CML),
while mirt uses marginal maximum likelihood (MML) with a normal latent
trait. For the Rasch family the two give very similar item estimates.
eRm reports item *easiness* (minus the difficulty) centred to sum to
zero, so translated [`coef()`](https://rdrr.io/r/stats/coef.html) and
[`summary()`](https://rdrr.io/r/base/summary.html) calls convert mirt’s
difficulties to the same form.

``` r

mirtify({
  library(eRm)
  fit <- RM(raschdat1)
  coef(fit)
  pp <- person.parameter(fit)
  itemfit(pp)
  LRtest(fit)
  plotPImap(fit)
})
#> mirtify: 7 of 7 statements translated from eRm
#> 
#> # mirtverse loads mirt, so one library() call covers both.
#> library(mirtverse)
#> # eRm uses conditional maximum likelihood (CML); mirt uses marginal maximum
#> # likelihood with a normal latent trait, so estimates are close but not
#> # identical.
#> # eRm reports item easiness (beta = -difficulty) centred to sum to zero;
#> # coef() and summary() below convert mirt's difficulties to the same form.
#> fit <- mirt(raschdat1, 1, itemtype = "Rasch", SE = TRUE)
#> # eRm's item easiness is minus the difficulty, centred to sum to zero.
#> fit_b <- coef(fit, IRTpars = TRUE, simplify = TRUE)$items[, "b"]
#> -(fit_b - mean(fit_b))
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
#> # gg_wright() draws the person-item map with ggplot2.
#> gg_wright(fit)
```

Andersen’s likelihood-ratio test
([`LRtest()`](https://rdrr.io/pkg/eRm/man/LRtest.html)) becomes the same
comparison in mirt: a model with equal item parameters in the low and
high score groups against one with separate parameters. On `raschdat1`
eRm gives LR = 32.5 with 29 df (p = .30) and the translation gives 32.8
with 29 df (p = .29).

## TAM: Q matrices, groups and latent regression

`tam.mml()` and `tam.mml.2pl()` translate with their most used
arguments: a Q matrix becomes a
[`mirt.model()`](https://philchalmers.github.io/mirt/reference/mirt.model.html)
with correlated dimensions, `group` becomes
[`multipleGroup()`](https://philchalmers.github.io/mirt/reference/multipleGroup.html)
with equal item parameters and free group means and variances, `Y`
becomes mirt’s latent regression (`covdata` and `formula`), and
`pweights` becomes `survey.weights`.

``` r

mirtify("library(TAM)
         mod <- tam.mml(resp, Q = Q)
         mod2 <- tam.mml.2pl(resp, group = school)
         wle <- tam.wle(mod)
         wle$WLE.rel
         tam.modelfit(mod)
         IRT.compareModels(mod, mod2)")
#> mirtify: 7 of 7 statements translated from TAM
#> 
#> # mirtverse loads mirt, so one library() call covers both.
#> library(mirtverse)
#> # Like TAM, itemtype = "Rasch" fixes the slopes at 1, sets the latent mean to
#> # 0 and estimates the latent variance.
#> # mirt.model() builds the same between-item structure from TAM's Q matrix,
#> # with correlated dimensions.
#> # TAM integrates over 21 nodes from -6 to 6 and mirt over 61 points, so
#> # estimates can differ slightly.
#> mod_model <- mirt.model(Q, COV = upper.tri(diag(ncol(Q))))
#> mod <- mirt(resp, mod_model, itemtype = "Rasch", SE = TRUE)
#> # For polytomous items use itemtype = "gpcm", which is what TAM fits for
#> # them.
#> # As in TAM, the latent variance is fixed at 1 and every item has its own
#> # slope.
#> # With group, TAM keeps item parameters equal across groups and estimates a
#> # mean and variance for each group; multipleGroup() with this invariance does
#> # the same.
#> mod2 <- multipleGroup(resp, 1, group = school, itemtype = "2PL",
#>                       SE = TRUE,
#>                       invariance = c("slopes", "intercepts", "free_means", "free_var"))
#> # Warm's weighted likelihood estimates, as in tam.wle().
#> wle <- fscores(mod, method = "WLE", full.scores.SE = TRUE)
#> empirical_rxx(wle)
#> # M2() gives the overall fit test with RMSEA and SRMSR. For TAM's Q3
#> # statistics use residuals(mod, type = "Q3") or gg_q3(mod).
#> M2(mod)
#> # anova() compares nested mirt models with AIC, BIC and a likelihood-ratio
#> # test.
#> anova(mod, mod2)
```

## irtQ: the scaling constant D and priors

irtQ often uses `D = 1.702`, which multiplies every slope. mirt has no
`D`, so its slopes equal irtQ’s times 1.702. The translated
[`summary()`](https://rdrr.io/r/base/summary.html) and
[`coef()`](https://rdrr.io/r/stats/coef.html) calls divide them back.
The translation also keeps irtQ’s defaults that mirt does not share: 49
quadrature points from -6 to 6, one shared slope for `1PLM` items, and a
Beta(5, 16) prior on the guessing parameters.

``` r

mirtify("library(irtQ)
         mod <- est_irt(data = resp, D = 1.702,
                        model = c('1PLM', '1PLM', '3PLM', '3PLM', 'GRM'),
                        cats = c(2, 2, 2, 2, 4))
         summary(mod)
         est_score(mod, method = 'WL')
         sx2_fit(mod)")
#> mirtify: 5 of 5 statements translated from irtQ
#> 
#> # mirtverse loads mirt, so one library() call covers both.
#> library(mirtverse)
#> # irtQ's 1PLM items share one estimated slope; the CONSTRAIN line does the
#> # same in mirt.
#> # irtQ puts a Beta(5, 16) prior on the guessing parameters by default; the
#> # PRIOR line does the same in mirt.
#> # With guessing parameters the likelihood can have more than one peak, so
#> # mirt and irtQ can stop at slightly different estimates. Compare the
#> # log-likelihoods if the estimates differ.
#> # quadpts and theta_lim use irtQ's quadrature (49 points from -6 to 6).
#> # irtQ multiplies the slopes by D = 1.702; mirt does not. mirt's slopes equal
#> # irtQ's times 1.702, and coef() and summary() below rescale them.
#> mod_model <- mirt.model("F = 1-5
#>                          CONSTRAIN = (1-2, a1)
#>                          PRIOR = (3-4, g, expbeta, 5, 16)")
#> mod <- mirt(resp, mod_model,
#>             itemtype = c(rep("2PL", 2), rep("3PL", 2), "graded"),
#>             quadpts = 49, theta_lim = c(-6, 6), SE = TRUE)
#> mod_pars <- coef(mod, IRTpars = TRUE, simplify = TRUE)$items
#> mod_pars[, "a"] <- mod_pars[, "a"] / 1.702  # irtQ's slopes include D = 1.702
#> mod_pars
#> fscores(mod, method = "WLE", full.scores.SE = TRUE)
#> # Orlando and Thissen's S-X2, as in irtQ.
#> itemfit(mod, fit_stats = "S_X2")
```

## How close are the results?

The package tests fit each model with the original package and with the
translated mirt code, then compare the estimates. These are the largest
absolute differences:

| Original call | Compared | Largest difference |
|----|----|----|
| `ltm::rasch(LSAT)` | difficulties, common slope | 0.001 |
| `ltm::ltm(LSAT ~ z1)` | difficulties, slopes | 0.001 |
| `ltm::grm(Science)` | thresholds, slopes | 0.006 |
| `ltm::gpcm(Science, constraint = "rasch")` | thresholds | 0.001 |
| `eRm::RM(raschdat1)` | item easiness (CML vs MML) | 0.005 |
| `TAM::tam.mml(data.sim.rasch)` | difficulties, variance | 0.001 |
| `TAM::tam.mml.2pl(data.sim.rasch)` | slopes, intercepts | 0.003 |
| `TAM::tam.mml(Science)` (partial credit) | log-likelihood | identical |
| `irtQ::est_irt(model = "1PLM"/"2PLM")` | slopes, difficulties | 0.006 |

The small differences come from the number of quadrature points (ltm
uses 21 and TAM 21, mirt 61) and from convergence tolerances. Two cases
differ more, and the notes say so:

- **Polytomous Rasch models in eRm**
  ([`PCM()`](https://rdrr.io/pkg/eRm/man/PCM.html)): eRm centres the
  item parameters and mirt centres the persons, so compare thresholds
  after subtracting their mean.
- **3PL models with a guessing prior in irtQ**: the likelihood can have
  more than one peak, so the two packages may stop at slightly different
  estimates. Compare the log-likelihoods if the estimates differ.

## What is not translated

A few functions have no direct mirt counterpart.
[`mirtify()`](https://www.okanbulut.com/mirtverse/reference/mirtify.md)
keeps them as comments and says what to use instead: eRm’s
repeated-measures models
([`LRSM()`](https://rdrr.io/pkg/eRm/man/LRSM.html),
[`LPCM()`](https://rdrr.io/pkg/eRm/man/LPCM.html)) and nonparametric
tests ([`NPtest()`](https://rdrr.io/pkg/eRm/man/NPtest.html)), irtQ’s
fixed-ability calibration (`est_item()`) and its list-based
multiple-group function (`est_mg()`), and ltm’s modified parallel
analysis ([`unidimTest()`](https://rdrr.io/pkg/ltm/man/unidimTest.html),
translated to
[`M2()`](https://philchalmers.github.io/mirt/reference/M2.html) as a fit
check). Arguments such as TAM’s design matrices (`A`, `B`, `xsi.fixed`)
are flagged in the notes and the statement is marked as translated with
caveats.

## The crosswalk

[`mirtify_crosswalk()`](https://www.okanbulut.com/mirtverse/reference/mirtify_crosswalk.md)
lists every function
[`mirtify()`](https://www.okanbulut.com/mirtverse/reference/mirtify.md)
knows:

``` r

knitr::kable(mirtify_crosswalk())
```

| package | function | mirt | notes |
|:---|:---|:---|:---|
| ltm | rasch() | mirt(data, model, itemtype = “2PL”) with CONSTRAIN = (1-J, a1) | Common discrimination; a constraint fixing it at 1 becomes START and FIXED lines. |
| ltm | ltm() | mirt(data, nfact, itemtype = “2PL”) | Interaction and quadratic terms become (F1*F2) and (F*F) model lines. |
| ltm | tpm() | mirt(data, 1, itemtype = “3PL”) | max.guessing is not translated. |
| ltm | grm() | mirt(data, 1, itemtype = “graded”) | constrained = TRUE adds an equal-slopes constraint. |
| ltm | gpcm() | mirt(data, 1, itemtype = “gpcm”) | “1PL” adds equal slopes, “rasch” fixes them at 1. |
| ltm | factor.scores() | fscores(fit, method = “MAP”, full.scores = FALSE) | ltm’s empirical Bayes scores are posterior modes (MAP). |
| ltm | item.fit() | itemfit(fit, fit_stats = “X2”) | Grouping details differ. |
| ltm | person.fit() | personfit(fit) | ltm’s Lz is mirt’s Zh. |
| ltm | information() | areainfo(fit, theta_lim) |  |
| ltm | descript() | itemstats(data) |  |
| ltm | margins() | residuals(fit, type = “LD”) |  |
| ltm | unidimTest() | M2(fit), residuals(fit, type = “Q3”) | No parallel analysis in mirt. |
| ltm | plot() | gg_trace(fit), gg_info(fit) | type = “IIC” maps to gg_info(). |
| eRm | RM(), PCM() | mirt(data, 1, itemtype = “Rasch”) | CML in eRm, MML in mirt; easiness = -difficulty, centred. |
| eRm | RSM() | mirt(data, 1, itemtype = “rsm”) |  |
| eRm | LLTM() | mirt(data, 1, itemtype = “Rasch”, itemdesign, item.formula) | Basic parameters have the opposite sign. |
| eRm | person.parameter() | fscores(fit, method = “ML”) | Extreme scores give -Inf/Inf in mirt. |
| eRm | itemfit() | itemfit(fit, fit_stats = “infit”) | Infit and outfit mean squares. |
| eRm | personfit() | personfit(fit) |  |
| eRm | LRtest() | anova() of two multipleGroup() models | Score-group split, marginal rather than conditional likelihood. |
| eRm | Waldtest() | dif(data, group, model = “Rasch”) | Per-item likelihood-ratio tests. |
| eRm | plotPImap() | gg_wright(fit) |  |
| eRm | plotICC(), plotjointICC() | gg_trace(fit) |  |
| eRm | thresholds() | coef(fit, IRTpars = TRUE, simplify = TRUE)\$items \| \| \|eRm \|IC() \|glance(fit) \|Marginal log-likelihood only. \| \|eRm \|LRSM(), LPCM(), NPtest() \|not translated \|See mirt::mixedmirt(). \| \|TAM \|tam.mml() \|mirt(data, 1, itemtype = "Rasch") \|RSM maps to "rsm"; Q matrix, group, Y and pweights are translated. \| \|TAM \|tam.mml.2pl() \|mirt(data, 1, itemtype = "2PL" or "gpcm") \|Slope groups are not translated. \| \|TAM \|tam.mml.3pl() \|mirt(data, 1, itemtype = "3PL") \|Only with est.guess. \| \|TAM \|tam.wle() \|fscores(fit, method = "WLE") \| \| \|TAM \|IRT.factor.scores() \|fscores(fit, method = ...) \| \| \|TAM \|tam.fit() \|itemfit(fit, fit_stats = "infit") \|Per item rather than per parameter. \| \|TAM \|tam.modelfit() \|M2(fit), residuals(fit, type = "Q3") \| \| \|TAM \|tam.personfit() \|personfit(fit) \| \| \|TAM \|IRT.compareModels() \|anova(fit1, fit2) \| \| \|TAM \|fit\$xsi, fit\$EAP.rel \|tidy(fit), empirical_rxx(fscores(...)) \| \| \|irtQ \|est_irt() \|mirt(data, model, itemtype, quadpts = 49, theta_lim = c(-6, 6)) \|1PLM equal slopes, guessing prior and D = 1.702 rescaling are handled. \| \|irtQ \|est_score() \|fscores(fit, method = ...) \|INV.TCC maps to EAPsum. \| \|irtQ \|sx2_fit() \|itemfit(fit, fit_stats = "S_X2") \| \| \|irtQ \|irtfit() \|itemfit(fit, fit_stats = "X2") \| \| \|irtQ \|info() \|testinfo(fit, Theta) \| \| \|irtQ \|traceline() \|probtrace(fit, Theta) \| \| \|irtQ \|getirt(), fit\$par.est | coef(fit, IRTpars = TRUE, simplify = TRUE) |
| irtQ | est_item(), est_mg() | not translated | See technical = list(fixedTheta) and multipleGroup(). |
