--@ title: Loot: moved in Edit Mode, in combat
--@ roots: PolestarUILoot
--@ stubs: stub_loot.lua
-- Moved in Edit Mode, the stock LootFrame's layout place is ours (read off the stock frame, never written). In combat the client hands the names over secret: they show through a game-font string (ours take none), the rest of the row as out of combat.
LootFrame:SetScale(0.8)
stub.moveLootFrame("BOTTOMRIGHT", "BOTTOMRIGHT", -300, 200)
stub.secretLoot, stub.inCombat = true, true
stub.openLoot()
local f = PolestarUILoot
local p, rel, rp, x, y = f:GetPoint(1)
assert(p == "BOTTOMRIGHT" and rel == UIParent and rp == "BOTTOMRIGHT", "not the layout's anchor: " .. tostring(p))
assert(math.abs(x * f:GetScale() + 300) < 0.01 and math.abs(y * f:GetScale() - 200) < 0.01, ("not the layout's place: %s, %s"):format(x, y))
local r = f.psRows[2]
assert(r.Raw:IsShown() and r.Raw:GetText() == stub.SECRET and not r.Name:IsShown(), "the secret name")
assert(r.Quality:GetText() == "Uncommon" and r:IsShown(), "the row")
