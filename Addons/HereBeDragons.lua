-- Other addons' world map icons put there through the HereBeDragons-Pins
-- library (LibStub "HereBeDragons-Pins-2.0": HandyNotes, TomTom, ...), on our
-- World Map (docs/addons.md). The library parents each icon, a frame of its
-- addon's, to a pin of the stock map; ours mirrors its registry (the map's
-- M.PinMirror): a frame of our own per icon of the shown map, with a copy of
-- the icon's shown textures, kept up by post-hooks on the library's calls
-- that write the registry. Nothing of the library's, the addons' or the
-- stock map's is touched. Generic: no addon is known here. A no-op without
-- the library. Questie's copy of it is not a LibStub library (Addons/Questie.lua).
-- shortcut: no tooltip or click (an icon's own OnEnter anchors GameTooltip to
-- the icon, which is hidden off our map), an icon's font strings and child
-- frames are not copied, and art an addon changes after adding the icon is
-- read again only when the icon is added again or the map shown again (no
-- signal); upgrade when an addon with such icons is at hand to check.

local ADDON, ns = ...

ns.AfterLogin(function()
local map = ns.modules.map
if not (map and map.overlays and map.PinMirror) then return end

local WORLD = 947 -- Azeroth
local CONTINENT, ZONE, DUNGEON, MICRO = 2, 3, 4, 5 -- Enum.UIMapType
local hbd, mirror, hookedAdd

-- Where an icon goes on the shown map (0..1), nil when it is not shown
-- there: the library's worldmapProvider:HandlePin (worldMapShowFlag: 0 its
-- own map, 1 parent zones too, 2 the continent, 3 the world map).
local function spot(_, d, v)
	local id, flag = v.id, d.worldMapShowFlag or 0
	if id == WORLD then
		if id ~= d.uiMapID and flag ~= 3 then return end
		return hbd:GetAzerothWorldMapCoordinatesFromWorld(d.x, d.y, d.instanceID)
	end
	if not hbd.mapData[id] then return end
	if id ~= d.uiMapID then
		local kind = v.kind
		if not d.uiMapID then
			if not (kind == CONTINENT and flag >= 2) and kind ~= ZONE and kind ~= DUNGEON and kind ~= MICRO then return end
		else
			local show = false
			local own = hbd.mapData[d.uiMapID]
			local parent = own and own.parent
			while parent and hbd.mapData[parent] do
				if parent == id then
					show = (flag >= 1 and (kind == ZONE or kind == DUNGEON or kind == MICRO)) or (flag >= 2 and kind == CONTINENT)
					break
				end
				parent = hbd.mapData[parent].parent
			end
			if not show then return end
		end
	end
	return hbd:GetZoneCoordinatesFromWorldInstance(d.x, d.y, d.instanceID, id)
end

-- Our frame as the icon looks: its size and scale, at the level the library
-- asks of the map for it, with a copy of each texture the icon shows (its
-- file or atlas, crop, colour, layer and place on the icon).
local function dress(f, icon, d, v)
	local s = icon:GetScale() * v.k
	f:SetSize(math.max(icon:GetWidth(), 1) * s, math.max(icon:GetHeight(), 1) * s)
	local levels = v.canvas:GetPinFrameLevelsManager()
	local ok, level = pcall(levels.GetValidFrameLevel, levels, d.frameLevelType or "PIN_FRAME_LEVEL_AREA_POI")
	f:SetFrameLevel(ok and level or 2016)
	f:SetAlpha(icon:GetAlpha())
	f.psTex = f.psTex or {}
	local n = 0
	for _, r in ipairs({ icon:GetRegions() }) do
		if r:IsObjectType("Texture") and r:IsShown() then
			n = n + 1
			local t = f.psTex[n] or f:CreateTexture()
			f.psTex[n] = t
			t:SetDrawLayer(r:GetDrawLayer())
			local atlas = r:GetAtlas()
			if atlas then
				t:SetAtlas(atlas)
			else
				t:SetTexture(r:GetTexture())
				t:SetTexCoord(r:GetTexCoord())
			end
			t:SetVertexColor(r:GetVertexColor())
			t:SetAlpha(r:GetAlpha())
			t:SetBlendMode(r:GetBlendMode() or "BLEND")
			t:SetDesaturated(r:IsDesaturated() and true or false)
			t:ClearAllPoints()
			local points = r:GetNumPoints()
			if points == 0 then
				t:SetAllPoints(f)
			else
				-- Its anchors are taken as the icon's own (what a pin icon's art hangs on).
				for i = 1, points do
					local point, _, relPoint, x, y = r:GetPoint(i)
					t:SetPoint(point, f, relPoint, (x or 0) * s, (y or 0) * s)
				end
				if points == 1 then t:SetSize(r:GetWidth() * s, r:GetHeight() * s) end
			end
			t:Show()
		end
	end
	for i = n + 1, #f.psTex do f.psTex[i]:Hide() end
end

-- The library, once it is there (an addon loaded on demand may bring it
-- late), and again when a newer copy took its place: LibStub hands every
-- copy the same table, and a newer one writes its functions afresh, without
-- our post-hooks; the registry stays. Checked at login and as our map shows
-- or changes, never on a timer.
local function attach()
	if type(LibStub) ~= "table" or type(LibStub.GetLibrary) ~= "function" then return end
	local okP, lib = pcall(LibStub.GetLibrary, LibStub, "HereBeDragons-Pins-2.0", true)
	local okH, core = pcall(LibStub.GetLibrary, LibStub, "HereBeDragons-2.0", true)
	if not (okP and okH and type(lib) == "table" and type(lib.worldmapPins) == "table"
		and type(lib.AddWorldMapIconMap) == "function" and type(lib.RemoveWorldMapIcon) == "function"
		and type(core) == "table" and type(core.mapData) == "table"
		and core.GetZoneCoordinatesFromWorldInstance and core.GetAzerothWorldMapCoordinatesFromWorld) then return end
	if lib.AddWorldMapIconMap == hookedAdd then return end
	hbd = core
	mirror = mirror or map.PinMirror({ name = "PolestarUIHereBeDragonsPins", pins = lib.worldmapPins, hbd = core, spot = spot, dress = dress })
	local function changed(_, _, icon) mirror.Changed(icon) end
	hooksecurefunc(lib, "AddWorldMapIconMap", changed)
	hooksecurefunc(lib, "RemoveWorldMapIcon", changed)
	if type(lib.AddWorldMapIconWorld) == "function" then hooksecurefunc(lib, "AddWorldMapIconWorld", changed) end
	if type(lib.RemoveAllWorldMapIcons) == "function" then hooksecurefunc(lib, "RemoveAllWorldMapIcons", mirror.Reindex) end
	hookedAdd = lib.AddWorldMapIconMap
	mirror.Reindex()
end
attach()
map.overlays[#map.overlays + 1] = attach
end)
