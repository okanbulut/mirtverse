# Numeracy items with their text, for the AI Hub

The text and field-test statistics of 192 simulated Grade 7 numeracy
multiple-choice items, written from 12 item models (families) of 16
items each, such as unit rates, percents, elapsed time and simple
equations. Within a family the items differ in their numbers, names and
contexts, so the data show how far surface features move item
difficulty. The items were calibrated with the 2PL on a simulated field
test of 1,500 test takers.

## Usage

``` r
itemtext
```

## Format

A data frame with 192 rows (one per item) and 17 columns: `id` (`N01-01`
to `N12-16`: Family and item number), `family` (the item model),
`domain` (content area), `stem` (the question), `A` to `D` (the
options), `key` (the keyed option), `decimal` (1 if the item uses
decimals or fractions), `digits` (digits in the largest number),
`context` (1 if the stem starts with a context sentence), `a` and `b`
(2PL discrimination and difficulty from the field test), `a_se` and
`b_se` (their standard errors) and `p_field` (share correct in the field
test).

## Source

Simulated; the script is `data-raw/itemtext.R` in the package's GitHub
repository.

## Details

The dataset is for learning to predict item difficulty from item text
and to calibrate item families from automatic item generation. Some
problems were planted on purpose; `lab_truth("itemtext")` lists them and
the true item parameters. Some families repeat a stem with different
options (for example "Which number is the greatest?"); the extra context
sentences are deliberately unrelated to the question, to add reading
load.

## See also

[essays](https://www.okanbulut.com/mirtverse/reference/essays.md) and
[aigfield](https://www.okanbulut.com/mirtverse/reference/aigfield.md),
the other AI Hub datasets; the [AI
Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.html).

## Examples

``` r
head(itemtext[, c("id", "family", "stem", "key", "b")])
#>       id    family
#> 1 N01-01 Unit rate
#> 2 N01-02 Unit rate
#> 3 N01-03 Unit rate
#> 4 N01-04 Unit rate
#> 5 N01-05 Unit rate
#> 6 N01-06 Unit rate
#>                                                                                                           stem
#> 1                                             A pack of 6 pencils costs $30.00. How much does one pencil cost?
#> 2  Maya is buying supplies for a school trip. A pack of 8 pencils costs $56.00. How much does one pencil cost?
#> 3      Sofia is saving money for a new bike. A pack of 10 pencils costs $30.00. How much does one pencil cost?
#> 4                                             A pack of 5 pencils costs $45.00. How much does one pencil cost?
#> 5                                            A pack of 10 pencils costs $50.00. How much does one pencil cost?
#> 6 Noah is buying supplies for a school trip. A pack of 10 pencils costs $40.00. How much does one pencil cost?
#>   key     b
#> 1   D -0.12
#> 2   A -0.24
#> 3   A -0.35
#> 4   C -0.45
#> 5   D -0.12
#> 6   C -0.32
# family means of difficulty
sort(tapply(itemtext$b, itemtext$family, mean))
#>    Converting units                Mean Area of a rectangle           Unit rate 
#>           -0.744375           -0.689375           -0.555000           -0.145625 
#>       Average speed Percent of a number        Elapsed time         Probability 
#>            0.162500            0.337500            0.389375            0.458750 
#>               Ratio    Adding fractions  Comparing decimals   Solving equations 
#>            0.620000            0.872500            1.110625            1.149375 
# surface features and difficulty
summary(lm(b ~ family + decimal + digits + context, data = itemtext))
#> 
#> Call:
#> lm(formula = b ~ family + decimal + digits + context, data = itemtext)
#> 
#> Residuals:
#>     Min      1Q  Median      3Q     Max 
#> -4.0926 -0.1181  0.0341  0.2148  0.6928 
#> 
#> Coefficients:
#>                           Estimate Std. Error t value Pr(>|t|)    
#> (Intercept)                0.49881    0.32271   1.546  0.12396    
#> familyArea of a rectangle -1.24944    0.20783  -6.012 1.02e-08 ***
#> familyAverage speed       -0.57767    0.21476  -2.690  0.00783 ** 
#> familyComparing decimals   0.20363    0.30116   0.676  0.49982    
#> familyConverting units    -1.48723    0.22033  -6.750 2.04e-10 ***
#> familyElapsed time        -0.21620    0.25036  -0.864  0.38901    
#> familyMean                -1.27347    0.23400  -5.442 1.73e-07 ***
#> familyPercent of a number -0.26404    0.24311  -1.086  0.27892    
#> familyProbability         -0.39455    0.19830  -1.990  0.04817 *  
#> familyRatio                0.03591    0.23400   0.153  0.87821    
#> familySolving equations    0.56528    0.23400   2.416  0.01672 *  
#> familyUnit rate           -0.86241    0.21035  -4.100 6.29e-05 ***
#> decimal                    0.27995    0.13756   2.035  0.04334 *  
#> digits                     0.02148    0.11710   0.183  0.85467    
#> context                    0.13542    0.08267   1.638  0.10316    
#> ---
#> Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
#> 
#> Residual standard error: 0.5356 on 177 degrees of freedom
#> Multiple R-squared:  0.6096, Adjusted R-squared:  0.5788 
#> F-statistic: 19.74 on 14 and 177 DF,  p-value: < 2.2e-16
#> 
```
