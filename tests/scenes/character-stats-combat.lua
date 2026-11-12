--@ title: Character: Stats in combat
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- First opened mid-fight: the stats and name read in the background before it still show, and the model's tooltip takes no secret name.
stub.fire("PLAYER_ENTERING_WORLD")
stub.advance(1)
stub.inCombat = true
PolestarUI.Show("character")
stub.RunScript(PolestarUICharacter.psGear.Model, "OnEnter")
