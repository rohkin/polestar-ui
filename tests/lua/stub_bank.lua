-- The client's bank as the Bank sees it (Blizzard_UIPanels_Game's
-- BankFrameTemplates.lua, Camelot's BankFrame.lua): C_Bank, the bank's bags
-- (or tabs) as containers (C_Container), the bag slots, the item search and
-- the clicks a slot makes. Load after stub_npc.lua (the interaction manager,
-- the bags, money).

Enum.BankType = { Character = 0, Guild = 1, Account = 2 }
Enum.BagIndex = { Characterbanktab = -2, Accountbanktab = -3, CharacterBankTab_1 = 6, AccountBankTab_1 = 15 }
Enum.BankLockedReason = { None = 0, NoAccountInventoryLock = 1, BankDisabled = 2, BankConversionFailed = 3 }
local CHAR, ACCT = Enum.BankType.Character, Enum.BankType.Account

-- Forever's bank holds bags (ShouldUsePlayerBagsInBank); false gives tabs.
stub.bagMode = true
-- Each bank's bought bags (or tabs): a container ID, name, icon, size and
-- items (slot = { icon, quality, count, locked, name }). In a bank of bags the
-- first is the bank itself; the others sit in its bag slots.
stub.bankTabs = {
	[CHAR] = {
		{ ID = 6, name = "Gear", icon = 132761, size = 28, items = {
			[1] = { 135274, 2, 1, false, "Sword" }, [2] = { 133784, 3, 1, false, "Ring" }, [3] = { 132940, 4, 1, false, "Cloak" },
			[5] = { 134400, 1, 20, false, "Linen Cloth" }, [6] = { 133970, 1, 200, true, "Arrow" }, [14] = { 134939, 0, 5, false, "Linen Scrap" } } },
		{ ID = 7, name = "Herbs", icon = 134215, size = 14, items = { [1] = { 134187, 1, 17, false, "Peacebloom" } } },
	},
	[ACCT] = {
		{ ID = 15, name = "Warband", icon = 237277, size = 28, items = { [1] = { 134400, 1, 200, false, "Linen Cloth" }, [2] = { 132940, 4, 1, false, "Cloak" } } },
	},
}
-- The bags in the bank's bag slots (Characterbanktab, slot = bag number).
stub.bankBags = { [CHAR] = { [2] = { 133643, 2, "Runecloth Bag" } }, [ACCT] = {} }
stub.maxTabs = { [CHAR] = 6, [ACCT] = 5 }
stub.bankViewable = { [CHAR] = true, [ACCT] = true }
stub.tabCost = { [CHAR] = 250000, [ACCT] = 10000000 }
stub.warbandMoney = 5000000
stub.locked = {}
stub.cvars.bankConfirmTabCleanUp = "1"

local function find(bag)
	for _, list in pairs(stub.bankTabs) do
		for _, t in ipairs(list) do if t.ID == bag then return t end end
	end
end

