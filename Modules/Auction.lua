-- The Auction House (docs/windows/auction.md): the mainline C_AuctionHouse's
-- Buy, Sell and Auctions in a Polestar shell. The stock window ends the
-- auction house as it hides, and Forever opens it from two routes (the
-- interaction manager and GameEvent's AUCTION_HOUSE_SHOW): ours takes both
-- (ns.Interaction, Core.lua), so the stock addon is never loaded. The calls
-- the client restricts to a hardware event (buy, bid, post, cancel) run only
-- straight from our buttons' clicks, never from an event or a timer.

local ADDON, ns = ...
local W = Polestar.Widgets

local NAME = "PolestarUIAuction"
local ROW_H = 48
-- A quote this far over the listed price is refused, as the stock buy dialog
-- does (MAXIMUM_PREVIEW_PRICE_DIFFERENTIAL).
local QUOTE_SLACK = 1.05

-- Forever's categories, as the stock list builds them (Camelot's
-- Blizzard_AuctionData.lua, the stock addon we never load): each node a
-- name, its item class filters (a node's filters are its children's too, as
-- AuctionCategoryMixin:AddFilter adds them up), its children, and the column
-- the stock browse list adds for it (SetDetailColumnString). Built on first
-- show: the names come from the client.
local tree
local function buildTree()
	local E, I = Enum, C_Item
	local IC, WS, AS, IT = E.ItemClass, E.ItemWeaponSubclass, E.ItemArmorSubclass, E.InventoryType
	local top = {}
	local function node(parent, name)
		local c = { name = name or "", filters = {}, kids = {}, parent = parent }
		table.insert(parent and parent.kids or top, c)
		return c
	end
	local function add(c, classID, subClassID, inv)
		local flt = { classID = classID, subClassID = subClassID, inventoryType = inv }
		while c do
			table.insert(c.filters, flt)
			c = c.parent
		end
	end
	-- CreateSubCategoryAndFilter: named after the slot, the subclass or the class.
	local function auto(parent, classID, subClassID, inv)
		local name = inv and I.GetItemInventorySlotInfo(inv) or subClassID and I.GetItemSubClassInfo(classID, subClassID)
			or I.GetItemClassInfo(classID)
		local c = node(parent, name)
		add(c, classID, subClassID, inv)
		return c
	end
	local function each(parent, classID, list) for _, s in ipairs(list) do auto(parent, classID, s) end end
	local function generate(parent, classID) each(parent, classID, C_AuctionHouse.GetAuctionItemSubClasses(classID) or {}) end
	local LEVEL = AUCTION_HOUSE_BROWSE_HEADER_REQUIRED_LEVEL or "Req. Level"

	local wpn = node(nil, AUCTION_CATEGORY_WEAPONS or "Weapons")
	wpn.detail = LEVEL
	each(node(wpn, AUCTION_SUBCATEGORY_ONE_HANDED or "One-Handed"), IC.Weapon,
		{ WS.Axe1H, WS.Mace1H, WS.Sword1H, WS.Dagger, WS.Unarmed, WS.Wand })
	each(node(wpn, AUCTION_SUBCATEGORY_TWO_HANDED or "Two-Handed"), IC.Weapon, { WS.Axe2H, WS.Mace2H, WS.Sword2H, WS.Polearm, WS.Staff })
	each(node(wpn, AUCTION_SUBCATEGORY_RANGED or "Ranged"), IC.Weapon, { WS.Bows, WS.Crossbow, WS.Guns, WS.Thrown })
	local misc = node(wpn, AUCTION_SUBCATEGORY_MISCELLANEOUS or "Miscellaneous")
	auto(misc, IC.Weapon, WS.Fishingpole)
	add(node(misc, AUCTION_SUBCATEGORY_OTHER or "Other"), IC.Weapon, WS.Generic)

	local arm = node(nil, AUCTION_CATEGORY_ARMOR or "Armor")
	arm.detail = LEVEL
	local SLOTS = { IT.IndexHeadType, IT.IndexShoulderType, IT.IndexChestType, IT.IndexWaistType, IT.IndexLegsType,
		IT.IndexFeetType, IT.IndexWristType, IT.IndexHandType, IT.IndexRelicType }
	for _, kind in ipairs({ AS.Plate, AS.Mail, AS.Leather, AS.Cloth }) do
		local k = auto(arm, IC.Armor, kind)
		for _, slot in ipairs(SLOTS) do
			local c = auto(k, IC.Armor, kind, slot)
			if slot == IT.IndexChestType then add(c, IC.Armor, kind, IT.IndexRobeType) end
		end
	end
	each(node(arm, AUCTION_SUBCATEGORY_RELIC or "Relic"), IC.Armor, { AS.Idol, AS.Libram, AS.Totem })
	misc = node(arm, I.GetItemSubClassInfo(IC.Armor, AS.Generic))
	auto(misc, IC.Armor, AS.Generic, IT.IndexNeckType)
	add(node(misc, AUCTION_SUBCATEGORY_CLOAK or "Cloak"), IC.Armor, AS.Cloth, IT.IndexCloakType)
	auto(misc, IC.Armor, AS.Generic, IT.IndexFingerType)
	auto(misc, IC.Armor, AS.Generic, IT.IndexTrinketType)
	auto(misc, IC.Armor, AS.Generic, IT.IndexHoldableType)
	auto(misc, IC.Armor, AS.Shield)
	auto(misc, IC.Armor, AS.Generic, IT.IndexBodyType)

	local cont = node(nil, AUCTION_CATEGORY_CONTAINERS or "Containers")
	cont.detail = AUCTION_HOUSE_BROWSE_HEADER_CONTAINER_SLOTS or "Slots"
	local CS, QS = E.ItemContainerSubclass, E.ItemQuiverSubclass
	each(node(cont, AUCTION_SUBCATEGORY_STANDARD_CONTAINER or "Standard"), IC.Container, { CS.Bag, CS.Soul })
	each(node(cont, AUCTION_SUBCATEGORY_AMMO_CONTAINER or "Ammo"), IC.Quiver, { QS.Quiver, QS.Ammopouch })
	each(node(cont, AUCTION_SUBCATEGORY_REAGENT_CONTAINER or "Reagent"), IC.Container,
		{ CS.Herb, CS.Enchanting, CS.Engineering, CS.Mining, CS.Leatherworking, CS.Tacklebox, CS.Cooking, CS.Reagent })

	local cons = node(nil, AUCTION_CATEGORY_CONSUMABLES or "Consumables")
	cons.detail = LEVEL
	local US = E.ItemConsumableSubclass
	for _, s in ipairs(C_AuctionHouse.GetAuctionItemSubClasses(IC.Consumable) or {}) do
		if s ~= US.Itemenhancement and s ~= US.ItemenhancementTemporary then auto(cons, IC.Consumable, s) end
		-- After bandages, the item enhancements under one heading.
		if s == US.Bandage then
			each(node(cons, AUCTION_SUBCATEGORY_ITEM_ENHANCEMENT or "Item Enhancement"), IC.Consumable,
				{ US.Itemenhancement, US.ItemenhancementTemporary })
		end
	end

	generate(node(nil, AUCTION_CATEGORY_TRADE_GOODS or "Trade Goods"), IC.Tradegoods)
	generate(node(nil, AUCTION_CATEGORY_PROJECTILE or "Projectiles"), IC.Projectile)
	local rec = node(nil, AUCTION_CATEGORY_RECIPES or "Recipes")
	rec.detail = AUCTION_HOUSE_BROWSE_HEADER_RECIPE_SKILL or "Skill"
	generate(rec, IC.Recipe)
	-- Books go last (SetSortIndex(100)).
	local book = I.GetItemSubClassInfo(IC.Recipe, E.ItemRecipeSubclass.Book)
	for i, c in ipairs(rec.kids) do
		if c.name == book then table.insert(rec.kids, table.remove(rec.kids, i)) break end
	end
	add(node(nil, AUCTION_CATEGORY_QUEST_ITEMS or "Quest Items"), IC.Questitem)
	local m = node(nil, AUCTION_CATEGORY_MISCELLANEOUS or "Miscellaneous")
	add(m, IC.Miscellaneous)
	generate(m, IC.Miscellaneous)
	return top
