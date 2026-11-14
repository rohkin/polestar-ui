--@ title: Cooldown Viewer: off
--@ roots: EssentialCooldownViewer, BuffIconCooldownViewer, BuffBarCooldownViewer
--@ stubs: stub_cooldowns.lua
-- Switched off, live: the game's rounded mask, overlay, sweep, faces, BarBG and pip are back, ours hidden; on and off again, the same.
stub.cdm({
	essential = { { icon = { 0.75, 0.3, 0.2 }, cd = 0.6, time = "12" }, { icon = { 0.3, 0.5, 0.85 }, charges = "2" } },
	buffs = { { icon = { 0.3, 0.65, 0.7 }, stacks = "3" } },
	bars = { { icon = { 0.85, 0.7, 0.25 }, name = "Ice Barrier", left = 15, duration = 30 } },
})
stub.advance(0.05)
PolestarUI.Switch("cooldowns", false)
PolestarUI.Switch("cooldowns", true)
stub.advance(0.05)
assert(not EssentialCooldownViewer.active[1].Icon.mask.psStock, "not restyled when on again")
PolestarUI.Switch("cooldowns", false)
stub.advance(0.05)
local function plain(f)
	for _, r in ipairs({ f:GetRegions() }) do
		assert(not (r.kind ~= "MaskTexture" and r:IsShown() and tostring(r:GetTexture()):find("white", 1, true)), "a texture of ours shows")
		if r:GetAtlas() == "UI-HUD-CoolDownManager-IconOverlay" then assert(r:GetAlpha() == 1, "the overlay is not back") end
	end
end
for _, v in ipairs({ EssentialCooldownViewer, BuffIconCooldownViewer }) do
	for _, it in ipairs(v.active) do
		plain(it)
		assert(it.Icon.mask.psStock and it.Icon.texCoord[1] == 0 and it.Cooldown.swipe == "Interface\\HUD\\UI-HUD-CoolDownManager-Icon-Swipe", "the icon or sweep is not the game's")
		local path, _, flags = it.Cooldown:GetCountdownFontString():GetFont()
		assert(path == STANDARD_TEXT_FONT and flags == "OUTLINE", "the countdown's face is not the game's")
	end
end
local it = BuffBarCooldownViewer.active[1]
plain(it.Bar)
plain(it.Icon)
assert(it.Bar.BarBG:GetAlpha() == 1 and it.Bar.Pip:GetAlpha() == 1 and it.Icon.Icon.mask.psStock, "the bar is not the game's")
assert(it.Bar.Name:GetFont() == STANDARD_TEXT_FONT, "the bar's name face is not the game's")
