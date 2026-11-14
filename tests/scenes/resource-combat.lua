--@ title: Personal Resource Display: in combat, a heal absorb
--@ roots: PersonalResourceDisplayFrame
--@ stubs: stub_resource.lua
-- In combat every value and the bars' own size are secret: nothing is read, ours follows the game's fill and prediction textures by anchors alone. A heal absorb (shade at 0.55 over the fill's end) and rage.
stub.units.player = { name = "Varian", level = 60, class = "WARRIOR", player = true, health = 2000, max = 3000, power = 60, powerMax = 100, powerType = 1, reaction = 5 }
stub.inCombat = true
local P = PersonalResourceDisplayFrame
local hb = P.HealthBarsContainer.healthBar
assert(issecretvalue(hb:GetWidth()) and issecretvalue(hb:GetValue()), "the stub's bar is not secret in combat")
stub.prd({ healAbsorb = 400 })
stub.advance(0.2)
stub.units.player.health = 1400
stub.prd({ healAbsorb = 400 })
stub.advance(0.2)
assert(#stub.errors == 0, "an error in combat: " .. tostring(stub.errors[1]))
local seg
for _, r in ipairs({ hb:GetRegions() }) do if r.points and r.points[1] and r.points[1].rel == hb.myHealAbsorb then seg = r end end
assert(hb.myHealAbsorb:IsShown() and seg and seg:IsShown() and select(4, seg:GetVertexColor()) == 0.55, "the heal absorb")
local function fill(bar) for _, r in ipairs({ bar:GetRegions() }) do if r.points and r.points[1] and r.points[1].rel == bar:GetStatusBarTexture() and r.points[1].relPoint == "TOPLEFT" then return r end end end
assert(fill(P.PowerBar):IsShown() and select(1, fill(P.PowerBar):GetVertexColor()) == Polestar.Theme.Color("danger"), "rage is not in danger")
stub.inCombat = false
