--@ title: Experience and reputation bars: Polestar's completed quest XP
--@ roots: MainStatusTrackingBarContainer
--@ stubs: stub_statusbars.lua, stub_questxp.lua
-- Polestar 0.4.2's "Completed quest XP" on the experience bar, restyled to ours: its sage band (masked by the game's fill atlas, inset) emptied (its alpha comes back to 1, as in game; the stub does that) and ours drawn on the same span at the bar's full inner height, flat, in success at 40%, a 1px success line along its bottom and at its end; its copy of the game's pip faded; "+1 level" in Polestar's label face, outlined, in success. Its frame comes after ours enabled (Polestar's first refresh with quest XP): found the next frame. Every redraw keeps it. Switched off, live: all of it Polestar's again. No texture of ours wears a game atlas.
local T = Polestar.Theme
local Main = MainStatusTrackingBarContainer
local xp = Main.bars[4]
local Q = Polestar.QoL.QuestXP
local function near(a, b) return math.abs(a - b) < 0.01 end
stub.finishStatusFade()
stub.setRested(1500)
stub.questXP(4200)
stub.advance(0.05)
local f = Q.frame
local band
for _, r in ipairs({ f:GetRegions() }) do
	if r ~= f.Tint and r.points and r.points[1] and r.points[1].rel == f.Tint then band = r end
end
local function restyled()
	local r, g, b, a = band:GetVertexColor()
	local sr, sg, sb = T.Color("success")
	return f.Tint:GetTexture() == nil and band:IsShown() and near(r, sr) and near(g, sg) and near(b, sb) and near(a, 0.4)
		and f.Rested:GetAlpha() == 0 and select(3, f.LevelLabel:GetFont()) == "OUTLINE"
end
-- At the bar's full height less our outline's inner pixel (Polestar's band: inset 2, from y = 1.5).
local px = T.Pixel(f)
assert(band and near(band.points[1].y, 2.5 - px) and near(band.points[2].y, -1.5 + px), "no band of ours on Polestar's, inside the outline")
assert(restyled(), "Polestar's quest XP is not restyled")
do
	local lines = {}
	for _, r in ipairs({ f:GetRegions() }) do
		local p = r.points and r.points[1]
		if p and p.rel == band then lines[p.point] = r end
	end
	for _, k in ipairs({ "BOTTOMLEFT", "TOPRIGHT" }) do
		local a = lines[k] and select(4, lines[k]:GetVertexColor())
		assert(lines[k] and lines[k]:IsShown() and a == 1, "no full-colour line on the quest XP band's " .. k)
	end
end
do
	local r, g, b = f.LevelLabel:GetTextColor()
	local sr, sg, sb = T.Color("success")
	assert(near(r, sr) and near(g, sg) and near(b, sb), "the label is not in success")
end
-- A redraw (more quests ready): still ours.
stub.questXP(5000)
assert(restyled(), "a redraw undid the restyle")
-- Off, live: Polestar's look back; on again: ours.
PolestarUI.Switch("statusbars", false)
assert(f.Tint:GetTexture() == T.Media("white") and not band:IsShown() and f.Rested:GetAlpha() == 1, "Polestar's band or pip is not back")
assert(select(3, f.LevelLabel:GetFont()) == "" and near(f.LevelLabel:GetTextColor(), 91 / 255), "Polestar's label is not back")
stub.questXP(4200)
assert(f.Tint:GetTexture() == T.Media("white") and not band:IsShown(), "a redraw while off restyled it")
PolestarUI.Switch("statusbars", true)
assert(restyled(), "not restyled when on again")
-- No texture of ours wears a game atlas.
local function noAtlas(frame)
	for _, r in ipairs({ frame:GetRegions() }) do
		assert(not (r.GetAtlas and tostring(r:GetAtlas()):find("UI-HUD-ExperienceBar", 1, true)), "a texture of ours wears the game's atlas")
	end
	for _, c in ipairs({ frame:GetChildren() }) do noAtlas(c) end
end
for _, c in ipairs({ Main, SecondaryStatusTrackingBarContainer }) do
	for _, bar in pairs(c.bars) do
		for _, ch in ipairs({ bar:GetChildren() }) do
			if ch ~= bar.StatusBar and ch ~= bar.OverlayFrame and ch ~= rawget(bar, "ExhaustionTick") and ch ~= rawget(bar, "Tick") and ch ~= f then noAtlas(ch) end
		end
	end
end
stub.advance(0.1)
