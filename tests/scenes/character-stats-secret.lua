--@ title: Character: Stats gone secret
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- Stats read once, then secret out of combat: the rows keep what they read, and no secret reaches our strings.
PolestarUI.Show("character")
stub.secretStats = true
stub.fire("UNIT_STATS", "player")
