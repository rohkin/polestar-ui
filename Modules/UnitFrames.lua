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
local DEFAULTS = { ground = 0.6, portrait = true }

-- The body of a frame on TargetFrameTemplate (the target's, focus's and
-- bosses'): where Edit Mode lays the target's and focus's Selection box
-- (EditModeUnitFrameSystemMixin:AnchorSelectionFrame); the pet's box.
local BODY = { 20, 16, 20, 18 }
local PET_BODY = { 4, 3, 4, 6 }

-- What the game only shows and hides on a pet frame and a party member:
-- faded; a party portrait, which the game re-alphas at low health
-- (PartyMemberFrameMixin:UpdateMemberHealth), hidden.
local PET_PARTS = { "PetPortrait", "PetFrameTexture", "PetFrameFlash", "PetAttackModeTexture", "PetName", "PetFrameHealthBar", "PetFrameManaBar" }
local PARTY_PARTS = { "Texture", "VehicleTexture", "Flash", "Name", "HealthBarContainer", "ManaBar" }

local function member(i) return PartyFrame and rawget(PartyFrame, "MemberFrame" .. i) end
local function boss(i) return _G["Boss" .. i .. "TargetFrame"] end

-- Each frame: its unit; the stock frame it stands for; how that one is veiled
-- (system, fade, pet, party); what ours sits on (the system's Selection box,
-- the frame itself, or its body) and, for a frame inside a stacking system,
-- where it stands when the game has not placed it yet; when it shows (always,
-- the unit watch, a state driver); and its look: a portrait, a line with the
-- name (and level, rank), the health and power text, the portrait's side.
local SPECS = {
	{ unit = "player", name = "PolestarUIPlayerFrame", stock = function() return PlayerFrame end, veil = "system", on = "selection",
		show = "always", portrait = true, line = true, level = true, text = true, side = "LEFT", vehicle = "vehicle" },
	{ unit = "target", name = "PolestarUITargetFrame", stock = function() return TargetFrame end, veil = "system", on = "selection",
		show = "watch", portrait = true, line = true, level = true, rank = true, text = true, side = "RIGHT" },
	{ unit = "focus", name = "PolestarUIFocusFrame", stock = function() return FocusFrame end, veil = "system", on = "selection",
		show = "watch", portrait = true, line = true, level = true, rank = true, text = true, side = "RIGHT" },
	-- The stock target of target hides with no unit, and while the target
	-- is dead (TargetOfTargetMixin:Update).
	{ unit = "targettarget", name = "PolestarUITargetToT", stock = function() return TargetFrameToT end, veil = "fade", on = "frame",
		show = "[@targettarget,noexists][@target,dead] hide; show", tot = true, side = "LEFT" },
	{ unit = "focustarget", name = "PolestarUIFocusToT", stock = function() return FocusFrameToT end, veil = "fade", on = "frame",
		show = "[@focustarget,noexists][@focus,dead] hide; show", tot = true, side = "LEFT" },
	-- The pet frame shows the player while the player drives a vehicle, as
	-- the stock one does (its clicks follow through toggleForVehicle).
	{ unit = "pet", name = "PolestarUIPetFrame", stock = function() return PetFrame end, veil = "pet", on = "selection", inset = PET_BODY,
		show = "watch", portrait = true, line = true, text = true, compact = true, side = "LEFT", vehicle = "player" },
}
for i = 1, 4 do
	-- The game hides the party frames in a raid (ShouldShowPartyFrames) and
	-- when Edit Mode's "Raid-Style Party Frames" is on (then the compact ones show).
	SPECS[#SPECS + 1] = { unit = "party" .. i, name = "PolestarUIPartyFrame" .. i, stock = function() return member(i) end, veil = "party", on = "frame",
		stack = { container = function() return PartyFrame end, index = i, height = 53, gap = function() return rawget(PartyFrame, "spacing") or 10 end },
		show = "[group:raid] hide; [@party" .. i .. ",exists] show; hide", party = true, portrait = true, line = true, text = true, compact = true, side = "LEFT" }
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
-- BOTH, NONE), shown always with statusText on, else on mouse-over, as the
-- stock bars do (TextStatusBarMixin:UpdateTextString). Values go straight
-- from the client into SetFormattedText (they are secret).
local function healthText(f, unit)
	local fs = f.healthText
	if not fs then return end
	if ns.Clean(UnitIsConnected(unit)) == false then return fs:SetFormattedText("%s", PLAYER_OFFLINE or "Offline") end
	if ns.Clean(UnitIsGhost(unit)) then return fs:SetFormattedText("%s", GHOST or "Ghost") end
	if ns.Clean(UnitIsDead(unit)) then return fs:SetFormattedText("%s", DEAD or "Dead") end
	local mode = GetCVar("statusTextDisplay") or "NUMERIC"
	local always = GetCVar("statusText") == "1"
	if mode == "NONE" or not (always or f.psHover) then return fs:SetText("") end
	local pct = UnitHealthPercent and CurveConstants and UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)
	if mode == "PERCENT" and pct then
		fs:SetFormattedText("%.0f%%", pct)
	elseif mode == "BOTH" and pct then
		fs:SetFormattedText("%.0f%%  %s", pct, AbbreviateNumbers(UnitHealth(unit)))
	else
		fs:SetFormattedText("%s / %s", AbbreviateNumbers(UnitHealth(unit)), AbbreviateNumbers(UnitHealthMax(unit)))
	end
