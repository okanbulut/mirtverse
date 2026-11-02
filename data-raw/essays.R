# Builds the `essays` teaching dataset: short written explanations to four
# Grade 8 science prompts, each scored 0-4 by trained human raters, for the
# AI Hub (automated scoring).
#
# 400 students (100 English language learners, ELL) each answered the four
# prompts E1-E4. A response's true score is the number of the prompt's four
# key ideas it states correctly; students with higher ability state more of
# them. The text is assembled from phrasings of each key idea, misconceptions
# and filler sentences, so the score depends only on the ideas, never on
# length or style.
#
# Every response was scored by one rater (`human1`); a random 40% were scored
# again by a second rater (`human2`), so agreement and PRMSE can be checked.
# Raters are accurate (SD 0.35 around the true score). Planted on purpose:
#   * Fluent writers add more filler (restating the question, hedges,
#     personal asides) and use longer phrasings, so at the same score their
#     answers are about twice as long as ELL students' answers. A scorer
#     that rewards length will score ELL students too low although humans
#     do not.
#   * ELL students use simpler phrasings and make some grammar slips that a
#     scorer trained on word choice may punish.
#   * About 2% of responses are off topic or not a real attempt (score 0).
#   * Prompt E2 (seasons) has a common misconception ("Earth is closer to the
#     Sun in summer"); an answer that states it loses a point.
# ELL students are 0.25 SD lower in science ability on average (real impact).
# The generating values are stored internally as `essays_truth`.
#
# Run from the package root: source("data-raw/essays.R")

set.seed(1029)
N <- 400L
ell <- sample(rep(c("ELL", "Fluent"), c(100, 300)))
theta <- stats::rnorm(N, ifelse(ell == "ELL", -0.25, 0), 1)

prompts <- c(
  E1 = "Explain why ice floats on liquid water.",
  E2 = "Explain why Earth has seasons.",
  E3 = "Explain how a green plant makes its own food.",
  E4 = "A metal spoon and a wooden spoon have been in the same room all day. Explain why the metal spoon feels colder when you touch it.")

