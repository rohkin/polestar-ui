--@ title: World Map: Quest Log
--@ roots: PolestarUIWorldMap
--@ stubs: stub_worldmap.lua
-- The quest log key opens our map with its quest log, never the stock map: headers fold at once, hidden quests stay out, a quest shows its level, objectives and marks; hover lights its area, a click shows its map, shift-click tracks, chat links; the column is remembered and widens the window, its tab (with the log's count) shuts it, the search on the tab row matches titles and objectives, and the empty body leaves it the mouse wheel; the Map Legend tab shows the legend in its place, whose rows light their pins.
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
assert(f.Search:IsShown() and f.Search:GetParent() == f.TabRow, "the search on the tab row")
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
f.Search:SetText("vermin")
stub.RunScript(f.Search, "OnTextChanged")
assert(#rows() == 2 and row("Kobold Camp Cleanup"), "search by objective: " .. #rows())
f.Search:SetText("defias")
stub.RunScript(f.Search, "OnTextChanged")
assert(row("The Defias Brotherhood"), "search")
f.Search:SetText("zzz")
stub.RunScript(f.Search, "OnTextChanged")
assert(#rows() == 0 and q.Empty:IsShown() and q.Empty:GetText() == "No quests match.", "no match")
f.Search:SetText("")
stub.RunScript(f.Search, "OnTextChanged")
assert(select(1, f.psFilter:GetPoint(1)) == "RIGHT" and select(2, f.Search:GetPoint(1)) == f.psFilter and f.psFilter.psTip == "Filter" and not f.psFilter.psActive, "filter at the search's end, unlit at its defaults")
f.psFilter:Click()
local m = stub.menu
local it = m.items
assert(m.tag == "MENU_WORLD_MAP_TRACKING" and #it == 8 and it[1].title and it[7].title, "filter menu: the stock tag, map filters, then the log ones")
assert(it[3].onEnter and not it[8].onEnter, "the stock filter tooltips")
assert(it[3].text == SHOW_QUEST_LEVELS and it[3].get() and it[4].get() and not it[5].get() and it[8].get(), "filters read the stock CVars")
local n = c.refreshed or 0
it[3].set()
assert(stub.cvars.showQuestLevel == "0" and row("A Threat Within").Name:GetText() == "A Threat Within" and c.refreshed == n + 1, "levels off, redrawn at once")
assert(f.psFilter.psActive and f.psFilter.psTip == "Filter (1 on)", "lit off its default")
f.psFilter:Click()
local clear = stub.menu.items[#stub.menu.items]
assert(clear.button and clear.text == "Clear filters", "clear filters entry")
clear.click()
assert(stub.cvars.showQuestLevel == "1" and not f.psFilter.psActive and f.psFilter.psTip == "Filter", "cleared back to the defaults")
assert(row("A Threat Within").Name:GetText() == "[1] A Threat Within", "levels on")
local function hue() return table.concat({ row("The Defias Brotherhood").Name:GetTextColor() }, ",") end
local red = hue()
it[4].set()
local plain = hue()
assert(plain ~= red, "plain colour")
it[4].set()
assert(hue() == red, "difficulty colour")
it[5].set()
assert(not stub.trivialOut and it[5].get(), "low-level quests through the tracking filter")
it[5].set()
assert(stub.trivialOut, "low-level quests off")
it[8].set()
assert(stub.cvars.showQuestObjectivesInLog == "0" and not row("Kobold Camp Cleanup").Goals:IsShown(), "objectives hidden")
it[8].set()
assert(row("Kobold Camp Cleanup").Goals:IsShown(), "objectives shown")
stub.cvars.showQuestLevel = "0"
stub.fire("CVAR_UPDATE", "showQuestLevel")
assert(row("A Threat Within").Name:GetText() == "A Threat Within", "a change from the stock menu")
stub.cvars.showQuestLevel = "1"
stub.fire("CVAR_UPDATE", "showQuestLevel")
row("The Defias Brotherhood"):Click()
assert(not f.Search:IsShown() and f.psFilter:IsShown(), "no search on the details; the map's filter stays")
q.Details.Back:Click()
assert(f.Search:IsShown(), "the search back with the list")
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
