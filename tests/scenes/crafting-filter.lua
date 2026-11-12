--@ title: Crafting: filtered
--@ roots: PolestarUICrafting, PolestarMenu
--@ stubs: stub_spellbook.lua, stub_professions.lua, stub_crafting.lua
-- The game's own filters, from the Filter menu on the band: "Have materials" and the Chest slot off leave the bolt and Mooncloth; the menu opens again after each pick.
stub.openTradeSkill()
local f = PolestarUICrafting
stub.RunScript(f.psFilter, "OnClick")
local function item(t) for _, r in ipairs({ PolestarMenu:GetChildren() }) do if r:IsShown() and r.Text and r.Text:GetText() == t then return r end end end
assert(item("Has skill up") and item("Chest"), "no menu")
item("Have materials"):Click()
assert(PolestarMenu:IsShown(), "menu closed")
item("Chest"):Click()
local names = {}
for _, r in ipairs({ f.NavScroll.Child:GetChildren() }) do if r:IsShown() and r.psRecipe then names[r.psRecipe.name] = true end end
assert(names["Bolt of Linen Cloth"] and names["Mooncloth"] and not names["Brown Linen Vest"] and not names["Linen Bag"], "not filtered")
assert(item("Have materials").Check:IsShown() and not item("Chest").Check:IsShown(), "checks wrong")
