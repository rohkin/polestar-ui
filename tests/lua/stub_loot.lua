-- The client's loot as the Loot sees it (Blizzard_UIPanels_Game's
-- Mainline/LootFrame.lua): LootFrame with its own open and close events, the
-- loot slots (GetLootSlotInfo) and what a click calls.

-- The game's window: addon code must never show or hide it (docs/CLIENT.md, rule 8).
LootFrame = CreateFrame("Frame", "LootFrame", UIParent)
LootFrame:Hide()
LootFrame:RegisterEvent("LOOT_OPENED")
LootFrame:RegisterEvent("LOOT_CLOSED")
LootFrame:SetScript("OnEvent", function(self, ev) if ev == "LOOT_OPENED" then self:Show() end end)

Enum.LootSlotType = { None = 0, Item = 1, Money = 2, Currency = 3 }

-- Each slot: { icon, name, count, quality, locked, isCoin }.
stub.loot = {
	{ 133784, "4 Silver\n12 Copper", 0, 0, false, true },
	{ 135274, "Worn Shortsword", 1, 2, false },
	{ 134400, "Linen Cloth", 3, 1, false },
	{ 132940, "Cloak of the Fallen", 1, 4, true },
}
stub.looted, stub.lootClosed, stub.linked = {}, 0, nil

function GetNumLootItems() return #stub.loot end
function GetLootSlotInfo(i)
	local s = stub.loot[i]
	if not s or s.gone then return nil end
	return s[1], s[2], s[3], nil, s[4], s[5], false, nil, false, s[6] or false
end
function GetLootSlotType(i)
	local s = stub.loot[i]
	if not s or s.gone then return Enum.LootSlotType.None end
	return s[6] and Enum.LootSlotType.Money or Enum.LootSlotType.Item
end
function GetLootSlotLink(i) return "|cff1eff00|Hitem:" .. i .. "|h[" .. stub.loot[i][2] .. "]|h|r" end
function LootSlot(i)
	stub.looted[#stub.looted + 1] = i
	stub.loot[i].gone = true
	stub.fire("LOOT_SLOT_CLEARED", i)
end
function CloseLoot()
	stub.lootClosed = stub.lootClosed + 1
	stub.fire("LOOT_CLOSED")
end
function IsFishingLoot() return stub.fishing or false end
function IsModifiedClick() return IsShiftKeyDown() end
function HandleModifiedItemClick(link) stub.linked = link end
function GameTooltip.SetLootItem(self, i) self.lootSlot = i end
function GameTooltip.SetLootCurrency(self, i) self.lootSlot = i end

-- The game opens the loot: LOOT_OPENED(isAutoLoot, acquiredFromItem).
function stub.openLoot(auto)
	for _, s in ipairs(stub.loot) do s.gone = nil end
	stub.fire("LOOT_OPENED", auto or false, false)
end
