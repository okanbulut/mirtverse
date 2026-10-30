#' Translate ltm, eRm, TAM and irtQ code into mirt code
#'
#' `mirtify()` reads R code written for the \pkg{ltm}, \pkg{eRm}, \pkg{TAM}
#' or \pkg{irtQ} packages and writes the equivalent \pkg{mirt} code. It parses
#' the code without running it, so the original package does not have to be
#' installed. Model calls (for example `ltm::rasch()`, `eRm::RM()`,
#' `TAM::tam.mml()` and `irtQ::est_irt()`) become [mirt::mirt()] calls with
#' the same model, and follow-up calls on the fitted object (person scores,
#' item fit, person fit, information, plots, Andersen's likelihood-ratio test
#' and so on) become their mirt or mirtverse equivalents.
#'
#' Each translated statement comes with notes on what differs between the
#' two packages, such as conditional versus marginal maximum likelihood in
#' eRm, the scaling constant `D` in irtQ, or the number of quadrature points.
#' Statements that do not involve these packages are kept as they are.
#' Statements with no mirt equivalent are kept as comments and explained in
#' the notes.
#'
#' Translation follows the defaults of ltm 1.2-0, eRm 1.0-10, TAM 4.3 and
#' irtQ 1.3. [mirtify_crosswalk()] lists every function that `mirtify()`
#' knows.
#'
#' @param code the code to translate. One of: a character string or vector
#'   of code lines, the path to an `.R` file, or the unquoted code itself
#'   (a single call, or several statements wrapped in `{ }`).
#' @param run logical; if `TRUE`, run the translated code and keep the
#'   objects it creates in the `env` element of the result.
#' @param notes logical; include the notes as comments in the translated
#'   script.
#' @param file optional path of an `.R` file to write the translated script
#'   to.
#' @param envir environment in which data objects are looked up (to count
#'   items and categories) and in which `run = TRUE` evaluates the code.
#' @return An object of class `mv_mirtify` with elements `script` (the
#'   translated code as a single string), `steps` (a tibble with one row per
#'   statement: `original`, `mirt`, `package`, `status` and `notes`) and, when
#'   `run = TRUE`, `env`. Use `as.character()` to get the script and
#'   `print()` to show it.
#' @seealso [mirtify_crosswalk()] for the table of supported functions.
#' @examples
#' mirtify("library(ltm)
#'          fit <- rasch(LSAT)
#'          summary(fit)
#'          factor.scores(fit)")
#'
#' # Unquoted code works too
#' mirtify({
#'   library(eRm)
#'   fit <- RM(raschdat1)
#'   pp <- person.parameter(fit)
#'   itemfit(pp)
#'   LRtest(fit)
#' })
#'
#' mirtify("mod <- irtQ::est_irt(data = resp, D = 1.702, model = '3PLM')")
#' @export
mirtify <- function(code, run = FALSE, notes = TRUE, file = NULL,
                    envir = parent.frame()) {
  input <- mirtify_input(substitute(code), parent.frame())
  ctx <- new.env(parent = emptyenv())
  ctx$objects <- list()
  ctx$packages <- character()
  ctx$library_done <- FALSE
  ctx$needs_library <- FALSE
  ctx$helpers <- character()
  ctx$envir <- envir

  steps <- lapply(seq_along(input$exprs), function(i) {
    translate_statement(input$exprs[[i]], input$text[[i]], ctx)
  })
  shown <- character()
  script_lines <- unlist(lapply(steps, function(s) {
    if (!length(s$code)) return(character())
    new_notes <- setdiff(s$notes, shown)
    shown <<- c(shown, new_notes)
    c(if (notes && length(new_notes)) comment_lines(new_notes), s$code)
  }))
  if (ctx$needs_library && !ctx$library_done) {
    script_lines <- c("library(mirtverse)", script_lines)
  }
  script <- paste(script_lines, collapse = "\n")

  out <- structure(list(
    script = script,
    steps = tibble::tibble(
      original = vapply(steps, `[[`, "", "original"),
      mirt = vapply(steps, function(s) paste(s$code, collapse = "\n"), ""),
      package = vapply(steps, `[[`, "", "package"),
      status = vapply(steps, `[[`, "", "status"),
      notes = lapply(steps, `[[`, "notes")
    ),
    env = NULL
  ), class = "mv_mirtify")

  if (!is.null(file)) {
    con <- file(file, open = "w", encoding = "UTF-8")
    on.exit(close(con), add = TRUE)
    writeLines(script, con)
  }
  if (isTRUE(run)) {
    env <- new.env(parent = envir)
    eval(parse(text = script, keep.source = FALSE), envir = env)
    out$env <- env
  }
  out
}

#' @export
print.mv_mirtify <- function(x, ...) {
  st <- x$steps
  src <- unique(st$package[!is.na(st$package) & nzchar(st$package)])
  n_tr <- sum(st$status %in% c("translated", "partial"))
  cat("mirtify: ", n_tr, " of ", nrow(st), " statements translated",
      if (length(src)) paste0(" from ", paste(src, collapse = ", ")), sep = "")
  n_part <- sum(st$status == "partial")
  n_no <- sum(st$status == "unsupported")
  if (n_part || n_no) {
    cat(" (", paste(c(if (n_part) paste(n_part, "with caveats"),
                      if (n_no) paste(n_no, "not translated")),
                    collapse = ", "), ")", sep = "")
  }
  cat("\n\n", x$script, "\n", sep = "")
  if (!is.null(x$env)) {
    cat("\nObjects created by the translated code:",
        paste(ls(x$env), collapse = ", "), "\n")
  }
  invisible(x)
}

#' @export
as.character.mv_mirtify <- function(x, ...) x$script

#' The ltm, eRm, TAM and irtQ to mirt crosswalk
#'
#' Lists the functions that [mirtify()] translates, with the mirt (or
#' mirtverse) code each one becomes and the main difference to keep in mind.
#'
#' @param package optional; one or more of `"ltm"`, `"eRm"`, `"TAM"` and
#'   `"irtQ"` to keep only those packages.
#' @return A tibble with columns `package`, `function`, `mirt` and `notes`.
#' @examples
#' mirtify_crosswalk("TAM")
#' @export
mirtify_crosswalk <- function(package = NULL) {
  cw <- crosswalk_table()
  if (!is.null(package)) {
    package <- match.arg(package, c("ltm", "eRm", "TAM", "irtQ"),
                         several.ok = TRUE)
    cw <- cw[cw$package %in% package, , drop = FALSE]
  }
  tibble::as_tibble(cw)
}

# ---------------------------------------------------------------------------
# Input handling

source_packages <- c("ltm", "eRm", "TAM", "irtQ")

mirtify_input <- function(expr, envir) {
  if (is.call(expr) && identical(expr[[1]], as.name("quote"))) {
    expr <- expr[[2]]
  } else if (is.name(expr) || (is.call(expr) && !is_code_call(expr))) {
    expr <- eval(expr, envir)
  }
  if (is.character(expr)) {
    if (length(expr) == 1L && !grepl("\n", expr) && grepl("\\.[Rr]$", expr) &&
        file.exists(expr)) {
      expr <- readLines(expr, warn = FALSE, encoding = "UTF-8")
    }
    parsed <- parse(text = expr, keep.source = TRUE)
    srcs <- attr(parsed, "srcref")
    text <- vapply(seq_along(parsed), function(i) {
      if (is.null(srcs)) deparse_one(parsed[[i]])
      else paste(as.character(srcs[[i]]), collapse = "\n")
    }, "")
    return(list(exprs = as.list(parsed), text = as.list(text)))
  }
  exprs <- if (is.expression(expr)) as.list(expr)
           else if (is.call(expr) && identical(expr[[1]], as.name("{"))) as.list(expr)[-1]
           else if (is.language(expr)) list(expr)
           else stop("`code` must be code, a character string or the path to an .R file.",
                     call. = FALSE)
  list(exprs = exprs, text = lapply(exprs, deparse_one))
}

is_code_call <- function(e) {
  fn <- call_fun(e)
  if (is.null(fn)) return(FALSE)
  if (!is.na(fn$pkg)) return(fn$pkg %in% source_packages)
  fn$fn %in% c("{", "<-", "=", "library", "require", "data") ||
    fn$fn %in% known_functions()
}

known_functions <- function() {
  unique(sub("^[^:]+::", "", names(mirtify_rules())))
}

call_fun <- function(e) {
  if (!is.call(e)) return(NULL)
  f <- e[[1]]
  if (is.name(f)) return(list(pkg = NA_character_, fn = as.character(f)))
  if (is.call(f) && as.character(f[[1]]) %in% c("::", ":::")) {
    return(list(pkg = as.character(f[[2]]), fn = as.character(f[[3]])))
  }
  NULL
}

# ---------------------------------------------------------------------------
# Statement translation

translate_statement <- function(e, text, ctx) {
  acc <- new.env(parent = emptyenv())
  acc$pre <- character(); acc$notes <- character()
  acc$status <- "unchanged"; acc$package <- ""
  acc$ctx <- ctx

  step <- function(code, status = acc$status) {
    list(original = text, code = code, package = acc$package,
         status = status, notes = unique(acc$notes))
  }

  # library() and require() calls
  lib <- library_call(e)
  if (!is.null(lib)) {
    if (lib %in% source_packages) {
      ctx$packages <- c(ctx$packages, lib)
      acc$package <- lib
      if (ctx$library_done) return(step(character(), "dropped"))
      ctx$library_done <- TRUE
      acc$notes <- "mirtverse loads mirt, so one library() call covers both."
      return(step("library(mirtverse)", "translated"))
    }
    if (lib %in% c("mirt", "mirtverse")) ctx$library_done <- TRUE
    return(step(text, "unchanged"))
  }

  # data() calls for example data sets of the source packages
  if (is.call(e) && identical(e[[1]], as.name("data"))) {
    res <- translate_data(e, ctx, acc)
    if (!is.null(res)) return(step(res))
    return(step(text, "unchanged"))
  }

  lhs <- NULL; rhs <- e; op <- NULL
  if (is.call(e) && as.character(e[[1]])[1] %in% c("<-", "=") && is.name(e[[2]])) {
    lhs <- as.character(e[[2]]); rhs <- e[[3]]; op <- as.character(e[[1]])
  }

  # whole statement is one known call: keep the translator's formatting
  top <- translate_call(rhs, ctx, acc, lhs)
  if (!is.null(top)) {
    if (!is.null(lhs)) {
      if (!is.null(top$register)) ctx$objects[[lhs]] <- top$register
      else ctx$objects[[lhs]] <- NULL
      forget_helpers(ctx, lhs)
    }
    if (identical(top$status, "unsupported")) {
      return(step(c(acc$pre, paste("#", strsplit(text, "\n")[[1]])), "unsupported"))
    }
    code <- if (is.null(lhs)) top$code else prefix_lines(paste(lhs, op, ""), top$code)
    return(step(c(acc$pre, code)))
  }

  # otherwise rewrite known calls and fields anywhere inside the statement
  changed <- FALSE
  new_rhs <- rewrite_expr(rhs, ctx, acc, function() changed <<- TRUE)
  if (!is.null(lhs)) {
    ctx$objects[[lhs]] <- NULL
    forget_helpers(ctx, lhs)
  }
  if (!changed) return(step(text, acc$status))
  new_e <- if (is.null(lhs)) new_rhs else {
    ee <- e; ee[[3]] <- new_rhs; ee
  }
  step(c(acc$pre, deparse_lines(new_e)))
}

