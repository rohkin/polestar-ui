-- Unit frames (docs/windows/unitframes.md): the player, target, target of
-- target, focus, focus's target, pet, party and boss frames in Polestar's
-- look, built from the HUD kit (Modules/HUD.lua). Ours are secure unit
-- buttons of our own; the stock frames stay where they are, as the game's
-- Edit Mode proxies.
--
-- The stock frames (docs/CLIENT.md, rule 16): PlayerFrame, TargetFrame,
-- FocusFrame, PetFrame, PartyFrame and BossTargetFrameContainer are Edit Mode
-- systems, whose Hide, SetShown, SetPoint, ClearAllPoints and SetScale Edit
-- Mode replaces with its own; they also carry the pet frame, totems, combo
-- points, the cast bars and the game's auras and status icons. So none of
-- them (nor a party member or boss frame in them) is hidden, moved, scaled or
-- reparented, and no event is unregistered. Out of combat we only switch off
-- a frame's mouse and veil its art and bars: hide the two plain child frames
-- that hold them (player, target, focus, bosses: its Container and its
-- Content's Main), or fade (SetAlpha 0) the pieces the game only shows and
-- hides (pet, party members; a party portrait, which the game re-alphas, is
-- hidden), or fade a frame that is no system (the targets of target). The
-- game's icons, auras, cast bars and happiness stay. Switched off, all of it
-- is given back at once.
--
-- Position: ours read the stock frame's Edit Mode selection box (its
-- `Selection`), or the stock member frame inside a system, and sit exactly on
-- it, at its scale: on login, on every Edit Mode layout change
-- (EDIT_MODE_LAYOUTS_UPDATED), every frame while Edit Mode is open (the
-- player drags the stock box; ours follow), and as it closes. Read, never
-- anchored (CLIENT.md, rule 10); placed out of combat only (rule 4), queued
-- for PLAYER_REGEN_ENABLED otherwise.

local ADDON, ns = ...
local Theme, W = Polestar.Theme, Polestar.Widgets
local H = ns.HUD

local M = { noun = "unit frames" }
local KEY = "unitframes"
local DEFAULTS = { ground = 0.6, portrait = true, powerText = true, sparkle = true, smooth = true, trail = true }

-- The body of a frame on TargetFrameTemplate (the target's, focus's and
-- bosses'): where Edit Mode lays the target's and focus's Selection box
-- (EditModeUnitFrameSystemMixin:AnchorSelectionFrame); the pet's box.
local BODY = { 20, 16, 20, 18 }
local PET_BODY = { 4, 3, 4, 6 }

-- What the game only shows and hides on a pet frame and a party member:
-- faded; a party portrait, which the game re-alphas at low health
-- (PartyMemberFrameMixin:UpdateMemberHealth), hidden.
local PET_PARTS = { "PetPortrait", "PetFrameTexture", "PetName", "PetFrameHealthBar", "PetFrameManaBar" }
-- A texture's alpha is its vertex colour's, and the game writes that on these
-- (the threat flash, UnitFrame_UpdateThreatIndicator; the attack pulse,
-- PetFrameMixin:OnUpdate), so a fade would not hold: emptied instead, and
-- given back with the atlas they had (the game never sets it again).
local PET_EMPTIED = { "PetFrameFlash", "PetAttackModeTexture" }
local petAtlas = {}
local PARTY_PARTS = { "Texture", "VehicleTexture", "Flash", "Name", "HealthBarContainer", "ManaBar" }

local function member(i) return PartyFrame and rawget(PartyFrame, "MemberFrame" .. i) end
local function boss(i) return _G["Boss" .. i .. "TargetFrame"] end

-- Each frame: its unit; the stock frame it stands for; how that one is veiled
-- (system, fade, pet, party); what ours sits on (the system's Selection box,
-- the frame itself, or its body) and, for a frame inside a stacking system,
-- where it stands when the game has not placed it yet; when it shows (always,
-- the unit watch, a state driver); its height, centred in what it sits on,
-- where it is slimmer; and its look: slim (the name and value on the health
-- bar), a block (party), a target of target's bar, or a line with the name
-- (and level, rank) over the bars; a portrait, the health and power text, the
-- portrait's side.
local SPECS = {
	{ unit = "player", name = "PolestarUIPlayerFrame", stock = function() return PlayerFrame end, veil = "system", on = "selection",
		show = "always", slim = true, height = 40, portrait = true, text = true, side = "LEFT", vehicle = "vehicle", feedback = { "player", "vehicle" } },
	{ unit = "target", name = "PolestarUITargetFrame", stock = function() return TargetFrame end, veil = "system", on = "selection",
		show = "watch", slim = true, height = 40, portrait = true, level = true, rank = true, text = true, side = "RIGHT" },
	{ unit = "focus", name = "PolestarUIFocusFrame", stock = function() return FocusFrame end, veil = "system", on = "selection",
		show = "watch", slim = true, height = 40, portrait = true, level = true, rank = true, text = true, side = "RIGHT" },
	-- The stock target of target hides with no unit, and while the target
	-- is dead (TargetOfTargetMixin:Update).
	{ unit = "targettarget", name = "PolestarUITargetToT", stock = function() return TargetFrameToT end, veil = "fade", on = "frame",
		show = "[@targettarget,noexists][@target,dead] hide; show", tot = true, height = 20, side = "LEFT" },
	{ unit = "focustarget", name = "PolestarUIFocusToT", stock = function() return FocusFrameToT end, veil = "fade", on = "frame",
		show = "[@focustarget,noexists][@focus,dead] hide; show", tot = true, height = 20, side = "LEFT" },
	-- The pet frame shows the player while the player drives a vehicle, as
	-- the stock one does (its clicks follow through toggleForVehicle). Slim
	-- as the player's, smaller as the stock pet frame is (its portrait 0.6 of the
	-- player's): 24 tall, small text.
	{ unit = "pet", name = "PolestarUIPetFrame", stock = function() return PetFrame end, veil = "pet", on = "selection", inset = PET_BODY,
		show = "watch", slim = true, height = 24, portrait = true, text = true, compact = true, side = "LEFT", vehicle = "player", feedback = { "pet", "player" } },
}
for i = 1, 4 do
	-- The game hides the party frames in a raid (ShouldShowPartyFrames) and
	-- when Edit Mode's "Raid-Style Party Frames" is on (then the compact ones show).
	SPECS[#SPECS + 1] = { unit = "party" .. i, name = "PolestarUIPartyFrame" .. i, stock = function() return member(i) end, veil = "party", on = "frame",
		stack = { container = function() return PartyFrame end, index = i, height = 53, gap = function() return rawget(PartyFrame, "spacing") or 10 end },
		show = "[group:raid] hide; [@party" .. i .. ",exists] show; hide", party = true, text = true, side = "LEFT" }
end
for i = 1, 5 do
	-- The stock boss frames have no portrait (BossTargetFrameMixin:OnLoad).
	SPECS[#SPECS + 1] = { unit = "boss" .. i, name = "PolestarUIBossFrame" .. i, stock = function() return boss(i) end, veil = "system", on = "body",
		stack = { container = function() return BossTargetFrameContainer end, index = i, height = 100, gap = function() return 10 end },
		show = "watch", boss = true, line = true, level = true, rank = true, text = true, side = "RIGHT" }
end

local frames, byUnit = {}, {}
local pending, editing, built = false, false, false
local driver
local lastRect = {} -- frame -> the rect it was last placed on (a stacked frame the game has not shown since)

local function opts()
	PolestarUIDB.unitframes = PolestarUIDB.unitframes or {}
	return PolestarUIDB.unitframes
end

local function opt(k)
	local v = opts()[k]
	if v == nil then return DEFAULTS[k] end
	return v
end

-- The unit a frame shows now: Edit Mode's stand-in (the player), the
-- vehicle swap, or its own.
local function shown(f)
	if f.psPreview then return f.psPreview end
	if f.spec.vehicle and ns.Clean(UnitHasVehicleUI("player")) then return f.spec.vehicle end
	return f.spec.unit
end

---------------------------------------------------------------------------
-- Text
---------------------------------------------------------------------------

-- The health text as the game's own statusTextDisplay asks (NUMERIC, PERCENT,
-- BOTH; NONE, the game's default, is the numbers), shown always with
-- statusText on, else on mouse-over, as the stock bars do
-- (TextStatusBarMixin:UpdateTextStringWithValues). Values go straight from
-- the client into SetFormattedText (they are secret).
local function healthText(f, unit)
	local fs = f.healthText
	if not fs then return end
	if ns.Clean(UnitIsConnected(unit)) == false then return fs:SetFormattedText("%s", PLAYER_OFFLINE or "Offline") end
	if ns.Clean(UnitIsGhost(unit)) then return fs:SetFormattedText("%s", GHOST or "Ghost") end
	if ns.Clean(UnitIsDead(unit)) then return fs:SetFormattedText("%s", DEAD or "Dead") end
	local pct = UnitHealthPercent and CurveConstants and UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)
	-- A party block always shows its percent.
	if f.spec.party and pct then return fs:SetFormattedText("%.0f%%", pct) end
	local mode = GetCVar("statusTextDisplay")
	if not (GetCVar("statusText") == "1" or f.psHover) then return fs:SetText("") end
	-- The pet's narrow bar keeps its name: the percent, whatever the mode.
	if (mode == "PERCENT" or f.spec.compact) and pct then
		fs:SetFormattedText("%.0f%%", pct)
	elseif mode == "BOTH" and pct then
		fs:SetFormattedText("%s || %.0f%%", AbbreviateNumbers(UnitHealth(unit)), pct)
	else
		fs:SetFormattedText("%s / %s", AbbreviateNumbers(UnitHealth(unit)), AbbreviateNumbers(UnitHealthMax(unit)))
	end
