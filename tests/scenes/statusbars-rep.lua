--@ title: Experience and reputation bars: reputation (renown, friendship, paragon, none, combat, max level, the click)
--@ roots: MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer
--@ stubs: stub_statusbars.lua
-- The reputation bar's fill and its track's tint take the watched faction's meaning, as ReputationStatusBarMixin:Update picks its atlas: renown and a major faction's paragon in the game's blue (npc, its rested blue), a friendship green whatever its reaction, a normal faction's paragon by its reaction (exalted: green). Watching none hides the bar (the game's container); watching one again shows it dressed at once, in its colour, the game's art faded. In combat the standing comes secret: the last colour stays, no error. At the maximum level the experience bar goes and the reputation bar takes the main container. A left-click on it opens our Character window on Reputation (not with our Character window off, nor a right-click). Shown: the main container at the maximum level, a renown faction.
-- Every region (and frame) of f and its descendants: ours are spread over a few frames.
local function regionsOf(f, out)
	out = out or {}
	for _, r in ipairs({ f:GetRegions() }) do out[#out + 1] = r end
	for _, c in ipairs({ f:GetChildren() }) do regionsOf(c, out) end
	return out
end
local function framesOf(f, out)
	out = out or {}
	for _, c in ipairs({ f:GetChildren() }) do out[#out + 1] = c; framesOf(c, out) end
	return out
end
local T = Polestar.Theme
local Main, Second = MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer
local REP = 1
local function ours(bar)
	for _, f in ipairs({ bar:GetChildren() }) do
		if f ~= bar.StatusBar and f ~= bar.OverlayFrame and f ~= rawget(bar, "ExhaustionTick") and f ~= rawget(bar, "Tick") then return f end
	end
end
local function fillOf(bar)
	for _, r in ipairs(regionsOf(ours(bar))) do
		if r.points[1] and r.points[1].rel == bar.StatusBar:GetStatusBarTexture() then return r end
	end
end
local function tintOf(bar)
	for _, r in ipairs(regionsOf(ours(bar))) do
		local l, sub = r:GetDrawLayer()
		if l == "BACKGROUND" and sub == 2 then return r end
	end
end
local function near(a, b) return math.abs(a - b) < 0.01 end
local function is(bar, token)
	local r, g, b = fillOf(bar):GetVertexColor()
	local tr, tg, tb = T.Color(token)
	local t = tintOf(bar)
	local ar, ag, ab = t:GetVertexColor()
	return near(r, tr) and near(g, tg) and near(b, tb) and near(ar, tr) and near(ag, tg) and near(ab, tb) and t:IsShown()
end
stub.finishStatusFade()
local rep = Second.bars[REP]
stub.watchFaction(8, { name = "Dream Wardens", factionID = 2574, major = true })
assert(is(rep, "npc"), "renown is not the game's blue")
stub.watchFaction(8, { name = "Dream Wardens", factionID = 2574, major = true, paragon = true })
assert(is(rep, "npc"), "a major faction's paragon is not blue")
stub.watchFaction(3, { name = "Lady Grimtotem", factionID = 3001, friend = true })
assert(is(rep, "success"), "a friendship is not green")
stub.watchFaction(8, { name = "Stormwind", factionID = 72, paragon = true })
assert(is(rep, "success"), "a normal faction's paragon is not green")
-- None watched: the game hides the bar; one again: dressed at once.
stub.watchFaction(nil)
stub.showStatusBar(Second, nil)
assert(not ours(rep):IsVisible(), "ours shows with no faction watched")
stub.watchFaction(4, { name = "Ratchet", factionID = 470 })
stub.showStatusBar(Second, REP)
assert(ours(rep):IsVisible() and is(rep, "warning"), "a newly watched neutral faction is not dressed in warning")
assert(Second.BarFrameTexture:GetAlpha() == 0 and rep.StatusBar.Background:GetAlpha() == 0, "the game's art shows on the bar shown again")
-- Combat: the standing comes secret; the colour stays, nothing errors.
stub.inCombat = true
stub.faction.reaction = stub.secret(2)
stub.fire("UPDATE_FACTION")
stub.fire("ZONE_CHANGED")
stub.advance(0.05)
assert(is(rep, "warning"), "a secret standing changed the colour")
stub.inCombat = false
-- The click: our Character window's Reputation page (its own toggle).
local ch = PolestarUI.modules.character
local toggle, got = ch.Toggle, {}
ch.Toggle = function(k) got[#got + 1] = k end
stub.RunScript(rep, "OnMouseUp", "RightButton")
stub.RunScript(rep, "OnMouseUp", "LeftButton")
PolestarUIDB.modules.character = false
stub.RunScript(rep, "OnMouseUp", "LeftButton")
PolestarUIDB.modules.character = nil
ch.Toggle = toggle
assert(#got == 1 and got[1] == "ReputationFrame", "the reputation bar's click")
-- The maximum level: the experience bar gives way, the reputation bar takes the main container.
stub.watchFaction(8, { name = "Dream Wardens", factionID = 2574, major = true })
stub.showStatusBar(Second, nil)
stub.showStatusBar(Main, REP)
stub.finishStatusFade()
local mainRep = Main.bars[REP]
assert(ours(mainRep):IsVisible() and is(mainRep, "npc"), "at the maximum level the main container's reputation bar is not dressed")
assert(not ours(Main.bars[4]):IsVisible(), "the experience bar still shows")
stub.advance(0.1)
