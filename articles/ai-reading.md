# AI in measurement: A reading list

This list is a starting point for a psychometrician who wants to read
about artificial intelligence (AI) in testing. Each entry says in one or
two sentences why it is worth your time. Entries are grouped in the
order of the [AI
Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.md) learning
path, and the first group is the place to start. Links point to the
publisher’s page or a free copy where one exists.

The field moves quickly: This list was checked in November 2026. To
suggest an addition, open an issue on
[GitHub](https://github.com/okanbulut/mirtverse/issues).

## Start here: Overviews

- Bulut, O., Beiting-Parrish, M., Casabianca, J. M., Slater, S. C.,
  Jiao, H., Song, D., Ormerod, C. M., Fabiyi, D. G., Ivan, R., Walsh,
  C., Rios, O., Wilson, J., Yildirim-Erbasli, S. N., Wongvorachan, T.,
  Liu, J. X., Tan, B., & Morilova, P. (2024). The rise of artificial
  intelligence in educational measurement: Opportunities and ethical
  challenges. *Chinese/English Journal of Educational Measurement and
  Evaluation*.
  [doi:10.59863/MIQL7785](https://doi.org/10.59863/MIQL7785)
  ([preprint](https://arxiv.org/abs/2406.18900)).  
  A broad survey of where AI is used in testing, from item writing to
  scoring and reporting, with the validity, fairness and privacy
  questions each use raises.
- Hao, J., von Davier, A. A., Yaneva, V., Lottridge, S., von Davier, M.,
  & Harris, D. J. (2024). Transforming assessment: The impacts and
  implications of large language models and generative AI. *Educational
  Measurement: Issues and Practice, 43*(2), 16–29.
  [doi:10.1111/emip.12602](https://doi.org/10.1111/emip.12602)  
  A short, practical account by testing-industry researchers of what
  large language models change in item development, scoring and score
  reporting.
- von Davier, A. A., Mislevy, R. J., & Hao, J. (Eds.). (2021).
  *Computational psychometrics: New methodologies for a new generation
  of digital learning and assessment.* Springer.
  [doi:10.1007/978-3-030-74394-9](https://doi.org/10.1007/978-3-030-74394-9)  
  How psychometric models and machine learning combine for data from
  games, simulations and process logs.

## Machine learning through a psychometric lens

- Breiman, L. (2001). Statistical modeling: The two cultures.
  *Statistical Science, 16*(3), 199–231.
  [doi:10.1214/ss/1009213726](https://doi.org/10.1214/ss/1009213726)  
  The classic essay on modelling to explain versus modelling to predict.
  Psychometrics lives mostly in the first culture; this explains the
  second.
- Yarkoni, T., & Westfall, J. (2017). Choosing prediction over
  explanation in psychology: Lessons from machine learning.
  *Perspectives on Psychological Science, 12*(6), 1100–1122.
  [doi:10.1177/1745691617693393](https://doi.org/10.1177/1745691617693393)  
  Overfitting, cross-validation and regularization, explained for
  researchers trained in classical statistics.
- James, G., Witten, D., Hastie, T., & Tibshirani, R. (2021). *An
  introduction to statistical learning with applications in R* (2nd
  ed.). Springer. [Free PDF](https://www.statlearning.com/)  
  The standard first textbook, with R labs. Chapters 2, 5 and 6 cover
  most of what the [translation
  table](https://www.okanbulut.com/mirtverse/articles/ai-translation.md)
  refers to.

## Automated scoring

- Williamson, D. M., Xi, X., & Breyer, F. J. (2012). A framework for
  evaluation and use of automated scoring. *Educational Measurement:
  Issues and Practice, 31*(1), 2–13.
  [doi:10.1111/j.1745-3992.2011.00223.x](https://doi.org/10.1111/j.1745-3992.2011.00223.x)  
  The source of the agreement thresholds (QWK, standardized mean
  difference) that
  [`score_open()`](https://www.okanbulut.com/mirtverse/reference/score_open.md)
  uses. Read this before any scoring project.
- Yan, D., Rupp, A. A., & Foltz, P. W. (Eds.). (2020). *Handbook of
  automated scoring: Theory into practice.* CRC Press.  
  The reference book: Scoring engines, evaluation, operational use and
  validity.
- Loukina, A., Madnani, N., Cahill, A., Yao, L., Johnson, M. S.,
  Riordan, B., & McCaffrey, D. F. (2020). Using PRMSE to evaluate
  automated scoring systems in the presence of label noise. In
  *Proceedings of the Fifteenth Workshop on Innovative Use of NLP for
  Building Educational Applications* (pp. 18–29). [ACL
  Anthology](https://aclanthology.org/2020.bea-1.2)  
  Why agreement with a single human rater undersells a good engine, and
  how PRMSE corrects for rater error.
- Bridgeman, B., Trapani, C., & Attali, Y. (2012). Comparison of human
  and machine scoring of essays: Differences by gender, ethnicity, and
  country. *Applied Measurement in Education, 25*(1), 27–40.
  [doi:10.1080/08957347.2012.635502](https://doi.org/10.1080/08957347.2012.635502)  
  An early and clear demonstration that an engine can agree well with
  humans overall and still score some groups differently.

## What item text tells us: Difficulty prediction

- Fischer, G. H. (1973). The linear logistic test model as an instrument
  in educational research. *Acta Psychologica, 37*(6), 359–374.
  [doi:10.1016/0001-6918(73)90003-6](https://doi.org/10.1016/0001-6918(73)90003-6)  
  The psychometric ancestor of difficulty prediction: Item difficulty as
  a sum of the cognitive operations an item requires.
- De Boeck, P., & Wilson, M. (Eds.). (2004). *Explanatory item response
  models: A generalized linear and nonlinear approach.* Springer.
  [doi:10.1007/978-1-4757-3990-9](https://doi.org/10.1007/978-1-4757-3990-9)  
  IRT models with item and person covariates, the bridge between
  features and item parameters.
- Bulut, O., Gorgun, G., & Yildirim-Erbasli, S. N. (2021). Estimating
  explanatory extensions of dichotomous and polytomous Rasch models: The
  eirm package in R. *Psych, 3*(3), 308–321.
  [doi:10.3390/psych3030023](https://doi.org/10.3390/psych3030023)  
  Explanatory IRT as generalized linear mixed models in R, with item and
  person covariates and random item effects.
- AlKhuzaey, S., Grasso, F., Payne, T. R., & Tamma, V. (2024).
  Text-based question difficulty prediction: A systematic review of
  automatic approaches. *International Journal of Artificial
  Intelligence in Education, 34*(3), 862–914.
  [doi:10.1007/s40593-023-00362-1](https://doi.org/10.1007/s40593-023-00362-1)  
  What features and models have been tried, and how well they work.
- Benedetto, L., Cremonesi, P., Caines, A., Buttery, P., Cappelli, A.,
  Giussani, A., & Turrin, R. (2023). A survey on recent approaches to
  question difficulty estimation from text. *ACM Computing Surveys,
  55*(9), Article 178.
  [doi:10.1145/3556538](https://doi.org/10.1145/3556538)  
  A companion survey from the computer science side, including neural
  approaches.
- Yaneva, V., North, K., Baldwin, P., Ha, L. A., Rezayi, S., Zhou, Y.,
  Ray Choudhury, S., Harik, P., & Clauser, B. (2024). Findings from the
  first shared task on automated prediction of difficulty and response
  time for multiple-choice questions. In *Proceedings of the 19th
  Workshop on Innovative Use of NLP for Building Educational
  Applications* (pp. 470–482). [ACL
  Anthology](https://aclanthology.org/2024.bea-1.39)  
  A sobering benchmark on real licensing-exam items: Many teams, modest
  gains over a simple baseline.

## Automatic item generation

- Gierl, M. J., & Haladyna, T. M. (Eds.). (2013). *Automatic item
  generation: Theory and practice.* Routledge.  
  The foundational book on cognitive models, item models and the
  psychometrics of generated items.
- Gierl, M. J., & Lai, H. (2013). Instructional topics in educational
  measurement (ITEMS) module: Using automated processes to generate test
  items. *Educational Measurement: Issues and Practice, 32*(3), 36–50.
  [doi:10.1111/emip.12018](https://doi.org/10.1111/emip.12018)  
  A short teaching module on the three-step method: Cognitive model,
  item model, generation.
- Glas, C. A. W., & van der Linden, W. J. (2003). Computerized adaptive
  testing with item cloning. *Applied Psychological Measurement, 27*(4),
  247–261.
  [doi:10.1177/0146621603027004001](https://doi.org/10.1177/0146621603027004001)  
  How to calibrate item families instead of single items, so generated
  isomorphs can be used without each one being field tested.
- Sinharay, S., Johnson, M. S., & Williamson, D. M. (2003). Calibrating
  item families and summarizing the results using family expected
  response functions. *Journal of Educational and Behavioral Statistics,
  28*(4), 295–313.  
  A hierarchical model for item families, with a way to report a family
  as a whole.
- Geerlings, H., Glas, C. A. W., & van der Linden, W. J. (2011).
  Modeling rule-based item generation. *Psychometrika, 76*(2), 337–359.
  [doi:10.1007/s11336-011-9204-x](https://doi.org/10.1007/s11336-011-9204-x)  
  Explains family difficulties by the rules used to generate the items:
  The LLTM idea applied to item models. In mirtverse:
  [`calibrate_families()`](https://www.okanbulut.com/mirtverse/reference/calibrate_families.md),
  the book’s chapter [Generating
  items](https://www.okanbulut.com/mirtverse/book/aig.md) and [Lab
  9](https://www.okanbulut.com/mirtverse/articles/teaching-labs.html#lab-9).
- von Davier, M. (2018). Automated item generation with recurrent neural
  networks. *Psychometrika, 83*(4), 847–857.
  [doi:10.1007/s11336-018-9608-y](https://doi.org/10.1007/s11336-018-9608-y)  
  An early neural approach to writing items, before today’s large
  language models.
- Circi, R., Hicks, J., & Sikali, E. (2023). Automatic item generation:
  Foundations and machine learning-based approaches for assessments.
  *Frontiers in Education, 8*, 858273.
  [doi:10.3389/feduc.2023.858273](https://doi.org/10.3389/feduc.2023.858273)  
  A review that places template and machine learning approaches side by
  side.

## Language models as respondents

- Argyle, L. P., Busby, E. C., Fulda, N., Gubler, J. R., Rytting, C., &
  Wingate, D. (2023). Out of one, many: Using language models to
  simulate human samples. *Political Analysis, 31*(3), 337–351.
  [doi:10.1017/pan.2023.2](https://doi.org/10.1017/pan.2023.2)  
  The paper that started the “silicon sample” debate. Read it alongside
  a psychometric check of whether simulated responses behave like real
  ones.

## Validity, fairness and governance

- American Educational Research Association, American Psychological
  Association, & National Council on Measurement in Education. (2014).
  *Standards for educational and psychological testing.* AERA. [Free
  PDF](https://www.testingstandards.net/open-access-files.html)  
  Not about AI, but every AI use in testing is ultimately judged against
  it.
- Kane, M. T. (2013). Validating the interpretations and uses of test
  scores. *Journal of Educational Measurement, 50*(1), 1–73.
  [doi:10.1111/jedm.12000](https://doi.org/10.1111/jedm.12000)  
  The argument-based approach to validity, which gives a structure for
  asking what an AI component must be shown to do.
- Johnson, M. S., Liu, X., & McCaffrey, D. F. (2022). Psychometric
  methods to evaluate measurement and algorithmic bias in automated
  scoring. *Journal of Educational Measurement, 59*(3), 338–361.
  [doi:10.1111/jedm.12335](https://doi.org/10.1111/jedm.12335)  
  Separates bias in what the engine measures from bias in how it
  predicts, using tools a psychometrician already knows.
- International Test Commission & Association of Test Publishers.
  (2022). *Guidelines for technology-based assessment.*  
  Practical guidance on scoring, security, accessibility and fairness
  for computer-delivered tests, including automated scoring.
