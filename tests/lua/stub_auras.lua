-- The player's buffs and debuffs as the client builds them on Forever
-- (Blizzard_BuffFrame: BuffFrame.xml, BuffFrameTemplates.xml, BuffFrame.lua):
-- BuffFrame and DebuffFrame, Edit Mode systems, each with an AuraContainer
-- holding its aura buttons (AuraButtonTemplate: the Icon, the Duration under
-- it, the DebuffBorder, the TempEnchantBorder, the Symbol, the Count), kept
-- in `auraFrames`. The game deals the auras over the buttons in order
-- (AuraFrameMixin:UpdateAuraButtons: weapon enchants first, then buffs),
-- lays them out as Edit Mode's settings say
-- (AuraContainerMixin:UpdateGridLayout: icon size, icons per row, padding,
-- direction, orientation), and shows examples in Edit Mode
-- (TryEditModeUpdateAuraButtons, which sets the duration's font again).
-- Colour textures stand in for the icons, Polestar's ring glyph for the
-- border atlases. Every frame, container, button and region is guarded
-- (stub_editmode.lua). A debuff's dispel type is secret in combat.
--
--   stub.auras = { buffs = { { icon = {r,g,b}, time = sec, count = n, enchant = true }, ... },
--                  debuffs = { { icon, time, count, dispel = "Magic" }, ... } }
--   stub.updateAuras()                 the game deals them again (UNIT_AURA)
--   stub.editAuras(frame, { size, perRow, padding, toRight, toTop, vertical })   Edit Mode's settings
--   stub.cancelled                     the index the game's right-click cancelled
--   stub.auraTip                       the aura the game's tooltip last showed

require("stub_editmode")

local CALLS = stub.SYSTEM_CALLS
local RING = "Interface\\AddOns\\Polestar\\Media\\UI\\skin-ring"

BUFF_MAX_DISPLAY, DEBUFF_MAX_DISPLAY = 32, 16
BUFF_DURATION_WARNING_TIME = 90

-- AuraUtil.GetDebuffDisplayInfoTable (Blizzard_FrameXMLUtil/AuraUtil.lua).
local DISPEL = {
	Magic = { color = CreateColor(0.2, 0.6, 1) }, Curse = { color = CreateColor(0.6, 0, 1) },
	Disease = { color = CreateColor(0.6, 0.4, 0) }, Poison = { color = CreateColor(0, 0.6, 0) },
	Bleed = { color = CreateColor(1, 0.2, 0.6) }, None = { color = CreateColor(0.8, 0, 0) },
}
AuraUtil = AuraUtil or {}
function AuraUtil.GetDebuffDisplayInfoTable() return DISPEL end

local function abbrev(s)
	if s >= 3600 then return string.format("%d h", math.ceil(s / 3600)) end
	if s >= 60 then return string.format("%d m", math.ceil(s / 60)) end
	return string.format("%d s", s)
end

local function button(container)
	local b = CreateFrame("Button", nil, container)
	b:SetSize(30, 40)
	b.Icon = b:CreateTexture(nil, "BACKGROUND")
	b.Icon:SetSize(30, 30)
	b.Icon:SetColorTexture(0.3, 0.3, 0.3, 1)
	b.Duration = b:CreateFontString(nil, "BACKGROUND")
	b.Duration:SetFontObject(GameFontNormalSmall)
	b.DebuffBorder = b:CreateTexture(nil, "OVERLAY")
	b.DebuffBorder:SetTexture(RING)
	b.DebuffBorder:SetSize(40, 40)
	b.DebuffBorder:SetPoint("CENTER", b.Icon, "CENTER", 0, 0)
	b.TempEnchantBorder = b:CreateTexture(nil, "OVERLAY")
	b.TempEnchantBorder:SetTexture(RING)
	b.TempEnchantBorder:SetVertexColor(0.6, 0.2, 0.9, 1)
	b.TempEnchantBorder:SetSize(32, 32)
	b.TempEnchantBorder:SetPoint("CENTER", b.Icon, "CENTER", 0, 0)
	b.Symbol = b:CreateFontString(nil, "OVERLAY")
	b.Symbol:SetFontObject(GameFontNormalSmall)
	b.Symbol:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
	b.Count = b:CreateFontString(nil, "OVERLAY")
	b.Count:SetFontObject(NumberFontNormal)
	b.Count:SetPoint("BOTTOMRIGHT", b.Icon, "BOTTOMRIGHT", -2, 2)
	b.DebuffBorder:Hide()
	b.TempEnchantBorder:Hide()
	b:Hide()
	-- AuraButtonMixin:OnClick and OnEnter: the game's own (CancelUnitBuff is
	-- the game's to call in combat).
	b:SetScript("OnClick", function(self, mouse)
		if self.isExample then return end
		if mouse == "RightButton" and self.auraType == "Buff" then stub.cancelled = self.buttonInfo.index end
	end)
	b:SetScript("OnEnter", function(self)
		if self.isExample then return end
		stub.auraTip = self.buttonInfo.auraInstanceID or self.buttonInfo.ID
	end)
	return b
end

-- AuraContainerMixin:UpdateGridLayout: every button in the grid, `iconStride`
-- to a line, growing left and down unless Edit Mode says otherwise; a
-- vertical frame's buttons are 60 x 30, the duration beside the icon.
local function layout(f)
	local c = f.AuraContainer
	local w, h = c.isHorizontal and 30 or 60, c.isHorizontal and 40 or 30
	local xm, ym = c.addIconsToRight and 1 or -1, c.addIconsToTop and 1 or -1
	local point = (c.addIconsToTop and "BOTTOM" or "TOP") .. (c.addIconsToRight and "LEFT" or "RIGHT")
	for i, b in ipairs(f.auraFrames) do
		local along, across = (i - 1) % c.iconStride, math.floor((i - 1) / c.iconStride)
		local col, row = c.isHorizontal and along or across, c.isHorizontal and across or along
		b:SetScale(c.iconScale)
		b:SetSize(w, h)
		b:ClearAllPoints()
		b:SetPoint(point, c, point, xm * col * (w + c.iconPadding), ym * row * (h + c.iconPadding))
		local ip = c.isHorizontal and (c.addIconsToTop and "BOTTOM" or "TOP") or (c.addIconsToRight and "LEFT" or "RIGHT")
		b.Icon:ClearAllPoints()
		b.Icon:SetPoint(ip, b, ip, 0, 0)
		b.Duration:ClearAllPoints()
		if c.isHorizontal then
			b.Duration:SetPoint(c.addIconsToTop and "BOTTOM" or "TOP", b.Icon, c.addIconsToTop and "TOP" or "BOTTOM", 0, 0)
		else
			b.Duration:SetPoint(c.addIconsToRight and "LEFT" or "RIGHT", b.Icon, c.addIconsToRight and "RIGHT" or "LEFT", 0, 0)
		end
	end
	local lines = math.ceil(f.maxAuras / c.iconStride)
	local cols, rows = c.isHorizontal and c.iconStride or lines, c.isHorizontal and lines or c.iconStride
	f:SetSize((w + c.iconPadding) * cols * c.iconScale, (h + c.iconPadding) * rows * c.iconScale)
	c:ClearAllPoints()
	c:SetPoint(point, f, point, 0, 0)
end

local function auraFrame(name, max, example)
	local f = CreateFrame("Frame", name, UIParent)
	f.maxAuras, f.exampleAuraType = max, example
	local c = CreateFrame("Frame", nil, f)
	c:SetSize(1, 1)
	c.isHorizontal, c.iconStride, c.iconPadding, c.iconScale, c.addIconsToRight, c.addIconsToTop = true, 8, 5, 1, false, false
	f.AuraContainer = c
	f.auraFrames = {}
	for i = 1, max do f.auraFrames[i] = button(c) end
	layout(f)
	stub.secureNames[name] = true
	return f
end

local buffs = auraFrame("BuffFrame", BUFF_MAX_DISPLAY, "Buff")
buffs:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -205, -13)
local debuffs = auraFrame("DebuffFrame", DEBUFF_MAX_DISPLAY, "Debuff")
debuffs:SetPoint("TOPRIGHT", buffs, "BOTTOMRIGHT", -13, -5)

