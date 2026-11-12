-- The client's loot as the Loot sees it (Blizzard_UIPanels_Game's
-- Mainline/LootFrame.lua): LootFrame with its own open and close events and
-- its Edit Mode place, the loot slots (GetLootSlotInfo), what a click calls,
-- and master loot (GroupLootFrame.lua's menu, the candidates).

-- The game's window: addon code must never show or hide it (docs/CLIENT.md, rule 8).
LootFrame = CreateFrame("Frame", "LootFrame", UIParent)
LootFrame:Hide()
LootFrame:RegisterEvent("LOOT_OPENED")
LootFrame:RegisterEvent("LOOT_CLOSED")
LootFrame:SetScript("OnEvent", function(self, ev) if ev == "LOOT_OPENED" then self:Show() end end)
-- Edit Mode's layout, applied at load (EditModeSystemMixin:UpdateSystem): the default place.
LootFrame.systemInfo = { isInDefaultPosition = true }
LootFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
-- The player moving it in Edit Mode, as ApplySystemAnchor anchors it (offsets over its scale).
function stub.moveLootFrame(point, relPoint, x, y)
	LootFrame.systemInfo = { isInDefaultPosition = false }
	LootFrame:ClearAllPoints()
	LootFrame:SetPoint(point, UIParent, relPoint, x / LootFrame:GetScale(), y / LootFrame:GetScale())
end

Enum.LootSlotType = { None = 0, Item = 1, Money = 2, Currency = 3 }

-- Each slot: { icon, name, count, quality, locked, isCoin }, and quest = "active"
-- (an item for a quest the player is on) or "starts" (it starts one).
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
	local questItem, questID, active = s.quest == "active", s.quest and 900 or nil, s.quest == "active"
	-- In combat the names come secret (stub.secretLoot), as the client hands them over.
	local name = stub.secretLoot and InCombatLockdown() and stub.SECRET or s[2]
	return s[1], name, s[3], nil, s[4], s[5], questItem, questID, active, s[6] or false
end
function GetLootSlotType(i)
	local s = stub.loot[i]
	if not s or s.gone then return Enum.LootSlotType.None end
	return s[6] and Enum.LootSlotType.Money or Enum.LootSlotType.Item
end
function GetLootSlotLink(i) return "|cff1eff00|Hitem:" .. i .. "|h[" .. stub.loot[i][2] .. "]|h|r" end
-- Master loot: the game answers a click with OPEN_MASTER_LOOT_LIST (stub.masterLoot on).
function LootSlot(i)
	stub.looted[#stub.looted + 1] = i
	if stub.masterLoot then return stub.fire("OPEN_MASTER_LOOT_LIST") end
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

-- The candidates: { name, class, classFile } by raid index; what the master looter did.
stub.candidates = { [1] = { "Testchar", "Warrior", "WARRIOR" }, [3] = { "Ayla", "Priest", "PRIEST" }, [4] = { "Bron", "Warrior", "WARRIOR" } }
stub.given, stub.rolled = nil, nil
MAX_RAID_MEMBERS = 40
function GetMasterLootCandidate(slot, i) local c = stub.candidates[i]; if c then return c[1], c[2], c[3] end end
function GiveMasterLoot(slot, i) stub.given = { slot, i } end
function DoMasterLootRoll(slot) stub.rolled = slot end
IsInRaid = function() return stub.raid or false end
Constants = Constants or {}
Constants.LootConsts = { MasterLootQualityThreshold = 2 }
ITEM_QUALITY_COLORS = ITEM_QUALITY_COLORS or { [2] = { r = 0.12, g = 1, b = 0, hex = "|cff1eff00" } }
for q, c in pairs(ITEM_QUALITY_COLORS) do c.hex = c.hex or ("|cff%02x%02x%02x"):format(c.r * 255, c.g * 255, c.b * 255) end
-- The game's menu (Blizzard_Menu): the description built, kept as stub.menu.
local function describe(t)
	t.items = {}
	function t:CreateTitle(text) self.items[#self.items + 1] = { title = text } end
	function t:CreateButton(text, fn)
		local b = describe({ text = text, fn = fn })
		self.items[#self.items + 1] = b
		return b
	end
	return t
end
MenuUtil = { CreateContextMenu = function(owner, gen)
	local m = describe({ owner = owner })
	function m:SetTag(tag) self.tag = tag end
	gen(owner, m)
	stub.menu = m
end }

-- The game opens the loot: LOOT_OPENED(isAutoLoot, acquiredFromItem).
function stub.openLoot(auto)
	for _, s in ipairs(stub.loot) do s.gone = nil end
	stub.fire("LOOT_OPENED", auto or false, false)
end
