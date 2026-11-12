--@ title: Character: Skills
--@ roots: PolestarUICharacter, PolestarUICharacterStats
PolestarUI.Show("character", "SkillsFrame")
-- The first skill is chosen; a click on Swords shows its weapon odds in the drawer.
local v = PolestarUICharacter.psPages.SkillsFrame
assert(PolestarUICharacterStats.Title:GetText() == "Mining", "first not chosen")
v.groups[2].rows[1]:Click()
assert(PolestarUICharacterStats.Title:GetText() == "Swords" and v.groups[2].rows[1].Sel:IsShown(), "Swords not chosen")
