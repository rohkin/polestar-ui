-- The status tracking bars as Forever builds them (Blizzard_StatusTrackingBar:
-- Mainline/StatusTrackingBar.xml, StatusTrackingBarTemplate.xml,
-- StatusTrackingManagerOverrides.lua, ExpBar.xml; Shared/StatusTrackingManager.lua):
-- StatusTrackingBarManager holding MainStatusTrackingBarContainer and
-- SecondaryStatusTrackingBarContainer, both Edit Mode systems (1192 x 17,
-- their frame art BarFrameTexture, 19 pooled dividers with a
-- BarDividerTexture each), each holding one bar of every kind
-- (`container.bars[StatusTrackingBarInfo.BarsEnum]`: all six exist on
-- Forever, seen in game) inset 1 px, 3 px smaller; one shown at a time. A bar:
-- a StatusBar (Background, Underlay, Overlay, the gain flare and level-up
-- flash, its fill) and OverlayFrame.Text (shown with xpBarText or on hover);
-- the experience bar's ExhaustionLevelFillBar and ExhaustionTick. The game's
-- fill atlas is a colour here (purple, rested blue, reputation green).
-- Everything is guarded (stub_editmode.lua).
--
--   stub.showStatusBar(container, kind)   kind nil: none (the container hides)
--   stub.setXP(cur, max)                  then PLAYER_XP_UPDATE
--   stub.setRestState(id)                 1 rested (the game's blue fill), 2 normal; UPDATE_EXHAUSTION
--   stub.setRested(amount)               rested experience (GetXPExhaustion; nil: none), then UPDATE_EXHAUSTION
--   stub.statusBarSize(container, pct)    Edit Mode's Size: the container, its bars and dividers laid again
--   stub.hoverStatusBar(bar, on)          the bar's OnEnter/OnLeave (its text)
--   stub.watchFaction(reaction, o?)      the watched faction (o: name, factionID, major, friend, paragon; nil: none), then UPDATE_FACTION; the rep bar shows in the second container from the start
--   stub.finishStatusFade(c?)          the fade-in (or out) each container plays ends (from login a fade-in plays)
--   stub.fadeOutStatusBar(c)           the game fades a container out (a bar switch)

require("stub_editmode")

local CALLS = stub.SYSTEM_CALLS
local B = stub.Methods
B.SetIgnoreParentAlpha = B.SetIgnoreParentAlpha or function(self, v) self.ignoreParentAlpha = v and true or false end
B.IsIgnoringParentAlpha = B.IsIgnoringParentAlpha or function(self) return self.ignoreParentAlpha == true end
local WIDTH, HEIGHT, SEGMENTS = 1192, 17, 20

local XP_PURPLE, XP_RESTED, REP_GREEN = { 0.58, 0, 0.55 }, { 0, 0.39, 0.88 }, { 0, 0.6, 0.1 }
local KINDS = { Reputation = 1, Honor = 2, Artifact = 3, Experience = 4, Azerite = 5, HouseFavor = 6 }
StatusTrackingBarInfo = { BarsEnum = { None = -1, Reputation = 1, Honor = 2, Artifact = 3, Experience = 4, Azerite = 5, HouseFavor = 6 } }

stub.xp = { cur = 6200, max = 10000, rest = 2 }
function UnitXP() return stub.xp.cur end
function UnitXPMax() return stub.xp.max end
function GetRestState() return stub.xp.rest, stub.xp.rest == 1 and "Rested" or "Normal", stub.xp.rest == 1 and 2 or 1 end
stub.xp.exhaustion = nil -- rested experience (stub.setRested)
function GetXPExhaustion() return stub.xp.exhaustion end
stub.cvars.xpBarText = stub.cvars.xpBarText or "0"

local function color(f, layer, sub, c, a)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetColorTexture(c[1], c[2], c[3], a or 1)
	return t
end

local manager = CreateFrame("Frame", "StatusTrackingBarManager", UIParent)
manager:SetSize(WIDTH, HEIGHT)
manager:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)

