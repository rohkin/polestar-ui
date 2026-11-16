--@ title: Nameplates: off
--@ roots: NamePlate1, NamePlate2
--@ stubs: stub_nameplates.lua
-- Switched off, live: every plate's ground, selection art, cast bar art, aura icons and faces are the game's again and ours hidden, on a plate now or in the pool; on and off again, the same.
stub.addPlate("nameplate1", { name = "Defias Pillager", level = 18, reaction = 2, health = 620, max = 1000, auras = { { icon = 136207, count = 2 } } })
stub.addPlate("nameplate2", { name = "Defias Conjurer", level = 18, reaction = 2, health = 800, max = 1000 })
stub.plateCast("nameplate2", { name = "Fireball", time = 3, elapsed = 1, locked = true })
stub.targetPlate("nameplate1")
stub.advance(0.1)
PolestarUI.Switch("nameplates", false)
PolestarUI.Switch("nameplates", true)
stub.advance(0.1)
assert(NamePlate1.UnitFrame.healthBar.bgTexture:GetAlpha() == 0 and PolestarUI.modules.nameplates.look(NamePlate1.UnitFrame).box:IsShown(), "not restyled when on again")
PolestarUI.Switch("nameplates", false)
stub.advance(0.1)
for _, p in ipairs({ NamePlate1, NamePlate2 }) do
	local uf = p.UnitFrame
	local hb = uf.healthBar
	assert(hb.bgTexture:GetAlpha() == 1 and hb.selectedBorder:GetAlpha() == 1 and uf.selectionHighlight:GetAlpha() == 1, "the game's bar art is not back")
	assert(uf.name:GetAlpha() == 1 and uf.PlayerLevelDiffFrame.playerLevelDiffIcon:GetAlpha() == 1 and uf.PlayerLevelDiffFrame.playerLevelDiffText:GetAlpha() == 1,
		"the game's name or level badge is not back")
	local l = PolestarUI.modules.nameplates.look(uf)
	assert(not l.box:IsShown() and not l.name:IsVisible() and not l.bar:IsVisible() and not l.ground.glow[1]:IsVisible(), "our bar, name or glow still shows")
	assert(hb.barTexture:GetAlpha() == 1 and hb.LeftText:GetAlpha() == 1 and hb.deselectedOverlay:GetAlpha() == 1, "the game's fill, health text or deselected overlay is not back")
	local cb = uf.CastBarsContainer.castBar
	assert(cb.Text:GetAlpha() == 1 and cb.Background:GetAlpha() == 1, "the game's cast bar art is not back")
end
assert(not NamePlate2.UnitFrame.CastBarsContainer.castBar:GetChildren():IsShown(), "our cast bar still shows")
local it = NamePlate1.UnitFrame.AurasFrame.DebuffListFrame.items[1]
assert(it.Icon.mask.atlas == "UI-HUD-CoolDownManager-Mask", "the aura icon's rounded mask is not back")
assert((SystemFont_NamePlate_Outlined:GetFont()) == STANDARD_TEXT_FONT and (NamePlate1.UnitFrame.name:GetFont()) == STANDARD_TEXT_FONT, "the plates' face is not the game's")
assert((it.CountFrame.Count:GetFont()) == STANDARD_TEXT_FONT, "the stack count's face is not the game's")
local _, size = it.Cooldown:GetCountdownFontString():GetFont()
assert(size == 16, "the countdown's font is not the game's")
