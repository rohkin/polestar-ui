-- The Bank (docs/windows/bank.md): the banker's Character and Warband banks in
-- a Polestar shell. The stock BankFrame ends the bank as it hides, so it is
-- never opened: ours takes the interaction (ns.Interaction, Core.lua).
-- Forever's stock bank (Camelot's BankFrame.lua) is a bank of bags
-- (C_Bank.ShouldUsePlayerBagsInBank): each bank shows every bought bag's slots
-- in one grid, with a strip of its bag slots to put bags in and buy. A client
-- that reports tabs instead shows each tab on its own.

local ADDON, ns = ...
local W = Polestar.Widgets
local Theme = Polestar.Theme

local NAME = "PolestarUIBank"
local CHAR, ACCT -- Enum.BankType's, read as the window is built
local COLS = 11

local f, grid, strip, money
local shown -- the shown bank type (bags), or the shown tab's container ID (tabs)
local M = {}
local paint, buy

local function bagMode() return C_Bank.ShouldUsePlayerBagsInBank() end

-- Polestar's dialogs of ours, so ours closes them as the bank ends
-- (BankPanelMixin:CloseAllBankPopups).
local asked
local function ask(spec, body)
	asked = spec
	if body then return ns.ModalWith(spec, body) end
	return W.Modal(spec)
end

local function enter(w)
	GameTooltip:SetOwner(w, "ANCHOR_RIGHT")
	GameTooltip:SetBagItem(w.psBag, w.psSlot)
	GameTooltip:Show()
end

-- Picks up from or places on a slot; a refundable item going into the Warband
-- bank asks first, and goes only if still held (BankPanelItemButtonMixin:HandleItemPickup,
-- ACCOUNT_BANK_DEPOSIT_NO_REFUND_CONFIRM).
local function pickup(w)
	local held = C_Cursor.GetCursorItem()
	if held and w.psType == ACCT and C_Bank.CanUseBank(ACCT) and C_Item.CanBeRefunded(held) then
		local guid = C_Item.GetItemGUID(held)
		return ask({ title = "Deposit a refundable item?", text = "Once in the Warband bank, it can no longer be sold back for a refund.",
			action = "Deposit", onCancel = ClearCursor, onAccept = function()
				local now = C_Cursor.GetCursorItem()
				if now and C_Item.GetItemGUID(now) == guid then C_Container.PickupContainerItem(w.psBag, w.psSlot) end
			end })
	end
	C_Container.PickupContainerItem(w.psBag, w.psSlot)
end

-- Splitting a stack: how many to pick up, on a stepper in Polestar's dialog.
local stepper, stepN, stepMax
local function split(bag, slot)
	local it = C_Container.GetContainerItemInfo(bag, slot)
	if not it or it.isLocked or it.stackCount < 2 then return end
	stepper = stepper or ns.Stepper(UIParent, { get = function() return stepN end, set = function(n) stepN = n end, max = function() return stepMax end })
	stepN, stepMax = 1, it.stackCount
	ask({ title = "Split the stack", text = "How many to pick up?", action = "Pick up",
		onAccept = function() C_Container.SplitContainerItem(bag, slot, stepN) end }, stepper)
	stepper.Paint()
end

-- A slot's click as the stock bank's (BankPanelItemButtonMixin:OnClick): a
-- modified click links or splits, a left-click picks up or places. The
-- unmodified right-click (to the bags) is the overlay's secure "item" action.
local function click(w, button)
	if IsModifiedClick() then
		if HandleModifiedItemClick(C_Container.GetContainerItemLink(w.psBag, w.psSlot)) then return end
		if not CursorHasItem() and IsModifiedClick("SPLITSTACK") then split(w.psBag, w.psSlot) end
	elseif button == "LeftButton" then
		pickup(w)
	end
end

-- Right-click is the protected UseContainerItem: a secure button of ours over
-- the hovered slot, out of combat (docs/CLIENT.md, rule 4), handing its other
-- clicks and drops back to the slot.
local overlay = ns.Overlay("PolestarUIBankSlot", {
	enter = enter,
	pickup = pickup,
	setup = function(over)
		over:HookScript("PostClick", function(self, button) click(self.psTarget, button) end)
		over:HookScript("OnReceiveDrag", function(self) pickup(self.psTarget) end)
	end,
	attrs = function(over, w)
		-- An empty slot gets no action: the game's "item" action expects an item.
		over:SetAttribute("type2", C_Container.GetContainerItemInfo(w.psBag, w.psSlot) and "item" or nil)
		over:SetAttribute("item", w.psBag .. " " .. w.psSlot)
	end,
})

