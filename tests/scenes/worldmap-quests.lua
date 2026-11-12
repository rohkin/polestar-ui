--@ title: World Map: Quest Log
--@ roots: PolestarUIWorldMap
--@ stubs: stub_worldmap.lua
-- The quest log key opens our map with its quest log, never the stock map: headers fold at once, hidden quests stay out, a quest shows its level, objectives and marks; hover lights its area, a click shows its map, shift-click tracks, chat links; the flyout is remembered and widens the window, searches titles and objectives, and the empty body leaves it the mouse wheel.
stub.pressKey("L")
local f = PolestarUIWorldMap
local c = PolestarUIWorldMapCanvas
local q = f.psQuests
assert(f:IsShown() and q:IsShown() and not WorldMapFrame:IsShown(), "quest log key")
local function rows() local t = {} for _, r in ipairs({ q.Scroll.Child:GetChildren() }) do if r:IsShown() then t[#t + 1] = r end end return t end
local function row(n) for _, r in ipairs(rows()) do if (r.psTitle or (r.Label and r.Label:GetText())) == n then return r end end end
assert(#rows() == 5 and not row("Hidden") and not row("The Defias Brotherhood"), "rows: " .. #rows())
assert(q.Count:GetText() == "5/25", "count " .. q.Count:GetText())
assert(row("Kobold Camp Cleanup").Goals:GetText():find("4/10") and row("Kobold Camp Cleanup").Mark:IsShown(), "objectives, tracked")
assert(row("Wolves Across the Border").Mark:IsShown() and row("A Threat Within").Name:GetText() == "[1] A Threat Within", "done, level")
assert(row("Wolves Across the Border").Name:GetText() == "[3+] Wolves Across the Border", "elite mark")
row("Westfall"):Click()
assert(row("The Defias Brotherhood"), "header did not unfold at once")
stub.RunScript(row("Kobold Camp Cleanup"), "OnEnter")
assert(c.events[#c.events][1] == "SetHighlightedQuestID" and c.events[#c.events][2] == 7, "hover")
stub.RunScript(row("Kobold Camp Cleanup"), "OnLeave")
stub.keys.shift = true
row("Kobold Camp Cleanup"):Click()
stub.keys.shift = false
assert(not stub.watched[7], "shift-click track")
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
f.psQuestsButton:Click()
assert(not q:IsShown() and f:GetWidth() == w - 320 and not PolestarUIDB.mapQuests, "button")
stub.pressKey("L")
assert(q:IsShown() and f:GetWidth() == w, "L opens the log")
assert(not f.Scroll:IsShown(), "the empty body takes the mouse wheel")
q.Search:SetText("vermin")
stub.RunScript(q.Search, "OnTextChanged")
assert(#rows() == 2 and row("Kobold Camp Cleanup"), "search by objective: " .. #rows())
q.Search:SetText("defias")
stub.RunScript(q.Search, "OnTextChanged")
assert(row("The Defias Brotherhood"), "search")
q.Search:SetText("zzz")
stub.RunScript(q.Search, "OnTextChanged")
assert(#rows() == 0 and q.Empty:IsShown() and q.Empty:GetText() == "No quests match.", "no match")
q.Search:SetText("")
stub.RunScript(q.Search, "OnTextChanged")
assert(select(1, q.Filter:GetPoint(1)) == "TOPRIGHT" and q.Filter.psTip == "Filter" and not q.Filter.psActive, "filter at the search row's end, unlit at its defaults")
q.Filter:Click()
local m = stub.menu
local it = m.items
assert(m.tag == "MENU_WORLD_MAP_TRACKING" and #it == 8 and it[1].title and it[7].title, "filter menu: the stock tag, map filters, then the log ones")
assert(it[3].onEnter and not it[8].onEnter, "the stock filter tooltips")
assert(it[3].text == SHOW_QUEST_LEVELS and it[3].get() and it[4].get() and not it[5].get() and it[8].get(), "filters read the stock CVars")
local n = c.refreshed or 0
it[3].set()
assert(stub.cvars.showQuestLevel == "0" and row("A Threat Within").Name:GetText() == "A Threat Within" and c.refreshed == n + 1, "levels off, redrawn at once")
assert(q.Filter.psActive and q.Filter.psTip == "Filter (1 on)", "lit off its default")
q.Filter:Click()
local clear = stub.menu.items[#stub.menu.items]
assert(clear.button and clear.text == "Clear filters", "clear filters entry")
clear.click()
assert(stub.cvars.showQuestLevel == "1" and not q.Filter.psActive and q.Filter.psTip == "Filter", "cleared back to the defaults")
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
assert(not q.Filter:IsShown(), "no filter on the details")
q.Details.Back:Click()
