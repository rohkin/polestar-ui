--@ title: Experience and reputation bars
--@ roots: MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer
--@ stubs: stub_statusbars.lua
-- The game's status tracking bars restyled in place: the experience bar (62%) in the main container, a reputation bar in the second (Edit Mode's "Show status bar 2"), the game's xpBarText option on. After login the game fades each container in from alpha 0 (5 to 8 s in the client): ours shows at once and follows the container again once the fade-in ends (and through a fade-out). The game's ground, fill, frame art and dividers faded where they are; under each bar a frame of ours: a track, a fill hung on the game's fill (so it follows the value with nothing read), a 1px hairline, a hairline tick on each of the 19 dividers. The experience fill is the scheme's violet, the mana blue while rested (the game's blue fill); the reputation bar by the watched faction's standing (friendly: success green), its track tinted in it at 30%. The experience bar's track wears Polestar's header band (the sky and its stars, Theme.Band) at 70%, cropped 1:1 to the thin bar from the band's middle rows; the ticks at half the edge's alpha. The text keeps its size in Polestar's number face, outlined. Every other kind of bar is dressed too, hidden with it.
local T = Polestar.Theme
local Main, Second = MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer
local XP, REP = 4, 1
local function ours(bar)
	for _, f in ipairs({ bar:GetChildren() }) do
		if f ~= bar.StatusBar and f ~= bar.OverlayFrame and f ~= rawget(bar, "ExhaustionTick") then return f end
	end
end
local function fillOf(bar)
	for _, r in ipairs({ ours(bar):GetRegions() }) do
		if r.points[1] and r.points[1].rel == bar.StatusBar:GetStatusBarTexture() then return r end
	end
end
local function ticks(bar)
	local n = 0
	for _, r in ipairs({ ours(bar):GetRegions() }) do
		local p = r.points[1]
		if p and p.rel and Main.HorizontalDividersPool.activeObjects[p.rel] and r:IsShown() then n = n + 1 end
	end
	return n
end
local function near(a, b) return math.abs(a - b) < 0.01 end
-- Straight after login, no event fired: the reputation bar (shown by the game
-- before we enable) is dressed, in the success green of a friendly faction,
-- and stays ours after the game's own OnUpdate sets its fill again at full
-- alpha (no event): ours is a level over the game's StatusBar.
local rep = Second.bars[REP]
local function color(bar) local r, g, b = fillOf(bar):GetVertexColor(); return r, g, b end
local function is(bar, token)
	local r, g, b = color(bar)
	local tr, tg, tb = T.Color(token)
	return near(r, tr) and near(g, tg) and near(b, tb)
end
assert(ours(rep):IsVisible() and fillOf(rep):IsShown(), "the reputation bar is not dressed after login")
-- The game fades each container in from alpha 0 (5 to 8 s after login in the client): ours
-- shows at once, ignoring the container's alpha while the fade-in plays, and follows it again after.
for _, c in ipairs({ Main, Second }) do
	local bar = c.bars[c.shownBarIndex]
	assert(c:GetAlpha() == 0 and c.FadeInAnimation:IsPlaying(), "the stub's fade-in is not playing")
	assert(ours(bar):IsIgnoringParentAlpha(), c:GetName() .. ": ours waits for the game's fade-in")
end
stub.finishStatusFade()
for _, c in ipairs({ Main, Second }) do
	assert(c:GetAlpha() == 1 and not ours(c.bars[c.shownBarIndex]):IsIgnoringParentAlpha(), c:GetName() .. ": ours does not follow the container after its fade-in")
end
-- The live client sets the game's art back to full alpha at the end of each
-- UpdateBarsShown (its UpdateBarVisuals): when a fade-in ends, and on the
-- manager's events. Faded again: at once after the fade, the next frame after an event.
local function artFaded()
	for _, c in ipairs({ Main, Second }) do
		if c.BarFrameTexture:GetAlpha() ~= 0 then return false end
		for d in c.HorizontalDividersPool:EnumerateActive() do if d.BarDividerTexture:GetAlpha() ~= 0 then return false end end
		local sb = c.bars[c.shownBarIndex].StatusBar
		if sb.Background:GetAlpha() ~= 0 or sb:GetStatusBarTexture():GetAlpha() ~= 0 then return false end
	end
	return true
end
assert(stub.visualsUpdated > 0 and artFaded(), "the game's art shows after its fade-in ended")
local n = stub.visualsUpdated
stub.fire("ZONE_CHANGED")
assert(stub.visualsUpdated > n and artFaded(), "the game's art shows after the manager's event")
stub.advance(0.05)
assert(artFaded(), "the game's art shows the frame after the manager's event")
assert(ours(rep):GetFrameLevel() > rep.StatusBar:GetFrameLevel(), "ours is not over the game's StatusBar")
assert(is(rep, "success"), "a friendly faction is not green")
-- Its track tinted in the standing's colour (the game's green ground); the experience bar's not.
local function tintOf(bar)
	for _, r in ipairs({ ours(bar):GetRegions() }) do
		local l, sub = r:GetDrawLayer()
		if l == "BACKGROUND" and sub == 2 then return r end
	end
