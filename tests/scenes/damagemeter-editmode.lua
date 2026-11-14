--@ title: Damage meter: Edit Mode, wider and taller, taller bars, Background 30%
--@ roots: DamageMeter
--@ stubs: stub_damagemeter.lua
-- Edit Mode's settings stay the game's: window 1 hangs on the system, which Edit Mode sizes (Frame Width and Height); Bar Height and Padding lay the rows out; Background Transparency is the alpha the game writes on its emptied ground, which ours copies (times the HUD's Background opacity). In Edit Mode the game shows its sample session; ours dresses it. Nothing of ours moved, sized, showed or wrote a key on the meter (the stub's guards).
stub.damage({ { name = "Jaina", class = "MAGE", amount = 96000, me = true } })
stub.advance(0.1)
stub.enterEditMode()
stub.dmSetting("width", 360)
stub.dmSetting("height", 260)
stub.dmSetting("barHeight", 30)
stub.dmSetting("spacing", 2)
stub.dmSetting("bgAlpha", 0.3)
stub.advance(0.1)
local w = DamageMeterSessionWindow1
local c = w.MinimizeContainer
assert(w:GetPoint(1) == "TOPLEFT" and select(2, w:GetPoint(1)) == DamageMeter and DamageMeter:GetWidth() == 360, "the window left the system")
local rows = { c.ScrollBox.ScrollTarget:GetChildren() }
assert(#rows == 7 and rows[7]:GetHeight() == 30, "the sample session's rows: " .. #rows)
for _, e in ipairs(rows) do assert(e.StatusBar.Background:GetAlpha() == 0, "a sample row's art shows") end
local ground
for _, r in ipairs({ c:GetRegions() }) do
	if r ~= c.Background and r.layer == "BACKGROUND" and r.sublayer == -8 and r.points[1] and r.points[1].rel == c and #r.points == 2 then ground = r break end
end
local _, _, _, a = ground:GetVertexColor()
assert(math.abs(a - 0.3 * 0.6) < 1e-6, "Background Transparency is not copied: " .. tostring(a))
assert(c.Background:GetAlpha() == 0.3 and c.Background:GetTexture() == nil, "the game's ground was touched")