for _, f in ipairs({ buffs, debuffs }) do
	stub.guard(f, CALLS)
	stub.guard(f.AuraContainer, CALLS, f:GetName() .. ".AuraContainer")
	for i, b in ipairs(f.auraFrames) do
		local label = f:GetName() .. "'s aura button " .. i
		stub.guard(b, CALLS, label)
		for _, k in ipairs({ "Icon", "Duration", "DebuffBorder", "TempEnchantBorder", "Symbol", "Count" }) do
			stub.guard(b[k], nil, label .. "." .. k)
		end
	end
end

stub.auras = { buffs = {}, debuffs = {} }

-- AuraButtonMixin:Update for one dealt aura.
local id = 0
local function deal(b, a, kind, index)
	id = id + 1
	b.isExample, b.hasValidInfo, b.auraType = false, true, kind
	local dispel = a.dispel
	if dispel and stub.inCombat then dispel = stub.secret(dispel) end
	b.buttonInfo = { auraType = kind, index = index, auraInstanceID = kind ~= "TempEnchant" and id or nil, ID = kind == "TempEnchant" and 16 or nil,
		debuffType = dispel, count = a.count or 0, expirationTime = a.time and GetTime() + a.time or 0 }
	local c = a.icon or { 0.4, 0.4, 0.4 }
	b.Icon:SetColorTexture(c[1], c[2], c[3], 1)
	b.DebuffBorder:SetShown(kind == "Debuff")
	if kind == "Debuff" then
		local d = DISPEL[a.dispel or "None"].color
		b.DebuffBorder:SetAtlas("ui-debuff-border-" .. (a.dispel or "default"):lower() .. "-noicon")
		b.DebuffBorder:SetVertexColor(d.r, d.g, d.b, 1)
	end
	b.TempEnchantBorder:SetShown(kind == "TempEnchant")
	b.Duration:SetShown(a.time ~= nil)
	if a.time then
		b.Duration:SetFormattedText(abbrev(a.time))
		if a.time < BUFF_DURATION_WARNING_TIME then b.Duration:SetTextColor(1, 1, 1) else b.Duration:SetTextColor(1, 0.82, 0) end
	end
	b.Count:SetShown((a.count or 0) > 1)
	if (a.count or 0) > 1 then b.Count:SetText(a.count) end
	b:Show()
