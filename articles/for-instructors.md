# Start here: Instructors

mirtverse gives you a complete, free set of materials for a course on
item response theory: A book, ten interactive labs, a 12-week course
map, a glossary and a cheat sheet. Everything is open, editable and runs
on student laptops.

## Your path in three steps

**1. See how the pieces fit a semester.** The [course
map](https://www.okanbulut.com/mirtverse/articles/course-map.md) ties
each week to a book chapter, a lab and a reading, and the [sample
syllabus](https://www.okanbulut.com/mirtverse/adopt/mirtverse-sample-syllabus.docx)
(Word) turns it into a document you can edit and hand out.

**2. Try a lab the way your students will.** Each lab is a realistic
case, such as advising a certification board or investigating a fairness
complaint, with live mirt models and decisions to defend:

``` r

library(mirtverse)
list_labs()                 # the ten labs
run_lab("fairness")         # Lab 3: Is the test fair?
```

The [Teaching
labs](https://www.okanbulut.com/mirtverse/articles/teaching-labs.md)
article has the learning goals, timing, discussion prompts and an answer
key for each lab.

**3. Make it yours.** Build a lab on your own data, swap the dataset in
a built-in lab, or copy a book chapter to edit:

``` r

new_course("irt-fall-2027")                    # a course folder
new_lab("my-lab", data = mydata, course = "irt-fall-2027")
check_material("irt-fall-2027")                # checks every lab before class does
```

See [The instructor
toolkit](https://www.okanbulut.com/mirtverse/articles/instructor-toolkit.md).
If you use Claude or an OpenAI assistant, the [MCP
server](https://www.okanbulut.com/mirtverse/articles/instructor-mcp.md)
lets it revise and adapt these materials for you.

## Also for your course

- [The book](https://www.okanbulut.com/mirtverse/book/index.md), also as
  PDF and EPUB, with its own DOI
  ([10.5281/zenodo.23885605](https://doi.org/10.5281/zenodo.23885605)).
- [AI in
  measurement](https://www.okanbulut.com/mirtverse/articles/ai-hub.md):
  Four labs and six chapters on AI for a later module, and a [one-day
  workshop
  kit](https://www.okanbulut.com/mirtverse/articles/ai-workshop.md).
- [Glossary](https://www.okanbulut.com/mirtverse/articles/glossary.md)
  and [cheat
  sheet](https://www.okanbulut.com/mirtverse/cheatsheet/mirtverse-cheatsheet.pdf)
  to hand out.

## Adopting it for a course?

[Adopt mirtverse for your
course](https://www.okanbulut.com/mirtverse/articles/adopt.md) has a
sample syllabus to edit (Word and PDF), a setup checklist, and a
two-minute form to tell us about your course. Hearing which courses use
the materials shapes what comes next.
