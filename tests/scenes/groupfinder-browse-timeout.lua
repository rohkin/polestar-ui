--@ title: Group Finder: Browse search unanswered
--@ roots: PolestarUIGroupFinder
--@ stubs: stub_groupfinder.lua, stub_lfgbrowse.lua
-- A search the client never answers (no results, no failure event) must not leave the page stuck on "Searching": after 10 seconds it reads as failed and Refresh searches again. A pick from the category menu searches from the menu row's click (Polestar runs a menu item's onClick inside that click: a hardware event). A failure event clears the search at once, and Refresh stays on throughout.
stub.resultOrder = {}
PolestarUI.Show("groupfinder", "browse")
local f = PolestarUIGroupFinder
local function find(test) for _, c in ipairs({ f.TabRow:GetChildren() }) do if test(c) then return c end end end
local cat = find(function(c) return type(c.Label) == "table" and c.Label.GetText and c.Label:GetText() == "Category" end)
local refresh = find(function(c) return c.psIconName == "reload" end)
cat:Click()
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() and r.psItem and r.psItem.text == "Dungeons" then r:Click() end end
assert(stub.searched and stub.searched.category == 2, "the menu pick did not search")
assert(f.Subtitle:GetText():find("Searching", 1, true) and refresh:IsEnabled(), "not searching, or Refresh greyed")
-- No answer: still searching a moment later, failed after the timeout.
stub.advance(5)
assert(f.Subtitle:GetText():find("Searching", 1, true), "gave up too soon")
stub.advance(5.1)
assert(f.Subtitle:GetText():find("Search failed", 1, true) and refresh:IsEnabled(), "stuck searching: " .. tostring(f.Subtitle:GetText()))
-- Refresh searches again; the client's failure event ends it at once.
stub.searched = nil
refresh:Click()
assert(stub.searched and f.Subtitle:GetText():find("Searching", 1, true), "Refresh did not search again")
stub.fire("LFG_LIST_SEARCH_FAILED")
assert(f.Subtitle:GetText():find("Search failed", 1, true) and refresh:IsEnabled(), "failure did not clear the search")
-- A search while one runs is sent again (Refresh never waits on a lost answer).
stub.searched = nil
refresh:Click()
stub.searched = nil
refresh:Click()
assert(stub.searched, "a second Refresh while searching did nothing")
-- The old search's timer does not end the new one early.
stub.advance(9)
assert(f.Subtitle:GetText():find("Searching", 1, true), "an old timer ended the new search")
stub.fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
stub.assertNoErrors()