library_call <- function(e) {
  if (!is.call(e)) return(NULL)
  fn <- call_fun(e)
  if (is.null(fn)) return(NULL)
  if (fn$fn %in% c("suppressMessages", "suppressPackageStartupMessages",
                   "suppressWarnings", "invisible") && length(e) > 1) {
    return(library_call(e[[2]]))
  }
  if (!fn$fn %in% c("library", "require") || length(e) < 2) return(NULL)
  arg <- e[[2]]
  if (is.name(arg)) return(as.character(arg))
  if (is.character(arg)) return(arg)
  NULL
}

translate_data <- function(e, ctx, acc) {
  args <- as.list(e)[-1]
  nms <- names(args) %or% rep("", length(args))
  sets <- vapply(args[nms == "" | nms == "list"], function(a) {
    if (is.name(a)) as.character(a) else if (is.character(a)) a else NA_character_
  }, "")
  if (!length(sets) || "package" %in% nms) return(NULL)
  if (identical(unname(sets), "LSAT") && "ltm" %in% ctx$packages) {
    acc$package <- "ltm"; acc$status <- "translated"
    ctx$needs_library <- TRUE
    acc$notes <- "ltm's LSAT data are mirt's LSAT6 table expanded to one row per person."
    return("LSAT <- expand.table(LSAT6)")
  }
  for (p in intersect(rev(ctx$packages), source_packages)) {
    if (!requireNamespace(p, quietly = TRUE)) next
    avail <- utils::data(package = p)$results[, "Item"]
    if (all(sets %in% sub(" .*", "", avail))) {
      acc$package <- p; acc$status <- "translated"
      acc$notes <- sprintf("The example data come from %s, so %s must stay installed to load them.",
                           p, p)
      return(deparse_one(as.call(c(as.list(e), package = p))))
    }
  }
  NULL
}

# Translate a single call if it is one mirtify knows. Returns NULL otherwise,
# or a list with `code` (character), `status` and optional `register`.
translate_call <- function(e, ctx, acc, lhs = NULL) {
  rule <- find_rule(e, ctx)
  if (is.null(rule)) return(NULL)
  a <- match_args(e, rule$stub, ctx)
  acc$package <- rule$package
  res <- rule$translate(a, ctx, acc, lhs %or% "fit")
  if (is.null(res)) return(NULL)
  res$status <- res$status %or% "translated"
  acc$status <- worst_status(acc$status, res$status)
  if (!identical(res$status, "unsupported")) ctx$needs_library <- TRUE
  res
}

worst_status <- function(a, b) {
  lv <- c("unchanged", "translated", "partial", "unsupported")
  lv[max(match(c(a, b), lv))]
}

rewrite_expr <- function(e, ctx, acc, mark) {
  if (!is.call(e)) return(e)
  # fields of fitted objects, e.g. fit$betapar
  if (identical(e[[1]], as.name("$")) && is.name(e[[2]])) {
    obj <- ctx$objects[[as.character(e[[2]])]]
    if (!is.null(obj)) {
      res <- translate_field(obj, as.character(e[[2]]), as.character(e[[3]]), ctx, acc)
      if (!is.null(res)) {
        mark()
        return(str2lang(res))
      }
    }
  }
  if (identical(e[[1]], as.name("$")) && is.call(e[[2]])) {
    inner <- call_fun(e[[2]])
    if (!is.null(inner) && inner$fn == "factor.scores" &&
        as.character(e[[3]]) == "score.dat") {
      return(rewrite_expr(e[[2]], ctx, acc, mark))
    }
  }
  res <- translate_call(e, ctx, acc)
  if (!is.null(res)) {
    mark()
    if (identical(res$status, "unsupported")) {
      acc$notes <- c(acc$notes, "This part has no mirt equivalent and was left as it was.")
      return(e)
    }
    return(str2lang(paste(res$code, collapse = "\n")))
  }
  for (i in seq_along(e)[-1]) {
    if (!is.null(e[[i]])) e[[i]] <- rewrite_expr(e[[i]], ctx, acc, mark)
  }
  e
}

find_rule <- function(e, ctx) {
  fn <- call_fun(e)
  if (is.null(fn)) return(NULL)
  rules <- mirtify_rules()
  first <- if (length(e) > 1) e[[2]] else NULL
  obj <- if (is.name(first)) ctx$objects[[as.character(first)]] else NULL

  # generics (summary, coef, plot, anova, print) on fitted objects
  if (is.na(fn$pkg) && fn$fn %in% names(generic_rules())) {
    if (is.null(obj)) return(NULL)
    g <- generic_rules()[[fn$fn]]
    return(list(package = obj$pkg, stub = g$stub,
                translate = function(a, ctx, acc, lhs) g$translate(a, obj, ctx, acc, lhs)))
  }
  if (!is.na(fn$pkg)) {
    if (!fn$pkg %in% source_packages) return(NULL)
    return(rules[[paste0(fn$pkg, "::", fn$fn)]])
  }
  cands <- source_packages[paste0(source_packages, "::", fn$fn) %in% names(rules)]
  if (!length(cands)) return(NULL)
  pkg <- if (!is.null(obj) && obj$pkg %in% cands) obj$pkg
         else if (length(intersect(rev(ctx$packages), cands)))
           intersect(rev(ctx$packages), cands)[1]
         else if (length(cands) == 1L && !exists(fn$fn, envir = asNamespace("mirt"),
                                                 inherits = FALSE) &&
                  !length(ctx$packages)) cands
         else NULL
  if (is.null(pkg)) return(NULL)
  rules[[paste0(pkg, "::", fn$fn)]]
}

match_args <- function(e, stub, ctx) {
  e2 <- e
  e2[[1]] <- as.name("f")
  mc <- tryCatch(match.call(stub, e2, expand.dots = FALSE), error = function(err) NULL)
  given <- if (is.null(mc)) list() else as.list(mc)[-1]
  list(given = given, stub = stub, envir = ctx$envir)
}

# argument expression (as given, or NULL)
ag <- function(a, name) a$given[[name]]

# argument as code text
at <- function(a, name, default = NULL) {
  x <- a$given[[name]]
  if (is.null(x)) return(default)
  deparse_one(x)
}

# argument value: evaluated when safe, otherwise the stub's default
av <- function(a, name) {
  x <- a$given[[name]]
  if (is.null(x)) {
    x <- formals(a$stub)[[name]]
    # choice vectors such as c("EB", "EAP") default to their first element
    if (is.call(x) && identical(x[[1]], as.name("c")) &&
        all(vapply(as.list(x)[-1], is.character, TRUE))) x <- x[[2]]
    if (is.symbol(x) && identical(as.character(x), "")) return(NULL)
  }
  safe_value(x, a$envir)
}

given <- function(a, name) !is.null(a$given[[name]])

safe_fns <- c("c", "rep", "seq", "seq_len", "seq_along", ":", "-", "+", "*", "/",
              "^", "(", "list", "cbind", "rbind", "matrix", "ncol", "nrow",
              "length", "[", "[[", "$", "names", "colnames", "which", "%in%",
              "==", "!=", ">", "<", "TRUE", "FALSE", "toupper", "as.numeric",
              "as.integer", "as.character", "paste", "paste0", "rep_len")

safe_value <- function(x, envir) {
  ok <- function(z) {
    if (is.call(z)) {
      f <- z[[1]]
      if (!is.name(f) || !as.character(f) %in% safe_fns) return(FALSE)
      all(vapply(as.list(z)[-1], function(y) is.null(y) || ok(y), TRUE))
    } else TRUE
  }
  if (is.null(x)) return(NULL)
  if (!is.language(x)) return(x)
  if (!ok(x)) return(NULL)
  tryCatch(eval(x, envir), error = function(err) NULL)
}

# number of items and categories of a data argument, when it can be found
data_info <- function(expr, envir) {
  if (is.null(expr)) return(NULL)
  d <- safe_value(expr, envir)
  if (!(is.data.frame(d) || is.matrix(d))) return(NULL)
  ncat <- vapply(seq_len(ncol(d)), function(j) {
    length(unique(stats::na.omit(as.vector(d[, j]))))
  }, 1)
  list(J = ncol(d), ncat = ncat, poly = any(ncat > 2))
}

# ---------------------------------------------------------------------------
# Code builders

deparse_one <- function(e) paste(trimws(deparse(e, width.cutoff = 500L)), collapse = " ")

deparse_lines <- function(e) deparse(e, width.cutoff = 75L)

fcall <- function(fn, args = list(), width = 64) {
  args <- Filter(Negate(is.null), args)
  nm <- names(args) %or% rep("", length(args))
  parts <- ifelse(nm == "", unlist(args), paste(nm, "=", unlist(args)))
  one <- paste0(fn, "(", paste(parts, collapse = ", "), ")")
  if (nchar(one) <= width || length(parts) < 2) return(one)
  # fill each line greedily, continuation lines indented under the first argument
  ind <- strrep(" ", nchar(fn) + 1)
  lines <- paste0(fn, "(", parts[1])
  for (p in parts[-1]) {
    cur <- lines[length(lines)]
    if (nchar(cur) + nchar(p) + 2 <= width) lines[length(lines)] <- paste0(cur, ", ", p)
    else {
      lines[length(lines)] <- paste0(cur, ",")
      lines <- c(lines, paste0(ind, p))
    }
  }
  lines[length(lines)] <- paste0(lines[length(lines)], ")")
  paste(lines, collapse = "\n")
}

