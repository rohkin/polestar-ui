--@ title: Minimap: Edit Mode
--@ roots: MinimapCluster, AddonCompartmentFrame, GameTimeFrame, TimeManagerClockButton, PolestarUIMinimapDock
--@ stubs: stub_minimap.lua
-- Edit Mode's minimap settings stay the game's: Size 125% scales the map's container (our border, corner icons and flyout scale with it, being on the Minimap), Header Underneath moves the zone text below the map; the flyout stays on the map, up from the addons icon. The screen clamp follows the visible square, not the cluster's box: after each setting the insets are the map's edges inside the box (left, right, top, bottom), so the box may leave the screen until the map meets its edge. Nothing of ours moved, scaled, hid or wrote a key on the cluster, its header or the map (the stub's guards), and the stock positions are the ones the game set.
local function insets(want, what)
	local got = { MinimapCluster:GetClampRectInsets() }
	for i = 1, 4 do assert(math.abs(got[i] - want[i]) < 0.01, what .. ": the clamp is not the map's edges: " .. table.concat(got, ", ")) end
end
insets({ 39, -19, -44, 14 }, "100%, header above")
stub.minimapEdit({ headerUnderneath = true })
insets({ 39, -19, -14, 44 }, "100%, header underneath")
stub.minimapEdit({ scale = 1.25, headerUnderneath = false })
insets({ 41.125, -21.125, -47.5, 17.5 }, "125%, header above")
stub.minimapEdit({ headerUnderneath = true })
insets({ 41.125, -21.125, -17.5, 47.5 }, "125%, header underneath")
-- Edit Mode setting its own clamp again (a drag, a highlight): ours follows it.
MinimapCluster:UpdateClampOffsets()
insets({ 41.125, -21.125, -17.5, 47.5 }, "after Edit Mode's UpdateClampOffsets")
local dock = PolestarUIMinimapDock
local p, rel, rp = dock:GetPoint(1)
assert(p == "BOTTOMRIGHT" and rel:GetParent() == PolestarUIMinimapEdge and rp == "TOPRIGHT", "the flyout is not on the map, up from the addons icon, with the header underneath")
assert(PolestarUIMinimapEdge:GetParent() == Minimap and dock:GetParent() == Minimap, "ours is not on the Minimap")
assert(MinimapCluster.MinimapContainer:GetScale() == 1.25, "the size setting was undone")
assert(MinimapCluster.ZoneTextButton:GetPoint(1) == "BOTTOM", "the header was moved back")
assert(tostring(stub.minimapMask):find("WHITE8X8"), "not square after Edit Mode")
