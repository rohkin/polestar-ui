--@ title: Professions
--@ roots: PolestarUIProfessions
--@ stubs: stub_spellbook.lua, stub_professions.lua
-- The professions key opens ours and closes it, never the stock window; hovering a profession's spell puts the secure cast button over it; unlearning asks first; the professions on its section rail, the overview marked.
stub.pressKey("K")
assert(PolestarUIProfessions:IsShown() and not ProfessionsFrame:IsShown(), "key")
stub.pressKey("K")
assert(not PolestarUIProfessions:IsShown(), "no toggle")
PolestarUI.Show("professions")
local byName = {}
for _, c in ipairs({ PolestarUIProfessions.Body:GetChildren() }) do for _, r in ipairs(c.rows or {}) do if r:IsShown() then byName[r.psSpell.info.name] = r end end end
stub.RunScript(byName["Smelting"], "OnEnter")
local o = PolestarUISpellbookCast
assert(o and o:IsShown() and o:GetAttribute("type1") == "spell" and o:GetAttribute("spell") == byName["Smelting"].psSpell.info.spellID, "no cast")
o:Hide()
local tail = byName["Tailoring"]:GetParent()
tail.Unlearn:Click()
assert(not stub.abandoned, "unlearnt without asking")
PolestarModal.Box.Action:Click()
assert(stub.abandoned == 197, "not unlearnt")
local art = tail.psArt[2]
assert(art:IsShown() and tail.psArt[1].gradient.min[4] == 0 and tail.psArt[3].gradient.max[4] == 0, "no card art, or not feathered at its sides")
local tabs, on = 0
for _, t in ipairs(PolestarUIProfessions.railButtons) do if t:IsShown() then tabs = tabs + 1
if t.psActive then on = t.psName end end end
assert(tabs == 5 and on == "Overview", "tabs: " .. tabs)
assert(select(2, PolestarUIProfessions.Main:GetPoint(1)) == PolestarUIProfessions, "main column hangs off the 0-wide sidebar (docs/CLIENT.md, rule 12)")
