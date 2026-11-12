--@ title: Spellbook: Fire
--@ roots: PolestarUISpellbook
--@ stubs: stub_spellbook.lua
-- The spellbook key opens ours without the stock book, and closes it again (docs/CLIENT.md, rule 8).
stub.pressKey("P")
assert(not PlayerSpellsFrame:IsShown(), "stock book open")
assert(PolestarUISpellbook:IsShown(), "ours closed")
stub.pressKey("P")
assert(not PolestarUISpellbook:IsShown(), "no toggle")
PolestarUI.Show("spellbook", "line3")
-- In combat the client blocks a spell pickup from addon code: a row's drag does nothing then.
local row
for _, c in ipairs({ PolestarUISpellbook.Body:GetChildren() }) do if c.psSpell and c:IsShown() then row = c; break end end
stub.inCombat = true
stub.RunScript(row, "OnDragStart")
stub.inCombat = false
assert(not stub.blocked, "spell pickup blocked in combat")
stub.RunScript(row, "OnDragStart")
assert(stub.pickedSpell, "no spell pickup out of combat")
assert(PolestarUISpellbook.psClass:GetAtlas() == "classicon-mage", "class icon not the class atlas")
