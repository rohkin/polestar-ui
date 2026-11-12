--@ title: Talents: Secondary
--@ roots: PolestarUITalents
--@ stubs: stub_talents.lua
-- Dual spec learnt: Secondary (Fire) in the sidebar with its points; viewing it says it is not the active spec.
stub.dual = true
PolestarUI.Show("talents", 2)
local f = PolestarUITalents
assert(f.psArt[2]:IsShown() and f.psTint[2]:IsShown() and f.psArt[1].gradient.min[4] == 0 and f.psArt[3].gradient.max[4] == 0 and f.psArt[6].gradient.max[4] == 0 and f.psArt[9].gradient.max[4] == 0, "no class art, or not feathered at its sides and seams")
