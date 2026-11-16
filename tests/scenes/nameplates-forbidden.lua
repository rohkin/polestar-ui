--@ title: Nameplates: a forbidden plate untouched
--@ roots: NamePlate1, NamePlate2
--@ stubs: stub_nameplates.lua
-- A friendly plate in an instance is a forbidden plate: the client never hands it to addon code and ours never touches it (the stub errors on any use); it keeps the game's look but for the face, which comes from the shared font families. The enemy beside it is ours.
stub.cvars.nameplateShowFriendlyPlayers = "1"
stub.addPlate("nameplate1", { name = "Defias Pillager", level = 18, reaction = 2, health = 620, max = 1000 })
stub.addPlate("nameplate2", { name = "Ayla", level = 30, reaction = 5, player = true, class = "PRIEST", forbidden = true, health = 800, max = 1000 })
stub.targetPlate("nameplate2")
stub.advance(0.1)
local uf = rawget(NamePlate2, "UnitFrame")
local hb = rawget(uf, "healthBar")
assert(select("#", hb:GetChildren()) == 0 and PolestarUI.modules.nameplates.look(uf) == nil, "a frame of ours on a forbidden plate")
assert(#C_NamePlate.GetNamePlates() == 1, "a forbidden plate was listed")
assert(NamePlate1.UnitFrame.healthBar.bgTexture:GetAlpha() == 0, "the enemy beside it is not ours")
