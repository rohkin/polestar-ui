-- The client's auction house as the Auction sees it (C_AuctionHouse,
-- AuctionHouseDocumentation.lua): browse results, commodity and item
-- listings, a commodity quote, the player's auctions. Load after
-- stub_npc.lua (the interaction manager, the stock AuctionHouseFrame,
-- GameEvent's routing, money). Buys, bids, posts and cancels are recorded;
-- the calls the client restricts to a hardware event error unless our click
-- runs them. The client's answers come at once (their events fire inside the call).

local T = Enum.PlayerInteractionType
Enum.AuctionHouseSortOrder = { Price = 0, Name = 1, Level = 2, Bid = 3, Buyout = 4, TimeRemaining = 5 }
Enum.ItemCommodityStatus = { Unknown = 0, Item = 1, Commodity = 2 }
Enum.AuctionStatus = { Active = 0, Sold = 1 }
Enum.AuctionHouseTimeLeftBand = { Short = 0, Medium = 1, Long = 2, VeryLong = 3 }
Enum.AuctionHouseFilter = { None = 0, UncollectedOnly = 1, UsableOnly = 2, CurrentExpansionOnly = 3, UpgradesOnly = 4, ExactMatch = 5, PoorQuality = 6, CommonQuality = 7, UncommonQuality = 8, RareQuality = 9, EpicQuality = 10, LegendaryQuality = 11, ArtifactQuality = 12, LegendaryCraftedItemOnly = 13 }
Enum.AuctionHouseFilterCategory = { Uncategorized = 0, Equipment = 1, Rarity = 2 }
-- The item classes the stock categories name (ItemConstantsDocumentation.lua).
Enum.ItemClass = { Consumable = 0, Container = 1, Weapon = 2, Armor = 4, Projectile = 6, Tradegoods = 7, Recipe = 9, Quiver = 11, Questitem = 12, Miscellaneous = 15 }
Enum.ItemWeaponSubclass = { Axe1H = 0, Axe2H = 1, Bows = 2, Guns = 3, Mace1H = 4, Mace2H = 5, Polearm = 6, Sword1H = 7, Sword2H = 8, Staff = 10, Unarmed = 13, Generic = 14, Dagger = 15, Thrown = 16, Crossbow = 18, Wand = 19, Fishingpole = 20 }
Enum.ItemArmorSubclass = { Generic = 0, Cloth = 1, Leather = 2, Mail = 3, Plate = 4, Shield = 6, Libram = 7, Idol = 8, Totem = 9 }
Enum.ItemContainerSubclass = { Bag = 0, Soul = 1, Herb = 2, Enchanting = 3, Engineering = 4, Mining = 6, Leatherworking = 7, Tacklebox = 9, Cooking = 10, Reagent = 11 }
Enum.ItemQuiverSubclass = { Quiver = 2, Ammopouch = 3 }
Enum.ItemConsumableSubclass = { Generic = 0, Potion = 1, Elixir = 2, Flask = 3, Scroll = 4, Fooddrink = 5, Itemenhancement = 6, Bandage = 7, Other = 8, ItemenhancementTemporary = 9 }
Enum.ItemRecipeSubclass = { Book = 0, Leatherworking = 1, Tailoring = 2 }
Enum.InventoryType = { IndexHeadType = 1, IndexNeckType = 2, IndexShoulderType = 3, IndexBodyType = 4, IndexChestType = 5, IndexWaistType = 6, IndexLegsType = 7, IndexFeetType = 8, IndexWristType = 9, IndexHandType = 10, IndexFingerType = 11, IndexTrinketType = 12, IndexCloakType = 16, IndexRobeType = 20, IndexHoldableType = 23, IndexRelicType = 28 }

-- The stock addon (Blizzard_AuctionHouseUI): loaded by either stock open,
-- which shows AuctionHouseFrame (Bootstrap.lua's ShowAuctionHouseFrame).
stub.stockLoaded = false
function ShowAuctionHouseFrame()
	stub.stockLoaded = true
	AuctionHouseFrame:Show()
end
RegisterPlayerInteraction(T.Auctioneer, { frame = "AuctionHouseFrame", showFunc = ShowAuctionHouseFrame })
-- Forever's second route (EventRouting.lua): AUCTION_HOUSE_SHOW opens it too.
local route = CreateFrame("Frame")
route:RegisterEvent("AUCTION_HOUSE_SHOW")
route:RegisterEvent("AUCTION_HOUSE_CLOSED")
route:SetScript("OnEvent", function(_, e) if e == "AUCTION_HOUSE_SHOW" then ShowAuctionHouseFrame() end end)
local unregister = GameEvent.UnregisterInternalEvent
function GameEvent.UnregisterInternalEvent(e)
	unregister(e)
	route:UnregisterEvent(e)
end

-- A hardware event: the innermost script running is a click (the client's
-- rule for its restricted calls: never from an event, a timer or OnUpdate).
local function hardware()
	for level = 2, 60 do
		local info = debug.getinfo(level, "f")
		if not info then return false end
		if info.func == stub.RunScript then
			local _, script = debug.getlocal(level, 2)
			return script == "OnClick"
		end
	end
	return false
end
local function restricted(name)
	assert(hardware(), name .. " without a hardware event")
end

-- Items: [itemID] = { name, icon, quality, commodity, vendor price }.
stub.ahItems = {
	[2589] = { "Linen Cloth", 132889, 1, true, 13 },
	[2592] = { "Wool Cloth", 132911, 1, true, 33 },
	[6975] = { "Whirlwind Axe", 132397, 3, false, 25000 },
	[2244] = { "Krol Blade", 135346, 4, false, 90000 },
}
-- Browse results: { itemID, totalQuantity, minPrice, classID }.
stub.browse = { { 2589, 350, 120, 7 }, { 2592, 80, 450, 7 }, { 6975, 3, 1800000, 2 }, { 2244, 1, 25000000, 2 } }
-- Commodity listings, cheapest first: { unitPrice, quantity, numOwnerItems }.
stub.commodity = { [2589] = { { 120, 200, 0 }, { 125, 100, 0 }, { 140, 50, 20 } }, [2592] = { { 450, 80, 0 } } }
-- Item listings: { auctionID, buyout, minBid, timeLeft band, own }.
stub.itemList = { [6975] = { { 901, 1800000, 1500000, 3 }, { 902, nil, 1200000, 1 }, { 903, 2000000, 1900000, 2, true } } }
-- The player's auctions: { auctionID, itemID, quantity, buyout, status, timeLeft band }.
stub.owned = { { 701, 2592, 20, 9000, 0, 2 }, { 702, 6975, 1, 2500000, 0, 3 }, { 703, 2589, 5, 600, 1 } }
stub.cancelCost = { [701] = 0, [702] = 12500 }
-- The quote's unit price (nil: the listings' own; false: none to be had).
stub.quoteUnit = nil
stub.browseQuery, stub.started, stub.bought, stub.quoteCancelled = nil, nil, nil, 0
stub.bids, stub.posted, stub.confirmedPost, stub.cancelled = {}, nil, nil, {}
stub.postNeedsConfirm = false
stub.cursor = nil
stub.bagCount = { [2589] = 40, [6975] = 1 }
stub.npcClosed.CloseAuctionHouse = 0

-- Class, subclass and slot names (C_Item), and the subclasses the auction house lists.
local SUBNAMES = { [2] = { [0] = "One-Handed Axes", [4] = "One-Handed Maces", [7] = "One-Handed Swords", [15] = "Daggers" },
	[4] = { [0] = "Miscellaneous", [1] = "Cloth", [2] = "Leather", [3] = "Mail", [4] = "Plate", [6] = "Shields" },
	[0] = { [1] = "Potion", [7] = "Bandage", [8] = "Other" }, [9] = { [0] = "Book", [1] = "Leatherworking", [2] = "Tailoring" }, [7] = { [0] = "Cloth", [1] = "Metal & Stone" } }
local SLOTNAMES = { [1] = "Head", [3] = "Shoulder", [5] = "Chest", [6] = "Waist", [7] = "Legs", [8] = "Feet", [9] = "Wrist", [10] = "Hands", [28] = "Relic" }
C_Item = C_Item or {}
function C_Item.GetItemSubClassInfo(c, s) return (SUBNAMES[c] or {})[s] or ("Subclass " .. c .. "." .. s) end
function C_Item.GetItemInventorySlotInfo(t) return SLOTNAMES[t] or ("Slot " .. t) end
function C_Item.GetItemClassInfo(c) return "Class " .. c end
stub.ahSubclasses = { [0] = { 1, 7, 6, 9, 8 }, [7] = { 0, 1 }, [6] = { 2, 3 }, [9] = { 0, 1, 2 }, [15] = { 0, 2 } }

local function key(id) return { itemID = id, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 } end

C_AuctionHouse = {}
local AH = C_AuctionHouse
function AH.CloseAuctionHouse()
	stub.npcClosed.CloseAuctionHouse = stub.npcClosed.CloseAuctionHouse + 1
	stub.endInteraction(T.Auctioneer)
end
AH.MakeItemKey = key
-- Forever's filter groups (as Classic's: usable, then the rarities to Legendary).
function AH.GetFilterGroups()
	return { { category = 1, filters = { 2, 4 } }, { category = 2, filters = { 6, 7, 8, 9, 10, 11 } } }
