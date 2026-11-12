-- The client calls the Character window reads (tests/lua/wow_stub.lua has
-- UnitName only); the values are the preview's sample character.
function UnitLevel(unit) return 24 end
function UnitRace(unit) return "Human", "Human" end
function UnitClass(unit) return "Warrior", "WARRIOR", 1 end
function GetClassAtlas(class) return "classicon-" .. class end
function UnitPVPName(unit) return InCombatLockdown() and stub.SECRET or "Testchar" end
function GetGuildInfo(unit) return InCombatLockdown() and stub.SECRET or "The Night Watch", "Member", 3 end
function ToggleCharacter(tab, onlyShow) end
-- The game's own open for a spell waiting on an item (an enchant): with the
-- stock frame hidden, it toggles.
function ShowCharacterFrameIfMatchesContext() ToggleCharacter("PaperDollFrame") end

-- Gear: the client's slot ids; a few items of each quality, one worn down,
-- one broken, the rest empty. Icons are client art, which the preview does
-- not draw: the wells and their borders show.
local SLOT_IDS = { AmmoSlot = 0, HeadSlot = 1, NeckSlot = 2, ShoulderSlot = 3, ShirtSlot = 4, ChestSlot = 5, WaistSlot = 6,
	LegsSlot = 7, FeetSlot = 8, WristSlot = 9, HandsSlot = 10, Finger0Slot = 11, Finger1Slot = 12, Trinket0Slot = 13,
	Trinket1Slot = 14, BackSlot = 15, MainHandSlot = 16, SecondaryHandSlot = 17, RangedSlot = 18, TabardSlot = 19 }
C_PaperDollInfo = C_PaperDollInfo or {}
function C_PaperDollInfo.GetInventorySlotInfo(name)
	return SLOT_IDS[name], "Interface/PaperDoll/UI-PaperDoll-Slot-" .. name, false
end
ITEM_QUALITY_COLORS = { [1] = { r = 1, g = 1, b = 1 }, [2] = { r = 0.12, g = 1, b = 0 }, [3] = { r = 0, g = 0.44, b = 0.87 }, [4] = { r = 0.64, g = 0.21, b = 0.93 } }
-- slot id = { quality, durability left (fraction), broken }
local GEAR = { [1] = { 3, 1 }, [3] = { 2, 1 }, [5] = { 4, 1 }, [7] = { 2, 0.2 }, [8] = { 1, 1 }, [10] = { 2, 0, true }, [15] = { 1, 1 }, [16] = { 3, 1 }, [18] = { 2, 1 }, [0] = { 1, 1 } }
function GetInventoryItemTexture(unit, id) return GEAR[id] and 134400 or nil end
function GetInventoryItemQuality(unit, id) return GEAR[id] and GEAR[id][1] end
function GetInventoryItemBroken(unit, id) return GEAR[id] and GEAR[id][3] or false end
function GetInventoryItemDurability(id) if GEAR[id] then return GEAR[id][2] * 100, 100 end end
-- Names for the worn items; names as long as the game's longest fit.
local NAMES = { [1] = "Helm of the Fallen Champion", [3] = "Ridge Spaulders", [5] = "Breastplate of the Long Watch",
	[7] = "Scouting Leggings", [8] = "Worn Boots", [10] = "Bloodied Gauntlets", [15] = "Frayed Cloak", [16] = "Whirling Blade", [18] = "Hunting Bow", [0] = "Rough Arrow" }
function GetInventoryItemLink(unit, id)
	if GEAR[id] then return ("|cff1eff00|Hitem:%d::::::::24:::::|h[%s]|h|r"):format(id, NAMES[id]) end
end
-- The game's item tooltip: the worn item's name, true when the slot holds one.
function GameTooltip.SetInventoryItem(self, unit, id)
	self.lines = { NAMES[id] }
	return GEAR[id] ~= nil
end
SHIRTSLOT, TABARDSLOT, FINGER1SLOT, TRINKET1SLOT, AMMOSLOT = "Shirt", "Tabard", "Finger", "Trinket", "Ammo"
C_Item = C_Item or {}
-- The ranged slot holds a bow (weapon class 2, subclass 2): it shoots ammo.
function C_Item.GetItemInfoInstant(link)
	if tonumber(link:match("item:(%d+)")) == 18 then return 18, "Weapon", "Bows", "INVTYPE_RANGED", 134400, 2, 2 end
