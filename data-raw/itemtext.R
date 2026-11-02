# Builds the `itemtext` teaching dataset: the text and field-test statistics of
# 192 Grade 7 numeracy multiple-choice items, for the AI Hub (predicting item
# difficulty from text, automatic item generation).
#
# The items come from 12 item models (families), each a template with
# variable numbers, names and contexts, 16 items per family. Each item's true
# difficulty is its family's difficulty plus effects of its surface features:
#   * decimal or fraction values: +0.35
#   * larger numbers (more digits): +0.12 per extra digit
#   * an extra context sentence that adds reading load: +0.15
#   * item-specific noise: SD 0.20
# A field test (2PL, 1,500 test takers per item, theta ~ N(0, 1)) gives the
# calibrated `b`, `a` and their standard errors, plus `p_field`, the share
# correct in the field test. Planted on purpose:
#   * `p_field` is computed from the same field test that gives `b`: a model
#     that predicts `b` from it looks excellent but is useless before field
#     testing (data leakage)
#   * three items are miskeyed (the listed key is a distractor), so their
#     estimated discrimination is negative: N05-07, N08-11, N11-03
#   * two pairs are near-duplicates (same stem, a different name):
#     N01-02 and N01-14; N06-05 and N06-12
# The generating values are stored internally as `itemtext_truth`.
#
# Run from the package root: source("data-raw/itemtext.R")

set.seed(2611)
library(mirt)

names_pool <- c("Maya", "Liam", "Aiko", "Omar", "Sofia", "Ethan", "Priya", "Noah",
                "Amara", "Lucas", "Chen", "Zoe", "Mateo", "Leila", "Owen", "Nadia")
contexts <- c("is buying supplies for a school trip.", "is helping at the community garden.",
              "is planning a weekend bike ride.", "is cooking dinner for the family.",
              "is working at a summer job.", "is saving money for a new bike.",
              "is getting ready for a science fair.", "is organizing the class library.")

fmt <- function(x) vapply(x, function(v) {
  if (abs(v - round(v)) < 1e-9) format(round(v), big.mark = ",", trim = TRUE) else
    sub("0+$", "", formatC(v, format = "f", digits = 4))
}, "")
money <- function(x) paste0("$", formatC(x, format = "f", digits = 2))

