-- The cast bars as the client builds them on Forever (Blizzard_UIPanels_Game:
-- Mainline/CastingBarFrame.xml, Shared/CastingBarFrame.lua; the target's and
-- focus's in Blizzard_UnitFrame/Mainline/TargetFrame.lua): PlayerCastingBarFrame,
-- an Edit Mode system on CastingBarFrameTemplate (208 x 11: the name in a text
-- box under the bar, the cast time beside it, the icon hidden unless locked
-- to the player frame), and TargetFrameSpellBar and FocusFrameSpellBar,
-- children of the stock unit frames on SmallCastingBarFrameTemplate (150 x
-- 10, the name in a text box under the bar, the icon beside both, a shield
-- round a cast that cannot be interrupted). Each a StatusBar with the template's regions
-- (Background, Border, TextBorder, BorderShield, Icon, Spark, Flash, Text,
-- CastTimeText) and CastingBarMixin's handling of the cast events: its
-- `casting`, `channeling` and `reverseChanneling` flags, the fill's atlas set
-- again for each cast (SetStatusBarTexture, SetStatusBarColor(1, 1, 1)), the
-- name, Interrupted and Failed, the spark's alpha set to 1 by the interrupt
-- animation. Colour textures stand in for the atlases. Every bar and region
-- is guarded (stub_editmode.lua). Another unit's cast is secret
-- (UnitCastingInfo, UnitChannelInfo; C_Secrets.ShouldUnitSpellCastingBeSecret).
--
--   stub.cast(unit, { name, time, elapsed, channel = true, empower = true, locked = true })
--   stub.interruptCast(unit)   stub.finishCast(unit)
--   stub.failCast(unit, other) other: another spell failed (a key pressed mid-cast); the game ignores it
--   stub.editCastBar({ lock = bool, time = bool })   Edit Mode: Lock to Player Frame, Show Cast Time

require("stub_editmode")

local M = stub.Methods
local CALLS = stub.SYSTEM_CALLS
local WHITE = "Interface\\Buttons\\WHITE8X8"
-- The fill atlases' colours (CastingBarTypeInfo).
local TYPES = { standard = { 1, 0.7, 0 }, channel = { 0.1, 0.8, 0.1 }, uninterruptable = { 0.6, 0.6, 0.6 }, interrupted = { 0.9, 0.1, 0.1 }, empowered = { 0, 0, 0 } }

stub.casts = {}
local function secretFor(unit) return unit ~= "player" end
local function wrap(unit, v) if secretFor(unit) then return stub.secret(v) end return v end

function UnitCastingInfo(unit)
	local c = stub.casts[unit]
	if not c or c.channel or c.empower then return nil end
	return wrap(unit, c.name), wrap(unit, c.name), wrap(unit, 136116), wrap(unit, 0), wrap(unit, c.time * 1000), false, wrap(unit, "cast-1"),
		wrap(unit, c.locked == true), wrap(unit, 133)
end
function UnitChannelInfo(unit)
	local c = stub.casts[unit]
	if not c or not (c.channel or c.empower) then return nil end
	return wrap(unit, c.name), wrap(unit, c.name), wrap(unit, 136116), wrap(unit, 0), wrap(unit, c.time * 1000), false, wrap(unit, c.locked == true),
		wrap(unit, 133), c.empower == true, c.empower and 3 or 0
end
-- A cast's duration object: its numbers are secret, whoever casts.
local function duration(c)
	return { GetRemainingDuration = function() return stub.secret(c.channel and (c.elapsed or c.time) or c.time - (c.elapsed or 0)) end }
end
function UnitCastingDuration(unit)
	local c = stub.casts[unit]
	if c and not (c.channel or c.empower) then return duration(c) end
end
function UnitChannelDuration(unit)
	local c = stub.casts[unit]
	if c and c.channel then return duration(c) end
end

-- A texture takes a secret boolean and picks its colour itself; SetTexture
-- takes a secret file from addon code.
function M.SetVertexColorFromBoolean(self, v, yes, no)
	local c = stub.reveal(v) and yes or no
	self:SetVertexColor(c.r, c.g, c.b, c.a)
end
local setTexture = M.SetTexture
function M.SetTexture(self, file, ...) return setTexture(self, stub.reveal(file), ...) end

local function color(f, layer, sub, r, g, b, a)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetColorTexture(r, g, b, a or 1)
	return t
end

local bars = {}

-- CastingBarMixin:SetLook: CLASSIC (the name in the text box under the bar,
-- no icon) or UNITFRAME (150 x 10, the name on the bar, the icon beside it);
-- it sets the name's font object again. SMALL: the target's and focus's
-- template as it is (no look set: the name under the bar, the icon shown).
local function setLook(bar, look)
	bar.look = look ~= "SMALL" and look or nil
	bar.Text:ClearAllPoints()
	if look == "SMALL" then
		bar:SetSize(150, 10)
		bar.Text:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, -8)
		bar.Text:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, -8)
		bar.Text:SetHeight(16)
		bar.Text:SetFontObject(GameFontHighlightSmall)
	elseif look == "UNITFRAME" then
		bar:SetSize(150, 10)
		bar.Text:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 3)
		bar.Text:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 3)
		bar.Text:SetHeight(16)
		bar.Text:SetFontObject(GameFontHighlightSmall)
		bar.TextBorder:Hide()
	else
		bar:SetSize(208, 11)
		bar.Text:SetPoint("TOP", bar, "TOP", 0, -10)
		bar.Text:SetSize(185, 16)
		bar.Text:SetFontObject(GameFontHighlightSmall)
		bar.TextBorder:Show()
	end
	bar.Icon:SetShown(bar.showIcon and look ~= "CLASSIC")
