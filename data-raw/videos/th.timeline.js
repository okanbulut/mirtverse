{ title: "Thesis kit demo", edMax: 7, total: 92, txt: __TXT__, timeline: [
 [0, () => slide(`<div style="text-align:center"><div style="font:600 22px Inter;letter-spacing:.12em;color:#ffd7b0">MIRTVERSE THESIS KIT</div>
   <div style="font:700 52px Inter;margin-top:14px;line-height:1.2">From item responses<br>to a Methods section</div>
   <div style="display:flex;gap:14px;justify-content:center;margin-top:34px;font:500 19px Inter">${["Fit","Compare","Check","Write it up"].map((x,i)=>`<span style="padding:9px 18px;border-radius:30px;background:#ffffff1a;opacity:0;animation:fi .5s ${0.6+i*0.4}s forwards">${i+1}. ${x}</span>`).join('')}</div>
   <style>@keyframes fi{to{opacity:1}}</style></div>`)],
 [9.3, () => slide(null)],
 [10, () => cap("Fit and compare models")],
 [10.5, () => type(["library(mirtverse)", "key <- c(1,4,5,2,3,1,2,1,3,1,2,4,2,1,5,3,4,4,1,4,3,3,4,1,3,5,1,3,1,5,4,5)", "data <- key2binary(SAT12, key)   # 32 items, 600 students", "sel <- select_model(data, candidates = c(\"Rasch\", \"2PL\"), verbose = FALSE)", "sel"], 48)],
 [19.5, () => run(["sel <- select_model(data, candidates = c(\"Rasch\", \"2PL\"), verbose = FALSE)", "sel"], "th-sel")],
 [21, () => mark("The 2PL model is recommended")],
 [23, () => mark("chi-square(31) = 309.03")],
 [26, () => cap("Draft the Methods paragraph")],
 [26.5, () => type(["cite_methods(sel, sample = \"high school students\",", "             items = \"multiple-choice science items\")"], 40)],
 [30, () => { edh(110); run(["cite_methods(sel, sample = \"high school students\",", "             items = \"multiple-choice science items\")"], "th-methods", true); scrollCon(0); }],
 [33, () => mark("version 1.47; Chalmers, 2012")],
 [36, () => mark("two-parameter logistic (2PL) model")],
 [39, () => mark("BIC = 19387.3")],
 [41.5, () => scrollCon(150)],
 [43, () => mark("RMSEA = .028")],
 [45, () => mark("Item.22 and Item.25")],
 [48, () => cap("A reference list, built for you")],
 [48.3, () => scrollCon(370)],
 [52, () => mark("Bock, R. D., & Aitkin, M. (1981)")],
 [55, () => mark("Orlando, M., & Thissen, D. (2000)")],
 [58, () => scrollCon(560)],
 [62, () => { cap("Save it as a Word file"); edh(200); }],
 [62.6, () => type(["cite_methods(sel, sample = \"high school students\",", "             items = \"multiple-choice science items\",", "             file = \"methods.docx\")"], 40)],
 [67.5, () => run(["cite_methods(sel, ..., file = \"methods.docx\")"], null, true)],
 [68.3, () => view("docx-1.png", "methods.docx", 640, 190)],
 [76, () => { cap(""); view(null); slide(`<div style="text-align:center"><div style="font:700 44px Inter;line-height:1.25">A first draft, not the last word:<br>Read it, and make it yours.</div>
   <div style="font:500 24px Inter;margin-top:30px;opacity:.9">The thesis kit article walks through every step</div><div style="font:600 26px Inter;margin-top:8px;color:#ffd7b0">okanbulut.com/mirtverse</div></div>`); }],
]}
