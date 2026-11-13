-- Minimap (docs/windows/minimap.md): the game's own minimap in Polestar's
-- look, restyled in place, never rebuilt: MinimapCluster is an Edit Mode
-- system, so its size, place, header side and rotation stay the game's and
-- the player's (docs/CLIENT.md, rule 17). The map square (its mask, and
-- HybridMinimap's), the round compass ring, its underlay and the day/night
-- ring faded with SetAlpha, a 1px accent border and, while the map turns, an
-- "N" of ours on a frame of ours on the Minimap. Addon buttons (LibDBIcon,
-- Polestar's, other addons' named buttons on the minimap) gathered in a dock
-- of ours outside the minimap's edge, on the side away from the zone text;
-- every one given back where it was when switched off. The header (zone
-- text, clock, calendar, tracking, addon compartment) on our ground and
-- hairline, its art faded, its fonts Polestar's; its clicks and menus stay the
-- game's, the two menus in the chat's menu look (by tag). No key is written
-- on a stock frame and no stock frame is moved, sized, shown or hidden: what
-- is ours is kept in weak tables. The zone and coordinate texts are never read
-- (secret in combat). GetMinimapShape answers "SQUARE" for the addons that
-- place buttons on the edge; when another addon defined it first, that addon
-- owns the shape, and only the header is restyled.

local ADDON, ns = ...
local Theme = Polestar.Theme
local W = Polestar.Widgets

local SQUARE = "Interface\\Buttons\\WHITE8X8"
-- The stock masks: Camelot's Minimap.lua (ModeData, both modes) and
-- Blizzard_HybridMinimap.xml (CircleMask).
local ROUND = "ui-hud-minimap-frame-generic-mask"
local HYBRID_ROUND = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local CLAMP = "CLAMPTOBLACKADDITIVE"
local EDGES = { { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }
local CELL, GAP = 32, 2 -- a dock cell (a LibDBIcon button is 31 square) and the room between cells
local MENUS = { "MENU_MINIMAP_TRACKING", "MENU_ADDON_COMPARTMENT" }

local M = { noun = "minimap" }
local looks = setmetatable({}, { __mode = "k" }) -- stock frame -> its textures of ours
local stockFonts = setmetatable({}, { __mode = "k" }) -- font string -> { path, size, flags }
local taken = setmetatable({}, { __mode = "k" }) -- addon button -> where it was
local edge, north, dock
local blocked, started

local function say(msg) print("|cffe6ba66Polestar: UI|r " .. msg) end
local function on() return ns.Enabled("minimap") end
-- The map's own look (square, ring, border, N, dock): not while another addon owns the shape.
local function shaped() return on() and not blocked end

local function shape() return shaped() and "SQUARE" or "ROUND" end

local function tex(f, layer, sub)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetTexture(Theme.Media("white"))
	return t
end

-- Four hairlines round region `r`, on frame `f`.
local function hairline(f, r)
	local e = {}
	for i, p in ipairs(EDGES) do
		local t = tex(f, "OVERLAY", 7)
		t:SetPoint(p[1], r, p[1], 0, 0)
		t:SetPoint(p[2], r, p[2], 0, 0)
		e[i] = t
	end
	return e
end

local function paintLine(e, shown, r, g, b, a)
	local px = Theme.Pixel(e[1]:GetParent())
	for i, t in ipairs(e) do
		t:SetShown(shown)
		t:SetVertexColor(r, g, b, a)
		if i <= 2 then t:SetHeight(px) else t:SetWidth(px) end
	end
end

-- A font string in Polestar's face (role) at the game's size and flags; off, the game's face.
local function face(fs, role, shown)
	if not fs then return end
	stockFonts[fs] = stockFonts[fs] or { fs:GetFont() }
	local s = stockFonts[fs]
	if not s[1] then return end
	Theme.SetFace(fs, shown and (Theme.FontSpec(role)) or s[1], s[2], s[3] or "")
end

-- The mask: square, or the game's again. HybridMinimap (indoor maps, loaded
-- on demand) masks its own canvas. Another addon's shape is left alone.
local function mask()
	if blocked then return end
	local sq = shaped()
	Minimap:SetMaskTexture(sq and SQUARE or ROUND)
	local h = rawget(_G, "HybridMinimap")
	if h and h.CircleMask then h.CircleMask:SetTexture(sq and SQUARE or HYBRID_ROUND, CLAMP, CLAMP) end
