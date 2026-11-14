--@ title: Personal Resource Display: class colour (Edit Mode's Show Class Color, a Druid in cat form; Polestar's Class colour)
--@ roots: PersonalResourceDisplayFrame
--@ stubs: stub_resource.lua
-- Edit Mode's Show Class Color on: the health in the class colour (the game's flag, read, never written). A Druid in cat form: energy, and the game's alt bar with the mana in the npc token.
stub.units.player = { name = "Malfurion", level = 60, class = "DRUID", player = true, health = 2100, max = 2400, power = 70, powerMax = 100, powerType = 3, reaction = 5 }
stub.prdEdit({ classColor = true })
stub.prd({ alt = true, mana = 2600, manaMax = 4000 })
stub.advance(0.1)
local P, T = PersonalResourceDisplayFrame, Polestar.Theme
local function fill(bar) for _, r in ipairs({ bar:GetRegions() }) do if r.points and r.points[1] and r.points[1].rel == bar:GetStatusBarTexture() and r.points[1].relPoint == "TOPLEFT" then return r end end end
local function is(tex, r, g, b) local x, y, z = tex:GetVertexColor() return x == r and y == g and z == b end
assert(is(fill(P.HealthBarsContainer.healthBar), T.ClassColor("DRUID")), "Show Class Color: not the druid's colour")
assert(P.AlternatePowerBar:IsShown() and is(fill(P.AlternatePowerBar), T.Color("npc")), "the alt bar's mana")
assert(is(fill(P.PowerBar), T.Color("warning")), "energy is not in warning")
stub.prdEdit({ classColor = false })
stub.advance(0.1)
assert(is(fill(P.HealthBarsContainer.healthBar), T.Color("sky")), "Show Class Color off: not sky")
stub.prdEdit({ classColor = true })
stub.advance(0.1)
--@ panel
--@ roots: PersonalResourceDisplayFrame
--@ stubs: stub_resource.lua
--@ saved: PolestarDB = { schema = 1, settings = { ui = { classAccent = true } } }
-- Polestar's Class colour on, Edit Mode's off: the class colour too.
stub.units.player = { name = "Valeera", level = 60, class = "ROGUE", player = true, health = 1700, max = 2400, power = 80, powerMax = 100, powerType = 3, reaction = 5 }
stub.prd({})
stub.advance(0.1)
local P, T = PersonalResourceDisplayFrame, Polestar.Theme
local hb = P.HealthBarsContainer.healthBar
local found
for _, r in ipairs({ hb:GetRegions() }) do
	if r.points and r.points[1] and r.points[1].rel == hb:GetStatusBarTexture() and r.points[1].relPoint == "TOPLEFT" then
		local x, y, z = r:GetVertexColor()
		local cr, cg, cb = T.ClassColor("ROGUE")
		found = x == cr and y == cg and z == cb
	end
end
assert(found, "Polestar's Class colour: not the rogue's colour")
