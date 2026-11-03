# Builds man/figures/home-ai.svg, the animated "AI-powered psychometrics"
# graphic in the home page's AI Hub highlight: Item text flows through a
# small neural network and comes out as a calibrated item characteristic
# curve. Pure SVG with CSS and SMIL animation, so it plays inside an <img>
# on GitHub and the pkgdown site, and stops for readers who ask for
# reduced motion. Run from the package root: python3 data-raw/home-ai.py
import math

W, H = 1200, 320
NAVY, BLUE, AMBER, TEAL, MUTED, BG = "#172B4D", "#2C5F8A", "#E8A317", "#2BA3A3", "#8A96A0", "#F4F7FB"
font = "font-family:-apple-system,'Segoe UI',Inter,Roboto,Helvetica,Arial,sans-serif"
mono = "font-family:SFMono-Regular,Menlo,Consolas,'DejaVu Sans Mono',monospace"
T = 6  # seconds per loop

o = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" role="img" aria-labelledby="t d">',
     '<title id="t">AI-powered psychometrics</title>',
     '<desc id="d">Animated: Item text and responses flow through a neural network and come out as a calibrated item characteristic curve.</desc>',
     f'''<style>
.flow{{stroke-dasharray:6 10;animation:flow 1.2s linear infinite}}
@keyframes flow{{to{{stroke-dashoffset:-32}}}}
.node{{animation:pulse {T/2}s ease-in-out infinite;transform-box:fill-box;transform-origin:center}}
@keyframes pulse{{0%,100%{{opacity:.55;transform:scale(.85)}}50%{{opacity:1;transform:scale(1.12)}}}}
.scan{{animation:scan {T/2}s ease-in-out infinite}}
@keyframes scan{{0%{{transform:translateY(0);opacity:0}}10%{{opacity:.9}}90%{{opacity:.9}}100%{{transform:translateY(118px);opacity:0}}}}
.curve{{stroke-dasharray:420;stroke-dashoffset:420;animation:draw {T}s ease-in-out infinite}}
@keyframes draw{{0%{{stroke-dashoffset:420;opacity:1}}45%,85%{{stroke-dashoffset:0;opacity:1}}100%{{stroke-dashoffset:0;opacity:0}}}}
.tok{{animation:tok {T/2}s ease-in-out infinite}}
@keyframes tok{{0%,100%{{fill:#C8D6E8}}50%{{fill:{AMBER}}}}}
@media (prefers-reduced-motion:reduce){{.flow,.node,.scan,.curve,.tok{{animation:none}}.curve{{stroke-dashoffset:0}}.scan{{opacity:0}}}}
</style>''',
     f'<rect width="{W}" height="{H}" rx="18" fill="{NAVY}"/>',
     '<defs><radialGradient id="g" cx="50%" cy="50%" r="60%"><stop offset="0" stop-color="#2C5F8A" stop-opacity=".55"/><stop offset="1" stop-color="#172B4D" stop-opacity="0"/></radialGradient>'
     f'<marker id="ar" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="{AMBER}"/></marker></defs>',
     f'<ellipse cx="600" cy="150" rx="260" ry="140" fill="url(#g)"/>']

# Panel 1: an item card with text lines and a response grid
x1, y1 = 50, 52
o.append(f'<rect x="{x1}" y="{y1}" width="260" height="170" rx="12" fill="#FFFFFF" fill-opacity=".06" stroke="#C8D6E8" stroke-opacity=".35"/>')
o.append(f'<text x="{x1+18}" y="{y1+30}" style="{mono}" font-size="14" fill="{AMBER}">Item 17</text>')
widths = [[60, 44, 70, 38], [52, 80, 46], [70, 40, 58, 30]]
for r, row in enumerate(widths):
    xx = x1 + 18
    for k, w in enumerate(row):
        o.append(f'<rect class="tok" style="animation-delay:{(r*4+k)*0.18:.2f}s" x="{xx}" y="{y1+48+r*20}" width="{w}" height="9" rx="4.5" fill="#C8D6E8"/>')
        xx += w + 8
for k in range(4):
    for j in range(10):
        on = (j * 7 + k * 3) % 5 < 3
        o.append(f'<rect x="{x1+18+j*22}" y="{y1+118+k*11}" width="16" height="7" rx="2" fill="{TEAL if on else "#C8D6E8"}" fill-opacity="{0.9 if on else 0.25}"/>')
o.append(f'<rect class="scan" x="{x1+8}" y="{y1+38}" width="244" height="3" rx="1.5" fill="{AMBER}"/>')
o.append(f'<text x="{x1+130}" y="{y1+205}" text-anchor="middle" style="{font}" font-size="16" fill="#FFFFFF">Item text and responses</text>')

