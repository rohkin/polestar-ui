-- The client's trade skill for the crafting window: Tailoring, opened when
-- stub.tradeSkill is set and TRADE_SKILL_SHOW fires. Three categories; a
-- recipe not learnt yet; Mooncloth needs a moonwell and is on cooldown.

-- The game's event routing: our module stops its TRADE_SKILL_SHOW.
GameEvent = GameEvent or {}
stub.unrouted = {}
function GameEvent.UnregisterInternalEvent(event) stub.unrouted[event] = true end

Enum.CraftingReagentType = { Modifying = 0, Basic = 1, Finishing = 2, Automatic = 3 }
Enum.TradeskillRecipeType = { Item = 1, Salvage = 2, Enchant = 3, Gathering = 4 }
tContains = tContains or function(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end

-- item ID = { name, quality, held }
local ITEMS = {
	[2589] = { "Linen Cloth", 1, 9 }, [2996] = { "Bolt of Linen Cloth", 1, 1 }, [2320] = { "Coarse Thread", 1, 3 },
	[2318] = { "Light Leather", 1, 0 }, [14256] = { "Felcloth", 2, 2 },
	[10940] = { "Strange Dust", 1, 4 }, [5] = { "Breastplate of the Long Watch", 4 }, [2569] = { "Linen Vest", 1 },
	[2568] = { "Brown Linen Vest", 1 }, [4312] = { "Soft-soled Linen Boots", 2 }, [4238] = { "Linen Bag", 1 }, [14342] = { "Mooncloth", 2 },
}
C_Item = C_Item or {}
function C_Item.GetItemNameByID(id) return ITEMS[id] and ITEMS[id][1] end
function C_Item.GetItemIconByID(id) return ITEMS[id] and 134400 end
function C_Item.GetItemQualityByID(id) return ITEMS[id] and ITEMS[id][2] end
function C_Item.GetItemCount(id) return ITEMS[id] and ITEMS[id][3] or 0 end

local CATEGORIES = { [10] = { "Materials", 1 }, [11] = { "Armor", 2 }, [12] = { "Bags", 3 }, [13] = { "Enchantments", 4 } }
-- recipe ID = { name, category, difficulty, product, { { item, needed } }, learnt }
local RECIPES = {
	{ 2963, "Bolt of Linen Cloth", 10, 3, 2996, { { 2589, 2 } } },
	{ 18560, "Mooncloth", 10, 0, 14342, { { 14256, 2 } } },
	{ 2385, "Brown Linen Vest", 11, 2, 2568, { { 2996, 1 }, { 2320, 1 } } },
	{ 3845, "Soft-soled Linen Boots", 11, 1, 4312, { { 2996, 3 }, { 2318, 1 }, { 2320, 1 } } },
	{ 3914, "Brown Linen Pants", 11, 2, 2568, { { 2996, 2 } }, false },
	{ 3755, "Linen Bag", 12, 0, 4238, { { 2996, 3 }, { 2320, 3 } } },
	-- An enchant (listed while stub.enchanting): it goes on an item.
	{ 7420, "Enchant Chest - Minor Health", 13, 0, nil, { { 10940, 1 } }, nil, true },
}
local byID = {}
for _, r in ipairs(RECIPES) do byID[r[1]] = r end

IsModifiedClick = IsModifiedClick or function() return false end
SecondsToTime = SecondsToTime or function(s) return ("%d Days"):format(math.floor(s / 86400)) end

C_TradeSkillUI = C_TradeSkillUI or {}
local T = C_TradeSkillUI
function T.GetChildProfessionInfo() return { professionID = 0 } end
function T.GetBaseProfessionInfo()
	if stub.tradeSkill ~= "ready" then return { professionID = 0 } end
	return { professionID = 197, professionName = "Tailoring", skillLevel = 112, maxSkillLevel = 150, skillModifier = 0 }
end
function T.GetTradeSkillTexture() return 136249 end
function T.IsTradeSkillLinked() return false end
function T.IsTradeSkillGuild() return false end
function T.IsDataSourceChanging() return false end
-- The client's filters: skill-ups (not trivial), materials, item slots
-- (slot 1 Chest: the vest; slot 2 Feet: the boots; slot 3 Bag).
local only = { skill = false, make = false }
local SLOTS, SLOT_OF, hidden = { "Chest", "Feet", "Bag" }, { [2385] = 1, [3914] = 1, [3845] = 2, [3755] = 3 }, {}
function T.GetOnlyShowSkillUpRecipes() return only.skill end
function T.SetOnlyShowSkillUpRecipes(on) only.skill = on end
function T.GetOnlyShowMakeableRecipes() return only.make end
function T.SetOnlyShowMakeableRecipes(on) only.make = on end
function T.GetAllFilterableInventorySlotsCount() return #SLOTS end
function T.GetFilterableInventorySlotName(i) return SLOTS[i] end
function T.IsInventorySlotFiltered(i) return hidden[i] or false end
function T.SetInventorySlotFilter(i, shown) hidden[i] = not shown end
function T.AreAnyInventorySlotsFiltered() return next(hidden) ~= nil and (hidden[1] or hidden[2] or hidden[3]) or false end
function T.GetFilteredRecipeIDs()
	local ids = {}
	for _, r in ipairs(RECIPES) do
		local slot = SLOT_OF[r[1]]
		if (not r[8] or stub.enchanting) and not (only.skill and r[4] == 3) and not (only.make and T.GetCraftableCount(r[1]) == 0) and not (slot and hidden[slot]) then
			ids[#ids + 1] = r[1]
		end
	end
	return ids
end
function T.GetCategoryInfo(id) return { categoryID = id, name = CATEGORIES[id][1], uiOrder = CATEGORIES[id][2] } end
function T.GetRecipeInfo(id)
	local r = byID[id]
	return { recipeID = id, name = r[2], categoryID = r[3], relativeDifficulty = r[4], icon = 134400,
		learned = r[7] ~= false, craftable = true, disabled = false, isDummyRecipe = false, favorite = stub.favorites[id] or false }
end
-- Favorites (Linen Bag one already), kept by the client.
stub.favorites = { [3755] = true }
function T.IsRecipeFavorite(id) return stub.favorites[id] or false end
function T.SetRecipeFavorite(id, on) stub.favorites[id] = on or nil end
function T.GetCraftableCount(id)
	local n = math.huge
	for _, g in ipairs(byID[id][6]) do n = math.min(n, math.floor(C_Item.GetItemCount(g[1]) / g[2])) end
	return n
end
function T.GetRecipeSchematic(id)
	local r = byID[id]
	local slots = {}
	for i, g in ipairs(r[6]) do
		slots[i] = { reagents = { { itemID = g[1] } }, reagentType = 1, quantityRequired = g[2], slotIndex = i, hiddenInCraftingForm = false, required = true }
	end
	return { recipeID = id, name = r[2], icon = 134400, quantityMin = 1, quantityMax = 1, outputItemID = r[5], reagentSlotSchematics = slots,
		recipeType = r[8] and 3 or 1 }
end
function T.GetRecipeDescription(id)
	if id == 18560 then return "Turns felcloth into mooncloth, by the light of a moonwell." end
end
function T.GetRecipeRequirements(id)
	if id == 18560 then return { { name = "Moonwell", met = false, type = 0 } } end
	return {}
end
function T.GetRecipeCooldown(id) if id == 18560 then return 3 * 86400 end end
function T.GetRecipeLink(id) return ("|cffffd000|Henchant:%d|h[Tailoring: %s]|h|r"):format(id, byID[id][2]) end
function T.CraftRecipe(id, n) stub.crafted = { id, n } end
function T.CloseTradeSkill()
	stub.closed = (stub.closed or 0) + 1
	stub.tradeSkill = false
	stub.fire("TRADE_SKILL_CLOSE")
end
-- As the client: TRADE_SKILL_SHOW before the data, then the list's update.
function stub.openTradeSkill()
	stub.tradeSkill = true
	stub.fire("TRADE_SKILL_SHOW")
	stub.tradeSkill = "ready"
	stub.fire("TRADE_SKILL_LIST_UPDATE")
end
function T.CanTradeSkillShowCraftingUI(spellID) return true end

-- The enchant's items: the worn chest and a vest in the bags (by GUID).
local GUIDS = { ["Item-worn-5"] = { 5, true }, ["Item-bag-2569"] = { 2569, false } }
function C_Item.GetItemIDByGUID(guid) return GUIDS[guid] and GUIDS[guid][1] end
function C_Item.GetItemLocation(guid)
	local g = GUIDS[guid]
	return g and { guid = guid, IsEquipmentSlot = function() return g[2] end }
end
function T.GetEnchantItems(id) return id == 7420 and { "Item-worn-5", "Item-bag-2569" } or {} end
function T.CanStoreEnchantInItem(guid) return false end
function T.CraftEnchant(id, n, reagents, loc) stub.enchanted = { id, n, loc and loc.guid } end
-- The client's difficulty colours (SharedColorConstants), as ColorMixin tables.
DIFFICULT_DIFFICULTY_COLOR = { r = 1, g = 0.5, b = 0.25 }
FAIR_DIFFICULTY_COLOR = { r = 1, g = 1, b = 0 }
EASY_DIFFICULTY_COLOR = { r = 0.25, g = 0.75, b = 0.25 }
TRIVIAL_DIFFICULTY_COLOR = { r = 0.5, g = 0.5, b = 0.5 }
-- The profession's link (the stock link button's): stub.linked when put in
-- chat, stub.posted when posted in a channel. Not in a guild; in a party.
function T.CanTradeSkillListLink() return true end
function T.GetTradeSkillListLink() return "|Htrade:197|h[Tailoring]|h" end
IsInGuild = IsInGuild or function() return false end
IsInRaid = IsInRaid or function() return false end
GetNumSubgroupMembers = GetNumSubgroupMembers or function() return 1 end
GetChannelList = GetChannelList or function() return 1, "General", false end
ChatFrameUtil = ChatFrameUtil or {}
ChatFrameUtil.InsertLink = ChatFrameUtil.InsertLink or function(link) stub.linked = link end
function ChatFrameUtil.OpenChat(text) stub.posted = text end
