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
Questie = { db = { profile = { hideIconsOnContinents = false } } }

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
function stub.questieIcon(map, x, y, texture, size, hidden, flag)
	made = made + 1
	local icon = CreateFrame("Button", "QuestieFrame" .. made)
	icon.texture = icon:CreateTexture(nil, "OVERLAY")
	icon.texture:SetAllPoints(icon)
	icon.texture:SetTexture(texture)
	icon:Hide() -- HBD shows it only on the stock map's own zone
	for _, m in ipairs({ "SetParent", "SetPoint", "ClearAllPoints", "Show", "Hide", "SetScript", "HookScript" }) do
		icon[m] = function() error("Questie's icon: " .. m .. " from Polestar: UI") end
	end
	function icon:FakeHide() self.hidden = true end
	function icon:FakeShow() self.hidden = false end
	args[icon] = { map, x, y, flag or 3 }
	pins:AddWorldMapIconMap("Questie", icon, map, x, y, flag or 3)
	icon:SetSize(size or 16, size or 16)
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

local modules = { HBDPins = pins, HBD = hbd }
QuestieLoader = {}
function QuestieLoader:ImportModule(name)
	modules[name] = modules[name] or { private = {} }
	return modules[name]
end

-- The canvas reads the mirror needs, as MapCanvasMixin gives them: the art
-- 1002 by 668, fitted to the 900 by 600 frame (scale 0.9 zoomed out).
local createFrame = CreateFrame
function CreateFrame(kind, name, parent, template, ...)
	local f = createFrame(kind, name, parent, template, ...)
	if template == "PolestarUIMapCanvasTemplate" then
		local child = createFrame("Frame", nil, f.ScrollContainer)
		child:SetSize(1002, 668)
		child:SetPoint("TOPLEFT")
		f.ScrollContainer.Child = child
		function f:GetCanvas() return child end
		function f:GetCanvasScale() return stub.mapScale or 0.9 end
		function f:GetCanvasZoomPercent() return stub.mapZoom or 0 end
		function f:GetGlobalPinScale() return 1 end
	end
	return f
end
