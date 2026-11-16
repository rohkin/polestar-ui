-- World Map (docs/DESIGN.md, "World Map"): the game's own map canvas
-- (MapCanvasMixin with the stock world map's data providers, as the zone map
-- BattlefieldMapFrame builds it) in a compact Polestar shell: the side
-- column's pages (quest log, map legend) as top tabs, the map's nav after
-- them, no sidebar. The stock WorldMapFrame is never touched: its hide
-- runs UpdateMicroButtons (docs/CLIENT.md, rule 8), and map addons draw on it,
-- so it stays theirs and the game's, for every door we do not take.

local ADDON, ns = ...
local W = Polestar.Widgets

local NAME = "PolestarUIWorldMap"
-- The canvas keeps the shape of the map art (1002x668).
local MAP_W, MAP_H = 900, 600
local CONTINENT, ZONE, DUNGEON, MICRO = 2, 3, 4, 5 -- Enum.UIMapType
local ZOOMS = { 1.5, 2.25, 3 }
local QUEST_W = 320
local f, canvas
local M = {}

-- The stock world map's providers (WorldMapMixin:AddStandardDataProviders),
-- by name so one this game lacks is skipped; less the stock map's own (its
-- event overlay and world quests, Blizzard_WorldMap's) and debug's.
local PROVIDERS = {
	"MapExplorationDataProviderMixin", "MapHighlightDataProviderMixin", "QuestOfferDataProviderMixin",
	"BattlefieldFlagDataProviderMixin", "BonusObjectiveDataProviderMixin", "VehicleDataProviderMixin",
	"FogOfWarDataProviderMixin", "DeathMapDataProviderMixin", "QuestBlobDataProviderMixin", "ScenarioDataProviderMixin",
	"VignetteDataProviderMixin", "QuestDataProviderMixin", "ContentTrackingDataProviderMixin", "InvasionDataProviderMixin",
	"GossipDataProviderMixin", "FlightPointDataProviderMixin", "PetTamerDataProviderMixin", "DigSiteDataProviderMixin",
	"GarrisonPlotDataProviderMixin", "DungeonEntranceDataProviderMixin", "DelveEntranceDataProviderMixin",
	"BannerDataProvider", "ContributionCollectorDataProviderMixin", "MapLinkDataProviderMixin",
	"SelectableGraveyardDataProviderMixin", "AreaPOIDataProviderMixin", "AreaPOIEventDataProviderMixin",
	"QuestSessionDataProviderMixin", "WaypointLocationDataProviderMixin", "DragonridingRaceDataProviderMixin",
	"SuperTrackWaypointDataProviderMixin", "NeighborhoodMapDataProviderMixin", "EncounterJournalDataProviderMixin",
	"GroupMembersDataProviderMixin",
}

