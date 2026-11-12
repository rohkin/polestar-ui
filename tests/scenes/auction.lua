--@ title: Auction House
--@ roots: PolestarUIAuction
--@ stubs: stub_npc.lua, stub_auction.lua
-- The auctioneer opens ours, never the stock window, and the stock addon is never loaded: Forever's AUCTION_HOUSE_SHOW route is stopped and the interaction taken, and ours opens and closes on either route alone or both at once; the bags open with it; closing ours ends the auction house once, the game ending it closes ours without ending it again. The sidebar names the auction house with the player's money and lists the categories; Enter in the search browses (by text and category), each result a row with its lowest price and how many are up; a price over the player's money is red.
local T = Enum.PlayerInteractionType
local ns = PolestarUI
assert(ns.modules.auction.reloadOff, "switching off does not wait for /reload")
assert(stub.unrouted.AUCTION_HOUSE_SHOW and stub.unrouted.AUCTION_HOUSE_CLOSED, "the GameEvent routes still open the stock window")
-- Only the event: it opens ours, never the stock window; closing ours ends the auction house, the game's close event closes ours without ending it again.
stub.fire("AUCTION_HOUSE_SHOW")
local f = PolestarUIAuction
assert(f and f:IsShown() and not AuctionHouseFrame:IsShown() and not stub.stockLoaded, "the event did not open ours")
assert(stub.bagsOpen and stub.bagsOpener == "PolestarUIAuction", "the event opened no bags")
f:Hide()
assert(stub.npcClosed.CloseAuctionHouse == 1 and not stub.bagsOpen, "closing ours did not end the auction house")
stub.fire("AUCTION_HOUSE_SHOW")
stub.fire("AUCTION_HOUSE_CLOSED")
assert(not f:IsShown() and stub.npcClosed.CloseAuctionHouse == 1, "the close event did not close ours, or ended it again")
-- Both routes: opened once, closed once.
stub.interact(T.Auctioneer)
stub.fire("AUCTION_HOUSE_SHOW")
assert(f:IsShown() and not stub.stockLoaded, "both routes")
stub.endInteraction(T.Auctioneer)
stub.fire("AUCTION_HOUSE_CLOSED")
assert(not f:IsShown() and stub.npcClosed.CloseAuctionHouse == 1 and not stub.bagsOpen, "both closes ended it again")
stub.npcClosed.CloseAuctionHouse = 0

-- Only the interaction.
stub.interact(T.Auctioneer)
assert(f:IsShown() and not AuctionHouseFrame:IsShown() and not stub.stockLoaded, "the auctioneer did not open ours")
assert(stub.bagsOpen and stub.bagsOpener == "PolestarUIAuction", "bags not opened by ours")
f:Hide()
assert(stub.npcClosed.CloseAuctionHouse == 1 and not stub.bagsOpen, "closing ours did not end the auction house once")
stub.interact(T.Auctioneer)
stub.endInteraction(T.Auctioneer)
assert(not f:IsShown() and stub.npcClosed.CloseAuctionHouse == 1, "the game's end was ended again")

stub.interact(T.Auctioneer)
assert(tostring(f.psMoney.psParts[1].text:GetText()) == "123", "the player's money")
local function rows()
	local out = {}
	for _, r in ipairs({ f.Body:GetChildren() }) do if r.psKey and r:IsShown() then out[#out + 1] = r end end
	table.sort(out, function(a, b) return a:GetTop() > b:GetTop() end)
	return out
end
assert(#rows() == 0, "results before any search")

-- A search by text: Enter sends it, its results are rows.
f.Search:SetText("cloth")
stub.RunScript(f.Search, "OnTextChanged", true)
stub.RunScript(f.Search, "OnEnterPressed")
assert(stub.browseQuery.searchString == "cloth" and #stub.browseQuery.itemClassFilters == 0, "the search not sent")
local r = rows()
assert(#r == 2 and tostring(r[1].Name:GetText()) == "Linen Cloth" and tostring(r[1].Note:GetText()) == "350 available", "the cloth results")
assert(tostring(r[2].Money.psParts[2].text:GetText()) == "4", "the lowest price")

-- A category narrows by its item classes; All lifts it.
f.Search:SetText("")
stub.RunScript(f.Search, "OnTextChanged", true)
local weapons
for _, b in ipairs(f.navButtons) do if b:IsShown() and tostring(b.Label:GetText()) == "Weapons" then weapons = b end end
weapons:Click()
assert(stub.browseQuery.itemClassFilters[1].classID == 2 and tostring(f.Title:GetText()) == "Weapons", "the category not searched")
r = rows()
assert(#r == 2 and tostring(r[2].Name:GetText()) == "Krol Blade", "the weapons")
stub.money = 100
stub.fire("PLAYER_MONEY")
f.navButtons[1]:Click()
assert(#stub.browseQuery.itemClassFilters == 0 and #rows() == 4, "All")
