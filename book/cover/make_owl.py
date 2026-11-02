"""Draw an engraving-style owl as SVG (hatching, feather marks, radial facial disc).

Original artwork for the mirtverse book cover. Run: python3 make_owl.py > owl.svg
"""
import math, random

random.seed(7)
W, H = 800, 900
INK = "#1d1d1b"
out = []
add = out.append

# ---- shapes -------------------------------------------------------------
body = ("M400,318 C548,318 612,468 600,600 C590,724 506,800 400,800 "
        "C294,800 210,724 200,600 C188,468 252,318 400,318Z")
wing_l = ("M248,410 C196,494 184,640 222,752 C246,806 300,826 336,808 "
          "C300,730 286,600 300,470 C292,440 270,418 248,410Z")
wing_r = ("M552,410 C604,494 616,640 578,752 C554,806 500,826 464,808 "
          "C500,730 514,600 500,470 C508,440 530,418 552,410Z")
head = ("M246,262 C238,206 252,150 276,100 L304,172 C344,156 456,156 496,172 "
        "L524,100 C548,150 562,206 554,262 C566,344 500,414 400,414 "
        "C300,414 234,344 246,262Z")
tuft_l = "M276,100 C262,140 256,176 262,214 L304,172 Z"
tuft_r = "M524,100 C538,140 544,176 538,214 L496,172 Z"
branch = ("M40,800 C200,786 340,796 470,800 C590,804 690,790 770,770 "
          "C778,776 780,784 772,790 C690,816 590,832 470,834 C330,836 190,834 40,846 "
          "C30,836 30,810 40,800Z")
twig = "M640,800 C670,770 700,752 742,744 C736,752 706,766 680,800Z"
eyes = [(328, 268), (472, 268)]

def hatch(clip_id, angle, gap, width, x0=-200, x1=1000, y0=-200, y1=1100, wobble=0.6, opacity=1):
    """Parallel engraving lines clipped to a shape, with slight hand wobble."""
    a = math.radians(angle)
    dx, dy = math.cos(a), math.sin(a)
    nx, ny = -dy, dx
    lines = []
    L = 1400
    k = -L
    while k < L:
        cx, cy = 400 + nx * k, 450 + ny * k
        pts = []
        for t in range(-L, L + 1, 40):
            px = cx + dx * t + random.uniform(-wobble, wobble)
            py = cy + dy * t + random.uniform(-wobble, wobble)
            pts.append(f"{px:.1f},{py:.1f}")
        w = width * random.uniform(0.85, 1.15)
        lines.append(f'<polyline points="{" ".join(pts)}" fill="none" stroke="{INK}" '
                     f'stroke-width="{w:.2f}" opacity="{opacity}"/>')
        k += gap
    add(f'<g clip-path="url(#{clip_id})">' + "".join(lines) + "</g>")

def chevrons(clip_id, y_from, y_to, row_gap, col_gap, size, width):
    """Rows of small V-shaped feather marks (breast plumage)."""
    marks = []
    row = 0
    y = y_from
    while y < y_to:
        off = (col_gap / 2) if row % 2 else 0
        x = 180 + off
        while x < 620:
            s = size * random.uniform(0.8, 1.2)
            jx, jy = random.uniform(-2, 2), random.uniform(-2, 2)
            marks.append(f'<path d="M{x-s+jx:.1f},{y-s*0.45+jy:.1f} Q{x+jx:.1f},{y+s*0.55+jy:.1f} '
                         f'{x+s+jx:.1f},{y-s*0.45+jy:.1f}" fill="none" stroke="{INK}" '
                         f'stroke-width="{width*random.uniform(.8,1.2):.2f}" stroke-linecap="round"/>')
            x += col_gap
        y += row_gap
        row += 1
    add(f'<g clip-path="url(#{clip_id})">' + "".join(marks) + "</g>")

