--@ title: Macros: the game's looks
--@ roots: PolestarUIMacros
--@ stubs: stub_macros.lua
-- In the game's looks (Forever's), the compact grid takes the skin's sizes: 32 tabs, the pad 20 and the close button on the frame's corner; the two stock tabs carry their counts.
Polestar.Set("ui.skin", "forever")
ShowMacroFrame()
local f = PolestarUIMacros
assert(f:IsShown() and f.TabRow:GetHeight() == 32 and f.psPad == 20 and not f.Close:IsShown() and not f.Sidebar:IsShown(), "not the game's looks")
assert(#f.tabButtons == 2 and f.tabButtons[1].psNavCount:GetText() == "12/120", "the tabs' counts")
