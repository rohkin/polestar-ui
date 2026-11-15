--@ title: Collections: Appearances, no sets
--@ roots: PolestarUICollections
--@ stubs: stub_collections.lua
-- Forever (live): no valid transmog sets and no category info for one-handed axes (13). Appearances shows Items alone, no Items | Sets switch on the tab row, its fact at the row's left; Sets left open before falls back to Items. The main hand, whose only weapon type has no info, gets no weapon picker and an empty grid, without an error.
PolestarUI.Show("collections", "appearances")
local f = PolestarUICollections
f.tabButtons[2]:Click()
assert(f.psNav:IsShown() and not f.psLooks:IsShown(), "sets view first")
f:Hide()
stub.noSets = true
stub.noCategory = { [13] = true }
PolestarUI.Show("collections", "appearances")
local L = f.psLooks
assert(L:IsShown() and not f.psNav:IsShown(), "items, not sets")
assert(not (f.tabButtons and f.tabButtons[1] and f.tabButtons[1]:IsShown()), "no Items | Sets switch")
-- Each tile's model at the stock tile's 78 by 104, its mouse over the whole tile.
local m = L.Looks[1].psModel
assert(math.abs(m:GetWidth() / m:GetHeight() - 78 / 104) < 0.01 and m.hitInsets[1] < 0, "tile model aspect")
for _, b in ipairs(L.Slots) do if b.psLoc.slot == "MAINHANDSLOT" then b:Click() end end
assert(not L.Weapon:IsShown() and L.Empty:IsShown(), "no picker for a category without info")
for _, b in ipairs(L.Slots) do if b.psLoc.slot == "HEADSLOT" then b:Click() end end
assert(not L.Empty:IsShown() and f.psStatus:GetText():find("collected"), "head appearances")
stub.assertNoErrors()