local function textShown(bar)
	bar.OverlayFrame.Text:SetShown(stub.cvars.xpBarText == "1" or bar.textLocked == true)
end

local function makeBar(c, kind)
	local bar = CreateFrame("Frame", nil, c)
	bar.barIndex = kind
	bar.isExpBar = kind == KINDS.Experience or nil
	bar:SetFrameStrata("LOW") -- StatusTrackingBarTemplate: LOW, fixed
	-- ExpStatusBarTemplate is useParentLevel; the others a level up (the client's levels, as the stub does not count them).
	bar:SetFrameLevel(c:GetFrameLevel() + (kind == KINDS.Experience and 0 or 1))
	local sb = CreateFrame("StatusBar", nil, bar)
	sb:SetAllPoints(bar)
	sb:SetFrameLevel(bar:GetFrameLevel() + 1)
	sb.Background = color(sb, "BACKGROUND", 0, { 0.1, 0.08, 0.06 })
	sb.Background:SetAllPoints(sb)
	sb.Underlay = color(sb, "BACKGROUND", 1, { 0.5, 0.44, 0.28 })
	sb.Underlay:SetAllPoints(sb)
	sb.Underlay:Hide()
	sb.Overlay = color(sb, "ARTWORK", -1, { 0.9, 0.8, 0.6 })
	sb.Overlay:SetAllPoints(sb)
	sb.Overlay:Hide()
	sb.GainFlareAnimationTexture = color(sb, "ARTWORK", 0, { 1, 1, 1 })
	sb.GainFlareAnimationTexture:Hide()
	sb.LevelUpTexture = color(sb, "ARTWORK", 0, { 1, 1, 1 })
	sb.LevelUpTexture:Hide()
	sb:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
	local c0 = kind == KINDS.Experience and XP_PURPLE or REP_GREEN
	sb:SetStatusBarColor(c0[1], c0[2], c0[3], 1)
	sb:SetMinMaxValues(0, 1)
	sb:SetValue(kind == KINDS.Experience and 0 or 0.4)
	bar.StatusBar = sb
	local over = CreateFrame("Frame", nil, bar)
	over:SetFrameStrata("MEDIUM") -- the template's OverlayFrame: over the bar (and ours)
	over:SetAllPoints(bar)
	over.Text = over:CreateFontString(nil, "OVERLAY")
	over.Text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	over.Text:SetPoint("CENTER", over, "CENTER", 0, 1)
	over.Text:Hide()
	bar.OverlayFrame = over
	if kind == KINDS.Experience then
		bar.ExhaustionLevelFillBar = color(bar, "ARTWORK", -1, XP_RESTED, 0.5)
		bar.ExhaustionLevelFillBar:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
		bar.ExhaustionLevelFillBar:SetSize(0, 11)
		bar.ExhaustionLevelFillBar:Hide()
		local tick = CreateFrame("Button", nil, bar)
		tick:SetFrameStrata("MEDIUM")
		tick:SetSize(10, 14)
		tick.Normal = color(tick, "ARTWORK", 0, { 0.9, 0.75, 0.4 })
		tick.Normal:SetAllPoints(tick)
		tick:SetNormalTexture(tick.Normal)
		tick.Highlight = color(tick, "HIGHLIGHT", 0, { 1, 1, 1 }, 0.5)
		tick.Highlight:SetAllPoints(tick)
		tick:SetHighlightTexture(tick.Highlight)
		tick:Hide()
		bar.ExhaustionTick = tick
	end
	if kind == KINDS.Artifact then
		-- ArtifactStatusBarTemplate's Tick (ArtifactTickMixin: the power for the next trait).
		local tick = CreateFrame("Button", nil, bar)
		tick:SetFrameStrata("MEDIUM")
		tick:SetSize(10, 14)
		tick.Normal = color(tick, "ARTWORK", 0, { 0.9, 0.75, 0.4 })
		tick.Normal:SetAllPoints(tick)
		tick:SetNormalTexture(tick.Normal)
		tick.Highlight = color(tick, "HIGHLIGHT", 0, { 1, 1, 1 }, 0.5)
		tick.Highlight:SetAllPoints(tick)
		tick:SetHighlightTexture(tick.Highlight)
		tick:SetPoint("CENTER", bar, "LEFT", 600, 0)
		bar.Tick = tick
	end
	bar:Hide()
	return bar
end

-- StatusTrackingBarContainerMixin:UpdateDividers: released and acquired
-- again with each layout change; a reused divider keeps its alpha.
local function pool(c)
	-- `order`: the stub enumerates in acquisition order, so goldens are stable
	-- (the client's pool walks its table with pairs).
	local p = { activeObjects = {}, free = {}, order = {} }
	function p:EnumerateActive()
		local i = 0
		return function()
			i = i + 1
			local d = self.order[i]
			if d then return d, true end
		end
	end
	function p:ReleaseAll()
		for _, d in ipairs(self.order) do d:Hide(); d:ClearAllPoints(); self.free[#self.free + 1] = d end
		self.activeObjects, self.order = {}, {}
	end
	function p:Acquire()
		local d = table.remove(self.free)
		if not d then
			d = CreateFrame("Frame", nil, c)
			d:SetSize(3, 10)
			d.BarDividerTexture = color(d, "OVERLAY", 0, { 0.55, 0.45, 0.25 })
			d.BarDividerTexture:SetAllPoints(d)
			stub.guard(d.BarDividerTexture, nil, "a status bar divider's texture")
		end
		self.activeObjects[d] = true
		self.order[#self.order + 1] = d
		d:Show()
		return d
	end
	return p
end

local function layout(c)
	local w, h = c:GetWidth(), c:GetHeight()
	for _, bar in pairs(c.bars) do
		bar:ClearAllPoints()
		bar:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 1, 2)
		bar:SetSize(w - 3, h - 3)
	end
	c.HorizontalDividersPool:ReleaseAll()
	for i = 1, SEGMENTS - 1 do
		local d = c.HorizontalDividersPool:Acquire()
		d:SetPoint("LEFT", c, "LEFT", w / SEGMENTS * i, 0)
	end
end

local containers = {}
local function container(name, y)
	local c = CreateFrame("Frame", name, manager)
	c:SetSize(WIDTH, HEIGHT)
	c:SetPoint("BOTTOM", manager, "BOTTOM", 0, y)
	c.BarFrameTexture = color(c, "OVERLAY", 0, { 0.45, 0.36, 0.2 })
	c.BarFrameTexture:SetPoint("TOPLEFT", c, "TOPLEFT", -2, 2)
	c.BarFrameTexture:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", 2, -2)
	c.bars = {}
	for kind = 1, 6 do c.bars[kind] = makeBar(c, kind) end
	c.HorizontalDividersPool = pool(c)
	c.shownBarIndex = -1
	-- StatusTrackingBarContainerTemplate's fades (Alpha on the container,
	-- setToFinalAlpha): played until stub.finishStatusFade (the client took
	-- 5 to 8 s for the fade-in after login, the loading screen's time counted).
	for _, k in ipairs({ "FadeInAnimation", "FadeOutAnimation", "MaxLevelFadeOutAnimation" }) do
		local g = c:CreateAnimationGroup()
		g.toAlpha = k == "FadeInAnimation" and 1 or 0
		local function play(self)
			self.playing = true
			stub.RunScript(self, "OnPlay")
		end
		rawset(g, "Play", play)
		rawset(g, "Restart", play)
		c[k] = g
	end
	layout(c)
	c:Hide()
	containers[#containers + 1] = c
	stub.secureNames[name] = true
	return c
end
container("MainStatusTrackingBarContainer", 0)
container("SecondaryStatusTrackingBarContainer", HEIGHT)

local function setXPBar(bar)
	local sb = bar.StatusBar
	sb:SetMinMaxValues(0, stub.xp.max)
	sb:SetValue(stub.xp.cur)
	local c = stub.xp.rest == 1 and XP_RESTED or XP_PURPLE
	-- ExpBarMixin:UpdateStatusBarTextures: a new atlas on the same fill.
	sb:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
	sb:SetStatusBarColor(c[1], c[2], c[3], 1)
	bar.OverlayFrame.Text:SetText(("XP: %d/%d"):format(stub.xp.cur, stub.xp.max))
end

-- The live client's StatusTrackingManagerMixin:UpdateBarVisuals (not in .ref;
-- seen in game): the end of every UpdateBarsShown sets the frame art, the
-- dividers, and the shown bar's ground and fill back to full alpha. It runs
-- on the manager's events (its frame registered before ours: first) and when
-- a container's fade-in ends (the game's OnFinished, before any hook).
stub.visualsUpdated = 0
local function updateBarVisuals()
	stub.visualsUpdated = stub.visualsUpdated + 1
	for _, c in ipairs(containers) do
		c.BarFrameTexture:SetAlpha(1)
		for d in c.HorizontalDividersPool:EnumerateActive() do d.BarDividerTexture:SetAlpha(1) end
		local bar = c.bars[c.shownBarIndex]
		if bar then
			bar.StatusBar.Background:SetAlpha(1)
			bar.StatusBar:GetStatusBarTexture():SetAlpha(1)
		end
	end
end
for _, c in ipairs(containers) do c.FadeInAnimation:SetScript("OnFinished", updateBarVisuals) end
for _, e in ipairs({ "UPDATE_FACTION", "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD", "CVAR_UPDATE", "PLAYER_XP_UPDATE" }) do
	manager:RegisterEvent(e)
end
manager:SetScript("OnEvent", updateBarVisuals)

-- The watched faction (C_Reputation.GetWatchedFactionData): reaction 1-8.
-- The reputation bar's colour is deferred (ReputationStatusBarMixin:
-- UpdateBarTextures, deferUntilNextLevel): the StatusBar's own OnUpdate
-- applies it 0.1 s later (GradualAnimatedStatusBarMixin: OnUpdate,
-- ProcessChanges, ApplyPendingTextures), with no event. As the client
-- may, the new texture comes back at full alpha (the look seen after login).
stub.faction = { name = "Stormwind", factionID = 72, reaction = 5, currentReactionThreshold = 3000, nextReactionThreshold = 9000, currentStanding = 5400 }
C_Reputation = C_Reputation or {}
C_Reputation.GetWatchedFactionData = function() return stub.faction end
-- A renown faction (major), a friendship (friend); the paragon of either.
C_Reputation.IsMajorFaction = function(id) return stub.faction and stub.faction.factionID == id and stub.faction.major == true end
C_Reputation.IsFactionParagonForCurrentPlayer = function(id) return stub.faction and stub.faction.factionID == id and stub.faction.paragon == true end
C_GossipInfo = C_GossipInfo or {}
local friendship = C_GossipInfo.GetFriendshipReputation
C_GossipInfo.GetFriendshipReputation = function(id)
	if stub.faction and stub.faction.factionID == id then return { friendshipFactionID = stub.faction.friend and id or 0 } end
	if friendship then return friendship(id) end
	return { friendshipFactionID = 0 }
end
local REACTION = { [1] = { 0.8, 0.13, 0.13 }, [2] = { 0.8, 0.13, 0.13 }, [3] = { 0.75, 0.27, 0 }, [4] = { 0.9, 0.7, 0 } }
local function setRepBar(bar)
	local sb, f = bar.StatusBar, stub.faction
	if not f then return end
	sb:SetMinMaxValues(0, f.nextReactionThreshold - f.currentReactionThreshold)
	sb:SetValue(f.currentStanding - f.currentReactionThreshold)
	bar.OverlayFrame.Text:SetText(("%s %d / %d"):format(f.name, f.currentStanding - f.currentReactionThreshold, f.nextReactionThreshold - f.currentReactionThreshold))
	sb.pendingBarTexture, sb.pendingWait = (not (f.major or f.friend) and REACTION[stub.reveal(f.reaction)]) or (f.major and XP_RESTED) or REP_GREEN, 0.1
end
local function applyPending(sb, elapsed)
	if not sb.pendingBarTexture then return end
	sb.pendingWait = sb.pendingWait - elapsed
	if sb.pendingWait > 0 then return end
	local c = sb.pendingBarTexture
	sb.pendingBarTexture = nil
	sb:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
	sb:SetStatusBarColor(c[1], c[2], c[3], 1)
	sb:GetStatusBarTexture():SetAlpha(1)
end
for _, c in ipairs(containers) do c.bars[KINDS.Reputation].StatusBar:SetScript("OnUpdate", applyPending) end

-- StatusTrackingBarContainerMixin:ApplyPendingBarToShow, UpdateShownState and FadeIn:
-- a container not shown yet starts at alpha 0 and fades in (until stub.finishStatusFade).
function stub.showStatusBar(c, kind)
	local old = c.bars[c.shownBarIndex]
	if old then old:Hide() end
	local bar = kind and c.bars[kind]
	c.shownBarIndex = kind or -1
	if bar then
		if kind == KINDS.Experience then setXPBar(bar) end
		if kind == KINDS.Reputation then setRepBar(bar) end
		textShown(bar)
		bar:Show()
	end
	local fresh = not c:IsShown()
	c:SetShown(bar ~= nil)
	if bar and fresh then
		c:SetAlpha(0)
		c.FadeInAnimation:Restart()
	end
end

-- The fades running on  (every container's when nil) end at their final alpha.
function stub.finishStatusFade(c)
	for _, cc in ipairs(c and { c } or containers) do
		for _, k in ipairs({ "FadeInAnimation", "FadeOutAnimation", "MaxLevelFadeOutAnimation" }) do
			local g = cc[k]
			if g.playing then
				g.playing = false
				cc:SetAlpha(g.toAlpha)
				stub.RunScript(g, "OnFinished")
			end
		end
	end
end
-- StatusTrackingBarContainerMixin:FadeOut (a bar switch): the fade-in stopped, the fade-out played.
function stub.fadeOutStatusBar(c)
	if c.FadeInAnimation.playing then c.FadeInAnimation:Stop() end
	c.FadeOutAnimation:Play()
end

local function xpBars(fn)
	for _, c in ipairs(containers) do fn(c.bars[KINDS.Experience]) end
end
function stub.setXP(cur, max)
	stub.xp.cur, stub.xp.max = cur, max or stub.xp.max
	xpBars(setXPBar)
	stub.fire("PLAYER_XP_UPDATE", "player")
end
-- ExhaustionTickMixin:UpdateTickPosition (its frame registered before ours):
-- the prediction from the bar's left to the experience plus the rest
-- (clamped to the bar), shown with rest below the maximum level; the pip at its end.
local function updateTick(bar)
	local fillBar, tick = bar.ExhaustionLevelFillBar, bar.ExhaustionTick
	local rest = stub.xp.exhaustion
	if not rest or rest <= 0 then
		tick:Hide()
		fillBar:Hide()
		return
	end
	local w = bar:GetWidth()
	local x = math.max(0, math.min(1, (stub.xp.cur + rest) / stub.xp.max)) * w
	fillBar:SetWidth(x)
	fillBar:Show()
	tick:ClearAllPoints()
	tick:SetPoint("CENTER", bar, "LEFT", x, 0)
	tick:Show()
end
local tickEvents = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_XP_UPDATE", "UPDATE_EXHAUSTION", "PLAYER_LEVEL_UP", "PLAYER_ENTERING_WORLD" }) do tickEvents:RegisterEvent(e) end
tickEvents:SetScript("OnEvent", function() xpBars(updateTick) end)
function stub.setRested(amount)
	stub.xp.exhaustion = amount
	stub.fire("UPDATE_EXHAUSTION")
end

function stub.setRestState(id)
	stub.xp.rest = id
	xpBars(setXPBar)
	stub.fire("UPDATE_EXHAUSTION")
end
function stub.statusBarSize(c, pct)
	c:SetSize(WIDTH * pct / 100, HEIGHT)
	layout(c)
	stub.fire("EDIT_MODE_LAYOUTS_UPDATED")
end
-- StatusTrackingBarMixin:ShowText/HideText (OnEnter/OnLeave).
function stub.hoverStatusBar(bar, on)
	bar.textLocked = on
	textShown(bar)
end
local setCVar = stub.setCVar
function stub.setCVar(cvar, value)
	if cvar == "xpBarText" then
		stub.cvars.xpBarText = value
		for _, c in ipairs(containers) do
			for _, bar in pairs(c.bars) do textShown(bar) end
		end
	end
	return setCVar(cvar, value)
end

-- A watched faction: the reputation bar in the second container (Edit Mode's "Show status bar 2").
-- watchFaction(reaction, o): o = { name, factionID, major, friend, paragon };
-- watchFaction(nil): no faction watched (the scene hides the rep bar's container).
function stub.watchFaction(reaction, o)
	if reaction == nil and o == nil then
		stub.faction = nil
		stub.fire("UPDATE_FACTION")
		return
	end
	stub.faction = stub.faction or { name = "Stormwind", factionID = 72, currentReactionThreshold = 3000, nextReactionThreshold = 9000, currentStanding = 5400 }
	local f = stub.faction
	f.reaction = reaction
	o = o or {}
	f.name, f.factionID = o.name or f.name, o.factionID or f.factionID
	f.major, f.friend, f.paragon = o.major, o.friend, o.paragon
	for _, c in ipairs(containers) do setRepBar(c.bars[KINDS.Reputation]) end
	stub.fire("UPDATE_FACTION")
end
stub.showStatusBar(MainStatusTrackingBarContainer, KINDS.Experience)
stub.showStatusBar(SecondaryStatusTrackingBarContainer, KINDS.Reputation)

for _, c in ipairs(containers) do
	for _, bar in pairs(c.bars) do
		local sb = bar.StatusBar
		for _, k in ipairs({ "Background", "Underlay", "Overlay", "GainFlareAnimationTexture", "LevelUpTexture" }) do stub.guard(sb[k], nil, "a status bar's " .. k) end
		stub.guard(sb:GetStatusBarTexture(), nil, "a status bar's fill")
		stub.guard(bar.OverlayFrame.Text, nil, "a status bar's text")
		stub.guard(bar.OverlayFrame, CALLS, "a status bar's OverlayFrame")
		if rawget(bar, "ExhaustionLevelFillBar") then
			stub.guard(bar.ExhaustionLevelFillBar, nil, "ExhaustionLevelFillBar")
			stub.guard(bar.ExhaustionTick, CALLS, "ExhaustionTick")
			stub.guard(bar.ExhaustionTick.Normal, nil, "ExhaustionTick.Normal")
			stub.guard(bar.ExhaustionTick.Highlight, nil, "ExhaustionTick.Highlight")
		end
		if rawget(bar, "Tick") then
			stub.guard(bar.Tick, CALLS, "the artifact bar's Tick")
			stub.guard(bar.Tick.Normal, nil, "Tick.Normal")
			stub.guard(bar.Tick.Highlight, nil, "Tick.Highlight")
		end
		stub.guard(sb, CALLS, "a status bar's StatusBar")
		stub.guard(bar, CALLS, "a status tracking bar")
	end
	stub.guard(c.BarFrameTexture, nil, c:GetName() .. ".BarFrameTexture")
	for d in c.HorizontalDividersPool:EnumerateActive() do stub.guard(d, CALLS, "a status bar divider") end
	stub.guard(c, CALLS)
end
stub.guard(StatusTrackingBarManager, CALLS)
