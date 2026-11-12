--@ title: Spellbook: filter
--@ roots: PolestarUISpellbook, PolestarMenu
--@ stubs: stub_spellbook.lua
-- The stock book's settings on a Filter button at the end of the search row: Hide passives and Show all ranks (the stock CVars), lit while one is off its default, "Clear filters" then; a search ignores them, as stock; no ranks for a Rogue.
PolestarUI.Show("spellbook", "line2")
local f = PolestarUISpellbook
local function item(t) for _, r in ipairs({ PolestarMenu:GetChildren() }) do if r:IsShown() and r.Text and r.Text:GetText() == t then return r end end end
local function names()
	local n = {}
	for _, c in ipairs({ f.Body:GetChildren() }) do if c.psSpell and c:IsShown() then n[#n + 1] = c.psSpell.info.name end end
	return table.concat(n, ",")
end
assert(not f.psFilter.psActive and names():find("Arcane Mind"), "default: " .. names())
f.psFilter:Click()
assert(item("Hide passives") and item("Show all ranks") and not item("Clear filters"), "menu")
item("Hide passives"):Click()
assert(PolestarMenu:IsShown() and f.psFilter.psActive and not names():find("Arcane Mind"), "passive shown: " .. names())
item("Show all ranks"):Click()
assert(select(2, names():gsub("Arcane Missiles", "")) == 2, "low rank hidden: " .. names())
f.Search:SetText("arcane")
stub.RunScript(f.Search, "OnTextChanged")
assert(names():find("Arcane Mind"), "a search hid a passive")
f.Search:SetText("")
stub.RunScript(f.Search, "OnTextChanged")
f.psFilter:Click()
f.psFilter:Click()
item("Clear filters"):Click()
assert(not f.psFilter.psActive and stub.cvars.spellBookHidePassives == "0" and stub.cvars.ShowAllSpellRanks == "0", "clear")
UnitClass = function() return "Rogue", "ROGUE", 4 end
f.psFilter:Click()
f.psFilter:Click()
assert(item("Hide passives") and not item("Show all ranks"), "a Rogue has ranks")
UnitClass = function() return "Mage", "MAGE", 8 end
item("Hide passives"):Click()
