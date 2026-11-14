--@ title: Damage meter: in combat, every value secret
--@ roots: DamageMeter
--@ stubs: stub_damagemeter.lua
-- In combat the session data is secret to addon code (names, amounts, spec icons): the game's own code fills the rows, ours reads none of it, only the row's classFilename (never secret) for Show Class Color. New rows acquired mid-fight are dressed; nothing errors.
local T = Polestar.Theme
stub.inCombat = true
stub.dmSetting("classColor", true)
stub.damage({
	{ name = "Garrosh", class = "WARRIOR", amount = 412000 },
	{ name = "Anduin", class = "PRIEST", amount = 318000 },
})
stub.advance(0.1)
local rows = { DamageMeterSessionWindow1.MinimizeContainer.ScrollBox.ScrollTarget:GetChildren() }
assert(issecretvalue(rows[1].value) and issecretvalue(rows[1].sourceName), "the stub's data is not secret")
-- New sources mid-fight: new pooled rows, dressed.
stub.damage({
	{ name = "Garrosh", class = "WARRIOR", amount = 512000 },
	{ name = "Anduin", class = "PRIEST", amount = 338000 },
	{ name = "Water Elemental", amount = 254000 },
	{ name = "Alleria", class = "HUNTER", amount = 201000 },
	{ name = "Jaina", class = "MAGE", amount = 96000, me = true },
})
stub.advance(0.1)
rows = { DamageMeterSessionWindow1.MinimizeContainer.ScrollBox.ScrollTarget:GetChildren() }
local sb = rows[5].StatusBar
assert(sb.Background:GetAlpha() == 0 and sb.Name:GetFont() == (T.FontSpec("label")), "a row acquired mid-fight is not dressed")
assert(#stub.errors == 0, "an error in combat: " .. tostring(stub.errors[1]))