end
local BANDS = { [0] = "Under 30 min", "30 min to 2 h", "2 to 12 h", "Over 12 h" }
local DURATIONS = { "12 hours", "24 hours", "48 hours" }
-- The client's error texts (AuctionHouseErrorToErrorText lives in the stock addon, never loaded).
local ERRORS = {
	NotEnoughMoney = "ERR_NOT_ENOUGH_MONEY", HigherBid = "ERR_AUCTION_HIGHER_BID", BidIncrement = "ERR_AUCTION_BID_INCREMENT",
	BidOwn = "ERR_AUCTION_BID_OWN", ItemNotFound = "ERR_ITEM_NOT_FOUND", RestrictedAccountTrial = "ERR_RESTRICTED_ACCOUNT_TRIAL",
	HasRestriction = "ERR_HAS_RESTRICTION", IsBusy = "ERR_AUCTION_HOUSE_BUSY", Unavailable = "ERR_AUCTION_HOUSE_UNAVAILABLE",
	ItemHasQuote = "ERR_AUCTION_ITEM_HAS_QUOTE", DatabaseError = "ERR_AUCTION_DATABASE_ERROR", MinBid = "ERR_AUCTION_MIN_BID",
	NotEnoughItems = "ERR_AUCTION_ENOUGH_ITEMS", RepairItem = "ERR_AUCTION_REPAIR_ITEM", UsedCharges = "ERR_AUCTION_USED_CHARGES",
	QuestItem = "ERR_AUCTION_QUEST_ITEM", BoundItem = "ERR_AUCTION_BOUND_ITEM", ConjuredItem = "ERR_AUCTION_CONJURED_ITEM",
	LimitedDurationItem = "ERR_AUCTION_LIMITED_DURATION_ITEM", IsBag = "ERR_AUCTION_BAG", EquippedBag = "ERR_AUCTION_EQUIPPED_BAG",
	WrappedItem = "ERR_AUCTION_WRAPPED_ITEM", LootItem = "ERR_AUCTION_LOOT_ITEM", DoubleBid = "ERR_AUCTION_DOUBLE_BID",
	ItemBoundToAccountUntilEquip = "ERR_NOT_SAME_ACCOUNT",
}

