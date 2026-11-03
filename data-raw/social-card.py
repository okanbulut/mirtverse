# Builds man/figures/card.png, the 1200 x 630 share image that LinkedIn,
# Bluesky and X show for links to the pkgdown site (template: opengraph).
# Run from the package root: python3 data-raw/social-card.py
from PIL import Image, ImageDraw, ImageFont

W, H = 1200, 630
NAVY, AMBER, WHITE, PALE = (23, 43, 77), (232, 163, 23), (255, 255, 255), (200, 214, 232)
card = Image.new("RGB", (W, H), NAVY)
d = ImageDraw.Draw(card)
d.rectangle([0, H - 14, W, H], fill=AMBER)

logo = Image.open("man/figures/logo.png").convert("RGBA")
lh = 430
logo = logo.resize((round(logo.width * lh / logo.height), lh), Image.LANCZOS)
card.paste(logo, (W - logo.width - 70, (H - lh) // 2 - 7), logo)

bold = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
reg = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
x = 70
d.text((x, 120), "mirtverse", font=ImageFont.truetype(bold, 84), fill=WHITE)
f = ImageFont.truetype(reg, 38)
for i, line in enumerate(["From item responses to", "defensible decisions,", "with or without writing R code."]):
    d.text((x, 245 + i * 52), line, font=f, fill=PALE)
d.text((x, 450), "IRT workflows, reports, labs and a free book for mirt",
       font=ImageFont.truetype(reg, 24), fill=AMBER)
d.text((x, 495), "okanbulut.com/mirtverse", font=ImageFont.truetype(bold, 26), fill=WHITE)
card.save("man/figures/card.png", optimize=True)
