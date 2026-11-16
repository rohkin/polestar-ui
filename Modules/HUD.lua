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
local tracks = setmetatable({}, { __mode = "k" }) -- bar -> its track's alpha on the ground colour

local function fillTexture()
	return Theme.GameSkin() and GAME_FILL or WHITE
end
H.FillTexture = fillTexture

-- A bar on a track (the scheme's ground at H.SetTrack's alpha, else
-- Polestar's progress wash): a StatusBar, so it takes the client's secret
-- health and power. With `trail`, a damage trail (b.trail, H.SetTrail) sits
-- between the track and the fill: a second StatusBar under the bar, so the
-- bar's fill covers it wherever both reach. It is drawn only past the bar's
-- new value (t.psAim, an unseen bar set at once, which holds the track): while
-- the fill eases up on a heal (Smooth bars) no red shows ahead of it.
local function paintTrail(t)
	local r, g, bl = Theme.Color("danger")
	t:SetStatusBarColor(r, g, bl, t.psOn == false and 0 or 1)
end

local TRAIL_OVERLAP = 2 -- UI units: over one physical pixel at any UI scale from 0.5 up

function H.Bar(parent, trail)
	local aim = trail and CreateFrame("StatusBar", nil, parent)
	local b = CreateFrame("StatusBar", nil, parent)
	b:SetMinMaxValues(0, 1)
	b:SetValue(0)
	if aim then
		local clip = CreateFrame("Frame", nil, aim)
		local t = CreateFrame("StatusBar", nil, clip)
		-- Levels set before the bar has children, so they stay above it.
		local level = b:GetFrameLevel()
		aim:SetFrameLevel(level)
		clip:SetFrameLevel(level + 1)
		t:SetFrameLevel(level + 1)
		b:SetFrameLevel(level + 2)
		for _, s in ipairs({ aim, t }) do
			s:SetAllPoints(b)
			s:SetMinMaxValues(0, 1)
			s:SetValue(0)
		end
		aim:SetStatusBarTexture(WHITE)
		aim:SetStatusBarColor(1, 1, 1, 0)
		-- The clip reaches TRAIL_OVERLAP under the fill's end: a clip edge and a
		-- texture edge on one coordinate snap to different pixels at a fractional
		-- UI scale, leaving a pixel of dark track between fill and trail.
		clip:SetPoint("TOPLEFT", aim:GetStatusBarTexture(), "TOPRIGHT", -TRAIL_OVERLAP, 0)
		clip:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
		clip:SetClipsChildren(true)
		t.psAim = aim
		b.trail = t
	end
	b.Track = (aim or b):CreateTexture(nil, "BACKGROUND")
	b.Track:SetTexture(WHITE)
	b.Track:SetAllPoints(b)
	W.Painter(b, function(bar)
		bar:SetStatusBarTexture(fillTexture())
		if bar.trail then
			bar.trail:SetStatusBarTexture(fillTexture())
			paintTrail(bar.trail)
		end
		if tracks[bar] then
			local r, g, b = Theme.Color("bg")
			bar.Track:SetVertexColor(r, g, b, tracks[bar])
		else
			bar.Track:SetVertexColor(Theme.Wash("progress"))
		end
		local c = barColors[bar]
		if c then bar:SetStatusBarColor(c[1], c[2], c[3]) end
	end)
	return b
end

-- The track in the ground colour at alpha `a`: the missing part reads dark.
function H.SetTrack(b, a)
	tracks[b] = a
	local r, g, bl = Theme.Color("bg")
	b.Track:SetVertexColor(r, g, bl, a)
end

function H.SetBarColor(b, r, g, b2)
	barColors[b] = { r, g, b2 }
	b:SetStatusBarColor(r, g, b2)
end

-- A segment that continues bar `b`'s fill (incoming heals, absorbs), or with
-- `back` eats into it from its end leftwards (heal absorbs): a bar of the
-- same size hung off the fill's right edge, given the same maximum, so the
-- client does the sums (no maths on secret values here). The caller sizes it
-- to the bar's width from its own clean layout numbers: a segment's geometry
-- hangs off a fill whose edge is secret in combat (CLIENT.md, rule 3).
-- Without `token` the caller colours it (SetStatusBarColor after each paint).
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
		if not token then return end
		local r, g, bl = Theme.Color(token)
		seg:SetStatusBarColor(r, g, bl, alpha or 0.5)
	end)
	return s
end

