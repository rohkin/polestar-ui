--@ title: Crafting: the guild's crafters
--@ roots: PolestarUICrafting, PolestarMenu
--@ stubs: stub_spellbook.lua, stub_professions.lua, stub_crafting.lua
-- The guild's recipes: no crafting, "View crafters" in Craft's place, as the stock button: the client is asked who knows the recipe, and the answer lists them in a menu, an online one whispered on a click, an offline one disabled.
stub.guildView = true
stub.openTradeSkill()
local f = PolestarUICrafting
local b = f.footerButtons.right[1]
assert(b.Label:GetText() == "View crafters" and b:IsEnabled() and not (f.footerButtons.right[2] and f.footerButtons.right[2]:IsShown()) and not f.psStep:IsShown(), "no View crafters")
assert(not f.psProduct.Fav:IsShown() and not f.psTrack:IsShown(), "favorite or track on the guild's recipes")
b:Click()
local function item(t) for _, r in ipairs({ PolestarMenu:GetChildren() }) do if r:IsShown() and r.Text and (r.Text:GetText() or ""):find(t, 1, true) then return r end end end
assert(item("Loading"), "not asked")
stub.answerGuild()
assert(item("Aelric") and item("Brannoc") and item("Brannoc").psItem.disabled, "no crafters")
item("Aelric"):Click()
assert(stub.told == "Aelric-Realm", "no whisper")
b:Click()
stub.answerGuild()
