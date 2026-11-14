--@ title: Character: Skills
--@ roots: PolestarUICharacter, PolestarUICharacterStats
PolestarUI.Show("character", "SkillsFrame")
-- The first skill is chosen; a click on Swords shows its weapon odds in the drawer.
local v = PolestarUICharacter.psPages.SkillsFrame
assert(PolestarUICharacterStats.Title:GetText() == "Mining", "first not chosen")
v.groups[2].rows[1]:Click()
assert(PolestarUICharacterStats.Title:GetText() == "Swords" and v.groups[2].rows[1].Sel:IsShown(), "Swords not chosen")
-- A skill's bonus can be secret even out of combat, Defense's gear bonus too
-- (docs/CLIENT.md, rule 3): both pages still paint, then show the clean ones again.
local swords = C_SkillInfo.GetSkillLineInfo(7)
local defense = UnitDefenseSkill
swords.modifier = stub.secret(5)
PolestarUI.RefreshCharacter()
swords.skillID, swords.modifier = 95, 5
UnitDefenseSkill = function() return 120, stub.secret(3) end
PolestarUI.RefreshCharacter()
swords.skillID, swords.modifier, UnitDefenseSkill = 43, 5, defense
PolestarUI.RefreshCharacter()
