--@ title: World Map: the game's looks
--@ roots: PolestarUIWorldMap
--@ stubs: stub_worldmap.lua
-- In the game's looks (Forever's), the compact grid takes the skin's sizes: 32 tabs, the pad 20; the map keeps its 900 by 600 under them, the tabs, nav and filter (the search in its dropdown) stay on the tab row.
Polestar.Set("ui.skin", "forever")
stub.pressKey("L")
local f = PolestarUIWorldMap
assert(f.TabRow:GetHeight() == 32 and f.psPad == 20, "not the game's looks")
assert(f:GetHeight() == 60 + 32 + 2 + 600 and f:GetWidth() == 902 + 320, "the map's size under the skin's tabs")
assert(not f.Search:IsShown() and f.psFilter:GetParent() == f.TabRow and f.psNav:GetParent() == f.TabRow, "tab row")