local function wire(w)
	if w.psBank then return end
	w.psBank = true
	w:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	w:RegisterForDrag("LeftButton")
	w:HookScript("OnEnter", function(self)
		enter(self)
		overlay(self)
	end)
	w:HookScript("OnLeave", W.HideTooltip)
	w:SetScript("OnClick", click)
	w:SetScript("OnDragStart", pickup)
	w:SetScript("OnReceiveDrag", pickup)
	-- The game's quest marks and cooldown sweep, as the stock slot shows them.
	w.psQuest = w:CreateTexture(nil, "OVERLAY")
	w.psQuest:SetAllPoints(w.Icon)
	w.psCooldown = CreateFrame("Cooldown", nil, w, "CooldownFrameTemplate")
	w.psCooldown:SetAllPoints(w.Icon)
	-- Lit while the cursor is on the bag the slot belongs to (BagIndicator).
	w.psGlow = w:CreateTexture(nil, "OVERLAY", nil, 2)
	w.psGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
	w.psGlow:SetAllPoints(w)
	W.Painter(w.psGlow, function(t) t:SetVertexColor(Theme.Wash("selected")) end)
	w.psGlow:Hide()
end

local function paintSlot(w)
	local it = C_Container.GetContainerItemInfo(w.psBag, w.psSlot)
	ns.PaintItem(w, it and { icon = it.iconFileID, quality = it.quality, count = it.stackCount, desat = it.isLocked })
	-- The search dims what does not match.
	w:SetAlpha(it and it.isFiltered and 0.25 or 1)
	local q = it and C_Container.GetContainerItemQuestInfo(w.psBag, w.psSlot)
	w.psQuest:SetShown(q ~= nil and (q.questID ~= nil or q.isQuestItem))
	if q then w.psQuest:SetTexture(q.questID and not q.isActive and TEXTURE_ITEM_QUEST_BANG or TEXTURE_ITEM_QUEST_BORDER) end
	local start, duration, on = C_Container.GetContainerItemCooldown(w.psBag, w.psSlot)
	if CooldownFrame_Set and it and ns.Clean(start) and ns.Clean(duration) then CooldownFrame_Set(w.psCooldown, start, duration, on) end
	return it
end

---------------------------------------------------------------------------
-- Bag slots (Forever's bank of bags): BankItemButtonBagMixin
---------------------------------------------------------------------------

local function bagSlots(t) return t == CHAR and Enum.BagIndex.Characterbanktab or Enum.BagIndex.Accountbanktab end
local function bagContainer(t, n) return (t == CHAR and Enum.BagIndex.CharacterBankTab_1 or Enum.BagIndex.AccountBankTab_1) + n - 1 end

local function glow(container, on)
	for _, w in ipairs({ grid:GetChildren() }) do
		if w.psGlow then w.psGlow:SetShown(on and w:IsShown() and w.psBag == container) end
	end
end

local function wireBag(b)
	if b.psBagSlot then return end
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b:RegisterForDrag("LeftButton")
	-- A bag goes in or comes out as any item: picked up and placed. A slot
	-- not bought yet buys the next (the stock Purchase button beside them).
	local function take(self) C_Container.PickupContainerItem(bagSlots(self.psType), self.psNum) end
	b:SetScript("OnClick", function(self)
		if self.psBought then take(self) else buy(self.psType) end
	end)
	b:SetScript("OnDragStart", take)
	b:SetScript("OnReceiveDrag", take)
	b:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if not self.psBought then
			local d = C_Bank.CanPurchaseBankTab(self.psType) and C_Bank.FetchNextPurchasableBankTabData(self.psType)
			GameTooltip:SetText("Bag slot not bought yet")
			if d then
				local r, g, bl = Theme.Color(d.canAfford and "text" or "danger")
				GameTooltip:AddLine("The next costs " .. ns.Coins(d.tabCost) .. ".", r, g, bl)
				ns.TooltipHint("Click to buy it.")
			end
		elseif not GameTooltip:SetBagItem(bagSlots(self.psType), self.psNum) then
			GameTooltip:SetText("Bag slot")
			ns.TooltipHint("Drop a bag here to add its slots to the bank.")
		end
		GameTooltip:Show()
		glow(bagContainer(self.psType, self.psNum), true)
	end)
	b:HookScript("OnLeave", function(self)
		W.HideTooltip()
		glow(nil, false)
	end)
	b.psBagSlot = true
