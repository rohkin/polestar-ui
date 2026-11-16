--@ title: Collections: Pets
--@ roots: PolestarUICollections
--@ stubs: stub_collections.lua
-- The Classic pet journal: favorites first, the summoned pet's well in the accent, a new pet marked, the other faction's pet red, a revoked one and uncollected ones receding; the card shows the selected pet (custom name over its species and source). Summon / Dismiss / Unwrap on the footer; right-click the stock menu, drag to the bars, shift-click links. Search and the Collected / Not Collected filter; the last page is kept.
PolestarUI.Show("collections", "pets")
local f = PolestarUICollections
local function rows()
	local t = {}
	for _, r in ipairs({ f.psNav.Child:GetChildren() }) do if r.psPet and r:IsShown() then t[#t + 1] = r end end
	return t
end
local function row(name) for _, r in ipairs(rows()) do if r.psPet.name == name then return r end end end
local foot = f.footerButtons.right[1]
assert(f.Subtitle:GetText() == "Pet Journal" and f.psStatus:GetText() == "6 pets collected", "status: " .. f.psStatus:GetText())
local t = rows()
assert(#t == 8 and t[1].psPet.name == "Mechanical Squirrel" and t[1].Star:IsShown() and t[1].Sel:IsShown(), "favorite first and selected")
assert(t[8].psPet.owned == false and t[8].Well.Icon.desaturated, "uncollected not receding")
assert(row("Lil' K.T.").Well.Icon.vertexColor ~= nil and row("Ancona Chicken").Well.Icon.desaturated, "never-summonable or revoked pet")
assert(row("Hyacinth Macaw").New:IsShown(), "new pet not marked")
-- The summoned cat: its custom name on the card, its species beneath; Dismiss.
stub.RunScript(row("Mister Whiskers"), "OnClick", "LeftButton")
assert(f.psDetail.Name:GetText() == "Mister Whiskers" and f.psDetail.Source:GetText():find("^Black Tabby Cat\nVendor: Donni Anthania"), "card: " .. tostring(f.psDetail.Source:GetText()))
assert(f.psDetail.Pet:IsShown() and not f.psDetail.Model:IsShown(), "pets on their own scene (stock PetCard.modelScene)")
-- Stock's ViewInsets (0, 0, 300, -50 on a 514-high card), scaled to our scene's height.
local insets
f.psDetail.Pet.SetViewInsets = function(_, ...) insets = { ... } end -- the stub's scene has none
PolestarUI.Show("collections", "pets")
local ph = f.psDetail.Pet:GetHeight()
assert(insets and insets[1] == 0 and insets[2] == 0 and math.abs(insets[3] - 300 * ph / 514) < 0.01 and math.abs(insets[4] + 50 * ph / 514) < 0.01, "pet view insets: " .. tostring(insets and insets[3]))
f.psDetail.Pet.SetViewInsets = nil
assert(foot.Label:GetText() == "Dismiss" and foot:IsEnabled(), "dismiss button")
foot:Click()
assert(stub.petDismissed == stub.pets[2].guid and foot.Label:GetText() == "Summon", "dismiss")
foot:Click()
assert(stub.petSummoned == stub.pets[2].guid and foot.Label:GetText() == "Dismiss", "summon")
-- The other faction's pet: Summon greyed with the client's reason.
stub.RunScript(row("Lil' K.T."), "OnClick", "LeftButton")
assert(not foot:IsEnabled() and foot.psReason == "This pet can't be summoned by your faction.", "never summonable: " .. tostring(foot.psReason))
-- One not collected: the card by species, nothing to summon.
stub.RunScript(row("Panda Cub"), "OnClick", "LeftButton")
assert(f.psDetail.Name:GetText() == "Panda Cub" and not foot:IsEnabled() and foot.psReason == "You don't have this pet.", "uncollected card")
stub.RunScript(row("Panda Cub"), "OnDragStart")
assert(not stub.picked, "uncollected pet dragged")
-- Drag and link a collected one; the revoked one picks nothing.
stub.RunScript(row("Prairie Dog"), "OnDragStart")
assert(stub.picked == "pet:" .. stub.pets[4].guid, "drag: " .. tostring(stub.picked))
stub.picked = nil
stub.RunScript(row("Ancona Chicken"), "OnDragStart")
assert(not stub.picked, "revoked pet dragged")
local mod = IsModifiedClick
IsModifiedClick = function(k) return k == "CHATLINK" end
stub.RunScript(row("Prairie Dog"), "OnClick", "LeftButton")
IsModifiedClick = mod
assert(stub.linked == "[Prairie Dog]", "link: " .. tostring(stub.linked))
-- Right-click: Summon and Set Favorite; the favorite moves up at once.
stub.RunScript(row("Prairie Dog"), "OnClick", "RightButton")
assert(PolestarMenu.rows[1].psItem.text == "Summon" and PolestarMenu.rows[2].psItem.text == "Set Favorite", "pet menu")
PolestarMenu.rows[2]:Click()
assert(rows()[2].psPet.name == "Prairie Dog" and rows()[2].Star:IsShown(), "favorite not redrawn at once")
-- The new macaw: Unwrap on its menu and the footer; unwrapped, it summons.
stub.RunScript(row("Hyacinth Macaw"), "OnClick", "RightButton")
assert(PolestarMenu.rows[1].psItem.text == "Unwrap" and not PolestarMenu.rows[2]:IsShown(), "unwrap menu")
Polestar.Widgets.HideMenu()
stub.RunScript(row("Hyacinth Macaw"), "OnClick", "LeftButton")
assert(foot.Label:GetText() == "Unwrap" and f.psDetail.New:IsShown(), "unwrap button")
f.psDetail.Pet.StartUnwrapAnimation = function(_, done) done() end -- the stub's scene plays no animation
foot:Click()
assert(not stub.pets[3].fanfare and foot.Label:GetText() == "Summon", "unwrapped")
-- Search and filter, on the client.
f.psFilter:Click()
f.Search:SetText("cat")
stub.RunScript(f.Search, "OnTextChanged")
assert(stub.petSearch == "cat" and #rows() == 1 and f.psStatus:GetText() == "6 pets collected · 1 shown", "search: " .. f.psStatus:GetText())
f.Search:SetText("")
stub.RunScript(f.Search, "OnTextChanged")
assert(PolestarMenu.rows[2].psItem.text == "Collected" and PolestarMenu.rows[3].psItem.text == "Not Collected", "filter menu")
PolestarMenu.rows[3]:Click()
assert(#rows() == 6 and f.psFilter.psTip == "Search and filter (on)", "not collected off")
local last
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() then last = r end end
last:Click()
assert(#rows() == 8 and f.psFilter.psTip == "Search and filter", "reset")
-- Leaving the page clears the "new" marks (PetJournal_OnHide); the last page is kept.
f:Hide()
assert(stub.petFanfaresCleared, "fanfares not cleared")
PolestarUI.Show("collections")
assert(f.Subtitle:GetText() == "Pet Journal" and PolestarUIDB.collectionsPage == "pets", "last page not kept")
stub.RunScript(row("Mister Whiskers"), "OnClick", "LeftButton")
