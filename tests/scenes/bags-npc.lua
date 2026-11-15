--@ title: Bags: at a vendor
--@ roots: PolestarUIMerchant, PolestarUIBags
--@ stubs: stub_npc.lua, stub_merchant.lua, stub_bags.lua
-- Our Merchant opens ours with it (ns.OpenBags), no stock frame shown; another frame's CloseAllBags leaves ours, closing the Merchant closes it (it opened it). Opened by the player first, ours stays when the Merchant closes. Shown last: the vendor and the bags.
local T = Enum.PlayerInteractionType
stub.interact(T.Merchant)
local f = PolestarUIBags
assert(PolestarUIMerchant:IsShown() and f and f:IsShown(), "the vendor did not open ours")
assert(not stub.stockShown.ContainerFrameCombinedBags and not stub.stockOpener(), "the stock bags opened")
CloseAllBags(stub.dispatcher)
stub.advance(0.05)
assert(f:IsShown(), "another frame closed ours")
PolestarUIMerchant:Hide()
assert(not f:IsShown(), "closing the vendor left ours")
stub.pressKey("B")
stub.interact(T.Merchant)
PolestarUIMerchant:Hide()
assert(f:IsShown(), "the vendor closed bags it did not open")
f:Hide()
stub.interact(T.Merchant)
