--@ title: Minimap
--@ roots: MinimapCluster, AddonCompartmentFrame, GameTimeFrame, TimeManagerClockButton
--@ stubs: stub_minimap.lua
-- The game's minimap restyled in place: square (the mask WHITE8X8), the round ring and the day/night ring faded, a 1px accent border; the addon buttons (two LibDBIcon ones, another addon's) in a dock under it, away from the zone text; the stock button on the backdrop and a map pin stay where they are. The header on our ground and hairline in Polestar's fonts, the tracking button's glyph, the calendar's day. GetMinimapShape answers SQUARE. Fixed (not rotating): no N.
assert(tostring(stub.minimapMask):find("WHITE8X8"), "not square: " .. tostring(stub.minimapMask))
assert(GetMinimapShape() == "SQUARE", "GetMinimapShape is not SQUARE")
assert(MinimapCompassTexture:GetAlpha() == 0 and MinimapCompassTextureUnderlay:GetAlpha() == 0, "the ring shows")
local dock = PolestarUIMinimapDock
assert(LibDBIcon10_Bagnon:GetParent() == dock and LibDBIcon10_Details:GetParent() == dock and WeakAurasMinimapButton:GetParent() == dock, "an addon button is not in the dock")
assert(ExpansionLandingPageMinimapButton:GetParent() == MinimapBackdrop and HandyNotesPin1:GetParent() == Minimap, "a stock button or a pin was taken")
assert(dock:GetPoint(1) == "TOP", "the dock is not under the map")
assert(PolestarUIMinimapEdge:IsShown() and PolestarUIMinimapEdge:GetParent() == Minimap, "no border on the map")
assert(MinimapCluster.ZoneTextButton.StateTexture:GetAlpha() == 0, "the header art shows")
assert(MinimapZoneText:GetFont() == (Polestar.Theme.FontSpec("small")), "the zone text is not Polestar's face")
local r, g, b = MinimapZoneText:GetTextColor()
assert(r == 1 and g == 0.82 and b == 0, "the zone text's colour is not the game's")
-- A button made after login (LibDBIcon's callback) joins the dock.
local late = stub.libDBIcon("Atlas", 90, 0.3, 0.8, 0.4)
assert(late:GetParent() == dock, "a late LibDBIcon button is not docked")
