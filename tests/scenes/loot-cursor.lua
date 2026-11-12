--@ title: Loot: under the mouse, fishing
--@ roots: PolestarUILoot
--@ stubs: stub_loot.lua
-- With lootUnderMouse ours opens at the cursor, as LootFrameMixin:Open places the stock one; fishing loot is titled so and plays the reel-in sound.
stub.cvars.lootUnderMouse = "1"
stub.fishing = true
stub.loot = { { 133888, "Raw Brilliant Smallfish", 1, 1, false } }
stub.cursor = { 600, 500 }
local before = #stub.sounds
stub.openLoot()
assert(#stub.sounds > before, "no reel-in sound")
local f = PolestarUILoot
local point, rel, relPoint, x, y = f:GetPoint(1)
assert(point == "TOPLEFT" and rel == UIParent and relPoint == "BOTTOMLEFT", "not placed from the screen's corner")
local s = f:GetEffectiveScale()
assert(math.abs(x - (600 / s - 30)) < 0.01 and math.abs(y - math.max(500 / s + 50, 350)) < 0.01, ("not at the cursor: %s, %s"):format(x, y))
assert(f.Title:GetText() == "Fishing", "fishing title")
assert(f:IsShown() and not LootFrame:IsShown(), "open")
