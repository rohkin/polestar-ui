-- The game's bag bar as Forever builds it (Blizzard_MainMenuBarBagButtons:
-- Camelot MainMenuBarBagButtons.xml/.lua, Mainline
-- MainMenuBarBagButtonTemplates.xml, Shared BagsBar.lua): BagsBar (an Edit
-- Mode system, its frame art BorderArt) holding the backpack, four bag
-- slots, the reagent bag and the keyring, each with BaseBagSlotButtonTemplate's
-- regions (icon under SquareMask, the frame as normal and pushed textures,
-- the hover, SlotHighlightTexture, Count; the backpack's FreeSlots).
-- UpdateTextures (each icon change) sets the frame atlases again and the
-- hover's alpha to 0.4 (stub.bagUpdateTextures). Clicks are the game's
-- toggles. Everything is guarded (stub_editmode.lua).

require("stub_editmode")

local M = stub.Methods
local CALLS = stub.SYSTEM_CALLS
local DISC = "Interface\\AddOns\\Polestar\\Media\\UI\\circle"
M.GetButtonState = M.GetButtonState or function(self) return self.buttonState or "NORMAL" end
M.SetButtonState = M.SetButtonState or function(self, s) self.buttonState = s end
M.RemoveMaskTexture = M.RemoveMaskTexture or function(self, m)
	if self.mask ~= m then error("RemoveMaskTexture: not a mask of this texture", 2) end
	self.mask = nil
end

M.GetTexCoord = M.GetTexCoord or function(self) return unpack(self.texCoord or { 0, 1, 0, 1 }) end
-- An icon wears two masks (SquareMask from the template, Mask from
-- ItemButtonMixin:PostOnLoad): a set per icon; `mask` (what the preview
-- draws) is any one still on.
local function masked(t)
	t.masks = {}
	function t:AddMaskTexture(m)
		if self.masks[m] then error("AddMaskTexture: already masked", 2) end
		self.masks[m] = true
		rawset(self, "mask", m)
	end
	function t:RemoveMaskTexture(m)
		if not self.masks[m] then error("RemoveMaskTexture: not a mask of this texture", 2) end
		self.masks[m] = nil
		rawset(self, "mask", (next(self.masks)))
	end
end

local function color(f, layer, r, g, b, a, sub)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetColorTexture(r, g, b, a or 1)
	return t
end
local function text(f, s, size)
	local fs = f:CreateFontString(nil, "OVERLAY")
	fs:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE")
	fs:SetText(s)
	return fs
end

local bar = CreateFrame("Frame", "BagsBar", UIParent)
bar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 60)
bar.BorderArt = color(bar, "BACKGROUND", 0.35, 0.28, 0.16, 1, -3)
bar.BorderArt:SetPoint("TOPLEFT", bar, "TOPLEFT", -6, 6)
bar.BorderArt:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 5, -5)
bar.BorderArt:SetAtlas("UI-HUD-ActionBar-Frame")
stub.secureNames.BagsBar = true

-- Bag id, size, icon colour (the reagent bag green, the keyring grey).
local SLOTS = {
	{ "MainMenuBarBackpackButton", 0, 45, { 0.6, 0.45, 0.25 } }, { "CharacterBag0Slot", 1, 30, { 0.45, 0.3, 0.2 } },
	{ "CharacterBag1Slot", 2, 30, { 0.5, 0.35, 0.3 } }, { "CharacterBag2Slot", 3, 30, { 0.35, 0.3, 0.5 } },
	{ "CharacterBag3Slot", 4, 30 }, { "CharacterReagentBag0Slot", 5, 30, { 0.3, 0.55, 0.3 } },
	{ "KeyRingButton", -2, 30, { 0.5, 0.5, 0.5 } },
}
stub.bagButtons = {}

function stub.bagUpdateTextures(b)
	b:GetNormalTexture():SetAtlas("ui-hud-actionbar-iconframe-bags")
	b:GetPushedTexture():SetAtlas("ui-hud-actionbar-iconframe-bags")
	b:GetHighlightTexture():SetAtlas("ui-hud-actionbar-iconframe-bags")
	b:GetHighlightTexture():SetAlpha(0.4)
end
-- A new bag in the slot (BAG_UPDATE_DELAYED -> PaperDollItemSlotButton_Update ->
-- SetItemButtonTexture_Base): the icon's coords reset, then UpdateTextures.
function stub.bagSetTexture(b)
	b.icon:SetTexCoord(0, 1, 0, 1)
	stub.bagUpdateTextures(b)
end
-- The game's open-bag highlight (ContainerFrame.OpenBag / CloseBag callbacks).
function stub.bagHighlight(b, shown) b.SlotHighlightTexture:SetShown(shown) end

