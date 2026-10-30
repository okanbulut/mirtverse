# Pipeline stage: link a calibration to an item bank

Puts a calibrated pipeline on the scale of an existing item bank through
the anchor items the two have in common, then checks the anchors.
Methods:

## Usage

``` r
link_to_bank(
  p,
  bank,
  method = c("stocking-lord", "haebara", "mean-sigma", "mean-mean", "fixed"),
  anchors = NULL,
  ...
)
```

## Arguments

- p:

  a calibrated pipeline from
  [`calibrate()`](https://www.okanbulut.com/mirtverse/reference/calibrate.md).

- bank:

  an item bank from
  [`mv_bank()`](https://www.okanbulut.com/mirtverse/reference/mv_bank.md)
  or
  [`bank_items()`](https://www.okanbulut.com/mirtverse/reference/bank_items.md).

- method:

  linking method; see above.

- anchors:

  anchor items to use. Defaults to every active bank item that is also
  in the pipeline with the same item type.

- ...:

  further arguments passed to
  [`mirt::mirt()`](https://philchalmers.github.io/mirt/reference/mirt.html)
  for `"fixed"`.

## Value

The pipeline with `p$link` (a list with `method`, `A`, `B` and
`anchors`, a tibble of the anchors' bank and linked locations and their
displacement) and the linking flags added. With `"fixed"`, `p$model` is
replaced by the fixed-anchor model.

## Details

- `"stocking-lord"` (default) and `"haebara"`: characteristic-curve
  methods. They find the slope `A` and intercept `B` of the change of
  scale (theta on the bank scale = `A` x theta + `B`) that make the
  anchors' test characteristic curve (Stocking-Lord) or item curves
  (Haebara) match the bank's, weighted by a standard normal ability
  distribution.

- `"mean-sigma"` and `"mean-mean"`: moment methods based on the anchors'
  locations (and discriminations).

- `"fixed"`: fixed-anchor calibration. The model is refitted with the
  anchor parameters fixed at their bank values and the ability mean and
  variance free, so every new item lands on the bank scale directly.

For the Rasch model the slope is fixed at 1. The checks (thresholds from
[`mv_rules()`](https://www.okanbulut.com/mirtverse/reference/mv_rules.md)):

- `too_few_anchors` (review): fewer than `min_anchors` anchor items, or
  fewer than `min_anchor_share` of the test.

- `anchor_drift` (review): an anchor whose location on the bank scale
  differs from its bank value by more than `anchor_displacement`.
  Drifting anchors can be left out with the `anchors` argument.

- `linking_constants` (review): a slope `A` outside `link_slope_min` to
  `link_slope_max`, which suggests a very different ability spread or
  unstable anchors.

- `not_converged` (block): the fixed-anchor calibration did not
  converge.

The constants and the anchor table are kept in `p$link` and shown in the
report.

## Examples

``` r
# \donttest{
set.seed(1)
a <- matrix(rlnorm(40, 0.2, 0.2)); d <- matrix(rnorm(40))
form_x <- simdata(a[1:25, , drop = FALSE], d[1:25, , drop = FALSE], 1500,
                  itemtype = "2PL")
form_y <- simdata(a[16:40, , drop = FALSE], d[16:40, , drop = FALSE], 1500,
                  itemtype = "2PL", Theta = matrix(rnorm(1500, 0.5, 1.2)))
colnames(form_x) <- sprintf("I%02d", 1:25)
colnames(form_y) <- sprintf("I%02d", 16:40)
px <- calibrate(add_responses(mv_pipeline("Form X"), form_x), model = "2PL")
bank <- bank_items(px)$bank
py <- calibrate(add_responses(mv_pipeline("Form Y"), form_y), model = "2PL")
py <- link_to_bank(py, bank)
py$link$A; py$link$B
#> [1] 1.209101
#> [1] 0.4655744
py <- bank_items(py, bank)
# }
```
