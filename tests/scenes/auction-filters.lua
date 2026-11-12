--@ title: Auction House: search options
--@ roots: PolestarUIAuction, PolestarMenu
--@ stubs: stub_npc.lua, stub_auction.lua
-- The stock search options on the sliders button at the end of the search row: a level range (our dialog with two fields) and the client's filter groups (C_AuctionHouse.GetFilterGroups) under their headings, every rarity on by default; the menu opens again after each pick. They go with the next search (SendBrowseQuery's filters and level range), and an item's auctions keep to the level range (SendSearchQuery). The glyph is lit while an option differs from the default, kept per character; Reset filters puts them back. Shown last: the menu with Usable only on and Poor off.
local T = Enum.PlayerInteractionType
stub.interact(T.Auctioneer)
local f = PolestarUIAuction
assert(f.psFilter and not f.psFilter.psActive, "the options button, lit with nothing set")
local function row(text)
	for _, r in ipairs(PolestarMenu.rows) do
		if r:IsShown() and tostring(r.Text:GetText()):find(text, 1, true) then return r end
	end
end
local function search(text)
	f.Search:SetText(text)
	stub.RunScript(f.Search, "OnTextChanged", true)
	stub.RunScript(f.Search, "OnEnterPressed")
end

-- The defaults go with a search: every rarity, nothing else, any level.
search("axe")
local q = stub.browseQuery
assert(#q.filters == 6 and q.filters[1] == 6 and q.minLevel == 0 and q.maxLevel == 0, "the default filters")

-- The menu: the level range, the groups under their headings.
f.psFilter:Click()
assert(PolestarMenu:IsShown() and row("Level range: any") and row("Equipment") and row("Rarity"), "the menu")
assert(row("Usable only") and not row("Usable only").Check:IsShown() and row("Poor").Check:IsShown(), "the defaults ticked")
row("Usable only"):Click()
assert(PolestarMenu:IsShown() and row("Usable only").Check:IsShown(), "Usable only, the menu open again")
row("Poor"):Click()
assert(f.psFilter.psActive, "the glyph not lit")

-- The level range: our dialog's two fields.
row("Level range"):Click()
local box = PolestarModal.Box
local fields = {}
for _, c in ipairs({ box:GetChildren() }) do if c.Min and c:IsShown() then fields = c end end
fields.Min:SetText("10")
fields.Max:SetText("20")
box.Action:Click()
search("axe")
q = stub.browseQuery
assert(q.minLevel == 10 and q.maxLevel == 20 and q.filters[1] == 2 and #q.filters == 6, "the options not searched")
local first
for _, r in ipairs({ f.Body:GetChildren() }) do if r.psKey and r:IsShown() then first = r end end
first:Click()
assert(stub.searchQuery.minLevel == 10 and stub.searchQuery.maxLevel == 20, "the item's auctions not kept to the level range")

-- Kept per character; Reset filters puts the defaults back.
assert(PolestarUICharDB.auctionFilters.minLevel == 10, "not kept")
f.psFilter:Click()
row("Reset filters"):Click()
assert(not f.psFilter.psActive and PolestarUICharDB.auctionFilters.minLevel == 0 and not next(PolestarUICharDB.auctionFilters.filters), "not reset")
f.footerButtons.left[1]:Click()
f.psFilter:Click()
row("Usable only"):Click()
row("Poor"):Click()
