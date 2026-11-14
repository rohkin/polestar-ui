--@ title: World Map: Map Legend
--@ roots: PolestarUIWorldMap
--@ stubs: stub_worldmap.lua
-- The Map Legend tab shows the stock legend in the side column: each category's pin kinds two to a row, a quest kind on its number circle.
stub.pressKey("M")
local f = PolestarUIWorldMap
f.tabButtons[2]:Click()
assert(f.psLegend:IsShown() and not f.psQuests:IsShown() and f.tabButtons[2].Label:GetText() == "Map Legend", "legend")
