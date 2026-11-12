--@ title: Merchant: restock
--@ roots: PolestarUIMerchant
--@ stubs: stub_npc.lua, stub_merchant.lua
-- Polestar's Restock in the footer: its plan's total in the label, what it buys in the tooltip, a press runs Polestar's Restock. Gone when the plan is empty or this Polestar has no Restock export.
local T = Enum.PlayerInteractionType
local plan = {
	{ i = 1, id = 159, name = "Refreshing Spring Water", need = 20, items = 20, cost = 500, price = 25, perStack = 1 },
	{ i = 2, id = 2512, name = "Rough Arrow", need = 1000, items = 1000, cost = 50, price = 10, perStack = 200 },
}
stub.restock(plan)
stub.repairCost, stub.junk = nil, 0
stub.interact(T.Merchant)
local w = PolestarUIMerchant
local b = w.footerButtons.right[1]
assert(b:IsShown() and tostring(b.Label:GetText()) == "Restock (5s 50c)", "the Restock label")
assert(b.psTipLines[1] == "20 Refreshing Spring Water" and b.psTipLines[2] == "1000 Rough Arrow", "the Restock tooltip")
b:Click()
assert(stub.restocked == 1, "a press did not run Polestar's Restock")

for i = #plan, 1, -1 do plan[i] = nil end
stub.fire("BAG_UPDATE_DELAYED")
assert(not w.Footer:IsShown(), "an empty plan kept the button")
stub.restock(nil)
stub.fire("MERCHANT_UPDATE")
assert(not w.Footer:IsShown(), "no export, yet a button")

stub.restock({ { i = 3, id = 4540, name = "Tough Hunk of Bread", need = 10, items = 10, cost = 250, price = 25, perStack = 1 } })
stub.fire("MERCHANT_UPDATE")
assert(tostring(w.footerButtons.right[1].Label:GetText()) == "Restock (2s 50c)", "the plan back")

-- Polestar hidden: no Restock button, as Polestar's own; shown again through POLESTAR_HIDDEN.
local hidden = true
Polestar.Hidden = function() return hidden end
Polestar.Fire("POLESTAR_HIDDEN", true)
assert(not w.Footer:IsShown(), "Restock kept while Polestar is hidden")
hidden = false
Polestar.Fire("POLESTAR_HIDDEN", false)
assert(w.footerButtons.right[1]:IsShown() and tostring(w.footerButtons.right[1].Label:GetText()) == "Restock (2s 50c)", "Restock did not come back")
Polestar.Hidden = nil