comment_lines <- function(x) {
  unlist(lapply(x, function(n) paste("#", strwrap(n, width = 76))))
}

prefix_lines <- function(prefix, code) {
  lines <- strsplit(paste(code, collapse = "\n"), "\n")[[1]]
  pad <- strrep(" ", nchar(prefix))
  c(paste0(prefix, lines[1]), if (length(lines) > 1) paste0(pad, lines[-1]))
}

q <- function(x) paste0('"', x, '"')

# item index vector -> "1-3, 5"
item_ranges <- function(idx) {
  idx <- sort(unique(idx))
  runs <- split(idx, cumsum(c(1, diff(idx) != 1)))
  paste(vapply(runs, function(r) {
    if (length(r) == 1) as.character(r) else paste0(r[1], "-", r[length(r)])
  }, ""), collapse = ", ")
}

# Writes `name <- mirt.model(...)` into acc$pre. `lines` may contain "{J}"
# for the number of items; when J is unknown it is computed with ncol(data).
add_model <- function(acc, name, lines, J, data) {
  prefix <- paste0(name, " <- mirt.model(")
  if (!is.null(J)) {
    body <- gsub("{J}", J, lines, fixed = TRUE)
    txt <- paste0('"', paste(body, collapse = "\n"), '"')
    code <- prefix_lines(prefix, txt)
    code[-1] <- paste0(" ", code[-1])
  } else {
    body <- gsub("{J}", "%1$d", lines, fixed = TRUE)
    txt <- paste0('sprintf("', paste(body, collapse = "\n"), '", ncol(', data, "))")
    code <- prefix_lines(prefix, txt)
    # continuation lines of the string sit under the opening quote
    code[-1] <- paste0(strrep(" ", nchar("sprintf(\"")), code[-1])
  }
  code[length(code)] <- paste0(code[length(code)], ")")
  acc$pre <- c(acc$pre, code)
  name
}

compress_itemtypes <- function(types) {
  if (length(unique(types)) == 1L) return(q(types[1]))
  r <- rle(types)
  parts <- ifelse(r$lengths == 1, q(r$values), paste0("rep(", q(r$values), ", ", r$lengths, ")"))
  paste0("c(", paste(parts, collapse = ", "), ")")
}

model_name <- function(lhs, suffix) paste0(lhs, "_", suffix)

# Adds a helper assignment (such as fit_b <- ...) once per script; it is
# written again only after the object it depends on is reassigned.
add_helper <- function(acc, name, code) {
  ctx <- acc$ctx
  if (!is.null(ctx) && name %in% ctx$helpers) return(invisible(name))
  acc$pre <- c(acc$pre, code)
  if (!is.null(ctx)) ctx$helpers <- c(ctx$helpers, name)
  invisible(name)
}

forget_helpers <- function(ctx, lhs) {
  ctx$helpers <- ctx$helpers[!startsWith(ctx$helpers, paste0(lhs, "_")) &
                               ctx$helpers != lhs]
}

note <- function(acc, ...) acc$notes <- c(acc$notes, paste0(...))

register_model <- function(pkg, data, itemtype, ...) {
  list(pkg = pkg, kind = "model", data = data, itemtype = itemtype, ...)
}

fit_of <- function(a, obj_name, ctx) {
  # the mirt model behind an argument: a model, or a scores object from it
  x <- ag(a, obj_name)
  if (!is.name(x)) {
    if (is.call(x) && identical(x[[1]], as.name("$")) && is.name(x[[2]])) x <- x[[2]]
    else return(NULL)
  }
  nm <- as.character(x)
  obj <- ctx$objects[[nm]]
  if (is.null(obj)) return(list(name = nm, obj = NULL))
  if (obj$kind != "model" && !is.null(obj$model)) {
    return(list(name = obj$model, obj = ctx$objects[[obj$model]] %or% obj))
  }
  list(name = nm, obj = obj)
}

needs_fit <- function(f, acc, what) {
  if (is.null(f)) {
    note(acc, what, " needs a fitted model object; pass the model by name.")
    return(FALSE)
  }
  if (is.null(f$obj)) {
    note(acc, "'", f$name, "' was not created in this code, so it is assumed to be a mirt model.")
  }
  TRUE
}

score_method <- function(m) {
  map <- c(EB = "MAP", MAP = "MAP", EAP = "EAP", ML = "ML", MLE = "ML",
           MLF = "ML", WL = "WLE", WLE = "WLE", EAP.SUM = "EAPsum")
  unname(map[toupper(m)] %or% map[m])
}

`%or%` <- function(a, b) {
  if (is.null(a) || length(a) == 0 || (is.atomic(a) && length(a) == 1 && is.na(a))) b else a
}

# ---------------------------------------------------------------------------
# Rules: one per source function

mirtify_rules <- function() {
  if (!is.null(.mirtify_cache$rules)) return(.mirtify_cache$rules)
  rules <- c(ltm_rules(), erm_rules(), tam_rules(), irtq_rules())
  .mirtify_cache$rules <- rules
  rules
}

.mirtify_cache <- new.env(parent = emptyenv())

rule <- function(package, stub, translate) {
  list(package = package, stub = stub, translate = translate)
}

quad_note_ltm <- paste("ltm integrates over 21 Gauss-Hermite points and mirt over",
                       "61 points, so estimates can differ slightly (usually in the",
                       "second or third decimal).")

# ---- ltm ------------------------------------------------------------------