end

-- The power as the same statusTextDisplay asks: PERCENT and BOTH add the
-- client's own percent (UnitPowerPercent on the 0-100 curve, secret-safe);
-- otherwise the value.
local function powerText(f, unit)
	if not f.powerText then return end
	if not opt("powerText") or not (GetCVar("statusText") == "1" or f.psHover) then return f.powerText:SetText("") end
	local mode = GetCVar("statusTextDisplay")
	local pct = (mode == "PERCENT" or mode == "BOTH") and UnitPowerPercent and CurveConstants
		and UnitPowerPercent(unit, nil, true, CurveConstants.ScaleTo100)
	if pct and mode == "PERCENT" then
		f.powerText:SetFormattedText("%.0f%%", pct)
	elseif pct then
		f.powerText:SetFormattedText("%s || %.0f%%", AbbreviateNumbers(UnitPower(unit)), pct)
	else
		f.powerText:SetFormattedText("%s", AbbreviateNumbers(UnitPower(unit)))
	end
end

local RANKS = { worldboss = "Boss", rareelite = "Rare Elite", elite = "Elite", rare = "Rare" }
-- On a slim bar the rank is a chip on the level ("25+", "25R", "25R+"), so the
-- name keeps its room. A world boss's level is "??" (-1), the stock skull's
-- convention: no letter of its own.
local CHIPS = { rareelite = "R+", elite = "+", rare = "R" }

-- The level's colour as stock's TargetFrameMixin:CheckLevel paints it: the
-- difficulty colour on an attackable unit, gold on a friendly one, the skull's
-- red (impossible) on "??". nil while secret or unknown: the neutral token.
local function levelColor(unit, level)
	if not level then return end
	local c
	if level < 1 then
		c = QuestDifficultyColors and QuestDifficultyColors.impossible
	elseif ns.Clean(UnitCanAttack("player", unit)) then
		local d = C_PlayerInfo and C_PlayerInfo.GetContentDifficultyCreatureForPlayer and ns.Clean(C_PlayerInfo.GetContentDifficultyCreatureForPlayer(unit))
		c = d and GetDifficultyColor and GetDifficultyColor(d)
	elseif ns.Clean(UnitCanAttack("player", unit)) == false then
		return 1, 0.82, 0
	end
	if c then return c.r, c.g, c.b end
end

local function nameLine(f, unit)
	if f.levelText then
		local level = ns.Clean(UnitEffectiveLevel and UnitEffectiveLevel(unit) or UnitLevel(unit))
		local r, g, b = levelColor(unit, level)
		if r then
			W.Uncolor(f.levelText)
			f.levelText:SetTextColor(r, g, b, 1)
		else
			W.Color(f.levelText, "textDim")
		end
		local lv = level and (level < 1 and "??" or tostring(level)) or ""
		local class = ns.Clean(UnitClassification(unit)) or ""
		if f.spec.rank and f.spec.slim then
			lv = lv .. (CHIPS[class] or "")
		elseif f.spec.rank and RANKS[class] then
			lv = lv .. " " .. RANKS[class]
		end
		f.levelText:SetFormattedText("%s", lv)
	end
	f.Name:SetFormattedText("%s", UnitName(unit) or "")
end

---------------------------------------------------------------------------
-- Painting
---------------------------------------------------------------------------

