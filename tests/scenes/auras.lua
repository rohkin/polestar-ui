--@ title: Buffs and debuffs
--@ roots: BuffFrame, DebuffFrame
--@ stubs: stub_auras.lua
-- The game's own aura buttons restyled in place: square icons in a 1px hairline (a weapon enchant's in the epic colour, a debuff's in its dispel type's), the game's round borders faded, the duration and count in Polestar's number face, outlined, in the game's colours. The game's handlers stay: right-click cancels, hover shows its tooltip.
local function edge(b)
	for _, r in ipairs({ b:GetRegions() }) do
		if r:IsShown() and tostring(r:GetTexture()):find("white", 1, true) then return r:GetVertexColor() end
	end
end
local function same(b, r, g, bl) local x, y, z = edge(b) return x == r and y == g and z == bl end
stub.auras.buffs = {
	{ icon = { 0.3, 0.5, 0.85 }, time = 1800 }, { icon = { 0.85, 0.7, 0.25 }, time = 45, count = 3 }, { icon = { 0.4, 0.7, 0.35 } },
	{ icon = { 0.6, 0.35, 0.75 }, time = 7200 }, { icon = { 0.75, 0.3, 0.2 }, time = 300, enchant = true }, { icon = { 0.3, 0.65, 0.7 }, time = 12 },
}
stub.auras.debuffs = { { icon = { 0.5, 0.2, 0.6 }, time = 20, dispel = "Magic" }, { icon = { 0.2, 0.5, 0.2 }, time = 8, dispel = "Poison", count = 2 }, { icon = { 0.6, 0.2, 0.2 }, time = 60 } }
-- In combat a debuff's dispel type is secret: the plain debuff red, no error.
stub.inCombat = true
stub.updateAuras()
stub.advance(0.2)
local B, D = BuffFrame.auraFrames, DebuffFrame.auraFrames
local none = AuraUtil.GetDebuffDisplayInfoTable().None.color
assert(same(D[1], none:GetRGB()), "a secret dispel type is not the plain debuff colour")
stub.inCombat = false
stub.updateAuras()
stub.advance(0.2)
local magic, poison = AuraUtil.GetDebuffDisplayInfoTable().Magic.color, AuraUtil.GetDebuffDisplayInfoTable().Poison.color
assert(same(D[1], magic:GetRGB()) and same(D[2], poison:GetRGB()) and same(D[3], none:GetRGB()), "debuff hairlines are not their dispel types'")
assert(D[1].DebuffBorder:IsShown() and D[1].DebuffBorder:GetAlpha() == 0, "the game's debuff border is not faded in place")
-- The weapon enchant is dealt first, in the epic colour, its purple border faded.
assert(B[1].auraType == "TempEnchant" and B[1].TempEnchantBorder:GetAlpha() == 0 and same(B[1], PolestarUI.QualityRGB(4)), "weapon enchant")
local br, bg, bb = Polestar.Theme.Color("border")
assert(same(B[2], br, bg, bb), "a buff's hairline is not the border token")
local number = Polestar.Theme.FontSpec("number")
local path, size, flags = B[2].Duration:GetFont()
assert(path == number and size == 10 and flags == "OUTLINE", "the duration is not in the number face at the game's size, outlined")
assert(select(1, B[3].Count:GetFont()) == number and B[3].Count:GetText() == "3", "the count")
local r, g = B[2].Duration:GetTextColor()
assert(r == 1 and g == 0.82, "the duration's colour is not the game's")
assert(B[2].Icon.texCoord[1] == 0.08, "the icon is not cropped")
-- The game's own handlers: right-click cancels, hover shows the tooltip.
stub.RunScript(B[2], "OnClick", "RightButton")
assert(stub.cancelled == 2, "right-click no longer cancels")
stub.RunScript(D[1], "OnEnter")
assert(stub.auraTip == D[1].buttonInfo.auraInstanceID, "the tooltip")
-- The game deals the auras over the buttons again: the hairlines follow what each now holds.
table.remove(stub.auras.debuffs, 1)
stub.updateAuras()
stub.advance(0.2)
assert(same(D[1], poison:GetRGB()), "the hairline did not follow the button's new aura")
assert(not D[3]:IsShown(), "an empty button shows")
local function polls(file)
	local n = 0
	for _, f in ipairs(stub.frames) do
		local fn = f:GetScript("OnUpdate")
		if fn and f:IsVisible() and debug.getinfo(fn, "S").source:find(file, 1, true) then n = n + 1 end
	end
	return n
end
-- No poll: the repaint after an event ran once and cleared itself.
assert(polls("Auras.lua") == 0, "the aura repaint is still running")
-- Another unit's auras (a raid's) start no repaint of the player's buttons; the player's do.
stub.fire("UNIT_AURA", "raid5")
assert(polls("Auras.lua") == 0, "another unit's aura repaints the player's buttons")
stub.fire("UNIT_AURA", "player")
assert(polls("Auras.lua") == 1, "the player's aura starts no repaint")
stub.advance(0.05)
assert(polls("Auras.lua") == 0, "the aura repaint is still running")
