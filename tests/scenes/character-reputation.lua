--@ title: Character: Reputation
--@ roots: PolestarUICharacter, PolestarUICharacterStats
PolestarUI.Show("character", "ReputationFrame")
-- Friendship, renown and paragon standings, as the stock bars draw them.
local g = PolestarUICharacter.psPages.ReputationFrame.groups[2]
assert(g.rows[1].Value:GetText() == "Ally" and g.rows[2].Value:GetText() == "Renown 4" and g.rows[3].Value:GetText() == "Exalted", "standings: " .. tostring(g.rows[1].Value:GetText()) .. "/" .. tostring(g.rows[2].Value:GetText()))
assert(g.rows[3].Paragon:IsShown() and g.rows[3].ParagonCheck:IsShown() and not g.rows[2].Paragon:IsShown(), "paragon bag")
assert(math.abs(g.rows[2].Bar.psFrac - 0.4) < 0.001 and math.abs(g.rows[1].Bar.psFrac - 0.25) < 0.001, "bars")
stub.RunScript(g.rows[1], "OnEnter")
assert(GameTooltip.lines[1] == "Wrathion (3 / 5)", "friendship tooltip: " .. GameTooltip.lines[1])
stub.RunScript(g.rows[3], "OnEnter")
assert(table.concat(GameTooltip.lines, "/"):find("A reward waits", 1, true), "paragon tooltip")
GameTooltip:Hide()
