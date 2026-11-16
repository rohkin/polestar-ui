-- The client's bags as the Bags window sees them (docs/windows/bags.md):
-- C_Container over the backpack, four bags, the reagent bag and the keyring
-- (the live slot counts: 20 12 12 14 12, reagent 6), C_NewItems, the stock
-- frames and toggles in their real shape (Blizzard_UIPanels_Game Mainline
-- ContainerFrame.lua: ToggleAllBags opens through OpenBackpack and OpenBag,
-- FRAME_THAT_OPENED_BAGS), the bag bar's clicks, and the slot template
-- ContainerFrameItemButtonTemplate for CreateFrame("ItemButton", ...).
-- Load after stub_npc.lua / stub_auction.lua: its C_Container wins.

Constants = Constants or {}
Constants.InventoryConstants = { NumBagSlots = 4, NumReagentBagSlots = 1 }
NUM_TOTAL_BAG_FRAMES, NUM_CONTAINER_FRAMES, KEYRING_CONTAINER = 5, 7, -2
Enum.BagIndex.Backpack, Enum.BagIndex.Keyring = 0, -2
stub.cvars.combinedBags, stub.cvars.showKeyring = "1", "1"
C_ActionBar = C_ActionBar or {}
function C_ActionBar.ShouldShowKeyring() return true end
function IsAccountSecured() return true end
EditModeUtil = EditModeUtil or {}
function EditModeUtil:GetRightActionBarWidth() return 0 end
function CooldownFrame_Set(cd, start, duration, enable) cd.psStub = { start, duration, enable } end

-- The bags: slot = { icon, quality, count, locked, extra } (extra: quest,
-- cooldown = { start, duration, enable }, filtered). Slot counts per bag.
stub.bagSlots = { [0] = 20, 12, 12, 14, 12, 6, [-2] = 4 }
stub.bags = {
	[0] = { { 134400, 1, 20 }, { 135274, 2, 1 }, { 133784, 3, 1 }, { 132940, 4, 1 }, { 134939, 0, 5 }, { 133970, 1, 200, true },
		[8] = { 134831, 1, 5, false, { cooldown = { 100, 120, 1 } } }, [9] = { 134939, 1, 1, false, { quest = { isQuestItem = true } } },
		[10] = { 134939, 1, 1, false, { quest = { questID = 7, isActive = false } } } },
	[1] = { { 133964, 1, 12 }, [5] = { 135274, 2, 1 } },
	[2] = { { 132889, 1, 20 } },
	[3] = {},
	[4] = { [12] = { 134400, 0, 3 } },
	[5] = { { 133940, 1, 40 } },
	[-2] = { { 134235, 1, 1 } },
}
stub.newItems = { ["0:2"] = true, ["1:5"] = true }
stub.used, stub.picked, stub.sortedBags = {}, nil, 0

C_Container = C_Container or {}
function C_Container.GetContainerNumSlots(bag) return stub.bagSlots[bag] or 0 end
function GetKeyRingSize() return stub.bagSlots[-2] end
local function slotOf(bag, slot) return (stub.bags[bag] or {})[slot] end
function C_Container.GetContainerItemInfo(bag, slot)
	local s = slotOf(bag, slot)
	if not s then return nil end
	local x = s[5] or {}
	return { iconFileID = s[1], quality = s[2], stackCount = stub.secretBags and stub.SECRET or s[3], isLocked = s[4] or false,
		isFiltered = stub.search ~= nil and stub.search ~= "" and not x.match, itemID = 2000 + slot, hyperlink = "item:" .. (2000 + slot) }
end
function C_Container.GetContainerItemQuestInfo(bag, slot)
	local s = slotOf(bag, slot)
	local q = s and s[5] and s[5].quest or {}
	return { isQuestItem = q.isQuestItem or false, questID = q.questID, isActive = q.isActive or false }
end
function C_Container.GetContainerItemCooldown(bag, slot)
	local s = slotOf(bag, slot)
	local c = s and s[5] and s[5].cooldown
	if not c then return 0, 0, 1 end
	if stub.secretBags then return stub.SECRET, stub.SECRET, c[3] end
	return c[1], c[2], c[3]
end
function C_Container.GetContainerItemLink(bag, slot) return slotOf(bag, slot) and ("|Hitem:%d|h[Bag item]|h"):format(2000 + slot) or nil end
function C_Container.SetItemSearch(text)
	stub.search = text
	stub.fire("INVENTORY_SEARCH_UPDATE")
