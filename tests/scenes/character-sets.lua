--@ title: Character: Gear sets
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- The Gear sets tab: the worn set checked, one missing an item in red. Select and Equip wears it; in combat it waits for the fight to end; New set saves a named set without shirt and tabard.
PolestarUI.Show("character")
local d = PolestarUICharacterStats
for _, t in ipairs(d.Tabs) do if t:IsShown() and t.Label:GetText() == "Gear sets" then t:Click() end end
local sf = d.panes.sets.psView
assert(d.panes.sets:IsShown(), "pane not shown")
assert(sf.rows[1].Name:GetText() == "Tanking" and sf.rows[1].Check:IsShown(), "worn set")
assert(not sf.Equip:IsEnabled(), "Equip without a set")
sf.rows[2]:Click()
assert(sf.rows[2].Mark:IsShown() and sf.Equip:IsEnabled(), "not selected")
stub.inCombat = true
sf.Equip:Click()
assert(stub.equippedSet == nil, "equipped in combat")
stub.inCombat = false
stub.fire("PLAYER_REGEN_ENABLED")
assert(stub.equippedSet == 7, "not equipped after the fight")
stub.equippedSet = nil
stub.RunScript(sf.rows[2], "OnDoubleClick")
assert(stub.equippedSet == 7, "double-click")
-- A new set: named, an icon picked, shirt and tabard left out.
sf.New:Click()
assert(PolestarModal:IsShown(), "no dialog")
local ed = PolestarModal.Box
local field
for _, c in ipairs({ ed:GetChildren() }) do if c.Field then field = c.Field end end
field:SetText("Raid")
PolestarModal.Box.Action:Click()
assert(stub.ignoredForSave[4] and stub.ignoredForSave[19], "shirt and tabard saved")
assert(sf.rows[3]:IsShown() and sf.rows[3].Name:GetText() == "Raid" and sf.rows[3].Mark:IsShown(), "new set not listed")
