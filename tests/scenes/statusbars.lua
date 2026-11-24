--@ title: Experience and reputation bars
--@ roots: MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer
--@ stubs: stub_statusbars.lua
-- The game's status tracking bars restyled in place: the experience bar (62%) in the main container, a reputation bar in the second (Edit Mode's "Show status bar 2"), the game's xpBarText option on. After login the game fades each container in from alpha 0 (5 to 8 s in the client): ours shows at once and follows the container again once the fade-in ends (and through a fade-out). The game's ground, fill, frame art and dividers faded where they are; under each bar a frame of ours: a track, a fill hung on the game's fill (so it follows the value with nothing read), a 1px hairline, a hairline tick on each of the 19 dividers. The experience fill is Polestar's blue (the HUD's default fill), the same while rested; the reputation bar by the watched faction's standing (friendly: success green), its track tinted in it at 30%. The experience bar as the game's in Polestar's look: a see-through black track (the scheme's shade at 40%), a solid Polestar-blue fill wearing the header's stars (band-stars in the star token at 60%, cropped 1:1 from the band's middle rows) over the fill only, clipped to it so they never slide; the ticks at least 30% and the outline at least 50% of the border colour's alpha. Rested experience: the game's prediction and pip faded, ours past the fill in the portal violet at 40% with a hairline at its end. The text keeps its size in Polestar's number face, outlined. Every other kind of bar is dressed too, hidden with it.
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
local XP, REP = 4, 1
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
local function ticks(bar)
	local n = 0
	for _, r in ipairs(regionsOf(ours(bar))) do
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
	for _, r in ipairs(regionsOf(ours(bar))) do
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
-- The experience track a see-through black (the scheme's shade at 40%);
-- ticks at least 30% and the outline at least 50% of the border colour's alpha.
do
	local track
	for _, r in ipairs(regionsOf(ours(xp))) do
		local l, sub = r:GetDrawLayer()
		if l == "BACKGROUND" and (sub or 0) == 0 and r.points[1] and r.points[1].point == "TOPLEFT" and r.points[1].rel == ours(xp) and r.points[2] then track = track or r end
	end
	local r, g, b, a = track:GetVertexColor()
	local sr, sg, sb = T.Color("shade")
	assert(near(r, sr) and near(g, sg) and near(b, sb) and near(a, 0.4), "the experience track is not the see-through shade at 40%")
	for _, t in ipairs(regionsOf(ours(xp))) do
		local p = t.points and t.points[1]
		if p and Main.HorizontalDividersPool.activeObjects[p.rel] then assert(select(4, t:GetVertexColor()) >= 0.3, "a tick fainter than 30%") end
	end
end
-- The fill, its stars and the rested preview inside the outline: under a frame clipped to the
-- bar less the outline's inner pixel on every side (so at 0% and 100% the outline stays whole);
-- the ticks over them.
do
	local box, px = ours(xp), T.Pixel(ours(xp))
	local inner
	for _, f in ipairs(framesOf(box)) do if f.clips and f.points[1] and f.points[1].rel == box then inner = f end end
	assert(inner and near(inner.points[1].x, px) and near(inner.points[1].y, -px) and near(inner.points[2].x, -px) and near(inner.points[2].y, px), "no clip one pixel inside the outline")
	local function under(r, f)
		local p = r:GetParent()
		while p do if p == f then return true end p = p:GetParent() end
	end
	assert(under(fillOf(xp), inner), "the fill is not inside the outline's clip")
	stub.setXP(10000, 10000)
	assert(under(fillOf(xp), inner) and fillOf(xp).points[2].rel == xp.StatusBar:GetStatusBarTexture(), "at 100% the fill is not clipped inside the outline")
	stub.setXP(6200, 10000)
end
-- The stars over the fill only: a frame clipped to the fill (its corners on the game's fill)
-- holding a frame as wide as the bar with the band-stars art, cropped 1:1, in the star token at 60%.
-- No sky band on the track; none on the reputation bar.
local function starsOf(bar)
	for _, clip in ipairs(framesOf(ours(bar))) do
		local holder = clip:GetChildren()
		local t = holder and holder:GetRegions()
		if t and tostring(t:GetTexture()):find("band%-stars") then return clip, holder, t end
	end
end
do
	local clip, holder, stars = starsOf(xp)
	local fill = xp.StatusBar:GetStatusBarTexture()
	assert(clip and clip.clips and clip.points[1].rel == fill and clip.points[2].rel == fill, "the stars are not clipped to the fill")
	assert(holder.points[1].rel == ours(xp) and stars:IsVisible(), "the stars do not span the bar")
	local _, x1, y0, y1 = unpack(stars.texCoord)
	assert(near(x1, 1) and near(y0, 23 / 128) and near(y1, 37 / 128), "the stars are not cropped 1:1 to the bar")
	local sr, sg, sb, sa = T.Color("star")
	assert(near(select(4, stars:GetVertexColor()), (sa or 1) * 0.6), "the stars are not at 60%")
	for _, r in ipairs(regionsOf(ours(xp))) do assert(not rawget(r, "psStars"), "a sky band on the experience track") end
	assert(not starsOf(Second.bars[REP]), "stars on the reputation bar")
end
local r, g, b = fillOf(xp):GetVertexColor()
local vr, vg, vb = PolestarUI.HUD.FillColor("player")
assert(near(r, vr) and near(g, vg) and near(b, vb), "the experience fill is not Polestar's blue (the HUD's default fill)")
local path, size, flags = xp.OverlayFrame.Text:GetFont()
assert(path == (T.FontSpec("number")) and size == 12 and flags == "OUTLINE", "the text is not in Polestar's number face at the game's size")
assert(xp.OverlayFrame.Text:IsShown(), "xpBarText on: the text is hidden")
-- Every kind dressed; only the shown one visible.
for kind, bar in pairs(Main.bars) do
	assert(ours(bar), "kind " .. kind .. " is not dressed")
	assert(ours(bar):IsVisible() == (kind == XP), "kind " .. kind .. ": ours does not follow the bar's visibility")
end
assert(ours(Second.bars[REP]):IsVisible(), "the second container's reputation bar is not dressed")
-- Rested: the game turns its fill blue; ours stays Polestar's blue (the rested preview says it).
stub.setRestState(1)
r, g, b = fillOf(xp):GetVertexColor()
assert(near(r, vr) and near(g, vg) and near(b, vb), "rested: the fill changed colour")
stub.setRestState(2)
-- Rested experience (seen in game: the game's prediction and pip showed through and over ours):
-- both faded; ours from the fill's end to the prediction's end in the portal violet at 40%, 1px lines
-- along its top and at its end; gone with no rest.
stub.setRested(2500)
local rest
for _, r in ipairs(regionsOf(ours(xp))) do
	local p = r.points and r.points[3]
	if p and p.rel == xp.ExhaustionLevelFillBar then rest = r end
end
assert(xp.ExhaustionLevelFillBar:IsShown() and xp.ExhaustionLevelFillBar:GetAlpha() == 0, "the game's rested prediction shows")
assert(xp.ExhaustionTick:IsShown() and xp.ExhaustionTick.Normal:GetAlpha() == 0 and xp.ExhaustionTick.Highlight:GetAlpha() == 0, "the game's pip shows")
assert(rest and rest:IsShown() and rest.points[1].rel == xp.StatusBar:GetStatusBarTexture(), "no rested segment from the fill's end")
do
	local r, g, b, a = rest:GetVertexColor()
	local tr, tg, tb = T.Color("dungeon")
	assert(near(r, tr) and near(g, tg) and near(b, tb) and near(a, 0.4), "the rested segment is not the portal violet at 40%")
end
do
	local top
	for _, r in ipairs(regionsOf(ours(xp))) do
		local p = r.points and r.points[1]
		if p and p.rel == rest and p.point == "TOPLEFT" then top = r end
	end
	local a = top and select(4, top:GetVertexColor())
	assert(top and top:IsShown() and a == 1, "no full-colour line along the rested segment's top")
end
stub.setRested(nil)
assert(not rest:IsShown(), "no rest: the rested segment shows")
stub.setRested(2500)
assert(rest:IsShown(), "rested again: no segment")
stub.setXP(6200, 10000)
r = fillOf(xp):GetVertexColor()
assert(near(r, vr), "normal again: the fill is not Polestar's blue")
assert(xp.StatusBar:GetStatusBarTexture():GetAlpha() == 0, "the game's fill shows after its new atlas")
stub.advance(0.1)
