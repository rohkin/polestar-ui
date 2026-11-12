-- The Loot (docs/windows/loot.md): a small Polestar panel for the open loot.
-- The stock LootFrame ends the loot as it hides (CloseLoot), so it is never
-- opened: its own LOOT_OPENED is unregistered (docs/CLIENT.md, rule 15's
-- exception) and ours opens on it. LootSlot is plain Lua, not protected.
-- Auto-loot (the CVar and its modifier) is the game's: it loots the slots
-- itself and ours shows them clearing, as the stock window. Group rolls
-- (GroupLootFrame) and the bind and roll confirms (StaticPopups shown by
-- GameEvent) stay the game's. Master loot's menu is ours: the stock one reads
-- the clicked slot off LootFrame, which only the stock row writes.

local ADDON, ns = ...
local W = Polestar.Widgets
local Theme = Polestar.Theme

local NAME = "PolestarUILoot"
local WIDTH, ROW_H, ICON, TOP, PAD = 240, 40, 32, 52, 12

local QUEST_BANG = TEXTURE_ITEM_QUEST_BANG or "Interface\\ContainerFrame\\UI-Icon-QuestBang"
local QUEST_BORDER = TEXTURE_ITEM_QUEST_BORDER or "Interface\\ContainerFrame\\UI-Icon-QuestBorder"
local secret = issecretvalue or function() return false end

local f
local rows, cleared = {}, {}
local picked -- the row last clicked, for master loot's menu (the stock LootFrame.selectedSlot)
local ended -- the game closed the loot: hiding ours must not close it again
local M = { reloadOff = true }

local function enter(r)
	local t = ns.Clean(GetLootSlotType(r.psSlot))
	if t ~= Enum.LootSlotType.Item and t ~= Enum.LootSlotType.Currency then return end
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	if t == Enum.LootSlotType.Currency then GameTooltip:SetLootCurrency(r.psSlot) else GameTooltip:SetLootItem(r.psSlot) end
	GameTooltip:Show()
	-- The dress-up cursor while its modifier is down, as the stock row.
	if CursorUpdate then CursorUpdate(r) end
end

local function leave()
	W.HideTooltip()
	if ResetCursor then ResetCursor() end
end

-- As the stock row's OnUpdate: the tooltip again while it is ours (a
-- modifier pressed shows the comparison), and the cursor kept in step.
local function update(r)
	if GameTooltip:GetOwner() ~= r then return end
	enter(r)
	if CursorOnUpdate then CursorOnUpdate(r) end
end