end

local function castBar(name, parent, unit, small)
	local bar = CreateFrame("StatusBar", name, parent)
	bar.unit, bar.showShield, bar.showIcon, bar.showCastbar = unit, small, true, true
	bar:SetStatusBarTexture(WHITE)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	bar.TextBorder = color(bar, "BACKGROUND", 0, 0.05, 0.04, 0.03, 0.85)
	bar.TextBorder:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
	bar.TextBorder:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, -12)
	bar.Background = color(bar, "BACKGROUND", 2, 0.1, 0.08, 0.05, 1)
	bar.Background:SetAllPoints(bar)
	bar.BorderShield = color(bar, "ARTWORK", 4, 0.7, 0.7, 0.75, 1)
	bar.BorderShield:SetSize(29, 33)
	bar.BorderShield:SetPoint("TOPLEFT", bar, "TOPLEFT", -27, 4)
	bar.BorderShield:Hide()
	bar.Icon = color(bar, "ARTWORK", 4, 0.3, 0.5, 0.85, 1)
	bar.Icon:SetSize(small and 20 or 16, small and 20 or 16)
	bar.Icon:SetPoint("RIGHT", bar, "LEFT", small and -2 or -5, small and -5 or 0)
	bar.Border = color(bar, small and "OVERLAY" or "ARTWORK", 4, 0.75, 0.6, 0.3, 0.6)
	bar.Border:SetPoint("TOPLEFT", bar, "TOPLEFT", -2, 2)
	bar.Border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 2, -2)
	bar.Flash = color(bar, "OVERLAY", 1, 1, 1, 1, 0.5)
	bar.Flash:SetAllPoints(bar)
	bar.Flash:SetAlpha(0)
	bar.Text = bar:CreateFontString(nil, "OVERLAY")
	bar.Spark = color(bar, "OVERLAY", 2, 1, 1, 0.8, 1)
	bar.Spark:SetSize(small and 6 or 8, small and 16 or 20)
	bar.Spark:Hide()
	if not small then
		bar.DropShadow = color(bar, "BACKGROUND", 0, 0, 0, 0, 0.5)
		bar.DropShadow:SetAllPoints(bar)
		bar.DropShadow:Hide()
		bar.CastTimeText = bar:CreateFontString(nil, "OVERLAY")
		bar.CastTimeText:SetFontObject(GameFontNormalLarge)
		bar.CastTimeText:SetPoint("LEFT", bar, "RIGHT", 10, 0)
		bar.CastTimeText:Hide()
	end
	setLook(bar, small and "SMALL" or "CLASSIC")
	-- In combat the target's and focus's bars answer their size with secret
	-- numbers (they hang off the unit frames and the secure aura container):
	-- seen in the client, 900 errors from one compare.
	if small then
		for _, name in ipairs({ "GetHeight", "GetWidth" }) do
			rawset(bar, name, function(self)
				if stub.inCombat then return stub.secret(M[name](self)) end
				return M[name](self)
			end)
		end
	end
	bar:Hide()
	bars[unit] = bar
	stub.secureNames[name] = true
	return bar
end

local function fillType(bar, kind)
	bar.barType = kind
	-- CastingBarMixin:UpdateBarFillTexture: the atlas, then white.
	bar:SetStatusBarTexture(WHITE)
	bar.fillAtlas = "ui-castingbar-filling-" .. kind
	local c = TYPES[kind]
	bar:SetStatusBarColor(c[1], c[2], c[3], kind == "empowered" and 0 or 1)
end

local function sparkAt(bar)
	local lo, hi = bar:GetMinMaxValues()
	bar.Spark:ClearAllPoints()
	bar.Spark:SetPoint("CENTER", bar, "LEFT", (hi > lo and bar:GetValue() / hi or 0) * M.GetWidth(bar), 0)
end

local function castTime(bar, c)
	if not rawget(bar, "CastTimeText") then return end
	bar.CastTimeText:SetShown(bar.showCastTimeSetting and c ~= nil)
	if c then bar.CastTimeText:SetFormattedText("%.1f sec", c.channel and (c.elapsed or c.time) or c.time - (c.elapsed or 0)) end
end

