--@ title: Target and focus auras: rows of ours, the game's veiled
--@ roots: PolestarUITargetFrame, PolestarUIFocusFrame
--@ stubs: stub_auras.lua
-- Under our target and focus frames, a row of square aura icons of ours in a 1px hairline, the game's own aura container faded (rule 16's exception: SetAlpha on that container alone, out of combat). A hostile creature: debuffs first, the player's own first and large, another player's left out (the game's filter), then its buffs; a debuff's hairline in its dispel type's colour. A friend: buffs first. The time is the game's countdown in the number face, the stacks outlined. While auras are secret (combat, an encounter, a keystone, a PvP match) the client refuses every aura call of ours: the game's container shows instead.
local T, F = PolestarUITargetFrame, PolestarUIFocusFrame
-- The shown icons of the row under one of our frames, left to right.
local function row(f)
	local out = {}
	for _, c in ipairs({ f:GetChildren() }) do
		for _, b in ipairs({ c:GetChildren() }) do
			if b.id and b:IsShown() and c:IsShown() then out[#out + 1] = b end
		end
	end
	table.sort(out, function(a, b) return a.points[1].x < b.points[1].x end)
	return out
end
local function order(f)
	local s = {}
	for i, b in ipairs(row(f)) do s[i] = b.id end
	return table.concat(s, ",")
end
local function edge(b) return b.edges[1]:GetVertexColor() end
local function stockAuras(f) return f.TargetFrameContent.TargetFrameContentContextual.Auras end
stub.units.target = { name = "Kurzen", level = 25, health = 12400, max = 20000, power = 900, powerMax = 1200, reaction = 2, auras = {
	{ id = 2, harmful = true, fromPlayer = true, time = 30 }, { id = 3, harmful = true, dispel = "Poison", time = 90 },
	{ id = 1, harmful = true, mine = true, dispel = "Magic", time = 12, count = 3 }, { id = 4 }, { id = 5, harmful = true, mine = true, time = 5 },
} }
stub.units.focus = { name = "Paxton", level = 26, class = "PRIEST", player = true, health = 2000, max = 2000, power = 3000, powerMax = 4000, reaction = 5, auras = {
	{ id = 13, harmful = true, dispel = "Curse", time = 20 }, { id = 12 }, { id = 11, mine = true, time = 1800 },
} }
stub.fire("PLAYER_TARGET_CHANGED")
stub.fire("PLAYER_FOCUS_CHANGED")
stub.unitWatch()
stub.advance(0.2)
-- The veil: the game's container faded, still shown, nothing else of it touched (the stub's guard).
assert(stockAuras(TargetFrame):GetAlpha() == 0 and stockAuras(FocusFrame):GetAlpha() == 0 and stockAuras(TargetFrame):IsShown(), "the game's auras are not veiled")
-- Faded, the game's buttons still took the mouse (its aura tooltip beside ours): the container is switched off too.
assert(not stockAuras(TargetFrame):IsEnabled() and not stockAuras(FocusFrame):IsEnabled(), "the game's aura buttons still take the mouse")
-- A hostile creature: the player's debuffs first, then the creature's own (another player's left out), then buffs.
assert(order(T) == "1,5,3,4", "the target's row: " .. order(T))
-- A friend: buffs first (the player's own first), then debuffs.
assert(order(F) == "11,12,13", "the focus's row: " .. order(F))
local t = row(T)
assert(t[1]:GetWidth() == 20 and t[3]:GetWidth() == 16, "the player's own auras are not the large ones")
local info = AuraUtil.GetDebuffDisplayInfoTable()
local r, g, b = edge(t[1])
assert(r == info.Magic.color.r and b == info.Magic.color.b, "a magic debuff's hairline")
r, g, b = edge(t[2])
assert(r == info.None.color.r and g == info.None.color.g, "a plain debuff's hairline")
local br, bg, bb = Polestar.Theme.Color("border")
r, g, b = edge(t[4])
assert(r == br and g == bg and b == bb, "a buff's hairline is not the border token")
assert(t[1].count:GetText() == "3" and t[2].count:GetText() == "", "the stacks")
assert(t[1].cd.duration and t[1].cd:GetCountdownFontString():GetFont() == (Polestar.Theme.FontSpec("number")), "the time is not the game's countdown in our face")
assert(t[1]:GetPoint(1) == "TOPLEFT" and select(2, t[1]:GetParent():GetPoint(1)) == T, "the row does not hang under our frame")
-- The tooltip: the game's, by the aura's id.
stub.RunScript(t[3], "OnEnter")
assert(stub.auraTip == "target:3", "the tooltip: " .. tostring(stub.auraTip))
-- The game's own option shows every debuff.
stub.cvars.noBuffDebuffFilterOnTarget = "1"
stub.fire("UNIT_AURA", "target")
assert(order(T) == "1,5,2,3,4", "noBuffDebuffFilterOnTarget: " .. order(T))
stub.cvars.noBuffDebuffFilterOnTarget = "0"
-- The unit frames off: the game's auras back (ours go with our frames); on again, veiled again.
PolestarUI.Switch("unitframes", false)
stub.advance(0.2)
assert(stockAuras(TargetFrame):GetAlpha() == 1 and stockAuras(TargetFrame):IsEnabled(), "the game's auras are not back with the unit frames off")
PolestarUI.Switch("unitframes", true)
stub.unitWatch()
stub.advance(0.2)
assert(stockAuras(TargetFrame):GetAlpha() == 0 and order(T) == "1,5,3,4", "not veiled again: " .. order(T))
PolestarUI.Switch("auras", false)
assert(stockAuras(TargetFrame):GetAlpha() == 1 and order(T) == "", "auras off: the game's are not back, or ours still show")
PolestarUI.Switch("auras", true)
-- In combat auras are secret, and the client refuses every aura call of a tainted caller
-- (BugGrabber: 3,937 "GetUnitAuraInstanceIDs(): Auras cannot be accessed when secret while
-- tainted"): ours read nothing and hide, and the game's container is given back as combat
-- starts (PLAYER_REGEN_DISABLED runs before the lockdown, rule 4).
stub.fire("PLAYER_REGEN_DISABLED")
stub.inCombat = true
stub.fire("UNIT_AURA", "target")
stub.fire("PLAYER_TARGET_CHANGED")
stub.advance(0.2)
assert(order(T) == "" and order(F) == "", "our rows still show in combat: " .. order(T))
assert(stockAuras(TargetFrame):GetAlpha() == 1 and stockAuras(FocusFrame):GetAlpha() == 1 and stockAuras(TargetFrame):IsEnabled(), "the game's auras are not back in combat")
stub.inCombat = false
stub.fire("PLAYER_REGEN_ENABLED")
stub.advance(0.2)
assert(stockAuras(TargetFrame):GetAlpha() == 0 and not stockAuras(TargetFrame):IsEnabled() and order(T) == "1,5,3,4", "not veiled again after combat: " .. order(T))
-- Out of combat but secret (an encounter, a keystone, a PvP match): the game's auras, ours hidden.
stub.aurasSecret = true
stub.fire("UNIT_AURA", "target")
stub.advance(0.2)
assert(stockAuras(TargetFrame):GetAlpha() == 1 and order(T) == "", "secret out of combat: " .. order(T))
stub.aurasSecret = false
-- No poll: the client's restriction change says it (then the next frame).
stub.advance(0.2)
assert(stockAuras(TargetFrame):GetAlpha() == 1, "the veil came back with no event")
stub.fire("ADDON_RESTRICTION_STATE_CHANGED")
stub.advance(0.05)
assert(stockAuras(TargetFrame):GetAlpha() == 0 and order(T) == "1,5,3,4", "not veiled again once no longer secret: " .. order(T))
