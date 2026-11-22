--@ title: World Map: HereBeDragons icons
--@ roots: PolestarUIWorldMap
--@ stubs: stub_worldmap.lua, stub_hbd.lua
-- An addon's world map icons put there through the HereBeDragons-Pins library (LibStub) are mirrored on our canvas: a frame of ours per icon of the shown map, at its spot, size and scale, at the level the library asks of the map, with a copy of the textures the icon shows (file or atlas, colour, place) and none it hides; the library's show flag decides the continent and Azeroth; an icon added or removed while the map is open follows at once through post-hooks (no timer); a newer copy of the library loaded later is hooked again as the map next changes; ours take no mouse (no tooltip or click yet); nothing of the addon's is written (the stub errors) and the stock map never opens.
stub.pressKey("M")
local c = PolestarUIWorldMapCanvas
local holder = PolestarUIHereBeDragonsPins
assert(holder and holder:GetParent() == c:GetCanvas() and not WorldMapFrame:IsShown(), "no mirror on our canvas")
assert(not PolestarUIQuestiePins, "Questie's mirror without Questie")
local function at(r) local _, rel, point, x, y = r:GetPoint(1) return rel == c:GetCanvas() and point == "TOPLEFT" and math.floor(x + 0.5) .. "," .. math.floor(y + 0.5) end
local function shown()
	local t, by = {}, {}
	for _, r in ipairs({ holder:GetChildren() }) do
		if r:IsShown() then
			t[#t + 1] = tostring(at(r))
			by[t[#t]] = r
		end
	end
	table.sort(t)
	return table.concat(t, " "), by
end
local function expect(want, why) local got = shown() assert(got == want, why .. ": " .. got) end
local function near(a, b) return math.abs(a - b) < 0.01 end
expect("251,-334 501,-167", "Elwynn's two icons, not Westfall's")
-- One of ours: the icon's size at its scale, as a stock pin holds it on screen; no mouse.
local _, by = shown()
local f = by["251,-334"]
local s = 1.5 / 0.9
assert(near(f:GetWidth(), 12 * s) and near(f:GetHeight(), 12 * s) and not f:IsMouseEnabled(), "size: " .. f:GetWidth())
-- Its art: the two textures the icon shows, not the hidden highlight; the file with its colour, filling ours; the atlas badge at its size and place on the icon.
local art = {}
for _, r in ipairs({ f:GetRegions() }) do if r:IsShown() then art[#art + 1] = r end end
assert(#art == 2, "textures copied: " .. #art)
local note, badge = art[1], art[2]
assert(note:GetTexture():find("note", 1, true) and near(select(2, note:GetVertexColor()), 0.5) and note:GetNumPoints() == 2 and select(2, note:GetPoint(1)) == f, "the icon's texture")
local point, rel, relPoint, x, y = badge:GetPoint(1)
assert(badge:GetAtlas() == "worldquest-icon-pvp-ffa" and near(badge:GetWidth(), 6 * s) and rel == f and point == "CENTER" and relPoint == "TOPRIGHT"
	and near(x, -1 * s) and near(y, -2 * s) and select(2, badge:GetDrawLayer()) == 2, "the badge")
-- The level the library asks of the map: area POIs unless the addon named another.
local levels = c:GetPinFrameLevelsManager()
assert(f:GetFrameLevel() == levels:GetValidFrameLevel("PIN_FRAME_LEVEL_AREA_POI") and by["501,-167"]:GetFrameLevel() == levels:GetValidFrameLevel("PIN_FRAME_LEVEL_VIGNETTE"), "frame levels")
-- Zoomed in: the same spot, held on screen.
stub.mapScale, stub.mapZoom = 2.7, 1
c:OnCanvasScaleChanged()
_, by = shown()
assert(by["251,-334"] and near(by["251,-334"]:GetWidth(), 12 * 1.5 * 1.2 / 2.7), "zoom")
stub.mapScale, stub.mapZoom = nil, nil
-- The library's show flag: the continent takes the icons flagged for it (2, 3), Azeroth the world ones (3), a zone only its own.
c:SetMapID(13)
expect("351,-401 626,-376", "the continent's icons")
c:SetMapID(947)
expect("564,-355", "Azeroth's icon")
c:SetMapID(52)
expect("401,-267", "Westfall's icon")
c:SetMapID(37)
expect("251,-334 501,-167", "back in Elwynn")
-- Added and removed while the map is open: at once, that icon alone.
_, by = shown()
local kept = by["501,-167"]
local new = stub.hbdIcon(37, 0.9, 0.9)
expect("251,-334 501,-167 902,-601", "the new icon")
_, by = shown()
assert(by["501,-167"] == kept, "another icon's frame was redrawn")
stub.hbdRemove(new)
expect("251,-334 501,-167", "removed")
assert(not holder:GetScript("OnUpdate"), "a polling OnUpdate")
-- A newer copy of the library loaded later (an addon loaded on demand) writes its functions afresh: hooked again as the map next changes, and live after.
stub.hbdUpgrade()
local late = stub.hbdIcon(37, 0.1, 0.1)
expect("251,-334 501,-167", "an icon added through the new copy, before the map changes")
c:OnCanvasScaleChanged()
expect("100,-67 251,-334 501,-167", "hooked again")
stub.hbdRemove(late)
expect("251,-334 501,-167", "live again")
-- Closed, changes are not drawn; reopened on the same map, they are there. An addon taking all its icons off empties ours.
PolestarUIWorldMap:Hide()
stub.hbdIcon(37, 0.2, 0.2)
stub.pressKey("M")
expect("200,-134 251,-334 501,-167", "reopened")
stub.hbdRemoveAll()
expect("", "all removed")