-- The stock map's pin layers, bottom up, with how many levels each takes.
local function pinLevels()
	local QO = QuestOfferDataProviderMixin and QuestOfferDataProviderMixin.PIN_LEVEL_RANGE
	return {
		{ "PIN_FRAME_LEVEL_WOW_LABS_AREA" }, { "PIN_FRAME_LEVEL_MAP_EXPLORATION" }, { "PIN_FRAME_LEVEL_PLUNDERSTORM_CIRCLE" },
		{ "PIN_FRAME_LEVEL_EVENT_OVERLAY" }, { "PIN_FRAME_LEVEL_GARRISON_PLOT" }, { "PIN_FRAME_LEVEL_FOG_OF_WAR" },
		{ "PIN_FRAME_LEVEL_QUEST_BLOB" }, { "PIN_FRAME_LEVEL_SCENARIO_BLOB" }, { "PIN_FRAME_LEVEL_MAP_HIGHLIGHT" },
		{ "PIN_FRAME_LEVEL_DEBUG", 4 }, { "PIN_FRAME_LEVEL_DIG_SITE" }, { "PIN_FRAME_LEVEL_DUNGEON_ENTRANCE" },
		{ "PIN_FRAME_LEVEL_DELVE_ENTRANCE" }, { "PIN_FRAME_LEVEL_FLIGHT_POINT" }, { "PIN_FRAME_LEVEL_NEIGHBORHOOD_MAP_OBJECTS" },
		{ "PIN_FRAME_LEVEL_INVASION" }, { "PIN_FRAME_LEVEL_PET_TAMER" }, { "PIN_FRAME_LEVEL_SELECTABLE_GRAVEYARD" },
		{ "PIN_FRAME_LEVEL_DRAGONRIDING_RACE" }, { "PIN_FRAME_LEVEL_AREA_POI" }, { "PIN_FRAME_LEVEL_GOSSIP" },
		{ "PIN_FRAME_LEVEL_DEBUG" }, { "PIN_FRAME_LEVEL_MAP_LINK" }, { "PIN_FRAME_LEVEL_ENCOUNTER" },
		{ "PIN_FRAME_LEVEL_CONTRIBUTION_COLLECTOR" }, { "PIN_FRAME_LEVEL_VIGNETTE", 200 }, { "PIN_FRAME_LEVEL_QUEST_OFFER", QO },
		{ "PIN_FRAME_LEVEL_SCENARIO" }, { "PIN_FRAME_LEVEL_BONUS_OBJECTIVE" }, { "PIN_FRAME_LEVEL_WORLD_QUEST", 500 },
		{ "PIN_FRAME_LEVEL_AREA_POI_EVENT" }, { "PIN_FRAME_LEVEL_QUEST_PING" }, { "PIN_FRAME_LEVEL_TRACKED_CONTENT" },
		{ "PIN_FRAME_LEVEL_ACTIVE_QUEST", C_QuestLog.GetMaxNumQuests() }, { "PIN_FRAME_LEVEL_SUPER_TRACKED_CONTENT" },
		{ "PIN_FRAME_LEVEL_SUPER_TRACKED_QUEST" }, { "PIN_FRAME_LEVEL_VEHICLE_BELOW_GROUP_MEMBER" },
		{ "PIN_FRAME_LEVEL_BATTLEFIELD_FLAG" }, { "PIN_FRAME_LEVEL_WAYPOINT_LOCATION" }, { "PIN_FRAME_LEVEL_GROUP_MEMBER" },
		{ "PIN_FRAME_LEVEL_VEHICLE_ABOVE_GROUP_MEMBER" }, { "PIN_FRAME_LEVEL_CORPSE" }, { "PIN_FRAME_LEVEL_AREA_POI_BANNER" },
	}
end