end
function C_Container.SortBags() stub.sortedBags = stub.sortedBags + 1 end
function C_Container.ContainerIDToInventoryID(bag) return 30 + bag end
function C_Container.PickupContainerItem(bag, slot) stub.picked = { bag, slot } end
-- Protected: the client blocks it when addon code is anywhere on the stack
-- (a tainted click). Our wells' clicks start in the template's own script.
function C_Container.UseContainerItem(bag, slot)
	for level = 2, 40 do
		local info = debug.getinfo(level, "S")
		if not info then break end
		if stub.addonSources[info.source] == "Polestar_UI" then error("ADDON_ACTION_BLOCKED: UseContainerItem from Polestar_UI", 2) end
	end
	table.insert(stub.used, { bag, slot })
end
local invTexture = GetInventoryItemTexture
function GetInventoryItemTexture(unit, id)
	if id >= 31 and id <= 35 then return id ~= 34 and 133639 or nil end
	return invTexture(unit, id)
end
GameTooltip.SetBagItem = GameTooltip.SetBagItem or function(self, bag, slot) self.lines = { "Bag item " .. bag .. "/" .. slot } end
function SpellCanTargetItem() return stub.targeting or false end

C_NewItems = {}
function C_NewItems.IsNewItem(bag, slot) return stub.newItems[bag .. ":" .. slot] or false end
function C_NewItems.RemoveNewItem(bag, slot) stub.newItems[bag .. ":" .. slot] = nil end

---------------------------------------------------------------------------
-- The stock frames and toggles
---------------------------------------------------------------------------

-- Each stock frame counts its shows (stub.stockShown[name]) and, as its
-- OnHide (UpdateNewItemList), clears its bags' new-item flags. As in the
-- client, its OnShow/OnHide run only when it becomes visible or stops being
-- (not under a hidden parent; SetParent runs them too), and one run with
-- Polestar_UI code on the stack is reported: it would run as ours and taint
-- the stock bags (docs/CLIENT.md, rules 8 and 19).
stub.stockShown = {}
local function guard(name, script)
	for level = 3, 40 do
		local info = debug.getinfo(level, "S")
		if not info then break end
		if stub.addonSources[info.source] == "Polestar_UI" then
			return geterrorhandler()(name .. "'s " .. script .. " ran from Polestar_UI code (taints the stock bags)")
		end
	end
end
local function stockFrame(name, bags)
	local fr = CreateFrame("Frame", name, UIParent)
	fr:Hide()
	local function shown()
		guard(name, "OnShow")
		stub.stockShown[name] = (stub.stockShown[name] or 0) + 1
		PlaySound(SOUNDKIT.IG_BACKPACK_OPEN)
	end
	local function hidden()
		guard(name, "OnHide")
		PlaySound(SOUNDKIT.IG_BACKPACK_CLOSE)
		for _, bag in ipairs(bags) do
			for slot = 1, C_Container.GetContainerNumSlots(bag) do C_NewItems.RemoveNewItem(bag, slot) end
		end
	end
	fr:SetScript("OnShow", function(self) if self:GetParent():IsVisible() then shown() end end)
	fr:SetScript("OnHide", function(self) if self:GetParent():IsVisible() then hidden() end end)
	rawset(fr, "SetParent", function(self, p)
		local was = self:IsVisible()
		stub.Methods.SetParent(self, p)
		if self:IsVisible() ~= was then
			if was then hidden() else shown() end
		end
	end)
	return fr
end
ContainerFrameCombinedBags = stockFrame("ContainerFrameCombinedBags", { 0, 1, 2, 3, 4 })
for i = 1, 6 do stockFrame("ContainerFrame" .. i, { i - 1 }) end
stockFrame("ContainerFrame7", { -2 })

local opener -- FRAME_THAT_OPENED_BAGS
function stub.stockOpener() return opener end
stub.bagsDisabled = false
function ContainerFrame_AllowedToOpenBags() return not stub.bagsDisabled end
local function combined(id) return GetCVar("combinedBags") ~= "0" and (id == nil or (id >= 0 and id <= 4)) end
local function frameFor(id) return _G["ContainerFrame" .. (id == KEYRING_CONTAINER and 7 or id + 1)] end
function IsBagOpen(id)
	if combined(id) then return ContainerFrameCombinedBags:IsShown() end
	return frameFor(id):IsShown()
end
function IsAnyBagOpen()
	for i = 0, NUM_TOTAL_BAG_FRAMES do if IsBagOpen(i) then return true end end
	return IsBagOpen(KEYRING_CONTAINER)
end
function OpenBag(id)
	if not ContainerFrame_AllowedToOpenBags() then return end
	if combined(id) then
		if not IsBagOpen(id) then ContainerFrameCombinedBags:Show() end
	elseif C_Container.GetContainerNumSlots(id) > 0 then
		frameFor(id):Show()
	end
end
function OpenBackpack()
	if not ContainerFrame_AllowedToOpenBags() then return end
	if combined() then return OpenBag(0) end
	if not IsBagOpen(0) then ToggleBackpack() end
end
function CloseBackpack()
	local fr = combined() and ContainerFrameCombinedBags or ContainerFrame1
	local was = fr:IsShown()
	fr:Hide()
	return was
