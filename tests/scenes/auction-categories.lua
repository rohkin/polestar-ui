--@ title: Auction House: categories
--@ roots: PolestarUIAuction
--@ stubs: stub_npc.lua, stub_auction.lua
-- The stock category tree in the sidebar: a category picked opens its subcategories under it, indented, and a subcategory its own; each searches with its item class filters, a parent with all of its children's (a chest category takes robes too). A click on one on the picked path closes it, as the stock list's toggle. Consumables list the client's subclasses with the item enhancements gathered after bandages; recipe books go last. Shown last: Armor, Plate, Chest.
local T = Enum.PlayerInteractionType
stub.interact(T.Auctioneer)
local f = PolestarUIAuction
local function nav(label)
	for _, b in ipairs(f.navButtons) do if b:IsShown() and tostring(b.Label:GetText()) == label then return b end end
end
local function labels()
	local out = {}
	for _, b in ipairs(f.navButtons) do if b:IsShown() then out[#out + 1] = tostring(b.Label:GetText()) end end
	return table.concat(out, ",")
end
assert(not nav("Plate"), "subcategories before a category is picked")

-- Consumables: the client's subclasses, item enhancements after bandages.
nav("Consumables"):Click()
assert(labels():find("Consumables,Potion,Bandage,Item Enhancement,Other,Trade Goods", 1, true), "the consumables: " .. labels())
nav("Item Enhancement"):Click()
assert(nav("Subclass 0.6") and nav("Subclass 0.9"), "the item enhancements")
local q = stub.browseQuery.itemClassFilters
assert(#q == 2 and q[1].subClassID == 6 and q[2].subClassID == 9, "the enhancement filters")
-- Recipes: books last.
nav("Recipes"):Click()
assert(labels():find("Recipes,Leatherworking,Tailoring,Book,Quest Items", 1, true), "books not last: " .. labels())

-- Armor: its kinds; Plate: its slots, indented under it.
nav("Armor"):Click()
assert(nav("Plate") and nav("Relic") and not nav("Head"), "the armor kinds")
assert(stub.browseQuery.itemClassFilters[1].classID == 4 and tostring(f.Title:GetText()) == "Armor", "Armor not searched")
nav("Plate"):Click()
local head = nav("Head")
assert(head and select(4, head.Icon:GetPoint()) > select(4, nav("Plate").Icon:GetPoint()), "the slots not indented under Plate")
q = stub.browseQuery.itemClassFilters
assert(#q == 11 and q[1].subClassID == 4 and not q[1].inventoryType and q[2].inventoryType == 1, "Plate's filters: " .. #q)
nav("Chest"):Click()
q = stub.browseQuery.itemClassFilters
assert(#q == 2 and q[1].inventoryType == 5 and q[2].inventoryType == 20, "a chest takes robes")
assert(tostring(f.Title:GetText()) == "Chest", "the title")

-- The toggle: Chest again closes it (Plate stays), Armor again closes Armor.
nav("Chest"):Click()
assert(tostring(f.Title:GetText()) == "Plate" and nav("Head"), "Chest not closed")
nav("Armor"):Click()
assert(tostring(f.Title:GetText()) == "Browse" and not nav("Plate"), "Armor not closed")
nav("Armor"):Click()
nav("Plate"):Click()
nav("Chest"):Click()
