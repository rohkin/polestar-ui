--@ title: Professions: the game's looks
--@ roots: PolestarUIProfessions
--@ stubs: stub_spellbook.lua, stub_professions.lua
-- In the game's looks (Forever's), the compact grid takes the skin's sizes: the pad 20, the close button on the frame's corner; the slim rail of icons stays 48 wide.
Polestar.Set("ui.skin", "forever")
PolestarUI.Show("professions")
local f = PolestarUIProfessions
assert(f.psPad == 20 and not f.Close:IsShown() and f.psRail == 48, "not the game's looks")
