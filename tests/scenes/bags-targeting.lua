--@ title: Bags: an enchant waiting for its item
--@ roots: PolestarUIBags
--@ stubs: stub_bags.lua
-- Choosing an enchant opens the bags matching it (GameEvent's OpenAllBagsMatchingContext): ours opens, that frame its opener, the stock frame parked (never shown). A left-click applies the enchant through the template's own script (UseContainerItem, untainted), nothing picked up. Another frame's CloseAllBags leaves ours, its opener's closes it; opened by the player first, it stays. Shown last: opened by the player, the enchant waiting.
local function well(bag, slot)
	for i = 1, 200 do
		local w = _G["PolestarUIBagsItem" .. i]
		if not w then return end
		if w.psBag == bag and w.psSlot == slot then return w end
	end
end
stub.selectEnchant()
assert(not ContainerFrameCombinedBags:IsVisible(), "the stock frame showed")
stub.advance(0.05)
local f = PolestarUIBags
assert(f and f:IsShown(), "the enchant did not open ours")
stub.mouseClick(well(0, 3), {}, "LeftButton")
assert(stub.used[1] and stub.used[1][1] == 0 and stub.used[1][2] == 3 and not stub.picked, "the left-click did not apply the enchant")
stub.targeting = false
CloseAllBags(UIParent)
stub.advance(0.05)
assert(f:IsShown(), "another frame closed ours")
CloseAllBags(stub.dispatcher)
stub.advance(0.05)
assert(not f:IsShown(), "its opener did not close ours")
stub.pressKey("B")
stub.selectEnchant()
stub.advance(0.05)
CloseAllBags(stub.dispatcher)
stub.advance(0.05)
assert(f:IsShown(), "the enchant's close shut bags the player opened")