-- The edge: the threat the player holds on the unit, in the game's threat
-- colours; the player's own frame in danger while in combat; else the border.
local function edge(f, unit)
	local a = H.GroundAlpha()
	if unit == "player" or unit == "vehicle" then
		if f.spec.unit == "player" and ns.Clean(UnitAffectingCombat("player")) then
			local r, g, b = Theme.Color("danger")
			return H.PaintGround(f.Ground, a, r, g, b, 1, true)
		end
	else
		local status = ns.Clean(UnitThreatSituation("player", unit))
		if status and status > 0 and GetThreatStatusColor then
			local r, g, b = GetThreatStatusColor(status)
			return H.PaintGround(f.Ground, a, r, g, b, H.THREAT_ALPHA)
		end
	end
	H.PaintGround(f.Ground, a)
end

-- The stock frame's alpha, which the game and Edit Mode set: its Opacity
-- setting (the system frame), a party member out of the group's phase or in
-- another group (0.6, PartyMemberFrameMixin:UpdateNotPresentIcon).
local function stockAlpha(f)
	local s = f.spec.stock()
	if not s or f.spec.tot then return 1 end
	if f.spec.party then return s:GetAlpha() * PartyFrame:GetAlpha() end
	if f.spec.boss then return BossTargetFrameContainer:GetAlpha() end
	return s:GetAlpha()
end

-- Heal prediction as the client works it out (UnitGetDetailedHealPrediction):
-- incoming heals up to the missing health, shields up to what is still
-- missing after them, heal absorbs up to the health, each netted against
-- the incoming heals as stock shows them; and whether the shields (heal
-- absorbs) went past that (the end glows). All secret: handed to the bars
-- and glows unread. A client without the calculator: the plain totals.
local calc
local function prediction(unit)
	if not (CreateUnitHealPredictionCalculator and UnitGetDetailedHealPrediction) then
		return UnitGetIncomingHeals(unit) or 0, UnitGetTotalAbsorbs(unit) or 0, false, UnitGetTotalHealAbsorbs(unit) or 0, false
	end
	if not calc then
		calc = CreateUnitHealPredictionCalculator()
		calc:SetIncomingHealClampMode(Enum.UnitIncomingHealClampMode.MissingHealth)
		calc:SetDamageAbsorbClampMode(Enum.UnitDamageAbsorbClampMode.MissingHealth)
		calc:SetHealAbsorbClampMode(Enum.UnitHealAbsorbClampMode.CurrentHealth)
		calc:SetHealAbsorbMode(Enum.UnitHealAbsorbMode.ReducedByIncomingHeals)
	end
	UnitGetDetailedHealPrediction(unit, "player", calc)
	local heals = calc:GetIncomingHeals()
	local absorbs, over = calc:GetDamageAbsorbs()
	local healAbsorbs, overHeal = calc:GetHealAbsorbs()
	return heals, absorbs, over, healAbsorbs, overHeal
end

-- Stock's end glows (UnitFrameHealPredictionBars_Update): shields past the
-- missing health light the health bar's right end, heal absorbs past the
-- health its left end. The flag is secret: SetAlphaFromBoolean takes it
-- unread; a client without it shows none.
local function glow(t, on, token)
	t:SetVertexColor(Theme.Color(token))
	if t.SetAlphaFromBoolean then t:SetAlphaFromBoolean(on, 1, 0) else t:SetAlpha(0) end
end

-- `snap`: another unit now (a new target): its bars jump, never slide.
local ROLE_ICONS = { TANK = "roleicon-tiny-tank", HEALER = "roleicon-tiny-healer", DAMAGER = "roleicon-tiny-dps" }

local function paint(f, snap)
	if not f:IsVisible() then return end
	local unit = shown(f)
	if not ns.Clean(UnitExists(unit)) then return end
	f:SetAlpha(stockAlpha(f))
	local smooth = opt("smooth") and not snap and not f.spec.tot
	local max = UnitHealthMax(unit)
	-- A party member wears their class colour, whatever Polestar's "Class colour" says.
	local r, g, b = H.UnitColor(unit, f.spec.party)
	H.SetBarColor(f.Health, r, g, b)
	f.Health:SetMinMaxValues(0, max)
	local health = UnitHealth(unit)
	H.SetValue(f.Health, health, smooth)
	H.SetTrail(f.Health, health, snap, opt("trail"), max)
	if f.Health.psSpark then H.PaintSparkle(f.Health, opt("sparkle")) end
	-- Incoming heals: the fill's own colour, lighter, continuing it.
	local heals, absorbs, over, healAbsorbs, overHeal = prediction(unit)
	f.Heal:SetStatusBarColor(r + (1 - r) * 0.45, g + (1 - g) * 0.45, b + (1 - b) * 0.45, 0.7)
	f.Heal:SetMinMaxValues(0, max)
	f.Heal:SetValue(heals)
	f.Absorb:SetMinMaxValues(0, max)
	f.Absorb:SetValue(absorbs)
	f.HealAbsorb:SetMinMaxValues(0, max)
	f.HealAbsorb:SetValue(healAbsorbs)
	glow(f.OverAbsorb, over, "text")
	glow(f.OverHealAbsorb, overHeal, "danger")
	H.SetBarColor(f.Power, H.PowerColor(unit))
	H.SetTrack(f.Health, H.GroundAlpha())
	H.SetTrack(f.Power, H.GroundAlpha())
	f.Sep:SetVertexColor(Theme.Color("border"))
	local powerMax = UnitPowerMax(unit)
	f.Power:SetMinMaxValues(0, powerMax)
	H.SetValue(f.Power, UnitPower(unit), smooth)
	if f.cost then
		-- The power the spell being cast will take (the player's own only).
		f.cost:SetMinMaxValues(0, powerMax)
		f.cost:SetValue(unit == "player" and f.psCost or 0)
	end
	if f.role then
		-- The group role, in the game's own icon (PartyMemberFrameMixin:UpdateAssignedRoles);
		-- none while it has none or the client keeps it secret.
		local atlas = ROLE_ICONS[ns.Clean(UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)) or ""]
		if atlas then f.role:SetAtlas(atlas) end
		f.role:SetShown(atlas ~= nil)
	end
	healthText(f, unit)
	powerText(f, unit)
	nameLine(f, unit)
	edge(f, unit)
	if f.portrait then
		f.portrait:SetShown(opt("portrait"))
		-- The model loads again only for another unit (its GUID; while that is
		-- secret, false: then the events that change the unit clear it).
		local guid = ns.Clean(UnitGUID(unit))
		if opt("portrait") and (f.psPortraitOf == nil or (guid and guid ~= f.psPortraitOf)) then
			f.psPortraitOf = guid or false
			H.SetPortrait(f.portrait, unit)
		end
	end
end

local function paintAll(snap)
	for _, f in ipairs(frames) do paint(f, snap) end
end

