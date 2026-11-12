--@ title: Crafting: Mooncloth, on cooldown
--@ roots: PolestarUICrafting
--@ stubs: stub_spellbook.lua, stub_professions.lua, stub_crafting.lua
-- The search finds Mooncloth: on cooldown and away from a moonwell it cannot be crafted. Closing ours ends the trade skill; reopened, it is still selected.
stub.openTradeSkill()
local f = PolestarUICrafting
local s = f.Search
s:SetText("moon")
stub.RunScript(s, "OnTextChanged")
local n, moon = 0
for _, r in ipairs({ f.NavScroll.Child:GetChildren() }) do if r:IsShown() and r.psRecipe then n = n + 1
moon = r end end
assert(n == 1 and moon.psRecipe.name == "Mooncloth", "search: " .. n)
moon:Click()
s:SetText("")
stub.RunScript(s, "OnTextChanged")
assert(not f.footerButtons.right[1]:IsEnabled() and not f.footerButtons.right[2]:IsEnabled(), "craftable")
f.Close:Click()
assert(stub.closed == 1 and not f:IsShown(), "trade skill left open")
stub.openTradeSkill()
assert(f.psProduct.Name:GetText() == "Mooncloth", "selection lost")
stub.fire("TRADE_SKILL_CLOSE")
assert(stub.closed == 1 and not f:IsShown(), "closed twice")
stub.openTradeSkill()
