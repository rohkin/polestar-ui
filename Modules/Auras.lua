-- Player buffs and debuffs (docs/windows/auras.md): the game's own aura
-- buttons in the HUD's look, restyled in place, never rebuilt. BuffFrame and
-- DebuffFrame are Edit Mode systems (docs/CLIENT.md, rule 17): their place,
-- icon size, icons per row, direction, wrap, padding, opacity and visibility
-- stay the game's and the player's, and each button keeps the game's own
-- handlers (the tooltip, cancel on right-click, which only the game's code
-- may do in combat). On each button only its art changes: the icon cropped
-- square, the game's debuff and weapon-enchant borders faded with SetAlpha
-- (the game swaps their atlases and shows or hides them, which keeps the
-- alpha), a 1px hairline of ours round the icon (a debuff's in its dispel
-- type's colour, a weapon enchant's in the epic colour), the duration and
-- stack count in Polestar's number face, outlined, at the game's sizes and
-- colours. Nothing of a button is read but what kind of aura it holds; the
-- texts never (rule 3). What is ours is kept in a weak table; no key is
-- written on a stock frame. The target's and focus's auras are rows of our
-- own under our unit frames (below), the game's veiled.

local ADDON, ns = ...
local Theme = Polestar.Theme
local H = ns.HUD

local M = { noun = "buffs and debuffs" }
local KEY = "auras"
local CROP = 0.08 -- the icon's baked border, cropped as ns.GameIcon does
local LOOK = H.ICONS -- the HUD look's Icons group (2 px at most while it follows Polestar)
-- AuraButtonArtTemplate's borders (BuffFrameTemplates.xml).
local FADED = { "DebuffBorder", "TempEnchantBorder" }

local looks = setmetatable({}, { __mode = "k" }) -- stock aura button -> its hairlines of ours
local driver, started

-- Every aura button of both frames (AuraFrameMixin:AuraFrame_OnLoad keeps
-- them in `auraFrames`); a private aura's anchor there is the game's alone.
local function each(fn)
	for _, name in ipairs({ "BuffFrame", "DebuffFrame" }) do
		local f = rawget(_G, name)
		local list = f and rawget(f, "auraFrames")
		if list then
			for _, b in ipairs(list) do
				if not rawget(b, "isAuraAnchor") then fn(b, f) end
			end
		end
	end
end

-- The hairline's colour by what the button holds (AuraButtonMixin's
-- `auraType`; Edit Mode's examples take their frame's): a debuff its dispel
-- type's (the game's colours; the plain debuff red while the type is secret),
-- a weapon enchant the epic colour (the game's border is purple), a buff the
-- border token.
local function edgeColor(b, f)
	local example = rawget(b, "isExample")
	local kind = example and rawget(f, "exampleAuraType") or rawget(b, "auraType")
	if kind == "Debuff" or kind == "DeadlyDebuff" then
		local info = not example and rawget(b, "buttonInfo")
		local types = AuraUtil and AuraUtil.GetDebuffDisplayInfoTable and AuraUtil.GetDebuffDisplayInfoTable()
		local d = types and (types[info and ns.Clean(info.debuffType) or "None"] or types.None)
		if d and d.color then return d.color:GetRGB() end
		return Theme.Color("danger")
	elseif kind == "TempEnchant" then
		local r, g, bl = ns.QualityRGB(4)
		if r then return r, g, bl end
	end
	return nil -- the HUD's edge (H.PaintTint)
end

local function paint(b, f, shown)
	local icon = rawget(b, "Icon")
	if not icon then return end
	local l = looks[b]
	if not l then
		l = { edges = ns.Hairlines(b, icon) }
		looks[b] = l
	end
	for _, k in ipairs(FADED) do
		local t = rawget(b, k)
		if t then t:SetAlpha(shown and 0 or 1) end
	end
	if shown ~= (l.square or false) then
		if shown then icon:SetTexCoord(CROP, 1 - CROP, CROP, 1 - CROP) else icon:SetTexCoord(0, 1, 0, 1) end
		l.square = shown
	end
	H.Face(rawget(b, "Count"), "number", shown)
	-- Where the game swaps the duration's font each frame (zhTW's smaller
	-- face for long buffs, AuraButtonMixin:OnUpdate), it stays the game's.
	if not SMALLER_AURA_DURATION_FONT_MIN_THRESHOLD then H.Face(rawget(b, "Duration"), "number", shown) end
	H.PaintTint(l.edges, shown, LOOK, edgeColor(b, f))
