--@ title: Legacy: the game's looks
--@ roots: PolestarUILegacy
--@ stubs: stub_legacy.lua
-- In the game's looks (Forever's), the compact grid takes the skin's sizes: 32 tabs, the pad 20; the filter (the search in its dropdown) stays on the tab row.
Polestar.Set("ui.skin", "forever")
PolestarUI.Show("legacy", "challenges")
local f = PolestarUILegacy
assert(f.TabRow:GetHeight() == 32 and f.psPad == 20 and not f.Search:IsShown() and f.psFilter:GetParent() == f.TabRow and f.Rail:GetWidth() == 48, "not the game's looks")
