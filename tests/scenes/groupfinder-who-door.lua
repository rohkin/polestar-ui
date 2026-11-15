--@ title: Group Finder: Who results open ours
--@ roots: PolestarUIGroupFinder
--@ stubs: stub_groupfinder.lua, stub_who.lua
-- The stock Who list shows the game's window on every WHO_LIST_UPDATE, so while ours is on that one event is unregistered on LFGWhoListFrame (docs/CLIENT.md, rule 15's exception), also when its addon loads late; results sent to the UI (a long /who typed in chat) open our Who page in its place. Switched off, the stock frame takes the event again and opens the game's window; switched on, it is taken again.
local f = PolestarUIGroupFinder
assert(not LFGWhoListFrame:IsEventRegistered("WHO_LIST_UPDATE"), "stock Who list still takes the results")
stub.whoResults = stub.whoSample
stub.fire("WHO_LIST_UPDATE")
f = PolestarUIGroupFinder
assert(f and f:IsShown() and PolestarUIDB.groupFinderPage == "who" and not LFGParentFrame:IsShown(), "results did not open our Who page")
assert(f.psWhoRows[5]:IsShown() and stub.whoToUi == true, "no cards")
-- On another page, results bring the Who page forward.
f.railButtons[1]:Click()
stub.fire("WHO_LIST_UPDATE")
assert(PolestarUIDB.groupFinderPage == "who", "not brought to Who")
-- Off: the stock list takes the event again and opens the game's window.
PolestarUI.Switch("groupfinder", false)
assert(not f:IsShown() and LFGWhoListFrame:IsEventRegistered("WHO_LIST_UPDATE"), "off: not given back")
stub.fire("WHO_LIST_UPDATE")
assert(LFGParentFrame:IsShown() and not f:IsShown(), "off: ours opened")
UIParent.Hide(LFGParentFrame)
-- On again, and a late load of the stock addon: taken again.
PolestarUI.Switch("groupfinder", true)
assert(not LFGWhoListFrame:IsEventRegistered("WHO_LIST_UPDATE"), "on: not taken again")
stub.loadWhoList()
assert(LFGWhoListFrame:IsEventRegistered("WHO_LIST_UPDATE"), "stub: late frame")
stub.addonLoaded("Blizzard_GroupFinder_VanillaStyle")
assert(not LFGWhoListFrame:IsEventRegistered("WHO_LIST_UPDATE"), "late load: not taken")
stub.fire("WHO_LIST_UPDATE")
assert(f:IsShown() and not LFGParentFrame:IsShown(), "late load: the game's window opened")
stub.assertNoErrors()