end

-- The bank's bag slots past its first, bought or not (RefreshBagButtons).
local function paintBags(t, bought)
	local n = C_Bank.FetchMaxNumBankTabs(t) - 1
	local wells = strip.Layout(n)
	for k, b in ipairs(wells) do
		wireBag(b)
		b.psType, b.psNum, b.psBought = t, k + 1, bought[k + 1] ~= nil
		local it = b.psBought and C_Container.GetContainerItemInfo(bagSlots(t), k + 1)
		ns.PaintItem(b, it and { icon = it.iconFileID, quality = it.quality })
		b:SetAlpha(b.psBought and 1 or 0.45)
	end
	return n
end

---------------------------------------------------------------------------
-- Money and buying
---------------------------------------------------------------------------

-- Polestar's dialog with a money input of ours, made once.
local moneyIn, amount, cost
local function moneyDialog(spec, fn, bankType)
	moneyIn = moneyIn or ns.MoneyInput(UIParent, function(c) amount = c end)
	amount = 0
	moneyIn.Set(0)
	spec.onAccept = function() if amount > 0 then fn(bankType, amount) end end
	ask(spec, moneyIn)
end

-- A bag slot or a tab: its cost, red when short (CONFIRM_BUY_BANK_TAB).
function buy(bankType)
	local d = C_Bank.FetchNextPurchasableBankTabData(bankType)
	if not d then return end
	cost = cost or ns.Money(UIParent)
	ns.SetMoney(cost, d.tabCost, not d.canAfford and "danger" or nil)
	ask({ title = d.purchasePromptTitle ~= "" and d.purchasePromptTitle or "Buy a bank slot", text = d.purchasePromptBody, action = "Buy",
		onAccept = function() C_Bank.PurchaseBankTab(bankType) end }, cost)
end

local function deposit(bankType)
	if bankType ~= ACCT then return C_Bank.AutoDepositItemsIntoBank(bankType) end
	-- As the stock bank warns (ACCOUNT_BANK_DEPOSIT_ALL_NO_REFUND_CONFIRM).
	ask({ title = "Deposit all", text = "Items you could still sell back for a refund stop being refundable in the Warband bank.",
		action = "Deposit", onAccept = function() C_Bank.AutoDepositItemsIntoBank(bankType) end })
end

-- Sorting, asked first unless the player said not to (BankAutoSortButtonMixin,
-- BankCleanUpConfirmationPopup and its bankConfirmTabCleanUp setting).
local quiet
local function cleanUp(bankType)
	local function sort()
		PlaySound(SOUNDKIT.UI_BAG_SORTING_01)
		C_Container.SortBank(bankType)
	end
	if not GetCVarBool("bankConfirmTabCleanUp") then return sort() end
	if not quiet then
		quiet = CreateFrame("Frame", nil, UIParent)
		quiet:SetSize(240, 20)
		quiet.Check = W.Checkbox(quiet)
		quiet.Check:SetPoint("LEFT", quiet, "LEFT", 0, 0)
		local label = W.Text(quiet, "label", "text")
		label:SetPoint("LEFT", quiet.Check, "RIGHT", 8, 0)
		label:SetText("Do not ask again")
	end
	quiet.Check:SetChecked(false)
	ask({ title = "Clean up the bank?", text = "Items are sorted and stacked across its slots.", action = "Clean up", onAccept = function()
		SetCVar("bankConfirmTabCleanUp", quiet.Check:GetChecked() and "0" or "1")
		sort()
	end }, quiet)
end

---------------------------------------------------------------------------
-- The window
---------------------------------------------------------------------------

-- Locked banks say why (BankPanelLockPromptMixin).
local function lockedText(reason)
	local R = Enum.BankLockedReason
	return reason == R.BankConversionFailed and "This bank could not be converted. Try again later."
		or reason == R.BankDisabled and "This bank is disabled."
		or reason == R.NoAccountInventoryLock and "Another of your characters is using the Warband bank."
		or "This bank is locked."
end