---------------------------------------------------------------------------
-- Building
---------------------------------------------------------------------------

-- What hangs off the fills, sized from the layout's own numbers: the bars'
-- width and the health bar's height (their geometry is secret, rule 3).
local function sized(f, w, healthH)
	for _, s in ipairs({ f.Heal, f.Absorb, f.HealAbsorb, f.cost }) do s:SetWidth(w) end
	if f.Health.psSpark then H.SizeSparkle(f.Health, w, healthH) end
end

-- Our frame's own layout, on the size it is given (the stock box): the
-- portrait square on its side; beside it a line with the level, rank and
-- name, then the health bar (its text at the far end) over the power bar. A
-- target of target is only its name on the health bar.
-- Slim (player, target, focus, pet), a block (party) and a target of target: 1 in
-- (inside the hairline) the portrait square on its side, 1 apart from the
-- health bar, which fills the rest over a power strip (4, a party's 6; none
-- on a target of target) under a hairline.

local function layout(f)
	local w, h = f:GetWidth(), f:GetHeight()
	if w <= 0 or h <= 0 then return end
	local spec = f.spec
	if spec.slim or spec.party or spec.tot then
		local left = spec.side == "LEFT"
		local port = (f.portrait and opt("portrait")) and h - 2 or 0
		if f.portrait then
			f.portrait:ClearAllPoints()
			f.portrait:SetSize(port, port)
			f.portrait:SetPoint(left and "TOPLEFT" or "TOPRIGHT", f, left and "TOPLEFT" or "TOPRIGHT", left and 1 or -1, -1)
		end
		local gap = port > 0 and port + 1 or 0
		local x0, x1 = 1 + (left and gap or 0), 1 + (left and 0 or gap)
		local powerH = spec.tot and 0 or spec.party and 6 or 4 -- a party's is easy to read at a glance
		f.Health:ClearAllPoints()
		f.Health:SetPoint("TOPLEFT", f, "TOPLEFT", x0, -1)
		f.Health:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -x1, powerH > 0 and powerH + 2 or 1)
		f.Power:ClearAllPoints()
		f.Power:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x0, 1)
		f.Power:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -x1, 1)
		f.Power:SetHeight(math.max(powerH, 1))
		f.Power:SetShown(powerH > 0)
		f.Sep:SetShown(powerH > 0)
		sized(f, w - x0 - x1, h - 1 - (powerH > 0 and powerH + 2 or 1))
		return
	end
	f.Sep:Hide()
	local pad = 2
	local inner = h - 2 * pad
	local port = (f.portrait and opt("portrait")) and inner or 0
	local powerH = math.max(3, math.floor(inner * 0.22 + 0.5))
	local left = f.spec.side == "LEFT"
	if f.portrait then
		f.portrait:ClearAllPoints()
		f.portrait:SetSize(port, port)
		f.portrait:SetPoint(left and "TOPLEFT" or "TOPRIGHT", f, left and "TOPLEFT" or "TOPRIGHT", left and pad or -pad, -pad)
	end
	local x0, x1 = pad + (left and (port > 0 and port + pad or 0) or 0), pad + ((not left) and (port > 0 and port + pad or 0) or 0)
	local line = f.spec.line and (inner >= 40 and 16 or 13) or 0
	if line > 0 then
		if f.levelText then
			f.levelText:ClearAllPoints()
			f.levelText:SetPoint("TOPLEFT", f, "TOPLEFT", x0 + 2, -pad - 1)
		end
		f.Name:ClearAllPoints()
		if f.levelText then
			f.Name:SetPoint("LEFT", f.levelText, "RIGHT", 4, 0)
		else
			f.Name:SetPoint("TOPLEFT", f, "TOPLEFT", x0 + 2, -pad - 1)
		end
		f.Name:SetPoint("RIGHT", f, "TOPRIGHT", -x1 - 2, -pad - line / 2)
	end
	f.Health:ClearAllPoints()
	f.Health:SetPoint("TOPLEFT", f, "TOPLEFT", x0, -pad - line)
	f.Health:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -x1, pad + powerH + 1)
	f.Power:ClearAllPoints()
	f.Power:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", x0, pad)
	f.Power:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -x1, pad)
	f.Power:SetHeight(powerH)
	sized(f, w - x0 - x1, h - 2 * pad - line - powerH - 1)
end

local function onEnter(self)
	self.psHover = true
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:SetUnit(shown(self))
	GameTooltip:Show()
	paint(self)
end

local function onLeave(self)
	self.psHover = nil
	GameTooltip:Hide()
	paint(self)
end

---------------------------------------------------------------------------
-- Combat feedback: the damage, heal and miss text the stock player and pet
-- frames show over their portraits (CombatFeedback.lua, PlayerFrame.lua and
-- PetFrame.lua on UNIT_COMBAT), on ours.
---------------------------------------------------------------------------

local FADE_IN, HOLD, FADE_OUT = 0.2, 0.7, 0.3 -- COMBATFEEDBACK_FADEINTIME, _HOLDTIME, _FADEOUTTIME

local function word(k) return (rawget(_G, "CombatFeedbackText") or {})[k] or rawget(_G, k) end

-- The holder's alpha (a string's alpha is its colour's, which a repaint sets),
-- run only while it shows.
local function feedbackFade(h)
	local t = GetTime() - h.start
	if t >= FADE_IN + HOLD + FADE_OUT then return h:Hide() end
	h:SetAlpha(t < FADE_IN and t / FADE_IN or t < FADE_IN + HOLD and 1 or 1 - (t - FADE_IN - HOLD) / FADE_OUT)
end

-- CombatFeedback_OnCombatEvent's text, size and colour. The amount is secret
-- in combat: never compared, handed through BreakUpLargeNumbers into
-- SetFormattedText.
local function feedback(h, _, unit, event, flags, amount, school)
	local f = h.owner
	if unit ~= shown(f) or not ns.Enabled(KEY) or not opt("portrait") then return end
	local size, r, g, b, text, number = 1, 1, 1, 1, nil, false
	local crit = flags == "CRITICAL"
	if event == "WOUND" then
		local clean = ns.Clean(amount)
		-- shortcut: a secret amount counts as 0 only under ABSORB, BLOCK or RESIST (stock compares it), until the client shows a partial one there.
		local zero = clean == 0 or (clean == nil and (flags == "ABSORB" or flags == "BLOCK" or flags == "RESIST"))
		if not zero then
			number = true
			size = (crit or flags == "CRUSHING") and 1.5 or flags == "GLANCING" and 0.75 or 1
			if ns.Clean(school) ~= ((Enum.Damageclass or {}).MaskPhysical or 1) then b = 0 end
		elseif flags == "ABSORB" or flags == "BLOCK" or flags == "RESIST" then
			size, text = 0.75, word(flags)
		else
			text = word("MISS")
		end
	elseif event == "HEAL" or event == "ENERGIZE" then
		number, size = true, crit and 1.5 or 1
		if event == "HEAL" then r, b = 0, 0 else r, g, b = 0.41, 0.8, 0.94 end
	else
		size = event == "IMMUNE" and 0.5 or event == "BLOCK" and 0.75 or 1
		text = word(event)
	end
	if not number and not text then return end
	local fs = h.text
	Theme.SetFace(fs, (Theme.FontSpec("number")), math.floor(f.spec.height / 2 * size + 0.5), "OUTLINE")
	if number then
		fs:SetFormattedText(flags == "BLOCK_REDUCED" and rawget(_G, "COMBAT_TEXT_BLOCK_REDUCED") or "%s", BreakUpLargeNumbers(amount))
	else
		fs:SetFormattedText("%s", text)
	end
	fs:SetTextColor(r, g, b)
	h.start = GetTime()
	h:SetAlpha(0)
	h:Show()
