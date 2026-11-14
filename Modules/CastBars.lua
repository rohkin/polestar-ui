-- Cast bars (docs/windows/castbars.md): the game's own player, target and
-- focus cast bars in the HUD's look, restyled in place, never rebuilt.
-- PlayerCastingBarFrame is an Edit Mode system and the target's and focus's
-- bars are children of the stock unit frames (docs/CLIENT.md, rules 16 and
-- 17): their place, size, Bar Size, Lock to Player Frame and
-- what shows and fades them stay the game's. The stock bar is never moved,
-- sized, shown or hidden and its children never re-anchored: its art, name,
-- cast time and icon are faded with SetAlpha (regions the game only shows,
-- hides and swaps atlases on), and a frame of ours under it (a child, so it
-- follows the bar's place, scale, alpha and visibility) draws the bar we
-- want: 20 units high from the stock bar's top (where the game's bar and its
-- text box were), a track, a flat fill whose right edge hangs on the game's
-- fill texture (so it follows the cast with no value or size read: cast
-- times and the bar's own geometry are secret, rule 3), a 1px hairline, the spell's icon at its left, its name
-- inside on the left and the time left inside on the right. What is ours is
-- kept in a weak table; no key is written on a stock frame.

local ADDON, ns = ...
local Theme = Polestar.Theme
local H = ns.HUD

local M = { noun = "cast bars" }
local KEY = "castbars"
local HEIGHT = 20 -- ours, in the stock bar's units (so Edit Mode's Bar Size scales it)
local CROP = 0.08 -- the icon's baked border, cropped as ns.GameIcon does
-- `shield`: the game marks a cast that cannot be interrupted (the target's
-- and focus's bars; never the player's own).
local BARS = {
	{ unit = "player", name = "PlayerCastingBarFrame" },
	{ unit = "target", name = "TargetFrameSpellBar", shield = true },
	{ unit = "focus", name = "FocusFrameSpellBar", shield = true },
}
-- CastingBarFrameBaseTemplate's and SmallCastingBarFrameTemplate's regions
-- the game never fades itself. The Spark is set to 1 again by the interrupt
-- animation (InterruptSparkAnim), so it is faded again while a bar shows.
local FADED = { "Border", "Background", "TextBorder", "DropShadow", "BorderShield", "Spark", "StandardGlow", "CraftGlow", "ChannelShadow",
	"Text", "CastTimeText", "Icon" }

local looks = setmetatable({}, { __mode = "k" }) -- stock cast bar -> our frame under it and its pieces
local driver, started

-- A stock bar the client has made, and lets addon code touch (rule 15).
local function stock(spec)
	local bar = rawget(_G, spec.name)
	if bar and not (bar.IsForbidden and bar:IsForbidden()) then return bar end
end

local function tex(f, layer, sub)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetTexture(Theme.Media("white"))
	return t
end

local function look(bar)
	local l = looks[bar]
	if l then return l end
	local fill = bar:GetStatusBarTexture()
	if not fill then return end
	-- A frame of ours under the bar: above every region of the game's (its
	-- fill, flash and effects), as wide as the bar, HEIGHT from its top.
	local box = Polestar.CreateFrameUnder("Frame", nil, bar)
	box:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
	box:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
	box:SetHeight(HEIGHT)
	local function edge() return tex(box, "OVERLAY", 7) end
	l = { box = box, stockFill = fill, track = tex(box, "BACKGROUND"), fill = tex(box, "ARTWORK"), edges = ns.Hairlines(box, box, edge) }
	l.track:SetAllPoints(box)
	-- Our fill: from the game's fill's left to its right edge, at our own
	-- height. Nothing of the stock bar's geometry is read: its size, like
	-- its fill's, is secret in combat (rule 3).
	l.fill:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, 0)
	l.fill:SetPoint("TOPRIGHT", fill, "TOPRIGHT", 0, 0)
	l.fill:SetHeight(HEIGHT)
	l.icon = tex(box, "ARTWORK")
	l.icon:SetTexCoord(CROP, 1 - CROP, CROP, 1 - CROP)
	l.icon:SetSize(HEIGHT, HEIGHT)
	l.icon:SetPoint("TOPRIGHT", box, "TOPLEFT", -2, 0)
	l.iconEdges = ns.Hairlines(box, l.icon, edge)
	-- As on the unit frames: the name from the left, cut where the time starts.
	l.time = H.Text(box, "number", "text")
	l.time:SetJustifyH("RIGHT")
	l.time:SetPoint("RIGHT", box, "RIGHT", -4, 0)
	l.name = H.Text(box, "label", "text")
	l.name:SetPoint("LEFT", box, "LEFT", 4, 0)
	l.name:SetPoint("RIGHT", l.time, "LEFT", -4, 0)
	looks[bar] = l
	return l
end

