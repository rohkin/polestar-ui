--@ title: Unit frames: in combat (secret values, a new target, a layout queued)
--@ roots: PolestarUIPlayerFrame, PolestarUITargetFrame, PolestarUITargetToT
stub.cvars.statusText = "1"
stub.cvars.statusTextDisplay = "BOTH"
stub.units.player = { name = "Testchar", level = 24, class = "WARRIOR", player = true, health = 900, max = 2400, power = 80, powerMax = 100, powerType = 1, reaction = 5 }
stub.inCombat = true
stub.fire("PLAYER_REGEN_DISABLED")
-- A new target mid-fight: the secure unit watch shows ours; we only paint.
stub.units.target = { name = "Hogger", level = 11, health = 300, max = 1200, power = 0, powerMax = 0, reaction = 2, classification = "rareelite", threat = 2 }
stub.units.targettarget = stub.units.player
stub.fire("PLAYER_TARGET_CHANGED")
stub.unitWatch()
stub.advance(0.3)
local P, T = PolestarUIPlayerFrame, PolestarUITargetFrame
assert(T:IsShown() and PolestarUITargetToT:IsShown(), "target shown by the unit watch")
assert(issecretvalue(T.Health:GetValue()) and issecretvalue(P.Power:GetValue()), "secrets handed to the bars")
assert(T.healthText:GetText() == "300 || 25%", "both, from secrets: " .. tostring(T.healthText:GetText()))
assert(T.levelText:GetText() == "11R+", "rank chip: " .. tostring(T.levelText:GetText()))
-- A layout applied in combat: ours cannot move now (protected), and wait.
local _, _, _, x0 = P:GetPoint(1)
stub.applyLayout({ [PlayerFrame] = { 300, 650 } })
stub.advance(0.1)
assert(select(4, P:GetPoint(1)) == x0, "not moved in combat")
-- The fight ends: placed.
stub.inCombat = false
stub.fire("PLAYER_REGEN_ENABLED")
assert(select(4, P:GetPoint(1)) == PlayerFrame.Selection:GetLeft(), "placed after combat")
stub.applyLayout({ [PlayerFrame] = { 260, 760 } })
stub.advance(0.1)
-- Back in the fight for the picture: the player's edge in danger.
stub.inCombat = true
stub.fire("PLAYER_REGEN_DISABLED")
-- A vehicle: the player's frame shows it, and its clicks follow (toggleForVehicle).
stub.vehicle = true
stub.units.vehicle = { name = "Demolisher", level = 24, health = 5000, max = 8000, power = 50, powerMax = 100, powerType = 3, reaction = 5 }
stub.fire("UNIT_ENTERED_VEHICLE", "player")
assert(P.Name:GetText() == "Demolisher", "vehicle shown: " .. tostring(P.Name:GetText()))
