--@ title: Damage meter: the window head (band, rim) over its header
--@ roots: DamageMeter
--@ stubs: stub_damagemeter.lua
-- The meter as a Polestar window: over its header strip the header band (sky, stars, haze) and the accent rim with its light, on the container (gone with it when minimized), round it the ground's window shadow. Each follows Polestar's own setting live (Header band, Rim), and the game's Background Transparency as the ground does. Switched off, nothing of ours is left.
local T = Polestar.Theme
local function near(a, b) return math.abs(a - b) < 1e-6 end
stub.damage({
	{ name = "Garrosh", class = "WARRIOR", amount = 412000 },
	{ name = "Anduin", class = "PRIEST", amount = 318000 },
	{ name = "Jaina", class = "MAGE", amount = 96000, me = true },
})
stub.advance(0.1)
local w = DamageMeterSessionWindow1
local c = w.MinimizeContainer
-- Our shown textures on the container whose file is `file` (in `layer`).
local function art(file, layer)
	local out = {}
	for _, r in ipairs({ c:GetRegions() }) do
		local t = r.GetTexture and tostring(r:GetTexture())
		if t and t:find("Polestar") and t:sub(-#file - 1) == "\\" .. file and r:IsShown() and (not layer or r:GetDrawLayer() == layer) then out[#out + 1] = r end
	end
	return out
end
local function is(sky, stars, glow, lines) return #art("band") == sky and #art("band-stars") == stars and #art("glow") == glow and #art("white", "OVERLAY") == lines end
assert(is(1, 1, 2, 4) and #art("shadow") == 16, "the meter has no band, rim or shadow")
-- Over the header strip, cropped 1:1 (never stretched), at the game's Background Transparency.
local sky = art("band")[1]
assert(sky.points[1].rel == w.Header and near(sky.texCoord[2], DamageMeter:GetWidth() / T.BAND_W) and near(sky.texCoord[4], 32 / T.BAND_H), "the band not on the header, or stretched")
assert(near(select(4, sky:GetVertexColor()), stub.dm.bgAlpha), "the band not at the meter's Background Transparency")
stub.dmSetting("bgAlpha", 0.9)
stub.advance(0.1)
assert(near(select(4, sky:GetVertexColor()), 0.9), "the band does not follow the meter's Background Transparency")
-- Polestar's Header band off, live: the band and its haze go, the rim stays; the rim off, live.
Polestar.Set("ui.band", false)
stub.advance(0.3)
assert(is(0, 0, 1, 4), "the band shows with Polestar's header band off (or the rim went with it)")
Polestar.Set("ui.band", nil)
Polestar.Set("ui.rim", false)
stub.advance(0.3)
assert(is(1, 1, 1, 0), "the rim shows with Polestar's rim off")
Polestar.Set("ui.rim", nil)
stub.advance(0.3)
assert(is(1, 1, 2, 4), "not back")
-- In combat (the session data secret): still painted, nothing read.
stub.inCombat = true
stub.dmSetting("bgAlpha", 0.7)
stub.advance(0.1)
assert(near(select(4, sky:GetVertexColor()), 0.7), "the head not painted in combat")
stub.inCombat = false
-- Switched off: nothing of ours on the container; on again, back.
PolestarUI.Switch("damagemeter", false)
stub.advance(0.1)
for _, r in ipairs({ c:GetRegions() }) do
	assert(r == c.Background or r.kind == "FontString" or not r:IsShown(), "a texture of ours still shows on the window")
end
PolestarUI.Switch("damagemeter", true)
stub.advance(0.1)
assert(is(1, 1, 2, 4), "not back when on again")
stub.assertNoErrors()
