--@ title: Macros: character
--@ roots: PolestarUIMacros
--@ stubs: stub_macros.lua
-- The stock second tab: this character's macros, indices 121 to 150; a new
-- one is made for the character. A full tab greys New and says why.
ShowMacroFrame()
local f = PolestarUIMacros
f.navButtons[2]:Click()
assert(tostring(f.Title:GetText()) == "Testchar Specific Macros", "not on the character tab: " .. tostring(f.Title:GetText()))
assert(f.psName:GetText() == "Bandage" and f.psKind:GetText() == "Character macro", "the first character macro")
f.psIcon:Click()
assert(stub.pickedMacro == 121, "the pickup's index: " .. tostring(stub.pickedMacro))
f.footerButtons.right[1]:Click()
local p = PolestarUIMacrosIcons
p.Name:SetText("Execute")
stub.RunScript(p.Name, "OnTextChanged", true)
p.Okay:Click()
assert(stub.created[1] == "Execute" and stub.created[4] == true, "not made for the character")
assert(f.psName:GetText() == "Execute" and stub.macros.character[2][1] == "Execute", "the new one not selected")
-- Full: 30 of 30.
while #stub.macros.character < 30 do table.insert(stub.macros.character, { "Z" .. #stub.macros.character, 132000, "" }) end
stub.fire("UPDATE_MACROS")
local new = f.footerButtons.right[1]
assert(not new:IsEnabled() and new.psReason == "All 30 character macro slots are used.", "New on with no slot: " .. tostring(new.psReason))
assert(tostring(f.Subtitle:GetText()) == "Full: 30 of 30 macros.", "the full count")
