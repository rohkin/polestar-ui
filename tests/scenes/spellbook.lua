--@ title: Spellbook: Fire
--@ roots: PolestarUISpellbook
--@ stubs: stub_spellbook.lua
-- The spellbook key opens ours without the stock book, and closes it again (docs/CLIENT.md, rule 8).
stub.pressKey("P")
assert(not PlayerSpellsFrame:IsShown(), "stock book open")
assert(PolestarUISpellbook:IsShown(), "ours closed")
stub.pressKey("P")
assert(not PolestarUISpellbook:IsShown(), "no toggle")
PolestarUI.Show("spellbook", "line3")
