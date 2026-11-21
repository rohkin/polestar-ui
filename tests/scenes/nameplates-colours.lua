--@ title: Nameplates: threat, tapped, a secret identity
--@ roots: NamePlate1, NamePlate2, NamePlate3, NamePlate4
--@ stubs: stub_nameplates.lua
-- The fill is the target frame's colour for the unit (H.UnitColor), whatever the threat: with the game's threat colours on (nameplateThreatDisplay, read off the game's own flag) the threat shows as the target frame shows it, a glow in the game's threat colour round the bar. A mob tapped by another in textMuted; a plate whose identity the client keeps secret: the target frame's fallback (nothing compared), ours still drawn.
local T, H = Polestar.Theme, PolestarUI.HUD
local NP = PolestarUI.modules.nameplates
stub.cvarBits.nameplateThreatDisplay = { [1] = true, [3] = true }
stub.addPlate("nameplate1", { name = "Gnoll Brute", level = 12, reaction = 4, threat = 1, health = 700, max = 1000 })
stub.addPlate("nameplate2", { name = "Gnoll Mystic", level = 12, reaction = 2, threat = 3, health = 900, max = 1000 })
stub.addPlate("nameplate3", { name = "Murloc Raider", level = 11, reaction = 2, tapped = true, health = 300, max = 600 })
stub.addPlate("nameplate4", { name = "Arena Foe", level = 30, reaction = 2, player = true, class = "MAGE", secret = true, health = 500, max = 1000 })
stub.advance(0.1)
local function l(p) return NP.look(p.UnitFrame) end
local function is(t, r, g, b)
	local x, y, z = t:GetVertexColor()
	return t:IsShown() and x == r and y == g and z == b
end
local function filled(k, r, g, b)
	local x, y, z = k.bar:GetStatusBarColor()
	return k.bar:IsVisible() and x == r and y == g and z == b
end
for i, unit in ipairs({ "nameplate1", "nameplate2", "nameplate3", "nameplate4" }) do
	assert(filled(l(_G["NamePlate" .. i]), H.UnitColor(unit)), unit .. "'s fill is not the target frame's colour")
end
assert(filled(l(NamePlate1), T.Color("warning")) and filled(l(NamePlate2), T.Color("danger")), "threat coloured the fill")
assert(filled(l(NamePlate3), T.Color("textMuted")), "a tapped mob is not in textMuted")
-- Threat: the game's threat colour on the edge, with the glow.
local tr, tg, tb = GetThreatStatusColor(3)
local g2 = l(NamePlate2).ground
assert(is(g2.edges[1], tr, tg, tb) and g2.glow[1]:IsShown(), "threat on the player does not glow in the threat colour")
assert(l(NamePlate4).name:IsShown() and not tostring(stub.reveal(l(NamePlate4).name:GetText())):find("30", 1, true), "a secret level was read")
-- Threat drops: the edge goes back to the border.
stub.updatePlate("nameplate2", { threat = 0 })
assert(is(g2.edges[1], T.Color("windowBorder")) and not g2.glow[1]:IsShown(), "the threat edge stayed")
assert(filled(l(NamePlate2), T.Color("danger")), "a hostile mob without threat is not in danger")
