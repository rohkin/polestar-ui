-- World Map (docs/DESIGN.md, "World Map"): the game's own map canvas
-- (MapCanvasMixin with the stock world map's data providers, as the zone map
-- BattlefieldMapFrame builds it) in a Polestar shell; the sidebar walks the
-- map's parents and zones. The stock WorldMapFrame is never touched: its hide
-- runs UpdateMicroButtons (docs/CLIENT.md, rule 8), and map addons draw on it,
-- so it stays theirs and the game's, for every door we do not take.

local ADDON, ns = ...
local W = Polestar.Widgets

local NAME = "PolestarUIWorldMap"
-- The canvas keeps the shape of the map art (1002x668).
local MAP_W, MAP_H = 852, 568
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

-- The quest log flyout, open or shut (remembered): the map ends at its left
-- edge, and the window grows by its width unless it fills the screen.
local function setQuests(on)
	PolestarUIDB.mapQuests = on or nil
	f.psQuests:SetShown(on)
	canvas:ClearAllPoints()
	canvas:SetPoint("TOPLEFT", f.Content, "TOPLEFT", 0, 0)
	canvas:SetPoint("BOTTOMRIGHT", on and f.psQuests or f.Content, on and "BOTTOMLEFT" or "BOTTOMRIGHT", 0, 0)
	if not f.psFull then f:SetSize(f.psSize[1] + (on and QUEST_W or 0), f.psSize[2]) end
	W.Color(f.psQuestsButton.Label, on and "accent" or "text")
	f.psQuestsButton.Arrow:SetTexture(Polestar.Theme.Media(on and "chevron-right" or "chevron-left"))
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
		setQuests(f.psQuests:IsShown()) -- its size again
	end
	local b = f.psFullButton
	b.psIconName, b.psTip = on and "compact" or "window", on and "Back to a window" or "Full screen"
	b.Icon:SetTexture(Polestar.Theme.Media(Polestar.Theme.Icon(b.psIconName)))
	ns.Relayout()
end

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = W.SHELL.sidebar + 2 + MAP_W, height = W.SHELL.header + 2 + MAP_H })
	ns.Dock(f)
	ns.WindowMenu(f, "map")
	-- The subject block names the window, in place of Polestar's lockup.
	f.Search:Hide()
	local b = ns.SubjectBlock(f)
	b.icon:SetTexture("Interface/Icons/INV_Misc_Map_01")
	f.psName, f.psLine = b.name, b.line
	f.psName:SetText("World Map")
	W.ShellTabs(f, nil)
	W.ShellFooter(f, {}, {})
	-- No body here: its scroll area would take the mouse wheel from the map
	-- and the quest log over it.
	f.Scroll:Hide()
	buildCanvas()
	hooksecurefunc(canvas, "OnMapChanged", function() M.Refresh() end)
	f.psSize = { f:GetWidth(), f:GetHeight() }
	f.psFullButton = W.IconButton(f.Header, "window", 28, "Full screen", function() setFull(not f.psFull) end, 14)
	f.psFullButton:SetPoint("BOTTOMRIGHT", f.Header, "BOTTOMRIGHT", -12, 12)
	-- The quest log's button, as the Spellbook's Options: a label and its arrow.
	local qb = CreateFrame("Button", nil, f.Header)
	qb:SetSize(88, 24)
	qb:SetPoint("RIGHT", f.psFullButton, "LEFT", -8, 0)
	W.Hover(qb)
	qb.Label = W.Text(qb, "small", "text")
	qb.Label:SetPoint("LEFT", qb, "LEFT", 10, 0)
	qb.Label:SetText("Quests")
	qb.Arrow = W.Tex(qb, "ARTWORK", "chevron-left", "textDim")
	qb.Arrow:SetSize(12, 12)
	qb.Arrow:SetPoint("RIGHT", qb, "RIGHT", -10, 0)
	qb:SetScript("OnClick", function() setQuests(not f.psQuests:IsShown()) end)
	f.psQuestsButton = qb
	f.psQuests = ns.QuestLog(f, canvas, QUEST_W)
	f.psQuests:SetPoint("TOPRIGHT", f.Content, "TOPRIGHT", 0, 0)
	f.psQuests:SetPoint("BOTTOMRIGHT", f.Content, "BOTTOMRIGHT", 0, 0)
	-- A new size: the band's sky cropped again, never stretched.
	f:HookScript("OnSizeChanged", function(self, w)
		self.Band:SetTexCoord(Polestar.Theme.BandCoords(w - W.SHELL.sidebar - 2, W.SHELL.header))
	end)
	setQuests(PolestarUIDB.mapQuests and true or false)
	if PolestarUIDB.mapFull then setFull(true) end
	-- As the stock map opens: on the player's map, zoomed out, with its sounds.
	f:HookScript("OnShow", function()
		canvas:Show()
		canvas:SetMapID(MapUtil.GetDisplayableMapForPlayer())
		canvas:ResetZoom()
		PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN)
	end)
	f:HookScript("OnHide", function()
		canvas:Hide()
		PlaySound(SOUNDKIT.IG_QUEST_LOG_CLOSE)
	end)
	Polestar.CloseOnEscape(NAME)
