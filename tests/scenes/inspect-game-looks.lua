--@ title: Inspect: the game's looks
--@ roots: PolestarUIInspect
--@ stubs: stub_inspect.lua
-- In the game's looks (Forever's), the compact grid takes the skin's sizes: 32 tabs, the pad 20; the stock tabs stay top tabs.
Polestar.Set("ui.skin", "forever")
InspectUnit("target")
stub.inspectReady("target")
local f = PolestarUIInspect
assert(f:IsShown() and f.TabRow:GetHeight() == 32 and f.psPad == 20 and f.tabButtons[3]:IsShown(), "not the game's looks")
