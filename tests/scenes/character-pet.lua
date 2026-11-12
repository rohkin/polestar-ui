--@ title: Character: the pet's stats
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- With a pet, the Pet tab shows its level, happiness, experience and stats; the slots step aside for its model. Without one, the tab goes.
stub.pet = true
PolestarUI.Show("character")
local d = PolestarUICharacterStats
local tab
for _, t in ipairs(d.Tabs) do if t:IsShown() and t.Label:GetText() == "Pet" then tab = t end end
assert(tab, "no Pet tab")
tab:Click()
local sf = d.panes.pet.psView
assert(sf.Level:GetText() == "Level 24 Wolf (Loyalty Level 3)" and sf.Happy:GetText() == "Content", "pet line: " .. sf.Level:GetText())
local names = {}
for _, s in ipairs(sf.Child.sections) do if s.Head:IsShown() then names[#names + 1] = s.name end end
assert(table.concat(names, ",") == "Pet,Combat,Resistance", "pet categories: " .. table.concat(names, ","))
local helm
for _, c in ipairs({ PolestarUICharacter.psGear:GetChildren() }) do if c.psLabel and c:GetID() == 1 then helm = c end end
assert(not helm:IsShown(), "slots still shown")