end

-- The cursor holds an item that fits stub.cursorFits[slot id]; the bags
-- (backpack only) hold two items.
function CursorHasItem() return stub.cursorFits ~= nil end
function C_PaperDollInfo.CursorCanGoInSlot(id) return stub.cursorFits and stub.cursorFits[id] or false end
NUM_BAG_SLOTS = 4
C_Container = C_Container or {}
function C_Container.GetContainerNumSlots(bag) return bag == 0 and 2 or 0 end
function C_Container.GetContainerItemLink(bag, i) return ("|Hitem:9%d::::::::24:::::|h[Bag item]|h"):format(i) end

-- The chest and gloves carry an enchant, read off their tooltip data.
ENCHANTED_TOOLTIP_LINE = "Enchanted: %s"
local ENCHANTS = { [5] = "Enchanted: +4 All Stats", [10] = "+15 Agility" }
C_TooltipInfo = C_TooltipInfo or {}
function C_TooltipInfo.GetInventoryItem(unit, id)
	return { lines = { { type = 0, leftText = NAMES[id] }, ENCHANTS[id] and { type = 15, leftText = ENCHANTS[id] } or nil } }
end

-- The gloves have a Use: effect (an engineering tinker).
function GetInventoryItemID(unit, id) return GEAR[id] and id end
function C_Item.GetItemSpell(link) if link:match("item:10:") then return "Nitro Boosts", 55004 end end

