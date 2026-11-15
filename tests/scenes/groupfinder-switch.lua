--@ title: Group Finder: switched off
--@ roots: PolestarUIGroupFinder
--@ stubs: stub_groupfinder.lua
-- Switched off (live: no stock routing was stopped), ours closes and the keys and micro button are the game's: they open the stock window. On again, they are ours.
PolestarUI.Show("groupfinder", "browse")
local f = PolestarUIGroupFinder
PolestarUI.Switch("groupfinder", false)
assert(not f:IsShown(), "ours left open")
assert(not stub.overrides["I"] and not stub.overrides["SHIFT-I"], "keys still ours")
stub.advance(0.1)
assert(not PolestarUIGroupFinderMicro:IsShown(), "micro overlay still up")
stub.pressKey("I")
assert(LFGParentFrame:IsShown() and not f:IsShown(), "the game's key")
UIParent.Hide(LFGParentFrame)
PolestarUI.Switch("groupfinder", true)
stub.pressKey("I")
assert(f:IsShown() and not LFGParentFrame:IsShown(), "on again")
stub.advance(0.1)
assert(PolestarUIGroupFinderMicro:IsShown(), "micro overlay not back")
stub.assertNoErrors()
