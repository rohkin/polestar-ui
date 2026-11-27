--@ title: Settings: the Bags in Polestar's Move frames, placed through our saved place
--@ roots: PolestarUIBags
--@ stubs: stub_npc.lua, stub_bags.lua
-- Polestar's movers (absent in the preview, which loads only Polestar's Core and Theme): a stand-in records the registration.
local spec
Polestar.Movers = { Register = function(s) spec = s; return true end }
PolestarUI.Show("bags")
assert(spec and spec.key == "PolestarUIBags" and spec.label == "Bags", "no mover for the bags")
assert(spec.frame() == PolestarUIBags, "mover frame")
local point = spec.get()
assert(point == "BOTTOMRIGHT", "default place: " .. tostring(point))
-- A move lands in PolestarUIDB.pos as our own drag saves it.
spec.set("TOPLEFT", "BOTTOMLEFT", 200, 700)
local k = PolestarUIBags:GetEffectiveScale() / UIParent:GetEffectiveScale()
local p = PolestarUIDB.pos.PolestarUIBags
assert(p and math.abs(p[1] - 200 / k) < 0.01 and math.abs(p[2] - 700 / k) < 0.01, "set not saved")
local _, _, x, y = spec.get()
assert(math.abs(x - 200) < 0.01 and math.abs(y - 700) < 0.01, "get does not read it back")
spec.reset()
assert(PolestarUIDB.pos.PolestarUIBags == nil and spec.get() == "BOTTOMRIGHT", "reset")
spec.set("TOPLEFT", "BOTTOMLEFT", 300, 600)
-- Dragged by its header (Polestar's ns.DragWindow): the new place is saved.
local f = PolestarUIBags
local l0, t0 = f:GetLeft(), f:GetTop()
stub.dragHeader(f, 80, -50)
p = PolestarUIDB.pos.PolestarUIBags
local _, rel, _, x, y = f:GetPoint(1)
assert(rel == UIParent and math.abs(x - (l0 + 80 / k)) < 1e-6 and math.abs(y - (t0 - 50 / k)) < 1e-6, "the header did not drag it")
assert(p and p[1] == x and p[2] == y, "drag not saved")
