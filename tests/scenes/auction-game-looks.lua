--@ title: Auction House: the game's looks
--@ roots: PolestarUIAuction
--@ stubs: stub_npc.lua, stub_auction.lua
-- In the game's looks (Forever's), the compact grid takes the skin's sizes: 32 tabs, the pad 20; the Search button, the options (the search in their dropdown) and the money stay on the tab row, the category column beside it without Polestar's lockup.
Polestar.Set("ui.skin", "forever")
stub.interact(Enum.PlayerInteractionType.Auctioneer)
local f = PolestarUIAuction
assert(f.TabRow:GetHeight() == 32 and f.psPad == 20, "not the game's looks")
assert(not f.Search:IsShown(), "the search on the tab row")
for _, w in ipairs({ f.psSearchGo, f.psFilter, f.psMoney }) do assert(w:GetParent() == f.TabRow, "off the tab row") end
assert(f.Sidebar:IsShown() and not f.Wordmark:IsVisible() and not f.Emblem:IsVisible(), "the category column, or the lockup")
