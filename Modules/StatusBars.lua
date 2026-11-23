-- Experience and reputation bars (docs/windows/statusbars.md): the game's
-- status tracking bars (Blizzard_StatusTrackingBar) in the HUD's look,
-- restyled in place, never rebuilt. MainStatusTrackingBarContainer and
-- SecondaryStatusTrackingBarContainer are Edit Mode systems (docs/CLIENT.md,
-- rule 17): their place, Size, "Show status bar 2", which bar each shows, the
-- fades between bars and at max level, the text (the xpBarText option and on
-- hover), the tooltips and the gain and level-up effects all stay the game's.
-- Each container holds one bar of every kind (StatusTrackingBarInfo.BarsEnum,
-- `container.bars`) and shows one at a time. Under every bar a frame of ours
-- (a child: it follows the bar's place, size, the container's alpha and the
-- bar's visibility) draws a track (the experience bar's wearing Polestar's
-- header band and its stars), a 1px hairline and the window shadow, a
-- fill whose edges hang on the game's fill texture (so it follows the value,
-- eased by the game, with no value or size read: rule 3), and a faint hairline tick
-- on each of the container's dividers. Ours sits a level over the game's
-- StatusBar: the game sets its fill's texture again from the bar's own
-- OnUpdate (GradualAnimatedStatusBarMixin:ApplyPendingTextures, the
-- reputation bar's colour deferred to its first update after it shows), with
-- no event to follow, and a reset fill showed the game's look over ours after
-- login. Ours covers it now, whatever the game does to it (its gain flare and
-- level-up flash go under ours too). The game's ground, fill, frame art and
-- dividers are faded with SetAlpha (regions it only shows, hides and swaps
-- atlases on); each bar is painted again as it shows (HookScript OnShow: a
-- widget script hook, no key written); its text keeps its size in Polestar's
-- face. Nothing is written on a stock frame; switched
-- off, live, everything is the game's again. Repainted on events only.

local ADDON, ns = ...
local Theme = Polestar.Theme
local H = ns.HUD

local M = { noun = "experience and reputation bars" }
local KEY = "statusbars"
local CONTAINERS = { "MainStatusTrackingBarContainer", "SecondaryStatusTrackingBarContainer" }
-- StatusTrackingBarTemplate's StatusBar regions besides its fill (the gain
-- flare and level-up flash, which the game animates, stay its own).
local FADED = { "Background", "Underlay", "Overlay" }
-- StatusTrackingBarInfo.BarsEnum.Experience.
local XP = 4
local REP = 1 -- StatusTrackingBarInfo.BarsEnum.Reputation
-- The experience bar's track wears Polestar's header band (Theme.Band: the
-- sky and its stars, the skin's own art, painted clear with the band off),
-- over the track, under the fill, at this alpha so the ticks and fill read.
-- STARS_Y: the band's rows shown, from the middle of a compact header's 60
-- (ns.Compact), so a thin bar crops its lit part and nothing is squashed.
local STARS_ALPHA, STARS_Y = 0.7, 23
-- The divider ticks: the edge's colour at half its alpha (faint, under the text).
local TICK_ALPHA = 0.5
-- The reputation bar's track tinted in the standing's colour (as the game's
-- green bar on its green-tinted ground), at this alpha over the dark track.
local TINT_ALPHA = 0.3

local looks = setmetatable({}, { __mode = "k" }) -- stock bar -> our frame under it and its pieces

-- Container -> true while the game fades it in (its FadeInAnimation).
local fadingIn = {}
local hooked = {}

local started

local function tex(f, layer, sub)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetTexture(Theme.Media("white"))
	return t
end

-- A token of the player's theme, else the game's own hue calmed halfway to
-- textMuted (as H.PowerColor).
local function token(name, r, g, b)
	if Theme.Palette()[name] then return Theme.Color(name) end
	local mr, mg, mb = Theme.Color("textMuted")
	return (r + mr) / 2, (g + mg) / 2, (b + mb) / 2
end

-- A bar kind's fill colour (StatusTrackingBarInfo.BarsEnum). Experience: the
-- game's purple in the scheme's violet, rested (GetRestState 1: the game's
-- blue fill) the soft blue of mana. The other kinds: the HUD's default fill
-- until each gets its own.
local function fillColor(kind)
	if kind == XP then
		if ns.Clean(GetRestState()) == 1 then return token("npc", 0.0, 0.39, 0.88) end
		return token("dungeon", 0.58, 0.0, 0.55)
	end
	if kind == REP then
		-- The watched faction's standing (C_Reputation.GetWatchedFactionData,
		-- as ReputationStatusBarMixin:Update): hostile and unfriendly in danger,
		-- neutral in warning, friendly and up in success. Renown, paragon and
		-- friendship by that same field for now. Secret or none: nil (kept).
		local d = C_Reputation and C_Reputation.GetWatchedFactionData and C_Reputation.GetWatchedFactionData()
		local reaction = d and ns.Clean(d.reaction)
		if not reaction then return nil end
		if reaction <= 3 then return Theme.Color("danger") end
		if reaction == 4 then return Theme.Color("warning") end
		return Theme.Color("success")
	end
	return H.FillColor("player")
