-- The HUD kit (docs/windows/unitframes.md, "HUD kit"): the pieces the unit
-- frames are built from, which Polestar's own kit has no use for. Each one is
-- painted only through Polestar's public theme API (Theme.Color, Theme.Wash,
-- Theme.FontSpec, Theme.GameSkin, W.Painter), so it follows every scheme and
-- skin and repaints on Theme.OnChanged like Polestar's own widgets.
--
-- Everything here takes the client's secret values (docs/CLIENT.md, rule 3):
-- a bar is a real StatusBar (SetMinMaxValues, SetValue and SetStatusBarColor
-- take secrets from addon code), text is set only with SetFormattedText
-- (takes secrets) and never read back, and no value is compared or counted.
-- Polestar's W.Text cannot be used for that text: its font hook reads the
-- string's text (CLIENT.md, rule 3), so HUD text gets its face from
-- Theme.SetFace, which reads nothing.

local ADDON, ns = ...
local Theme, W = Polestar.Theme, Polestar.Widgets

local H = {}
ns.HUD = H

local WHITE = Theme.Media("white")
-- The game skins (Hearth, WoW Forever, Blizzard, Classic) wear the game's own
-- bar fill; the house skins a flat one.
local GAME_FILL = "Interface\\TargetingFrame\\UI-StatusBar"

local barColors = setmetatable({}, { __mode = "k" }) -- bar -> { r, g, b }, put back after a skin swaps its texture

local function fillTexture()
	return Theme.GameSkin() and GAME_FILL or WHITE
end