end
function AH.GetAuctionItemSubClasses(c) return stub.ahSubclasses[c] or {} end
function AH.GetItemKeyInfo(k)
	local it = stub.ahItems[k.itemID]
	if it then return { itemID = k.itemID, battlePetSpeciesID = 0, itemName = it[1], iconFileID = it[2], quality = it[3], isCommodity = it[4], isPet = false, isEquipment = not it[4] } end
end
-- Required levels and the browse list's extra column (container slots, recipe skill).
stub.reqLevel = { [6975] = 42, [2244] = 40 }
function AH.GetItemKeyRequiredLevel(k) return stub.reqLevel[k.itemID] or 0 end
function AH.GetExtraBrowseInfo(k) return 0 end
function AH.ShouldAutoPopulatePrice() return true end
function AH.SupportsCopperValues() return true end

-- Favorites: kept by item ID; the favorites search lists them.
stub.favorites, stub.maxFavorites = {}, 3
function AH.FavoritesAreAvailable() return true end
function AH.IsFavoriteItem(k) return stub.favorites[k.itemID] or false end
function AH.HasFavorites() return next(stub.favorites) ~= nil end
function AH.HasMaxFavorites()
	local n = 0
	for _ in pairs(stub.favorites) do n = n + 1 end
	return n >= stub.maxFavorites
