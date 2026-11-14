--@ title: Personal Resource Display: off
--@ roots: PersonalResourceDisplayFrame
--@ stubs: stub_resource.lua
-- Switched off, live: the game's bar art, prediction textures, glows and fonts are back and ours hidden; on and off again, the same.
stub.units.player = { name = "Jaina", level = 60, class = "MAGE", player = true, health = 1500, max = 2400, power = 3200, powerMax = 4000, powerType = 0, reaction = 5 }
stub.prdEdit({ barText = true })
stub.prd({ heal = 250, absorb = 300, cost = 600 })
stub.advance(0.1)
local P = PersonalResourceDisplayFrame
local hb, pb = P.HealthBarsContainer.healthBar, P.PowerBar
PolestarUI.Switch("resource", false)
PolestarUI.Switch("resource", true)
stub.advance(0.1)
assert(hb.totalAbsorb:GetAlpha() == 0, "not restyled when on again")
PolestarUI.Switch("resource", false)
stub.advance(0.1)
for _, bar in ipairs({ hb, pb, P.AlternatePowerBar }) do
	for _, r in ipairs({ bar:GetRegions() }) do
		local white = r.kind == "Texture" and tostring(r:GetTexture()):find("white", 1, true)
		if white then assert(not r:IsShown(), "a texture of ours still shows") end
		if r.kind == "Texture" and not white and r ~= bar:GetStatusBarTexture() then assert(r:GetAlpha() == 1, "a region of the game's is still faded") end
	end
	local path, size, flags = bar.TextString:GetFont()
	assert(path == STANDARD_TEXT_FONT and size == 10 and flags == "", "the bar text's font is not the game's")
end
assert(hb.overAbsorbGlow:GetAlpha() == 1 and pb.ManaCostPredictionBar:GetAlpha() == 1, "the glow or the cost bar is still faded")
