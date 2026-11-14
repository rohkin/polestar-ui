-- The game's action bars as the client builds them on Forever
-- (Blizzard_ActionBar: Mainline/ActionButtonTemplate.xml, Shared/ActionBar.lua,
-- MultiActionBars.xml, PetActionBar.xml, StanceBar.xml, SpellFlyout.xml):
-- each bar an Edit Mode system holding a container per button, each button
-- named as ActionBarMixin names it, with ActionButtonTemplate's regions (the
-- icon under its IconMask, SlotBackground and SlotArt, the frame as its
-- NormalTexture, PushedTexture, HighlightTexture, CheckedTexture, the
-- equipped Border, Flash, the HotKey and Count on its text overlay, the
-- macro Name). Colour textures and Polestar's ring and disc glyphs stand in
-- for the atlases (the icon mask drawn as a disc). Every bar, container,
-- button and region is guarded (stub_editmode.lua). Edit Mode's bar settings
-- (icon size, rows, Hide Bar Art) as EditModeActionBarSystemMixin applies
-- them; the spell flyout's buttons made on first open.

require("stub_editmode")

local M = stub.Methods
local DISC = "Interface\\AddOns\\Polestar\\Media\\UI\\circle"
local RING = "Interface\\AddOns\\Polestar\\Media\\UI\\skin-ring"
local CALLS = stub.SYSTEM_CALLS

-- Button states and masks as the client keeps them.
function M.GetButtonState(self) return self.buttonState or "NORMAL" end
function M.SetButtonState(self, s)
	self.buttonState = s
	if self.pushedTexture then self.pushedTexture:SetShown(s == "PUSHED") end
end
function M.GetCheckedTexture(self) return self.checkedTexture end
function M.RemoveMaskTexture(self, m)
	if self.mask ~= m then error("RemoveMaskTexture: not a mask of this texture", 2) end
	self.mask = nil
end
function M.AddMaskTexture(self, m)
	if self.mask == m then error("AddMaskTexture: already masked", 2) end
	self.mask = m
end

local function color(f, layer, r, g, b, a, sub)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetColorTexture(r, g, b, a or 1)
	return t
end
local function glyph(f, layer, file, r, g, b, a, sub)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetTexture(file)
	t:SetVertexColor(r, g, b, a or 1)
	return t
end
local function text(f, s, size, flags, r, g, b)
	local fs = f:CreateFontString(nil, "OVERLAY")
	fs:SetFont(STANDARD_TEXT_FONT, size, flags or "")
	fs:SetTextColor(r or 1, g or 1, b or 1)
	fs:SetText(s)
	return fs
end

local ICONS = { { 0.75, 0.3, 0.2 }, { 0.3, 0.5, 0.85 }, { 0.85, 0.7, 0.25 }, { 0.4, 0.7, 0.35 }, { 0.6, 0.35, 0.75 }, { 0.3, 0.65, 0.7 } }
local KEYS = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=" }