end

-- The game sets its mask again when the rotation changes
-- (MinimapClusterMixin:UpdateMinimapConfig, on the same CVar callback as
-- ours, in no set order): ours goes on the next frame.
local function maskLater()
	C_Timer.After(0, function() if started then mask() end end)
end

-- The ring (MinimapCompassTexture, swapped between its two atlases by the
-- game, which keeps the alpha), its underlay and the day/night ring (Camelot's Diel.lua).
local function ring(a)
	MinimapCompassTexture:SetAlpha(a)
	MinimapCompassTextureUnderlay:SetAlpha(a)
	local d = rawget(MinimapCluster, "DielFrame")
	if d then for _, r in ipairs({ d:GetRegions() }) do r:SetAlpha(a) end end
end

-- North on the square's edge while the map turns with the player
-- (GetPlayerFacing: radians, counter-clockwise from north; nil where the
-- game keeps it, in instances).
local lastFacing
local function placeNorth()
	local f = GetCVarBool("rotateMinimap") and GetPlayerFacing and GetPlayerFacing()
	if not f or (issecretvalue and issecretvalue(f)) then
		north:Hide()
		lastFacing = nil
		return
	end
	north:Show()
	if f == lastFacing then return end
	lastFacing = f
	local x, y = math.sin(f), math.cos(f)
	local m = math.max(math.abs(x), math.abs(y))
	local r = Minimap:GetWidth() / 2 - 8
	north:ClearAllPoints()
	north:SetPoint("CENTER", edge, "CENTER", x / m * r, y / m * r)
end

-- Our frame on the Minimap: the border and N (they scale and hide with it).
local function buildEdge()
	edge = Polestar.CreateFrameUnder("Frame", "PolestarUIMinimapEdge", Minimap)
	edge:SetAllPoints(Minimap)
	edge:SetFrameLevel(Minimap:GetFrameLevel() + 6)
	looks[edge] = { edges = hairline(edge, edge) }
	north = W.Text(edge, "caption", "accent")
	north:SetText("N")
	north:SetJustifyH("CENTER")
	north:Hide()
end

local function paintEdge()
	edge:SetShown(shaped())
	local r, g, b = Theme.Accent()
	paintLine(looks[edge].edges, true, r, g, b, 1)
	lastFacing = nil
	if edge:IsShown() then placeNorth() end
end

-- The dock: addon buttons, never a stock one. A Blizzard frame's global is
-- secure (issecurevariable); a protected button is left where it is, as are
-- map pins (HereBeDragons and the like name theirs so) and anything not
-- button-sized.
local function addonButton(c)
	if c == edge or c == dock or taken[c] then return false end
	local name = c:GetName()
	if not name or c:GetObjectType() ~= "Button" or c:IsProtected() then return false end
	if issecurevariable(name) or name:find("^PolestarUI") or name:find("[Pp]in") then return false end
	local w, h = c:GetSize()
	return w >= 14 and w <= 40 and h >= 14 and h <= 40
end

local function take(b)
	if not b or taken[b] then return end
	local t = { parent = b:GetParent(), points = {} }
	for i = 1, b:GetNumPoints() do t.points[i] = { b:GetPoint(i) } end
	taken[b] = t
	b:SetParent(dock)
	-- Dragged round the edge (LibDBIcon, Polestar's), it would leave the row.
	b:RegisterForDrag()
end

local function giveBack()
	for b, t in pairs(taken) do
		b:SetParent(t.parent)
		b:ClearAllPoints()
		for _, p in ipairs(t.points) do b:SetPoint(unpack(p)) end
		b:RegisterForDrag("LeftButton")
		taken[b] = nil
	end
end

local function collect()
	local lib = LibStub and LibStub("LibDBIcon-1.0", true)
	if lib and lib.GetButtonList then
		for _, name in ipairs(lib:GetButtonList()) do take(lib:GetMinimapButton(name)) end
	end
	take(rawget(_G, "PolestarMinimapButton"))
	for _, parent in ipairs({ Minimap, MinimapBackdrop }) do
		for _, c in ipairs({ parent:GetChildren() }) do
			if addonButton(c) then take(c) end
		end
	end
end

-- The side away from the zone text: below the map when the header is on top
-- (under the player's coordinates when the game shows them), above it when
-- the header is underneath (Edit Mode's setting, read from the cluster).
local function headerUnderneath()
	local s = Enum and Enum.EditModeMinimapSetting
	return s and MinimapCluster.GetSettingValueBool and MinimapCluster:GetSettingValueBool(s.HeaderUnderneath) or false
end

local shownKey
local function layout()
	local list = {}
	for b in pairs(taken) do if b:IsShown() then list[#list + 1] = b end end
	table.sort(list, function(a, b) return a:GetName() < b:GetName() end)
	local per = math.max(1, math.floor((Minimap:GetWidth() + GAP) / (CELL + GAP)))
	local rows = math.ceil(#list / per)
	local width = math.min(#list, per) * (CELL + GAP) - GAP
	for i, b in ipairs(list) do
		local col, row = (i - 1) % per, math.floor((i - 1) / per)
		b:ClearAllPoints()
		b:SetPoint("CENTER", dock, "TOPLEFT", col * (CELL + GAP) + CELL / 2, -row * (CELL + GAP) - CELL / 2)
	end
	dock:SetSize(math.max(width, 1), math.max(rows * (CELL + GAP) - GAP, 1))
	dock:ClearAllPoints()
	if headerUnderneath() then
		dock:SetPoint("BOTTOM", Minimap, "TOP", 0, 6)
	else
		local coords = MinimapCluster.MinimapContainer and rawget(MinimapCluster.MinimapContainer, "PlayerCoords")
		dock:SetPoint("TOP", Minimap, "BOTTOM", 0, coords and coords:IsShown() and -22 or -6)
	end
	dock:SetShown(#list > 0)
end

-- A button shown or hidden by its addon (no event says so): the row redrawn.
-- From the edge's OnUpdate (the dock hides while empty, and a hidden frame
-- runs none).
local function watch(elapsed)
	dock.wait = (dock.wait or 0) + elapsed
	if dock.wait < 0.5 then return end
	dock.wait = 0
	local names = {}
	for b in pairs(taken) do if b:IsShown() then names[#names + 1] = b:GetName() end end
	table.sort(names)
	local key = table.concat(names, ",")
	if key ~= shownKey then
		shownKey = key
		layout()
	end
end

local function paintDock()
	if shaped() then
		collect()
		shownKey = nil
		layout()
	else
		giveBack()
		dock:Hide()
	end
end

-- A header button (ButtonStateBehaviorMixin: StateTexture, its atlas set
-- again on every state change, which keeps its alpha; AddTexture, the hover,
-- whose alpha the game writes, so emptied): our ground and hairline round it,
-- the hover wash, and `glyph` (a Polestar glyph) where its art was the icon.
local function header(b, glyph, size)
	if not b then return end
	local l = looks[b]
	if not l then
		l = { fill = tex(b, "BACKGROUND", -8), hover = tex(b, "HIGHLIGHT"), add = rawget(b, "AddTexture") }
		l.atlas = l.add and l.add:GetAtlas()
		l.fill:SetAllPoints(b)
		l.edges = hairline(b, l.fill)
		l.hover:SetAllPoints(b)
		if glyph then
			l.glyph = b:CreateTexture(nil, "ARTWORK", nil, 7)
			l.glyph:SetSize(size, size)
			l.glyph:SetPoint("CENTER", b, "CENTER", 0, 0)
		end
		looks[b] = l
	end
	local shown = on()
	local state = rawget(b, "StateTexture")
	if state then state:SetAlpha(shown and 0 or 1) end
	if l.add then
		if shown then l.add:SetTexture(nil) elseif l.atlas then l.add:SetAtlas(l.atlas, true) end
	end
	local r, g, bl = Theme.Color("bg")
	l.fill:SetVertexColor(r, g, bl, Theme.GroundAlpha())
	l.fill:SetShown(shown)
	paintLine(l.edges, shown, Theme.Color("border"))
	l.hover:SetVertexColor(Theme.Wash("hover"))
	l.hover:SetShown(shown)
	if l.glyph then
		l.glyph:SetTexture(Theme.Media(Theme.Icon(glyph)))
		l.glyph:SetVertexColor(Theme.Color("icon"))
		l.glyph:SetShown(shown)
	end
	return l
end

-- The calendar's day, in place of the stock calendar icon.
local function paintDay()
	local l = looks[GameTimeFrame]
	if not l then return end
	if not l.day then
		l.day = W.Text(GameTimeFrame, "number", "text")
		l.day:SetJustifyH("CENTER")
		l.day:SetPoint("CENTER", GameTimeFrame, "CENTER", 0, 0)
	end
	local t = C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime and C_DateAndTime.GetCurrentCalendarTime()
	l.day:SetText(t and t.monthDay or "")
	l.day:SetShown(on())
end

-- The clock (Blizzard_TimeManager, loaded on demand): its ticker's face.
local function clock()
	face(rawget(_G, "TimeManagerClockTicker"), "number", on())
end

local function paintHeader()
	local shown = on()
	header(MinimapCluster.ZoneTextButton)
	face(rawget(_G, "MinimapZoneText"), "small", shown)
	local t = rawget(MinimapCluster, "Tracking")
	if t then
		if t.Background then t.Background:SetAlpha(shown and 0 or 1) end
		header(t.Button, "search", 12)
	end
	if rawget(_G, "GameTimeFrame") then
		header(GameTimeFrame)
		paintDay()
	end
	local c = rawget(_G, "AddonCompartmentFrame")
	if c then
		header(c)
		face(rawget(c, "Text"), "number", shown)
	end
	clock()
end

-- The tracking and compartment menus (Blizzard_Menu, pooled): the chat's
-- menu look through the menu's own compositor (docs/CLIENT.md, rule 15).
local function menuLook(menu)
	if not on() then return end
	for _, r in ipairs({ menu:GetRegions() }) do r:SetAlpha(0) end
	local function piece(layer, sub, r, g, b, a)
		local t = menu:AttachTexture()
		t:SetTexture(Theme.Media("white"))
		t:SetDrawLayer(layer, sub)
		t:SetVertexColor(r, g, b, a)
		return t
	end
	local r, g, b = Theme.Color("bg")
	local fill = piece("BACKGROUND", -8, r, g, b, Theme.GroundAlpha())
	fill:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, 0)
	fill:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", 0, 7)
	local px = Theme.Pixel(menu)
	for i, e in ipairs(EDGES) do
		local t = piece("BORDER", 7, Theme.Color("border"))
		t:SetPoint(e[1], fill, e[1], 0, 0)
		t:SetPoint(e[2], fill, e[2], 0, 0)
		if i <= 2 then t:SetHeight(px) else t:SetWidth(px) end
	end
end

function M.Apply()
	if not started then return end
	mask()
	if not blocked then ring(shaped() and 0 or 1) end
	paintEdge()
	paintDock()
	paintHeader()
end

function M.Enable()
	if not rawget(_G, "MinimapCluster") then return end
	started = true
	if GetMinimapShape then
		blocked = true
		say("minimap: another addon shapes the minimap; only its header is restyled.")
	else
		GetMinimapShape = shape
	end
	buildEdge()
	dock = Polestar.CreateFrameUnder("Frame", "PolestarUIMinimapDock", Minimap)
	edge:SetScript("OnUpdate", function(_, elapsed)
		placeNorth()
		watch(elapsed)
	end)
	CVarCallbackRegistry:RegisterCallback("rotateMinimap", maskLater, M)
	Polestar.RegisterEvent("PLAYER_ENTERING_WORLD", function()
		maskLater()
		-- Addons make their minimap buttons at login or after it.
		C_Timer.After(1, function() if shaped() then paintDock() end end)
	end)
	Polestar.RegisterEvent("ADDON_LOADED", function(_, name)
		if name == "Blizzard_HybridMinimap" then mask()
		elseif name == "Blizzard_TimeManager" then clock() end
	end)
	-- Edit Mode moved the header: the dock to the other side.
	local function relayout() if shaped() then shownKey = nil layout() end end
	EventRegistry:RegisterCallback("EditMode.Exit", relayout, M)
	Polestar.RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", relayout)
	local lib = LibStub and LibStub("LibDBIcon-1.0", true)
	if lib and lib.RegisterCallback then
		lib.RegisterCallback(M, "LibDBIcon_IconCreated", function(_, b) if shaped() then take(b) relayout() end end)
	end
	for _, tag in ipairs(MENUS) do
		Menu.ModifyMenu(tag, function(_, root) root:AddMenuAcquiredCallback(menuLook) end)
	end
	if rawget(_G, "GameTimeFrame") then C_Timer.NewTicker(30, paintDay) end
	Theme.OnChanged(function() if on() then M.Apply() end end)
	M.Apply()
end

ns.Module("minimap", M)