end
function CloseBag(id)
	if combined(id) then return CloseBackpack() end
	local fr = frameFor(id)
	local was = fr:IsShown()
	fr:Hide()
	return was
end
function ToggleBackpack()
	if not ContainerFrame_AllowedToOpenBags() then return end
	if combined() then
		if IsBagOpen(0) then ContainerFrameCombinedBags:Hide() else OpenBackpack() end
	elseif IsBagOpen(0) then
		CloseAllBags()
	else
		ToggleBag(0)
	end
end
function ToggleBag(id)
	if id == KEYRING_CONTAINER and not GetCVarBool("showKeyring") then return end
	if not ContainerFrame_AllowedToOpenBags() then return end
	if combined(id) then
		if IsBagOpen(0) then ContainerFrameCombinedBags:Hide() else OpenBackpack() end
	elseif IsBagOpen(id) then
		if id == 0 then CloseAllBags() else frameFor(id):Hide() end
	else
		frameFor(id):Show()
	end
end
local function openAllInternal()
	OpenBackpack()
	for i = combined() and 5 or 1, NUM_TOTAL_BAG_FRAMES do OpenBag(i) end
end
function OpenAllBags(frame)
	if not ContainerFrame_AllowedToOpenBags() or IsAnyBagOpen() then return end
	if frame and not opener then opener = frame:GetName() end
	openAllInternal()
end
function ToggleAllBags()
	if not ContainerFrame_AllowedToOpenBags() then return end
	local open, total = 0, 1
	if IsBagOpen(0) then open = open + 1; CloseBackpack() end
	if IsBagOpen(KEYRING_CONTAINER) then open = open + 1; CloseBag(KEYRING_CONTAINER) end
	for i = 1, NUM_TOTAL_BAG_FRAMES do
		if not combined(i) then
			if C_Container.GetContainerNumSlots(i) > 0 then total = total + 1 end
			if IsBagOpen(i) then CloseBag(i); open = open + 1 end
		end
	end
	if open < total then openAllInternal() end
end
-- stub.contextBags[bag]: the bags holding an item the waiting spell can take.
stub.contextBags = { [0] = true }
function OpenAllBagsMatchingContext(frame)
	local n = 0
	for i = 0, NUM_TOTAL_BAG_FRAMES do
		if stub.contextBags[i] and not IsBagOpen(i) then OpenBag(i); n = n + 1 end
	end
	if frame and not opener then opener = frame:GetName() end
	return n
end
function CloseAllBags(frame)
	if frame and frame:GetName() ~= opener then return false end
	opener = nil
	local closed = CloseBackpack()
	for i = 1, NUM_TOTAL_BAG_FRAMES do closed = CloseBag(i) or closed end
	return CloseBag(KEYRING_CONTAINER) or closed
end

-- The game's keys and the bag bar (MainMenuBarBagButtons: the backpack button
-- toggles the backpack, shift-click all bags; a bag slot its bag).
stub.bindings.OPENALLBAGS, stub.bindings.TOGGLEBACKPACK, stub.bindings.TOGGLEBAG2 = { "B" }, { "F12" }, { "F10" }
stub.bindingRun.OPENALLBAGS = function() ToggleAllBags() end
stub.bindingRun.TOGGLEBACKPACK = function() ToggleBackpack() end
stub.bindingRun.TOGGLEBAG2 = function() ToggleBag(2) end
function stub.clickBackpack() if IsShiftKeyDown() then ToggleAllBags() else ToggleBackpack() end end
function stub.clickBagSlot(id) ToggleBag(id) end
-- An enchant chosen, waiting for its item (GameEvent.HandleEnchantSpellSelected).
stub.dispatcher = CreateFrame("Frame", "GameEventDispatcher", UIParent)
function stub.selectEnchant() stub.targeting = true; OpenAllBagsMatchingContext(stub.dispatcher) end

---------------------------------------------------------------------------
-- The slot template
---------------------------------------------------------------------------

-- ContainerFrameItemButtonMixin, as far as our wells reach it. Its methods
-- live in the button's lookup, not on the button, so a key written over one
-- shows. Addon code (Polestar_UI) writing a key the mixin reads, calling
-- SetBagID, or replacing one of the template's scripts errors: the click
-- would then run tainted and the client block its use (bags.md, Taint). As
-- in the live client, the template's own RegisterForClicks does not take on
-- a button addon code makes: it takes only left-ups until we register.
local function ours(level)
	local info = debug.getinfo(level + 1, "S")
	return info and stub.addonSources[info.source] == "Polestar_UI"
end
local Mixin = {}
function Mixin:GetBagID() return rawget(self, "bagID") or self:GetParent():GetID() end
function Mixin:SetBagID(id)
	if ours(2) then error("Polestar: UI called SetBagID on a bag slot (it writes bagID from our code)", 2) end
	rawset(self, "bagID", id)
