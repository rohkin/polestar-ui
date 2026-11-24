-- Minimap (docs/windows/minimap.md): the game's own minimap in Polestar's
-- look, restyled in place, never rebuilt: MinimapCluster is an Edit Mode
-- system, so its size, place, header side and rotation stay the game's and
-- the player's (docs/CLIENT.md, rule 17). The map square (its mask, and
-- HybridMinimap's), the round compass ring, its underlay and the day/night
-- ring faded with SetAlpha, a 1px accent border and, on a frame of ours on
-- the Minimap, the zone name (bottom) and clock (top) inside the map and,
-- while the map turns, an "N". Edit Mode's screen clamp follows the visible
-- square, not the cluster's box (rule 17's exception). Addon buttons (LibDBIcon, Polestar's, other
-- addons' named buttons on the minimap) gathered in a flyout of ours, hidden
-- until the addons icon in the map's bottom-right corner opens it; every one
-- given back where it was when switched off.
-- The header: the stock zone text and clock faded (ours are on the map); the
-- tracking, calendar and mail indicator faded, with bare icons of ours in the
-- map's corners that do what theirs do (the game re-anchors its header on a
-- header side change, so a stock one is never moved); the addon compartment
-- faded with no stand-in (the flyout is the one list of addons); the
-- two menus in the chat's menu look (by tag). No key is written on a
-- stock frame and no stock frame is moved, sized, shown or hidden: what is
-- ours is kept in weak tables. The zone name is read through ns.Clean
-- (secret in combat: the last clean one stays). GetMinimapShape answers
-- "SQUARE" for the addons that place buttons on the edge; when another addon
-- defined it first, that addon owns the shape, and only the header is
-- restyled, in place (bare icons where the game puts them).

local ADDON, ns = ...
local Theme = Polestar.Theme
local W = Polestar.Widgets
local H = ns.HUD

local SQUARE = "Interface\\Buttons\\WHITE8X8"
-- The stock masks: Camelot's Minimap.lua (ModeData, both modes) and
-- Blizzard_HybridMinimap.xml (CircleMask).
local ROUND = "ui-hud-minimap-frame-generic-mask"
local HYBRID_ROUND = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local CLAMP = "CLAMPTOBLACKADDITIVE"
local CELL, GAP = 18, 2 -- a dock cell (a button scaled to fit) and the room between cells
local MENUS = { "MENU_MINIMAP_TRACKING", "MENU_ADDON_COMPARTMENT" }

local M = { noun = "minimap" }
local looks = setmetatable({}, { __mode = "k" }) -- stock frame -> its textures of ours
local stockFonts = setmetatable({}, { __mode = "k" }) -- font string -> { path, size, flags }
local taken = setmetatable({}, { __mode = "k" }) -- addon button -> where it was
local edge, north, dock, zoneLabel, clockLabel, addons
local clamp -- the screen clamp to the map's edges (below)
local corner = {} -- the corners' icons of ours: { b = ours, at = its corner, stock = function() -> the game's }
local INSET = 4 -- a corner icon's, the zone's and the clock's distance from the map's edge
local SHADOW = 10 -- the shadow's reach round the map (H.Shadow)
local zoneName = "" -- the last zone name read out of combat
local blocked, started

local say = ns.Say
local function on() return ns.Enabled("minimap") end
-- The map's own look (square, ring, border, N, dock): not while another addon owns the shape.
local function shaped() return on() and not blocked end

local function shape() return shaped() and "SQUARE" or "ROUND" end

local tex = ns.HUD.Tex

-- Four hairlines round region `r`, on frame `f` (over the map: OVERLAY).
local function hairline(f, r) return ns.Hairlines(f, r, function() return tex(f, "OVERLAY", 7) end) end

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
	-- The quest/task/dig-site blob rings are drawn on the round map's edge
	-- circle: inside a square they show as a hatched circle. 1 is the client's default.
	for _, k in ipairs({ "Quest", "Task", "Arch" }) do
		local set = Minimap["Set" .. k .. "BlobRingScalar"]
		if set then set(Minimap, sq and 0 or 1) end
	end
	local h = rawget(_G, "HybridMinimap")
	if h and h.CircleMask then h.CircleMask:SetTexture(sq and SQUARE or HYBRID_ROUND, CLAMP, CLAMP) end
