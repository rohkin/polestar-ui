--@ title: Nameplates: a plate added mid-fight
--@ roots: NamePlate1, NamePlate2
--@ stubs: stub_nameplates.lua
-- In combat: plates come and go, their health is secret (it reaches the bars unread), a cast starts, an aura lands; everything of ours is a widget call, so nothing waits for the fight to end.
stub.inCombat, stub.aurasSecret = true, true
stub.addPlate("nameplate1", { name = "Defias Pillager", level = 18, reaction = 2, health = 310, max = 1000, auras = { { icon = 136207 } } })
stub.plateCast("nameplate1", { name = "Fireball", time = 3, elapsed = 2 })
stub.addPlate("nameplate2", { name = "Defias Thug", level = 17, reaction = 2, health = 900, max = 900 })
stub.targetPlate("nameplate2")
stub.advance(0.1)
local hb = NamePlate1.UnitFrame.healthBar
local l = PolestarUI.modules.nameplates.look(NamePlate1.UnitFrame)
assert(issecretvalue(l.bar:GetValue()) and l.box:IsShown() and hb.bgTexture:GetAlpha() == 0 and hb.barTexture:GetAlpha() == 0, "the plate is not ours in combat")
-- Health changes mid-fight reach our bar unread.
stub.updatePlate("nameplate1", { health = 120 })
assert(stub.reveal(l.bar:GetValue()) == 120, "a health change in combat did not reach our bar")
assert(NamePlate1.UnitFrame.CastBarsContainer.castBar:GetChildren():IsShown(), "the cast bar is not ours in combat")
stub.inCombat, stub.aurasSecret = false, false
