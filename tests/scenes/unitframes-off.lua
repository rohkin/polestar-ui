--@ title: Unit frames: switched off, the game's are back
--@ roots: PlayerFrame, TargetFrame, PolestarUIPlayerFrame
stub.units.target = { name = "Defias Pillager", level = 25, health = 12400, max = 20000, reaction = 2 }
stub.fire("PLAYER_TARGET_CHANGED")
stub.unitWatch()
-- Refused in combat (secure frames cannot change then).
stub.inCombat = true
PolestarUI.Switch("unitframes", false)
assert(PolestarUIPlayerFrame:IsShown(), "no switch in combat")
stub.inCombat = false
PolestarUI.Switch("unitframes", false)
assert(not PolestarUIPlayerFrame:IsShown() and not PolestarUITargetFrame:IsShown(), "ours hidden")
assert(PlayerFrame:IsMouseEnabled() and PlayerFrame.PlayerFrameContainer:IsShown() and PlayerFrame.PlayerFrameContent.PlayerFrameContentMain:IsShown(), "stock player back")
assert(TargetFrameToT:GetAlpha() == 1 and TargetFrameToT:IsMouseEnabled(), "stock target of target back")
-- A target change while off: ours stay hidden (the unit watch is off).
stub.fire("PLAYER_TARGET_CHANGED")
stub.unitWatch()
assert(not PolestarUITargetFrame:IsShown(), "ours stay off")
-- And on again, live.
PolestarUI.Switch("unitframes", true)
assert(PolestarUITargetFrame:IsShown() and not PlayerFrame:IsMouseEnabled(), "back on")
PolestarUI.Switch("unitframes", false)
