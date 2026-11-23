--@ title: Experience and reputation bars: off
--@ roots: MainStatusTrackingBarContainer
--@ stubs: stub_statusbars.lua
-- Switched off, live: the game's fill, ground, frame art, dividers and text font are back and ours hidden; on and off again, the same.
stub.finishStatusFade() -- the fade-in after login (statusbars checks it)
local Main = MainStatusTrackingBarContainer
local xp = Main.bars[4]
local font = { xp.OverlayFrame.Text:GetFont() }
stub.setCVar("xpBarText", "1")
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
		assert(f == bar.StatusBar or f == bar.OverlayFrame or f == rawget(bar, "ExhaustionTick") or not f:IsShown(), "ours still shows")
	end
end
assert(Main.BarFrameTexture:GetAlpha() == 1, "the game's frame art is not back")
for d in Main.HorizontalDividersPool:EnumerateActive() do assert(d.BarDividerTexture:GetAlpha() == 1, "a divider is not back") end