end

-- The game's frame and dividers on a container: faded (a = 0) or given back.
local function fadeContainer(c, a)
	local art = rawget(c, "BarFrameTexture")
	if art then art:SetAlpha(a) end
	local pool = rawget(c, "HorizontalDividersPool")
	if not pool then return end
	for d in pool:EnumerateActive() do
		local t = rawget(d, "BarDividerTexture")
		if t then t:SetAlpha(a) end
	end
end

local paint
local function look(c, kind, bar)
	local l = looks[bar]
	if l then return l end
	local sb = rawget(bar, "StatusBar")
	if not sb then return end
	-- A level over the game's StatusBar (see the top).
	local box = Polestar.CreateFrameUnder("Frame", nil, bar)
	box:SetAllPoints(bar)
	box:SetFrameLevel(sb:GetFrameLevel() + 1)
	l = { box = box, sb = sb, track = tex(box, "BACKGROUND"), fill = tex(box, "ARTWORK"), edges = ns.Hairlines(box, box), shadow = H.Shadow(box, box, 8), ticks = {} }
	l.track:SetAllPoints(box)
	l.tint = tex(box, "BACKGROUND", 2)
	l.tint:SetAllPoints(box)
	if rawget(bar, "barIndex") == XP or rawget(bar, "isExpBar") then
		l.band = Theme.Band(box, "BACKGROUND", 1)
		l.band:SetAllPoints(box)
		l.band:SetAlpha(STARS_ALPHA)
		-- Edit Mode's Size (a drag while it is open): cropped again, as ns.Compact does.
		box:SetScript("OnSizeChanged", function() l.crop(bar) end)
	end
	-- The band at 1:1 on the bar (Theme.BandCoords), from the bar's own size:
	-- set by Edit Mode, read only out of combat and never while secret (rule 3).
	function l.crop(b)
		if not l.band or InCombatLockdown() then return end
		local w, h = b:GetSize()
		if not (ns.Clean(w) and ns.Clean(h)) or w <= 0 or h <= 0 then return end
		l.band:SetTexCoord(Theme.BandCoords(w, h, STARS_Y))
	end
	looks[bar] = l
	-- Painted in the frame the game shows the bar (its first show after login too).
	bar:HookScript("OnShow", function() if ns.Enabled(KEY) then paint(c, kind, bar, l) end end)
	return l
end

-- Our fill on the game's (asked again each paint: a new texture is followed).
local function hang(l)
	local fill = l.sb:GetStatusBarTexture()
	if not fill then return end
	fill:SetAlpha(0)
	if l.stockFill == fill then return end
	l.stockFill = fill
	l.fill:ClearAllPoints()
	l.fill:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, 0)
	l.fill:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 0)
end

