# Gallery

Each figure below is made by the code above it, with data that ships
with mirt or mirtverse. Every plot is a ggplot2 object, so you can
change its theme, labels and colours with ordinary ggplot2 code.

``` r

library(mirtverse)
data <- expand.table(LSAT7)
mod <- mirt(data, 1, itemtype = "2PL", verbose = FALSE)
```

## Outputs to share

These run in a browser with nothing installed.

| Output | Made with | Example |
|----|----|----|
| Interactive results dashboard | [`mv_dashboard()`](https://www.okanbulut.com/mirtverse/reference/mv_dashboard.md), [`export_dashboard()`](https://www.okanbulut.com/mirtverse/reference/export_dashboard.md) | [Open the live dashboard](https://www.okanbulut.com/mirtverse/dashboard/sat12-demo.md) |
| Printable cheat sheet | Two pages, by task | [PDF](https://www.okanbulut.com/mirtverse/cheatsheet/mirtverse-cheatsheet.pdf) |
| Interactive teaching labs | [`run_lab()`](https://www.okanbulut.com/mirtverse/reference/run_lab.md) | [Teaching labs](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md) |
| Online book | Worked examples and exercises | [Read the book](https://www.okanbulut.com/mirtverse/book/index.md) |

[![The dashboard’s summary
panel.](../dashboard/summary.png)](https://www.okanbulut.com/mirtverse/dashboard/sat12-demo.md)

## Choosing a model

[`select_model()`](https://www.okanbulut.com/mirtverse/reference/select_model.md)
compares candidate models and explains its choice.

``` r

sel <- select_model(data)
autoplot(sel)
```

![](gallery_files/figure-html/select-model-1.png)

## Item curves

``` r

gg_trace(mod)
```

![](gallery_files/figure-html/trace-1.png)

## Test and item information

``` r

gg_info(mod)
```

![](gallery_files/figure-html/info-1.png)

``` r

gg_info(mod, type = "items")
```

![](gallery_files/figure-html/info-items-1.png)

## Wright map

People and items on one scale.

``` r

gg_wright(mod)
```

![](gallery_files/figure-html/wright-1.png)

## Item fit

``` r

gg_itemfit(mod)
```

![](gallery_files/figure-html/itemfit-1.png)

## Observed versus expected

``` r

gg_empirical(mod, item = 3)
```

![](gallery_files/figure-html/empirical-1.png)

## Local dependence

``` r

gg_q3(mod)
```

![](gallery_files/figure-html/q3-1.png)

## Score distribution

``` r

gg_scores(mod)
```

![](gallery_files/figure-html/scores-1.png)

## Item health card

A one-page summary of a single item for review meetings, with a
traffic-light status.

``` r

sci <- mirt(Science, 1, verbose = FALSE)
item_card(sci, "Work")
```

![](gallery_files/figure-html/item-card-1.png)

## Differential item functioning

``` r

set.seed(1)
a <- matrix(rlnorm(8, 0.2, 0.3)); d <- matrix(rnorm(8))
d2 <- d; d2[1] <- d2[1] - 1
dif_data <- rbind(simdata(a, d, 400, itemtype = "2PL"),
                  simdata(a, d2, 400, itemtype = "2PL"))
res <- dif(dif_data, group = rep(c("F", "M"), each = 400))
gg_dif(res)
```

![](gallery_files/figure-html/dif-1.png)

## Response times

``` r

sim <- sim_rt(N = 500, J = 10, rapid = 0.05, seed = 1)
rt_mod <- mirt(sim$responses, 1, verbose = FALSE)
fit <- fit_rt(rt_mod, sim$rt)
autoplot(fit)
```

![](gallery_files/figure-html/rt-1.png)

## Teaching labs

The labs run in RStudio’s viewer or a browser. See [Teaching
labs](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md) for
all ten.

![A decision screen from Lab 2.](figures/lab-decisions.png)

A decision screen from Lab 2.