local function build()
	CHAR, ACCT = Enum.BankType.Character, Enum.BankType.Account
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 760, height = 600, searchPlaceholder = "Search the bank",
		onSearch = function(text) C_Container.SetItemSearch(text or "") end })
	ns.Dock(f)
	ns.WindowMenu(f, "bank")
	local b = ns.SubjectBlock(f)
	b.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
	b.name:SetText("Bank")
	money = ns.Money(f.Sidebar)
	money:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, -6)
	f.psStripLabel = W.Text(f.Body, "small", "textDim")
	f.psStripLabel:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
	f.psStripLabel:SetText("Bag slots")
	strip = ns.ItemGrid(f.Body, COLS, 36, 4)
	strip:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -42)
	f.psStrip = strip
	grid = ns.ItemGrid(f.Body, COLS, 36, 4)
	f.psGrid = grid
	f.psNote = W.Text(f.Body, "default", "textDim")
	f.psNote:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
	f.psNote:SetWidth(f.BodyWidth)
	f.psNote:SetWordWrap(true)
	f.psNote:SetJustifyH("LEFT")
	-- The search is the bags' too: it ends with the bank, and so do our dialogs.
	f:HookScript("OnHide", function()
		f.Search:SetText("")
		C_Container.SetItemSearch("")
		if asked and PolestarModal and PolestarModal:IsShown() and PolestarModal.psSpec == asked then PolestarModal:Hide() end
	end)
	Polestar.CloseOnEscape(NAME)
end

