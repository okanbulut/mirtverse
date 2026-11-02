# Machine learning for psychometricians: A translation table

Machine learning papers often describe ideas a psychometrician already
knows under other names, and sometimes use a familiar word for something
different. This page lines the two vocabularies up. Each row gives the
machine learning or AI term, what it means in plain words, the closest
idea in measurement, and **where they differ**, which is usually where
the misunderstandings start.

The analogies are approximate on purpose. They give you a foothold, not
an identity. Terms with a full entry in the
[glossary](https://www.okanbulut.com/mirtverse/articles/glossary.html#ai)
link there. The [AI
Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.md) shows how
these ideas fit into the measurement workflow.

## Data and models

| Machine learning term | What it means | Closest psychometric idea | Where they differ |
|----|----|----|----|
| Model | A function that maps inputs to a prediction | A measurement model, such as the 2PL | A measurement model claims to describe how responses arise from a latent trait; a prediction model only has to predict well |
| [Feature](https://www.okanbulut.com/mirtverse/articles/glossary.html#feature) | A measured input to a model | A covariate, or an item property in an explanatory IRT model | ML models may use thousands of features with no theory behind them |
| Label, target | The outcome a model learns to predict | The criterion, or a human score | In scoring, the “label” is a human rating that contains its own error |
| Supervised learning | Learning to predict a known label from features | Regression on a criterion | IRT is closer to *unsupervised* learning: The trait is never observed |
| Unsupervised learning | Finding structure in data without labels | Factor analysis, latent class analysis | ML clustering rarely tests whether the structure fits or replicates |
| Latent representation | Hidden variables a model builds to summarize inputs | The latent trait θ | Latent dimensions in a neural network have no intended meaning and are not identified |
| Classification | Predicting a category | Mastery decisions, latent class membership, pass/fail at a cut score | ML reports accuracy against labels; psychometrics also asks how consistent the decision would be on a retest |
| Logistic regression | Predicting a 0/1 outcome with a logit link | The 1PL and 2PL item response functions | In IRT the predictor (θ) is latent and estimated jointly with the item parameters |
| Neural network | Layers of weighted sums passed through non-linear functions | A very large, flexible multidimensional model | Its parameters are not interpretable one by one |
| Decision tree, random forest, boosting | Models that split cases by feature values and combine many such trees | Recursive partitioning for DIF, such as Rasch trees | Ensembles predict well but hide which feature does what |

## Training and evaluation

| Machine learning term | What it means | Closest psychometric idea | Where they differ |
|----|----|----|----|
| Training | Estimating a model’s parameters from data | Calibration | Training usually minimizes prediction error, not a likelihood of a measurement model |
| Loss function | The quantity training minimizes | The negative log-likelihood | Many ML losses are not likelihoods, so likelihood-ratio tests and information criteria do not apply |
| Training, validation and test sets | Separate data for fitting, tuning and the final check | Calibration sample and cross-validation sample | ML treats the held-out test set as the only honest evidence; IRT often relies on fit to the calibration data |
| [Overfitting](https://www.okanbulut.com/mirtverse/articles/glossary.html#cross-validation) | Fitting noise, so new data are predicted worse | Capitalizing on chance in item selection or model modification | The cure in ML is held-out data; in IRT it is often a simpler model or a priori constraints |
| [Cross-validation](https://www.okanbulut.com/mirtverse/articles/glossary.html#cross-validation) | Rotating which part of the data is held out | Cross-validation of a regression, double cross-validation in test construction | Fold-to-fold variation shows how unstable the estimate is |
| Regularization (lasso, ridge) | Shrinking parameters toward zero to reduce overfitting | Priors on item parameters, as in Bayesian or MAP estimation | The amount of shrinkage is tuned for prediction, not chosen on substantive grounds |
| Hyperparameter | A setting chosen before training, such as tree depth | Estimation settings: Number of quadrature points, prior variances | Hyperparameters are tuned on validation data and can change results a lot |
| Bias-variance trade-off | Simpler models err systematically; complex ones vary a lot | Choosing between 1PL, 2PL and 3PL with AIC or BIC | Same idea; ML usually settles it with held-out error instead of information criteria |
| Accuracy, precision, recall, F1 | Ways to count correct and incorrect classifications | Classification accuracy, sensitivity and specificity at a cut score | ML “precision” is a share of positive predictions, not measurement precision |
| AUC | How well a score ranks positives above negatives | The probability a master outscores a non-master; a discrimination index | AUC ignores calibration, the match between predicted and observed rates |
| Calibration (ML sense) | Predicted probabilities match observed rates | Item fit: Model-implied versus observed proportions | Same word, different meaning: In IRT “calibration” is estimating item parameters |
| Data leakage | Information in the features that would not be available in use | Item exposure or contaminated anchor items | Leakage makes a model look accurate in testing and fail in use |
| Distribution shift | New data differ from training data | Parameter drift, population invariance | ML models rarely state the population they are valid for |
| Explainability (SHAP, feature importance) | Methods that describe what drove a prediction | Item parameters, which are interpretable by design | Explanations of a black box are approximations of it, not the model itself |

## Text and language models

| Machine learning term | What it means | Closest psychometric idea | Where they differ |
|----|----|----|----|
| Natural language processing (NLP) | Methods that turn text into numbers or text | Content coding, readability formulas | NLP features are computed automatically and at scale |
| Token | A word or word piece a language model reads | None close | Token counts, not word counts, set the cost and length limits of a language model |
| Bag of words | Representing a text by counts of its words, ignoring order | A checklist rubric that counts key terms | Ignores meaning and order, so it rewards keywords |
| [Embedding](https://www.okanbulut.com/mirtverse/articles/glossary.html#embedding) | A vector that places texts with similar meaning close together | A factor score for a text | Embedding dimensions have no meaning, and different models give different embeddings |
| [Large language model](https://www.okanbulut.com/mirtverse/articles/glossary.html#llm) | A model trained on huge text corpora to predict the next token | None close; sometimes used as an item writer, rater or simulated respondent | Its output is a sample, not a fixed estimate |
| [Prompt](https://www.okanbulut.com/mirtverse/articles/glossary.html#prompt) | The instructions and context given to a language model | Item-writing guidelines, rater training materials | Small wording changes can change the output, so the prompt is part of the method |
| Temperature | How random a language model’s output is | None close | At temperature 0 output is more repeatable but still not guaranteed identical |
| Zero-shot and few-shot | Asking a model to do a task with no examples, or a few in the prompt | Rater training with anchor papers | The anchors chosen change the scores, as they do for human raters |
| Fine-tuning | Further training a pretrained model on your own labelled data | Training raters on local anchor sets | Needs many human-scored responses and must be repeated when the model changes |
| [Hallucination](https://www.okanbulut.com/mirtverse/articles/glossary.html#hallucination) | Fluent but false output | Item-writing flaws: A wrong key, two keys, an implausible distractor | Errors look confident, so they are found only by checking |
| Retrieval-augmented generation | Giving the model source documents to answer from | Writing items from a specified content source | Reduces, but does not remove, invented content |
| Agent | A language model that calls tools and takes several steps on its own | An automated test assembly or scoring pipeline | Each step can fail, so checks are needed between steps |

## Scoring and agreement

| Machine learning term | What it means | Closest psychometric idea | Where they differ |
|----|----|----|----|
| [Automated scoring](https://www.okanbulut.com/mirtverse/articles/glossary.html#automated-scoring) | A model that scores constructed responses | A rater | The engine is consistent with itself but can be consistently wrong for a subgroup |
| Ground truth | The correct label | The true score | In scoring, human scores stand in for the truth but contain rater error |
| [Quadratic weighted kappa](https://www.okanbulut.com/mirtverse/articles/glossary.html#qwk) | Chance-corrected agreement on an ordered scale | Inter-rater reliability | Depends on the score distribution, so compare machine-human with human-human QWK on the same responses |
| [PRMSE](https://www.okanbulut.com/mirtverse/articles/glossary.html#prmse) | Share of true-score variance a machine score explains | Reliability of the machine score with respect to the human true score | Needs double-scored responses to separate human error from machine error |
| [Human-in-the-loop](https://www.okanbulut.com/mirtverse/articles/glossary.html#human-in-the-loop) | People review or override AI output | Read-behind and adjudication by a third rater | Routing rules decide which responses humans see, and they need their own checks |

## Fairness and governance

| Machine learning term | What it means | Closest psychometric idea | Where they differ |
|----|----|----|----|
| Algorithmic bias | A model works worse or differently for a group | Measurement bias, [DIF](https://www.okanbulut.com/mirtverse/articles/glossary.html#dif) | ML fairness often compares outcomes; psychometrics compares people of equal ability |
| Demographic parity | Equal rates of a positive outcome across groups | Impact (group differences in scores) | Equal outcomes are not required when groups differ in the trait; DIF conditions on the trait for that reason |
| Equalized odds | Equal error rates across groups | Equal classification accuracy across groups; differential prediction | Closer to measurement invariance, but still conditions on an observed label, not the latent trait |
| Model card, datasheet | A short document of a model’s data, uses and limits | A technical manual, validity evidence | Rarely includes the evidence a validity argument would ask for |
| Responsible AI | Principles for safe, fair and transparent AI use | The *Standards for Educational and Psychological Testing* | The Standards ask for evidence for a specific use; responsible AI principles are often general |

## Where to go next

- The [AI Hub](https://www.okanbulut.com/mirtverse/articles/ai-hub.md)
  gives a learning path through these ideas.
- The [reading
  list](https://www.okanbulut.com/mirtverse/articles/ai-reading.md) has
  an annotated set of papers and books for each topic.
- [Lab 6](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md)
  puts an automated scoring engine next to human raters on the same
  responses.
