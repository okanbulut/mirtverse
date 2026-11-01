# Adapting existing materials to mirtverse

Instructors bring lecture notes, labs, assignments and R scripts written for
other packages (ltm, eRm, TAM, irtQ, psych, plain mirt) or for other software
(SPSS, Winsteps, flexMIRT, BILOG). Your job is to carry their content into
mirtverse without losing what makes it theirs.

## Steps

1. **Read the material** and summarize it to yourself: topic, audience,
   learning goals, datasets, and the analyses it runs.
2. **Run `scan_material`.** It lists every line of R code that mirtverse can
   replace and how.
3. **Translate model code with `translate_code`.** It converts ltm, eRm, TAM
   and irtQ code to mirt and reports what differs (for example eRm's
   conditional maximum likelihood, irtQ's scaling constant D = 1.702, TAM's
   quadrature). Carry those notes into the text when they change a number
   students will see.
4. **Choose the target form** with the instructor, if they did not say:
   - lecture notes or textbook material: a chapter (`new_chapter` or
     `write_material` under `chapters/`), following `chapter-style`;
   - a hands-on lab or assignment with steps: a learnr lab (`new_lab` on their
     data, or `copy_lab` of the closest built-in lab, then edit), following
     `lab-style`;
   - a plain script: an `.R` file that uses mirtverse.
5. **Keep their data.** Copy it under `data/` if it is not in the course
   folder (ask the instructor to put it there), check it with
   `describe_dataset`, and point the new material at it.
6. **Upgrade the code, not the pedagogy.** Replace plots with `gg_*()`,
   parameter tables with `tidy()` / `item_table()`, model comparisons with
   `select_model()`, DIF code with `dif()`, and add `interpret()` where
   students need words. Keep the instructor's explanations, examples and
   order. Keep base mirt calls where the course teaches mirt.
7. **Never overwrite the original.** Write the adapted version to a new file
   and tell the instructor where it is.
8. **Check** with `check_material` (use `render = true` for chapters) and fix
   failures. Numbers can differ slightly from the original software; say so
   and explain why (estimation method, priors, quadrature, scaling).
9. **Report**: what was adapted, what was translated automatically, what you
   changed by hand, and anything the instructor should review (for example
   a statistic with no mirt equivalent).

## Common equivalents

| From | mirtverse |
|---|---|
| `ltm::rasch()`, `eRm::RM()`, `TAM::tam.mml()` | `mirt(data, 1, itemtype = "Rasch")` (translate_code) |
| `ltm::ltm(data ~ z1)` | `mirt(data, 1, itemtype = "2PL")` |
| `ltm::tpm()` | `mirt(data, 1, itemtype = "3PL")` |
| `ltm::grm()`, `eRm::PCM()` | `itemtype = "graded"`, `"Rasch"` (polytomous) |
| `coef()` / parameter tables | `tidy(model)`, `item_table(model)` |
| `plot(fit)` item curves | `gg_trace(model)` |
| information curves | `gg_info(model)` |
| `factor.scores()`, `person.parameter()` | `augment(model, data)` or `fscores()` |
| item fit (`item.fit()`, `itemfit()`) | `item_table(model)`, `gg_itemfit(model)` |
| model comparison (`anova()`) | `select_model(data)` |
| Wright map (WrightMap) | `gg_wright(model)` |
| DIF (difR, lordif) | `dif(data, group)`, `gg_dif()` |
| Winsteps / flexMIRT output tables | `tidy()`, `item_table()`, `glance()` |
