-- Questie loaded (after stub_worldmap.lua): its loader with the two modules
-- Addons/Questie.lua reads, HBDPins (its HereBeDragons-Pins copy: the
-- worldmapPins registry, icon frame -> where it goes) and HBD (world to zone
-- coordinates; here each map is a rect of one flat world: Elwynn 0..1000,
-- Westfall left of it, Duskwood right, Eastern Kingdoms 4000 round them,
-- Azeroth 8000). Its icons are parented to the stock map's pins or to
-- UIParent, never to ours: any write on an icon or its registry row fails
-- the scene.

local function guard(t, what)
	return setmetatable({}, { __index = t, __newindex = function(_, k) error("write on Questie's " .. what .. ": " .. tostring(k)) end,
		__metatable = false })
end

local RECT = { [37] = { 0, 0, 1000 }, [52] = { -1000, 0, 1000 }, [47] = { 1000, 0, 1000 }, [13] = { -2000, -2000, 4000 } } -- left, top, size
local pins, hbd = { worldmapPins = {} }, { mapData = {} }
for id in pairs(RECT) do hbd.mapData[id] = { mapType = id == 13 and 2 or 3, parent = id ~= 13 and 13 or 947 } end
function hbd:GetZoneCoordinatesFromWorldInstance(x, y, instance, zone)
	local r = RECT[zone]
	if instance ~= 0 or not r then return nil, nil end
	x, y = (x - r[1]) / r[3], (y - r[2]) / r[3]
	if x < 0 or x > 1 or y < 0 or y > 1 then return nil, nil end
	return x, y
end
function hbd:GetAzerothWorldMapCoordinatesFromWorld(x, y) return (x + 4000) / 8000, (y + 4000) / 8000 end
Questie = { db = { profile = { hideIconsOnContinents = false, alwaysGlowMap = true, globalScale = 0.75, waypointMapEnabled = true, waypointWidth = 3 } } }

-- Questie's HereBeDragons-Pins copy: the registry's writers, as Questie calls them (zone x, y in 0..1).
function pins:AddWorldMapIconMap(ref, icon, uiMapID, x, y, showFlag)
	self.worldmapPins[icon] = guard({ instanceID = 0, x = RECT[uiMapID][1] + x * 1000, y = RECT[uiMapID][2] + y * 1000, uiMapID = uiMapID,
		worldMapShowFlag = showFlag or 0 }, "pin data")
end
function pins:RemoveWorldMapIcon(ref, icon) self.worldmapPins[icon] = nil end
function pins:RemoveAllWorldMapIcons(ref) for icon in pairs(self.worldmapPins) do self.worldmapPins[icon] = nil end end

