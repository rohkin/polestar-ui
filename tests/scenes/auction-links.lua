--@ title: Auction House: tooltips, links and long lists
--@ roots: PolestarUIAuction
--@ stubs: stub_npc.lua, stub_auction.lua
-- The stock rows' tooltip: the item's link, then a listing's sellers and time left, the player's bid status, and on the player's own auction its high bidder, asked for when not known yet (RequestOwnedAuctionBidderInfo) and shown as it comes in. A modified click on a row dresses up or links in chat, as the stock rows; a link shift-clicked with no chat line open searches for its item. A long list asks for its next page within 30 rows of its end, once per page; a failed browse says so. Shown last: the failed browse.
local T = Enum.PlayerInteractionType
stub.interact(T.Auctioneer)
local f = PolestarUIAuction
local function rows()
	local out = {}
	for _, r in ipairs({ f.Body:GetChildren() }) do if r.psKey and r:IsShown() then out[#out + 1] = r end end
	table.sort(out, function(a, b) return a:GetTop() > b:GetTop() end)
	return out
end
local function tip() return table.concat(GameTooltip.lines, "\n") end
local function search(text)
	f.Search:SetText(text)
	stub.RunScript(f.Search, "OnTextChanged", true)
	stub.RunScript(f.Search, "OnEnterPressed")
end

-- A long list: the next page asked for, once.
stub.morePages = 1
search("")
assert(stub.moreAsked == 1, "the next page not asked for: " .. stub.moreAsked)
stub.fire("AUCTION_HOUSE_BROWSE_RESULTS_ADDED")
assert(stub.moreAsked == 1, "the same page asked for twice")

-- A listing's tooltip: the link, sellers, time left.
search("axe")
rows()[1]:Click()
stub.RunScript(rows()[1], "OnEnter")
assert(stub.tipLink:find("item:6975", 1, true) and tip():find("Seller: Seller901", 1, true) and tip():find("Time left", 1, true), "the listing's tooltip: " .. tip())
-- A modified click: dress-up, a chat link; nothing bought.
stub.modified.DRESSUP, stub.modified.any = true, true
rows()[1]:Click()
assert(stub.dressed and stub.dressed:find("item:6975", 1, true) and not (PolestarModal and PolestarModal:IsShown()), "not dressed up")
stub.modified.DRESSUP = nil
stub.modified.CHATLINK = true
stub.chatWindow = {}
rows()[1]:Click()
assert(stub.linked and stub.linked:find("item:6975", 1, true), "not linked")
stub.modified.CHATLINK, stub.modified.any, stub.chatWindow = nil, nil, nil
-- A link shift-clicked with no chat line open: searched for.
f.footerButtons.left[1]:Click()
ChatFrameUtil.InsertLink(C_AuctionHouse.GetItemKeySampleLink({ itemID = 2592 }))
assert(tostring(f.Search:GetText()) == "Wool Cloth", "the link not put in the search: " .. tostring(f.Search:GetText()))

-- The player's own: its high bidder, as it comes in.
f.tabButtons[3]:Click()
local axe
for _, r in ipairs(rows()) do if tostring(r.Name:GetText()) == "Whirlwind Axe" then axe = r end end
stub.RunScript(axe, "OnEnter")
assert(not tip():find("High bidder", 1, true), "a bidder before one is known")
stub.fire("OWNED_AUCTION_BIDDER_INFO_RECEIVED", 702, "Thrall")
assert(tip():find("High bidder: Thrall", 1, true), "the bidder not shown as it came in: " .. tip())


-- A failed browse.
f.tabButtons[1]:Click()
search("bread")
stub.fire("AUCTION_HOUSE_BROWSE_FAILURE")
assert(f.psEmpty:IsShown() and tostring(f.psEmpty:GetText()):find("could not", 1, true), "the failure not said")