end

-- Over the portrait's model, centred; the units its stock frame listens to.
local function feedbackText(f)
	local h = CreateFrame("Frame", nil, f.portrait)
	h:SetAllPoints(f.portrait)
	h:SetFrameLevel(f.portrait.Model:GetFrameLevel() + 2)
	h:Hide()
	h.owner = f
	h.text = H.Text(h, "number", "text")
	h.text:SetPoint("CENTER", h, "CENTER", 0, 0)
	h:SetScript("OnUpdate", feedbackFade)
	h:SetScript("OnEvent", feedback)
	h:RegisterUnitEvent("UNIT_COMBAT", f.spec.feedback[1], f.spec.feedback[2])
	f.feedback = h
end

local function build(spec)
	-- A secure unit button of our own: left-click targets, right-click opens
	-- the game's unit menu from secure code (togglemenu: Set Focus and the
	-- rest stay usable), click bindings run through SecureUnitButton_OnClick,
	-- and the ping system takes it as a unit frame.
	local f = CreateFrame("Button", spec.name, UIParent, "SecureUnitButtonTemplate,PingableUnitFrameTemplate")
	f.spec = spec
	f:SetFrameStrata("LOW")
	f:SetFrameLevel(100)
	f:SetSize(spec.tot and 120 or 192, spec.height or 66)
	f:RegisterForClicks("AnyUp")
	f:SetAttribute("unit", spec.unit)
	f:SetAttribute("*type1", "target")
	f:SetAttribute("*type2", "togglemenu")
	if spec.vehicle then f:SetAttribute("toggleForVehicle", true) end
	ClickCastFrames = ClickCastFrames or {} -- click-casting addons (Clique): the standard registry, either load order
	ClickCastFrames[f] = true
	f.Ground = H.Ground(f)
	if spec.portrait then f.portrait = H.Portrait(f, spec.slim) end
	if spec.feedback then feedbackText(f) end
	f.Health = H.Bar(f, true)
	f.Health:SetClipsChildren(true) -- the heal and absorb segments end at the bar's ends
	if spec.unit == "player" then H.Sparkle(f.Health) end
	f.Heal = H.Segment(f.Health) -- coloured as the fill (paint)
	f.Absorb = H.Segment(f.Heal, "text", 0.55)
	f.HealAbsorb = H.Segment(f.Health, "shade", 0.55, true) -- health that heals must fill first: the fill darkened
	-- The end glows (paint), over the segments: in Polestar's look a 2-unit
	-- strip inside the bar's end, where stock's 16-unit glow overhangs it.
	local glows = CreateFrame("Frame", nil, f.Health)
	glows:SetAllPoints(f.Health)
	glows:SetFrameLevel(f.Absorb:GetFrameLevel() + 1)
	for _, g in ipairs({ { "OverAbsorb", "RIGHT" }, { "OverHealAbsorb", "LEFT" } }) do
		local key, side = g[1], g[2]
		local t = glows:CreateTexture(nil, "OVERLAY")
		t:SetTexture(Theme.Media("white"))
		t:SetWidth(2)
		t:SetPoint("TOP" .. side, f.Health, "TOP" .. side, 0, 0)
		t:SetPoint("BOTTOM" .. side, f.Health, "BOTTOM" .. side, 0, 0)
		t:SetAlpha(0)
		f[key] = t
	end
	f.Power = H.Bar(f)
	if spec.unit == "player" then
		f.Power:SetClipsChildren(true) -- a cost past the power ends at the bar's start
		f.cost = H.Segment(f.Power, "shade", 0.55, true) -- darkened: the power colours are light
	end
	-- The hairline between the health bar and the power strip.
	f.Sep = f:CreateTexture(nil, "BORDER", nil, 7)
	f.Sep:SetTexture(Theme.Media("white"))
	f.Sep:SetPoint("TOPLEFT", f.Health, "BOTTOMLEFT", 0, 0)
	f.Sep:SetPoint("BOTTOMRIGHT", f.Power, "TOPRIGHT", 0, 0)
	local small = spec.compact or spec.party
	local on = spec.line and f or f.Health
	f.Name = H.Text(on, small and "small" or "label", "text")
	ns.NameFont(f.Name) -- a name in any script (Cyrillic, Hangul, Chinese), never read: it is secret in combat
	if spec.level then f.levelText = H.Text(on, "small", "textDim") end
	if spec.text then
		f.healthText = H.Text(f.Health, small and "small" or "number", spec.party and "textDim" or "text")
		f.healthText:SetJustifyH("RIGHT")
		if spec.party then
			f.healthText:SetPoint("BOTTOMRIGHT", f.Health, "BOTTOMRIGHT", -3, 3)
		else
			f.healthText:SetPoint("RIGHT", f.Health, "RIGHT", spec.compact and -2 or -4, 0)
			-- Same right edge as the health value, centred on the power bar (on the slim 4 px
			-- strip it overhangs). Its own unclipped frame above both bars, so neither the
			-- bar's clipping nor the health bar hides it.
			local over = CreateFrame("Frame", nil, f)
			over:SetAllPoints(f.Power)
			over:SetFrameLevel(math.max(f.Health:GetFrameLevel(), f.Power:GetFrameLevel()) + 5)
			f.powerText = H.Text(over, "small", "textDim")
			f.powerText:SetJustifyH("RIGHT")
			f.powerText:SetPoint("RIGHT", f.Power, "RIGHT", spec.compact and -2 or -4, 0)
		end
	end
	if spec.party then
		-- The role icon where the game's own is (12 units, 5 in from the top
		-- right of the member frame); the name ends before it.
		f.role = f.Health:CreateTexture(nil, "OVERLAY")
		f.role:SetSize(12, 12)
		f.role:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
		f.role:Hide()
		f.Name:SetPoint("TOPLEFT", f.Health, "TOPLEFT", 3, -3)
		f.Name:SetPoint("RIGHT", f.role, "LEFT", -2, 0)
	elseif not spec.line then
		-- On the bar: the level (and rank) in front, the value at the far end.
		if f.levelText then f.levelText:SetPoint("LEFT", f.Health, "LEFT", 4, 0) end
		f.Name:SetPoint("LEFT", f.levelText or f.Health, f.levelText and "RIGHT" or "LEFT", 4, 0)
		f.Name:SetPoint("RIGHT", f.healthText or f.Health, f.healthText and "LEFT" or "RIGHT", -4, 0)
	end
	f:HookScript("OnEnter", onEnter)
	f:HookScript("OnLeave", onLeave)
	f:HookScript("OnSizeChanged", layout)
	f:HookScript("OnShow", function(self) self.psPortraitOf = nil; paint(self, true) end)
	layout(f)
	frames[#frames + 1] = f
	byUnit[spec.unit] = f
	return f
end

---------------------------------------------------------------------------
-- The stock frames (rule 16) and placement
---------------------------------------------------------------------------

-- The faded bars (TextStatusBar, enableMouseMotion) still took the mouse,
-- showing the game's unit tooltip over ours: their hover off while veiled.
local function hover(bar, on)
	if bar and bar.SetMouseMotionEnabled then bar:SetMouseMotionEnabled(not on) end
end

-- Veil (on) or give back (off) one stock frame. Out of combat only.
local function veil(f, on)
	local stock = f.spec.stock()
	if not stock then return end
	stock:EnableMouse(not on)
	local kind = f.spec.veil
	if kind == "fade" or kind == "party" then
		local c = rawget(stock, "HealthBarContainer")
		hover(c and rawget(c, "HealthBar") or rawget(stock, "HealthBar"), on)
		hover(rawget(stock, "ManaBar"), on)
	elseif kind == "pet" then
		hover(rawget(_G, "PetFrameHealthBar"), on)
		hover(rawget(_G, "PetFrameManaBar"), on)
	end
	if kind == "system" then
		local c = rawget(stock, "PlayerFrameContainer") or rawget(stock, "TargetFrameContainer")
		local content = rawget(stock, "PlayerFrameContent") or rawget(stock, "TargetFrameContent")
		local main = content and (rawget(content, "PlayerFrameContentMain") or rawget(content, "TargetFrameContentMain"))
		if c then c:SetShown(not on) end
		if main then main:SetShown(not on) end
	elseif kind == "fade" then
		stock:SetAlpha(on and 0 or 1)
	elseif kind == "pet" then
		-- The plain frame holding only PetHitIndicator and PetName: ours shows the hit text.
		local hit = rawget(_G, "PetHitIndicator")
		if hit then hit:GetParent():SetAlpha(on and 0 or 1) end
		for _, n in ipairs(PET_PARTS) do
			local r = _G[n]
			if r then r:SetAlpha(on and 0 or 1) end
		end
		for _, n in ipairs(PET_EMPTIED) do
			local r = _G[n]
			if r then
				petAtlas[n] = petAtlas[n] or { r:GetAtlas(), r:GetTexture() }
				if on then
					r:SetTexture(nil)
				elseif petAtlas[n][1] then
					r:SetAtlas(petAtlas[n][1], true)
				else
					r:SetTexture(petAtlas[n][2])
				end
			end
		end
	elseif kind == "party" then
		for _, k in ipairs(PARTY_PARTS) do
			local r = rawget(stock, k)
			if r then r:SetAlpha(on and 0 or 1) end
		end
		local overlay = rawget(stock, "PartyMemberOverlay")
		local status = overlay and rawget(overlay, "Status")
		if status then status:SetAlpha(on and 0 or 1) end
		local portrait = rawget(stock, "Portrait")
		if portrait then portrait:SetShown(not on) end
	end
end

-- The client's UI modes (a cutscene, a pet battle, a spectator view) hide
-- frames by roleset (C_Roleset, Blizzard_UIModes): ours take the stock unit
-- frames' "unitFrames" (PlayerFrame.xml, TargetFrame.xml, PartyFrame.xml), as
-- oUF tags its own. Protected (rule 4): set out of combat, once; what hangs
-- off ours (the aura rows) goes with them.
local function roleset(f)
	if f.psRoleset or not f.SetRolesets or InCombatLockdown() then return end
	f:SetRolesets("unitFrames")
	f.psRoleset = true
end

local function inset(l, t, w, h, i)
	return l + i[1], t - i[2], w - i[1] - i[3], h - i[2] - i[4]
end

-- What our frame sits on, -> left, top, width, height in that region's
-- units, and its effective scale; nil when there is nothing to read.
local function rectOf(f)
	local spec, stock = f.spec, f.spec.stock()
	-- A stock frame with no points reads as at its parent's corner, not where
	-- it shows: the pet frame before its first pet, and between its managed
	-- container's ClearAllPoints and Layout (ManagedFrameContainerMixin:
	-- UpdateFrame). Never read then: ours stay where they were.
	local anchored = stock and stock:GetNumPoints() > 0
	if spec.on == "selection" and stock then
		if not anchored then return nil end
		local r = rawget(stock, "Selection")
		if r and r:GetLeft() and r:GetWidth() > 0 then return r:GetLeft(), r:GetTop(), r:GetWidth(), r:GetHeight(), r:GetEffectiveScale() end
		if stock:GetLeft() then
			local l, t, w, h = inset(stock:GetLeft(), stock:GetTop(), stock:GetWidth(), stock:GetHeight(), spec.inset or BODY)
			return l, t, w, h, stock:GetEffectiveScale()
		end
		return nil
	end
	-- A frame the game shows and lays out (a party member, a boss, a target
	-- of target): its own rect while it has one.
	if anchored and stock:IsShown() and stock:GetLeft() then
		local l, t, w, h = stock:GetLeft(), stock:GetTop(), stock:GetWidth(), stock:GetHeight()
		if spec.on == "body" then l, t, w, h = inset(l, t, w, h, BODY) end
		lastRect[f] = { l, t, w, h, stock:GetEffectiveScale() }
		return unpack(lastRect[f])
	end
	if lastRect[f] then return unpack(lastRect[f]) end
	-- Never shown yet: where the stacking system will put it, below its top
	-- left corner (the party's VerticalLayoutFrame, the bosses' container).
	local st = spec.stack
	local c = st and st.container()
	if c and c:GetLeft() then
		local s = stock and stock:GetScale() or 1
		local h = (stock and stock:GetHeight() > 0 and stock:GetHeight() or st.height)
		local w = stock and stock:GetWidth() or 0
		local l = c:GetLeft() / s
		local t = c:GetTop() / s - (st.index - 1) * (h + st.gap() / s)
		if spec.on == "body" then l, t, w, h = inset(l, t, w, h, BODY) end
		return l, t, w, h, c:GetEffectiveScale() * s
	end
	if anchored and stock:GetLeft() then
		return stock:GetLeft(), stock:GetTop(), stock:GetWidth(), stock:GetHeight(), stock:GetEffectiveScale()
	end
	return nil
