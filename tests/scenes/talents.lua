--@ title: Talents
--@ roots: PolestarUITalents
--@ stubs: stub_talents.lua
-- The talents key opens ours and closes it, in combat too, never touching the stock window; the micro button's overlay opens ours on a click and hands a shift-click to the micro button from secure code (docs/CLIENT.md, rule 8). Frost learnt, a point staged in Arcane.
stub.noPoints = true
stub.pressKey("N")
assert(not PolestarUITalents or not PolestarUITalents:IsShown(), "opened before the first talent point")
stub.noPoints = false
stub.pressKey("N")
assert(PolestarUITalents:IsShown() and not PlayerSpellsFrame:IsShown(), "key")
stub.pressKey("N")
assert(not PolestarUITalents:IsShown(), "no toggle")
stub.inCombat = true
stub.pressKey("N")
assert(PolestarUITalents:IsShown(), "not in combat")
stub.pressKey("N")
stub.inCombat = false
stub.advance(0.1)
local o = PolestarUITalentsMicro
assert(o:IsShown() and o:GetAttribute("shift-type1") == "click" and o:GetAttribute("clickbutton") == TalentMicroButton, "no overlay")
assert(o:GetFrameStrata() == "HIGH" and o:GetFrameLevel() > 40, "overlay under the micro button")
assert(select(2, o:GetPoint(1)) ~= TalentMicroButton and o:GetLeft() == TalentMicroButton:GetLeft() and o:GetWidth() == TalentMicroButton:GetWidth(), "overlay anchored to the micro button, or not over it")
stub.RunScript(o, "PostClick", "LeftButton")
assert(PolestarUITalents:IsShown() and not PlayerSpellsFrame:IsShown(), "micro")
