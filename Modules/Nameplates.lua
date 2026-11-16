-- Nameplates (docs/windows/nameplates.md): the game's own enemy and friendly
-- nameplates in the unit frames' look, restyled in place, never rebuilt. The
-- plate frames are pooled and the game's code writes into them
-- (docs/CLIENT.md, rules 15 and 20): every option (style, size, health text,
-- threat, auras, casts, who gets a plate) stays the game's, and no plate
-- frame is moved, sized, shown, hidden or hooked. On each pooled UnitFrame,
-- once, a frame of our own under the game's health bar, placed by anchors on
-- the game's containers and sized by us: the unit frames' ground (H.Ground:
-- track, hairline, glow), a health bar of ours (H.Bar: the secret health goes
-- in unread) as wide as the plate's content and a little taller than the
-- game's, in the target frame's colour (H.UnitColor), with the unit frames'
-- heal and absorb segments; the level and name in the row above it (inside
-- it in the styles without that row), the health text inside at the right;
-- the focus has a warning hairline, threat
-- (the game's option) the threat glow, and while there is a target the other
-- plates are dimmed. The game's bar art, fill, texts, level badge and name
-- (while ours shows) are faded with SetAlpha, region by region. The cast bar
-- wears the cast bars' look (ns.CastLook) over the game's cast area, the aura
-- icons square with a hairline and a smaller timer, the plate texts
-- Polestar's face on the roman member of the game's font families (other
-- alphabets keep the client's faces). Forbidden plates (friendly plates in
-- instances) are never touched. No CVar is written.

local ADDON, ns = ...
local Theme = Polestar.Theme
local H = ns.HUD

local M = { noun = "nameplates" }
local KEY = "nameplates"
local CROP = 0.08 -- the icon's baked border, cropped as ns.GameIcon does
local OVERLAY = "UI-HUD-CoolDownManager-IconOverlay" -- the aura item's unnamed rounded ring
-- The plates' font families and the Polestar role each takes (the game's size and outline kept).
local FONTS = { SystemFont_NamePlate = "number", SystemFont_NamePlate_Outlined = "label", SystemFont_NamePlateLevel = "number",
	SystemFont_NamePlateCastBar = "label" }
-- Plate addons that draw over these frames: ours is off by default beside them.
local OTHERS = { "Plater", "Platynator", "Kui_Nameplates", "TidyPlates_ThreatPlates", "EllesmereUINameplates" }
-- The cast bar's height by nameplateStyle (GetCastBarHeight: Block and Cast
-- Focus large, the others small) and nameplateSize (NAME_PLATE_SCALES' vertical).
local LARGE_CAST = { [2] = true, [4] = true }
local VERTICAL = { 0.8, 1, 1.25, 1.4, 1.6 }
local HORIZONTAL = { 0.75, 1, 1.25, 1.4, 1.6 }
local INSIDE = { [0] = true, [2] = true } -- Modern, Block: the name inside the bar (GetUnitNameAnchorStyle)
local UP = 2 -- units our bar is taller than the game's, upward into the name's row (times the vertical scale)
local INSET = 12 -- the plate's side inset (HORIZONTAL_INSET): the name may reach the plate's edges
local DIM = 0.35 -- the dim over a plate that is not the target, on the ground colour

local looks = setmetatable({}, { __mode = "k" }) -- pooled UnitFrame -> our textures on it
local auraLooks = setmetatable({}, { __mode = "k" }) -- pooled aura item -> ours on it
local casting = setmetatable({}, { __mode = "k" }) -- UnitFrame -> true while its cast bar may show
local castLooks = setmetatable({}, { __mode = "k" }) -- stock cast bar -> CastLook's pieces on it
local pending = setmetatable({}, { __mode = "k" }) -- UnitFrame -> true: aura items to dress next frame
local stockFaces = {}
local driver, started

local function on() return started and ns.Enabled(KEY) end

local function tex(f, layer, sub)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetTexture(Theme.Media("white"))
	return t
end

-- The plate's UnitFrame, if the client lets us touch it (rawget: parentKeys, never methods).
local function frameOf(plate)
	if not plate or (plate.IsForbidden and plate:IsForbidden()) then return end
	local uf = rawget(plate, "UnitFrame")
	if uf and not (uf.IsForbidden and uf:IsForbidden()) then return uf end
end
local function plates()
	return C_NamePlate.GetNamePlates() or {}
end
local function castBar(uf)
	local cc = rawget(uf, "CastBarsContainer")
	return cc and rawget(cc, "castBar")
end

---------------------------------------------------------------------------
-- Health bar, level and name
---------------------------------------------------------------------------

-- The game's art we fade (its alpha kept to give back): the whole of its
-- health bar's regions (fill, ground, selection and deselection art, heal
-- prediction and absorbs, the health texts: ours stand in), Camelot's level
-- badge (PlayerLevelDiffFrame) and the classic style's level (LevelFrame).
-- The game shows, hides and fills them; we set alpha only.
local BAR_ART = { "bgTexture", "selectedBorder", "deselectedOverlay", "Text", "LeftText", "RightText", "myHealPrediction",
	"otherHealPrediction", "totalAbsorb", "totalAbsorbOverlay", "myHealAbsorb", "myHealAbsorbLeftShadow", "myHealAbsorbRightShadow",
	"overAbsorbGlow", "overHealAbsorbGlow" }
