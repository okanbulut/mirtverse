# Answer key and true values for the lab datasets

Instructor helper: returns how a lab dataset was generated, so you can
check students' conclusions. Students meet the same information in the
reveal at the end of the labs.

## Usage

``` r
lab_truth(
  data = c("certexam", "numeracy", "linking", "catbank", "openended", "itemtext",
    "essays", "aigfield")
)
```

## Arguments

- data:

  the dataset: `"certexam"` (Labs 1 and 2), `"numeracy"` (Lab 3),
  `"linking"` (Lab 4), `"catbank"` (Lab 5), `"openended"` (Lab 6), or
  one of the AI Hub datasets, `"itemtext"`, `"essays"` and `"aigfield"`.

## Value

For `"certexam"`, a list with the true `model`, the correct `key`, the
`miskeyed` item, the `testlet` items, the `dif` items and their type,
the group `impact` (mean ability difference in SD units), the generating
item parameters `pars` and the pass mark `cut_raw`. For `"numeracy"`, a
list with the true `model`, the `dif` items and their type, the
`impact`, the generating item parameters `pars` (with separate values
for ELL students) and `no_dif_long`, long word problems without DIF. For
`"linking"`, a list with the true `model`, the `anchors`, the `drift` of
the drifted anchor, each form's group `ability` mean and SD on the Form
A scale, the generating item parameters `pars` (with `b_formB` for the
anchors' Form B difficulties) and the Form A pass mark `cut_A`. For
`"catbank"`, a list with the five over-used `stars`, the number of items
harder than b = 1.5 (`thin_top`), the student `population` and `notes`.
For `"openended"`, a list with the true `model`, the `severe_rater` and
its severity, the `inconsistent_rater`, the task with a `vague_rubric`,
the categories to `collapse`, the scoring engine's bias against ELL
students (`engine_bias`), the group `impact` and the generating task
parameters `pars`. For `"itemtext"`, a list with the true difficulty `b`
and discrimination `a` of every item, each family's difficulty
(`family_b`), the size of the feature `effects`, the `miskeyed` items
with their listed and correct keys, the `near_duplicates` and the
`leaky` column. For `"essays"`, a list with each response's
`true_score`, each student's ability `theta`, the difficulty of every
key idea (`idea_difficulty`), the raters' error `rater_sd`, the
`off_topic` and `misconception` responses, the `planted` problems and
the `prompts`. For `"aigfield"`, a list with the true difficulty `b` and
discrimination `a` of every item, each item model's difficulty
(`model_b`), the true within-model SD (`sd_within`), which subtraction
items need regrouping (`regroup`) and its effect, the `flawed` items and
the `planted` problems.

## Examples

``` r
lab_truth()$dif
#>           Q09           Q27 
#>     "uniform" "non-uniform" 
lab_truth("numeracy")$dif
#>                     N07                     N18                     N20 
#>               "uniform"               "uniform"               "uniform" 
#>                     N25                     N30                     N02 
#>               "uniform"               "uniform"           "non-uniform" 
#>                     N21                     N03 
#> "uniform (favours ELL)"            "negligible" 
```