end

local function update(f, list, kindOf)
	if f.isInEditMode then return end
	for i, b in ipairs(f.auraFrames) do
		local a = list[i]
		if a then
			deal(b, a, kindOf(a), i)
		else
			b.isExample, b.hasValidInfo = false, false
			b:Hide()
		end
	end
end

function stub.updateAuras()
	-- Weapon enchants first, then the buffs, as BuffFrameMixin:UpdateAuras orders them.
	local list = {}
	for _, a in ipairs(stub.auras.buffs) do if a.enchant then list[#list + 1] = a end end
	for _, a in ipairs(stub.auras.buffs) do if not a.enchant then list[#list + 1] = a end end
	update(buffs, list, function(a) return a.enchant and "TempEnchant" or "Buff" end)
	update(debuffs, stub.auras.debuffs, function() return "Debuff" end)
	stub.fire("UNIT_AURA", "player")
end

-- Edit Mode's settings (EditModeAuraFrameSystemMixin): Icon Size, Icon
-- Limit per row, Icon Padding, Icon Direction, Icon Wrap, Orientation.
function stub.editAuras(f, o)
	local c = f.AuraContainer
	if o.size then c.iconScale = o.size / 100 end
	if o.perRow then c.iconStride = o.perRow end
	if o.padding then c.iconPadding = o.padding end
	if o.toRight ~= nil then c.addIconsToRight = o.toRight end
	if o.toTop ~= nil then c.addIconsToTop = o.toTop end
	if o.vertical ~= nil then c.isHorizontal = not o.vertical end
	layout(f)
	stub.fire("EDIT_MODE_LAYOUTS_UPDATED")
end

-- Edit Mode shows every button as an example, its duration's font set again
-- (AuraFrameEditModeMixin:TryEditModeUpdateAuraButtons); leaving it deals
-- the real auras again.
local enter, exit = stub.enterEditMode, stub.exitEditMode
function stub.enterEditMode()
	for _, f in ipairs({ buffs, debuffs }) do
		f.isInEditMode = true
		for i, b in ipairs(f.auraFrames) do
			b.isExample = true
			b.DebuffBorder:SetShown(f.exampleAuraType == "Debuff")
			b.TempEnchantBorder:Hide()
			b.Count:Hide()
			b.Duration:SetFontObject(GameFontNormalSmall)
			b.Duration:SetFormattedText(abbrev(i * 60))
			b.Duration:Show()
			b.Icon:SetColorTexture(0.25 + (i % 5) * 0.1, 0.3 + (i % 3) * 0.15, 0.35 + (i % 4) * 0.1, 1)
			b:Show()
		end
	end
	enter()
end
function stub.exitEditMode()
	buffs.isInEditMode, debuffs.isInEditMode = false, false
	stub.updateAuras()
	exit()
end

---------------------------------------------------------------------------
-- A unit's auras (C_UnitAuras), for the rows under our target and focus
-- frames: stub.units[unit].auras = { { id, harmful = true, mine = true,
-- fromPlayer = true (another player's), time = sec, count = n, dispel =
-- "Magic", icon = fileID }, ... }. The ids come sorted as the client sorts
-- them (UnitAuraSortRule.Default: the player's own first). While auras are
-- secret (in combat, or stub.aurasSecret: an encounter, a keystone, a PvP
-- match; C_Secrets.ShouldAurasBeSecret) every call of addon code errors, as
-- the client's RequiresUnitAuraAccess does for a tainted caller.
---------------------------------------------------------------------------

Enum = Enum or {}
Enum.UnitAuraSortRule = Enum.UnitAuraSortRule or { Unsorted = 0, Default = 1 }
C_UnitAuras = C_UnitAuras or {}

local function aurasOf(unit)
	local d = stub.units[unit]
	return d and d.auras or {}
end
local function find(unit, id)
	for _, a in ipairs(aurasOf(unit)) do if a.id == id then return a end end
end
local function hide(v) if stub.inCombat then return stub.secret(v) end return v end
C_Secrets = C_Secrets or {}
function C_Secrets.ShouldAurasBeSecret() return (stub.inCombat or stub.aurasSecret) and true or false end
local function access(name)
	if C_Secrets.ShouldAurasBeSecret() then error(name .. "(): Auras cannot be accessed when secret while tainted by 'Polestar_UI'", 3) end
end

function C_UnitAuras.GetUnitAuraInstanceIDs(unit, filter, max, rule)
	access("GetUnitAuraInstanceIDs")
	local harmful, mine = filter:find("HARMFUL", 1, true) ~= nil, filter:find("PLAYER", 1, true) ~= nil
	local out = {}
	for pass = 1, 2 do
		for _, a in ipairs(aurasOf(unit)) do
			local first = rule == Enum.UnitAuraSortRule.Default and a.mine or false
			if (a.harmful or false) == harmful and (not mine or a.mine) and (first == (pass == 1)) and #out < (max or 99) then out[#out + 1] = a.id end
		end
	end
	return out
end
function C_UnitAuras.GetAuraDataByAuraInstanceID(unit, id)
	access("GetAuraDataByAuraInstanceID")
	local a = find(unit, id)
	if not a then return nil end
	return { auraInstanceID = id, icon = hide(a.icon or 136116), dispelName = hide(a.dispel), isFromPlayerOrPlayerPet = hide(a.mine or a.fromPlayer or false),
		nameplateShowAll = hide(false), applications = hide(a.count or 0), isHarmful = hide(a.harmful or false) }
end
function C_UnitAuras.GetAuraDuration(unit, id)
	access("GetAuraDuration")
	local a = find(unit, id)
	if not a then return nil end
	return { GetRemainingDuration = function() return stub.secret(a.time or 0) end }
end
function C_UnitAuras.GetAuraApplicationDisplayCount(unit, id, min)
	access("GetAuraApplicationDisplayCount")
	local a = find(unit, id)
	return hide(a and (a.count or 0) >= (min or 2) and tostring(a.count) or "")
end

-- A Cooldown takes a duration object and draws its own countdown (the
-- game formats it; an aura with no time draws none).
local M = stub.Methods
function M.GetCountdownFontString(self)
	if not self.countdown then
		self.countdown = self:CreateFontString(nil, "OVERLAY")
		self.countdown:SetFontObject(GameFontNormalSmall)
		self.countdown:SetPoint("CENTER", self, "CENTER", 0, 0)
	end
	return self.countdown
end
function M.SetCooldownFromDurationObject(self, d)
	self.duration = d
	local left = stub.reveal(d:GetRemainingDuration())
	self:GetCountdownFontString():SetText(left > 0 and (left >= 60 and string.format("%dm", math.ceil(left / 60)) or tostring(math.floor(left))) or "")
end

function GameTooltip.SetUnitAuraByAuraInstanceID(_, unit, id)
	access("GetUnitAuraByAuraInstanceID")
	stub.auraTip = unit .. ":" .. tostring(id)
end

-- Friend or foe by the unit stub's reaction (5 and up: friendly).
local isFriend = UnitIsFriend
function UnitIsFriend(a, unit)
	local d = stub.units[unit]
	if d then return (d.reaction or 4) >= 5 end
	return isFriend and isFriend(a, unit) or false
end

-- SetTexture takes a secret file from addon code.
local setTexture = M.SetTexture
function M.SetTexture(self, file, ...) return setTexture(self, stub.reveal(file), ...) end
