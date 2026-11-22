--@ title: HUD look: Polestar's border (3 px, accent), shadow and background opacity on unit frames and a cast bar
--@ roots: PolestarUIPlayerFrame, PolestarUITargetFrame, PlayerCastingBarFrame
--@ stubs: stub_castbars.lua
--@ saved: PolestarDB = { schema = 1, settings = { ui = { borderSize = 3, borderAccent = true } } }
-- The HUD follows Polestar's Frames settings as its windows do: every edge in the window border's colour (here the accent) at its size, laid as Theme.Border lays a window's (the first pixel inside, the rest outward); border off hides the plain edges but keeps a tint (threat); the window shadow (on in the house look) round the ground and the cast bar, as the window painter lays it, gone with it off (and under a tint); the ground at Polestar's Background opacity, or ours with "follow" off.
local T, H = Polestar.Theme, PolestarUI.HUD
local function near(a, b) return math.abs(a - b) < 1e-6 end
local function is(t, r, g, b) local x, y, z = t:GetVertexColor() return t:IsShown() and near(x, r) and near(y, g) and near(z, b) end
local function thick(t, n) return near(t:GetHeight(), n * T.Pixel(t:GetParent())) or near(t:GetWidth(), n * T.Pixel(t:GetParent())) end
local function regions(f, layer, sub, file)
	local out = {}
	for _, r in ipairs({ f:GetRegions() }) do
		local l, s = r:GetDrawLayer()
		if l == layer and s == sub and tostring(r:GetTexture()):find(file, 1, true) then out[#out + 1] = r end
	end
	return out
end
-- The top edge laid as Theme.Border's: from `o` outside rel's top corners, n pixels down from there.
local function outward(top, n) local px = T.Pixel(top:GetParent()) local a, b = top.points[1], top.points[2] return near(a.x, -(n - 1) * px) and near(a.y, (n - 1) * px) and near(b.x, (n - 1) * px) and a.point == "TOPLEFT" end
local function allShown(list, on) for _, t in ipairs(list) do if t:IsShown() ~= on then return false end end return #list > 0 end
stub.units.target = { name = "Kurzen", level = 25, health = 12400, max = 20000, power = 900, powerMax = 1200, powerType = 0, reaction = 2, threat = 3 }
stub.fire("PLAYER_TARGET_CHANGED")
stub.unitWatch()
stub.cast("player", { name = "Fireball", time = 2.5, elapsed = 1.5 })
stub.advance(0.3)
local P, Tg = PolestarUIPlayerFrame, PolestarUITargetFrame
local box = PlayerCastingBarFrame:GetChildren()
local castEdges, castShadow = regions(box, "OVERLAY", 7, "white"), regions(box, "BACKGROUND", -8, "shadow")
local br, bg, bb = T.Color("windowBorder")
assert(near(br, (T.Accent())), "the window border is not the accent here")
-- The border: its colour and Polestar's 3 px on frames.
for _, e in ipairs(P.Ground.edges) do assert(is(e, br, bg, bb) and thick(e, 3), "the unit frame's edge is not the window border at 3 px") end
assert(outward(P.Ground.edges[1], 3), "the unit frame's edge does not grow outward as a window's")
for i = 1, 4 do assert(is(castEdges[i], br, bg, bb) and thick(castEdges[i], 3), "the cast bar's edge is not the window border at 3 px") end
-- The shadow: round the ground and the cast bar in the shadow colour (no glow without a tint).
local sr, sg, sb = T.Color("shadow")
assert(H.ShadowColor() and allShown(P.Ground.shadow, true) and not P.Ground.glow[1]:IsShown() and allShown(castShadow, true), "no shadow while Polestar draws one")
assert(is(castShadow[1], sr, sg, sb), "the cast bar's shadow is not the shadow colour")
-- Border off: the plain edges go, the threat edge stays.
Polestar.Set("ui.border", false)
stub.advance(0.1)
assert(allShown(P.Ground.edges, false) and allShown(castEdges, false), "the border off still shows the HUD's edges")
assert(allShown(Tg.Ground.edges, true) and Tg.Ground.glow[1]:IsShown() and allShown(Tg.Ground.shadow, false), "the border off hid the threat edge (or a tint has a shadow)")
Polestar.Set("ui.border", nil)
-- Shadow off.
Polestar.Set("ui.shadow", false)
stub.advance(0.1)
assert(not H.ShadowColor() and allShown(P.Ground.shadow, false) and allShown(castShadow, false), "the shadow off still shows")
Polestar.Set("ui.shadow", nil)
-- Opacity: Polestar's by default, the Frames group's own while it overrides.
Polestar.Set("ui.bgOpacity", 0.5)
stub.advance(0.1)
assert(near(select(4, P.Ground.fill:GetVertexColor()), 0.5), "the HUD ground does not follow Polestar's opacity")
PolestarUIDB.hudLook = { frames = { override = true, ground = 0.6 } }
T.Refresh()
assert(near(select(4, P.Ground.fill:GetVertexColor()), 0.6), "the HUD ground does not take its group's own")
PolestarUIDB.hudLook = nil
Polestar.Set("ui.bgOpacity", nil)
stub.advance(0.1)
assert(allShown(P.Ground.shadow, true) and allShown(P.Ground.edges, true), "not back as it was")

--@ panel
--@ roots: MainActionBar, MicroMenuContainer
--@ stubs: stub_actionbars.lua, stub_micromenu.lua
--@ saved: PolestarDB = { schema = 1, settings = { ui = { borderSize = 3, borderAccent = true } } }
-- Buttons: the window border capped at 2 px, growing outward (the micro plate a pixel smaller so the gap to the next stays), a shadow round each (the micro button's round its plate); border off keeps the checked (stance) and active edges.
local T = Polestar.Theme
local function near(a, b) return math.abs(a - b) < 1e-6 end
local function is(t, r, g, b) local x, y, z = t:GetVertexColor() return t:IsShown() and near(x, r) and near(y, g) and near(z, b) end
local function thick(t, n) return near(t:GetHeight(), n * T.Pixel(t:GetParent())) or near(t:GetWidth(), n * T.Pixel(t:GetParent())) end
local function regions(f, layer, sub, file)
	local out = {}
	for _, r in ipairs({ f:GetRegions() }) do
		local l, s = r:GetDrawLayer()
		if l == layer and s == sub and tostring(r:GetTexture()):find(file, 1, true) then out[#out + 1] = r end
	end
	return out
end
local function allShown(list, on) for _, t in ipairs(list) do if t:IsShown() ~= on then return false end end return #list > 0 end
local function topOf(list) for _, t in ipairs(list) do if t.points[1] and t.points[1].point == "TOPLEFT" and t.points[2] and t.points[2].point == "TOPRIGHT" then return t end end end
stub.microSetPushed(QuestLogMicroButton, true)
stub.advance(0.1)
local br, bg, bb = T.Color("windowBorder")
local function edges(b) return regions(b, "OVERLAY", 7, "white") end
for _, b in ipairs({ ActionButton1, CharacterMicroButton }) do
	for _, e in ipairs(edges(b)) do assert(is(e, br, bg, bb) and thick(e, 2), b:GetName() .. ": the edge is not the window border at 2 px") end
	assert(allShown(regions(b, "BACKGROUND", -8, "shadow"), true), b:GetName() .. ": no shadow")
	local top, px = topOf(edges(b)), T.Pixel(b)
	assert(top and near(top.points[1].x, -px) and near(top.points[1].y, px), b:GetName() .. ": the edge does not grow outward")
end
-- The micro plate gives the outward pixel room: its edge's outer side where the 1 px plate's was (4 in, 4 down).
local plateTop = topOf(edges(CharacterMicroButton)).points[1].rel
assert(near(plateTop.points[1].x, 4 + T.Pixel(CharacterMicroButton)) and near(plateTop.points[1].y, -4 - T.Pixel(CharacterMicroButton)), "the micro plate did not give the border room")
local fill = regions(ActionButton1, "BACKGROUND", -8, "white")[1]
assert(near(select(4, fill:GetVertexColor()), T.GroundAlpha()), "the button's ground is not Polestar's opacity")
PolestarUIDB.hudLook = { icons = { override = true, ground = 0.6 } }
T.Refresh()
assert(near(select(4, fill:GetVertexColor()), 0.6), "the button's ground does not take its group's own")
PolestarUIDB.hudLook = nil
T.Refresh()
Polestar.Set("ui.border", false)
Polestar.Set("ui.shadow", false)
stub.advance(0.1)
assert(allShown(edges(ActionButton1), false) and allShown(edges(CharacterMicroButton), false), "the border off still shows a button's edge")
assert(allShown(edges(StanceButton1), true) and allShown(edges(QuestLogMicroButton), true), "the border off hid a checked or active edge")
assert(allShown(regions(ActionButton1, "BACKGROUND", -8, "shadow"), false) and allShown(regions(CharacterMicroButton, "BACKGROUND", -8, "shadow"), false), "the shadow off still shows")
Polestar.Set("ui.border", nil)
Polestar.Set("ui.shadow", nil)
stub.advance(0.1)

--@ panel
--@ roots: MinimapCluster
--@ stubs: stub_minimap.lua
--@ saved: PolestarDB = { schema = 1, settings = { ui = { borderSize = 3, borderAccent = true } } }
-- The minimap's edge: the window border at 3 px, growing outward, the shadow round the map; border off hides it.
local T = Polestar.Theme
local function near(a, b) return math.abs(a - b) < 1e-6 end
local function regions(f, layer, sub, file)
	local out = {}
	for _, r in ipairs({ f:GetRegions() }) do
		local l, s = r:GetDrawLayer()
		if l == layer and s == sub and tostring(r:GetTexture()):find(file, 1, true) then out[#out + 1] = r end
	end
	return out
end
stub.advance(0.6)
local edge = PolestarUIMinimapEdge
local br, bg, bb = T.Color("windowBorder")
local lines, shade = regions(edge, "OVERLAY", 7, "white"), regions(edge, "BACKGROUND", -8, "shadow")
assert(#lines == 4 and #shade == 16, "the minimap's edge or shadow is missing")
for _, e in ipairs(lines) do
	local r, g, b = e:GetVertexColor()
	assert(e:IsShown() and near(r, br) and near(g, bg) and near(b, bb) and (near(e:GetHeight(), 3 * T.Pixel(edge)) or near(e:GetWidth(), 3 * T.Pixel(edge))), "the minimap's edge is not the window border at 3 px")
end
for _, s in ipairs(shade) do assert(s:IsShown(), "no shadow round the minimap") end
local px = T.Pixel(edge)
for _, e in ipairs(lines) do
	local p = e.points[1]
	if p.rel == edge and p.point == "TOPLEFT" then assert(near(p.x, -2 * px) and near(p.y, 2 * px), "the minimap's edge does not grow outward") end
end
Polestar.Set("ui.border", false)
Polestar.Set("ui.shadow", false)
stub.advance(0.1)
for _, e in ipairs(lines) do assert(not e:IsShown(), "the border off still shows the minimap's edge") end
for _, s in ipairs(shade) do assert(not s:IsShown(), "the shadow off still shows round the minimap") end
Polestar.Set("ui.border", nil)
Polestar.Set("ui.shadow", nil)
stub.advance(0.1)

--@ panel
--@ roots: NamePlate1, NamePlate2
--@ stubs: stub_nameplates.lua
--@ saved: PolestarDB = { schema = 1, settings = { ui = { borderSize = 3, borderAccent = true } } }
-- A plate's edge: the window border capped at 2 px, its first pixel inside the box, the bar inset by that pixel; threat keeps its edge with the border off.
local T, NP = Polestar.Theme, PolestarUI.modules.nameplates
local function near(a, b) return math.abs(a - b) < 1e-6 end
stub.cvarBits.nameplateThreatDisplay = { [1] = true, [3] = true }
local plain = stub.addPlate("nameplate1", { name = "Defias Pillager", level = 18, reaction = 2, health = 620, max = 1000 })
local threat = stub.addPlate("nameplate2", { name = "Gnoll Mystic", level = 12, reaction = 2, threat = 3, health = 900, max = 1000 })
stub.advance(0.1)
local l, t = NP.look(plain.UnitFrame), NP.look(threat.UnitFrame)
local one = T.Pixel(l.box)
local px = 2 * one
local br, bg, bb = T.Color("windowBorder")
local r, g, b = l.ground.edges[1]:GetVertexColor()
assert(near(r, br) and near(g, bg) and near(b, bb) and near(l.ground.edges[1]:GetHeight(), px), "the plate's edge is not the window border at 2 px")
local p = l.bar.points[1]
assert(near(p.x, one) and near(p.y, -one), "the plate's bar is not inset by the edge's inner pixel")
assert(near(l.ground.edges[1].points[1].x, -one) and near(l.ground.edges[1].points[1].y, one), "the plate's edge does not grow outward")
Polestar.Set("ui.border", false)
stub.advance(0.1)
assert(not l.ground.edges[1]:IsShown() and t.ground.edges[1]:IsShown(), "the border off: the plain edge shows, or the threat edge went")
Polestar.Set("ui.border", nil)
stub.advance(0.1)
