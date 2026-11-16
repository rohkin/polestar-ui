--@ title: Nameplates: the game's plates switched off, then on
--@ roots: NamePlate1
--@ stubs: stub_nameplates.lua
-- With nameplateShowEnemies off (the player's choice, or another addon's) the client makes no plate and ours draws nothing; nothing of ours turns it back on (no CVar is written). The player turns them on: the plate is ours at once.
stub.cvars.nameplateShowEnemies = "0"
assert(stub.addPlate("nameplate1", { name = "Defias Pillager", level = 18, reaction = 2, health = 620, max = 1000 }) == nil, "a plate the CVars hide")
stub.advance(0.1)
assert(#C_NamePlate.GetNamePlates() == 0 and #stub.cvarsWrittenByUs() == 0, "a plate shows or a CVar was written")
stub.setCVar("nameplateShowEnemies", "1")
stub.advance(0.1)
assert(NamePlate1.UnitFrame.healthBar.bgTexture:GetAlpha() == 0, "the plate is not ours once the player turns plates on")
assert(#stub.cvarsWrittenByUs() == 0, "a CVar was written")
