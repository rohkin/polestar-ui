--@ title: Loot
--@ roots: PolestarUILoot
--@ stubs: stub_loot.lua
-- LOOT_OPENED opens ours, never the stock window: its own open event is unregistered. A row per slot (the coin slot by its money text, names in quality colour); a click loots that slot (LootSlot) and its row goes on LOOT_SLOT_CLEARED; a Shift-click links instead. Auto-loot is the game's: the window shows and our code loots nothing. Closing ours ends the loot once; the game's LOOT_CLOSED closes ours without ending it again.
local f
assert(PolestarUI.modules.loot.reloadOff, "switching off does not wait for /reload")
assert(not LootFrame.events.LOOT_OPENED and LootFrame.events.LOOT_CLOSED, "only the stock open event is unregistered")

stub.openLoot(true)
f = PolestarUILoot
assert(f:IsShown() and not LootFrame:IsShown(), "auto-loot: ours not shown, or the stock one opened")
assert(#stub.looted == 0, "auto-loot: our code looted")
assert(f.Title:GetText() == "Loot", "title")
f:Hide()
assert(stub.lootClosed == 1, "closing ours did not end the loot once")

stub.openLoot()
stub.fire("LOOT_CLOSED")
assert(not f:IsShown() and stub.lootClosed == 1, "the game's close did not close ours, or ended the loot again")

stub.openLoot()
local rows = f.psRows
assert(rows[1].Name:GetText() == "4 Silver 12 Copper", "coin slot: " .. tostring(rows[1].Name:GetText()))
assert(rows[4].Name:GetText() == "Cloak of the Fallen" and rows[4]:IsShown(), "item row")
stub.keys.shift = true
stub.RunScript(rows[2], "OnClick", "LeftButton")
stub.keys.shift = false
assert(#stub.looted == 0 and stub.linked and stub.linked:find("Worn Shortsword"), "shift-click did not link")
stub.RunScript(rows[2], "OnClick", "LeftButton")
assert(stub.looted[1] == 2, "click did not loot slot 2")
assert(rows[2].Name:GetText() == "Linen Cloth" and not rows[4]:IsShown(), "the looted row stayed")
stub.RunScript(rows[2], "OnEnter")
assert(GameTooltip.lootSlot == 3, "tooltip not the row's slot")
stub.RunScript(rows[2], "OnLeave")
assert(f:IsShown() and not LootFrame:IsShown(), "open")