end
function AH.SetFavoriteItem(k, on) stub.favorites[k.itemID] = on or nil end
function AH.SearchForFavorites(sorts)
	stub.browseQuery = { searchString = "", favorites = true, sorts = sorts }
	stub.fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
end

-- Browse: the search text and class filters narrow the list.
function AH.SendBrowseQuery(q)
	stub.browseQuery = q
	stub.fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
end
function AH.GetBrowseResults()
	local q, out = stub.browseQuery or { searchString = "" }, {}
	for _, b in ipairs(stub.browse) do
		local fits = not q.itemClassFilters or #q.itemClassFilters == 0
		for _, c in ipairs(q.itemClassFilters or {}) do fits = fits or c.classID == b[4] end
		if q.favorites then fits = stub.favorites[b[1]] end
		if fits and stub.ahItems[b[1]][1]:lower():find(q.searchString:lower(), 1, true) then
			out[#out + 1] = { itemKey = key(b[1]), totalQuantity = b[2], minPrice = b[3], containsOwnerItem = false }
		end
	end
	return out
end

-- Listings of one item, for buying and for the sell price.
local function search(k)
	if stub.ahItems[k.itemID][4] then stub.fire("COMMODITY_SEARCH_RESULTS_UPDATED", k.itemID) else stub.fire("ITEM_SEARCH_RESULTS_UPDATED", k) end
end
function AH.SendSearchQuery(k, sorts, separate, minLevel, maxLevel)
	stub.searchQuery = { key = k, sorts = sorts, minLevel = minLevel, maxLevel = maxLevel }
	search(k)
end
function AH.SendSellSearchQuery(k) search(k) end
function AH.GetNumCommoditySearchResults(id) return #(stub.commodity[id] or {}) end
function AH.GetCommoditySearchResultInfo(id, i)
	local c = (stub.commodity[id] or {})[i]
	if c then return { itemID = id, unitPrice = c[1], quantity = c[2], numOwnerItems = c[3], containsOwnerItem = c[3] > 0, auctionID = 500 + i, owners = c[3] > 0 and { "player", "Trader" } or { "Trader" }, totalNumberOfOwners = c[3] > 0 and 2 or 1 } end
end
function AH.GetCommoditySearchResultsQuantity(id)
	local n = 0
	for _, c in ipairs(stub.commodity[id] or {}) do n = n + c[2] end
	return n
end
function AH.GetNumItemSearchResults(k) return #(stub.itemList[k.itemID] or {}) end
function AH.GetItemSearchResultInfo(k, i)
	local a = (stub.itemList[k.itemID] or {})[i]
	if a then return { itemKey = k, auctionID = a[1], buyoutAmount = a[2], minBid = a[3], timeLeft = a[4], quantity = 1, containsOwnerItem = a[5] or false, owners = { a[5] and "player" or ("Seller" .. a[1]) }, totalNumberOfOwners = 1 } end
end

-- Buying: a commodity's quote, then its confirm; an item's bid or buyout.
function AH.StartCommoditiesPurchase(id, n, unit)
	restricted("StartCommoditiesPurchase")
	stub.started = { id, n, unit }
	local q = stub.quoteUnit
	if q == false then return stub.fire("COMMODITY_PRICE_UNAVAILABLE") end
	q = q or unit
	stub.fire("COMMODITY_PRICE_UPDATED", q, q * n)
end
function AH.ConfirmCommoditiesPurchase(id, n)
	restricted("ConfirmCommoditiesPurchase")
	stub.bought = { id, n }
	stub.fire("COMMODITY_PURCHASE_SUCCEEDED")
end
function AH.CancelCommoditiesPurchase() stub.quoteCancelled = stub.quoteCancelled + 1 end
function AH.PlaceBid(id, amount)
	restricted("PlaceBid")
	stub.bids[#stub.bids + 1] = { id, amount }
end

-- Selling: the cursor's item (an ItemLocation), its deposit, the post.
C_Cursor = { GetCursorItem = function() return stub.cursor end }
function ClearCursor() stub.cursor = nil end
function CursorHasItem() return stub.cursor ~= nil end
function stub.holdItem(id)
	stub.cursor = { itemID = id, IsValid = function() return true end }
end
C_Item = C_Item or {}
function C_Item.GetItemID(loc) return loc.itemID end
local itemInfo = C_Item.GetItemInfo
function C_Item.GetItemInfo(id, ...)
	local it = stub.ahItems[id]
	if it then return it[1], "item:" .. id, it[3], 1, 1, "", "", 1, "", it[2], it[5] end
	if itemInfo then return itemInfo(id, ...) end
end
function AH.IsSellItemValid(loc) return stub.ahItems[loc.itemID] ~= nil end
function AH.GetItemKeyFromItem(loc) return key(loc.itemID) end
function AH.GetItemCommodityStatus(loc) return stub.ahItems[loc.itemID][4] and 2 or 1 end
function AH.GetAvailablePostCount(loc) return stub.bagCount[loc.itemID] or 1 end
function AH.CalculateCommodityDeposit(id, duration, n) return 15 * duration * n end
function AH.CalculateItemDeposit(loc, duration, n) return 500 * duration * n end
function AH.PostCommodity(loc, duration, n, unit)
	restricted("PostCommodity")
	stub.posted = { "commodity", loc.itemID, duration, n, unit }
	return stub.postNeedsConfirm
end
function AH.PostItem(loc, duration, n, bid, buyout)
	restricted("PostItem")
	stub.posted = { "item", loc.itemID, duration, n, buyout }
	return stub.postNeedsConfirm
end
function AH.ConfirmPostCommodity(loc, duration, n, unit)
	restricted("ConfirmPostCommodity")
	stub.confirmedPost = { "commodity", loc.itemID, duration, n, unit }
end
function AH.ConfirmPostItem(loc, duration, n, bid, buyout)
	restricted("ConfirmPostItem")
	stub.confirmedPost = { "item", loc.itemID, duration, n, buyout }
end

-- The player's auctions.
function AH.QueryOwnedAuctions() stub.fire("OWNED_AUCTIONS_UPDATED") end
function AH.GetNumOwnedAuctions() return #stub.owned end
function AH.GetOwnedAuctionInfo(i)
	local o = stub.owned[i]
	if o then return { auctionID = o[1], itemKey = key(o[2]), quantity = o[3], buyoutAmount = o[4], status = o[5], timeLeft = o[6] } end
end
function AH.CanCancelAuction(id) return stub.cancelCost[id] ~= nil end
function AH.GetCancelCost(id) return stub.cancelCost[id] or 0 end
function AH.CancelAuction(id)
	restricted("CancelAuction")
	stub.cancelled[#stub.cancelled + 1] = id
end

-- The player's bids: { auctionID, itemID, bid, buyout, minBid, timeLeft band, bidder }.
local ME = "Player-1-0001"
local unitGUID = UnitGUID
function UnitGUID(unit) if unit == "player" then return ME end return unitGUID and unitGUID(unit) end
stub.ahBids = { { 801, 6975, 1550000, 1800000, 1600000, 3, ME }, { 802, 2244, 20000000, 25000000, 21000000, 0, "Player-1-0002" } }
stub.bidsQueried = nil
function AH.QueryBids(sorts, ids)
	stub.bidsQueried = { sorts = sorts, ids = ids }
	stub.fire("BIDS_UPDATED")
end
function AH.GetNumBids() return #stub.ahBids end
function AH.GetBidInfo(i)
	local b = stub.ahBids[i]
	if b then return { auctionID = b[1], itemKey = key(b[2]), bidAmount = b[3], buyoutAmount = b[4], minBid = b[5], timeLeft = b[6], bidder = b[7] } end
end

local unitName = UnitName
function UnitName(unit, ...)
	if unit == "npc" then return "Auctioneer Beardo" end
	return unitName(unit, ...)
end
GameTooltip.SetItemKey = GameTooltip.SetItemKey or function(self, id) self:SetText(stub.ahItems[id][1]) end
