--@ title: Merchant: buyback
--@ roots: PolestarUIMerchant
--@ stubs: stub_npc.lua, stub_merchant.lua
-- The Buyback tab: what was sold here, its count on the well and its price; a click buys it back, the game's buy-back cursor over it. The next visit opens on Buy, the last item sold under the wares with its tooltip, a click buying it back.
local T = Enum.PlayerInteractionType
stub.interact(T.Merchant)
local w = PolestarUIMerchant
w.tabButtons[2]:Click()
local rows = {}
for _, r in ipairs({ w.Body:GetChildren() }) do if r.psIndex and r:IsShown() then rows[r.psIndex] = r end end
assert(#rows == 2 and tostring(w.Title:GetText()) == "Buyback" and tostring(w.Subtitle:GetText()) == "2 items to buy back", "a row per item sold")
assert(tostring(rows[1].Name:GetText()) == "Linen Cloth" and tostring(rows[1].Well.psCount:GetText()) == "20", "name and count")
assert(tostring(rows[2].Stack:GetText()) == "" and rows[2].Money:IsShown(), "price, no stack size")
rows[2]:Click("LeftButton")
assert(stub.boughtBack[1] == 2 and #stub.bought == 0, "a click did not buy it back")
stub.RunScript(rows[1], "OnEnter")
assert(GameTooltip.lines[1] == "Linen Cloth" and stub.cursorShape == "BUYBACK", "the buyback tooltip or cursor")
stub.RunScript(rows[1], "OnLeave")
assert(stub.cursorShape == nil, "the cursor stayed")
w:Hide()
stub.interact(T.Merchant)
assert(tostring(w.Title:GetText()) == "Merchant", "the next visit not on Buy")
-- The last item sold, under the wares.
local last = w.psLast
assert(last:IsShown() and tostring(last.Name:GetText()) == "Malachite", "the last sold not shown")
stub.RunScript(last, "OnEnter")
assert(GameTooltip.lines[1] == "Malachite", "its tooltip")
last:Click("LeftButton")
assert(stub.boughtBack[2] == 2 and #stub.bought == 0, "not bought back")
stub.RunScript(rows[1], "OnLeave")
stub.RunScript(PolestarUIMerchant.Body:GetChildren(), "OnEnter")
assert(stub.cursorShape == "BUY_CURSOR", "the buy cursor")
w.tabButtons[2]:Click()
