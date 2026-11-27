--@ title: Unit frames: the player's frame as a window head (band, rim)
--@ roots: PolestarUIPlayerFrame, PolestarUITargetFrame
-- The player's frame as a Polestar window's head: its health fill is the band's sky under the band's stars (the sparkle), the accent rim and its light run along its top over the bars, the window shadow round it. The stars follow Polestar's Header band, the rim Polestar's Rim, live; the target's frame has no head. In combat it is painted all the same; switched off, it is gone with the frame.
stub.units.player = { name = "Testchar", level = 24, class = "WARRIOR", player = true, health = 1830, max = 2400, power = 45, powerMax = 100, powerType = 1, reaction = 5 }
stub.units.target = { name = "Kurzen", level = 25, health = 12400, max = 20000, power = 900, powerMax = 1200, powerType = 0, reaction = 2 }
stub.fire("PLAYER_TARGET_CHANGED")
stub.unitWatch()
stub.advance(0.3)
local P, Tg = PolestarUIPlayerFrame, PolestarUITargetFrame
local h = P.head
local function rim() local n = 0 for _, t in ipairs(h.rim) do if t:IsVisible() then n = n + 1 end end return n, h.throw:IsVisible() end
local function shown(list) for _, t in ipairs(list) do if not t:IsShown() then return false end end return true end
assert(h and not h.sky and not Tg.head, "the player's frame has no head (or a band over its bars, or the target has one)")
assert(rim() == 4 and h.throw:IsVisible() and P.Health.Sparkle:IsShown() and shown(P.Ground.shadow), "no rim, stars or shadow on the player's frame")
-- The rim along the frame's top, over the bars: on a frame of ours above the health bar, never on the secure button itself.
local top = h.rim[1]:GetParent()
assert(top ~= P and top:GetParent() == P and top:GetFrameLevel() > P.Health:GetFrameLevel() and h.rim[1].points[1].rel == P, "the rim not over the bars")
assert(h.rim[2]:GetWidth() == P:GetWidth() * 0.28 and h.throw:GetHeight() == P:GetHeight(), "the rim not laid out on the frame's size")
-- Polestar's Header band off, live: the stars go (the rim stays); the rim off, live.
Polestar.Set("ui.band", false)
stub.advance(0.3)
assert(not P.Health.Sparkle:IsShown() and rim() == 4, "the stars show with Polestar's header band off (or the rim went with it)")
Polestar.Set("ui.band", nil)
Polestar.Set("ui.rim", false)
stub.advance(0.3)
assert(P.Health.Sparkle:IsShown() and rim() == 0 and not h.throw:IsVisible(), "the rim shows with Polestar's rim off")
Polestar.Set("ui.rim", nil)
stub.advance(0.3)
assert(rim() == 4, "the rim not back")
-- Our own Sparkle option still switches the stars.
PolestarUI.modules.unitframes.SetOption("sparkle", false)
assert(not P.Health.Sparkle:IsShown(), "the Sparkle option no longer hides the stars")
PolestarUI.modules.unitframes.SetOption("sparkle", nil)
-- In combat (secret values, a locked secure frame): painted, nothing protected called.
stub.inCombat = true
stub.fire("PLAYER_REGEN_DISABLED")
stub.fire("UNIT_HEALTH", "player")
assert(rim() == 4 and P.Health.Sparkle:IsShown(), "the head not painted in combat")
stub.inCombat = false
stub.fire("PLAYER_REGEN_ENABLED")
-- Switched off: gone with the frame.
PolestarUI.Switch("unitframes", false)
assert(not P:IsShown() and rim() == 0 and not h.throw:IsVisible() and not P.Health.Sparkle:IsVisible(), "the head still shows with the unit frames off")
PolestarUI.Switch("unitframes", true)
assert(rim() == 4, "not back when on again")
stub.assertNoErrors()
