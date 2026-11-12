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
-- The assisted combat spell, where the client has one, comes first under General, as the stock book shows it above its pages.
AssistedCombatManager = { HasActionSpell = function() return true end, GetActionSpellID = function() return 111 end }
PolestarUI.Show("spellbook", "line1")
local names = {}
for _, c in ipairs({ PolestarUISpellbook.Body:GetChildren() }) do if c.psSpell and c:IsShown() then names[#names + 1] = c.psSpell.info.name end end
assert(table.concat(names, ","):find("Fire Blast") and #names == 4, "no assisted spell: " .. table.concat(names, ","))
AssistedCombatManager = nil
PolestarUI.Show("spellbook", "line3")
