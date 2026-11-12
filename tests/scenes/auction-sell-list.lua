--@ title: Auction House: listings while selling
--@ roots: PolestarUIAuction
--@ stubs: stub_npc.lua, stub_auction.lua
-- The stock sell lists under the form: an item's or a commodity's current listings (SendSellSearchQuery), its unit price, quantity and sellers, or an item's bid, buyout and sellers under sortable headers. The price starts at the best one (an item's cheapest buyout at its own level); a listing clicked takes its price, and a price a silver under it shows the stock undercut tip. After a post the listings stay, as the stock list keeps the last item's. Shown last: Linen Cloth posted, its listings still shown.
local T = Enum.PlayerInteractionType
stub.interact(T.Auctioneer)
local f = PolestarUIAuction
f.tabButtons[2]:Click()
local s = f.psSell
local function rows()
	local out = {}
	for _, r in ipairs({ f.Body:GetChildren() }) do if r.psKey and r:IsShown() then out[#out + 1] = r end end
	table.sort(out, function(a, b) return a:GetTop() > b:GetTop() end)
	return out
end
local function coins(m)
	local out = {}
	for _, p in ipairs(m.psParts) do if p.text:IsShown() then out[#out + 1] = tostring(p.text:GetText()) end end
	return table.concat(out, " ")
end
assert(#rows() == 0, "listings with no item")

-- An item: its listings, the best buyout taken; a click takes another's.
stub.holdItem(6975)
s.Well:Click("LeftButton")
local r = rows()
assert(#r == 3 and stub.sellQuery.key.itemID == 6975 and tostring(r[1].Line:GetText()) == "Seller901", "the item's listings")
assert(coins(s.Total) == "180", "not the best buyout")
r[3]:Click()
assert(coins(s.Total) == "200", "the clicked listing's price not taken")
-- Sortable: Bid first asks again.
local bidHead
for _, h in ipairs({ f.Body:GetChildren() }) do if rawget(h, "Arrow") and h:IsShown() and tostring(h.Text:GetText()) == "Bid" then bidHead = h end end
bidHead:Click()
assert(stub.sellQuery.sorts[1].sortOrder == Enum.AuctionHouseSortOrder.Bid, "the sell list not sorted")
s.Well:Click("RightButton")

-- A commodity: unit price, quantity, sellers; the undercut tip a silver under.
stub.holdItem(2589)
s.Well:Click("LeftButton")
r = rows()
assert(#r == 3 and tostring(r[3].Cells[2].Text:GetText()) == "50", "the commodity's listings")
r[2]:Click()
local silver = ({ s.Price:GetChildren() })[2]
local copper = ({ s.Price:GetChildren() })[3]
silver:SetText("0")
copper:SetText("25")
stub.RunScript(copper, "OnTextChanged", true)
assert(tostring(s.Reason:GetText()):find("ndercut", 1, true), "the undercut tip: " .. tostring(s.Reason:GetText()))
-- Posted: the listings stay.
f.footerButtons.right[1]:Click()
assert(tostring(s.Name:GetText()) == "No item" and #rows() == 3, "the listings not kept after the post")
