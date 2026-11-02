-- PDF edition: turn the HTML boxes and folded solutions into LaTeX.
local boxes = { goals = "goalsbox", yourturn = "yourturnbox", lab = "labbox" }

function Div(el)
  if not FORMAT:match("latex") then return nil end
  for class, env in pairs(boxes) do
    if el.classes:includes(class) then
      return { pandoc.RawBlock("latex", "\\begin{" .. env .. "}"), el,
               pandoc.RawBlock("latex", "\\end{" .. env .. "}") }
    end
  end
end

-- Unnumbered chapters (Preface, About the author, References) do not set the
-- running head, so the previous one would carry over. Set it explicitly.
function Header(el)
  if FORMAT:match("latex") and el.level == 1 and el.classes:includes("unnumbered") then
    local title = pandoc.utils.stringify(el.content)
    return { el, pandoc.RawBlock("latex", "\\markboth{" .. title .. "}{" .. title .. "}") }
  end
end
