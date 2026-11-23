--@ title: Unit frames: end glows (shields past the missing health, a heal absorb past the health), the power percent, the UI-mode rolesets, a Cyrillic name on a font family
--@ roots: PolestarUIPlayerFrame, PolestarUITargetFrame, PolestarUIFocusFrame
--@ saved: PolestarUIDB = { modules = {}, unitframes = { powerText = true } }
stub.cvars.statusText = "1"
stub.cvars.statusTextDisplay = "PERCENT"
stub.units.player = { name = "Testchar", level = 24, class = "PRIEST", player = true, health = 2000, max = 2400, absorbs = 900, power = 2600, powerMax = 4000, powerType = 0, reaction = 5 }
stub.units.target = { name = "Kurzen", level = 25, health = 1200, max = 20000, healAbsorbs = 3000, power = 900, powerMax = 1200, powerType = 0, reaction = 2 }
stub.units.focus = { name = "Paxton", level = 26, class = "WARRIOR", player = true, health = 1500, max = 2000, absorbs = 200, power = 30, powerMax = 100, powerType = 1, reaction = 5 }
stub.fire("PLAYER_TARGET_CHANGED")
stub.fire("PLAYER_FOCUS_CHANGED")
stub.unitWatch()
stub.advance(0.3)
local P, T, F = PolestarUIPlayerFrame, PolestarUITargetFrame, PolestarUIFocusFrame
-- The glows take the client's secret "clamped" flags unread (SetAlphaFromBoolean).
assert(P.OverAbsorb.alphaFromBoolean and P.OverAbsorb:GetAlpha() == 1, "shield past the missing health: right end lit")
assert(P.OverHealAbsorb:GetAlpha() == 0, "no heal absorb: left end dark")
assert(T.OverHealAbsorb:GetAlpha() == 1 and T.OverAbsorb:GetAlpha() == 0, "heal absorb past the health: left end lit")
assert(F.OverAbsorb:GetAlpha() == 0 and F.OverHealAbsorb:GetAlpha() == 0, "a shield that fits: no glow")
stub.units.player.absorbs = 0
stub.fire("UNIT_ABSORB_AMOUNT_CHANGED", "player")
assert(P.OverAbsorb:GetAlpha() == 0, "the glow goes with the shield")
-- The power text follows statusTextDisplay: the client's percent (UnitPowerPercent, 0-100 curve).
assert(P.powerText:GetText() == "65%", "power percent: " .. tostring(P.powerText:GetText()))
stub.cvars.statusTextDisplay = "BOTH"
stub.fire("CVAR_UPDATE", "statusTextDisplay")
assert(P.powerText:GetText() == "2600 || 65%", "power both: " .. tostring(P.powerText:GetText()))
stub.cvars.statusTextDisplay = "PERCENT"
stub.fire("CVAR_UPDATE", "statusTextDisplay")
-- Every frame of ours carries the stock unit frames' roleset, so the client's
-- UI modes (cutscenes, pet battles) hide them with the game's.
for _, n in ipairs({ "PolestarUIPlayerFrame", "PolestarUITargetFrame", "PolestarUIFocusFrame", "PolestarUITargetToT", "PolestarUIFocusToT",
	"PolestarUIPetFrame", "PolestarUIPartyFrame1", "PolestarUIPartyFrame4", "PolestarUIBossFrame1", "PolestarUIBossFrame5" }) do
	assert(_G[n]:GetRolesetNames()[1] == "unitFrames", n .. " roleset: " .. tostring(_G[n].rolesets))
end
-- SetRolesets is protected: never called again, in combat or out.
-- Names sit on an engine font family (ns.NameFont): a Cyrillic name draws in the client's face, unread.
stub.units.target.name = "Курзен"
stub.fire("UNIT_NAME_UPDATE", "target")
local fam = T.Name.fontObject
assert(fam and fam.members and stub.fontFamilies[fam.name or ""] == fam, "target name on a font family")
assert(PolestarUIPartyFrame1.Name.fontObject and PolestarUIBossFrame1.Name.fontObject.members, "party and boss names on a family")
stub.inCombat = true
stub.fire("PLAYER_REGEN_DISABLED")
stub.fire("GROUP_ROSTER_UPDATE")
stub.inCombat = false
stub.fire("PLAYER_REGEN_ENABLED")
stub.assertNoErrors()
-- The power text shares the health value's right edge, and follows the Status Text CVar.
do
	local _, _, _, hx = P.healthText:GetPoint()
	local _, rel, _, px = P.powerText:GetPoint()
		assert(rel == P.Power and P.powerText:GetParent():GetFrameLevel() > P.Health:GetFrameLevel(), "power text on the power bar, above the health")
	assert(P.powerText:GetJustifyH() == "RIGHT" and hx == px, "power text on the health value's right edge")
	stub.cvars.statusText = "0"
	stub.fire("CVAR_UPDATE", "statusText")
	assert(P.powerText:GetText() == "", "power text follows statusText off")
end
