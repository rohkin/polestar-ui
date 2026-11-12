--@ title: Character: upgrades in the bags, a ring held
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- Polestar's gear advice finds upgrades in the bags for the shoulders and main hand; the cursor holds a ring.
Polestar.Gear = { Bags = { IsOn = function() return true end, IsUpgrade = function() return true end }, CompareToEquipped = function(link) return { slot = link:find("item:91") and 3 or 16 } end }
stub.cursorFits = { [11] = true, [12] = true }
PolestarUI.Show("character")
