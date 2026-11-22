-- Questie's world map icons on our World Map (docs/addons.md). Questie draws
-- on WorldMapFrame alone: each icon is one frame its HereBeDragons-Pins copy
-- (a QuestieLoader module, not the LibStub library) parents to a pin there.
-- Ours mirrors them: a texture of our own per icon of the shown map, on a
-- frame of ours on our canvas, read from that copy's registry and kept up by
-- post-hooks on what changes it (no timer, no rescan). Nothing of Questie's is
-- moved, shown or hidden, the stock map is not touched, and no pin is
-- acquired (docs/CLIENT.md, rules 4, 14). A no-op without Questie.

local ADDON, ns = ...

ns.AfterLogin(function()
local map, loader = ns.modules.map, QuestieLoader
if not (map and map.overlays and type(loader) == "table" and loader.ImportModule) then return end
local ok, pins, hbd = pcall(function() return loader:ImportModule("HBDPins"), loader:ImportModule("HBD") end)
if not (ok and type(pins) == "table" and type(pins.worldmapPins) == "table"
	and type(pins.AddWorldMapIconMap) == "function" and type(pins.RemoveWorldMapIcon) == "function"
	and type(hbd) == "table" and hbd.GetZoneCoordinatesFromWorldInstance and hbd.GetAzerothWorldMapCoordinatesFromWorld
	and type(hbd.mapData) == "table") then return end

local WORLD = 947 -- Azeroth
local CONTINENT, ZONE, DUNGEON, MICRO = 2, 3, 4, 5 -- Enum.UIMapType
local holder, dead
local drawn, free = {}, {} -- icon -> its texture of ours; textures to reuse
-- The registry by continent, so a map change walks its own continent's icons
-- only (Questie shows an icon on every map its spot lies on, a neighbour
-- zone's too): icon -> root, root -> its icons. Root: the continent at or
-- above the icon's map, else the map itself; 0 for an icon with no map.
local roots, sets = {}, {}
local hooked = setmetatable({}, { __mode = "k" })
-- The shown map; `stale`: Questie changed something while ours was closed.
local view, id, kind, child, w, h, k, stale

local function rootOf(mapID)
	if not mapID then return 0 end
	local m, data = mapID, hbd.mapData[mapID]
	while data do
		if data.mapType == CONTINENT then return m end
		m = data.parent
		data = m and hbd.mapData[m]
	end
	return mapID
end

-- Where an icon goes on the shown map (0..1), nil when it is not shown
-- there: the rules of Questie's worldmapProvider:HandlePin (HBD's
-- worldMapShowFlag: -1 its own map only, 3 the world map too; its "hide icons
-- on continents" hides them all there; a map HBD does not know has none).
local function spot(icon, d)
	local profile = type(Questie) == "table" and Questie.db and Questie.db.profile
	if profile and profile.hideIconsOnContinents == true and (kind == CONTINENT or id == WORLD) then return end
	local flag = d.worldMapShowFlag or 0
	if id ~= d.uiMapID then
		if flag == -1 or (id == WORLD and flag ~= 3) then return end
		if id ~= WORLD and not d.uiMapID and not (kind == CONTINENT and flag >= 2)
			and kind ~= ZONE and kind ~= DUNGEON and kind ~= MICRO then return end
	end
	if id ~= WORLD then
		if not hbd.mapData[id] then return end
		return hbd:GetZoneCoordinatesFromWorldInstance(d.x, d.y, d.instanceID, id)
	end
	if icon.UiMapID == WORLD then return icon.x / 100, icon.y / 100 end
	return hbd:GetAzerothWorldMapCoordinatesFromWorld(d.x, d.y, d.instanceID)
end

local function release(icon)
	local t = drawn[icon]
	if not t then return end
	t:Hide()
	free[#free + 1] = t
	drawn[icon] = nil
end

-- One icon drawn, moved, repainted or taken off, as it now is.
-- shortcut: no glow, tooltip or click, and an icon keeps the size Questie gave
-- it for the stock map's kind of map (up to 15% off on ours); each a next piece.
local function update(icon)
	if not (holder and holder:IsVisible()) then stale = true return end
	local d = pins.worldmapPins[icon]
	-- `hidden`: Questie's own hide (a filter, a hidden quest); HBD hides every icon off the stock map's zone.
	local tex = d and not icon.hidden and icon.texture
	local x, y
	if tex then x, y = spot(icon, d) end
	if not (x and y) then return release(icon) end
	local t = drawn[icon] or table.remove(free) or holder:CreateTexture(nil, "OVERLAY")
	drawn[icon] = t
	t:SetTexture(tex:GetTexture())
	t:SetVertexColor(tex:GetVertexColor())
	t:SetSize(icon:GetWidth() * k, icon:GetHeight() * k)
	t:ClearAllPoints()
	t:SetPoint("CENTER", child, "TOPLEFT", x * w, -y * h)
	t:Show()
end

-- Questie's tables are private and may change: a failure takes the icons off
-- our map for the session, and never breaks the map or Questie's own call.
local function safe(icon)
	if dead or pcall(update, icon) then return end
	dead = true
	if holder then holder:Hide() end
end
local function tinted(tex) safe(tex:GetParent()) end

-- An icon put on, moved in or taken out of the registry: indexed, and its own
-- changes followed. Questie changes an icon through these and tells no one:
-- FakeHide/FakeShow (filters), SetSize (its scale, set after the icon is
-- added), its texture's art and colour (a fade, a new state).
local function index(icon)
	local d = pins.worldmapPins[icon]
	local root, old = d and rootOf(d.uiMapID), roots[icon]
	if old ~= root then
		if old then sets[old][icon] = nil end
		if root then
			sets[root] = sets[root] or {}
			sets[root][icon] = true
		end
		roots[icon] = root
	end
	if not d or hooked[icon] then return end
	hooked[icon] = true
	for _, m in ipairs({ "FakeHide", "FakeShow", "SetSize" }) do
		if type(icon[m]) == "function" then hooksecurefunc(icon, m, safe) end
	end
	local tex = icon.texture
	if type(tex) == "table" and tex.SetTexture and tex.SetVertexColor then
		hooksecurefunc(tex, "SetTexture", tinted)
		hooksecurefunc(tex, "SetVertexColor", tinted)
	end
end
local function changed(_, _, icon)
	if dead or not icon then return end
	if not pcall(index, icon) then dead = true return end
	safe(icon)
end
hooksecurefunc(pins, "AddWorldMapIconMap", changed)
hooksecurefunc(pins, "RemoveWorldMapIcon", changed)
if type(pins.AddWorldMapIconWorld) == "function" then hooksecurefunc(pins, "AddWorldMapIconWorld", changed) end
if type(pins.RemoveAllWorldMapIcons) == "function" then
	hooksecurefunc(pins, "RemoveAllWorldMapIcons", function()
		for icon in pairs(roots) do changed(nil, nil, icon) end
	end)
end
for icon in pairs(pins.worldmapPins) do changed(nil, nil, icon) end

-- The shown map, its size or its zoom changed (or ours opened): another map
-- draws its continent's icons afresh, the same map lays the drawn ones out again.
local function paint(canvas)
	child = canvas:GetCanvas()
	if not holder then
		holder = CreateFrame("Frame", "PolestarUIQuestiePins", child)
		holder:SetAllPoints(child)
		holder:SetFrameLevel(2016) -- where Questie puts its icons (QuestieMap.utils.SetDrawOrder)
	end
	local was = id
	view, id, w, h = canvas, canvas:GetMapID(), child:GetWidth(), child:GetHeight()
	kind = hbd.mapData[id] and hbd.mapData[id].mapType
	-- The size a stock pin keeps on screen (HBD's SetScalingLimits(1, 1.0, 1.2), MapCanvasPinMixin:ApplyCurrentScale).
	k = (1 + 0.2 * canvas:GetCanvasZoomPercent()) * canvas:GetGlobalPinScale() / canvas:GetCanvasScale()
	if id == was and not stale then
		for icon in pairs(drawn) do update(icon) end
		return
	end
	stale = false
	for icon in pairs(drawn) do release(icon) end
	if id == WORLD then
		for icon in pairs(pins.worldmapPins) do update(icon) end
		return
	end
	for icon in pairs(sets[rootOf(id)] or {}) do update(icon) end
	for icon in pairs(sets[0] or {}) do update(icon) end
end

map.overlays[#map.overlays + 1] = function(canvas)
	if dead or pcall(paint, canvas) then return end
	dead = true
	if holder then holder:Hide() end
end
end)
