--@ title: Cooldown Viewer: essential, utility, tracked buffs and bars
--@ roots: EssentialCooldownViewer, UtilityCooldownViewer, BuffIconCooldownViewer, BuffBarCooldownViewer
--@ stubs: stub_cooldowns.lua
-- The game's four cooldown viewers restyled in place, as the action buttons: each icon unmasked and cropped square, the game's rounded overlay faded, our ground and 1px hairline, the sweep square (the stock file swapped for white; its colour stays the game's), the countdown, charges and stacks in Polestar's number face, outlined. An essential spell on cooldown, one with two charges; a tracked buff with three stacks, a debuff with the game's border; a buff bar half done: our track and a flat fill in the header band's sky whose edge hangs on the game's fill, the game's BarBG and pip faded, the name and time the game's in Polestar's faces. Nothing read (the counts' GetText is guarded), nothing moved or written on a viewer or item (the stub's guards).
local T = Polestar.Theme
stub.cdm({
	essential = { { icon = { 0.75, 0.3, 0.2 }, cd = 0.6, time = "12" }, { icon = { 0.3, 0.5, 0.85 }, charges = "2" }, { icon = { 0.85, 0.7, 0.25 } } },
	utility = { { icon = { 0.4, 0.7, 0.35 }, cd = 0.3, time = "4" }, { icon = { 0.6, 0.35, 0.75 } } },
	buffs = { { icon = { 0.3, 0.65, 0.7 }, cd = 0.4, time = "8", stacks = "3" }, { icon = { 0.6, 0.2, 0.2 }, debuff = true } },
	bars = { { icon = { 0.85, 0.7, 0.25 }, name = "Ice Barrier", left = 15, duration = 30, stacks = "2" }, { icon = { 0.3, 0.5, 0.85 }, name = "Arcane Intellect", left = 24, duration = 30 } },
})
stub.advance(0.05)
local function regions(f) return { f:GetRegions() } end
local function overlay(f) for _, r in ipairs(regions(f)) do if r:GetAtlas() == "UI-HUD-CoolDownManager-IconOverlay" then return r end end end
-- Ours on a frame: its white textures (ground, hairlines, track, fill), shown.
local function ours(f) local n = 0 for _, r in ipairs(regions(f)) do if r.kind ~= "MaskTexture" and r:IsShown() and tostring(r:GetTexture()):find("white", 1, true) then n = n + 1 end end return n end
local num = (T.FontSpec("number"))
for _, v in ipairs({ EssentialCooldownViewer, UtilityCooldownViewer, BuffIconCooldownViewer }) do
	for _, it in ipairs(v.active) do
		assert(not it.Icon.mask.psStock and it.Icon.texCoord[1] == 0.08, v:GetName() .. ": an icon is not square")
		assert(overlay(it):GetAlpha() == 0, v:GetName() .. ": the overlay shows")
		assert(ours(it) == 5, v:GetName() .. ": our ground and hairlines: " .. ours(it))
		assert(it.Cooldown.swipe ~= "Interface\\HUD\\UI-HUD-CoolDownManager-Icon-Swipe", v:GetName() .. ": the sweep is rounded")
		assert(it.Cooldown:GetCountdownFontString():GetFont() == num, v:GetName() .. ": the countdown is not in Polestar's face")
	end
end
assert(EssentialCooldownViewer.active[2].ChargeCount.Current:GetFont() == num and select(3, BuffIconCooldownViewer.active[1].Applications.Applications:GetFont()) == "OUTLINE", "the charges or stacks")
assert(select(2, EssentialCooldownViewer.active[1].Cooldown:GetCountdownFontString():GetFont()) == 20, "the countdown is not at the game's size")
assert(BuffIconCooldownViewer.active[2].DebuffBorder:IsShown() and BuffIconCooldownViewer.active[2].DebuffBorder.Texture:GetAlpha() == 1, "the debuff border is not the game's")
-- The bar: our track, fill and hairline on the bar; its fill hangs on the game's.
local it = BuffBarCooldownViewer.active[1]
local bar = it.Bar
assert(bar.BarBG:GetAlpha() == 0 and bar.Pip:GetAlpha() == 0 and bar.Pip:IsShown(), "the bar's BarBG or pip")
assert(ours(bar) == 6, "our track, fill and hairlines on the bar: " .. ours(bar))
local fill
for _, r in ipairs(regions(bar)) do if r.points[1] and r.points[1].rel == bar:GetStatusBarTexture() and r ~= bar.Pip then fill = r end end
local sr, sg, sb = T.Color("sky")
local fr, fg, fb = fill:GetVertexColor()
assert(fr == sr and fg == sg and fb == sb, "the bar's fill is not in the header band's sky")
assert(bar.Name:GetFont() == (T.FontSpec("label")) and bar.Duration:GetFont() == num and it.Icon.Applications:GetFont() == num, "the bar's texts")
assert(not it.Icon.Icon.mask.psStock and ours(it.Icon) == 5 and overlay(it.Icon):GetAlpha() == 0, "the bar's icon")
-- Room between the icons. The game lays items out at Padding less 4 (GetAdditionalPaddingOffset), so at the default Padding 2 the frames overlap by 2 (its rounded mask makes the gap): our tile (ground, hairline, sweep) sits inside each item, leaving a gap of 2.
local e = EssentialCooldownViewer
local first = e.active[1]
local ground, edges
for _, r in ipairs(regions(first)) do if r.layer == "BACKGROUND" and tostring(r:GetTexture()):find("white", 1, true) then ground = r end end
local inset = ground.points[1].x
assert(e.padding + e.offset == -2 and e.padding + e.offset + 2 * inset == 2, "no room between the icons: inset " .. inset)
assert(first.Cooldown.swipe:find("cooldown%-swipe%-50$"), "the sweep is not the inset square: " .. tostring(first.Cooldown.swipe))
-- The border shows: the hairline hangs on the tile's edges over our ground, and the icon (our square mask) sits a unit inside it, so no art lies under the line.
local n = 0
for _, r in ipairs(regions(first)) do if r.layer == "OVERLAY" and r:IsShown() and r.points[1] and r.points[1].rel == ground then n = n + 1 end end
local mask = first.Icon.mask
assert(n == 4 and mask and mask.points[1].x == inset + 1 and mask.points[2].x == -inset - 1, "the hairline lies on the icon's art")
-- A relayout (a spec or settings change) hands back the same pooled frames, still dressed.
stub.cdmRelayout()
stub.advance(0.05)
assert(not EssentialCooldownViewer.active[1].Icon.mask.psStock, "a re-acquired item lost its look")
