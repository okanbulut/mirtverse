# Single-file HTML version of the results dashboard. It is built from the same
# mv_dashboard object as the shiny app: static plots become embedded PNGs, and
# the interactive parts (tables, item curves, the ability slider) are drawn by
# a small inline script from the object's data, so the file works offline.

dashboard_html <- function(d, file) {
  h <- htmltools::tags
  img <- function(src, alt = "") if (!is.null(src)) h$img(src = src, alt = alt, class = "plot")
  png_src <- function(p, width = 7, height = 4) plot_img(p, width, height)$attribs$src
  card <- function(title, ...) h$div(class = "card", h$h3(title), ...)
  note <- function(txt) h$p(class = "note", txt)
  panels <- d$panels

  data <- list(panels = panels, method = d$meta$method)
  if ("items" %in% panels) {
    data$items <- dash_items_view(d$items)
    data$cards <- d$cards
  }
  if (!is.null(d$trace)) data$trace <- trace_json(d$trace, d$dich)
  if ("information" %in% panels)
    data$iteminfo <- list(theta = unique(d$iteminfo$theta),
                          items = lapply(split(d$iteminfo$info, d$iteminfo$item), round, 4))
  if ("scores" %in% panels && !is.null(d$conv)) {
    cv <- d$conv[, intersect(c("Sum.Scores", "F1", "SE_F1"), names(d$conv))]
    names(cv) <- c("Total score", "Ability", "SE")[seq_along(cv)]
    data$conv <- cv
  }
  if ("persons" %in% panels) {
    data$persons <- d$persons
    names(data$persons) <- c("ID", "Ability", "SE", "Percentile")
  }
  if ("dif" %in% panels) {
    dt <- d$dif$table
    dt$flag <- ifelse(dt$flag, "DIF", "")
    data$dif <- dt[, intersect(c("item", "flag", "X2", "df", "p.value", "p.adjusted", "esd", "uesd"),
                               names(dt))]
  }
  if ("rt" %in% panels) data$rt <- d$rt$items

  section <- function(id) {
    body <- switch(id,
      summary = list(
        if (!is.null(d$meta$subtitle)) h$p(class = "lead", d$meta$subtitle),
        h$div(class = "boxes", lapply(summary_box_data(d), function(b)
          h$div(class = paste("box", b$theme), h$div(class = "box-title", b$title),
                h$div(class = "box-value", b$value),
                if (!is.null(b$sub)) h$div(class = "box-sub", b$sub)))),
        h$div(class = "cols",
          card("What the results say", interp_html(d$interp)),
          card("Model details", html_table(dash_glance_table(d$glance))))),
      items = list(
        card("Items",
             note("Status: red for misfit or low discrimination, amber for other flags, green otherwise. Select a row to see the item in detail."),
             h$div(id = "tbl-items")),
        card("Selected item", h$div(id = "item-detail"))),
      curves = h$div(class = "side",
        h$div(class = "card controls",
          h$h3("Items"), h$div(id = "curve-items", class = "checks"),
          h$h3("Show"),
          h$label(h$input(type = "radio", name = "curve-type", value = "prob", checked = NA),
                  " Response probabilities"),
          h$label(h$input(type = "radio", name = "curve-type", value = "expected"),
                  " Expected item score"),
          h$h3("Ability level: ", h$span(id = "theta-val", "0.0")),
          h$input(type = "range", id = "theta", min = -4, max = 4, step = 0.1, value = 0),
          note("Ability is on a standard scale: 0 is average, and most people fall between -2 and 2.")),
        h$div(
          card("Item characteristic curves", h$div(id = "curves", class = "grid")),
          card("At the chosen ability level", h$div(id = "at-theta")))),
      information = h$div(class = "cols",
        card("Test information",
             note("The test measures most precisely where information is high and the standard error is low."),
             img(png_src(plot_test_info(d$testinfo)), "Test information and standard error")),
        card("Item information", h$div(id = "info-items", class = "checks inline"),
             h$div(id = "iteminfo"))),
      wright = card("Wright map",
        note("People (left) and items (right) on the same scale. A well-targeted test has items spread where most people are."),
        img(png_src(plot_wright(d$wright$persons, d$wright$items), 9, 5.5), "Wright map")),
      scores = h$div(class = "cols",
        card("Distribution of ability estimates",
             img(png_src(plot_score_bins(d$score_bins, d$meta$method), 7, 4), "Score distribution"),
             html_table(data.frame(Mean = fmt(d$score_summary[["mean"]]),
                                   SD = fmt(d$score_summary[["sd"]]),
                                   Median = fmt(d$score_summary[["median"]])))),
        card("Sum score conversion table",
             note("The ability estimate and its standard error for each total score."),
             h$div(id = "tbl-conv"))),
      persons = card("Person scores",
        note(sprintf("%s ability estimates with standard errors. Search for an ID to look someone up.",
                     d$meta$method)),
        h$div(id = "tbl-persons")),
      dif = list(
        card("Differential item functioning", interp_html(d$dif$interp), h$div(id = "tbl-dif")),
        if (!is.null(d$dif$effect)) card("Effect sizes", img(d$dif$effect, "DIF effect sizes")),
        if (!is.null(d$dif$curves)) card("Flagged items by group", img(d$dif$curves, "Item curves by group"))),
      rt = list(
        h$div(class = "cols",
          card("What the response times say", interp_html(d$rt$interp)),
          card("Plots",
               h$select(id = "rt-plot",
                        h$option(value = "items", "Item parameters"),
                        h$option(value = "rapid", "Rapid responding by item"),
                        h$option(value = "rte", "Response time effort")),
               lapply(names(d$rt$plots), function(nm)
                 h$img(src = d$rt$plots[[nm]], class = "plot rt-img", `data-plot` = nm,
                       hidden = if (nm != "items") NA)))),
        card("Item response-time parameters", h$div(id = "tbl-rt"))))
    h$section(id = paste0("p-", id), class = "panel", hidden = if (id != panels[1]) NA, body)
  }

  data <- lapply(data, function(v) if (is.data.frame(v)) json_cols(v) else v)
  json <- jsonlite::toJSON(data, dataframe = "columns", auto_unbox = TRUE, digits = 4,
                           na = "null", null = "null")
  json <- gsub("</", "<\\/", json, fixed = TRUE)

  body <- htmltools::tagList(
    h$header(
      h$div(class = "brand",
            if (!is.null(d$meta$logo)) h$img(src = d$meta$logo, alt = ""),
            h$span(d$meta$title)),
      h$nav(lapply(panels, function(id)
        h$button(type = "button", `data-panel` = id, class = if (id == panels[1]) "active",
                 dashboard_panels[[id]]))),
      h$span(class = "made", sprintf("Made with mirtverse %s, %s", d$meta$version, d$meta$created))),
    h$main(lapply(panels, section)),
    htmltools::HTML(paste0("<script type=\"application/json\" id=\"mv-data\">", json, "</script>")),
    htmltools::HTML(paste0("<script>", dashboard_js, "</script>")))

  html <- c("<!DOCTYPE html>", "<html lang=\"en\">", "<head>", "<meta charset=\"utf-8\">",
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
            paste0("<title>", htmltools::htmlEscape(d$meta$title), "</title>"),
            "<style>", dashboard_css, "</style>", "</head>", "<body>",
            enc2utf8(as.character(body)), "</body>", "</html>")
  con <- file(file, open = "w", encoding = "UTF-8")
  on.exit(close(con))
  writeLines(html, con)
  invisible(file)
}