local AH -- C_AuctionHouse, set in Enable
local f, money
local tab = "buy"
local sel, searched = {}, nil -- the browse: the category path ({ top, sub, subsub } indexes); whether a search ran
local view -- an item's listings: { key, info, n (commodity count) }
local quote -- a commodity purchase waiting on its quote: { id, n, unit, total, name }
local sell = { n = 1, price = 0, duration = 2 } -- loc, key, commodity, touched
local pendingPost, bidAmount
local rows = {}
local M = {}
local paint

local coins = ns.Coins

local function sorts()
	local S = Enum.AuctionHouseSortOrder
	return { { sortOrder = S.Price, reverseSort = false }, { sortOrder = S.Name, reverseSort = false } }
end

-- Polestar's dialogs of ours, so ours closes them as it hides.
local asked
local function ask(spec, body)
	asked = spec
	if body then ns.ModalWith(spec, body) else W.Modal(spec) end
end

local function system(text)
	if text and ChatFrameUtil and ChatFrameUtil.AddSystemMessage then ChatFrameUtil.AddSystemMessage(text) end
end

local function caption(parent, text, x, y)
	local t = W.Text(parent, "small", "textDim")
	t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
	t:SetText(text)
	return t
end

---------------------------------------------------------------------------
-- Buy: the browse, then an item's listings.

-- The category picked, deepest first (nil: all).
local function picked()
	local c, list = nil, tree
	for _, i in ipairs(sel) do
		c = list[i]
		list = c.kids
	end
	return c
end

local function browse()
	tab, view, searched = "buy", nil, true
	local c = picked()
	paint()
	AH.SendBrowseQuery({ searchString = f.Search:GetText() or "", sorts = sorts(), itemClassFilters = c and c.filters or {} })
end

local function research()
	if view then AH.SendSearchQuery(view.key, sorts(), true) end
end

local function open(key)
	local info = AH.GetItemKeyInfo(key)
	if not info then return end
	view = { key = key, info = info, n = 1 }
	paint()
	research()
end

-- n of a commodity at its listed prices, cheapest first, leaving out the
-- player's own (AggregateSearchResultsByQuantity): how many, and their total.
local function aggregate(id, n)
	local got, total = 0, 0
	for i = 1, AH.GetNumCommoditySearchResults(id) do
		local r = AH.GetCommoditySearchResultInfo(id, i)
		if r then
			local take = math.min(r.quantity - (r.numOwnerItems or 0), n - got)
			got, total = got + take, total + take * r.unitPrice
			if got >= n then break end
		end
	end
	return got, total
end

local function lost(text)
	if quote then AH.CancelCommoditiesPurchase() end
	quote = nil
	ask({ title = "Not bought", text = text, action = "OK" })
end

-- Buy's click: the restricted StartCommoditiesPurchase, straight from it.
local function buyCommodity()
	local id = view.info.itemID
	local got, total = aggregate(id, view.n)
	if got == 0 then return end
	local unit = math.ceil(total / got)
	quote = { id = id, n = got, unit = unit, total = total, name = view.info.itemName }
	AH.StartCommoditiesPurchase(id, got, unit)
end

-- The client's quote (COMMODITY_PRICE_UPDATED): asked, as the stock buy
-- dialog shows it; its confirm is the dialog button's click.
local function quoted(unit, total)
	local q = quote
	if not q then return end
	if unit > q.unit * QUOTE_SLACK then return lost("The price went up too far since the search. Search again.") end
	local up = unit > q.unit and (" The price went up by %s."):format(coins(total - q.total)) or ""
	ask({ title = ("Buy %d %s?"):format(q.n, q.name or ""), action = "Buy",
		text = ("It costs %s (%s each).%s"):format(coins(total), coins(unit), up),
		onAccept = function()
			quote = nil
			AH.ConfirmCommoditiesPurchase(q.id, q.n)
		end,
		onCancel = function()
			quote = nil
			AH.CancelCommoditiesPurchase()
		end })
