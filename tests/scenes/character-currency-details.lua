--@ title: Character: a currency's details
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- The first currency is chosen at once; its details show caps and the toggles. Shift-click shows a currency on the backpack, and links it while typing in chat.
PolestarUI.Show("character", "TokenFrame")
local v = PolestarUICharacter.psPages.TokenFrame
local sf = PolestarUICharacterStats.panes.currency.psView
assert(PolestarUICharacterStats.Title:GetText() == "Honor Points" and v.groups[1].rows[1].Sel:IsShown(), "first not chosen")
assert(sf.checks[2].Box:GetChecked(), "backpack not checked")
sf.checks[1]:Click()
assert(stub.unused[1] == 2 and stub.unused[2] == true, "not unused")
stub.modified.TOKENWATCHTOGGLE = true
v.groups[2].rows[1]:Click()
assert(stub.backpack[1] == 5 and stub.backpack[2] == true, "shift-click: not on the backpack")
stub.modified.TOKENWATCHTOGGLE = nil
stub.modified.CHATLINK = true
local linked
HandleModifiedItemClick = function(link) linked = link; return true end
v.groups[1].rows[2]:Click()
assert(linked and linked:find("Arena Points", 1, true), "not linked")
stub.modified.CHATLINK = nil
v.groups[1].rows[1]:Click()
