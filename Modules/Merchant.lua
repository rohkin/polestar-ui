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

local f, money
local tab = "buy"
local rows = {}
local M = {}
local paint

-- Coins as plain text, as Polestar's own Restock label writes them.
local function coins(c)
	local g, s = math.floor(c / 10000), math.floor(c / 100) % 100
	if g > 0 then return ("%dg %ds %dc"):format(g, s, c % 100) end
	if s > 0 then return ("%ds %dc"):format(s, c % 100) end
	return ("%dc"):format(c % 100)
end

-- Polestar's dialogs of ours, so ours closes them when the visit ends.
local asked
local function ask(spec, body)
	asked = spec
	if body then ns.ModalWith(spec, body) else W.Modal(spec) end
end

local function purchase(i, n)
	if n then BuyMerchantItem(i, n) else BuyMerchantItem(i) end
end

-- Buys n of item i (nil: one purchase), first asking as the stock window
-- does for a high price or a cost in currencies or items.
local function buy(i, n)
	local it = C_MerchantFrame.GetItemInfo(i)
	if not it then return end
	local per = math.max(1, it.stackCount or 1)
	local times = (n or per) / per
	local price = (it.price or 0) * times
	if not it.hasExtendedCost and price < HIGH then return purchase(i, n) end
	local parts = {}
	if price > 0 then parts[1] = coins(price) end
	for k = 1, GetMerchantItemCostInfo(i) or 0 do
		local tex, value, link, currency = GetMerchantItemCostItem(i, k)
		if value then parts[#parts + 1] = ("|T%s:0|t %d %s"):format(tex or "", value * times, currency or link or "") end
	end
	local refund = not C_MerchantFrame.IsMerchantItemRefundable or C_MerchantFrame.IsMerchantItemRefundable(i)
	ask({ title = ("Buy %s?"):format(it.name or ""), action = "Buy", onAccept = function() purchase(i, n) end,
		text = ("It costs %s.%s"):format(table.concat(parts, ", "), refund and "" or " You cannot sell it back for a refund.") })
end

-- Shift-click: how many, on a stepper, up to a stack or what the money buys.
local stepper, stepN, stepMax
local function howMany(i)
	local it = C_MerchantFrame.GetItemInfo(i)
	local most = GetMerchantItemMaxStack(i) or 1
	if it and (it.price or 0) > 0 then most = math.min(most, math.floor(GetMoney() / (it.price / math.max(1, it.stackCount or 1)))) end
	if not it or most < 2 then return end
	stepper = stepper or ns.Stepper(UIParent, { get = function() return stepN end, set = function(n) stepN = n end, max = function() return stepMax end })
	stepN, stepMax = 1, most
	ask({ title = ("Buy %s"):format(it.name or ""), text = "How many?", action = "Buy", onAccept = function() buy(i, stepN) end }, stepper)
	stepper.Paint()
end

-- A held item dropped on the window is sold, as on the stock window.
local function sell()
	if CursorHasItem() then
		PickupMerchantItem(0)
		return true
	end
end

---------------------------------------------------------------------------
-- Item rows: the well, the name in its quality colour, the price under it.

local function link(r)
	return tab == "buyback" and GetBuybackItemLink(r.psIndex) or GetMerchantItemLink(r.psIndex)
end

local function click(r, button)
	if sell() then return end
	local i = r.psIndex
	if IsModifiedClick() then
		if HandleModifiedItemClick(link(r)) then return end
		if tab == "buy" and IsModifiedClick("SPLITSTACK") then howMany(i) end
	elseif tab == "buyback" then
		BuybackItem(i)
	else
		buy(i, button == "RightButton" and GetMerchantItemMaxStack(i) or nil)
	end
end

local function enter(r)
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	if tab == "buyback" then
		GameTooltip:SetBuybackItem(r.psIndex)
		ns.TooltipHint("Click to buy it back.")
	else
		GameTooltip:SetMerchantItem(r.psIndex)
		if GameTooltip_ShowCompareItem then GameTooltip_ShowCompareItem(GameTooltip) end
		ns.TooltipHint("Click to buy. Right-click buys a stack, Shift-click asks how many.")
	end
	GameTooltip:Show()
end

local function newRow(k)
	local r = CreateFrame("Button", nil, f.Body)
	r:SetSize((f.BodyWidth - GAP) / 2, ROW_H)
	r:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad + ((k - 1) % 2) * (r:GetWidth() + GAP), -(24 + math.floor((k - 1) / 2) * ROW_H))
	W.Hover(r)
	r.Well = ns.ItemWell(r, 36)
	r.Well:SetPoint("LEFT", r, "LEFT", 8, 0)
	r.Name = W.Text(r, "label", "text")
	r.Name:SetPoint("BOTTOMLEFT", r.Well, "RIGHT", 10, 2)
	r.Name:SetPoint("RIGHT", r, "RIGHT", -8, 0)
	r.Name:SetJustifyH("LEFT")
	r.Money = ns.Money(r)
	r.Money:SetPoint("TOPLEFT", r.Well, "RIGHT", 10, -3)
	r.Cost = W.Text(r, "number", "text")
	r.Stack = W.Text(r, "number", "textDim")
	r.Stack:SetPoint("TOPRIGHT", r, "RIGHT", -8, -3)
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	r:RegisterForDrag("LeftButton")
	r:SetScript("OnClick", click)
	-- Dragged to the bags, as the stock button; never one that asks first.
	r:SetScript("OnDragStart", function(self)
		local it = tab == "buy" and C_MerchantFrame.GetItemInfo(self.psIndex)
		if it and not it.hasExtendedCost and (it.price or 0) < HIGH then PickupMerchantItem(self.psIndex) end
	end)
	r:SetScript("OnReceiveDrag", sell)
	r:SetScript("OnEnter", enter)
	r:SetScript("OnLeave", W.HideTooltip)
	rows[k] = r
	return r
