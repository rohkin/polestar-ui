-- Unit frames (Modules/UnitFrames.lua): the client's unit API with its secret
-- values, secure unit buttons and the unit watch, the stock unit frames as
-- Edit Mode systems (docs/CLIENT.md, rule 16), and Edit Mode itself. Loaded
-- for every scene (tools/preview.js): our unit frames are built at every
-- login. Nothing here changes a scene that sets no stub.units.

local M = stub.Methods
local noop = function() end

---------------------------------------------------------------------------
-- Secret values (CLIENT.md, rule 3)
---------------------------------------------------------------------------

-- stub.secret(v): a secret holding v. Addon code may not compare it or do
-- maths on it (a table: Lua errors), only hand it to what takes secrets
-- (StatusBar values, SetFormattedText, AbbreviateNumbers). The preview shows
-- what it holds, as the client draws it.
local SECRET_MT = { __tostring = function(s) return tostring(s.v) end }
function stub.secret(v) return setmetatable({ v = v }, SECRET_MT) end
local function held(v) return type(v) == "table" and getmetatable(v) == SECRET_MT end
local isSecret = issecretvalue
function issecretvalue(v) return held(v) or isSecret(v) end
function stub.reveal(v) if held(v) then return v.v end return v end

-- FontString:SetFormattedText takes secrets from addon code; plain SetText
-- of a secret stays an error on our strings (stub_client.lua).
local setFormatted = M.SetFormattedText
function M.SetFormattedText(self, fmt, ...)
	local n, args = select("#", ...), { ... }
	for i = 1, n do args[i] = stub.reveal(args[i]) end
	return setFormatted(self, fmt, unpack(args, 1, n))
end

local function abbreviate(v)
	if v >= 1e6 then return string.format("%.1fM", v / 1e6) end
	if v >= 1e4 then return string.format("%.1fK", v / 1e3) end
	return tostring(math.floor(v + 0.5))
end
function AbbreviateNumbers(v)
	if held(v) then return stub.secret(abbreviate(v.v)) end
	return abbreviate(v)
end

