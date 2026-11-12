--@ title: Auction House: favorites
--@ roots: PolestarUIAuction
--@ stubs: stub_npc.lua, stub_auction.lua
-- The stock favorites: a star at the end of each browse row, lit on a favorite, and the stock right-click menu (Set favorite, Remove favorite); an item's listings set it from the footer. Favorites in the sidebar lists them (SearchForFavorites), dimmed while there are none; the window opens on them when there are any, as the stock one does. Past the most allowed, a new one is refused. Shown last: the favorites, listed as the window opened.
local T = Enum.PlayerInteractionType
stub.interact(T.Auctioneer)
local f = PolestarUIAuction
local function nav(label)
	for _, b in ipairs(f.navButtons) do if b:IsShown() and tostring(b.Label:GetText()) == label then return b end end
end
local function rows()
	local out = {}
	for _, r in ipairs({ f.Body:GetChildren() }) do if r.psKey and r:IsShown() then out[#out + 1] = r end end
	table.sort(out, function(a, b) return a:GetTop() > b:GetTop() end)
	return out
end
local function named(name)
	for _, r in ipairs(rows()) do if tostring(r.Name:GetText()):find(name, 1, true) then return r end end
end
assert(stub.browseQuery == nil, "a search on opening with no favorites")
assert(nav("Favorites").psEmpty, "Favorites not dimmed with none")
nav("Favorites"):Click()
assert(stub.browseQuery == nil, "an empty favorites search")

-- The star: a click sets it, lit at once; the right-click menu sets another.
f.Search:SetText("cloth")
stub.RunScript(f.Search, "OnTextChanged", true)
stub.RunScript(f.Search, "OnEnterPressed")
local linen = named("Linen")
assert(linen.Fav:IsShown() and not linen.Fav.psActive, "the star")
linen.Fav:Click()
assert(stub.favorites[2589] and named("Linen").Fav.psActive, "the star not set")
named("Wool"):Click("RightButton")
local item
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() then item = r end end
assert(tostring(item.Text:GetText()) == "Set favorite", "the right-click menu")
item:Click()
assert(stub.favorites[2592] and not nav("Favorites").psEmpty, "the menu did not set it")

-- An item's listings: the footer sets it; past the most allowed, refused.
stub.maxFavorites = 2
f.Search:SetText("axe")
stub.RunScript(f.Search, "OnEnterPressed")
named("Whirlwind").Fav:Click()
assert(not stub.favorites[6975], "past the most allowed")
stub.maxFavorites = 3
named("Whirlwind"):Click()
local set = f.footerButtons.left[3]
assert(tostring(set.Label:GetText()) == "Set favorite", "the footer's favorite")
set:Click()
assert(stub.favorites[6975] and tostring(f.footerButtons.left[3].Label:GetText()) == "Remove favorite", "not set from the footer")
f.footerButtons.left[3]:Click()
assert(not stub.favorites[6975], "not removed")

-- Favorites lists them; the window opens on them.
nav("Favorites"):Click()
assert(stub.browseQuery.favorites and tostring(f.Title:GetText()) == "Favorites" and #rows() == 2, "the favorites")
f:Hide()
stub.browseQuery = nil
stub.interact(T.Auctioneer)
assert(stub.browseQuery and stub.browseQuery.favorites and #rows() == 2 and nav("Favorites").Selected:IsShown(), "not opened on the favorites")
