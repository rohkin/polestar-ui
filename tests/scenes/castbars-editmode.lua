--@ title: Cast bars: Edit Mode, locked to the player frame, cast time shown
--@ roots: PolestarUIPlayerFrame, PlayerCastingBarFrame
--@ stubs: stub_castbars.lua
-- Edit Mode's settings stay the game's. In Edit Mode the game shows the bar with no cast: ours covers it in the accent, named "Cast Bar", with a sample time and no icon. Show Cast Time: the game's own cast time shows where it is, faded (ours always shows). Lock to Player Frame hangs the bar under the player frame in the game's unit frame look (150 x 10, its own icon shown, its name's font set again): ours follows, still 20 high from the bar's top, the game's name and icon still faded. Nothing of ours moved, sized, showed or wrote a key on the bar (the stub's guards).
local P = PlayerCastingBarFrame
stub.enterEditMode()
stub.advance(0.1)
local box, fill, icon, texts = P:GetChildren(), nil, nil, {}
for _, r in ipairs({ box:GetRegions() }) do
	if r.kind == "FontString" then texts[#texts + 1] = r elseif r.points[1] and r.points[1].rel == P:GetStatusBarTexture() then fill = r elseif r.texCoord then icon = r end
end
local time, name = texts[1], texts[2]
assert(P:IsShown() and not P.casting and box:IsShown() and fill:IsShown(), "Edit Mode's sample bar is not covered")
assert(name:GetText() == "Cast Bar" and time:GetText() == "10.0" and not icon:IsShown(), "the sample bar's name, time and icon")
stub.editCastBar({ lock = true, time = true })
stub.advance(0.1)
stub.exitEditMode()
stub.cast("player", { name = "Hearthstone", time = 10, elapsed = 4 })
stub.advance(0.1)
assert(P:GetWidth() == 150 and P:GetHeight() == 10 and P:GetPoint(1) == "TOPLEFT" and select(2, P:GetPoint(1)) == PlayerFrame, "Lock to Player Frame was undone")
assert(box:GetHeight() == 20 and fill:GetHeight() == 20, "ours is not 20 high on the smaller bar")
assert(name:GetText() == "Hearthstone" and time:GetText() == "6.0" and icon:IsShown(), "the name, time and icon")
-- The game shows its own icon and sets its name's font in this look: both still faded, the cast time too.
assert(P.Icon:IsShown() and P.Icon:GetAlpha() == 0 and P.Text:GetAlpha() == 0 and P.CastTimeText:IsShown() and P.CastTimeText:GetAlpha() == 0, "the game's icon, name or time shows")