-- A bar's value; with `smooth` the client eases the fill to it
-- (StatusBarInterpolation, which takes secrets), and whatever hangs off the
-- fill (segments, the sparkle's mask) rides along.
-- Under Reduce motion (ui.reduceMotion, read per call) it snaps, the trail too.
function H.SetValue(b, v, smooth)
	local ease = Enum and Enum.StatusBarInterpolation
	if not ease then return b:SetValue(v) end
	b:SetValue(v, smooth and not Theme.ReduceMotion() and ease.ExponentialEaseOut or ease.Immediate)
end

-- The damage trail: the bar's new value, given to b.trail after a hold and
-- then eased (H.SetValue). On a loss the fill drops and the trail, still at
-- the old value, shows the lost health in `danger` until it drains; on a gain
-- the trail's end is below the new value, where it is clipped (t.psAim takes
-- the value at once), so it catches up unseen even while the fill eases. So no
-- value is compared (secret in combat, CLIENT.md rule 3): a secret is only kept
-- and handed to SetValue later. `snap` (another unit) sets it at once; `on`
-- false keeps it clear. `max`: the bar's maximum, given to both at once.
local TRAIL_HOLD = 0.4

function H.SetTrail(b, v, snap, on, max)
	local t = b.trail
	t:SetMinMaxValues(0, max)
	t.psAim:SetMinMaxValues(0, max)
	H.SetValue(t.psAim, v)
	t.psValue = v
	if t.psOn ~= on then t.psOn = on; paintTrail(t) end
	if snap or Theme.ReduceMotion() or not (C_Timer and C_Timer.After) then return H.SetValue(t, v) end
	if t.psWait then return end -- the timer due takes the latest value
	t.psWait = true
	C_Timer.After(TRAIL_HOLD, function()
		t.psWait = nil
		H.SetValue(t, t.psValue, true)
	end)
end

-- The sparkle: the constellation of Polestar's night-sky stars
-- (Theme.Media("band-stars")) at the bar's right end, in the `star` token (its
-- alpha too: a skin without stars on its band has none here). The segment is
-- the band's x 655-945, y 12-76: the connected chain (x 667-935, y 17-72) with
-- a small margin, no scattered stars beyond. It fills the bar's full height,
-- unstretched (width follows), cropped from its left if the bar is narrower,
-- its left quarter fading to clear so no hard edge shows. Skipped on a bar
-- under 24 high. The caller sizes it with H.SizeSparkle from clean layout
-- numbers.
local SPARK = { x0 = 655, x1 = 945, y0 = 12, y1 = 76, minH = 24, fade = 0.25 }

function H.Sparkle(b)
	local function tex()
		local t = b:CreateTexture(nil, "ARTWORK", nil, 7)
		t:SetTexture(Theme.Media("band-stars"))
		return t
	end
	local s, f = tex(), tex() -- the solid right part, and the fading left part
	s:SetPoint("TOPRIGHT", b, "TOPRIGHT")
	s:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT")
	f:SetPoint("TOPRIGHT", s, "TOPLEFT")
	f:SetPoint("BOTTOMRIGHT", s, "BOTTOMLEFT")
	s.fade = f
	b.Sparkle, b.psSpark = s, s
	return s
end

function H.SizeSparkle(b, w, h)
	local s = b.Sparkle
	local f = s.fade
	s.skip = h < SPARK.minH or w <= 0
	if s.skip then return end
	local k = h / (SPARK.y1 - SPARK.y0) -- screen px per band px
	local x0 = math.max(SPARK.x0, SPARK.x1 - w / k) -- cropped on the left when the bar is narrow
	local split = x0 + (SPARK.x1 - x0) * SPARK.fade
	local v0, v1 = SPARK.y0 / Theme.BAND_H, SPARK.y1 / Theme.BAND_H
	s:SetWidth((SPARK.x1 - split) * k)
	s:SetTexCoord(split / Theme.BAND_W, SPARK.x1 / Theme.BAND_W, v0, v1)
	f:SetWidth((split - x0) * k)
	f:SetTexCoord(x0 / Theme.BAND_W, split / Theme.BAND_W, v0, v1)
end