ltm_rules <- function() {
  list(
    "ltm::rasch" = rule("ltm",
      function(data, constraint = NULL, IRT.param = TRUE, start.val = NULL,
               na.action = NULL, control = list(), Hessian = TRUE) NULL,
      function(a, ctx, acc, lhs) {
        data <- at(a, "data"); info <- data_info(ag(a, "data"), a$envir)
        fixed <- ltm_fixed_slope(a, info)
        mname <- model_name(lhs, "model")
        if (!is.null(fixed)) {
          add_model(acc, mname, c("F = 1-{J}", paste0("START = (1-{J}, a1, ", fixed, ")"),
                                  "FIXED = (1-{J}, a1)"), info$J, data)
          note(acc, "The constraint fixes every discrimination at ", fixed,
               ", which the START and FIXED lines reproduce. (mirt's itemtype = \"Rasch\" ",
               "fixes the slopes at 1 but frees the latent variance instead.)")
        } else {
          add_model(acc, mname, c("F = 1-{J}", "CONSTRAIN = (1-{J}, a1)"), info$J, data)
          note(acc, "ltm::rasch() estimates one common discrimination for all items; ",
               "the CONSTRAIN line does the same in mirt.")
          if (given(a, "constraint")) {
            note(acc, "Constraints on single item parameters were not translated; ",
                 "add START and FIXED lines to the model for them.")
            acc$status <- "partial"
          }
        }
        if (isFALSE(av(a, "IRT.param"))) {
          note(acc, "With IRT.param = FALSE ltm reports intercepts; mirt's coef(fit) ",
               "without IRTpars = TRUE shows the same intercept form (d).")
        }
        note(acc, quad_note_ltm)
        list(code = fcall("mirt", list(data, mname, itemtype = q("2PL"),
                                       SE = if (!isFALSE(av(a, "Hessian"))) "TRUE")),
             register = register_model("ltm", data, "2PL", J = info$J),
             status = if (given(a, "constraint") && is.null(fixed)) "partial")
      }),

    "ltm::ltm" = rule("ltm",
      function(formula, constraint = NULL, IRT.param, start.val = NULL,
               na.action = NULL, control = list()) NULL,
      function(a, ctx, acc, lhs) {
        f <- ag(a, "formula")
        if (!inherits(f, "formula") && !(is.call(f) && identical(f[[1]], as.name("~")))) {
          return(NULL)
        }
        data <- deparse_one(f[[2]])
        info <- data_info(f[[2]], a$envir)
        rhs <- f[[3]]
        tl <- attr(stats::terms(stats::as.formula(call("~", rhs))), "term.labels")
        z <- sort(unique(all.vars(rhs)))
        nfact <- length(z)
        status <- NULL
        extra <- setdiff(tl, z)
        if (length(extra)) {
          fac <- setNames(paste0("F", seq_along(z)), z)
          lines <- c(paste0(fac, " = 1-{J}"))
          for (t in extra) {
            vars <- all.vars(str2lang(t))
            if (grepl("^I\\(", t)) vars <- rep(vars, 2)
            lines <- c(lines, paste0("(", paste(fac[vars], collapse = "*"), ") = 1-{J}"))
          }
          mname <- add_model(acc, model_name(lhs, "model"), lines, info$J, data)
          note(acc, "Interaction and quadratic terms become product terms such as (F1*F2) ",
               "in the mirt model.")
          code <- fcall("mirt", list(data, mname, itemtype = q("2PL"), SE = "TRUE"))
        } else {
          code <- fcall("mirt", list(data, as.character(nfact), itemtype = q("2PL"),
                                     SE = "TRUE"))
        }
        if (nfact > 1) {
          note(acc, "ltm reports the unrotated two-factor solution; use ",
               "summary(", lhs, ", rotate = \"none\") in mirt to compare.")
        }
        if (given(a, "constraint")) {
          note(acc, "The constraint argument was not translated; add START and FIXED ",
               "lines to a mirt.model() for it.")
          status <- "partial"
        }
        note(acc, quad_note_ltm)
        list(code = code, register = register_model("ltm", data, "2PL", J = info$J,
                                                    nfact = nfact),
             status = status)
      }),

    "ltm::tpm" = rule("ltm",
      function(data, type = c("latent.trait", "rasch"), constraint = NULL,
               max.guessing = 1, IRT.param = TRUE, start.val = NULL,
               na.action = NULL, control = list()) NULL,
      function(a, ctx, acc, lhs) {
        data <- at(a, "data"); info <- data_info(ag(a, "data"), a$envir)
        status <- NULL
        model <- "1"
        if (identical(av(a, "type"), "rasch")) {
          model <- add_model(acc, model_name(lhs, "model"),
                             c("F = 1-{J}", "CONSTRAIN = (1-{J}, a1)"), info$J, data)
          note(acc, "type = \"rasch\" uses one common discrimination; the CONSTRAIN line ",
               "does the same in mirt.")
        }
        mg <- av(a, "max.guessing")
        if (!is.null(mg) && mg < 1) {
          note(acc, "mirt has no upper bound for guessing like max.guessing; a prior such as ",
               "PRIOR = (1-J, g, expbeta, 5, 17) in mirt.model() keeps guessing small.")
          status <- "partial"
        }
        if (given(a, "constraint")) {
          note(acc, "The constraint argument was not translated.")
          status <- "partial"
        }
        note(acc, quad_note_ltm)
        list(code = fcall("mirt", list(data, model, itemtype = q("3PL"), SE = "TRUE")),
             register = register_model("ltm", data, "3PL", J = info$J), status = status)
      }),

    "ltm::grm" = rule("ltm",
      function(data, constrained = FALSE, IRT.param = TRUE, Hessian = FALSE,
               start.val = NULL, na.action = NULL, control = list()) NULL,
      function(a, ctx, acc, lhs) {
        data <- at(a, "data"); info <- data_info(ag(a, "data"), a$envir)
        model <- "1"
        if (isTRUE(av(a, "constrained"))) {
          model <- add_model(acc, model_name(lhs, "model"),
                             c("F = 1-{J}", "CONSTRAIN = (1-{J}, a1)"), info$J, data)
          note(acc, "constrained = TRUE gives every item the same discrimination; the ",
               "CONSTRAIN line does the same in mirt.")
        }
        note(acc, "ltm's Extrmt thresholds match the b1, b2, ... columns of ",
             "coef(", lhs, ", IRTpars = TRUE).")
        note(acc, quad_note_ltm)
        list(code = fcall("mirt", list(data, model, itemtype = q("graded"),
                                       SE = if (isTRUE(av(a, "Hessian"))) "TRUE")),
             register = register_model("ltm", data, "graded", J = info$J))
      }),

    "ltm::gpcm" = rule("ltm",
      function(data, constraint = c("gpcm", "1PL", "rasch"), IRT.param = TRUE,
               start.val = NULL, na.action = NULL, control = list()) NULL,
      function(a, ctx, acc, lhs) {
        data <- at(a, "data"); info <- data_info(ag(a, "data"), a$envir)
        con <- av(a, "constraint") %or% "gpcm"
        model <- "1"
        if (identical(con, "1PL")) {
          model <- add_model(acc, model_name(lhs, "model"),
                             c("F = 1-{J}", "CONSTRAIN = (1-{J}, a1)"), info$J, data)
          note(acc, "constraint = \"1PL\" gives every item the same discrimination; the ",
               "CONSTRAIN line does the same in mirt.")
        } else if (identical(con, "rasch")) {
          model <- add_model(acc, model_name(lhs, "model"),
                             c("F = 1-{J}", "START = (1-{J}, a1, 1)", "FIXED = (1-{J}, a1)"),
                             info$J, data)
          note(acc, "constraint = \"rasch\" fixes every discrimination at 1, which the ",
               "START and FIXED lines reproduce.")
        }
        note(acc, quad_note_ltm)
        list(code = fcall("mirt", list(data, model, itemtype = q("gpcm"), SE = "TRUE")),
             register = register_model("ltm", data, "gpcm", J = info$J))
      }),

    "ltm::factor.scores" = rule("ltm",
      function(object, resp.patterns = NULL, method = c("EB", "EAP", "MI", "Component"),
               B = 5, robust.se = FALSE, prior = TRUE, return.MIvalues = FALSE, ...) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "object", ctx)
        if (!needs_fit(f, acc, "factor.scores()")) return(NULL)
        m <- av(a, "method") %or% "EB"
        status <- NULL
        meth <- switch(m, EB = "MAP", EAP = "EAP", {
          note(acc, "method = \"", m, "\" has no mirt equivalent; empirical Bayes (MAP) ",
               "scores are used instead.")
          status <- "partial"; "MAP"
        })
        if (m == "EB") note(acc, "ltm's empirical Bayes scores are the posterior modes, ",
                            "which mirt calls MAP.")
        args <- list(f$name, method = q(meth))
        if (given(a, "resp.patterns")) {
          args$response.pattern <- at(a, "resp.patterns")
        } else {
          args$full.scores <- "FALSE"
          note(acc, "Like ltm, full.scores = FALSE returns one row per observed response ",
               "pattern; drop it to get one score per person.")
        }
        list(code = fcall("fscores", args), status = status,
             register = list(pkg = "ltm", kind = "scores", model = f$name))
      }),

    "ltm::item.fit" = rule("ltm",
      function(object, G = 10, FUN = median, simulate.p.value = FALSE, B = 100) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "object", ctx)
        if (!needs_fit(f, acc, "item.fit()")) return(NULL)
        note(acc, "Both use Yen's Q1-type chi-square with 10 ability groups, but the groups ",
             "are formed differently, so the statistics differ a little. ",
             "fit_stats = \"S_X2\" is usually preferred in mirt.")
        list(code = fcall("itemfit", list(f$name, fit_stats = q("X2"),
                                          group.bins = at(a, "G"))))
      }),

    "ltm::person.fit" = rule("ltm",
      function(object, alternative = c("less", "greater", "two.sided"),
               resp.patterns = NULL, FUN = NULL, simulate.p.value = FALSE,
               B = 1000) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "object", ctx)
        if (!needs_fit(f, acc, "person.fit()")) return(NULL)
        note(acc, "ltm's Lz statistic is mirt's Zh. ltm reports one row per response ",
             "pattern, mirt one row per person.")
        list(code = fcall("personfit", list(f$name)))
      }),

    "ltm::information" = rule("ltm",
      function(object, range, items = NULL, ...) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "object", ctx)
        if (!needs_fit(f, acc, "information()")) return(NULL)
        list(code = fcall("areainfo", list(f$name, theta_lim = at(a, "range"),
                                           which.items = at(a, "items"))))
      }),

    "ltm::descript" = rule("ltm",
      function(data, n.print = 10, chi.squared = TRUE, B = 1000) NULL,
      function(a, ctx, acc, lhs) {
        note(acc, "itemstats() gives proportions, item-total correlations and alpha ",
             "if item deleted.")
        list(code = fcall("itemstats", list(at(a, "data"))))
      }),

    "ltm::unidimTest" = rule("ltm",
      function(object, data, thetas, IRT = TRUE, z.vals = NULL, B = 100, ...) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "object", ctx)
        if (!needs_fit(f, acc, "unidimTest()")) return(NULL)
        note(acc, "mirt has no modified parallel analysis. M2() tests overall fit; ",
             "residuals(", f$name, ", type = \"Q3\") and gg_q3() show local dependence.")
        list(code = fcall("M2", list(f$name)), status = "partial")
      }),

    "ltm::margins" = rule("ltm",
      function(object, type = c("two-way", "three-way"), rule = 3.5, nprint = 3, ...) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "object", ctx)
        if (!needs_fit(f, acc, "margins()")) return(NULL)
        note(acc, "The LD residuals are signed chi-square statistics for every item pair, ",
             "like ltm's two-way margins.")
        list(code = fcall("residuals", list(f$name, type = q("LD"))))
      })
  )
}

ltm_fixed_slope <- function(a, info) {
  con <- ag(a, "constraint")
  if (is.null(con)) return(NULL)
  val <- safe_value(con, a$envir)
  if (is.matrix(val) && ncol(val) == 2 && !is.null(info$J) && any(val[, 1] == info$J + 1)) {
    return(val[val[, 1] == info$J + 1, 2][1])
  }
  txt <- deparse_one(con)
  m <- regmatches(txt, regexec("^cbind\\((.*)\\+ *1, *([-0-9.]+)\\)$", txt))[[1]]
  if (length(m) == 3) return(as.numeric(m[3]))
  NULL
}

# ---- eRm ------------------------------------------------------------------

erm_fit_note <- function(acc) {
  note(acc, "eRm uses conditional maximum likelihood (CML); mirt uses marginal maximum ",
       "likelihood with a normal latent trait, so estimates are close but not identical.")
  note(acc, "eRm reports item easiness (beta = -difficulty) centred to sum to zero; ",
       "coef() and summary() below convert mirt's difficulties to the same form.")
}

erm_model_rule <- function(itemtype, label) {
  rule("eRm",
    function(X, W, se = TRUE, sum0 = TRUE, etaStart) NULL,
    function(a, ctx, acc, lhs) {
      data <- at(a, "X")
      if (given(a, "W")) note(acc, "The W design matrix is ignored for ", label, "().")
      erm_fit_note(acc)
      if (itemtype == "rsm") {
        note(acc, "mirt's rating scale model needs every item to have the same number ",
             "of categories, as in eRm.")
      }
      list(code = fcall("mirt", list(data, "1", itemtype = q(itemtype),
                                     SE = if (!isFALSE(av(a, "se"))) "TRUE")),
           register = register_model("eRm", data, itemtype, erm = label,
                                     sum0 = !isFALSE(av(a, "sum0"))))
    })
}

erm_unsupported_rule <- function(label) {
  rule("eRm",
    function(X, W, mpoints = 1, groupvec = 1, se = TRUE, sum0 = TRUE, etaStart) NULL,
    function(a, ctx, acc, lhs) {
      note(acc, label, "() for repeated measurements has no single-call mirt translation; ",
           "see mirt::mixedmirt() for linear item designs.")
      list(code = character(), status = "unsupported")
    })
}

