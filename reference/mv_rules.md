# Thresholds for the pipeline checks

Every check that
[`mv_pipeline()`](https://www.okanbulut.com/mirtverse/reference/mv_pipeline.md)
runs compares a statistic with a threshold from this list. The defaults
follow common practice in operational testing (the *Standards for
Educational and Psychological Testing*, the ETS classification of
differential item functioning); change any of them by name.

## Usage

``` r
mv_rules(..., preset = c("standards", "lenient"))
```

## Arguments

- ...:

  rules to change, by name, e.g. `q3 = 0.25`.

- preset:

  starting values: `"standards"` (the defaults above) or `"lenient"`.

## Value

A list of class `mv_rules`.

## Details

|  |  |  |
|----|----|----|
| Rule | Default | Check |
| `miskey_p` | 0.10 | proportion correct below this suggests a miskeyed item |
| `miskey_r` | 0 | corrected item-total correlation below this suggests a miskey |
| `missing_item` | 0.20 | share of missing responses on an item |
| `missing_person` | 0.50 | share of items a respondent skipped |
| `straight_min_items` | 5 | minimum test length for straight-lining checks |
| `rapid_rt` | 0.10 | response time below this share of the item's median is a rapid guess |
| `rapid_person` | 0.10 | share of rapid guesses that flags a respondent |
| `min_category_n` | 10 | responses needed in each score category |
| `rmsea` | 0.06 | maximum M2-based RMSEA |
| `cfi` | 0.95 | minimum M2-based CFI |
| `q3` | 0.20 | maximum absolute Q3 residual correlation between two items |
| `fit_alpha` | 0.01 | significance level for S-X2 item misfit |
| `fit_adjust` | `"BH"` | p-value adjustment for item misfit ([`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html)) |
| `a_min`, `a_max` | 0.3, 4 | acceptable range of discrimination (slope) |
| `b_max` | 4 | largest acceptable absolute difficulty (location) |
| `c_max` | 0.35 | largest acceptable lower asymptote (guessing) |
| `dif_alpha` | 0.05 | significance level of the Mantel-Haenszel test |
| `dif_b`, `dif_c` | 1, 1.5 | absolute MH D-DIF for ETS categories B and C (0/1 items) |
| `dif_poly_b`, `dif_poly_c` | 0.17, 0.25 | absolute SMD/SD for categories B and C (polytomous items) |
| `reliability` | 0.80 | minimum marginal reliability |
| `person_misfit` | -1.96 | Zh (lz) person-fit value below which a respondent misfits |
| `min_anchors` | 5 | fewest anchor items for linking to a bank |
| `min_anchor_share` | 0.20 | smallest share of the test that should be anchors |
| `anchor_displacement` | 0.3 | largest change in an anchor's location (logits) after linking |
| `link_slope_min`, `link_slope_max` | 0.8, 1.2 | acceptable range of the linking slope A |
| `min_group_n` | 10 | smallest group summarized in a report |

`preset = "lenient"` relaxes the rules for pilot studies and small
samples (`rmsea = 0.08`, `cfi = 0.90`, `q3 = 0.30`, `a_min = 0.2`,
`reliability = 0.70`, `missing_item = 0.30`); values given by name are
applied on top of the preset.

## Examples

``` r
mv_rules()
#> <mv_rules> preset: standards
#>   miskey_p            0.1
#>   miskey_r            0
#>   missing_item        0.2
#>   missing_person      0.5
#>   straight_min_items  5
#>   rapid_rt            0.1
#>   rapid_person        0.1
#>   min_category_n      10
#>   rmsea               0.06
#>   cfi                 0.95
#>   q3                  0.2
#>   fit_alpha           0.01
#>   fit_adjust          BH
#>   a_min               0.3
#>   a_max               4
#>   b_max               4
#>   c_max               0.35
#>   dif_alpha           0.05
#>   dif_b               1
#>   dif_c               1.5
#>   dif_poly_b          0.17
#>   dif_poly_c          0.25
#>   reliability         0.8
#>   person_misfit       -1.96
#>   min_anchors         5
#>   min_anchor_share    0.2
#>   anchor_displacement 0.3
#>   link_slope_min      0.8
#>   link_slope_max      1.2
#>   min_group_n         10
mv_rules(q3 = 0.25, reliability = 0.85)
#> <mv_rules> preset: standards; changed: q3, reliability
#>   miskey_p            0.1
#>   miskey_r            0
#>   missing_item        0.2
#>   missing_person      0.5
#>   straight_min_items  5
#>   rapid_rt            0.1
#>   rapid_person        0.1
#>   min_category_n      10
#>   rmsea               0.06
#>   cfi                 0.95
#>   q3                  0.25
#>   fit_alpha           0.01
#>   fit_adjust          BH
#>   a_min               0.3
#>   a_max               4
#>   b_max               4
#>   c_max               0.35
#>   dif_alpha           0.05
#>   dif_b               1
#>   dif_c               1.5
#>   dif_poly_b          0.17
#>   dif_poly_c          0.25
#>   reliability         0.85
#>   person_misfit       -1.96
#>   min_anchors         5
#>   min_anchor_share    0.2
#>   anchor_displacement 0.3
#>   link_slope_min      0.8
#>   link_slope_max      1.2
#>   min_group_n         10
mv_rules(preset = "lenient")
#> <mv_rules> preset: lenient
#>   miskey_p            0.1
#>   miskey_r            0
#>   missing_item        0.3
#>   missing_person      0.5
#>   straight_min_items  5
#>   rapid_rt            0.1
#>   rapid_person        0.1
#>   min_category_n      10
#>   rmsea               0.08
#>   cfi                 0.9
#>   q3                  0.3
#>   fit_alpha           0.01
#>   fit_adjust          BH
#>   a_min               0.2
#>   a_max               4
#>   b_max               4
#>   c_max               0.35
#>   dif_alpha           0.05
#>   dif_b               1
#>   dif_c               1.5
#>   dif_poly_b          0.17
#>   dif_poly_c          0.25
#>   reliability         0.7
#>   person_misfit       -1.96
#>   min_anchors         5
#>   min_anchor_share    0.2
#>   anchor_displacement 0.3
#>   link_slope_min      0.8
#>   link_slope_max      1.2
#>   min_group_n         10
```
