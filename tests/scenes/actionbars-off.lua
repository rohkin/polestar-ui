--@ title: Action bars: off
--@ roots: MainActionBar, MultiBarBottomLeft, PetActionBar, StanceBar
--@ stubs: stub_actionbars.lua
-- Switched off, live: every button's art, round icon mask, checked glow and fonts are the game's again and ours hidden; on and off again, the same.
local font = ActionButton1.HotKey:GetFont()
PolestarUI.Switch("actionbars", false)
PolestarUI.Switch("actionbars", true)
assert(ActionButton1.NormalTexture:GetAlpha() == 0, "not restyled when on again")
PolestarUI.Switch("actionbars", false)
for _, b in ipairs({ ActionButton1, MultiBarBottomLeftButton2, PetActionButton1, StanceButton1 }) do
	assert(b.NormalTexture:GetAlpha() == 1 and b.SlotArt:GetAlpha() == 1 and b.HighlightTexture:GetAlpha() == 1, b:GetName() .. ": the art is not back")
	assert(b.icon.mask == b.IconMask, b:GetName() .. ": the icon is not masked again")
	assert(b.CheckedTexture:GetAtlas() == "UI-HUD-ActionBar-IconFrame-Mouseover", b:GetName() .. ": the checked glow is not back")
	assert(b.HotKey:GetFont() == font, b:GetName() .. ": the key's font is not the game's")
end
local ours = 0
for _, r in ipairs({ ActionButton1:GetRegions() }) do if r:IsShown() and tostring(r:GetTexture()):find("white", 1, true) then ours = ours + 1 end end
assert(ours == 0, "our textures still show")
local emblems = 0
for _, r in ipairs({ ActionButton12:GetRegions() }) do if r:IsShown() and tostring(r:GetTexture()):find("emblem", 1, true) then emblems = emblems + 1 end end
assert(emblems == 0, "the emblem still shows in an empty slot")