# for each prompt: four key ideas, each with fluent and simple phrasings
ideas <- list(
  E1 = list(
    list(f = c("Ice is less dense than liquid water.", "The density of ice is lower than the density of liquid water.",
               "Frozen water has a lower density than the water around it."),
         s = c("Ice is less dense than water.", "Ice have less density than water.")),
    list(f = c("When water freezes, its molecules line up in an open, hexagonal pattern held by hydrogen bonds.",
               "In ice the water molecules are locked into a crystal structure with lots of empty space.",
               "Hydrogen bonds hold the molecules in ice in a rigid, open lattice."),
         s = c("When water freeze, the molecules make a pattern with space inside.", "In ice the molecules are in a crystal with spaces.")),
    list(f = c("Because the molecules are spread out, the same mass of water takes up more volume as ice.",
               "Water expands when it freezes, so a kilogram of ice takes more space than a kilogram of water.",
               "The same number of molecules fills a bigger volume once they are frozen."),
         s = c("Ice take more space than the same water.", "Water get bigger when it freeze.")),
    list(f = c("Anything less dense than the liquid it is in is pushed up by buoyancy and floats.",
               "Objects that are less dense than a fluid float because the buoyant force is greater than their weight.",
               "The water pushes up on the ice more than gravity pulls it down, so it floats."),
         s = c("Less dense things float on more dense things.", "The water push the ice up so it float."))),
  E2 = list(
    list(f = c("Earth's axis is tilted about 23.5 degrees.", "The Earth spins on an axis that is tilted compared with its orbit.",
               "Our planet is tilted on its axis."),
         s = c("The Earth is tilted.", "Earth axis is tilt.")),
    list(f = c("As Earth orbits the Sun, first one hemisphere and then the other leans toward the Sun.",
               "During the year the tilt points the northern half toward the Sun for part of the orbit and away for the rest.",
               "Because the tilt stays pointed the same way, each hemisphere takes turns facing the Sun."),
         s = c("Part of the year the north side point to the Sun.", "Each half of Earth take turns facing the Sun.")),
    list(f = c("When your hemisphere leans toward the Sun, sunlight hits the ground more directly, so each square metre gets more energy.",
               "Direct rays in summer concentrate the Sun's energy on a smaller area, which heats it more.",
               "In winter the light comes in at a low angle and is spread out, so it heats the ground less."),
         s = c("In summer the sunlight is more direct so it is hotter.", "The light hit more straight in summer.")),
    list(f = c("Days are also longer in summer, so the ground has more hours to warm up.",
               "Summer has more hours of daylight, which adds to the heating.",
               "Longer days in summer and shorter days in winter add to the difference."),
         s = c("Summer days are longer.", "In summer the day is more long."))),
  E3 = list(
    list(f = c("Plants make food by photosynthesis.", "The process is called photosynthesis.",
               "Green plants carry out photosynthesis to make their food."),
         s = c("Plants do photosynthesis.", "It is called photosynthesis.")),
    list(f = c("Chlorophyll in the leaves captures energy from sunlight.", "The green pigment chlorophyll absorbs light energy.",
               "Leaves contain chlorophyll, which traps the energy in sunlight."),
         s = c("The leaves use sunlight.", "Chlorophyll take the light energy.")),
    list(f = c("The plant takes in carbon dioxide from the air and water from the soil.",
               "Carbon dioxide enters through the leaves and water comes up from the roots.",
               "The raw materials are carbon dioxide and water."),
         s = c("Plant need carbon dioxide and water.", "It take water from roots and CO2 from air.")),
    list(f = c("It uses the energy to turn them into glucose, a sugar, and gives off oxygen.",
               "The products are glucose, which the plant uses for energy and growth, and oxygen.",
               "Light energy is stored in the sugar glucose, and oxygen is released."),
         s = c("It make sugar and oxygen.", "The plant make glucose and give oxygen."))),
  E4 = list(
    list(f = c("Both spoons are actually at the same temperature, room temperature.",
               "The two spoons have the same temperature because they have been in the room all day.",
               "Neither spoon is really colder; they are both at room temperature."),
         s = c("Both spoons are same temperature.", "The spoons are not really cold, they are room temperature.")),
    list(f = c("Your hand is warmer than the spoons, so heat flows from your hand into the spoon.",
               "Heat moves from your warm skin to the cooler spoon when you touch it.",
               "Thermal energy flows from your hand to the spoon because your hand is warmer."),
         s = c("Heat go from the hand to the spoon.", "The hand is warm so heat move to spoon.")),
    list(f = c("Metal is a good conductor of heat, while wood is an insulator.",
               "Metals conduct heat much better than wood does.",
               "Wood is a poor conductor, but metal conducts heat well."),
         s = c("Metal is a conductor and wood is not.", "Metal conduct heat good, wood no.")),
    list(f = c("So the metal carries heat away from your hand faster, and what you feel as cold is that fast loss of heat.",
               "Your skin senses how fast it loses heat, not the temperature of the object, so the metal feels colder.",
               "The faster heat leaves your hand, the colder something feels, and metal takes heat away faster."),
         s = c("Metal take heat from hand fast so it feel cold.", "You lose heat fast with metal so it feel more cold."))))

misconception_e2 <- c("Also, Earth is closer to the Sun in the summer, so it is hotter.",
                      "Summer happens when Earth is nearest to the Sun.")
fillers_open <- c("This is a really interesting question about science.", "To answer this question, we need to think about what is happening.",
                  "There are a few reasons why this happens.", "I learned about this in class last year.",
                  "Many people wonder about this.", "Let me explain what I think is going on here.",
                  "This is something that we can see in everyday life.")
fillers_close <- c("That is why this happens.", "I think this is the main reason, but there could be other reasons too.",
                   "In conclusion, this is how it works.", "Overall, it is a combination of these things.",
                   "I hope this explains it clearly.", "This shows that science can explain things we see every day.")