end

local function powerText(f, unit)
	if not f.powerText then return end
	local always = GetCVar("statusText") == "1"
	if GetCVar("statusTextDisplay") == "NONE" or not (always or f.psHover) then return f.powerText:SetText("") end
	f.powerText:SetFormattedText("%s", AbbreviateNumbers(UnitPower(unit)))
end

local RANKS = { worldboss = "Boss", rareelite = "Rare Elite", elite = "Elite", rare = "Rare" }

local function nameLine(f, unit)
	if f.levelText then
		local level = ns.Clean(UnitEffectiveLevel and UnitEffectiveLevel(unit) or UnitLevel(unit))
		local lv = level and (level < 1 and "??" or tostring(level)) or ""
		local rank = f.spec.rank and RANKS[ns.Clean(UnitClassification(unit)) or ""]
		if rank then lv = lv .. " " .. rank end
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
	local a = opt("ground")
	if unit == "player" or unit == "vehicle" then
		if f.spec.unit == "player" and ns.Clean(UnitAffectingCombat("player")) then
			local r, g, b = Theme.Color("danger")
			return H.PaintGround(f.Ground, a, r, g, b, 1)
		end
	else
		local status = ns.Clean(UnitThreatSituation("player", unit))
		if status and status > 0 and GetThreatStatusColor then
			local r, g, b = GetThreatStatusColor(status)
			return H.PaintGround(f.Ground, a, r, g, b, 1)
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

local function paint(f)
	if not f:IsVisible() then return end
	local unit = shown(f)
	if not ns.Clean(UnitExists(unit)) then return end
	f:SetAlpha(stockAlpha(f))
	local max = UnitHealthMax(unit)
	H.SetBarColor(f.Health, H.UnitColor(unit))
	f.Health:SetMinMaxValues(0, max)
	f.Health:SetValue(UnitHealth(unit))
	f.Heal:SetMinMaxValues(0, max)
	f.Heal:SetValue(UnitGetIncomingHeals(unit) or 0)
	f.Absorb:SetMinMaxValues(0, max)
	f.Absorb:SetValue(UnitGetTotalAbsorbs(unit))
	f.HealAbsorb:SetMinMaxValues(0, max)
	f.HealAbsorb:SetValue(UnitGetTotalHealAbsorbs(unit))
	H.SetBarColor(f.Power, H.PowerColor(unit))
	f.Power:SetMinMaxValues(0, UnitPowerMax(unit))
	f.Power:SetValue(UnitPower(unit))
	healthText(f, unit)
	powerText(f, unit)
	nameLine(f, unit)
	edge(f, unit)
	if f.portrait then
		f.portrait:SetShown(opt("portrait"))
		if opt("portrait") and f.psPortraitOf ~= UnitGUID(unit) then
			f.psPortraitOf = UnitGUID(unit)
			H.SetPortrait(f.portrait, unit)
		end
	end
end

local function paintAll()
	for _, f in ipairs(frames) do
		f.psPortraitOf = nil
		paint(f)
	end
end

---------------------------------------------------------------------------
-- Building
---------------------------------------------------------------------------

-- Our frame's own layout, on the size it is given (the stock box): the
-- portrait square on its side; beside it a line with the level, rank and
-- name, then the health bar (its text at the far end) over the power bar. A
-- target of target is only its name on the health bar.
local function layout(f)
	local w, h = f:GetWidth(), f:GetHeight()
	if w <= 0 or h <= 0 then return end
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
	for _, s in ipairs({ f.Heal, f.Absorb, f.HealAbsorb }) do s:SetWidth(w - x0 - x1) end
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