end

---------------------------------------------------------------------------
-- Target and focus auras: a row of ours under our unit frames
---------------------------------------------------------------------------

-- The stock target's and focus's auras are the client's secure aura
-- container (TargetFrameContent.TargetFrameContentContextual.Auras), whose
-- buttons addon code cannot reach. With the user's leave (docs/CLIENT.md,
-- rule 16's exception) that container alone is faded with SetAlpha(0) and
-- switched off with its SetEnabled(false), out of combat, and a row of ours under our own target and focus frames shows
-- the auras instead. Everything of an aura is handed over unread: the ids
-- come sorted by the client (the player's own first: UnitAuraSortRule
-- Default, and the "PLAYER" filter says which are the player's), the icon
-- goes into SetTexture, the time into a Cooldown as a duration object, the
-- stack count into SetFormattedText; only the dispel type (through
-- ns.Clean: plain red while secret) and who applied it are looked at.
-- While auras are secret (combat, an encounter, a keystone, a PvP match) the
-- client refuses every C_UnitAuras call (and the aura tooltip) of a tainted
-- caller outright ("Auras cannot be accessed when secret while tainted"):
-- ours hide and the game's container shows (docs/CLIENT.md, rule 3).
local ROWS = {
	{ unit = "target", ours = "PolestarUITargetFrame", stock = "TargetFrame" },
	{ unit = "focus", ours = "PolestarUIFocusFrame", stock = "FocusFrame" },
}
local SIZE, SMALL, GAP = 20, 16, 2 -- the player's own auras large, as the game's (21 and 17)

local fighting -- PLAYER_REGEN_DISABLED to PLAYER_REGEN_ENABLED
local function secret()
	return fighting or InCombatLockdown() or (C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret()) or false
end

local function stockAuras(row)
	local f = rawget(_G, row.stock)
	local c = f and rawget(f, "TargetFrameContent")
	c = c and rawget(c, "TargetFrameContentContextual")
	local a = c and rawget(c, "Auras")
	if a and not (a.IsForbidden and a:IsForbidden()) then return a end
end

-- Fade the game's container while ours stands in (both modules on, our
-- frame there, auras not secret), give it back otherwise. Out of combat
-- only (PLAYER_REGEN_DISABLED still is, rule 4: the veil lifts there); a container
-- that refuses is left alone, and ours never shows beside it. -> true when
-- it changed.
local function veil(row)
	local want = (ns.Enabled(KEY) and ns.Enabled("unitframes") and rawget(_G, row.ours) ~= nil and not secret()) or false
	if want == (row.veiled or false) or row.refused or InCombatLockdown() then return end
	local a = stockAuras(row)
	if not a then return end
	if pcall(a.SetAlpha, a, want and 0 or 1) then row.veiled = want else row.refused = true end
	-- Faded, its buttons still took the mouse (the game's aura tooltip beside
	-- ours): the container's own public switch drops them (rule 16's exception).
	if a.SetEnabled and not row.refused then pcall(a.SetEnabled, a, not want) end
	return true
end

local function slot(row, i)
	local b = row.slots[i]
	if b then return b end
	b = CreateFrame("Frame", nil, row.frame)
	b.fill = b:CreateTexture(nil, "BACKGROUND")
	b.fill:SetTexture(Theme.Media("white"))
	b.fill:SetAllPoints(b)
	b.Icon = ns.GameIcon(b, "BORDER")
	b.Icon:SetAllPoints(b)
	b.edges = ns.Hairlines(b, b)
	-- The time left: the game's own sweep and countdown, fed a duration object.
	b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
	b.cd:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
	b.cd:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
	b.cd:SetDrawEdge(false)
	b.cd:SetReverse(true)
	b.cd:SetHideCountdownNumbers(false)
	b.count = H.Text(b.cd, "number", "text")
	b.count:SetJustifyH("RIGHT")
	b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 1, -1)
	b:EnableMouse(true)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
		GameTooltip:SetUnitAuraByAuraInstanceID(row.unit, self.id)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	row.slots[i] = b
	return b
