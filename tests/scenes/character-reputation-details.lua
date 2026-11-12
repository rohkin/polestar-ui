--@ title: Character: a faction's details, at war
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- A click on Ironforge shows its details; the drawer's checkboxes set it at war, inactive and on the experience bar.
PolestarUIDB.hideStats = true
PolestarUI.Show("character", "ReputationFrame")
local v = PolestarUICharacter.psPages.ReputationFrame
v.groups[1].rows[2]:Click()
assert(PolestarUICharacterStats:IsShown(), "the drawer stays shut")
local sf = PolestarUICharacterStats.panes.reputation.psView
assert(PolestarUICharacterStats.Title:GetText() == "Ironforge" and v.groups[1].rows[2].Sel:IsShown(), "not chosen")
sf.checks[1]:Click()
assert(stub.atWar == 3 and sf.checks[1].Box:GetChecked(), "not at war")
sf.checks[3]:Click()
assert(stub.watched == 3, "not watched")
assert(PolestarUICharacter.Subtitle:GetText() == "Watching Ironforge", "subtitle: " .. tostring(PolestarUICharacter.Subtitle:GetText()))
sf.checks[2]:Click()
assert(stub.inactive == 3 and sf.checks[2].Box:GetChecked(), "not inactive")
