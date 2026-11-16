-- Personal Resource Display (docs/windows/resource.md): the game's own
-- PersonalResourceDisplayFrame in the HUD's look, restyled in place, never
-- rebuilt. It is an Edit Mode system (docs/CLIENT.md, rule 17): its place,
-- Size, Bar Width, bar heights, Padding, the Hide toggles, Opacity and
-- Visibility all work by the game sizing, showing and hiding its own bars,
-- so nothing of it is moved, sized, shown or hidden here. On each of its
-- three bars (health, power, the Druid's mana in forms) we only add
-- textures of ours (kept in a weak table, no key written): a track, a flat
-- fill pinned to the game's fill texture (so it follows the bar with no value
-- or size read: both are secret in combat, rule 3), the heal, absorb, heal
-- absorb and cost segments pinned to the game's own prediction textures (the
-- game does the maths and the placing; we copy only whether each is shown),
-- and a 1px hairline. The game's bar art and prediction textures are faded
-- with SetAlpha, its bar text set in Polestar's face. Its power animations
-- (child frames of the power bar), TempMaxHealthLoss and the combo points
-- stay the game's.

local ADDON, ns = ...
local Theme = Polestar.Theme
local H = ns.HUD

local M = { noun = "personal resource display" }
local KEY = "resource"
local WHITE = Theme.Media("white")
local BG_ATLAS = "UI-HUD-CoolDownManager-Bar-BG" -- the bar's unnamed BACKGROUND art (PersonalResourceStatusBar)
local TEXTS = { "TextString", "LeftText", "RightText" }
-- The game's prediction textures and our segment pinned to each (a list: made in a fixed order).
local HEALTH_SEGMENTS = { { "myHealPrediction", "heal" }, { "otherHealPrediction", "heal" }, { "totalAbsorb", "absorb" }, { "myHealAbsorb", "healAbsorb" } }
local POWER_SEGMENTS = { { "ManaCostPredictionBar", "cost" } }
-- Faded every frame: the game writes some of their vertex colours (alpha
-- included: ManaCostPredictionBar on a power change, the heal predictions on
-- setup), which would undo a single fade. The over-absorb glows are dropped,
-- as on our unit frames.
local HEALTH_FADED = { "myHealPrediction", "otherHealPrediction", "totalAbsorb", "totalAbsorbOverlay", "myHealAbsorb",
	"myHealAbsorbLeftShadow", "myHealAbsorbRightShadow", "overAbsorbGlow", "overHealAbsorbGlow" }
local POWER_FADED = { "ManaCostPredictionBar" }
local LAYER = { heal = 4, absorb = 5, healAbsorb = 6, cost = 4 }

local looks = setmetatable({}, { __mode = "k" }) -- stock bar -> our textures on it
local driver, started

local function frame()
	local f = rawget(_G, "PersonalResourceDisplayFrame")
	if f and not (f.IsForbidden and f:IsForbidden()) then return f end
end

-- The three bars and what each carries; rawget: parentKeys, never methods.
local function bars(f)
	local hc = rawget(f, "HealthBarsContainer")
	return {
		{ bar = hc and rawget(hc, "healthBar"), kind = "health", segments = HEALTH_SEGMENTS, faded = HEALTH_FADED },
		{ bar = rawget(f, "PowerBar"), kind = "power", segments = POWER_SEGMENTS, faded = POWER_FADED },
		{ bar = rawget(f, "AlternatePowerBar"), kind = "alt", faded = {} },
	}
end

local function tex(bar, layer, sub)
	local t = bar:CreateTexture(nil, layer, nil, sub)
	t:SetTexture(WHITE)
	return t
end

