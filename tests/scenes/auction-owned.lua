--@ title: Auction House: your auctions
--@ roots: PolestarUIAuction
--@ stubs: stub_npc.lua, stub_auction.lua
-- The Auctions tab asks for the player's auctions (QueryOwnedAuctions) and lists them: count, price, time left, or Sold. A click on an active one asks in our dialog, naming the cancel fee when there is one, and CancelAuction runs from that click; a sold one takes no click. AUCTION_CANCELED asks for the list again.
local T = Enum.PlayerInteractionType
stub.interact(T.Auctioneer)
local f = PolestarUIAuction
f.tabButtons[3]:Click()
assert(tostring(f.Title:GetText()) == "Your auctions", "not on Auctions")
local r = {}
for _, b in ipairs({ f.Body:GetChildren() }) do if b.psKey and b:IsShown() then r[#r + 1] = b end end
table.sort(r, function(a, b) return a:GetTop() > b:GetTop() end)
assert(#r == 3 and tostring(r[1].Name:GetText()) == "Wool Cloth" and tostring(r[1].Line:GetText()) == "\195\15120", "the auctions")
assert(tostring(r[3].Cells[1].Text:GetText()) == "Incoming" and tostring(r[2].Cells[3].Text:GetText()) == "Over 12 h", "time left and sold")

r[2]:Click()
assert(PolestarModal:IsShown() and tostring(PolestarModal.Box.Text:GetText()):find("1g 25s 0c", 1, true), "the fee not named")
PolestarModal.Box.Action:Click()
assert(stub.cancelled[1] == 702, "not cancelled")
r[1]:Click()
assert(not tostring(PolestarModal.Box.Text:GetText()):find("costs"), "a fee named where there is none")
PolestarModal.Box.Cancel:Click()
assert(#stub.cancelled == 1, "cancel cancelled")
r[3]:Click()
assert(not PolestarModal:IsShown(), "a sold auction asked")
table.remove(stub.owned, 2)
stub.fire("AUCTION_CANCELED", 702)
local n = 0
for _, b in ipairs({ f.Body:GetChildren() }) do if b.psKey and b:IsShown() then n = n + 1 end end
assert(n == 2, "the list not asked for again")