end

local function place()
	if InCombatLockdown() then
		pending = true
		return
	end
	pending = false
	local base = UIParent:GetEffectiveScale()
	for _, f in ipairs(frames) do
		local l, t, w, h, s = rectOf(f)
		local want = f.spec.height
		if want and h and h > want then t, h = t - (h - want) / 2, want end
		if l and w > 0 then
			-- Ours hang off UIParent at the region's effective scale, so its
			-- units are ours: the box's left and top are our offsets.
			f:SetScale(s / base)
			f:ClearAllPoints()
			f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t)
			f:SetSize(w, h)
			layout(f)
		end
	end
end
M.Place = place

-- When ours show: always (the player), while the unit exists (the unit
-- watch), or by a state driver (party, targets of target). Party frames
-- stand down while Edit Mode's "Raid-Style Party Frames" is on, the targets
-- of target while the game's "Target of Target" option is off
-- (showTargetOfTarget). Out of combat only.
local function partyStandsDown()
	return EditModeManagerFrame and EditModeManagerFrame.UseRaidStylePartyFrames and EditModeManagerFrame:UseRaidStylePartyFrames()
end

local function watch(f, on)
	local spec = f.spec
	UnregisterUnitWatch(f)
	UnregisterStateDriver(f, "visibility")
	if on and spec.tot and GetCVar("showTargetOfTarget") == "0" then on = false end
	if on and spec.party and partyStandsDown() then on = false end
	if not on then return f:Hide() end
	if spec.show == "always" then
		f:Show()
	elseif spec.show == "watch" then
		RegisterUnitWatch(f)
	else
		RegisterStateDriver(f, "visibility", spec.show)
	end
