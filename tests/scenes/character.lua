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
-- The top tabs wear the stock mode tabs' icons: the portrait, the faction's honor icon.
local nav = PolestarUICharacter.tabButtons
assert(nav[1].psNavIcon:GetTexture() == 132355, "Character tab: not the player's portrait")
assert(nav[2].psNavIcon:GetTexture() == "Interface/ICONS/INV_SideTab_Reputation2_c60", "Reputation tab icon")
assert(nav[4].psNavIcon:GetTexture() == "Interface/ICONS/INV_SideTab_Honor_Alliance_c60", "Honor tab: not the Alliance icon")
nav[1].psNavIcon:SetTexture(nil); stub.fire("UNIT_PORTRAIT_UPDATE", "player")
assert(nav[1].psNavIcon:GetTexture() == 132355, "Character tab: portrait not repainted")
-- The compact grid: no sidebar, no rail, every tab on the tab row; another
-- page keeps its own title, the player leading its subtitle.
local f = PolestarUICharacter
assert(not f.Sidebar:IsShown() and f.psCompact and (f.psRail or 0) == 0, "not the compact grid")
assert(f.psTabsRight <= f:GetWidth() - f.psPad, "tabs overflow the row: " .. f.psTabsRight)
PolestarUI.Show("character", "ReputationFrame")
assert(f.Title:GetText() == "Reputation", "Reputation title: " .. f.Title:GetText())
assert(f.psSubtitle:find("^Testchar · "), "Reputation subtitle: " .. f.psSubtitle)
PolestarUI.Show("character", "PaperDollFrame")
