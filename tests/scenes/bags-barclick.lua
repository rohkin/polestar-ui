--@ title: Bags: the bag bar
--@ roots: PolestarUIBags
--@ stubs: stub_bags.lua
-- The bag bar stays the game's (docs/CLIENT.md, rule 17): its clicks run the stock toggles on the stock frames, parked under a hidden frame of ours (rule 19), so none shows and no stock OnShow/OnHide runs; ours follows at the frame's end, and the stock frame's new items stay new. A second click closes ours; shift-click (all bags), a bag slot, the game's own bag key and the keyring alike. Shown last: open from the keyring, the new item from the stock frame glowing.
local function well(bag, slot)
	for i = 1, 200 do
		local w = _G["PolestarUIBagsItem" .. i]
		if not w then return end
		if w.psBag == bag and w.psSlot == slot then return w end
	end
end
local f = function() return PolestarUIBags end
stub.newItems["2:1"] = true
stub.clickBackpack()
assert(ContainerFrameCombinedBags:IsShown() and not ContainerFrameCombinedBags:IsVisible() and not stub.stockShown.ContainerFrameCombinedBags, "the stock frame showed")
stub.advance(0.05)
assert(f() and f():IsShown(), "ours did not open")
assert(well(2, 1).psNew:IsShown(), "the stock frame's new item lost")
stub.clickBackpack()
assert(not ContainerFrameCombinedBags:IsShown(), "the stock toggle did not close its frame")
stub.advance(0.05)
assert(not f():IsShown(), "a second click did not close ours")
stub.keys.shift = true
stub.clickBackpack()
stub.keys.shift = false
stub.advance(0.05)
assert(f():IsShown(), "shift-click did not open ours")
for i = 1, 7 do assert(not _G["ContainerFrame" .. i]:IsVisible(), "ContainerFrame" .. i .. " showed") end
stub.clickBagSlot(2)
stub.advance(0.05)
assert(not f():IsShown(), "a bag slot did not close ours")
-- A bag key: ours, never the stock frame.
stub.pressKey("F10")
assert(not ContainerFrameCombinedBags:IsVisible() and f():IsShown(), "TOGGLEBAG2 not ours")
stub.pressKey("F10")
stub.newItems["2:1"] = true
stub.clickBagSlot(KEYRING_CONTAINER)
assert(not ContainerFrame7:IsVisible(), "the keyring frame showed")
stub.advance(0.05)
assert(f():IsShown() and well(2, 1).psNew:IsShown(), "the keyring did not open ours")
