--@ title: Character
--@ roots: PolestarUICharacter, PolestarUICharacterStats
PolestarUI.Show("character")
-- The stock pane's last category: the five resistances.
local v = PolestarUICharacterStats.Body
local res = v.sections[#v.sections]
assert(res.name == "Resistance" and res.rows[5]:IsShown() and res.rows[2].Value:GetText() == "15", "resistances")
