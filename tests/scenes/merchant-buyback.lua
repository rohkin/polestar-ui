--@ title: Merchant: buyback
--@ roots: PolestarUIMerchant
--@ stubs: stub_npc.lua, stub_merchant.lua
-- The Buyback tab: what was sold here, its count on the well and its price; a click buys it back. The next visit opens on Buy.
local T = Enum.PlayerInteractionType
stub.interact(T.Merchant)
local w = PolestarUIMerchant
w.tabButtons[2]:Click()
local rows = {}
for _, r in ipairs({ w.Body:GetChildren() }) do if r.psIndex and r:IsShown() then rows[r.psIndex] = r end end
assert(#rows == 2, "a row per item sold")
assert(tostring(rows[1].Name:GetText()) == "Linen Cloth" and tostring(rows[1].Well.psCount:GetText()) == "20", "name and count")
assert(tostring(rows[2].Stack:GetText()) == "" and rows[2].Money:IsShown(), "price, no stack size")
rows[2]:Click("LeftButton")
assert(stub.boughtBack[1] == 2 and #stub.bought == 0, "a click did not buy it back")
w:Hide()
stub.interact(T.Merchant)
assert(tostring(w.Subtitle:GetText()):find("^Click an item to buy it%.") ~= nil, "the next visit not on Buy")
w.tabButtons[2]:Click()