-- The sidebar: in a bank of bags, one row per bank; with tabs, each bank's
-- tabs under its heading and "Buy a tab" while one can be bought.
local function navigation()
	local NAMES = { [CHAR] = "Bank", [ACCT] = "Warband bank" }
	local ICONS = { [CHAR] = "Interface\\Icons\\INV_SideTab_Bank_c60", [ACCT] = "Interface\\Icons\\UI_Warbands" }
	local nav, cur, curType, curLabel = {}, nil, nil, nil
	for _, t in ipairs({ CHAR, ACCT }) do
		if C_Bank.CanViewBank(t) then
			if bagMode() then
				nav[#nav + 1] = { key = "t" .. t, label = NAMES[t], psIcon = ICONS[t] }
				if "t" .. t == shown or not cur then cur, curType, curLabel = "t" .. t, t, NAMES[t] end
			else
				nav[#nav + 1] = { heading = true, label = t == CHAR and "Character" or "Warband" }
				for i, d in ipairs(C_Bank.FetchPurchasedBankTabData(t) or {}) do
					local label = (d.name or "") ~= "" and d.name or ("Tab %d"):format(i)
					nav[#nav + 1] = { key = d.ID, label = label, psIcon = d.icon }
					if d.ID == shown or not cur then cur, curType, curLabel = d.ID, t, label end
				end
				if C_Bank.CanPurchaseBankTab(t) then nav[#nav + 1] = { key = "buy" .. t, label = "Buy a tab", icon = "plus" } end
			end
		end
	end
	shown = cur
	W.ShellNav(f, nav, shown or false, function(k)
		if type(k) == "string" and k:sub(1, 3) == "buy" then return buy(tonumber(k:sub(4))) end
		shown = k
		paint()
	end)
	-- The banks' and tabs' own icons on their rows, in their colours.
	for i, item in ipairs(nav) do
		local icon = f.navButtons[i].Icon
		if item.psIcon then
			W.Uncolor(icon)
			icon:SetTexture(item.psIcon)
			icon:SetVertexColor(1, 1, 1)
			icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		else
			icon:SetTexCoord(0, 1, 0, 1)
		end
	end
	return curType, curLabel
end

function paint()
	local t, label = navigation()
	ns.SetMoney(money, GetMoney())
	W.ShellTabs(f, nil)
	local bags = bagMode()
	local locked = t and C_Bank.FetchBankLockedReason(t)
	local data = t and not locked and C_Bank.FetchPurchasedBankTabData(t) or {}
	-- The containers shown: every bought bag of the bank, or the one tab.
	local containers = {}
	if bags then
		for _, d in ipairs(data) do containers[#containers + 1] = d.ID end
	elseif shown and not locked then
		containers[1] = shown
	end
	local byNum = {}
	for i, d in ipairs(data) do byNum[i] = d end
	local y = 24
	local stripN = bags and t and not locked and #data > 0 and paintBags(t, byNum) or 0
	if stripN == 0 then strip.Layout(0) end
	strip:SetShown(stripN > 0)
	f.psStripLabel:SetShown(stripN > 0)
	if stripN > 0 then
		y = 42 + strip:GetHeight() + 20
		-- The next slot's cost, as the stock "Cost:" beside its Purchase button.
		local d = C_Bank.CanPurchaseBankTab(t) and C_Bank.FetchNextPurchasableBankTabData(t)
		f.psStripLabel:SetText(d and ("Bag slots (the next costs %s)"):format(ns.Coins(d.tabCost)) or "Bag slots")
	end
	local total = 0
	for _, id in ipairs(containers) do total = total + C_Container.GetContainerNumSlots(id) end
	local wells, k, free = grid.Layout(total), 0, 0
	for _, id in ipairs(containers) do
		for slot = 1, C_Container.GetContainerNumSlots(id) do
			k = k + 1
			local w = wells[k]
			wire(w)
			w.psBag, w.psSlot, w.psType = id, slot, t
			if not paintSlot(w) then free = free + 1 end
		end
	end
	grid:ClearAllPoints()
	grid:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -y)
	-- Nothing to show: why (locked), or what buying the first slot gives.
	local first = t and not locked and #data == 0 and C_Bank.CanPurchaseBankTab(t) and C_Bank.FetchNextPurchasableBankTabData(t)
	f.psNote:SetShown(locked ~= nil or first ~= nil)
	f.psNote:SetText(locked and lockedText(locked) or first and first.purchasePromptBody or "")
	local sub = total > 0 and ("%d of %d slots free."):format(free, total) or label and "Nothing here yet." or "No bank to show."
	if t and C_Bank.DoesBankTypeSupportMoneyTransfer(t) then sub = sub .. " Holds " .. ns.Coins(C_Bank.FetchDepositedMoney(t)) .. "." end
	W.ShellTitle(f, label or "Bank", sub)
	-- The footer: buy a bag slot, clean up, the money moves, deposit all.
	local left, right, gates = {}, {}, {}
	if t and not locked then
		if first then
			right[#right + 1] = { label = ("Buy (%s)"):format(ns.Coins(first.tabCost)), onClick = function() buy(t) end, opts = { primary = true } }
		end
		if #data > 0 then left[#left + 1] = { label = "Clean up", onClick = function() cleanUp(t) end } end
		if C_Bank.DoesBankTypeSupportMoneyTransfer(t) then
			left[#left + 1] = { label = "Deposit money", onClick = function() moneyDialog({ title = "Deposit money", text = "Into your Warband bank.", action = "Deposit" }, C_Bank.DepositMoney, t) end }
			gates[#left] = C_Bank.CanDepositMoney(t)
			left[#left + 1] = { label = "Withdraw money", onClick = function()
				moneyDialog({ title = "Withdraw money", text = "Your Warband bank holds " .. GetMoneyString(C_Bank.FetchDepositedMoney(t), true) .. ".", action = "Withdraw" }, C_Bank.WithdrawMoney, t)
			end }
			gates[#left] = C_Bank.CanWithdrawMoney(t)
		end
		if #data > 0 and C_Bank.DoesBankTypeSupportAutoDeposit(t) then
			right[#right + 1] = { label = "Deposit all", onClick = function() deposit(t) end, opts = { primary = true } }
		end
	end
	W.ShellFooter(f, left, right)
	for i, b in ipairs(f.footerButtons.left) do ns.SetEnabled(b, gates[i] ~= false) end
	W.ShellBody(f, math.max(y + grid:GetHeight(), f.psNote:IsShown() and 24 + f.psNote:GetStringHeight() or 0) + 24)
	-- The hovered slot's item may have moved: its secure action follows.
	local over = PolestarUIBankSlot
	if over and over:IsShown() and not InCombatLockdown() then overlay(over.psTarget) end
end

function M.Show()
	-- As BankFrame_Open: nothing to show, nothing opens (the interaction ends).
	if not C_Bank.AreAnyBankTypesViewable() then return end
	if not f then build() end
	paint()
	f:Show()
end

function M.Enable()
	ns.Interaction("bank", { Enum.PlayerInteractionType.Banker, Enum.PlayerInteractionType.CharacterBanker, Enum.PlayerInteractionType.AccountBanker },
		{ frame = NAME, close = function() C_Bank.CloseBankFrame() end, bags = true })
	for _, e in ipairs({ "BANK_TABS_CHANGED", "BANK_TAB_SETTINGS_UPDATED", "BAG_UPDATE", "BAG_CONTAINER_UPDATE", "ITEM_LOCK_CHANGED",
		"INVENTORY_SEARCH_UPDATE", "PLAYER_MONEY", "ACCOUNT_MONEY", "PLAYERBANKSLOTS_CHANGED", "PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED",
		"BAG_UPDATE_COOLDOWN" }) do
		Polestar.RegisterEvent(e, function() if f and f:IsShown() then paint() end end)
	end
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return BankFrame and BankFrame:IsShown() and BankFrame end

ns.Module("bank", M)