def scallops(clip_id, x_from, x_to, y_from, y_to, gap_x, gap_y, width):
    """Overlapping feather scallops for the wings."""
    marks = []
    row = 0
    y = y_from
    while y < y_to:
        x = x_from + (gap_x / 2 if row % 2 else 0)
        while x < x_to:
            marks.append(f'<path d="M{x-gap_x/2:.1f},{y:.1f} Q{x:.1f},{y+gap_y*1.3:.1f} {x+gap_x/2:.1f},{y:.1f}" '
                         f'fill="none" stroke="{INK}" stroke-width="{width}"/>')
            x += gap_x
        y += gap_y
        row += 1
    add(f'<g clip-path="url(#{clip_id})">' + "".join(marks) + "</g>")

# ---- svg ----------------------------------------------------------------
add(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">')
add("<defs>")
for cid, d in [("body", body), ("wl", wing_l), ("wr", wing_r), ("head", head),
               ("tl", tuft_l), ("tr", tuft_r), ("branch", branch)]:
    add(f'<clipPath id="{cid}"><path d="{d}"/></clipPath>')
add('<clipPath id="breast"><path d="M300,420 C360,400 440,400 500,420 C520,560 510,700 470,790 '
    'C430,800 370,800 330,790 C290,700 280,560 300,420Z"/></clipPath>')
for i, (ex, ey) in enumerate(eyes):
    add(f'<clipPath id="disc{i}"><circle cx="{ex}" cy="{ey}" r="90"/></clipPath>')
add('<clipPath id="halfL"><rect x="0" y="0" width="400" height="900"/></clipPath>')
add('<clipPath id="halfR"><rect x="400" y="0" width="400" height="900"/></clipPath>')
add("</defs>")

# branch with bark texture
add(f'<clipPath id="twig"><path d="{twig}"/></clipPath>')
add(f'<path d="{twig}" fill="#fff" stroke="{INK}" stroke-width="2.2"/>')
hatch("twig", -40, 4, 1.0)
add(f'<path d="{branch}" fill="#fff" stroke="{INK}" stroke-width="2.4"/>')
hatch("branch", 4, 4.2, 1.1)
hatch("branch", -35, 7, 0.8, opacity=.9)
add(f'<ellipse cx="160" cy="822" rx="16" ry="8" fill="#fff" stroke="{INK}" stroke-width="2"/>')
add(f'<ellipse cx="160" cy="822" rx="8" ry="3.5" fill="{INK}"/>')

# body: light tone + breast chevrons
add(f'<path d="{body}" fill="#fff" stroke="{INK}" stroke-width="2.6"/>')
hatch("body", 80, 7.5, 0.7, opacity=.85)
add('<clipPath id="shade"><path d="M430,330 C600,360 640,560 600,700 C570,780 500,810 420,806 '
    'C520,740 560,600 520,460 C500,400 470,360 430,330Z"/></clipPath>')
add('<clipPath id="neck"><path d="M240,380 C320,450 480,450 560,380 L560,470 C480,520 320,520 240,470Z"/></clipPath>')
add('<g clip-path="url(#body)">')
hatch("shade", 35, 5, 0.9)
hatch("neck", 20, 7, 0.6, opacity=.6)
add('</g>')
chevrons("breast", 440, 790, 18, 24, 7, 1.4)

# wings: darker, crossed hatching + scallops
for cid, d, ang in [("wl", wing_l, 70), ("wr", wing_r, 110)]:
    add(f'<path d="{d}" fill="#fff" stroke="{INK}" stroke-width="2.6"/>')
    hatch(cid, ang, 4.2, 1.15)
    hatch(cid, ang + 55, 7, 0.7, opacity=.9)
    scallops(cid, 180, 620, 430, 820, 26, 24, 1.8)

# head + tufts
add(f'<path d="{head}" fill="#fff" stroke="{INK}" stroke-width="2.6"/>')
hatch("head", 100, 5.2, 0.9)
for cid, d in [("tl", tuft_l), ("tr", tuft_r)]:
    add(f'<path d="{d}" fill="#fff" stroke="{INK}" stroke-width="2.2"/>')
    hatch(cid, 75 if cid == "tl" else 105, 3.2, 1.2)
for (tx, ty, bx, by) in [(276,100,286,190),(276,100,270,200),(524,100,514,190),(524,100,530,200)]:
    add(f'<path d="M{tx},{ty} Q{(tx+bx)/2+6},{(ty+by)/2} {bx},{by}" fill="none" stroke="#fff" stroke-width="1.6"/>')

# facial discs: white with radial strokes, darker rim
for i, (ex, ey) in enumerate(eyes):
    half = "halfL" if i == 0 else "halfR"
    add(f'<g clip-path="url(#{half})"><circle cx="{ex}" cy="{ey}" r="90" fill="#fff"/></g>')
    strokes = []
    for deg in range(0, 360, 5):
        a = math.radians(deg + random.uniform(-1.5, 1.5))
        r0, r1 = 44 + random.uniform(0, 6), 88 + random.uniform(-6, 2)
        strokes.append(f'<line x1="{ex+r0*math.cos(a):.1f}" y1="{ey+r0*math.sin(a):.1f}" '
                       f'x2="{ex+r1*math.cos(a):.1f}" y2="{ey+r1*math.sin(a):.1f}" '
                       f'stroke="{INK}" stroke-width="{random.uniform(.7,1.3):.2f}"/>')
    add(f'<g clip-path="url(#{half})"><g clip-path="url(#disc{i})">' + "".join(strokes) + "</g></g>")
    rim = []
    for deg in range(0, 360, 4):
        a = math.radians(deg)
        x1, y1 = ex + 84 * math.cos(a), ey + 84 * math.sin(a)
        x2, y2 = ex + 95 * math.cos(a + .05), ey + 95 * math.sin(a + .05)
        rim.append(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" '
                   f'stroke="{INK}" stroke-width="2.2" stroke-linecap="round"/>')
    add(f'<g clip-path="url(#{half})">' + "".join(rim) + "</g>")
    # eye: amber-free, engraved: iris rings + pupil + highlight
    add(f'<circle cx="{ex}" cy="{ey}" r="36" fill="#fff" stroke="{INK}" stroke-width="3"/>')
    for r in range(22, 36, 3):
        add(f'<circle cx="{ex}" cy="{ey}" r="{r}" fill="none" stroke="{INK}" stroke-width="0.8"/>')
    add(f'<circle cx="{ex}" cy="{ey}" r="19" fill="{INK}"/>')
    add(f'<circle cx="{ex-7}" cy="{ey-8}" r="5" fill="#fff"/>')

# brows: a dark V between the discs
brow = []
for side in (-1, 1):
    for k in range(14):
        x0, y0 = 400 + side * (2 + k * 1.2), 262 - k * 4
        x1, y1 = 400 + side * (40 + k * 4.5), 200 - k * 1.5
        brow.append(f'<path d="M{x0:.1f},{y0:.1f} Q{(x0+x1)/2:.1f},{min(y0,y1)-6:.1f} {x1:.1f},{y1:.1f}" '
                    f'fill="none" stroke="{INK}" stroke-width="{1.6 - k*0.06:.2f}" stroke-linecap="round"/>')
add("".join(brow))
# beak
add(f'<path d="M400,268 C418,290 420,322 402,350 C392,330 384,300 400,268Z" fill="#fff" stroke="{INK}" stroke-width="2.4"/>')
add(f'<path d="M400,280 C410,300 410,320 402,340" fill="none" stroke="{INK}" stroke-width="1.2"/>')

# feet / talons gripping the branch
for fx in (350, 450):
    for k in (-18, 0, 18):
        add(f'<path d="M{fx+k*0.4},{786} C{fx+k},{800} {fx+k*1.3},{812} {fx+k*1.5+4},{826}" '
            f'fill="none" stroke="{INK}" stroke-width="5" stroke-linecap="round"/>')
add("</svg>")
print("\n".join(out))