# Each family returns stem, correct answer, three distractors (misconceptions)
# and its surface features: decimal (0/1), digits (largest number of digits).
fam <- list(
  # 1 unit rate
  function(i, nm) {
    n <- sample(c(4, 5, 6, 8, 10, 12), 1)
    dec <- i > 8
    unit <- if (dec) sample(c(0.25, 0.75, 1.25, 1.5), 1) else sample(2:9, 1)
    cost <- n * unit
    list(stem = sprintf("A pack of %d pencils costs %s. How much does one pencil cost?", n, money(cost)),
         ans = money(unit), dis = c(money(cost * n), money(cost - n), money(n / cost)),
         decimal = dec, digits = nchar(round(cost)))
  },
  # 2 percent of a number
  function(i, nm) {
    p <- sample(c(10, 20, 25, 50), 1); x <- sample(c(40, 60, 80, 120, 200, 360, 480, 1200), 1)
    if (i > 10) p <- sample(c(15, 35, 45), 1)
    a <- p * x / 100
    list(stem = sprintf("What is %d%% of %s?", p, fmt(x)),
         ans = fmt(a), dis = c(fmt(x / p), fmt(x - p), fmt(p * x / 10)),
         decimal = (a %% 1) != 0, digits = nchar(x))
  },
  # 3 area of a rectangle
  function(i, nm) {
    l <- sample(4:15, 1); w <- sample(2:9, 1)
    if (i > 10) { l <- l + 0.5 }
    list(stem = sprintf("A rectangle is %s cm long and %s cm wide. What is its area?", fmt(l), fmt(w)),
         ans = paste(fmt(l * w), "square cm"),
         dis = paste(c(fmt(2 * (l + w)), fmt(l + w), fmt(2 * l * w)), "square cm"),
         decimal = i > 10, digits = nchar(round(l * w)))
  },
  # 4 elapsed time
  function(i, nm) {
    h <- sample(1:9, 1); m <- sample(c(0, 15, 30, 45), 1); d <- sample(c(75, 90, 105, 130, 145), 1)
    end <- h * 60 + m + d
    tm <- function(t) sprintf("%d:%02d", (t %/% 60 - 1) %% 12 + 1, t %% 60)
    list(stem = sprintf("A movie starts at %s p.m. and lasts %d minutes. At what time does it end?", tm(h * 60 + m), d),
         ans = paste(tm(end), "p.m."),
         dis = paste(c(tm(h * 60 + m + d %/% 100 * 60 + d %% 100), tm(h * 60 + m + 60), tm(end + 40)), "p.m."),
         decimal = FALSE, digits = nchar(d))
  },
  # 5 mean
  function(i, nm) {
    repeat {
      v <- sample(if (i > 8) 55:98 else 2:20, 4)
      if (sum(v) %% 4 == 0 && stats::median(v) != mean(v)) break
    }
    list(stem = sprintf("%s's quiz scores were %s. What is the mean score?", nm, paste(v, collapse = ", ")),
         ans = fmt(mean(v)), dis = c(fmt(stats::median(v)), fmt(sum(v)), fmt(max(v) - min(v))),
         decimal = FALSE, digits = max(nchar(v)))
  },
  # 6 adding fractions
  function(i, nm) {
    if (i <= 8) {
      b <- sample(5:12, 1); a <- sample(1:(b - 3), 1); c <- sample(1:(b - a - 1), 1)
      stem <- sprintf("What is %d/%d + %d/%d?", a, b, c, b)
      ans <- sprintf("%d/%d", a + c, b); dis <- c(sprintf("%d/%d", a + c, 2 * b),
                                                   sprintf("%d/%d", a * c, b), sprintf("%d/%d", a + c, b + 1))
    } else {
      b <- sample(c(2, 3, 4), 1); d <- sample(c(5, 6, 8), 1)
      stem <- sprintf("What is 1/%d + 1/%d?", b, d)
      ans <- sprintf("%d/%d", b + d, b * d); dis <- c(sprintf("2/%d", b + d),
                                                      sprintf("1/%d", b * d), sprintf("2/%d", b * d))
    }
    list(stem = stem, ans = ans, dis = dis, decimal = TRUE, digits = 2)
  },
  # 7 one-step and two-step equations
  function(i, nm) {
    x <- sample(2:12, 1); a <- sample(2:9, 1); b <- sample(3:30, 1)
    list(stem = sprintf("If %dx + %d = %d, what is the value of x?", a, b, a * x + b),
         ans = fmt(x), dis = c(fmt((a * x + b + b) / a), fmt(a * x), fmt(x + b)),
         decimal = FALSE, digits = nchar(a * x + b))
  },
  # 8 ratio
  function(i, nm) {
    r <- sample(list(c(2, 3), c(3, 4), c(1, 4), c(3, 5), c(2, 5)), 1)[[1]]
    k <- sample(c(4, 5, 6, 8, 10, 12), 1); n <- k * sum(r)
    list(stem = sprintf("In a club, the ratio of boys to girls is %d:%d. There are %d students in the club. How many are girls?",
                        r[1], r[2], n),
         ans = fmt(k * r[2]), dis = c(fmt(k * r[1]), fmt(n / r[2]), fmt(n - r[2])),
         decimal = FALSE, digits = nchar(n))
  },
  # 9 comparing decimals
  function(i, nm) {
    base <- sample(2:8, 1)
    v <- c(base + 0.5, base + 0.45, base + 0.405, base + 0.09)
    if (i > 8) v <- c(base + 0.7, base + 0.69, base + 0.071, base + 0.6999)
    q <- c("Which number is the greatest?", "Which of these numbers is the largest?",
           "Which number has the greatest value?", "Which decimal is the largest?")
    list(stem = sample(q, 1), ans = fmt(v[1]), dis = fmt(v[2:4]),
         decimal = TRUE, digits = 4)
  },
  # 10 unit conversion
  function(i, nm) {
    m <- if (i > 8) sample(c(1.5, 2.25, 3.4, 0.75, 1.25, 2.6, 4.05, 0.85, 3.75, 1.8), 1) else sample(2:9, 1)
    list(stem = sprintf("How many centimetres are in %s metres?", fmt(m)),
         ans = fmt(m * 100), dis = c(fmt(m * 10), fmt(m * 1000), fmt(m / 100)),
         decimal = i > 8, digits = nchar(round(m * 100)))
  },
  # 11 simple probability
  function(i, nm) {
    r <- sample(2:9, 1); b <- sample(2:9, 1); g <- if (i > 8) sample(2:6, 1) else 0
    tot <- r + b + g
    bag <- if (g) sprintf("%d red, %d blue and %d green marbles", r, b, g) else
      sprintf("%d red and %d blue marbles", r, b)
    list(stem = sprintf("A bag has %s. %s picks one marble without looking. What is the probability that it is red?", bag, nm),
         ans = sprintf("%d/%d", r, tot), dis = c(sprintf("%d/%d", r, b + g), sprintf("1/%d", tot),
                                                  sprintf("%d/%d", b + g, tot)),
         decimal = TRUE, digits = nchar(tot))
  },
  # 12 average speed
  function(i, nm) {
    t <- if (i > 8) sample(c(1.5, 2.5, 0.5), 1) else sample(2:5, 1)
    s <- sample(c(40, 50, 60, 70, 80, 90), 1); d <- s * t
    list(stem = sprintf("A car travels %s km in %s hours. What is its average speed?", fmt(d), fmt(t)),
         ans = paste(fmt(s), "km/h"),
         dis = paste(c(fmt(d * t), fmt(d - t), fmt(d)), "km/h"),
         decimal = i > 8, digits = nchar(round(d)))
  })

