--@ title: Bank: the game's looks
--@ roots: PolestarUIBank
--@ stubs: stub_npc.lua, stub_bank.lua
-- In the game's looks (Forever's), the compact grid takes the skin's sizes: 32 tabs, the pad 20, the close button on the frame's corner and the search on the tab row.
Polestar.Set("ui.skin", "forever")
stub.interact(Enum.PlayerInteractionType.Banker)
local f = PolestarUIBank
assert(f:IsShown() and f.TabRow:GetHeight() == 32 and f.psPad == 20 and not f.Close:IsShown() and f.Search:GetParent() == f.TabRow, "not the game's looks")