# Columns as arrays even when a table has one row (toJSON would unbox them)
json_cols <- function(df) lapply(as.list(df), function(v) I(if (is.factor(v)) as.character(v) else v))

dash_items_view <- function(items) {
  items[, intersect(c("item", "status", "itemtype", "mean", "item_total_r", "discrimination",
                      "location", "RMSEA", "p.value", "flag"), names(items))]
}

dash_glance_table <- function(g) {
  keep <- intersect(c("nobs", "nitems", "itemtype", "logLik", "AIC", "BIC", "M2", "df", "p.value",
                      "RMSEA", "CFI", "TLI", "SRMSR", "reliability", "converged"), names(g))
  labs <- c(nobs = "Respondents", nitems = "Items", itemtype = "Item type",
            logLik = "Log-likelihood", M2 = "M2 (limited-information fit)", df = "M2 df",
            p.value = "M2 p-value", reliability = "Reliability", converged = "Converged")
  data.frame(Statistic = ifelse(keep %in% names(labs), labs[keep], keep),
             Value = vapply(keep, function(nm) format_cell(g[[nm]][[1]]), ""))
}

summary_box_data <- function(d) {
  rel <- d$glance$reliability
  st <- table(factor(d$items$status, levels = c("green", "amber", "red")))
  box <- function(title, value, sub = NULL, theme = "primary")
    list(title = title, value = value, sub = sub, theme = theme)
  Filter(Negate(is.null), list(
    box("Respondents", format(d$meta$nobs, big.mark = ",")),
    box("Items", d$meta$nitems, d$meta$itemtype),
    if (!is.null(rel) && !is.na(rel))
      box("Reliability", formatC(rel, format = "f", digits = 2), "marginal reliability"),
    box("Items to review", st[["red"]] + st[["amber"]],
        sprintf("%d red, %d amber", st[["red"]], st[["amber"]]),
        theme = if (st[["red"]] > 0) "danger" else if (st[["amber"]] > 0) "warning" else "success")))
}