end

-- Edit Mode shows the party and boss frames (its "Party Frames" option, the
-- boss container) and the pet frame with no unit there: ours stand in with
-- the player, as the game's do, until it closes.
local function standIn(f)
	local spec = f.spec
	if not editing then return false end
	if spec.party then return EditModeManagerFrame.ArePartyFramesForcedShown and EditModeManagerFrame:ArePartyFramesForcedShown() and not partyStandsDown() end
	if spec.boss then return BossTargetFrameContainer and rawget(BossTargetFrameContainer, "isInEditMode") end
	if spec.unit == "pet" then return PetFrame and rawget(PetFrame, "isInEditMode") and not UnitExists("pet") end
	return false
end

local function preview(f)
	local want = standIn(f) and "player" or nil
	if want == f.psPreview then return end
	f.psPreview = want
	if want then
		UnregisterUnitWatch(f)
		UnregisterStateDriver(f, "visibility")
		f:SetAttribute("unit", "player")
		f:Show()
	else
		f:SetAttribute("unit", f.spec.unit)
		watch(f, ns.Enabled(KEY))
	end
	f.psPortraitOf = nil
	paint(f)
end

function M.Apply()
	if InCombatLockdown() then
		pending = true
		return
	end
	local on = ns.Enabled(KEY)
	for _, f in ipairs(frames) do
		roleset(f)
		veil(f, on)
		f.psPreview = nil
		f:SetAttribute("unit", f.spec.unit)
		watch(f, on)
	end
	if on then
		place()
		paintAll()
	end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local UNIT_EVENTS = {
	"UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_POWER_FREQUENT", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
	"UNIT_NAME_UPDATE", "UNIT_LEVEL", "UNIT_FACTION", "UNIT_CLASSIFICATION_CHANGED", "UNIT_PORTRAIT_UPDATE",
	"UNIT_MODEL_CHANGED", "UNIT_HEAL_PREDICTION", "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_HEAL_ABSORB_AMOUNT_CHANGED",
	"UNIT_THREAT_SITUATION_UPDATE", "UNIT_CONNECTION", "UNIT_FLAGS", "UNIT_PHASE", "UNIT_ENTERED_VEHICLE",
	"UNIT_EXITED_VEHICLE", "UNIT_TARGET", "UNIT_PET",
}
local ALL_EVENTS = {
	"PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
	"PLAYER_ENTERING_WORLD", "EDIT_MODE_LAYOUTS_UPDATED", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED", "CVAR_UPDATE",
	"GROUP_ROSTER_UPDATE", "INSTANCE_ENCOUNTER_ENGAGE_UNIT", "PLAYER_ROLES_ASSIGNED",
}

-- The power cost of the player's cast, as the stock player frame predicts it
-- (UnitFrameManaCostPredictionBars_Update): the spell's cost in the power the
-- bar shows, from its start till it ends, kept while another cast still runs.
-- The cost may be secret: handed to the bar unread. A power type the client
-- keeps secret is taken to be the bar's.
local CAST_END = { UNIT_SPELLCAST_STOP = true, UNIT_SPELLCAST_FAILED = true, UNIT_SPELLCAST_INTERRUPTED = true, UNIT_SPELLCAST_SUCCEEDED = true }
local function castCost(event, spellID)
	local f = byUnit.player
	if not (f and f.cost) then return end
	if event == "UNIT_SPELLCAST_START" then
		local cost, power = 0, ns.Clean(UnitPowerType("player"))
		for _, c in ipairs(C_Spell and C_Spell.GetSpellPowerCost and C_Spell.GetSpellPowerCost(spellID) or {}) do
			local kind = ns.Clean(c.type)
			if kind == nil or kind == power then
				cost = c.cost
				break
			end
		end
		f.psCost = cost
	elseif not (UnitCastingInfo and ns.Clean(select(9, UnitCastingInfo("player")))) then
		f.psCost = nil
	end
	paint(f)
end

-- What brings another unit into a frame: its bars snap to it.
local UNIT_CHANGE = { PLAYER_TARGET_CHANGED = true, PLAYER_FOCUS_CHANGED = true, GROUP_ROSTER_UPDATE = true, UNIT_PET = true,
	UNIT_ENTERED_VEHICLE = true, UNIT_EXITED_VEHICLE = true, UNIT_TARGET = true, INSTANCE_ENCOUNTER_ENGAGE_UNIT = true }

