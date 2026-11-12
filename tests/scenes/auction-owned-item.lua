--@ title: Auction House: one item of yours
--@ roots: PolestarUIAuction
--@ stubs: stub_npc.lua, stub_auction.lua
-- The stock summary list in the sidebar on Auctions and Bids: all of them, then each item among them (GetOwnedAuctionType, GetBidType). An item picked shows all its listings (SendSearchQuery, the player's own kept apart): the player's own to cancel after our dialog, the others to buy out or bid on as on Buy; a commodity's own listing cancels too. An item no longer among them goes back to all. Shown last: Whirlwind Axe on Auctions.
local T = Enum.PlayerInteractionType
stub.money = 50000000
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
f.tabButtons[3]:Click()
assert(nav("All auctions") and nav("Wool Cloth") and nav("Whirlwind Axe (42)") and nav("Linen Cloth") and not nav("Weapons"), "the summary list")
assert(nav("All auctions").Selected:IsShown(), "all not picked")

-- An item: its listings; the player's own cancels, another buys out.
nav("Whirlwind Axe (42)"):Click()
assert(stub.searchQuery.key.itemID == 6975 and stub.searchQuery.sorts[1].sortOrder == Enum.AuctionHouseSortOrder.Buyout, "the item's listings not asked for")
local r = rows()
assert(#r == 3 and tostring(r[3].Line:GetText()) == "You", "the listings")
r[3]:Click()
assert(PolestarModal:IsShown() and tostring(PolestarModal.Box.Title:GetText()) == "Cancel this auction?", "the player's own not to cancel")
PolestarModal.Box.Action:Click()
assert(stub.cancelled[1] == 903, "not cancelled")
r[1]:Click("LeftButton")
PolestarModal.Box.Action:Click()
assert(stub.bids[1][1] == 901 and stub.bids[1][2] == 1800000, "another's not bought out")

-- A commodity: the player's own listing cancels.
nav("Linen Cloth"):Click()
r = rows()
assert(#r == 3 and tostring(r[3].Line:GetText()) == "2 sellers", "the commodity's listings")
r[3]:Click()
PolestarModal.Box.Action:Click()
assert(stub.cancelled[2] == 503, "the commodity listing not cancelled")
r[1]:Click()
assert(not PolestarModal:IsShown(), "another's commodity listing took a click")

-- Bids: all bids, then each item bid on.
f.tabButtons[4]:Click()
assert(nav("All bids") and nav("Krol Blade (40)") and nav("All bids").Selected:IsShown(), "the bids' summary list")
nav("Whirlwind Axe (42)"):Click()
assert(tostring(f.Title:GetText()) == "Whirlwind Axe (42)" and #rows() == 3, "a bid item's listings")

-- An item no longer among them: back to all.
f.tabButtons[3]:Click()
nav("Wool Cloth"):Click()
table.remove(stub.owned, 1)
stub.fire("OWNED_AUCTIONS_UPDATED")
assert(tostring(f.Title:GetText()) == "Your auctions" and nav("All auctions").Selected:IsShown(), "not back to all")
nav("Whirlwind Axe (42)"):Click()