-- CastingBarMixin:OnEvent, as the game's code.
local function onEvent(bar, event, unit, other)
	if unit ~= bar.unit then return end
	local c = stub.casts[unit]
	if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_EMPOWER_START" then
		fillType(bar, c.locked and "uninterruptable" or c.channel and "channel" or c.empower and "empowered" or "standard")
		bar:SetMinMaxValues(0, c.time)
		bar:SetValue(c.channel and (c.elapsed or c.time) or c.elapsed or 0)
		bar.Text:SetText(c.name)
		bar.casting, bar.channeling, bar.reverseChanneling = not c.channel or nil, c.channel or nil, c.empower or nil
		bar.Spark:Show()
		sparkAt(bar)
		bar.Flash:SetAlpha(0)
		bar.BorderShield:SetShown(bar.showShield and c.locked == true)
		bar.Icon:SetShown(bar.showIcon and (bar.look == nil or bar.look == "UNITFRAME"))
		castTime(bar, c)
		bar:SetAlpha(1)
		bar:Show()
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
		-- Another spell's failure carries another cast id: ignored.
		if other or not (bar.casting or bar.channeling) then return end
		fillType(bar, "interrupted")
		bar.Text:SetText(event == "UNIT_SPELLCAST_FAILED" and "Failed" or "Interrupted")
		bar.casting, bar.channeling, bar.reverseChanneling = nil, nil, nil
		-- InterruptSparkAnim (setToFinalAlpha) leaves the spark at 1; then the bar fills.
		bar.Spark:SetAlpha(1)
		bar:SetValue(select(2, bar:GetMinMaxValues()))
		bar.Spark:Hide()
		stub.casts[unit] = nil
		castTime(bar, nil)
	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		if not bar.channeling then bar:SetValue(select(2, bar:GetMinMaxValues())) end
		bar.casting, bar.channeling, bar.reverseChanneling = nil, nil, nil
		bar.Spark:Hide()
		bar.Flash:SetAlpha(1)
		stub.casts[unit] = nil
		castTime(bar, nil)
	end
end

local player = castBar("PlayerCastingBarFrame", UIParent, "player", false)
player:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 300, 700)
local target = castBar("TargetFrameSpellBar", TargetFrame, "target", true)
target:SetPoint("TOPLEFT", TargetFrame, "BOTTOMLEFT", 43, 5)
local focus = castBar("FocusFrameSpellBar", FocusFrame, "focus", true)
focus:SetPoint("TOPLEFT", FocusFrame, "BOTTOMLEFT", 43, 5)

for _, bar in pairs(bars) do
	for _, e in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_EMPOWER_START", "UNIT_SPELLCAST_INTERRUPTED",
		"UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_STOP" }) do
		bar:RegisterEvent(e)
	end
	bar:SetScript("OnEvent", onEvent)
	stub.guard(bar, CALLS)
	for _, k in ipairs({ "TextBorder", "Background", "BorderShield", "Icon", "Border", "Flash", "Text", "Spark", "DropShadow", "CastTimeText" }) do
		if rawget(bar, k) then stub.guard(bar[k], nil, bar:GetName() .. "." .. k) end
	end
	stub.guard(bar:GetStatusBarTexture(), nil, bar:GetName() .. "'s fill")
end

function stub.cast(unit, c)
	stub.casts[unit] = c
	stub.fire(c.empower and "UNIT_SPELLCAST_EMPOWER_START" or c.channel and "UNIT_SPELLCAST_CHANNEL_START" or "UNIT_SPELLCAST_START", unit)
end
function stub.interruptCast(unit) stub.fire("UNIT_SPELLCAST_INTERRUPTED", unit) end
function stub.failCast(unit, other) stub.fire("UNIT_SPELLCAST_FAILED", unit, other) end
function stub.finishCast(unit)
	local c = stub.casts[unit]
	stub.fire(c and c.channel and "UNIT_SPELLCAST_CHANNEL_STOP" or "UNIT_SPELLCAST_STOP", unit)
end

-- Edit Mode's cast bar settings (EditModeCastBarSystemMixin): Lock to Player
-- Frame hangs the bar under the player frame in the unit frame look; Show
-- Cast Time shows the game's cast time.
function stub.editCastBar(o)
	if o.lock ~= nil then
		player.attachedToPlayerFrame = o.lock
		setLook(player, o.lock and "UNITFRAME" or "CLASSIC")
		player:ClearAllPoints()
		if o.lock then player:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", 78, 26) else player:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 300, 700) end
	end
	if o.time ~= nil then
		player.showCastTimeSetting = o.time
		castTime(player, stub.casts.player)
	end
	stub.fire("EDIT_MODE_LAYOUTS_UPDATED")
end

-- Edit Mode shows the player's bar with no cast (CastingBarMixin:UpdateShownState).
local enter, exit = stub.enterEditMode, stub.exitEditMode
function stub.enterEditMode()
	player.isInEditMode = true
	if not player.casting then
		fillType(player, "standard")
		player:SetMinMaxValues(0, 1)
		player:SetValue(1)
		player.Text:SetText("Cast Bar")
	end
	player:SetAlpha(1)
	player:Show()
	enter()
end
function stub.exitEditMode()
	player.isInEditMode = false
	if not (player.casting or player.channeling) then player:Hide() end
	exit()
end
