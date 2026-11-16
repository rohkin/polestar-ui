--@ title: Collections: Appearances, items
--@ roots: PolestarUICollections
--@ stubs: stub_collections.lua
-- The wardrobe's Items view: Items | Sets on the tab row; Forever's slot row (head to ranged) and 18 DressUpModel tiles a page (6 by 3), the stock camera per appearance, the player trying on armor; a favorite first and starred, a new one marked until hovered, one the player can't show desaturated, an unusable one in danger. The tooltip lists the sources and Tab cycles them; shift-click links the source shown; right-click its favorite and "Transmogrify as"; a weapon slot gets the weapon type picker; the footer and the wheel turn pages; the class sits first in the filter menu; the async search shows "Searching…" until the client answers.
PolestarUI.Show("collections", "appearances")
local f = PolestarUICollections
local L = f.psLooks
local function looks()
	local t = {}
	for _, l in ipairs(L.Looks) do if l:IsShown() then t[#t + 1] = l end end
	return t
end
assert(L:IsShown() and not f.psNav:IsShown(), "items view")
assert(f.tabButtons[1]:IsShown() and f.tabButtons[1].Label:GetText() == "Items" and f.tabButtons[2].Label:GetText() == "Sets", "views")
assert(stub.uncollectedShown == false and stub.collectedShown == true, "Forever shows collected appearances only")
assert(#L.Slots == 14 and L.Slots[1].psLoc.slot == "HEADSLOT" and L.Slots[14].psLoc.slot == "RANGEDSLOT", "slots")
assert(stub.searchCategory == 1, "head category not set: " .. tostring(stub.searchCategory))
local t = looks()
assert(#t == 18 and t[1].psLook.visualID == 101 and t[1].Star:IsShown(), "favorite first: " .. #t)
assert(t[1].psModel.psAppliedCamera == 201 and t[1].psModel.psSlot == "HEADSLOT", "camera or model setup")
assert(f.psStatus:GetText() == "18 of 20 collected · Page 1 of 2", "status: " .. f.psStatus:GetText())
local new, hidden
for _, l in ipairs(t) do
	if l.psLook.visualID == 102 then new = l end
	if l.psLook.visualID == 103 then hidden = l end
end
assert(new.New:IsShown(), "new not marked")
-- Hovering: the sources, Tab cycles them, shift-click links the one shown.
stub.RunScript(new.psModel, "OnEnter")
assert(not new.New:IsShown() and not stub.newLook[102], "new not cleared on hover")
assert(GameTooltip.lines[1] == "Helm 102" and f.psKeys.keyboardEnabled and f.psKeys.propagate, "tooltip or keys")
stub.RunScript(f.psKeys, "OnKeyDown", "TAB")
assert(GameTooltip.lines[1] == "Helm 102 (alt)" and f.psKeys.propagate == false, "tab: " .. tostring(GameTooltip.lines[1]))
stub.RunScript(f.psKeys, "OnKeyDown", "W")
assert(f.psKeys.propagate, "other keys swallowed")
local mod = IsModifiedClick
IsModifiedClick = function(k) return k == nil or k == "CHATLINK" end
stub.RunScript(new.psModel, "OnMouseDown", "LeftButton")
IsModifiedClick = mod
assert(stub.linked == "[item:1022]", "link: " .. tostring(stub.linked))
stub.RunScript(new.psModel, "OnLeave")
assert(not f.psKeys.keyboardEnabled, "keyboard left on")
-- Right-click: favorite, and the source the model wears.
stub.RunScript(new.psModel, "OnMouseUp", "RightButton")
assert(PolestarMenu.rows[1].psItem.text == "Set favorite" and PolestarMenu.rows[2].psItem.text == "Transmogrify as:", "menu")
PolestarMenu.rows[4]:Click()
assert(new.psModel.psVisual == 102, "alt source not tried on")
stub.RunScript(new.psModel, "OnMouseUp", "RightButton")
assert(PolestarMenu.rows[4].psItem.checked, "chosen source not checked")
PolestarMenu.rows[1]:Click()
assert(stub.favoriteLook[1] == 102 and stub.favoriteLook[2] == true, "favorite")
-- One whose sources are all refundable asks first.
local refund
for _, l in ipairs(looks()) do if l.psLook.visualID == 105 then refund = l end end
stub.favoriteLook = nil
stub.RunScript(refund.psModel, "OnMouseUp", "RightButton")
PolestarMenu.rows[1]:Click()
assert(not stub.favoriteLook and PolestarModal and PolestarModal:IsShown(), "no refund warning")
PolestarModal:Hide()
-- Pages: the footer and the wheel.
f.footerButtons.right[1]:Click()
assert(f.psStatus:GetText():find("Page 2 of 2", 1, true) and #looks() == 2, "next page")
stub.RunScript(L, "OnMouseWheel", 1)
assert(f.psStatus:GetText():find("Page 1 of 2", 1, true), "wheel")
-- A weapon slot: the first weapon type it takes, and the picker.
for _, b in ipairs(L.Slots) do if b.psLoc.slot == "MAINHANDSLOT" then b:Click() end end
assert(stub.searchCategory == 13 and L.Weapon:IsShown() and L.Weapon.Label:GetText() == "One-Handed Axes", "weapon slot")
L.Weapon:Click()
assert(PolestarMenu.rows[1].psItem.text == "One-Handed Axes" and not PolestarMenu.rows[2]:IsShown(), "weapon types")
Polestar.Widgets.HideMenu()
-- The class, first in the filter menu: a class change on a weapon goes back to the head.
f.psFilter:Click()
assert(PolestarMenu.rows[2].psItem.text == "Class: Warrior…", "class row: " .. PolestarMenu.rows[2].psItem.text)
PolestarMenu.rows[2]:Click()
assert(PolestarMenu.rows[1].psItem.text == "Back" and PolestarMenu.rows[2].psItem.checked and PolestarMenu.rows[4].psItem.text == "Hunter", "classes")
PolestarMenu.rows[4]:Click()
assert(C_TransmogCollection.GetClassFilter() == 3 and stub.searchCategory == 1 and PolestarMenu.rows[2].psItem.text == "Class: Hunter…", "class change")
Polestar.Widgets.HideMenu()
-- The async search (in the filter's dropdown): "Searching…" until the client answers.
f.psFilter:Click()
f.Search:SetText("helm 12")
stub.RunScript(f.Search, "OnTextChanged")
assert(stub.transmogSearch[1] == "helm 12" and f.psStatus:GetText() == "Searching…" and #looks() == 0, "searching")
stub.finishSearch(1)
assert(#looks() == 1 and f.psStatus:GetText():find("Page 1 of 1", 1, true), "search result: " .. #looks())
f.Search:SetText("")
stub.RunScript(f.Search, "OnTextChanged")
assert(stub.transmogSearch[1] == nil and #looks() == 18, "search cleared")
-- The filter: Forever's source types, flat.
assert(f.psFilter:IsShown() and PolestarMenu.rows[3].psItem.text == "Check All" and PolestarMenu.rows[5].psItem.text == "Boss Drop", "filter")
PolestarMenu.rows[5]:Click()
assert(f.psFilter.psTip == "Search and filter (on)", "filter glyph")
Polestar.Widgets.HideMenu()
C_TransmogCollection.SetDefaultFilters()
-- Closing ends the search (WardrobeCollectionFrameMixin:OnHide).
f:Hide()
assert(stub.searchEnded, "search not ended")
PolestarUI.Show("collections", "appearances")
