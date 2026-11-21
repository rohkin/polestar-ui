--@ title: Micro menu: off
--@ roots: MicroMenuContainer
--@ stubs: stub_micromenu.lua
-- Switched off, live: the button backgrounds, the bar's frame art, the pulse glow's atlas, the notification mark and the latency strip are the game's again, ours hidden; on and off again, the same.
stub.microPulse(CollectionsMicroButton, 1)
stub.microNotify(TalentMicroButton, true)
PolestarUI.Switch("micromenu", false)
PolestarUI.Switch("micromenu", true)
assert(CharacterMicroButton.Background:GetAlpha() == 0, "not restyled when on again")
PolestarUI.Switch("micromenu", false)
stub.advance(0.1)
for _, b in ipairs(stub.microButtons) do
	assert(b.Background:GetAlpha() == 1 and b.PushedBackground:GetAlpha() == 1, b:GetName() .. ": the background is not back")
	assert(b.FlashBorder:GetAtlas() == "UI-HUD-MicroMenu-Highlightalert", b:GetName() .. ": the pulse glow is not back")
	assert(b.NotificationOverlay:GetRegions():GetAlpha() == 1, b:GetName() .. ": the notification mark is not back")
	for _, r in ipairs({ b:GetRegions() }) do
		assert(not (r:IsShown() and tostring(r:GetTexture()):find("white", 1, true)), b:GetName() .. ": our textures still show")
	end
	assert(not select(2, b.NotificationOverlay:GetRegions()):IsShown(), b:GetName() .. ": our dot still shows")
end
assert(MicroMenu.BorderArt:GetAlpha() == 1 and MicroMenu.BackgroundArt:GetAlpha() == 1, "the bar's frame art is not back")
assert(MainMenuMicroButton.MainMenuBarPerformanceBar:GetAlpha() == 1, "the latency strip is not back")
for _, r in ipairs({ MainMenuMicroButton:GetRegions() }) do
	assert(not (r:IsShown() and tostring(r:GetTexture()):find("disc", 1, true)), "our latency dot still shows")
end