end
do
	local t = tintOf(rep)
	local r, g, b, a = t:GetVertexColor()
	local tr, tg, tb = T.Color("success")
	assert(t:IsShown() and near(r, tr) and near(g, tg) and near(b, tb) and near(a, 0.3), "the reputation track is not tinted green")
	assert(not tintOf(Main.bars[XP]):IsShown(), "the experience track is tinted")
end
stub.advance(0.2)
assert(rep.StatusBar:GetStatusBarTexture():GetAlpha() == 1, "the stub did not reset the game's fill")
assert(ours(rep):IsVisible() and fillOf(rep):IsShown() and ours(rep):GetFrameLevel() > rep.StatusBar:GetFrameLevel(), "the game's reset fill is not covered")
-- Standing: hostile and unfriendly danger, neutral warning, friendly and up success.
stub.watchFaction(2)
assert(is(rep, "danger"), "a hostile faction is not in danger")
stub.watchFaction(3)
assert(is(rep, "danger"), "an unfriendly faction is not in danger")
stub.watchFaction(4)
assert(is(rep, "warning"), "a neutral faction is not in warning")
stub.watchFaction(6)
assert(is(rep, "success"), "an honored faction is not green")
-- A fade-out (the game switching bars): ours fades with the container; its fade-in after shows ours at once again.
stub.fadeOutStatusBar(Second)
assert(not ours(rep):IsIgnoringParentAlpha(), "ours does not follow the game's fade-out")
stub.finishStatusFade(Second)
assert(Second:GetAlpha() == 0 and not ours(rep):IsIgnoringParentAlpha(), "faded out: ours shows")
Second.FadeInAnimation:Restart()
assert(ours(rep):IsIgnoringParentAlpha(), "fading in again: ours waits")
stub.finishStatusFade(Second)
stub.setCVar("xpBarText", "1")
local xp = Main.bars[XP]
assert(ours(xp):IsVisible() and fillOf(xp), "the experience bar is not dressed")
assert(xp.StatusBar:GetStatusBarTexture():GetAlpha() == 0 and xp.StatusBar.Background:GetAlpha() == 0, "the game's fill or ground shows")
assert(Main.BarFrameTexture:GetAlpha() == 0, "the game's frame art shows")
for d in Main.HorizontalDividersPool:EnumerateActive() do assert(d.BarDividerTexture:GetAlpha() == 0, "a divider shows") end
assert(ticks(xp) == 19, "not a tick on every divider")
local band
for _, r in ipairs({ ours(xp):GetRegions() }) do if rawget(r, "psStars") then band = r end end
assert(band and band:IsShown() and band:GetAlpha() == 0.7, "the experience track has no header band")
local _, x1, y0, y1 = unpack(band.texCoord)
assert(near(x1, 1) and near(y0, 23 / 128) and near(y1, 37 / 128), "the band is not cropped 1:1 to the bar")
local rb
for _, r in ipairs({ ours(Second.bars[REP]):GetRegions() }) do if rawget(r, "psStars") then rb = r end end
assert(not rb, "a band on the reputation bar")
local r, g, b = fillOf(xp):GetVertexColor()
local vr, vg, vb = T.Color("dungeon")
assert(near(r, vr) and near(g, vg) and near(b, vb), "the experience fill is not violet")
local path, size, flags = xp.OverlayFrame.Text:GetFont()
assert(path == (T.FontSpec("number")) and size == 12 and flags == "OUTLINE", "the text is not in Polestar's number face at the game's size")
assert(xp.OverlayFrame.Text:IsShown(), "xpBarText on: the text is hidden")
-- Every kind dressed; only the shown one visible.
for kind, bar in pairs(Main.bars) do
	assert(ours(bar), "kind " .. kind .. " is not dressed")
	assert(ours(bar):IsVisible() == (kind == XP), "kind " .. kind .. ": ours does not follow the bar's visibility")
end
assert(ours(Second.bars[REP]):IsVisible(), "the second container's reputation bar is not dressed")
-- Rested: the game's blue fill; ours in the mana blue. Then normal again, with more experience.
stub.setRestState(1)
r, g, b = fillOf(xp):GetVertexColor()
vr, vg, vb = T.Color("npc")
assert(near(r, vr) and near(g, vg) and near(b, vb), "rested: the fill is not blue")
stub.setRestState(2)
stub.setXP(6200, 10000)
r = fillOf(xp):GetVertexColor()
assert(near(r, (T.Color("dungeon"))), "normal again: the fill is not violet")
assert(xp.StatusBar:GetStatusBarTexture():GetAlpha() == 0, "the game's fill shows after its new atlas")
stub.advance(0.1)
