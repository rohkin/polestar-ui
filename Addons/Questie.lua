-- Questie's world map icons on our World Map (docs/addons.md). Questie draws
-- on WorldMapFrame alone: each icon is one frame its HereBeDragons-Pins copy
-- (a QuestieLoader module, not the LibStub library) parents to a pin there.
-- Ours mirrors them: a frame of our own per icon of the shown map (its art,
-- glow and overlay, at its frame level), under a frame of ours on our canvas, read from that copy's registry and kept up by
-- post-hooks on what changes it (no timer, no rescan). Hovered, ours shows
-- Questie's own tooltip in a tooltip frame of ours (never GameTooltip: rule
-- 15), as Questie's gamepad hover does; clicked, it opens the icon's zone on
-- our map, or with a modifier runs the icon's own click. Nothing of Questie's
-- is moved, shown or hidden, the stock map is not touched, and no pin is
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
local view, id, kind, child, w, h, k, mapScale, cluster, stale
-- Questie's tooltip and hover reset, when it has them (else icons without hover).
local okTip, tipMod = pcall(loader.ImportModule, loader, "MapIconTooltip")
local okFrame, frameMod = pcall(loader.ImportModule, loader, "QuestieFrame")
local canTip = okTip and okFrame and type(tipMod) == "table" and type(tipMod.ShowOnTooltip) == "function"
	and type(frameMod) == "table" and type(frameMod.ResetHoverHighlights) == "function"
local tip, hovered -- our tooltip; the frame of ours under the mouse

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

-- The hover ended: our tooltip hidden, and Questie's highlights (the hovered
-- quest's tinted icons, its path) given back, by the data hovered: the icon
-- may be another quest's by now (as GamepadMapHover's Leave).
local function leave()
	local f = hovered
	if not f then return end
	hovered = nil
	if tip then tip:Hide() end
	pcall(frameMod.ResetHoverHighlights, { data = f.psData })
	f.psData = nil
end

-- Questie's tooltip for the icon under the mouse, in our tooltip: the icon
-- and the drawn ones round it (its rule: the same zone, within 1, 4 on a
-- continent or 6 on the world map, in zone coordinates; ours for the shown
-- map, where Questie reads the stock map's), listed whatever the stock map shows.
local function enter(f)
	leave()
	local icon = f.psIcon
	if not (canTip and icon and type(icon.data) == "table" and icon.texture) then return end
	if select(4, icon.texture:GetVertexColor()) == 0 then return end -- faded out: nothing, as Questie
	if not tip then
		tip = CreateFrame("GameTooltip", "PolestarUIQuestieTooltip", UIParent, "GameTooltipTemplate")
		local tips = ns.modules.tooltips
		if tips and tips.Add then tips.Add(tip) end
	end
	local list = { icon }
	if icon.x and icon.y then
		for other in pairs(drawn) do
			if other ~= icon and other.x and other.y and other.AreaID == icon.AreaID and type(other.data) == "table"
				and math.max(math.abs(other.x - icon.x), math.abs(other.y - icon.y)) < cluster
				and select(4, other.texture:GetVertexColor()) ~= 0 then
				list[#list + 1] = other
			end
		end
	end
	hovered, f.psData = f, icon.data
	tip:Hide() -- Questie skips a call within 0.05 s of the last while the tooltip shows
	if not pcall(tipMod.ShowOnTooltip, icon, tip, f, list) then leave() end
end

-- Shift pressed or let go over an icon: Questie's tooltip drawn again (its
-- long form), as its own handler does for the stock map's (EventHandler.lua).
if canTip then
	Polestar.RegisterEvent("MODIFIER_STATE_CHANGED", function(_, key)
		if not (hovered and tip and tip:IsShown() and tip._Rebuild and (key == "LSHIFT" or key == "RSHIFT")) then return end
		pcall(function()
			tip:Hide()
			tip:ClearLines()
			tip:SetOwner(hovered, "ANCHOR_CURSOR")
			tip:_Rebuild()
			tip:SetFrameStrata("TOOLTIP")
			tip:Show()
		end)
	end)
end

-- A click on an icon, as on the stock map: a plain left click opens the
-- icon's own map when another is shown (ours, where Questie opens the stock
-- map); with a modifier, the icon's own click (a chat link, hide the quest,
-- TomTom), which with a modifier down never reads the stock map; a
-- right-click goes out a map, as on the map under it (plain code: making a
-- frame pass clicks through is blocked in combat, rule 4).
local function click(f, button)
	local icon = f.psIcon
	if not (icon and view) then return end
	if button == "RightButton" then
		view:NavigateToParentMap()
	elseif button == "LeftButton" then
		if IsModifierKeyDown() then
			local handler = icon:GetScript("OnClick")
			if handler then pcall(handler, icon, button) end
		elseif icon.UiMapID and icon.UiMapID ~= id and hbd.mapData[icon.UiMapID] then
			view:SetMapID(icon.UiMapID)
		end
	end
end