end

-- The game sets its mask again when the rotation changes
-- (MinimapClusterMixin:UpdateMinimapConfig, on the same CVar callback as
-- ours, in no set order): ours goes on the next frame.
local function maskLater()
	C_Timer.After(0, function() if started then mask() clamp() end end)
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
	-- On a square inside the corner icons, the clock and the zone name, so it crosses none of them.
	local r = Minimap:GetWidth() / 2 - 26
	north:ClearAllPoints()
	north:SetPoint("CENTER", edge, "CENTER", x / m * r, y / m * r)
end

-- MinimapZoneTextButtonMixin:OnEnter and Minimap_SetTooltip: the zone, then
-- the subzone in its PvP colour and what that territory is (a faction's only
-- with a faction named). Secret in combat: the last clean zone name stays.
local PVP = {
	sanctuary = { 0.41, 0.8, 0.94, "SANCTUARY_TERRITORY" }, arena = { 1, 0.1, 0.1, "FREE_FOR_ALL_TERRITORY" },
	friendly = { 0.1, 1, 0.1, "FACTION_CONTROLLED_TERRITORY" }, hostile = { 1, 0.1, 0.1, "FACTION_CONTROLLED_TERRITORY" },
	contested = { 1, 0.7, 0, "CONTESTED_TERRITORY" }, combat = { 1, 0.1, 0.1, "COMBAT_ZONE" },
}
local function zoneTip(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	local zone = GetZoneText and ns.Clean(GetZoneText()) or zoneName
	local sub = GetSubZoneText and ns.Clean(GetSubZoneText()) or ""
	if sub == zone then sub = "" end
	local pvp, faction
	if C_PvP and C_PvP.GetZonePVPInfo then
		local p, _, f = C_PvP.GetZonePVPInfo()
		pvp, faction = ns.Clean(p), ns.Clean(f)
	end
	GameTooltip:AddLine(zone, 1, 1, 1)
	local c = PVP[pvp]
	if c and c[4] == "FACTION_CONTROLLED_TERRITORY" then
		if faction and faction ~= "" then
			GameTooltip:AddLine(sub, c[1], c[2], c[3])
			GameTooltip:AddLine(format(FACTION_CONTROLLED_TERRITORY, faction), c[1], c[2], c[3])
		end
	elseif c then
		GameTooltip:AddLine(sub, c[1], c[2], c[3])
		GameTooltip:AddLine(_G[c[4]], c[1], c[2], c[3])
	else
		local n = NORMAL_FONT_COLOR
		GameTooltip:AddLine(sub, n and n.r or 1, n and n.g or 0.82, n and n.b or 0)
	end
	GameTooltip:Show()
end

-- Our frame on the Minimap: the border and N (they scale and hide with it).
local function buildEdge()
	edge = Polestar.CreateFrameUnder("Frame", "PolestarUIMinimapEdge", Minimap)
	edge:SetAllPoints(Minimap)
	edge:SetFrameLevel(Minimap:GetFrameLevel() + 6)
	looks[edge] = { edges = hairline(edge, edge), shadow = H.Shadow(edge, edge, SHADOW) }
	north = W.Text(edge, "caption", "accent")
	north:SetText("N")
	north:SetJustifyH("CENTER")
	north:Hide()
	-- Between the bottom corners' icons (tracking, addons): a long name is cut, not run under them.
	zoneLabel = H.Text(edge, "small", "text")
	zoneLabel:SetJustifyH("CENTER")
	zoneLabel:SetWordWrap(false)
	zoneLabel:SetPoint("BOTTOMLEFT", edge, "BOTTOMLEFT", 24, INSET)
	zoneLabel:SetPoint("BOTTOMRIGHT", edge, "BOTTOMRIGHT", -24, INSET)
	-- The stock zone text's tooltip on ours; hover only, so a click still pings the map.
	local tip = CreateFrame("Frame", "PolestarUIMinimapZone", edge)
	tip:SetAllPoints(zoneLabel)
	tip:SetMouseMotionEnabled(true)
	tip:SetScript("OnEnter", zoneTip)
	tip:SetScript("OnLeave", function() GameTooltip:Hide() end)
	clockLabel = H.Text(edge, "number", "text")
	clockLabel:SetJustifyH("CENTER")
	clockLabel:SetPoint("TOP", edge, "TOP", 0, -INSET)
end

-- Edit Mode clamps the cluster to the screen by its box (UpdateClampOffsets:
-- SetClampRectInsets from the Selection's edges), which keeps the stock
-- header strip and the ring's margin on screen round our square. Ours: the
-- insets to the visible map's edges, so the box may leave the screen until
-- the map meets its edge, on every side (rule 17's exception, the user's
-- leave). Re-set after every UpdateClampOffsets and UpdateSystemSetting
-- (Size, Header Underneath and Rotate move the map inside the box), on the
-- rotation CVar and with each Apply. Off: the Selection's edges again, as
-- the game sets them. Another addon's shape: never touched.
-- After the game's UpdateClampOffsets its own insets are live, and a rect
-- read then would lay the cluster out clamped by them, pulling a box placed
-- off screen back on: there the last insets measured are set again unread.
local cut -- the last insets measured: { left, right, top, bottom }
function clamp(unread)
	if blocked then return end
	local c = MinimapCluster
	if unread then
		if cut and shaped() then c:SetClampRectInsets(unpack(cut)) end
		return
	end
	local r = shaped() and Minimap or rawget(c, "Selection")
	local cl = c:GetLeft()
	if not (r and cl and r:GetLeft()) then return end
	local k = r:GetEffectiveScale() / c:GetEffectiveScale() -- the map's units in the cluster's (the container's scale)
	cut = { r:GetLeft() * k - cl, r:GetRight() * k - c:GetRight(), r:GetTop() * k - c:GetTop(), r:GetBottom() * k - c:GetBottom() }
	c:SetClampRectInsets(unpack(cut))
end

-- The zone name (GetMinimapZoneText, secret in combat: the last clean one stays).
local function paintZone()
	if not zoneLabel then return end
	zoneName = ns.Clean(GetMinimapZoneText()) or zoneName
	zoneLabel:SetText(zoneName)
end

-- The clock as the game's shows it (GameTime_GetTime: the TimeManager's
-- local/realm and 24-hour CVars), while the game shows its clock button.
local function paintClock()
	if not clockLabel then return end
	local b = rawget(_G, "TimeManagerClockButton")
	local shown = b and b:IsShown() and GameTime_GetTime and true or false
	clockLabel:SetShown(shown)
	if shown then clockLabel:SetText(GameTime_GetTime(false)) end
end

-- A stock dropdown's menu (the tracking button's, the compartment's) from a
-- button of ours: its own generator, read, never called on the stock button.
local function openMenu(stock, owner)
	local gen = stock and rawget(stock, "menuGenerator")
	if gen and stock:IsEnabled() then MenuUtil.CreateContextMenu(owner, gen) end
end

local function gameTip(b, fill)
	b:SetScript("OnEnter", function(self) fill(self) GameTooltip:Show() end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- The calendar's pending invites as GameTimeFrame_Refresh counts them: a new
-- one lights it while the calendar is shut; a click or none left puts it out.
local invites = { seen = 0, on = false }
local function readInvites()
	local n = C_Calendar and C_Calendar.GetNumPendingInvites and C_Calendar.GetNumPendingInvites() or 0
	local cal = rawget(_G, "CalendarFrame")
	if n > invites.seen then
		if not (cal and cal:IsShown()) then invites.on, invites.seen = true, n end
	elseif n == 0 then
		invites.on, invites.seen = false, 0
	end
	if corner.glow then corner.glow:SetShown(invites.on) end
end

local function calendarTip(b)
	GameTooltip:SetOwner(b, "ANCHOR_BOTTOMLEFT")
	local cal, tm = rawget(_G, "CalendarFrame"), rawget(_G, "TimeManagerClockButton")
	if invites.on then
		GameTooltip:AddLine(GAMETIME_TOOLTIP_CALENDAR_INVITES)
		if cal and not cal:IsShown() then GameTooltip:AddLine(" ") GameTooltip:AddLine(GAMETIME_TOOLTIP_TOGGLE_CALENDAR) end
		return
	end
	if not tm or not tm:IsVisible() or (TimeManager_IsAlarmFiring and TimeManager_IsAlarmFiring()) then
		GameTooltip:AddLine(GameTime_GetGameTime(true), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
		GameTooltip:AddLine(" ")
	end
	GameTooltip:AddLine(GAMETIME_TOOLTIP_TOGGLE_CALENDAR)
end

-- GameTimeFrameMixin:OnClick: invites waiting, the calendar shown; else toggled.
local function calendarClick()
	if not GameTimeFrame:IsEnabled() then return end
	if invites.on then
		Calendar_LoadUI()
		if Calendar_Show then Calendar_Show() end
		invites.on, invites.seen = false, 0
		corner.glow:Hide()
	elseif not DISALLOW_FRAME_TOGGLING then
		ToggleCalendar()
	end
end

-- The map's corners, on our frame: the mail indicator top-left, the calendar
-- (today's day) top-right, the tracking button bottom-left (the addons icon
-- takes the fourth), bare icons shown while the game shows theirs, clear of
-- the clock (top) and zone name (bottom) between them. The game's stay where
-- it puts them, faded (paintHeader).
local function buildCorner()
	local track = W.IconButton(edge, "search", 16, TRACKING, function(self)
		openMenu(rawget(MinimapCluster, "Tracking") and MinimapCluster.Tracking.Button, self)
	end, 12)
	corner[1] = { b = track, at = "BOTTOMLEFT", stock = function() return rawget(MinimapCluster, "Tracking") end }
	local cal = CreateFrame("Button", nil, edge)
	cal:SetSize(18, 16)
	corner.hover = tex(cal, "HIGHLIGHT")
	corner.hover:SetAllPoints(cal)
	corner.glow = cal:CreateTexture(nil, "BACKGROUND")
	corner.glow:SetTexture(Theme.Media("glow"))
	corner.glow:SetSize(30, 30)
	corner.glow:SetPoint("CENTER", cal, "CENTER", 0, 0)
	corner.glow:Hide()
	corner.day = H.Text(cal, "number", "text")
	corner.day:SetJustifyH("CENTER")
	corner.day:SetPoint("CENTER", cal, "CENTER", 0, 0)
	cal:RegisterForClicks("AnyUp")
	cal:SetScript("OnClick", calendarClick)
	gameTip(cal, calendarTip)
	corner[2] = { b = cal, at = "TOPRIGHT", stock = function() return rawget(_G, "GameTimeFrame") end }
	local mail = CreateFrame("Button", nil, edge)
	mail:SetSize(18, 16)
	local icon = mail:CreateTexture(nil, "ARTWORK")
	icon:SetAtlas("ui-hud-minimap-mail-icon")
	icon:SetSize(18, 12)
	icon:SetPoint("CENTER", mail, "CENTER", 0, 0)
	-- MiniMapMailFrameMixin:OnEnter: the latest three senders.
	gameTip(mail, function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
		MinimapMailFrameUpdate()
	end)
	corner[3] = { b = mail, at = "TOPLEFT", stock = function()
		local i = rawget(MinimapCluster, "IndicatorFrame")
		return i and rawget(i, "MailFrame")
	end }
end

local function at(b, point)
	b:ClearAllPoints()
	b:SetPoint(point, edge, point, point:find("LEFT") and INSET or -INSET, point:find("TOP") and -INSET or INSET)
end

-- Each corner's icon, shown while the game shows its own.
local function placeCorner()
	for _, c in ipairs(corner) do
		local s = c.stock()
		local shown = s and s:IsShown() or false
		c.b:SetShown(shown)
		if shown then at(c.b, c.at) end
	end
end

local function paintEdge()
	edge:SetShown(shaped())
	placeCorner()
	if corner.glow then
		corner.glow:SetVertexColor(Theme.Accent())
		corner.hover:SetVertexColor(Theme.Wash("hover"))
	end
	H.PaintEdge(looks[edge].edges, true)
	H.PaintShadow(looks[edge].shadow, true, 1)
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
	local t = { parent = b:GetParent(), scale = b:GetScale(), level = b:GetFrameLevel(), points = {} }
	for i = 1, b:GetNumPoints() do t.points[i] = { b:GetPoint(i) } end
	taken[b] = t
	b:SetParent(dock)
	b:SetFrameLevel(dock:GetFrameLevel() + 2) -- over the flyout's ground
	-- Dragged round the edge (LibDBIcon, Polestar's), it would leave the row.
	b:RegisterForDrag()
end

local function giveBack()
	for b, t in pairs(taken) do
		b:SetParent(t.parent)
		b:SetScale(t.scale)
		b:SetFrameLevel(t.level)
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
		-- Map pin addons can put more frames here than the Lua stack holds as
		-- return values ("stack overflow"): the scan skipped, LibDBIcon's list still docks.
		local ok, kids = pcall(function() return { parent:GetChildren() } end)
		for _, c in ipairs(ok and kids or {}) do
			if addonButton(c) then take(c) end
		end
	end
end

-- The flyout: on the map, up from the addons icon in its bottom-right
-- corner, each button scaled to the cell; a column further left when the
-- map's height is full. Hidden until the icon opens it: a button parented to
-- it stays out of sight when its addon shows it again.
local PAD = 4
local function buildFlyout()
	dock = Polestar.CreateFrameUnder("Frame", "PolestarUIMinimapDock", Minimap)
	dock:SetFrameLevel(edge:GetFrameLevel() + 4)
	dock:EnableMouse(true) -- a click between its buttons does not ping the map
	dock:Hide()
	local fill = dock:CreateTexture(nil, "BACKGROUND")
	fill:SetTexture(Theme.Media("white"))
	fill:SetAllPoints(dock)
	looks[dock] = { fill = fill, edges = ns.Hairlines(dock, dock) }
	Polestar.CloseOnEscape("PolestarUIMinimapDock")
	addons = W.IconButton(edge, "plug", 16, ADDONS, function() dock:SetShown(not dock:IsShown()) end, 12)
	at(addons, "BOTTOMRIGHT")
	-- A click anywhere else closes it (the icon's own click toggles it).
	Polestar.RegisterEvent("GLOBAL_MOUSE_DOWN", function()
		if dock:IsShown() and not dock:IsMouseOver() and not addons:IsMouseOver() then dock:Hide() end
	end)
end

local function paintFlyout()
	local l = looks[dock]
	local r, g, b = Theme.Color("bg")
	l.fill:SetVertexColor(r, g, b, H.GroundAlpha())
	H.PaintEdge(l.edges, true)
end

local shownKey
local function layout()
	local list = {}
	for b in pairs(taken) do if b:IsShown() then list[#list + 1] = b end end
	table.sort(list, function(a, b) return a:GetName() < b:GetName() end)
	local room = Minimap:GetHeight() - addons:GetHeight() - 3 * INSET - 2 * PAD
	local per = math.max(1, math.floor((room + GAP) / (CELL + GAP)))
	local cols = math.ceil(#list / per)
	for i, b in ipairs(list) do
		local col, row = math.floor((i - 1) / per), (i - 1) % per
		b:SetScale(CELL / math.max(b:GetWidth(), b:GetHeight(), 1))
		local k = b:GetScale() -- offsets are in the button's own units
		b:ClearAllPoints()
		b:SetPoint("CENTER", dock, "BOTTOMRIGHT", (-PAD - col * (CELL + GAP) - CELL / 2) / k, (PAD + row * (CELL + GAP) + CELL / 2) / k)
	end
	dock:SetSize(math.max(cols * (CELL + GAP) - GAP, 1) + 2 * PAD, math.max(math.min(#list, per) * (CELL + GAP) - GAP, 1) + 2 * PAD)
	dock:ClearAllPoints()
	dock:SetPoint("BOTTOMRIGHT", addons, "TOPRIGHT", 0, INSET)
	addons:SetShown(#list > 0)
	if #list == 0 then dock:Hide() end
end

-- A button shown or hidden by its addon (no event says so): the flyout laid
-- again. From the edge's OnUpdate (the flyout is hidden while shut, and a
-- hidden frame runs none).
local function watch(elapsed)
	dock.wait = (dock.wait or 0) + elapsed
	if dock.wait < 0.5 then return end
	dock.wait = 0
	local names = {}
	for b in pairs(taken) do if b:IsShown() then names[#names + 1] = b:GetName() end end
	table.sort(names)
	local key = table.concat(names, ",")
	placeCorner()
	if key ~= shownKey then
		shownKey = key
		layout()
	end
end

local function paintDock()
	if shaped() then
		collect()
		shownKey = nil
		paintFlyout()
		layout()
	else
		giveBack()
		dock:Hide()
	end
end

-- A header button (ButtonStateBehaviorMixin: StateTexture, its atlas set
-- again on every state change, which keeps its alpha; AddTexture, the hover,
-- whose alpha the game writes, so emptied). With our map, all of it faded:
-- the corner's icons stand in for it. With another addon's shape, a bare icon
-- in place: the hover wash, and `glyph` (a Polestar glyph) where its art was the icon.
local function header(b, glyph, size)
	if not b then return end
	local l = looks[b]
	if not l then
		l = { hover = tex(b, "HIGHLIGHT"), add = rawget(b, "AddTexture") }
		l.atlas = l.add and l.add:GetAtlas()
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
	shown = shown and blocked
	l.hover:SetVertexColor(Theme.Wash("hover"))
	l.hover:SetShown(shown)
	if l.glyph then
		l.glyph:SetTexture(Theme.Media(Theme.Icon(glyph)))
		l.glyph:SetVertexColor(Theme.Color("icon"))
		l.glyph:SetShown(shown)
	end
	return l
end

-- The calendar's day: on the corner's icon, or with another addon's shape in
-- place of the stock calendar icon.
local function paintDay()
	local t = C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime and C_DateAndTime.GetCurrentCalendarTime()
	if corner.day then corner.day:SetText(t and t.monthDay or "") end
	local l = looks[GameTimeFrame]
	if not l then return end
	if not l.day then
		l.day = H.Text(GameTimeFrame, "number", "text") -- outlined: no ground behind it
		l.day:SetJustifyH("CENTER")
		l.day:SetPoint("CENTER", GameTimeFrame, "CENTER", 0, 0)
	end
	l.day:SetText(t and t.monthDay or "")
	l.day:SetShown(on() and blocked)
end

-- The clock (Blizzard_TimeManager, loaded on demand): its ticker's face,
-- faded while ours shows on the map.
local function clock()
	local t = rawget(_G, "TimeManagerClockTicker")
	face(t, "number", on())
	if t then t:SetAlpha(shaped() and 0 or 1) end
	paintClock()
end

-- With our map, the header's buttons are faded where the game puts them, and
-- their hover showed the game's tooltips over nothing (the zone's beside our
-- map): hover off while ours stand in (the corner icons, the zone name's
-- tooltip), back otherwise. Their clicks stay the game's (rule 17's exception).
local function hover(b)
	if b and b.SetMouseMotionEnabled then b:SetMouseMotionEnabled(not shaped()) end
end

local function paintHeader()
	local shown = on()
	-- The zone text button stays (its click opens the map), faded: ours is on the map.
	local zone = MinimapCluster.ZoneTextButton
	hover(zone)
	local ind = rawget(MinimapCluster, "IndicatorFrame")
	hover(ind and rawget(ind, "MailFrame"))
	local state = zone and rawget(zone, "StateTexture")
	if state then state:SetAlpha(shown and 0 or 1) end
	local zt = rawget(_G, "MinimapZoneText")
	face(zt, "small", shown)
	if zt then zt:SetAlpha(shaped() and 0 or 1) end
	paintZone()
	local t = rawget(MinimapCluster, "Tracking")
	if t then
		if t.Background then t.Background:SetAlpha(shown and 0 or 1) end
		header(t.Button, "search", 12)
		hover(t.Button)
	end
	local sq = shaped()
	if rawget(_G, "GameTimeFrame") then
		header(GameTimeFrame)
		hover(GameTimeFrame)
		paintDay()
		-- The invite flash: its alpha the game writes, so emptied.
		for _, name in ipairs({ "GameTimeCalendarInvitesTexture", "GameTimeCalendarInvitesGlow" }) do
			local r = rawget(_G, name)
			if r then
				looks[r] = looks[r] or { file = r:GetTexture() }
				if sq then r:SetTexture(nil) elseif looks[r].file then r:SetTexture(looks[r].file) end
			end
		end
	end
	local mail = rawget(_G, "MiniMapMailIcon")
	if mail then mail:SetAlpha(sq and 0 or 1) end
	local c = rawget(_G, "AddonCompartmentFrame")
	if c then
		header(c)
		hover(c)
		local text = rawget(c, "Text")
		face(text, "number", shown)
		if text then text:SetAlpha(sq and 0 or 1) end
	end
	clock()
end

-- The tracking and compartment menus (Blizzard_Menu, pooled): the chat's
-- menu look (ns.MenuLook; docs/CLIENT.md, rule 15).
local function menuLook(menu)
	if on() then ns.MenuLook(menu, 7) end
end

function M.Apply()
	if not started then return end
	mask()
	clamp()
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
	buildCorner()
	buildFlyout()
	edge:SetScript("OnUpdate", function(_, elapsed)
		placeNorth()
		watch(elapsed)
		if invites.on then corner.glow:SetAlpha(0.5 + 0.5 * math.cos(GetTime() * math.pi)) end
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
	-- Edit Mode resized the map: the flyout laid again.
	local function relayout() if shaped() then shownKey = nil layout() end end
	for _, e in ipairs({ "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED" }) do
		Polestar.RegisterEvent(e, paintZone)
	end
	C_Timer.NewTicker(1, paintClock)
	for _, e in ipairs({ "CALENDAR_UPDATE_PENDING_INVITES", "PLAYER_ENTERING_WORLD" }) do
		Polestar.RegisterEvent(e, readInvites)
	end
	EventRegistry:RegisterCallback("EditMode.Exit", relayout, M)
	if MinimapCluster.UpdateClampOffsets then hooksecurefunc(MinimapCluster, "UpdateClampOffsets", function() clamp(true) end) end
	if MinimapCluster.UpdateSystemSetting then hooksecurefunc(MinimapCluster, "UpdateSystemSetting", function() clamp() end) end
	Polestar.RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", relayout)
	local lib = LibStub and LibStub("LibDBIcon-1.0", true)
	if lib and lib.RegisterCallback then
		lib.RegisterCallback(M, "LibDBIcon_IconCreated", function(_, b) if shaped() then take(b) relayout() end end)
	end
	for _, tag in ipairs(MENUS) do
		Menu.ModifyMenu(tag, function(_, root) root:AddMenuAcquiredCallback(menuLook) end)
	end
	if rawget(_G, "GameTimeFrame") then C_Timer.NewTicker(30, paintDay) end
	Theme.OnChanged(function() if on() then M.Apply() end end, true)
	M.Apply()
end

ns.Module("minimap", M)
