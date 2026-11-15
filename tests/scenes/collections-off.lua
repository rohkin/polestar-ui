--@ title: Collections: switched off
--@ roots: PolestarUICollections
--@ stubs: stub_collections.lua
-- Switched off (live: no stock routing was stopped), ours closes and the keys and micro button are the game's: they open the stock journal. On again, they are ours.
PolestarUI.Show("collections", "mounts")
local f = PolestarUICollections
PolestarUI.Switch("collections", false)
assert(not f:IsShown(), "ours left open")
assert(not stub.overrides["SHIFT-J"] and not stub.overrides["CTRL-M"] and not stub.overrides["CTRL-T"], "keys still ours")
stub.advance(0.1)
assert(not PolestarUICollectionsMicro:IsShown(), "micro overlay still up")
stub.pressKey("SHIFT-J")
assert(CollectionsJournal:IsShown() and not f:IsShown(), "the game's key")
UIParent.Hide(CollectionsJournal)
PolestarUI.Switch("collections", true)
stub.pressKey("SHIFT-J")
assert(f:IsShown() and not CollectionsJournal:IsShown(), "on again")