local function release(icon)
	local f = drawn[icon]
	if not f then return end
	if hovered == f then leave() end
	f.psIcon = nil
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
	f:EnableMouse(true)
	f:SetScript("OnEnter", enter)
	f:SetScript("OnLeave", leave)
	f:SetScript("OnMouseUp", click)
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
local function update(icon)
	if not (holder and holder:IsVisible()) then stale = true return end
	local d = pins.worldmapPins[icon]
	-- `hidden`: Questie's own hide (a filter, a hidden quest); HBD hides every icon off the stock map's zone.
	local tex = d and not icon.hidden and icon.texture
	local x, y
	if tex then x, y = spot(icon, d) end
	if not (x and y) then return release(icon) end
	local f = drawn[icon] or table.remove(free) or make()
	drawn[icon], f.psIcon = f, icon
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
		holder:SetScript("OnHide", leave)
	end
	local was = id
	view, id, w, h = canvas, canvas:GetMapID(), child:GetWidth(), child:GetHeight()
	kind = hbd.mapData[id] and hbd.mapData[id].mapType
	-- The size a stock pin keeps on screen (HBD's SetScalingLimits(1, 1.0, 1.2), MapCanvasPinMixin:ApplyCurrentScale).
	k = (1 + 0.2 * canvas:GetCanvasZoomPercent()) * canvas:GetGlobalPinScale() / canvas:GetCanvasScale()
	local info = C_Map.GetMapInfo(id)
	local mapType = info and info.mapType
	mapScale = (mapType == 0 or mapType == 1) and 0.85 or mapType == CONTINENT and 0.9 or 1
	cluster = (mapType == 0 or mapType == 1) and 6 or mapType == CONTINENT and 4 or 1 -- MapIconTooltip's maxDistCluster
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

-- Questie's patrol paths (its waypoint lines), which it draws on the stock
-- map's canvas alone (WaypointMap.lua). Ours draws the shown map's with
-- Questie's own renderer (WaypointRenderer.New on our canvas: its frames, its
-- look and settings), by WaypointMap's rules: a path on its own map only, at
-- its icon's visibility and fade, each route once (its highlighted copy, else
-- the most visible). Questie says a path, its visibility or its highlight
-- changed by calling WaypointMap.Invalidate, post-hooked here: one redraw on
-- the next frame however many changed at once (Questie's own waits for its
-- next frame too), none while our map is closed. A route whose line is drawn
-- keeps it; only its style is set again.
-- shortcut: a hovered path shows no tooltip (Questie finds the path under the
-- cursor by reading the cursor every frame); ask before adding that.
local okWays, ways = pcall(loader.ImportModule, loader, "QuestieWaypoints")
local okRend, rendMod = pcall(loader.ImportModule, loader, "WaypointRenderer")
local okWayMap, wayMap = pcall(loader.ImportModule, loader, "WaypointMap")
if not (okWays and okRend and okWayMap and type(ways) == "table" and type(ways.paths) == "table"
	and type(ways.WorldMapAlpha) == "function" and type(ways.IsHighlighted) == "function" and type(ways.Color) == "function"
	and type(rendMod) == "table" and type(rendMod.New) == "function"
	and type(wayMap) == "table" and type(wayMap.Invalidate) == "function") then return end

local renderer, lineCanvas, queued, linesDead
local lines = {} -- route -> { view, map, w, h }: its drawn line, and what it was drawn for

local function drawLines()
	local canvas = lineCanvas
	if not (canvas and canvas:IsVisible()) then return end
	local area = canvas:GetCanvas()
	renderer = renderer or rendMod.New(area)
	local mapID, lw, lh, scale = canvas:GetMapID(), area:GetWidth(), area:GetHeight(), canvas:GetCanvasScale()
	local profile = Questie.db.profile
	local routes = {}
	if lw > 0 and lh > 0 then
		for path in pairs(ways.paths) do
			local alpha = path.uiMapId == mapID and ways.WorldMapAlpha(path)
			if alpha then
				local rank = alpha + (ways.IsHighlighted(path) and 2 or 0)
				local best = routes[path.route]
				if not best or rank > best.rank then routes[path.route] = { path = path, alpha = alpha, rank = rank } end
			end
		end
	end
	for route, shown in pairs(routes) do
		-- The width holds its size on screen; under Questie's icons (2016 up).
		local style = { thickness = profile.waypointWidth / scale, color = ways.Color(shown.path), alpha = shown.alpha, frameLevel = 2015 }
		local e = lines[route]
		if not e or e.map ~= mapID or e.w ~= lw or e.h ~= lh then
			local points = {}
			for i, point in ipairs(shown.path.points) do points[i] = { x = point.x * lw / 100, y = point.y * lh / 100 } end
			e = { view = renderer:Draw(e and e.view, { points }, style), map = mapID, w = lw, h = lh }
			lines[route] = e
		else
			renderer:Restyle(e.view, style)
		end
		e.view:Show()
	end
	for route, e in pairs(lines) do
		if not routes[route] then
			renderer:Release(e.view)
			lines[route] = nil
		end
	end
end

-- A failure takes the lines off our map for the session, as the icons.
local function runLines()
	queued = false
	if linesDead or pcall(drawLines) then return end
	linesDead = true
	if renderer then pcall(renderer.Clear, renderer) end
end

hooksecurefunc(wayMap, "Invalidate", function()
	if linesDead or queued or not (lineCanvas and lineCanvas:IsVisible()) then return end
	queued = true
	C_Timer.After(0, runLines)
end)

-- The shown map, its size or its zoom changed, or ours opened (whatever Questie changed while it was closed).
map.overlays[#map.overlays + 1] = function(canvas)
	lineCanvas = canvas
	runLines()
end
end)
