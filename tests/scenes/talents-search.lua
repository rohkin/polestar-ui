--@ title: Talents: search, Secondary locked
--@ roots: PolestarUITalents
--@ stubs: stub_talents.lua
-- Before dual spec, Secondary is listed locked: a click does nothing, its tooltip says how to learn it. The search marks the talents whose name or description matches.
PolestarUI.Show("talents")
local f = PolestarUITalents
local sec
for _, b in ipairs(f.navButtons) do if b.psKey == 2 and b:IsShown() then sec = b end end
assert(sec, "no Secondary")
sec:Click()
assert(f.Title:GetText() == "Talents" and not f.Subtitle:GetText():find("active spec"), "locked spec opened")
stub.RunScript(sec, "OnEnter")
assert(table.concat(GameTooltip.lines, "/"):find("trainer"), "no unlock hint")
local s = f.Search
s:SetText("frost")
stub.RunScript(s, "OnTextChanged")
assert(f.Subtitle:GetText():find("talents? match"), "no count: " .. f.Subtitle:GetText())
