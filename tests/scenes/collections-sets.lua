--@ title: Collections: Appearances, sets
--@ roots: PolestarUICollections
--@ stubs: stub_collections.lua
-- The wardrobe's Sets view: the base sets (the favorite first; colour by the best variant's progress: done, in progress, none), each with its label; a set with a new piece marked. The selected set on the player (DressUpModel, the stock set camera) with its pieces along the pane's foot (collected ones in their quality, the rest faded), the variant picker when more than one shows. Right-click favorites a set, a piece's tooltip lists its sources, shift-click links one; the async search; the filter (class first, Collected, Not Collected, PvE, PvP).
PolestarUI.Show("collections", "appearances")
local f = PolestarUICollections
f.tabButtons[2]:Click()
local d = f.psDetail
local function rows()
	local t = {}
	for _, r in ipairs({ f.psNav.Child:GetChildren() }) do if r.psSet and r:IsShown() then t[#t + 1] = r end end
	return t
end
assert(f.psNav:IsShown() and not f.psLooks:IsShown() and d.Dress:IsShown() and not d.Model:IsShown(), "sets view")
assert(f.psStatus:GetText() == "1 of 3 sets collected", "status: " .. f.psStatus:GetText())
local function byID(id) for _, r in ipairs(rows()) do if r.psSet.setID == id then return r end end end
local t = rows()
assert(#t == 3 and t[1].psSet.setID == 511 and t[1].Star:IsShown() and t[1].Sub:GetText() == "Dungeon", "favorite first")
assert(t[2].psSet.setID == 521 and t[2].Well.Icon.desaturated and t[3].psSet.setID == 501 and t[3].New:IsShown(), "new or uncollected set")
-- The favorite is selected first: its pieces, all collected, on the player.
assert(t[1].Sel:IsShown() and d.Name:GetText() == "Lightforge Armor" and d.Dress.psAppliedCamera == 300, "first set")
assert(#d.psPieces == 4 and d.psPieces[1]:IsShown() and not d.Variant:IsShown(), "pieces")
-- The raid set: its variant with a new piece shows first; the picker lists the visible variants.
stub.RunScript(byID(501), "OnClick", "LeftButton")
assert(d.Name:GetText() == "Battlegear of Might" and d.Variant:IsShown() and d.Variant.Label:GetText() == "Heroic", "variant: " .. tostring(d.Variant.Label:GetText()))
assert(d.psPieces[1].New:IsShown() and d.psPieces[4].Icon:GetAlpha() < 1, "new or missing piece")
d.Variant:Click()
assert(PolestarMenu.rows[1].psItem.text == "Normal (2/4)" and PolestarMenu.rows[2].psItem.checked and PolestarMenu.rows[3].psItem.text == "Mythic (0/4)", "variants: " .. PolestarMenu.rows[1].psItem.text)
PolestarMenu.rows[1]:Click()
assert(d.Variant.Label:GetText() == "Normal", "variant pick")
-- A piece: its sources, the "new" cleared on hover, shift-click links.
d.Variant:Click()
PolestarMenu.rows[2]:Click()
stub.RunScript(d.psPieces[1], "OnEnter")
assert(GameTooltip.lines[1] == "Piece 50201" and stub.setNewCleared and not d.psPieces[1].New:IsShown(), "piece tooltip")
local mod = IsModifiedClick
IsModifiedClick = function(k) return k == "CHATLINK" end
stub.RunScript(d.psPieces[1], "OnClick", "LeftButton")
IsModifiedClick = mod
assert(stub.linked == "[item:50201]", "piece link: " .. tostring(stub.linked))
stub.RunScript(d.psPieces[1], "OnLeave")
-- Right-click: favorite the set shown (with its variant's name), the list redraws at once.
stub.RunScript(byID(501), "OnClick", "RightButton")
assert(PolestarMenu.rows[1].psItem.text == "Set favorite", "set menu: " .. PolestarMenu.rows[1].psItem.text)
PolestarMenu.rows[1]:Click()
assert(stub.sets[502].favorite and rows()[2].psSet.setID == 501 and rows()[2].Star:IsShown(), "favorite not redrawn at once")
-- The async search.
f.Search:SetText("plate")
stub.RunScript(f.Search, "OnTextChanged")
assert(stub.transmogSearch[2] == "plate" and f.psStatus:GetText() == "Searching…", "searching")
stub.finishSearch(2)
assert(#rows() == 1 and rows()[1].psSet.setID == 521, "search result")
f.Search:SetText("")
stub.RunScript(f.Search, "OnTextChanged")
-- The items view keeps its own search box.
f.tabButtons[1]:Click()
assert(f.Search:GetText() == "" and stub.transmogSearch[2] == nil, "sets search left behind")
f.tabButtons[2]:Click()
-- The filter: the class, then the stock set filters.
f.psFilter:Click()
assert(PolestarMenu.rows[1].psItem.text == "Class: Warrior…" and PolestarMenu.rows[3].psItem.text == "Not Collected" and PolestarMenu.rows[5].psItem.text == "PvP", "set filter")
PolestarMenu.rows[2]:Click()
assert(#rows() == 2 and f.psFilter.psTip == "Filter (on)", "collected off")
local last
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() then last = r end end
last:Click()
assert(#rows() == 3, "reset")
stub.RunScript(byID(501), "OnClick", "LeftButton")
