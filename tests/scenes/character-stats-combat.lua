--@ title: Character: Stats in combat
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- First opened mid-fight: the stats and name read in the background before it still show, and the model's tooltip takes no secret name.
stub.fire("PLAYER_ENTERING_WORLD")
stub.advance(1)
stub.inCombat = true
PolestarUI.Show("character")
stub.RunScript(PolestarUICharacter.psGear.Model, "OnEnter")
-- The gloves' Use: effect waits for the fight to end, and so does an enchant.
local gloves
for _, c in ipairs({ PolestarUICharacter.psGear:GetChildren() }) do if c.psLabel and c:GetID() == 10 then gloves = c end end
stub.RunScript(gloves, "OnEnter")
local tip = table.concat(GameTooltip.lines, "/")
assert(tip:find("Using it waits for the fight to end", 1, true) and not tip:find("Right-click", 1, true), "use hint in combat: " .. tip)
stub.targeting = true
stub.RunScript(gloves, "OnEnter")
assert(table.concat(GameTooltip.lines, "/"):find("Applying it here waits", 1, true), "targeting hint in combat")
stub.targeting = false
GameTooltip:Hide()