# Panel 2: a small neural network with flowing edges
layers = [4, 6, 6, 3]
lx = [470, 560, 650, 740]
nodes = []
for li, n in enumerate(layers):
    gap = 150 / (n - 1)
    nodes.append([(lx[li], 62 + i * gap) for i in range(n)])
for li in range(len(layers) - 1):
    for a in nodes[li]:
        for b in nodes[li + 1]:
            o.append(f'<line x1="{a[0]}" y1="{a[1]:.1f}" x2="{b[0]}" y2="{b[1]:.1f}" stroke="#C8D6E8" stroke-opacity=".18"/>')
import random
random.seed(3)
for li in range(len(layers) - 1):
    for a in nodes[li]:
        for b in random.sample(nodes[li + 1], 2):
            o.append(f'<line class="flow" style="animation-delay:{random.random():.2f}s" x1="{a[0]}" y1="{a[1]:.1f}" x2="{b[0]}" y2="{b[1]:.1f}" stroke="{AMBER}" stroke-opacity=".75" stroke-width="1.6"/>')
for li, layer in enumerate(nodes):
    for i, (x, y) in enumerate(layer):
        col = TEAL if li in (0, 3) else "#FFFFFF"
        o.append(f'<circle class="node" style="animation-delay:{li*0.35+i*0.12:.2f}s" cx="{x}" cy="{y:.1f}" r="8" fill="{col}"/>')
o.append(f'<text x="605" y="{y1+205}" text-anchor="middle" style="{font}" font-size="16" fill="#FFFFFF">Machine learning and language models</text>')

# Arrows between panels
o.append(f'<line class="flow" x1="325" y1="137" x2="440" y2="137" stroke="{AMBER}" stroke-width="3" marker-end="url(#ar)"/>')
o.append(f'<line class="flow" x1="770" y1="137" x2="880" y2="137" stroke="{AMBER}" stroke-width="3" marker-end="url(#ar)"/>')

# Panel 3: an item characteristic curve drawing itself, a person sliding along it
x3, y3, pw, ph = 905, 62, 250, 150
o.append(f'<line x1="{x3}" y1="{y3+ph}" x2="{x3+pw}" y2="{y3+ph}" stroke="#C8D6E8" stroke-opacity=".6"/>')
o.append(f'<line x1="{x3}" y1="{y3}" x2="{x3}" y2="{y3+ph}" stroke="#C8D6E8" stroke-opacity=".6"/>')
for f in (0.5,):
    o.append(f'<line x1="{x3}" y1="{y3+ph*(1-f)}" x2="{x3+pw}" y2="{y3+ph*(1-f)}" stroke="#C8D6E8" stroke-opacity=".2" stroke-dasharray="4 4"/>')
pts = []
for k in range(61):
    t = -3 + 6 * k / 60
    p = 1 / (1 + math.exp(-1.6 * (t - 0.3)))
    pts.append((x3 + pw * k / 60, y3 + ph * (1 - p)))
d = "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts)
for a, op in ((0.8, ".25"), (2.4, ".25")):
    ghost = []
    for k in range(61):
        t = -3 + 6 * k / 60
        p = 1 / (1 + math.exp(-a * (t + (0.9 if a < 1 else -1.0))))
        ghost.append((x3 + pw * k / 60, y3 + ph * (1 - p)))
    o.append(f'<path d="M{" L".join(f"{x:.1f},{y:.1f}" for x, y in ghost)}" fill="none" stroke="{TEAL}" stroke-opacity="{op}" stroke-width="2"/>')
o.append(f'<path id="icc" class="curve" d="{d}" fill="none" stroke="{AMBER}" stroke-width="4" stroke-linecap="round"/>')
o.append(f'<circle r="7" fill="#FFFFFF" stroke="{AMBER}" stroke-width="3"><animateMotion dur="{T}s" repeatCount="indefinite" keyPoints="0;0;1;1" keyTimes="0;0.45;0.85;1" calcMode="linear"><mpath href="#icc"/></animateMotion></circle>')
o.append(f'<text x="{x3+pw/2}" y="{y3+ph+22}" text-anchor="middle" style="{font}" font-size="13" fill="{MUTED}">θ</text>')
o.append(f'<text x="{x3+pw/2}" y="{y1+205}" text-anchor="middle" style="{font}" font-size="16" fill="#FFFFFF">Calibrated, auditable IRT</text>')

# Footer line
o.append(f'<text x="600" y="296" text-anchor="middle" style="{mono}" font-size="14" fill="{AMBER}">item_features()  ·  predict_difficulty()  ·  generate_isomorphs()  ·  train_scorer()  ·  ai_audit()</text>')
o.append('</svg>')
open("man/figures/home-ai.svg", "w").write("\n".join(o) + "\n")
