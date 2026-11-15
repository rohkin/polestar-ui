--@ title: Bags: in combat
--@ roots: PolestarUIBags
--@ stubs: stub_bags.lua
-- In combat B still opens and closes ours (no secure frame in it), and a right-click still uses the item: the template's own click. Counts and cooldowns come secret: no error, and the name read before combat stays. Shown last: open mid-fight after a bag update.
PolestarUI.Show("bags")
PolestarUIBags:Hide()
stub.inCombat = true
stub.secretBags = true
stub.pressKey("B")
local f = PolestarUIBags
assert(f:IsShown(), "B did not open ours in combat")
stub.pressKey("B")
assert(not f:IsShown(), "B did not close ours in combat")
stub.pressKey("B")
local function secureIn(fr)
	if tostring(fr.template or ""):find("Secure") then return fr end
	for _, c in ipairs(fr.children) do
		local s = secureIn(c)
		if s then return s end
	end
end
assert(not secureIn(f), "a secure frame in ours")
stub.mouseClick(PolestarUIBagsItem1, {}, "RightButton")
assert(stub.used[1] and stub.used[1][1] == 0 and stub.used[1][2] == 1, "no use in combat")
stub.fire("BAG_UPDATE_DELAYED")
assert(not tostring(f.Subtitle:GetText()):find("secret"), "a secret name shown")