C_Bank = C_Bank or {}
function C_Bank.ShouldUsePlayerBagsInBank() return stub.bagMode end
function C_Bank.AreAnyBankTypesViewable() return stub.bankViewable[CHAR] or stub.bankViewable[ACCT] or false end
function C_Bank.CanViewBank(t) return stub.bankViewable[t] or false end
function C_Bank.CanUseBank(t) return stub.bankViewable[t] and not stub.locked[t] or false end
function C_Bank.FetchBankLockedReason(t) return stub.locked[t] end
function C_Bank.FetchPurchasedBankTabData(t)
	local out = {}
	for _, tab in ipairs(stub.bankTabs[t] or {}) do out[#out + 1] = { ID = tab.ID, bankType = t, name = tab.name, icon = tab.icon, depositFlags = 0 } end
	return out
end
function C_Bank.FetchNumPurchasedBankTabs(t) return #(stub.bankTabs[t] or {}) end
function C_Bank.FetchMaxNumBankTabs(t) return stub.maxTabs[t] end
function C_Bank.CanPurchaseBankTab(t) return stub.tabCost[t] ~= nil end
function C_Bank.FetchNextPurchasableBankTabData(t)
	local c = stub.tabCost[t]
	return c and { tabCost = c, canAfford = GetMoney() >= c, purchasePromptTitle = "Purchase Bank Tab", purchasePromptBody = "Do you want to buy a new bank tab?" }
end
function C_Bank.PurchaseBankTab(t)
	stub.boughtTab = t
	local list = stub.bankTabs[t]
	list[#list + 1] = { ID = (list[#list] and list[#list].ID or (t == CHAR and 5 or 14)) + 1, name = "", icon = 0, size = 14, items = {} }
	stub.fire("BANK_TABS_CHANGED", t)
end
function C_Bank.DoesBankTypeSupportAutoDeposit() return true end
function C_Bank.DoesBankTypeSupportMoneyTransfer(t) return t == ACCT end
function C_Bank.CanDepositMoney(t) return t == ACCT and GetMoney() > 0 end
function C_Bank.CanWithdrawMoney(t) return t == ACCT and stub.warbandMoney > 0 end
function C_Bank.AutoDepositItemsIntoBank(t) stub.autoDeposited = t end
function C_Bank.FetchDepositedMoney(t) return t == ACCT and stub.warbandMoney or 0 end
function C_Bank.DepositMoney(t, n) stub.moneyMoved = { "deposit", t, n } end
function C_Bank.WithdrawMoney(t, n) stub.moneyMoved = { "withdraw", t, n } end
function C_Container.SortBank(t) stub.sorted = t end

-- The bank's bags and bag slots are containers; the backpack stays stub_npc's.
local numSlots, itemInfo = C_Container.GetContainerNumSlots, C_Container.GetContainerItemInfo
function C_Container.GetContainerNumSlots(bag)
	local t = find(bag)
	return t and t.size or numSlots(bag)
end
-- The item search (SetItemSearch): a filled slot whose name does not match is filtered.
stub.search = ""
function C_Container.SetItemSearch(text)
	stub.search = text
	stub.fire("INVENTORY_SEARCH_UPDATE")
end
function C_Container.GetContainerItemInfo(bag, slot)
	local holder = bag == Enum.BagIndex.Characterbanktab and CHAR or bag == Enum.BagIndex.Accountbanktab and ACCT
	if holder then
		local b = stub.bankBags[holder][slot]
		return b and { iconFileID = b[1], quality = b[2], stackCount = 1, isLocked = false, itemID = 4000 + slot }
	end
	local t = find(bag)
	if not t then return itemInfo(bag, slot) end
	local s = t.items[slot]
	if not s then return nil end
	return { iconFileID = s[1], quality = s[2], stackCount = s[3], isLocked = s[4], itemID = 2000 + slot,
		isFiltered = stub.search ~= "" and not s[5]:lower():find(stub.search:lower(), 1, true) }
end
-- Peacebloom starts a quest; nothing is cooling down.
function C_Container.GetContainerItemQuestInfo(bag, slot)
	return { isQuestItem = false, questID = bag == 7 and slot == 1 and 2 or nil, isActive = false }
end
function C_Container.GetContainerItemCooldown() return 0, 0, 1 end
function C_Container.GetContainerItemLink(bag, slot)
	local it = C_Container.GetContainerItemInfo(bag, slot)
	return it and ("|Hitem:%d|h[Item]|h"):format(it.itemID)
end
function C_Container.PickupContainerItem(bag, slot) stub.picked = { bag, slot } end
function C_Container.SplitContainerItem(bag, slot, n) stub.split = { bag, slot, n } end

-- The cursor: an item held (stub.held = { guid, refundable }), or nothing.
C_Cursor = C_Cursor or {}
function C_Cursor.GetCursorItem() return stub.held end
C_Item = C_Item or {}
function C_Item.CanBeRefunded(loc) return loc.refundable end
function C_Item.GetItemGUID(loc) return loc.guid end
function ClearCursor() stub.held = nil end

-- Shift is the split (and the chat link, which takes nothing: no chat is open).
function IsModifiedClick(what) return IsShiftKeyDown() and (what == nil or what == "SPLITSTACK" or what == "CHATLINK") end
function HandleModifiedItemClick() return false end
function CursorHasItem() return stub.held ~= nil end
function GetMoneyString(m) return ("%dg"):format(math.floor(m / 10000)) end
function GameTooltip.SetBagItem(self, bag, slot)
	local it = C_Container.GetContainerItemInfo(bag, slot)
	self:SetText(it and "item " .. it.itemID or "")
	return it ~= nil
end
