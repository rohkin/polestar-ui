--@ title: Character: upgrades in the bags, a ring held
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- Polestar's gear advice finds upgrades in the bags for the shoulders and main hand; the cursor holds a ring.
Polestar.Gear = { Bags = { IsOn = function() return true end, IsUpgrade = function() return true end }, CompareToEquipped = function(link) return { slot = link:find("item:91") and 3 or 16 } end }
stub.cursorFits = { [11] = true, [12] = true }
PolestarUI.Show("character")

-- Polestar hidden: no upgrade arrows (Polestar's Bags.IsOn answers false); back through POLESTAR_HIDDEN.
local function arrows(fr, n)
	n = n or 0
	if fr.psUp and fr.psUp.IsShown and fr.psUp:IsShown() then n = n + 1 end
	for _, k in ipairs({ fr:GetChildren() }) do n = arrows(k, n) end
	return n
end
local hidden = true
Polestar.Gear.Bags.IsOn = function() return not hidden end
Polestar.Fire("POLESTAR_HIDDEN", true)
assert(arrows(PolestarUICharacter) == 0, "upgrade arrows while Polestar is hidden")
hidden = false
Polestar.Fire("POLESTAR_HIDDEN", false)
assert(arrows(PolestarUICharacter) > 0, "the arrows did not come back")
