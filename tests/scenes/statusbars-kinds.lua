--@ title: Experience and reputation bars: honor, artifact, azerite, house favour; Edit Mode with each
--@ roots: MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer
--@ stubs: stub_statusbars.lua
-- Every bar kind a container holds is dressed through one path, each in the game's meaning: honor (the game's orange-red) in the warm place, artifact, azerite and house favour (the game's one artifact-power gold) in quest gold. Each, shown, has the game's art faded again after the manager's events reset it. The artifact bar's pip (its Tick) is faded and marked by an accent hairline of ours; its mouse stays the game's. In Edit Mode at Size 60% every kind follows the container, a tick on each divider. Shown: honor in the main container, the artifact in the second.
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
local T = Polestar.Theme
local Main, Second = MainStatusTrackingBarContainer, SecondaryStatusTrackingBarContainer
local function ours(bar)
	for _, f in ipairs({ bar:GetChildren() }) do
		if f ~= bar.StatusBar and f ~= bar.OverlayFrame and f ~= rawget(bar, "ExhaustionTick") and f ~= rawget(bar, "Tick") then return f end
	end
end
local function fillOf(bar)
	for _, r in ipairs(regionsOf(ours(bar))) do
		if r.points[1] and r.points[1].rel == bar.StatusBar:GetStatusBarTexture() then return r end
	end
end
local function near(a, b) return math.abs(a - b) < 0.01 end
-- The token, else the game's hue calmed halfway to textMuted (as the module).
local function expect(name, r, g, b)
	if T.Palette()[name] then return T.Color(name) end
	local mr, mg, mb = T.Color("textMuted")
	return (r + mr) / 2, (g + mg) / 2, (b + mb) / 2
end
local KINDS = {
	[2] = { expect("place", 0.9, 0.4, 0.1) },
	[3] = { expect("quest", 0.9, 0.8, 0.5) },
	[5] = { expect("quest", 0.9, 0.8, 0.5) },
	[6] = { expect("quest", 0.9, 0.8, 0.5) },
}
stub.finishStatusFade()
stub.showStatusBar(Second, nil)
for kind, c in pairs(KINDS) do
	stub.showStatusBar(Main, kind)
	stub.finishStatusFade()
	local bar = Main.bars[kind]
	local r, g, b = fillOf(bar):GetVertexColor()
	assert(ours(bar):IsVisible() and near(r, c[1]) and near(g, c[2]) and near(b, c[3]), "kind " .. kind .. ": not dressed in its colour")
	stub.fire("ZONE_CHANGED")
	assert(bar.StatusBar.Background:GetAlpha() == 0 and bar.StatusBar:GetStatusBarTexture():GetAlpha() == 0 and Main.BarFrameTexture:GetAlpha() == 0,
		"kind " .. kind .. ": the game's art shows after the manager's event")
end
-- The artifact's pip.
local art = Main.bars[3]
stub.showStatusBar(Main, 3)
local mark
for _, r in ipairs(regionsOf(ours(art))) do if r.points[1] and r.points[1].rel == art.Tick then mark = r end end
assert(art.Tick:IsShown() and art.Tick.Normal:GetAlpha() == 0 and art.Tick.Highlight:GetAlpha() == 0, "the artifact's pip shows")
assert(mark and mark:IsShown(), "no mark on the artifact's pip")
-- Edit Mode, Size 60%: every kind.
stub.enterEditMode()
stub.statusBarSize(Main, 60)
for kind = 1, 6 do
	stub.showStatusBar(Main, kind)
	local bar, box = Main.bars[kind], ours(Main.bars[kind])
	assert(box:IsVisible() and box.points[1].rel == bar and box.points[2].rel == bar, "Edit Mode: kind " .. kind .. " is not dressed on its bar")
	local n = 0
	for _, r in ipairs(regionsOf(box)) do
		local p = r.points[1]
		if p and p.rel and Main.HorizontalDividersPool.activeObjects[p.rel] and r:IsShown() then n = n + 1 end
	end
	assert(n == 19, "Edit Mode: kind " .. kind .. " has not a tick on every divider")
end
stub.exitEditMode()
stub.statusBarSize(Main, 100)
stub.showStatusBar(Main, 2)
stub.showStatusBar(Second, 3)
stub.finishStatusFade()
stub.advance(0.1)