end

-- An item's auction: a click buys it out, a right-click (or no buyout) bids;
-- PlaceBid runs from the dialog button's click.
local moneyIn
local function bid(r)
	moneyIn = moneyIn or ns.MoneyInput(UIParent, function(c) bidAmount = c end)
	bidAmount = r.minBid
	moneyIn.Set(bidAmount)
	ask({ title = ("Bid on %s"):format(view.info.itemName or ""), text = ("At least %s."):format(coins(r.minBid)), action = "Bid",
		onAccept = function() if bidAmount >= r.minBid then AH.PlaceBid(r.auctionID, bidAmount) end end }, moneyIn)
end

local function auctionClick(row, button)
	local r = row.psData
	if r.containsOwnerItem then return end
	if r.buyoutAmount and button ~= "RightButton" then
		ask({ title = ("Buy out %s?"):format(view.info.itemName or ""), text = ("It costs %s."):format(coins(r.buyoutAmount)), action = "Buy",
			onAccept = function() AH.PlaceBid(r.auctionID, r.buyoutAmount) end })
	elseif r.minBid then
		bid(r)
	end
end

---------------------------------------------------------------------------
-- Rows: the well, the name in its quality colour, a line under it; a price
-- and a note on the right.

local function enter(r)
	local k = r.psKey
	if not k then return end
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:SetItemKey(k.itemID, k.itemLevel, k.itemSuffix)
	if r.psHint then ns.TooltipHint(r.psHint) end
	GameTooltip:Show()
end

local function row(k)
	local r = rows[k]
	if r then return r end
	r = CreateFrame("Button", nil, f.Body)
	r:SetSize(f.BodyWidth, ROW_H)
	W.Hover(r)
	r.Well = ns.ItemWell(r, 36)
	r.Well:SetPoint("LEFT", r, "LEFT", 6, 0)
	r.Name = W.Text(r, "label", "text")
	r.Name:SetPoint("BOTTOMLEFT", r.Well, "RIGHT", 10, 2)
	r.Name:SetPoint("RIGHT", r, "RIGHT", -200, 0)
	r.Name:SetJustifyH("LEFT")
	r.Line = W.Text(r, "small", "textDim")
	r.Line:SetPoint("TOPLEFT", r.Well, "RIGHT", 10, -3)
	r.Money = ns.Money(r)
	r.Money:SetPoint("BOTTOMRIGHT", r, "RIGHT", -10, 2)
	r.Note = W.Text(r, "small", "textDim")
	r.Note:SetPoint("TOPRIGHT", r, "RIGHT", -10, -3)
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	r:SetScript("OnClick", function(self, button) if self.psClick then self.psClick(self, button) end end)
	r:SetScript("OnEnter", enter)
	r:SetScript("OnLeave", W.HideTooltip)
	rows[k] = r
	return r
end

-- o = { key, line, price, cost (red when short of money), note, click, hint, data }
local function fill(k, top, o)
	local r = row(k)
	r:ClearAllPoints()
	r:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -(top + (k - 1) * ROW_H))
	local info = AH.GetItemKeyInfo(o.key) or {}
	ns.PaintItem(r.Well, { icon = info.iconFileID, quality = info.quality })
	r.Name:SetText(info.itemName or "")
	local cr, cg, cb = ns.QualityRGB(info.quality)
	W.Uncolor(r.Name)
	if cr and info.quality ~= 1 then r.Name:SetTextColor(Polestar.Theme.Legible(cr, cg, cb)) else W.Color(r.Name, "text") end
	r.Line:SetText(o.line or "")
	r.Money:SetShown(o.price ~= nil)
	if o.price then ns.SetMoney(r.Money, o.price, o.cost and o.price > GetMoney() and "danger" or nil) end
	r.Note:SetText(o.note or "")
	r.psKey, r.psClick, r.psHint, r.psData = o.key, o.click, o.hint, o.data
	r:Show()
end

-- Each page fills its rows and returns how many, where they start, and the
-- text shown when there are none.
local function paintBrowse()
	W.ShellTitle(f, picked() and picked().name or "Browse",
		searched and "Click an item to see its listings." or "Search for an item (Enter), or pick a category.")
	W.ShellFooter(f, {}, {})
	local list = searched and AH.GetBrowseResults() or {}
	for i, b in ipairs(list) do
		fill(i, 24, { key = b.itemKey, price = b.minPrice, cost = true, note = ("%d available"):format(b.totalQuantity),
			click = function() open(b.itemKey) end, hint = "Click to see its listings." })
	end
	return #list, 24, searched and "Nothing found." or ""