fam_names <- c("Unit rate", "Percent of a number", "Area of a rectangle", "Elapsed time",
               "Mean", "Adding fractions", "Solving equations", "Ratio", "Comparing decimals",
               "Converting units", "Probability", "Average speed")
domain <- c("Ratios and rates", "Ratios and rates", "Measurement", "Measurement", "Data",
            "Number", "Algebra", "Ratios and rates", "Number", "Measurement", "Data",
            "Ratios and rates")
fam_b <- c(-0.45, 0.05, -0.95, 0.1, -0.55, 0.35, 1.0, 0.75, 0.45, -1.25, 0.3, -0.2)

rows <- list()
sigs <- character()
for (f in 1:12) {
  for (i in 1:16) {
    nm <- names_pool[(i + f) %% 16 + 1]
    repeat {
      it <- fam[[f]](i, nm)
      sig <- paste(it$stem, paste(sort(c(it$ans, it$dis)), collapse = " "))
      if (!sig %in% sigs && !anyDuplicated(c(it$ans, it$dis))) break
    }
    sigs <- c(sigs, sig)
    ctx <- i %% 3 == 0
    stem <- if (ctx) paste(nm, sample(contexts, 1), it$stem) else it$stem
    opts <- c(it$ans, it$dis)
    if (anyDuplicated(opts)) opts[duplicated(opts)] <- paste(opts[duplicated(opts)], "")
    ord <- sample(4)
    rows[[length(rows) + 1]] <- data.frame(
      id = sprintf("N%02d-%02d", f, i), family = fam_names[f], domain = domain[f], stem = stem,
      A = trimws(opts[ord[1]]), B = trimws(opts[ord[2]]), C = trimws(opts[ord[3]]),
      D = trimws(opts[ord[4]]), key = LETTERS[which(ord == 1)],
      decimal = as.integer(it$decimal), digits = it$digits, context = as.integer(ctx),
      stringsAsFactors = FALSE)
  }
}
itemtext <- do.call(rbind, rows)