-- As the stock row: a modified click links (Polestar's HandleModifiedItemClick hook sees it), else loots.
local function click(r)
	if IsModifiedClick() then return HandleModifiedItemClick(ns.Clean(GetLootSlotLink(r.psSlot))) end
	picked = r
	LootSlot(r.psSlot)
end

-- Master loot (GroupLootFrame_OnLoad's menu, the gamepad one with the
-- candidates in it): Assign Loot, by class in a raid, and Request Roll. An
-- item of the threshold quality or better asks first (CONFIRM_LOOT_DISTRIBUTION).
local function give(slot, p)
	local _, name, _, _, q = GetLootSlotInfo(slot)
	name, q = ns.Clean(name), ns.Clean(q)
	local min = Constants and Constants.LootConsts and Constants.LootConsts.MasterLootQualityThreshold or 2
	if not (q and q >= min) then return GiveMasterLoot(slot, p.index) end
	local col = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
	local item = col and col.hex and (col.hex .. (name or "") .. "|r") or name or ""
	W.Modal({ title = MASTER_LOOTER or "Master Looter", text = (CONFIRM_LOOT_DISTRIBUTION or "You wish to assign %s to %s. Is this correct?"):format(item, p.name),
		action = YES or "Yes", onAccept = function() GiveMasterLoot(slot, p.index) end })
end
local function masterMenu()
	local r = picked
	if not (r and r:IsShown() and f:IsShown()) then return end
	local slot, players = r.psSlot, {}
	for i = 1, MAX_RAID_MEMBERS or 40 do
		local name, class, className = GetMasterLootCandidate(slot, i)
		if name then players[#players + 1] = { index = i, name = name, class = class or "", className = className } end
	end
	table.sort(players, function(a, b) if a.class == b.class then return a.name < b.name end return a.class < b.class end)
	local function colored(text, className)
		local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[className]
		if not c then return text end
		return ("|c%s%s|r"):format(c.colorStr or ("ff%02x%02x%02x"):format(c.r * 255, c.g * 255, c.b * 255), text)
	end
	MenuUtil.CreateContextMenu(r, function(_, root)
		root:SetTag("MENU_GROUP_LOOT")
		root:CreateTitle(MASTER_LOOTER or "Master Looter")
		local assign = root:CreateButton(ASSIGN_LOOT or "Assign Loot")
		local list, class = assign, nil
		for _, p in ipairs(players) do
			if IsInRaid() and p.class ~= class then
				class = p.class
				list = assign:CreateButton(colored(p.class, p.className), function() end)
			end
			list:CreateButton(colored(p.name, p.className), function() give(slot, p) end)
		end
		root:CreateButton(REQUEST_ROLL or "Request Roll", function() DoMasterLootRoll(slot) end)
	end)
end

local function newRow(n)
	local r = CreateFrame("Button", nil, f)
	r:SetSize(WIDTH - 2 * PAD + 8, ROW_H)
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	W.Hover(r)
	r.Well = ns.ItemWell(r, ICON)
	r.Well:SetPoint("LEFT", r, "LEFT", 4, 0)
	-- A quest item's mark over its icon, as the stock IconQuestTexture.
	r.Quest = r.Well:CreateTexture(nil, "OVERLAY")
	r.Quest:SetAllPoints(r.Well)
	r.Name = W.Text(r, "label", "text")
	-- A name the client hands over secret (combat) goes in a string on a game
	-- font: ours take no secret (docs/CLIENT.md, rule 3).
	r.Raw = r:CreateFontString(nil, "ARTWORK")
	r.Raw:SetFontObject(GameFontNormal)
	-- The quality under the name, as the stock tag ("Uncommon").
	r.Quality = W.Text(r, "small", "textMuted")
	r.Quality:SetPoint("TOPLEFT", r.Well, "RIGHT", 10, -2)
	for _, t in ipairs({ r.Name, r.Raw, r.Quality }) do
		t:SetPoint("RIGHT", r, "RIGHT", -4, 0)
		t:SetJustifyH("LEFT")
	end
	r:SetScript("OnClick", click)
	r:SetScript("OnEnter", enter)
	r:SetScript("OnLeave", leave)
	r:SetScript("OnUpdate", update)
	rows[n] = r
	return r
end

local function paint()
	f.Title:SetText(IsFishingLoot() and "Fishing" or "Loot")
	local n = 0
	for slot = 1, GetNumLootItems() do
		local icon, name, count, currencyID, quality, locked, isQuestItem, questID, isActive, isCoin = GetLootSlotInfo(slot)
		if (secret(icon) or icon) and not cleared[slot] then
			n = n + 1
			local r = rows[n] or newRow(n)
			r.psSlot = slot
			r:SetPoint("TOPLEFT", f, "TOPLEFT", PAD - 4, -(TOP + (n - 1) * ROW_H))
			isCoin = ns.Clean(isCoin)
			-- A currency container shows what it holds, as the stock row.
			if ns.Clean(currencyID) and CurrencyContainerUtil and not (secret(name) or secret(count) or secret(quality) or secret(icon)) then
				name, icon, count, quality = CurrencyContainerUtil.GetCurrencyContainerInfo(currencyID, count, name, icon, quality)
			end
			quality = not isCoin and ns.Clean(quality) or nil
			ns.PaintItem(r.Well, { icon = icon, quality = quality, count = ns.Num(count), unusable = ns.Clean(locked) })
			questID = ns.Clean(questID)
			local mark = questID and not ns.Clean(isActive) and QUEST_BANG or (questID or ns.Clean(isQuestItem)) and QUEST_BORDER or nil
			r.Quest:SetTexture(mark)
			r.Quest:SetShown(mark ~= nil)
			local tag = quality and _G["ITEM_QUALITY" .. quality .. "_DESC"]
			r.Quality:SetText(tag or "")
			-- The name over its tag, else in the row's middle. A coin slot's name
			-- is the game's money text, a line per coin ("1 Silver\n50 Copper").
			local text = secret(name) and r.Raw or r.Name
			for _, t in ipairs({ r.Name, r.Raw }) do
				t:ClearAllPoints()
				t:SetPoint("RIGHT", r, "RIGHT", -4, 0)
				if tag then t:SetPoint("BOTTOMLEFT", r.Well, "RIGHT", 10, 1) else t:SetPoint("LEFT", r.Well, "RIGHT", 10, 0) end
				t:SetWordWrap(isCoin and true or false)
				t:SetShown(t == text)
			end
			text:SetText(name or "")
			if text == r.Name then
				W.Uncolor(r.Name)
				local qr, qg, qb = ns.QualityRGB(quality)
				if qr then r.Name:SetTextColor(Theme.Legible(qr, qg, qb)) else W.Color(r.Name, "text") end
			end
			r:Show()
		end
	end
	for i = n + 1, #rows do rows[i]:Hide() end
	f:SetHeight(TOP + math.max(n, 1) * ROW_H + PAD)
end

local function build()
	f = CreateFrame("Frame", NAME, UIParent)
	f:SetWidth(WIDTH)
	f:SetFrameStrata("HIGH")
	f:SetClampedToScreen(true)
	f:EnableMouse(true)
	Theme.Skin(f, "window")
	f.Title = W.Text(f, "heading", "text")
	f.Title:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + 4, -18)
	f.Close = W.IconButton(f, "close", 28, "Close", function() f:Hide() end, 14)
	f.Close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)
	f.psRows = rows
	f:Hide()
	f:SetScript("OnHide", function()
		if not ended then CloseLoot() end
		ended = nil
	end)
	Polestar.CloseOnEscape(NAME)