plot_score_bins <- function(bins, method) {
  ggplot2::ggplot(bins) +
    ggplot2::geom_rect(ggplot2::aes(xmin = lo, xmax = hi, ymin = 0, ymax = count),
                       fill = mv_colours[["primary"]], colour = "white") +
    ggplot2::labs(x = sprintf("%s estimate of ability", method), y = "Respondents") +
    theme_mirtverse()
}

# Curves per item as compact arrays: one probability vector per category
trace_json <- function(tr, dich) {
  theta <- unique(tr$theta)
  items <- lapply(split(tr, tr$item), function(df) {
    nm <- as.character(df$item[1])
    list(name = nm, dich = isTRUE(dich[[nm]]),
         cats = levels(droplevels(df$category)),
         probs = unname(lapply(split(df$prob, droplevels(df$category)), round, 4)),
         expected = round(df$expected[df$first], 4))
  })
  list(theta = theta, items = unname(items))
}

dashboard_css <- "
:root{--bg:#f6f8fa;--card:#ffffff;--fg:#1d2733;--muted:#5b6876;--line:#e3e8ee;--accent:#2C5F8A;--soft:#f0f4f8;
--good:#2E8B57;--warn:#C9861F;--bad:#C23B4E;--grid:#e8ecf0}
@media (prefers-color-scheme: dark){:root{--bg:#11161c;--card:#182029;--fg:#e6ebf0;--muted:#9aa7b4;--line:#2a333d;
--accent:#8db8de;--soft:#1f2933;--grid:#2a333d} img.plot{background:#fff;border-radius:6px}}
*{box-sizing:border-box}
[hidden]{display:none !important}
body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.5 system-ui,-apple-system,'Segoe UI',Roboto,sans-serif}
header{position:sticky;top:0;z-index:5;display:flex;flex-wrap:wrap;align-items:center;gap:8px 24px;
padding:10px 20px;background:var(--card);border-bottom:1px solid var(--line)}
.brand{display:flex;align-items:center;gap:10px;font-size:20px;font-weight:600}
.brand img{height:32px}
nav{display:flex;flex-wrap:wrap;gap:4px;flex:1}
nav button{border:0;background:none;color:var(--muted);font:inherit;padding:8px 10px;cursor:pointer;border-bottom:2px solid transparent}
nav button.active{color:var(--fg);border-bottom-color:var(--accent);font-weight:600}
.made{color:var(--muted);font-size:13px}
main{max-width:1280px;margin:0 auto;padding:20px 16px 60px}
.card{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:14px 18px;margin:0 0 18px;min-width:0}
.card h3{font-size:15px;margin:0 0 10px}
.interp h3{font-size:20px;font-weight:500;margin:14px 0 4px}
.interp ul{margin:4px 0 10px;padding-left:20px}
.lead{color:var(--muted);font-size:19px;margin:0 0 14px}
.note{color:var(--muted);margin:0 0 10px}
.boxes{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:18px;margin-bottom:18px}
.box{border-radius:10px;padding:22px 26px;color:#fff;background:#2C5F8A}
.box.danger{background:#C23B4E}.box.warning{background:#C9861F}.box.success{background:#2E8B57}
.box-title{font-size:15px}.box-value{font-size:32px;line-height:1.3}.box-sub{font-size:13px;font-weight:600}
.cols{display:grid;grid-template-columns:repeat(auto-fit,minmax(420px,1fr));gap:18px;align-items:start}
.side{display:grid;grid-template-columns:280px 1fr;gap:18px;align-items:start}
@media (max-width:760px){.cols,.side{grid-template-columns:1fr}
header{flex-direction:column;align-items:stretch;gap:4px}header>*{min-width:0;max-width:100%}nav{flex-wrap:nowrap;overflow-x:auto}nav button{white-space:nowrap}}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:10px}
.checks{max-height:220px;overflow-y:auto;border:1px solid var(--line);border-radius:6px;padding:6px 8px;margin-bottom:12px}
.checks.inline{display:flex;flex-wrap:wrap;gap:2px 14px;max-height:120px}
.checks label,.controls label{display:block;cursor:pointer}
.checks.inline label{display:inline-block}
input[type=range]{width:100%}
img.plot{max-width:100%;height:auto;display:block}
.table-wrap{overflow-x:auto}
table{border-collapse:collapse;font-size:14px;width:100%}
th,td{padding:7px 10px;border-bottom:1px solid var(--line);text-align:left;white-space:nowrap}
th{font-weight:600;cursor:pointer;user-select:none}
th.sorted-asc::after{content:' \\25B2';font-size:10px}th.sorted-desc::after{content:' \\25BC';font-size:10px}
td.num,th.num{text-align:right;font-variant-numeric:tabular-nums}
tbody tr:nth-child(odd){background:var(--soft)}
tbody tr.clickable{cursor:pointer}
tbody tr.selected{background:var(--accent);color:#fff}
.pill{display:inline-block;padding:1px 9px;border-radius:10px;color:#fff;font-size:12px;font-weight:600;text-transform:uppercase}
.pill.green{background:var(--good)}.pill.amber{background:var(--warn)}.pill.red{background:var(--bad)}
.tbl-bar{display:flex;justify-content:space-between;align-items:center;gap:10px;margin:0 0 8px;flex-wrap:wrap}
.tbl-bar input{padding:6px 8px;border:1px solid var(--line);border-radius:6px;background:var(--card);color:var(--fg);font:inherit}
.pager{display:flex;align-items:center;gap:8px;color:var(--muted);font-size:13px;margin-top:8px}
.pager button,select{border:1px solid var(--line);background:var(--card);color:var(--fg);border-radius:6px;padding:4px 10px;font:inherit;cursor:pointer}
select{margin-bottom:10px}
svg text{fill:var(--muted);font-size:11px}
svg .title{fill:var(--fg);font-weight:600;font-size:12px}
svg .gridline{stroke:var(--grid)}
svg .vline{stroke:var(--muted);stroke-dasharray:4 3}
.legend{display:flex;flex-wrap:wrap;gap:4px 14px;font-size:12px;color:var(--muted);margin-top:4px}
.legend i{display:inline-block;width:14px;height:3px;margin-right:5px;vertical-align:middle}
"

dashboard_js <- "
(function(){
var D=JSON.parse(document.getElementById('mv-data').textContent);
var PAL=['#440154','#3B528B','#21908C','#5DC863','#C7A800','#D1495B','#7A7A7A','#2C5F8A'];
function el(tag,attrs,kids){var e=document.createElement(tag);if(attrs)for(var k in attrs){if(k==='text')e.textContent=attrs[k];else e.setAttribute(k,attrs[k]);}
(kids||[]).forEach(function(c){if(c)e.appendChild(typeof c==='string'?document.createTextNode(c):c);});return e;}
function fmt(v,d){if(v===null||v===undefined||v==='')return '';if(typeof v==='number'){if(Number.isInteger(v))return String(v);return v.toFixed(d===undefined?3:d);}return String(v);}

// tabs
document.querySelectorAll('nav button').forEach(function(b){b.addEventListener('click',function(){
  document.querySelectorAll('nav button').forEach(function(x){x.classList.toggle('active',x===b);});
  document.querySelectorAll('section.panel').forEach(function(s){s.hidden=(s.id!=='p-'+b.dataset.panel);});
  window.scrollTo(0,0);});});

// sortable, searchable, paged table built from column-oriented data
function table(target,cols,opts){
  opts=opts||{};var names=Object.keys(cols);var n=names.length?cols[names[0]].length:0;
  var rows=[];for(var i=0;i<n;i++)rows.push(i);
  var num={};names.forEach(function(k){num[k]=cols[k].every(function(v){return v===null||typeof v==='number';});});
  var view=rows.slice(),page=0,size=opts.page||15,sortKey=null,sortDir=1,selected=opts.selected;
  var box=document.getElementById(target);if(!box)return;
  var search=el('input',{type:'search',placeholder:opts.placeholder||'Search'});var scols=opts.searchCols||names;
  var bar=el('div',{class:'tbl-bar'},[el('span'),opts.search===false?null:search]);
  var thead=el('thead'),tbody=el('tbody'),pager=el('div',{class:'pager'});
  box.appendChild(bar);box.appendChild(el('div',{class:'table-wrap'},[el('table',null,[thead,tbody])]));box.appendChild(pager);
  var hr=el('tr');names.forEach(function(k){var th=el('th',{class:num[k]?'num':''},[k]);
    th.addEventListener('click',function(){sortDir=(sortKey===k)?-sortDir:1;sortKey=k;
      hr.querySelectorAll('th').forEach(function(t){t.classList.remove('sorted-asc','sorted-desc');});
      th.classList.add(sortDir>0?'sorted-asc':'sorted-desc');apply();});hr.appendChild(th);});
  thead.appendChild(hr);
  function apply(){var q=search.value.trim().toLowerCase();
    view=rows.filter(function(i){return !q||scols.some(function(k){return String(cols[k][i]).toLowerCase().indexOf(q)>=0;});});
    if(sortKey)view.sort(function(a,b){var x=cols[sortKey][a],y=cols[sortKey][b];if(x===y)return 0;if(x===null)return 1;if(y===null)return -1;return (x<y?-1:1)*sortDir;});
    page=0;draw();}
  function draw(){tbody.innerHTML='';var pages=Math.max(1,Math.ceil(view.length/size));if(page>=pages)page=pages-1;
    view.slice(page*size,(page+1)*size).forEach(function(i){var tr=el('tr',{class:opts.onclick?'clickable':''});
      if(i===selected)tr.classList.add('selected');
      names.forEach(function(k){var v=cols[k][i];var td=el('td',{class:num[k]?'num':''});
        if(k===opts.status)td.appendChild(el('span',{class:'pill '+v,text:v}));else td.textContent=fmt(v);tr.appendChild(td);});
      if(opts.onclick)tr.addEventListener('click',function(){selected=i;draw();opts.onclick(i);});
      tbody.appendChild(tr);});
    pager.innerHTML='';if(view.length>size){
      var prev=el('button',{type:'button',text:'Previous'}),next=el('button',{type:'button',text:'Next'});
      prev.disabled=page===0;next.disabled=page>=pages-1;
      prev.onclick=function(){page--;draw();};next.onclick=function(){page++;draw();};
      pager.appendChild(prev);pager.appendChild(el('span',{text:'Page '+(page+1)+' of '+pages+' ('+view.length+' rows)'}));pager.appendChild(next);}
    else pager.appendChild(el('span',{text:view.length+' rows'}));}
  search.addEventListener('input',apply);apply();}

// minimal SVG line chart
var NS='http://www.w3.org/2000/svg';
function sv(tag,attrs){var e=document.createElementNS(NS,tag);for(var k in attrs)e.setAttribute(k,attrs[k]);return e;}
function chart(opts){
  var W=opts.width||340,H=opts.height||220,m={l:40,r:10,t:opts.title?22:8,b:30};
  var x0=opts.x[0],x1=opts.x[opts.x.length-1],y0=opts.ymin,y1=opts.ymax;
  if(y1===undefined){y1=0;opts.series.forEach(function(s){s.y.forEach(function(v){if(v>y1)y1=v;});});y1=y1*1.05||1;}
  var X=function(v){return m.l+(v-x0)/(x1-x0)*(W-m.l-m.r);},Y=function(v){return H-m.b-(v-y0)/(y1-y0)*(H-m.t-m.b);};
  var s=sv('svg',{viewBox:'0 0 '+W+' '+H,width:'100%',role:'img'});
  if(opts.title){var t=sv('text',{x:m.l,y:14,class:'title'});t.textContent=opts.title;s.appendChild(t);}
  var ticks=opts.yticks||[0,0.25,0.5,0.75,1].map(function(f){return y0+f*(y1-y0);});
  ticks.forEach(function(v){s.appendChild(sv('line',{x1:m.l,x2:W-m.r,y1:Y(v),y2:Y(v),class:'gridline'}));
    var t=sv('text',{x:m.l-5,y:Y(v)+4,'text-anchor':'end'});t.textContent=(Math.round(v*100)/100).toString();s.appendChild(t);});
  [-4,-2,0,2,4].filter(function(v){return v>=x0&&v<=x1;}).forEach(function(v){
    s.appendChild(sv('line',{x1:X(v),x2:X(v),y1:m.t,y2:H-m.b,class:'gridline'}));
    var t=sv('text',{x:X(v),y:H-m.b+14,'text-anchor':'middle'});t.textContent=v;s.appendChild(t);});
  var xl=sv('text',{x:(m.l+W-m.r)/2,y:H-3,'text-anchor':'middle'});xl.textContent=opts.xlab||'\\u03b8';s.appendChild(xl);
  opts.series.forEach(function(se){var d='';se.y.forEach(function(v,i){d+=(i?'L':'M')+X(opts.x[i]).toFixed(1)+','+Y(v).toFixed(1);});
    s.appendChild(sv('path',{d:d,fill:'none',stroke:se.color,'stroke-width':2}));});
  if(opts.vline!=null)s.appendChild(sv('line',{x1:X(opts.vline),x2:X(opts.vline),y1:m.t,y2:H-m.b,class:'vline'}));
  return s;}
function legend(series){return el('div',{class:'legend'},series.map(function(s){var i=el('i');i.style.background=s.color;return el('span',null,[i,s.name]);}));}

// checkbox list of items
function checks(target,names,selected,onchange){var box=document.getElementById(target);if(!box)return function(){return [];};
  names.forEach(function(nm){var cb=el('input',{type:'checkbox',value:nm});cb.checked=selected.indexOf(nm)>=0;
    cb.addEventListener('change',onchange);box.appendChild(el('label',null,[cb,' '+nm]));});
  return function(){return Array.prototype.filter.call(box.querySelectorAll('input'),function(c){return c.checked;}).map(function(c){return c.value;});};}

// items panel
if(D.items){var names=D.items.item;
  function detail(i){var box=document.getElementById('item-detail');box.innerHTML='';var nm=names[i];
    if(D.cards&&D.cards[nm]){box.appendChild(el('img',{src:D.cards[nm],class:'plot',alt:'Item health card for '+nm}));return;}
    if(D.trace){var it=D.trace.items.filter(function(x){return x.name===nm;})[0];box.appendChild(itemChart(it,'prob',null,520,300));return;}
    box.appendChild(el('p',{class:'note',text:'No item curves for this model.'}));}
  table('tbl-items',D.items,{status:'status',onclick:detail,selected:0});detail(0);}

function itemChart(it,type,theta,w,h){var x=D.trace.theta,series;
  if(type==='expected')series=[{name:'Expected score',y:it.expected,color:PAL[7]}];
  else if(it.dich)series=[{name:'P(correct)',y:it.probs[it.probs.length-1],color:PAL[7]}];
  else series=it.probs.map(function(p,k){return {name:'Category '+it.cats[k],y:p,color:PAL[k%PAL.length]};});
  var ymax=type==='expected'?Math.max(1,Number(it.cats[it.cats.length-1])):1,ymin=type==='expected'?Number(it.cats[0]):0;
  var wrap=el('div');wrap.appendChild(chart({x:x,series:series,ymin:ymin,ymax:ymax,title:it.name,vline:theta,width:w,height:h,
    yticks:type==='expected'?null:[0,0.25,0.5,0.75,1]}));
  if(series.length>1)wrap.appendChild(legend(series));return wrap;}

// curves panel
if(D.trace&&document.getElementById('curves')){var all=D.trace.items.map(function(x){return x.name;});
  var slider=document.getElementById('theta');
  var picked=checks('curve-items',all,all.slice(0,4),drawCurves);
  document.querySelectorAll('input[name=curve-type]').forEach(function(r){r.addEventListener('change',drawCurves);});
  slider.addEventListener('input',drawCurves);
  function drawCurves(){var th=Number(slider.value);document.getElementById('theta-val').textContent=th.toFixed(1);
    var type=document.querySelector('input[name=curve-type]:checked').value;
    var box=document.getElementById('curves');box.innerHTML='';var sel=picked();
    var items=D.trace.items.filter(function(x){return sel.indexOf(x.name)>=0;});
    if(!items.length){box.appendChild(el('p',{class:'note',text:'Choose at least one item.'}));}
    items.forEach(function(it){box.appendChild(itemChart(it,type,th));});
    var j=0,best=Infinity;D.trace.theta.forEach(function(v,i){if(Math.abs(v-th)<best){best=Math.abs(v-th);j=i;}});
    var maxc=0;items.forEach(function(it){if(it.cats.length>maxc)maxc=it.cats.length;});
    var cats=[];items.forEach(function(it){it.cats.forEach(function(c){if(cats.indexOf(c)<0)cats.push(c);});});
    cats.sort(function(a,b){return Number(a)-Number(b);});
    var t=el('table'),hr=el('tr',null,[el('th',{text:'Item'}),el('th',{class:'num',text:'Expected score'})]);
    cats.forEach(function(c){hr.appendChild(el('th',{class:'num',text:'P('+c+')'}));});
    t.appendChild(el('thead',null,[hr]));var tb=el('tbody');
    items.forEach(function(it){var tr=el('tr',null,[el('td',{text:it.name}),el('td',{class:'num',text:it.expected[j].toFixed(3)})]);
      cats.forEach(function(c){var k=it.cats.indexOf(c);tr.appendChild(el('td',{class:'num',text:k<0?'':it.probs[k][j].toFixed(3)}));});
      tb.appendChild(tr);});
    t.appendChild(tb);var at=document.getElementById('at-theta');at.innerHTML='';at.appendChild(el('div',{class:'table-wrap'},[t]));}
  drawCurves();}

// item information
if(D.iteminfo){var inames=Object.keys(D.iteminfo.items);
  var ipicked=checks('info-items',inames,inames.slice(0,5),drawInfo);
  function drawInfo(){var box=document.getElementById('iteminfo');box.innerHTML='';var sel=ipicked();
    if(!sel.length){box.appendChild(el('p',{class:'note',text:'Choose at least one item.'}));return;}
    var series=sel.map(function(nm,k){return {name:nm,y:D.iteminfo.items[nm],color:PAL[k%PAL.length]};});
    box.appendChild(chart({x:D.iteminfo.theta,series:series,ymin:0,width:520,height:300}));box.appendChild(legend(series));}
  drawInfo();}

if(D.conv)table('tbl-conv',D.conv,{search:false});
if(D.persons)table('tbl-persons',D.persons,{searchCols:['ID'],placeholder:'Search ID'});
if(D.dif)table('tbl-dif',D.dif,{search:false});
if(D.rt)table('tbl-rt',D.rt,{search:false});
var rtSel=document.getElementById('rt-plot');
if(rtSel)rtSel.addEventListener('change',function(){document.querySelectorAll('.rt-img').forEach(function(i){i.hidden=i.dataset.plot!==rtSel.value;});});
})();
"