# near-duplicates: copy one item into another, changing only the name
dup <- function(from, to, old_name, new_name) {
  j <- match(from, itemtext$id); k <- match(to, itemtext$id)
  cols <- c("stem", "A", "B", "C", "D", "key", "decimal", "digits", "context")
  itemtext[k, cols] <<- itemtext[j, cols]
  itemtext$stem[k] <<- sub(old_name, new_name, itemtext$stem[k], fixed = TRUE)
}
j <- match("N01-02", itemtext$id)
itemtext$stem[j] <- paste("Maya is buying supplies for a school trip.",
                          sub("^.*?\\. (A pack)", "\\1", itemtext$stem[j]))
itemtext$context[j] <- 1L
dup("N01-02", "N01-14", "Maya", "Leila")
j <- match("N06-05", itemtext$id)
itemtext$stem[j] <- paste("Owen is cooking dinner for the family.", itemtext$stem[j])
itemtext$context[j] <- 1L
dup("N06-05", "N06-12", "Owen", "Nadia")

# true difficulty and discrimination
fam_idx <- match(itemtext$family, fam_names)
b_true <- fam_b[fam_idx] + 0.35 * itemtext$decimal + 0.12 * pmax(itemtext$digits - 1, 0) +
  0.15 * itemtext$context + stats::rnorm(nrow(itemtext), 0, 0.2)
a_true <- round(stats::rlnorm(nrow(itemtext), log(1.2), 0.25), 2)

# miskeys: the listed key is a distractor
miskey <- c("N05-07", "N08-11", "N11-03")
true_key <- itemtext$key
for (m in miskey) {
  j <- match(m, itemtext$id)
  itemtext$key[j] <- setdiff(LETTERS[1:4], true_key[j])[1]
}

# field test: each item taken by 1,500 test takers, calibrated with the 2PL
N <- 1500L
theta <- stats::rnorm(N)
resp <- sapply(seq_len(nrow(itemtext)), function(j) {
  p <- 1 / (1 + exp(-a_true[j] * (theta - b_true[j])))
  correct <- stats::runif(N) < p
  if (itemtext$id[j] %in% miskey) {
    # scored against the wrong key: credit only for choosing that distractor
    correct <- !correct & stats::runif(N) < 0.25
  }
  as.integer(correct)
})
colnames(resp) <- itemtext$id
fit <- mirt(as.data.frame(resp), 1, itemtype = "2PL", SE = TRUE, verbose = FALSE,
            technical = list(NCYCLES = 2000))
cf <- coef(fit, IRTpars = TRUE, printSE = TRUE, simplify = FALSE)
pars <- t(sapply(itemtext$id, function(id) c(cf[[id]]["par", c("a", "b")], cf[[id]]["SE", c("a", "b")])))
itemtext$a <- round(pars[, 1], 2)
itemtext$b <- round(pars[, 2], 2)
itemtext$a_se <- round(pars[, 3], 3)
itemtext$b_se <- round(pars[, 4], 3)
itemtext$p_field <- round(colMeans(resp), 3)
itemtext$b[itemtext$b > 6] <- 6
rownames(itemtext) <- NULL

itemtext_truth <- list(
  b = stats::setNames(round(b_true, 3), itemtext$id),
  a = stats::setNames(a_true, itemtext$id),
  family_b = stats::setNames(fam_b, fam_names),
  effects = c(decimal = 0.35, digit = 0.12, context = 0.15, noise_sd = 0.2),
  miskeyed = data.frame(id = miskey, listed_key = itemtext$key[match(miskey, itemtext$id)],
                        correct_key = true_key[match(miskey, itemtext$id)]),
  near_duplicates = list(c("N01-02", "N01-14"), c("N06-05", "N06-12")),
  leaky = "p_field")

usethis_save <- function() {
  save(itemtext, file = "data/itemtext.rda", compress = "xz")
  sysdata <- new.env()
  load("R/sysdata.rda", envir = sysdata)
  assign("itemtext_truth", itemtext_truth, envir = sysdata)
  save(list = ls(sysdata), envir = sysdata, file = "R/sysdata.rda", compress = "xz")
}
usethis_save()
