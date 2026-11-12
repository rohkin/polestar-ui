--@ title: Bank: buying a tab
--@ roots: PolestarUIBank, PolestarModal
--@ stubs: stub_npc.lua, stub_bank.lua
-- "Buy a tab" is a row while one can be bought: it opens the game's prompt with the tab's cost (red when the player cannot pay) and does not select itself; Buy buys it, the new tab joins the list, and the row goes once no more can be bought.
local T = Enum.PlayerInteractionType
stub.interact(T.Banker)
local f = PolestarUIBank
local function row(label)
	for _, b in ipairs(f.navButtons) do if b:IsShown() and b.Label:GetText() == label then return b end end
end
row("Buy a tab"):Click()
assert(PolestarModal:IsShown() and PolestarModal.Box.Title:GetText() == "Purchase Bank Tab", "no prompt")
assert(f.Title:GetText() == "Gear", "the buy row was selected")
PolestarModal.Box.Action:Click()
assert(stub.boughtTab == 0, "not bought")
assert(row("Tab 3"), "the new tab is not listed")
stub.tabCost[0] = nil
stub.fire("BANK_TABS_CHANGED", 0)
local n = 0
for _, b in ipairs(f.navButtons) do if b:IsShown() and b.Label:GetText() == "Buy a tab" then n = n + 1 end end
assert(n == 1, "the row stayed with no tab to buy")
-- The Warband tab costs more than the player has: its cost shows in danger.
stub.fire("BANK_TABS_CHANGED", 2)
row("Buy a tab"):Click()
assert(PolestarModal:IsShown(), "no Warband prompt")
local cost
for _, c in ipairs({ PolestarModal.Box:GetChildren() }) do if c:IsShown() and c.psParts then cost = c end end
local r, g, b = cost.psParts[1].text:GetTextColor()
local dr, dg, db = Polestar.Theme.Color("danger")
assert(r == dr and g == dg and b == db and tostring(cost.psParts[1].text:GetText()) == "1000", "cost not in danger")
