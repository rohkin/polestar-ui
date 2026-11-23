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
-- Its mirror, the gain (t.psGain, over the fill): health just gained, in
-- `success`, from the trail's end to the fill's end; on a loss the trail ends
-- past the fill, so nothing shows. It shrinks as the trail catches up.
local function paintTrail(t)
	local r, g, bl = Theme.Color("danger")
	t:SetStatusBarColor(r, g, bl, t.psOn == false and 0 or 1)
	r, g, bl = Theme.Color("success")
	t.psGain:SetVertexColor(r, g, bl, t.psOn == false and 0 or 1)
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
		-- The gain: a clip from the trail's end to the bar's right, holding a
		-- texture from the bar's left to the fill's end (no value of its own).
		t:SetStatusBarTexture(fillTexture()) -- the fills exist before they are anchored to
		b:SetStatusBarTexture(fillTexture())
		local gclip = CreateFrame("Frame", nil, b)
		gclip:SetPoint("TOPLEFT", t:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
		gclip:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)
		gclip:SetClipsChildren(true)
		local gain = CreateFrame("Frame", nil, gclip)
		gain:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
		gain:SetPoint("BOTTOMRIGHT", b:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
		t.psGain = gain:CreateTexture(nil, "ARTWORK")
		t.psGain:SetTexture(WHITE)
		t.psGain:SetAllPoints(gain)
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
function H.Ground(f, out)
	local g = { fill = f:CreateTexture(nil, "BACKGROUND", nil, -8) }
	g.fill:SetTexture(WHITE)
	g.fill:SetAllPoints(f)
	g.edges = ns.Hairlines(f, f)
	g.shadow = H.Shadow(f, f, out)
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

-- The HUD's look, per group (`look`: H.FRAMES, H.PLATES, H.ICONS, or nil for
-- frames): Polestar's Frames settings, the window's own (border, its size,
-- colour or accent; shadow and its strength; Background opacity), a small
-- piece's border `cap` px at most. A group whose "Override Polestar's look" is
-- on (PolestarUIDB.hudLook[group].override, Settings.lua) takes its own values
-- instead, the cap aside (the player sets the size).
H.FRAMES = { group = "frames" }
H.FRAME_ICONS = { group = "frames", cap = 2 } -- an icon on a frame (the damage meter's rows)
H.PLATES = { group = "plates", cap = 2 }
H.ICONS = { group = "icons", cap = 2 }
H.GROUPS = { "frames", "plates", "icons" }
H.COLORS = { white = { 1, 1, 1 }, black = { 0, 0, 0 }, gold = { 1, 0.82, 0 }, silver = { 0.75, 0.75, 0.78 } }

-- The group's own look while it overrides Polestar's, else nil.
function H.Own(look)
	local d = PolestarUIDB and PolestarUIDB.hudLook
	local o = d and d[look and look.group or "frames"]
	return o and o.override and o or nil
end

-- What Polestar's window border would be with no colour of the player's:
-- the skin's windowBorder, else the look's edge, else its hairline.
local function schemeEdge()
	local r, g, b, a = Theme.SkinToken("windowBorder")
	if r then return r, g, b, a end
	local p = Theme.Palette()
	local c = p.windowEdge or p.border
	return c[1], c[2], c[3], c[4] or 1
end

-- A group's own look as Polestar's settings stand now (an override's start):
-- the small pieces' size at their cap, so turning it on changes nothing.
function H.Seed(group)
	local shown, n = Theme.WindowBorder()
	local own = Polestar.Get("ui.borderColor")
	local cap = group ~= "frames" and 2 or 4
	return { override = true, border = shown, borderSize = math.max(1, math.min(n, cap)),
		borderColor = type(own) == "table" and "own" or nil, ownColor = type(own) == "table" and { own[1], own[2], own[3] } or nil,
		borderAccent = Polestar.Get("ui.borderAccent") and true or false, hairline = 1,
		shadow = Polestar.Get("ui.shadow") ~= false, shadowStrength = tonumber(Polestar.Get("ui.shadowStrength")) or 1,
		ground = Theme.GroundAlpha() }
end

-- -> shown, r, g, b, a, n (n at least 1: a tint's thickness while it is off)
function H.Edge(look)
	local o = H.Own(look)
	if o then
		local r, g, b, a
		local c = o.borderColor == "own" and o.ownColor or H.COLORS[o.borderColor or ""]
		if o.borderColor == "class" then r, g, b = H.ClassColor("player"); a = 1 end
		if r then -- the class colour
		elseif c then r, g, b, a = c[1], c[2], c[3], 1
		elseif o.borderAccent then r, g, b = Theme.Accent(); a = 0.8
		else r, g, b, a = schemeEdge() end
		a = math.min(1, (a or 1) * (o.hairline or 1))
		local n = math.max(1, math.min(4, math.floor((o.borderSize or 1) + 0.5)))
		return o.border ~= false, r, g, b, a, n
	end
	local shown, n = Theme.WindowBorder()
	local r, g, b, a = Theme.Color("windowBorder")
	local cap = look and look.cap
	return shown, r, g, b, a, math.max(1, math.min(n, cap or n))
end

-- Hairlines `e` (ns.Hairlines) as the HUD's edge, while `on` and the border is.
function H.PaintEdge(e, on, look)
	local shown, r, g, b, a, n = H.Edge(look)
	ns.PaintHairlines(e, on and shown, r, g, b, a, n)
end

-- Hairlines `e` in a tint (r, g, b, a: shown with the border off too, at its
-- thickness), else as the HUD's edge (H.PaintEdge).
function H.PaintTint(e, on, look, r, g, b, a)
	if not r then return H.PaintEdge(e, on, look) end
	ns.PaintHairlines(e, on, r, g, b, a, select(6, H.Edge(look)))
end

-- The window shadow's colour while it is drawn (ui.shadow, the shadow token's
-- alpha with ui.shadowStrength in it; an override: its own switch and
-- strength on the token), else nil. -> r, g, b, a
function H.ShadowColor(look)
	local r, g, b, a = Theme.Color("shadow")
	local o = H.Own(look)
	if o then
		if o.shadow == false or not a then return nil end
		local s = tonumber(Polestar.Get("ui.shadowStrength")) or 1
		a = math.min(1, (s > 0 and a / s or a) * (o.shadowStrength or 1))
		if a <= 0 then return nil end
		return r, g, b, a
	end
	if Polestar.Get("ui.shadow") == false or not a or a <= 0 then return nil end
	return r, g, b, math.min(1, a)
end

-- Polestar's window shadow round region `rel` (default f), as Theme.lua's
-- shadowFor lays it (its softBox): Media/UI/shadow on a box `out` units
-- round rel, dropped out / 4, each corner reaching out * 6 / 16 into rel (the
-- window's 16, 4 and 6, scaled). Polestar's slices run on inside the shape
-- (half strength at its edge), where an opaque window covers them; a HUD
-- ground is translucent, so that part showed through it as a darker frame
-- inside the frame. Ours are cut at rel's edge: the box as a 5 x 5 grid (the
-- box's edge, rel's edge, the corner's end, on each side), the nine cells
-- over rel left out. Textures on `f` only: no rect Edit Mode sees.
local SLICE = 20 / 64
function H.Shadow(f, rel, out)
	rel, out = rel or f, out or 16
	local drop, inner, parts = out / 4, out * 6 / 16, {}
	local k = SLICE / (out + inner) -- texture coordinate per unit in a corner
	-- Grid lines: { rel's side, offset, texture coordinate }, left to right and top to bottom.
	local xs = { { "LEFT", -out, 0 }, { "LEFT", 0, out * k }, { "LEFT", inner, SLICE },
		{ "RIGHT", -inner, 1 - SLICE }, { "RIGHT", 0, 1 - out * k }, { "RIGHT", out, 1 } }
	local ys = { { "TOP", out - drop, 0 }, { "TOP", 0, (out - drop) * k }, { "TOP", -inner - drop, SLICE },
		{ "BOTTOM", inner - drop, 1 - SLICE }, { "BOTTOM", 0, 1 - (out + drop) * k }, { "BOTTOM", -out - drop, 1 } }
	for j = 1, 5 do
		for i = 1, 5 do
			if i == 1 or i == 5 or j == 1 or j == 5 then
				local x0, x1, y0, y1 = xs[i], xs[i + 1], ys[j], ys[j + 1]
				local t = f:CreateTexture(nil, "BACKGROUND", nil, -8)
				t:SetTexture(Theme.Media("shadow"))
				t:SetTexCoord(x0[3], x1[3], y0[3], y1[3])
				t:SetPoint("TOPLEFT", rel, y0[1] .. x0[1], x0[2], y0[2])
				t:SetPoint("BOTTOMRIGHT", rel, y1[1] .. x1[1], x1[2], y1[2])
				parts[#parts + 1] = t
			end
		end
	end
	return parts
end

-- Shows shadow `s` (H.Shadow) while `on` and Polestar draws window shadows,
-- at the window painter's alpha: the shadow's, times the ground's `ground`
-- (default the group's) plus 0.1.
function H.PaintShadow(s, on, ground, look)
	local r, g, b, a = H.ShadowColor(look)
	if r then a = a * math.min(1, (ground or H.GroundAlpha(look)) + 0.1) end
	for _, t in ipairs(s) do
		t:SetShown(on and r ~= nil)
		if r then t:SetVertexColor(r, g, b, a) end
	end
end

-- `flat`: a tint without the glow (the player's own combat edge). A tint
-- shows with the border off; `g.look`: its group and cap (H.Edge).
-- Untinted, Polestar's window shadow round it (a tint, flat too, has none).
function H.PaintGround(g, alpha, r, gr, b, a, flat)
	local br, bg, bb = Theme.Color("bg")
	g.fill:SetVertexColor(br, bg, bb, alpha)
	g.fill:SetShown(alpha > 0)
	local tinted = r ~= nil and not flat
	local shown, er, eg, eb, ea, n = H.Edge(g.look)
	H.PaintShadow(g.shadow, r == nil, alpha, g.look)
	if r then shown = true else r, gr, b, a = er, eg, eb, ea end
	ns.PaintHairlines(g.edges, shown, r, gr, b, a, n)
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
		W.Painter(p, function(well) H.PaintEdge(well.Edges, true) end)
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

-- A group's ground alpha: Polestar's Background opacity (ui.bgOpacity), or
-- its override's own.
function H.GroundAlpha(look)
	local o = H.Own(look)
	return o and tonumber(o.ground) or Theme.GroundAlpha()
end

-- Once: a save from before the groups (one HUD-wide opacity of our own,
-- PolestarUIDB.hudOwnGround over unitframes.ground) becomes an override of
-- every group at Polestar's look and that opacity, so nothing changes.
ns.AfterLogin(function()
	local db = PolestarUIDB
	if not db.hudOwnGround then return end
	db.hudLook = db.hudLook or {}
	local ground = db.unitframes and tonumber(db.unitframes.ground) or 0.6
	for _, group in ipairs(H.GROUPS) do
		local o = H.Seed(group)
		o.ground = ground
		db.hudLook[group] = o
	end
	db.hudOwnGround = nil
end)

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
