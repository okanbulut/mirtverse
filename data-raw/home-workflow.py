# Builds man/figures/home-workflow.svg, the four-step workflow on the home page.
# Run from the package root: python3 data-raw/home-workflow.py
stages = [
    ("1", "Bring your data", "CSV, Excel or SPSS,", "or any mirt model", "launch_workbench()"),
    ("2", "Fit and choose", "Compare Rasch, 2PL, 3PL", "and pick a model", "select_model()"),
    ("3", "Understand", "Plain-language results,", "item cards and figures", "interpret()  item_card()"),
    ("4", "Share and decide", "Reports, dashboards", "and a documented pipeline", "mv_report()  mv_dashboard()"),
]
W, H, M, GAP, Y0, BH = 1200, 250, 24, 44, 30, 190
BW = (W - 2 * M - 3 * GAP) / 4
font = "font-family:-apple-system,'Segoe UI',Inter,Roboto,Helvetica,Arial,sans-serif"
mono = "font-family:SFMono-Regular,Menlo,Consolas,'DejaVu Sans Mono',monospace"
out = [
    f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" role="img" aria-labelledby="t d">',
    '<title id="t">The mirtverse workflow</title>',
    '<desc id="d">Four steps: Bring your data, fit and choose a model, understand the results, then share them and make decisions.</desc>',
    f'<rect width="{W}" height="{H}" rx="16" fill="#F4F7FB"/>',
    '<defs><marker id="a" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto">'
    '<path d="M0,0 L10,5 L0,10 z" fill="#E8A317"/></marker></defs>',
]
for i, (n, title, l1, l2, fn) in enumerate(stages):
    x = M + i * (BW + GAP)
    last = i == len(stages) - 1
    fill, tc, sc, fc = ("#172B4D", "#FFFFFF", "#C8D6E8", "#E8A317") if last else ("#FFFFFF", "#172B4D", "#5A636E", "#2C5F8A")
    out += [
        f'<rect x="{x:.1f}" y="{Y0}" width="{BW:.1f}" height="{BH}" rx="14" fill="{fill}" stroke="#2C5F8A" stroke-opacity="0.25" stroke-width="1.5"/>',
        f'<circle cx="{x + 34:.1f}" cy="{Y0 + 38}" r="17" fill="#E8A317"/>',
        f'<text x="{x + 34:.1f}" y="{Y0 + 44}" text-anchor="middle" style="{font}" font-size="17" font-weight="700" fill="#172B4D">{n}</text>',
        f'<text x="{x + 62:.1f}" y="{Y0 + 45}" style="{font}" font-size="21" font-weight="700" fill="{tc}">{title}</text>',
        f'<text x="{x + 20:.1f}" y="{Y0 + 92}" style="{font}" font-size="16" fill="{sc}">{l1}</text>',
        f'<text x="{x + 20:.1f}" y="{Y0 + 114}" style="{font}" font-size="16" fill="{sc}">{l2}</text>',
        f'<line x1="{x + 20:.1f}" y1="{Y0 + 136}" x2="{x + BW - 20:.1f}" y2="{Y0 + 136}" stroke="{sc}" stroke-opacity="0.3"/>',
        f'<text x="{x + 20:.1f}" y="{Y0 + 164}" style="{mono}" font-size="14" fill="{fc}">{fn}</text>',
    ]
    if not last:
        ax = x + BW + 6
        out.append(f'<line x1="{ax:.1f}" y1="{Y0 + BH / 2}" x2="{ax + GAP - 14:.1f}" y2="{Y0 + BH / 2}" stroke="#E8A317" stroke-width="3" marker-end="url(#a)"/>')
out.append('</svg>')
open("man/figures/home-workflow.svg", "w").write("\n".join(out) + "\n")
