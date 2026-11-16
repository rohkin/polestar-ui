--@ title: Nameplates: auras (in combat too)
--@ roots: NamePlate1, NamePlate2
--@ stubs: stub_nameplates.lua
-- The game's aura icons on a plate, made, filtered and filled by the game: square (the rounded mask swapped for ours, the icon cropped), the overlay ring faded, a hairline, the stack count in Polestar's face in its corner, the countdown smaller (11 on the 25-unit item, as the target frame's 9 on 20) and centred. Their size is the game's (its Aura scale option). No aura is read: in combat (auras secret) a new aura is dressed the same.
local a = stub.addPlate("nameplate1", { name = "Defias Pillager", level = 18, reaction = 2, health = 620, max = 1000,
	auras = { { icon = 136207, count = 3, timer = 12 }, { icon = 135817, timer = 7 } }, buffs = { { icon = 136096 } } })
stub.advance(0.1)
local list = a.UnitFrame.AurasFrame.DebuffListFrame
local it = list.items[1]
local function square(item)
	local overlay
	for _, r in ipairs({ item:GetRegions() }) do
		if r.atlas == "UI-HUD-CoolDownManager-IconOverlay" then overlay = r end
	end
	return item.Icon.mask ~= nil and item.Icon.mask.atlas ~= "UI-HUD-CoolDownManager-Mask" and overlay:GetAlpha() == 0 and item.Icon.texCoord ~= nil
end
assert(square(it) and square(list.items[2]) and square(a.UnitFrame.AurasFrame.BuffListFrame.items[1]), "an aura icon is not square in a hairline")
assert((it.CountFrame.Count:GetFont()) == (Polestar.Theme.FontSpec("number")), "the stack count is not in Polestar's face")
local timer = it.Cooldown:GetCountdownFontString()
local face, size = timer:GetFont()
assert(face == Polestar.Theme.FontSpec("number") and size == 11 and timer.points[1].point == "CENTER", "the countdown is not smaller and centred: " .. tostring(size))
-- In combat: a new aura on another plate, nothing read.
stub.inCombat, stub.aurasSecret = true, true
local b = stub.addPlate("nameplate2", { name = "Defias Thug", level = 17, reaction = 2, health = 400, max = 900 })
stub.advance(0.1)
stub.updatePlate("nameplate2", { auras = { { icon = 132155, count = 2 } } })
stub.advance(0.1)
assert(square(b.UnitFrame.AurasFrame.DebuffListFrame.items[1]), "an aura gained in combat is not dressed")
stub.inCombat, stub.aurasSecret = false, false
