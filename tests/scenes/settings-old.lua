--@ title: Settings: Polestar older than 0.4.0 is refused (a plain release number only)
--@ roots: PolestarUISpellbook
--@ stubs: stub_spellbook.lua
local ns = PolestarUI
assert(ns.PolestarTooOld("0.3.7") and ns.PolestarTooOld("0.3.10") and ns.PolestarTooOld("0.3.7.1"), "0.3.x passes")
assert(not ns.PolestarTooOld("0.4.0") and not ns.PolestarTooOld("0.4.1") and not ns.PolestarTooOld("1.0.0") and not ns.PolestarTooOld("0.4.3.1"), "0.4.0+ refused")
assert(not ns.PolestarTooOld("dev") and not ns.PolestarTooOld("0.1.0-test"), "a dev or test build refused")
-- Too old: no switch, no window, one line saying why.
local said, print0 = 0, print
print = function(m) if tostring(m):find("needs Polestar 0.4.0", 1, true) then said = said + 1 end end
ns.tooOld = true
ns.Switch("spellbook", false)
ns.Show("spellbook")
ns.tooOld, print = false, print0
assert(PolestarUIDB.modules.spellbook == nil, "switched while too old")
assert(said == 2, "no update line: " .. said)
ns.Show("spellbook")
