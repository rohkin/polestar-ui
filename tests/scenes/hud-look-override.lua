--@ title: HUD look override: Polestar at 4 px accent; the Icons group at 1 px white, no shadow
--@ roots: MainActionBar, MicroMenuContainer, BuffFrame
--@ stubs: stub_actionbars.lua, stub_micromenu.lua, stub_auras.lua
--@ saved: PolestarDB = { schema = 1, settings = { ui = { borderSize = 4, borderAccent = true } } }
-- A group overriding Polestar's look takes its own values alone, past the small pieces' 2 px cap; the others still follow Polestar (the frames at its 4 px accent border, the plates capped at 2). Off again: Polestar's.
local T, H = Polestar.Theme, PolestarUI.HUD
local function near(a, b) return math.abs(a - b) < 1e-6 end
local function regions(f, layer, sub, file)
	local out = {}
	for _, r in ipairs({ f:GetRegions() }) do
		local l, s = r:GetDrawLayer()
		if l == layer and s == sub and tostring(r:GetTexture()):find(file, 1, true) then out[#out + 1] = r end
	end
	return out
end
local AURA
local function edged(b, n, r, g, bl)
	local list = regions(b, b == AURA and "BORDER" or "OVERLAY", 7, "white")
	for _, e in ipairs(list) do
		local x, y, z = e:GetVertexColor()
		if not (e:IsShown() and near(x, r) and near(y, g) and near(z, bl) and (near(e:GetHeight(), n * T.Pixel(b)) or near(e:GetWidth(), n * T.Pixel(b)))) then return false end
	end
	return #list == 4
end
local function shaded(b)
	for _, s in ipairs(regions(b, "BACKGROUND", -8, "shadow")) do if s:IsShown() then return true end end
	return false
end
stub.auras.buffs = { { icon = { 0.3, 0.5, 0.85 }, time = 1800 } }
stub.updateAuras()
stub.advance(0.2)
for _, b in ipairs(BuffFrame.auraFrames) do if b:IsVisible() and not AURA then AURA = b end end
assert(AURA, "no aura shown")
local ar, ag, ab = T.Color("windowBorder")
local buttons = { ActionButton1, CharacterMicroButton }
-- Following: the accent at the 2 px cap, with the shadow.
for _, b in ipairs(buttons) do assert(edged(b, 2, ar, ag, ab) and shaded(b), b:GetName() .. ": not Polestar's look at the cap") end
assert(edged(AURA, 2, ar, ag, ab), "the aura is not Polestar's look at the cap")
-- Icons override: 1 px white, no shadow, its own opacity.
PolestarUIDB.hudLook = { icons = { override = true, border = true, borderSize = 1, borderColor = "white", hairline = 1, shadow = false, ground = 0.4 } }
T.Refresh()
stub.advance(0.2)
for _, b in ipairs(buttons) do assert(edged(b, 1, 1, 1, 1) and not shaded(b), b:GetName() .. ": the Icons override is not 1 px white without a shadow") end
assert(edged(AURA, 1, 1, 1, 1), "the aura does not take the Icons override")
local fill = regions(ActionButton1, "BACKGROUND", -8, "white")[1]
assert(near(select(4, fill:GetVertexColor()), 0.4), "the button's ground is not the Icons override's")
-- Past the cap while overriding.
PolestarUIDB.hudLook.icons.borderSize = 3
T.Refresh()
assert(edged(ActionButton1, 3, 1, 1, 1), "the override is capped")
-- The other groups still follow Polestar.
local shown, r, g, b, a, n = H.Edge(H.FRAMES)
assert(shown and near(r, ar) and n == 4, "the Frames group left Polestar's look")
assert(select(6, H.Edge(H.PLATES)) == 2 and H.ShadowColor(H.PLATES) ~= nil, "the Plates group left Polestar's look")
-- Off again: Polestar's.
PolestarUIDB.hudLook.icons.override = nil
T.Refresh()
stub.advance(0.2)
for _, b in ipairs(buttons) do assert(edged(b, 2, ar, ag, ab) and shaded(b), b:GetName() .. ": not back to Polestar's look") end
-- The override shown in the preview.
PolestarUIDB.hudLook.icons.override = true
PolestarUIDB.hudLook.icons.borderSize = 1
T.Refresh()
stub.advance(0.2)

--@ panel
--@ roots: PolestarUIPlayerFrame, MainActionBar
--@ stubs: stub_actionbars.lua
--@ saved: PolestarDB = { schema = 1, settings = { ui = { borderSize = 4, borderAccent = true } } } PolestarUIDB = { modules = {}, hudOwnGround = true, unitframes = { ground = 0.3 } }
-- A save from before the groups (one HUD opacity of our own) becomes an override of every group at Polestar's look and that opacity: nothing changes but what was ours.
local T, H = Polestar.Theme, PolestarUI.HUD
local function near(a, b) return math.abs(a - b) < 1e-6 end
stub.advance(0.2)
local d = PolestarUIDB.hudLook
assert(PolestarUIDB.hudOwnGround == nil and d, "the old save was not moved")
for _, g in ipairs({ "frames", "plates", "icons" }) do
	assert(d[g] and d[g].override and d[g].ground == 0.3, g .. ": not overridden at the old opacity")
end
assert(d.frames.borderSize == 4 and d.icons.borderSize == 2 and d.plates.borderSize == 2 and d.icons.borderAccent == true, "the groups did not start from Polestar's look")
assert(near(select(4, PolestarUIPlayerFrame.Ground.fill:GetVertexColor()), 0.3), "the unit frame's ground is not the old opacity")
local _, r, _, _, _, n = H.Edge(H.FRAMES)
assert(n == 4 and near(r, (T.Color("windowBorder"))), "the migrated frames' border is not Polestar's")
assert(select(6, H.Edge(H.ICONS)) == 2, "the migrated icons' border is not Polestar's at the cap")
