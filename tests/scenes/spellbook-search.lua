--@ title: Spellbook: search
--@ roots: PolestarUISpellbook
--@ stubs: stub_spellbook.lua
-- The sidebar search looks through every category. Docked: at the stock left edge, beside a stock panel while it is open, closed for a newer one beside it that does not fit, and not draggable.
PolestarUI.Show("spellbook")
local s = PolestarUISpellbook.Search
s:SetText("fire")
stub.RunScript(s, "OnTextChanged")
local w = PolestarUISpellbook
local function left() return select(4, w:GetPoint(1)) end
assert(left() == 16, "not docked: " .. tostring(left()))
w:StartMoving()
assert(not w.moving, "docked window drags")
local p = CreateFrame("Frame", "StockPanel", UIParent)
p:SetSize(384, 400)
p.x = 16
p:SetAttribute("UIPanelLayout-defined", true)
p:Show()
EventRegistry:TriggerEvent("UIParentPanelManager.ShowUIPanel", p)
stub.advance(0.1)
assert(w:IsShown() and left() == 16 + 384 + 32, "not beside the stock panel: " .. tostring(left()))
p:Hide()
assert(left() == 16, "did not move back")
local o = CreateFrame("Frame", nil, UIParent)
o:SetSize(1100, 600)
o:Hide()
PolestarUI.Dock(o)
o:Show()
assert(not w:IsShown() and o:IsShown() and select(4, o:GetPoint(1)) == 16, "the older window did not make room")
o:Hide()
PolestarUI.Show("spellbook")
