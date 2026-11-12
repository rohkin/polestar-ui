--@ title: Spellbook: Arcane
--@ roots: PolestarUISpellbook
--@ stubs: stub_spellbook.lua
-- Lower ranks hidden (the stock setting), a passive and a spell not learned yet; hovering a spell puts the secure cast button over it, a passive gets none.
PolestarUI.Show("spellbook", "line2")
local f = PolestarUISpellbook
local byName = {}
for _, c in ipairs({ f.Body:GetChildren() }) do if c.psSpell and c:IsShown() then byName[c.psSpell.info.name] = c end end
assert(not byName["Arcane Missiles"] or byName["Arcane Missiles"].psSpell.info.subName == "Rank 3", "low rank shown")
stub.RunScript(byName["Blink"], "OnEnter")
local o = PolestarUISpellbookCast
assert(o and o:IsShown() and o:GetAttribute("type1") == "spell" and o:GetAttribute("spell") == 107, "no cast")
stub.RunScript(byName["Arcane Mind"], "OnEnter")
assert(o:GetAttribute("type1") == nil, "passive casts")