-- The game's art, texts and icon faded or given back; ours shown or hidden.
local function dress(bar, l, on)
	for _, k in ipairs(FADED) do
		local t = rawget(bar, k)
		if t then t:SetAlpha(on and 0 or 1) end
	end
	l.box:SetShown(on)
	l.fill:SetTexture(H.FillTexture())
	-- Until a cast colours it (Edit Mode's sample bar): the default fill.
	local r, g, b = H.FillColor("player")
	l.fill:SetVertexColor(r, g, b, 1)
end

local function castInfo(unit, channel)
	if channel then return UnitChannelInfo(unit) end
	return UnitCastingInfo(unit)
end

-- The fill's colour: H.FillColor (the header band's blue, the class colour with
-- Polestar's "Class colour"); a cast that cannot be interrupted in
-- textMuted (the game's grey shield bar). The client may hand that over
-- secret: then the texture picks the colour itself (SetVertexColorFromBoolean).
local function castColor(spec, l, channel)
	local r, g, b = H.FillColor(spec.unit)
	local locked
	if spec.shield then
		if channel then locked = select(7, UnitChannelInfo(spec.unit)) else locked = select(8, UnitCastingInfo(spec.unit)) end
	end
	if issecretvalue and issecretvalue(locked) then
		if l.fill.SetVertexColorFromBoolean then
			local mr, mg, mb = Theme.Color("textMuted")
			return l.fill:SetVertexColorFromBoolean(locked, CreateColor(mr, mg, mb, 1), CreateColor(r, g, b, 1))
		end
	elseif locked then
		r, g, b = Theme.Color("textMuted")
	end
	l.fill:SetVertexColor(r, g, b, 1)
end

-- One shown bar, each frame. What the game's bar is doing is read off its
-- own flags (CastingBarMixin's `casting`, `channeling`, `reverseChanneling`,
-- `isInEditMode`: plain booleans, never secret),
-- after the game's handlers ran.
local function paint(spec, bar, l)
	local empower = rawget(bar, "reverseChanneling") and true or false
	local channel = rawget(bar, "channeling") and true or false
	local live = empower or channel or (rawget(bar, "casting") and true or false)
	local editing = rawget(bar, "isInEditMode") and not live
	if live then l.failed = nil end
	l.live = live
	-- An empowered cast keeps the game's stage art, seen through ours: only
	-- our hairline, icon, name and time stay over it.
	l.track:SetShown(not empower)
	l.fill:SetShown(not empower)
	local r, g, b = Theme.Color("bg")
	l.track:SetVertexColor(r, g, b, H.GroundAlpha())
	if live then
		castColor(spec, l, channel)
	elseif l.failed then
		r, g, b = Theme.Color("danger")
		l.fill:SetVertexColor(r, g, b, 1)
	end
	local br, bg, bb, ba = Theme.Color("border")
	ns.PaintHairlines(l.edges, true, br, bg, bb, ba)
	local spark = rawget(bar, "Spark")
	if spark then spark:SetAlpha(0) end
	-- The icon and the name, from the cast itself (secret for another unit:
	-- handed over unread; `known`, never secret, says there is a cast).
	if live then
		local _, text, texture, _, _, known = castInfo(spec.unit, channel or empower)
		if known ~= nil then
			l.icon:SetTexture(texture)
			l.name:SetFormattedText("%s", text)
			l.iconSet = true
		end
	elseif l.failed then
		l.name:SetFormattedText("%s", l.failed)
	elseif editing then
		l.name:SetFormattedText("%s", HUD_EDIT_MODE_CAST_BAR_LABEL or "Cast Bar")
	end
	local icon = l.iconSet and not editing or false
	l.icon:SetShown(icon)
	ns.PaintHairlines(l.iconEdges, icon, br, bg, bb, ba)
	-- The time left, from the cast's duration object (secret; never read).
	-- Always shown, whatever Edit Mode's Show Cast Time says (the game's own
	-- cast time is faded); a sample in Edit Mode.
	local get = channel and UnitChannelDuration or UnitCastingDuration
	local d = live and not empower and get and get(spec.unit)
	if d then
		l.time:SetFormattedText("%.1f", d:GetRemainingDuration())
	elseif editing then
		l.time:SetFormattedText("%.1f", 10)
	else
		l.time:SetText("")
	end
end

local function update()
	for _, spec in ipairs(BARS) do
		local bar = stock(spec)
		if bar then
			local fresh = not looks[bar]
			local l = look(bar)
			if l then
				if fresh then dress(bar, l, true) end
				if bar:IsVisible() then paint(spec, bar, l) else l.iconSet = nil end
			end
		end
	end
end

function M.Apply()
	if not started then return end
	local on = ns.Enabled(KEY)
	for _, spec in ipairs(BARS) do
		local bar = stock(spec)
		local l = bar and look(bar)
		if l then dress(bar, l, on) end
	end
	driver:SetShown(on)
	if on then update() end
end

-- An interrupt or a failure ends a cast in danger, with the game's word for
-- it. The game tells them from another spell's failure by the cast's id
-- (secret for another unit); ours by the bar itself: it was casting (our
-- last look at it) and, once the game's handler ran, it no longer is.
local function onEvent(_, event, unit)
	for _, spec in ipairs(BARS) do
		local bar = spec.unit == unit and stock(spec)
		local l = bar and looks[bar]
		if l and l.live then l.failed = event == "UNIT_SPELLCAST_FAILED" and (FAILED or "Failed") or (INTERRUPTED or "Interrupted") end
	end
end

function M.Enable()
	if not rawget(_G, "PlayerCastingBarFrame") then return end
	started = true
	driver = CreateFrame("Frame", nil, UIParent)
	driver:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	driver:RegisterEvent("UNIT_SPELLCAST_FAILED")
	driver:SetScript("OnEvent", onEvent)
	driver:SetScript("OnUpdate", update)
	Theme.OnChanged(function() if ns.Enabled(KEY) then M.Apply() end end)
	M.Apply()
end

ns.Module(KEY, M)
