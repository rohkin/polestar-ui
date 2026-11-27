--@ title: Bank: clean up
--@ roots: PolestarUIBank
--@ stubs: stub_npc.lua, stub_bank.lua
-- A sort of the bank sends two ITEM_LOCK_CHANGED a moved slot and BAG_UPDATE a bag at every step: a lock paints its one well (one item read), the updates of one frame one repaint of the contents (every slot where it is, the bag slots, the free count), with no tabs, layout or footer; the player's own bags updating paint nothing here. A container whose slot count changed lays everything out again. Shown last: an item landed in the fourth slot, the second bag two slots bigger.
-- The bank's stub has no cooldowns: stub.cooldowns["bag:slot"] = { start, duration, enable }, and the sweep as the client sets and clears it.
stub.cooldowns = { ["6:1"] = { 10, 30, 1 } }
function C_Container.GetContainerItemCooldown(bag, slot)
	local c = stub.cooldowns[bag .. ":" .. slot]
	if not c then return 0, 0, 1 end
	return c[1], c[2], c[3]
end
function CooldownFrame_Clear(cd) cd.psStub = nil end
function CooldownFrame_Set(cd, start, duration, enable)
	if enable and enable ~= 0 and start > 0 and duration > 0 then cd.psStub = { start, duration, enable } else CooldownFrame_Clear(cd) end
end
stub.interact(Enum.PlayerInteractionType.Banker)
local f = PolestarUIBank
assert(f and f:IsShown(), "the banker did not open ours")
local wells = { f.psGrid:GetChildren() }
local calls = { info = 0, footer = 0 }
local function count(t, k, name)
	local o = t[k]
	t[k] = function(...) calls[name] = calls[name] + 1; return o(...) end
end
count(C_Container, "GetContainerItemInfo", "info")
count(Polestar.Widgets, "ShellFooter", "footer")
local items = stub.bankTabs[0][1].items
assert(wells[1].psCooldown.psStub[2] == 30 and not wells[2].psCooldown.psStub, "the cooldown not drawn")

-- One lock: one item read, that well greyed; the unlock gives it back.
items[1][4] = true
stub.fire("ITEM_LOCK_CHANGED", 6, 1)
assert(calls.info == 1 and calls.footer == 0, ("a lock read %d items, made %d footers"):format(calls.info, calls.footer))
assert(wells[1].Icon.desaturated and not wells[2].Icon.desaturated, "the locked item not greyed")
items[1][4] = false
stub.fire("ITEM_LOCK_CHANGED", 6, 1)
assert(not wells[1].Icon.desaturated, "the unlocked item left grey")
-- An equipped item's lock, a slot of the player's bags, their updates: nothing.
stub.fire("ITEM_LOCK_CHANGED", 16)
stub.fire("ITEM_LOCK_CHANGED", 0, 1)
stub.fire("BAG_UPDATE", 0)
stub.advance(0.05)
assert(calls.info == 2, "a lock or an update outside the bank repainted it")

-- A sort: 25 swaps (both slots lock, both unlock, each bag updates) in one frame.
calls.info = 0
for i = 1, 25 do
	for _ = 1, 2 do
		stub.fire("ITEM_LOCK_CHANGED", 6, i % 28 + 1)
		stub.fire("ITEM_LOCK_CHANGED", 7, i % 14 + 1)
	end
	stub.fire("BAG_UPDATE", 6)
	stub.fire("BAG_UPDATE", 7)
end
assert(calls.info == 100, "100 locks and their updates read " .. calls.info .. " items")
items[4] = { 134400, 1, 5, false, "Linen Cloth" }
stub.advance(0.05)
-- The 42 slots and the bank's five bag slots.
assert(calls.info <= 100 + 42 + 5 and calls.footer == 0, ("the sort read %d items, made %d footers"):format(calls.info, calls.footer))
assert(tostring(f.Subtitle:GetText()) == "Thrall · 34 of 42 free.", "free count: " .. tostring(f.Subtitle:GetText()))
assert(wells[4].Icon:GetTexture() == 134400, "the landed item not painted")

-- The item on cooldown moves (a sort): the old slot's sweep ends and the new slot's starts, on the cooldown event alone (no item read)...
calls.info = 0
items[9], items[1] = items[1], nil
stub.cooldowns = { ["6:9"] = { 10, 30, 1 } }
stub.fire("BAG_UPDATE_COOLDOWN")
assert(calls.info == 0 and calls.footer == 0, "a cooldown repainted the slots")
assert(not wells[1].psCooldown.psStub and wells[9].psCooldown.psStub[2] == 30, "the cooldown did not follow its item on the cooldown event")
-- ...and on the bank's repaint, where the emptied slot is cleared as empty.
items[1], items[9] = items[9], nil
stub.cooldowns = { ["6:1"] = { 10, 30, 1 } }
stub.fire("BAG_UPDATE", 6)
stub.advance(0.05)
assert(wells[1].psCooldown.psStub[2] == 30 and not wells[9].psCooldown.psStub, "the cooldown did not follow its item on the bank's repaint")

-- A bag swapped for a bigger one: everything laid out again.
stub.bankTabs[0][2].size = 16
stub.fire("BAG_UPDATE", 7)
stub.advance(0.05)
wells = { f.psGrid:GetChildren() }
assert(#wells == 44 and wells[44]:IsShown() and calls.footer == 1, "the bigger bag's slots not laid out")
assert(tostring(f.Subtitle:GetText()) == "Thrall · 36 of 44 free.", "free count: " .. tostring(f.Subtitle:GetText()))
