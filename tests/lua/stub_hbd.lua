-- An addon with HereBeDragons loaded (after stub_worldmap.lua): the two
-- LibStub libraries Addons/HereBeDragons.lua reads, "HereBeDragons-2.0" (the
-- maps and world to map coordinates; here each map is a rect of one flat
-- world: Elwynn 0..1000, Westfall left of it, Duskwood right, Eastern
-- Kingdoms 4000 round them, Azeroth 8000) and "HereBeDragons-Pins-2.0" (the
-- worldmapPins registry and the calls that write it). An icon is its addon's
-- frame, parented to the stock map's pin or to UIParent, never to ours: a
-- move, show, hide or script of one fails the scene, and so does a write on
-- its registry row.

stub.withCanvasReads()

local function guard(t, what)
	return setmetatable({}, { __index = t, __newindex = function(_, k) error("write on HereBeDragons' " .. what .. ": " .. tostring(k)) end,
		__metatable = false })
end

local RECT = { [37] = { 0, 0, 1000 }, [52] = { -1000, 0, 1000 }, [47] = { 1000, 0, 1000 }, [13] = { -2000, -2000, 4000 } } -- left, top, size
local core = { mapData = {} }
for id in pairs(RECT) do core.mapData[id] = { mapType = id == 13 and 2 or 3, parent = id ~= 13 and 13 or 947 } end
function core:GetZoneCoordinatesFromWorldInstance(x, y, instance, zone)
	local r = RECT[zone]
	if instance ~= 0 or not r then return nil, nil end
	x, y = (x - r[1]) / r[3], (y - r[2]) / r[3]
	if x < 0 or x > 1 or y < 0 or y > 1 then return nil, nil end
	return x, y
end
function core:GetAzerothWorldMapCoordinatesFromWorld(x, y) return (x + 4000) / 8000, (y + 4000) / 8000 end

-- The library's table, which LibStub hands to every copy of it; a copy
-- writes its functions on it (stub.hbdUpgrade(): a newer copy loaded later
-- does so again, and any hook on the old ones is gone; the registry stays).
local lib = { worldmapPins = {} }
local function define()
	function lib:AddWorldMapIconMap(ref, icon, uiMapID, x, y, showFlag, frameLevel)
		self.worldmapPins[icon] = guard({ instanceID = 0, x = RECT[uiMapID][1] + x * 1000, y = RECT[uiMapID][2] + y * 1000, uiMapID = uiMapID,
			worldMapShowFlag = showFlag or 0, frameLevelType = frameLevel }, "pin data")
	end
	function lib:RemoveWorldMapIcon(ref, icon) self.worldmapPins[icon] = nil end
	function lib:RemoveAllWorldMapIcons(ref) for icon in pairs(self.worldmapPins) do self.worldmapPins[icon] = nil end end
end
define()
stub.hbdUpgrade = define

local libs = { ["HereBeDragons-2.0"] = core, ["HereBeDragons-Pins-2.0"] = lib }
LibStub = { libs = libs }
function LibStub:GetLibrary(major, silent)
	if not libs[major] and not silent then error("Cannot find a library instance of " .. major) end
	return libs[major], 17
end

-- stub.hbdIcon(map, x, y, flag, level) -> an addon's icon (as HandyNotes
-- makes one), added to the map: 12 by 12 at scale 1.5, a file texture
-- filling it, an atlas badge 6 by 6 on its top right corner, and a
-- highlight texture that is hidden.
local made = 0
function stub.hbdIcon(map, x, y, flag, level)
	made = made + 1
	local icon = CreateFrame("Frame", "HandyNotesPin" .. made)
	icon:SetSize(12, 12)
	icon:SetScale(1.5)
	icon.texture = icon:CreateTexture(nil, "OVERLAY")
	icon.texture:SetAllPoints(icon)
	icon.texture:SetTexture("Interface/AddOns/HandyNotes/Icons/note.blp")
	icon.texture:SetVertexColor(1, 0.5, 0.25, 1)
	local badge = icon:CreateTexture(nil, "OVERLAY", nil, 2)
	badge:SetSize(6, 6)
	badge:SetPoint("CENTER", icon, "TOPRIGHT", -1, -2)
	badge:SetAtlas("worldquest-icon-pvp-ffa")
	local lit = icon:CreateTexture(nil, "HIGHLIGHT")
	lit:SetAllPoints(icon)
	lit:SetTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")
	lit:Hide()
	icon:Hide()
	for _, m in ipairs({ "SetParent", "SetPoint", "ClearAllPoints", "Show", "Hide", "SetSize", "SetScale", "SetScript", "HookScript" }) do
		icon[m] = function() error("an addon's icon: " .. m .. " from Polestar: UI") end
	end
	lib:AddWorldMapIconMap("HandyNotes", icon, map, x, y, flag, level)
	return icon
end
function stub.hbdRemove(icon) lib:RemoveWorldMapIcon("HandyNotes", icon) end
function stub.hbdRemoveAll() lib:RemoveAllWorldMapIcons("HandyNotes") end

stub.hbdIcon(37, 0.25, 0.5) -- Elwynn's, its own map only
stub.hbdIcon(37, 0.5, 0.25, 3, "PIN_FRAME_LEVEL_VIGNETTE") -- on the continent and the world map too
stub.hbdIcon(52, 0.4, 0.4, 2) -- Westfall's, on the continent too
