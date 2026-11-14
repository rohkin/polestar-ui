--@ title: Personal Resource Display: Edit Mode's settings
--@ roots: PersonalResourceDisplayFrame
--@ stubs: stub_resource.lua
-- Edit Mode's settings stay the game's and ours follows them: Size 120%, Bar Width 130%, a taller health bar, padding and Show Bar Text, then Hide Power and back. Ours hangs only on the game's bars, so nothing of ours is moved or sized and nothing of the game's is touched (the stub's guards).
stub.units.player = { name = "Jaina", level = 60, class = "MAGE", player = true, health = 1800, max = 2400, power = 2400, powerMax = 4000, powerType = 0, reaction = 5 }
stub.prd({ absorb = 200 })
stub.enterEditMode()
stub.prdEdit({ size = 120, width = 130, health = 22, padding = 2, barText = true })
stub.advance(0.1)
local P = PersonalResourceDisplayFrame
local hb, pb = P.HealthBarsContainer.healthBar, P.PowerBar
assert(P:GetScale() == 1.2 and P:GetWidth() == 260 and P.HealthBarsContainer:GetHeight() == 22, "Edit Mode's settings were undone")
local function fill(bar) for _, r in ipairs({ bar:GetRegions() }) do if r.points and r.points[1] and r.points[1].rel == bar:GetStatusBarTexture() and r.points[1].relPoint == "TOPLEFT" then return r end end end
assert(fill(hb):IsShown() and fill(pb):IsShown(), "ours does not show in Edit Mode")
assert(hb.TextString:IsShown() and hb.TextString:GetText() == "1800 / 2400" and hb.TextString:GetFont() == (Polestar.Theme.FontSpec("number")), "Show Bar Text: the game's text in our face")
-- Hide Power: the game hides its bar, ours with it.
stub.prdEdit({ hidePower = true })
stub.advance(0.1)
assert(not pb:IsShown() and not fill(pb):IsVisible(), "ours shows on a hidden power bar")
stub.prdEdit({ hidePower = false })
stub.exitEditMode()
stub.advance(0.1)
assert(pb:IsShown() and fill(pb):IsVisible(), "the power bar is not back")
