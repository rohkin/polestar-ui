--@ title: Character: sockets on the helm
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- The helm's two sockets show on its slot, one gem set; shift-right-click opens the game's socketing.
PolestarUI.Show("character")
local slot = {}
for _, c in ipairs({ PolestarUICharacter.psGear:GetChildren() }) do if c.psLabel then slot[c:GetID()] = c end end
assert(slot[1].psGems[1]:IsShown() and slot[1].psGems[2]:IsShown(), "helm sockets")
assert(#slot[3].psGems == 0, "sockets on the shoulders")
stub.RunScript(slot[1], "OnEnter")
assert(table.concat(GameTooltip.lines, "/"):find("socket gems", 1, true), "no socket hint")
assert(PolestarUICharacterSlot:GetAttribute("shift-type2") == "", "shift-right-click would use it")
stub.modified.EXPANDITEM = true
stub.RunScript(slot[1], "OnClick", "RightButton")
assert(stub.socketed == 1, "not socketed")
stub.modified.EXPANDITEM = nil
GameTooltip:Hide()