for i, s in ipairs(SLOTS) do
	local b = CreateFrame("Button", s[1], bar)
	b:SetSize(s[3], s[3])
	b:SetID(s[2])
	b.icon = color(b, "BORDER", 0, 0, 0, 1)
	b.icon:SetAllPoints(b)
	if s[4] then b.icon:SetColorTexture(s[4][1], s[4][2], s[4][3], 1) else b.icon:Hide() end
	masked(b.icon)
	b.SquareMask = b:CreateMaskTexture()
	b.SquareMask:SetAllPoints(b)
	b.SquareMask:SetTexture(DISC)
	b.icon:AddMaskTexture(b.SquareMask)
	-- The intrinsic ItemButton's rounded common-iconmask, put on the icon by PostOnLoad.
	b.Mask = b:CreateMaskTexture()
	b.Mask:SetAllPoints(b)
	b.Mask:SetTexture(DISC)
	b.icon:AddMaskTexture(b.Mask)
	b.GetItemButtonIconTexture = function(self) return self.icon end
	local n = color(b, "OVERLAY", 0.7, 0.58, 0.32, 0.8)
	n:SetAllPoints(b)
	b:SetNormalTexture(n)
	local p = color(b, "OVERLAY", 1, 0.9, 0.5, 0.8)
	p:SetAllPoints(b)
	p:Hide()
	b:SetPushedTexture(p)
	local h = color(b, "HIGHLIGHT", 1, 1, 1, 1)
	h:SetAllPoints(b)
	b:SetHighlightTexture(h)
	b.SlotHighlightTexture = color(b, "OVERLAY", 1, 0.85, 0.3, 0.6, 6)
	b.SlotHighlightTexture:SetAllPoints(b)
	b.SlotHighlightTexture:Hide()
	b.Count = text(b, "", 12)
	b.Count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
	if s[2] == 0 then
		b.FreeSlots = text(b, "(31)", 12)
		b.FreeSlots:SetPoint("CENTER", b, "CENTER", 0, -10)
	end
	b:SetScript("OnClick", function()
		if s[2] == 0 then
			if ToggleBackpack then ToggleBackpack() end
		elseif ToggleBag then
			ToggleBag(s[2])
		end
	end)
	stub.bagUpdateTextures(b)
	stub.bagButtons[i] = b
end

-- BagsBarMixin:UpdateDividers (Camelot's useDividers): a pool per
-- orientation (EnumerateActive yields the frames as keys, as ObjectPoolMixin
-- does), released and acquired again with each Layout; a reused divider
-- keeps its alpha.
local function pool()
	local p = { activeObjects = {}, free = {} }
	function p:EnumerateActive() return pairs(self.activeObjects) end
	function p:ReleaseAll()
		for d in pairs(self.activeObjects) do d:Hide(); self.free[#self.free + 1] = d end
		self.activeObjects = {}
	end
	function p:Acquire()
		local d = table.remove(self.free)
		if not d then
			d = CreateFrame("Frame", nil, bar)
			color(d, "ARTWORK", 0.45, 0.2, 0.15, 1):SetAllPoints(d)
		end
		self.activeObjects[d] = true
		d:Show()
		return d
	end
	return p
end
bar.HorizontalDividersPool, bar.VerticalDividersPool = pool(), pool()

-- BagsBarMixin:Layout with Edit Mode's orientation, Size and padding.
stub.bagsVertical, stub.bagPadding = false, 2
local function layout()
	local x = 0
	for i, b in ipairs(stub.bagButtons) do
		b:ClearAllPoints()
		local w = b:GetWidth()
		if stub.bagsVertical then b:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, x) else b:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -x, 0) end
		x = x + w + stub.bagPadding
	end
	if stub.bagsVertical then bar:SetSize(45, x) else bar:SetSize(x, 45) end
	bar.HorizontalDividersPool:ReleaseAll()
	bar.VerticalDividersPool:ReleaseAll()
	local dp = stub.bagsVertical and bar.VerticalDividersPool or bar.HorizontalDividersPool
	for i = 2, #stub.bagButtons do
		local b, d = stub.bagButtons[i], dp:Acquire()
		d:ClearAllPoints()
		if stub.bagsVertical then
			d:SetPoint("LEFT", b, "LEFT"); d:SetPoint("RIGHT", b, "RIGHT"); d:SetPoint("BOTTOM", b, "TOP", 0, -5); d:SetHeight(6)
		else
			d:SetPoint("TOP", b, "TOP"); d:SetPoint("BOTTOM", b, "BOTTOM"); d:SetPoint("LEFT", b, "RIGHT", -5, 0); d:SetWidth(6)
		end
	end
end
layout()

function stub.editBagsBar(o)
	if o.size then bar:SetScale(o.size / 100) end
	if o.vertical ~= nil then stub.bagsVertical = o.vertical end
	if o.padding then stub.bagPadding = o.padding end
	layout()
	stub.exitEditMode()
end

stub.guard(bar, CALLS)
stub.guard(bar.BorderArt, nil, "BagsBar.BorderArt")
for _, b in ipairs(stub.bagButtons) do
	stub.guard(b, CALLS)
	local name = b:GetName()
	for _, k in ipairs({ "icon", "SlotHighlightTexture", "Count", "FreeSlots", "normalTexture", "pushedTexture", "highlightTexture" }) do
		if rawget(b, k) then stub.guard(rawget(b, k), nil, name .. "." .. k) end
	end
end
