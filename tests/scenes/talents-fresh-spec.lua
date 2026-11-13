--@ title: Talents: fresh second spec
--@ roots: PolestarUITalents
--@ stubs: stub_talents.lua
-- Dual spec just bought at level 80: Secondary has no combat config until the client makes it after the switch (TRAIT_CONFIG_CREATED); the window never says talents open at level 10, and shows the empty tree with every point to spend once it is there.
function UnitLevel() return 80 end
stub.dual, stub.freshSpec = true, 2
PolestarUI.Show("talents", 2)
local f = PolestarUITalents
assert(f.psEmpty:IsShown() and not f.psEmpty:GetText():find("level 10"), "not activated yet: " .. f.psEmpty:GetText())
f.footerButtons.right[1]:Click()
stub.finishSwitch()
assert(not f.psEmpty:GetText():find("level 10"), "switched, config not made yet: " .. f.psEmpty:GetText())
stub.createConfig()
assert(not f.psEmpty:IsShown() and f.psHeads[1]:IsShown(), "config made: no tree")
assert(f.Subtitle:GetText() == "15 points to spend.", "points: " .. f.Subtitle:GetText())
assert(f.psHeads[1].Spent:GetText() == "0" and f.psHeads[2].Spent:GetText() == "0" and f.psHeads[3].Spent:GetText() == "0", "points spent in a fresh spec")
stub.assertNoErrors()
