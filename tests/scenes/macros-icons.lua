--@ title: Macros: icon picker
--@ roots: PolestarUIMacros, PolestarUIMacrosIcons
--@ stubs: stub_macros.lua
-- The stock MacroPopupFrame as a flyout. New: no name (Okay off), the "?"
-- icon, the body hidden until the macro is made; then it takes the keys.
-- The spellbook's icons follow "?" (IconDataProviderOverrides): a spell, a
-- flyout and its known spell; not a spell still to learn.
Enum.SpellBookItemType = { Spell = 1, FutureSpell = 2, Flyout = 4 }
C_SpellBook = { GetNumSpellBookSkillLines = function() return 1 end,
	GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = 3 } end,
	GetSpellBookItemType = function(slot) return ({ 1, 2, 4 })[slot], slot == 3 and 7 or nil end,
	GetSpellBookItemTexture = function(slot) return 135000 + slot end }
function GetFlyoutInfo() return "Portals", nil, 2, true end
function GetFlyoutSlotInfo(_, k) return 500 + k, nil, k == 1 end
C_Spell = C_Spell or {}
function C_Spell.GetSpellTexture(id) return 136000 + id end
ShowMacroFrame()
local f = PolestarUIMacros
f.footerButtons.right[1]:Click()
local p = PolestarUIMacrosIcons
assert(p:IsShown() and tostring(p.Title:GetText()) == "New macro", "no picker for New")
assert(p.Name:GetText() == "" and p.psIcon == 134400 and not p.Okay:IsEnabled(), "New does not start empty on the ? icon")
assert(p.Okay.psReason == "Enter a name.", "Okay off without saying why")
assert(not f.psEditWell:IsShown(), "the body shows before the new macro is made")
-- The stock list: ?, the spellbook's, then the spell icons (names as Interface\Icons paths), then the item icons.
local l = p.psIcons
assert(#l == 1 + 3 + 2 + 60 + 1 + 40 and l[2] == 135001 and l[3] == 135003 and l[4] == 136501
	and l[5] == "INTERFACE\\ICONS\\Ability_Warrior_Charge", "the icon list")
-- The filter: items only.
p.Filter:Click()
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() and r.psItem.text == "Items" then r:Click() end end
assert(#p.psIcons == 1 + 1 + 40 and p.psFilter == "item", "the item filter")
-- A click on an icon picks it; a name and Enter make it, quotes dropped as stock.
local wells = {}
for _, w in ipairs(p.Wells) do if w:IsShown() then wells[#wells + 1] = w end end
wells[4]:Click()
assert(p.psIcon == 133002, "the icon not picked: " .. tostring(p.psIcon))
p.Name:SetText("\"Bandage\" me")
stub.RunScript(p.Name, "OnTextChanged", true)
assert(p.Okay:IsEnabled(), "Okay off with a name")
stub.RunScript(p.Name, "OnEnterPressed")
assert(stub.created[1] == "Bandage me" and stub.created[2] == 133002 and not stub.created[4], "not made: " .. tostring(stub.created[1]))
assert(not p:IsShown() and f.psName:GetText() == "Bandage me" and f.psEditWell:IsShown() and f.psEdit:HasFocus(), "the new macro not selected with its body in focus")
-- Change name/icon: the selected macro's name highlighted, its chosen icon.
f.psChange:Click()
assert(p:IsShown() and tostring(p.Title:GetText()) == "Change name and icon" and p.Name:GetText() == "Bandage me" and p.psIcon == 133002, "the edit picker")
assert(p.psFilter == "all", "the filter kept")
-- An item dropped on the picker gives its icon, as the stock drag area.
stub.cursorInfo = { "item", 6948 }
stub.RunScript(p, "OnReceiveDrag")
assert(p.psIcon == 134414 and not stub.cursorInfo, "a dropped item's icon")
assert(tostring(p.ChosenText:GetText()) == "The current icon is not in the list.", "the not-in-list line")
p.Name:SetText("Bandage")
stub.RunScript(p.Name, "OnTextChanged", true)
p.Okay:Click()
assert(stub.edited[2] == "Bandage" and stub.edited[3] == 134414, "not edited")
assert(f.psName:GetText() == "Bandage", "the renamed macro not selected: " .. tostring(f.psName:GetText()))
-- Picking another macro closes the picker; show it again for the picture, on Zone.
f.psChange:Click()
local zone
for _, c in ipairs({ f.psGrid.Child:GetChildren() }) do if c:IsShown() and c.Name and c.Name:GetText() == "Zone" then zone = c end end
zone:Click()
assert(not p:IsShown(), "the picker stayed open")
f.psChange:Click()
assert(not stub.blocked, "a macro call refused: " .. tostring(stub.blocked))
