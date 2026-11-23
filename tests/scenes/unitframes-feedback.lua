--@ title: Unit frames: damage and heal text on the player's and pet's portraits
--@ roots: PolestarUIPlayerFrame, PolestarUIPetFrame
stub.units.player = { name = "Testchar", level = 24, class = "WARRIOR", player = true, health = 1800, max = 2400, power = 80, powerMax = 100, powerType = 1, reaction = 5 }
stub.units.pet = { name = "Wolf", level = 23, health = 700, max = 900, power = 60, powerMax = 100, powerType = 3, reaction = 5 }
stub.secure(function() PetFrame:Show() end)
stub.unitWatch()
stub.fire("UNIT_PET", "player")
stub.advance(0.1)
local P, Pet = PolestarUIPlayerFrame, PolestarUIPetFrame
assert(PetHitIndicator:GetParent():GetAlpha() == 0, "the stock pet's hit text veiled")

-- A secret crit, then it fades as stock's (0.2 in, 0.7 held, 0.3 out).
stub.inCombat = true
stub.combat("player", "WOUND", "CRITICAL", 12345)
assert(P.feedback:IsShown() and P.feedback.text:GetText() == "12,345", "crit: " .. tostring(P.feedback.text:GetText()))
assert(select(2, P.feedback.text:GetFont()) == 30, "crit 1.5 times: " .. tostring(select(2, P.feedback.text:GetFont())))
stub.advance(0.1)
assert(P.feedback:GetAlpha() > 0 and P.feedback:GetAlpha() < 1, "fading in")
stub.advance(1.3)
assert(not P.feedback:IsShown(), "faded out")

-- Another unit's combat does not reach the player's; the pet's goes to the pet's.
stub.combat("target", "WOUND", "", 99)
assert(not P.feedback:IsShown(), "the target's damage on the player")
stub.combat("pet", "HEAL", "", 500)
assert(Pet.feedback:IsShown() and Pet.feedback.text:GetText() == "500", "pet heal")
local r, g, b = Pet.feedback.text:GetTextColor()
assert(r == 0 and g == 1 and b == 0, "heals green")
DODGE = DODGE or "Dodge"
stub.combat("pet", "DODGE")
assert(Pet.feedback.text:GetText() == DODGE, "a dodge: " .. tostring(Pet.feedback.text:GetText()))

-- Drawn: a magic hit held on the player, a heal on the pet.
stub.combat("player", "WOUND", "", 842, 4)
stub.combat("pet", "HEAL", "", 500)
stub.advance(0.4)
assert(P.feedback:GetAlpha() == 1, "held")
stub.inCombat = false
stub.assertNoErrors()
