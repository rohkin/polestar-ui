--@ title: Character: Honor
--@ roots: PolestarUICharacter, PolestarUICharacterStats
PolestarUI.Show("character", "PVPRankFrame")
-- The details: the season's progress against this week's cap, its rise, and the next rank's rewards.
local all = {}
for _, t in ipairs({ PolestarUICharacterStats.panes.honor.psView.Child:GetRegions() }) do if t.GetText and t:IsShown() and t:GetText() then all[#all + 1] = t:GetText() end end
local text = table.concat(all, "/")
assert(text:find("Season progress: 11240 / 14000", 1, true) and text:find("rose by 2000", 1, true) and text:find("Rank 6 rewards", 1, true), "honor details: " .. text)
