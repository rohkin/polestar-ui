--@ title: Character: Statistics, a category open
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- A heading opens its category, and a sub-category row opens under it, each redrawn at once.
PolestarUI.Show("character", "StatisticsFrame")
local v = PolestarUICharacter.psPages.StatisticsFrame
v.groups[1].Hit:Click()
v.groups[1].rows[3]:Click()
