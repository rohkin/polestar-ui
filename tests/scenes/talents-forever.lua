--@ title: Talents: Talents Forever
--@ roots: PolestarUITalents
--@ stubs: stub_talents.lua, stub_talentsforever.lua
-- With Talents Forever loaded, a footer button opens its planner and its next planned point is ringed.
PolestarUI.Show("talents")
local f = PolestarUITalents
local b = f.footerButtons.left[2]
assert(b and b:IsShown() and b.Label:GetText() == "Talents Forever", "no Talents Forever button")
stub.RunScript(b, "OnClick")
assert(stub.tfToggled == 1, "Toggle not called")
local ring = f.psNext
assert(ring:IsShown() and ring.psNode == stub.tfNext, "ring not on the next node")
assert(select(2, ring:GetPoint(1)).psNode == stub.tfNext, "ring not anchored to the node's button")
-- Its setting off, or a plan for another class: no ring; a plan change redraws.
TalentsForeverBook.db.settings.overlay = false
stub.tfFire("PLAN_CHANGED")
assert(not ring:IsShown(), "ring with the overlay setting off")
TalentsForeverBook.db.settings.overlay = true
TalentsForeverBook.plan.cls = "WARRIOR"
PolestarUI.Show("talents")
assert(not ring:IsShown(), "ring for another class's plan")
TalentsForeverBook.plan.cls = "MAGE"
stub.tfFire("GAME_CHANGED")
assert(ring:IsShown(), "ring not back")