erm_rules <- function() {
  list(
    "eRm::RM" = erm_model_rule("Rasch", "RM"),
    "eRm::PCM" = erm_model_rule("Rasch", "PCM"),
    "eRm::RSM" = erm_model_rule("rsm", "RSM"),

    "eRm::LLTM" = rule("eRm",
      function(X, W, mpoints = 1, groupvec = 1, se = TRUE, sum0 = TRUE, etaStart) NULL,
      function(a, ctx, acc, lhs) {
        if (!identical(av(a, "mpoints"), 1) || !identical(av(a, "groupvec"), 1)) {
          note(acc, "LLTM() with mpoints or groupvec has no single-call mirt translation; ",
               "see mirt::mixedmirt().")
          return(list(code = character(), status = "unsupported"))
        }
        if (!given(a, "W")) {
          note(acc, "LLTM() needs the design matrix W.")
          return(list(code = character(), status = "unsupported"))
        }
        data <- at(a, "X")
        dname <- model_name(lhs, "design")
        acc$pre <- c(acc$pre, paste0(dname, " <- as.data.frame(", at(a, "W"), ")"))
        note(acc, "mirt decomposes the item intercepts (easiness) with item.formula, so the ",
             "basic parameters have the opposite sign of eRm's eta.")
        erm_fit_note(acc)
        list(code = fcall("mirt", list(data, "1", itemtype = q("Rasch"),
                                       itemdesign = dname,
                                       item.formula = paste0("reformulate(c(\"0\", names(",
                                                             dname, ")))"),
                                       SE = "TRUE")),
             register = register_model("eRm", data, "Rasch", erm = "LLTM", sum0 = TRUE))
      }),

    "eRm::LRSM" = erm_unsupported_rule("LRSM"),
    "eRm::LPCM" = erm_unsupported_rule("LPCM"),

    "eRm::person.parameter" = rule("eRm",
      function(object) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "object", ctx)
        if (!needs_fit(f, acc, "person.parameter()")) return(NULL)
        note(acc, "eRm's person parameters are maximum likelihood estimates. For ",
             "all-correct or all-wrong patterns mirt returns -Inf or Inf where eRm ",
             "extrapolates; method = \"WLE\" gives finite values for everyone.")
        list(code = fcall("fscores", list(f$name, method = q("ML"),
                                          full.scores.SE = "TRUE")),
             register = list(pkg = "eRm", kind = "scores", model = f$name))
      }),

    "eRm::itemfit" = rule("eRm",
      function(object) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "object", ctx)
        if (!needs_fit(f, acc, "itemfit()")) return(NULL)
        note(acc, "mirt's infit and outfit mean squares use EAP person estimates while eRm ",
             "uses ML estimates, so values differ a little.")
        list(code = fcall("itemfit", list(f$name, fit_stats = q("infit"))))
      }),

    "eRm::personfit" = rule("eRm",
      function(object) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "object", ctx)
        if (!needs_fit(f, acc, "personfit()")) return(NULL)
        note(acc, "personfit() reports infit and outfit for each person, plus the Zh statistic.")
        list(code = fcall("personfit", list(f$name)))
      }),

    "eRm::LRtest" = rule("eRm",
      function(object, splitcr = "median", se = TRUE) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "object", ctx)
        if (!needs_fit(f, acc, "LRtest()")) return(NULL)
        data <- f$obj$data %or% paste0("extract.mirt(", f$name, ", \"data\")")
        itype <- f$obj$itemtype %or% "Rasch"
        split <- erm_split(a, data, acc, f$name)
        if (is.null(split)) return(NULL)
        g <- model_name(f$name, "split")
        add_helper(acc, g, paste(g, "<-", split))
        acc$pre <- c(acc$pre,
          prefix_lines(paste0(model_name(f$name, "free"), " <- "),
                       fcall("multipleGroup", list(data, "1", group = g,
                                                   itemtype = q(itype)))),
          prefix_lines(paste0(model_name(f$name, "equal"), " <- "),
                       fcall("multipleGroup", list(data, "1", group = g,
                                                   itemtype = q(itype),
                                                   invariance = 'c("slopes", "intercepts", "free_means", "free_var")'))))
        note(acc, "Andersen's test compares item parameters across score groups. Here the ",
             "same comparison is a likelihood-ratio test between a model with equal item ",
             "parameters in both groups and one with separate parameters. It uses marginal ",
             "rather than conditional likelihood, so the statistic differs from eRm's.")
        list(code = fcall("anova", list(model_name(f$name, "equal"),
                                        model_name(f$name, "free"))))
      }),

    "eRm::Waldtest" = rule("eRm",
      function(object, splitcr = "median") NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "object", ctx)
        if (!needs_fit(f, acc, "Waldtest()")) return(NULL)
        data <- f$obj$data %or% paste0("extract.mirt(", f$name, ", \"data\")")
        split <- erm_split(a, data, acc, f$name)
        if (is.null(split)) return(NULL)
        g <- model_name(f$name, "split")
        add_helper(acc, g, paste(g, "<-", split))
        note(acc, "dif() runs a likelihood-ratio test for each item in place of eRm's Wald ",
             "z tests; both flag items whose difficulty differs between the score groups.")
        list(code = fcall("dif", list(data, group = g, model = q(f$obj$itemtype %or% "Rasch"))),
             status = "partial")
      }),

    "eRm::plotPImap" = rule("eRm",
      function(object, item.subset = "all", sorted = FALSE, ...) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "object", ctx)
        if (!needs_fit(f, acc, "plotPImap()")) return(NULL)
        note(acc, "gg_wright() draws the person-item map with ggplot2.")
        list(code = fcall("gg_wright", list(f$name)))
      }),

    "eRm::plotICC" = rule("eRm",
      function(object, item.subset = "all", ...) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "object", ctx)
        if (!needs_fit(f, acc, "plotICC()")) return(NULL)
        items <- if (given(a, "item.subset") && !identical(av(a, "item.subset"), "all"))
          at(a, "item.subset")
        list(code = fcall("gg_trace", list(f$name, which.items = items)))
      }),

    "eRm::plotjointICC" = rule("eRm",
      function(object, item.subset = "all", ...) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "object", ctx)
        if (!needs_fit(f, acc, "plotjointICC()")) return(NULL)
        list(code = fcall("gg_trace", list(f$name, facet = "FALSE")))
      }),

    "eRm::thresholds" = rule("eRm",
      function(object) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "object", ctx)
        if (!needs_fit(f, acc, "thresholds()")) return(NULL)
        note(acc, "The b columns are the threshold locations. mirt centres the persons at 0 ",
             "while eRm centres the items, so subtract the mean threshold to compare.")
        list(code = paste0(fcall("coef", list(f$name, IRTpars = "TRUE",
                                              simplify = "TRUE")), "$items"))
      }),

    "eRm::IC" = rule("eRm",
      function(ppobj) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "ppobj", ctx)
        if (!needs_fit(f, acc, "IC()")) return(NULL)
        note(acc, "glance() reports the marginal log-likelihood, AIC and BIC; eRm's joint ",
             "and conditional versions have no mirt equivalent.")
        list(code = fcall("glance", list(f$name)))
      }),

    "eRm::NPtest" = rule("eRm",
      function(obj, n = NULL, method = "T1", ...) NULL,
      function(a, ctx, acc, lhs) {
        note(acc, "eRm's nonparametric tests have no mirt equivalent.")
        list(code = character(), status = "unsupported")
      })
  )
}

erm_split <- function(a, data, acc, base) {
  sp <- ag(a, "splitcr")
  spv <- av(a, "splitcr") %or% "median"
  if (identical(spv, "all.r")) {
    note(acc, "splitcr = \"all.r\" (one group per raw score) was not translated.")
    return(NULL)
  }
  if (is.null(sp) || identical(spv, "median") || identical(spv, "mean")) {
    score <- model_name(base, "score")
    add_helper(acc, score, paste0(score, " <- rowSums(", data, ", na.rm = TRUE)"))
    fun <- if (identical(spv, "mean")) "mean" else "median"
    return(sprintf('ifelse(%s > %s(%s), "high", "low")', score, fun, score))
  }
  paste0("factor(", deparse_one(sp), ")")
}

# ---- TAM ------------------------------------------------------------------

tam_mml_stub <- function(resp, Y = NULL, group = NULL, irtmodel = "1PL", formulaY = NULL,
                         dataY = NULL, ndim = 1, pid = NULL, xsi.fixed = NULL,
                         xsi.inits = NULL, beta.fixed = NULL, beta.inits = NULL,
                         variance.fixed = NULL, variance.inits = NULL, est.variance = TRUE,
                         constraint = "cases", A = NULL, B = NULL, B.fixed = NULL, Q = NULL,
                         est.slopegroups = NULL, E = NULL, pweights = NULL,
                         userfct.variance = NULL, variance.Npars = NULL, item.elim = TRUE,
                         verbose = TRUE, control = list(), ...) NULL

tam_translate <- function(a, ctx, acc, lhs, family) {
  data <- at(a, "resp"); info <- data_info(ag(a, "resp"), a$envir)
  irt <- av(a, "irtmodel") %or% if (family == "2pl") "2PL" else "1PL"
  status <- NULL
  itemtype <- switch(family,
    "1pl" = switch(irt, "1PL" = , "PCM" = , "PCM2" = "Rasch", "RSM" = "rsm", NULL),
    "2pl" = switch(irt,
      "2PL" = if (isTRUE(info$poly)) "gpcm" else "2PL",
      "GPCM" = "gpcm", "2PL.groups" = , "GPCM.groups" = , "GPCM.design" = {
        note(acc, "irtmodel = \"", irt, "\" (slopes shared within groups of items) was ",
             "translated as a model with a free slope for every item; add CONSTRAIN lines ",
             "to a mirt.model() for the slope groups.")
        status <- "partial"
        if (isTRUE(info$poly)) "gpcm" else "2PL"
      }, NULL),
    "3pl" = {
      if (given(a, "est.guess")) "3PL" else "2PL"
    })
  if (is.null(itemtype)) {
    note(acc, "irtmodel = \"", irt, "\" has no direct mirt translation.")
    return(list(code = character(), status = "unsupported"))
  }
  if (family == "1pl") {
    if (irt == "PCM2") note(acc, "PCM2 is a reparameterization of the partial credit model, ",
                             "so it fits the same model as itemtype = \"Rasch\".")
    note(acc, "Like TAM, itemtype = \"Rasch\" fixes the slopes at 1, sets the latent mean ",
         "to 0 and estimates the latent variance.")
    if (isFALSE(av(a, "est.variance"))) {
      note(acc, "est.variance = FALSE (variance fixed at 1) was not translated; mirt's ",
           "Rasch model estimates the variance.")
      status <- "partial"
    }
  } else if (family == "2pl") {
    if (irt == "2PL" && is.null(info)) {
      note(acc, "For polytomous items use itemtype = \"gpcm\", which is what TAM fits for them.")
    }
    note(acc, "As in TAM, the latent variance is fixed at 1 and every item has its own slope.")
  } else {
    if (given(a, "est.guess")) {
      note(acc, "est.guess groups guessing parameters in TAM; mirt estimates one guessing ",
           "parameter for each item. Use a mirt.model() with CONSTRAIN lines to share them.")
    } else {
      note(acc, "Without est.guess, tam.mml.3pl() estimates no guessing parameters, so this ",
           "is a 2PL model.")
    }
  }
  if (identical(av(a, "constraint"), "items")) {
    note(acc, "constraint = \"items\" centres the item difficulties at 0; mirt centres the ",
         "persons instead, so subtract the mean difficulty to compare.")
  }
  for (arg in c("xsi.fixed", "beta.fixed", "variance.fixed", "A", "B", "B.fixed", "E",
                "xsi.prior", "gammaslope.des", "guess.prior")) {
    if (given(a, arg)) {
      note(acc, "The ", arg, " argument was not translated.")
      status <- "partial"
    }
  }
  if (given(a, "ndim") && !given(a, "Q")) {
    note(acc, "ndim without a Q matrix was ignored; give TAM's Q matrix to fit a ",
         "multidimensional model.")
  }

  model <- "1"
  if (given(a, "Q")) {
    model <- model_name(lhs, "model")
    acc$pre <- c(acc$pre, paste0(model, " <- mirt.model(", at(a, "Q"),
                                 ", COV = upper.tri(diag(ncol(", at(a, "Q"), "))))"))
    note(acc, "mirt.model() builds the same between-item structure from TAM's Q matrix, ",
         "with correlated dimensions.")
  }
  args <- list(data, model, itemtype = q(itemtype))
  if (given(a, "Y") || given(a, "dataY")) {
    cv <- model_name(lhs, "covdata")
    src <- if (given(a, "dataY")) at(a, "dataY") else at(a, "Y")
    acc$pre <- c(acc$pre, paste0(cv, " <- as.data.frame(", src, ")"))
    args$covdata <- cv
    args$formula <- if (given(a, "formulaY")) at(a, "formulaY")
                    else paste0("reformulate(names(", cv, "))")
    note(acc, "The latent regression on Y uses mirt's covdata and formula arguments.")
  }
  if (given(a, "pweights")) args$survey.weights <- at(a, "pweights")
  args$SE <- "TRUE"
  note(acc, "TAM integrates over 21 nodes from -6 to 6 and mirt over 61 points, so ",
       "estimates can differ slightly.")

  if (given(a, "group")) {
    note(acc, "With group, TAM keeps item parameters equal across groups and estimates a ",
         "mean and variance for each group; multipleGroup() with this invariance does the same.")
    args <- c(args[1:2], list(group = at(a, "group")), args[-(1:2)])
    args$invariance <- 'c("slopes", "intercepts", "free_means", "free_var")'
    code <- fcall("multipleGroup", args)
  } else {
    code <- fcall("mirt", args)
  }
  list(code = code, status = status,
       register = register_model("TAM", data, itemtype, poly = info$poly))
}