local function onEvent(_, event, unit, _, spellID)
	if not ns.Enabled(KEY) then return end
	if event == "UNIT_SPELLCAST_START" or CAST_END[event] then
		if unit == "player" then castCost(event, spellID) end
		return
	end
	local snap = UNIT_CHANGE[event]
	if snap and event ~= "UNIT_TARGET" and event ~= "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
		-- A unit may have changed under a secret GUID: its model again.
		for _, f in ipairs(frames) do if f.psPortraitOf == false then f.psPortraitOf = nil end end
	end
	if unit == "player" and (event == "UNIT_PET" or event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") then
		-- The pet frame the game shows (a pet summoned, a vehicle) is laid out
		-- by the player's managed container: ours placed on it next frame.
		C_Timer.After(0, function() if InCombatLockdown() then pending = true else place() end end)
	end
	if event == "PLAYER_REGEN_ENABLED" then
		if pending then M.Apply() end
		return paintAll()
	elseif event == "EDIT_MODE_LAYOUTS_UPDATED" or event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
		-- Next frame: Edit Mode applies the new layout in its own handler of
		-- this event. A layout may switch Raid-Style Party Frames: shown again.
		C_Timer.After(0, function()
			if InCombatLockdown() then pending = true return end
			for _, f in ipairs(frames) do if f.spec.party then watch(f, true) end end
			place()
			paintAll()
		end)
		return
	elseif event == "CVAR_UPDATE" or event == "GROUP_ROSTER_UPDATE" then
		-- New party members get the game's frames from its pool: veiled too,
		-- and placed on them.
		if not InCombatLockdown() then M.Apply() else pending = true end
		return paintAll(snap)
	end
	if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_ROLES_ASSIGNED"
		or event == "UNIT_THREAT_SITUATION_UPDATE" or event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT"
		or event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" then
		return paintAll(snap)
	end
	if event == "UNIT_PET" and byUnit.pet then paint(byUnit.pet, true) end
	for _, f in ipairs(frames) do
		if shown(f) == unit then
			if event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_MODEL_CHANGED" then f.psPortraitOf = nil end
			paint(f)
		end
	end
	if event == "UNIT_TARGET" then
		if unit == "target" and byUnit.targettarget then paint(byUnit.targettarget, true) end
		if unit == "focus" and byUnit.focustarget then paint(byUnit.focustarget, true) end
	end
end

-- The targets of target have no events of their own: redrawn five times a
-- second, as the stock ones are (TargetFrame's OnUpdate). While Edit Mode is
-- open, ours follow the stock boxes the player drags, and stand in for the
-- frames Edit Mode shows with no unit.
local elapsed = 0
local function onUpdate(_, dt)
	if editing and not InCombatLockdown() then
		for _, f in ipairs(frames) do preview(f) end
		place()
	end
	elapsed = elapsed + dt
	if elapsed < 0.2 then return end
	elapsed = 0
	if byUnit.targettarget then paint(byUnit.targettarget) end
	if byUnit.focustarget then paint(byUnit.focustarget) end
end

function M.Enable()
	if not built then
		built = true
		for _, spec in ipairs(SPECS) do build(spec) end
		driver = CreateFrame("Frame")
		for _, e in ipairs(UNIT_EVENTS) do driver:RegisterEvent(e) end
		for _, e in ipairs(ALL_EVENTS) do driver:RegisterEvent(e) end
		for _, e in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_SUCCEEDED" }) do
			driver:RegisterUnitEvent(e, "player")
		end
		driver:SetScript("OnEvent", onEvent)
		driver:SetScript("OnUpdate", onUpdate)
		EventRegistry:RegisterCallback("EditMode.Enter", function()
			editing = ns.Enabled(KEY)
			onUpdate(nil, 0)
		end, M)
		EventRegistry:RegisterCallback("EditMode.Exit", function()
			editing = false
			if not ns.Enabled(KEY) or InCombatLockdown() then return end
			for _, f in ipairs(frames) do preview(f) end
			place()
			paintAll()
		end, M)
		Theme.OnChanged(function() if ns.Enabled(KEY) then paintAll() end end)
	end
	M.Apply()
end

---------------------------------------------------------------------------
-- Settings (/pui unitframes): a small page of our own
---------------------------------------------------------------------------

local OPTIONS = "PolestarUIUnitFramesOptions"
local page

local function setOpt(k, v)
	if v == nil then v = DEFAULTS[k] end
	opts()[k] = v
	for _, f in ipairs(frames) do layout(f) end
	paintAll()
end

M.Option, M.SetOption = opt, setOpt

local function buildOptions()
	local f = W.Shell(OPTIONS, { scalePath = "ui.menuScale", sidebar = 0, width = 520, height = 360 })
	ns.Plain(f)
	ns.WindowMenu(f, KEY)
	Polestar.CloseOnEscape(OPTIONS)
	W.ShellTitle(f, "Unit frames", "Move them in the game's Edit Mode")
	W.ShellTabs(f, nil)
	local body = f.Content
	local y = 0
	local function row(r)
		r:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -y)
		r:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, -y)
		y = y + (r:GetHeight() > 0 and r:GetHeight() or W.RowH())
		return r
	end
	f.portrait = row(W.Toggle(body, "3D portraits", nil, "The unit's model in a square beside the bars.", nil,
		{ get = function() return opt("portrait") end, set = function(v) setOpt("portrait", v) end }))
	f.powerText = row(W.Toggle(body, "Power text", nil, "The unit's power as a number, shown as the game's Status Text options show the health.", nil,
		{ get = function() return opt("powerText") end, set = function(v) setOpt("powerText", v) end }))
	f.sparkle = row(W.Toggle(body, "Sparkle", nil, "Polestar's stars over the health bars, as over its windows' header band.", nil,
		{ get = function() return opt("sparkle") end, set = function(v) setOpt("sparkle", v) end }))
	f.smooth = row(W.Toggle(body, "Smooth bars", nil, "Health and power glide to a new value instead of jumping.", nil,
		{ get = function() return opt("smooth") end, set = function(v) setOpt("smooth", v) end }))
	f.trail = row(W.Toggle(body, "Damage trail", nil, "Health just lost stays red for a moment, then drains away.", nil,
		{ get = function() return opt("trail") end, set = function(v) setOpt("trail", v) end }))
	W.ShellBody(f, y)
	return f
end

function M.Show()
	page = page or buildOptions()
	page:Show()
	if page.portrait.Refresh then page.portrait:Refresh() end
	for _, k in ipairs({ "powerText", "sparkle", "smooth", "trail" }) do
		if page[k].Refresh then page[k]:Refresh() end
	end
end

ns.Module(KEY, M)