end

-- At the cursor with lootUnderMouse, as LootFrameMixin:Open places it.
local function place()
	f:ClearAllPoints()
	if GetCVarBool("lootUnderMouse") then
		local x, y = GetCursorPosition()
		local s = f:GetEffectiveScale()
		f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s - 30, math.max(y / s + 50, 350))
	elseif LootFrame and LootFrame.systemInfo and LootFrame.systemInfo.isInDefaultPosition == false and LootFrame:GetPoint(1) then
		-- Moved in Edit Mode: where the layout put the stock frame (its
		-- ApplySystemAnchor runs at load, shown or not), read off it, never written.
		local p, rel, rp, x, y = LootFrame:GetPoint(1)
		local k = LootFrame:GetScale() / f:GetScale()
		f:SetPoint(p, rel or UIParent, rp, x * k, y * k)
	else
		-- The stock default: a UI panel in the left slot.
		f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
	end
end

-- Shown only on the game's LOOT_OPENED: with no loot open there is nothing to show.
function M.Show()
	if not f then build() end
	place()
	paint()
	f:Show()
	f:Raise()
end

function M.Enable()
	if not f then build() end
	-- The stock window's own open, stopped (docs/CLIENT.md, rule 15's exception).
	if LootFrame then LootFrame:UnregisterEvent("LOOT_OPENED") end
	Polestar.RegisterEvent("LOOT_OPENED", function(_, _, fromItem)
		cleared, ended, picked = {}, nil, nil
		M.Show()
		if fromItem then PlaySound(SOUNDKIT.UI_CONTAINER_ITEM_OPEN)
		elseif IsFishingLoot() then PlaySound(SOUNDKIT.FISHING_REEL_IN)
		elseif GetNumLootItems() == 0 then PlaySound(SOUNDKIT.LOOT_WINDOW_OPEN_EMPTY) end
	end)
	-- The stock GroupLootFrame opens its own menu first (at the cursor, with
	-- no slot to act on); ours, a frame later, takes its place.
	Polestar.RegisterEvent("OPEN_MASTER_LOOT_LIST", function() C_Timer.After(0, masterMenu) end)
	Polestar.RegisterEvent("LOOT_SLOT_CLEARED", function(_, slot)
		cleared[slot] = true
		if f:IsShown() then paint() end
	end)
	Polestar.RegisterEvent("LOOT_SLOT_CHANGED", function() if f:IsShown() then paint() end end)
	Polestar.RegisterEvent("LOOT_CLOSED", function()
		if not f:IsShown() then return end
		ended = true
		f:Hide()
	end)
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return LootFrame and LootFrame:IsShown() and LootFrame end

ns.Module("loot", M)
