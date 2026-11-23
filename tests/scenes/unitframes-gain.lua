--@ title: Unit frames: the gain, health just gained shown in success from the trail's end to the fill's end, gone once the trail catches up
--@ roots: PolestarUIPlayerFrame
stub.units.player = { name = "Testchar", level = 24, class = "WARRIOR", player = true, health = 1000, max = 2000, power = 40, powerMax = 100, powerType = 1, reaction = 5 }
stub.unitWatch()
stub.fire("UNIT_HEALTH", "player")
stub.advance(1)
local B = PolestarUIPlayerFrame.Health
local t = B.trail
local v = function(bar) return stub.reveal(bar:GetValue()) end
-- The gain hangs off the trail's end and reaches the fill's end: no value of its own.
local gain = t.psGain:GetParent()
local clip = gain:GetParent()
assert(clip.clips and clip.points[1].rel == t:GetStatusBarTexture(), "the gain clipped from the trail's end")
assert(gain.points[2].rel == B:GetStatusBarTexture() and gain.points[1].rel == B, "the gain from the bar's left to the fill's end")
assert(clip:GetFrameLevel() > B:GetFrameLevel() and B:GetFrameLevel() > t:GetFrameLevel(), "the gain over the fill, the trail under it")
local r, g, b = Polestar.Theme.Color("success")
local c = t.psGain.vertexColor
assert(c[1] == r and c[2] == g and c[3] == b and c[4] == 1, "the gain in success")
-- A heal in combat (secret values): the fill takes it, the trail holds the old
-- health, so the gain shows 1000..1700; then the trail catches up and it is gone.
stub.inCombat = true
stub.fire("PLAYER_REGEN_DISABLED")
stub.units.player.health = 1700
stub.fire("UNIT_HEALTH", "player")
assert(v(B) == 1700 and v(t) == 1000, "the gain shown: trail held under the new health")
stub.advance(0.5)
assert(v(t) == 1700 and t.interpolation == Enum.StatusBarInterpolation.ExponentialEaseOut, "the trail eases to the fill: the gain gone")
-- The damage trail still works: a loss holds red, the gain empty (trail past the fill).
stub.units.player.health = 900
stub.fire("UNIT_HEALTH", "player")
assert(v(B) == 900 and v(t) == 1700, "a loss held red")
stub.advance(0.5)
assert(v(t) == 900, "then drained")
-- Reduce motion: no hold, so no gain.
Polestar.Set("ui.reduceMotion", true)
stub.units.player.health = 1500
stub.fire("UNIT_HEALTH", "player")
assert(v(t) == 1500, "reduce motion: the trail with the fill, no gain")
Polestar.Set("ui.reduceMotion", false)
-- A regen tick (Smooth on), the trail caught up level with the fill: the red
-- ends inside the fill, never at its edge (a red fringe there in game), and
-- the bar clips it on the left; the gain still starts at the trail's value.
stub.units.player.health = 1510
stub.fire("UNIT_HEALTH", "player")
stub.advance(0.5)
assert(B.interpolation == Enum.StatusBarInterpolation.ExponentialEaseOut and v(t) == 1510 and v(B) == 1510, "the trail level with the fill")
local w, x = 200, {} -- any bar width: the anchors decide
for _, p in ipairs(t.points) do x[p.point] = p.x; assert(p.rel == B, "the trail hangs off the bar") end
local redEnd = x.TOPLEFT + (w + x.BOTTOMRIGHT - x.TOPLEFT) * 1510 / 2000
assert(redEnd <= w * 1510 / 2000 - 1, "no red at the fill's end: " .. redEnd .. " vs " .. w * 1510 / 2000)
assert(t.psAim.clips and t:GetParent():GetParent() == t.psAim, "the red clipped to the bar")
assert(clip.points[1].x == -x.BOTTOMRIGHT, "the gain from the trail's value")
-- The drawn state: mid-gain, 900 to 1600 of 2000.
stub.units.player.health = 900
stub.fire("UNIT_HEALTH", "player")
stub.advance(0.5)
stub.units.player.health = 1600
stub.fire("UNIT_HEALTH", "player")
stub.advance(0.2)
assert(v(t) == 900 and v(B) == 1600, "drawn mid-gain")
stub.assertNoErrors()
--@ panel
--@ roots: PolestarUIPlayerFrame
--@ saved: PolestarUIDB = { modules = {}, unitframes = { trail = false } }
stub.units.player = { name = "Testchar", level = 24, class = "WARRIOR", player = true, health = 2000, max = 2000, power = 40, powerMax = 100, powerType = 1, reaction = 5 }
stub.advance(1)
stub.units.player.health = 1200
stub.fire("UNIT_HEALTH", "player")
assert(PolestarUIPlayerFrame.Health.trail.psGain.vertexColor[4] == 0, "trail off: the gain kept clear too")
stub.assertNoErrors()
