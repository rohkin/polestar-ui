--@ title: Character: an enchant started while open
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- An enchant started from the bags while the window is open: the game's "show it" must not close it.
PolestarUI.Show("character")
ShowCharacterFrameIfMatchesContext()
assert(PolestarUICharacter:IsShown(), "the window closed")
