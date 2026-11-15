--@ title: Bags: switched off
--@ roots: PolestarUIBags
--@ stubs: stub_bags.lua
--@ saved: PolestarUIDB = { modules = { bags = false } }
-- Off at login, the game's keys and toggles show the stock frames and ours never opens. The switch is live both ways (docs/CLIENT.md, rule 19): switched on while the stock bags show, they stay until the game closes them (moved shown, their OnHide would run as ours), and the bag bar's next click closes them and opens ours; switched off, ours closes and the stock frames come back closed under their own parent, the game's B showing them again; on again, B is ours. No stock OnShow/OnHide ever runs from our code (the stub reports one). Shown last: ours, open after switching back on.
local said = {}
print = function(m) said[#said + 1] = m end
stub.pressKey("B")
assert(ContainerFrameCombinedBags:IsVisible() and not PolestarUIBags, "off: not the game's bags")
stub.advance(0.05)
assert(ContainerFrameCombinedBags:IsVisible() and not PolestarUIBags, "off: ours took the stock frame")
-- On, with the stock bags open: they stay where they are until closed.
PolestarUI.Switch("bags", true)
assert(ContainerFrameCombinedBags:IsVisible() and ContainerFrameCombinedBags:GetParent() == UIParent, "on: a shown stock frame moved")
stub.clickBackpack()
stub.advance(0.05)
assert(not ContainerFrameCombinedBags:IsShown() and PolestarUIBags:IsShown(), "on: the bag bar did not swap the stock bags for ours")
assert(ContainerFrameCombinedBags:GetParent() ~= UIParent, "on: the closed stock frame not parked")
stub.clickBackpack()
stub.advance(0.05)
assert(not PolestarUIBags:IsShown() and not ContainerFrameCombinedBags:IsVisible(), "on: the bag bar did not close ours")
-- Off, live: the stock frames back closed, the game's B theirs.
stub.pressKey("B")
assert(PolestarUIBags:IsShown(), "on: B did not open ours")
assert(ContainerFrameCombinedBags:IsShown(), "the parked stock frame is not open (the bag bar's last click opened it)")
PolestarUI.Switch("bags", false)
assert(not tostring(said[#said]):find("reload"), "switching off waits for /reload")
assert(not PolestarUIBags:IsShown(), "off: ours left open")
assert(ContainerFrameCombinedBags:GetParent() == UIParent and not ContainerFrameCombinedBags:IsShown(), "off: the stock frame not given back closed")
for i = 1, 7 do assert(_G["ContainerFrame" .. i]:GetParent() == UIParent, "off: ContainerFrame" .. i .. " not given back") end
stub.pressKey("B")
stub.advance(0.05)
assert(ContainerFrameCombinedBags:IsVisible() and not PolestarUIBags:IsShown(), "off: B not the game's at once")
stub.pressKey("B")
assert(not ContainerFrameCombinedBags:IsShown(), "off: the game's B did not close them")
-- On again: B is ours.
PolestarUI.Switch("bags", true)
stub.pressKey("B")
assert(PolestarUIBags:IsShown() and not ContainerFrameCombinedBags:IsVisible(), "on again: B not ours")
