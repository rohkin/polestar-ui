--@ title: Cooldown Viewer, Class colour on: a mage's buff bars
--@ roots: BuffBarCooldownViewer
--@ stubs: stub_cooldowns.lua
--@ saved: PolestarDB = { schema = 1, settings = { ui = { classAccent = true } } }
-- With Polestar's "Class colour", the buff bars' fill is the player's class colour (H.FillColor, as the cast bars).
stub.units.player = { name = "Jaina", level = 80, class = "MAGE", player = true, health = 2000, max = 2000, reaction = 5 }
stub.cdm({ bars = { { icon = { 0.85, 0.7, 0.25 }, name = "Ice Barrier", left = 15, duration = 30, stacks = "2" }, { icon = { 0.3, 0.5, 0.85 }, name = "Arcane Intellect", left = 24, duration = 30 } } })
stub.advance(0.05)
local bar = BuffBarCooldownViewer.active[1].Bar
local fill
for _, r in ipairs({ bar:GetRegions() }) do if r.points[1] and r.points[1].rel == bar:GetStatusBarTexture() and r ~= bar.Pip then fill = r end end
local r, g, b = Polestar.Theme.ClassColor("MAGE")
local x, y, z = fill:GetVertexColor()
assert(x == r and y == g and z == b, "the bar's fill is not the mage's class colour")
