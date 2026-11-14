--@ title: World Map
--@ roots: PolestarUIWorldMap
--@ stubs: stub_worldmap.lua
-- The map key opens ours, never the stock map, on the player's zone, on the compact grid (no sidebar, the map under the tab row); the nav after the tabs walks up to a continent, whose zones its menu lists (a zone's caves apart, as the stock dropdown lists them), and the canvas sits in the window's strata; a map art of one zoom step gets ours, and the window goes full screen and back.
stub.pressKey("M")
local f = PolestarUIWorldMap
local c = PolestarUIWorldMapCanvas
assert(f:IsShown() and not WorldMapFrame:IsShown(), "key")
assert(c:IsShown() and c:GetFrameStrata() == f:GetFrameStrata(), "canvas under the window")
assert(c.mapID == 37 and c.zoomedOut and f.Title:GetText() == "World Map" and f.Subtitle:GetText() == "Elwynn Forest · Eastern Kingdoms", "not the player map")
assert(#c.providers > 0 and c.navigateOnClick, "canvas setup")
-- The compact grid: no sidebar, a 60 band, the canvas from the tab row's foot, 900 by 600.
assert(not f.Sidebar:IsShown() and f.Header:GetHeight() == 60 and f.psPad == 24, "compact shell")
assert(f:GetWidth() == 902 and f:GetHeight() == 60 + 36 + 2 + 600 and not f.Footer:IsShown(), "window size")
assert(select(2, c:GetPoint(1)) == f.Content and select(2, c:GetPoint(2)) == f.Content and select(2, f.Content:GetPoint(1)) == f.TabRow and f.TabRow:GetHeight() == 36, "the map fills the body under the tab row")
-- The nav after the tabs: where you are, and the shown map's menu.
local go, here = f.psGo, f.psHere
assert(f.psNav:GetParent() == f.TabRow and select(2, f.psNav:GetPoint(1)) == f.tabButtons[2] and go.Label:GetText() == "Elwynn Forest", "nav on the tab row")
assert(here.psTip == "Where you are: Elwynn Forest", "where you are")
local function menu() go:Click() return stub.menu end
local function row(n) for _, x in ipairs(menu().items) do if x.text == n then return x end end end
assert(row("Azeroth") and row("Eastern Kingdoms") and not row("Westfall"), "parents")
row("Eastern Kingdoms").click()
assert(c.mapID == 13 and go.Label:GetText() == "Eastern Kingdoms", "nav")
assert(f.Subtitle:GetText() == "Eastern Kingdoms · Azeroth", "subtitle: the parent map")
stub.RunScript(go, "OnEnter")
assert(GameTooltip:IsShown() and GameTooltip.lines[1] == "Eastern Kingdoms" and tostring(GameTooltip.lines[#GameTooltip.lines]):find("right-click to go back out", 1, true), "the hint in the nav's tooltip")
stub.RunScript(go, "OnLeave")
assert(row("Duskwood") and row("Westfall") and row("Elwynn Forest") and not row("Kalimdor"), "zones")
local list = menu().items
assert(list[1].text == "Azeroth" and list[2].divider and list[3].text == "Duskwood", "parents, then zones by name")
stub.caveListed = true
row("Elwynn Forest").click()
assert(row("Fargodeep Mine") and not row("Fargodeep Mine, Lower"), "a cave as the stock dropdown lists it, its floors once")
assert(not row("Upper Level"), "floors on an ungrouped map")
row("Fargodeep Mine").click()
assert(c.mapID == 1429, "cave row")
assert(row("Upper Level").radio and row("Upper Level").get() and not row("Lower Level").get(), "active floor")
row("Lower Level").set()
assert(c.mapID == 1430, "floor click")
c:SetMapID(52)
assert(not row("The Deadmines"), "a dungeon the dropdown does not list")
here:Click()
assert(c.mapID == 37, "where you are")
assert(not WorldMapFrame:IsShown(), "stock map")
-- Coordinates at the canvas's bottom left, as the stock CVars say (none set: shown).
c:SetMapID(37)
stub.advance(0.2)
local co = f.psCoords
assert(co:IsShown() and co.Text:GetText() == "Player: 41, 65" and select(2, co:GetPoint(1)) == c, "player coordinates: " .. tostring(co.Text:GetText()))
stub.mapCursor = { 0.5, 0.25 }
stub.cvars.coordsByTenths = "1"
stub.advance(0.2)
assert(co.Text:GetText() == "Player: 41.2, 65.3" .. string.char(10) .. "Cursor: 50.0, 25.0", "cursor coordinates, by tenths: " .. co.Text:GetText())
stub.cvars.worldMapShowPlayerCoords, stub.cvars.coordsByTenths = "0", nil
stub.advance(0.2)
assert(co.Text:GetText() == "Cursor: 50, 25", "the player's CVar off")
stub.cvars.worldMapShowPlayerCoords, stub.cvars.worldMapShowCursorCoords = "1", "0"
c:SetMapID(52)
stub.advance(0.2)
assert(co.Text:GetText() == "Player: 41, 65 (Elwynn Forest)", "off this map: the player's own map named")
stub.cvars.worldMapShowPlayerCoords, stub.cvars.worldMapShowCursorCoords, stub.mapCursor = nil, nil, nil
c:SetMapID(37)
stub.advance(0.2)
-- The filter at the tab row's end (the log's menu, the log shut), the
-- search hidden with the log; full screen and the map pin on the canvas's top right.
local mf, pin = f.psFilter, f.psPin
assert(not f.psQuests:IsShown() and mf:IsShown() and mf:GetParent() == f.TabRow and select(1, mf:GetPoint(1)) == "RIGHT" and not f.Search:IsShown(), "the filter on the tab row")
assert(select(2, f.psFullButton:GetPoint(1)) == c and select(1, f.psFullButton:GetPoint(1)) == "TOPRIGHT" and select(2, pin:GetPoint(1)) == c, "controls on the map")
assert(pin:GetFrameLevel() > c:GetFrameLevel() + 1000, "the controls above the pins")
mf:Click()
assert(stub.menu.tag == "MENU_WORLD_MAP_TRACKING" and stub.menu.owner == mf, "the map's filter menu with the log shut")
stub.menu.items[3].set()
assert(stub.cvars.showQuestLevel == "0" and mf.psActive and mf.psTip == "Filter (1 on)", "lit off its default")
stub.menu.items[3].set()
assert(not mf.psActive, "back to its default")
stub.cvars.questPOI = "0"
stub.fire("CVAR_UPDATE", "questPOI")
assert(mf.psActive, "a change from the stock menu lights it")
stub.cvars.questPOI = "1"
stub.fire("CVAR_UPDATE", "questPOI")
assert(select(2, pin:GetPoint(1)) == c and pin:IsEnabled() and not pin.psPinning, "the map pin, off")
pin:Click()
assert(pin.psPinning and pin.psActive and c.events[#c.events][1] == "WaypointLocationToggleUpdate" and c.events[#c.events][2] == true, "pinning")
stub.fire("USER_WAYPOINT_UPDATED")
assert(not pin.psPinning and c.events[#c.events][2] == false, "a waypoint set ends the pinning")
pin:Click()
c:SetMapID(947)
assert(not pin.psPinning and not pin:IsEnabled() and pin.psTipLines[1][1]:find("can't", 1, true), "no pin on Azeroth")
c:SetMapID(37)
row("Eastern Kingdoms").click()
stub.pressKey("M")
assert(not f:IsShown() and not c:IsShown(), "no toggle")
stub.pressKey("M")
assert(c.mapID == 37, "reopened elsewhere")
c:OnFrameSizeChanged()
assert(#c.ScrollContainer.zoomLevels == 4, "no zoom steps added")
local w, h = f:GetWidth(), f:GetHeight()
f.psFullButton:Click()
assert(f.psFull and PolestarUIDB.mapFull and f:GetNumPoints() == 2 and select(2, f:GetPoint(1)) == UIParent, "full screen")
f.psFullButton:Click()
assert(not f.psFull and f:GetWidth() == w and f:GetHeight() == h, "back to a window")
row("Eastern Kingdoms").click()
