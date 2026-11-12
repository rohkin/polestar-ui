--@ title: Character: an enchant over the head slot
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- An enchant waiting for its item: hovering a slot puts the secure overlay over it, targeting that slot (and using it on a right-click).
PolestarUI.Show("character")
stub.targeting = true
local s
for _, c in ipairs({ PolestarUICharacter.psGear:GetChildren() }) do if c.psLabel and c:GetID() == 1 then s = c end end
stub.RunScript(s, "OnEnter")
local a = PolestarUICharacterSlot
assert(a and a:IsShown(), "no overlay")
assert(a:GetAttribute("*target-slot*") == 1, "wrong slot")
assert(a:GetAttribute("type2") == "item" and a:GetAttribute("item") == "1", "no use")
for _, c in ipairs({ PolestarUICharacter.psGear:GetChildren() }) do if c.psLabel and c:GetID() == 2 then stub.RunScript(c, "OnEnter") end end
assert(a:GetAttribute("type2") == nil and a:GetAttribute("*target-slot*") == 2, "empty slot")
