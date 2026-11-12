--@ title: World Map
--@ roots: PolestarUIWorldMap
--@ stubs: stub_worldmap.lua
-- The map key opens ours, never the stock map, on the player's zone; the sidebar walks up to a continent, whose zones it lists (a zone's caves apart, as the stock dropdown lists them), and the canvas sits in the window's strata; a map art of one zoom step gets ours, and the window goes full screen and back.
stub.pressKey("M")
local f = PolestarUIWorldMap
local c = PolestarUIWorldMapCanvas
assert(f:IsShown() and not WorldMapFrame:IsShown(), "key")
assert(c:IsShown() and c:GetFrameStrata() == f:GetFrameStrata(), "canvas under the window")
assert(c.mapID == 37 and c.zoomedOut and f.Title:GetText() == "Elwynn Forest", "not the player map")
assert(#c.providers > 0 and c.navigateOnClick, "canvas setup")
local function row(n) for _, b in ipairs(f.navButtons) do if b:IsShown() and b.Label:GetText() == n then return b end end end
assert(row("Azeroth") and row("Where you are"), "parents")
row("Eastern Kingdoms"):Click()
assert(c.mapID == 13 and f.Title:GetText() == "Eastern Kingdoms", "nav")
assert(row("Duskwood") and row("Westfall") and row("Elwynn Forest") and not row("Kalimdor"), "zones")
stub.caveListed = true
row("Elwynn Forest"):Click()
assert(row("Fargodeep Mine").Icon:GetTexture() == Polestar.Theme.Media("icon-dungeon") and not row("Fargodeep Mine, Lower"), "a cave as the stock dropdown lists it, its floors once")
assert(not row("Upper Level"), "floors on an ungrouped map")
row("Fargodeep Mine"):Click()
assert(c.mapID == 1429, "cave row")
c:SetMapID(1429)
assert(row("Upper Level").Selected:IsShown() and not row("Lower Level").Selected:IsShown(), "active floor")
row("Lower Level"):Click()
assert(c.mapID == 1430, "floor click")
c:SetMapID(52)
assert(not row("The Deadmines"), "a dungeon the dropdown does not list")
assert(not WorldMapFrame:IsShown(), "stock map")
c:SetMapID(37)
row("Eastern Kingdoms"):Click()
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
row("Eastern Kingdoms"):Click()
