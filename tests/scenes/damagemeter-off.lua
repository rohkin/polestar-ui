--@ title: Damage meter: off
--@ roots: DamageMeter
--@ stubs: stub_damagemeter.lua
-- Switched off, live: the header art, the window ground (its atlas, at the alpha the game wrote), the rows' art and the game's faces are back and ours hidden; on and off again, the same.
stub.damage({
	{ name = "Garrosh", class = "WARRIOR", amount = 412000 },
	{ name = "Anduin", class = "PRIEST", amount = 318000 },
	{ name = "Water Elemental", amount = 254000 },
	{ name = "Jaina", class = "MAGE", amount = 96000, me = true },
})
stub.advance(0.1)
PolestarUI.Switch("damagemeter", false)
PolestarUI.Switch("damagemeter", true)
stub.advance(0.1)
local w = DamageMeterSessionWindow1
local c = w.MinimizeContainer
assert(w.Header:GetAlpha() == 0 and c.Background:GetAtlas() == nil, "not restyled when on again")
PolestarUI.Switch("damagemeter", false)
stub.dmSetting("bgAlpha", 0.8)
stub.advance(0.1)
assert(w.Header:GetAlpha() == 1, "the header art is not back")
assert(c.Background:GetAtlas() == "damagemeters-background" and c.Background:GetAlpha() == 0.8, "the window ground is not the game's")
for _, r in ipairs({ c:GetRegions() }) do
	assert(r == c.Background or r.kind == "FontString" or not r:IsShown(), "a texture of ours still shows on the window")
end
for _, e in ipairs({ c.ScrollBox.ScrollTarget:GetChildren() }) do
	local sb = e.StatusBar
	assert(sb.Background:GetAlpha() == 1 and sb.BackgroundEdge:GetAlpha() == 1, "a row's art is not back")
	local path, size, flags = sb.Name:GetFont()
	assert(path == STANDARD_TEXT_FONT and size == 12 and flags == "OUTLINE", "a row's name is not in the game's font")
	for _, r in ipairs({ sb:GetRegions() }) do
		assert(r.kind == "FontString" or r == sb:GetStatusBarTexture() or r == sb.Background or r == sb.BackgroundEdge or not r:IsShown(), "ours still shows on a row")
	end
end
local min, set, ses, kind = w.MinimizeButton, w.SettingsDropdown, w.SessionDropdown, w.DamageMeterTypeDropdown
assert(min:GetNormalTexture():GetAlpha() == 1 and set.Icon:GetAlpha() == 1 and ses.Background:GetAlpha() == 1 and kind.Arrow:GetAlpha() == 1, "a button's art is not back")
for _, b in ipairs({ min, set, ses, kind }) do
	for _, r in ipairs({ b:GetRegions() }) do
		assert(r.kind == "FontString" or r == b:GetNormalTexture() or r == b:GetPushedTexture() or r == b:GetHighlightTexture() or r == rawget(b, "Icon")
			or r == rawget(b, "Background") or r == rawget(b, "Arrow") or not r:IsShown(), "ours still shows on a button")
	end
end
local menu, bg = stub.openMenu(kind, "MENU_DAMAGE_METER_WINDOW_TRACKED_TYPE", { "Damage" })
assert(bg:GetAlpha() == 0.925, "off: the menu is not the game's")
stub.closeMenu()
local r, g, b = ses.SessionName:GetTextColor()
local nr, ng, nb = GameFontNormalMed1:GetTextColor()
assert(ses.SessionName:GetFont() == STANDARD_TEXT_FONT and r == nr and g == ng and b == nb, "the session letter is not the game's again")
