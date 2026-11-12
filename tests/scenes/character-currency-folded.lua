--@ title: Character: Currency, a group folded
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- A click on a group's chevron folds it, and the page redraws without an event.
PolestarUI.Show("character", "TokenFrame")
PolestarUICharacter.psPages.TokenFrame.groups[1].Hit:Click()
