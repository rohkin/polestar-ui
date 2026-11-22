-- The nameplates as Forever's client builds them (Blizzard_NamePlates, Camelot
-- overrides; docs/windows/nameplates.md): the client makes a base plate per
-- unit in sight (NamePlate1..n, reused) and fires NAME_PLATE_UNIT_ADDED;
-- NamePlateDriverFrame (registered first, so its handler runs before any
-- addon's) acquires a pooled UnitFrame (NamePlateUnitFrameTemplate, its
-- mixin copied in when the frame is made), parents it to the plate and sets
-- its unit; on NAME_PLATE_UNIT_REMOVED it clears the unit and releases the
-- frame to the pool, so one UnitFrame serves many units in turn. Friendly
-- plates in instances are forbidden plates (a pool of their own,
-- FORBIDDEN_NAME_PLATE_* events, never handed to addon code).
--
-- The UnitFrame's parts as the template has them (Blizzard_NamePlates.xml):
-- HealthBarsContainer.healthBar (alias uf.healthBar: barTexture, bgTexture,
-- selectedBorder, deselectedOverlay, Text, LeftText, RightText), name,
-- selectionHighlight, aggroHighlightBase, CastBarsContainer.castBar
-- (NamePlateCastingBarTemplate: Background, Border, ImportantCastIndicator,
-- CastTargetIndicator, Icon, Text, CastTargetNameText, BorderShield, Spark;
-- the `casting`/`channeling` flags as CastingBarMixin keeps them),
-- WidgetContainer, RaidTargetFrame.RaidTargetIcon,
-- ClassificationFrame.classificationIndicator, AurasFrame (DebuffListFrame,
-- BuffListFrame, CrowdControlListFrame: items with Icon, Border, Cooldown,
-- CountFrame.Count, the Cooldown's countdown string), LevelFrame (LevelText,
-- HighLevelTexture), PlayerLevelDiffFrame (Camelot's level badge right of the
-- bar: playerLevelDiffIcon, playerLevelDiffText, selectedBorder,
-- highLevelTexture; the bar narrowed by its width). Colour
-- textures stand in for the atlases; the atlas names are kept (`atlas`).
--
-- The game's code here (it may do anything): UpdateAnchors lays the plate
-- out by nameplateStyle and nameplateSize and sets the bar atlases and font
-- objects again (stub.anchorRuns counts it); the global
-- CompactUnitFrame_UpdateHealthColor colours the health bar (threat when
-- the plate's displayThreatHealthBarColor is set, grey dead, class colour,
-- tapped, reaction), skipping an unchanged colour, and SetStatusBarColor
-- puts the fill's alpha back to 1 (a fade of the game's fill holds only if it
-- is set again after that global: ours does, in its post-hook). A
-- plate whose identity is secret (`secret = true`) answers the unit API
-- secret, and its bar's colour (GetStatusBarColor) is secret too.
--
-- Guards (Polestar: UI's own files only; docs/CLIENT.md rules 15 and 20):
-- every stock plate frame, UnitFrame, child frame and region errors on a
-- Lua key written, a hooksecurefunc on it (stub_editmode.lua), and on
-- moving, sizing, showing, hiding, reparenting or re-scripting it; stock
-- textures take SetAlpha only (and mask calls on an aura icon), stock font
-- strings SetAlpha only (no text read or written, no font set; an aura's
-- count takes a face, H.Face). A forbidden plate or its UnitFrame errors on any use at all.
-- A C_UnitAuras call for a nameplate unit errors while auras are secret
-- (combat, stub.aurasSecret), and C_NamePlate.SetNamePlateSize from our
-- code errors. Every SetCVar is recorded with the addon that made it
-- (stub.cvarWrites): Polestar: UI writes none.
--
--   stub.addPlate(unit, { name, level, reaction, class, player, classification, health, max, tapped, dead,
--     threat, raidTarget, widgetsOnly, auras = { { icon, count } }, buffs, forbidden, secret, x, y })
--     -> the base plate, or nil when the nameplate CVars hide that kind of unit (it shows once they allow it)
--   stub.updatePlate(unit, changes)   merges and fires what the client would (health, threat, faction, ...)
--   stub.removePlate(unit)            stub.targetPlate(unit|nil)   stub.focusPlate(unit|nil)
--   stub.plateCast(unit, { name, time, elapsed, channel, locked, important, icon, targetName })
--   stub.plateCastEnd(unit, "stop" | "interrupt")
--   stub.setCVarBits(cvar, { [index] = true })   a bitfield CVar (nameplateThreatDisplay, ...), as the options panel sets it
--   stub.setCVar(cvar, value)                    the player's own CVar change (stub_editmode.lua), not recorded
--   stub.plates[unit] (base plate)   stub.unitFrames (every pooled UnitFrame made)   stub.cvarWrites

require("stub_editmode")

local M = stub.Methods
local WHITE = "Interface\\Buttons\\WHITE8X8"

---------------------------------------------------------------------------
-- Who is calling, and breaches
---------------------------------------------------------------------------

local function ours(level)
	local info = debug.getinfo(level + 1, "S")
	return info and stub.addonSources[info.source] == "PolestarUI"
end
-- The first addon on the stack, for the CVar record.
local function addonOnStack()
	for level = 3, 40 do
		local info = debug.getinfo(level, "S")
		if not info then return nil end
		local a = stub.addonSources[info.source]
		if a then return a end
	end
end
local function breach(msg)
	table.insert(stub.breaches, msg)
	io.stderr:write(msg .. "\n")
	error(msg, 3)
end

---------------------------------------------------------------------------
-- CVars
---------------------------------------------------------------------------

for k, v in pairs({ nameplateShowAll = "1", nameplateShowEnemies = "1", nameplateShowEnemyMinions = "1", nameplateShowFriendlyPlayers = "0",
	nameplateShowFriendlyNpcs = "0", nameplateStyle = "1", nameplateSize = "2", nameplateShowClassColor = "1",
	nameplateShowFriendlyClassColor = "1", nameplateShowOnlyNameForFriendlyPlayerUnits = "0" }) do
	if stub.cvars[k] == nil then stub.cvars[k] = v end
end
-- Bitfield CVars by index (Enum.NamePlate*Display; the client packs them in a string).
stub.cvarBits = { nameplateInfoDisplay = {}, nameplateThreatDisplay = { [1] = true }, nameplateCastBarDisplay = { [1] = true, [2] = true, [4] = true } }

Enum.NamePlateStyle = { Modern = 0, Thin = 1, Block = 2, HealthFocus = 3, CastFocus = 4, Legacy = 5, Classic = 6 }
Enum.NamePlateSize = { Small = 1, Medium = 2, Large = 3, ExtraLarge = 4, Huge = 5 }
Enum.NamePlateInfoDisplay = { None = 0, CurrentHealthPercent = 1, CurrentHealthValue = 2, RarityIcon = 3 }
Enum.NamePlateThreatDisplay = { None = 0, Progressive = 1, Flash = 2, HealthBarColor = 3 }
Enum.NamePlateCastBarDisplay = { None = 0, SpellName = 1, SpellIcon = 2, SpellTarget = 3, HighlightImportantCasts = 4, HighlightWhenCastTarget = 5 }

function CVarCallbackRegistry:GetCVarBitfieldIndex(cvar, index) return (stub.cvarBits[cvar] or {})[index] == true end
function CVarCallbackRegistry:GetCVarNumberOrDefault(cvar) return tonumber(stub.cvars[cvar]) end
C_CVar = rawget(_G, "C_CVar") or {}
function C_CVar.GetCVar(k) return stub.cvars[k] end
function C_CVar.GetCVarBitfield(cvar, index) return (stub.cvarBits[cvar] or {})[index] == true end

stub.cvarWrites = {}
local setCVar = SetCVar
function SetCVar(k, v, ...)
	table.insert(stub.cvarWrites, { name = k, value = tostring(v), by = addonOnStack() or "game" })
	return setCVar(k, v, ...)
end
function C_CVar.SetCVar(k, v, ...) return SetCVar(k, v, ...) end
-- The CVars Polestar: UI wrote (it writes none).
function stub.cvarsWrittenByUs()
	local list = {}
	for _, w in ipairs(stub.cvarWrites) do if w.by == "PolestarUI" then list[#list + 1] = w.name end end
	return list
end

---------------------------------------------------------------------------
-- The unit API for plates (over stub_unitframes.lua's)
---------------------------------------------------------------------------

stub.plateData = {} -- unit -> what the client knows, read raw by the game's code here
local function plateData(unit) return unit and stub.plateData[unit] end

-- A plate with a restricted identity answers these secret to addon code.
for _, name in ipairs({ "UnitReaction", "UnitIsTapDenied", "UnitClass", "UnitIsPlayer", "UnitClassification", "UnitName", "UnitLevel",
	"UnitEffectiveLevel", "UnitCanAttack", "UnitIsFriend" }) do
	local base = _G[name]
	_G[name] = function(a, b, ...)
		local unit = (name == "UnitCanAttack" or name == "UnitIsFriend") and b or a
		local d = plateData(unit)
		if name == "UnitIsFriend" and d then
			local v = (d.reaction or 4) >= 5
			if d.secret then return stub.secret(v) end
			return v
		end
		local r = { (base or function() end)(a, b, ...) }
		if d and d.secret then for i = 1, math.max(#r, 1) do r[i] = stub.secret(r[i]) end end
		return unpack(r)
	end
end

-- Target and focus comparisons are allowed with a secret identity (SecretPredicates);
-- two nameplates compared answer secret.
local unitIsUnit = UnitIsUnit
function UnitIsUnit(a, b)
	local da, db = plateData(a), plateData(b)
	if da and db then return stub.secret(a == b) end
	local d, other = da or db, da and b or a
	if d then
		if other == "target" then return d.target == true end
		if other == "focus" then return d.focus == true end
		return false
	end
	if unitIsUnit then return unitIsUnit(a, b) end
	return a == b
end
local raidTarget = GetRaidTargetIndex
function GetRaidTargetIndex(unit)
	local d = plateData(unit)
	if d then return d.raidTarget end
	if raidTarget then return raidTarget(unit) end
end
-- The target exists while a plate's unit is it (stub.targetPlate).
local unitExists = UnitExists
function UnitExists(unit)
	if unit == "target" and stub.plateTarget then return true end
	return unitExists(unit)
end
function UnitNameplateShowsWidgetsOnly(unit) local d = plateData(unit) return d ~= nil and d.widgetsOnly == true end
UnitIsGameObject = rawget(_G, "UnitIsGameObject") or function() return false end
UnitThreatLeadSituation = rawget(_G, "UnitThreatLeadSituation") or function(_, unit) local d = plateData(unit) return d and d.threat end
canaccessvalue = rawget(_G, "canaccessvalue") or function(v) return not issecretvalue(v) end
PlayerUtil = rawget(_G, "PlayerUtil") or {}
PlayerUtil.IsPlayerEffectivelyTank = PlayerUtil.IsPlayerEffectivelyTank or function() return stub.tank == true end

-- Casts on plates answer from stub.casts (the shape stub_castbars.lua uses), secret.
stub.casts = stub.casts or {}
local function castOf(unit) return plateData(unit) and stub.casts[unit] end
local S = function(v) return stub.secret(v) end
for _, spec in ipairs({
	{ "UnitCastingInfo", function(c) if c.channel then return end return S(c.name), S(c.name), S(c.icon or 136116), S(0), S(c.time * 1000), false, S("cast-1"), S(c.locked == true), S(133) end },
	{ "UnitChannelInfo", function(c) if not c.channel then return end return S(c.name), S(c.name), S(c.icon or 136116), S(0), S(c.time * 1000), false, S(c.locked == true), S(133), false, 0 end },
	{ "UnitCastingDuration", function(c) if c.channel then return end return { GetRemainingDuration = function() return S(c.time - (c.elapsed or 0)) end } end },
	{ "UnitChannelDuration", function(c) if not c.channel then return end return { GetRemainingDuration = function() return S(c.elapsed or c.time) end } end },
}) do
	local base = rawget(_G, spec[1])
	_G[spec[1]] = function(unit, ...)
		local c = castOf(unit)
		if c then return spec[2](c) end
		if plateData(unit) then return nil end
		if base then return base(unit, ...) end
	end
end

-- The caster's target (CastingBarMixin:UpdateTargetNameText), secret.
function UnitShouldDisplaySpellTargetName(unit) local c = castOf(unit) return c ~= nil and c.targetName ~= nil end
function UnitSpellTargetName(unit) local c = castOf(unit) return c and c.targetName and S(c.targetName) end

-- No aura of a plate is read while auras are secret (rule 3): the game draws them.
C_UnitAuras = rawget(_G, "C_UnitAuras") or {}
for name, fn in pairs(C_UnitAuras) do
	if type(fn) == "function" then
		C_UnitAuras[name] = function(unit, ...)
			if ours(2) and type(unit) == "string" and unit:match("^nameplate") and (stub.inCombat or stub.aurasSecret) then
				breach("Polestar: UI read a nameplate's auras (C_UnitAuras." .. name .. ") while they are secret")
			end
			return fn(unit, ...)
		end
	end
end

function M.GetStatusBarColor(self)
	local c = self.barColor or { 1, 1, 1, 1 }
	if self.psSecretColor then return stub.secret(c[1]), stub.secret(c[2]), stub.secret(c[3]), stub.secret(c[4]) end
	return c[1], c[2], c[3], c[4]
end

---------------------------------------------------------------------------
-- Font objects (SystemFont_NamePlate*)
---------------------------------------------------------------------------

-- Font families (GameFonts.xml): each answers its roman member, a live font
-- object: a face set on it reaches the family and every string on it now
-- (the client's font objects are live; the generic stub copies a font at
-- SetFontObject). The other alphabets keep the client's faces.
local function family(name, size, flags)
	if rawget(_G, name) then return end
	local fam = CreateFont(name)
	fam:SetFont(STANDARD_TEXT_FONT, size, flags)
	local roman = CreateFont(nil)
	roman:SetFont(STANDARD_TEXT_FONT, size, flags)
	rawset(roman, "SetFont", function(self, path, sz, fl)
		M.SetFont(self, path, sz, fl)
		M.SetFont(fam, path, sz, fl)
		for _, fs in ipairs(stub.strings) do
			if rawget(fs, "fontObject") == fam then fs.font = { path, sz, fl or "" } end
		end
		return true
	end)
	rawset(fam, "GetFontObjectForAlphabet", function(self, alphabet)
		if alphabet == "roman" then return roman end
		return M.GetFontObjectForAlphabet(self, alphabet)
	end)
end
family("SystemFont_NamePlate", 9, "")
family("SystemFont_NamePlate_Outlined", 9, "OUTLINE")
family("SystemFont_NamePlateLevel", 9, "OUTLINE")
family("SystemFont_NamePlateCastBar", 8, "")

-- Masks (the aura items' rounded mask), where no other stub has them.
if not rawget(M, "GetMaskTexture") then function M.GetMaskTexture(self, i) if i == 1 then return self.mask end end end
if not rawget(M, "RemoveMaskTexture") then function M.RemoveMaskTexture(self, m) if self.mask == m then self.mask = nil end end end
-- A texture takes a secret boolean and picks its colour itself (as stub_castbars.lua).
if not rawget(M, "SetVertexColorFromBoolean") then
	function M.SetVertexColorFromBoolean(self, v, yes, no)
		local c = stub.reveal(v) and yes or no
		self:SetVertexColor(c.r, c.g, c.b, c.a)
	end
end

---------------------------------------------------------------------------
-- The UnitFrame (BaseNamePlateUnitFrameTemplate)
---------------------------------------------------------------------------

-- What Polestar: UI never calls on a stock plate's frames, and on its regions.
local FRAME_CALLS = { "SetPoint", "ClearAllPoints", "SetAllPoints", "SetScale", "Hide", "Show", "SetShown", "SetParent", "SetSize",
	"SetWidth", "SetHeight", "SetFrameStrata", "SetFrameLevel", "SetAlpha", "EnableMouse", "SetScript", "RegisterEvent",
	"RegisterUnitEvent", "UnregisterEvent", "UnregisterAllEvents", "SetAttribute", "SetStatusBarTexture", "SetStatusBarColor",
	"SetMinMaxValues", "SetValue", "SetHitTestPoints", "SetAllHitTestPoints", "ClearAllHitTestPoints", "SetStackingBoundsFrame" }
local TEXTURE_CALLS = { "SetPoint", "ClearAllPoints", "SetAllPoints", "SetSize", "SetWidth", "SetHeight", "SetParent", "Hide", "Show",
	"SetShown", "SetAtlas", "SetTexture", "SetColorTexture", "SetVertexColor", "SetTexCoord", "SetDrawLayer" }
local STRING_CALLS = { "SetPoint", "ClearAllPoints", "SetAllPoints", "SetSize", "SetWidth", "SetHeight", "SetParent", "Hide", "Show",
	"SetShown", "SetText", "SetFormattedText", "GetText", "SetFont", "SetFontObject", "SetTextColor" }

-- An aura's count: its face may be set (H.Face; the game only shows, hides and fills it).
local COUNT_CALLS = { "SetPoint", "ClearAllPoints", "SetAllPoints", "SetSize", "SetParent", "Hide", "Show", "SetShown", "SetText",
	"SetFormattedText", "GetText", "SetFontObject", "SetTextColor", "SetAlpha" }

local function guardRegion(r, label, calls)
	stub.guard(r, calls or (r.kind == "FontString" and STRING_CALLS or TEXTURE_CALLS), label)
end

local function tex(f, layer, sub, r, g, b, a, atlas)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetColorTexture(r, g, b, a or 1)
	if atlas then t:SetAtlas(atlas) end
	return t
end
local function text(f, font)
	local fs = f:CreateFontString(nil, "OVERLAY")
	fs:SetFontObject(font)
	return fs
end

-- The template's own parts, made once per pooled frame.
local function build(uf, label)
	local hc = CreateFrame("Frame", nil, uf)
	uf.HealthBarsContainer = hc
	local hb = CreateFrame("StatusBar", nil, hc)
	hc.healthBar, uf.healthBar = hb, hb
	hb:SetAllPoints(hc)
	hb:SetStatusBarTexture(WHITE)
	hb:GetStatusBarTexture():SetAtlas("UI-HUD-CoolDownManager-Bar")
	hb:SetMinMaxValues(0, 1)
	hb.barTexture = hb:GetStatusBarTexture()
	hb.bgTexture = tex(hb, "BACKGROUND", 0, 0.08, 0.06, 0.05, 0.85, "UI-HUD-CoolDownManager-Bar-BG")
	hb.bgTexture:SetAllPoints(hb)
	hb.selectedBorder = tex(hb, "OVERLAY", 2, 1, 0.85, 0.2, 1, "UI-HUD-CoolDownManager-Selected-yellow")
	hb.selectedBorder:Hide()
	hb.deselectedOverlay = tex(hb, "OVERLAY", 1, 0, 0, 0, 0.35, "ui-hud-nameplates-deselected-overlay")
	hb.deselectedOverlay:SetAllPoints(hb)
	hb.deselectedOverlay:Hide()
	-- Heal prediction and absorbs (CompactUnitFrame: the game only places, shows and hides them).
	hb.myHealPrediction, hb.totalAbsorb = tex(hb, "BORDER", 5, 0.4, 0.9, 0.4, 1), tex(hb, "BORDER", 5, 0.9, 0.9, 0.9, 1)
	hb.myHealPrediction:Hide()
	hb.totalAbsorb:Hide()
	hb.Text, hb.LeftText, hb.RightText = text(hb, SystemFont_NamePlate), text(hb, SystemFont_NamePlate), text(hb, SystemFont_NamePlate)
	hb.Text:SetPoint("CENTER", hb, "CENTER", 0, 0)
	hb.LeftText:SetPoint("LEFT", hb, "LEFT", 2, 0)
	hb.RightText:SetPoint("RIGHT", hb, "RIGHT", -2, 0)
	uf.name = text(uf, SystemFont_NamePlate_Outlined)
	uf.selectionHighlight = tex(hb, "OVERLAY", 0, 1, 1, 1, 0.25)
	uf.selectionHighlight:SetAllPoints(hb)
	uf.selectionHighlight:Hide()
	uf.aggroHighlightBase = tex(uf, "BACKGROUND", 0, 1, 0.3, 0.1, 0.6, "UI-HUD-Nameplates-Aggro-Flare")
	uf.aggroHighlightBase:SetPoint("BOTTOMLEFT", hb, "TOPLEFT", -6, -4)
	uf.aggroHighlightBase:SetPoint("BOTTOMRIGHT", hb, "TOPRIGHT", 6, -4)
	uf.aggroHighlightBase:SetHeight(10)
	uf.aggroHighlightBase:Hide()

	local cc = CreateFrame("Frame", nil, uf)
	uf.CastBarsContainer = cc
	local cb = CreateFrame("StatusBar", nil, cc)
	cc.castBar = cb
	cb:SetStatusBarTexture(WHITE)
	cb.Background = tex(cb, "BACKGROUND", 0, 0.1, 0.08, 0.05, 1, "ui-castingbar-background")
	cb.Background:SetAllPoints(cb)
	cb.Border = tex(cb, "ARTWORK", 0, 0.75, 0.6, 0.3, 0.6)
	cb.Border:SetPoint("TOPLEFT", cb, "TOPLEFT", -1, 1)
	cb.Border:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", 1, -1)
	cb.Border:Hide()
	cb.ImportantCastIndicator = tex(cb, "OVERLAY", 3, 1, 0.5, 0, 0.8, "ui-hud-nameplates-importantcast")
	cb.ImportantCastIndicator:SetPoint("TOPLEFT", cb, "TOPLEFT", -3, 3)
	cb.ImportantCastIndicator:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", 3, -3)
	cb.ImportantCastIndicator:Hide()
	cb.CastTargetIndicator = tex(cb, "OVERLAY", 3, 0.9, 0.1, 0.1, 1, "ui-hud-nameplates-targetedbyenemy")
	cb.CastTargetIndicator:SetSize(10, 10)
	cb.CastTargetIndicator:SetPoint("LEFT", cb, "RIGHT", 2, 0)
	cb.CastTargetIndicator:Hide()
	cb.Icon = tex(cb, "OVERLAY", 1, 0.3, 0.5, 0.85, 1)
	cb.Icon:SetPoint("RIGHT", cb, "LEFT", -2, 0)
	cb.Icon:Hide()
	cb.Text = text(cb, SystemFont_NamePlateCastBar)
	cb.Text:SetPoint("CENTER", cb, "CENTER", 0, 0)
	cb.CastTargetNameText = text(cb, SystemFont_NamePlateCastBar)
	cb.CastTargetNameText:SetPoint("TOPRIGHT", cb, "BOTTOMRIGHT", 0, -1)
	cb.BorderShield = tex(cb, "OVERLAY", 2, 0.7, 0.7, 0.75, 1, "nameplates-InterruptShield")
	cb.BorderShield:SetSize(10, 12)
	cb.BorderShield:SetPoint("CENTER", cb, "LEFT", 0, 0)
	cb.BorderShield:Hide()
	cb.Spark = tex(cb, "OVERLAY", 4, 1, 1, 0.8, 1, "ui-castingbar-pip")
	cb.Spark:SetSize(4, 10)
	cb.Spark:Hide()
	cb:Hide()

	uf.WidgetContainer = CreateFrame("Frame", nil, uf)
	uf.WidgetContainer:Hide()
	uf.RaidTargetFrame = CreateFrame("Frame", nil, uf)
	uf.RaidTargetFrame.RaidTargetIcon = tex(uf.RaidTargetFrame, "ARTWORK", 0, 0.9, 0.9, 0.2, 1)
	uf.RaidTargetFrame.RaidTargetIcon:SetAllPoints(uf.RaidTargetFrame)
	uf.RaidTargetFrame:Hide()
	uf.ClassificationFrame = CreateFrame("Frame", nil, uf)
	uf.ClassificationFrame.classificationIndicator = tex(uf.ClassificationFrame, "ARTWORK", 0, 0.95, 0.75, 0.2, 1)
	uf.ClassificationFrame.classificationIndicator:SetAllPoints(uf.ClassificationFrame)
	uf.classificationIndicator = uf.ClassificationFrame.classificationIndicator
	uf.ClassificationFrame:Hide()
	uf.LevelFrame = CreateFrame("Frame", nil, uf)
	uf.LevelFrame.LevelText = text(uf.LevelFrame, SystemFont_NamePlateLevel)
	uf.LevelFrame.LevelText:SetPoint("CENTER", uf.LevelFrame, "CENTER", 0, 0)
	uf.LevelFrame.HighLevelTexture = tex(uf.LevelFrame, "ARTWORK", 0, 0.9, 0.9, 0.9, 1, "UI-TargetingFrame-Skull")
	uf.LevelFrame.HighLevelTexture:SetAllPoints(uf.LevelFrame)
	uf.LevelFrame.HighLevelTexture:Hide()
	uf.LevelFrame:Hide()
	-- Camelot's level badge (NameplateLevelFrame), placed by UpdateAnchors.
	local ld = CreateFrame("Frame", nil, uf)
	uf.PlayerLevelDiffFrame = ld
	ld.playerLevelDiffIcon = tex(ld, "BACKGROUND", 0, 0.12, 0.1, 0.06, 1, "ui-hud-nameplates-levelindicator")
	ld.playerLevelDiffIcon:SetAllPoints(ld)
	ld.playerLevelDiffText = text(ld, SystemFont_NamePlateLevel)
	ld.playerLevelDiffText:SetPoint("CENTER", ld, "CENTER", 0, 0)
	ld.selectedBorder = tex(ld, "OVERLAY", 0, 1, 0.85, 0.2, 1, "ui-hud-nameplates-levelindicator-rectangle-selected")
	ld.selectedBorder:SetPoint("TOPLEFT", ld, "TOPLEFT", -3, 3)
	ld.selectedBorder:SetPoint("BOTTOMRIGHT", ld, "BOTTOMRIGHT", 3, -4)
	ld.selectedBorder:Hide()
	ld.highLevelTexture = tex(ld, "OVERLAY", 0, 0.9, 0.9, 0.9, 1, "ui-hud-nameplates-levelindicator-skull")
	ld.highLevelTexture:SetSize(16, 16)
	ld.highLevelTexture:SetPoint("CENTER", ld, "CENTER", 0, 0)
	ld.highLevelTexture:Hide()
	ld:Hide()

	local af = CreateFrame("Frame", nil, uf)
	uf.AurasFrame = af
	af:SetAllPoints(uf)
	for _, k in ipairs({ "DebuffListFrame", "BuffListFrame", "CrowdControlListFrame" }) do
		af[k] = CreateFrame("Frame", nil, af)
		af[k].items = {}
	end

	-- The guards, each frame and region by its path.
	stub.guard(uf, FRAME_CALLS, label)
	for path, f in pairs({ HealthBarsContainer = hc, healthBar = hb, CastBarsContainer = cc, castBar = cb, WidgetContainer = uf.WidgetContainer,
		RaidTargetFrame = uf.RaidTargetFrame, ClassificationFrame = uf.ClassificationFrame, LevelFrame = uf.LevelFrame, AurasFrame = af,
		PlayerLevelDiffFrame = ld,
		DebuffListFrame = af.DebuffListFrame, BuffListFrame = af.BuffListFrame, CrowdControlListFrame = af.CrowdControlListFrame }) do
		stub.guard(f, FRAME_CALLS, label .. "." .. path)
	end
	for k, r in pairs({ bgTexture = hb.bgTexture, selectedBorder = hb.selectedBorder, deselectedOverlay = hb.deselectedOverlay,
		Text = hb.Text, LeftText = hb.LeftText, RightText = hb.RightText, barTexture = hb.barTexture,
		myHealPrediction = hb.myHealPrediction, totalAbsorb = hb.totalAbsorb }) do
		guardRegion(r, label .. ".healthBar." .. k)
	end
	for k, r in pairs({ name = uf.name, selectionHighlight = uf.selectionHighlight, aggroHighlightBase = uf.aggroHighlightBase,
		RaidTargetIcon = uf.RaidTargetFrame.RaidTargetIcon, classificationIndicator = uf.classificationIndicator,
		LevelText = uf.LevelFrame.LevelText, HighLevelTexture = uf.LevelFrame.HighLevelTexture, playerLevelDiffIcon = ld.playerLevelDiffIcon,
		playerLevelDiffText = ld.playerLevelDiffText, ["PlayerLevelDiffFrame.selectedBorder"] = ld.selectedBorder, highLevelTexture = ld.highLevelTexture }) do
		guardRegion(r, label .. "." .. k)
	end
	for _, k in ipairs({ "Background", "Border", "ImportantCastIndicator", "CastTargetIndicator", "Icon", "Text", "CastTargetNameText", "BorderShield", "Spark" }) do
		guardRegion(cb[k], label .. ".castBar." .. k)
	end
	guardRegion(cb:GetStatusBarTexture(), label .. ".castBar's fill")
end

-- An aura item (NameplateAuraItemTemplate), pooled in its list: the icon
-- under the rounded mask, the unnamed overlay ring, the cooldown, the count.
local AURA_SIZE = 18
local function auraItem(list, i, label)
	local it = list.items[i]
	if it then return it end
	it = CreateFrame("Frame", nil, list)
	it:SetSize(AURA_SIZE, AURA_SIZE)
	it:SetPoint("BOTTOMLEFT", list, "BOTTOMLEFT", (i - 1) * AURA_SIZE, 0)
	it.Icon = it:CreateTexture(nil, "ARTWORK")
	it.Icon:SetAllPoints(it)
	local mask = it:CreateMaskTexture()
	mask:SetAllPoints(it)
	mask:SetAtlas("UI-HUD-CoolDownManager-Mask")
	it.Icon:AddMaskTexture(mask)
	local overlay = tex(it, "OVERLAY", 0, 0.12, 0.1, 0.08, 0.6, "UI-HUD-CoolDownManager-IconOverlay")
	overlay:SetPoint("TOPLEFT", it, "TOPLEFT", -2, 2)
	overlay:SetPoint("BOTTOMRIGHT", it, "BOTTOMRIGHT", 2, -2)
	it.Cooldown = CreateFrame("Cooldown", nil, it)
	it.Cooldown:SetAllPoints(it)
	-- The countdown numbers (the client's own string on the Cooldown; large, as live).
	local countdown = text(it.Cooldown, NumberFontNormal)
	countdown:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
	countdown:SetPoint("CENTER", it, "CENTER", 0, 0)
	rawset(it.Cooldown, "GetCountdownFontString", function() return countdown end)
	it.CountFrame = CreateFrame("Frame", nil, it)
	it.CountFrame:SetAllPoints(it)
	it.CountFrame.Count = text(it.CountFrame, rawget(_G, "NumberFontNormalSmall") or NumberFontNormal)
	it.CountFrame.Count:SetPoint("BOTTOMRIGHT", it, "BOTTOMRIGHT", 3, -2)
	list.items[i] = it
	local l = label .. ".aura" .. i
	stub.guard(it, FRAME_CALLS, l)
	stub.guard(it.Cooldown, FRAME_CALLS, l .. ".Cooldown")
	stub.guard(it.CountFrame, FRAME_CALLS, l .. ".CountFrame")
	guardRegion(it.Icon, l .. ".Icon", { "SetPoint", "ClearAllPoints", "SetAllPoints", "SetSize", "SetParent", "Hide", "Show", "SetShown", "SetAtlas", "SetTexture", "SetColorTexture" })
	guardRegion(overlay, l .. "'s overlay")
	guardRegion(it.CountFrame.Count, l .. ".Count", COUNT_CALLS)
	guardRegion(countdown, l .. "'s countdown", COUNT_CALLS)
	return it
end

---------------------------------------------------------------------------
-- The game's code: NamePlateUnitFrameMixin and CompactUnitFrame
---------------------------------------------------------------------------

-- Thin (the Camelot default) and the others by their health, cast and name layout; nameplateSize scales them.
-- (GetHealthBarHeight, GetCastBarHeight, GetUnitNameAnchorStyle, IsSpellNameInsideCastBar in Blizzard_NamePlates.lua)
local STYLES = {
	[0] = { health = 20, cast = 6, inside = true }, -- Modern
	[1] = { health = 13, cast = 6 }, -- Thin
	[2] = { health = 20, cast = 16, inside = true, spellInside = true }, -- Block
	[3] = { health = 20, cast = 6 }, -- HealthFocus
	[4] = { health = 13, cast = 16, spellInside = true }, -- CastFocus
}
-- NAME_PLATE_SCALES by nameplateSize: horizontal, vertical.
local SCALES = { { 0.75, 0.8 }, { 1, 1 }, { 1.25, 1.25 }, { 1.4, 1.4 }, { 1.6, 1.6 } }
stub.anchorRuns = 0

NamePlateUnitFrameMixin = rawget(_G, "NamePlateUnitFrameMixin") or {}
local Mx = NamePlateUnitFrameMixin

function Mx:UpdateAnchors()
	stub.anchorRuns = stub.anchorRuns + 1
	local style = STYLES[tonumber(stub.cvars.nameplateStyle) or 1] or STYLES[1]
	local k = SCALES[tonumber(stub.cvars.nameplateSize) or 2] or SCALES[2]
	local w, hh, ch, icon = 166 * k[1], style.health * k[2], style.cast * k[2], 10 * k[2]
	local hc, hb, cc = self.HealthBarsContainer, self.healthBar, self.CastBarsContainer
	-- Camelot's level badge right of the bar, the bar narrowed by its width and gap (NameplateLevelFrame).
	local ld = self.PlayerLevelDiffFrame
	local badge = ld:IsShown() and 28 * k[2] + 5 or 0
	cc:ClearAllPoints()
	cc:SetPoint("TOP", self, "TOP", 0, style.inside and -36 or -38)
	cc:SetSize(w, style.spellInside and ch or ch + icon)
	hc:ClearAllPoints()
	hc:SetPoint("BOTTOMLEFT", cc, "TOPLEFT", 0, 2)
	hc:SetSize(w - badge, hh)
	ld:ClearAllPoints()
	ld:SetPoint("TOPLEFT", hb, "TOPRIGHT", 5, 3)
	ld:SetPoint("BOTTOMLEFT", hb, "BOTTOMRIGHT", 5, -2)
	ld:SetWidth(28 * k[2])
	-- The cast bar (NamePlateCastingBarMixin:ApplyStyleAndAnchoring): the spell's name inside a large bar, else
	-- the bar on top and the icon and name under it; the shield where the icon is.
	local cb = cc.castBar
	cb:ClearAllPoints()
	cb.Icon:ClearAllPoints()
	cb.Icon:SetSize(icon, icon)
	if style.spellInside then
		cb:SetAllPoints(cc)
		cb.Icon:SetPoint("LEFT", cb, "LEFT", 0, 0)
	else
		cb.Icon:SetPoint("BOTTOMLEFT", cc, "BOTTOMLEFT", 0, 0)
		cb:SetPoint("TOPLEFT", cc, "TOPLEFT", 0, 0)
		cb:SetPoint("TOPRIGHT", cc, "TOPRIGHT", 0, 0)
		cb:SetHeight(ch)
	end
	cb.Text:ClearAllPoints()
	cb.Text:SetPoint("LEFT", cb.Icon, "RIGHT", 2, 0)
	cb.CastTargetNameText:ClearAllPoints()
	cb.CastTargetNameText:SetPoint("LEFT", cb.Text, "RIGHT", 2, 0)
	cb.CastTargetNameText:SetPoint("RIGHT", cb, "RIGHT", -4, 0)
	cb.BorderShield:ClearAllPoints()
	cb.BorderShield:SetPoint("RIGHT", cb.Icon, "RIGHT", 0, 0)
	-- The health texts inside the bar's right end, right to left (UpdateAnchors' InsideHealthBar and Camelot's
	-- healthTextInsideBarWhenNameAboveHealthBar); the name inside the bar (Modern, Block) or above it, centred.
	hb.LeftText:ClearAllPoints()
	hb.LeftText:SetPoint("RIGHT", hb, "RIGHT", -4, 0)
	hb.RightText:ClearAllPoints()
	hb.RightText:SetPoint("RIGHT", hb.LeftText, "LEFT", -2, 0)
	hb.Text:ClearAllPoints()
	hb.Text:SetPoint("RIGHT", hb.RightText, "LEFT", 2, 0)
	self.name:ClearAllPoints()
	if style.inside then
		self.name:SetPoint("LEFT", hc, "LEFT", 4, 0)
		self.name:SetPoint("RIGHT", hb.Text, "LEFT", -2, 0)
		self.name:SetJustifyH("LEFT")
	else
		self.name:SetPoint("BOTTOMLEFT", hc, "TOPLEFT", 0, 2)
		self.name:SetPoint("RIGHT", ld:IsShown() and ld or hc, "RIGHT", 0, 0)
		self.name:SetJustifyH("CENTER")
	end
	self.name:SetFontObject(SystemFont_NamePlate_Outlined) -- Camelot: outlined above the bar too
	for _, t in ipairs({ hb.Text, hb.LeftText, hb.RightText }) do t:SetFontObject(SystemFont_NamePlate) end
	hb.selectedBorder:ClearAllPoints()
	hb.selectedBorder:SetPoint("TOPLEFT", hb, "TOPLEFT", -3, 2)
	hb.selectedBorder:SetPoint("BOTTOMRIGHT", hb, "BOTTOMRIGHT", 0, -2)
	-- The atlases set again (alpha kept, as SetAtlas keeps it).
	hb.barTexture:SetAtlas("UI-HUD-CoolDownManager-Bar")
	hb.bgTexture:SetAtlas("UI-HUD-CoolDownManager-Bar-BG")
	hb.selectedBorder:SetAtlas("UI-HUD-CoolDownManager-Selected-yellow")
	ld.playerLevelDiffIcon:SetAtlas("ui-hud-nameplates-levelindicator")
	self.RaidTargetFrame:ClearAllPoints()
	self.RaidTargetFrame:SetPoint("RIGHT", hc, "LEFT", -4, 0)
	self.RaidTargetFrame:SetSize(18, 18)
	self.ClassificationFrame:ClearAllPoints()
	self.ClassificationFrame:SetPoint("RIGHT", hc, "LEFT", -2, 0)
	self.ClassificationFrame:SetSize(14, 14)
	self.LevelFrame:ClearAllPoints()
	self.LevelFrame:SetPoint("BOTTOMRIGHT", hc, "TOPRIGHT", 0, 2)
	self.LevelFrame:SetSize(20, 12)
	local af = self.AurasFrame
	af.DebuffListFrame:ClearAllPoints()
	af.DebuffListFrame:SetPoint("BOTTOMLEFT", hc, "TOPLEFT", 0, style.inside and 4 or 18)
	af.DebuffListFrame:SetSize(w, 16)
	af.BuffListFrame:ClearAllPoints()
	af.BuffListFrame:SetPoint("BOTTOMLEFT", af.DebuffListFrame, "TOPLEFT", 0, 2)
	af.BuffListFrame:SetSize(w, 16)
	af.CrowdControlListFrame:ClearAllPoints()
	af.CrowdControlListFrame:SetPoint("LEFT", hc, "RIGHT", 5 + badge, 0)
	af.CrowdControlListFrame:SetSize(40, 16)
end

function Mx:UpdateThreatDisplay()
	local bits = stub.cvarBits.nameplateThreatDisplay or {}
	self.displayAggroHighlight = bits[1] == true
	self.displayAggroFlash = bits[2] == true
	self.displayThreatHealthBarColor = bits[3] == true
end

function Mx:UpdateHealth()
	local d = plateData(self.unit)
	if not d then return end
	local hb = self.healthBar
	hb:SetMinMaxValues(0, stub.secret(d.max or 100))
	hb:SetValue(stub.secret(d.health or d.max or 100))
	local bits = stub.cvarBits.nameplateInfoDisplay or {}
	-- SetBarText(Text, RightText, LeftText): the percentage is LeftText, at the right end.
	hb.LeftText:SetShown(bits[1] == true)
	if bits[1] then hb.LeftText:SetFormattedText("%d%%", stub.secret(math.floor((d.health or 100) / (d.max or 100) * 100 + 0.5))) end
	hb.RightText:SetShown(bits[2] == true)
	if bits[2] then hb.RightText:SetFormattedText("%s", AbbreviateNumbers(stub.secret(d.health or 100))) end
end

-- CompactUnitFrame_UpdateName, called by name (a post-hook on the global runs after it).
function CompactUnitFrame_UpdateName(frame)
	local d = plateData(frame.unit)
	if d then frame.name:SetText(d.secret and stub.secret(d.name or "") or d.name or "") end
end
function Mx:UpdateName() CompactUnitFrame_UpdateName(self) end

function Mx:UpdateIsTarget()
	local d = plateData(self.unit)
	if not d then return end
	local hb = self.healthBar
	hb.selectedBorder:SetShown(d.target == true or d.focus == true)
	if d.focus and not d.target then hb.selectedBorder:SetVertexColor(1, 0.49, 0.039) else hb.selectedBorder:SetVertexColor(1, 1, 1) end
	hb.deselectedOverlay:SetShown(stub.plateTarget ~= nil and not d.target)
	self.selectionHighlight:SetShown(d.target == true)
	local ld = self.PlayerLevelDiffFrame.selectedBorder
	ld:SetShown(d.target == true or d.focus == true)
	if d.focus and not d.target then ld:SetVertexColor(1, 0.49, 0.039) else ld:SetVertexColor(1, 1, 1) end
end
Mx.UpdateIsFocus = Mx.UpdateIsTarget

function Mx:UpdateRaidTarget()
	local d = plateData(self.unit)
	local i = d and d.raidTarget
	self.RaidTargetFrame:SetShown(i ~= nil and not d.widgetsOnly)
	if i then self.RaidTargetFrame.RaidTargetIcon:SetTexCoord(((i - 1) % 4) / 4, ((i - 1) % 4 + 1) / 4, math.floor((i - 1) / 4) / 4, (math.floor((i - 1) / 4) + 1) / 4) end
	self:UpdateClassification()
end

local CLASSIFICATION = { elite = "nameplates-icon-elite-gold", worldboss = "nameplates-icon-elite-gold",
	rare = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Star", rareelite = "nameplates-icon-elite-silver" }
function Mx:UpdateClassification()
	local d = plateData(self.unit)
	-- Hidden while a raid icon is set.
	local atlas = d and not d.raidTarget and not d.widgetsOnly and CLASSIFICATION[d.classification or "normal"]
	self.ClassificationFrame:SetShown(atlas ~= nil and atlas ~= false)
	if atlas then
		self.classificationIndicator:SetAtlas(atlas)
		self.classificationIndicator:SetColorTexture(atlas:find("silver") and 0.8 or 0.95, atlas:find("silver") and 0.8 or 0.75, atlas:find("silver") and 0.85 or 0.2, 1)
	end
end

-- CompactUnitFrame_UpdatePlayerLevelDiff, called by name: Camelot's badge (ShouldDisplay: not for a game
-- object or a name-only friendly player), the level in the difficulty colour, the skull for ??.
-- The game's code sees the level itself (a secret identity is secret only to addons).
function CompactUnitFrame_UpdatePlayerLevelDiff(frame)
	local d = plateData(frame.unit)
	local ld = frame.PlayerLevelDiffFrame
	local friendlyNameOnly = d and d.player and (d.reaction or 4) >= 5 and stub.cvars.nameplateShowOnlyNameForFriendlyPlayerUnits == "1"
	local show = d ~= nil and not d.widgetsOnly and not friendlyNameOnly
	ld:SetShown(show)
	if not show then return end
	ld.highLevelTexture:SetShown(d.level == -1)
	ld.playerLevelDiffText:SetShown(d.level ~= -1)
	if d.level ~= -1 then
		local diff = (d.level or 1) - (UnitLevel("player") or 1)
		local c = GetDifficultyColor(diff >= 5 and 4 or diff >= 3 and 3 or diff >= -4 and 2 or -diff <= 8 and 1 or 0)
		ld.playerLevelDiffText:SetText(tostring(d.level or 1))
		ld.playerLevelDiffText:SetTextColor(c.r, c.g, c.b)
	end
end
function Mx:UpdateLevel() CompactUnitFrame_UpdatePlayerLevelDiff(self) end

function Mx:UpdateAggro()
	local d = plateData(self.unit)
	self.aggroHighlightBase:SetShown(self.displayAggroHighlight == true and d ~= nil and (d.threat or 0) > 0)
	CompactUnitFrame_UpdateHealthColor(self)
end

function Mx:RefreshAuras()
	local d = plateData(self.unit)
	local label = self.psLabel
	for _, spec in ipairs({ { "DebuffListFrame", "auras" }, { "BuffListFrame", "buffs" } }) do
		local list, auras = self.AurasFrame[spec[1]], d and not d.widgetsOnly and d[spec[2]] or {}
		for i = 1, math.max(#auras, #list.items) do
			local a = auras[i]
			local it = auraItem(list, i, label .. "." .. spec[1])
			it:SetShown(a ~= nil)
			if a then
				it.Icon:SetTexture(a.icon or 136116)
				it.CountFrame.Count:SetText((a.count or 0) > 1 and tostring(a.count) or "")
				it.Cooldown:GetCountdownFontString():SetText(a.timer and tostring(a.timer) or "")
			end
		end
	end
end

function Mx:UpdateWidgetsOnly()
	local d = plateData(self.unit)
	local only = d ~= nil and d.widgetsOnly == true
	local friendlyNameOnly = d and d.player and (d.reaction or 4) >= 5 and stub.cvars.nameplateShowOnlyNameForFriendlyPlayerUnits == "1"
	self.HealthBarsContainer:SetShown(not only and not friendlyNameOnly)
	self.WidgetContainer:SetShown(only)
	self.name:SetShown(not only)
end

function Mx:OnEvent(event, unit)
	if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then return self:UpdateIsTarget() end
	if event == "RAID_TARGET_UPDATE" then return self:UpdateRaidTarget() end
	if unit ~= self.unit then return end
	if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
		self:UpdateHealth()
		CompactUnitFrame_UpdateHealthColor(self)
	elseif event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" then
		self:UpdateAggro()
	elseif event == "UNIT_FACTION" or event == "UNIT_CONNECTION" then
		CompactUnitFrame_UpdateHealthColor(self)
		self:UpdateLevel()
	elseif event == "UNIT_NAME_UPDATE" then
		self:UpdateName()
		CompactUnitFrame_UpdateHealthColor(self)
	elseif event == "UNIT_CLASSIFICATION_CHANGED" then
		self:UpdateClassification()
	elseif event == "UNIT_LEVEL" then
		self:UpdateLevel()
	elseif event == "UNIT_AURA" then
		self:RefreshAuras()
	end
end

local UNIT_EVENTS = { "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_THREAT_SITUATION_UPDATE", "UNIT_THREAT_LIST_UPDATE", "UNIT_FACTION",
	"UNIT_CONNECTION", "UNIT_NAME_UPDATE", "UNIT_CLASSIFICATION_CHANGED", "UNIT_LEVEL", "UNIT_AURA" }

function Mx:OnUnitSet()
	for _, e in ipairs(UNIT_EVENTS) do self:RegisterUnitEvent(e, self.unit) end
	for _, e in ipairs({ "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "RAID_TARGET_UPDATE" }) do self:RegisterEvent(e) end
	self:UpdateThreatDisplay()
	self:UpdateLevel() -- before the layout: the badge narrows the bar
	self:UpdateAnchors()
	self:UpdateWidgetsOnly()
	self:UpdateName()
	self:UpdateHealth()
	self:UpdateIsTarget()
	self:UpdateRaidTarget()
	self:UpdateLevel()
	self:UpdateAggro()
	self:RefreshAuras()
end

function Mx:OnUnitCleared()
	self:UnregisterAllEvents()
	self.CastBarsContainer.castBar:Hide()
	self.CastBarsContainer.castBar.casting, self.CastBarsContainer.castBar.channeling = nil, nil
	self.healthBar.psSecretColor = nil
	self.unit, self.displayedUnit = nil, nil
end

-- CompactUnitFrame_UpdateHealthColor, called by name (so a post-hook on the
-- global runs after it), with the game's colours.
local THREAT = { { 1, 1, 0.47 }, { 1, 1, 0.47 }, { 1, 0, 0 } }
function CompactUnitFrame_UpdateHealthColor(frame)
	local d = plateData(frame.unit)
	if not d then return end
	local r, g, b
	local friend = (d.reaction or 4) >= 5
	local classOn = stub.cvars[friend and "nameplateShowFriendlyClassColor" or "nameplateShowClassColor"] == "1"
	if frame.displayThreatHealthBarColor and (d.threat or 0) > 0 then
		r, g, b = unpack(THREAT[d.threat] or THREAT[1])
	elseif d.dead or d.offline then
		r, g, b = 0.5, 0.5, 0.5
	elseif d.player and d.class and classOn and RAID_CLASS_COLORS[d.class] then
		local c = RAID_CLASS_COLORS[d.class]
		r, g, b = c.r, c.g, c.b
	elseif d.tapped then
		r, g, b = 0.9, 0.9, 0.9
	elseif friend and d.player then
		r, g, b = 0.667, 0.667, 1
	elseif friend then
		r, g, b = 0, 1, 0
	elseif (d.reaction or 4) == 4 then
		r, g, b = 1, 1, 0
	else
		r, g, b = 1, 0, 0
	end
	local hb = frame.healthBar
	hb.psSecretColor = d.secret or nil
	local c = rawget(hb, "barColor")
	if not c or c[1] ~= r or c[2] ~= g or c[3] ~= b then
		hb:SetStatusBarColor(r, g, b)
		hb.barTexture:SetAlpha(1) -- SetStatusBarColor writes the fill's alpha
		stub.colourRuns = (stub.colourRuns or 0) + 1
	end
end

-- The cast bar's handling (CastingBarMixin, as the game's code).
local CAST_COLOURS = { standard = { 1, 0.7, 0 }, channel = { 0.1, 0.8, 0.1 }, uninterruptable = { 0.6, 0.6, 0.6 }, interrupted = { 0.9, 0.1, 0.1 } }
local function castEvent(cb, event, unit)
	local uf = cb:GetParent():GetParent()
	if unit ~= uf.unit then return end
	local c = stub.casts[unit]
	local bits = stub.cvarBits.nameplateCastBarDisplay or {}
	if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
		local kind = c.locked and "uninterruptable" or c.channel and "channel" or "standard"
		cb.barType = kind
		cb:SetStatusBarTexture(WHITE)
		local col = CAST_COLOURS[kind]
		cb:SetStatusBarColor(col[1], col[2], col[3], 1)
		cb:GetStatusBarTexture():SetAlpha(1)
		cb:SetMinMaxValues(0, stub.secret(c.time))
		cb:SetValue(stub.secret(c.channel and (c.elapsed or c.time) or c.elapsed or 0))
		cb.Text:SetText(bits[1] and stub.secret(c.name) or "")
		cb.Icon:SetShown(bits[2] == true)
		if bits[2] then cb.Icon:SetColorTexture(0.3, 0.5, 0.85, 1) end
		cb.CastTargetNameText:SetShown(bits[3] == true and c.targetName ~= nil)
		if bits[3] and c.targetName then cb.CastTargetNameText:SetText(stub.secret(c.targetName)) end
		cb.ImportantCastIndicator:SetShown(bits[4] == true and c.important == true)
		cb.CastTargetIndicator:SetShown(bits[5] == true and c.targetsPlayer == true)
		cb.BorderShield:SetShown(c.locked == true)
		cb.casting, cb.channeling = not c.channel or nil, c.channel or nil
		cb.Spark:Show()
		cb:SetAlpha(1)
		cb:Show()
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
		if not (cb.casting or cb.channeling) then return end
		cb:SetStatusBarColor(0.9, 0.1, 0.1, 1)
		cb.Text:SetText("Interrupted")
		cb.casting, cb.channeling = nil, nil
		cb.Spark:Hide()
		stub.casts[unit] = nil
	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		cb.casting, cb.channeling = nil, nil
		cb.Spark:Hide()
		cb:Hide()
		stub.casts[unit] = nil
	end
end

---------------------------------------------------------------------------
-- The driver, pools and base plates
---------------------------------------------------------------------------

NamePlateDriverFrame = CreateFrame("Frame", "NamePlateDriverFrame", UIParent)
local driver = NamePlateDriverFrame
stub.plates, stub.unitFrames = {}, {}
local pools = { normal = {}, forbidden = {} }
local basePlates, freePlates = {}, {}
local order = {} -- units in the order added, for the auto layout
stub.plateUnits = {} -- every unit the stub knows, shown or held back by CVars

-- Anything of a forbidden plate used from our code errors.
local function forbid(f, label)
	rawset(f, "IsForbidden", function() return true end)
	local mt = getmetatable(f)
	local index = mt.__index
	setmetatable(f, {
		__index = function(t, k)
			if k ~= "IsForbidden" and ours(2) then breach("Polestar: UI touched " .. label .. " (forbidden)") end
			if type(index) == "function" then return index(t, k) end
			return index[k]
		end,
		__newindex = function(t, k, v)
			if ours(2) then breach("Polestar: UI wrote " .. tostring(k) .. " on " .. label .. " (forbidden)") end
			rawset(t, k, v)
		end,
	})
end

local function acquire(kind)
	local free = pools[kind]
	local uf = table.remove(free)
	if uf then return uf end
	local n = #stub.unitFrames + 1
	uf = CreateFrame("Button", nil, driver)
	Mixin(uf, NamePlateUnitFrameMixin) -- copied when the frame is made: later hooks on the mixin miss it
	local label = (kind == "forbidden" and "a forbidden UnitFrame " or "UnitFrame ") .. n
	uf.psLabel = label
	uf.psKind = kind
	uf:SetScript("OnEvent", function(self, ...) self:OnEvent(...) end)
	build(uf, label)
	uf.CastBarsContainer.castBar:SetScript("OnEvent", castEvent)
	for _, e in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_STOP",
		"UNIT_SPELLCAST_INTERRUPTED" }) do
		uf.CastBarsContainer.castBar:RegisterEvent(e)
	end
	if kind == "forbidden" then forbid(uf, label) end
	stub.unitFrames[n] = uf
	return uf
end

local function basePlate(forbidden)
	local p = table.remove(freePlates[forbidden and "f" or "n"] or {})
	if p then return p end
	local n = #basePlates + 1
	p = CreateFrame("Frame", "NamePlate" .. n, UIParent)
	p:SetSize(190, 60)
	basePlates[n] = p
	stub.fire(forbidden and "FORBIDDEN_NAME_PLATE_CREATED" or "NAME_PLATE_CREATED", p)
	stub.guard(p, FRAME_CALLS, "NamePlate" .. n)
	-- A plate with no unit has no UnitFrame (the generic stub answers a noop for capitalised keys).
	local mt = getmetatable(p)
	local index = mt.__index
	mt.__index = function(t, k)
		if k == "UnitFrame" or k == "namePlateUnitToken" then return nil end
		return index(t, k)
	end
	if forbidden then forbid(p, "NamePlate" .. n) end
	return p
end

driver:SetScript("OnEvent", function(_, event, unit)
	if event == "NAME_PLATE_UNIT_ADDED" or event == "FORBIDDEN_NAME_PLATE_UNIT_ADDED" then
		local p = stub.plates[unit]
		local uf = acquire(event == "NAME_PLATE_UNIT_ADDED" and "normal" or "forbidden")
		rawset(p, "UnitFrame", uf)
		uf:SetParent(p)
		uf:ClearAllPoints()
		uf:SetAllPoints(p)
		uf.unit, uf.displayedUnit = unit, unit
		uf:Show()
		uf:OnUnitSet()
	elseif event == "NAME_PLATE_UNIT_REMOVED" or event == "FORBIDDEN_NAME_PLATE_UNIT_REMOVED" then
		local p = stub.plates[unit]
		local uf = p and rawget(p, "UnitFrame")
		if not uf then return end
		uf:OnUnitCleared()
		uf:Hide()
		uf:ClearAllPoints()
		uf:SetParent(driver)
		rawset(p, "UnitFrame", nil)
		table.insert(pools[uf.psKind], uf)
	elseif event == "CVAR_UPDATE" then
		if unit == "nameplateStyle" or unit == "nameplateSize" then
			for _, p in pairs(stub.plates) do local uf = rawget(p, "UnitFrame") if uf then uf:UpdateAnchors() end end
		elseif unit == "nameplateThreatDisplay" then
			for _, p in pairs(stub.plates) do local uf = rawget(p, "UnitFrame") if uf then uf:UpdateThreatDisplay() uf:UpdateAggro() end end
		elseif unit == "nameplateInfoDisplay" then
			for _, p in pairs(stub.plates) do local uf = rawget(p, "UnitFrame") if uf then uf:UpdateHealth() end end
		else
			stub.refreshPlates()
		end
	end
end)
for _, e in ipairs({ "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "FORBIDDEN_NAME_PLATE_UNIT_ADDED", "FORBIDDEN_NAME_PLATE_UNIT_REMOVED", "CVAR_UPDATE" }) do
	driver:RegisterEvent(e)
end
function driver:GetNamePlateForUnit(unit) return stub.plates[unit] end
stub.guard(driver, FRAME_CALLS, "NamePlateDriverFrame")
stub.secureNames.NamePlateDriverFrame = true

C_NamePlate = rawget(_G, "C_NamePlate") or {}
function C_NamePlate.GetNamePlateForUnit(unit, includeForbidden)
	local p, d = stub.plates[unit], plateData(unit)
	if p and d and d.forbidden and not includeForbidden then return nil end
	if p and d and d.forbidden and ours(2) then return nil end -- issecure() is false for us
	return p
end
function C_NamePlate.GetNamePlates(includeForbidden)
	local list = {}
	for _, unit in ipairs(order) do
		local p, d = stub.plates[unit], plateData(unit)
		if p and not (d.forbidden and (not includeForbidden or ours(2))) then list[#list + 1] = p end
	end
	return list
end
function C_NamePlate.GetNamePlateSize() return 190, 60 end
function C_NamePlate.SetNamePlateSize()
	if ours(2) then breach("Polestar: UI called C_NamePlate.SetNamePlateSize (the plates' size is the game's)") end
end

-- Whether the CVars let the client show this unit a plate.
local function allowed(d)
	if (d.reaction or 4) <= 4 then return stub.cvars.nameplateShowEnemies == "1" end
	if d.player then return stub.cvars.nameplateShowFriendlyPlayers == "1" end
	return stub.cvars.nameplateShowFriendlyNpcs == "1"
end

local function show(unit)
	local d = stub.plateData[unit]
	local p = basePlate(d.forbidden)
	stub.plates[unit] = p
	rawset(p, "namePlateUnitToken", unit)
	order[#order + 1] = unit
	local i = #order
	p:ClearAllPoints()
	p:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", d.x or (60 + ((i - 1) % 4) * 230), d.y or (720 - math.floor((i - 1) / 4) * 110))
	p:Show()
	stub.fire(d.forbidden and "FORBIDDEN_NAME_PLATE_UNIT_ADDED" or "NAME_PLATE_UNIT_ADDED", unit)
	return p
end
local function hide(unit)
	local p, d = stub.plates[unit], stub.plateData[unit]
	if not p then return end
	stub.fire(d.forbidden and "FORBIDDEN_NAME_PLATE_UNIT_REMOVED" or "NAME_PLATE_UNIT_REMOVED", unit)
	p:Hide()
	rawset(p, "namePlateUnitToken", nil)
	stub.plates[unit] = nil
	for i, u in ipairs(order) do if u == unit then table.remove(order, i) break end end
	local key = d.forbidden and "f" or "n"
	freePlates[key] = freePlates[key] or {}
	table.insert(freePlates[key], p)
end

-- The CVars changed: plates the client now hides go, ones it now allows come.
function stub.refreshPlates()
	for _, unit in ipairs(stub.plateUnits) do
		local d = stub.plateData[unit]
		local want = allowed(d)
		if want and not stub.plates[unit] then show(unit) elseif not want and stub.plates[unit] then hide(unit) end
	end
end

function stub.addPlate(unit, o)
	o = o or {}
	local d = {}
	for k, v in pairs(o) do d[k] = v end
	d.name, d.max = d.name or unit, d.max or 100
	d.health = d.health or d.max
	stub.plateData[unit] = d
	-- The unit API (stub_unitframes.lua) answers from stub.units.
	stub.units[unit] = d
	table.insert(stub.plateUnits, unit)
	if not allowed(d) then return nil end
	return show(unit)
end

function stub.removePlate(unit)
	hide(unit)
	stub.plateData[unit], stub.units[unit] = nil, nil
	for i, u in ipairs(stub.plateUnits) do if u == unit then table.remove(stub.plateUnits, i) break end end
end

local FIRES = { health = "UNIT_HEALTH", max = "UNIT_MAXHEALTH", threat = "UNIT_THREAT_SITUATION_UPDATE", reaction = "UNIT_FACTION",
	tapped = "UNIT_FACTION", dead = "UNIT_HEALTH", class = "UNIT_NAME_UPDATE", player = "UNIT_FACTION", name = "UNIT_NAME_UPDATE",
	classification = "UNIT_CLASSIFICATION_CHANGED", raidTarget = "RAID_TARGET_UPDATE", level = "UNIT_LEVEL", auras = "UNIT_AURA",
	buffs = "UNIT_AURA", secret = "UNIT_FACTION" }
function stub.updatePlate(unit, changes)
	local d = stub.plateData[unit]
	local fired = {}
	for k, v in pairs(changes) do
		d[k] = v
		local e = FIRES[k]
		if e and not fired[e] then fired[e] = true end
	end
	for _, e in ipairs({ "UNIT_MAXHEALTH", "UNIT_HEALTH", "UNIT_FACTION", "UNIT_THREAT_SITUATION_UPDATE", "UNIT_NAME_UPDATE",
		"UNIT_CLASSIFICATION_CHANGED", "UNIT_LEVEL", "UNIT_AURA", "RAID_TARGET_UPDATE" }) do
		if fired[e] then stub.fire(e, unit) end
	end
	if changes.widgetsOnly ~= nil and stub.plates[unit] then
		local uf = rawget(stub.plates[unit], "UnitFrame")
		if uf then uf:UpdateWidgetsOnly() uf:RefreshAuras() uf:UpdateRaidTarget() end
	end
end

function stub.targetPlate(unit)
	for u, d in pairs(stub.plateData) do d.target = (u == unit) or nil end
	stub.plateTarget = unit
	stub.fire("PLAYER_TARGET_CHANGED")
end
function stub.focusPlate(unit)
	for u, d in pairs(stub.plateData) do d.focus = (u == unit) or nil end
	stub.fire("PLAYER_FOCUS_CHANGED")
end

function stub.plateCast(unit, c)
	stub.casts[unit] = c
	stub.fire(c.channel and "UNIT_SPELLCAST_CHANNEL_START" or "UNIT_SPELLCAST_START", unit)
end
function stub.plateCastEnd(unit, how)
	local c = stub.casts[unit]
	if how == "interrupt" then return stub.fire("UNIT_SPELLCAST_INTERRUPTED", unit) end
	stub.fire(c and c.channel and "UNIT_SPELLCAST_CHANNEL_STOP" or "UNIT_SPELLCAST_STOP", unit)
end

function stub.setCVarBits(cvar, bits)
	stub.cvarBits[cvar] = bits
	for _, c in ipairs(CVarCallbackRegistry.callbacks[cvar] or {}) do c.fn(c.owner, bits) end
	stub.fire("CVAR_UPDATE", cvar)
end