-- A frame anchored to a StatusBar's fill texture: the fill's edge moves with
-- the bar's secret value, so the frame's size is secret too. Its OnSizeChanged
-- hands secret numbers on, and SetWidth refuses a secret from addon code.
-- (Only the bar's children are looked at: the preview stub owns SetPoint.)
local setValue, setWidth = M.SetValue, M.SetWidth
function M.SetValue(self, v, interpolation)
	setValue(self, v)
	self.interpolation = interpolation
	local fill = self.barTexture
	if not (held(v) and fill) then return end
	for _, f in ipairs(self.children or {}) do
		for _, p in ipairs(f.points or {}) do
			if p.rel == fill then
				stub.RunScript(f, "OnSizeChanged", stub.secret(f:GetWidth()), stub.secret(f:GetHeight()))
				break
			end
		end
	end
end
function M.SetWidth(self, w)
	if held(w) then error("bad argument #1 to 'SetWidth' (Secret values are only allowed during untainted execution)", 2) end
	return setWidth(self, w)
end

---------------------------------------------------------------------------
-- Units: stub.units[unit] = { name, level, class (file), player, reaction,
-- classification, health, max, power, powerMax, powerType, dead, ghost,
-- offline, tapped, threat, heals, absorbs, combat, visible }
---------------------------------------------------------------------------

stub.units = {}
stub.vehicle = false
-- The client's default status text (Interface > Status Text: None).
stub.cvars.statusText, stub.cvars.statusTextDisplay = "0", "NONE"
local PLAYER = { name = "Testchar", level = 24, class = "WARRIOR", player = true, health = 1000, max = 1000, power = 40, powerMax = 100, powerType = 1, reaction = 5 }
local function data(unit)
	if unit == "vehicle" and not stub.vehicle then return nil end
	return stub.units[unit] or (unit == "player" and PLAYER) or nil
end

-- Wraps global `name`: our answer for units the stub knows, the earlier one else.
local function unitFn(name, fn, default)
	local base = _G[name]
	_G[name] = function(unit, ...)
		local d = data(unit)
		if d then return fn(d, unit, ...) end
		if base then return base(unit, ...) end
		return default
	end
end

-- The client's heal prediction calculator (UnitGetDetailedHealPrediction),
-- with the clamps the unit frames ask for: heals and heal absorbs netted,
-- heals up to the missing health, shields up to what is still missing after
-- them, heal absorbs up to the health. Amounts and "clamped" flags secret.
Enum.UnitIncomingHealClampMode = { MissingHealth = 0, MaximumHealth = 1 }
Enum.UnitDamageAbsorbClampMode = { MissingHealth = 0, MissingHealthWithoutIncomingHeals = 1, MaximumHealth = 2 }
Enum.UnitHealAbsorbClampMode = { CurrentHealth = 0, MaximumHealth = 1 }
Enum.UnitHealAbsorbMode = { ReducedByIncomingHeals = 0, Total = 1 }
Enum.StatusBarInterpolation = { Immediate = 0, ExponentialEaseOut = 1 }
local CALC = {}
CALC.__index = CALC
for _, n in ipairs({ "SetIncomingHealClampMode", "SetDamageAbsorbClampMode", "SetHealAbsorbClampMode", "SetHealAbsorbMode" }) do
	CALC[n] = function(c, v) c[n] = v end
end
function CALC.GetIncomingHeals(c) return stub.secret(c.heals), stub.secret(c.heals), stub.secret(0), stub.secret(c.healsOver) end
function CALC.GetDamageAbsorbs(c) return stub.secret(c.absorbs), stub.secret(c.absorbsOver) end
function CALC.GetHealAbsorbs(c) return stub.secret(c.healAbsorbs), stub.secret(c.healAbsorbsOver) end
function CreateUnitHealPredictionCalculator() return setmetatable({}, CALC) end
function UnitGetDetailedHealPrediction(unit, _, c)
	local d = data(unit) or {}
	local hp, max = d.health or 0, d.max or 1
	local heals, ha = d.heals or 0, d.healAbsorbs or 0
	heals, ha = math.max(0, heals - ha), math.max(0, ha - heals)
	local missing = max - hp
	c.heals, c.healsOver = math.min(heals, missing), heals > missing
	c.healAbsorbs, c.healAbsorbsOver = math.min(ha, hp), ha > hp
	local room = math.max(0, missing - c.heals)
	c.absorbs, c.absorbsOver = math.min(d.absorbs or 0, room), (d.absorbs or 0) > room
end

-- Region:SetAlphaFromBoolean takes a secret boolean from addon code.
function M.SetAlphaFromBoolean(self, b, yes, no)
	self.alphaFromBoolean = true
	self:SetAlpha(stub.reveal(b) and (yes or 1) or (no or 0))
end

-- The player's cast for the power cost: stub.casting = { spellID }, the
-- costs in stub.spellCosts[spellID] = { { type, cost } }.
function UnitCastingInfo(unit) -- over stub_character.lua's; stub_castbars.lua (loaded later) has its own
	if unit == "player" and stub.casting then return "Spell", nil, nil, 0, 1, false, "cast", false, stub.casting.spellID end
end
C_Spell = rawget(_G, "C_Spell") or {}
C_Spell.GetSpellPowerCost = rawget(C_Spell, "GetSpellPowerCost") or function(id) return stub.spellCosts and stub.spellCosts[id] end

-- The client's class colours (fill the ones the shared stub lacks).
RAID_CLASS_COLORS = rawget(_G, "RAID_CLASS_COLORS") or {}
for k, c in pairs({ DEATHKNIGHT = { 0.77, 0.12, 0.23 }, DRUID = { 1, 0.49, 0.04 }, HUNTER = { 0.67, 0.83, 0.45 }, MAGE = { 0.25, 0.78, 0.92 },
	PALADIN = { 0.96, 0.55, 0.73 }, PRIEST = { 1, 1, 1 }, ROGUE = { 1, 0.96, 0.41 }, SHAMAN = { 0, 0.44, 0.87 }, WARLOCK = { 0.53, 0.53, 0.93 },
	WARRIOR = { 0.78, 0.61, 0.43 } }) do
	if not RAID_CLASS_COLORS[k] then RAID_CLASS_COLORS[k] = { r = c[1], g = c[2], b = c[3] } end
end
local POWER = { [0] = "MANA", [1] = "RAGE", [3] = "ENERGY" }
local CLASSES = { WARRIOR = "Warrior", MAGE = "Mage", PRIEST = "Priest", ROGUE = "Rogue", DRUID = "Druid", HUNTER = "Hunter", PALADIN = "Paladin", WARLOCK = "Warlock", DEATHKNIGHT = "Death Knight", SHAMAN = "Shaman" }

unitFn("UnitExists", function() return true end)
local unitExists = UnitExists
-- A unit the stub does not know exists while it has a name (the NPC of a dialog).
function UnitExists(unit) local v = unitExists(unit) if v == nil then return UnitName(unit) ~= nil end return v end
unitFn("UnitHealth", function(d) return stub.secret(d.health or 0) end, 0)
unitFn("UnitHealthMax", function(d) return stub.secret(d.max or 1) end, 1)
unitFn("UnitHealthPercent", function(d) return stub.secret((d.health or 0) / (d.max or 1) * 100) end)
unitFn("UnitPower", function(d) return stub.secret(d.power or 0) end, 0)
unitFn("UnitPowerMax", function(d) return stub.secret(d.powerMax or 0) end, 0)
unitFn("UnitPowerType", function(d) local k = d.powerType or 0 return k, POWER[k] end, 0)
unitFn("UnitGetIncomingHeals", function(d) return stub.secret(d.heals or 0) end)
unitFn("UnitGetTotalAbsorbs", function(d) return stub.secret(d.absorbs or 0) end, 0)
unitFn("UnitGetTotalHealAbsorbs", function(d) return stub.secret(d.healAbsorbs or 0) end, 0)
unitFn("UnitLevel", function(d) return d.level or 1 end, 0)
unitFn("UnitEffectiveLevel", function(d) return d.level or 1 end)
-- A unit the stub does not know: its level, as the client answers (a scene's own UnitLevel).
local effectiveLevel = UnitEffectiveLevel
function UnitEffectiveLevel(unit) local v = effectiveLevel(unit) if v == nil then return UnitLevel(unit) end return v end
-- Stock's level colours (Constants.lua) and its relative difficulty (DifficultyUtil
-- GetRelativeDifficultyColor, trivial range 8) as the enum: 0 trivial .. 4 impossible.
QuestDifficultyColors = rawget(_G, "QuestDifficultyColors") or {
	impossible = { r = 1, g = 0.1, b = 0.1 }, verydifficult = { r = 1, g = 0.5, b = 0.25 },
	difficult = { r = 1, g = 0.82, b = 0 }, standard = { r = 0.25, g = 0.75, b = 0.25 }, trivial = { r = 0.5, g = 0.5, b = 0.5 } }
local DIFF = { [0] = "trivial", "standard", "difficult", "verydifficult", "impossible" }
C_PlayerInfo = rawget(_G, "C_PlayerInfo") or {}
function C_PlayerInfo.GetContentDifficultyCreatureForPlayer(unit)
	local diff = UnitEffectiveLevel(unit) - UnitEffectiveLevel("player")
	return diff >= 5 and 4 or diff >= 3 and 3 or diff >= -4 and 2 or -diff <= 8 and 1 or 0
end
function GetDifficultyColor(d) return QuestDifficultyColors[DIFF[d] or "difficult"] end
function UnitCanAttack(_, unit) local d = data(unit) return d ~= nil and d.reaction ~= nil and d.reaction <= 4 end
unitFn("UnitClass", function(d) if not d.class then return nil end return CLASSES[d.class], d.class end)
unitFn("UnitIsPlayer", function(d) return d.player == true end, false)
unitFn("UnitReaction", function(d) return d.reaction end)
unitFn("UnitClassification", function(d) return d.classification or "normal" end, "normal")
unitFn("UnitGroupRolesAssigned", function(d) return d.role or "NONE" end, "NONE")
unitFn("UnitIsDead", function(d) return d.dead == true end, false)
unitFn("UnitIsGhost", function(d) return d.ghost == true end, false)
unitFn("UnitIsDeadOrGhost", function(d) return d.dead == true or d.ghost == true end, false)
unitFn("UnitIsConnected", function(d) return not d.offline end, false)
unitFn("UnitIsTapDenied", function(d) return d.tapped == true end, false)
unitFn("UnitIsVisible", function(d) return d.visible ~= false end, false)
unitFn("UnitGUID", function(d, unit) return d.guid or ("guid-" .. (d.name or unit)) end)
unitFn("UnitAffectingCombat", function(d, unit) if unit == "player" then return stub.inCombat end return d.combat == true end, false)
local unitName = UnitName
function UnitName(unit, ...)
	local d = stub.units[unit] or (unit == "vehicle" and data(unit))
	if d then return d.name end
	return unitName(unit, ...)
end
function UnitThreatSituation(_, unit) local d = data(unit) return d and d.threat or nil end
function UnitHasVehicleUI(unit) return unit == "player" and stub.vehicle end
function GetThreatStatusColor(s)
	local c = ({ { 1, 1, 0.47 }, { 1, 0.6, 0 }, { 1, 0, 0 } })[s] or { 0.69, 0.69, 0.69 }
	return c[1], c[2], c[3]
end
SetPortraitTexture = SetPortraitTexture or function(tex) tex:SetTexture(132355) end
GameTooltip_SetDefaultAnchor = GameTooltip_SetDefaultAnchor or noop
CurveConstants = CurveConstants or { ScaleTo100 = {} }
PowerBarColor = PowerBarColor or {
	MANA = { r = 0, g = 0, b = 1 }, RAGE = { r = 1, g = 0, b = 0 }, ENERGY = { r = 1, g = 1, b = 0 },
	[0] = { r = 0, g = 0, b = 1 }, [1] = { r = 1, g = 0, b = 0 }, [3] = { r = 1, g = 1, b = 0 },
}
DEAD, GHOST, PLAYER_OFFLINE = DEAD or "Dead", GHOST or "Ghost", PLAYER_OFFLINE or "Offline"

---------------------------------------------------------------------------
-- Protected frames (CLIENT.md, rule 4) and the stock frames (rule 16)
---------------------------------------------------------------------------

-- A secure unit button is protected: moved, sized, shown or set up from
-- addon code in combat, the client blocks it. The secure code itself (the
-- unit watch, Edit Mode) may: stub.secure(fn) runs fn as the game's code.
local secure = false
function stub.secure(fn, ...) local was = secure; secure = true; fn(...); secure = was end

-- What Edit Mode replaces on a system frame, and what moves or drops one
-- (EditModeSystemMixin:OnSystemLoad, EditModeSystemTemplates.lua): addon
-- code never calls these on a stock unit frame, in or out of combat.
local STOCK_ONLY = { "Show", "Hide", "SetShown", "SetPoint", "ClearAllPoints", "SetAllPoints", "SetScale", "SetSize", "SetWidth", "SetHeight",
	"SetParent", "UnregisterEvent", "UnregisterAllEvents", "SetScript" }
local IN_COMBAT = { "Show", "Hide", "SetShown", "SetPoint", "ClearAllPoints", "SetAllPoints", "SetScale", "SetSize", "SetWidth", "SetHeight",
	"SetParent", "SetAttribute", "EnableMouse", "SetAlpha" }
local guarded = {}
for _, n in ipairs(STOCK_ONLY) do guarded[n] = "stock" end
for _, n in ipairs(IN_COMBAT) do guarded[n] = guarded[n] and "both" or "combat" end
for name, kind in pairs(guarded) do
	local orig = M[name]
	if orig then
		M[name] = function(self, ...)
			if not secure and type(self) == "table" then
				if self.psStockUnit and kind ~= "combat" then
					error(name .. " on the stock " .. tostring(self.name) .. " from addon code (docs/CLIENT.md, rule 16)", 2)
				end
				-- SetAlpha is protected only on the stock frames; ours fade freely.
				if self.psProtected and InCombatLockdown() and kind ~= "stock" and not (name == "SetAlpha" and not self.psStockUnit) then
					error(name .. " on protected " .. tostring(self.name) .. " in combat (ADDON_ACTION_BLOCKED, rule 4)", 2)
				end
			end
			return orig(self, ...)
		end
	end
end

local create = CreateFrame
function CreateFrame(kind, name, parent, template, ...)
	local f = create(kind, name, parent, template, ...)
	if type(template) == "string" and template:find("SecureUnitButtonTemplate") then f.psProtected = true end
	return f
end


-- The game's group role icons (the roleicon-tiny-* atlases): a colour stands
-- in for each (tank blue, healer green, damage red).
local ROLE_ATLAS = { ["roleicon-tiny-tank"] = { 0.25, 0.5, 0.95 }, ["roleicon-tiny-healer"] = { 0.3, 0.8, 0.35 }, ["roleicon-tiny-dps"] = { 0.9, 0.25, 0.25 } }
local setAtlas = M.SetAtlas
function M.SetAtlas(self, atlas, ...)
	local c = ROLE_ATLAS[atlas]
	if c then self:SetColorTexture(c[1], c[2], c[3], 1) end
	return setAtlas(self, atlas, ...)
end

-- A status bar filled from its right end (SetReverseFill), as the preview draws it.
function M.SetReverseFill(self, v) self.reverseFill = v and true or nil end

-- The secure state drivers: the unit watch shows a watched frame while its
-- unit exists (RegisterUnitWatch); a visibility driver shows or hides a
-- frame by its macro conditions (RegisterStateDriver; the stub knows @unit,
-- exists, noexists, dead, group:raid, nogroup:raid and combat; stub.inRaid).
-- stub.unitWatch() runs them again after a unit change, as the client does
-- each frame.
local watched, drivers = {}, {}
stub.unitWatched, stub.stateDrivers = watched, drivers
stub.inRaid = false

local function test(c)
	local unit = "target"
	for part in c:gmatch("[^,]+") do
		part = part:match("^%s*(.-)%s*$")
		local u = part:match("^@(.+)$")
		if u then
			unit = u
		elseif part == "exists" then
			if not UnitExists(unit) then return false end
		elseif part == "noexists" then
			if UnitExists(unit) then return false end
		elseif part == "dead" then
			if not UnitIsDeadOrGhost(unit) then return false end
		elseif part == "group:raid" then
			if not stub.inRaid then return false end
		elseif part == "nogroup:raid" then
			if stub.inRaid then return false end
		elseif part == "combat" then
			if not InCombatLockdown() then return false end
		else
			error("stub state driver: unknown condition " .. part, 3)
		end
	end
	return true
end

local function evaluate(cond)
	for clause in cond:gmatch("[^;]+") do
		local conds, action = clause:match("^%s*(.-)%s*(%w+)%s*$")
		if conds == "" then return action end
		for c in conds:gmatch("%[(.-)%]") do
			if test(c) then return action end
		end
	end
	return nil
end
stub.evaluateDriver = evaluate

function RegisterUnitWatch(f) watched[f] = true; stub.unitWatch() end
function UnregisterUnitWatch(f) watched[f] = nil end
function RegisterStateDriver(f, state, cond)
	assert(state == "visibility", "stub: only visibility drivers")
	drivers[f] = cond
	stub.unitWatch()
end
function UnregisterStateDriver(f) drivers[f] = nil end
function stub.unitWatch()
	stub.secure(function()
		for f in pairs(watched) do f:SetShown(UnitExists(f:GetAttribute("unit")) and true or false) end
		for f, cond in pairs(drivers) do f:SetShown(evaluate(cond) == "show") end
	end)
end

---------------------------------------------------------------------------
-- The stock unit frames
---------------------------------------------------------------------------

local function art(f, r, g, b, a, layer)
	local t = f:CreateTexture(nil, layer or "ARTWORK")
	t:SetTexture("Interface\\Buttons\\WHITE8X8")
	t:SetVertexColor(r, g, b, a or 1)
	return t
end
local function fill(child, parent)
	child.points = { { point = "TOPLEFT", rel = parent, relPoint = "TOPLEFT", x = 0, y = 0 }, { point = "BOTTOMRIGHT", rel = parent, relPoint = "BOTTOMRIGHT", x = 0, y = 0 } }
	return child
end

local stock = {}
stub.stockUnits = stock

-- A stock frame (a secure unit button) of `w` x `h`: addon code may not move,
-- show or drop it (rule 16), and in combat not touch it at all.
local function unitButton(name, parent, w, h)
	local f = create("Button", name, parent, "SecureUnitButtonTemplate")
	f.psProtected, f.psStockUnit = true, true
	f.width, f.height, f.mouse = w, h, true
	f.strata, f.level = "LOW", 500
	return f
end

-- The art and bars of a frame on PlayerFrame's or TargetFrameTemplate's XML:
-- a Container (frame art, portrait) and its Content's Main (bars, names), its
-- icons and auras in the Content's Contextual.
local function layered(f, prefix)
	local c = fill(create("Frame", nil, f), f)
	art(c, 0.35, 0.28, 0.12):SetAllPoints(c)
	f[prefix .. "FrameContainer"] = c
	local content = fill(create("Frame", nil, f), f)
	local main = fill(create("Frame", nil, content), content)
	local hp = art(main, 0.1, 0.8, 0.1)
	hp:SetPoint("TOPLEFT", main, "TOPLEFT", 85, -40)
	hp:SetSize(125, 18)
	content[prefix .. "FrameContentMain"] = main
	content[prefix .. "FrameContentContextual"] = fill(create("Frame", nil, content), content)
	f[prefix .. "FrameContent"] = content
end

-- An Edit Mode system: its Selection box (shown in Edit Mode) inset as
-- EditModeUnitFrameSystemMixin:AnchorSelectionFrame places it.
local function system(f, inset)
	local i = inset or { 0, 0, 0, 0 }
	local sel = create("Frame", f.name .. "Selection", f)
	sel.points = { { point = "TOPLEFT", rel = f, relPoint = "TOPLEFT", x = i[1], y = -i[2] }, { point = "BOTTOMRIGHT", rel = f, relPoint = "BOTTOMRIGHT", x = -i[3], y = i[4] } }
	art(sel, 0.25, 0.55, 1, 0.35):SetAllPoints(sel)
	sel.shown = false
	f.Selection, f.psInset = sel, i
	stock[#stock + 1] = f
	return f
end

-- Edit Mode places a system (a layout applied, a drag): its rect and its
-- Selection's, in the frame's own units (as GetLeft answers), and what it lays out.
function stub.moveSystem(f, x, y, scale)
	f.x, f.y = x, y
	if scale then f.scale = scale end
	f.points = { { point = "BOTTOMLEFT", rel = UIParent, relPoint = "BOTTOMLEFT", x = x, y = y } }
	local s, i = f.Selection, f.psInset
	s.x, s.y, s.width, s.height = x + i[1], y + i[4], f.width - i[1] - i[3], f.height - i[2] - i[4]
	if f.psLayout then f.psLayout(f) end
end

local function tot(parent, name)
	local f = unitButton(name, parent, 120, 49)
	f.shown = false
	f.points = { { point = "TOPRIGHT", rel = parent, relPoint = "BOTTOMRIGHT", x = 12, y = 10 } }
	art(f, 0.35, 0.28, 0.12):SetAllPoints(f)
	local was = parent.psLayout
	parent.psLayout = function(p)
		if was then was(p) end
		f.x, f.y = p.x + p.width - f.width + 12, p.y - f.height + 10
	end
	return f
end

local BODY = { 20, 16, 20, 18 }
layered(system(unitButton("PlayerFrame", UIParent, 232, 100), BODY), "Player")
layered(system(unitButton("TargetFrame", UIParent, 232, 100), BODY), "Target")
layered(system(unitButton("FocusFrame", UIParent, 232, 100), BODY), "Target")
tot(TargetFrame, "TargetFrameToT")
tot(FocusFrame, "FocusFrameToT")

-- The pet frame (PetFrame.xml): its pieces are named regions of its own.
system(unitButton("PetFrame", UIParent, 120, 49), { 4, 3, 4, 6 })
PetFrame.shown = false
for _, n in ipairs({ "PetPortrait", "PetFrameTexture", "PetFrameFlash", "PetAttackModeTexture", "PetName" }) do
	_G[n] = art(PetFrame, 0.35, 0.28, 0.12)
	_G[n]:SetAllPoints(PetFrame)
end
for _, n in ipairs({ "PetFrameHealthBar", "PetFrameManaBar" }) do
	_G[n] = create("StatusBar", n, PetFrame)
	fill(_G[n], PetFrame)
end
PetFrameHappiness = create("Frame", "PetFrameHappiness", PetFrame)

-- The party (PartyFrame.xml): a stacking system, its members pooled
-- (PartyMemberFrameTemplate, 120 x 53, `spacing` apart), each shown while its
-- unit exists and the party frames are in use (PartyMemberFrameMixin:UpdateMember).
local party = system(unitButton("PartyFrame", UIParent, 120, 4 * 53 + 3 * 10))
party.spacing = 10
for i = 1, 4 do
	local m = unitButton(nil, party, 120, 53)
	m.name = "PartyMemberFrame" .. i
	m.shown = false
	for _, k in ipairs({ "Portrait", "Texture", "VehicleTexture", "Flash" }) do
		m[k] = art(m, 0.35, 0.28, 0.12)
		m[k]:SetAllPoints(m)
	end
	m.Name = m:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	m.HealthBarContainer = fill(create("Frame", nil, m), m)
	m.ManaBar = fill(create("StatusBar", nil, m), m)
	m.PartyMemberOverlay = fill(create("Frame", nil, m), m)
	m.PartyMemberOverlay.Status = art(m.PartyMemberOverlay, 1, 0, 0, 0.5)
	m.PartyMemberOverlay.LeaderIcon = art(m.PartyMemberOverlay, 1, 0.8, 0, 1)
	party["MemberFrame" .. i] = m
end
party.psLayout = function(p)
	for i = 1, 4 do
		local m = p["MemberFrame" .. i]
		m.x, m.y = p.x, p.y + p.height - i * 53 - (i - 1) * p.spacing
		m.points = { { point = "TOPLEFT", rel = p, relPoint = "TOPLEFT", x = 0, y = -(i - 1) * (53 + p.spacing) } }
	end
end
stub.raidStyleParty = false
function stub.updateParty()
	stub.secure(function()
		for i = 1, 4 do
			local show = not stub.inRaid and not stub.raidStyleParty and (UnitExists("party" .. i) or EditModeManagerFrame:ArePartyFramesForcedShown())
			party["MemberFrame" .. i]:SetShown(show and true or false)
		end
	end)
end

-- The bosses (TargetFrame.xml): BossTargetFrameContainer stacks five frames
-- on TargetFrameTemplate, at the small focus scale, 10 apart, each shown
-- while its unit exists (or in Edit Mode).
local bosses = system(unitButton("BossTargetFrameContainer", UIParent, 232 * 0.75, 5 * 100 * 0.75 + 4 * 10))
bosses.psStockUnit, bosses.psProtected = true, false
for i = 1, 5 do
	local b = unitButton("Boss" .. i .. "TargetFrame", bosses, 232, 100)
	b.scale, b.shown = 0.75, false
	layered(b, "Target")
end
bosses.psLayout = function(c)
	for i = 1, 5 do
		local b = _G["Boss" .. i .. "TargetFrame"]
		b.x, b.y = c.x / 0.75, (c.y + c.height) / 0.75 - i * 100 - (i - 1) * 10 / 0.75
		b.points = { { point = "TOPLEFT", rel = c, relPoint = "TOPLEFT", x = 0, y = -(i - 1) * (100 + 10 / 0.75) } }
	end
end
function stub.updateBosses()
	stub.secure(function()
		for i = 1, 5 do _G["Boss" .. i .. "TargetFrame"]:SetShown((UnitExists("boss" .. i) or bosses.isInEditMode) and true or false) end
	end)
end

stub.moveSystem(PlayerFrame, 260, 760)
stub.moveSystem(TargetFrame, 560, 760)
stub.moveSystem(FocusFrame, 260, 560)
stub.moveSystem(PetFrame, 300, 690)
stub.moveSystem(PartyFrame, 40, 300)
stub.moveSystem(BossTargetFrameContainer, 900, 300)

---------------------------------------------------------------------------
-- Edit Mode
---------------------------------------------------------------------------

EditModeManagerFrame = EditModeManagerFrame or create("Frame", "EditModeManagerFrame", UIParent)
EditModeManagerFrame.shown = false
stub.showPartyInEditMode = false -- Edit Mode's "Party Frames" option
function EditModeManagerFrame.UseRaidStylePartyFrames() return stub.raidStyleParty end
function EditModeManagerFrame.ArePartyFramesForcedShown(self) return self:IsShown() and stub.showPartyInEditMode end

-- Open and close it as the game does: every system's Selection shows
-- (EditModeSystemMixin:OnEditModeEnter), the pet and boss frames show
-- (isInEditMode), then EventRegistry's EditMode.Enter.
function stub.enterEditMode()
	stub.secure(function()
		EditModeManagerFrame:Show()
		for _, f in ipairs(stock) do f.Selection:Show() end
		PetFrame.isInEditMode, BossTargetFrameContainer.isInEditMode = true, true
		PetFrame:Show()
	end)
	stub.updateParty()
	stub.updateBosses()
	EventRegistry:TriggerEvent("EditMode.Enter")
end

function stub.exitEditMode()
	stub.secure(function()
		EditModeManagerFrame:Hide()
		for _, f in ipairs(stock) do f.Selection:Hide() end
		PetFrame.isInEditMode, BossTargetFrameContainer.isInEditMode = false, false
		PetFrame:SetShown(UnitExists("pet") and true or false)
	end)
	stub.updateParty()
	stub.updateBosses()
	EventRegistry:TriggerEvent("EditMode.Exit")
end

-- A layout applied (switching layouts, a reset, login): each system moved,
-- then EDIT_MODE_LAYOUTS_UPDATED. layout = { [frame] = { x, y, scale } }.
function stub.applyLayout(layout)
	for f, p in pairs(layout) do stub.moveSystem(f, p[1], p[2], p[3]) end
	stub.fire("EDIT_MODE_LAYOUTS_UPDATED")
end
