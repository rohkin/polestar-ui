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
-- The stock sheet's title (UnitPVPName) and its level line, the class in its colour.
assert(PolestarUICharacter.Title:GetText() == "Testchar", "title: " .. PolestarUICharacter.Title:GetText())
assert(PolestarUICharacter.psSubtitle:find("^Level 20 %(24%) |cffc69b6dWarrior|r · "), "level: " .. PolestarUICharacter.psSubtitle)
UnitEffectiveLevel = nil
PolestarUI.RefreshCharacter()
-- The rail sections wear the stock mode tabs' icons: the portrait, the faction's honor icon.
local nav = PolestarUICharacter.railButtons
assert(nav[1].Icon:GetTexture() == 132355, "Character row: not the player's portrait")
assert(nav[2].Icon:GetTexture() == "Interface/ICONS/INV_SideTab_Reputation2_c60", "Reputation row icon")
assert(nav[4].Icon:GetTexture() == "Interface/ICONS/INV_SideTab_Honor_Alliance_c60", "Honor row: not the Alliance icon")
nav[1].Icon:SetTexture(nil); stub.fire("UNIT_PORTRAIT_UPDATE", "player")
assert(nav[1].Icon:GetTexture() == 132355, "Character row: portrait not repainted")
-- No sidebar; another page keeps its own title.
assert(not PolestarUICharacter.Sidebar:IsShown(), "sidebar shown")
PolestarUI.Show("character", "ReputationFrame")
assert(PolestarUICharacter.Title:GetText() == "Reputation", "Reputation title: " .. PolestarUICharacter.Title:GetText())
PolestarUI.Show("character", "PaperDollFrame")