end

local function ids(unit, filter)
	local get = C_UnitAuras and C_UnitAuras.GetUnitAuraInstanceIDs
	return get and get(unit, filter, 32, Enum.UnitAuraSortRule and Enum.UnitAuraSortRule.Default or 1) or {}
end

-- One kind of aura in the game's order, the player's own first.
local function gather(list, unit, filter, harmful)
	local own = {}
	for _, id in ipairs(ids(unit, filter .. "|PLAYER")) do
		if ns.Clean(id) then own[id] = true end
	end
	local all = ids(unit, filter)
	for pass = 1, 2 do
		for _, id in ipairs(all) do
			local mine = ns.Clean(id) and own[id] or false
			if mine == (pass == 1) then list[#list + 1] = { id = id, harmful = harmful, own = mine } end
		end
	end
end

-- The game's filter (TargetFrameAuraContainerPrivateMixin:ShouldShowAuraAsDebuff):
-- on a hostile creature, another player's debuffs are left out, unless
-- "noBuffDebuffFilterOnTarget" is set. What the client keeps secret shows.
local function leftOut(unit, a, aura)
	if not a.harmful or a.own or GetCVarBool("noBuffDebuffFilterOnTarget") then return false end
	if ns.Clean(UnitIsPlayer(unit)) ~= false or ns.Clean(UnitIsFriend("player", unit)) ~= false then return false end
	return ns.Clean(aura.isFromPlayerOrPlayerPet) == true and ns.Clean(aura.nameplateShowAll) ~= true
end

local function paintRow(row)
	local ours = rawget(_G, row.ours)
	if not (ours and row.veiled and C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID) or secret() then
		if row.frame then row.frame:Hide() end
		return
	end
	if not row.frame then
		row.frame = CreateFrame("Frame", nil, ours)
		row.frame:SetPoint("TOPLEFT", ours, "BOTTOMLEFT", 0, -3)
		row.frame:SetPoint("TOPRIGHT", ours, "BOTTOMRIGHT", 0, -3)
		row.frame:SetHeight(SIZE)
		row.slots = {}
	end
	row.frame:Show()
	local unit, list = row.unit, {}
	-- A friend's buffs first, anyone else's debuffs first, as the game lays them.
	local friend = ns.Clean(UnitIsFriend("player", unit)) == true
	if friend then gather(list, unit, "HELPFUL", false) end
	gather(list, unit, "HARMFUL", true)
	if not friend then gather(list, unit, "HELPFUL", false) end
	local types = AuraUtil and AuraUtil.GetDebuffDisplayInfoTable and AuraUtil.GetDebuffDisplayInfoTable()
	local face = Theme.FontSpec("number")
	local gr, gg, gb = Theme.Color("bg")
	-- Our own frame's width; should the client ever keep it secret, the slim frame's.
	local width, x, n = ns.Clean(ours:GetWidth()) or 192, 0, 0
	for _, a in ipairs(list) do
		local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, a.id)
		local size = a.own and SIZE or SMALL
		if aura and not leftOut(unit, a, aura) then
			-- One row: what does not fit the frame's width is left out.
			if x + size > width then break end
			n = n + 1
			local b = slot(row, n)
			b.id = a.id
			b:SetSize(size, size)
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", row.frame, "TOPLEFT", x, 0)
			x = x + size + GAP
			b.fill:SetVertexColor(gr, gg, gb, H.GroundAlpha(LOOK))
			b.Icon:SetTexture(aura.icon)
			local d = C_UnitAuras.GetAuraDuration and C_UnitAuras.GetAuraDuration(unit, a.id)
			if d and b.cd.SetCooldownFromDurationObject then b.cd:SetCooldownFromDurationObject(d) else b.cd:Clear() end
			local fs = b.cd.GetCountdownFontString and b.cd:GetCountdownFontString()
			if fs then Theme.SetFace(fs, face, 9, "OUTLINE") end
			local count = C_UnitAuras.GetAuraApplicationDisplayCount and C_UnitAuras.GetAuraApplicationDisplayCount(unit, a.id, 2, 99)
			b.count:SetFormattedText("%s", count or "")
			local kind = a.harmful and types and (types[ns.Clean(aura.dispelName) or "None"] or types.None)
			if kind and kind.color then
				H.PaintTint(b.edges, true, LOOK, kind.color:GetRGB())
			elseif a.harmful then
				H.PaintTint(b.edges, true, LOOK, Theme.Color("danger"))
			else
				H.PaintEdge(b.edges, true, LOOK)
			end
			b:Show()
		end
	end
	for i = n + 1, #row.slots do row.slots[i]:Hide() end
