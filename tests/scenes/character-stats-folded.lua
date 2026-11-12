--@ title: Character: a stats category folded
--@ roots: PolestarUICharacter, PolestarUICharacterStats
PolestarUI.Show("character")
local v = PolestarUICharacterStats.Body
v.sections[2].Hit:Click()
assert(not v.sections[2].Panel:IsShown(), "not folded")
assert(PolestarUIDB.statsFolded[v.sections[2].name], "not kept")