end

local function fill(r, k)
	local name, icon, price, count, avail, usable, it, l
	if tab == "buyback" then
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
	ns.PaintItem(r.Well, { icon = icon, quality = q, count = not it and count or nil, desat = avail == 0, unusable = not usable })
	r.Name:SetText(name or "")
	local cr, cg, cb = ns.QualityRGB(q)
	W.Uncolor(r.Name)
	if cr and q ~= 1 then r.Name:SetTextColor(Polestar.Theme.Legible(cr, cg, cb)) else W.Color(r.Name, "text") end
	price = price or 0
	r.Money:SetShown(price > 0)
	if price > 0 then ns.SetMoney(r.Money, price, it and CanAffordMerchantItem(k) == false and "danger" or nil) end
	-- The other costs (currencies, items): their icon and count.
	local parts = {}
	for c = 1, it and it.hasExtendedCost and GetMerchantItemCostInfo(k) or 0 do
		local tex, value = GetMerchantItemCostItem(k, c)
		if value then parts[#parts + 1] = ("%d |T%s:0|t"):format(value, tex or "") end
	end
	r.Cost:SetText(table.concat(parts, "  "))
	r.Cost:ClearAllPoints()
	if price > 0 then r.Cost:SetPoint("LEFT", r.Money, "RIGHT", 8, 0) else r.Cost:SetPoint("TOPLEFT", r.Well, "RIGHT", 10, -3) end
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
		radio(UnitClass("player"), LE_LOOT_FILTER_CLASS)
		root:CreateDivider()
		radio(ITEM_BIND_ON_EQUIP, LE_LOOT_FILTER_BOE)
		radio(ALL, LE_LOOT_FILTER_ALL)
	end)
end

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 640, height = 600, sidebar = 0 })
	ns.Plain(f)
	ns.Dock(f)
	ns.WindowMenu(f, "merchant")
	if GetMerchantFilter then
		f.psFilter = W.IconButton(f.Header, "sliders", 28, "Filter", filterMenu, 14)
		f.psFilter:SetPoint("BOTTOMRIGHT", f.Header, "BOTTOMRIGHT", -20, 12)
	end
	money = ns.Money(f.TabRow)
	money:SetPoint("RIGHT", f.TabRow, "RIGHT", -W.SHELL.pad, 0)
	f.psMoney = money
	f.psEmpty = W.Text(f.Body, "default", "textDim")
	f.psEmpty:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
	f:HookScript("OnReceiveDrag", sell)
	f:HookScript("OnMouseUp", sell)
	-- As the stock show and hide: the sounds, the filter reset, its dialogs gone.
	f:HookScript("OnShow", function()
		if ResetSetMerchantFilter then ResetSetMerchantFilter() end
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
	end)
	f:HookScript("OnHide", function()
		if asked and PolestarModal and PolestarModal:IsShown() and PolestarModal.psSpec == asked then PolestarModal:Hide() end
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
	end)
	Polestar.CloseOnEscape(NAME)
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

local function footer()
	local left = {}
	if CanMerchantRepair() then
		local cost, can = GetRepairAllCost()
		if can and cost > 0 then
			left[1] = { label = ("Repair all (%s)"):format(coins(cost)), onClick = function() RepairAllItems() end }
			if CanGuildBankRepair and CanGuildBankRepair() then
				left[2] = { label = "Guild repair", onClick = function() RepairAllItems(true) end }
			end
		end
	end
	local MF = C_MerchantFrame
	if MF.IsSellAllJunkEnabled and MF.IsSellAllJunkEnabled() and MF.GetNumJunkItems() > 0 then
		left[#left + 1] = { label = "Sell junk", onClick = function()
			ask({ title = "Sell junk", text = SELL_ALL_JUNK_ITEMS_POPUP or "Sell all your junk?", action = "Sell", onAccept = MF.SellAllJunkItems })
		end }
	end
	local r, lines = restock()
	W.ShellFooter(f, left, { r })
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
	W.ShellTitle(f, ns.Clean(UnitName("npc")) or "Merchant",
		buyback and "Click an item to buy it back." or "Click an item to buy it. Right-click an item in your bags to sell it.")
	local n = buyback and GetNumBuybackItems() or GetMerchantNumItems()
	for k = 1, n do fill(rows[k] or newRow(k), k) end
	for k = n + 1, #rows do rows[k]:Hide() end
	f.psEmpty:SetText(buyback and "Nothing sold here yet." or "Nothing for sale.")
	f.psEmpty:SetShown(n == 0)
	ns.SetMoney(money, GetMoney())
	footer()
	W.ShellBody(f, 24 + math.max(1, math.ceil(n / 2)) * ROW_H + 24)
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
	for _, e in ipairs({ "MERCHANT_UPDATE", "MERCHANT_FILTER_ITEM_UPDATE", "PLAYER_MONEY", "BAG_UPDATE_DELAYED", "UPDATE_INVENTORY_DURABILITY", "GET_ITEM_INFO_RECEIVED" }) do
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
