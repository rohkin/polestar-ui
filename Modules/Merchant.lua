-- The Merchant (docs/windows/merchant.md): the vendor's Buy and Buyback in a
-- Polestar shell. The stock MerchantFrame ends the visit as it hides, so it is
-- never opened: ours takes the interaction (ns.Interaction, Core.lua).
-- Polestar's Vendor and Keep run on MERCHANT_SHOW with no frame; its Restock
-- button hangs under MerchantFrame, so ours carries Restock in the footer.

local ADDON, ns = ...
local W = Polestar.Widgets

local NAME = "PolestarUIMerchant"
local ROW_H, GAP = 52, 16
local HIGH = MERCHANT_HIGH_PRICE_COST or 1500000
local MAX_COSTS = MAX_ITEM_COST or 3

local f, money, subject
local tab = "buy"
local query = "" -- the sidebar search, lowercased
local rows = {}
local M = {}
local paint

local coins = ns.Coins

-- Polestar's dialogs of ours, so ours closes them when the visit ends.
local asked
local function ask(spec, body)
	asked = spec
	if body then ns.ModalWith(spec, body) else W.Modal(spec) end
end

local function purchase(i, n)
	if n then BuyMerchantItem(i, n) else BuyMerchantItem(i) end
end

-- The specs an item is for, as the stock token dialog lists them.
local function specText(link)
	local specs = link and C_Item.GetItemSpecInfo and C_Item.GetItemSpecInfo(link)
	local names = {}
	for _, id in ipairs(specs or {}) do names[#names + 1] = select(2, GetSpecializationInfoByID(id)) end
	return #names > 0 and (" For %s."):format(table.concat(names, ", ")) or ""
end

-- Buys n of item i (nil: one purchase), first asking as the stock window does
-- (MerchantItemButton_OnClick, MerchantFrame_ConfirmExtendedItemCost): a high
-- price; a cost in currencies or in items above uncommon; a purchase that
-- cannot be refunded; the last of a limited currency.
local function buy(i, n)
	local it = C_MerchantFrame.GetItemInfo(i)
	if not it then return end
	local per = math.max(1, it.stackCount or 1)
	local times = (n or per) / per
	local price = (it.price or 0) * times
	local title, go = ("Buy %s?"):format(it.name or ""), function() purchase(i, n) end
	local nonref = not C_MerchantFrame.IsMerchantItemRefundable(i)
	local count = GetMerchantItemCostInfo(i) or 0
	if count == 0 and not nonref then
		if price < HIGH then return go() end
		return ask({ title = title, action = "Buy", onAccept = go, text = ("It costs %s."):format(coins(price)) })
	end
	local parts, currency, best = {}, false, 0
	for k = 1, MAX_COSTS do
		local tex, value, costLink, currencyName = GetMerchantItemCostItem(i, k)
		if value then
			value = value * times
			if currencyName then
				currency = true
				parts[#parts + 1] = ("|T%s:0|t %d %s"):format(tex or "", value, currencyName)
			elseif costLink then
				-- A limited currency says what is left to earn (MerchantFrame_ConfirmLimitedCurrencyPurchase).
				local lname, licon, have, most, earned
				if k == 1 and count == 1 and C_Item.GetLimitedCurrencyItemInfo then lname, licon, have, most, earned = C_Item.GetLimitedCurrencyItemInfo(costLink) end
				if lname then
					local left = most - (earned - have) - value
					local cost = ("|T%s:0|t %d %s"):format(licon or "", value, lname)
					return ask({ title = title, action = "Buy", onAccept = go, text = left <= 0
						and ("It costs %s, the last %s you can earn this season."):format(cost, lname)
						or ("It costs %s. You can still earn %d %s this season."):format(cost, left, lname) })
				end
				local _, full, q = C_Item.GetItemInfo(costLink)
				best = math.max(best, q or 0)
				parts[#parts + 1] = ("%d %s"):format(value, full or costLink)
			end
		end
	end
	if nonref and (it.price or 0) > 0 then
		if #parts == 0 and price < HIGH then return go() end
		parts[#parts + 1] = coins(price)
	end
	if (not currency and best <= 2 and not nonref) or (#parts == 0 and price == 0) then return go() end
	ask({ title = title, action = "Buy", onAccept = go,
		text = ("It costs %s.%s%s"):format(table.concat(parts, ", "), nonref and " You cannot sell it back for a refund." or "", specText(GetMerchantItemLink(i))) })
end

-- Shift-click: how many, on a stepper, up to a stack or what the money buys.
local stepper, stepN, stepMax
-- (MerchantItemButton_BuyMultipleStacks: the money and the cost items held cap it.)
local function howMany(i)
	local it = C_MerchantFrame.GetItemInfo(i)
	if not it then return end
	local most, per = GetMerchantItemMaxStack(i) or 1, math.max(1, it.stackCount or 1)
	if (it.price or 0) > 0 then most = math.min(most, math.floor(GetMoney() / (it.price / per))) end
	if it.hasExtendedCost then
		for k = 1, MAX_COSTS do
			local _, value, costLink, currencyName = GetMerchantItemCostItem(i, k)
			if costLink and not currencyName and value then
				most = math.min(most, math.floor(C_Item.GetItemCount(costLink, false, false, true) / (value / per)))
			end
		end
	end
	if most < 2 then return end
	stepper = stepper or ns.Stepper(UIParent, { get = function() return stepN end, set = function(n) stepN = n end, max = function() return stepMax end })
	stepN, stepMax = 1, most
	ask({ title = ("Buy %s"):format(it.name or ""), text = "How many?", action = "Buy", onAccept = function() buy(i, stepN) end }, stepper)
	stepper.Paint()
end

-- What a refundable item gives back, or nil when it gives nothing
-- (ContainerFrame_GetExtendedPriceString).
local function refundText(bag, slot, equipped)
	local C = C_Container
	local info = C.GetContainerItemPurchaseInfo(bag, slot, equipped)
	if not info or not info.refundSeconds or (info.itemCount == 0 and info.money == 0 and info.currencyCount == 0) then return end
	local parts = {}
	if info.money > 0 then parts[1] = coins(info.money) end
	for k = 1, info.itemCount do
		local it = C.GetContainerItemPurchaseItem(bag, slot, k, equipped)
		if it and it.hyperlink then parts[#parts + 1] = ("%d %s"):format(it.itemCount or 0, it.hyperlink) end
	end
	for k = 1, info.currencyCount do
		local c = C.GetContainerItemPurchaseCurrency(bag, slot, k, equipped)
		if c and c.name then parts[#parts + 1] = ("|T%s:0|t %d %s"):format(c.iconFileID or "", c.currencyCount or 0, c.name) end
	end
	return ("You get back %s.%s"):format(table.concat(parts, ", "), info.hasEnchants and " Its enchantments and gems are lost." or "")
end

-- A held item dropped on the window is sold, as on the stock window; one
-- that can still be refunded asks first and is refunded (CONFIRM_REFUND_TOKEN_ITEM).
local function sell()
	if not CursorHasItem() then return end
	local loc = C_Cursor.GetCursorItem()
	if loc and C_Item.CanBeRefunded(loc) then
		local equipped = loc:IsEquipmentSlot()
		local bag, slot = 0, nil
		if equipped then slot = loc:GetEquipmentSlot() else bag, slot = loc:GetBagAndSlot() end
		local text = slot and refundText(bag, slot, equipped)
		if text then
			ask({ title = "Refund this item?", text = text, action = "Refund", onCancel = ClearCursor,
				onAccept = function() C_Container.ContainerRefundItemPurchase(bag, slot, equipped) end })
			return true
		end
	end
	PickupMerchantItem(0)
	return true
end

---------------------------------------------------------------------------
-- Item rows: the well, the name in its quality colour, the price under it.

-- A row of something sold here: the Buyback tab's, or the last sold on Buy.
local function back(r) return r.psBuyback or tab == "buyback" end

local function link(r)
	return back(r) and GetBuybackItemLink(r.psIndex) or GetMerchantItemLink(r.psIndex)
end

local function click(r, button)
	if sell() then return end
	local i = r.psIndex
	if IsModifiedClick() then
		if HandleModifiedItemClick(link(r)) then return end
		if not back(r) and IsModifiedClick("SPLITSTACK") then howMany(i) end
	elseif back(r) then
		BuybackItem(i)
	else
		buy(i, button == "RightButton" and GetMerchantItemMaxStack(i) or nil)
	end
end

-- The tooltip, and the game's cursor as on the stock rows: buy (or can't),
-- buy back, or inspect with the dress-up key.
local function enter(r)
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	if back(r) then
		GameTooltip:SetBuybackItem(r.psIndex)
		ns.TooltipHint("Click to buy it back.")
		if IsModifiedClick("DRESSUP") then ShowInspectCursor() else ShowBuybackSellCursor(r.psIndex) end
	else
		if IsModifiedClick("DRESSUP") then ShowInspectCursor() else SetCursor(CanAffordMerchantItem(r.psIndex) == false and "BUY_ERROR_CURSOR" or "BUY_CURSOR") end
		GameTooltip:SetMerchantItem(r.psIndex)
		if GameTooltip_ShowCompareItem then GameTooltip_ShowCompareItem(GameTooltip) end
		ns.TooltipHint("Click to buy. Right-click buys a stack, Shift-click asks how many. Drop an item from your bags here to sell it.")
	end
	GameTooltip:Show()
end

local function newRow(k)
	local r = CreateFrame("Button", nil, f.Body)
	r:SetSize((f.BodyWidth - GAP) / 2, ROW_H)
	W.Hover(r)
	r.Well = ns.ItemWell(r, 36)
	r.Well:SetPoint("LEFT", r, "LEFT", 8, 0)
	r.Name = W.Text(r, "label", "text")
	r.Name:SetPoint("BOTTOMLEFT", r.Well, "RIGHT", 10, 2)
	r.Name:SetPoint("RIGHT", r, "RIGHT", -8, 0)
	r.Name:SetJustifyH("LEFT")
	r.Money = ns.Money(r)
	r.Money:SetPoint("TOPLEFT", r.Well, "RIGHT", 10, -3)
	-- A quest starts from it: the game's quest bang on the icon.
	r.Quest = r.Well:CreateTexture(nil, "OVERLAY")
	r.Quest:SetAllPoints(r.Well.Icon)
	r.Quest:SetTexture(TEXTURE_ITEM_QUEST_BANG or "Interface\\ContainerFrame\\UI-Icon-QuestBang")
	-- The other costs (currencies, items): each its count and icon, and its
	-- own tooltip (the stock AltCurrencyFrame's buttons).
	r.Costs = {}
	for c = 1, MAX_COSTS do
		local b = CreateFrame("Button", nil, r)
		b:SetSize(40, 16)
		b.Text = W.Text(b, "number", "text")
		b.Text:SetPoint("LEFT", b, "LEFT", 0, 0)
		b.Icon = ns.GameIcon(b)
		b.Icon:SetSize(14, 14)
		b.Icon:SetPoint("LEFT", b.Text, "RIGHT", 3, 0)
		b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetMerchantCostItem(r.psIndex, self.psCost)
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", W.HideTooltip)
		b:SetScript("OnClick", function(_, button) click(r, button) end)
		r.Costs[c] = b
	end
	r.Stack = W.Text(r, "number", "textDim")
	r.Stack:SetPoint("TOPRIGHT", r, "RIGHT", -8, -3)
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	r:RegisterForDrag("LeftButton")
	r:SetScript("OnClick", click)
	-- Dragged to the bags, as the stock button; never one that asks first.
	r:SetScript("OnDragStart", function(self)
		local it = not back(self) and C_MerchantFrame.GetItemInfo(self.psIndex)
		if it and not it.hasExtendedCost and (it.price or 0) < HIGH then PickupMerchantItem(self.psIndex) end
	end)
	r:SetScript("OnReceiveDrag", sell)
	r:SetScript("OnEnter", enter)
	r:SetScript("OnLeave", function(self)
		W.HideTooltip(self)
		ResetCursor()
	end)
	rows[k] = r
	return r
end

local function fill(r, k)
	local name, icon, price, count, avail, usable, it, l
	if back(r) then
		name, icon, price, count, avail, usable = GetBuybackItemInfo(k)
		l = GetBuybackItemLink(k)
	else
		it = C_MerchantFrame.GetItemInfo(k) or {}
		name, icon, price, count, avail = it.name, it.texture, it.price, it.stackCount, it.numAvailable
		usable = it.isUsable and it.isPurchasable ~= false
		l = GetMerchantItemLink(k)
	end
	r.psIndex = k
	local q = l and C_Item.GetItemQualityByID(l)
	-- An heirloom is never red; one the player owns is faded, as sold out.
	local id = it and GetMerchantItemID(k)
	local heirloom = id and C_Heirloom and C_Heirloom.IsItemHeirloom(id)
	local known = heirloom and C_Heirloom.PlayerHasHeirloom(id)
	ns.PaintItem(r.Well, { icon = icon, quality = q, count = not it and count or nil, desat = avail == 0 or known,
		unusable = not usable and not (heirloom and it.isPurchasable ~= false) })
	r.Name:SetText(name or "")
	local cr, cg, cb = ns.QualityRGB(q)
	W.Uncolor(r.Name)
	if cr and q ~= 1 then r.Name:SetTextColor(Polestar.Theme.Legible(cr, cg, cb)) else W.Color(r.Name, "text") end
	price = price or 0
	r.Money:SetShown(price > 0)
	if price > 0 then ns.SetMoney(r.Money, price, it and CanAffordMerchantItem(k) == false and "danger" or nil) end
	local afford = not it or CanAffordMerchantItem(k) ~= false
	local prev = price > 0 and r.Money or nil
	for c, b in ipairs(r.Costs) do
		local tex, value
		if it and it.hasExtendedCost then tex, value = GetMerchantItemCostItem(k, c) end
		b:SetShown(tex ~= nil and value ~= nil)
		if b:IsShown() then
			b.psCost = c
			b.Text:SetText(value)
			W.Color(b.Text, afford and "text" or "danger")
			b.Icon:SetTexture(tex)
			b:SetWidth(math.ceil(b.Text:GetStringWidth()) + 3 + 14)
			b:ClearAllPoints()
			if prev then b:SetPoint("LEFT", prev, "RIGHT", 8, 0) else b:SetPoint("TOPLEFT", r.Well, "RIGHT", 10, -3) end
			prev = b
		end
	end
	r.Quest:SetShown(it and it.isQuestStartItem or false)
	local stack = {}
	if it and (count or 1) > 1 then stack[1] = "\195\151" .. count end
	if it and (avail or -1) >= 0 then stack[#stack + 1] = avail == 0 and "Sold out" or ("%d left"):format(avail) end
	r.Stack:SetText(table.concat(stack, "  "))
	r:Show()
end

---------------------------------------------------------------------------
-- The window.

local function filterMenu(self)
	MenuUtil.CreateContextMenu(self, function(_, root)
		root:SetTag("MENU_MERCHANT_FRAME")
		local function radio(text, v)
			root:CreateRadio(text, function(x) return GetMerchantFilter() == x end, function(x)
				SetMerchantFilter(x)
				paint() -- at once, not on the client's event (docs/CLIENT.md, rule 6)
			end, v)
		end
		for k = 1, GetNumSpecializations() do
			radio(select(2, C_SpecializationInfo.GetSpecializationInfo(k, false, false, nil, UnitSex("player"))), LE_LOOT_FILTER_SPEC1 + k - 1)
		end
		radio(ALL_SPECS or UnitClass("player"), LE_LOOT_FILTER_CLASS)
		root:CreateDivider()
		radio(ITEM_BIND_ON_EQUIP, LE_LOOT_FILTER_BOE)
		radio(ALL, LE_LOOT_FILTER_ALL)
		root:CreateDivider()
		root:CreateButton("Clear filters", function()
			SetMerchantFilter(LE_LOOT_FILTER_ALL)
			paint()
		end)
	end)
end

local function build()
	-- The main column keeps the 640 of the stock-sized page; the sidebar
	-- names the vendor and holds the search and the filter.
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 640 + W.SHELL.sidebar, height = 600, searchPlaceholder = "Search the wares",
		onSearch = function(text)
			query = (text or ""):lower()
			if f:IsShown() then paint() end
		end })
	ns.Dock(f)
	ns.WindowMenu(f, "merchant")
	-- The vendor (the stock portrait and title), the player's money under the name.
	subject = ns.SubjectBlock(f)
	subject.line:Hide()
	f.psSubject = subject
	money = ns.Money(f.Sidebar)
	money:SetPoint("TOPLEFT", subject.name, "BOTTOMLEFT", 0, -6)
	f.psMoney = money
	-- The filter ends the search row, lit while one is on.
	if GetMerchantFilter then
		f.psFilter = W.IconButton(f.Sidebar, "sliders", 30, "Filter", filterMenu, 14)
		f.psFilter:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -W.SHELL.side, -(W.SHELL.header - 30))
		Polestar.Theme.Skin(f.psFilter, "editbox")
	end
	f.psEmpty = W.Text(f.Body, "default", "textDim")
	f.psEmpty:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
	f:HookScript("OnReceiveDrag", sell)
	f:HookScript("OnMouseUp", sell)
	-- As the stock show and hide: the sounds, the filter reset, its dialogs gone.
	f:HookScript("OnShow", function()
		if ResetSetMerchantFilter then ResetSetMerchantFilter() end
		f.Search:SetText("")
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
	end)
	f:HookScript("OnHide", function()
		if asked and PolestarModal and PolestarModal:IsShown() and PolestarModal.psSpec == asked then PolestarModal:Hide() end
		if InRepairMode() then HideRepairCursor() end
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
	end)
	Polestar.CloseOnEscape(NAME)
end

-- The vendor's currencies and how many the player holds, at the tab row's
-- right (MerchantFrame_UpdateCurrencies), each with its tooltip.
local tokens = {}
local function currencies()
	local list = C_MerchantFrame.GetMerchantCurrencies() or {}
	local prev
	for i = 1, math.max(#list, #tokens) do
		local id, t = list[i], tokens[i]
		if id and not t then
			t = CreateFrame("Button", nil, f.TabRow)
			t:SetHeight(16)
			t.Text = W.Text(t, "number", "text")
			t.Text:SetPoint("LEFT", t, "LEFT", 0, 0)
			t.Icon = ns.GameIcon(t)
			t.Icon:SetSize(14, 14)
			t.Icon:SetPoint("LEFT", t.Text, "RIGHT", 3, 0)
			t:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetCurrencyByID(self.psID)
				GameTooltip:Show()
			end)
			t:SetScript("OnLeave", W.HideTooltip)
			tokens[i] = t
		end
		local info = id and C_CurrencyInfo.GetCurrencyInfo(id)
		if t then t:SetShown(info ~= nil and (info.name or "") ~= "") end
		if t and t:IsShown() then
			t.psID = id
			t.Text:SetText(info.quantity)
			t.Icon:SetTexture(info.iconFileID)
			t:SetWidth(math.ceil(t.Text:GetStringWidth()) + 3 + 14)
			t:ClearAllPoints()
			if prev then t:SetPoint("RIGHT", prev, "LEFT", -16, 0) else t:SetPoint("RIGHT", f.TabRow, "RIGHT", -W.SHELL.pad, 0) end
			prev = t
		end
	end
end

-- Polestar's Restock (QoL/Restock.lua), when this Polestar exports it: what a
-- press buys here and its total.
local function restock()
	local R = Polestar.QoL and Polestar.QoL.Restock
	if not (R and R.Plan and R.Run) then return end
	local plan = R.Plan()
	if #plan == 0 then return end
	local total, lines = 0, {}
	for _, e in ipairs(plan) do
		total = total + e.cost
		lines[#lines + 1] = ("%d %s"):format(e.items, e.name)
	end
	return { label = ("Restock (%s)"):format(coins(total)), onClick = function() R.Run() end, opts = { primary = true } }, lines
end

-- The repair buttons' tooltips, as the stock ones: the cost, the guild's
-- funds and what the player still pays, or that the money is short.
local function repairTips(cost)
	local dr, dg, db = Polestar.Theme.Color("danger")
	local own = { "Costs " .. coins(cost) }
	if cost > GetMoney() then own[2] = { "You do not have enough money.", dr, dg, db } end
	local guild = { "Costs " .. coins(cost) }
	if CanGuildBankRepair() then
		local funds, bank = GetGuildBankWithdrawMoney(), GetGuildBankMoney()
		funds = funds == -1 and bank or math.min(funds, bank)
		guild[2] = "The guild pays up to " .. coins(funds) .. "."
		if cost > funds then
			guild[3] = cost - funds <= GetMoney() and ("You pay the other " .. coins(cost - funds) .. ".") or { "You do not have enough money.", dr, dg, db }
		end
	end
	return own, guild
end

local function footer()
	local left, tips = {}, {}
	if CanMerchantRepair() then
		local cost, can = GetRepairAllCost()
		if can and cost > 0 then
			local own, guild = repairTips(cost)
			left[1] = { label = ("Repair all (%s)"):format(coins(cost)), onClick = function()
				RepairAllItems()
				PlaySound(SOUNDKIT.ITEM_REPAIR)
			end }
			tips[1] = { "Repair all items", own }
			if CanGuildBankRepair() then
				left[2] = { label = "Guild repair", onClick = function() RepairAllItems(true) end }
				tips[2] = { "Repair all items with guild funds", guild }
			end
		end
		-- One item: the game's repair cursor, then a click on the item (MerchantRepairItemButton).
		left[#left + 1] = { label = InRepairMode() and "Stop repairing" or "Repair an item", onClick = function()
			if InRepairMode() then HideRepairCursor() else ShowRepairCursor() end
			paint() -- at once: the client says nothing (docs/CLIENT.md, rule 6)
		end }
		tips[#left] = { "Repair an item", { "Then click a damaged item, worn or in your bags." } }
	end
	local MF = C_MerchantFrame
	if MF.IsSellAllJunkEnabled and MF.IsSellAllJunkEnabled() and MF.GetNumJunkItems() > 0 then
		left[#left + 1] = { label = "Sell junk", onClick = function()
			ask({ title = "Sell junk", text = SELL_ALL_JUNK_ITEMS_POPUP or "Sell all your junk?", action = "Sell", onAccept = MF.SellAllJunkItems })
		end }
	end
	local r, lines = restock()
	W.ShellFooter(f, left, { r })
	for i, b in ipairs(f.footerButtons.left) do b.psTip, b.psTipLines = tips[i] and tips[i][1], tips[i] and tips[i][2] end
	if r then
		local b = f.footerButtons.right[1]
		b.psTip, b.psTipLines = "Restock", lines
	end
end

function paint()
	W.ShellTabs(f, { { key = "buy", label = "Buy" }, { key = "buyback", label = "Buyback" } }, tab, function(k)
		tab = k
		paint()
	end)
	local buyback = tab == "buyback"
	SetPortraitTexture(subject.icon, "npc")
	subject.name:SetText(ns.Clean(UnitName("npc")) or MERCHANT or "Merchant")
	-- What the search keeps, two to a line.
	local all = buyback and GetNumBuybackItems() or GetMerchantNumItems()
	local list = {}
	for k = 1, all do
		local name
		if buyback then name = GetBuybackItemInfo(k) else name = (C_MerchantFrame.GetItemInfo(k) or {}).name end
		if query == "" or (name or ""):lower():find(query, 1, true) then list[#list + 1] = k end
	end
	local n = #list
	for slot, k in ipairs(list) do
		local r = rows[slot] or newRow(slot)
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad + ((slot - 1) % 2) * (r:GetWidth() + GAP), -(24 + math.floor((slot - 1) / 2) * ROW_H))
		fill(r, k)
	end
	for k = n + 1, #rows do rows[k]:Hide() end
	local count = query ~= "" and ("%d of %d"):format(n, all) or tostring(all)
	W.ShellTitle(f, buyback and (MERCHANT_BUYBACK or "Buyback") or (MERCHANT or "Merchant"),
		all == 0 and (buyback and "Nothing sold here yet." or "Nothing for sale.")
		or (buyback and "%s to buy back" or "%s for sale"):format(all == 1 and query == "" and "1 item" or count .. " items"))
	-- On Buy, the last item sold, to buy back (the stock MerchantBuyBackItem).
	local h = 24 + math.max(1, math.ceil(n / 2)) * ROW_H + 24
	local last = not buyback and GetNumBuybackItems() or 0
	if not f.psLast then
		f.psLast = newRow(0)
		rows[0] = nil
		f.psLast.psBuyback = true
		f.psLastCaption = W.Text(f.Body, "small", "textDim")
		f.psLastCaption:SetText("Sold last")
	end
	f.psLast:SetShown(last > 0)
	f.psLastCaption:SetShown(last > 0)
	if last > 0 then
		f.psLastCaption:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad + 8, -h)
		f.psLast:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -(h + 18))
		fill(f.psLast, last)
		h = h + 18 + ROW_H + 24
	end
	f.psEmpty:SetText(all > 0 and "Nothing matches the search." or buyback and "Nothing sold here yet." or "Nothing for sale.")
	f.psEmpty:SetShown(n == 0)
	ns.SetMoney(money, GetMoney())
	currencies()
	-- A game rule can take the filter away (MerchantFrame_Update); the search
	-- then runs to the sidebar's edge.
	local filter = f.psFilter and not (C_GameRules and C_GameRules.IsGameRuleActive(Enum.GameRule.MerchantFilterDisabled))
	f.Search:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -(W.SHELL.side + (filter and 30 + 6 or 0)), -(W.SHELL.header - 30))
	if f.psFilter then
		f.psFilter:SetShown(filter and true or false)
		local on = GetMerchantFilter() ~= LE_LOOT_FILTER_ALL
		W.SetIconState(f.psFilter, on)
		f.psFilter.psTip = on and "Filter (1 on)" or "Filter"
	end
	footer()
	W.ShellBody(f, h)
end

function M.Show()
	if not f then build() end
	tab = "buy"
	paint()
	f:Show()
end

function M.Enable()
	-- The NPC is the only door: ours takes its interaction, and the stock
	-- window is never opened (docs/DESIGN.md, "NPC windows: how they open").
	ns.Interaction("merchant", { Enum.PlayerInteractionType.Merchant }, { frame = NAME, close = CloseMerchant, bags = true })
	local function changed() if f and f:IsShown() then paint() end end
	for _, e in ipairs({ "MERCHANT_UPDATE", "MERCHANT_FILTER_ITEM_UPDATE", "PLAYER_MONEY", "BAG_UPDATE_DELAYED", "UPDATE_INVENTORY_DURABILITY", "GET_ITEM_INFO_RECEIVED", "CURRENCY_DISPLAY_UPDATE", "HEIRLOOMS_UPDATED", "UNIT_INVENTORY_CHANGED" }) do
		Polestar.RegisterEvent(e, changed)
	end
	-- Restock's amounts and setting.
	if Polestar.On then
		Polestar.On("RESTOCK_CHANGED", changed)
		Polestar.On("SETTING_CHANGED", changed)
	end
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return MerchantFrame and MerchantFrame:IsShown() and MerchantFrame end

ns.Module("merchant", M)
