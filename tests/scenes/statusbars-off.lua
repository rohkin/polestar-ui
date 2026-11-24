--@ title: Experience and reputation bars: off
--@ roots: MainStatusTrackingBarContainer
--@ stubs: stub_statusbars.lua
-- Switched off, live: the game's fill, ground, frame art, dividers, text font, rested prediction and pip, and the artifact's pip are back and ours (tints, rest, marks with it) hidden; on and off again, the same; the manager's events after it fade nothing again.
stub.finishStatusFade() -- the fade-in after login (statusbars checks it)
local Main = MainStatusTrackingBarContainer
local xp = Main.bars[4]
local font = { xp.OverlayFrame.Text:GetFont() }
stub.setCVar("xpBarText", "1")
-- Rested, and the artifact bar (its pip) in the second container: both dressed, then given back.
local Second = SecondaryStatusTrackingBarContainer
local art = Second.bars[3]
stub.setRested(2500)
stub.showStatusBar(Second, 3)
stub.finishStatusFade()
assert(xp.ExhaustionLevelFillBar:GetAlpha() == 0 and art.Tick.Normal:GetAlpha() == 0, "rest or the artifact's pip not dressed")
PolestarUI.Switch("statusbars", false)
PolestarUI.Switch("statusbars", true)
assert(xp.StatusBar:GetStatusBarTexture():GetAlpha() == 0 and Main.BarFrameTexture:GetAlpha() == 0, "not restyled when on again")
PolestarUI.Switch("statusbars", false)
stub.advance(0.1)
for _, bar in pairs(Main.bars) do
	assert(bar.StatusBar:GetStatusBarTexture():GetAlpha() == 1, "the game's fill is not back")
	for _, k in ipairs({ "Background", "Underlay", "Overlay" }) do assert(bar.StatusBar[k]:GetAlpha() == 1, "the game's " .. k .. " is not back") end
	local path, size, flags = bar.OverlayFrame.Text:GetFont()
	assert(path == font[1] and size == font[2] and flags == font[3], "the text's font is not the game's")
	for _, f in ipairs({ bar:GetChildren() }) do
		assert(f == bar.StatusBar or f == bar.OverlayFrame or f == rawget(bar, "ExhaustionTick") or f == rawget(bar, "Tick") or not f:IsShown(), "ours still shows")
	end
end
assert(Main.BarFrameTexture:GetAlpha() == 1, "the game's frame art is not back")
for d in Main.HorizontalDividersPool:EnumerateActive() do assert(d.BarDividerTexture:GetAlpha() == 1, "a divider is not back") end
assert(xp.ExhaustionLevelFillBar:GetAlpha() == 1 and xp.ExhaustionTick.Normal:GetAlpha() == 1 and xp.ExhaustionTick.Highlight:GetAlpha() == 1, "the game's rested prediction or pip is not back")
assert(art.Tick.Normal:GetAlpha() == 1 and art.Tick.Highlight:GetAlpha() == 1, "the artifact's pip is not back")
assert(Second.BarFrameTexture:GetAlpha() == 1 and art.StatusBar.Background:GetAlpha() == 1, "the second container's art is not back")
stub.fire("ZONE_CHANGED")
stub.fire("UPDATE_FACTION")
stub.advance(0.1)
assert(Main.BarFrameTexture:GetAlpha() == 1 and xp.ExhaustionLevelFillBar:GetAlpha() == 1, "faded again while off")
stub.setRested(nil)
