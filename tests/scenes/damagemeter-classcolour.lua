--@ title: Damage meter: the meter's own Show Class Color on
--@ roots: DamageMeter
--@ stubs: stub_damagemeter.lua
-- With the meter's Show Class Color (Edit Mode) each player's fill is in their class colour, from the row's own classFilename (never secret); a creature (no class) stays in the accent (every fill mixed 0.55 into the ground colour, so the names read on the priest's white).
local T = Polestar.Theme
stub.dmSetting("classColor", true)
stub.damage({
	{ name = "Garrosh", class = "WARRIOR", amount = 412000 },
	{ name = "Anduin", class = "PRIEST", amount = 318000 },
	{ name = "Water Elemental", amount = 254000 },
	{ name = "Alleria", class = "HUNTER", amount = 201000 },
	{ name = "Jaina", class = "MAGE", amount = 96000, me = true },
})
stub.advance(0.1)
local function fill(e)
	local sb = e.StatusBar
	for _, r in ipairs({ sb:GetRegions() }) do if r.points[1] and r.points[1].rel == sb:GetStatusBarTexture() then return r end end
end
-- Every fill mixed 0.55 into the ground colour (opaque over the game's fill).
local br, bg, bb = T.Color("bg")
local function is(e, r, g, b)
	local x, y, z = fill(e):GetVertexColor()
	return math.abs(x - (r * 0.55 + br * 0.45)) < 1e-6 and math.abs(y - (g * 0.55 + bg * 0.45)) < 1e-6 and math.abs(z - (b * 0.55 + bb * 0.45)) < 1e-6
end
local rows = { DamageMeterSessionWindow1.MinimizeContainer.ScrollBox.ScrollTarget:GetChildren() }
assert(is(rows[1], T.ClassColor("WARRIOR")), "the warrior is not in the warrior's colour")
assert(is(rows[2], T.ClassColor("PRIEST")), "the priest is not in the priest's colour")
assert(is(rows[3], T.Accent()), "a creature is not in the accent")
-- Show Class Color off again: the accent.
stub.dmSetting("classColor", false)
stub.advance(0.1)
assert(is(rows[1], T.Accent()), "Show Class Color off: not the accent")
stub.dmSetting("classColor", true)
stub.advance(0.1)
