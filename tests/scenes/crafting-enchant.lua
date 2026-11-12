--@ title: Crafting: an enchant on the worn chest
--@ roots: PolestarUICrafting
--@ stubs: stub_spellbook.lua, stub_professions.lua, stub_crafting.lua
-- An enchant: without an item Craft casts it for the game to ask; the item slot lists what it can go on (the worn one marked), and Craft then enchants that item, one at a time.
stub.enchanting = true
stub.openTradeSkill()
local f = PolestarUICrafting
local row
for _, r in ipairs({ f.NavScroll.Child:GetChildren() }) do if r:IsShown() and r.psRecipe and r.psRecipe.name == "Enchant Chest - Minor Health" then row = r end end
row:Click()
local t = f.psTarget
assert(t:IsShown() and t.Name:GetText() == "Add an item", "no item slot")
local craft = f.footerButtons.right[1]
craft:Click()
assert(stub.crafted[1] == 7420 and not stub.enchanted, "cast without an item")
stub.RunScript(t, "OnClick", "LeftButton")
local pick
for _, r in ipairs({ PolestarMenu:GetChildren() }) do if r:IsShown() and r.Text and r.Text:GetText() == "Breastplate of the Long Watch (equipped)" then pick = r end end
assert(pick, "worn item not listed")
pick:Click()
assert(t.Name:GetText() == "Breastplate of the Long Watch", "not chosen")
assert(not f.psStep.More:IsEnabled(), "more than one enchant on one item")
craft:Click()
assert(stub.enchanted[1] == 7420 and stub.enchanted[2] == 1 and stub.enchanted[3] == "Item-worn-5", "not enchanted")
stub.RunScript(t, "OnClick", "RightButton")
assert(t.Name:GetText() == "Add an item", "not cleared")
stub.RunScript(t, "OnClick", "LeftButton")
for _, r in ipairs({ PolestarMenu:GetChildren() }) do if r:IsShown() and r.Text and r.Text:GetText() == "Breastplate of the Long Watch (equipped)" then r:Click() end end
