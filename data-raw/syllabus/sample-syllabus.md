---
title: "Item Response Theory with mirt and mirtverse"
subtitle: "Sample syllabus for a 12-week graduate course"
---

*Replace everything in [square brackets]. Drop, merge or reorder weeks as you need. The weekly readings are chapters of the free online book; the labs run on students' laptops.*

| | |
|-----------|-------------------------------|
| **Course** | [Course number and title] |
| **Instructor** | [Name, email, office hours] |
| **Term and meetings** | [Term; days, times and room] |
| **Prerequisites** | An introductory statistics course. No experience with R is required. |

# Course description

This course introduces item response theory (IRT), the measurement framework behind most modern tests and surveys. Students learn to fit and compare IRT models, check whether items and models work, score people, examine fairness, link test forms and report results to people who do not use statistics. Every week combines a reading, a short analysis in R and, in most weeks, an interactive lab built around a realistic testing decision.

# Learning outcomes

By the end of the course, students will be able to:

1. Explain the assumptions and parameters of the Rasch, 2PL, 3PL and polytomous IRT models.
2. Fit, compare and choose IRT models with the mirt package, and defend the choice.
3. Evaluate dimensionality, local independence, item fit and person fit.
4. Describe measurement precision with information, standard errors and reliability.
5. Detect and interpret differential item functioning.
6. Link two test forms and describe how item banks support adaptive testing.
7. Report results, including cut scores, in plain language to non-specialists.

# Materials

All materials are free.

- **Book:** Bulut, O. (2026). *Item Response Theory with mirt and mirtverse*. <https://www.okanbulut.com/mirtverse/book/> (PDF and EPUB available; doi:10.5281/zenodo.23885605).
- **Software:** R, RStudio and the R packages mirt and mirtverse. Installation steps: <https://www.okanbulut.com/mirtverse/articles/for-new-to-r.html>.
- **Handouts:** The mirtverse cheat sheet and the glossary of IRT terms on the course website.

# Schedule

| Week | Topic | Reading | Lab or activity |
|----|--------------------------|--------|--------------------------|
| 1 | Measurement, scoring and classical item analysis | Ch. 1 | Install R and mirtverse; Lab 1, first two sections |
| 2 | The Rasch, 2PL and 3PL models | Ch. 2 | Fitting models to `LSAT7` |
| 3 | Estimation and comparing models | Ch. 3 | `select_model()` on `LSAT7` and `SAT12` |
| 4 | Dimensionality and local independence | Ch. 4 | **Lab 1:** Choosing a model the board can defend |
| 5 | Item fit, person fit and item quality | Ch. 5 | Item health cards on `SAT12` |
| 6 | Information, precision and reliability | Ch. 6 | Problem set 1 due |
| 7 | Scoring people | Ch. 7 | **Lab 2:** From parameters to decisions |
| 8 | Polytomous items and open-ended responses | Ch. 8 | **Lab 6:** Scoring open-ended responses |
| 9 | Differential item functioning and fairness | Ch. 9 | **Lab 3:** Is the test fair? |
| 10 | Linking and equating | Ch. 10 | **Lab 4:** Linking two forms; problem set 2 due |
| 11 | Item banks, test assembly and adaptive testing | Ch. 11 | **Lab 5:** Designing an adaptive test |
| 12 | Cut scores, reporting and communicating results | Ch. 12 | Final project presentations |

An optional four-week module on AI in measurement (book chapters 13 to 18, Labs 7 to 10) can replace weeks 10 and 11 or extend the course.

# Assessment

| Weight | Task | Due |
|-----|------------------------------------|--------|
| 20% | Lab 1 decision table and model justification | Week 4 |
| 20% | Lab 2 memo to the certification board | Week 7 |
| 20% | Two short problem sets (fit and precision; DIF or linking) | Weeks 6 and 10 |
| 40% | Final project: A full analysis of a dataset of your choice, submitted as an HTML report or dashboard with a two-page memo | Week 12 |

# Course policies

[Attendance, late work, academic integrity, use of generative AI tools, accessibility and accommodations, and other policies required by your institution.]

---

*This syllabus is adapted from the mirtverse course map: <https://www.okanbulut.com/mirtverse/articles/course-map.html>.*
