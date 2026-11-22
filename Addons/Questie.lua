-- Questie's world map icons on our World Map (docs/addons.md). Questie draws
-- on WorldMapFrame alone: each icon is one frame its HereBeDragons-Pins copy
-- (a QuestieLoader module, not the LibStub library) parents to a pin there.
-- Ours mirrors them: a frame of our own per icon of the shown map (its art,
-- glow and overlay, at its frame level), under a frame of ours on our canvas, read from that copy's registry and kept up by
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
local drawn, free = {}, {} -- icon -> its frame of ours; frames to reuse
-- The registry by continent, so a map change walks its own continent's icons
-- only (Questie shows an icon on every map its spot lies on, a neighbour
-- zone's too): icon -> root, root -> its icons. Root: the continent at or
-- above the icon's map, else the map itself; 0 for an icon with no map.
local roots, sets = {}, {}
local hooked = setmetatable({}, { __mode = "k" })
-- The shown map; `stale`: Questie changed something while ours was closed.
local view, id, kind, child, w, h, k, mapScale, stale

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
	local f = drawn[icon]
	if not f then return end
	f:Hide()
	free[#free + 1] = f
	drawn[icon] = nil
end

-- A frame of ours for one icon: Questie's three textures in its order (glow
-- behind, overlay in front), levelled among the others as Questie levels its icons.
local function make()
	local f = CreateFrame("Frame", nil, holder)
	f.glow = f:CreateTexture(nil, "OVERLAY", nil, -1)
	f.glow:SetPoint("CENTER")
	f.tex = f:CreateTexture(nil, "OVERLAY", nil, 0)
	f.tex:SetAllPoints(f)
	f.over = f:CreateTexture(nil, "OVERLAY", nil, 1)
	f.over:SetAllPoints(f)
	return f
end

-- The icon's size on our map, as Questie works it out for the stock map's
-- (QuestieMap.ProcessQueue, GetScaleValue: smaller on a continent and the
-- world); the icon's own size holds the stock map's kind of map, not ours.
local function sizeOf(icon, data, profile)
	local scale = data and data.IconScale
	if not (profile and type(scale) == "number") then return icon:GetWidth(), icon:GetHeight() end
	local size = 16 * scale * ((icon.isManualIcon and profile.globalTownsfolkScale or profile.globalScale) or 0.7) * mapScale
	return size, size
end

-- One icon drawn, moved, repainted or taken off, as it now is.
-- shortcut: no tooltip or click yet; each a next piece.
local function update(icon)
	if not (holder and holder:IsVisible()) then stale = true return end
	local d = pins.worldmapPins[icon]
	-- `hidden`: Questie's own hide (a filter, a hidden quest); HBD hides every icon off the stock map's zone.
	local tex = d and not icon.hidden and icon.texture
	local x, y
	if tex then x, y = spot(icon, d) end
	if not (x and y) then return release(icon) end
	local f = drawn[icon] or table.remove(free) or make()
	drawn[icon] = f
	local profile = type(Questie) == "table" and Questie.db and Questie.db.profile
	local data = type(icon.data) == "table" and icon.data
	local sw, sh = sizeOf(icon, data, profile)
	f:SetSize(sw * k, sh * k)
	f:SetFrameLevel(math.max(icon:GetFrameLevel(), 2016)) -- never under the map, whatever the icon holds
	f:SetAlpha(icon:GetAlpha()) -- a party member's objective is dimmed
	f:ClearAllPoints()
	f:SetPoint("CENTER", child, "TOPLEFT", x * w, -y * h)
	local r, g, b, a = tex:GetVertexColor()
	f.tex:SetTexture(tex:GetTexture())
	f.tex:SetVertexColor(r, g, b, a)
	-- The overlay (a quest started by an item or an object): its own shown flag, whatever the icon's.
	local over = icon.overlayTexture
	local on = over and over:IsShown() and over:GetTexture()
	f.over:SetTexture(on or nil)
	f.over:SetShown(on and true or false)
	-- The objective glow: Questie shows it as the icon shows on the stock map
	-- (BaseOnShow), so its rule is read here, not the glow texture's state.
	local color = data and data.ObjectiveData and data.ObjectiveData.Color
	local glow = profile and profile.alwaysGlowMap and color and data.Type ~= "available" and data.Type ~= "complete" and icon.glowTexture
	if glow then
		f.glow:SetTexture(glow:GetTexture())
		f.glow:SetVertexColor(color[1], color[2], color[3], a or 1)
		f.glow:SetSize(sw * k * 1.13, sh * k * 1.13)
	end
	f.glow:SetShown(glow and true or false)
	f:Show()
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
-- added, and again as a scale setting changes), SetFrameLevel (its draw
-- order, set after that), its texture's art and colour (a fade, a new state).
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
	for _, m in ipairs({ "FakeHide", "FakeShow", "SetSize", "SetFrameLevel" }) do
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
-- The glow setting: Questie walks its icons with no call an icon of ours
-- could follow; the drawn ones are painted again after it.
local okPool, framePool = pcall(loader.ImportModule, loader, "QuestieFramePool")
if okPool and type(framePool) == "table" and type(framePool.UpdateGlowConfig) == "function" then
	hooksecurefunc(framePool, "UpdateGlowConfig", function() for icon in pairs(drawn) do safe(icon) end end)
end

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
	local info = C_Map.GetMapInfo(id)
	local mapType = info and info.mapType
	mapScale = (mapType == 0 or mapType == 1) and 0.85 or mapType == CONTINENT and 0.9 or 1
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