local function fadedOf(uf, hb)
	local list = {}
	for _, t in ipairs(BAR_ART) do list[#list + 1] = rawget(hb, t) end
	list[#list + 1] = rawget(uf, "selectionHighlight")
	for _, spec in ipairs({ { "PlayerLevelDiffFrame", "playerLevelDiffIcon", "playerLevelDiffText", "selectedBorder", "highLevelTexture" },
		{ "LevelFrame", "LevelText", "HighLevelTexture" } }) do
		local f = rawget(uf, spec[1])
		for i = 2, f and #spec or 0 do list[#list + 1] = rawget(f, spec[i]) end
	end
	return list
end

-- A HUD text at our own size (the plate's scale), repainted with the theme.
local function sized(fs, role, size)
	Polestar.Widgets.Painter(fs, function(s)
		Theme.SetFace(s, (Theme.FontSpec(role)), size, "OUTLINE")
		s:SetShadowOffset(1, -1)
		s:SetShadowColor(0, 0, 0, 1)
	end)
end

-- Ours, once per pooled UnitFrame: a frame of our own under the game's health
-- bar (so it shows and hides with it), placed by anchors on the game's
-- containers and sized by us. No stock frame is moved or sized (rule 20).
local function look(uf)
	local l = looks[uf]
	if l then return l end
	local hb = rawget(uf, "healthBar")
	local fill = hb and hb:GetStatusBarTexture()
	if not fill then return end
	l = { hb = hb, hc = rawget(uf, "HealthBarsContainer") or hb, cc = rawget(uf, "CastBarsContainer"), gameFill = fill, alphas = {} }
	local box = Polestar.CreateFrameUnder("Frame", nil, hb)
	l.box = box
	-- The unit frames' ground: the scheme's ground at the HUD's Background opacity, a hairline, the glow.
	l.ground = H.Ground(box)
	-- A bar of our own (a StatusBar: it takes the secret health), inside the hairline, with the unit frames' segments.
	l.bar = H.Bar(box) -- placed in colour(), inset by the hairline's own thickness
	l.bar:SetClipsChildren(true) -- the segments end at the bar's ends
	H.SetTrack(l.bar, 0) -- the ground is the track
	l.heal = H.Segment(l.bar) -- coloured as the fill (colour)
	l.absorb = H.Segment(l.heal, "text", 0.55)
	l.healAbsorb = H.Segment(l.bar, "shade", 0.55, true)
	-- Over the bar and its segments: the dim of a plate that is not the target, and the texts.
	local over = CreateFrame("Frame", nil, box)
	over:SetAllPoints(box)
	over:SetFrameLevel(l.bar:GetFrameLevel() + 10)
	l.dim = tex(over, "ARTWORK")
	l.dim:SetAllPoints(l.bar)
	l.health = H.Text(over, "number", "text")
	l.health:SetJustifyH("RIGHT")
	l.health:SetPoint("RIGHT", box, "RIGHT", -4, 0)
	l.name = H.Text(over, "small", "text")
	ns.NameFont(l.name) -- a name in any script, never read: it is secret in combat
	l.faded = fadedOf(uf, hb)
	l.faded[#l.faded + 1] = fill
	for _, t in ipairs(l.faded) do l.alphas[t] = t:GetAlpha() end
	looks[uf] = l
	return l
end

-- Our bar's place and size, from the game's style and size options (read,
-- never written). Its sides are the plate's content edges (the cast bars'
-- container: the room the game leaves for its level badge is the bar's too),
-- its bottom 1 unit above the cast area, its top the game's bar's, UP higher
-- where the game keeps a row for the name above the bar (the row is 14 high:
-- ours, at 11, leaves the difference to the bar). The name sits in that row,
-- centred, as wide as the plate; in the styles with the name inside the bar
-- (Modern, Block: a 20-high bar, no row above) it stays inside, as on the
-- unit frames.
local barWidth -- our bar's width as last read out of combat (the same on every plate)
local function fit(l)
	local style, size = tonumber(GetCVar("nameplateStyle")) or 1, tonumber(GetCVar("nameplateSize")) or 2
	local v, inside = VERTICAL[size] or 1, INSIDE[style] or false
	if l.v ~= v or l.inside ~= inside then
		l.v, l.inside = v, inside
		local box, name = l.box, l.name
		box:ClearAllPoints()
		box:SetPoint("TOPLEFT", l.hc, "TOPLEFT", 0, inside and 0 or UP * v)
		if l.cc then box:SetPoint("BOTTOMRIGHT", l.cc, "TOPRIGHT", 0, 1) else box:SetPoint("BOTTOMRIGHT", l.hc, "BOTTOMRIGHT", 0, 0) end
		name:ClearAllPoints()
		if inside then
			name:SetPoint("LEFT", box, "LEFT", 4, 0)
			name:SetPoint("RIGHT", l.health, "LEFT", -4, 0)
		else
			name:SetPoint("BOTTOMLEFT", box, "TOPLEFT", -INSET, v)
			name:SetPoint("BOTTOMRIGHT", box, "TOPRIGHT", INSET, v)
		end
		name:SetJustifyH(inside and "LEFT" or "CENTER")
		sized(name, "small", math.floor(11 * v + 0.5))
		sized(l.health, "number", math.floor(9 * v + 0.5))
	end
	-- The segments are as wide as the bar (H.Segment): from a width read out
	-- of combat only (geometry can be secret in combat, rule 3).
	-- shortcut: until one is read, the game's layout numbers (190 less the insets, Camelot); a client with another plate width draws heals and absorbs a little off until the first plate added out of combat.
	local w = not InCombatLockdown() and ns.Clean(l.bar:GetWidth())
	if w and w > 0 then barWidth = w end
	for _, s in ipairs({ l.heal, l.absorb, l.healAbsorb }) do s:SetWidth(barWidth or (190 - 2 * INSET) * (HORIZONTAL[size] or 1) - 2) end
end

-- The level's colour as the target frame paints it (UnitFrames.lua's
-- levelColor, after stock's TargetFrameMixin:CheckLevel): the difficulty
-- colour on an attackable unit, gold on a friendly one, the skull's red on
-- "??"; nil while secret or unknown (the neutral token).
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

-- The level (in its colour) and the name, one string, where the game shows
-- a name (not on a simplified plate; a name-only or widget plate has no bar:
-- ours hides with it and the game's name shows). The game's name is faded
-- while our bar shows. Nothing is read off the game's string; the name goes
-- in unread (secret in combat), the level only while it is not secret.
local function label(uf, l)
	local unit, game = rawget(uf, "unit"), rawget(uf, "name")
	local bar = l.hb:IsShown() and l.hc:IsShown()
	local shown = unit ~= nil and bar and (not game or game:IsShown())
	if game then game:SetAlpha(bar and 0 or 1) end
	l.name:SetShown(shown)
	if not shown then return end
	local level = ns.Clean(UnitEffectiveLevel and UnitEffectiveLevel(unit) or UnitLevel(unit))
	local prefix = ""
	if level then
		local r, g, b = levelColor(unit, level)
		if not r then r, g, b = Theme.Color("textDim") end
		prefix = ("|cff%02x%02x%02x%s|r "):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5), level < 1 and "??" or level)
	end
	l.name:SetFormattedText("%s%s", prefix, UnitName(unit) or "")
end

-- Heal prediction as the unit frames work it out (UnitFrames.lua's
-- prediction: the client's calculator, clamped as stock shows it). All
-- secret: handed to the segments unread.
local calc
local function prediction(unit)
	if not (CreateUnitHealPredictionCalculator and UnitGetDetailedHealPrediction) then
		return UnitGetIncomingHeals(unit) or 0, UnitGetTotalAbsorbs(unit) or 0, UnitGetTotalHealAbsorbs(unit) or 0
	end
	if not calc then
		calc = CreateUnitHealPredictionCalculator()
		calc:SetIncomingHealClampMode(Enum.UnitIncomingHealClampMode.MissingHealth)
		calc:SetDamageAbsorbClampMode(Enum.UnitDamageAbsorbClampMode.MissingHealth)
		calc:SetHealAbsorbClampMode(Enum.UnitHealAbsorbClampMode.CurrentHealth)
		calc:SetHealAbsorbMode(Enum.UnitHealAbsorbMode.ReducedByIncomingHeals)
	end
	UnitGetDetailedHealPrediction(unit, "player", calc)
	return (calc:GetIncomingHeals()), (calc:GetDamageAbsorbs()), (calc:GetHealAbsorbs())
end

local function bit(cvar, i)
	local ok, v = pcall(CVarCallbackRegistry.GetCVarBitfieldIndex, CVarCallbackRegistry, cvar, i)
	return not ok or v ~= false
end

-- The health, its segments and its text: values straight from the client
-- into the bars and SetFormattedText (secret). The text as the game's own
-- nameplateInfoDisplay asks: the percent, the value, both or none.
local function health(uf, l)
	local unit = rawget(uf, "unit")
	if not unit then return end
	local max = UnitHealthMax(unit)
	local heals, absorbs, healAbsorbs = prediction(unit)
	for _, s in ipairs({ l.bar, l.heal, l.absorb, l.healAbsorb }) do s:SetMinMaxValues(0, max) end
	l.bar:SetValue(UnitHealth(unit))
	l.heal:SetValue(heals)
	l.absorb:SetValue(absorbs)
	l.healAbsorb:SetValue(healAbsorbs)
	local pct = bit("nameplateInfoDisplay", 1) and UnitHealthPercent and CurveConstants and UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)
	local value = bit("nameplateInfoDisplay", 2)
	if pct and value then
		l.health:SetFormattedText("%s  %.0f%%", AbbreviateNumbers(UnitHealth(unit)), pct)
	elseif pct then
		l.health:SetFormattedText("%.0f%%", pct)
	elseif value then
		l.health:SetFormattedText("%s", AbbreviateNumbers(UnitHealth(unit)))
	else
		l.health:SetText("")
	end
end

-- The target frame's colour for this unit (H.UnitColor: grey gone or tapped,
-- danger hostile, warning neutral, else sky or the class colour), and its
-- edge: the focus has a flat warning
-- hairline (the target has none: the dim of the others marks it), a plate showing threat (the game's own nameplateThreatDisplay
-- flag on the UnitFrame) glows in the game's threat colour as the target
-- frame's edge does; else the border. While there is a target, every plate
-- that is neither it nor the focus is dimmed (the game's deselected overlay,
-- faded with its bar). Secret inputs fall through as on the target frame.
local function colour(uf, l)
	local unit = rawget(uf, "unit")
	if not unit then return end
	l.gameFill:SetAlpha(0) -- the game's SetStatusBarColor wrote its alpha again
	-- The bar inset by exactly the hairline's thickness (one physical pixel as
	-- PaintHairlines reads it now), so both edges are the same coordinate and
	-- snap alike at any scale: the game scales plates with distance and
	-- selection, and a fixed 1-unit inset beside a 1-pixel hairline left a
	-- gap of ground showing as a flickering dark line.
	local px = Theme.Pixel(l.box)
	if l.px ~= px then
		l.px = px
		l.bar:ClearAllPoints()
		l.bar:SetPoint("TOPLEFT", l.box, "TOPLEFT", px, -px)
		l.bar:SetPoint("BOTTOMRIGHT", l.box, "BOTTOMRIGHT", -px, px)
	end
	local r, g, b = H.UnitColor(unit)
	H.SetBarColor(l.bar, r, g, b)
	l.heal:SetStatusBarColor(r + (1 - r) * 0.45, g + (1 - g) * 0.45, b + (1 - b) * 0.45, 0.7)
	local target, focus = ns.Clean(UnitIsUnit(unit, "target")), ns.Clean(UnitIsUnit(unit, "focus"))
	local dr, dg, db = Theme.Color("bg")
	l.dim:SetVertexColor(dr, dg, db, DIM)
	l.dim:SetShown(not target and not focus and ns.Clean(UnitExists("target")) == true)
	local a = H.GroundAlpha()
	if focus then
		local fr, fg, fb = Theme.Color("warning")
		return H.PaintGround(l.ground, a, fr, fg, fb, 1, true)
	end
	if rawget(uf, "displayThreatHealthBarColor") and GetThreatStatusColor then
		local s = ns.Clean(UnitThreatSituation("player", unit))
		if s and s > 0 then
			local tr, tg, tb = GetThreatStatusColor(s)
			return H.PaintGround(l.ground, a, tr, tg, tb, H.THREAT_ALPHA)
		end
	end
	H.PaintGround(l.ground, a)
end

local function paint(uf, l, shown)
	for _, t in ipairs(l.faded) do t:SetAlpha(shown and 0 or l.alphas[t]) end
	l.box:SetShown(shown)
	if not shown then
		local game = rawget(uf, "name")
		if game then game:SetAlpha(1) end
		return
	end
	colour(uf, l) -- places the bar in its hairline, before fit reads its width
	fit(l)
	label(uf, l)
	health(uf, l)
end

---------------------------------------------------------------------------
-- Cast bar (ns.CastLook, Modules/CastBars.lua)
---------------------------------------------------------------------------

-- Ours fills the game's cast area (never read off the bar: secret in combat):
-- the bar's height plus, where the spell's name sits under a thin bar, the
-- icon's row under it (GetCastBarHeight, GetCastBarIconHeight: 6 + 10, or
-- 16 for Block and Cast Focus; times nameplateSize's vertical scale). The
-- icon inside on the left, where the game's icon and its shield are.
local function castLayout()
	local style, size = tonumber(GetCVar("nameplateStyle")), tonumber(GetCVar("nameplateSize"))
	local v = VERTICAL[size or 2] or 1
	local h = (LARGE_CAST[style or 1] and 16 or 6 + 10) * v
	return { height = h, inside = true, text = math.floor(9 * v + 0.5) }
end

-- Ours over the game's shield and target name (our box covers the bar):
-- a shield of ours on our icon while the game shows its own (a cast that
-- cannot be interrupted), and the caster's target in place of the time
-- while the game shows its target name (the game's faded). Shown states
-- are read through ns.Clean: secret, ours stays off and the textMuted fill
-- (CastLook) still marks the shield. The name and icon only where the
-- game's options show them.
local shields = setmetatable({}, { __mode = "k" }) -- stock cast bar -> our shield texture
local function afterCast(cb, l, unit)
	local game = rawget(cb, "BorderShield")
	local s = shields[cb]
	if not s then
		s = l.box:CreateTexture(nil, "OVERLAY", nil, 7)
		s:SetAtlas("nameplates-InterruptShield")
		s:SetPoint("TOPLEFT", l.icon, "TOPLEFT", 0, 0)
		s:SetPoint("BOTTOMRIGHT", l.icon, "BOTTOMRIGHT", 0, 0)
		shields[cb] = s
	end
	s:SetShown(game ~= nil and ns.Clean(game:IsShown()) == true)
	if not bit("nameplateCastBarDisplay", 1) then l.name:SetText("") end
	local target = rawget(cb, "CastTargetNameText")
	if target then
		target:SetAlpha(0)
		local show = unit and ns.Clean(target:IsShown()) and UnitSpellTargetName
			and ns.Clean(UnitShouldDisplaySpellTargetName and UnitShouldDisplaySpellTargetName(unit)) ~= false
		if show then l.time:SetFormattedText("%s", UnitSpellTargetName(unit) or "") end
	end
	if not bit("nameplateCastBarDisplay", 2) then
		l.icon:Hide()
		ns.PaintHairlines(l.iconEdges, false, 0, 0, 0, 0)
	end
end

local function dressCast(uf, shown)
	local CL, cb = ns.CastLook, castBar(uf)
	if not (CL and cb) then return end
	if not shown then
		local target, s = rawget(cb, "CastTargetNameText"), shields[cb]
		if target then target:SetAlpha(1) end
		if s then s:Hide() end
		return CL.undress(cb)
	end
	local o = castLayout()
	local l = CL.dress(cb, o)
	if l then
		castLooks[cb] = l
		afterCast(cb, l, rawget(uf, "unit"))
		casting[uf] = true
	end
end

local function paintCast(uf)
	local CL, cb, unit = ns.CastLook, castBar(uf), rawget(uf, "unit")
	if not (CL and cb and unit and cb:IsVisible()) then
		casting[uf] = nil
		return
	end
	CL.paint(cb, { unit = unit, shield = true })
	local l = castLooks[cb]
	if l then afterCast(cb, l, unit) end
end

---------------------------------------------------------------------------
-- Aura icons
---------------------------------------------------------------------------

local function byAtlas(f, atlas)
	for _, r in ipairs({ f:GetRegions() }) do
		if r.GetAtlas and r:GetAtlas() == atlas then return r end
	end
end

local function auraLook(item)
	local l = auraLooks[item]
	if l then return l end
	local icon = rawget(item, "Icon")
	if not icon then return end
	local cf, cd = rawget(item, "CountFrame"), rawget(item, "Cooldown")
	l = { icon = icon, mask = icon.GetMaskTexture and icon:GetMaskTexture(1), overlay = byAtlas(item, OVERLAY), count = cf and rawget(cf, "Count"),
		timer = cd and cd.GetCountdownFontString and cd:GetCountdownFontString() }
	-- Ours in place of the game's rounded mask (a mask swap): the icon square inside the hairline.
	l.square = item:CreateMaskTexture()
	l.square:SetTexture(Theme.Media("white"), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	l.square:SetPoint("TOPLEFT", item, "TOPLEFT", 1, -1)
	l.square:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", -1, 1)
	l.edges = ns.Hairlines(item, item, function() return tex(item, "OVERLAY", 7) end)
	auraLooks[item] = l
	return l
end

local function paintAura(l, shown)
	if l.mask and shown ~= (l.squared or false) then
		if shown then
			l.icon:RemoveMaskTexture(l.mask)
			l.icon:AddMaskTexture(l.square)
			l.icon:SetTexCoord(CROP, 1 - CROP, CROP, 1 - CROP)
		else
			l.icon:RemoveMaskTexture(l.square)
			l.icon:AddMaskTexture(l.mask)
			l.icon:SetTexCoord(0, 1, 0, 1)
		end
		l.squared = shown
	end
	if l.overlay then l.overlay:SetAlpha(shown and 0 or 1) end
	H.Face(l.count, "number", shown)
	-- The time left: the client's countdown string (centred on the icon), in
	-- the number face at the target frame's auras' size relative to the icon
	-- (9 on 20: 11 on the plate's 25-unit item); the game's font given back off.
	if l.timer then
		l.timerFont = l.timerFont or { l.timer:GetFont() }
		local f = l.timerFont
		if shown then Theme.SetFace(l.timer, (Theme.FontSpec("number")), 11, "OUTLINE") elseif f[1] then Theme.SetFace(l.timer, f[1], f[2], f[3] or "") end
	end
	local r, g, b, a = Theme.Color("border")
	ns.PaintHairlines(l.edges, shown, r, g, b, a or 1)
end

local LISTS = { "DebuffListFrame", "BuffListFrame", "CrowdControlListFrame" }
local function dressItems(_, ...)
	for i = 1, select("#", ...) do
		local item = select(i, ...)
		if not auraLooks[item] then
			local l = auraLook(item)
			if l then paintAura(l, true) end
		end
	end
end
-- The game's aura items now on this plate (pooled: each dressed once, and kept).
local function dressAuras(uf)
	local af = rawget(uf, "AurasFrame")
	if not af then return end
	for _, k in ipairs(LISTS) do
		local list = rawget(af, k)
		if list then dressItems(list, list:GetChildren()) end
	end
	local loc = rawget(af, "LossOfControlFrame")
	local item = loc and rawget(loc, "AuraItemFrame")
	if item and not auraLooks[item] then
		local l = auraLook(item)
		if l then paintAura(l, true) end
	end
end

---------------------------------------------------------------------------
-- Plates
---------------------------------------------------------------------------

local function dressPlate(uf, shown)
	local l = look(uf)
	if not l then return end
	paint(uf, l, shown)
	dressCast(uf, shown)
	if shown then pending[uf] = true end
end

-- Each frame while on: the cast bars that show (the time left counts down)
-- and the plates whose auras changed (after the game's handlers ran).
local function update()
	for uf in pairs(casting) do paintCast(uf) end
	for uf in pairs(pending) do
		pending[uf] = nil
		if rawget(uf, "unit") then dressAuras(uf) end
	end
end

local HEALTH_EVENTS = { UNIT_HEALTH = true, UNIT_MAXHEALTH = true, UNIT_HEAL_PREDICTION = true, UNIT_ABSORB_AMOUNT_CHANGED = true,
	UNIT_HEAL_ABSORB_AMOUNT_CHANGED = true }
local function plateUnit(unit) return type(unit) == "string" and unit:sub(1, 9) == "nameplate" end

local function onEvent(_, event, unit)
	if not on() then return end
	if event == "NAME_PLATE_UNIT_ADDED" then
		-- The driver's handler ran first: the plate has its UnitFrame and unit.
		local uf = frameOf(C_NamePlate.GetNamePlateForUnit(unit))
		if uf then dressPlate(uf, true) end
	elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
		for _, plate in ipairs(plates()) do
			local uf = frameOf(plate)
			local l = uf and looks[uf]
			if l then colour(uf, l) end
		end
	elseif event == "CVAR_UPDATE" then
		if unit == "nameplateStyle" or unit == "nameplateSize" or unit == "nameplateInfoDisplay" then
			barWidth = nil -- the game lays the plates out again
			for _, plate in ipairs(plates()) do
				local uf = frameOf(plate)
				if uf then dressPlate(uf, true) end
			end
		end
	elseif plateUnit(unit) then
		local uf = frameOf(C_NamePlate.GetNamePlateForUnit(unit))
		if not uf then return end
		local l = looks[uf]
		if HEALTH_EVENTS[event] then
			if l then health(uf, l) end
		elseif event == "UNIT_AURA" then
			pending[uf] = true
		elseif event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" then
			if l then colour(uf, l) end
		elseif event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
			local cb = castBar(uf)
			if cb and ns.CastLook then ns.CastLook.fail(cb, event == "UNIT_SPELLCAST_FAILED" and (FAILED or "Failed") or (INTERRUPTED or "Interrupted")) end
		else
			casting[uf] = true
		end
	end
end

-- The plate texts' faces: Polestar's on the roman member of each family (the
-- game's size and outline kept), the game's again off.
local function faces(shown)
	for name, role in pairs(FONTS) do
		local fam = rawget(_G, name)
		if fam then
			if not stockFaces[name] then
				local ok, roman = pcall(fam.GetFontObjectForAlphabet, fam, "roman")
				local obj = ok and roman or fam
				stockFaces[name] = { obj, obj:GetFont() }
			end
			local s = stockFaces[name]
			Theme.SetFace(s[1], shown and (Theme.FontSpec(role)) or s[2], s[3], s[4] or "")
		end
	end
end

function M.Apply()
	if not started then return end
	local shown = ns.Enabled(KEY)
	faces(shown)
	driver:SetShown(shown)
	if shown then
		for _, plate in ipairs(plates()) do
			local uf = frameOf(plate)
			if uf then dressPlate(uf, true) end
		end
		return
	end
	-- Off: every pooled frame and item we dressed, on a plate now or not.
	for uf, l in pairs(looks) do
		paint(uf, l, false)
		dressCast(uf, false)
	end
	for _, l in pairs(auraLooks) do paintAura(l, false) end
	for uf in pairs(casting) do casting[uf] = nil end
	for uf in pairs(pending) do pending[uf] = nil end
end

function M.Enable()
	if not (C_NamePlate and C_NamePlate.GetNamePlates and rawget(_G, "NamePlateDriverFrame")) then return end
	started = true
	driver = CreateFrame("Frame", nil, UIParent)
	for _, e in ipairs({ "NAME_PLATE_UNIT_ADDED", "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "CVAR_UPDATE", "UNIT_AURA",
		"UNIT_THREAT_SITUATION_UPDATE", "UNIT_THREAT_LIST_UPDATE", "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_HEAL_PREDICTION",
		"UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_HEAL_ABSORB_AMOUNT_CHANGED",
		"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED" }) do
		driver:RegisterEvent(e)
	end
	driver:SetScript("OnEvent", onEvent)
	driver:SetScript("OnUpdate", update)
	-- After the game colours a bar, names a plate or lays out its level badge
	-- (globals called by name; they run for raid frames too: ours only).
	for name, fn in pairs({ CompactUnitFrame_UpdateHealthColor = colour, CompactUnitFrame_UpdateName = label,
		CompactUnitFrame_UpdatePlayerLevelDiff = label }) do
		if rawget(_G, name) then
			hooksecurefunc(name, function(frame)
				local l = looks[frame]
				if l and on() then fn(frame, l) end
			end)
		end
	end
	Theme.OnChanged(function() if ns.Enabled(KEY) then M.Apply() end end)
	M.Apply()
end

-- Beside a plate addon that draws over the same frames, off unless the player switches it on.
ns.AfterLogin(function()
	local loaded = C_AddOns and C_AddOns.IsAddOnLoaded
	if not loaded then return end
	for _, name in ipairs(OTHERS) do
		if loaded(name) then M.defaultOff = true end
	end
	local E = rawget(_G, "ElvUI") and ElvUI[1]
	if E and E.private and E.private.nameplates and E.private.nameplates.enable then M.defaultOff = true end
end)

-- For the scenes: ours on a pooled UnitFrame (box, bar, ground, name, health, dim), or nil.
function M.look(uf) return looks[uf] end

ns.Module(KEY, M)
