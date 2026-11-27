--@ title: Bags: clean up
--@ roots: PolestarUIBags
--@ stubs: stub_bags.lua
-- A sort (Clean up) sends two ITEM_LOCK_CHANGED a moved slot, BAG_UPDATE a bag and one BAG_UPDATE_DELAYED at the end: each repaints only what it changed. A lock paints its one well (one item read, greyed and back), an equipped item's lock nothing; BAG_UPDATE_DELAYED every slot where it is and the free count, with no layout and no footer; a cooldown, the search and the money only themselves. BAG_CONTAINER_UPDATE (a bag swapped for a bigger one) lays the grid out again, and so does a repaint that finds a bag's slot count changed. Shown last: a 16-slot second bag, an item landed in the fourth.
local function well(bag, slot)
	for i = 1, 200 do
		local w = _G["PolestarUIBagsItem" .. i]
		if not w then return end
		if w.psBag == bag and w.psSlot == slot then return w end
	end
end
stub.pressKey("B")
local f = PolestarUIBags
assert(f and f:IsShown(), "B did not open ours")
local calls = { info = 0, footer = 0 }
local function count(t, k, name)
	local o = t[k]
	t[k] = function(...) calls[name] = calls[name] + 1; return o(...) end
end
count(C_Container, "GetContainerItemInfo", "info")
count(Polestar.Widgets, "ShellFooter", "footer")
local slots = 0
for _, n in pairs(stub.bagSlots) do slots = slots + n end

-- One lock: one item read, that well greyed; the unlock gives it back.
stub.bags[0][1][4] = true
stub.fire("ITEM_LOCK_CHANGED", 0, 1)
assert(calls.info == 1 and calls.footer == 0, ("a lock read %d items, made %d footers"):format(calls.info, calls.footer))
assert(well(0, 1).Icon.desaturated and not well(0, 2).Icon.desaturated, "the locked item not greyed")
stub.bags[0][1][4] = false
stub.fire("ITEM_LOCK_CHANGED", 0, 1)
assert(not well(0, 1).Icon.desaturated, "the unlocked item left grey")
-- An equipped item's lock names no slot; a slot not in the grid is no well.
stub.fire("ITEM_LOCK_CHANGED", 16)
stub.fire("ITEM_LOCK_CHANGED", 0, 99)
stub.fire("UNIT_QUEST_LOG_CHANGED", "target")
assert(calls.info == 2, "an equipment lock or another unit's quest log repainted")

-- A sort: 25 swaps (both slots lock, both unlock, each bag updates), then the bags settle.
calls.info = 0
for i = 1, 25 do
	for _ = 1, 2 do
		stub.fire("ITEM_LOCK_CHANGED", 0, i % 20 + 1)
		stub.fire("ITEM_LOCK_CHANGED", 1, i % 12 + 1)
	end
	stub.fire("BAG_UPDATE", 0)
	stub.fire("BAG_UPDATE", 1)
end
assert(calls.info == 100, "100 locks read " .. calls.info .. " items")
stub.bags[3][1] = { 134400, 1, 5 }
stub.fire("BAG_UPDATE_DELAYED")
assert(calls.info <= 100 + slots and calls.footer == 0, ("the sort read %d items (%d slots), made %d footers"):format(calls.info, slots, calls.footer))
assert(tostring(f.Subtitle:GetText()):match("· 56 of 70 free%.$"), "free count: " .. tostring(f.Subtitle:GetText()))
assert(well(3, 1).Icon:GetTexture() == 134400, "the landed item not painted")

-- A cooldown, the search, the money: only themselves.
calls.info = 0
stub.bags[0][1][5] = { cooldown = { 10, 30, 1 } }
stub.fire("BAG_UPDATE_COOLDOWN")
assert(calls.info == 0 and well(0, 1).Cooldown.psStub[2] == 30, "the cooldown not drawn alone")
-- The item moves (a sort): the old slot's sweep ends and the new slot's starts, on the cooldown event alone...
stub.bags[2][3], stub.bags[0][1] = stub.bags[0][1], nil
stub.fire("BAG_UPDATE_COOLDOWN")
assert(calls.info == 0 and not well(0, 1).Cooldown.psStub and well(2, 3).Cooldown.psStub[2] == 30, "the cooldown did not follow its item on the cooldown event")
-- ...and on the bags' update, where the emptied slot is cleared as empty.
stub.bags[0][1], stub.bags[2][3] = stub.bags[2][3], nil
stub.fire("BAG_UPDATE_DELAYED")
assert(well(0, 1).Cooldown.psStub[2] == 30 and not well(2, 3).Cooldown.psStub, "the cooldown did not follow its item on the bags' update")
-- Not usable yet (enable 0) greys the icon; usable again, it is as it was.
stub.bags[0][1][5] = { cooldown = { 10, 30, 0 } }
stub.fire("BAG_UPDATE_COOLDOWN")
local r = well(0, 1).Icon:GetVertexColor()
assert(math.abs(r - 0.4) < 0.01 and not well(0, 1).Cooldown.psStub, "an item not usable yet is not grey")
stub.bags[0][1][5] = nil
stub.fire("BAG_UPDATE_COOLDOWN")
assert(well(0, 1).Icon:GetVertexColor() == 1 and not well(0, 1).Cooldown.psStub, "left grey, or its sweep left on")
calls.info = 0
stub.fire("PLAYER_MONEY")
assert(calls.info == 0 and calls.footer == 0, "the money repainted the slots")
C_Container.SetItemSearch("x")
assert(well(0, 1):GetAlpha() == 0.25 and well(0, 7):GetAlpha() == 1 and calls.footer == 0, "the search does not dim alone")
C_Container.SetItemSearch("")
assert(well(0, 1):GetAlpha() == 1, "the search left dimmed")

-- A bigger bag: the grid is laid out again, by the event or by the next repaint.
stub.bagSlots[1] = 16
stub.fire("BAG_CONTAINER_UPDATE")
assert(well(1, 16) and well(1, 16):IsShown() and calls.footer == 1, "the new bag's slots not laid out")
assert(tostring(f.Subtitle:GetText()):match("· 60 of 74 free%.$"), "free count: " .. tostring(f.Subtitle:GetText()))
stub.bagSlots[1] = 12
stub.fire("BAG_UPDATE_DELAYED")
assert(not well(1, 16):IsShown() and calls.footer == 2, "a changed slot count not laid out again")
stub.bagSlots[1] = 16
stub.fire("BAG_UPDATE_DELAYED")
assert(well(1, 16):IsShown(), "the bag's slots not back")
