--@ title: Social: the game's looks
--@ roots: PolestarUISocial
--@ stubs: stub_social.lua
-- In the game's looks (Forever's), the compact grid takes the skin's sizes: 32 tabs, the pad 20, the close button on the frame's corner; the five pages are top tabs and the search sits on the tab row.
Polestar.Set("ui.skin", "forever")
PolestarUI.Show("social")
local f = PolestarUISocial
assert(f.TabRow:GetHeight() == 32 and f.psPad == 20 and not f.Close:IsShown() and f.Search:GetParent() == f.TabRow, "not the game's looks")