-- A hairline on each of the container's dividers (positioned by them: Edit
-- Mode's Size moves them, ours follow); one the game released, hidden.
local function paintTicks(c, l)
	local pool = rawget(c, "HorizontalDividersPool")
	local live = {}
	if pool then
		for d in pool:EnumerateActive() do live[#live + 1] = d; live[d] = true end
	end
	local _, r, g, b, a = H.Edge()
	local px = Theme.Pixel(l.box)
	for _, d in ipairs(live) do
		if not l.ticks[d] then
			local t = tex(l.box, "OVERLAY", 6)
			t:SetPoint("TOP", d, "TOP", 0, 0)
			t:SetPoint("BOTTOM", d, "BOTTOM", 0, 0)
			l.ticks[d] = t
		end
	end
	for d, t in pairs(l.ticks) do
		t:SetShown(live[d] == true and d:IsShown())
		t:SetWidth(px)
		t:SetVertexColor(r, g, b, a * TICK_ALPHA)
	end
end

function paint(c, kind, bar, l)
	hang(l)
	for _, k in ipairs(FADED) do
		local t = rawget(l.sb, k)
		if t then t:SetAlpha(0) end
	end
	H.Face(rawget(rawget(bar, "OverlayFrame") or {}, "Text"), "number", true)
	local r, g, b = Theme.Color("bg")
	l.track:SetVertexColor(r, g, b, H.GroundAlpha())
	l.fill:SetTexture(H.FillTexture())
	r, g, b = fillColor(kind)
	if r then l.color = { r, g, b } elseif not l.color then l.color = { H.FillColor("player") } end
	l.fill:SetVertexColor(l.color[1], l.color[2], l.color[3], 1)
	l.tint:SetShown(kind == REP)
	l.tint:SetVertexColor(l.color[1], l.color[2], l.color[3], TINT_ALPHA)
	H.PaintEdge(l.edges, true)
	H.PaintShadow(l.shadow, true)
	paintTicks(c, l)
	l.crop(bar)
	l.box:SetIgnoreParentAlpha(fadingIn[c] == true)
	l.box:Show()
end

local function undress(bar, l)
	l.box:Hide()
	l.box:SetIgnoreParentAlpha(false)
	if l.stockFill then l.stockFill:SetAlpha(1) end
	for _, k in ipairs(FADED) do
		local t = rawget(l.sb, k)
		if t then t:SetAlpha(1) end
	end
	H.Face(rawget(rawget(bar, "OverlayFrame") or {}, "Text"), "number", false)
end

local function each(fn)
	for _, name in ipairs(CONTAINERS) do
		local c = rawget(_G, name)
		local bars = c and not (c.IsForbidden and c:IsForbidden()) and rawget(c, "bars")
		if bars then
			local kinds = {}
			for kind in pairs(bars) do kinds[#kinds + 1] = kind end
			table.sort(kinds)
			for _, kind in ipairs(kinds) do fn(c, kind, bars[kind]) end
		end
	end
end

-- The game fades a container in (its FadeInAnimation: alpha 0 to 1 in 0.5 s)
-- as it shows a bar. After login that fade ran 5 to 8 s (time spent behind
-- the loading screen counts), the container at alpha 0 with ours in it: the
-- bar showed up seconds late. While a fade-in plays, ours ignores the
-- container's alpha (shown at once); the game's fade-outs (a bar switch, the
-- max-level fade) and everything after a fade-in it follows. Read from the
-- animations' own scripts (HookScript: no key written), never polled.
-- The game sets its art's alpha back after we faded it (seen in game: the
-- frame, all 19 dividers, the ground and the fill at full alpha again under
-- ours while the bar loaded in, faded once UPDATE_FACTION repainted). Not in
-- the .ref source: the live client's StatusTrackingManagerMixin:UpdateBarVisuals
-- (Edit Mode calls it with an argument the .ref one does not take), at the end
-- of every UpdateBarsShown: on the manager's events, and once a container's
-- fade ends (UpdateBarsShown waits for it). A method of the manager, copied
-- into it when it was made: a hook would write a key on it (rule 15), and
-- one on the mixin would never run. So the art is faded again just after:
-- on each of the manager's events (the client calls a frame's handlers in
-- the order frames registered, the manager's long before ours), again the
-- frame after (one deferred call, however many events came: should an
-- event reach us first), and from the fades' own OnFinished, which runs
-- after the game's. Only SetAlpha on the regions we fade; nothing polled.
local MANAGER_EVENTS = { "UPDATE_FACTION", "MAJOR_FACTION_RENOWN_LEVEL_CHANGED", "ENABLE_XP_GAIN", "DISABLE_XP_GAIN", "CVAR_UPDATE",
	"UPDATE_EXPANSION_LEVEL", "PLAYER_ENTERING_WORLD", "HONOR_XP_UPDATE", "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "UNIT_INVENTORY_CHANGED",
	"ARTIFACT_XP_UPDATE", "AZERITE_ITEM_EXPERIENCE_CHANGED", "PLAYER_EQUIPMENT_CHANGED", "TRACKED_HOUSE_CHANGED", "PLAYER_MAX_LEVEL_UPDATE",
	"UNIT_LEVEL", "PLAYER_XP_UPDATE", "UPDATE_EXHAUSTION", "PLAYER_UPDATE_RESTING", "EDIT_MODE_LAYOUTS_UPDATED" }

local function refade()
	if not (started and ns.Enabled(KEY)) then return end
	each(function(c, kind, bar)
		local l = looks[bar]
		if not l then return end
		hang(l)
		for _, k in ipairs(FADED) do
			local t = rawget(l.sb, k)
			if t then t:SetAlpha(0) end
		end
	end)
	for _, name in ipairs(CONTAINERS) do
		local c = rawget(_G, name)
		if c then fadeContainer(c, 0) end
	end
end

local soon
local function refadeSoon()
	if soon or not ns.Enabled(KEY) then return end
	soon = true
	C_Timer.After(0, function()
		soon = nil
		refade()
	end)
end

local function follow(c)
	local bars = rawget(c, "bars")
	if not bars then return end
	for _, bar in pairs(bars) do
		local l = looks[bar]
		if l then l.box:SetIgnoreParentAlpha(fadingIn[c] == true) end
	end
end

local function watchFades(c)
	if hooked[c] then return end
	hooked[c] = true
	local fadeIn = rawget(c, "FadeInAnimation")
	if fadeIn then
		local function done() fadingIn[c] = nil; follow(c); refade() end
		fadeIn:HookScript("OnPlay", function() fadingIn[c] = true; follow(c) end)
		fadeIn:HookScript("OnFinished", done)
		fadeIn:HookScript("OnStop", done)
		fadingIn[c] = fadeIn:IsPlaying() or nil
	end
	for _, k in ipairs({ "FadeOutAnimation", "MaxLevelFadeOutAnimation" }) do
		local a = rawget(c, k)
		if a then
			a:HookScript("OnPlay", function() fadingIn[c] = nil; follow(c) end)
			a:HookScript("OnFinished", refade)
		end
	end
end

function M.Apply()
	if not started then return end
	local on = ns.Enabled(KEY)
	each(function(c, kind, bar)
		local l = look(c, kind, bar)
		if not l then return end
		if on then paint(c, kind, bar, l) else undress(bar, l) end
	end)
	for _, name in ipairs(CONTAINERS) do
		local c = rawget(_G, name)
		if c then
			fadeContainer(c, on and 0 or 1)
			if on then watchFades(c) end
		end
	end
end

local function repaint()
	if ns.Enabled(KEY) then M.Apply() end
end

function M.Enable()
	if not rawget(_G, "MainStatusTrackingBarContainer") then return end
	started = true
	-- The rest state (the fill's colour), a new fill texture, and the
	-- dividers Edit Mode lays again (a Size change, a layout switch).
	for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "UPDATE_EXHAUSTION", "PLAYER_UPDATE_RESTING",
		"UPDATE_FACTION", "MAJOR_FACTION_RENOWN_LEVEL_CHANGED", "EDIT_MODE_LAYOUTS_UPDATED" }) do
		Polestar.RegisterEvent(e, repaint)
	end
	for _, e in ipairs(MANAGER_EVENTS) do Polestar.RegisterEvent(e, function() refade(); refadeSoon() end) end
	EventRegistry:RegisterCallback("EditMode.Exit", repaint, M)
	Theme.OnChanged(repaint, true)
	M.Apply()
end

ns.Module(KEY, M)
