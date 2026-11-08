-- The Character window (docs/DESIGN.md, "Character"): the stock CharacterFrame's
-- sections in a Polestar shell. 4a: the shell, its sections and the doors in.

local ADDON, ns = ...
local W = Polestar.Widgets

local NAME = "PolestarUICharacter"
-- The stock subframes, in stock order; their keys are what ToggleCharacter takes.
-- shortcut: Currency is always listed; hide it via ShouldShowCurrencyTab when its page is built (4e).
local SECTIONS = {
	{ key = "PaperDollFrame", label = CHARACTER or "Character", icon = "icon-level" },
	{ key = "ReputationFrame", label = REPUTATION or "Reputation", icon = "icon-rep" },
	{ key = "TokenFrame", label = CURRENCY or "Currency", icon = "qol-coin" },
	{ key = "PVPRankFrame", label = PVP or "Honor", icon = "flag" },
	{ key = "SkillsFrame", label = SKILLS or "Skills", icon = "icon-skill" },
}
local TABS = { { key = "gear", label = "Gear" }, { key = "stats", label = "Stats" } }

local f, section, tab = nil, "PaperDollFrame", "gear"
local M = {}

---------------------------------------------------------------------------
-- Gear: the slot tiles (docs/DESIGN.md, "Slot Tile"), in the stock columns.

local SLOT, GAP = 40, 6
local LEFT = { "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot" }
local RIGHT = { "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot" }
local WEAPONS = { "MainHandSlot", "SecondaryHandSlot", "RangedSlot", "AmmoSlot" }
local slots = {}

local function qualityRGB(q)
	if C_Item and C_Item.GetItemQualityColor then
		local ok, r, g, b = pcall(C_Item.GetItemQualityColor, q)
		if ok and type(r) == "number" then return r, g, b end
	end
	local t = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
	if t then return t.r, t.g, t.b end
end

local function paintSlot(s)
	local id = s:GetID()
	local icon = GetInventoryItemTexture("player", id)
	s.Icon:SetTexture(icon or s.psEmpty)
	s.Icon:SetDesaturated(not icon)
	s.Icon:SetAlpha(icon and 1 or 0.6)
	local cur, max = GetInventoryItemDurability(id)
	local broken = icon and GetInventoryItemBroken("player", id)
	local r, g, b, a
	if broken or (cur and max and max > 0 and cur == 0) then
		r, g, b = Polestar.Theme.Color("danger"); a = 1
	elseif cur and max and max > 0 and cur / max < 0.25 then
		r, g, b = Polestar.Theme.Color("warning"); a = 1
	else
		local q = icon and GetInventoryItemQuality("player", id)
		-- Common and poor items wear the hairline, as an empty slot does.
		if q and q >= 2 then r, g, b = qualityRGB(q); a = 0.9 end
	end
	if not r then r, g, b, a = Polestar.Theme.Wash("border") end
	Polestar.Theme.Border(s, r, g, b, a)
end

local function slotEnter(s)
	GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
	if not GameTooltip:SetInventoryItem("player", s:GetID()) then
		GameTooltip:SetText(s.psLabel)
	end
	GameTooltip:Show()
end

