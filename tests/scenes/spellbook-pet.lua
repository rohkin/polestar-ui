--@ title: Spellbook: Pet
--@ roots: PolestarUISpellbook
--@ stubs: stub_spellbook.lua
-- A pet's book: right-click toggles autocast (the game's slash command on the secure button); a pet command does not cast.
stub.pet = true
PolestarUI.Show("spellbook", "pet")
local byName = {}
for _, c in ipairs({ PolestarUISpellbook.Body:GetChildren() }) do if c.psSpell and c:IsShown() then byName[c.psSpell.info.name] = c end end
stub.RunScript(byName["Growl"], "OnEnter")
local o = PolestarUISpellbookCast
assert(o:GetAttribute("type2") == "macro" and o:GetAttribute("macrotext") == "/petautocasttoggle Growl", "no autocast")
assert(o:GetAttribute("type1") == "spell" and o:GetAttribute("spell") == "Growl", "no cast")
stub.RunScript(byName["Attack"], "OnEnter")
assert(o:GetAttribute("type1") == nil and o:GetAttribute("type2") == nil, "command casts")
