--@ title: Minimap: thousands of map pins
--@ roots: MinimapCluster
--@ stubs: stub_minimap.lua
-- Map pin addons (HandyNotes, Questie, GatherMate...) put more frames on the Minimap than the Lua stack holds as GetChildren's return values: gathering the addon buttons skips that scan (no stack overflow) and the LibDBIcon buttons still join the flyout.
for i = 1, 9000 do CreateFrame("Frame", nil, Minimap) end
stub.fire("PLAYER_ENTERING_WORLD")
stub.advance(1.1)
assert(LibDBIcon10_Bagnon:GetParent() == PolestarUIMinimapDock, "a LibDBIcon button is not docked")
stub.assertNoErrors()
