# Short science explanations scored by raters, for the AI Hub

1,600 simulated written answers of 400 Grade 8 students (100 of them
English language learners, ELL) to four science prompts, each scored 0
to 4 by trained raters. A response's true score is the number of the
prompt's four key ideas it states correctly. The prompts are E1 (why ice
floats), E2 (why Earth has seasons), E3 (how plants make food) and E4
(why a metal spoon feels colder than a wooden one).

## Usage

``` r
essays
```

## Format

A data frame with 1,600 rows (one per response) and 8 columns: `id`
(response ID), `student` (student ID), `prompt` (`E1` to `E4`), `group`
(factor, `Fluent` or `ELL`), `response` (the text), `words` (number of
words), `human1` (first rater's score, 0 to 4) and `human2` (second
rater's score, `NA` when the response was read once).

## Source

Simulated; the script is `data-raw/essays.R` in the package's GitHub
repository.

## Details

The dataset is for learning automated scoring: training a scorer on the
text, checking machine-human agreement, and checking that the scorer is
fair to ELL students. Some problems were planted on purpose;
`lab_truth("essays")` lists them and the true scores. Every response has
one human score (`human1`); 40% were scored again (`human2`) so that
human-human agreement can be compared with machine-human agreement.

## See also

[itemtext](https://www.okanbulut.com/mirtverse/reference/itemtext.md)
and
[aigfield](https://www.okanbulut.com/mirtverse/reference/aigfield.md),
the other AI Hub datasets;
[`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md)
to score responses and check them against human scores.

## Examples

``` r
essays$response[1:3]
#> [1] "I learned about this in class last year. This is something that we can see in everyday life. Frozen water has a lower density than the water around it. When water freezes, its molecules line up in an open, hexagonal pattern held by hydrogen bonds. The water pushes up on the ice more than gravity pulls it down, so it floats. In conclusion, this is how it works."
#> [2] "I learned about this in class last year. Earth's axis is tilted about 23.5 degrees. As Earth orbits the Sun, first one hemisphere and then the other leans toward the Sun. Direct rays in summer concentrate the Sun's energy on a smaller area, which heats it more."                                                                                                     
#> [3] "Let me explain what I think is going on here. This is a really interesting question about science. Plants make food by photosynthesis. Carbon dioxide enters through the leaves and water comes up from the roots. The plant grows and makes food. Plants take in oxygen and give off carbon dioxide when they make food. Overall, it is a combination of these things."   
table(essays$prompt, essays$human1)
#>     
#>        0   1   2   3   4
#>   E1  58  99  92  99  52
#>   E2  81  96  97  82  44
#>   E3  35  76 105 103  81
#>   E4  86  90 106  69  49
# human-human agreement on the double-scored responses
with(essays, mean(human1 == human2, na.rm = TRUE))
#> [1] 0.5634675
```
