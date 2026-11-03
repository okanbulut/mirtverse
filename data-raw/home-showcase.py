# Builds man/figures/home-showcase.png, the 2 x 2 grid of real outputs on the
# home page. The plots come from data-raw/home-showcase.R (written to
# data-raw/home/), the dashboard screenshot from pkgdown/assets/dashboard.
# Run from the package root: python3 data-raw/home-showcase.py
from PIL import Image, ImageDraw, ImageFont

NAVY, AMBER, INK, MUTED, LINE, BG = (23, 43, 77), (232, 163, 23), (33, 37, 41), (90, 99, 110), (222, 226, 230), (248, 249, 250)
tiles = [
    ("pkgdown/assets/dashboard/summary.png", "Dashboards for people who don't use R", "mv_dashboard()"),
    ("data-raw/home/card.png", "Item health cards for review meetings", "item_card()"),
    ("data-raw/home/wright.png", "Publication-ready ggplot2 figures", "gg_wright()"),
    ("data-raw/home/dif.png", "Fairness checks in one call", "dif() + gg_dif()"),
]
TW, TH, CAP, PAD = 780, 470, 74, 20
W = 2 * TW + 3 * PAD
H = 2 * (TH + CAP) + 3 * PAD
out = Image.new("RGB", (W, H), BG)
d = ImageDraw.Draw(out)
bold = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 25)
mono = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", 21)
for i, (path, title, fn) in enumerate(tiles):
    x = PAD + (i % 2) * (TW + PAD)
    y = PAD + (i // 2) * (TH + CAP + PAD)
    d.rounded_rectangle([x, y, x + TW, y + TH + CAP], radius=14, fill="white", outline=LINE, width=2)
    im = Image.open(path).convert("RGB")
    s = min((TW - 24) / im.width, (TH - 20) / im.height)
    im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    out.paste(im, (x + (TW - im.width) // 2, y + 12 + (TH - 20 - im.height) // 2))
    d.line([x + 2, y + TH, x + TW - 2, y + TH], fill=LINE, width=2)
    d.rectangle([x + 22, y + TH + 22, x + 28, y + TH + 52], fill=AMBER)
    d.text((x + 40, y + TH + 14), title, font=bold, fill=NAVY)
    d.text((x + 40, y + TH + 44), fn, font=mono, fill=MUTED)
out.save("man/figures/home-showcase.png", optimize=True)
