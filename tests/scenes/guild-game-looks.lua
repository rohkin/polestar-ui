--@ title: Guild: the game's looks
--@ roots: PolestarUIGuild
--@ stubs: stub_guild.lua
-- In the game's looks (Forever's), the compact grid takes the skin's sizes: 32 tabs, the pad 20; the search and filter stay on the tab row.
Polestar.Set("ui.skin", "forever")
PolestarUI.Show("guild")
local f = PolestarUIGuild
assert(f.TabRow:GetHeight() == 32 and f.psPad == 20 and f.psSearch:GetParent() == f.TabRow and f.psFilter:GetParent() == f.TabRow, "not the game's looks")
