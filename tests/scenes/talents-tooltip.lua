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
-- Drag: a learnt active talent picks up its spell (not in combat, where the client blocks it); a passive or unlearnt one does not.
local active, passive, unlearnt
for _, c in ipairs({ PolestarUITalents.Body:GetChildren() }) do if c.psInfo and c:IsShown() then local n = c.psInfo
if n.currentRank > 0 then if active then passive = passive or c else active = c end elseif n.maxRanks == 1 then unlearnt = unlearnt or c end end end
local isPassive = C_Spell.IsSpellPassive
C_Spell.IsSpellPassive = function(id) return id ~= active.psSpell and isPassive(id) end
stub.RunScript(passive, "OnDragStart")
stub.RunScript(unlearnt, "OnDragStart")
assert(not stub.pickedSpell, "a passive or unlearnt talent dragged")
stub.inCombat = true
stub.RunScript(active, "OnDragStart")
stub.inCombat = false
assert(not stub.blocked and not stub.pickedSpell, "dragged in combat")
stub.RunScript(active, "OnDragStart")
assert(stub.pickedSpell == active.psSpell, "no drag")
stub.RunScript(active, "OnEnter")
assert(has("Drag it to an action bar."), "no drag hint")
stub.RunScript(locked, "OnEnter")
