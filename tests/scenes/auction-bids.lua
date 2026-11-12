--@ title: Auction House: your bids
--@ roots: PolestarUIAuction
--@ stubs: stub_npc.lua, stub_auction.lua
--@ saved: PolestarUICharDB = { auctionBids = { 801, 802, 803 } }
-- The stock Bids tab: the auctions the player bid on, asked for by the IDs kept per character (QueryBids) as the window opens, so the outbid marks are right. A bid of the player's shows green with "You are the highest bidder"; one bid on before whose bidder is now someone else is red, "Outbid". A click buys out after our dialog; a right-click bids from the least bid, as the stock bid frame: the highest bidder cannot bid again, a bid at the buyout or over buys it out instead, one under the least is refused with the stock error. Shown last: the Bids tab.
local T = Enum.PlayerInteractionType
stub.money = 50000000
stub.interact(T.Auctioneer)
local f = PolestarUIAuction
local ids = stub.bidsQueried and stub.bidsQueried.ids
assert(ids and ids[1] == 801 and ids[3] == 803, "the kept bids not asked for on opening")
assert(#PolestarUICharDB.auctionBids == 2, "the bids list not brought up to date")
f.tabButtons[4]:Click()
assert(tostring(f.Title:GetText()) == "Bids", "not on Bids")
local r = {}
for _, b in ipairs({ f.Body:GetChildren() }) do if b.psKey and b:IsShown() then r[#r + 1] = b end end
table.sort(r, function(a, b) return a:GetTop() > b:GetTop() end)
assert(#r == 2 and tostring(r[1].Line:GetText()) == "You are the highest bidder" and tostring(r[2].Line:GetText()) == "Outbid", "the bid status")
local box = function() return PolestarModal.Box end

-- A click buys out.
r[1]:Click("LeftButton")
box().Action:Click()
assert(stub.bids[1][1] == 801 and stub.bids[1][2] == 1800000, "not bought out")
-- The highest bidder cannot bid again.
r[1]:Click("RightButton")
assert(not PolestarModal:IsShown() and stub.uiError == "You are the highest bidder", "bid again as the highest bidder")
-- A bid under the least is refused; at the buyout or over, it buys out.
r[2]:Click("RightButton")
local input
for _, c in ipairs({ box():GetChildren() }) do if rawget(c, "Set") and c:IsShown() then input = c end end
local gold = ({ input:GetChildren() })[1]
gold:SetText("10")
stub.RunScript(gold, "OnTextChanged", true)
box().Action:Click()
assert(#stub.bids == 1 and stub.uiError == "Your bid is too low.", "a bid under the least placed")
r[2]:Click("RightButton")
gold:SetText("3000")
stub.RunScript(gold, "OnTextChanged", true)
box().Action:Click()
assert(PolestarModal:IsShown() and tostring(box().Title:GetText()) == "Buy out Krol Blade?", "a bid over the buyout did not buy out")
box().Action:Click()
assert(stub.bids[2][1] == 802 and stub.bids[2][2] == 25000000, "not bought out from the bid")
-- At the least: placed.
r[2]:Click("RightButton")
box().Action:Click()
assert(stub.bids[3][1] == 802 and stub.bids[3][2] == 21000000, "the least bid not placed")
-- The stock list's refresh button asks again.
stub.bidsQueried = nil
f.footerButtons.left[1]:Click()
assert(stub.bidsQueried and stub.bidsQueried.ids[1] == 801, "Refresh did not ask again")
