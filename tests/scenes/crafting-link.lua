--@ title: Crafting: link profession
--@ roots: PolestarUICrafting, PolestarMenu
--@ stubs: stub_spellbook.lua, stub_professions.lua, stub_crafting.lua
-- The stock link button's menu in the window menu ("..."): "Link profession" puts the profession's link in chat; the channels post it, Guild disabled outside a guild.
stub.openTradeSkill()
local f = PolestarUICrafting
local function item(t) for _, r in ipairs({ PolestarMenu:GetChildren() }) do if r:IsShown() and r.Text and r.Text:GetText() == t then return r end end end
f.psMenu:Click()
item("Link profession"):Click()
assert(stub.linked == "|Htrade:197|h[Tailoring]|h", "no link: " .. tostring(stub.linked))
f.psMenu:Click()
assert(item("Guild") and item("Guild").psItem.disabled, "Guild enabled outside a guild")
item("Party"):Click()
assert(stub.posted == "/p |Htrade:197|h[Tailoring]|h", "not posted: " .. tostring(stub.posted))
f.psMenu:Click()
