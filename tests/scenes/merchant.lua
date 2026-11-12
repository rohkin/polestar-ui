--@ title: Merchant
--@ roots: PolestarUIMerchant
--@ stubs: stub_npc.lua, stub_merchant.lua
-- The vendor opens ours, never the stock window, with the bags; closing ours ends the visit once, the game ending it closes ours without ending it again. Every ware on one page in two columns: quality names, prices (danger when short of money), a currency cost, stack size and stock left, sold out faded, unusable red. A click buys one, right-click a stack, shift-click asks how many; a high price or a currency cost asks first. A held item dropped on the window is sold. The footer repairs (guild too) and sells junk after asking; the money shows by the tabs; the filter is the game's menu.
local T = Enum.PlayerInteractionType
local ns = PolestarUI
local f = function() return PolestarUIMerchant end
assert(ns.modules.merchant.reloadOff, "switching off does not wait for /reload")

stub.interact(T.Merchant)
assert(f():IsShown() and not MerchantFrame:IsShown(), "the vendor did not open ours")
assert(stub.bagsOpen and stub.bagsOpener == "PolestarUIMerchant", "bags not opened by ours")
f():Hide()
assert(stub.npcClosed.CloseMerchant == 1 and not stub.bagsOpen, "closing ours did not end the visit once")
stub.interact(T.Merchant)
stub.endInteraction(T.Merchant)
assert(not f():IsShown() and stub.npcClosed.CloseMerchant == 1, "the game's end was ended again")

stub.interact(T.Merchant)
local w = f()
assert(tostring(w.Title:GetText()) == "Harlan Bagley", "the band names the vendor")
local rows = {}
for _, r in ipairs({ w.Body:GetChildren() }) do if r.psIndex then rows[r.psIndex] = r end end
assert(#rows == 7, "a row per ware")
assert(tostring(rows[2].Stack:GetText()) == "\195\151200" and tostring(rows[3].Stack:GetText()) == "3 left", "stack size and stock")
assert(rows[4].Well.Icon.desaturated and not rows[1].Well.Icon.desaturated, "sold out not faded")
assert(not rows[6].Money:IsShown() and tostring(rows[6].Cost:GetText()):find("^2 ") ~= nil, "the currency cost")
assert(tostring(rows[5].Money.psParts[1].text:GetText()) == "180", "the price")

-- Buying.
rows[1]:Click("LeftButton")
assert(stub.bought[1][1] == 1 and stub.bought[1][2] == nil, "a click buys one")
rows[2]:Click("RightButton")
assert(stub.bought[2][1] == 2 and stub.bought[2][2] == 1000, "a right-click buys a stack")
stub.keys.shift = true
rows[1]:Click("LeftButton")
stub.keys.shift = false
assert(PolestarModal:IsShown() and #stub.bought == 2, "shift-click did not ask how many")
for _, c in ipairs({ PolestarModal.Box:GetChildren() }) do local m = rawget(c, "More"); if m and c:IsShown() then m:Click(); m:Click() end end
PolestarModal.Box.Action:Click()
assert(stub.bought[3][1] == 1 and stub.bought[3][2] == 3, "the stepper's count not bought")
rows[5]:Click("LeftButton")
assert(#stub.bought == 3 and PolestarModal:IsShown(), "a high price bought without asking")
PolestarModal.Box.Action:Click()
assert(stub.bought[4][1] == 5, "the high price, asked, not bought")
rows[6]:Click("LeftButton")
assert(#stub.bought == 4 and tostring(PolestarModal.Box.Text:GetText()):find("Honor") and tostring(PolestarModal.Box.Text:GetText()):find("refund"), "a currency cost bought without asking")
PolestarModal.Box.Cancel:Click()
assert(#stub.bought == 4, "cancel bought")
-- The visit ends with our dialog open: it goes too.
rows[5]:Click("LeftButton")
stub.endInteraction(T.Merchant)
assert(not PolestarModal:IsShown(), "our dialog outlived the visit")
stub.interact(T.Merchant)

-- Selling: a held item dropped on a row or the window.
stub.cursorItem = true
stub.RunScript(rows[3], "OnReceiveDrag")
assert(stub.sold == 1 and #stub.bought == 4, "a dropped item not sold")
stub.cursorItem = true
rows[3]:Click("LeftButton")
assert(stub.sold == 2 and #stub.bought == 4, "a click with a held item bought")

-- The footer: repair, guild repair, junk.
local left = w.footerButtons.left
assert(tostring(left[1].Label:GetText()) == "Repair all (2g 34s 56c)" and tostring(left[2].Label:GetText()) == "Sell junk", "repair and junk")
left[1]:Click()
assert(stub.repaired[1] == "own", "repair all")
left[2]:Click()
assert(stub.junkSold == 0 and PolestarModal:IsShown(), "junk sold without asking")
PolestarModal.Box.Action:Click()
assert(stub.junkSold == 1, "junk not sold")
stub.guildRepair = true
stub.fire("PLAYER_MONEY")
assert(tostring(left[2].Label:GetText()) == "Guild repair" and left[3]:IsShown(), "guild repair not offered")
left[2]:Click()
assert(stub.repaired[2] == "guild", "guild repair")
stub.repairCost, stub.junk, stub.guildRepair = 0, 0, false
stub.fire("UPDATE_INVENTORY_DURABILITY")
assert(not w.Footer:IsShown(), "nothing to repair or sell, yet a footer")
stub.repairCost, stub.junk = 23456, 3
stub.fire("MERCHANT_UPDATE")

-- The filter: the game's menu, its choice applied at once.
w.psFilter:Click()
assert(stub.menu.tag == "MENU_MERCHANT_FRAME" and #stub.menu.items == 3, "the filter menu")
stub.menu.items[3].set(stub.menu.items[3].value)
assert(stub.filter == LE_LOOT_FILTER_ALL and stub.menu.items[3].get(LE_LOOT_FILTER_ALL), "the filter not set")
assert(tostring(w.psMoney.psParts[1].text:GetText()) == "123", "the player's money")
