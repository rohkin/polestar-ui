--@ title: Auction House: buying a commodity
--@ roots: PolestarUIAuction, PolestarModal
--@ stubs: stub_npc.lua, stub_auction.lua
-- A commodity opens its price list (the player's own units counted out) and a quantity stepper with the total at the listed prices. Buy asks the auction house for a quote (StartCommoditiesPurchase from the click) and shows it in our dialog; its Buy confirms (ConfirmCommoditiesPurchase from that click), Cancel drops the quote. A quote too far over the listed price, or none to be had, is dropped and said; a smaller rise is named in the dialog (shown last). The restricted calls error outside a click.
local T = Enum.PlayerInteractionType
assert(not pcall(C_AuctionHouse.StartCommoditiesPurchase, 2589, 1, 1), "the stub's hardware check let a call through")
stub.interact(T.Auctioneer)
local f = PolestarUIAuction
f.Search:SetText("linen")
stub.RunScript(f.Search, "OnTextChanged", true)
stub.RunScript(f.Search, "OnEnterPressed")
local first
for _, r in ipairs({ f.Body:GetChildren() }) do if r.psKey and r:IsShown() then first = r end end
first:Click()
assert(tostring(f.Title:GetText()) == "Linen Cloth" and f.psBuy:IsShown(), "the commodity not opened")
local rows = {}
for _, r in ipairs({ f.Body:GetChildren() }) do if r.psKey and r:IsShown() then rows[#rows + 1] = r end end
table.sort(rows, function(a, b) return a:GetTop() > b:GetTop() end)
assert(#rows == 3 and tostring(rows[3].Cells[2].Text:GetText()) == "50" and tostring(rows[3].Line:GetText()) == "2 sellers (20 yours)", "the price list")

-- How many: Max is every unit not the player's own; the total adds the tiers up.
f.psBuy.Stepper.Max:Click()
local buy = f.footerButtons.right[1]
assert(tostring(buy.Label:GetText()) == "Buy 330 (4g 7s 0c)", "the total: " .. tostring(buy.Label:GetText()))
local box = PolestarModal and PolestarModal.Box

-- The quote at the listed price: asked, then bought from the dialog's click.
buy:Click()
assert(stub.started[1] == 2589 and stub.started[2] == 330 and stub.started[3] == 124, "the quote not asked")
box = PolestarModal.Box
assert(PolestarModal:IsShown() and tostring(box.Title:GetText()) == "Buy 330 Linen Cloth?", "the quote not shown")
assert(not tostring(box.Text:GetText()):find("went up"), "a rise named at the listed price")
box.Action:Click()
assert(stub.bought[1] == 2589 and stub.bought[2] == 330, "not bought")

-- Too far over: dropped and said.
stub.bought = nil
stub.quoteUnit = 200
buy:Click()
assert(tostring(box.Title:GetText()) == "Not bought" and stub.quoteCancelled == 1, "a dear quote not dropped")
box.Action:Click()
-- None to be had.
stub.quoteUnit = false
buy:Click()
assert(tostring(box.Title:GetText()) == "Not bought" and stub.quoteCancelled == 2, "no quote not dropped")
box.Action:Click()
-- The player cancels.
stub.quoteUnit = nil
buy:Click()
box.Cancel:Click()
assert(stub.quoteCancelled == 3 and stub.bought == nil, "cancel bought")
-- A small rise: named, left open.
stub.quoteUnit = 128
buy:Click()
assert(PolestarModal:IsShown() and tostring(box.Text:GetText()):find("went up by 15s 40c", 1, true), "the rise not named")
