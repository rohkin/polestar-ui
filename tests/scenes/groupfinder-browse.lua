--@ title: Group Finder: Browse
--@ roots: PolestarUIGroupFinder
--@ stubs: stub_groupfinder.lua, stub_lfgbrowse.lua
-- Browse never searches by itself (C_LFGList.Search needs a hardware event): opening it shows the pick-a-category line and Refresh greyed. Picking a category searches for its activities in the player's level range; Refresh stays on while the search runs (a click searches again). The results come sorted as stock (own listing, then matches to it, groups before solo players), under Groups and Solo Players headings, with every member display: role icons, role counts, class icons, a player count, a comment, none; a solo player's class and level; a delisted one dimmed. Ticking one activity in the filter does not search (as stock) but dims the rows it leaves out. The tooltip lists members, voice chat, activities and bosses defeated.

local results = stub.resultOrder
stub.resultOrder = {}
PolestarUI.Show("groupfinder", "browse")
local f = PolestarUIGroupFinder
assert(f:IsShown() and PolestarUIDB.groupFinderPage == "browse", "not on Browse")
assert(stub.searched == nil, "searched on show")
assert(f.TabRow:IsShown(), "no tab row")
local function find(parent, test)
	for _, c in ipairs({ parent:GetChildren() }) do if test(c) then return c end end
end
local cat = find(f.TabRow, function(c) return type(c.Label) == "table" and c.Label.GetText and c.Label:GetText() == "Category" end)
local act = find(f.TabRow, function(c) return type(c.Label) == "table" and c.Label.GetText and c.Label:GetText() == "All Activities" end)
local refresh = find(f.TabRow, function(c) return c.psIconName == "reload" end)
assert(cat and act and refresh, "pickers or Refresh missing")
assert(not refresh:IsEnabled() and not act:IsEnabled(), "Refresh or activities enabled with no category")
local function pick(text)
	for _, r in ipairs(PolestarMenu.rows) do
		if r:IsShown() and r.psItem and r.psItem.text == text then return r:Click() end
	end
	error("no menu item " .. text)
end
cat:Click()
pick("Dungeons")
assert(stub.searched and stub.searched.category == 2, "no search for the category")
local ids = table.concat(stub.searched.activityIDs, ",")
assert(ids == "11,12,14", "level-filtered activities: " .. ids)
assert(cat.Label:GetText() == "Dungeons" and act:IsEnabled(), "category not shown")
assert(refresh:IsEnabled() and f.Subtitle:GetText():find("Searching", 1, true), "not searching, or Refresh greyed while searching")
-- The client answers: the player is listed for Deadmines.
stub.resultOrder = results
stub.activeEntry = { activityIDs = { 11 } }
stub.fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
assert(refresh:IsEnabled() and f.Subtitle:GetText():find("9 listings", 1, true), "results: " .. tostring(f.Subtitle:GetText()))
-- Own listing first (no heading), then what matches it (Brannoc's group, Thessa), then the other groups (a slot for the player's roles, size, a healer wanted, age), then solo players.
local seen = {}
for _, c in ipairs({ f.Body:GetChildren() }) do
	for _, r in ipairs({ c:GetChildren() }) do
		if r:IsShown() and r.Name and r.psID then seen[#seen + 1] = { y = -select(5, r:GetPoint(1)), id = r.psID, r = r } end
	end
end
table.sort(seen, function(a, b) return a.y < b.y end)
local order = {}
for i, s in ipairs(seen) do order[i] = s.id end
assert(table.concat(order, ",") == "1,2,8,4,5,6,3,7,9", "order: " .. table.concat(order, ","))
assert(seen[1].r.Sub:GetText() == "Your listing" and seen[2].r.Sub:GetText():find("^Deadmines"), "activity text")
assert(seen[3].r.Sub:GetText() == "Deadmines" and seen[3].r.Level:GetText() == "Lvl 24", "solo: only the matching activity, and the level")
assert(seen[9].r.Sub:GetText() == "Delisted", "a delisted row does not say why it is dimmed")
assert(seen[6].r.Comment:IsShown() and seen[6].r.Comment:GetText() == "LF healer, chill run", "comment display")
-- Filter one activity: no search, rows it leaves out dim.
stub.searched = nil
act:Click()
pick("    Wailing Caverns")
assert(stub.searched == nil, "a single activity searched")
assert(act.Label:GetText() == "Wailing Caverns", "activity picker: " .. act.Label:GetText())
Polestar.Widgets.HideMenu()
stub.RunScript(seen[4].r, "OnEnter")
assert(table.concat(GameTooltip.lines, "/"):find("Not in your activity filter.", 1, true), "a row the filter leaves out does not say why")
stub.RunScript(seen[4].r, "OnLeave")
assert(seen[2].r.Name:GetTextColor() == seen[2].r.Sub:GetTextColor(), "a row the filter leaves out is not dimmed")
assert((seen[2].r.Name):GetFontObject() and (seen[2].r.Name):GetFontObject().members, "leader name not on the font family")
-- Reset searches the whole category again.
act:Click()
pick("Reset")
assert(stub.searched and table.concat(stub.searched.activityIDs, ",") == "11,12,14", "Reset did not search")
stub.fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
assert(act.Label:GetText() == "All Activities", "filter not reset")
-- Tooltip on Brannoc's group.
stub.RunScript(seen[2].r, "OnEnter")
local tip = table.concat(GameTooltip.lines, "/")
for _, want in ipairs({ "Brannoc", "New Player Friendly", "Ellia", "3 members", "Discord", "Classic Dungeons", "Rhahk'Zor" }) do
	assert(tip:find(want, 1, true), "tooltip lacks " .. want .. ": " .. tip)
end
stub.RunScript(seen[2].r, "OnLeave")
stub.assertNoErrors()
