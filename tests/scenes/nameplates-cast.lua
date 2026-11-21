--@ title: Nameplates: cast bars (Thin and Cast Focus)
--@ roots: NamePlate1, NamePlate2, NamePlate3
--@ stubs: stub_nameplates.lua
-- A plate's cast bar wears the cast bars' look (ns.CastLook) at the plate's own size, from the game's layout numbers and our options (never read off the bar): 10 high from the top of Thin's cast area, no icon by default, the name from the left, the time at the right (the caster's target in its place while the game shows its target name, the game's faded under ours). "Cast bar icon" puts the icon inside at the left (a shield of ours on it while the game shows its own), "Cast bar height" sizes it (the texts under it below 9). No stock region shows through during a cast, a channel or a cast that cannot be interrupted: the game's "targets me" and important-cast highlights are faded, ours tints our hairline danger or warning. An interrupt ends in danger with the game's word.
local T = Polestar.Theme
stub.cvarBits.nameplateCastBarDisplay = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true }
local a = stub.addPlate("nameplate1", { name = "Defias Conjurer", level = 18, reaction = 2, health = 800, max = 1000 })
local b = stub.addPlate("nameplate2", { name = "Riverpaw Mystic", level = 17, reaction = 2, health = 500, max = 700 })
local c = stub.addPlate("nameplate3", { name = "Kobold Geomancer", level = 9, reaction = 2, health = 300, max = 300 })
stub.plateCast("nameplate1", { name = "Fireball", time = 3, elapsed = 1.2, targetName = "Ayla", targetsPlayer = true })
stub.plateCast("nameplate2", { name = "Healing Wave", time = 2.5, elapsed = 0.5, locked = true, important = true })
stub.plateCast("nameplate3", { name = "Arcane Missiles", time = 3, elapsed = 1, channel = true })
stub.advance(0.1)
-- Ours on a stock cast bar: the frame CastLook hangs under it.
local function ours(plate)
	local cb = plate.UnitFrame.CastBarsContainer.castBar
	local box = cb:GetChildren()
	local o = { cb = cb, box = box, texts = {} }
	for _, r in ipairs({ box:GetRegions() }) do
		if r.kind == "FontString" then
			o.texts[#o.texts + 1] = r
		elseif r.points[1] and r.points[1].rel == cb:GetStatusBarTexture() then
			o.fill = r
		end
	end
	o.time, o.name = o.texts[1], o.texts[2]
	for _, r in ipairs({ box:GetRegions() }) do
		local p = r.points[1]
		if r.kind ~= "FontString" and p and p.rel == box and not r.atlas then
			local layer = r:GetDrawLayer()
			if layer == "ARTWORK" then o.icon = r elseif layer == "OVERLAY" then o.edge = r end
		end
	end
	return o
end
-- No region of the game's cast bar shows (shown at an alpha over 0), its fill included.
local STOCK = { "Background", "Border", "ImportantCastIndicator", "CastTargetIndicator", "Icon", "Text", "CastTargetNameText", "BorderShield", "Spark" }
local function noStock(o, what)
	for _, k in ipairs(STOCK) do
		local r = o.cb[k]
		assert(not (r:IsShown() and r:GetAlpha() > 0), "the game's " .. k .. " shows through " .. what)
	end
	assert(o.cb:GetStatusBarTexture():GetAlpha() == 0, "the game's fill shows under " .. what)
end
local function same(t, token)
	local r, g, b = T.Color(token)
	local x, y, z = t:GetVertexColor()
	return x == r and y == g and z == b
end
local oa, ob, oc0 = ours(a), ours(b), ours(c)
-- Thin: ours 10 high from the top of the game's cast area, no icon, the name from the bar's left.
assert(oa.box:IsShown() and oa.box:GetHeight() == 10, "the cast bar is not 10 high: " .. tostring(oa.box:GetHeight()))
assert(not oa.icon:IsShown() and oa.name.points[1].rel == oa.box and oa.name.points[1].point == "LEFT", "the icon shows, or the name does not start the bar")
assert(ob.time:GetText() == "2.0", "the time left: " .. tostring(ob.time:GetText()))
noStock(oa, "a cast")
noStock(ob, "a cast that cannot be interrupted")
noStock(oc0, "a channel")
-- The game's highlights: ours on our hairline ("targets me" danger, an important cast warning).
assert(oa.cb.CastTargetIndicator:IsShown() and same(oa.edge, "danger"), "a cast at the player does not tint the hairline danger")
assert(ob.cb.ImportantCastIndicator:IsShown() and same(ob.edge, "warning"), "an important cast does not tint the hairline warning")
-- The game's target name under our box: the caster's target in the time's place, the game's faded.
assert(oa.name:GetText() == "Fireball" and oa.time:GetText() == "Ayla", "the name and the caster's target: " .. tostring(oa.name:GetText()) .. " " .. tostring(oa.time:GetText()))
assert(oa.cb.Text:GetAlpha() == 0 and oa.cb.CastTargetNameText:GetAlpha() == 0 and oa.cb.CastTargetNameText:IsShown(), "the game's name or target name is not faded")
-- A cast that cannot be interrupted: a shield of ours on our icon while the game shows its own.
local shield
for _, r in ipairs({ ob.box:GetRegions() }) do if r.atlas == "nameplates-InterruptShield" then shield = r end end
assert(shield and not shield:IsShown() and ob.cb.BorderShield:IsShown(), "a shield shows with no icon")
-- "Cast bar icon": the icon inside at the left, as high as the bar, the name after it; the shield on it.
local NP = PolestarUI.modules.nameplates
NP.SetOption("castIcon", true)
stub.advance(0.1)
assert(oa.icon:IsShown() and oa.icon:GetHeight() == 10 and oa.icon.points[1].point == "TOPLEFT", "the icon is not inside at the left")
assert(oa.name.points[1].rel == oa.icon, "the name does not follow the icon")
assert(shield:IsShown(), "no shield on the icon of a cast that cannot be interrupted")
noStock(ob, "a cast that cannot be interrupted, with the icon")
-- "Cast bar height": the bar follows; below 9 the texts go under it.
NP.SetOption("castHeight", 14)
stub.advance(0.1)
assert(oa.box:GetHeight() == 14 and oa.icon:GetHeight() == 14 and oa.name.points[1].point == "LEFT", "the bar is not 14 high with the texts inside")
NP.SetOption("castHeight", 6)
stub.advance(0.1)
assert(oa.box:GetHeight() == 6 and oa.name.points[1].point == "TOPLEFT" and oa.name.points[1].relPoint == "BOTTOMLEFT", "a 6-high bar does not put the texts under it")
NP.SetOption("castHeight", nil)
NP.SetOption("castIcon", nil)
stub.advance(0.1)
assert(oa.box:GetHeight() == 10 and not oa.icon:IsShown() and PolestarUIDB.nameplates.castHeight == nil, "a reset does not give the defaults back")
local mr, mg, mb = T.Color("textMuted")
local x, y, z = ob.fill:GetVertexColor()
assert(x == mr and y == mg and z == mb, "a cast that cannot be interrupted is not in textMuted")
-- An interrupt: danger and the game's word.
stub.plateCastEnd("nameplate3", "interrupt")
stub.advance(0.1)
local oc = ours(c)
local dr, dg, db = T.Color("danger")
x, y, z = oc.fill:GetVertexColor()
assert(x == dr and y == dg and z == db and oc.name:GetText() == "Interrupted", "an interrupt is not in danger with the game's word")
-- Cast Focus: the large bar, the name inside.
stub.setCVar("nameplateStyle", "4")
stub.advance(0.1)
oa = ours(a)
assert(oa.box:GetHeight() == 16 and oa.name.points[1].point == "LEFT", "Cast Focus's bar is not ours at 16 with the name inside")
noStock(oa, "Cast Focus's bar")
-- Large plates: ours scales with nameplateSize.
stub.setCVar("nameplateSize", "3")
stub.advance(0.1)
assert(ours(a).box:GetHeight() == 20, "the cast bar does not follow nameplateSize")
stub.setCVar("nameplateSize", "2")
stub.setCVar("nameplateStyle", "1")
stub.advance(0.1)
assert(#stub.cvarsWrittenByUs() == 0, "a CVar was written")
