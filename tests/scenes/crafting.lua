--@ title: Crafting: Tailoring
--@ roots: PolestarUICrafting
--@ stubs: stub_spellbook.lua, stub_professions.lua, stub_crafting.lua
-- Casting a profession opens ours, the game's open stopped (docs/CLIENT.md, rule 11); a recipe picked in the sidebar is crafted and listed under Recent; a recipe not learnt is left out. The professions on the section rail: a profession's casts it through the secure button, the open one does not, the overview opens the Professions window, in the crafting window's place (docked: its slot, left of a window opened after it).
stub.openTradeSkill()
assert(stub.unrouted.TRADE_SKILL_SHOW, "the game's window still opens")
local f = PolestarUICrafting
assert(f:IsShown(), "not shown")
local function row(n) for _, r in ipairs({ f.NavScroll.Child:GetChildren() }) do if r:IsShown() and r.psRecipe and r.psRecipe.name == n then return r end end end
assert(not row("Brown Linen Pants"), "unlearnt recipe listed")
row("Brown Linen Vest"):Click()
assert(f.psProduct.Name:GetText() == "Brown Linen Vest" and f.Title:GetText() == "Tailoring", "not selected")
local craft = f.footerButtons.right[1]
assert(craft:IsEnabled(), "cannot craft")
craft:Click()
assert(stub.crafted[1] == 2385 and stub.crafted[2] == 1, "not crafted")
local on, recent
for _, r in ipairs({ f.NavScroll.Child:GetChildren() }) do if r:IsShown() and r.psRecipe and r.Sel:IsShown() then on = r end
if r:IsShown() and r.psKey == "recent" and not r.psRecipe then recent = r end end
assert(on and on.psKey == "make", "selection moved")
assert(recent, "no Recent")
local tabs = {}
for _, t in ipairs(f.railButtons) do if t:IsShown() then tabs[t.psName] = t end end
assert(tabs.Overview and tabs.Tailoring and tabs.Mining and tabs.Cooking and tabs["First Aid"], "tabs missing")
stub.RunScript(tabs.Mining, "OnEnter")
local o = PolestarUIProfessionTab
assert(o:IsShown() and o:GetAttribute("type1") == "spell" and o:GetAttribute("spell") == tabs.Mining.psSpell, "no cast on Mining")
stub.RunScript(tabs.Tailoring, "OnEnter")
assert(o:GetAttribute("type1") == nil, "recasts the open profession")
o:Hide()
local other = CreateFrame("Frame", nil, UIParent)
other:SetSize(300, 300)
other:Hide()
PolestarUI.Dock(other)
other:Show()
tabs.Overview:Click()
assert(not f:IsShown() and PolestarUIProfessions:IsShown() and stub.closed == 1, "overview")
assert(select(4, PolestarUIProfessions:GetPoint(1)) < select(4, other:GetPoint(1)), "professions not in the slot of the crafting window")
other:Hide()
assert(PolestarUIProfessions:GetLeft() == f:GetLeft() and PolestarUIProfessions:GetTop() == f:GetTop(), "not where the crafting window was")
PolestarUIProfessions:Hide()
stub.openTradeSkill()
