--@ title: Merchant
--@ roots: PolestarUIMerchant
--@ stubs: stub_npc.lua, stub_merchant.lua
-- The vendor opens ours, never the stock window, with the bags; closing ours ends the visit once, the game ending it closes ours without ending it again. Every ware on one page in two columns: quality names, prices (danger when short of money), each other cost (a currency, an item) as its count and icon with its own tooltip, the vendor's currencies held by the money, a quest bang on a ware that starts one, stack size and stock left, sold out faded, unusable red. A click buys one, right-click a stack, shift-click asks how many; a high price, a currency, an item above uncommon or a purchase that cannot be refunded asks first (the stock rules); shift-click is capped by the money and the cost items held. A held item dropped on the window is sold; one that can still be refunded asks first, naming what comes back, and is refunded (cancel puts it back). The footer repairs all (guild too, each with the stock tooltip: the cost, the guild's funds, what the player pays on top), one item with the game's repair cursor (on until clicked again or the window closes), and sells junk after asking; the money shows by the tabs; the filter is the game's menu.
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
assert(tostring(w.psSubject.name:GetText()) == "Harlan Bagley" and w.psSubject.icon:GetTexture() == 132355, "the subject block names the vendor")
assert(tostring(w.Title:GetText()) == "Merchant" and tostring(w.Subtitle:GetText()) == "9 items for sale", "the band's title and status")
local rows = {}
for _, r in ipairs({ w.Body:GetChildren() }) do if r.psIndex and not r.psBuyback then rows[r.psIndex] = r end end
assert(#rows == 9, "a row per ware")
assert(tostring(rows[2].Stack:GetText()) == "\195\151200" and tostring(rows[3].Stack:GetText()) == "3 left", "stack size and stock")
assert(rows[4].Well.Icon.desaturated and not rows[1].Well.Icon.desaturated, "sold out not faded")
assert(not rows[6].Money:IsShown() and rows[6].Costs[1]:IsShown() and tostring(rows[6].Costs[1].Text:GetText()) == "2" and not rows[6].Costs[2]:IsShown(), "the currency cost")
-- Each cost has its own tooltip; a quest starts from the Reaper.
stub.RunScript(rows[8].Costs[1], "OnEnter")
assert(GameTooltip.lines[1] == "Arcanite Bar", "the cost item's tooltip")
GameTooltip:Hide()
assert(rows[8].Quest:IsShown() and not rows[1].Quest:IsShown(), "the quest bang")
-- The vendor's currency by the money, with its tooltip.
local token
for _, c in ipairs({ w.TabRow:GetChildren() }) do if c.psID then token = c end end
assert(token and token:IsShown() and tostring(token.Text:GetText()) == "1500", "the Honor held")
assert(tostring(rows[5].Money.psParts[1].text:GetText()) == "180", "the price")
-- A drag picks the ware up, never while a spell waits for its item.
stub.targeting = true
stub.RunScript(rows[1], "OnDragStart")
assert(not stub.pickedUp, "picked up while targeting")
stub.targeting = false
stub.RunScript(rows[1], "OnDragStart")
assert(stub.pickedUp == 1, "a drag did not pick it up")
stub.pickedUp = nil
-- The sidebar search keeps the wares whose names match.
w.Search:SetText("bread"); stub.RunScript(w.Search, "OnTextChanged", true)
local shown = 0
for _, r in ipairs({ w.Body:GetChildren() }) do if r.psIndex and not r.psBuyback and r:IsShown() then shown = shown + 1 end end
assert(shown == 1 and tostring(w.Subtitle:GetText()) == "1 of 9 items for sale", "the search: " .. tostring(w.Subtitle:GetText()))
w.Search:SetText(""); stub.RunScript(w.Search, "OnTextChanged", true)

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
-- Paid in an item: above uncommon asks, naming it; a common one does not.
rows[8]:Click("LeftButton")
assert(#stub.bought == 4 and tostring(PolestarModal.Box.Text:GetText()):find("2 %[Arcanite Bar%]"), "a rare cost item bought without asking")
PolestarModal.Box.Cancel:Click()
rows[9]:Click("LeftButton")
assert(#stub.bought == 5 and stub.bought[5][1] == 9 and not PolestarModal:IsShown(), "a common cost item asked")
-- Shift-click: as many as the Linen held pays for (9 / 2 = 4).
stub.keys.shift = true
rows[9]:Click("LeftButton")
stub.keys.shift = false
for _, c in ipairs({ PolestarModal.Box:GetChildren() }) do local m = rawget(c, "More"); if m and c:IsShown() then for _ = 1, 9 do m:Click() end end end
PolestarModal.Box.Action:Click()
assert(stub.bought[6][1] == 9 and stub.bought[6][2] == 4, "not capped by the cost items held")
-- The visit ends with our dialog open: it goes too.
rows[5]:Click("LeftButton")
stub.endInteraction(T.Merchant)
assert(not PolestarModal:IsShown(), "our dialog outlived the visit")
stub.interact(T.Merchant)

-- Selling: a held item dropped on a row or the window.
stub.cursorItem = true
stub.RunScript(rows[3], "OnReceiveDrag")
assert(stub.sold == 1 and #stub.bought == 6, "a dropped item not sold")
stub.cursorItem = true
rows[3]:Click("LeftButton")
assert(stub.sold == 2 and #stub.bought == 6, "a click with a held item bought")
-- A refundable one: asked, then refunded, never sold.
stub.cursorItem, stub.refund = true, { money = 0, itemCount = 0, currencyCount = 1, refundSeconds = 7000, hasEnchants = false }
stub.RunScript(rows[3], "OnReceiveDrag")
assert(PolestarModal:IsShown() and tostring(PolestarModal.Box.Text:GetText()):find("2 Honor") and stub.sold == 2, "no refund dialog")
PolestarModal.Box.Cancel:Click()
assert(not stub.cursorItem and not stub.refunded, "cancel did not put it back")
stub.cursorItem = true
stub.RunScript(rows[3], "OnReceiveDrag")
PolestarModal.Box.Action:Click()
assert(stub.refunded and stub.refunded[2] == 3 and stub.sold == 2, "not refunded")
stub.refund = nil

-- The footer: repair, guild repair, junk.
local left = w.footerButtons.left
assert(tostring(left[1].Label:GetText()) == "Repair all (2g 34s 56c)" and tostring(left[2].Label:GetText()) == "Repair an item"
	and tostring(left[3].Label:GetText()) == "Sell junk", "repair and junk")
assert(left[1].psTip == "Repair all items" and left[1].psTipLines[1] == "Costs 2g 34s 56c" and not left[1].psTipLines[2], "the repair tooltip")
left[1]:Click()
assert(stub.repaired[1] == "own", "repair all")
-- One item: the repair cursor, on and off.
left[2]:Click()
assert(stub.repairMode and tostring(left[2].Label:GetText()) == "Stop repairing", "no repair cursor")
left[2]:Click()
assert(not stub.repairMode and tostring(left[2].Label:GetText()) == "Repair an item", "the repair cursor stayed")
left[2]:Click()
w:Hide()
assert(not stub.repairMode, "the repair cursor outlived the window")
stub.interact(T.Merchant)
left[3]:Click()
assert(stub.junkSold == 0 and PolestarModal:IsShown(), "junk sold without asking")
PolestarModal.Box.Action:Click()
assert(stub.junkSold == 1, "junk not sold")
stub.guildRepair = true
stub.fire("PLAYER_MONEY")
assert(tostring(left[2].Label:GetText()) == "Guild repair" and left[4]:IsShown(), "guild repair not offered")
assert(left[2].psTipLines[2] == "The guild pays up to 1g 0s 0c." and left[2].psTipLines[3] == "You pay the other 1g 34s 56c.", "the guild tooltip")
left[2]:Click()
assert(stub.repaired[2] == "guild", "guild repair")
stub.repairCost, stub.junk, stub.guildRepair = nil, 0, false
stub.fire("UPDATE_INVENTORY_DURABILITY")
assert(not w.Footer:IsShown(), "no repairs or junk here, yet a footer")
stub.repairCost, stub.junk = 23456, 3
stub.fire("MERCHANT_UPDATE")

-- The filter: the game's menu at the end of the search row, lit while on
-- (the visit starts on the class), its choice applied at once, Clear filters.
assert(w.psFilter:GetParent() == w.Sidebar and w.psFilter.psActive and w.psFilter.psTip == "Filter (1 on)", "the filter not lit for the class")
w.psFilter:Click()
assert(stub.menu.tag == "MENU_MERCHANT_FRAME" and #stub.menu.items == 4 and stub.menu.items[4].text == "Clear filters", "the filter menu")
stub.menu.items[1].set(stub.menu.items[1].value)
assert(stub.filter == LE_LOOT_FILTER_CLASS and stub.menu.items[1].get(LE_LOOT_FILTER_CLASS), "the filter not set")
stub.menu.items[4].set()
assert(stub.filter == LE_LOOT_FILTER_ALL and not w.psFilter.psActive and w.psFilter.psTip == "Filter", "Clear filters")
assert(tostring(w.psMoney.psParts[1].text:GetText()) == "123", "the player's money")