local function buildCanvas()
	canvas = CreateFrame("Frame", NAME .. "Canvas", f.Main, "PolestarUIMapCanvasTemplate")
	-- Polestar draws its map features (nav pins, routes, zone levels) on this canvas too.
	if Polestar and Polestar.MapCanvas and Polestar.MapCanvas.Add then Polestar.MapCanvas.Add(canvas) end
	-- The template's MEDIUM strata would put the map under its own window.
	canvas:SetFrameStrata(f:GetFrameStrata())
	-- Any new size (the window's, the quest log opening): the map refitted.
	canvas:HookScript("OnSizeChanged", function(self) self:OnFrameSizeChanged() end)
	-- As the stock map: a click opens the zone under it, right-click goes out.
	canvas:SetShouldZoomInOnClick(false)
	canvas:SetShouldPanOnClick(false)
	canvas:SetShouldNavigateOnClick(true)
	canvas:SetShouldZoomInstantly(true)
	local levels = canvas:GetPinFrameLevelsManager()
	for _, l in ipairs(pinLevels()) do levels:AddFrameLevel(l[1], l[2]) end
	for _, key in ipairs(PROVIDERS) do
		local mixin = _G[key]
		if mixin then canvas:AddDataProvider(CreateFromMixins(mixin)) end
	end
	if AreaLabelDataProviderMixin then -- the zone name under the cursor, no pins
		local labels = CreateFromMixins(AreaLabelDataProviderMixin)
		labels:SetOffsetY(-10)
		canvas:AddDataProvider(labels)
	end
	-- The zoom steps come from the map art, and Forever's art gives one (no
	-- zoom at all): then ours steps in up to three times the fitted size.
	local sc = canvas.ScrollContainer
	local zoomLevels = sc.CreateZoomLevels
	function sc:CreateZoomLevels()
		zoomLevels(self)
		if #self.zoomLevels ~= 1 then return end
		local base = self.zoomLevels[1]
		for _, k in ipairs(ZOOMS) do self.zoomLevels[#self.zoomLevels + 1] = { scale = base.scale * k, layerIndex = base.layerIndex } end
	end
end

-- The side column (the stock quest panel and its tabs): the quest log or the
-- map legend, or shut (remembered). Its pages are the window's top tabs; a
-- click on the shown page's tab shuts it. The map ends at its left edge, and
-- the window grows by its width unless it fills the screen.
local paintTabs -- below
local function setPanel(page)
	if page == true then page = "quests" end -- saved before the legend
	if page == "legend" and not f.psLegend then page = "quests" end
	PolestarUIDB.mapQuests = page
	f.psPage = page
	f.psQuests:SetShown(page == "quests")
	if f.psLegend then f.psLegend:SetShown(page == "legend") end
	local col = page == "legend" and f.psLegend or f.psQuests
	canvas:ClearAllPoints()
	canvas:SetPoint("TOPLEFT", f.Content, "TOPLEFT", 0, 0)
	canvas:SetPoint("BOTTOMRIGHT", page and col or f.Content, page and "BOTTOMLEFT" or "BOTTOMRIGHT", 0, 0)
	if not f.psFull then f:SetSize(f.psSize[1] + (page and QUEST_W or 0), f.psSize[2]) end
	paintTabs()
end

-- The search is the quest list's: in the filter's dropdown while the list shows.
local function searchable() return f.psPage == "quests" and not f.psQuests.Details:IsShown() end

-- The filter's state (the quest log's), lit too while a search runs.
local function paintFilter()
	f.psQuests.PaintFilter(f.psFilter)
	if not searchable() then return end
	if (f.Search:GetText() or "") ~= "" then W.SetIconState(f.psFilter, true) end
	f.psFilter.psTip = "Search and " .. f.psFilter.psTip:lower()
end

