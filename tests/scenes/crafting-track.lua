--@ title: Crafting: a recipe tracked
--@ roots: PolestarUICrafting
--@ stubs: stub_spellbook.lua, stub_professions.lua, stub_crafting.lua
-- "Track recipe", as the stock page's checkbox (C_TradeSkillUI.SetRecipeTracked): the box and its label toggle it; a shift-click on a row tracks it while the chat line is closed, as the stock list.
stub.openTradeSkill()
local f = PolestarUICrafting
local function row(n) for _, r in ipairs({ f.NavScroll.Child:GetChildren() }) do if r:IsShown() and r.psRecipe and r.psRecipe.name == n then return r end end end
row("Soft-soled Linen Boots"):Click()
local tr = f.psTrack
assert(tr:IsShown() and not tr.Box:GetChecked(), "no Track recipe")
tr.Box:Click()
assert(stub.trackedRecipes[3845] and tr.Box:GetChecked(), "not tracked")
tr:Click()
assert(not stub.trackedRecipes[3845] and not tr.Box:GetChecked(), "still tracked")
local mod = IsModifiedClick
IsModifiedClick = function(k) return k == "CHATLINK" or k == "RECIPEWATCHTOGGLE" end
stub.RunScript(row("Linen Bag"), "OnClick", "LeftButton")
IsModifiedClick = mod
assert(stub.trackedRecipes[3755], "shift-click did not track")
tr.Box:Click()