-- One button: ActionButtonTemplate's regions, sized as the template (45,
-- or SmallActionButtonTemplate's 30). `slot` filled when an icon is given.
local function button(name, parent, size, i, filled)
	local b = CreateFrame("CheckButton", name, parent)
	b:SetSize(size, size)
	b:SetPoint("CENTER", parent, "CENTER", 0, 0)
	b.icon = color(b, "BACKGROUND", 0, 0, 0, 1)
	b.icon:SetAllPoints(b)
	local c = ICONS[(i - 1) % #ICONS + 1]
	if filled then b.icon:SetColorTexture(c[1], c[2], c[3], 1) else b.icon:Hide() end
	b.IconMask = b:CreateMaskTexture()
	b.IconMask:SetAllPoints(b)
	b.IconMask:SetTexture(DISC)
	b.icon:AddMaskTexture(b.IconMask)
	b.SlotBackground = color(b, "BACKGROUND", 0.12, 0.1, 0.08, 1, 1)
	b.SlotBackground:SetAllPoints(b)
	b.SlotBackground:Hide()
	b.SlotArt = color(b, "BACKGROUND", 0.2, 0.16, 0.1, 1, -1)
	b.SlotArt:SetAllPoints(b)
	b.Flash = color(b, "ARTWORK", 1, 0, 0, 0.5, 1)
	b.Flash:SetAllPoints(b)
	b.Flash:Hide()
	b.Border = color(b, "OVERLAY", 0, 1, 0, 0.5)
	b.Border:SetAllPoints(b)
	b.Border:Hide()
	b.Name = text(b, "", 10, "OUTLINE")
	b.Name:SetPoint("BOTTOM", b, "BOTTOM", 0, 2)
	b.NormalTexture = glyph(b, "OVERLAY", RING, 0.7, 0.58, 0.32, 1)
	b.NormalTexture:SetAllPoints(b)
	b:SetNormalTexture(b.NormalTexture)
	b.PushedTexture = glyph(b, "OVERLAY", RING, 1, 0.9, 0.5, 1)
	b.PushedTexture:SetAllPoints(b)
	b.PushedTexture:Hide()
	b:SetPushedTexture(b.PushedTexture)
	b.HighlightTexture = glyph(b, "HIGHLIGHT", RING, 1, 1, 1, 0.6)
	b.HighlightTexture:SetAllPoints(b)
	b:SetHighlightTexture(b.HighlightTexture)
	b.CheckedTexture = glyph(b, "OVERLAY", DISC, 1, 0.9, 0.4, 0.35, 2)
	b.CheckedTexture:SetAllPoints(b)
	b.CheckedTexture:SetAtlas("UI-HUD-ActionBar-IconFrame-Mouseover")
	b:SetCheckedTexture(b.CheckedTexture)
	local overlay = CreateFrame("Frame", nil, b)
	overlay:SetAllPoints(b)
	overlay:SetFrameLevel(500)
	b.TextOverlayContainer = overlay
	b.HotKey = text(overlay, KEYS[i] or "", 12, "OUTLINE", 0.6, 0.6, 0.6)
	b.HotKey:SetPoint("TOPRIGHT", b, "TOPRIGHT", -4, -5)
	b.Count = text(overlay, "", 12, "OUTLINE")
	b.Count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -5, 5)
	stub.secureNames[name] = true
	return b
end