weak <- list(
  E1 = c("Ice is cold and water is not.", "Ice is solid so it is light.", "Ice floats because it has air in it like a boat."),
  E2 = c("Seasons happen because the weather changes.", "The Sun gets hotter in summer.", "It is because of the clouds."),
  E3 = c("Plants get food from the soil.", "Plants eat dirt and water.", "The plant grows and makes food."),
  E4 = c("Metal is always colder than wood.", "Metal spoons are cold because they are metal.", "Wood is warm."))
off_topic <- c("I don't know.", "idk", "This question is boring.", "My favourite subject is art.", "?", "no")

b_idea <- rbind(E1 = c(-1.2, 0.4, 0.9, -0.3), E2 = c(-1.5, -0.2, 0.6, 1.1),
                E3 = c(-1.8, -0.6, -0.1, 0.5), E4 = c(-0.4, -0.1, 0.3, 1.3))

make_response <- function(pr, th, is_ell) {
  if (stats::runif(1) < 0.02) return(list(text = sample(off_topic, 1), score = 0L, off = TRUE, mis = FALSE))
  has <- stats::runif(4) < stats::plogis(1.3 * (th - b_idea[pr, ]))
  parts <- character()
  for (k in which(has)) {
    simple <- is_ell && stats::runif(1) < 0.75
    parts <- c(parts, sample(if (simple) ideas[[pr]][[k]]$s else ideas[[pr]][[k]]$f, 1))
  }
  if (!length(parts)) parts <- sample(weak[[pr]], 1)
  else if (stats::runif(1) < 0.3) parts <- c(parts, sample(weak[[pr]], 1))
  mis <- pr == "E2" && stats::runif(1) < 0.25 * stats::plogis(-th)  * 2
  if (mis) parts <- append(parts, sample(misconception_e2, 1), after = sample(0:length(parts), 1))
  n_fill <- if (is_ell) stats::rbinom(1, 1, 0.25) else stats::rbinom(1, 3, 0.55)
  open <- if (n_fill > 0) sample(fillers_open, min(n_fill, 2)) else character()
  close <- if (n_fill > 1) sample(fillers_close, 1) else character()
  score <- max(0L, sum(has) - mis)
  list(text = paste(c(open, parts, close), collapse = " "), score = as.integer(score), off = FALSE, mis = mis)
}

rows <- list()
for (s in seq_len(N)) for (pr in names(prompts)) {
  r <- make_response(pr, theta[s], ell[s] == "ELL")
  rows[[length(rows) + 1]] <- data.frame(student = sprintf("S%03d", s), prompt = pr, group = ell[s],
                                         response = r$text, true = r$score, off_topic = r$off,
                                         misconception = r$mis, stringsAsFactors = FALSE)
}
essays <- do.call(rbind, rows)
rate <- function(x) as.integer(pmin(4, pmax(0, round(x + stats::rnorm(length(x), 0, 0.35)))))
essays$human1 <- rate(essays$true)
double <- stats::runif(nrow(essays)) < 0.4
essays$human2 <- ifelse(double, rate(essays$true), NA_integer_)
essays$words <- lengths(strsplit(essays$response, "\\s+"))
essays$id <- sprintf("R%04d", seq_len(nrow(essays)))
essays$group <- factor(essays$group, levels = c("Fluent", "ELL"))

essays_truth <- list(
  true_score = stats::setNames(essays$true, essays$id),
  theta = stats::setNames(round(theta, 3), sprintf("S%03d", seq_len(N))),
  idea_difficulty = b_idea,
  rater_sd = 0.35,
  off_topic = essays$id[essays$off_topic],
  misconception = essays$id[essays$misconception],
  planted = c(length = "Fluent writers add filler; at the same score their answers are about twice as long.",
              simple_language = "ELL students use simpler phrasings with some grammar slips.",
              impact = "ELL students are 0.25 SD lower in ability."),
  prompts = prompts)
essays <- essays[, c("id", "student", "prompt", "group", "response", "words", "human1", "human2")]
rownames(essays) <- NULL

save(essays, file = "data/essays.rda", compress = "xz")
sysdata <- new.env()
load("R/sysdata.rda", envir = sysdata)
assign("essays_truth", essays_truth, envir = sysdata)
save(list = ls(sysdata), envir = sysdata, file = "R/sysdata.rda", compress = "xz")