-- A bar on a faint track (Polestar's progress wash): a StatusBar, so it takes
-- the client's secret health and power.
function H.Bar(parent)
	local b = CreateFrame("StatusBar", nil, parent)
	b:SetMinMaxValues(0, 1)
	b:SetValue(0)
	b.Track = b:CreateTexture(nil, "BACKGROUND")
	b.Track:SetTexture(WHITE)
	b.Track:SetAllPoints(b)
	W.Painter(b, function(bar)
		bar:SetStatusBarTexture(fillTexture())
		bar.Track:SetVertexColor(Theme.Wash("progress"))
		local c = barColors[bar]
		if c then bar:SetStatusBarColor(c[1], c[2], c[3]) end
	end)
	return b
end

function H.SetBarColor(b, r, g, b2)
	barColors[b] = { r, g, b2 }
	b:SetStatusBarColor(r, g, b2)
end

-- A segment that continues bar `b`'s fill (incoming heals, absorbs), or with
-- `back` eats into it from its end leftwards (heal absorbs): a bar of the
-- same size hung off the fill's right edge, given the same maximum, so the
-- client does the sums (no maths on secret values here).
function H.Segment(b, token, alpha, back)
	local s = CreateFrame("StatusBar", nil, b)
	local side = back and "RIGHT" or "LEFT"
	s:SetPoint("TOP" .. side, b:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	s:SetPoint("BOTTOM" .. side, b:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
	if back then s:SetReverseFill(true) end
	s:SetMinMaxValues(0, 1)
	s:SetValue(0)
	W.Painter(s, function(seg)
		seg:SetStatusBarTexture(WHITE)
		local r, g, bl = Theme.Color(token)
		seg:SetStatusBarColor(r, g, bl, alpha or 0.5)
	end)
	b:HookScript("OnSizeChanged", function(bar, w) s:SetWidth(w) end)
	return s
end

-- HUD text: outlined, with a hard shadow, legible over any terrain (the
-- transparent guide window's rule, docs/DESIGN.md "HUD"). Take values with
-- SetFormattedText only.
function H.Text(parent, role, color, layer)
	local fs = parent:CreateFontString(nil, layer or "OVERLAY")
	W.Painter(fs, function(s)
		local path, size = Theme.FontSpec(role or "body")
		Theme.SetFace(s, path, size, "OUTLINE")
		s:SetShadowOffset(1, -1)
		s:SetShadowColor(0, 0, 0, 1)
	end)
	W.Color(fs, color or "text")
	fs:SetJustifyH("LEFT")
	fs:SetJustifyV("MIDDLE")
	fs:SetWordWrap(false)
	return fs
end

-- The HUD ground: the scheme's ground at `alpha` (the player's choice), edged
-- by a hairline in the border token unless the caller tints it (threat,
-- combat). -> ground; H.PaintGround(g, alpha, r, g, b, a) repaints it.
function H.Ground(f)
	local g = { fill = f:CreateTexture(nil, "BACKGROUND", nil, -8) }
	g.fill:SetTexture(WHITE)
	g.fill:SetAllPoints(f)
	g.edges = ns.Hairlines(f, f)
	return g
end

function H.PaintGround(g, alpha, r, gr, b, a)
	local br, bg, bb = Theme.Color("bg")
	g.fill:SetVertexColor(br, bg, bb, alpha)
	g.fill:SetShown(alpha > 0)
	if not r then r, gr, b, a = Theme.Color("border") end
	ns.PaintHairlines(g.edges, true, r, gr, b, a)
end

-- A square portrait well: the unit's 3D model (a PlayerModel framed as the
-- game frames portraits), or the game's 2D portrait while the unit is out of
-- sight (a model needs it in view). -> well; H.SetPortrait(p, unit).
function H.Portrait(parent)
	local p = CreateFrame("Frame", nil, parent)
	Theme.Skin(p, "inset")
	p.Edges = ns.Hairlines(p, p)
	W.Painter(p, function(well) ns.PaintHairlines(well.Edges, true, Theme.Color("border")) end)
	p.Model = CreateFrame("PlayerModel", nil, p)
	p.Model:SetPoint("TOPLEFT", p, "TOPLEFT", 1, -1)
	p.Model:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -1, 1)
	p.Flat = p:CreateTexture(nil, "ARTWORK")
	p.Flat:SetAllPoints(p.Model)
	p.Flat:SetTexCoord(0.15, 0.85, 0.15, 0.85) -- the round portrait's square middle
	return p
end

function H.SetPortrait(p, unit)
	local seen = ns.Clean(UnitIsVisible(unit))
	if seen then
		p.Flat:Hide()
		p.Model:Show()
		p.Model:SetUnit(unit)
		p.Model:SetPortraitZoom(1)
		p.Model:SetCamDistanceScale(1)
	else
		p.Model:Hide()
		p.Model:ClearModel()
		SetPortraitTexture(p.Flat, unit)
		p.Flat:Show()
	end
end

-- A unit's class colour, nil for a non-player or while the client keeps its
-- class secret (UnitClass is secret when the unit's identity is restricted;
-- indexing a colour table with a secret errors). Polestar's Theme.ClassColor
-- does not guard that (docs/windows/unitframes.md, "Polestar asks").
function H.ClassColor(unit)
	if not ns.Clean(UnitIsPlayer(unit)) then return nil end
	local _, file = UnitClass(unit)
	if not ns.Clean(file) then return nil end
	return Theme.ClassColor(file)
end

-- The colour of a unit's health, from the player's theme (docs/windows/
-- unitframes.md, "Colours"): grey when it is gone, offline or tapped by
-- another; an enemy in danger, a neutral creature in warning; anyone else in
-- the accent, or in their class colour while the theme's accent follows the
-- class (Polestar's "Class colour", ui.classAccent).
function H.UnitColor(unit)
	if ns.Clean(UnitIsDeadOrGhost(unit)) or ns.Clean(UnitIsConnected(unit)) == false or ns.Clean(UnitIsTapDenied(unit)) then
		return Theme.Color("textMuted")
	end
	local reaction = ns.Clean(UnitReaction(unit, "player"))
	if reaction and reaction <= 3 then return Theme.Color("danger") end
	if reaction == 4 and not ns.Clean(UnitIsPlayer(unit)) then return Theme.Color("warning") end
	if Theme.FollowsClassAccent() then
		local r, g, b = H.ClassColor(unit)
		if r then return r, g, b end
	end
	return Theme.Accent()
end

-- A unit's power colour: the game's (PowerBarColor; power keeps the game's
-- meaning, as item quality does), by its power type.
function H.PowerColor(unit)
	local kind, token = UnitPowerType(unit)
	local c = (ns.Clean(token) and PowerBarColor[token]) or (ns.Clean(kind) and PowerBarColor[kind]) or PowerBarColor.MANA
	return c.r, c.g, c.b
end
