--@ title: Talents: Secondary
--@ roots: PolestarUITalents
--@ stubs: stub_talents.lua
-- Dual spec learnt: Secondary (Fire) in the sidebar with its points; viewing it says it is not the active spec.
stub.dual = true
PolestarUI.Show("talents", 2)
local f = PolestarUITalents
assert(f.psArt[2]:IsShown() and f.psTint[2]:IsShown() and f.psArt[1].gradient.min[4] == 0 and f.psArt[3].gradient.max[4] == 0 and f.psArt[6].gradient.max[4] == 0 and f.psArt[9].gradient.max[4] == 0, "no class art, or not feathered at its sides and seams")
stub.RunScript(f.footerButtons.right[2], "OnEnter")
assert(GameTooltip.lines[1] == "Not your active spec", "no reason on Undo: " .. tostring(GameTooltip.lines[1]))
-- Activate in Apply's place, as the stock ActivateButton: a cast; the window waits, then shows the spec, now the active one.
local act = f.footerButtons.right[1]
assert(act.Label:GetText() == "Activate" and act:IsEnabled(), "no Activate")
act:Click()
assert(stub.switching == 2 and not act:IsEnabled() and f.Subtitle:GetText():find("Switching"), "not switching")
stub.finishSwitch()
assert(f.footerButtons.right[1].Label:GetText() == "Apply" and not f.Subtitle:GetText():find("active spec"), "not the active spec: " .. f.Subtitle:GetText())
stub.specGroup = 1
stub.fire("ACTIVE_TALENT_GROUP_CHANGED", 1)
PolestarUI.Show("talents", 2)
