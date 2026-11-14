--@ title: Cooldown Viewer: Edit Mode, Icon Size 120%, vertical, name-only bars
--@ roots: EssentialCooldownViewer, UtilityCooldownViewer, BuffIconCooldownViewer, BuffBarCooldownViewer
--@ stubs: stub_cooldowns.lua
-- Edit Mode's viewer settings stay the game's. In Edit Mode every viewer shows, empty ones with the game's sample items (on the same pooled frames, dressed like the real ones). The essential viewer at Icon Size 120%, the utility viewer vertical with Padding 2, the bars name only and 260 wide with the timer off: each setting re-lays the viewer out (release and acquire); ours hangs on the items, so it follows, and leaving Edit Mode repaints the hairlines at the new scale. Nothing of ours moved, scaled, hid or wrote a key on a viewer or item (the stub's guards).
stub.cdm({ essential = { { icon = { 0.75, 0.3, 0.2 }, cd = 0.6, time = "12" }, { icon = { 0.3, 0.5, 0.85 }, charges = "2" } } })
stub.advance(0.05)
stub.enterEditMode()
stub.advance(0.05)
for _, v in ipairs(stub.cooldownViewers) do
	assert(v:IsShown() and #v.active > 0, v:GetName() .. " shows no items in Edit Mode")
end
assert(not BuffIconCooldownViewer.active[1].Icon.mask.psStock and BuffBarCooldownViewer.active[1].Bar.BarBG:GetAlpha() == 0, "the sample items are not dressed")
stub.editCooldowns("EssentialCooldownViewer", { iconSize = 120 })
stub.editCooldowns("UtilityCooldownViewer", { horizontal = false, padding = 2 })
stub.editCooldowns("BuffBarCooldownViewer", { barContent = "NameOnly", barWidth = 260, timer = false })
stub.advance(0.05)
local e = EssentialCooldownViewer.active[1]
assert(e:GetScale() == 1.2 and EssentialCooldownViewer:GetWidth() == 2 * 60 + 2 - 4, "Icon Size was undone")
assert(not e.Icon.mask.psStock and e.Cooldown:GetCountdownFontString():GetFont() == (Polestar.Theme.FontSpec("number")), "a resized item lost its look")
assert(UtilityCooldownViewer:GetHeight() == 2 * 30 + 2 - 4, "the utility viewer is not vertical")
local it = BuffBarCooldownViewer.active[1]
assert(it:GetWidth() == 260 and not it.Icon:IsShown() and not it.Bar.Duration:IsShown() and it.Bar.Name:IsShown(), "Bar Content, Bar Width or the timer were undone")
assert(it.Bar.BarBG:GetAlpha() == 0, "a name-only bar lost its look")
-- Leaving Edit Mode: the samples are released (the game's), the essential viewer keeps its size; back in Edit Mode for the picture.
stub.exitEditMode()
stub.advance(0.05)
assert(#UtilityCooldownViewer.active == 0 and #BuffBarCooldownViewer.active == 0, "the samples stay after Edit Mode")
assert(EssentialCooldownViewer.active[1]:GetScale() == 1.2 and not EssentialCooldownViewer.active[1].Icon.mask.psStock, "the essential viewer after Edit Mode")
stub.enterEditMode()
stub.advance(0.05)