-- The top tabs (the quest log's count on its own, in danger past the most
-- it holds), the filter (the search in its dropdown), and the map's nav
-- after the tabs.
function paintTabs()
	local count, over = f.psQuests.Count()
	local function tab(key, label)
		return { key = key, label = label, count = key == "quests" and count or nil,
			tip = f.psPage == key and "Click again to close it and give the map the room." or nil }
	end
	local items = { tab("quests", QUESTS_LABEL or "Quests") }
	if f.psLegend then items[2] = tab("legend", MAP_LEGEND_FRAME_LABEL or "Map Legend") end
	ns.TopNav(f, items, f.psPage, function(k) setPanel(f.psPage ~= k and k or nil) end)
	W.Color(f.tabButtons[1].psNavCount, over and "danger" or "textMuted")
	if not searchable() and W.MenuShown(f.psFilter) then W.HideMenu() end
	f.psNav:ClearAllPoints()
	f.psNav:SetPoint("LEFT", f.tabButtons[#items], "RIGHT", 12, 0)
	paintFilter()
end

-- Full screen, as the stock map's maximise: the window fills the screen, out
-- of the dock (ns.Dock skips psFull), until toggled back.
local function setFull(on)
	PolestarUIDB.mapFull = on or nil
	f.psFull = on
	f:ClearAllPoints()
	if on then
		f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
		f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
	else
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
		setPanel(f.psPage) -- its size again
	end
	local b = f.psFullButton
	b.psIconName, b.psTip = on and "compact" or "window", on and "Back to a window" or "Full screen"
	b.Icon:SetTexture(Polestar.Theme.Media(Polestar.Theme.Icon(b.psIconName)))
	ns.Relayout()
end

-- The map legend (the stock MapLegendFrame, where the client has its data):
-- each category's pin kinds, two to a row, with the stock tooltip; hovering
-- one lights its pins on our map, matched as the stock button matches them.
local function legend()
	local data, defs = MapLegendData, MapLegendPinDefinitions
	if not (data and defs) then return nil end
	local p = CreateFrame("Frame", nil, f.Main)
	p:SetWidth(QUEST_W)
	p:SetPoint("TOPRIGHT", f.Content, "TOPRIGHT", 0, 0)
	p:SetPoint("BOTTOMRIGHT", f.Content, "BOTTOMRIGHT", 0, 0)
	Polestar.Theme.Skin(p, "sidebar")
	local rule = W.Divider(p, true)
	rule:SetPoint("TOPLEFT", p, "TOPLEFT", 0, 0)
	rule:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 0, 0)
	p.Scroll = W.Scroll(p)
	p.Scroll:SetPoint("TOPLEFT", p, "TOPLEFT", 1, 0)
	p.Scroll:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 0, 0)
	local child, X, ROW = p.Scroll.Child, W.SHELL.side, 28
	child:SetWidth(QUEST_W - 1)
	local colW = math.floor((QUEST_W - 1 - 2 * X) / 2)
	local lit, match = {}, MapLegendButtonMixin and MapLegendButtonMixin.MetaDataMatches
	local function enter(b)
		local def = b.psDef
		GameTooltip:SetOwner(b, "ANCHOR_BOTTOMRIGHT")
		GameTooltip_SetTitle(GameTooltip, def.Name)
		if def.Tooltip then GameTooltip_AddNormalLine(GameTooltip, def.Tooltip) end
		GameTooltip:Show()
		if not canvas.EnumeratePinsByTemplate then return end
		for _, t in ipairs(def.TemplateNames or {}) do
			for pin in canvas:EnumeratePinsByTemplate(t) do
				if pin.ShowMapLegendGlow and (not match or match({ metaData = def.MetaData }, pin)) then
					pin:ShowMapLegendGlow()
					lit[#lit + 1] = pin
				end
			end
		end
	end
	local function leave()
		W.HideTooltip()
		for i = #lit, 1, -1 do
			lit[i]:HideMapLegendGlow()
			lit[i] = nil
		end
	end
	p.Rows = {}
	local y = 16
	for _, cat in ipairs(data) do
		local head = W.Text(child, "label", "textDim")
		head:SetPoint("TOPLEFT", child, "TOPLEFT", X, -y)
		head:SetText(cat.CategoryTitle or "")
		y = y + 24
		local n = 0
		for _, key in ipairs(cat.CategoryData or {}) do
			local def = defs[key]
			if def then
				local b = CreateFrame("Button", nil, child)
				b:SetSize(colW, ROW)
				b:SetPoint("TOPLEFT", child, "TOPLEFT", X + (n % 2) * colW, -(y + math.floor(n / 2) * ROW))
				W.Hover(b)
				if def.BackgroundAtlas then
					b.Back = b:CreateTexture(nil, "BORDER")
					b.Back:SetAtlas(def.BackgroundAtlas)
					b.Back:SetSize(22, 22)
					b.Back:SetPoint("LEFT", b, "LEFT", 3, 0)
				end
				b.Icon = b:CreateTexture(nil, "ARTWORK")
				b.Icon:SetAtlas(def.Atlas)
				b.Icon:SetSize(20, 20)
				b.Icon:SetPoint("LEFT", b, "LEFT", 4, 0)
				b.Label = W.Text(b, "small", "text")
				b.Label:SetPoint("LEFT", b.Icon, "RIGHT", 8, 0)
				b.Label:SetPoint("RIGHT", b, "RIGHT", -4, 0)
				b.Label:SetJustifyH("LEFT")
				b.Label:SetWordWrap(false)
				b.Label:SetText(def.Name or key)
				b.psDef = def
				b:SetScript("OnEnter", enter)
				b:SetScript("OnLeave", leave)
				p.Rows[#p.Rows + 1] = b
				n = n + 1
			end
		end
		y = y + math.ceil(n / 2) * ROW + 16
	end
	p:Hide()
	p:SetScript("OnShow", function(self) W.SetScrollContent(self.Scroll, y, self:GetHeight()) end)
	return p
end

-- Where to go, after the tabs (the old sidebar, as the stock nav bar): where
-- you are, then the shown map's name opening a menu of the maps above it, its
-- zones (continents and zones, by name), its dungeons and caves (as the stock
-- nav bar's dropdown lists them; a map of floors once, by its first) and its
-- floors (in the client's order, the shown one checked).
local function mapMenu(owner)
	local id = canvas:GetMapID()
	local info = id and C_Map.GetMapInfo(id)
	if not info then return end
	local up, p = {}, info.parentMapID
	while p and p > 0 do
		local pi = C_Map.GetMapInfo(p)
		if not pi then break end
		table.insert(up, 1, pi)
		p = pi.parentMapID
	end
	local zones, dungeons, seen = {}, {}, {}
	for _, c in ipairs(C_Map.GetMapChildrenInfo(id, nil, false) or {}) do
		if c.mapType == CONTINENT or c.mapType == ZONE then
			zones[#zones + 1] = c
		elseif (c.mapType == DUNGEON or c.mapType == MICRO) and C_Map.IsMapValidForNavBarDropdown(c.mapID) then
			local g = C_Map.GetMapGroupID(c.mapID)
			local first = g and (C_Map.GetMapGroupMembersInfo(g) or {})[1]
			local key = first and first.mapID or c.mapID
			if not seen[key] then
				seen[key] = true
				dungeons[#dungeons + 1] = C_Map.GetMapInfo(key) or c
			end
		end
	end
	local function byName(a, b) return a.name < b.name end
	table.sort(zones, byName)
	table.sort(dungeons, byName)
	local group = C_Map.GetMapGroupID(id)
	local floors = group and C_Map.GetMapGroupMembersInfo(group) or {}
	local function go(k) canvas:SetMapID(k) end
	MenuUtil.CreateContextMenu(owner, function(_, root)
		if root.SetScrollMode then root:SetScrollMode(480) end
		local any = false
		local function section(list, radio)
			if #list == 0 then return end
			if any then root:CreateDivider() end
			any = true
			for _, m in ipairs(list) do
				if radio then
					root:CreateRadio(m.name, function() return canvas:GetMapID() == m.mapID end, function() go(m.mapID) end)
				else
					root:CreateButton(m.name, function() go(m.mapID) end)
				end
			end
		end
		section(up)
		section(zones)
		section(dungeons)
		section(floors, true)
	end)
end

local function mapNav()
	local nav = CreateFrame("Frame", nil, f.TabRow)
	nav:SetSize(30, 30)
	f.psNav = nav
	local here = W.IconButton(nav, "flag", 30, "Where you are", function() canvas:SetMapID(MapUtil.GetDisplayableMapForPlayer()) end, 14)
	here:SetPoint("LEFT", nav, "LEFT", 0, 0)
	f.psHere = here
	local go = CreateFrame("Button", nil, nav)
	go:SetHeight(30)
	go:SetPoint("LEFT", here, "RIGHT", 4, 0)
	W.Hover(go)
	go.Label = W.Text(go, "label", "text")
	go.Label:SetPoint("LEFT", go, "LEFT", 10, 0)
	go.Arrow = W.Tex(go, "ARTWORK", "chevron-down", "textDim")
	go.Arrow:SetSize(12, 12)
	go.Arrow:SetPoint("RIGHT", go, "RIGHT", -10, 0)
	go:SetScript("OnClick", mapMenu)
	-- How to move around the map lives in its tooltip; the band's line is a fact.
	go:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:SetText(self.Label:GetText() or "", 1, 1, 1)
		ns.TooltipHint("Click for the maps above this one, its zones, dungeons and floors. On the map, click a zone to open it, right-click to go back out, and scroll to zoom.")
		GameTooltip:Show()
	end)
	go:SetScript("OnLeave", W.HideTooltip)
	f.psGo = go
end

-- A game rule that turns a stock map control off (C_GameRules), as the stock map checks.
local function ruled(name)
	local r = Enum.GameRule and Enum.GameRule[name]
	return r and C_GameRules and C_GameRules.IsGameRuleActive(r) or false
end

-- The stock map's controls over the canvas's top right (its overlay frames):
-- full screen (the stock maximise, remembered) and under it the map pin
-- (WorldMapTrackingPinButtonMixin: while on, a click on the map sets the
-- player's waypoint, through the stock waypoint provider). Above the pins,
-- in the window's strata. The filter is on the tab row.
local function mapControls()
	local y = -8
	local function place(b)
		b:SetFrameLevel(canvas:GetFrameLevel() + 1500)
		b:SetPoint("TOPRIGHT", canvas, "TOPRIGHT", -8, y)
		Polestar.Theme.Skin(b, "editbox")
		y = y - 30 - 6
	end
	f.psFullButton = W.IconButton(f.Main, "window", 30, "Full screen", function() setFull(not f.psFull) end, 14)
	place(f.psFullButton)
	if not ruled("WorldMapTrackingPinDisabled") then
		local pin = W.IconButton(f.Main, "qol-target", 30, MAP_PIN or "Map Pin", function(self)
			M.SetPinning(not self.psPinning)
			PlaySound(self.psPinning and SOUNDKIT.UI_MAP_WAYPOINT_BUTTON_CLICK_ON or SOUNDKIT.UI_MAP_WAYPOINT_BUTTON_CLICK_OFF)
		end, 14)
		place(pin)
		f.psPin = pin
		-- A waypoint set (or cleared) ends the pinning, as the stock button.
		Polestar.RegisterEvent("USER_WAYPOINT_UPDATED", function() M.SetPinning(false) end)
	end
end

-- The player's and the cursor's coordinates at the canvas's bottom left, as
-- the stock coordinates panel (WorldMapCoordsPanelMixin): each as its CVar
-- says (worldMapShowPlayerCoords, worldMapShowCursorCoords), shown where the
-- client has no such CVar; tenths as coordsByTenths says. The player off
-- this map: their own map's coordinates, its name after them.
local function shown(cvar) local v = GetCVar(cvar) return v == nil or v == "1" end
local function coordText(prefix, x, y, name)
	local t = GetCVarBool("coordsByTenths") and ("%s: %.1f, %.1f"):format(prefix, x * 100, y * 100)
		or ("%s: %d, %d"):format(prefix, math.floor(x * 100 + 0.5), math.floor(y * 100 + 0.5))
	return name and ("%s (%s)"):format(t, name) or t
end
local function paintCoords()
	local c, lines = f.psCoords, {}
	local id = canvas:GetMapID()
	if id and shown("worldMapShowPlayerCoords") then
		local pos = C_Map.GetPlayerMapPosition(id, "player")
		if pos then
			lines[#lines + 1] = coordText("Player", pos:GetXY())
		else
			local own = C_Map.GetBestMapForUnit("player")
			pos = own and C_Map.GetPlayerMapPosition(own, "player")
			if pos then
				local x, y = pos:GetXY()
				lines[#lines + 1] = coordText("Player", x, y, (C_Map.GetMapInfo(own) or {}).name or UNKNOWN)
			end
		end
	end
	if shown("worldMapShowCursorCoords") and canvas:IsMouseOver() then
		local x, y = canvas:GetNormalizedCursorPosition()
		if x and x >= 0 and x <= 1 and y >= 0 and y <= 1 then lines[#lines + 1] = coordText("Cursor", x, y) end
	end
	c.Text:SetText(table.concat(lines, string.char(10)))
	c:SetSize(math.ceil(c.Text:GetStringWidth()) + 16, math.ceil(c.Text:GetStringHeight()) + 10)
	c:SetShown(#lines > 0)
end
local function coords()
	local c = CreateFrame("Frame", nil, f.Main)
	c:SetFrameLevel(canvas:GetFrameLevel() + 1500)
	c:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", 8, 8)
	Polestar.Theme.Skin(c, "editbox")
	c.Text = W.Text(c, "small", "text")
	c.Text:SetPoint("LEFT", c, "LEFT", 8, 0)
	c.Text:SetJustifyH("LEFT")
	c.Text:SetSpacing(2)
	f.psCoords = c
	-- Read ten times a second while the map shows (the stock panel reads every frame).
	local wait = 0
	local driver = CreateFrame("Frame", nil, f)
	driver:SetScript("OnUpdate", function(_, e)
		wait = wait - e
		if wait > 0 then return end
		wait = 0.1
		paintCoords()
	end)
end

-- The pin button's state: on (the accent), and enabled where the map takes a waypoint.
function M.SetPinning(on)
	local b = f and f.psPin
	if not b then return end
	local can = C_Map.CanSetUserWaypointOnMap(canvas:GetMapID() or 0) and true or false
	b.psPinning = on and can or false
	W.SetIconState(b, b.psPinning, can)
	b.psTipLines = can and { MAP_PIN_TOOLTIP or "Click on the map to place a pin you can track.", { MAP_PIN_TOOLTIP_INSTRUCTIONS or "", 0.1, 1, 0.1 } }
		or { { MAP_PIN_INVALID_MAP or "You can't place a pin on this map.", 1, 0.13, 0.13 } }
	canvas:TriggerEvent("WaypointLocationToggleUpdate", b.psPinning)
end

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 2 + MAP_W, height = 60 + 36 + 2 + MAP_H, searchPlaceholder = "Search quests",
		onSearch = function(text)
			if not (f and f.psQuests) then return end
			f.psQuests.SetQuery(text)
			paintFilter()
		end })
	ns.Dock(f)
	ns.WindowMenu(f, "map")
	ns.Compact(f)
	-- The canvas under the tab row keeps the map art's shape, whatever the skin's tab height.
	f:SetSize(2 + MAP_W, f.psHead + f.psTabsH + 2 + MAP_H)
	ns.Footer(f, {}, {})
	-- No body here: its scroll area would take the mouse wheel from the map
	-- and the quest log over it.
	f.Scroll:Hide()
	buildCanvas()
	hooksecurefunc(canvas, "OnMapChanged", function() M.Refresh() end)
	f.psSize = { f:GetWidth(), f:GetHeight() }
	f.psQuests = ns.QuestLog(f, canvas, QUEST_W)
	f.psQuests:SetPoint("TOPRIGHT", f.Content, "TOPRIGHT", 0, 0)
	f.psQuests:SetPoint("BOTTOMRIGHT", f.Content, "BOTTOMRIGHT", 0, 0)
	-- Its details open or shut: the search follows the list.
	f.psQuests.OnView = function() paintTabs() end
	f.psLegend = legend()
	-- The stock map's filter menu (the quest log's, one state for both), at
	-- the tab row's end (ns.TopNav), lit while a filter is off its default.
	-- It opens our dropdown: the search while the quest list shows, then the
	-- game's menu (MENU_WORLD_MAP_TRACKING, with what other addons add to it)
	-- read into its rows (ns.GameMenu); a submenu in its place.
	ns.SearchInFilter(f, function(self)
		ns.GameMenu(self, f.psQuests.FilterMenu, function(items, depth)
			if depth == 0 and searchable() then return ns.FilterMenu(f, items) end
			return W.ShowMenu(self, items, { minWidth = 220 })
		end)
	end)
	f.psQuests.OnFilters = paintFilter
	mapNav()
	mapControls()
	coords()
	setPanel(PolestarUIDB.mapQuests)
	if PolestarUIDB.mapFull then setFull(true) end
	-- A new size (the side column, full screen): the tab row and band laid out again.
	f:HookScript("OnSizeChanged", function() paintTabs() end)
	-- As the stock map opens: on the player's map, zoomed out, with its sounds.
	f:HookScript("OnShow", function()
		canvas:Show()
		canvas:SetMapID(MapUtil.GetDisplayableMapForPlayer())
		canvas:ResetZoom()
		PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN)
	end)
	f:HookScript("OnHide", function()
		M.SetPinning(false)
		canvas:Hide()
		PlaySound(SOUNDKIT.IG_QUEST_LOG_CLOSE)
	end)
	Polestar.CloseOnEscape(NAME)
end

-- The band: "World Map", then the shown map and the one it lies in; the
-- nav's label, the tabs and the pin follow the shown map.
function M.Refresh()
	if not (f and f:IsShown()) then return end
	local id = canvas:GetMapID()
	local info = id and C_Map.GetMapInfo(id)
	if not info then return end
	local go = f.psGo
	go.Label:SetText(info.name)
	go:SetWidth(math.ceil(go.Label:GetStringWidth()) + 10 + 8 + 12 + 10)
	f.psHere.psTip = ("Where you are: %s"):format(GetZoneText() or "")
	paintTabs()
	-- A new map: the pin turned off, enabled where the map takes one.
	if f.psPin and f.psPinMap ~= id then
		f.psPinMap = id
		M.SetPinning(false)
	end
	local parent = info.parentMapID and info.parentMapID > 0 and C_Map.GetMapInfo(info.parentMapID)
	W.ShellTitle(f, "World Map", parent and (info.name .. " · " .. parent.name) or info.name)
end

function M.Show()
	if not f then build() end
	f:Show()
	M.Refresh()
end

-- The map key toggles the map; the quest log's, as the stock toggle, closes
-- the map when the log shows in it, else opens both.
function M.Toggle()
	if f and f:IsShown() then f:Hide() else M.Show() end
end

function M.ToggleQuests()
	if f and f:IsShown() and f.psPage == "quests" then
		f:Hide()
	else
		M.Show()
		setPanel("quests")
	end
end

function M.Enable()
	-- The map and quest log keys and the micro button open ours; the stock
	-- map is never touched (docs/CLIENT.md, rule 8), a shift-click on the
	-- micro button away. Every other door stays the game's (docs/CLIENT.md, rule 14).
	ns.Doors("map", "WorldMap", { TOGGLEWORLDMAP = M.Toggle, TOGGLEQUESTLOG = M.ToggleQuests }, QuestLogMicroButton, M.ToggleQuests)
	Polestar.RegisterEvent("ZONE_CHANGED_NEW_AREA", M.Refresh)
	Polestar.RegisterEvent("ZONE_CHANGED", M.Refresh)
	local function quests()
		if not f then return end
		f.psQuests.Paint()
		if f:IsShown() then paintTabs() end
	end
	Polestar.RegisterEvent("QUEST_LOG_UPDATE", quests)
	Polestar.RegisterEvent("QUEST_WATCH_LIST_CHANGED", quests)
	Polestar.RegisterEvent("SUPER_TRACKING_CHANGED", quests)
	-- A filter changed from the stock map's menu or log (the level, colour, objectives).
	Polestar.RegisterEvent("CVAR_UPDATE", quests)
	-- A reward's item, loaded after the details first showed it.
	Polestar.RegisterEvent("GET_ITEM_INFO_RECEIVED", function() if f and f.psQuests.Details:IsShown() then quests() end end)
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return WorldMapFrame end

ns.Module("map", M)
