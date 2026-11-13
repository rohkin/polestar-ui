-- The game's minimap as the client builds it on Forever (Blizzard_Minimap:
-- Mainline/Minimap.xml with Camelot's overrides, Camelot/Diel.lua,
-- GameTimeFrameTemplate.xml, AddonCompartment.xml, Blizzard_TimeManager's
-- clock): MinimapCluster (an Edit Mode system) holding the header (zone text
-- button, tracking, mail indicator), MinimapContainer with the Minimap, its
-- backdrop's compass ring and underlay, the day/night ring; the calendar,
-- addon compartment and clock beside the header. Colour textures and
-- Polestar's ring and disc glyphs stand in for the client's atlases; the
-- map's ground is masked by whatever Minimap:SetMaskTexture was given
-- (the game's round mask drawn as a disc, WHITE8X8 square). Every stock frame
-- is guarded (stub_editmode.lua). Also: LibDBIcon with two buttons, another
-- addon's named button, a map pin, a stock button on the backdrop, new mail
-- and its senders, pending calendar invites, the tracking and compartment
-- menus by their generators (opened as context menus), the
-- rotation CVar and its game callback, the player's facing, and Edit Mode's
-- minimap settings (header underneath, size).

require("stub_editmode")

local DISC = "Interface\\AddOns\\Polestar\\Media\\UI\\circle"
local RING = "Interface\\AddOns\\Polestar\\Media\\UI\\skin-ring"
local CALLS = stub.SYSTEM_CALLS

local function art(f, layer, r, g, b, a, sub)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetColorTexture(r, g, b, a or 1)
	return t
end
local function glyph(f, layer, file, r, g, b, sub)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetTexture(file)
	t:SetVertexColor(r, g, b, 1)
	return t
end
local function text(f, name, s, size, flags, r, g, b)
	local fs = f:CreateFontString(name, "OVERLAY")
	fs:SetFont(STANDARD_TEXT_FONT, size, flags or "")
	fs:SetTextColor(r or 1, g or 1, b or 1)
	fs:SetText(s)
	return fs
end
local function secure(...) for _, n in ipairs({ ... }) do stub.secureNames[n] = true end end

Enum = Enum or {}
Enum.EditModeMinimapSetting = { HeaderUnderneath = 0, RotateMinimap = 1, Size = 2, IconScale = 3 }
stub.cvars.rotateMinimap = "0"
stub.minimapSettings = { [0] = false }
stub.facing = 0
function GetPlayerFacing() return stub.facing end
-- The zone name (secret in combat: stub.SECRET) and the clock (GameTimeUtil.lua, by the TimeManager CVars).
stub.zone = "Goldshire"
function GetMinimapZoneText() return stub.zone end
stub.clock = "21:40"
function GameTime_GetTime() return stub.clock end
C_DateAndTime = C_DateAndTime or {}
C_DateAndTime.GetCurrentCalendarTime = C_DateAndTime.GetCurrentCalendarTime or function() return { monthDay = 13, month = 11, year = 2026 } end

local cluster = CreateFrame("Frame", "MinimapCluster", UIParent)
cluster:SetSize(256, 256)
cluster:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
cluster:SetFrameStrata("LOW")
function cluster.GetSettingValueBool(_, setting) return stub.minimapSettings[setting] == true end

-- The header: the zone text button (its state art and hover), the tracking
-- button left of it, the mail indicator under it.
local zone = CreateFrame("Button", nil, cluster)
cluster.ZoneTextButton = zone
zone:SetSize(152, 23)
zone:SetPoint("TOP", cluster, "TOP", 10, 0)
zone:SetFrameLevel(10)
zone.StateTexture = art(zone, "BACKGROUND", 0.32, 0.22, 0.1, 0.95)
zone.StateTexture:SetAllPoints(zone)
zone.AddTexture = art(zone, "BACKGROUND", 1, 1, 1, 0.1)
zone.AddTexture:SetAllPoints(zone)
zone.AddTexture:SetAtlas("ui-hud-minimap-header-button")
zone.AddTexture:Hide()
local zoneText = text(zone, "MinimapZoneText", "Goldshire", 10, "", 1, 0.82, 0)
zoneText:SetSize(110, 12)
zoneText:SetJustifyH("LEFT")
zoneText:SetPoint("LEFT", zone, "LEFT", 8, -1)

local tracking = CreateFrame("Frame", nil, cluster)
cluster.Tracking = tracking
tracking:SetSize(17, 17)
tracking:SetPoint("RIGHT", zone, "LEFT", 0, 0)
tracking.Background = art(tracking, "BACKGROUND", 0.32, 0.22, 0.1, 0.95)
tracking.Background:SetAllPoints(tracking)
local track = CreateFrame("Button", nil, tracking)
tracking.Button = track
track:SetSize(23, 23)
track:SetPoint("CENTER", tracking, "CENTER", 0, 0)
track.StateTexture = glyph(track, "ARTWORK", DISC, 0.75, 0.6, 0.3)
track.StateTexture:SetAllPoints(track)
track.AddTexture = art(track, "ARTWORK", 1, 1, 1, 0.1)
track.AddTexture:SetAtlas("ui-hud-minimap-tracking-button")
track.AddTexture:Hide()

local indicator = CreateFrame("Frame", nil, cluster)
cluster.IndicatorFrame = indicator
indicator:SetSize(32, 24)
indicator:SetPoint("TOPLEFT", zone, "BOTTOMLEFT", 0, 0)
local mail = CreateFrame("Frame", nil, indicator)
indicator.MailFrame = mail
mail:SetSize(32, 24)
mail:SetPoint("TOPLEFT", indicator, "TOPLEFT", 0, 0)
mail.MailIcon = art(mail, "ARTWORK", 0.85, 0.8, 0.65, 1)
mail.MailIcon:SetSize(18, 13)
mail.MailIcon:SetPoint("CENTER", mail, "CENTER", 0, 0)
_G.MiniMapMailIcon = mail.MailIcon
mail:Hide()
-- New mail (UPDATE_PENDING_MAIL): the indicator shown; its tooltip the latest
-- three senders (MinimapMailFrameUpdate, FormatUnreadMailTooltip).
stub.mailSenders = {}
function stub.newMail(senders)
	stub.mailSenders = senders or {}
	mail:SetShown(senders ~= nil)
end
function MinimapMailFrameUpdate()
	GameTooltip:AddLine(#stub.mailSenders > 0 and "You have mail from:" or "You have unread mail")
	for _, n in ipairs(stub.mailSenders) do GameTooltip:AddLine(n) end
	GameTooltip:Show()
end

-- The map: its ground (fields, a road, the player's arrow), masked.
local container = CreateFrame("Frame", nil, cluster)
cluster.MinimapContainer = container
container:SetSize(215, 226)
container:SetPoint("TOP", cluster, "TOP", 10, -30)
Minimap:SetParent(container)
Minimap:ClearAllPoints()
Minimap:SetPoint("CENTER", container, "CENTER", 0, 0)
Minimap:SetSize(198, 198)
local mapMask = Minimap:CreateMaskTexture()
mapMask:SetAllPoints(Minimap)
mapMask:SetTexture(DISC)
local function ground(r, g, b, w, h, x, y)
	local t = art(Minimap, "BACKGROUND", r, g, b, 1)
	if w then t:SetSize(w, h) t:SetPoint("CENTER", Minimap, "CENTER", x, y) else t:SetAllPoints(Minimap) end
	t:AddMaskTexture(mapMask)
	return t
end
ground(0.27, 0.36, 0.2)
ground(0.2, 0.3, 0.42, 70, 60, -70, 72)
ground(0.5, 0.42, 0.28, 240, 10, 0, -20)
ground(0.5, 0.42, 0.28, 10, 240, 30, 0)
ground(0.95, 0.85, 0.3, 8, 8, 0, 0)
stub.minimapMask = "ui-hud-minimap-frame-generic-mask"
-- Any mask but WHITE8X8 is the game's round one.
function Minimap.SetMaskTexture(self, asset)
	stub.minimapMask = asset
	mapMask:SetTexture(tostring(asset):find("WHITE8X8") and asset or DISC)
end
local playerCoords = CreateFrame("Frame", nil, container)
container.PlayerCoords = playerCoords
playerCoords:SetSize(90, 10)
playerCoords:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, -18)
playerCoords:Hide()

local backdrop = CreateFrame("Frame", "MinimapBackdrop", Minimap)
backdrop:SetSize(215, 226)
backdrop:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
backdrop:SetFrameLevel(Minimap:GetFrameLevel() + 2)
local underlay = glyph(backdrop, "OVERLAY", RING, 0.12, 0.1, 0.08, 1)
_G.MinimapCompassTextureUnderlay = underlay
underlay:SetSize(208, 208)
underlay:SetPoint("CENTER", backdrop, "CENTER", 0, 0)
underlay:Hide()
local compass = glyph(backdrop, "OVERLAY", RING, 0.72, 0.58, 0.3, 2)
_G.MinimapCompassTexture = compass
compass:SetSize(212, 212)
compass:SetPoint("CENTER", Minimap, "CENTER", 0, 0)
-- A stock button on the backdrop (ExpansionLandingPageMinimapButton): never the dock's.
local landing = CreateFrame("Button", "ExpansionLandingPageMinimapButton", backdrop)
landing:SetSize(32, 32)
landing:SetPoint("TOPLEFT", backdrop, "TOPLEFT", -3, -150)
glyph(landing, "ARTWORK", DISC, 0.55, 0.35, 0.75):SetAllPoints(landing)

local diel = CreateFrame("Frame", nil, container)
cluster.DielFrame = diel
diel:SetSize(28, 28)
diel:SetPoint("CENTER", container, "CENTER", 55, 86)
diel:SetFrameLevel(5)
diel.Background = glyph(diel, "BACKGROUND", DISC, 0.95, 0.8, 0.35)
diel.Background:SetSize(20, 20)
diel.Background:SetPoint("CENTER", diel, "CENTER", 0, 0)
glyph(diel, "OVERLAY", RING, 0.72, 0.58, 0.3, 1):SetAllPoints(diel)

-- Beside the header: the calendar, the addon compartment (its count), the clock.
local function stateButton(name, w, h)
	local b = CreateFrame("Button", name, cluster)
	b:SetSize(w, h)
	b.StateTexture = art(b, "ARTWORK", 0.32, 0.22, 0.1, 0.95)
	b.StateTexture:SetAllPoints(b)
	b.AddTexture = art(b, "ARTWORK", 1, 1, 1, 0.1)
	b.AddTexture:SetAllPoints(b)
	b.AddTexture:SetAtlas("ui-hud-minimap-button")
	b.AddTexture:Hide()
	return b
end
local cal = stateButton("GameTimeFrame", 23, 23)
cal:SetPoint("TOPLEFT", zone, "TOPRIGHT", -4, 0)
local invites = art(cal, "ARTWORK", 1, 0.8, 0.2, 1)
_G.GameTimeCalendarInvitesTexture = invites
invites:Hide()
-- The calendar (GameTimeFrameMixin:OnClick): pending invites, the calendar toggled or shown.
stub.invites, stub.calendar = 0, {}
C_Calendar = C_Calendar or {}
C_Calendar.GetNumPendingInvites = function() return stub.invites end
function ToggleCalendar() table.insert(stub.calendar, "toggle") end
function Calendar_LoadUI() end
function Calendar_Show() table.insert(stub.calendar, "show") end
GAMETIME_TOOLTIP_TOGGLE_CALENDAR = "Click to show/hide the calendar."
GAMETIME_TOOLTIP_CALENDAR_INVITES = "You have pending calendar invites."
ADDONS, TRACKING = "AddOns", "Tracking"
-- A stock dropdown's menu (DropdownButtonMixin:SetupMenu keeps its
-- generator): opened as a context menu, its tag and entries kept.
function stub.dropdown(b, tag, entries)
	b.menuGenerator = function(_, root)
		root:SetTag(tag)
		for _, e in ipairs(entries) do root:CreateButton(e) end
	end
end
MenuUtil = MenuUtil or {}
function MenuUtil.CreateContextMenu(owner, gen)
	local m = { owner = owner, entries = {} }
	function m.SetTag(self, tag) self.tag = tag end
	function m.CreateButton(self, text) table.insert(self.entries, text) end
	gen(owner, m)
	stub.contextMenu = m
end
local comp = stateButton("AddonCompartmentFrame", 23, 22)
comp:SetPoint("TOPLEFT", cal, "BOTTOMLEFT", -1, 1)
comp.Text = text(comp, nil, "3", 10)
comp.Text:SetPoint("CENTER", comp, "CENTER", 0, 0)
comp.registeredAddons = { {}, {}, {} }
-- AddonCompartmentMixin: UpdateDisplay (on RegisterAddon) writes the count
-- and shows it; OnButtonStateChanged (hover, press, menu) sets the state
-- atlas again and shows the hover at its alpha.
function stub.compartmentAdd(data)
	table.insert(comp.registeredAddons, data or {})
	comp.Text:SetText(#comp.registeredAddons)
	comp:SetShown(#comp.registeredAddons > 0)
	comp.StateTexture:SetAtlas("ui-hud-minimap-addon-indicator")
	comp.AddTexture:SetShown(true)
	comp.AddTexture:SetAlpha(0.1)
end
local clock = CreateFrame("Button", "TimeManagerClockButton", cluster)
clock:SetSize(40, 16)
clock:SetPoint("RIGHT", zone, "RIGHT", -3, -1)
clock:SetFrameLevel(11)
text(clock, "TimeManagerClockTicker", "21:40", 12, "", 1, 1, 1):SetPoint("CENTER", clock, "CENTER", 3, 0)

stub.dropdown(track, "MENU_MINIMAP_TRACKING", { "Find Herbs", "Find Minerals" })
stub.dropdown(comp, "MENU_ADDON_COMPARTMENT", { "Bagnon", "Details", "Atlas" })

secure("MinimapCluster", "Minimap", "MinimapBackdrop", "ExpansionLandingPageMinimapButton", "GameTimeFrame",
	"AddonCompartmentFrame", "TimeManagerClockButton", "MinimapZoneText", "TimeManagerClockTicker")
for _, f in ipairs({ container, zone, tracking, track, indicator, mail, Minimap, backdrop, landing, diel, cal, comp, clock }) do
	stub.guard(f, CALLS)
end
-- The cluster: all of rule 17 but its clamp insets (the exception).
local clusterCalls = {}
for _, n in ipairs(CALLS) do if n ~= "SetClampRectInsets" then clusterCalls[#clusterCalls + 1] = n end end
stub.guard(cluster, clusterCalls)
stub.hookAllowed[cluster] = { UpdateClampOffsets = true, UpdateSystemSetting = true }
for _, r in ipairs({ zone.StateTexture, zone.AddTexture, zoneText, tracking.Background, track.StateTexture, track.AddTexture,
	underlay, compass, diel.Background, cal.StateTexture, cal.AddTexture, comp.StateTexture, comp.AddTexture, comp.Text, mail.MailIcon }) do
	stub.guard(r)
end

-- The game's rotation callback (MinimapClusterMixin:UpdateMinimapConfig):
-- its mask set again, the ring swapped for the pointer, the underlay shown.
CVarCallbackRegistry:RegisterCallback("rotateMinimap", function()
	local rotate = GetCVarBool("rotateMinimap")
	Minimap:SetMaskTexture("ui-hud-minimap-frame-generic-mask")
	compass:SetVertexColor(rotate and 0.85 or 0.72, rotate and 0.4 or 0.58, 0.3, compass:GetAlpha())
	underlay:SetShown(rotate)
end, cluster)

-- Edit Mode's hold on the cluster (EditModeSystemMixin): its Selection box
-- over it, and the screen clamp set from the Selection's edges
-- (UpdateClampOffsets), the game's widget call keeping the insets.
local sel = CreateFrame("Frame", nil, cluster)
cluster.Selection = sel
sel:SetAllPoints(cluster)
-- A rect read right after the game's insets replaced ours lays the cluster
-- out clamped by them (a box placed off screen pulled back on): from our
-- files, an error. (Before ours were ever set the game has read it already.)
local stockClamp, oursLive = false, false
local function fromUs(level)
	local info = debug.getinfo(level + 1, "S")
	return info and stub.addonSources[info.source] == "Polestar_UI"
end
function cluster.SetClampRectInsets(self, l, r, t, b)
	rawset(self, "clampInsets", { l, r, t, b })
	local us = fromUs(2)
	stockClamp = not us and oursLive
	oursLive = us
end
for _, name in ipairs({ "GetLeft", "GetRight", "GetTop", "GetBottom", "GetRect" }) do
	local base = cluster[name]
	cluster[name] = function(self, ...)
		if stockClamp and fromUs(2) then
			local msg = "Polestar: UI read MinimapCluster's rect under the game's clamp insets (" .. name .. ")"
			table.insert(stub.breaches, msg) -- raised again by the next stub.advance, should a handler catch it
			error(msg, 2)
		end
		return base(self, ...)
	end
end
function cluster.GetClampRectInsets(self) return unpack(self.clampInsets or { 0, 0, 0, 0 }) end
function cluster.UpdateClampOffsets(self)
	self:SetClampRectInsets(sel:GetLeft() - self:GetLeft(), sel:GetRight() - self:GetRight(), sel:GetTop() - self:GetTop(), sel:GetBottom() - self:GetBottom())
end
function cluster.UpdateSystemSetting(self, setting) end

-- Where the client lays them (the stub keeps no layout of its own; GetLeft
-- and the like answer these, each in the frame's own units): the cluster at
-- the screen's top-right, ResizeLayoutFrame's size round the container (256
-- at 100%), the map in the container 10 right of the cluster's centre and 30
-- from its header edge.
local function place()
	local s = container:GetScale()
	local w, h = 215 * s + 41, 226 * s + 30
	cluster:SetSize(w, h)
	sel:SetSize(w, h)
	rawset(cluster, "x", UIParent.width - w) rawset(cluster, "y", UIParent.height - h)
	sel.x, sel.y = cluster.x, cluster.y
	local cx = cluster.x + w / 2 + 10
	local cy = stub.minimapSettings[0] and cluster.y + 30 + 226 * s / 2 or cluster.y + h - 30 - 226 * s / 2
	rawset(Minimap, "x", cx / s - 99) rawset(Minimap, "y", cy / s - 99)
end
place()
cluster:UpdateClampOffsets()

-- Edit Mode's minimap settings, as MinimapClusterMixin applies them, then
-- UpdateSystemSetting for each (the game's, which our hook follows).
function stub.minimapEdit(o)
	if o.scale then container:SetScale(o.scale) end
	if o.headerUnderneath ~= nil then
		stub.minimapSettings[Enum.EditModeMinimapSetting.HeaderUnderneath] = o.headerUnderneath
		container:ClearAllPoints()
		zone:ClearAllPoints()
		indicator:ClearAllPoints()
		if o.headerUnderneath then
			local s = container:GetScale()
			container:SetPoint("BOTTOM", cluster, "BOTTOM", 10 / s, 30 / s)
			zone:SetPoint("BOTTOM", cluster, "BOTTOM", -1, 8)
			indicator:SetPoint("BOTTOMLEFT", zone, "TOPLEFT", 0, 0)
		else
			local s = container:GetScale()
			container:SetPoint("TOP", cluster, "TOP", 10 / s, -30 / s)
			zone:SetPoint("TOP", cluster, "TOP", 10, 0)
			indicator:SetPoint("TOPLEFT", zone, "BOTTOMLEFT", 0, 0)
		end
	end
	if o.rotate ~= nil then stub.setCVar("rotateMinimap", o.rotate and "1" or "0") end
	place()
	for _, k in ipairs({ "scale", "headerUnderneath", "rotate" }) do
		if o[k] ~= nil then cluster:UpdateSystemSetting(k) end
	end
	stub.exitEditMode()
end

-- HybridMinimap (loaded on demand indoors): its canvas's round mask.
function stub.loadHybridMinimap()
	local h = CreateFrame("Frame", "HybridMinimap", Minimap)
	h:SetAllPoints(Minimap)
	h:Hide()
	h.CircleMask = h:CreateMaskTexture()
	h.CircleMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
	function h.CircleMask.SetTexture(self, file, hw, vw) self.texture, self.wrap = file, { hw, vw } end
	stub.secureNames.HybridMinimap = true
	stub.guard(h, CALLS)
	stub.addonLoaded("Blizzard_HybridMinimap")
	return h
end

-- Addons' buttons on the minimap's edge: round, an icon in a ring.
local function addonButton(name, angle, r, g, b, size)
	local btn = CreateFrame("Button", name, Minimap)
	btn:SetSize(size or 31, size or 31)
	btn:SetFrameLevel(8)
	local a = math.rad(angle)
	btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * 104, math.sin(a) * 104)
	glyph(btn, "BACKGROUND", DISC, 0.08, 0.08, 0.1):SetAllPoints(btn)
	local icon = glyph(btn, "ARTWORK", DISC, r, g, b)
	icon:SetSize((size or 31) - 12, (size or 31) - 12)
	icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
	glyph(btn, "OVERLAY", RING, 0.72, 0.58, 0.3):SetAllPoints(btn)
	return btn
end

-- LibDBIcon-1.0 as minimap addons use it: its buttons by name, and the
-- callback it fires as it makes one.
local icons, order, created = {}, {}, {}
local lib = {}
function lib:GetButtonList() return order end
function lib:GetMinimapButton(name) return icons[name] end
function lib.RegisterCallback(owner, event, fn) created[#created + 1] = fn end
function stub.libDBIcon(name, angle, r, g, b)
	local btn = addonButton("LibDBIcon10_" .. name, angle, r, g, b)
	btn:RegisterForDrag("LeftButton")
	icons[name] = btn
	order[#order + 1] = name
	for _, fn in ipairs(created) do fn("LibDBIcon_IconCreated", btn, name) end
	return btn
end
function LibStub(major, silent)
	if major == "LibDBIcon-1.0" then return lib end
	if not silent then error("LibStub: no " .. tostring(major)) end
end
stub.libDBIcon("Bagnon", 200, 0.85, 0.55, 0.25)
stub.libDBIcon("Details", 160, 0.4, 0.65, 0.95)
-- Another addon's own button, and a map pin (HereBeDragons-style).
stub.otherButton = addonButton("WeakAurasMinimapButton", 300, 0.75, 0.3, 0.85, 28)
stub.pin = addonButton("HandyNotesPin1", 45, 1, 0.9, 0.2, 12)