local function build(spec)
	-- A secure unit button of our own: left-click targets, right-click opens
	-- the game's unit menu from secure code (togglemenu: Set Focus and the
	-- rest stay usable), click bindings run through SecureUnitButton_OnClick,
	-- and the ping system takes it as a unit frame.
	local f = CreateFrame("Button", spec.name, UIParent, "SecureUnitButtonTemplate,PingableUnitFrameTemplate")
	f.spec = spec
	f:SetFrameStrata("LOW")
	f:SetFrameLevel(100)
	f:SetSize(spec.tot and 112 or 192, spec.tot and 40 or 66)
	f:RegisterForClicks("AnyUp")
	f:SetAttribute("unit", spec.unit)
	f:SetAttribute("*type1", "target")
	f:SetAttribute("*type2", "togglemenu")
	if spec.vehicle then f:SetAttribute("toggleForVehicle", true) end
	f.Ground = H.Ground(f)
	if spec.portrait then f.portrait = H.Portrait(f) end
	f.Health = H.Bar(f)
	f.Health:SetClipsChildren(true) -- the heal and absorb segments end at the bar's ends
	f.Heal = H.Segment(f.Health, "success", 0.45)
	f.Absorb = H.Segment(f.Heal, "text", 0.35)
	f.HealAbsorb = H.Segment(f.Health, "danger", 0.5, true)
	f.Power = H.Bar(f)
	f.Name = H.Text(spec.line and f or f.Health, (spec.line and not spec.compact) and "label" or "small", "text")
	f.Name:SetPoint("LEFT", f.Health, "LEFT", 4, 0)
	f.Name:SetPoint("RIGHT", f.Health, "RIGHT", -4, 0)
	if spec.level then f.levelText = H.Text(f, "small", "textDim") end
	if spec.text then
		f.healthText = H.Text(f.Health, spec.compact and "small" or "number", "text")
		f.healthText:SetJustifyH("RIGHT")
		f.healthText:SetPoint("RIGHT", f.Health, "RIGHT", spec.compact and -1 or -4, 0)
		f.powerText = H.Text(f.Power, "small", "textDim")
		f.powerText:SetPoint("CENTER", f.Power, "CENTER", 0, 0)
	end
	f:HookScript("OnEnter", onEnter)
	f:HookScript("OnLeave", onLeave)
	f:HookScript("OnSizeChanged", layout)
	f:HookScript("OnShow", function(self) self.psPortraitOf = nil; paint(self) end)
	layout(f)
	frames[#frames + 1] = f
	byUnit[spec.unit] = f
	return f
end

---------------------------------------------------------------------------
-- The stock frames (rule 16) and placement
---------------------------------------------------------------------------

-- Veil (on) or give back (off) one stock frame. Out of combat only.
local function veil(f, on)
	local stock = f.spec.stock()
	if not stock then return end
	stock:EnableMouse(not on)
	local kind = f.spec.veil
	if kind == "system" then
		local c = rawget(stock, "PlayerFrameContainer") or rawget(stock, "TargetFrameContainer")
		local content = rawget(stock, "PlayerFrameContent") or rawget(stock, "TargetFrameContent")
		local main = content and (rawget(content, "PlayerFrameContentMain") or rawget(content, "TargetFrameContentMain"))
		if c then c:SetShown(not on) end
		if main then main:SetShown(not on) end
	elseif kind == "fade" then
		stock:SetAlpha(on and 0 or 1)
	elseif kind == "pet" then
		for _, n in ipairs(PET_PARTS) do
			local r = _G[n]
			if r then r:SetAlpha(on and 0 or 1) end
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

local function inset(l, t, w, h, i)
	return l + i[1], t - i[2], w - i[1] - i[3], h - i[2] - i[4]
end

-- What our frame sits on, -> left, top, width, height in that region's
-- units, and its effective scale; nil when there is nothing to read.
local function rectOf(f)
	local spec, stock = f.spec, f.spec.stock()
	if spec.on == "selection" and stock then
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
	if stock and stock:IsShown() and stock:GetLeft() then
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
	if stock and stock:GetLeft() then
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
	"GROUP_ROSTER_UPDATE", "INSTANCE_ENCOUNTER_ENGAGE_UNIT",
}

local function onEvent(_, event, unit)
	if not ns.Enabled(KEY) then return end
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
		return paintAll()
	elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" or event == "PLAYER_REGEN_DISABLED"
		or event == "UNIT_THREAT_SITUATION_UPDATE" or event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT"
		or event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" then
		return paintAll()
	end
	if event == "UNIT_PET" and byUnit.pet then paint(byUnit.pet) end
	for _, f in ipairs(frames) do
		if shown(f) == unit then
			if event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_MODEL_CHANGED" then f.psPortraitOf = nil end
			paint(f)
		end
	end
	if event == "UNIT_TARGET" then
		if unit == "target" and byUnit.targettarget then paint(byUnit.targettarget) end
		if unit == "focus" and byUnit.focustarget then paint(byUnit.focustarget) end
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

local function buildOptions()
	local f = W.Shell(OPTIONS, { scalePath = "ui.menuScale", sidebar = 0, width = 520, height = 300 })
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
	f.Ground = row(W.Slider(body, "Background opacity", nil, 0, 100, 5, "%d%%", "The ground behind the bars. Their colours follow your Polestar theme; with its \"Class colour\" on, players wear their class colour.", nil,
		{ get = function() return math.floor(opt("ground") * 100 + 0.5) end, set = function(v) setOpt("ground", v and v / 100) end }))
	f.portrait = row(W.Toggle(body, "3D portraits", nil, "The unit's model in a square beside the bars.", nil,
		{ get = function() return opt("portrait") end, set = function(v) setOpt("portrait", v) end }))
	W.ShellBody(f, y)
	return f
end

function M.Show()
	page = page or buildOptions()
	page:Show()
	if page.Ground.Refresh then page.Ground:Refresh() end
	if page.portrait.Refresh then page.portrait:Refresh() end
end

ns.Module(KEY, M)
