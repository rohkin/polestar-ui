-- The client's vendor for the Merchant window (MerchantFrameDocumentation.lua
-- and the globals MerchantFrame.lua calls); loaded after stub_npc.lua, which
-- makes the stock MerchantFrame, the interaction and CloseMerchant. Buys,
-- buybacks, sells, repairs and junk sales are recorded, never answered.

-- item = { name, itemID, icon, quality, price, stackCount, numAvailable, usable, maxStack, costs }
-- costs = { { icon, value, currencyName } }
stub.wares = {
	{ "Refreshing Spring Water", 159, 132794, 1, 25, 1, -1, true, 20 },
	{ "Rough Arrow", 2512, 132382, 1, 10, 200, -1, true, 1000 },
	{ "Tough Hunk of Bread", 4540, 133964, 1, 25, 1, 3, true, 20 },
	{ "Formula: Enchant Bracer", 6342, 134939, 2, 50000, 1, 0, true, 1 },
	{ "Mageweave Robe", 4041, 132666, 2, 1800000, 1, -1, false, 1 },
	{ "Champion's Tabard", 15196, 135026, 4, 0, 1, -1, true, 1, { { 136998, 2, "Honor" } } },
	{ "Grimoire of Sacrifice", 9214, 133738, 3, 230000, 1, -1, true, 1 },
}
-- item = { name, itemID, icon, quality, price, quantity }
stub.buyback = {
	{ "Linen Cloth", 2589, 132889, 1, 10, 20 },
	{ "Malachite", 774, 134132, 2, 50, 3 },
}
stub.repairCost, stub.guildRepair, stub.junk = 23456, false, 3
stub.bought, stub.boughtBack, stub.sold, stub.repaired, stub.junkSold = {}, {}, 0, {}, 0
stub.cursorItem = false

local function ware(i) return stub.wares[i] end

local unitName = UnitName
function UnitName(unit, ...)
	if unit == "npc" then return "Harlan Bagley" end
	return unitName(unit, ...)
end
function GetMerchantNumItems() return #stub.wares end
C_MerchantFrame = {}
function C_MerchantFrame.GetItemInfo(i)
	local w = ware(i)
	if not w then return nil end
	return { name = w[1], texture = w[3], price = w[5], stackCount = w[6], numAvailable = w[7], isUsable = w[8], isPurchasable = true, hasExtendedCost = w[10] ~= nil }
end
function C_MerchantFrame.IsMerchantItemRefundable(i) return ware(i)[10] == nil end
function C_MerchantFrame.IsSellAllJunkEnabled() return true end
function C_MerchantFrame.GetNumJunkItems() return stub.junk end
function C_MerchantFrame.SellAllJunkItems() stub.junkSold = stub.junkSold + 1 end
function GetMerchantItemLink(i) return ware(i) and "item:" .. ware(i)[2] end
function GetMerchantItemMaxStack(i) return ware(i)[9] end
function CanAffordMerchantItem(i) return GetMoney() >= ware(i)[5] end
function GetMerchantItemCostInfo(i) return #(ware(i)[10] or {}) end
function GetMerchantItemCostItem(i, k)
	local c = (ware(i)[10] or {})[k]
	if c then return c[1], c[2], nil, c[3] end
end
function BuyMerchantItem(i, n) stub.bought[#stub.bought + 1] = { i, n } end
function PickupMerchantItem(i)
	if i == 0 and stub.cursorItem then stub.sold, stub.cursorItem = stub.sold + 1, false end
end
function CursorHasItem() return stub.cursorItem end

function GetNumBuybackItems() return #stub.buyback end
function GetBuybackItemInfo(i)
	local b = stub.buyback[i]
	if b then return b[1], b[3], b[5], b[6], -1, true, false end
end
function GetBuybackItemLink(i) return stub.buyback[i] and "item:" .. stub.buyback[i][2] end
function BuybackItem(i) stub.boughtBack[#stub.boughtBack + 1] = i end

function CanMerchantRepair() return stub.repairCost ~= nil end
function GetRepairAllCost() return stub.repairCost or 0, (stub.repairCost or 0) > 0 end
function CanGuildBankRepair() return stub.guildRepair end
function RepairAllItems(guild) stub.repaired[#stub.repaired + 1] = guild and "guild" or "own" end

-- A quality per item, from either list, by link.
C_Item = C_Item or {}
function C_Item.GetItemQualityByID(l)
	local id = tonumber(tostring(l):match("item:(%d+)"))
	for _, list in ipairs({ stub.wares, stub.buyback }) do
		for _, w in ipairs(list) do if w[2] == id then return w[4] end end
	end
end

function GameTooltip:SetMerchantItem(i) self:SetText(ware(i)[1]) end
function GameTooltip:SetBuybackItem(i) self:SetText(stub.buyback[i][1]) end
function IsModifiedClick(what) return IsShiftKeyDown() and (what == nil or what == "SPLITSTACK") end
function HandleModifiedItemClick() return false end

-- The filter (LE_LOOT_FILTER_*) and the game's menu, as the stock dropdown reads them.
LE_LOOT_FILTER_ALL, LE_LOOT_FILTER_CLASS, LE_LOOT_FILTER_SPEC1, LE_LOOT_FILTER_BOE = 0, 1, 2, 6
ITEM_BIND_ON_EQUIP, ALL = "Binds when equipped", "All"
stub.filter = LE_LOOT_FILTER_CLASS
function GetMerchantFilter() return stub.filter end
function SetMerchantFilter(v) stub.filter = v end
function ResetSetMerchantFilter() stub.filter = LE_LOOT_FILTER_CLASS end
function GetNumSpecializations() return 0 end
MenuUtil = { CreateContextMenu = function(owner, gen)
	local m = { owner = owner, items = {} }
	gen(owner, {
		SetTag = function(_, tag) m.tag = tag end,
		CreateRadio = function(_, text, get, set, v) m.items[#m.items + 1] = { text = text, get = get, set = set, value = v } end,
		CreateDivider = function() end,
	})
	stub.menu = m
end }

-- Polestar's Restock (QoL/Restock.lua) with this plan; nil takes the export away.
-- Polestar sets Polestar itself as it loads, so a scene calls this after login.
function stub.restock(plan)
	stub.restocked = 0
	if not plan then
		if Polestar.QoL then Polestar.QoL.Restock = nil end
		return
	end
	Polestar.QoL = Polestar.QoL or {}
	Polestar.QoL.Restock = {
		Plan = function() return plan, {} end,
		Run = function() stub.restocked = stub.restocked + 1 end,
	}
end
