--@ title: Character: the helm's flyout
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- Alt over the helm: Put in bags and the helm in the backpack; a click wears it. In combat only weapons change. With a gear set chosen, the flyout leaves the slot out of it.
PolestarUI.Show("character")
local slot = {}
for _, c in ipairs({ PolestarUICharacter.psGear:GetChildren() }) do if c.psLabel then slot[c:GetID()] = c end end
local fly = function() return PolestarUICharacterFlyout end
stub.modified.SHOWITEMFLYOUT = true
stub.RunScript(slot[1], "OnEnter")
assert(fly() and fly():IsShown(), "no flyout")
local wells = {}
for _, w in ipairs({ fly().Grid:GetChildren() }) do if w:IsShown() then wells[#wells + 1] = w end end
assert(#wells == 2 and wells[1].psEntry.text == "Put in bags" and wells[2].psEntry.bag == 0, "flyout entries")
wells[2]:Click()
assert(stub.wornFrom and stub.wornFrom[2] == 1 and stub.pickedUp == 1, "not worn")
-- In combat the helm stays; the sword still goes in the main hand.
stub.wornFrom, stub.pickedUp = nil, nil
stub.inCombat = true
stub.RunScript(slot[1], "OnEnter")
wells[2]:Click()
assert(stub.wornFrom == nil and stub.uiError, "armor changed in combat")
stub.RunScript(slot[16], "OnEnter")
for _, w in ipairs({ fly().Grid:GetChildren() }) do if w:IsShown() and w.psEntry.bag then w:Click() end end
assert(stub.wornFrom and stub.wornFrom[2] == 2 and stub.pickedUp == 16, "weapon not swapped in combat")
stub.inCombat = false
-- A set chosen: the flyout leaves the helm out of it, marked on the slot.
local d = PolestarUICharacterStats
for _, t in ipairs(d.Tabs) do if t:IsShown() and t.Label:GetText() == "Gear sets" then t:Click() end end
d.panes.sets.psView.rows[1]:Click()
stub.RunScript(slot[1], "OnEnter")
local leave
for _, w in ipairs({ fly().Grid:GetChildren() }) do if w:IsShown() and w.psEntry.text == "Leave out of the set" then leave = w end end
assert(leave, "no Leave out entry")
leave:Click()
assert(stub.ignoredForSave[1] and slot[1].psOut:IsShown(), "helm not left out")
stub.RunScript(slot[1], "OnEnter")
-- Kept open for the picture: the cursor stays on the helm.
slot[1].IsMouseOver = function() return true end
