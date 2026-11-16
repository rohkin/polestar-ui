--@ title: Unit frames: the damage trail, health just lost held red under the fill, a heal snapping past it, no red past the new health
--@ roots: PolestarUIPlayerFrame, PolestarUITargetFrame
stub.units.player = { name = "Testchar", level = 24, class = "WARRIOR", player = true, health = 2000, max = 2000, power = 40, powerMax = 100, powerType = 1, reaction = 5 }
stub.units.target = { name = "Kurzen", level = 25, health = 20000, max = 20000, power = 900, powerMax = 1200, powerType = 0, reaction = 2 }
stub.fire("PLAYER_TARGET_CHANGED")
stub.unitWatch()
stub.fire("UNIT_HEALTH", "player")
stub.advance(1)
local P, T = PolestarUIPlayerFrame, PolestarUITargetFrame
local v = function(bar) return stub.reveal(bar:GetValue()) end
local EASE = Enum.StatusBarInterpolation
assert(v(P.Health.trail) == 2000, "the trail starts at the health: " .. tostring(v(P.Health.trail)) .. " " .. tostring(v(P.Health)))
assert(P.Health.trail:GetFrameLevel() < P.Health:GetFrameLevel(), "the trail under the fill")
-- A loss in combat (secret values): the fill drops, the trail holds, then drains eased.
stub.inCombat = true
stub.fire("PLAYER_REGEN_DISABLED")
stub.units.player.health = 1200
stub.fire("UNIT_HEALTH", "player")
assert(v(P.Health) == 1200 and v(P.Health.trail) == 2000, "the lost health held red")
stub.advance(0.5)
assert(v(P.Health.trail) == 1200 and P.Health.trail.interpolation == EASE.ExponentialEaseOut, "then drains, eased")
-- A gain: the fill jumps past the trail, which follows hidden under it.
stub.units.player.health = 1800
stub.fire("UNIT_HEALTH", "player")
assert(v(P.Health) == 1800, "a heal fills at once")
stub.advance(0.5)
assert(v(P.Health.trail) == 1800, "the trail catches up under the fill")
-- The trail is drawn only past the bar's new value (psAim, set at once): a
-- heal past a held trail shows no red ahead of the fill while it eases up.
local function clipped(bar)
	local aim, clip = bar.trail.psAim, bar.trail:GetParent()
	assert(clip.clips and clip.points[1].rel == aim:GetStatusBarTexture(), "the trail clipped at the new value's end")
	-- No butted edge: the clip starts under the fill (which covers it), so no seam of track shows at a fractional scale.
	assert(clip.points[1].x < 0 and bar:GetFrameLevel() > bar.trail:GetFrameLevel(), "the trail's clip reaches under the fill's end")
	assert(aim.interpolation == EASE.Immediate, "the new value set at once")
	local lo, hi = bar:GetMinMaxValues()
	local tlo, thi = bar.trail:GetMinMaxValues()
	local alo, ahi = aim:GetMinMaxValues()
	assert(stub.reveal(hi) == stub.reveal(thi) and stub.reveal(hi) == stub.reveal(ahi), "one maximum for fill, trail and aim")
	return v(aim), v(bar.trail)
end
stub.units.player.health = 1700
stub.fire("UNIT_HEALTH", "player")
stub.units.player.health = 2000
stub.fire("UNIT_HEALTH", "player")
local aim, tr = clipped(P.Health)
assert(P.Health.interpolation == EASE.ExponentialEaseOut and aim == 2000 and tr == 1800, "a heal past the trail: no red ahead of the easing fill " .. aim .. " " .. tr)
stub.advance(0.5)
aim, tr = clipped(P.Health)
assert(aim == 2000 and tr == 2000 and v(P.Health) == 2000, "at full health the trail ends with the fill")
-- Max health up (a buff): fill, trail and aim take it at once.
stub.units.player.max, stub.units.player.health = 2400, 2400
stub.fire("UNIT_MAXHEALTH", "player")
stub.fire("UNIT_HEALTH", "player")
aim = clipped(P.Health)
assert(aim == 2400, "the new maximum in step")
stub.advance(0.5)
stub.units.player.max, stub.units.player.health = 2000, 1800
stub.fire("UNIT_MAXHEALTH", "player")
stub.fire("UNIT_HEALTH", "player")
stub.advance(0.5)
-- A new target snaps its trail (no red from the last one).
stub.units.target = { name = "Paxton", level = 26, health = 5000, max = 20000, power = 30, powerMax = 100, powerType = 1, reaction = 2 }
stub.fire("PLAYER_TARGET_CHANGED")
assert(v(T.Health.trail) == 5000 and T.Health.trail.interpolation == EASE.Immediate, "a new unit snaps its trail")
-- The drawn state: the player mid-trail, the target hit too.
stub.units.player.health = 900
stub.fire("UNIT_HEALTH", "player")
stub.units.target.health = 3000
stub.fire("UNIT_HEALTH", "target")
stub.advance(0.2)
assert(v(P.Health.trail) == 1800 and v(T.Health.trail) == 5000, "both held")
stub.assertNoErrors()
-- Reduce motion (ui.reduceMotion): the fill and the trail snap, no hold, no ease.
Polestar.Set("ui.reduceMotion", true)
stub.units.player.health = 900
stub.fire("UNIT_HEALTH", "player")
assert(v(P.Health) == 900 and v(P.Health.trail) == 900, "reduce motion: the trail snaps at once")
assert(P.Health.trail.interpolation ~= EASE.ExponentialEaseOut and P.Health.interpolation ~= EASE.ExponentialEaseOut, "reduce motion: no easing")
Polestar.Set("ui.reduceMotion", false)
--@ panel
--@ roots: PolestarUIPlayerFrame
--@ saved: PolestarUIDB = { modules = {}, unitframes = { trail = false } }
stub.units.player = { name = "Testchar", level = 24, class = "WARRIOR", player = true, health = 2000, max = 2000, power = 40, powerMax = 100, powerType = 1, reaction = 5 }
stub.advance(1)
stub.units.player.health = 1200
stub.fire("UNIT_HEALTH", "player")
local a = PolestarUIPlayerFrame.Health.trail.barColor[4]
assert(a == 0, "trail off: kept clear")
stub.assertNoErrors()
--@ panel
--@ roots: PolestarUIPlayerFrame
--@ saved: PolestarUIDB = { modules = {}, unitframes = { smooth = false } }
-- Smooth bars off: a heal past a held trail, the fill at once, the trail still clipped at it.
stub.units.player = { name = "Testchar", level = 24, class = "WARRIOR", player = true, health = 2000, max = 2000, power = 40, powerMax = 100, powerType = 1, reaction = 5 }
stub.advance(1)
local H = PolestarUIPlayerFrame.Health
local v = function(bar) return stub.reveal(bar:GetValue()) end
stub.units.player.health = 1500
stub.fire("UNIT_HEALTH", "player")
stub.units.player.health = 2000
stub.fire("UNIT_HEALTH", "player")
assert(H.interpolation == Enum.StatusBarInterpolation.Immediate and v(H) == 2000 and v(H.trail.psAim) == 2000 and v(H.trail) <= 2000, "no red past the fill")
stub.advance(0.5)
assert(v(H.trail) == 2000, "the trail ends with the fill")
