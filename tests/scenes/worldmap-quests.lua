--@ title: World Map: Quest Log
--@ roots: PolestarUIWorldMap
--@ stubs: stub_worldmap.lua
-- The quest log key opens our map with its quest log, never the stock map: headers fold at once, hidden quests stay out, a quest shows its level, objectives and marks; hover lights its area, a click shows its map, shift-click tracks, chat links; the column is remembered and widens the window, its tab (with the log's count) shuts it, the search (atop the filter's dropdown, the game's filter menu read into its rows under it, a submenu in place) matches titles and objectives, and the empty body leaves it the mouse wheel; the Map Legend tab shows the legend in its place, whose rows light their pins.
stub.pressKey("L")
local f = PolestarUIWorldMap
local c = PolestarUIWorldMapCanvas
local q = f.psQuests
assert(f:IsShown() and q:IsShown() and not WorldMapFrame:IsShown(), "quest log key")
local function rows() local t = {} for _, r in ipairs({ q.Scroll.Child:GetChildren() }) do if r:IsShown() then t[#t + 1] = r end end return t end
local function row(n) for _, r in ipairs(rows()) do if (r.psTitle or (r.Label and r.Label:GetText())) == n then return r end end end
assert(#rows() == 5 and not row("Hidden") and not row("The Defias Brotherhood"), "rows: " .. #rows())
local tab = f.tabButtons[1]
assert(tab.Label:GetText() == "Quests" and tab.psNavCount:GetText() == "5/25", "count on the tab: " .. tostring(tab.psNavCount:GetText()))
assert(not f.Search:IsShown(), "the search on the tab row")
local kobold, wolves = row("Kobold Camp Cleanup"), row("Wolves Across the Border")
assert(kobold.Goals:GetText():find("4/10") and kobold.Tracked:IsShown() and kobold.Tracked:GetAtlas() == "questlog-icon-checkmark-yellow" and not kobold.Mark:IsShown(), "objectives, tracked")
assert(wolves.Mark:IsShown() and wolves.Tracked:IsShown() and row("A Threat Within").Name:GetText() == "[1] A Threat Within", "done and tracked both show, level")
local tx = select(4, wolves.Tracked:GetPoint(1))
assert(select(4, wolves.Mark:GetPoint(1)) < tx and select(4, kobold.Tracked:GetPoint(1)) == tx, "two fixed slots, tracked at the end")
assert(wolves.Name:GetWidth() == row("A Threat Within").Name:GetWidth(), "the title's width keeps the slots free")
assert(row("Wolves Across the Border").Name:GetText() == "[3+] Wolves Across the Border", "elite mark")
row("Westfall"):Click()
assert(row("The Defias Brotherhood"), "header did not unfold at once")
assert(row("The Defias Brotherhood").Goals:GetText() == "1s 20c / 5s 0c", "the money it takes, have / need: " .. tostring(row("The Defias Brotherhood").Goals:GetText()))
assert(not row("Heroes of the Alliance"), "an empty header")
stub.campaign = 5
q.Paint()
assert(row("Heroes of the Alliance"), "a campaign's header always shows")
stub.campaign = nil
stub.inGroup = true
q.Paint()
assert(row("A Threat Within").Name:GetText() == "[1] [2] A Threat Within", "party members on it")
stub.inGroup = false
q.Paint()
assert(row("The Defias Brotherhood").Tag:IsShown() and row("The Defias Brotherhood").Tag:GetAtlas() == "questlog-questtypeicon-group", "the stock tag")
stub.RunScript(row("Kobold Camp Cleanup"), "OnEnter")
assert(c.events[#c.events][1] == "SetHighlightedQuestID" and c.events[#c.events][2] == 7, "hover")
stub.RunScript(row("Kobold Camp Cleanup"), "OnLeave")
stub.keys.shift = true
row("Kobold Camp Cleanup"):Click()
stub.keys.shift = false
assert(not stub.watched[7], "shift-click track")
-- Right-click: the stock title menu under its tag; focus is the client's super-track.
stub.RunScript(row("Kobold Camp Cleanup"), "OnClick", "RightButton")
local qm = stub.menu
local function entry(m, t) for _, x in ipairs(m.items) do if x.text == t then return x end end end
assert(qm.tag == "MENU_QUEST_MAP_LOG_TITLE" and entry(qm, TRACK_QUEST) and entry(qm, SUPER_TRACK_QUEST) and entry(qm, SHARE_QUEST).disabled and entry(qm, ABANDON_QUEST), "quest menu")
assert(not q.Details:IsShown(), "a right-click opens no details")
entry(qm, SUPER_TRACK_QUEST).click()
assert(stub.superTracked == 7 and row("Kobold Camp Cleanup").Bar:IsShown() and not row("A Threat Within").Bar:IsShown(), "focused, marked")
stub.RunScript(row("Kobold Camp Cleanup"), "OnEnter")
assert(table.concat(GameTooltip.lines, "/"):find("Focused", 1, true) and table.concat(GameTooltip.lines, "/"):find("Kobold Vermin slain: 4/10", 1, true), "the stock tooltip's objectives, and the focus")
stub.RunScript(row("Kobold Camp Cleanup"), "OnLeave")
stub.RunScript(row("Kobold Camp Cleanup"), "OnClick", "RightButton")
entry(stub.menu, STOP_SUPER_TRACK_QUEST).click()
assert(stub.superTracked == 0, "unfocused")
stub.RunScript(row("Kobold Camp Cleanup"), "OnClick", "RightButton")
entry(stub.menu, TRACK_QUEST).click()
assert(stub.watched[7] and row("Kobold Camp Cleanup").Tracked:IsShown(), "tracked from the menu")
stub.RunScript(row("Kobold Camp Cleanup"), "OnClick", "RightButton")
entry(stub.menu, ABANDON_QUEST).click()
assert(PolestarModal:IsShown() and not stub.abandoned, "abandon asks first")
PolestarModal.Box.Cancel:Click()
-- A header's menu: track or untrack all its quests.
stub.RunScript(row("Elwynn Forest"), "OnClick", "RightButton")
assert(stub.menu.tag == "MENU_QUEST_MAP_FRAME", "header menu")
entry(stub.menu, QUEST_LOG_UNTRACK_ALL).click()
assert(not stub.watched[7] and not stub.watched[33] and not stub.watched[783], "untrack all")
stub.RunScript(row("Elwynn Forest"), "OnClick", "RightButton")
entry(stub.menu, QUEST_LOG_TRACK_ALL).click()
assert(stub.watched[7] and stub.watched[33] and stub.watched[783] and not stub.watched[65] and row("Elwynn Forest"), "track all, its own quests only, not folded")
stub.watched = { [33] = true }
q.Paint()
stub.chatOpen = true
row("A Threat Within"):Click()
stub.chatOpen = false
assert(stub.linked == 783, "link")
row("The Defias Brotherhood"):Click()
assert(q.Details:IsShown() and c.mapID == 52 and c.events[#c.events][1] == "SetFocusedQuestID", "select")
q.Details.Back:Click()
assert(row("The Defias Brotherhood").Sel:IsShown(), "selected in the list")
local w = f:GetWidth()
stub.pressKey("L")
assert(not f:IsShown(), "L closes it")
stub.pressKey("M")
assert(q:IsShown(), "not remembered")
tab:Click()
assert(not q:IsShown() and f:GetWidth() == w - 320 and not PolestarUIDB.mapQuests and not f.Search:IsShown(), "the tab shuts it")
stub.pressKey("L")
assert(q:IsShown() and f:GetWidth() == w, "L opens the log")
assert(not f.Scroll:IsShown(), "the empty body takes the mouse wheel")
f.psFilter:Click()
assert(f.Search:IsShown() and f.Search:GetParent() == PolestarMenu, "the search not in the dropdown")
f.Search:SetText("vermin")
stub.RunScript(f.Search, "OnTextChanged")
assert(#rows() == 2 and row("Kobold Camp Cleanup"), "search by objective: " .. #rows())
f.Search:SetText("defias")
stub.RunScript(f.Search, "OnTextChanged")
assert(row("The Defias Brotherhood"), "search")
f.Search:SetText("zzz")
stub.RunScript(f.Search, "OnTextChanged")
assert(#rows() == 0 and q.Empty:IsShown() and q.Empty:GetText() == "No quests match." and f.psFilter.psActive, "no match, or the filter unlit")
f.Search:SetText("")
stub.RunScript(f.Search, "OnTextChanged")
stub.RunScript(f.Search, "OnEnterPressed")
assert(select(1, f.psFilter:GetPoint(1)) == "RIGHT" and not PolestarMenu:IsShown() and f.psFilter.psTip == "Search and filter" and not f.psFilter.psActive, "filter at the tab row's end, unlit at its defaults")
-- The game's filter menu (MENU_WORLD_MAP_TRACKING) read into the dropdown
-- under the search, never shown as the game's: headings, checks, a separator
-- per divider run, then what other addons add (Menu.ModifyMenu), a submenu as
-- a "…" row opened in place; a check keeps the dropdown open, read anew.
Menu.ModifyMenu("MENU_WORLD_MAP_TRACKING", function(_, root)
	local sub = root:CreateButton("Test services")
	sub:CreateCheckbox("Show test pins", function() return stub.testPins end, function() stub.testPins = not stub.testPins end)
	sub:CreateDivider()
	sub:CreateButton("Go there", function() stub.wentThere = true end)
end)
local M = PolestarMenu
local function shown()
	local t = {}
	for _, r in ipairs(M.rows) do if r:IsShown() then t[#t + 1] = r end end
	return t
end
local function texts() local t = {} for i, r in ipairs(shown()) do t[i] = tostring(r.psItem.text) end return table.concat(t, " | ") end
local function mrow(text) for _, r in ipairs(shown()) do if r.psItem.text == text then return r end end end
local function seps() local n = 0 for _, s in ipairs(M.seps) do if s:IsShown() then n = n + 1 end end return n end
local function mapMenu()
	if not M:IsShown() then f.psFilter:Click() end
	return shown()
end
stub.menu = nil
local it = mapMenu()
assert(M:IsShown() and M.psOwner == f.psFilter and f.Search:IsShown() and it[1] and it[1].psItem.text == "" and not stub.menu, "the game's menu in our dropdown, under the search: " .. texts())
assert(texts() == " | Show on Map: | Quest Objectives | Show Quest Levels | Quest Difficulty Color | Low-Level Quests | Tracked Items | Show in Quest Log: | Quest Objectives | Test services…", "stock rows, then the addon's: " .. texts())
assert(it[2].psItem.disabled and it[8].psItem.disabled and seps() == 2, "headings, a separator under the search and per divider run")
assert(it[4].psItem.psEnter and not it[9].psItem.psEnter, "the stock filter tooltips")
stub.RunScript(it[4], "OnEnter")
assert(GameTooltip:IsShown() and GameTooltip.lines[1] == SHOW_QUEST_LEVELS and GameTooltip.lines[2] == QUEST_LEVEL_FILTER_DESCRIPTION, "an entry's tooltip on our row")
stub.RunScript(it[4], "OnLeave")
assert(it[4].psItem.checked and it[5].psItem.checked and not it[6].psItem.checked and it[9].psItem.checked, "filters read the stock CVars")
local n = c.refreshed or 0
it[4]:Click()
it = shown()
assert(stub.cvars.showQuestLevel == "0" and row("A Threat Within").Name:GetText() == "A Threat Within" and c.refreshed == n + 1, "levels off, redrawn at once")
assert(M:IsShown() and f.Search:IsShown() and not it[4].psItem.checked, "the dropdown kept open, its check read anew")
assert(f.psFilter.psActive and f.psFilter.psTip == "Search and filter (1 on)", "lit off its default")
local clear = mrow("Clear filters")
assert(clear and not clear.psItem.disabled, "clear filters entry")
clear:Click()
assert(not M:IsShown(), "a button closes the dropdown")
assert(stub.cvars.showQuestLevel == "1" and not f.psFilter.psActive and f.psFilter.psTip == "Search and filter", "cleared back to the defaults")
assert(row("A Threat Within").Name:GetText() == "[1] A Threat Within", "levels on")
local function hue() return table.concat({ row("The Defias Brotherhood").Name:GetTextColor() }, ",") end
local function toggle(i) mapMenu()[i]:Click() end
local red = hue()
toggle(5)
local plain = hue()
assert(plain ~= red, "plain colour")
toggle(5)
assert(hue() == red, "difficulty colour")
toggle(6)
assert(not stub.trivialOut and mapMenu()[6].psItem.checked, "low-level quests through the tracking filter")
toggle(6)
assert(stub.trivialOut, "low-level quests off")
toggle(9)
assert(stub.cvars.showQuestObjectivesInLog == "0" and not row("Kobold Camp Cleanup").Goals:IsShown(), "objectives hidden")
toggle(9)
assert(row("Kobold Camp Cleanup").Goals:IsShown(), "objectives shown")
-- The addon's submenu, in place: Back first, its check keeps it open.
mrow("Test services…"):Click()
assert(M:IsShown() and not f.Search:IsShown() and texts() == "Back | Show test pins | Go there" and seps() == 2, "the submenu in place: " .. texts())
mrow("Show test pins"):Click()
assert(stub.testPins and M:IsShown() and mrow("Show test pins").psItem.checked, "its check kept open, read anew")
mrow("Back"):Click()
assert(f.Search:IsShown() and mrow("Test services…"), "back to the top, the search with it")
mrow("Test services…"):Click()
mrow("Go there"):Click()
assert(stub.wentThere and not M:IsShown(), "its button picked, the dropdown shut")
stub.cvars.showQuestLevel = "0"
stub.fire("CVAR_UPDATE", "showQuestLevel")
assert(row("A Threat Within").Name:GetText() == "A Threat Within", "a change from the stock menu")
stub.cvars.showQuestLevel = "1"
stub.fire("CVAR_UPDATE", "showQuestLevel")
row("The Defias Brotherhood"):Click()
assert(f.psFilter:IsShown(), "the map's filter left with the details")
f.psFilter:Click()
assert(not f.Search:IsShown() and M:IsShown() and mrow("Show on Map:") and not stub.menu, "no search on the details: the filters alone")
f.psFilter:Click()
q.Details.Back:Click()
f.psFilter:Click()
assert(f.Search:IsShown() and M:IsShown(), "the search back with the list")
Polestar.Widgets.HideMenu()
-- The Map Legend tab: the legend in the log's place (remembered), its rows
-- the client's pin kinds by category (one the client lacks left out); a hover
-- gives the stock tooltip and lights its pins on our map.
local lt = f.tabButtons[2]
assert(lt.Label:GetText() == "Map Legend", "legend tab")
lt:Click()
local lg = f.psLegend
assert(lg:IsShown() and not q:IsShown() and PolestarUIDB.mapQuests == "legend" and f:GetWidth() == w and not f.Search:IsShown(), "the legend in the log's place")
assert(#lg.Rows == 5 and lg.Rows[1].Label:GetText() == "Turn In" and lg.Rows[1].Back and lg.Rows[3].Label:GetText() == "Dungeon", "legend rows: " .. #lg.Rows)
stub.RunScript(lg.Rows[4], "OnEnter")
assert(GameTooltip.lines[1] == "Raid" and stub.mapPins[2].glow and not stub.mapPins[1].glow, "a raid row lights the raid's pin only")
stub.RunScript(lg.Rows[4], "OnLeave")
assert(not stub.mapPins[2].glow, "lit off again")
lt:Click()
assert(not lg:IsShown() and not PolestarUIDB.mapQuests, "its tab shuts it")
lt:Click()
stub.pressKey("L")
assert(f:IsShown() and q:IsShown() and not lg:IsShown(), "L over the legend opens the log")
