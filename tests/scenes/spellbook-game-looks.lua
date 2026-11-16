--@ title: Spellbook: the game's looks
--@ roots: PolestarUISpellbook
--@ stubs: stub_spellbook.lua
-- In the game's looks (Forever's), the compact grid takes the skin's sizes: 32 tabs, the pad 20, the close button on the frame's corner and the menu on the pad.
Polestar.Set("ui.skin", "forever")
PolestarUI.Show("spellbook", "line3")
local f = PolestarUISpellbook
assert(f.TabRow:GetHeight() == 32 and f.psPad == 20 and not f.Close:IsShown() and f.psFilter:GetParent() == f.TabRow, "not the game's looks")
