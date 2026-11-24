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
-- face. Every kind (experience, reputation, honor, artifact, azerite, house
-- favour) is dressed by the same path, its fill in the game's meaning
-- (fillColor); rested experience and the game's pips as their own pieces
-- (paintRest); a left-click on the reputation bar opens our Character
-- window's Reputation page. Nothing is written on a stock frame; switched
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
local REP, HONOR, ARTIFACT, AZERITE, HOUSE = 1, 2, 3, 5, 6 -- the others
-- The experience bar as the game's, in Polestar's look: a see-through black
-- track (the scheme's shade at XP_TRACK; the world shows through a little)
-- and a solid fill in Polestar's blue wearing the header band's stars (the
-- band-stars art, the skin's own bandStars, in the star token at STAR_OVER,
-- gone with Polestar's band off: as Theme.Band paints them), over the fill
-- only. The stars sit on a frame as wide as the whole bar, inside a frame
-- clipped to the fill (its corners hung on the game's fill, as our fill):
-- the fill reveals them as it grows, nothing slides or stretches.
-- STARS_Y: the band's rows shown, from the middle of a compact header's 60
-- (ns.Compact), cropped 1:1 to the bar (Theme.BandCoords).
local STARS_Y, STAR_OVER = 23, 0.6
local XP_TRACK = 0.4
-- The divider ticks and the outline: the window border's colour (H.Edge),
-- its alpha raised to at least these (the house border, 0.1, vanished on
-- the dark track); the outline hidden with Polestar's border off.
local TICK_MIN, EDGE_MIN = 0.3, 0.5
-- The reputation bar's track tinted in the standing's colour (as the game's
-- green bar on its green-tinted ground), at this alpha over the dark track.
local TINT_ALPHA = 0.3
-- Rested experience: the portal violet (dungeon; apart from the fill's
-- Polestar blue and the quest XP's green) at this alpha past the fill (the
-- game's lighter prediction), a full-colour 1px line along its top and at its end,
-- so it reads on the dark track and apart from the solid fill. The quest XP
-- band (QUEST_ALPHA) has its lines along its bottom and at its end: both
-- start at the fill's end and overlap, the lines keep them apart.
local REST_ALPHA = 0.4

local looks = setmetatable({}, { __mode = "k" }) -- stock bar -> our frame under it and its pieces

-- Container -> true while the game fades it in (its FadeInAnimation).
local fadingIn = {}
local hooked = {}

local started

local tex = ns.HUD.Tex

-- A token of the player's theme, else the game's own hue calmed halfway to
-- textMuted (as H.PowerColor).
local function token(name, r, g, b)
	if Theme.Palette()[name] then return Theme.Color(name) end
	local mr, mg, mb = Theme.Color("textMuted")
	return (r + mr) / 2, (g + mg) / 2, (b + mb) / 2
end

-- The watched faction's fill, as ReputationStatusBarMixin:Update picks its
-- atlas: renown (a major faction) and a major faction's paragon in the game's
-- blue (the game's rested blue: npc, as the rested experience); a friendship as the game's green
-- (success: it draws every friendship at reaction 5); a paragon of a normal
-- faction by its reaction (exalted: success); else hostile and unfriendly in
-- danger, neutral in warning, friendly and up in success. Every answer
-- through ns.Clean: secret (combat) or none gives nil, and the last colour stays.
local function call(t, name, ...)
	local fn = t and t[name]
	if fn then return ns.Clean(fn(...)) end
end

local function repColor()
	local d = C_Reputation and C_Reputation.GetWatchedFactionData and C_Reputation.GetWatchedFactionData()
	if not d then return nil end
	local id, reaction = ns.Clean(d.factionID), ns.Clean(d.reaction)
	if not id or id == 0 then return nil end
	local major = call(C_Reputation, "IsMajorFaction", id)
	if major then return token("npc", 0.0, 0.39, 0.88) end
	local friend = C_GossipInfo and C_GossipInfo.GetFriendshipReputation and C_GossipInfo.GetFriendshipReputation(id)
	if friend and (ns.Clean(friend.friendshipFactionID) or 0) > 0 then return Theme.Color("success") end
	if not reaction then return nil end
	if reaction <= 3 then return Theme.Color("danger") end
	if reaction == 4 then return Theme.Color("warning") end
	return Theme.Color("success")
end

-- A bar kind's fill colour (StatusTrackingBarInfo.BarsEnum), each the game's
-- meaning in the player's theme. Experience: Polestar's blue, the HUD's
-- default fill as on the unit frames (H.FillColor: the header band's sky, or
-- the class colour with Polestar's "Class colour"), the same whether rested
-- or not (the rested preview says that). Reputation: repColor. Honor (the game's orange-red fill) in
-- the warm `place`; artifact, azerite and house favour (the game's one
-- artifact-power gold, ArtifactBar.lua, AzeriteBar.lua, HouseFavorBar.lua) in
-- `quest` gold. A token a scheme lacks: the game's hue calmed (token).
local function fillColor(kind)
	if kind == REP then return repColor() end
	if kind == HONOR then return token("place", 0.9, 0.4, 0.1) end
	if kind == ARTIFACT or kind == AZERITE or kind == HOUSE then return token("quest", 0.9, 0.8, 0.5) end
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
	l = { box = box, sb = sb, track = tex(box, "BACKGROUND"), edges = ns.Hairlines(box, box), shadow = H.Shadow(box, box, 8), ticks = {} }
	l.track:SetAllPoints(box)
	-- The fill, its stars and the previews inside the outline: on a frame
	-- (art, as wide as the bar) in a frame clipped to the box less the
	-- outline's inner pixel (inner, set in paint), so the outline shows
	-- unbroken at 0% and 100% too. The ticks and marks over them (over).
	l.inner = CreateFrame("Frame", nil, box)
	l.inner:SetClipsChildren(true)
	l.art = CreateFrame("Frame", nil, l.inner)
	l.art:SetAllPoints(box)
	l.fill = tex(l.art, "ARTWORK")
	l.over = CreateFrame("Frame", nil, box)
	l.over:SetAllPoints(box)
	l.over:SetFrameLevel(box:GetFrameLevel() + 6)
	l.tint = tex(box, "BACKGROUND", 2)
	l.tint:SetAllPoints(box)
	-- Rested experience (ExpStatusBarTemplate's ExhaustionLevelFillBar, the
	-- game's prediction from the bar's left to the experience plus the rest,
	-- sized and shown by its ExhaustionTick): ours from our fill's end to its
	-- right edge, the bar's full height, a hairline at its end where the
	-- game's pip was (the pip's art faded, its mouse and tooltip the game's).
	local rested = rawget(bar, "ExhaustionLevelFillBar")
	if rested and rested.GetObjectType then
		l.rested = rested
		l.rest = tex(l.art, "ARTWORK", -1)
		l.rest:SetPoint("TOPLEFT", sb:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
		l.rest:SetPoint("BOTTOMLEFT", sb:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
		l.rest:SetPoint("RIGHT", rested, "RIGHT", 0, 0)
		l.restEdge = tex(l.art, "OVERLAY", 5)
		l.restEdge:SetPoint("TOPRIGHT", l.rest, "TOPRIGHT", 0, 0)
		l.restEdge:SetPoint("BOTTOMRIGHT", l.rest, "BOTTOMRIGHT", 0, 0)
		l.restTop = tex(l.art, "OVERLAY", 5)
		l.restTop:SetPoint("TOPLEFT", l.rest, "TOPLEFT", 0, 0)
		l.restTop:SetPoint("TOPRIGHT", l.rest, "TOPRIGHT", 0, 0)
	end
	-- The game's pips (the rest's ExhaustionTick; the artifact bar's Tick, at
	-- the power for the next trait): their art faded, their mouse and tooltip
	-- the game's. The artifact's marked by a hairline of ours on it, the bar's
	-- height less 2 each side, shown while the game shows its pip.
	l.pip = {}
	for _, k in ipairs({ "ExhaustionTick", "Tick" }) do
		local tick = rawget(bar, k)
		if tick and tick.GetObjectType then
			for _, t in ipairs({ rawget(tick, "Normal") or tick:GetNormalTexture(), rawget(tick, "Highlight") or tick:GetHighlightTexture() }) do
				l.pip[#l.pip + 1] = t
			end
			if k == "Tick" then
				l.mark = tex(l.over, "OVERLAY", 5)
				l.mark:SetPoint("TOP", tick, "CENTER", 0, 5)
				l.mark:SetPoint("BOTTOM", tick, "CENTER", 0, -5)
				l.markOf = tick
			end
		end
	end
	if rawget(bar, "barIndex") == XP or rawget(bar, "isExpBar") then
		l.clip = CreateFrame("Frame", nil, l.art)
		l.clip:SetClipsChildren(true)
		local holder = CreateFrame("Frame", nil, l.clip)
		holder:SetAllPoints(box)
		l.stars = holder:CreateTexture(nil, "ARTWORK")
		l.stars:SetAllPoints(holder)
		-- Edit Mode's Size (a drag while it is open): cropped again, as ns.Compact does.
		box:SetScript("OnSizeChanged", function() l.crop(bar) end)
	end
	-- The band at 1:1 on the bar (Theme.BandCoords), from the bar's own size:
	-- set by Edit Mode, read only out of combat and never while secret (rule 3).
	function l.crop(b)
		if not l.stars or InCombatLockdown() then return end
		local w, h = b:GetSize()
		if not (ns.Clean(w) and ns.Clean(h)) or w <= 0 or h <= 0 then return end
		l.stars:SetTexCoord(Theme.BandCoords(w, h, STARS_Y))
	end
	looks[bar] = l
	-- Painted in the frame the game shows the bar (its first show after login too).
	bar:HookScript("OnShow", function() if ns.Enabled(KEY) then paint(c, kind, bar, l) end end)
	-- A left-click on the reputation bar opens our Character window on its
	-- Reputation page (the stock bar takes the mouse for its text and tooltip
	-- but has no click: StatusTrackingBarTemplate, ReputationBar.xml). Our
	-- window's own toggle, as its key door calls it: no stock window shown
	-- from our code (CLIENT.md rule 8), so with our Character window off the
	-- click does nothing. A script hook (HookScript), no key written.
	if kind == REP then
		bar:HookScript("OnMouseUp", function(_, button)
			local ch = ns.modules.character
			if button ~= "LeftButton" or not (ns.Enabled(KEY) and ch and ch.Toggle and ns.Enabled("character")) then return end
			ch.Toggle("ReputationFrame")
		end)
	end
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
	if l.clip then
		l.clip:ClearAllPoints()
		l.clip:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, 0)
		l.clip:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 0)
	end
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
			local t = tex(l.over, "OVERLAY", 6)
			t:SetPoint("TOP", d, "TOP", 0, 0)
			t:SetPoint("BOTTOM", d, "BOTTOM", 0, 0)
			l.ticks[d] = t
		end
	end
	for d, t in pairs(l.ticks) do
		t:SetShown(live[d] == true and d:IsShown())
		t:SetWidth(px)
			t:SetVertexColor(r, g, b, math.max(a or 1, TICK_MIN))
	end
end

-- The game's prediction and pip faded; ours shown while the game's prediction
-- is (it hides it with no rest, at the maximum level, XP off).
local function paintRest(l, on)
	for _, t in ipairs(l.pip) do t:SetAlpha(on and 0 or 1) end
	if l.mark then
		l.mark:SetShown(on and l.markOf:IsShown())
		local r, g, b = Theme.Accent()
		l.mark:SetVertexColor(r, g, b, 1)
		l.mark:SetWidth(Theme.Pixel(l.box) * 2)
	end
	if not l.rest then return end
	l.rested:SetAlpha(on and 0 or 1)
	local shown = on and l.rested:IsShown()
	l.rest:SetShown(shown)
	l.restEdge:SetShown(shown)
	l.restTop:SetShown(shown)
	if not shown then return end
	local r, g, b = token("dungeon", 0.58, 0.0, 0.55)
	local px = Theme.Pixel(l.box)
	l.rest:SetVertexColor(r, g, b, REST_ALPHA)
	l.restEdge:SetVertexColor(r, g, b, 1)
	l.restEdge:SetWidth(px)
	l.restTop:SetVertexColor(r, g, b, 1)
	l.restTop:SetHeight(px)
end

function paint(c, kind, bar, l)
	hang(l)
	for _, k in ipairs(FADED) do
		local t = rawget(l.sb, k)
		if t then t:SetAlpha(0) end
	end
	H.Face(rawget(rawget(bar, "OverlayFrame") or {}, "Text"), "number", true)
	local r, g, b = Theme.Color("bg")
	if kind == XP then
		r, g, b = Theme.Color("shade")
		l.track:SetVertexColor(r, g, b, XP_TRACK)
	else
		l.track:SetVertexColor(r, g, b, H.GroundAlpha())
	end
	l.fill:SetTexture(H.FillTexture())
	if l.stars then
		l.stars:SetTexture(Theme.SkinMedia("bandStars") or Theme.Media("band-stars"))
		local sr, sg, sb, sa = Theme.Color("star")
		l.stars:SetVertexColor(sr, sg, sb, (sa or 1) * STAR_OVER)
		l.clip:SetShown(Theme.ShowsBand())
	end
	r, g, b = fillColor(kind)
	if r then l.color = { r, g, b } elseif not l.color then l.color = { H.FillColor("player") } end
	l.fill:SetVertexColor(l.color[1], l.color[2], l.color[3], 1)
	l.tint:SetShown(kind == REP)
	l.tint:SetVertexColor(l.color[1], l.color[2], l.color[3], TINT_ALPHA)
	local shown, er, eg, eb, ea, en = H.Edge()
	ns.PaintHairlines(l.edges, shown, er, eg, eb, math.max(ea or 1, EDGE_MIN), en)
	-- The outline's first pixel lies inside the box, the rest outward
	-- (ns.PaintHairlines): the fill and previews stop one pixel in.
	local d = shown and Theme.Pixel(l.box) or 0
	l.inner:ClearAllPoints()
	l.inner:SetPoint("TOPLEFT", l.box, "TOPLEFT", d, -d)
	l.inner:SetPoint("BOTTOMRIGHT", l.box, "BOTTOMRIGHT", -d, d)
	if l.restTop then
		-- Its top line just under the clip's edge (the segment's own top is clipped off).
		l.restTop:ClearAllPoints()
		l.restTop:SetPoint("TOPLEFT", l.rest, "TOPLEFT", 0, -d)
		l.restTop:SetPoint("TOPRIGHT", l.rest, "TOPRIGHT", 0, -d)
	end
	H.PaintShadow(l.shadow, true)
	paintTicks(c, l)
	paintRest(l, true)
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
	paintRest(l, false)
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
		paintRest(l, true)
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

-- Polestar's "Completed quest XP" (Polestar 0.4.2's QoL/QuestXP.lua, option
-- qol.questXPOverlay): a frame of Polestar's under the game's XP bar, over
-- its StatusBar, with a sage band from the XP fill to the XP the quests
-- ready to hand in will give (masked by the game's fill atlas, inset 2),
-- a copy of the game's pip on the rest tick, and "+1 level". Drawn for the
-- game's bar, it sat over ours in the game's look. While ours is on: its
-- band emptied (SetTexture(nil): a SetAlpha(0) did not hold in game) and ours drawn on the same span at the bar's full inner
-- height, flat, in success (the quest XP Polestar shows in sage, apart from
-- our violet fill and rested blue) at QUEST_ALPHA; its pip copy faded; its
-- label in Polestar's label face, outlined, in success. Off: all of it
-- Polestar's again. Polestar's draw routine is local; every draw ends its
-- band with Tint:SetShown, so ours follows a post-hook on that (on
-- Polestar's own texture, no frame of the game's touched). The frame is
-- made on Polestar's first refresh with quest XP, after ours enables: a
-- post-hook on QoL.XPMark.Bar (which each refresh calls first) looks for it
-- the next frame, until it exists. Without QuestXP (Polestar 0.4.0): nothing.
local QUEST_ALPHA = 0.4
local quest = {}

local function questFrame()
	local q = Polestar.QoL and Polestar.QoL.QuestXP
	local f = q and rawget(q, "frame")
	if f and rawget(f, "Tint") then return f end
end

local function paintQuest()
	local f = quest.band and questFrame()
	if not f then return end
	local on = started and ns.Enabled(KEY)
	-- Emptied, not faded: in game its alpha read 1 again after our SetAlpha(0)
	-- (probe: hook in place, Tint shown at 1, Rested at our 0; Polestar's
	-- source sets none). Polestar sets its texture only once, as it makes it,
	-- so an emptied band stays empty; given back with the texture read then.
	if on then
		if f.Tint:GetTexture() ~= nil then f.Tint:SetTexture(nil) end
	elseif quest.tintTex and f.Tint:GetTexture() == nil then
		f.Tint:SetTexture(quest.tintTex)
	end
	local shown = on and f.Tint:IsShown()
	local r, g, b = Theme.Color("success")
	local px = Theme.Pixel(f)
	quest.band:SetShown(shown)
	quest.band:SetVertexColor(r, g, b, QUEST_ALPHA)
	for _, t in ipairs({ quest.bottom, quest.edge }) do
		t:SetShown(shown)
		t:SetVertexColor(r, g, b, 1)
	end
	quest.bottom:SetHeight(px)
	quest.edge:SetWidth(px)
	-- Inside our outline's inner pixel, as our fill (Polestar's band: from
	-- y = inset - 0.5, its height less 2 * inset; inset 2; its right end
	-- already 2 in).
	local d = H.Edge() and px or 0
	quest.band:ClearAllPoints()
	quest.band:SetPoint("TOPLEFT", f.Tint, "TOPLEFT", 0, 2.5 - d)
	quest.band:SetPoint("BOTTOMRIGHT", f.Tint, "BOTTOMRIGHT", 0, -1.5 + d)
	local pip, label = rawget(f, "Rested"), rawget(f, "LevelLabel")
	if pip then pip:SetAlpha(on and 0 or 1) end
	if label then
		H.Face(label, "label", on)
		if on then label:SetTextColor(r, g, b, 1) elseif quest.labelColor then label:SetTextColor(unpack(quest.labelColor)) end
	end
end

local function hookQuest()
	local f = questFrame()
	if not f or quest.band then return end
	quest.band = f:CreateTexture(nil, "OVERLAY")
	quest.band:SetTexture(Theme.Media("white"))
	-- Polestar's band: from y = inset - 0.5 up, the frame's height less 2 * inset (inset 2).
	-- shortcut: its inset (2, on a bar 8 or more high) undone by constants; upgrade if Polestar's draw changes it.
	quest.band:SetPoint("TOPLEFT", f.Tint, "TOPLEFT", 0, 2.5)
	quest.band:SetPoint("BOTTOMRIGHT", f.Tint, "BOTTOMRIGHT", 0, -1.5)
	quest.bottom = f:CreateTexture(nil, "OVERLAY", nil, 1)
	quest.bottom:SetTexture(Theme.Media("white"))
	quest.bottom:SetPoint("BOTTOMLEFT", quest.band, "BOTTOMLEFT", 0, 0)
	quest.bottom:SetPoint("BOTTOMRIGHT", quest.band, "BOTTOMRIGHT", 0, 0)
	quest.edge = f:CreateTexture(nil, "OVERLAY", nil, 1)
	quest.edge:SetTexture(Theme.Media("white"))
	quest.edge:SetPoint("TOPRIGHT", quest.band, "TOPRIGHT", 0, 0)
	quest.edge:SetPoint("BOTTOMRIGHT", quest.band, "BOTTOMRIGHT", 0, 0)
	local label = rawget(f, "LevelLabel")
	quest.labelColor = label and { label:GetTextColor() }
	quest.tintTex = f.Tint:GetTexture()
	hooksecurefunc(f.Tint, "SetShown", paintQuest)
	paintQuest()
end

local function watchQuest()
	local qol = Polestar.QoL
	if quest.watching or not (qol and qol.QuestXP and qol.XPMark and qol.XPMark.Bar) then return end
	quest.watching = true
	hooksecurefunc(qol.XPMark, "Bar", function()
		if not quest.band then C_Timer.After(0, hookQuest) end
	end)
	hookQuest()
end

function M.Apply()
	if not started then return end
	paintQuest()
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
	watchQuest()
	M.Apply()
end

ns.Module(KEY, M)