-- stub.questieIcon(map, x, y, texture, size, hidden, flag) -> the icon, as
-- QuestieFrame.CreateIconFrame makes it and QuestieMap.ProcessQueue adds it:
-- into the registry first, sized after (flag: HBD's worldMapShowFlag; Questie's
-- is 3, the world map too). Questie changes it through icon:FakeHide(),
-- icon:FakeShow(), icon:SetSize() and its texture's SetTexture/SetVertexColor.
-- stub.questieReset(): QuestieQuest:SmoothReset (a setting changed): every icon removed and added again.
local made, args = 0, {}
function stub.questieIcon(map, x, y, texture, size, hidden, flag, data)
	made = made + 1
	local icon = CreateFrame("Button", "QuestieFrame" .. made)
	icon.texture = icon:CreateTexture(nil, "OVERLAY")
	icon.texture:SetAllPoints(icon)
	icon.texture:SetTexture(texture)
	-- The glow shows only as the icon shows on the stock map (its OnShow); the overlay keeps its own flag.
	icon.glowTexture = icon:CreateTexture(nil, "OVERLAY", nil, -1)
	icon.glowTexture:SetTexture("Interface/AddOns/Questie/Icons/glow.blp")
	icon.glowTexture:Hide()
	icon.overlayTexture = icon:CreateTexture(nil, "OVERLAY", nil, 1)
	icon.overlayTexture:Hide()
	icon.data = data -- { Type, Name, IconScale, ObjectiveData = { Color } }, as Questie's draw calls give it
	icon.x, icon.y, icon.AreaID, icon.UiMapID = x * 100, y * 100, map, map
	-- Its own click (QuestieFrame's OnClick: a chat link, hide the quest, TomTom).
	icon:SetScript("OnClick", function(self, button) stub.questieClicked = { self, button } end)
	icon:Hide() -- HBD shows it only on the stock map's own zone
	for _, m in ipairs({ "SetParent", "SetPoint", "ClearAllPoints", "Show", "Hide", "SetScript", "HookScript" }) do
		icon[m] = function() error("Questie's icon: " .. m .. " from Polestar: UI") end
	end
	function icon:FakeHide() self.hidden = true end
	function icon:FakeShow() self.hidden = false end
	-- Its art swap (QuestieFrame's UpdateTexture), ending on the colour.
	function icon:UpdateTexture(path) self.texture:SetTexture(path); self.texture:SetVertexColor(self.texture:GetVertexColor()) end
	args[icon] = { map, x, y, flag or 3 }
	pins:AddWorldMapIconMap("Questie", icon, map, x, y, flag or 3)
	icon:SetSize(size or 16, size or 16)
	icon:SetFrameLevel(2016 + (data and data.Type == "complete" and 8 or 4)) -- QuestieMap.utils.SetDrawOrder
	if hidden then icon:FakeHide() end
	return icon
end
function stub.questieRemove(icon) pins:RemoveWorldMapIcon("Questie", icon) end
function stub.questieReset()
	local list = {}
	for icon in pairs(pins.worldmapPins) do list[#list + 1] = icon end
	for _, icon in ipairs(list) do pins:RemoveWorldMapIcon("Questie", icon) end
	for _, icon in ipairs(list) do pins:AddWorldMapIconMap("Questie", icon, unpack(args[icon])) end
end

local ICONS = "Interface\\AddOns\\Questie\\Icons\\"
stub.questieIcon(37, 0.25, 0.5, ICONS .. "available.blp")
stub.questieIcon(37, 0.5, 0.25, ICONS .. "complete.blp", 20)
stub.questieIcon(37, 0.75, 0.75, ICONS .. "slay.blp", 16, true) -- hidden by Questie
stub.questieIcon(52, 0.4, 0.4, ICONS .. "available.blp") -- Westfall's
stub.questieIcon(47, 0.5, 0.5, ICONS .. "event.blp", 16, false, -1) -- Duskwood's, on its own map only

-- The glow setting's handler walks Questie's icons (their OnShow, or the glow hidden): nothing of an icon's is called.
local modules = { HBDPins = pins, HBD = hbd, QuestieFramePool = { UpdateGlowConfig = function() end } }
-- Questie's tooltip into the tooltip given (MapIconTooltip.ShowOnTooltip): the
-- hovered icon and the icons given, one line each (the long form with Shift),
-- built by the _Rebuild it leaves on the tooltip; the hovered quest's icon
-- tinted until QuestieFrame.ResetHoverHighlights gives its colour back.
modules.MapIconTooltip = { ShowOnTooltip = function(self, tooltip, owner, icons)
	stub.questieTip = { icon = self, tooltip = tooltip, owner = owner, icons = icons }
	tooltip:SetOwner(owner or self, "ANCHOR_CURSOR")
	self.data.touchedPins = { { icon = self, color = { self.texture:GetVertexColor() } } }
	self.texture:SetVertexColor(0.6, 1, 1, 1)
	tooltip._Rebuild = function(t)
		for _, icon in ipairs(icons or { self }) do t:AddLine(icon.data.Name .. (IsShiftKeyDown() and " (long)" or "")) end
	end
	tooltip:_Rebuild()
	tooltip:Show()
end }
-- Questie's patrol paths: its registry (a path: its map, its points in the
-- map's percent, its route and owner icon), how each shows, and its line
-- renderer on a canvas (a view: a frame with its points and style). Questie
-- says a change through WaypointMap.Invalidate.
-- stub.questiePath(icon, map, points, route) -> the path; stub.questiePathGone(path).
local ways = { paths = {} }
function ways.WorldMapAlpha(path) if Questie.db.profile.waypointMapEnabled and not path.owner.hidden then return 1 end end
function ways.IsHighlighted(path) return path.highlighted or false end
function ways.Color(path) return path.highlighted and { 1, 1, 0, 1 } or { 0, 1, 0, 1 } end
modules.QuestieWaypoints = ways
modules.WaypointMap = { Invalidate = function() stub.questieInvalidated = (stub.questieInvalidated or 0) + 1 end }
stub.questieRenderers = {}
modules.WaypointRenderer = { New = function(canvas)
	local r = { canvas = canvas, owned = {}, drawn = 0 }
	function r:Restyle(view, style) assert(self.owned[view], "not this renderer's view") view.style = style end
	function r:Draw(view, runs, style)
		view = view or CreateFrame("Frame", nil, canvas)
		self.owned[view], self.drawn = true, self.drawn + 1
		view.runs = runs
		view:Hide()
		self:Restyle(view, style)
		return view
	end
	function r:Release(view) view:Hide() self.owned[view] = nil end
	function r:Clear() for view in pairs(self.owned) do self:Release(view) end end
	stub.questieRenderers[#stub.questieRenderers + 1] = r
	return r
end }
function stub.questiePath(icon, map, points, route)
	local path = { owner = icon, data = icon.data, uiMapId = map, points = points, route = route }
	ways.paths[path] = true
	modules.WaypointMap.Invalidate()
	return path
end
function stub.questiePathGone(path) ways.paths[path] = nil modules.WaypointMap.Invalidate() end
modules.QuestieFrame = { ResetHoverHighlights = function(t)
	stub.questieUnhovered = t.data
	for _, e in ipairs(t.data.touchedPins or {}) do e.icon.texture:SetVertexColor(unpack(e.color)) end
	t.data.touchedPins = nil
end }
QuestieLoader = {}
function QuestieLoader:ImportModule(name)
	modules[name] = modules[name] or { private = {} }
	return modules[name]
end

stub.withCanvasReads()

local createFrame = CreateFrame
function CreateFrame(kind, name, parent, template, ...)
	local f = createFrame(kind, name, parent, template, ...)
	if kind == "GameTooltip" and template == "GameTooltipTemplate" then
		-- A tooltip of an addon's own, as the game's: its lines and its stock art.
		for _, m in ipairs({ "SetOwner", "ClearLines", "AddLine", "AddDoubleLine", "SetText" }) do f[m] = GameTooltip[m] end
		f.lines = {}
		if not rawget(f, "NineSlice") then stub.tooltipArt(f) end
		f.StatusBar = false -- no health bar in the stub (an unset key answers a function)
		f:Hide()
	end
	return f
end