function H.PaintSparkle(b, on)
	local s = b.Sparkle
	local r, g, bl, a = Theme.Color("star")
	s:SetVertexColor(r, g, bl, a)
	s.fade:SetGradient("HORIZONTAL", CreateColor(r, g, bl, 0), CreateColor(r, g, bl, a or 1))
	on = on and not s.skip
	s:SetShown(on)
	s.fade:SetShown(on)
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
	-- The glow: four strips just outside the frame, fading to clear outward.
	-- Textures, so neither the frame's rect (Edit Mode) nor its size changes.
	-- Each corner is a quarter disc of GLOW rows, one texture per row, fading
	-- to clear along the row, so the glow wraps round without overlapping.
	g.glow = {}
	-- dir, and whether the strong end is the gradient's max (top/right) end.
	for i, p in ipairs({ { "VERTICAL", false }, { "VERTICAL", true }, { "HORIZONTAL", true }, { "HORIZONTAL", false } }) do
		local t = f:CreateTexture(nil, "BACKGROUND", nil, -8)
		t:SetTexture(WHITE)
		t.dir, t.towardMax = p[1], p[2]
		g.glow[i] = t
	end
	-- top, bottom, left, right: each hangs off the matching edge of f.
	local T, B, L, R = g.glow[1], g.glow[2], g.glow[3], g.glow[4]
	T:SetPoint("BOTTOMLEFT", f, "TOPLEFT"); T:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT"); T:SetHeight(H.GLOW)
	B:SetPoint("TOPLEFT", f, "BOTTOMLEFT"); B:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT"); B:SetHeight(H.GLOW)
	L:SetPoint("TOPRIGHT", f, "TOPLEFT"); L:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT"); L:SetWidth(H.GLOW)
	R:SetPoint("TOPLEFT", f, "TOPRIGHT"); R:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT"); R:SetWidth(H.GLOW)
	-- point on the row, point on f, row step (+1 up), strong end is the max end.
	for _, c in ipairs({ { "BOTTOMRIGHT", "TOPLEFT", 1, true }, { "BOTTOMLEFT", "TOPRIGHT", 1, false },
		{ "TOPRIGHT", "BOTTOMLEFT", -1, true }, { "TOPLEFT", "BOTTOMRIGHT", -1, false } }) do
		for j = 0, H.GLOW - 1 do
			local d = j + 0.5 -- the row's distance from the frame
			local t = f:CreateTexture(nil, "BACKGROUND", nil, -8)
			t:SetTexture(WHITE)
			t.dir, t.towardMax, t.k = "HORIZONTAL", c[4], 1 - d / H.GLOW
			t:SetSize(math.sqrt(H.GLOW * H.GLOW - d * d), 1)
			t:SetPoint(c[1], f, c[2], 0, c[3] * j)
			g.glow[#g.glow + 1] = t
		end
	end
	return g
end

H.GLOW = 8 -- px a tinted edge's glow reaches outward
H.GLOW_PEAK = 0.7 -- the glow's alpha at the frame, times the edge's alpha (sides and corners alike)
H.THREAT_ALPHA = 0.65 -- the threat edge's alpha: hairline, and the glow peak scaled by it (0.455)

-- `flat`: a tint without the glow (the player's own combat edge).
function H.PaintGround(g, alpha, r, gr, b, a, flat)
	local br, bg, bb = Theme.Color("bg")
	g.fill:SetVertexColor(br, bg, bb, alpha)
	g.fill:SetShown(alpha > 0)
	local tinted = r ~= nil and not flat
	if not r then r, gr, b, a = Theme.Color("border") end
	ns.PaintHairlines(g.edges, true, r, gr, b, a)
	-- Strongest at the frame, clear at the far edge.
	local clear = CreateColor(r, gr, b, 0)
	for _, t in ipairs(g.glow) do
		t:SetShown(tinted)
		if tinted then
			local strong = CreateColor(r, gr, b, H.GLOW_PEAK * (a or 1) * (t.k or 1))
			if t.towardMax then t:SetGradient(t.dir, clear, strong) else t:SetGradient(t.dir, strong, clear) end
		end
	end
end

-- A square portrait well: the unit's 3D model (a PlayerModel framed as the
-- game frames portraits), or the game's 2D portrait while the unit is out of
-- sight (a model needs it in view). `bare`: no hairline of its own (the
-- frame's edge frames it). -> well; H.SetPortrait(p, unit).
function H.Portrait(parent, bare)
	local p = CreateFrame("Frame", nil, parent)
	Theme.Skin(p, "inset")
	if not bare then
		p.Edges = ns.Hairlines(p, p)
		W.Painter(p, function(well) ns.PaintHairlines(well.Edges, true, Theme.Color("border")) end)
	end
	p.Model = CreateFrame("PlayerModel", nil, p)
	p.Model:SetPoint("TOPLEFT", p, "TOPLEFT", 1, -1)
	p.Model:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -1, 1)
	p.Model:SetScript("OnModelLoaded", H.Framed)
	p.Flat = p:CreateTexture(nil, "ARTWORK")
	p.Flat:SetAllPoints(p.Model)
	p.Flat:SetTexCoord(0.15, 0.85, 0.15, 0.85) -- the round portrait's square middle
	return p
end

-- A model is drawn only once framed: the portrait camera set before the unit
-- and again as its model loads (OnModelLoaded), unseen (alpha 0) till then,
-- so the unframed model (rising from below the well) never shows. A model
-- the client already had may not fire OnModelLoaded: framed a moment later.
function H.Framed(m)
	m:SetPortraitZoom(1)
	m:SetCamDistanceScale(1)
	m:SetAlpha(1)
end

-- Call only when the unit changed (a new GUID, the unit's model or portrait
-- updated): each call loads the model again.
function H.SetPortrait(p, unit)
	local seen = ns.Clean(UnitIsVisible(unit))
	if seen then
		local m = p.Model
		p.Flat:Hide()
		m:SetAlpha(0)
		m:Show()
		m:SetPortraitZoom(1)
		m:SetCamDistanceScale(1)
		m:SetUnit(unit)
		local n = (m.psLoads or 0) + 1
		m.psLoads = n
		C_Timer.After(0.25, function() if m.psLoads == n and m:GetAlpha() == 0 then H.Framed(m) end end)
	else
		p.Model:Hide()
		p.Model:ClearModel()
		SetPortraitTexture(p.Flat, unit)
		p.Flat:Show()
	end
end

-- The HUD's ground alpha: the unit frames' "Background opacity" (/pui
-- unitframes), one setting for every HUD piece (the cast bars' track).
function H.GroundAlpha()
	local o = PolestarUIDB and PolestarUIDB.unitframes
	return o and o.ground or 0.6
end

-- A stock font string in Polestar's face for `role`, outlined, at the game's
-- size (docs/CLIENT.md, rule 15: a widget call, no key written; what it was
-- is kept here), or with `on` false the game's again. Safe to call again and
-- again: when the game has set the font since (SetFontObject), that one is
-- kept as the game's and ours set over it. The text is never read.
local faces = setmetatable({}, { __mode = "k" }) -- font string -> { the game's path, size, flags; path, flags = ours as set }
function H.Face(fs, role, on)
	if not fs then return end
	local cur, size, flags = fs:GetFont()
	if not cur then return end
	flags = flags or ""
	local s = faces[fs]
	local ours = s and cur == s.path and flags == s.flags
	if not on then
		if ours then Theme.SetFace(fs, s[1], s[2], s[3]) end
		faces[fs] = nil
		return
	end
	if not ours then
		s = { cur, size, flags }
		faces[fs] = s
	end
	Theme.SetFace(fs, (Theme.FontSpec(role)), s[2], "OUTLINE")
	local path, _, set = fs:GetFont()
	s.path, s.flags = path, set or ""
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

-- The default fill (health, a cast): the header band's blue (`sky`, under its
-- stars), or the unit's class colour while Polestar's "Class colour" is on,
-- or always with `classed` (the party frames). While the client keeps the
-- class secret, the default.
function H.FillColor(unit, classed)
	if classed or Theme.FollowsClassAccent() then
		local r, g, b = H.ClassColor(unit)
		if r then return r, g, b end
	end
	return Theme.Color("sky")
end

-- The colour of a unit's health, from the player's theme (docs/windows/
-- unitframes.md, "Colours"): grey when it is gone, offline or tapped by
-- another; an enemy in danger, a neutral creature in warning; anyone else in
-- the header band's sky, or in their class colour while the theme's accent follows the
-- class (Polestar's "Class colour", ui.classAccent).
function H.UnitColor(unit, classed)
	if ns.Clean(UnitIsDeadOrGhost(unit)) or ns.Clean(UnitIsConnected(unit)) == false or ns.Clean(UnitIsTapDenied(unit)) then
		return Theme.Color("textMuted")
	end
	local reaction = ns.Clean(UnitReaction(unit, "player"))
	if reaction and reaction <= 3 then return Theme.Color("danger") end
	if reaction == 4 and not ns.Clean(UnitIsPlayer(unit)) then return Theme.Color("warning") end
	return H.FillColor(unit, classed)
end

-- A unit's power colour, from the player's theme: each power type wears a
-- Polestar token near the game's hue (mana the soft blue of `npc`, clear of
-- the health's sky; rage `danger`; energy `warning`; focus the warm `place`;
-- runic power the ice of `spell`), so the strip follows every scheme. A type
-- with no token, or a token the scheme lacks, wears the game's own colour
-- (PowerBarColor) calmed halfway to textMuted.
local POWER = { MANA = "npc", RAGE = "danger", ENERGY = "warning", FOCUS = "place", RUNIC_POWER = "spell", MAELSTROM = "spell",
	INSANITY = "dungeon", FURY = "dungeon", LUNAR_POWER = "item", PAIN = "achievement" }
function H.PowerColor(unit)
	local kind, token = UnitPowerType(unit)
	kind, token = ns.Clean(kind), ns.Clean(token)
	local game = PowerBarColor and ((token and PowerBarColor[token]) or (kind and PowerBarColor[kind]))
	local name = (token and POWER[token]) or (not game and "npc")
	if name and Theme.Palette()[name] then return Theme.Color(name) end
	if not game then return Theme.Color("textMuted") end
	local r, g, b = Theme.Color("textMuted")
	return (game.r + r) / 2, (game.g + g) / 2, (game.b + b) / 2
end
