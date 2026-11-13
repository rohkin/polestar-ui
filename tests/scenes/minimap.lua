--@ title: Minimap
--@ roots: MinimapCluster, AddonCompartmentFrame, GameTimeFrame, TimeManagerClockButton
--@ stubs: stub_minimap.lua
-- The game's minimap restyled in place: square (the mask WHITE8X8), the round ring and the day/night ring faded, a 1px accent border; the zone name inside the map at its foot (between the bottom corners' icons) and the clock at its top (outlined HUD text), the stock zone text and clock faded; the addon buttons (two LibDBIcon ones, another addon's) gathered in a flyout of 18-unit cells, shut: only the addons icon in the map's bottom-right corner shows (opened in the panel beside it); the stock button on the backdrop and a map pin stay where they are. The mail indicator (with new mail) top-left, the calendar (today's day) top-right and the tracking button (its glyph) bottom-left as bare icons of ours in the map's corners, the game's faded where it puts them; the addon compartment faded with no stand-in, every region of it unseen after the game writes its count and hover again: the flyout is the one list of addons. In combat the zone name turns secret: the last one read stays. GetMinimapShape answers SQUARE. Fixed (not rotating): no N.
assert(tostring(stub.minimapMask):find("WHITE8X8"), "not square: " .. tostring(stub.minimapMask))
assert(GetMinimapShape() == "SQUARE", "GetMinimapShape is not SQUARE")
assert(MinimapCompassTexture:GetAlpha() == 0 and MinimapCompassTextureUnderlay:GetAlpha() == 0, "the ring shows")
local dock = PolestarUIMinimapDock
stub.newMail({ "Thrall", "Jaina" })
stub.advance(0.6)
assert(LibDBIcon10_Bagnon:GetParent() == dock and LibDBIcon10_Details:GetParent() == dock and WeakAurasMinimapButton:GetParent() == dock, "an addon button is not in the dock")
assert(ExpansionLandingPageMinimapButton:GetParent() == MinimapBackdrop and HandyNotesPin1:GetParent() == Minimap, "a stock button or a pin was taken")
assert(not dock:IsShown() and not LibDBIcon10_Bagnon:IsVisible(), "the flyout is open before a click")
-- An addon showing its button again (LibDBIcon does on every update) leaves it out of sight.
LibDBIcon10_Bagnon:Show()
stub.advance(0.6)
assert(not LibDBIcon10_Bagnon:IsVisible(), "a re-shown addon button shows with the flyout shut")
assert(math.abs(LibDBIcon10_Bagnon:GetWidth() * LibDBIcon10_Bagnon:GetScale() - 18) < 0.01, "a docked button is not 18 across")
local function label(s)
	for _, r in ipairs({ PolestarUIMinimapEdge:GetRegions() }) do if r:GetObjectType() == "FontString" and r:GetText() == s then return r end end
end
local zone, clock = label("Goldshire"), label("21:40")
assert(zone and zone:GetPoint(1) == "BOTTOMLEFT" and clock and clock:GetPoint(1) == "TOP" and clock:IsShown(), "no zone name or clock on the map")
assert(MinimapZoneText:GetAlpha() == 0 and TimeManagerClockTicker:GetAlpha() == 0, "the stock zone text or clock shows")
stub.zone = stub.secret("Elwynn Forest")
stub.fire("ZONE_CHANGED")
assert(zone:GetText() == "Goldshire", "a secret zone name was shown")
stub.zone = "Goldshire"
stub.fire("ZONE_CHANGED")
assert(PolestarUIMinimapEdge:IsShown() and PolestarUIMinimapEdge:GetParent() == Minimap, "no border on the map")
assert(MinimapCluster.ZoneTextButton.StateTexture:GetAlpha() == 0, "the header art shows")
assert(MinimapZoneText:GetFont() == (Polestar.Theme.FontSpec("small")), "the zone text is not Polestar's face")
local r, g, b = MinimapZoneText:GetTextColor()
assert(r == 1 and g == 0.82 and b == 0, "the zone text's colour is not the game's")
-- A button made after login (LibDBIcon's callback) joins the dock.
local late = stub.libDBIcon("Atlas", 90, 0.3, 0.8, 0.4)
assert(late:GetParent() == dock, "a late LibDBIcon button is not docked")
-- The corners: mail top-left, calendar top-right, tracking bottom-left, addons bottom-right; the game's faded.
local edge = PolestarUIMinimapEdge
local at = {}
for _, c in ipairs({ edge:GetChildren() }) do
	local p, rel, rp, x, y = c:GetPoint(1)
	if c:IsShown() and rel == edge and p == rp and math.abs(x) == 4 and math.abs(y) == 4 then at[p] = c end
end
local mail, cal, track, addons = at.TOPLEFT, at.TOPRIGHT, at.BOTTOMLEFT, at.BOTTOMRIGHT
assert(mail and cal and track and addons, "an icon is missing from the map's corners")
assert(MinimapCluster.Tracking.Button.StateTexture:GetAlpha() == 0 and GameTimeFrame.StateTexture:GetAlpha() == 0 and MiniMapMailIcon:GetAlpha() == 0, "a stock header icon shows")
-- The game's update path (RegisterAddon -> UpdateDisplay, OnButtonStateChanged) leaves every region of it unseen.
stub.compartmentAdd()
stub.advance(0.6)
local comp = AddonCompartmentFrame
assert(comp:IsShown() and tostring(comp.Text:GetText()) == "4", "the stub's compartment did not update")
for _, r in ipairs({ comp:GetRegions() }) do
	assert(not r:IsShown() or r:GetAlpha() == 0 or (r == comp.AddTexture and r:GetTexture() == nil), "a region of the stock compartment shows")
end
stub.RunScript(track, "OnClick")
assert(stub.contextMenu.owner == track and stub.contextMenu.tag == "MENU_MINIMAP_TRACKING" and stub.contextMenu.entries[1] == "Find Herbs", "the corner's tracking button does not open the tracking menu")
stub.RunScript(cal, "OnClick")
assert(stub.calendar[1] == "toggle", "the corner's calendar does not toggle the calendar")
stub.invites = 2
stub.fire("CALENDAR_UPDATE_PENDING_INVITES")
stub.RunScript(cal, "OnEnter")
assert(GameTooltip.lines[1] == GAMETIME_TOOLTIP_CALENDAR_INVITES, "no pending invite line on the calendar")
stub.RunScript(cal, "OnClick")
assert(stub.calendar[2] == "show", "a pending invite does not show the calendar")
stub.RunScript(mail, "OnEnter")
assert(GameTooltip.lines[2] == "Thrall" and GameTooltip.lines[3] == "Jaina", "the mail tooltip does not list its senders")
stub.newMail(nil)
stub.advance(0.6)
assert(not mail:IsShown(), "the mail icon stays with no new mail")
stub.newMail({ "Thrall", "Jaina" })
stub.advance(0.6)
-- The addons icon opens the flyout and shuts it again; Escape's list and a click elsewhere shut it.
stub.RunScript(addons, "OnClick")
assert(dock:IsShown() and LibDBIcon10_Bagnon:IsVisible(), "the addons icon does not open the flyout")
stub.RunScript(addons, "OnClick")
assert(not dock:IsShown(), "a second click does not shut the flyout")
local listed = false
for _, n in ipairs(UISpecialFrames) do if n == "PolestarUIMinimapDock" then listed = true end end
assert(listed, "Escape does not shut the flyout")
stub.RunScript(addons, "OnClick")
stub.fire("GLOBAL_MOUSE_DOWN", "LeftButton")
assert(not dock:IsShown(), "a click elsewhere does not shut the flyout")
-- No cell of ours for the compartment: the flyout holds only addon buttons.
for _, c in ipairs({ dock:GetChildren() }) do
	assert(not c:IsShown() or c:GetName() ~= nil, "a compartment cell in the flyout")
end
--@ panel
--@ roots: MinimapCluster, AddonCompartmentFrame, GameTimeFrame, TimeManagerClockButton
--@ stubs: stub_minimap.lua
-- The addons icon clicked: the flyout open on the map, up from the icon, in Polestar's ground and hairline, the addon buttons only (no compartment count).
stub.advance(0.6)
local addons
for _, c in ipairs({ PolestarUIMinimapEdge:GetChildren() }) do
	local p, _, _, x, y = c:GetPoint(1)
	if c:IsShown() and p == "BOTTOMRIGHT" and x == -4 and y == 4 then addons = c end
end
stub.RunScript(addons, "OnClick")
assert(PolestarUIMinimapDock:IsShown() and WeakAurasMinimapButton:IsVisible(), "the flyout does not open")
