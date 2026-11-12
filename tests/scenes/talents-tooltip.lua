--@ title: Talents: tooltips
--@ roots: PolestarUITalents
--@ stubs: stub_talents.lua
-- The stock talent tooltip's lines: rank, subtext, this and the next rank's text; a locked talent names its tier gate.
PolestarUI.Show("talents")
local part, locked
for _, c in ipairs({ PolestarUITalents.Body:GetChildren() }) do if c.psInfo and c:IsShown() then local n = c.psInfo
if n.currentRank > 0 and n.currentRank < n.maxRanks then part = c elseif not n.isAvailable then locked = locked or c end end end
local function has(t) for _, l in ipairs(GameTooltip.lines) do if l:find(t, 1, true) then return true end end end
stub.RunScript(part, "OnEnter")
assert(has("Rank 2/") and has("Passive") and has("rank 2]") and has("Next Rank:") and has("rank 3]"), "partial: " .. table.concat(GameTooltip.lines, "/"))
stub.RunScript(locked, "OnEnter")
assert(has("Rank 0/") and has("rank 1]") and not has("Next Rank:") and has(" points in "), "locked: " .. table.concat(GameTooltip.lines, "/"))
