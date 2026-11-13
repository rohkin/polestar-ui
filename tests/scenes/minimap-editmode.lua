--@ title: Minimap: Edit Mode
--@ roots: MinimapCluster, AddonCompartmentFrame, GameTimeFrame, TimeManagerClockButton, PolestarUIMinimapDock
--@ stubs: stub_minimap.lua
-- Edit Mode's minimap settings stay the game's: Size 125% scales the map's container (our border and dock scale with it, being on the Minimap), Header Underneath moves the zone text below the map, and leaving Edit Mode moves the dock above it, away from the header. Nothing of ours moved, scaled, hid or wrote a key on the cluster, its header or the map (the stub's guards), and the stock positions are the ones the game set.
stub.minimapEdit({ scale = 1.25, headerUnderneath = true })
local dock = PolestarUIMinimapDock
local p, rel, rp = dock:GetPoint(1)
assert(p == "BOTTOM" and rel == Minimap and rp == "TOP", "the dock is not above the map with the header underneath")
assert(PolestarUIMinimapEdge:GetParent() == Minimap and dock:GetParent() == Minimap, "ours is not on the Minimap")
assert(MinimapCluster.MinimapContainer:GetScale() == 1.25, "the size setting was undone")
assert(MinimapCluster.ZoneTextButton:GetPoint(1) == "BOTTOM", "the header was moved back")
assert(tostring(stub.minimapMask):find("WHITE8X8"), "not square after Edit Mode")
-- Back to the header on top: the dock under the map again.
stub.minimapEdit({ headerUnderneath = false })
assert(dock:GetPoint(1) == "TOP", "the dock did not go back under the map")
stub.minimapEdit({ headerUnderneath = true })
