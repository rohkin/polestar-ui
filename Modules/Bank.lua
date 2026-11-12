-- The Bank (docs/windows/bank.md): the banker's Character and Warband tabs in
-- a Polestar shell. The stock BankFrame ends the bank as it hides, so it is
-- never opened: ours takes the interaction (ns.Interaction, Core.lua).

local ADDON, ns = ...
local W = Polestar.Widgets

local NAME = "PolestarUIBank"

local f, grid, money
local tab -- the shown tab's container ID
local M = {}
local paint

local function pickup(w) C_Container.PickupContainerItem(w.psBag, w.psSlot) end

local function enter(w)
	GameTooltip:SetOwner(w, "ANCHOR_RIGHT")
	GameTooltip:SetBagItem(w.psBag, w.psSlot)
	GameTooltip:Show()
end

-- Splitting a stack: how many to pick up, on a stepper in Polestar's dialog.
local stepper, stepN, stepMax
local function split(bag, slot)
	local it = C_Container.GetContainerItemInfo(bag, slot)
	if not it or it.isLocked or it.stackCount < 2 then return end
	stepper = stepper or ns.Stepper(UIParent, { get = function() return stepN end, set = function(n) stepN = n end, max = function() return stepMax end })
	stepN, stepMax = 1, it.stackCount
	ns.ModalWith({ title = "Split the stack", text = "How many to pick up?", action = "Pick up",
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
local place = ns.Overlay("PolestarUIBankSlot", {
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
		place(self)
	end)
	w:HookScript("OnLeave", W.HideTooltip)
	w:SetScript("OnClick", click)
	w:SetScript("OnDragStart", pickup)
	w:SetScript("OnReceiveDrag", pickup)
end

-- Polestar's dialog with a body of ours, made once.
local moneyIn, amount, cost
local function moneyDialog(spec, fn, bankType)
	moneyIn = moneyIn or ns.MoneyInput(UIParent, function(c) amount = c end)
	amount = 0
	moneyIn.Set(0)
	spec.onAccept = function() if amount > 0 then fn(bankType, amount) end end
	ns.ModalWith(spec, moneyIn)
end

local function buy(bankType)
	local d = C_Bank.FetchNextPurchasableBankTabData(bankType)
	if not d then return end
	cost = cost or ns.Money(UIParent)
	ns.SetMoney(cost, d.tabCost, not d.canAfford and "danger" or nil)
	ns.ModalWith({ title = d.purchasePromptTitle ~= "" and d.purchasePromptTitle or "Buy a tab", text = d.purchasePromptBody, action = "Buy",
		onAccept = function() C_Bank.PurchaseBankTab(bankType) end }, cost)
end

local function deposit(bankType)
	if bankType ~= Enum.BankType.Account then return C_Bank.AutoDepositItemsIntoBank(bankType) end
	-- As the stock bank warns (ACCOUNT_BANK_DEPOSIT_ALL_NO_REFUND_CONFIRM).
	W.Modal({ title = "Deposit all", text = "Items you could still sell back for a refund stop being refundable in the Warband bank.",
		action = "Deposit", onAccept = function() C_Bank.AutoDepositItemsIntoBank(bankType) end })
end

local function optionsMenu(self)
	W.ShowMenu(self, { { text = "Tab name, icon and filters: the game's bank (/pui bank off)", disabled = true } }, { minWidth = 200 })
end

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 760, height = 600, searchPlaceholder = "Search the bank",
		onSearch = function(text) C_Container.SetItemSearch(text or "") end })
	ns.Dock(f)
	ns.WindowMenu(f, "bank")
	local b = ns.SubjectBlock(f)
	b.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
	b.name:SetText("Bank")
	money = ns.Money(f.Sidebar)
	money:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, -6)
	-- The tab settings stay the stock bank's, on the band's Options (as Spellbook's).
	local opt = CreateFrame("Button", nil, f.Header)
	opt:SetSize(96, 24)
	opt:SetPoint("BOTTOMRIGHT", f.Header, "BOTTOMRIGHT", -20, 12)
	W.Hover(opt)
	opt.Label = W.Text(opt, "small", "text")
	opt.Label:SetPoint("LEFT", opt, "LEFT", 10, 0)
	opt.Label:SetText("Options")
	opt.Arrow = W.Tex(opt, "ARTWORK", "chevron-down", "textDim")
	opt.Arrow:SetSize(12, 12)
	opt.Arrow:SetPoint("RIGHT", opt, "RIGHT", -10, 0)
	opt:SetScript("OnClick", optionsMenu)
	f.psOptions = opt
	grid = ns.ItemGrid(f.Body, 11, 36, 4)
	grid:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
	f.psGrid = grid
	-- The search is the bags' too: it ends with the bank.
	f:HookScript("OnHide", function()
		f.Search:SetText("")
		C_Container.SetItemSearch("")
	end)
	Polestar.CloseOnEscape(NAME)
end

function paint()
	local nav, cur, curType, curLabel = {}, nil, nil, nil
	for _, bank in ipairs({ { Enum.BankType.Character, "Character" }, { Enum.BankType.Account, "Warband" } }) do
		local t = bank[1]
		if C_Bank.CanViewBank(t) then
			nav[#nav + 1] = { heading = true, label = bank[2] }
			for i, d in ipairs(C_Bank.FetchPurchasedBankTabData(t) or {}) do
				local label = (d.name or "") ~= "" and d.name or ("Tab %d"):format(i)
				nav[#nav + 1] = { key = d.ID, label = label, psIcon = d.icon }
				if d.ID == tab or not cur then cur, curType, curLabel = d.ID, t, label end
			end
			if C_Bank.CanPurchaseBankTab(t) then nav[#nav + 1] = { key = "buy" .. t, label = "Buy a tab", icon = "plus" } end
		end
	end
	tab = cur
	W.ShellNav(f, nav, tab or false, function(k)
		if type(k) == "string" then return buy(tonumber(k:sub(4))) end
		tab = k
		paint()
	end)
	-- The tabs' own icons on their rows, in their colours.
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
	ns.SetMoney(money, GetMoney())
	W.ShellTitle(f, curLabel or "Bank", tab and "Right-click an item to move it to your bags." or "No tab bought yet.")
	W.ShellTabs(f, nil)
	local wells = grid.Layout(tab and C_Container.GetContainerNumSlots(tab) or 0)
	for i, w in ipairs(wells) do
		wire(w)
		w.psBag, w.psSlot = tab, i
		local it = C_Container.GetContainerItemInfo(tab, i)
		ns.PaintItem(w, it and { icon = it.iconFileID, quality = it.quality, count = it.stackCount, desat = it.isLocked })
		-- The search dims what does not match.
		w:SetAlpha(it and it.isFiltered and 0.25 or 1)
	end
	local left, right = {}, {}
	if curType and C_Bank.DoesBankTypeSupportMoneyTransfer(curType) then
		left = {
			{ label = "Deposit money", onClick = function() moneyDialog({ title = "Deposit money", text = "Into your Warband bank.", action = "Deposit" }, C_Bank.DepositMoney, curType) end },
			{ label = "Withdraw money", onClick = function()
				moneyDialog({ title = "Withdraw money", text = "Your Warband bank holds " .. GetMoneyString(C_Bank.FetchDepositedMoney(curType), true) .. ".", action = "Withdraw" }, C_Bank.WithdrawMoney, curType)
			end },
		}
	end
	if curType and C_Bank.DoesBankTypeSupportAutoDeposit(curType) then
		right[1] = { label = "Deposit all", onClick = function() deposit(curType) end, opts = { primary = true } }
	end
	W.ShellFooter(f, left, right)
	W.ShellBody(f, 24 + grid:GetHeight() + 24)
	-- The hovered slot's item may have moved: its secure action follows.
	local over = PolestarUIBankSlot
	if over and over:IsShown() and not InCombatLockdown() then place(over.psTarget) end
end

function M.Show()
	-- As BankFrame_Open: nothing to show, nothing opens (the interaction ends).
	if not C_Bank.AreAnyBankTypesViewable() then return end
	if not f then build() end
	paint()
	f:Show()
end

function M.Enable()
	-- shortcut: the preview loads the interaction manager only in NPC scenes; drop this guard once Core's ns.Interaction checks it.
	if not RegisterPlayerInteraction then return end
	local T = Enum.PlayerInteractionType
	ns.Interaction("bank", { T.Banker, T.CharacterBanker, T.AccountBanker }, { frame = NAME, close = function() C_Bank.CloseBankFrame() end, bags = true })
	for _, e in ipairs({ "BANK_TABS_CHANGED", "BANK_TAB_SETTINGS_UPDATED", "BAG_UPDATE", "ITEM_LOCK_CHANGED", "INVENTORY_SEARCH_UPDATE", "PLAYER_MONEY" }) do
		Polestar.RegisterEvent(e, function() if f and f:IsShown() then paint() end end)
	end
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return BankFrame and BankFrame:IsShown() and BankFrame end

ns.Module("bank", M)
