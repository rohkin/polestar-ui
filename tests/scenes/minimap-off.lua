--@ title: Minimap: off
--@ roots: MinimapCluster, AddonCompartmentFrame, GameTimeFrame, TimeManagerClockButton
--@ stubs: stub_minimap.lua
-- Switched off, live: the game's round mask, ring and day/night ring, its header art and fonts, and every addon button back on the edge where it was, under the map again, dragging again; GetMinimapShape answers ROUND. Switched on and off again, the same. Beside it, another addon (a minimap addon) defined GetMinimapShape first: that addon owns the shape, so the mask, ring and buttons are left to it and only the header is restyled.
local bagnon = LibDBIcon10_Bagnon
local font = MinimapZoneText:GetFont()
PolestarUI.Switch("minimap", false)
PolestarUI.Switch("minimap", true)
assert(bagnon:GetParent() == PolestarUIMinimapDock, "not docked when on again")
PolestarUI.Switch("minimap", false)
assert(stub.minimapMask == "ui-hud-minimap-frame-generic-mask", "not the game's mask when off")
assert(GetMinimapShape() == "ROUND", "GetMinimapShape is not ROUND when off")
assert(MinimapCompassTexture:GetAlpha() == 1 and MinimapCluster.DielFrame.Background:GetAlpha() == 1, "the ring is still faded")
assert(MinimapCluster.ZoneTextButton.StateTexture:GetAlpha() == 1 and MinimapZoneText:GetFont() == font, "the header is not the game's")
assert(MinimapCluster.ZoneTextButton.AddTexture:GetAtlas() == "ui-hud-minimap-header-button", "the header's hover is not back")
local p1 = { bagnon:GetPoint(1) }
assert(bagnon:GetParent() == Minimap and p1[1] == "CENTER" and p1[2] == Minimap and math.abs(p1[4] - math.cos(math.rad(200)) * 104) < 0.01 and math.abs(p1[5] - math.sin(math.rad(200)) * 104) < 0.01, "a button is not back where it was")
assert(WeakAurasMinimapButton:GetParent() == Minimap and not PolestarUIMinimapDock:IsShown() and not PolestarUIMinimapEdge:IsShown(), "the dock or border still shows")
--@ panel
--@ roots: MinimapCluster, AddonCompartmentFrame, GameTimeFrame, TimeManagerClockButton
--@ stubs: stub_minimap.lua, stub_minimapaddon.lua
assert(GetMinimapShape() == "ROUND" and stub.minimapMask == "ui-hud-minimap-frame-generic-mask", "another addon's shape was taken")
assert(MinimapCompassTexture:GetAlpha() == 1 and LibDBIcon10_Bagnon:GetParent() == Minimap, "the ring or a button was taken from the other addon")
assert(MinimapCluster.ZoneTextButton.StateTexture:GetAlpha() == 0, "the header is not restyled")
