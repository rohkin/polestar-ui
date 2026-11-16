--@ title: Nameplates: a pooled frame on another unit
--@ roots: NamePlate1, NamePlate2
--@ stubs: stub_nameplates.lua
-- The game hands a plate's UnitFrame back to its pool when the unit goes and to the next unit that comes: it already wears ours (made once per pooled frame, no second set), in the new unit's colour.
local T = Polestar.Theme
stub.cvars.nameplateShowFriendlyNpcs = "1"
stub.addPlate("nameplate1", { name = "Defias Pillager", level = 18, reaction = 2, health = 620, max = 1000 })
stub.addPlate("nameplate2", { name = "Young Wolf", level = 3, reaction = 4, health = 40, max = 80 })
stub.advance(0.1)
local uf = NamePlate1.UnitFrame
local count = select("#", uf.healthBar:GetRegions()) + select("#", uf.healthBar:GetChildren())
stub.removePlate("nameplate1")
stub.advance(0.1)
local p = stub.addPlate("nameplate3", { name = "Stormwind Guard", level = 30, reaction = 5, health = 1000, max = 1000 })
stub.advance(0.1)
assert(p == NamePlate1 and p.UnitFrame == uf, "the pool did not hand the same frame on")
assert(select("#", uf.healthBar:GetRegions()) + select("#", uf.healthBar:GetChildren()) == count, "a second set of ours on a pooled frame")
local l = PolestarUI.modules.nameplates.look(uf)
local sr, sg, sb = PolestarUI.HUD.UnitColor("nameplate3")
local x, y, z = l.bar:GetStatusBarColor()
assert(x == sr and y == sg and z == sb, "the reused frame is not in the new unit's colour")
assert(l.name:GetText():find("30", 1, true) and l.name:GetText():find("Stormwind Guard", 1, true), "the reused frame's level and name are the old unit's: " .. tostring(l.name:GetText()))
assert(issecretvalue(l.bar:GetValue()) and stub.reveal(l.bar:GetValue()) == 1000, "the reused frame's health is the old unit's")