end

local function back()
	view = nil
	paint()
end

local function paintCommodity()
	local id = view.info.itemID
	local most = aggregate(id, math.huge)
	view.n = math.max(1, math.min(view.n, most))
	local got, total = aggregate(id, view.n)
	W.ShellTitle(f, view.info.itemName, "Pick how many; Buy asks the auction house for its price first.")
	W.ShellFooter(f, { { label = "Back", onClick = back } },
		{ got > 0 and { label = ("Buy %d (%s)"):format(got, coins(total)), onClick = buyCommodity, opts = { primary = true } } or nil })
	local strip = f.psBuy
	strip.Stepper.Paint()
	ns.SetMoney(strip.Total, total, total > GetMoney() and "danger" or nil)
	local n = AH.GetNumCommoditySearchResults(id)
	for i = 1, n do
		local r = AH.GetCommoditySearchResultInfo(id, i)
		fill(i, 72, { key = view.key, price = r.unitPrice, line = "each",
			note = ("%d%s"):format(r.quantity, (r.numOwnerItems or 0) > 0 and (" (%d yours)"):format(r.numOwnerItems) or "") })
	end
	return n, 72, "None listed."
end

local function paintItem()
	W.ShellTitle(f, view.info.itemName, "Click an auction to buy it out; right-click to bid.")
	W.ShellFooter(f, { { label = "Back", onClick = back } }, {})
	local n = AH.GetNumItemSearchResults(view.key)
	for i = 1, n do
		local r = AH.GetItemSearchResultInfo(view.key, i)
		local line = r.buyoutAmount and r.minBid and ("Bid %s"):format(coins(r.minBid)) or (r.buyoutAmount and "Buyout" or "Bid only")
		fill(i, 24, { key = view.key, price = r.buyoutAmount or r.bidAmount or r.minBid, cost = not r.containsOwnerItem, line = line,
			note = r.containsOwnerItem and "Yours" or BANDS[r.timeLeft],
			click = auctionClick, data = r, hint = not r.containsOwnerItem and "Click to buy out, right-click to bid." or nil })
	end
	return n, 24, "None listed."
end

---------------------------------------------------------------------------
-- Sell: the item from the cursor, how many, the price, the duration.

local function defaultPrice(id)
	if not AH.ShouldAutoPopulatePrice() then return 0 end
	local vendor = select(11, C_Item.GetItemInfo(id)) or 0
	local k = Constants and Constants.AuctionConstants and Constants.AuctionConstants.DEFAULT_AUCTION_PRICE_MULTIPLIER or 1.5
	-- Silver steps, as the stock default (GetDefaultPrice).
	return math.max(100, math.ceil(vendor * k / 100) * 100)
end

local function setItem(loc)
	if loc and not (loc:IsValid() and AH.IsSellItemValid(loc, true)) then return end
	sell.loc, sell.n, sell.touched, pendingPost = loc, 1, false, nil
	if loc then
		sell.key = AH.GetItemKeyFromItem(loc)
		sell.commodity = AH.GetItemCommodityStatus(loc) == Enum.ItemCommodityStatus.Commodity
		sell.price = defaultPrice(C_Item.GetItemID(loc))
		f.psSell.Price.Set(sell.price)
		AH.SendSellSearchQuery(sell.key, sorts(), true)
	end
	paint()
	return true
end

local function take()
	local loc = C_Cursor.GetCursorItem()
	if loc and setItem(loc) then ClearCursor() end
end