tam_rules <- function() {
  tam_2pl_stub <- tam_mml_stub
  formals(tam_2pl_stub)$irtmodel <- "2PL"
  tam_3pl_stub <- function(resp, Y = NULL, group = NULL, formulaY = NULL, dataY = NULL,
                           ndim = 1, pid = NULL, xsi.fixed = NULL, xsi.inits = NULL,
                           xsi.prior = NULL, beta.fixed = NULL, beta.inits = NULL,
                           variance.fixed = NULL, variance.inits = NULL,
                           est.variance = TRUE, A = NULL, notA = FALSE, Q = NULL,
                           Q.fixed = NULL, E = NULL, gammaslope.des = "2PL",
                           gammaslope = NULL, est.guess = NULL, guess = NULL,
                           guess.prior = NULL, max.guess = 0.5, pweights = NULL,
                           verbose = TRUE, control = list(), ...) NULL
  scores_rule <- function(fun, method, what) {
    rule("TAM", function(tamobj, ...) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "tamobj", ctx)
        if (!needs_fit(f, acc, fun)) return(NULL)
        note(acc, what)
        list(code = fcall("fscores", list(f$name, method = q(method),
                                          full.scores.SE = "TRUE")),
             register = list(pkg = "TAM", kind = "scores", model = f$name, method = method))
      })
  }
  list(
    "TAM::tam.mml" = rule("TAM", tam_mml_stub,
      function(a, ctx, acc, lhs) tam_translate(a, ctx, acc, lhs, "1pl")),
    "TAM::tam" = rule("TAM", tam_mml_stub,
      function(a, ctx, acc, lhs) {
        irt <- av(a, "irtmodel") %or% "1PL"
        fam <- if (irt %in% c("2PL", "GPCM", "2PL.groups", "GPCM.groups", "GPCM.design")) "2pl"
               else "1pl"
        tam_translate(a, ctx, acc, lhs, fam)
      }),
    "TAM::tam.mml.2pl" = rule("TAM", tam_2pl_stub,
      function(a, ctx, acc, lhs) tam_translate(a, ctx, acc, lhs, "2pl")),
    "TAM::tam.mml.3pl" = rule("TAM", tam_3pl_stub,
      function(a, ctx, acc, lhs) tam_translate(a, ctx, acc, lhs, "3pl")),

    "TAM::tam.wle" = scores_rule("tam.wle()", "WLE",
      "Warm's weighted likelihood estimates, as in tam.wle()."),
    "TAM::tam.mml.wle" = scores_rule("tam.mml.wle()", "WLE",
      "Warm's weighted likelihood estimates, as in tam.mml.wle()."),

    "TAM::IRT.factor.scores" = rule("TAM",
      function(object, type = "EAP", ...) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "object", ctx)
        if (!needs_fit(f, acc, "IRT.factor.scores()")) return(NULL)
        m <- score_method(av(a, "type") %or% "EAP") %or% "EAP"
        list(code = fcall("fscores", list(f$name, method = q(m), full.scores.SE = "TRUE")),
             register = list(pkg = "TAM", kind = "scores", model = f$name, method = m))
      }),

    "TAM::tam.fit" = rule("TAM",
      function(tamobj, ...) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "tamobj", ctx)
        if (!needs_fit(f, acc, "tam.fit()")) return(NULL)
        note(acc, "TAM reports infit and outfit for each item parameter, mirt for each item. ",
             "Both are mean squares with an expected value of 1.")
        list(code = fcall("itemfit", list(f$name, fit_stats = q("infit"))))
      }),

    "TAM::tam.modelfit" = rule("TAM",
      function(tamobj, progress = TRUE) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "tamobj", ctx)
        if (!needs_fit(f, acc, "tam.modelfit()")) return(NULL)
        note(acc, "M2() gives the overall fit test with RMSEA and SRMSR. For TAM's Q3 ",
             "statistics use residuals(", f$name, ", type = \"Q3\") or gg_q3(", f$name, ").")
        poly <- isTRUE(f$obj$poly)
        list(code = fcall("M2", list(f$name, type = if (poly) q("C2"))))
      }),

    "TAM::tam.personfit" = rule("TAM",
      function(tamobj) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "tamobj", ctx)
        if (!needs_fit(f, acc, "tam.personfit()")) return(NULL)
        list(code = fcall("personfit", list(f$name)))
      }),

    "TAM::IRT.compareModels" = rule("TAM",
      function(object, ...) NULL,
      function(a, ctx, acc, lhs) {
        mods <- c(at(a, "object"), vapply(a$given$`...` %or% list(), deparse_one, ""))
        note(acc, "anova() compares nested mirt models with AIC, BIC and a likelihood-ratio test.")
        list(code = fcall("anova", as.list(mods)))
      }),

    "TAM::tam.threshold" = rule("TAM",
      function(tamobj, prob.lvl = 0.5) NULL,
      function(a, ctx, acc, lhs) {
        f <- fit_of(a, "tamobj", ctx)
        if (!needs_fit(f, acc, "tam.threshold()")) return(NULL)
        note(acc, "TAM's Thurstonian thresholds have no direct mirt function; the IRT ",
             "parameters (b columns) are shown instead.")
        list(code = paste0(fcall("coef", list(f$name, IRTpars = "TRUE",
                                              simplify = "TRUE")), "$items"),
             status = "partial")
      })
  )
}

# ---- irtQ -----------------------------------------------------------------

irtq_irt_stub <- function(x = NULL, data, D = 1, model = NULL, cats = NULL, item.id = NULL,
                          fix.a.1pl = FALSE, fix.a.gpcm = FALSE, fix.g = FALSE,
                          a.val.1pl = 1, a.val.gpcm = 1, g.val = 0.2, use.aprior = FALSE,
                          use.bprior = FALSE, use.gprior = TRUE,
                          aprior = list(dist = "lnorm", params = c(0, 0.5)),
                          bprior = list(dist = "norm", params = c(0, 1)),
                          gprior = list(dist = "beta", params = c(5, 16)),
                          missing = NA, Quadrature = c(49, 6), weights = NULL,
                          group.mean = 0, group.var = 1, EmpHist = FALSE,
                          use.startval = FALSE, Etol = 1e-04, MaxE = 500,
                          control = list(), fipc = FALSE, fipc.method = "MEM",
                          fix.loc = NULL, fix.id = NULL, se = TRUE, verbose = TRUE) NULL

irtq_map <- c("1PLM" = "2PL", "2PLM" = "2PL", "3PLM" = "3PL", "DRM" = "3PL",
              "GRM" = "graded", "GPCM" = "gpcm")

