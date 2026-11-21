--@ title: Nameplates: enemy, rare, neutral, friendly, target, focus
--@ roots: NamePlate1, NamePlate2, NamePlate3, NamePlate4, NamePlate5
--@ stubs: stub_nameplates.lua
-- The game's own plates in the unit frames' look. A bar of our own over the game's (the game's fill, ground, selection art, texts and level badge faded): as wide as the plate's content (the level badge's gap is the bar's), a little taller than the game's, the unit frames' ground (track, hairline), a flat fill in the target frame's colour (H.UnitColor: hostile danger, neutral warning, friendly sky). The level (in its difficulty colour) and the name in the row above the bar, centred and as wide as the plate; the health text (the game's option) inside at the right. The target glows in its colour, the focus has a flat warning hairline, and while there is a target the other plates are dimmed. The elite marker and the raid icon stay the game's. No CVar is written.
local T, H = Polestar.Theme, PolestarUI.HUD
local NP = PolestarUI.modules.nameplates
local function is(tex, r, g, b) local x, y, z = tex:GetVertexColor() return x == r and y == g and z == b end
local function filled(l, r, g, b) local x, y, z = l.bar:GetStatusBarColor() return l.bar:IsVisible() and x == r and y == g and z == b end
stub.cvars.nameplateShowFriendlyNpcs = "1"
stub.cvarBits.nameplateInfoDisplay = { [1] = true }
local elite = stub.addPlate("nameplate1", { name = "Defias Pillager", level = 18, reaction = 2, classification = "elite", health = 620, max = 1000 })
local rare = stub.addPlate("nameplate2", { name = "Thistlenettle", level = 20, reaction = 2, classification = "rare", health = 1000, max = 1000 })
local neutral = stub.addPlate("nameplate3", { name = "Young Wolf", level = 3, reaction = 4, health = 40, max = 80 })
local friend = stub.addPlate("nameplate4", { name = "Town Guard", level = 30, reaction = 5, health = 900, max = 1000 })
local marked = stub.addPlate("nameplate5", { name = "Deadwood Den Watcher", level = 54, reaction = 2, raidTarget = 8, health = 300, max = 300 })
stub.targetPlate("nameplate1")
stub.focusPlate("nameplate3")
stub.advance(0.1)
local e, n, f, m = NP.look(elite.UnitFrame), NP.look(neutral.UnitFrame), NP.look(friend.UnitFrame), NP.look(marked.UnitFrame)
-- The fill: the target frame's colour for the same unit, on a bar of ours that takes the secret health.
for unit, l in pairs({ nameplate1 = e, nameplate3 = n, nameplate4 = f }) do
	assert(filled(l, H.UnitColor(unit)), unit .. "'s fill is not the target frame's colour")
end
assert(filled(e, T.Color("danger")) and filled(n, T.Color("warning")) and filled(f, T.Color("sky")), "hostile, neutral, friendly")
assert(issecretvalue(e.bar:GetValue()), "the health did not reach our bar")
local uf = elite.UnitFrame
local hb, ld = uf.healthBar, uf.PlayerLevelDiffFrame
-- Ours is sized by us and placed by anchors on the game's containers: the plate's whole content width (the game's bar stops short of its level badge), taller than the game's bar.
-- (Thin: the game's 13-high bar, 2 units higher and down to 1 unit above the cast area, 2 under the game's bar: 16.)
local tl, br = e.box.points[1], e.box.points[2]
assert(e.box:GetParent() == hb and ld:IsShown(), "our bar is not under the game's health bar, beside its level badge")
assert(tl.point == "TOPLEFT" and tl.rel == uf.HealthBarsContainer and tl.relPoint == "TOPLEFT" and tl.y == 2, "our bar's top is not 2 units over the game's")
assert(br.point == "BOTTOMRIGHT" and br.rel == uf.CastBarsContainer and br.relPoint == "TOPRIGHT" and br.x == 0 and br.y == 1,
	"our bar does not reach the plate's right edge (the level badge's gap) and the cast area")
-- The level and name in the row above the bar, one centred string as wide as the plate: a long name is whole.
assert(e.name:IsShown() and e.name:GetText():find("18", 1, true) and e.name:GetText():find("Defias Pillager", 1, true), "the level and name: " .. tostring(e.name:GetText()))
assert(e.name.points[1].rel == e.box and e.name.points[1].relPoint == "TOPLEFT" and e.name.justifyH == "CENTER", "the name is not in the row above the bar")
assert(m.name:GetText():find("Deadwood Den Watcher", 1, true) and m.name.points[1].x == -12 and m.name.points[2].x == 12, "a long name has not the plate's whole width")
-- The health text, as the game's option asks, inside at the right; the game's own faded with its bar.
assert(e.health:GetText() == "62%" and e.health.points[1].point == "RIGHT", "the health text: " .. tostring(e.health:GetText()))
assert(hb.LeftText:IsShown() and hb.LeftText:GetAlpha() == 0 and hb.barTexture:GetAlpha() == 0, "the game's health text or fill is not faded")
assert(ld.playerLevelDiffIcon:GetAlpha() == 0 and ld.playerLevelDiffText:GetAlpha() == 0 and ld.selectedBorder:GetAlpha() == 0,
	"the game's level badge is not faded")
assert(uf.name:IsShown() and uf.name:GetAlpha() == 0, "the game's name is not faded while ours shows")
-- The game colours its bar again (a health change, a new colour): its fill stays faded.
stub.updatePlate("nameplate1", { health = 500, tapped = true })
assert(hb.barTexture:GetAlpha() == 0 and e.health:GetText() == "50%", "the game's fill came back, or our health text did not follow")
stub.updatePlate("nameplate1", { tapped = false })
assert(filled(e, T.Color("danger")) and hb.barTexture:GetAlpha() == 0, "the colour did not follow")
-- The ground and edges: the target the plain border (Polestar's window border; the dim of the others marks it), the focus a flat warning hairline, the others the border and the dim; untinted, Polestar's window shadow instead of a glow.
assert(e.ground.fill:IsShown() and not e.ground.glow[1]:IsShown() and is(e.ground.edges[1], T.Color("windowBorder")), "the target does not have the plain border")
assert(not n.ground.glow[1]:IsShown() and is(n.ground.edges[1], T.Color("warning")), "the focus has no flat warning hairline")
assert(not f.ground.glow[1]:IsShown() and is(f.ground.edges[1], T.Color("windowBorder")), "another plate's edge is not the border")
assert(f.dim:IsShown() and not e.dim:IsShown() and not n.dim:IsShown(), "the plates that are not the target or focus are not dimmed")
assert(hb.bgTexture:GetAlpha() == 0 and hb.selectedBorder:GetAlpha() == 0 and hb.deselectedOverlay:GetAlpha() == 0 and hb.totalAbsorb:GetAlpha() == 0,
	"the game's ground, selection art or absorb art is not faded")
assert(hb.selectedBorder:IsShown(), "the game's own regions were hidden")
assert(rare.UnitFrame.ClassificationFrame:IsShown() and marked.UnitFrame.RaidTargetFrame:IsShown(), "the game's markers do not show")
assert((SystemFont_NamePlate:GetFont()) == (T.FontSpec("number")), "the game's plate texts are not in Polestar's face")
assert(#stub.cvarsWrittenByUs() == 0, "a CVar was written")
-- The target moves: the dim follows. No target: no plate is dimmed.
stub.targetPlate("nameplate5")
assert(not m.ground.glow[1]:IsShown() and not m.dim:IsShown() and e.dim:IsShown(), "the dim did not follow the target")
stub.targetPlate(nil)
assert(not e.dim:IsShown() and not f.dim:IsShown(), "plates are dimmed with no target")
-- The name inside the bar where the game's style has no row above it (Modern): the bar at the game's 20, the name cut at the health text.
stub.setCVar("nameplateStyle", "0")
stub.advance(0.1)
assert(e.name.points[1].point == "LEFT" and e.name.points[2].rel == e.health and e.box.points[1].y == 0, "Modern: the name is not inside the bar")
stub.setCVar("nameplateStyle", "1")
stub.advance(0.1)
stub.targetPlate("nameplate1")
-- The game scales plates with distance and selection (here a selected far plate at 1080p: 0.711 x 0.8 x 1.2). The bar sits inset by exactly the hairline's thickness (one physical pixel, read with it), so no strip of ground shows between them at any scale.
PixelUtil = { GetNearestPixelSize = function(size, scale, min)
	local unit = 768 / 1080
	return math.max(math.floor(size * scale / unit + 0.5), min or 0) * unit / scale
end }
elite.scale = 768 / 1080 * 0.8 * 1.2
stub.targetPlate("nameplate1")
local px = e.ground.edges[2]:GetHeight()
assert(px ~= 1 and e.bar.points[1].x == px and e.bar.points[1].y == -px and e.bar.points[2].x == -px and e.bar.points[2].y == px,
	"the bar's inset is not the hairline's thickness at a fractional scale: " .. px .. " vs " .. tostring(e.bar.points[1].x))
PixelUtil, elite.scale = nil, nil
stub.targetPlate("nameplate1")
assert(e.bar.points[1].x == 1, "the bar's inset did not follow the scale back")
