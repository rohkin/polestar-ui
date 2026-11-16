--@ title: Nameplates: cast bars (Thin and Cast Focus)
--@ roots: NamePlate1, NamePlate2, NamePlate3
--@ stubs: stub_nameplates.lua
-- A plate's cast bar wears the cast bars' look (ns.CastLook) at the plate's own size, from the game's layout numbers (never read off the bar): over the whole cast area (Thin's 6-high bar and the icon's row under it), the icon inside at the left, the name after it, the time at the right (the caster's target in its place while the game shows its target name, the game's faded under ours); a shield of ours on the icon while the game shows its own, and the game's important-cast highlight. An interrupt ends in danger with the game's word.
local T = Polestar.Theme
stub.cvarBits.nameplateCastBarDisplay = { [1] = true, [2] = true, [3] = true, [4] = true }
local a = stub.addPlate("nameplate1", { name = "Defias Conjurer", level = 18, reaction = 2, health = 800, max = 1000 })
local b = stub.addPlate("nameplate2", { name = "Riverpaw Mystic", level = 17, reaction = 2, health = 500, max = 700 })
local c = stub.addPlate("nameplate3", { name = "Kobold Geomancer", level = 9, reaction = 2, health = 300, max = 300 })
stub.plateCast("nameplate1", { name = "Fireball", time = 3, elapsed = 1.2, targetName = "Ayla" })
stub.plateCast("nameplate2", { name = "Healing Wave", time = 2.5, elapsed = 0.5, locked = true, important = true })
stub.plateCast("nameplate3", { name = "Frost Armor", time = 2, elapsed = 1 })
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
	return o
end
local oa, ob = ours(a), ours(b)
-- Thin: ours fills the game's cast area (the 6-high bar and the icon's row under it: 16), the icon inside at the left.
assert(oa.box:IsShown() and oa.box:GetHeight() == 16, "the cast bar is not ours over Thin's cast area: " .. tostring(oa.box:GetHeight()))
assert(ob.time:GetText() == "2.0", "the time left: " .. tostring(ob.time:GetText()))
assert(oa.name.points[1].point == "LEFT" and oa.name.points[1].relPoint == "RIGHT", "the name does not follow the icon inside the bar")
-- The game's target name under our box: the caster's target in the time's place, the game's faded.
assert(oa.name:GetText() == "Fireball" and oa.time:GetText() == "Ayla", "the name and the caster's target: " .. tostring(oa.name:GetText()) .. " " .. tostring(oa.time:GetText()))
assert(oa.cb.Text:GetAlpha() == 0 and oa.cb.CastTargetNameText:GetAlpha() == 0 and oa.cb.CastTargetNameText:IsShown(), "the game's name or target name is not faded")
-- A cast that cannot be interrupted: a shield of ours on our icon while the game shows its own.
local shield
for _, r in ipairs({ ob.box:GetRegions() }) do if r.atlas == "nameplates-InterruptShield" then shield = r end end
assert(shield and shield:IsShown() and ob.cb.BorderShield:IsShown(), "no shield on a cast that cannot be interrupted")
assert(ob.cb.ImportantCastIndicator:IsShown() and ob.cb.ImportantCastIndicator:GetAlpha() == 1, "the important-cast highlight does not show")
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
-- Large plates: ours scales with nameplateSize.
stub.setCVar("nameplateSize", "3")
stub.advance(0.1)
assert(ours(a).box:GetHeight() == 20, "the cast bar does not follow nameplateSize")
stub.setCVar("nameplateSize", "2")
stub.setCVar("nameplateStyle", "1")
stub.advance(0.1)
assert(#stub.cvarsWrittenByUs() == 0, "a CVar was written")
