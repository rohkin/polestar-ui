--@ title: Auction House: selling
--@ roots: PolestarUIAuction
--@ stubs: stub_npc.lua, stub_auction.lua
-- The Sell page: an item held on the cursor goes on the well (one the auction house refuses stays held); a right-click takes it off. The price starts at the stock default and moves to the lowest listing until the player types one; the stepper sets how many, the duration menu picks 12, 24 or 48 hours, and the deposit and total follow. Post runs PostCommodity or PostItem from its click; a post the client wants confirmed asks in our dialog (AUCTION_HOUSE_POST_WARNING) and confirms from that click. Shown last: a commodity on the well, three of them.
local T = Enum.PlayerInteractionType
stub.interact(T.Auctioneer)
local f = PolestarUIAuction
f.tabButtons[2]:Click()
local s = f.psSell
assert(s:IsShown() and tostring(f.Title:GetText()) == "Sell" and tostring(s.Name:GetText()) == "No item", "the empty Sell page")
assert(#f.footerButtons.right == 0 or not f.footerButtons.right[1]:IsShown(), "Post with no item")
local function coins(m)
	local out = {}
	for _, p in ipairs(m.psParts) do if p.text:IsShown() then out[#out + 1] = tostring(p.text:GetText()) end end
	return table.concat(out, " ")
end

-- A refused item stays on the cursor.
stub.holdItem(9999)
s.Well:Click("LeftButton")
assert(stub.cursor and tostring(s.Name:GetText()) == "No item", "a refused item taken")
-- A commodity: taken off the cursor, priced at the lowest listing.
stub.holdItem(2589)
s.Well:Click("LeftButton")
assert(stub.cursor == nil and tostring(s.Name:GetText()) == "Linen Cloth", "the item not taken")
assert(tostring(s.PriceCaption:GetText()) == "Unit price" and coins(s.Total) == "1 20", "the lowest listing's price: " .. coins(s.Total))
s.Stepper.More:Click()
s.Stepper.More:Click()
assert(coins(s.Deposit) == "90" and coins(s.Total) == "3 60", "three at 24 hours")
s.Duration:Click()
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() and tostring(r.Text:GetText()) == "48 hours" then r:Click() end end
assert(tostring(s.Duration.Label:GetText()) == "48 hours" and coins(s.Deposit) == "1 35", "the duration")
-- The player's own price: kept over the listings.
local silver = ({ s.Price:GetChildren() })[2]
silver:SetText("2")
stub.RunScript(silver, "OnTextChanged", true)
assert(coins(s.Total) == "6 60", "the typed price: " .. coins(s.Total))
f.footerButtons.right[1]:Click()
local p = stub.posted
assert(p[1] == "commodity" and p[2] == 2589 and p[3] == 3 and p[4] == 3 and p[5] == 220, "the post")
assert(tostring(s.Name:GetText()) == "No item", "the posted item still on the well")

-- An item the client wants confirmed: asked, then confirmed from our dialog's click.
stub.holdItem(6975)
stub.RunScript(s.Well, "OnReceiveDrag")
assert(tostring(s.PriceCaption:GetText()) == "Buyout (each)" and coins(s.Total) == "180", "the item's lowest buyout")
stub.postNeedsConfirm = true
f.footerButtons.right[1]:Click()
assert(stub.posted[1] == "item" and stub.posted[5] == 1800000 and stub.confirmedPost == nil, "the item post")
stub.fire("AUCTION_HOUSE_POST_WARNING")
assert(PolestarModal:IsShown(), "the post not asked")
PolestarModal.Box.Action:Click()
assert(stub.confirmedPost[1] == "item" and stub.confirmedPost[2] == 6975, "the post not confirmed")
stub.postNeedsConfirm = false

-- Right-click takes it off; the picture: three Linen Cloth.
stub.holdItem(6975)
s.Well:Click("LeftButton")
s.Well:Click("RightButton")
assert(tostring(s.Name:GetText()) == "No item", "right-click")
stub.holdItem(2589)
s.Well:Click("LeftButton")
s.Stepper.More:Click()
s.Stepper.More:Click()
