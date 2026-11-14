--@ title: Cast bars, Class colour on: warlock, priest, rogue
--@ roots: PlayerCastingBarFrame, PolestarUITargetFrame, TargetFrameSpellBar, PolestarUIFocusFrame, FocusFrameSpellBar
--@ stubs: stub_castbars.lua
--@ saved: PolestarDB = { schema = 1, settings = { ui = { classAccent = true } } }
stub.units.player = { name = "Gul'dan", level = 80, class = "WARLOCK", player = true, health = 1830, max = 2400, reaction = 5 }
stub.units.target = { name = "Paxton", level = 80, class = "PRIEST", player = true, health = 12400, max = 20000, reaction = 5 }
stub.units.focus = { name = "Valeera", level = 80, class = "ROGUE", player = true, health = 2000, max = 2000, reaction = 5 }
stub.fire("PLAYER_TARGET_CHANGED")
stub.fire("PLAYER_FOCUS_CHANGED")
stub.unitWatch()
stub.cast("player", { name = "Shadow Bolt", time = 2.5, elapsed = 1.5 })
stub.cast("target", { name = "Smite", time = 3, elapsed = 1.8 })
stub.cast("focus", { name = "Crippling Poison", time = 3, elapsed = 2, channel = true })
stub.advance(0.1)
local function fill(bar) local box = bar:GetChildren() for _, r in ipairs({ box:GetRegions() }) do if r.points and r.points[1] and r.points[1].rel == bar:GetStatusBarTexture() then return r end end end
local T = Polestar.Theme
local r, g, b = T.ClassColor("PRIEST")
local x, y, z = fill(TargetFrameSpellBar):GetVertexColor()
assert(x == r and y == g and z == b, "the priest's cast is not in the priest's class colour")
