--@ title: Damage meter: a second window (the player's) with a breakdown, window 1 minimized
--@ roots: DamageMeter, DamageMeterSessionWindow2, DamageMeterSessionWindow2Breakdown
--@ stubs: stub_damagemeter.lua
-- Windows 2 and up are the player's: the game places, drags and resizes them; ours dresses each the first frame it exists and never moves it. The breakdown flyout (HIGH strata) of a row: its plain ground faded, ours under it, its spell rows dressed. Window 1 minimized hides its container (rows, ground) as the game does: only its header's texts stay.
stub.damage({
	{ name = "Garrosh", class = "WARRIOR", amount = 412000 },
	{ name = "Anduin", class = "PRIEST", amount = 318000 },
	{ name = "Jaina", class = "MAGE", amount = 96000, me = true },
})
stub.advance(0.1)
local w2 = stub.dmWindow(2, 40, -300, 260, 150)
stub.advance(0.1)
assert(w2.Header:GetAlpha() == 0 and w2.MinimizeContainer.Background:GetAtlas() == nil, "window 2 is not restyled")
local p, rel, _, x, y = w2:GetPoint(1)
assert(p == "TOPLEFT" and rel == UIParent and x == 40 and y == -300 and w2:GetWidth() == 260 and w2:GetHeight() == 150, "window 2 was moved or sized")
local row = w2.MinimizeContainer.ScrollBox.ScrollTarget:GetChildren()
assert(row.StatusBar.Background:GetAlpha() == 0, "window 2's rows are not dressed")
stub.dmBreakdown(2, 3)
stub.advance(0.1)
local sw = w2.MinimizeContainer.SourceWindow
assert(sw:IsShown() and sw.Background:GetAlpha() == 0, "the breakdown's ground shows")
assert(sw.ScrollBox.ScrollTarget:GetChildren().StatusBar.Background:GetAlpha() == 0, "the breakdown's rows are not dressed")
stub.dmMinimize(1, true)
stub.advance(0.1)
local min = DamageMeterSessionWindow1.MinimizeButton
local g
for _, r in ipairs({ min:GetRegions() }) do if r.layer == "ARTWORK" and r.sublayer == 7 then g = r end end
assert(tostring(g:GetTexture()):find("chevron%-down") and min:GetNormalTexture():GetAtlas() == "ui-questtrackerbutton-expand-all" and min:GetNormalTexture():GetAlpha() == 0, "the minimized window's button: expand glyph, the game's art faded")