stub.bars = {}
-- A bar: its containers laid out in rows (Edit Mode's rows and icon size).
local function layout(bar)
	local per = math.ceil(bar.numButtons / bar.rows)
	for i, c in ipairs(bar.containers) do
		local col, row = (i - 1) % per, math.floor((i - 1) / per)
		c:ClearAllPoints()
		if bar.vertical then
			c:SetPoint("TOPLEFT", bar, "TOPLEFT", row * (bar.size + 2), -col * (bar.size + 2))
		else
			c:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", col * (bar.size + 2), row * (bar.size + 2))
		end
	end
	local scale = bar.containers[1]:GetScale()
	local long, short = per * (bar.size + 2) * scale, bar.rows * (bar.size + 2) * scale
	if bar.vertical then bar:SetSize(short, long) else bar:SetSize(long, short) end
end

local function bar(name, prefix, n, size, filled, vertical)
	local f = CreateFrame("Frame", name, UIParent)
	f.numButtons, f.rows, f.size, f.vertical = n, 1, size, vertical
	f.containers, f.actionButtons = {}, {}
	for i = 1, n do
		local c = CreateFrame("Frame", name .. "ButtonContainer" .. i, f)
		c:SetSize(size, size)
		f.containers[i] = c
		local b = button(prefix .. i, c, size, i, filled(i))
		b.bar, b.container = f, c
		f.actionButtons[i] = b
	end
	layout(f)
	stub.secureNames[name] = true
	stub.bars[name] = f
	return f
end

local main = bar("MainActionBar", "ActionButton", 12, 45, function(i) return i <= 10 end)
main:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 20)
local left = bar("MultiBarBottomLeft", "MultiBarBottomLeftButton", 12, 45, function(i) return i % 3 ~= 0 end)
left:SetPoint("BOTTOMLEFT", main, "TOPLEFT", 0, 4)
local right = bar("MultiBarRight", "MultiBarRightButton", 12, 45, function(i) return i <= 6 end, true)
right.rows = 2
layout(right)
right:SetPoint("BOTTOMLEFT", main, "BOTTOMRIGHT", 8, 0)
local pet = bar("PetActionBar", "PetActionButton", 10, 30, function(i) return i <= 7 end)
pet:SetPoint("BOTTOMLEFT", left, "TOPLEFT", 0, 4)
local stance = bar("StanceBar", "StanceButton", 3, 30, function() return true end)
stance:SetPoint("BOTTOMLEFT", pet, "BOTTOMRIGHT", 16, 0)
-- A pet button and the main bar's tenth with a count and a macro name; the
-- first stance on (checked); an equipped item (the game's green border).
StanceButton1:SetChecked(true)
ActionButton10.Count:SetText("20")
-- The eleventh has no binding: the game writes its range dot (ActionButton.lua).
RANGE_INDICATOR = "●"
ActionButton11.HotKey:SetText(RANGE_INDICATOR)
ActionButton9.Name:SetText("Heal")
ActionButton8.Border:SetVertexColor(0, 1, 0, 0.5)
ActionButton8.Border:Show()

-- The spell flyout: its buttons (SmallActionButtonTemplate) made the first
-- time it opens, over a button.
local flyout = CreateFrame("Frame", "SpellFlyout", UIParent)
flyout:SetFrameStrata("DIALOG")
flyout:Hide()
stub.secureNames.SpellFlyout = true
function stub.openFlyout(owner, n)
	flyout:ClearAllPoints()
	flyout:SetPoint("BOTTOM", owner, "TOP", 0, 4)
	flyout:SetSize(30, n * 32)
	for i = 1, n do
		if not _G["SpellFlyoutPopupButton" .. i] then
			local b = button("SpellFlyoutPopupButton" .. i, flyout, 28, i + 2, true)
			b:ClearAllPoints()
			b:SetPoint("BOTTOM", flyout, "BOTTOM", 0, (i - 1) * 32)
			b.HotKey:SetText("")
			stub.guardButton(b)
		end
	end
	flyout:Show()
end

-- Every bar and container a system frame's guard, every button and region too.
function stub.guardButton(b)
	stub.guard(b, CALLS)
	for _, k in ipairs({ "icon", "SlotBackground", "SlotArt", "Flash", "Border", "Name", "NormalTexture", "PushedTexture",
		"HighlightTexture", "CheckedTexture", "HotKey", "Count" }) do
		stub.guard(b[k], nil, b:GetName() .. "." .. k)
	end
	stub.guard(b.TextOverlayContainer, CALLS, b:GetName() .. ".TextOverlayContainer")
end
for _, f in pairs(stub.bars) do
	stub.guard(f, CALLS)
	for i, c in ipairs(f.containers) do
		stub.guard(c, CALLS)
		stub.guardButton(f.actionButtons[i])
	end
end
stub.guard(flyout, CALLS)

-- Edit Mode's bar settings, as EditModeActionBarSystemMixin applies them:
-- icon size scales each container, rows lay them out again, Hide Bar Art
-- runs each button's UpdateButtonArt (Mainline/ActionButtonOverrides.lua:
-- the slot background for the slot art).
function stub.editBar(name, o)
	local f = stub.bars[name]
	if o.iconSize then for _, c in ipairs(f.containers) do c:SetScale(o.iconSize / 100) end end
	if o.rows then f.rows = o.rows end
	if o.hideArt ~= nil then
		for _, b in ipairs(f.actionButtons) do
			b.SlotArt:SetShown(not o.hideArt)
			b.SlotBackground:SetShown(o.hideArt)
			b.NormalTexture:SetAtlas(o.hideArt and "UI-HUD-ActionBar-IconFrame-AddRow" or "UI-HUD-ActionBar-IconFrame")
		end
	end
	layout(f)
	stub.exitEditMode()
end
