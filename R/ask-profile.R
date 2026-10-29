#' Summarise a data set without revealing its values
#'
#' Describes each column of a data set (type, number of distinct values,
#' range, share missing) and guesses its role: an `item` (whole numbers with
#' few categories), a `group` variable (few categories, e.g. gender), an `id`,
#' a response time (`rt`), or `other`. This summary is the only information
#' [mv_ask()] ever shares with an AI model; individual responses are never
#' included. Category labels are kept only for likely grouping variables.
#'
#' @param data a data frame.
#' @return A tibble of class `mv_profile` with one row per column: `column`,
#'   `type`, `n_distinct`, `min`, `max`, `prop_missing`, `role` and `levels`.
#'   The number of rows of `data` is stored in the `n` attribute.
#' @examples
#' profile_data(Science)
#' @export
profile_data <- function(data) {
  data <- as.data.frame(data)
  if (!ncol(data)) stop("`data` has no columns.", call. = FALSE)
  nms <- names(data)
  rows <- lapply(nms, function(nm) {
    v <- data[[nm]]
    num <- is.numeric(v) || is.logical(v)
    vals <- unique(stats::na.omit(v))
    k <- length(vals)
    whole <- num && k > 0 && all(abs(as.numeric(vals) - round(as.numeric(vals))) < 1e-8)
    role <- guess_role(nm, v, num, whole, k, nrow(data))
    data.frame(column = nm,
               type = if (is.factor(v)) "factor" else if (is.logical(v)) "logical" else
                 if (num) (if (whole) "integer" else "numeric") else "text",
               n_distinct = k,
               min = if (num && k) min(as.numeric(vals)) else NA_real_,
               max = if (num && k) max(as.numeric(vals)) else NA_real_,
               prop_missing = mean(is.na(v)),
               role = role,
               levels = if (role == "group" && k <= 12)
                 paste(sort(as.character(vals)), collapse = ", ") else NA_character_,
               stringsAsFactors = FALSE)
  })
  out <- as_tbl(do.call(rbind, rows))
  structure(out, n = nrow(data), class = c("mv_profile", class(out)))
}

group_words <- c("gender", "sex", "group", "grade", "country", "language", "lang", "region",
                 "school", "form", "booklet", "ethnicity", "race", "site", "class", "cohort",
                 "condition", "treatment", "version", "female", "male")
id_words <- c("id", "identifier", "student", "person", "respondent", "examinee", "candidate")
rt_words <- c("rt", "time", "latency", "duration", "seconds", "secs", "ms")

has_word <- function(name, words) {
  tokens <- strsplit(gsub("([a-z])([A-Z])", "\\1_\\2", name), "[^A-Za-z]+")[[1]]
  any(tolower(tokens) %in% words)
}

guess_role <- function(name, v, num, whole, k, n) {
  if (has_word(name, id_words) && k > 0.9 * n) return("id")
  if (has_word(name, group_words) && k >= 2 && k <= 20) return("group")
  if (num && has_word(name, rt_words) && (!whole || k > 20)) return("rt")
  if (whole && k >= 2 && k <= 10 && min(v, na.rm = TRUE) >= 0 && max(v, na.rm = TRUE) <= 10)
    return("item")
  if (!num && k >= 2 && k <= 12) return("group")
  if (k > 0.9 * n && (whole || !num)) return("id")
  "other"
}

#' @method print mv_profile
#' @export
print.mv_profile <- function(x, ...) {
  cat(sprintf("Data profile: %d rows, %d columns (%d look like items)\n", attr(x, "n"),
              nrow(x), sum(x$role == "item")))
  df <- as.data.frame(x)
  df$prop_missing <- round(df$prop_missing, 3)
  df$levels[is.na(df$levels)] <- ""
  print(df, row.names = FALSE)
  invisible(x)
}
