--@ title: Cast bars: off
--@ roots: PlayerCastingBarFrame, PolestarUITargetFrame, TargetFrameSpellBar
--@ stubs: stub_castbars.lua
-- Switched off, live: the game's art, spark, name and icon are back and ours hidden, mid-cast; on and off again, the same.
stub.units.target = { name = "Kurzen", level = 25, health = 12400, max = 20000, power = 900, powerMax = 1200, reaction = 2 }
stub.fire("PLAYER_TARGET_CHANGED")
stub.unitWatch()
stub.cast("player", { name = "Fireball", time = 2.5, elapsed = 1.5 })
stub.cast("target", { name = "Shadow Bolt", time = 3, elapsed = 1.8, locked = true })
stub.advance(0.1)
PolestarUI.Switch("castbars", false)
PolestarUI.Switch("castbars", true)
stub.advance(0.1)
assert(PlayerCastingBarFrame.Border:GetAlpha() == 0 and PlayerCastingBarFrame:GetChildren():IsShown(), "not restyled when on again")
PolestarUI.Switch("castbars", false)
stub.advance(0.1)
for _, bar in ipairs({ PlayerCastingBarFrame, TargetFrameSpellBar }) do
	for _, k in ipairs({ "Border", "Background", "Spark", "BorderShield", "Text", "Icon", "TextBorder" }) do
		assert(bar[k]:GetAlpha() == 1, "the game's " .. k .. " is not back")
	end
	local path, size, flags = bar.Text:GetFont()
	assert(path == STANDARD_TEXT_FONT and size == 10 and flags == "", "the name's font is not the game's")
	assert(not bar:GetChildren():IsShown(), "ours still shows")
	for _, r in ipairs({ bar:GetRegions() }) do
		assert(r == bar:GetStatusBarTexture() or not tostring(r:GetTexture()):find("white", 1, true), "a texture of ours on the bar itself")
	end
end
