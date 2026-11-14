--@ title: Buffs and debuffs: off
--@ roots: BuffFrame, DebuffFrame
--@ stubs: stub_auras.lua
-- Switched off, live: every button's borders, icon and fonts are the game's again and ours hidden; on and off again, the same.
stub.auras.buffs = { { icon = { 0.3, 0.5, 0.85 }, time = 1800 }, { icon = { 0.85, 0.7, 0.25 }, time = 45, count = 3 }, { icon = { 0.75, 0.3, 0.2 }, time = 300, enchant = true } }
stub.auras.debuffs = { { icon = { 0.5, 0.2, 0.6 }, time = 20, dispel = "Magic" } }
stub.updateAuras()
stub.advance(0.2)
local B, D = BuffFrame.auraFrames, DebuffFrame.auraFrames
PolestarUI.Switch("auras", false)
PolestarUI.Switch("auras", true)
assert(D[1].DebuffBorder:GetAlpha() == 0, "not restyled when on again")
PolestarUI.Switch("auras", false)
stub.advance(0.2)
for _, b in ipairs({ B[1], B[2], D[1] }) do
	assert(b.DebuffBorder:GetAlpha() == 1 and b.TempEnchantBorder:GetAlpha() == 1, "the borders are not back")
	assert(b.Icon.texCoord[1] == 0 and b.Icon.texCoord[2] == 1, "the icon is still cropped")
	local path, size, flags = b.Duration:GetFont()
	assert(path == STANDARD_TEXT_FONT and size == 10 and flags == "", "the duration's font is not the game's")
	assert(select(3, b.Count:GetFont()) == "OUTLINE" and b.Count:GetFont() == STANDARD_TEXT_FONT, "the count's font is not the game's")
	for _, r in ipairs({ b:GetRegions() }) do assert(not (r:IsShown() and tostring(r:GetTexture()):find("white", 1, true)), "our hairlines still show") end
end