-- A spell (an enchant, a stone) waiting for its item: stub.targeting.
function SpellIsTargeting() return stub.targeting or false end
-- A worn item picked up (or the cursor's put down): stub.pickedUp = slot id.
function PickupInventoryItem(id) stub.pickedUp = id end

-- The character-sheet model scene: the preview draws its well, not the model.
ModelSceneUtil = { SetUpCharacterSheetScene = function(scene) end }

-- Stats: the stock categories and their update functions, filled with the
-- sample warrior's numbers the way the stock ones fill a row.
STAT_FORMAT, STAT_AVERAGE_ITEM_LEVEL = "%s:", "Item Level"
local function stat(label, value, hidden)
	return { updateFunc = function(r)
		if hidden then r:Hide() return end
		r.Label:SetText(STAT_FORMAT:format(label))
		-- stub.secretStats: the client makes a value secret, even out of combat.
		if stub.secretStats then r.Value:SetText(stub.SECRET) return end
		r.Value:SetText(value)
		r.numericValue = tonumber(value) or 1
		r.tooltip = label .. " " .. value
	end }
end
function PaperDollStatTooltip(r) end
PAPERDOLL_STATINFO = {
	HEALTH = stat("Health", "1,240"), POWER = stat("Rage", "100"),
	STRENGTH = stat("Strength", "|cff20ff2078|r"), AGILITY = stat("Agility", "45"), STAMINA = stat("Stamina", "71"),
	INTELLECT = stat("Intellect", "22"), SPIRIT = stat("Spirit", "31"),
	MAINHAND_DAMAGE = stat("Main Hand", "41 - 63"), OFFHAND_DAMAGE = stat("Off Hand", "0"), ATTACK_AP = stat("Attack Power", "196"),
	HITCHANCE = stat("Hit", "2%"), CRITCHANCE = stat("Crit", "6.4%"), SPELLPOWER = stat("Spell Power", "0", true),
	DEFENSE = stat("Defense", "120"), DODGE = stat("Dodge", "5.1%"), PARRY = stat("Parry", "5%"), ARMOR = stat("Armor", "1,032"),
}
-- Movement speed is secret in combat: the stock maths on it errors there.
PAPERDOLL_STATINFO.MOVESPEED = { updateFunc = function(r)
	if InCombatLockdown() then error("attempt to perform arithmetic on local 'runSpeed' (a secret number value)") end
	stat("Movement Speed", "100%").updateFunc(r)
end }
PAPERDOLL_STATCATEGORIES = {
	{ categoryName = "General", unit = "player", stats = { { stat = "HEALTH" }, { stat = "POWER" }, { stat = "MOVESPEED" } } },
	{ categoryName = "Attributes", unit = "player", stats = { { stat = "STRENGTH" }, { stat = "AGILITY" }, { stat = "STAMINA" }, { stat = "INTELLECT" }, { stat = "SPIRIT" } } },
	{ categoryName = "Weapons", unit = "player", stats = { { stat = "MAINHAND_DAMAGE" }, { stat = "OFFHAND_DAMAGE", hideAt = 0 }, { stat = "ATTACK_AP" } } },
	{ categoryName = "Modifiers", unit = "player", stats = { { stat = "HITCHANCE" }, { stat = "CRITCHANCE" }, { stat = "SPELLPOWER", hideAt = 0 } } },
	{ categoryName = "Defense", unit = "player", stats = { { stat = "DEFENSE" }, { stat = "DODGE" }, { stat = "PARRY" }, { stat = "ARMOR" } } },
	{ categoryName = "Pet", unit = "pet", stats = { { stat = "HEALTH" } } },
}

-- The other sections: a few factions, currencies, skills and a PvP rank.
function UnitSex(unit) return 2 end
function UnitFactionGroup(unit) return "Alliance", "Alliance" end
function BreakUpLargeNumbers(n)
	local s = tostring(math.floor(n))
	while true do
		local k
		s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then return s end
	end
end
function GetText(key) return _G[key] or key end
FACTION_STANDING_LABEL4, FACTION_STANDING_LABEL5, FACTION_STANDING_LABEL6 = "Neutral", "Friendly", "Honored"
FACTION_BAR_COLORS = { [4] = { r = 1, g = 1, b = 0 }, [5] = { r = 0, g = 0.6, b = 0.1 }, [6] = { r = 0, g = 0.6, b = 0.1 } }
local function faction(name, reaction, cur, lo, hi, extra)
	local d = { name = name, description = "", reaction = reaction, currentStanding = cur, currentReactionThreshold = lo,
		nextReactionThreshold = hi, isHeader = false, isChild = false, isCollapsed = false, isWatched = false }
	for k, v in pairs(extra or {}) do d[k] = v end
	return d
end
local FACTIONS = {
	faction("Alliance", 0, 0, 0, 0, { isHeader = true }),
	faction("Stormwind", 6, 11200, 9000, 21000, { isWatched = true }),
	faction("Ironforge", 5, 4100, 3000, 9000),
	faction("Darnassus", 4, 1500, 0, 3000),
	faction("Classic", 0, 0, 0, 0, { isHeader = true, isCollapsed = true }),
}
C_Reputation = { GetNumFactions = function() return #FACTIONS end, GetFactionDataByIndex = function(i) return FACTIONS[i] end }

local CURRENCIES = {
	{ name = "Player vs. Player", isHeader = true, isHeaderExpanded = true },
	{ name = "Honor Points", isHeader = false, quantity = 1240, maxQuantity = 75000, iconFileID = 1455894 },
	{ name = "Arena Points", isHeader = false, quantity = 0, maxQuantity = 0, iconFileID = 1455894 },
	{ name = "Miscellaneous", isHeader = true, isHeaderExpanded = true },
	{ name = "Darkmoon Prize Ticket", isHeader = false, quantity = 12, maxQuantity = 0, iconFileID = 134481 },
}
C_CurrencyInfo = { GetCurrencyListSize = function() return #CURRENCIES end, GetCurrencyListInfo = function(i) return CURRENCIES[i] end }
-- Folding hides the header's currencies from the list, as the client does,
-- and sends no event.
local hidden = {}
function C_CurrencyInfo.ExpandCurrencyList(index, expand)
	local h = CURRENCIES[index]
	h.isHeaderExpanded = expand
	if expand then
		for i, c in ipairs(hidden[h] or {}) do table.insert(CURRENCIES, index + i, c) end
		hidden[h] = nil
	else
		hidden[h] = {}
		while CURRENCIES[index + 1] and not CURRENCIES[index + 1].isHeader do
			table.insert(hidden[h], table.remove(CURRENCIES, index + 1))
		end
	end
end

local function skill(name, rank, max, extra)
	local d = { name = name, rank = rank, maxRank = max, modifier = 0, isHeader = false, isCollapsed = false,
		parentSkillLineID = 0, skillLineCategoryID = 9, skillID = 0, description = "" }
	for k, v in pairs(extra or {}) do d[k] = v end
	return d
end
local SKILLS = {
	skill("Class Skills", 0, 0, { isHeader = true, skillID = 7 }),
	skill("Arms", 1, 1, { skillLineCategoryID = 7 }),
	skill("Professions", 0, 0, { isHeader = true, skillID = 11 }),
	skill("Mining", 112, 150),
	skill("Blacksmithing", 95, 150),
	skill("Weapon Skills", 0, 0, { isHeader = true, skillID = 6 }),
	skill("Swords", 118, 120, { modifier = 5 }),
	skill("Two-Handed Swords", 64, 120),
}
C_SkillInfo = { GetNumSkillLines = function() return #SKILLS end, GetSkillLineInfo = function(i) return SKILLS[i] end }

Enum.PvPRanks = { Rank_1 = 5 }
PVP_RANK_9_1, PVP_RANK_NUMBER = "Sergeant", "Rank %d"
EXPANSION_SEASON_NAME = "%sSeason %d"
function GetCurrentArenaSeason() return 1 end
C_MajorFactions = { GetMajorFactionProgressionInfo = function(id)
	return { renownLevel = 5, renownReputationEarned = 1240, renownLevelThreshold = 2000 }
end }

-- Statistics: two top categories (one with a sub-category) and one left
-- folded; a money value, a count and a zero ("--").
STATISTICS = "Statistics"
local STAT_CATS = { [130] = { "Character", -1 }, [140] = { "Wealth", 130 }, [141] = { "Combat", -1 }, [145] = { "Deaths", -1 } }
local STATS = {
	[130] = { { "Quests completed", "212" }, { "Daily quests completed", "0" } },
	[140] = { { "Gold looted", "54|TInterface/MoneyFrame/UI-GoldIcon:0:0:2:0|t" }, { "Most gold ever owned", "61" } },
	[141] = { { "Creatures killed", "14820" } },
	[145] = { { "Total deaths", "37" } },
}
function GetStatisticsCategoryList() return { 130, 140, 141, 145 } end
function GetCategoryInfo(id) return STAT_CATS[id][1], STAT_CATS[id][2] end
function GetCategoryNumAchievements(id) return #(STATS[id] or {}) end
function GetStatistic(id, i) return STATS[id][i][2], false, id * 100 + i end
function GetAchievementInfo(statID)
	local s = STATS[math.floor(statID / 100)][statID % 100]
	return statID, s[1]
end

-- Resistances, as the stock pane reads them (UnitResistance's effective value).
Enum.Damageclass = { Arcane = 6, Fire = 2, Frost = 4, Nature = 3, Shadow = 5 }
DAMAGE_SCHOOL3, DAMAGE_SCHOOL4, DAMAGE_SCHOOL5, DAMAGE_SCHOOL6, DAMAGE_SCHOOL7 = "Fire", "Nature", "Frost", "Shadow", "Arcane"
STAT_CATEGORY_RESISTANCE = "Resistance"
function UnitResistance(unit, class) local v = class == 2 and 15 or 0; return v, v, v, 0 end

-- Titles: three known of four, the second worn; SetCurrentTitle records stub.title.
PLAYER_TITLE_NONE = "None"
local TITLES = { { "Private %s", true }, { "Scout %s", true }, { "Grunt %s", false }, { "%s the Explorer", true } }
local currentTitle = 2
function GetNumTitles() return #TITLES end
function IsTitleKnown(i) return TITLES[i] and TITLES[i][2] or false end
function GetTitleName(i) return TITLES[i][1]:gsub("%%s", ""), true end
function GetCurrentTitle() return currentTitle end
function SetCurrentTitle(i) currentTitle, stub.title = i, i end
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
