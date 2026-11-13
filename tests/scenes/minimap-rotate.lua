--@ title: Minimap: rotating
--@ roots: MinimapCluster, AddonCompartmentFrame, GameTimeFrame, TimeManagerClockButton
--@ stubs: stub_minimap.lua
-- The map turning with the player (Edit Mode's Rotate Minimap: the rotateMinimap CVar). The game's callback lays its round mask and the pointer ring again, in no set order with ours: the next frame the map is square again and the ring and its underlay stay faded. Facing west (a quarter turn counter-clockwise), north is on the right edge: our N there. Indoors HybridMinimap's canvas is squared as it loads. Facing unknown (an instance), no N. Beside it, the tracking menu (by its tag) in the chat's menu look.
local function square() return tostring(stub.minimapMask):find("WHITE8X8") ~= nil end
stub.facing = math.pi / 2
stub.minimapEdit({ rotate = true })
assert(not square(), "the stub's game callback did not run after ours")
stub.advance(0.1)
assert(square(), "not square again after the game's rotation callback")
assert(MinimapCompassTexture:GetAlpha() == 0 and MinimapCompassTextureUnderlay:IsShown() and MinimapCompassTextureUnderlay:GetAlpha() == 0, "the pointer ring shows")
local n
for _, r in ipairs({ PolestarUIMinimapEdge:GetRegions() }) do if r:GetObjectType() == "FontString" then n = r end end
assert(n and n:IsShown() and n:GetText() == "N", "no N while rotating")
local p, _, _, x, y = n:GetPoint(1)
assert(p == "CENTER" and x > 80 and math.abs(y) < 1, "N is not on the right edge facing west: " .. x .. ", " .. y)
local h = stub.loadHybridMinimap()
assert(tostring(h.CircleMask.texture):find("WHITE8X8") and h.CircleMask.wrap[1] == "CLAMPTOBLACKADDITIVE", "HybridMinimap is not square")
stub.facing = nil
stub.advance(0.1)
assert(not n:IsShown(), "N shows with no facing")
stub.facing = math.pi / 2
stub.advance(0.1)
--@ panel
--@ roots: StubMenu
--@ stubs: stub_chat.lua, stub_minimap.lua
local m, bg = stub.openMenu(MinimapCluster.Tracking.Button, "MENU_MINIMAP_TRACKING", { "Find Herbs", "Find Minerals", "Flight Master" })
assert(bg:GetAlpha() == 0, "the tracking menu's stock ground shows")
local ours = 0
for _, r in ipairs({ m:GetRegions() }) do if r:IsShown() and r ~= bg and r.GetTexture and tostring(r:GetTexture()):find("Polestar") then ours = ours + 1 end end
assert(ours == 5, "the tracking menu is not restyled: " .. ours)