irtq_est <- function(a, ctx, acc, lhs) {
  data <- at(a, "data")
  if (is.null(data)) {
    note(acc, "est_irt() without data was not translated.")
    return(list(code = character(), status = "unsupported"))
  }
  info <- data_info(ag(a, "data"), a$envir)
  status <- NULL
  if (given(a, "x")) {
    note(acc, "The item types come from the metadata in x; the 1PLM equality constraints ",
         "and priors stored there were not translated.")
    itemtype <- paste0('unname(c(', paste0('"', names(irtq_map), '" = "', irtq_map, '"',
                                            collapse = ", "), ')[toupper(', at(a, "x"),
                       '$model)])')
    args <- list(data, "1", itemtype = itemtype)
    status <- "partial"
    models <- NULL
  } else {
    models <- toupper(av(a, "model") %or% character())
    if (!length(models)) {
      note(acc, "est_irt() needs the model argument (or x) to know the item types.")
      return(list(code = character(), status = "unsupported"))
    }
    if (!all(models %in% names(irtq_map))) {
      note(acc, "Unknown irtQ model names: ", paste(setdiff(models, names(irtq_map)), collapse = ", "), ".")
      return(list(code = character(), status = "unsupported"))
    }
    J <- if (length(models) > 1) length(models) else info$J
    if (length(models) == 1 && !is.null(J)) models <- rep(models, J)
    types <- unname(irtq_map[models])
    lines <- "F = 1-{J}"
    idx <- function(m) if (length(models) == 1) "1-{J}" else item_ranges(which(models %in% m))
    if (any(models == "1PLM")) {
      if (isTRUE(av(a, "fix.a.1pl"))) {
        val <- av(a, "a.val.1pl") %or% 1
        lines <- c(lines, paste0("START = (", idx("1PLM"), ", a1, ", val, ")"),
                   paste0("FIXED = (", idx("1PLM"), ", a1)"))
        note(acc, "fix.a.1pl = TRUE fixes the 1PLM slopes at ", val, ".")
      } else {
        lines <- c(lines, paste0("CONSTRAIN = (", idx("1PLM"), ", a1)"))
        note(acc, "irtQ's 1PLM items share one estimated slope; the CONSTRAIN line does ",
             "the same in mirt.")
      }
    }
    if (any(models == "GPCM") && isTRUE(av(a, "fix.a.gpcm"))) {
      val <- av(a, "a.val.gpcm") %or% 1
      lines <- c(lines, paste0("START = (", idx("GPCM"), ", a1, ", val, ")"),
                 paste0("FIXED = (", idx("GPCM"), ", a1)"))
      note(acc, "fix.a.gpcm = TRUE fixes the GPCM slopes at ", val, " (a partial credit model).")
    }
    three <- c("3PLM", "DRM")
    if (any(models %in% three)) {
      if (isTRUE(av(a, "fix.g"))) {
        val <- av(a, "g.val") %or% 0.2
        lines <- c(lines, paste0("START = (", idx(three), ", g, ", val, ")"),
                   paste0("FIXED = (", idx(three), ", g)"))
        note(acc, "fix.g = TRUE fixes the guessing parameters at ", val, ".")
      } else if (!isFALSE(av(a, "use.gprior"))) {
        gp <- av(a, "gprior")$params %or% c(5, 16)
        lines <- c(lines, paste0("PRIOR = (", idx(three), ", g, expbeta, ", gp[1], ", ",
                                 gp[2], ")"))
        note(acc, "irtQ puts a Beta(", gp[1], ", ", gp[2], ") prior on the guessing ",
             "parameters by default; the PRIOR line does the same in mirt.")
        note(acc, "With guessing parameters the likelihood can have more than one peak, so ",
             "mirt and irtQ can stop at slightly different estimates. Compare the ",
             "log-likelihoods if the estimates differ.")
      }
    }
    if (isTRUE(av(a, "use.aprior"))) {
      ap <- av(a, "aprior")
      if (!identical(ap$dist, "lnorm")) {
        note(acc, "Only lognormal slope priors are translated.")
        status <- "partial"
      } else {
        sl <- which(!models %in% "1PLM")
        lines <- c(lines, paste0("PRIOR = (", if (length(models) == 1) "1-{J}" else item_ranges(sl),
                                 ", a1, lnorm, ", ap$params[1], ", ", ap$params[2], ")"))
        note(acc, "The lognormal slope prior is a PRIOR line in mirt.")
      }
    }
    if (isTRUE(av(a, "use.bprior"))) {
      note(acc, "mirt places priors on intercepts rather than difficulties, so the ",
           "difficulty prior (use.bprior) was not translated.")
      status <- "partial"
    }
    model <- if (length(lines) > 1) {
      add_model(acc, model_name(lhs, "model"), lines, J, data)
    } else "1"
    args <- list(data, model, itemtype = compress_itemtypes(types))
  }

  quad <- av(a, "Quadrature") %or% c(49, 6)
  args$quadpts <- as.character(quad[1])
  args$theta_lim <- paste0("c(", -quad[2], ", ", quad[2], ")")
  if (isTRUE(av(a, "EmpHist"))) {
    args$dentype <- q("empiricalhist")
    note(acc, "EmpHist = TRUE estimates the latent distribution as a histogram, which is ",
         "dentype = \"empiricalhist\" in mirt.")
  }
  if (!isFALSE(av(a, "se"))) args$SE <- "TRUE"
  note(acc, "quadpts and theta_lim use irtQ's quadrature (", quad[1], " points from ",
       -quad[2], " to ", quad[2], ").")

  D <- av(a, "D") %or% 1
  if (!isTRUE(all.equal(D, 1))) {
    note(acc, "irtQ multiplies the slopes by D = ", D, "; mirt does not. mirt's slopes equal ",
         "irtQ's times ", D, ", and coef() and summary() below rescale them.")
  }
  if (!identical(av(a, "group.mean"), 0) || !identical(av(a, "group.var"), 1)) {
    note(acc, "group.mean and group.var were not translated; mirt fixes the latent mean at 0 ",
         "and variance at 1.")
    status <- "partial"
  }
  if (isTRUE(av(a, "fipc"))) {
    note(acc, "Fixed item parameter calibration was not translated; see mirt::fixedCalib().")
    status <- "partial"
  }
  if (given(a, "missing") && !is.na(av(a, "missing") %or% NA)) {
    note(acc, "Recode the missing-data code ", at(a, "missing"), " to NA before fitting; mirt ",
         "treats only NA as missing.")
  }
  list(code = fcall("mirt", args), status = status,
       register = register_model("irtQ", data, if (!is.null(models)) unique(irtq_map[models]),
                                 D = D, poly = isTRUE(info$poly) ||
                                   any(models %in% c("GRM", "GPCM"))))
}

irtq_rules <- function() {
  fit_rule <- function(fun, argname, build) {
    rule("irtQ", function(x, ...) NULL,
      function(a, ctx, acc, lhs) {
        a$given$x <- a$given$x %or% a$given[[argname]]
        f <- fit_of(a, "x", ctx)
        if (!needs_fit(f, acc, fun)) return(NULL)
        dots <- a$given$`...` %or% list()
        build(f, dots, acc)
      })
  }
  dot <- function(dots, name, default = NULL) {
    if (is.null(dots[[name]])) default else deparse_one(dots[[name]])
  }
  list(
    "irtQ::est_irt" = rule("irtQ", irtq_irt_stub, irtq_est),

    "irtQ::est_item" = rule("irtQ",
      function(x = NULL, data, score, D = 1, model = NULL, cats = NULL, ...) NULL,
      function(a, ctx, acc, lhs) {
        note(acc, "Calibration with known abilities (est_item) can be approximated in mirt ",
             "with technical = list(fixedTheta = matrix(score)), but it is not translated ",
             "automatically.")
        list(code = character(), status = "unsupported")
      }),

    "irtQ::est_mg" = rule("irtQ",
      function(x = NULL, data, group.name = NULL, ...) NULL,
      function(a, ctx, acc, lhs) {
        note(acc, "irtQ's est_mg() takes one data set per group; stack them and use ",
             "mirt::multipleGroup() with a group vector.")
        list(code = character(), status = "unsupported")
      }),

    "irtQ::est_score" = fit_rule("est_score()", "x", function(f, dots, acc) {
      m <- toupper(gsub("[\"']", "", dot(dots, "method", "ML")))
      if (m == "INV.TCC") {
        note(acc, "Inverse TCC scoring has no mirt equivalent; EAP summed scores ",
             "(method = \"EAPsum\") also map summed scores to the theta scale.")
        m <- "EAP.SUM"
      }
      meth <- score_method(m) %or% "ML"
      if (m == "MLF") note(acc, "irtQ's MLF adds fences to ML; mirt's ML is used instead.")
      args <- list(f$name, method = q(meth), full.scores.SE = "TRUE")
      if (meth == "EAPsum") args$full.scores.SE <- NULL
      list(code = fcall("fscores", args), status = if (m %in% c("MLF")) "partial",
           register = list(pkg = "irtQ", kind = "scores", model = f$name, method = meth))
    }),

    "irtQ::sx2_fit" = fit_rule("sx2_fit()", "x", function(f, dots, acc) {
      note(acc, "Orlando and Thissen's S-X2, as in irtQ.")
      list(code = fcall("itemfit", list(f$name, fit_stats = q("S_X2"))))
    }),

    "irtQ::irtfit" = fit_rule("irtfit()", "x", function(f, dots, acc) {
      note(acc, "mirt's X2 groups people by ability like irtQ's irtfit(), with ",
           "group.bins groups. The grouping details differ, so values differ a little.")
      list(code = fcall("itemfit", list(f$name, fit_stats = q("X2"),
                                        group.bins = dot(dots, "n.width"))))
    }),

    "irtQ::info" = fit_rule("info()", "x", function(f, dots, acc) {
      th <- dot(dots, "theta", "seq(-4, 4, by = 0.1)")
      note(acc, "testinfo() gives the test information; use iteminfo(extract.item(",
           f$name, ", j), Theta) for item j. Information does not depend on D.")
      list(code = fcall("testinfo", list(f$name, Theta = paste0("matrix(", th, ")"))))
    }),

    "irtQ::traceline" = fit_rule("traceline()", "x", function(f, dots, acc) {
      th <- dot(dots, "theta", "seq(-4, 4, by = 0.1)")
      list(code = fcall("probtrace", list(f$name, Theta = paste0("matrix(", th, ")"))))
    }),

    "irtQ::getirt" = fit_rule("getirt()", "x", function(f, dots, acc) {
      what <- gsub("[\"']", "", dot(dots, "what", "par.est"))
      res <- translate_field(f$obj %or% list(pkg = "irtQ", kind = "model"), f$name, what,
                             NULL, acc)
      if (is.null(res)) return(NULL)
      list(code = res)
    })
  )
}

# ---------------------------------------------------------------------------
# Generic functions on translated models

generic_rules <- function() {
  list(
    summary = list(stub = function(object, ...) NULL,
      translate = function(a, obj, ctx, acc, lhs) {
        nm <- at(a, "object")
        if (obj$kind != "model") return(NULL)
        if (identical(obj$pkg, "eRm") || !is.null(obj$D) && !isTRUE(all.equal(obj$D, 1))) {
          return(list(code = coef_code(obj, nm, acc)))
        }
        note(acc, "tidy() lists every parameter with its standard error, on the IRT scale.")
        list(code = fcall("tidy", list(nm)))
      }),
    coef = list(stub = function(object, ...) NULL,
      translate = function(a, obj, ctx, acc, lhs) {
        nm <- at(a, "object")
        if (obj$kind != "model") {
          return(list(code = nm))
        }
        list(code = coef_code(obj, nm, acc))
      }),
    plot = list(stub = function(x, type = NULL, items = NULL, ...) NULL,
      translate = function(a, obj, ctx, acc, lhs) {
        nm <- at(a, "x")
        if (obj$kind != "model") return(NULL)
        type <- av(a, "type") %or% "ICC"
        items <- av(a, "items")
        if (identical(obj$pkg, "ltm") && type %in% c("IIC", "information")) {
          if (identical(items, 0)) return(list(code = fcall("gg_info", list(nm))))
          return(list(code = fcall("gg_info", list(nm, type = q("items"),
                                                   which.items = at(a, "items")))))
        }
        if (identical(obj$pkg, "TAM")) {
          note(acc, "TAM's plot() compares expected and observed scores; gg_empirical() ",
               "does this for one item at a time.")
          return(list(code = fcall("gg_empirical", list(nm, item = at(a, "items", "1")))))
        }
        list(code = fcall("gg_trace", list(nm, which.items = at(a, "items"))))
      }),
    anova = list(stub = function(object, ...) NULL,
      translate = function(a, obj, ctx, acc, lhs) {
        if (obj$kind != "model") return(NULL)
        mods <- c(at(a, "object"), vapply(a$given$`...` %or% list(), deparse_one, ""))
        note(acc, "anova() compares nested mirt models with AIC, BIC and a likelihood-ratio test.")
        list(code = fcall("anova", as.list(mods)))
      })
  )
}

