--@ title: Experience and reputation bars: Edit Mode, Size 50%, the text on hover
--@ roots: MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer
--@ stubs: stub_statusbars.lua
-- Edit Mode's place and Size stay the game's: at 50% the game lays the container, its bars and its dividers again; ours follows by its anchors alone (half as wide, a tick on each divider where it now is). The game's xpBarText option off: the text shows only while the bar is hovered (the game's OnEnter), in Polestar's face. Nothing of ours moved, sized, showed, faded or wrote a key on a stock frame (the stub's guards).
-- Every region (and frame) of f and its descendants: ours are spread over a few frames.
local function regionsOf(f, out)
	out = out or {}
	for _, r in ipairs({ f:GetRegions() }) do out[#out + 1] = r end
	for _, c in ipairs({ f:GetChildren() }) do regionsOf(c, out) end
	return out
end
local function framesOf(f, out)
	out = out or {}
	for _, c in ipairs({ f:GetChildren() }) do out[#out + 1] = c; framesOf(c, out) end
	return out
end
stub.finishStatusFade() -- the fade-in after login (statusbars checks it)
local Main = MainStatusTrackingBarContainer
local xp = Main.bars[4]
local function ours(bar)
	for _, f in ipairs({ bar:GetChildren() }) do
		if f ~= bar.StatusBar and f ~= bar.OverlayFrame and f ~= rawget(bar, "ExhaustionTick") and f ~= rawget(bar, "Tick") then return f end
	end
end
stub.enterEditMode()
stub.statusBarSize(Main, 50)
stub.advance(0.1)
stub.exitEditMode()
stub.advance(0.1)
assert(Main:GetWidth() == 596 and xp:GetWidth() == 593, "Edit Mode's Size was undone")
local box = ours(xp)
assert(#box.points == 2 and box.points[1].rel == xp and box.points[2].rel == xp, "ours is not hung on the bar's corners")
local n = 0
for _, r in ipairs(regionsOf(box)) do
	local p = r.points[1]
	if p and p.rel and Main.HorizontalDividersPool.activeObjects[p.rel] and r:IsShown() then n = n + 1 end
end
assert(n == 19, "the ticks do not follow the dividers")
for d in Main.HorizontalDividersPool:EnumerateActive() do assert(d.BarDividerTexture:GetAlpha() == 0, "a divider laid again shows") end
assert(not xp.OverlayFrame.Text:IsShown(), "xpBarText off: the text shows at rest")
stub.hoverStatusBar(xp, true)
assert(xp.OverlayFrame.Text:IsShown() and select(3, xp.OverlayFrame.Text:GetFont()) == "OUTLINE", "hovered: the text is not shown in our face")