local function look(spec)
	local bar = spec.bar
	local l = looks[bar]
	if l then return l end
	local fill = bar:GetStatusBarTexture()
	if not fill then return end
	l = { track = tex(bar, "BACKGROUND", 1), fill = tex(bar, "ARTWORK", 3), segments = {} }
	l.track:SetAllPoints(bar)
	l.fill:SetAllPoints(fill)
	for _, r in ipairs({ bar:GetRegions() }) do
		if r.GetAtlas and r:GetAtlas() == BG_ATLAS then l.bg = r end
	end
	for _, p in ipairs(spec.segments or {}) do
		local stock, kind = rawget(bar, p[1]), p[2]
		if stock then
			local t = tex(bar, "ARTWORK", LAYER[kind])
			t:SetAllPoints(stock)
			l.segments[#l.segments + 1] = { stock = stock, tex = t, kind = kind }
		end
	end
	l.edges = ns.Hairlines(bar, bar, function() return tex(bar, "ARTWORK", 7) end)
	looks[bar] = l
	return l
end

local function show(l, on)
	l.track:SetShown(on)
	l.fill:SetShown(on)
	for _, s in ipairs(l.segments) do s.tex:SetShown(on) end
	if not on then ns.PaintHairlines(l.edges, false, 0, 0, 0, 0) end
end

-- The game's art and texts faded and in our face, or given back.
local function dress(spec, l, on)
	local bar = spec.bar
	if l.bg then l.bg:SetAlpha(on and 0 or 1) end
	for _, k in ipairs(spec.faded) do
		local t = rawget(bar, k)
		if t then t:SetAlpha(on and 0 or 1) end
	end
	for _, k in ipairs(TEXTS) do H.Face(rawget(bar, k), "number", on) end
	l.fill:SetTexture(H.FillTexture())
	show(l, on)
end

local function mix(r, g, b, token, k)
	local sr, sg, sb = Theme.Color(token)
	return r + (sr - r) * k, g + (sg - g) * k, b + (sb - b) * k
end

-- One shown bar, each frame. Colours come only from H.FillColor and
-- H.PowerColor (both guard against secrets); Edit Mode's Show Class Color is
-- the game's own flag on the frame (a plain boolean, read, never written).
local function paint(f, spec, l)
	local r, g, b
	if spec.kind == "health" then
		r, g, b = H.FillColor("player", rawget(f, "showClassColor") and true or false)
	elseif spec.kind == "power" then
		r, g, b = H.PowerColor("player")
	else
		r, g, b = Theme.Color("npc") -- the alt bar is always mana here (H.PowerColor's MANA)
	end
	l.fill:SetVertexColor(r, g, b, 1)
	local tr, tg, tb = Theme.Color("bg")
	l.track:SetVertexColor(tr, tg, tb, H.GroundAlpha())
	for _, k in ipairs(spec.faded) do
		local t = rawget(spec.bar, k)
		if t then t:SetAlpha(0) end
	end
	for _, s in ipairs(l.segments) do
		-- IsShown is a plain boolean; ns.Clean in case the client ever hands it secret (then hidden).
		s.tex:SetShown(ns.Clean(s.stock:IsShown()) and true or false)
		if s.kind == "heal" then -- the unit frames' heal: the fill lightened
			s.tex:SetVertexColor(r + (1 - r) * 0.45, g + (1 - g) * 0.45, b + (1 - b) * 0.45, 0.7)
		elseif s.kind == "absorb" then
			local ar, ag, ab = Theme.Color("text")
			s.tex:SetVertexColor(ar, ag, ab, 0.55)
		elseif s.kind == "healAbsorb" then -- over the fill's end, darkened
			local sr, sg, sb = Theme.Color("shade")
			s.tex:SetVertexColor(sr, sg, sb, 0.55)
		else -- the cost, past the game's fill (power less cost): the power darkened, as our player frame's
			s.tex:SetVertexColor(mix(r, g, b, "shade", 0.55))
		end
	end
	local br, bg, bb, ba = Theme.Color("border")
	ns.PaintHairlines(l.edges, true, br, bg, bb, ba)
end

local function update()
	local f = frame()
	if not (f and f:IsVisible()) then return end
	for _, spec in ipairs(bars(f)) do
		local l = spec.bar and looks[spec.bar]
		if l and spec.bar:IsVisible() then paint(f, spec, l) end
	end
end

function M.Apply()
	if not started then return end
	local f = frame()
	if not f then return end
	local on = ns.Enabled(KEY)
	for _, spec in ipairs(bars(f)) do
		local l = spec.bar and look(spec)
		if l then dress(spec, l, on) end
	end
	driver:SetShown(on)
	if on then update() end
end

function M.Enable()
	if not frame() then return end
	started = true
	driver = CreateFrame("Frame", nil, UIParent)
	driver:SetScript("OnUpdate", update)
	Theme.OnChanged(function() if ns.Enabled(KEY) then M.Apply() end end, true)
	M.Apply()
end

ns.Module(KEY, M)