coef_code <- function(obj, nm, acc) {
  cf <- paste0(fcall("coef", list(nm, IRTpars = "TRUE", simplify = "TRUE")), "$items")
  if (identical(obj$pkg, "eRm") && identical(obj$itemtype, "Rasch") &&
      identical(obj$erm, "RM")) {
    bn <- model_name(nm, "b")
    add_helper(acc, bn, paste0(bn, " <- ", cf, "[, \"b\"]"))
    note(acc, "eRm's item easiness is minus the difficulty, centred to sum to zero.")
    return(if (isFALSE(obj$sum0)) paste0("-(", bn, " - ", bn, "[1])")
           else paste0("-(", bn, " - mean(", bn, "))"))
  }
  if (identical(obj$pkg, "eRm")) {
    note(acc, "mirt shows the threshold (b) form; eRm's beta parameters are cumulative ",
         "easiness values centred to sum to zero.")
  }
  if (!is.null(obj$D) && !isTRUE(all.equal(obj$D, 1))) {
    pn <- model_name(nm, "pars")
    add_helper(acc, pn, c(paste0(pn, " <- ", cf),
                          paste0(pn, "[, \"a\"] <- ", pn, "[, \"a\"] / ", obj$D,
                                 "  # irtQ's slopes include D = ", obj$D)))
    return(pn)
  }
  cf
}

translate_field <- function(obj, nm, field, ctx, acc) {
  cf <- function() coef_code(obj, nm, acc)
  fs <- function(method = "EAP") fcall("fscores", list(obj$model %or% nm, method = q(method),
                                                         full.scores.SE = "TRUE"))
  if (obj$kind == "scores") {
    res <- switch(field,
      score.dat = nm,
      theta = , theta.table = , thetapar = , person = paste0(nm, "[, \"F1\"]"),
      error = , se.theta = paste0(nm, "[, \"SE_F1\"]"),
      WLE.rel = , EAP.rel = paste0("empirical_rxx(", nm, ")"),
      NULL)
  } else {
    res <- switch(paste(obj$pkg, field),
      "eRm betapar" = cf(),
      "eRm loglik" = paste0("logLik(", nm, ")"),
      "eRm X" = , "TAM resp" = , "irtQ data" = paste0("extract.mirt(", nm, ", \"data\")"),
      "TAM xsi" = { note(acc, "tidy() lists the parameters with their standard errors, ",
                         "like TAM's xsi table."); fcall("tidy", list(nm)) },
      "TAM EAP.rel" = paste0("empirical_rxx(", fs("EAP"), ")"),
      "TAM person" = fs("EAP"),
      "TAM deviance" = paste0("-2 * extract.mirt(", nm, ", \"logLik\")"),
      "TAM ic" = fcall("glance", list(nm)),
      "TAM item" = cf(),
      "TAM variance" = paste0("coef(", nm, ", simplify = TRUE)$cov"),
      "ltm coefficients" = cf(),
      "ltm log.Lik" = paste0("logLik(", nm, ")"),
      "irtQ par.est" = cf(),
      "irtQ estimates" = { note(acc, "tidy() lists the estimates with standard errors."); fcall("tidy", list(nm)) },
      "irtQ loglikelihood" = paste0("extract.mirt(", nm, ", \"logLik\")"),
      "irtQ aic" = paste0("extract.mirt(", nm, ", \"AIC\")"),
      "irtQ bic" = paste0("extract.mirt(", nm, ", \"BIC\")"),
      NULL)
  }
  if (is.null(res)) {
    note(acc, "The ", field, " element of ", nm, " has no automatic mirt translation; see ",
         "extract.mirt() for what a mirt model stores.")
    acc$status <- worst_status(acc$status, "partial")
  } else {
    acc$status <- worst_status(acc$status, "translated")
    acc$package <- obj$pkg
  }
  res
}

# ---------------------------------------------------------------------------
# Crosswalk table (also used in the website article)

crosswalk_table <- function() {
  rows <- list(
    c("ltm", "rasch()", "mirt(data, model, itemtype = \"2PL\") with CONSTRAIN = (1-J, a1)",
      "Common discrimination; a constraint fixing it at 1 becomes START and FIXED lines."),
    c("ltm", "ltm()", "mirt(data, nfact, itemtype = \"2PL\")",
      "Interaction and quadratic terms become (F1*F2) and (F*F) model lines."),
    c("ltm", "tpm()", "mirt(data, 1, itemtype = \"3PL\")", "max.guessing is not translated."),
    c("ltm", "grm()", "mirt(data, 1, itemtype = \"graded\")",
      "constrained = TRUE adds an equal-slopes constraint."),
    c("ltm", "gpcm()", "mirt(data, 1, itemtype = \"gpcm\")",
      "\"1PL\" adds equal slopes, \"rasch\" fixes them at 1."),
    c("ltm", "factor.scores()", "fscores(fit, method = \"MAP\", full.scores = FALSE)",
      "ltm's empirical Bayes scores are posterior modes (MAP)."),
    c("ltm", "item.fit()", "itemfit(fit, fit_stats = \"X2\")", "Grouping details differ."),
    c("ltm", "person.fit()", "personfit(fit)", "ltm's Lz is mirt's Zh."),
    c("ltm", "information()", "areainfo(fit, theta_lim)", ""),
    c("ltm", "descript()", "itemstats(data)", ""),
    c("ltm", "margins()", "residuals(fit, type = \"LD\")", ""),
    c("ltm", "unidimTest()", "M2(fit), residuals(fit, type = \"Q3\")", "No parallel analysis in mirt."),
    c("ltm", "plot()", "gg_trace(fit), gg_info(fit)", "type = \"IIC\" maps to gg_info()."),
    c("eRm", "RM(), PCM()", "mirt(data, 1, itemtype = \"Rasch\")",
      "CML in eRm, MML in mirt; easiness = -difficulty, centred."),
    c("eRm", "RSM()", "mirt(data, 1, itemtype = \"rsm\")", ""),
    c("eRm", "LLTM()", "mirt(data, 1, itemtype = \"Rasch\", itemdesign, item.formula)",
      "Basic parameters have the opposite sign."),
    c("eRm", "person.parameter()", "fscores(fit, method = \"ML\")",
      "Extreme scores give -Inf/Inf in mirt."),
    c("eRm", "itemfit()", "itemfit(fit, fit_stats = \"infit\")", "Infit and outfit mean squares."),
    c("eRm", "personfit()", "personfit(fit)", ""),
    c("eRm", "LRtest()", "anova() of two multipleGroup() models",
      "Score-group split, marginal rather than conditional likelihood."),
    c("eRm", "Waldtest()", "dif(data, group, model = \"Rasch\")",
      "Per-item likelihood-ratio tests."),
    c("eRm", "plotPImap()", "gg_wright(fit)", ""),
    c("eRm", "plotICC(), plotjointICC()", "gg_trace(fit)", ""),
    c("eRm", "thresholds()", "coef(fit, IRTpars = TRUE, simplify = TRUE)$items", ""),
    c("eRm", "IC()", "glance(fit)", "Marginal log-likelihood only."),
    c("eRm", "LRSM(), LPCM(), NPtest()", "not translated", "See mirt::mixedmirt()."),
    c("TAM", "tam.mml()", "mirt(data, 1, itemtype = \"Rasch\")",
      "RSM maps to \"rsm\"; Q matrix, group, Y and pweights are translated."),
    c("TAM", "tam.mml.2pl()", "mirt(data, 1, itemtype = \"2PL\" or \"gpcm\")",
      "Slope groups are not translated."),
    c("TAM", "tam.mml.3pl()", "mirt(data, 1, itemtype = \"3PL\")", "Only with est.guess."),
    c("TAM", "tam.wle()", "fscores(fit, method = \"WLE\")", ""),
    c("TAM", "IRT.factor.scores()", "fscores(fit, method = ...)", ""),
    c("TAM", "tam.fit()", "itemfit(fit, fit_stats = \"infit\")", "Per item rather than per parameter."),
    c("TAM", "tam.modelfit()", "M2(fit), residuals(fit, type = \"Q3\")", ""),
    c("TAM", "tam.personfit()", "personfit(fit)", ""),
    c("TAM", "IRT.compareModels()", "anova(fit1, fit2)", ""),
    c("TAM", "fit$xsi, fit$EAP.rel", "tidy(fit), empirical_rxx(fscores(...))", ""),
    c("irtQ", "est_irt()", "mirt(data, model, itemtype, quadpts = 49, theta_lim = c(-6, 6))",
      "1PLM equal slopes, guessing prior and D = 1.702 rescaling are handled."),
    c("irtQ", "est_score()", "fscores(fit, method = ...)", "INV.TCC maps to EAPsum."),
    c("irtQ", "sx2_fit()", "itemfit(fit, fit_stats = \"S_X2\")", ""),
    c("irtQ", "irtfit()", "itemfit(fit, fit_stats = \"X2\")", ""),
    c("irtQ", "info()", "testinfo(fit, Theta)", ""),
    c("irtQ", "traceline()", "probtrace(fit, Theta)", ""),
    c("irtQ", "getirt(), fit$par.est", "coef(fit, IRTpars = TRUE, simplify = TRUE)", ""),
    c("irtQ", "est_item(), est_mg()", "not translated",
      "See technical = list(fixedTheta) and multipleGroup().")
  )
  m <- do.call(rbind, rows)
  data.frame(package = m[, 1], `function` = m[, 2], mirt = m[, 3], notes = m[, 4],
             check.names = FALSE, stringsAsFactors = FALSE)
}
