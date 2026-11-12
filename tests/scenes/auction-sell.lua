--@ title: Auction House: selling
--@ roots: PolestarUIAuction
--@ stubs: stub_npc.lua, stub_auction.lua
-- The Sell page: an item held on the cursor goes on the well (one the auction house refuses stays held); a right-click takes it off. The price starts at the stock default and moves to the lowest listing until the player types one; a commodity starts at its stack's count, and the quantity shows only when more than one could go. The duration menu picks 12, 24 or 48 hours, kept in the stock CVar; the deposit and total follow. An item posts as a buyout only, or, with Buyout only off, with a starting price and an optional buyout (a buyout at or under it is refused, its caption red). Post is disabled, the stock reason under the form, while it cannot go (no price, the deposit over the player's money, the throttle). Post runs PostCommodity or PostItem from its click; a post the client wants confirmed asks in our dialog (AUCTION_HOUSE_POST_WARNING) and confirms from that click; one the client refuses says so (AUCTION_HOUSE_POST_ERROR). Several of an item post one by one with their progress shown, no other item taken meanwhile, and stop as the window closes (CancelSell). Shown last: Whirlwind Axe with a starting price.
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
local function postButton() return f.footerButtons.right[1] end

-- A refused item stays on the cursor.
stub.holdItem(9999)
s.Well:Click("LeftButton")
assert(stub.cursor and tostring(s.Name:GetText()) == "No item", "a refused item taken")
-- A commodity: taken off the cursor, its stack's count, priced at the lowest listing.
stub.holdItem(2589)
s.Well:Click("LeftButton")
assert(stub.cursor == nil and tostring(s.Name:GetText()) == "Linen Cloth", "the item not taken")
assert(tostring(s.PriceCaption:GetText()) == "Unit price" and coins(s.Total) == "24", "twenty at the lowest listing's price: " .. coins(s.Total))
assert(s.Stepper:IsShown() and not s.BuyoutOnly:IsShown(), "a commodity's quantity, no Buyout only")
s.Stepper.More:Click()
s.Stepper.More:Click()
assert(coins(s.Deposit) == "6 60" and coins(s.Total) == "26 40", "22 at 24 hours")
s.Duration:Click()
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() and tostring(r.Text:GetText()) == "48 hours" then r:Click() end end
assert(tostring(s.Duration.Label:GetText()) == "48 hours" and coins(s.Deposit) == "9 90" and stub.cvars.auctionHouseDurationDropdown == "3", "the duration")
-- The player's own price: kept over the listings.
local silver = ({ s.Price:GetChildren() })[2]
silver:SetText("2")
stub.RunScript(silver, "OnTextChanged", true)
assert(coins(s.Total) == "48 40", "the typed price: " .. coins(s.Total))
-- The throttle: Post waits, with the stock reason.
stub.throttled = true
stub.fire("AUCTION_HOUSE_THROTTLED_MESSAGE_SENT")
assert(not postButton():IsEnabled() and tostring(s.Reason:GetText()) ~= "", "Post not held by the throttle")
stub.throttled = false
stub.fire("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
assert(postButton():IsEnabled() and tostring(s.Reason:GetText()) == "", "Post not ready again")
postButton():Click()
local p = stub.posted
assert(p[1] == "commodity" and p[2] == 2589 and p[3] == 3 and p[4] == 22 and p[5] == 220, "the post")
assert(tostring(s.Name:GetText()) == "No item", "the posted item still on the well")

-- An item: one only, so no quantity; the client wants it confirmed: asked, then confirmed from our dialog's click.
stub.holdItem(6975)
stub.RunScript(s.Well, "OnReceiveDrag")
assert(tostring(s.PriceCaption:GetText()) == "Buyout" and coins(s.Total) == "180", "the item's lowest buyout")
assert(not s.Stepper:IsShown() and s.BuyoutOnly:IsShown() and s.BuyoutOnly.Box:GetChecked() and not s.Bid:IsShown(), "one item: no quantity, Buyout only on")
stub.postNeedsConfirm = true
postButton():Click()
assert(stub.posted[1] == "item" and stub.posted[5] == 1800000 and stub.posted[6] == nil and stub.confirmedPost == nil, "the item post")
stub.fire("AUCTION_HOUSE_POST_WARNING")
assert(PolestarModal:IsShown(), "the post not asked")
PolestarModal.Box.Action:Click()
assert(stub.confirmedPost[1] == "item" and stub.confirmedPost[2] == 6975, "the post not confirmed")
stub.postNeedsConfirm = false
-- The client refuses one: said.
stub.fire("AUCTION_HOUSE_POST_ERROR")
assert(PolestarModal:IsShown() and tostring(PolestarModal.Box.Title:GetText()) == "Not posted", "the post error not said")
PolestarModal.Box.Action:Click()

-- The deposit over the player's money: held, the stock reason.
stub.holdItem(6975)
s.Well:Click("LeftButton")
stub.money = 100
stub.fire("PLAYER_MONEY")
assert(not postButton():IsEnabled() and tostring(s.Reason:GetText()):find("deposit", 1, true), "Post not held by the deposit")
stub.money = 1234567
stub.fire("PLAYER_MONEY")

-- Several items: one by one, their progress shown; closing stops them.
stub.bagCount[6975] = 3
s.Well:Click("RightButton")
assert(tostring(s.Name:GetText()) == "No item", "right-click")
stub.holdItem(6975)
s.Well:Click("LeftButton")
s.Stepper.More:Click()
s.Stepper.More:Click()
stub.multisellSteps = 1
postButton():Click()
assert(tostring(s.Reason:GetText()) == "Creating auction 1 of 3" and not postButton():IsEnabled(), "the multisell's progress")
stub.holdItem(2589)
s.Well:Click("LeftButton")
assert(tostring(s.Name:GetText()) == "Whirlwind Axe" and stub.cursor, "another item taken during a multisell")
ClearCursor()
stub.fire("AUCTION_MULTISELL_UPDATE", 3, 3)
assert(tostring(s.Name:GetText()) == "No item" and tostring(s.Reason:GetText()) == "", "the multisell not done")
stub.holdItem(6975)
s.Well:Click("LeftButton")
s.Stepper.More:Click()
postButton():Click()
f:Hide()
assert(stub.sellCancelled == 1, "the multisell not stopped as the window closed")
stub.multisellSteps = nil

-- Buyout only off: a starting price and an optional buyout; a buyout at or under it is refused.
stub.interact(T.Auctioneer)
f.tabButtons[2]:Click()
stub.holdItem(6975)
s.Well:Click("LeftButton")
s.BuyoutOnly:Click()
assert(s.Bid:IsShown() and tostring(s.PriceCaption:GetText()) == "Buyout (optional)", "the starting price")
local bidGold = ({ s.Bid:GetChildren() })[1]
bidGold:SetText("200")
stub.RunScript(bidGold, "OnTextChanged", true)
assert(not postButton():IsEnabled(), "a buyout under the starting price allowed")
bidGold:SetText("150")
stub.RunScript(bidGold, "OnTextChanged", true)
assert(postButton():IsEnabled(), "the starting price refused")
