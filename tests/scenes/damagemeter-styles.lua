--@ title: Damage meter, Style Thin
--@ roots: DamageMeter
--@ stubs: stub_damagemeter.lua
-- Every Style gets our flat bars, on the game's geometry. Thin: the name and value above a thin bar.
stub.dmSetting("style", Enum.DamageMeterStyle.Thin)
stub.damage({
	{ name = "Garrosh", class = "WARRIOR", amount = 412000 },
	{ name = "Anduin", class = "PRIEST", amount = 318000 },
	{ name = "Water Elemental", amount = 254000 },
	{ name = "Jaina", class = "MAGE", amount = 96000, me = true },
})
stub.advance(0.1)
local sb = DamageMeterSessionWindow1.MinimizeContainer.ScrollBox.ScrollTarget:GetChildren().StatusBar
assert(sb.Background:GetAlpha() == 0 and sb.BackgroundEdge:GetAlpha() == 0, "Thin: the row's art shows")
--@ panel
--@ title: Damage meter, Style Bordered
--@ roots: DamageMeter
--@ stubs: stub_damagemeter.lua
-- Bordered: the game sets its own bordered atlas on the row's background (and hides the edge); faded as any other.
stub.damage({
	{ name = "Garrosh", class = "WARRIOR", amount = 412000 },
	{ name = "Anduin", class = "PRIEST", amount = 318000 },
	{ name = "Water Elemental", amount = 254000 },
	{ name = "Jaina", class = "MAGE", amount = 96000, me = true },
})
stub.advance(0.1)
stub.dmSetting("style", Enum.DamageMeterStyle.Bordered)
local sb = DamageMeterSessionWindow1.MinimizeContainer.ScrollBox.ScrollTarget:GetChildren().StatusBar
assert(sb.Background:GetAtlas() == "UI-HUD-CoolDownManager-Bar-BG" and sb.Background:GetAlpha() == 1, "the stub did not set the bordered art")
stub.advance(0.1)
assert(sb.Background:GetAlpha() == 0, "Bordered: the row's art shows")
