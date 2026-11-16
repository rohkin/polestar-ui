--@ title: Collections: Mounts, searched and filtered
--@ roots: PolestarUICollections, PolestarMenu
--@ stubs: stub_collections.lua
-- The search sits atop the filter's dropdown, focused as it opens. Each page keeps its own search on the client (C_MountJournal.SetSearch, C_ToyBox.SetFilterString); the stock filter menus, flat: the source list opens from a row, the glyph lit while a filter is off its default, "Reset filters" then; the list redraws at once.
PolestarUI.Show("collections", "mounts")
local f = PolestarUICollections
local function rows()
	local n = 0
	for _, r in ipairs({ f.psNav.Child:GetChildren() }) do if r.psMount and r:IsShown() then n = n + 1 end end
	return n
end
assert(not f.Search:IsShown(), "search on the tab row")
f.psFilter:Click()
assert(f.Search:IsShown() and f.Search:GetParent() == PolestarMenu, "search not in the dropdown")
f.Search:SetText("swift")
stub.RunScript(f.Search, "OnTextChanged")
stub.RunScript(f.Search, "OnEnterPressed")
assert(stub.mountSearch == "swift" and rows() == 2 and not PolestarMenu:IsShown() and f.psFilter.psActive, "search: " .. rows())
assert(f.psStatus:GetText() == "7 mounts collected · 2 shown", "subtitle: " .. f.psStatus:GetText())
-- The toy box has its own search; the mounts' comes back with them.
PolestarUI.Show("collections", "toys")
assert(f.Search:GetText() == "", "toy search not its own")
f.Search:SetText("orb")
stub.RunScript(f.Search, "OnTextChanged")
assert(stub.toySearch == "orb" and f.psStatus:GetText():find("Page 1 of 1", 1, true), "toy search")
PolestarUI.Show("collections", "mounts")
assert(f.Search:GetText() == "swift" and stub.toySearch == "orb", "mount search lost")
f.Search:SetText("")
stub.RunScript(f.Search, "OnTextChanged")
assert(rows() == 10 and f.psStatus:GetText() == "7 mounts collected", "search cleared")
-- The filter: Not Collected off hides three mounts at once and lights the glyph.
f.psFilter:Click()
assert(PolestarMenu.rows[3].psItem.text == "Not Collected" and PolestarMenu.rows[3].psItem.checked, "filter menu")
PolestarMenu.rows[3]:Click()
assert(rows() == 7 and PolestarMenu:IsShown(), "not redrawn at once, or the menu closed")
assert(f.psFilter.psTip == "Search and filter (on)", "glyph not lit")
-- The sources open as a menu of their own, with Back, Check All and Uncheck All.
local src
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() and r.psItem.text == "Sources…" then src = r end end
src:Click()
assert(PolestarMenu.rows[1].psItem.text == "Back" and PolestarMenu.rows[3].psItem.text == "Uncheck All", "sources menu")
local pet = false
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() and r.psItem.text == "Pet Battle" then pet = true end end
assert(not pet, "an invalid source listed")
assert(not f.Search:IsShown(), "the search over a submenu")
PolestarMenu.rows[1]:Click()
assert(f.Search:IsShown(), "the search not back over the main menu")
-- Drawn with the main menu open, "Reset filters" at its end.
local last
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() then last = r end end
assert(last.psItem.text == "Reset filters", "no reset")
