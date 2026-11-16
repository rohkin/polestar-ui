--@ title: Spellbook: search
--@ roots: PolestarUISpellbook, PolestarMenu
--@ stubs: stub_spellbook.lua
-- The search, at the top of the filter's dropdown (the tab row keeps only the filter), looks through every category; the filter is lit while one runs. Docked: at the stock left edge, beside a stock panel while it is open, closed for a newer one beside it that does not fit, and not draggable.
PolestarUI.Show("spellbook")
local w = PolestarUISpellbook
local s = w.Search
assert(not s:IsShown() and not w.psFilter.psActive, "search on the tab row")
w.psFilter:Click()
assert(s:IsShown() and s:GetParent() == PolestarMenu, "search not in the dropdown")
assert(not s:HasFocus(), "opening the dropdown took the keyboard")
s:SetText("fire")
stub.RunScript(s, "OnTextChanged")
assert(w.Title:GetText() == "Search" and w.psFilter.psActive, "no search")
stub.RunScript(s, "OnEnterPressed")
assert(not PolestarMenu:IsShown() and not s:IsShown() and s:GetText() == "fire" and w.psFilter.psActive, "Enter lost the search")
local function left() return select(4, w:GetPoint(1)) end
assert(left() == 16, "not docked: " .. tostring(left()))
stub.dragHeader(w, 60, -40)
assert(left() == 16, "docked window drags: " .. tostring(left()))
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
-- Closing the window closes its dropdown; opened again, the search is still in it.
assert(not PolestarMenu:IsShown(), "dropdown outlived its window")
w.psFilter:Click()
assert(s:IsShown() and s:GetText() == "fire", "search lost")
