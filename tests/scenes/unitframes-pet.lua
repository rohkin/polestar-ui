--@ title: Unit frames: the pet stays on its box while the game re-lays out its frame
--@ roots: PolestarUIPlayerFrame, PolestarUIPetFrame
stub.units.pet = { name = "Wolf", level = 23, health = 700, max = 900, power = 60, powerMax = 100, powerType = 3, reaction = 5, threat = 2 }
stub.secure(function() PetFrame:Show() end)
stub.unitWatch()
stub.fire("UNIT_PET", "player")
stub.advance(0.1)
local Pet = PolestarUIPetFrame
local function at() return select(4, Pet:GetPoint(1)), select(5, Pet:GetPoint(1)) end
local x, y = at()
assert(Pet:IsShown() and x == PetFrame.Selection:GetLeft(), "pet on its box")
assert(Pet:GetHeight() == 24 and Pet.portrait:GetWidth() == 22, "slim and smaller: " .. Pet:GetHeight())
assert(Pet.Name:GetText() == "Wolf", "the name on the bar")
-- The game unanchors the pet frame (its managed container's ClearAllPoints
-- before Layout, or no pet yet): it then reads as at its parent's corner.
local function unanchor()
	stub.secure(function() PetFrame:ClearAllPoints() end)
	PetFrame.x, PetFrame.y = 0, 1080 - 49
	PetFrame.Selection.x, PetFrame.Selection.y = 4, 1080 - 46
end
local function still(why)
	local nx, ny = at()
	assert(nx == x and ny == y, why .. ": moved to " .. tostring(nx) .. ", " .. tostring(ny))
end
unanchor()
stub.fire("EDIT_MODE_LAYOUTS_UPDATED")
stub.advance(0.1)
still("layout update")
-- Dismissed and summoned again, a vehicle and back.
stub.units.pet = nil
stub.unitWatch()
stub.fire("UNIT_PET", "player")
stub.advance(0.1)
still("dismissed")
stub.units.pet = { name = "Wolf", level = 23, health = 700, max = 900, power = 60, powerMax = 100, powerType = 3, reaction = 5, threat = 2 }
stub.unitWatch()
stub.fire("UNIT_PET", "player")
stub.advance(0.1)
still("summoned")
stub.vehicle = true
stub.fire("UNIT_ENTERED_VEHICLE", "player")
stub.advance(0.1)
still("vehicle")
stub.vehicle = false
stub.fire("UNIT_EXITED_VEHICLE", "player")
stub.advance(0.1)
still("vehicle left")
-- Anchored again where the player moved it: ours follow on the pet's summon.
stub.moveSystem(PetFrame, 320, 650)
stub.fire("UNIT_PET", "player")
stub.advance(0.1)
assert(select(4, Pet:GetPoint(1)) == PetFrame.Selection:GetLeft(), "follows the box again")
stub.assertNoErrors()
