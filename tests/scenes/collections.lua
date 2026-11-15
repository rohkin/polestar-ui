--@ title: Collections: Mounts
--@ roots: PolestarUICollections
--@ stubs: stub_collections.lua
-- The collections key opens ours on Mounts and closes it, never the stock journal; the mount journal and toy box keys open their pages and close on a second press; the micro overlay opens ours and hands a shift-click to the micro button (docs/CLIENT.md, rules 8 and 10). Mounts: favorites first, a collected unusable mount in danger, uncollected ones receding, the first selected.
local f
stub.pressKey("SHIFT-J")
f = PolestarUICollections
assert(f:IsShown() and not CollectionsJournal:IsShown(), "key")
stub.pressKey("SHIFT-J")
assert(not f:IsShown(), "no toggle")
stub.pressKey("CTRL-T")
assert(f:IsShown() and f.psToys:IsShown() and not f.psNav:IsShown(), "toy box key")
stub.pressKey("CTRL-M")
assert(f:IsShown() and f.psNav:IsShown(), "mount key while on toys: mounts")
stub.pressKey("CTRL-M")
assert(not f:IsShown(), "mount key again closes")
-- The pet journal and wardrobe keys open their pages, never the stock journal.
stub.pressKey("CTRL-P")
assert(f:IsShown() and f.Subtitle:GetText() == "Pet Journal" and not CollectionsJournal:IsShown(), "pet journal key")
stub.pressKey("CTRL-W")
assert(f:IsShown() and f.psLooks:IsShown() and not CollectionsJournal:IsShown(), "wardrobe key")
stub.pressKey("CTRL-W")
assert(not f:IsShown(), "wardrobe key again closes")
stub.advance(0.1)
local o = PolestarUICollectionsMicro
assert(o:IsShown() and o:GetAttribute("shift-type1") == "click" and o:GetAttribute("clickbutton") == CollectionsMicroButton, "no micro overlay")
assert(select(2, o:GetPoint(1)) ~= CollectionsMicroButton and o:GetLeft() == CollectionsMicroButton:GetLeft(), "overlay anchored to the micro button, or not over it")
PolestarUI.Show("collections", "mounts")
f:Hide()
stub.RunScript(o, "PostClick", "LeftButton")
assert(f:IsShown() and not CollectionsJournal:IsShown(), "micro")

-- The rail: the stock side tabs' icons, slim.
assert(f.Rail:GetWidth() == 48 and f.railButtons[1].Icon:GetTexture() == "Interface/ICONS/INV_Horse3Saddle008_Chestnut", "slim rail of the stock icons")
assert(f.railButtons[4] and f.railButtons[4]:IsShown() and not (f.railButtons[5] and f.railButtons[5]:IsShown()), "four pages, no heirlooms or warband scenes")

local rows = {}
for _, r in ipairs({ f.psNav.Child:GetChildren() }) do if r.psMount and r:IsShown() then rows[#rows + 1] = r end end
assert(#rows == 10, "rows: " .. #rows)
assert(rows[1].psMount.name == "Brown Horse" and rows[1].Star:IsShown() and rows[1].Sel:IsShown(), "favorite first and selected")
assert(f.footerButtons.right[1].Label:GetText() == "Mount" and f.footerButtons.right[1]:IsEnabled(), "mount button")
assert(f.psStatus:GetText() == "7 mounts collected" and f.psStatus:GetParent() == f.TabRow, "status: " .. f.psStatus:GetText())
assert(f.Title:GetText() == "Collections" and f.Subtitle:GetText() == "Mounts", "band")
assert(f.psDetail.Source:GetText():find("Vendor: Katie Hunter", 1, true), "source colour codes not stripped")
-- Pick the turtle, summon it, then dismount.
local turtle
for _, r in ipairs(rows) do if r.psMount.name == "Riding Turtle" then turtle = r end end
stub.RunScript(turtle, "OnClick", "LeftButton")
assert(f.psDetail.Name:GetText() == "Riding Turtle", "select")
-- The scene at the stock MountDisplay's aspect (407 by 514), centred in the pane: the game's cameras frame it for that.
do
	local m, d = f.psDetail.Model, f.psDetail
	assert(math.abs(m:GetWidth() / m:GetHeight() - 407 / 514) < 0.01 and m:GetHeight() <= d:GetHeight() - 2, "mount scene aspect")
end
f.footerButtons.right[1]:Click()
assert(stub.summoned == 5 and f.footerButtons.right[1].Label:GetText() == "Dismount", "summon")
f.footerButtons.right[1]:Click()
assert(stub.dismissed and f.footerButtons.right[1].Label:GetText() == "Mount", "dismount")
-- A collected mount drags to the bars; an uncollected one picks nothing.
stub.RunScript(turtle, "OnDragStart")
assert(stub.picked == "mount:5", "drag: " .. tostring(stub.picked))
stub.picked = nil
stub.RunScript(rows[10], "OnDragStart")
assert(not stub.picked, "uncollected mount dragged")
-- Right-click: the stock menu; Set Favorite moves the turtle up at once.
stub.RunScript(turtle, "OnClick", "RightButton")
assert(PolestarMenu:IsShown() and PolestarMenu.rows[2].psItem.text == "Set Favorite", "row menu")
PolestarMenu.rows[2]:Click()
rows = {}
for _, r in ipairs({ f.psNav.Child:GetChildren() }) do if r.psMount and r:IsShown() then rows[#rows + 1] = r end end
assert(rows[2].psMount.name == "Riding Turtle" and rows[2].Star:IsShown() and rows[2].Sel:IsShown(), "favorite not redrawn at once")
-- Shift-click links it.
local mod = IsModifiedClick
IsModifiedClick = function(k) return k == "CHATLINK" end
stub.RunScript(rows[2], "OnClick", "LeftButton")
IsModifiedClick = mod
assert(stub.linked == "[mount:30174]", "link: " .. tostring(stub.linked))
-- The raptor: collected, unusable here; the button greyed with the client's reason.
local raptor
for _, r in ipairs(rows) do if r.psMount.name == "Swift Razzashi Raptor" then raptor = r end end
stub.RunScript(raptor, "OnClick", "LeftButton")
assert(not f.footerButtons.right[1]:IsEnabled() and f.footerButtons.right[1].psReason == "You can't use that mount here.", "unusable mount's button")
-- Last, the new mount: "New" on its row and title, Unwrap on the button.
for _, r in ipairs(rows) do if r.psMount.fanfare then stub.RunScript(r, "OnClick", "LeftButton") end end
assert(f.footerButtons.right[1].Label:GetText() == "Unwrap" and f.psDetail.New:IsShown(), "new mount")
-- The "..." menu: the stock "show player" toggle.
f.psMenu:Click()
assert(PolestarMenu.rows[1].psItem.text == "Show character on mount", "options")
f.psMenu:Click()