end
function ContainerFrameItemButton_OnClick(self, button)
	local bag, slot = self:GetBagID(), self:GetID()
	if button == "LeftButton" and not SpellCanTargetItem() then return C_Container.PickupContainerItem(bag, slot) end
	C_Container.UseContainerItem(bag, slot)
end
function Mixin:OnClick(button)
	if IsModifiedClick() then return self:OnModifiedClick(button) end
	ContainerFrameItemButton_OnClick(self, button)
end
function Mixin:OnModifiedClick(button)
	stub.bagModified = button
	HandleModifiedItemClick(C_Container.GetContainerItemLink(self:GetBagID(), self:GetID()))
end
function Mixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	C_NewItems.RemoveNewItem(self:GetBagID(), self:GetID())
	GameTooltip:SetBagItem(self:GetBagID(), self:GetID())
	EventRegistry:TriggerEvent("ContainerFrameItemButton.EnterButton", self)
end
function Mixin:OnLeave() GameTooltip:Hide() end
function Mixin:OnDragStart() self:OnClick("LeftButton") end
function Mixin:OnReceiveDrag() self:OnClick("LeftButton") end
function Mixin:UpdateQuestItem(isQuestItem, questID, isActive)
	local t = self.IconQuestTexture
	if questID and not isActive then
		t:SetTexture(TEXTURE_ITEM_QUEST_BANG)
		t:Show()
	elseif questID or isQuestItem then
		t:SetTexture(TEXTURE_ITEM_QUEST_BORDER)
		t:Show()
	else
		t:Hide()
	end
end
-- ItemButtonMixin:SetAlpha (ItemButtonTemplate.lua): the template's own
-- parts fade, never the button, so a well of ours stays as bright.
function Mixin:SetAlpha(a)
	for _, k in ipairs({ "icon", "IconBorder", "IconOverlay", "Stock", "Count" }) do self[k]:SetAlpha(a) end
end
local GUARDED = { bagID = true, SplitStack = true, hasStackSplit = true, containerFrame = true }
local SCRIPTS = { OnClick = true, OnEnter = true, OnLeave = true, OnHide = true, OnDragStart = true, OnReceiveDrag = true, OnAttributeChanged = true, OnLoad = true }
TEXTURE_ITEM_QUEST_BANG = TEXTURE_ITEM_QUEST_BANG or "Interface/ContainerFrame/UI-Icon-QuestBang"
TEXTURE_ITEM_QUEST_BORDER = TEXTURE_ITEM_QUEST_BORDER or "Interface/ContainerFrame/UI-Icon-QuestBorder"

local createFrame = CreateFrame
function CreateFrame(kind, name, parent, template, ...)
	local b = createFrame(kind, name, parent, template, ...)
	if template ~= "ContainerFrameItemButtonTemplate" then return b end
	if not name then error("ContainerFrameItemButtonTemplate: $parentCooldown needs a named button", 2) end
	b:SetSize(37, 37)
	b:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
	b:SetFrameLevel(10)
	b:Hide()
	b.icon = b:CreateTexture(name .. "IconTexture", "BORDER")
	b.IconBorder = b:CreateTexture(nil, "OVERLAY")
	b.IconQuestTexture = b:CreateTexture(name .. "IconQuestTexture", "OVERLAY", nil, 2)
	b.IconQuestTexture:SetAllPoints(b)
	b.IconQuestTexture:Hide()
	for _, k in ipairs({ "NewItemTexture", "BattlepayItemTexture", "flash", "JunkIcon", "UpgradeIcon", "IconOverlay", "Stock", "Count" }) do b[k] = b:CreateTexture(nil, "OVERLAY") end
	b.Cooldown = createFrame("Cooldown", name .. "Cooldown", b, "CooldownFrameTemplate")
	b.Cooldown:SetAllPoints(b)
	for s in pairs(SCRIPTS) do if Mixin[s] then b:SetScript(s, Mixin[s]) end end
	local base = getmetatable(b).__index
	rawset(b, "SetScript", function(self, script, fn)
		if SCRIPTS[script] and ours(2) then error("Polestar: UI replaced the bag slot's " .. script .. " (HookScript it)", 2) end
		return stub.Methods.SetScript(self, script, fn)
	end)
	setmetatable(b, {
		__index = function(t, k)
			local v = Mixin[k]
			if v ~= nil then return v end
			return base(t, k)
		end,
		__newindex = function(t, k, v)
			if (Mixin[k] or GUARDED[k]) and ours(2) then error("Polestar: UI wrote the key " .. tostring(k) .. " on a bag slot", 2) end
			rawset(t, k, v)
		end,
	})
	return b
end

stub.money = stub.money or 1234567
GetMoney = GetMoney or function() return stub.money end
