--@ title: Crafting: the game's looks
--@ roots: PolestarUICrafting
--@ stubs: stub_spellbook.lua, stub_professions.lua, stub_crafting.lua
-- In the game's looks (Forever's), the compact grid takes the skin's sizes: the pad 20, the close button on the frame's corner; the search and filter head the recipe list; the slim rail of icons stays 48 wide, and the window is the Professions window's size.
Polestar.Set("ui.skin", "forever")
stub.profSlots = true
stub.openTradeSkill()
local f = PolestarUICrafting
assert(f.psPad == 20 and not f.Close:IsShown() and f.psRail == 48 and f.Search:GetParent() == f.Sidebar and f.psFilter:GetParent() == f.Sidebar, "not the game's looks")
PolestarUI.Show("professions")
assert(PolestarUIProfessions:GetWidth() == f:GetWidth() and PolestarUIProfessions:GetHeight() == f:GetHeight(), "not one size")
PolestarUIProfessions:Hide()