end

-- The sidebar: where the player is, the maps above this one, and the zones in it.
function M.Refresh()
	if not (f and f:IsShown()) then return end
	local id = canvas:GetMapID()
	local info = id and C_Map.GetMapInfo(id)
	if not info then return end
	local here = MapUtil.GetDisplayableMapForPlayer()
	local items = { { key = here, label = "Where you are", icon = "flag" }, { separator = true } }
	local up, p = {}, info.parentMapID
	while p and p > 0 do
		local pi = C_Map.GetMapInfo(p)
		if not pi then break end
		table.insert(up, 1, { key = pi.mapID, label = pi.name, icon = "chevron-left" })
		p = pi.parentMapID
	end
	for _, item in ipairs(up) do items[#items + 1] = item end
	local zones = {}
	for _, c in ipairs(C_Map.GetMapChildrenInfo(id, nil, false) or {}) do
		if c.mapType == CONTINENT or c.mapType == ZONE then zones[#zones + 1] = { key = c.mapID, label = c.name, icon = "icon-explore" } end
	end
	table.sort(zones, function(a, b) return a.label < b.label end)
	if #up > 0 and #zones > 0 then items[#items + 1] = { separator = true } end
	for _, item in ipairs(zones) do items[#items + 1] = item end
	-- Its dungeons and caves, as the stock nav bar's dropdown lists them (a
	-- cave has no entrance pin to click); a map of floors once, by its first.
	local dungeons, seen = {}, {}
	for _, c in ipairs(C_Map.GetMapChildrenInfo(id, nil, false) or {}) do
		if (c.mapType == DUNGEON or c.mapType == MICRO) and C_Map.IsMapValidForNavBarDropdown(c.mapID) then
			local g = C_Map.GetMapGroupID(c.mapID)
			local first = g and (C_Map.GetMapGroupMembersInfo(g) or {})[1]
			local key = first and first.mapID or c.mapID
			if not seen[key] then
				seen[key] = true
				dungeons[#dungeons + 1] = { key = key, label = (C_Map.GetMapInfo(key) or c).name, icon = "icon-dungeon" }
			end
		end
	end
	table.sort(dungeons, function(a, b) return a.label < b.label end)
	if #dungeons > 0 then items[#items + 1] = { separator = true } end
	for _, item in ipairs(dungeons) do items[#items + 1] = item end
	-- A map of several levels lists them, in the order the client gives, as the stock floor dropdown does.
	local group = C_Map.GetMapGroupID(id)
	local floors = group and C_Map.GetMapGroupMembersInfo(group)
	if floors and #floors > 0 then
		items[#items + 1] = { separator = true }
		for _, fl in ipairs(floors) do items[#items + 1] = { key = fl.mapID, label = fl.name, icon = "layers" } end
	end
	W.ShellNav(f, items, id, function(k) canvas:SetMapID(k) end)
	-- How to move around the map lives in the rows' tooltips; the title line is a fact.
	for _, b in ipairs(f.navButtons) do
		if not b.psMapTip then
			b.psMapTip = true
			b:HookScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(self.Label:GetText() or "", 1, 1, 1)
				ns.TooltipHint("Click to show this map. On the map, click a zone to open it, right-click to go back out, and scroll to zoom.")
				GameTooltip:Show()
			end)
			b:HookScript("OnLeave", W.HideTooltip)
		end
	end
	f.psLine:SetText(GetZoneText() or "")
	-- The status line: the map this one lies in.
	local parent = info.parentMapID and info.parentMapID > 0 and C_Map.GetMapInfo(info.parentMapID)
	W.ShellTitle(f, info.name, parent and parent.name or nil)
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
	if f and f:IsShown() and f.psQuests:IsShown() then
		f:Hide()
	else
		M.Show()
		setQuests(true)
	end
end

function M.Enable()
	-- The map and quest log keys and the micro button open ours; the stock
	-- map is never touched (docs/CLIENT.md, rule 8), a shift-click on the
	-- micro button away. Every other door stays the game's (docs/CLIENT.md, rule 14).
	ns.Doors("map", "WorldMap", { TOGGLEWORLDMAP = M.Toggle, TOGGLEQUESTLOG = M.ToggleQuests }, QuestLogMicroButton, M.ToggleQuests)
	Polestar.RegisterEvent("ZONE_CHANGED_NEW_AREA", M.Refresh)
	Polestar.RegisterEvent("ZONE_CHANGED", M.Refresh)
	local function quests() if f then f.psQuests.Paint() end end
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
