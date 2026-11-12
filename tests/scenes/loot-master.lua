--@ title: Loot: master loot
--@ roots: PolestarUILoot
--@ stubs: stub_loot.lua
-- Master loot: a click hands the slot to the game, which answers OPEN_MASTER_LOOT_LIST; the stock GroupLootFrame's menu reads the slot off LootFrame (only the stock row writes it), so ours opens a frame later on the clicked row: Master Looter, Assign Loot with the candidates (by class, then name; in a raid under their class), Request Roll. An item of the threshold quality asks first in our dialog (CONFIRM_LOOT_DISTRIBUTION), then GiveMasterLoot; below it, at once.
stub.masterLoot = true
stub.openLoot()
local f = PolestarUILoot
local rows = f.psRows
stub.RunScript(rows[2], "OnClick", "LeftButton")
assert(stub.looted[1] == 2 and not stub.menu, "the menu opened before the stock one had its turn")
stub.advance(0.1)
local m = stub.menu
assert(m and m.owner == rows[2] and m.tag == "MENU_GROUP_LOOT", "no master loot menu on the row")
assert(m.items[1].title == "Master Looter" and m.items[2].text == "Assign Loot" and m.items[3].text == "Request Roll", "menu entries")
local names = {}
for _, b in ipairs(m.items[2].items) do names[#names + 1] = b.text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end
assert(table.concat(names, ",") == "Ayla,Bron,Testchar", "candidates: " .. table.concat(names, ","))
m.items[3].fn()
assert(stub.rolled == 2, "Request Roll")

-- Uncommon: asks first.
m.items[2].items[2].fn()
assert(PolestarModal:IsShown() and not stub.given, "assigned an uncommon item without asking")
PolestarModal.Box.Action:Click()
assert(stub.given[1] == 2 and stub.given[2] == 4, "not given to Bron")

-- Common: at once. In a raid, the candidates under their class.
stub.given, stub.raid = nil, true
stub.RunScript(rows[3], "OnClick", "LeftButton")
stub.advance(0.1)
m = stub.menu
local classes = {}
for _, b in ipairs(m.items[2].items) do classes[#classes + 1] = b.text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") .. ":" .. #b.items end
assert(table.concat(classes, ",") == "Priest:1,Warrior:2", "raid classes: " .. table.concat(classes, ","))
m.items[2].items[1].items[1].fn()
assert(stub.given[1] == 3 and stub.given[2] == 3 and not PolestarModal:IsShown(), "a common item asked, or went to the wrong one")
stub.raid = false
