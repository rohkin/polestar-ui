--@ title: Unit frames: incoming heals, shields past the missing health, a heal absorb, the cast's power cost, the sparkle
--@ roots: PolestarUIPlayerFrame, PolestarUITargetFrame, PolestarUIFocusFrame
stub.cvars.statusText = "1"
stub.cvars.statusTextDisplay = "BOTH"
stub.units.player = { name = "Testchar", level = 24, class = "PRIEST", player = true, health = 1400, max = 2400, heals = 300, absorbs = 500, power = 2600, powerMax = 4000, powerType = 0, reaction = 5 }
stub.units.target = { name = "Kurzen", level = 25, health = 12400, max = 20000, healAbsorbs = 3000, power = 900, powerMax = 1200, powerType = 0, reaction = 2 }
stub.units.focus = { name = "Paxton", level = 26, class = "WARRIOR", player = true, health = 1500, max = 2000, heals = 200, absorbs = 900, power = 30, powerMax = 100, powerType = 1, reaction = 5 }
stub.fire("PLAYER_TARGET_CHANGED")
stub.fire("PLAYER_FOCUS_CHANGED")
stub.unitWatch()
stub.advance(0.3)
local P, T, F = PolestarUIPlayerFrame, PolestarUITargetFrame, PolestarUIFocusFrame
local v = function(bar) return stub.reveal(bar:GetValue()) end
-- The client's calculator: heals up to the missing health, shields up to what is still missing after them.
assert(v(P.Heal) == 300 and v(P.Absorb) == 500, "heal then shield: " .. tostring(v(P.Heal)) .. ", " .. tostring(v(P.Absorb)))
assert(v(F.Heal) == 200 and v(F.Absorb) == 300, "the shield is clamped to the missing health")
assert(v(T.HealAbsorb) == 3000, "a heal absorb eats into the fill")
-- Smooth bars: the client eases the fill (secrets allowed); a new unit snaps.
stub.fire("UNIT_HEALTH", "player")
assert(P.Health.interpolation == Enum.StatusBarInterpolation.ExponentialEaseOut, "health eased")
assert(P.Power.interpolation == Enum.StatusBarInterpolation.ExponentialEaseOut, "power eased")
stub.fire("PLAYER_TARGET_CHANGED")
assert(T.Health.interpolation == Enum.StatusBarInterpolation.Immediate, "a new target snaps")
-- The sparkle: Polestar's band stars, static over the health bar, in the star token.
local S = P.Health.Sparkle
assert(not T.Health.psSpark and not F.Health.psSpark, "stars on the player frame only")
assert(S:IsShown() and S.texture:find("band%-stars") and not S.mask and not S.animGroups, "static stars on the bar")
-- The power cost of a cast, from its start till it ends.
stub.spellCosts = { [2061] = { { type = 0, cost = 600 } } }
stub.casting = { spellID = 2061 }
stub.fire("UNIT_SPELLCAST_START", "player", "cast-1", 2061)
assert(v(P.cost) == 600, "cost shown while casting: " .. tostring(v(P.cost)))
stub.casting = nil
stub.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-1", 2061)
assert(v(P.cost) == 0, "cost cleared after the cast")
stub.casting = { spellID = 2061 }
stub.fire("UNIT_SPELLCAST_START", "player", "cast-2", 2061)
stub.fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-x", 17)
assert(v(P.cost) == 600, "an instant cast mid-cast keeps the cost")
stub.assertNoErrors()
