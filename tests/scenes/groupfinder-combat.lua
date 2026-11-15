--@ title: Group Finder: in combat
--@ roots: PolestarUIGroupFinder
--@ stubs: stub_groupfinder.lua
-- In combat the keys still open and close ours (override bindings set before); the game's-window button is greyed with the reason and no secure button is placed over it (a secure frame cannot move in combat: docs/CLIENT.md, rule 4); the switch is refused. After combat the button works again.
stub.inCombat = true
stub.fire("PLAYER_REGEN_DISABLED")
stub.pressKey("I")
local f = PolestarUIGroupFinder
assert(f:IsShown(), "key in combat")
stub.pressKey("I")
assert(not f:IsShown(), "key closes in combat")
PolestarUI.Switch("groupfinder", false)
assert(PolestarUI.Enabled("groupfinder"), "switched in combat")
stub.pressKey("I")
local b = f.footerButtons.right[1]
assert(not b:IsEnabled() and b.psReason == "You can't do that while in combat.", "game's window button: " .. tostring(b.psReason))
stub.RunScript(b, "OnEnter")
assert(not (PolestarUIGroupFinderGame and PolestarUIGroupFinderGame:IsShown()), "secure button placed in combat")
stub.inCombat = false
stub.fire("PLAYER_REGEN_ENABLED")
assert(b:IsEnabled(), "still greyed after combat")
stub.inCombat = true
stub.fire("PLAYER_REGEN_DISABLED")
stub.assertNoErrors()
