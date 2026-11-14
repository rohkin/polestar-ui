--@ title: Merchant: the game's looks
--@ roots: PolestarUIMerchant
--@ stubs: stub_npc.lua, stub_merchant.lua
-- In the game's looks (Forever's), the compact grid takes the skin's sizes: 32 tabs, the pad 20; the search and money stay on the tab row.
Polestar.Set("ui.skin", "forever")
stub.interact(Enum.PlayerInteractionType.Merchant)
local f = PolestarUIMerchant
assert(f.TabRow:GetHeight() == 32 and f.psPad == 20 and f.Search:GetParent() == f.TabRow and f.psMoney:GetParent() == f.TabRow, "not the game's looks")
