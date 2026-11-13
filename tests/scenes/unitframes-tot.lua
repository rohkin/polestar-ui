--@ title: Unit frames: the target of target hides as the game's does
--@ roots: PolestarUITargetFrame, PolestarUITargetToT
stub.cvars.statusText = "1"
stub.units.target = { name = "Kobold Vermin", level = 3, health = 0, max = 50, dead = true, reaction = 2 }
stub.units.targettarget = { name = "Testchar", level = 24, player = true, health = 1000, max = 1000, reaction = 5 }
stub.fire("PLAYER_TARGET_CHANGED")
stub.unitWatch()
assert(PolestarUITargetFrame:IsShown() and not PolestarUITargetToT:IsShown(), "a dead target: no target of target")
stub.units.target = { name = "Kobold Miner", level = 4, health = 60, max = 80, reaction = 2 }
stub.fire("PLAYER_TARGET_CHANGED")
stub.unitWatch()
assert(PolestarUITargetToT:IsShown(), "alive: shown")
-- The game's Target of Target option off: none.
stub.cvars.showTargetOfTarget = "0"
stub.fire("CVAR_UPDATE", "showTargetOfTarget")
stub.unitWatch()
assert(not PolestarUITargetToT:IsShown(), "option off")
stub.cvars.showTargetOfTarget = "1"
stub.fire("CVAR_UPDATE", "showTargetOfTarget")
stub.unitWatch()
assert(PolestarUITargetToT:IsShown(), "option on")
