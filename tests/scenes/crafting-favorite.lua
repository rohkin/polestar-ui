--@ title: Crafting: favorites
--@ roots: PolestarUICrafting, PolestarMenu
--@ stubs: stub_spellbook.lua, stub_professions.lua, stub_crafting.lua
-- Favorites first in the list, as the stock list groups them; the star on the recipe page sets or removes one, lit while it is; the list's right-click menu does the same (C_TradeSkillUI.SetRecipeFavorite).
stub.openTradeSkill()
local f = PolestarUICrafting
local function heads()
	local t = {}
	for _, r in ipairs({ f.NavScroll.Child:GetChildren() }) do
		if r:IsShown() and r.Label and not r.psRecipe then t[#t + 1] = { r:GetTop() or -select(5, r:GetPoint(1)), r.Label:GetText() } end
	end
	table.sort(t, function(a, b) return a[1] < b[1] end)
	local n = {}
	for i, h in ipairs(t) do n[i] = h[2] end
	return table.concat(n, ",")
end
local function row(n, key) for _, r in ipairs({ f.NavScroll.Child:GetChildren() }) do if r:IsShown() and r.psRecipe and r.psRecipe.name == n and (not key or r.psKey == key) then return r end end end
assert(heads():find("^Favorites,") and row("Linen Bag", "fav"), "no Favorites first: " .. heads())
row("Brown Linen Vest", "c11"):Click()
local star = f.psProduct.Fav
assert(star:IsShown() and not star.psActive, "star")
star:Click()
assert(stub.favorites[2385] and star.psActive and row("Brown Linen Vest", "fav"), "not a favorite")
stub.RunScript(row("Linen Bag", "fav"), "OnClick", "RightButton")
local item
for _, r in ipairs({ PolestarMenu:GetChildren() }) do if r:IsShown() and r.Text and r.Text:GetText() == "Remove favorite" then item = r end end
item:Click()
assert(not stub.favorites[3755] and not row("Linen Bag", "fav"), "still a favorite")
