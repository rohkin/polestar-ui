--@ title: Crafting: a level search
--@ roots: PolestarUICrafting
--@ stubs: stub_spellbook.lua, stub_professions.lua, stub_crafting.lua
-- As the stock search box: "10-15" or "~17" searches by item level through the client's level filter (SetRecipeItemLevelFilter), cleared again by a name search.
stub.openTradeSkill()
local f = PolestarUICrafting
local function names()
	local n = {}
	for _, r in ipairs({ f.NavScroll.Child:GetChildren() }) do if r:IsShown() and r.psRecipe then n[r.psRecipe.name] = true end end
	return n
end
local function search(t) f.Search:SetText(t); stub.RunScript(f.Search, "OnTextChanged") end
search("~17")
local n = names()
assert(n["Linen Bag"] and n["Soft-soled Linen Boots"] and not n["Brown Linen Vest"] and not n["Mooncloth"], "~17")
search("linen")
n = names()
assert(n["Brown Linen Vest"] and n["Bolt of Linen Cloth"], "name search kept the level filter")
search("10-15")
n = names()
assert(n["Brown Linen Vest"] and n["Linen Bag"] and not n["Soft-soled Linen Boots"], "10-15")
assert(not names()["Bolt of Linen Cloth"] and f.Title:GetText() == "Tailoring", "a level search is not a search")
