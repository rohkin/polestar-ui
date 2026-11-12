--@ title: Character
--@ roots: PolestarUICharacter, PolestarUICharacterStats
PolestarUI.Show("character")
-- The stock pane's last category: the five resistances.
local v = PolestarUICharacterStats.Body
local res = v.sections[#v.sections]
assert(res.name == "Resistance" and res.rows[5]:IsShown() and res.rows[2].Value:GetText() == "15", "resistances")
-- An item dropped on the model goes on.
stub.cursorFits = {}
stub.RunScript(PolestarUICharacter.psGear.Model, "OnReceiveDrag")
assert(stub.autoEquipped and not CursorHasItem(), "not worn")
-- The stock slot's extras: the arrows' count, the locked boots greyed out.
local slot = {}
for _, c in ipairs({ PolestarUICharacter.psGear:GetChildren() }) do if c.psLabel then slot[c:GetID()] = c end end
for _, c in ipairs({ slot[18]:GetChildren() }) do if c.psLabel then slot[0] = c end end
assert(slot[0].psCount:GetText() == "200", "ammo count")
assert(slot[8].Icon.desaturated and not slot[7].Icon.desaturated, "lock")
-- A scaled level shows both, as the stock sheet.
UnitEffectiveLevel = function() return 20 end
EFFECTIVE_LEVEL_FORMAT = "%d (%d)"
PolestarUI.RefreshCharacter()
assert(PolestarUICharacter.psLine:GetText() == "Level 20 (24) Warrior", "level: " .. PolestarUICharacter.psLine:GetText())
UnitEffectiveLevel = nil
PolestarUI.RefreshCharacter()
