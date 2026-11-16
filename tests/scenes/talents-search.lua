--@ title: Talents: search, Secondary locked
--@ roots: PolestarUITalents, PolestarMenu
--@ stubs: stub_talents.lua
-- Before dual spec, Secondary is listed locked: a click does nothing, its tooltip says how to learn it. The search, at the top of the filter's dropdown (focused as it opens), marks the talents whose name or description matches; the filter is lit while it runs.
PolestarUI.Show("talents")
local f = PolestarUITalents
local sec
for _, b in ipairs(f.tabButtons) do if b.psKey == 2 and b:IsShown() then sec = b end end
assert(sec, "no Secondary")
sec:Click()
assert(f.Title:GetText() == "Talents" and not f.Subtitle:GetText():find("active spec"), "locked spec opened")
stub.RunScript(sec, "OnEnter")
assert(table.concat(GameTooltip.lines, "/"):find("trainer"), "no unlock hint")
local s = f.Search
assert(not s:IsShown(), "search on the tab row")
f.psFilter:Click()
assert(s:IsShown() and s:GetParent() == PolestarMenu, "search not in the dropdown")
s:SetText("frost")
stub.RunScript(s, "OnTextChanged")
assert(f.Subtitle:GetText():find("talents? match") and f.psFilter.psActive, "no count: " .. f.Subtitle:GetText())
