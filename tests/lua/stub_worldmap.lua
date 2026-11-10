-- The client's map reads and the game's map canvas; the values are the
-- preview's sample: Azeroth > Eastern Kingdoms > Elwynn Forest, the player in
-- Elwynn. The canvas (PolestarUIMapCanvasTemplate, from XML the stub does not
-- read) records its map and providers and draws a flat well for the art.

local MAPS = {
	[947] = { mapID = 947, name = "Azeroth", mapType = 1, parentMapID = 0 },
	[13] = { mapID = 13, name = "Eastern Kingdoms", mapType = 2, parentMapID = 947 },
	[12] = { mapID = 12, name = "Kalimdor", mapType = 2, parentMapID = 947 },
	[37] = { mapID = 37, name = "Elwynn Forest", mapType = 3, parentMapID = 13 },
	[52] = { mapID = 52, name = "Westfall", mapType = 3, parentMapID = 13 },
	[47] = { mapID = 47, name = "Duskwood", mapType = 3, parentMapID = 13 },
	[1429] = { mapID = 1429, name = "Fargodeep Mine", mapType = 4, parentMapID = 37 },
}
C_Map = C_Map or {}
function C_Map.GetMapInfo(id) return MAPS[id] end
function C_Map.GetMapChildrenInfo(id)
	local t = {}
	for _, m in pairs(MAPS) do if m.parentMapID == id then t[#t + 1] = m end end
	return t
end
MapUtil = { GetDisplayableMapForPlayer = function() return 37 end }
function GetZoneText() return "Elwynn Forest" end
C_QuestLog = C_QuestLog or {}
function C_QuestLog.GetMaxNumQuests() return 25 end

QuestDataProviderMixin = {}
AreaLabelDataProviderMixin = { SetOffsetY = function(self, y) self.offsetY = y end }

local Canvas = {}
function Canvas:SetShouldZoomInOnClick() end
function Canvas:SetShouldPanOnClick() end
function Canvas:SetShouldNavigateOnClick(on) self.navigateOnClick = on end
function Canvas:SetShouldZoomInstantly() end
function Canvas:GetPinFrameLevelsManager() return { AddFrameLevel = function(_, name) self.levels[#self.levels + 1] = name end } end
function Canvas:AddDataProvider(p) self.providers[#self.providers + 1] = p end
function Canvas:SetMapID(id) if id ~= self.mapID then self.mapID = id; self:OnMapChanged() end end
function Canvas:GetMapID() return self.mapID end
function Canvas:OnMapChanged() end
function Canvas:ResetZoom() self.zoomedOut = true end
-- The map art's one zoom step, as Forever's art gives it.
function Canvas:OnFrameSizeChanged() self.ScrollContainer:CreateZoomLevels() end
local function oneStep(self) self.zoomLevels = { { scale = 0.8, layerIndex = 1 } } end

local createFrame = CreateFrame
function CreateFrame(kind, name, parent, template, ...)
	local f = createFrame(kind, name, parent, template, ...)
	if template == "PolestarUIMapCanvasTemplate" then
		for k, v in pairs(Canvas) do f[k] = v end
		f.providers, f.levels = {}, {}
		f:SetFrameStrata("MEDIUM") -- as the template sets it
		f:Hide()
		f.ScrollContainer = createFrame("ScrollFrame", nil, f)
		f.ScrollContainer:SetAllPoints(f)
		f.ScrollContainer.CreateZoomLevels = oneStep
		local art = f.ScrollContainer:CreateTexture(nil, "BACKGROUND")
		art:SetAllPoints(f.ScrollContainer)
		art:SetColorTexture(0.18, 0.22, 0.2, 1)
	end
	return f
end

-- The game's own map: our doors must not open it.
WorldMapFrame = createFrame("Frame", "WorldMapFrame", UIParent)
WorldMapFrame:Hide()
stub.bindings.TOGGLEWORLDMAP = { "M" }
function stub.bindingRun.TOGGLEWORLDMAP() WorldMapFrame:Show() end