-- The lowest listing becomes the price, until the player types one (as the
-- stock sell frames' UpdatePriceSelection).
local function listed(id)
	if tab ~= "sell" or not sell.loc or sell.touched or sell.key.itemID ~= id or not AH.ShouldAutoPopulatePrice() then return end
	local r
	if sell.commodity then r = AH.GetCommoditySearchResultInfo(id, 1) else r = AH.GetItemSearchResultInfo(sell.key, 1) end
	local low = r and (r.unitPrice or r.buyoutAmount)
	if low then
		sell.price = low
		f.psSell.Price.Set(low)
	end
end

-- Post's click: the restricted PostCommodity/PostItem, straight from it. A
-- post the client wants confirmed waits for AUCTION_HOUSE_POST_WARNING.
local function post()
	local s = sell
	if not s.loc or s.price <= 0 then return end
	local args = s.commodity and { s.loc, s.duration, s.n, s.price } or { s.loc, s.duration, s.n, nil, s.price }
	args.commodity = s.commodity
	local fn = s.commodity and AH.PostCommodity or AH.PostItem
	if fn(unpack(args, 1, 5)) then pendingPost = args else setItem(nil) end
end

local function confirmPost()
	local p = pendingPost
	if not p then return end
	ask({ title = "Post this auction?", text = CONFIRM_AUCTION_POSTING_TEXT or "The auction house asks you to confirm this post.", action = "Post",
		onAccept = function()
			pendingPost = nil
			local fn = p.commodity and AH.ConfirmPostCommodity or AH.ConfirmPostItem
			fn(unpack(p, 1, 5))
			setItem(nil)
		end,
		onCancel = function() pendingPost = nil end })
end

local function durationMenu(self)
	local items = {}
	for i, label in ipairs(DURATIONS) do
		items[i] = { text = label, checked = sell.duration == i, onClick = function() sell.duration = i; paint() end }
	end
	W.ShowMenu(self, items, { point = "TOPLEFT", relPoint = "BOTTOMLEFT", minWidth = 140 })
end

local function buildSell()
	local s = CreateFrame("Frame", nil, f.Body)
	s:SetPoint("TOPLEFT", f.Body, "TOPLEFT", 0, 0)
	s:SetSize(f.BodyWidth + 2 * W.SHELL.pad, 1)
	local x = W.SHELL.pad
	s.Well = ns.ItemWell(s, 56, "Button")
	s.Well:SetPoint("TOPLEFT", s, "TOPLEFT", x, -24)
	W.Hover(s.Well)
	s.Well:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	s.Well:SetScript("OnClick", function(_, button) if button == "RightButton" then setItem(nil) else take() end end)
	s.Well:SetScript("OnReceiveDrag", take)
	s.Name = W.Text(s, "label", "text")
	s.Name:SetPoint("BOTTOMLEFT", s.Well, "RIGHT", 12, 2)
	s.Line = W.Text(s, "small", "textDim")
	s.Line:SetPoint("TOPLEFT", s.Well, "RIGHT", 12, -4)
	local y = 24 + 56 + 24
	caption(s, "Quantity", x, y)
	s.Stepper = ns.Stepper(s, { get = function() return sell.n end, set = function(n) sell.n = n; paint() end,
		max = function() return sell.loc and AH.GetAvailablePostCount(sell.loc) or 1 end })
	s.Stepper:SetPoint("TOPLEFT", s, "TOPLEFT", x, -(y + 18))
	y = y + 18 + 28 + 20
	s.PriceCaption = caption(s, "", x, y)
	s.Price = ns.MoneyInput(s, function(c)
		sell.price, sell.touched = c, true
		paint()
	end)
	s.Price:SetPoint("TOPLEFT", s, "TOPLEFT", x, -(y + 18))
	y = y + 18 + 28 + 20
	caption(s, "Duration", x, y)
	s.Duration = W.Button(s, DURATIONS[2], durationMenu, { width = 120 })
	s.Duration:SetPoint("TOPLEFT", s, "TOPLEFT", x, -(y + 18))
	y = y + 18 + 28 + 20
	caption(s, "Deposit", x, y)
	s.Deposit = ns.Money(s)
	s.Deposit:SetPoint("TOPLEFT", s, "TOPLEFT", x, -(y + 18 + 7))
	caption(s, "Total", x + 200, y)
	s.Total = ns.Money(s)
	s.Total:SetPoint("TOPLEFT", s, "TOPLEFT", x + 200, -(y + 18 + 7))
	s.psHeight = y + 18 + 28 + 24
	return s
end

local function paintSell()
	local s, loc = f.psSell, sell.loc
	local info = loc and AH.GetItemKeyInfo(sell.key) or {}
	ns.PaintItem(s.Well, loc and { icon = info.iconFileID, quality = info.quality })
	s.Name:SetText(loc and info.itemName or "No item")
	s.Line:SetText(not loc and "Drop an item from your bags here." or sell.commodity and "Sold by the unit; buyers take any amount."
		or "Each one is posted as its own auction.")
	s.PriceCaption:SetText(sell.commodity and "Unit price" or "Buyout (each)")
	s.Stepper.Paint()
	W.SetButtonText(s.Duration, DURATIONS[sell.duration])
	local deposit = 0
	if loc then
		deposit = sell.commodity and AH.CalculateCommodityDeposit(sell.key.itemID, sell.duration, sell.n)
			or AH.CalculateItemDeposit(loc, sell.duration, sell.n) or 0
	end
	ns.SetMoney(s.Deposit, deposit, deposit > GetMoney() and "danger" or nil)
	ns.SetMoney(s.Total, loc and sell.price * sell.n or 0)
	W.ShellTitle(f, "Sell", "Drop an item on the well, set its price, and post it.")
	W.ShellFooter(f, { loc and { label = "Clear", onClick = function() setItem(nil) end } or nil },
		{ loc and sell.price > 0 and { label = "Post", onClick = post, opts = { primary = true } } or nil })
	return 0, s.psHeight, nil
end

---------------------------------------------------------------------------
-- Auctions: the player's own; a click on an active one cancels it.

local function cancel(row)
	local o = row.psData
	if o.status ~= Enum.AuctionStatus.Active or not AH.CanCancelAuction(o.auctionID) then return end
	local cost = AH.GetCancelCost(o.auctionID) or 0
	ask({ title = "Cancel this auction?", action = "Cancel auction", danger = true,
		text = cost > 0 and ("Cancelling costs %s, and the deposit is not returned."):format(coins(cost)) or "The deposit is not returned.",
		onAccept = function() AH.CancelAuction(o.auctionID) end })
end

local function paintOwned()
	W.ShellTitle(f, "Your auctions", "Click an auction to cancel it. Sold items' money comes by mail.")
	W.ShellFooter(f, {}, {})
	local n = AH.GetNumOwnedAuctions()
	for i = 1, n do
		local o = AH.GetOwnedAuctionInfo(i)
		local sold = o.status == Enum.AuctionStatus.Sold
		fill(i, 24, { key = o.itemKey, price = o.buyoutAmount or o.bidAmount, line = ("\195\151%d"):format(o.quantity),
			note = sold and "Sold" or BANDS[o.timeLeft], click = cancel, data = o, hint = not sold and "Click to cancel it." or nil })
	end
	return n, 24, "You have no auctions."
end

---------------------------------------------------------------------------
-- The window.

local TABS = { { key = "buy", label = "Buy" }, { key = "sell", label = "Sell" }, { key = "auctions", label = "Auctions" } }

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 960, height = 680, searchPlaceholder = "Search the auction house" })
	ns.Dock(f)
	ns.WindowMenu(f, "auction")
	local b = ns.SubjectBlock(f)
	b.icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_02")
	b.name:SetText("Auction House")
	money = ns.Money(f.Sidebar)
	money:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, -6)
	f.psMoney = money
	-- Enter searches: each query counts against the client's throttle, so not per keystroke.
	f.Search:HookScript("OnEnterPressed", browse)
	f.psEmpty = W.Text(f.Body, "default", "textDim")
	local strip = CreateFrame("Frame", nil, f.Body)
	strip:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
	strip:SetSize(f.BodyWidth, 28)
	strip.Stepper = ns.Stepper(strip, { get = function() return view.n end, set = function(n) view.n = n; paint() end,
		max = function() return math.max(1, aggregate(view.info.itemID, math.huge)) end })
	strip.Stepper:SetPoint("LEFT", strip, "LEFT", 0, 0)
	local t = W.Text(strip, "small", "textDim")
	t:SetPoint("LEFT", strip.Stepper, "RIGHT", 24, 0)
	t:SetText("Total")
	strip.Total = ns.Money(strip)
	strip.Total:SetPoint("LEFT", t, "RIGHT", 10, 0)
	f.psBuy = strip
	f.psSell = buildSell()
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.AUCTION_WINDOW_OPEN) end)
	-- As the stock hide: a pending quote or post dropped, the browse reset, our dialogs gone.
	f:HookScript("OnHide", function()
		if asked and PolestarModal and PolestarModal:IsShown() and PolestarModal.psSpec == asked then PolestarModal:Hide() end
		if quote then AH.CancelCommoditiesPurchase() end
		quote, pendingPost, view, searched, sel, sell.loc = nil, nil, nil, false, {}, nil
		f.Search:SetText("")
		PlaySound(SOUNDKIT.AUCTION_WINDOW_CLOSE)
	end)
	Polestar.CloseOnEscape(NAME)