end

local function paintRows(unit)
	for _, row in ipairs(ROWS) do
		if unit == nil or unit == row.unit then paintRow(row) end
	end
end

local function veilRows()
	for _, row in ipairs(ROWS) do
		if veil(row) then paintRow(row) end
	end
end

function M.Apply()
	if not started then return end
	local shown = ns.Enabled(KEY)
	each(function(b, f) paint(b, f, shown) end)
	veilRows()
	paintRows()
end

-- The game deals the auras over its buttons again on its own updates and
-- no hook may sit on them (rule 17): the shown buttons are painted again the
-- frame after each event its frames update on (BuffFrame.lua:
-- AuraFrameEventListenerMixin, BuffFrameMixin:OnEvent; Edit Mode's examples,
-- which also set the duration's font again). The collapse arrow and the
-- hidden buffs' timer only re-deal buffs over buff buttons (temporary
-- enchants come first), which changes nothing painted. The driver's
-- OnUpdate is set by soon() and clears itself after one pass.
local function flush(self)
	self:SetScript("OnUpdate", nil)
	-- The unit frames switched on or off, combat ended, auras no longer
	-- secret: the game's target and focus auras veiled or given back.
	veilRows()
	if not ns.Enabled(KEY) then return end
	each(function(b, f) if b:IsVisible() then paint(b, f, true) end end)
end
local function soon() if driver then driver:SetScript("OnUpdate", flush) end end

local EVENTS = { "UNIT_AURA", "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED",
	"WEAPON_ENCHANT_CHANGED", "WEAPON_SLOT_CHANGED", "GROUP_ROSTER_UPDATE", "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_ENTERING_WORLD",
	"EDIT_MODE_LAYOUTS_UPDATED", "ADDON_RESTRICTION_STATE_CHANGED" }

function M.Enable()
	if not rawget(_G, "BuffFrame") then return end
	started = true
	driver = CreateFrame("Frame", nil, UIParent)
	-- pcall: an event this client may not know (ADDON_RESTRICTION_STATE_CHANGED: auras secret or no longer).
	for _, e in ipairs(EVENTS) do pcall(driver.RegisterEvent, driver, e) end
	driver:SetScript("OnEvent", function(_, event, unit)
		-- Combat starting: the veil lifts now, while it still may.
		if event == "PLAYER_REGEN_DISABLED" then fighting = true; veilRows() elseif event == "PLAYER_REGEN_ENABLED" then fighting = false end
		if event == "UNIT_AURA" then paintRows(unit) else paintRows() end
		-- Only the units painted here: the player's (or vehicle's) buttons and the target's and focus's veil (auras
		-- turned secret with no event of its own); a raid's or the nameplates' UNIT_AURA would repaint every frame.
		if event ~= "UNIT_AURA" or unit == "player" or unit == "vehicle" or unit == "target" or unit == "focus" then soon() end
	end)
	EventRegistry:RegisterCallback("EditMode.Enter", soon, M)
	EventRegistry:RegisterCallback("EditMode.Exit", soon, M)
	-- The unit frames switched on or off: our rows stand in or the game's come back.
	hooksecurefunc(ns, "Switch", soon)
	Theme.OnChanged(function() paintRows(); soon() end)
	M.Apply()
end

ns.Module(KEY, M)
