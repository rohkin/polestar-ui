--@ title: Auction House: buying an item
--@ roots: PolestarUIAuction
--@ stubs: stub_npc.lua, stub_auction.lua
-- An item (not a commodity) opens its auctions: each with its buyout, its next bid and the time left; the player's own says so and takes no click. A click buys out after our dialog, a right-click (or an auction with no buyout) bids from a money field set to the least bid, refusing less; PlaceBid runs from the dialog button's click. Back returns to the results.
local T = Enum.PlayerInteractionType
stub.money = 50000000
stub.interact(T.Auctioneer)
local f = PolestarUIAuction
f.Search:SetText("axe")
stub.RunScript(f.Search, "OnTextChanged", true)
stub.RunScript(f.Search, "OnEnterPressed")
local function rows()
	local out = {}
	for _, r in ipairs({ f.Body:GetChildren() }) do if r.psKey and r:IsShown() then out[#out + 1] = r end end
	table.sort(out, function(a, b) return a:GetTop() > b:GetTop() end)
	return out
end
rows()[1]:Click()
assert(tostring(f.Title:GetText()) == "Whirlwind Axe" and not f.psBuy:IsShown(), "the item not opened")
local r = rows()
assert(#r == 3, "an auction per row")
local function cell(r, i) return tostring(r.Cells[i].Text:GetText()) end
assert(tostring(r[1].Line:GetText()) == "Seller901" and cell(r[1], 4) == "Over 12 h" and r[1].Cells[2].Money:IsShown(), "buyout, seller and time left")
assert(tostring(r[2].Line:GetText()) == "Seller902, bid only" and tostring(r[3].Line:GetText()) == "You", "bid only, and yours")
local box = function() return PolestarModal.Box end

-- Buyout.
r[1]:Click("LeftButton")
assert(#stub.bids == 0 and PolestarModal:IsShown(), "bought out without asking")
box().Action:Click()
assert(stub.bids[1][1] == 901 and stub.bids[1][2] == 1800000, "not bought out")
-- A bid at the least amount.
r[1]:Click("RightButton")
box().Action:Click()
assert(stub.bids[2][1] == 901 and stub.bids[2][2] == 1500000, "the least bid not placed")
-- No buyout: a click bids; less than the least is refused.
r[2]:Click("LeftButton")
local input
for _, c in ipairs({ box():GetChildren() }) do if rawget(c, "Set") and c:IsShown() then input = c end end
local gold = ({ input:GetChildren() })[1]
gold:SetText("100")
stub.RunScript(gold, "OnTextChanged", true)
box().Action:Click()
assert(#stub.bids == 2, "a bid under the least placed")
-- The player's own: nothing.
r[3]:Click("LeftButton")
assert(not PolestarModal:IsShown() and #stub.bids == 2, "the player's own auction took a click")
-- Back to the results, then the item again for the picture.
f.footerButtons.left[1]:Click()
assert(tostring(f.Title:GetText()) == "Browse" and #rows() == 1, "Back")
rows()[1]:Click()