end

-- The sidebar: All, the top categories, and under the one picked its
-- subcategories (and under the subcategory picked, its own), indented, as the
-- stock list opens them. A click on the one picked closes it again.
local function paintNav()
	local nav, depth = { { key = "", label = "All" } }, {}
	local function walk(list, path, d)
		for i, c in ipairs(list) do
			local key = path .. i .. "."
			nav[#nav + 1] = { key = key, label = c.name }
			depth[#nav] = d
			if sel[d + 1] == i then walk(c.kids, key, d + 1) end
		end
	end
	walk(tree, "", 0)
	local active = tab == "buy" and not view and searched and (table.concat(sel, ".") .. (#sel > 0 and "." or "")) or false
	W.ShellNav(f, nav, active, function(k)
		local path = {}
		for n in k:gmatch("%d+") do path[#path + 1] = tonumber(n) end
		-- One on the picked path again closes it, as the stock list's toggle.
		local on = #path > 0
		for d, i in ipairs(path) do on = on and sel[d] == i end
		if on then table.remove(path) end
		sel = path
		browse()
	end)
	for i, b in ipairs(f.navButtons) do
		local d = depth[i] or 0
		b.Icon:ClearAllPoints()
		b.Icon:SetPoint("LEFT", b, "LEFT", W.SHELL.side + 16 * d, 0)
		if d > 0 then b.Icon:Hide() end
	end
end

function paint()
	W.ShellTabs(f, TABS, tab, function(k)
		tab = k
		if k == "auctions" then AH.QueryOwnedAuctions(sorts()) end
		paint()
	end)
	paintNav()
	ns.SetMoney(money, GetMoney())
	local commodity = tab == "buy" and view and view.info.isCommodity
	f.psSell:SetShown(tab == "sell")
	f.psBuy:SetShown(commodity and true or false)
	local n, top, empty
	if tab == "sell" then n, top, empty = paintSell()
	elseif tab == "auctions" then n, top, empty = paintOwned()
	elseif not view then n, top, empty = paintBrowse()
	elseif commodity then n, top, empty = paintCommodity()
	else n, top, empty = paintItem() end
	for k = n + 1, #rows do rows[k]:Hide() end
	f.psEmpty:ClearAllPoints()
	f.psEmpty:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -top)
	f.psEmpty:SetText(empty or "")
	f.psEmpty:SetShown(n == 0 and empty ~= nil)
	W.ShellBody(f, tab == "sell" and top or top + math.max(1, n) * ROW_H + 24)
end

function M.Show()
	tree = tree or buildTree()
	if not f then build() end
	tab = "buy"
	paint()
	f:Show()
end

local function onError(_, err)
	for name, v in pairs(Enum.AuctionHouseError or {}) do
		if v == err and _G[ERRORS[name] or ""] then UIErrorsFrame:AddExternalErrorMessage(_G[ERRORS[name]]) end
	end
end

function M.Enable()
	-- The NPC is the only door: ours takes its interaction and Forever's
	-- AUCTION_HOUSE_SHOW route (and opens on either), and the stock window is never opened
	-- (docs/DESIGN.md, "NPC windows: how they open").
	AH = C_AuctionHouse
	ns.Interaction("auction", { Enum.PlayerInteractionType.Auctioneer }, { frame = NAME, bags = true,
		close = function() C_AuctionHouse.CloseAuctionHouse() end, internal = { "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED" }, events = { "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED" } })
	local function shown() return f and f:IsShown() end
	local function changed() if shown() then paint() end end
	for _, e in ipairs({ "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", "AUCTION_HOUSE_BROWSE_RESULTS_ADDED", "ITEM_KEY_ITEM_INFO_RECEIVED",
		"OWNED_AUCTIONS_UPDATED", "PLAYER_MONEY" }) do
		Polestar.RegisterEvent(e, changed)
	end
	Polestar.RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED", function(_, id) listed(id); changed() end)
	Polestar.RegisterEvent("ITEM_SEARCH_RESULTS_UPDATED", function(_, key) listed(key and key.itemID); changed() end)
	Polestar.RegisterEvent("COMMODITY_PRICE_UPDATED", function(_, unit, total) quoted(unit, total) end)
	Polestar.RegisterEvent("COMMODITY_PRICE_UNAVAILABLE", function() if quote then lost("None left at that price. Search again.") end end)
	Polestar.RegisterEvent("COMMODITY_PURCHASE_FAILED", function() lost("The purchase failed. Search again.") end)
	Polestar.RegisterEvent("COMMODITY_PURCHASE_SUCCEEDED", function()
		PlaySound(SOUNDKIT.LOOT_WINDOW_COIN_SOUND)
		research()
	end)
	Polestar.RegisterEvent("AUCTION_HOUSE_PURCHASE_COMPLETED", research)
	Polestar.RegisterEvent("AUCTION_CANCELED", function() if shown() then AH.QueryOwnedAuctions(sorts()) end end)
	Polestar.RegisterEvent("AUCTION_HOUSE_POST_WARNING", confirmPost)
	-- What the stock frame said while open.
	Polestar.RegisterEvent("AUCTION_HOUSE_AUCTION_CREATED", function() system(ERR_AUCTION_STARTED) end)
	Polestar.RegisterEvent("AUCTION_HOUSE_SHOW_COMMODITY_WON_NOTIFICATION", function(_, name, n)
		if ERR_AUCTION_COMMODITY_WON_S then system(ERR_AUCTION_COMMODITY_WON_S:format(name, n)) end
	end)
	Polestar.RegisterEvent("AUCTION_HOUSE_SHOW_ERROR", onError)
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return AuctionHouseFrame and AuctionHouseFrame:IsShown() and AuctionHouseFrame end

ns.Module("auction", M)
