--@ title: Spellbook: Summon Demon opened
--@ roots: PolestarUISpellbook
--@ stubs: stub_spellbook.lua
-- A flyout whose spells are hidden from the book, as the warlock's Summon Demon: opened, it lists the demons the player knows (found with includeHidden, never the flyout itself again); one not learnt is left out.
stub.warlock = true
PolestarUI.Show("spellbook", "line4")
local f = PolestarUISpellbook
local function names()
	local n = {}
	for _, c in ipairs({ f.Body:GetChildren() }) do if c.psSpell and c:IsShown() then n[#n + 1] = c.psSpell.info.name end end
	table.sort(n)
	return table.concat(n, ",")
end
local flyout
for _, c in ipairs({ f.Body:GetChildren() }) do if c:IsShown() and c.psSpell and c.psSpell.info.name == "Summon Demon" then flyout = c end end
assert(names() == "Summon Demon" and flyout.Sub:GetText() == "2 spells", "flyout not one entry of its known spells: " .. names())
stub.RunScript(flyout, "OnClick", "LeftButton")
assert(names() == "Summon Demon,Summon Imp,Summon Voidwalker", "not the demons: " .. names())
