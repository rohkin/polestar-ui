--@ title: Loot
--@ roots: PolestarUILoot
--@ stubs: stub_loot.lua
-- LOOT_OPENED opens ours, never the stock window: its own open event is unregistered. A row per slot: the coin slot by its money text, a line per coin, as the stock row; items in quality colour with the quality under the name; a quest item marked over its icon (the stock border, or the bang on one that starts a quest). A click loots that slot (LootSlot) and its row goes on LOOT_SLOT_CLEARED; a Shift-click links instead. Auto-loot is the game's: the window shows and our code loots nothing. Closing ours ends the loot once; the game's LOOT_CLOSED closes ours without ending it again. Empty loot plays the stock empty sound.
local f
ITEM_QUALITY4_DESC = ITEM_QUALITY4_DESC or "Epic"
table.insert(stub.loot, { 133854, "Kobold Ear", 2, 1, false, quest = "active" })
table.insert(stub.loot, { 134328, "A Sealed Letter", 1, 1, false, quest = "starts" })
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

-- Empty loot: the stock empty sound.
local all = stub.loot
stub.loot = {}
local before = #stub.sounds
stub.openLoot()
assert(#stub.sounds > before, "no empty-loot sound")
f:Hide()
stub.loot = all

stub.openLoot()
local rows = f.psRows
assert(rows[1].Name:GetText() == "4 Silver\n12 Copper" and rows[1].Quality:GetText() == "", "coin slot: " .. tostring(rows[1].Name:GetText()))
assert(rows[2].Quality:GetText() == "Uncommon" and rows[4].Quality:GetText() == "Epic", "quality tag")
assert(rows[4].Name:GetText() == "Cloak of the Fallen" and rows[4]:IsShown(), "item row")
assert(not rows[2].Quest:IsShown(), "a plain item marked")
assert(rows[5].Quest:IsShown() and rows[5].Quest.texture == TEXTURE_ITEM_QUEST_BORDER or tostring(rows[5].Quest.texture):find("QuestBorder"), "quest item not bordered")
assert(rows[6].Quest:IsShown() and tostring(rows[6].Quest.texture):find("QuestBang"), "a quest starter has no bang")
-- Hovered, the tooltip follows the modifiers as the stock row's (redrawn each frame) and so does the cursor.
stub.RunScript(rows[2], "OnEnter")
stub.keys.shift = true
stub.advance(0.1)
assert(GameTooltip:GetOwner() == rows[2] and stub.cursorShape == "inspect", "no dress-up cursor while hovered")
stub.keys.shift = false
stub.RunScript(rows[2], "OnLeave")
assert(not GameTooltip:IsShown() and stub.cursorShape == nil, "the cursor not reset")
stub.keys.shift = true
stub.RunScript(rows[2], "OnClick", "LeftButton")
stub.keys.shift = false
assert(#stub.looted == 0 and stub.linked and stub.linked:find("Worn Shortsword"), "shift-click did not link")
stub.RunScript(rows[2], "OnClick", "LeftButton")
assert(stub.looted[1] == 2, "click did not loot slot 2")
assert(rows[2].Name:GetText() == "Linen Cloth" and not rows[6]:IsShown(), "the looted row stayed")
stub.RunScript(rows[2], "OnEnter")
assert(GameTooltip.lootSlot == 3, "tooltip not the row's slot")
stub.RunScript(rows[2], "OnLeave")
stub.openLoot()
assert(f:IsShown() and not LootFrame:IsShown(), "open")
