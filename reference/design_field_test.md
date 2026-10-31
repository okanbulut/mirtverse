# Pipeline stage: field-test design

Plans how new items reach test takers before they are calibrated: the
number of forms, the anchor items every form shares (so the forms can be
put on one scale), and the sample size per form. The unique items are
spread over the forms in turn by blueprint cell, so each form covers the
blueprint. A simulation then shows how well the item parameters would be
recovered under the plan: responses are simulated from plausible item
parameters
([`mirt::simdata()`](https://philchalmers.github.io/mirt/reference/simdata.html)),
the items a form does not include are set to missing, the model is
fitted, and the estimates are compared with the true values.

## Usage

``` r
design_field_test(
  p,
  n_forms,
  n_per_form,
  items = NULL,
  anchors = NULL,
  model = c("2PL", "Rasch", "3PL", "graded"),
  reps = 10,
  seed = NULL
)
```

## Arguments

- p:

  a pipeline.

- n_forms:

  number of field-test forms.

- n_per_form:

  number of test takers who take each form.

- items:

  the items to field-test: by default the approved items in the pipeline
  (or every item not rejected, if none has been reviewed); or a
  character vector of item ids; or a number of items, for planning
  before items exist.

- anchors:

  optional anchor item ids. By default the fewest items that make up
  `min_anchor_share` of a form, taken in turn from each blueprint cell.

- model:

  the model the items will be calibrated with: `"2PL"`, `"Rasch"`,
  `"3PL"` or `"graded"` (polytomous items use the graded model in any
  case).

- reps:

  number of simulated field tests (0 skips the simulation).

- seed:

  optional random seed.

## Value

The pipeline with `p$field_test`: `forms` (a tibble with one row per
form and item, and its role), `items` (respondents per item), `recovery`
(average RMSE of slopes and intercepts over the replications) and the
settings.

## Details

The checks (thresholds from
[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)):

- `sample_size` (review): items answered by fewer than `n_rasch`,
  `n_2pl` or `n_3pl` respondents, depending on the model (polytomous
  items count as needing `n_3pl`).

- `anchor_share` (review): the anchors make up less than
  `min_anchor_share` of a form.

- `anchor_coverage` (review): a blueprint cell with no anchor item, so
  the link between forms does not represent it.

- `recovery` (review): the average RMSE of the simulated slopes (or of
  the intercepts, for the Rasch model) is above `recovery_rmse`.

## Examples

``` r
# \donttest{
p <- design_field_test(mv_pipeline(verbose = FALSE), n_forms = 3, n_per_form = 300,
                       items = 60, reps = 2, seed = 1)
p$field_test$items
#> # A tibble: 60 × 4
#>    item  forms     n role  
#>    <chr> <int> <dbl> <chr> 
#>  1 I001      3   900 anchor
#>  2 I002      3   900 anchor
#>  3 I003      3   900 anchor
#>  4 I004      3   900 anchor
#>  5 I005      3   900 anchor
#>  6 I006      1   300 unique
#>  7 I007      1   300 unique
#>  8 I008      1   300 unique
#>  9 I009      1   300 unique
#> 10 I010      1   300 unique
#> # ℹ 50 more rows
flags(p)
#> # A tibble: 2 × 10
#>      id stage      check       target      value rule  level advice status note 
#>   <int> <chr>      <chr>       <chr>       <chr> <chr> <chr> <chr>  <chr>  <chr>
#> 1     1 field_test sample_size 55 unique … n = … at l… revi… Add t… open   ""   
#> 2     2 field_test recovery    design      RMSE… RMSE… revi… Param… open   ""   
# }
```
