# Pipeline stage: calibration

Fits a unidimensional IRT model to the responses in a pipeline and
checks whether the items are fit to enter an item bank. The checks
(thresholds from
[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)):

## Usage

``` r
calibrate(p, model = "auto", dif = NULL, reference = NULL, ...)
```

## Arguments

- p:

  a pipeline with responses from
  [`add_responses()`](https://www.okanbulut.com/mirtverse/reference/add_responses.md).

- model:

  the item type passed to
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html),
  such as `"Rasch"`, `"2PL"`, `"3PL"`, `"graded"` or `"gpcm"`, or
  `"auto"` to let
  [`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md)
  choose.

- dif:

  logical; test for DIF. Defaults to `TRUE` when the pipeline has a
  grouping variable.

- reference:

  the reference group for DIF. Defaults to the largest group.

- ...:

  further arguments passed to
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html).

## Value

The pipeline with the fitted model (`p$model`), the DIF results
(`p$dif`) and the calibration flags added.

## Details

- `not_converged` (block): the estimation did not converge.

- `model_fit` (review): M2-based RMSEA above `rmsea` or CFI below `cfi`,
  which suggests more than one dimension or a poorly fitting model.

- `local_dependence` (review): pairs of items whose absolute Q3 residual
  correlation exceeds `q3`.

- `item_misfit` (review): S-X2 item fit p-value below `fit_alpha` after
  `fit_adjust` adjustment.

- `parameter_range` (review): discrimination outside `a_min` to `a_max`,
  an absolute difficulty above `b_max`, or a guessing parameter above
  `c_max`.

- `dif_large` (block) and `dif_moderate` (review): differential item
  functioning between the groups given to
  [`add_responses()`](https://www.okanbulut.com/mirtverse/reference/add_responses.md),
  classified with the ETS A/B/C rules. 0/1 items use the Mantel-Haenszel
  D-DIF statistic (category C: \|D-DIF\| at least `dif_c` and a
  significant Mantel-Haenszel test; B: at least `dif_b` and
  significant). Polytomous items use the standardized mean difference
  divided by the item's standard deviation with the Mantel test
  (`dif_poly_c`, `dif_poly_b`). Respondents are matched on their total
  score; with more than two groups each group is compared with the
  reference group.

- `low_reliability` (review): marginal reliability below `reliability`.

- `person_misfit` (info): the share of respondents whose Zh (lz)
  person-fit statistic is below `person_misfit`; they are listed in
  `p$persons`.

## Examples

``` r
# \donttest{
p <- add_responses(mv_pipeline(), certexam, items = 3:34, key = certexam_key,
                   group = "language")
p <- calibrate(p, model = "3PL")
#> Warning: Calibration is running with 1 block open flag(s) from earlier stages:
#>   #1 [block] possible_miskey: Q14 (p = 0.18, item-total r = -0.23)
#> Flags only warn because strict = FALSE. See flags(p).
flags(p, stage = "calibration")
#> # A tibble: 7 × 10
#>      id stage       check           target value rule  level advice status note 
#>   <int> <chr>       <chr>           <chr>  <chr> <chr> <chr> <chr>  <chr>  <chr>
#> 1     2 calibration not_converged   test   not … esti… block Try a… open   ""   
#> 2     6 calibration dif_large       Q09    MH D… ETS … block Have … open   ""   
#> 3     3 calibration local_dependen… Q21 &… Q3 =… |Q3|… revi… The i… open   ""   
#> 4     4 calibration parameter_range Q14    a = … a in… revi… Extre… open   ""   
#> 5     5 calibration parameter_range Q21    c = … a in… revi… Extre… open   ""   
#> 6     7 calibration dif_moderate    Q27    MH D… ETS … revi… Revie… open   ""   
#> 7     8 calibration person_misfit   26 re… 2.2%… Zh <… info  About… open   ""   
# }
```
