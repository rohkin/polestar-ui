--@ title: Mail: the game's looks
--@ roots: PolestarUIMail
--@ stubs: stub_npc.lua, stub_mail.lua
-- In the game's looks (Forever's), the compact grid takes the skin's sizes: 32 tabs, the pad 20.
Polestar.Set("ui.skin", "forever")
stub.interact(Enum.PlayerInteractionType.MailInfo)
local f = PolestarUIMail
assert(f.TabRow:GetHeight() == 32 and f.psPad == 20, "not the game's looks")
