# Plot knowledge tracing results

**Experimental.** Three views of a model from
[`mv_kt_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kt_fit.md):

## Usage

``` r
gg_kt(
  kt,
  student = NULL,
  skills = NULL,
  type = c("curve", "graph"),
  kg = NULL,
  max_attempts = 20
)
```

## Arguments

- kt:

  an `mv_kt` object from
  [`mv_kt_fit()`](https://www.okanbulut.com/mirtverse/reference/mv_kt_fit.md).

- student:

  optional student id.

- skills:

  optional skills to show (curves only).

- type:

  `"curve"` (the default) or `"graph"`.

- kg:

  the knowledge graph for `type = "graph"`; by default the graph the
  model was fitted with.

- max_attempts:

  for learning curves, the last attempt number shown.

## Value

A ggplot object.

## Details

- `type = "curve"` with no `student`: Learning curves, the mean
  probability of knowing each skill and the proportion of correct
  answers at each attempt number.

- `type = "curve"` with a `student`: That student's probability of
  knowing each skill after every attempt, with the answers as points
  (filled = correct).

- `type = "graph"`: The knowledge graph with each concept shaded by the
  probability of knowing it after the last attempt, for one student or
  on average over all students.

## Examples

``` r
kt <- mv_kt_fit(fractions_logs, kg = fractions_kg)
gg_kt(kt)

gg_kt(kt, student = "P001")

gg_kt(kt, student = "P001", type = "graph")
```