-- Left: pick up or put down (the stock slot's own call, unprotected); with a
-- modifier, the client's linking and try-on handling.
-- shortcut: right-click "use" is left out (UseInventoryItem is protected); add a secure item button when needed.
local function slotClick(s, button)
	local link = GetInventoryItemLink("player", s:GetID())
	if link and IsModifiedClick() and HandleModifiedItemClick(link) then return end
	if button == "LeftButton" then PickupInventoryItem(s:GetID()) end
end

local function newSlot(parent, name)
	local id, empty = C_PaperDollInfo.GetInventorySlotInfo(name)
	local s = CreateFrame("Button", nil, parent)
	s:SetID(id)
	s:SetSize(SLOT, SLOT)
	s.psEmpty = empty
	s.psLabel = _G[name:upper()] or name
	W.Fill(s, "scrim", "BACKGROUND", 0)
	s.Icon = s:CreateTexture(nil, "ARTWORK")
	s.Icon:SetPoint("TOPLEFT", 1, -1)
	s.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
	W.Hover(s)
	s:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	s:RegisterForDrag("LeftButton")
	s:SetScript("OnClick", slotClick)
	s:SetScript("OnDragStart", function(self) PickupInventoryItem(self:GetID()) end)
	s:SetScript("OnReceiveDrag", function(self) PickupInventoryItem(self:GetID()) end)
	s:SetScript("OnEnter", slotEnter)
	s:SetScript("OnLeave", W.HideTooltip)
	slots[#slots + 1] = s
	return s
end

-- The two columns on the body's edges, the weapons centred under them.
local function buildGear(body, width)
	local v = CreateFrame("Frame", nil, body)
	v:SetPoint("TOPLEFT", body, "TOPLEFT", 32, -24)
	v:SetSize(width, #LEFT * (SLOT + GAP) - GAP + 16 + SLOT)
	for i, name in ipairs(LEFT) do newSlot(v, name):SetPoint("TOPLEFT", v, "TOPLEFT", 0, -(i - 1) * (SLOT + GAP)) end
	for i, name in ipairs(RIGHT) do newSlot(v, name):SetPoint("TOPRIGHT", v, "TOPRIGHT", 0, -(i - 1) * (SLOT + GAP)) end
	local row = #WEAPONS * (SLOT + GAP) - GAP
	for i, name in ipairs(WEAPONS) do
		newSlot(v, name):SetPoint("BOTTOMLEFT", v, "BOTTOM", -row / 2 + (i - 1) * (SLOT + GAP), 0)
	end
	return v
end

local function paintGear()
	for _, s in ipairs(slots) do paintSlot(s) end
end

local function build()
	f = W.Shell(NAME, {})
	-- The subject block names the window, in place of Polestar's lockup.
	-- Reparented, not hidden: the shell re-shows its version line on every show.
	local holder = CreateFrame("Frame", nil, f)
	holder:Hide()
	for _, r in ipairs({ f.Emblem, f.Emblem.Glow, f.Emblem.Hot, f.Wordmark, f.Tagline, f.Search, f.Status, f.Stage }) do r:SetParent(holder) end
	f.psName = W.Text(f.Sidebar, "title", "text")
	f.psName:SetPoint("BOTTOMLEFT", f.Sidebar, "TOPLEFT", 24, -47)
	f.psLine = W.Text(f.Sidebar, "small", "textDim")
	f.psLine:SetPoint("TOPLEFT", f.psName, "BOTTOMLEFT", 0, -6)
	f.psGear = buildGear(f.Body, f.BodyWidth)
	Polestar.CloseOnEscape(NAME)
end

local function refresh()
	local level, race = UnitLevel("player"), UnitRace("player")
	f.psName:SetText(UnitName("player"))
	f.psLine:SetText(("Level %d %s"):format(level, UnitClass("player")))
	W.ShellNav(f, SECTIONS, section, function(k) M.Show(k) end)
	if section == "PaperDollFrame" then
		W.ShellTabs(f, TABS, tab, function(k) tab = k; refresh() end)
		W.ShellTitle(f, UnitPVPName("player") or UnitName("player"), ("Level %d %s %s"):format(level, race, UnitClass("player")))
	else
		W.ShellTabs(f, nil)
		for _, s in ipairs(SECTIONS) do
			if s.key == section then W.ShellTitle(f, s.label) end
		end
	end
	W.ShellFooter(f, {}, {})
	local gear = section == "PaperDollFrame" and tab == "gear"
	f.psGear:SetShown(gear)
	if gear then paintGear() end
	W.ShellBody(f, gear and f.psGear:GetHeight() + 48 or 0)
end

function M.Show(key)
	if not f then build() end
	section = key or section
	refresh()
	f:Show()
end

function M.Toggle(key, onlyShow)
	if f and f:IsShown() and (key == nil or key == section) and not onlyShow then
		f:Hide()
	else
		M.Show(key)
	end
end

function M.Enable()
	-- Every stock door (TOGGLECHARACTER0/2/4, the micro button) calls
	-- ToggleCharacter; it has just shown CharacterFrame, which we close again.
	-- Hide(), not HideUIPanel: that dispatches to a forbidden frame, which does
	-- nothing from addon code; the panel manager repairs a frame hidden this
	-- way before it places the next panel (FramePositionDelegate:ShowUIPanel).
	hooksecurefunc("ToggleCharacter", function(key, onlyShow)
		if CharacterFrame and CharacterFrame:IsShown() then CharacterFrame:Hide() end
		M.Toggle(key, onlyShow)
	end)
	local function changed()
		if f and f:IsShown() and f.psGear:IsShown() then paintGear() end
	end
	Polestar.RegisterEvent("PLAYER_EQUIPMENT_CHANGED", changed)
	Polestar.RegisterEvent("UNIT_INVENTORY_CHANGED", function(_, unit) if unit == "player" then changed() end end)
end

ns.Module("character", M)
