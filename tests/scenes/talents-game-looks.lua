--@ title: Talents: the game's looks
--@ roots: PolestarUITalents
--@ stubs: stub_talents.lua
-- In the game's looks (Forever's), the compact grid takes the skin's sizes: 32 tabs, the pad 20, the close button on the frame's corner and the menu on the pad.
Polestar.Set("ui.skin", "forever")
PolestarUI.Show("talents")
local f = PolestarUITalents
assert(f.TabRow:GetHeight() == 32 and f.psPad == 20 and not f.Close:IsShown() and not f.Search:IsShown() and f.psFilter:GetParent() == f.TabRow, "not the game's looks")
