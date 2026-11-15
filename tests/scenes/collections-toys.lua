--@ title: Collections: Toy Box
--@ roots: PolestarUICollections
--@ stubs: stub_collections.lua
-- The toy box: 18 a page, the favorite first, uncollected toys desaturated and receding, a new toy marked; the footer and the wheel turn pages; a click uses a toy, a right-click favorites it at once, a drag picks it up, shift-click links it.
PolestarUI.Show("collections", "toys")
local f = PolestarUICollections
local function tiles()
	local t = {}
	for _, c in ipairs({ f.psToys:GetChildren() }) do if c.psID and c:IsShown() then t[#t + 1] = c end end
	return t
end
local t = tiles()
assert(#t == 18, "tiles: " .. #t)
assert(t[1].psID == 1004 and t[1].Star:IsShown(), "favorite first")
assert(f.psStatus:GetText() == "16 of 24 toys collected · Page 1 of 2", "subtitle: " .. f.psStatus:GetText())
assert(not f.footerButtons.right[2]:IsEnabled() and f.footerButtons.right[1]:IsEnabled(), "Previous greyed on page 1")
-- An uncollected toy: desaturated, its name receding; a click uses nothing.
local un
for _, c in ipairs(t) do if c.psID == 1003 then un = c end end
assert(un.Well.Icon.desaturated, "uncollected not desaturated")
stub.RunScript(un, "OnClick", "LeftButton")
assert(not stub.usedToy, "uncollected toy used")
-- A collected one: used on click, picked up on drag, linked on shift-click.
stub.RunScript(t[2], "OnClick", "LeftButton")
assert(stub.usedToy == 1001, "use: " .. tostring(stub.usedToy))
stub.RunScript(t[2], "OnDragStart")
assert(stub.picked == "toy:1001", "drag: " .. tostring(stub.picked))
local mod = IsModifiedClick
IsModifiedClick = function(k) return k == "CHATLINK" end
stub.RunScript(t[2], "OnClick", "LeftButton")
IsModifiedClick = mod
assert(stub.linked == "[Hearthstone Board]", "link: " .. tostring(stub.linked))
-- The new toy: its first click unwraps it, uses nothing.
local new
for _, c in ipairs(t) do if c.psID == 1007 then new = c end end
assert(new.New:IsShown(), "new toy not marked")
stub.usedToy = nil
stub.RunScript(new, "OnClick", "LeftButton")
assert(not stub.usedToy and not stub.toys[7].fanfare, "unwrap")
-- Right-click: Set Favorite, redrawn at once (the Orb joins the favorites at the top).
stub.RunScript(t[3], "OnClick", "RightButton")
assert(PolestarMenu.rows[1].psItem.text == "Set Favorite", "toy menu")
PolestarMenu.rows[1]:Click()
t = tiles()
assert(t[1].psID == 1002 and t[1].Star:IsShown() and t[2].psID == 1004, "favorite not redrawn at once")
-- The wheel and the footer turn pages.
stub.RunScript(f.psToys, "OnMouseWheel", -1)
assert(f.psStatus:GetText():find("Page 2 of 2", 1, true) and #tiles() == 6, "wheel")
stub.RunScript(f.psToys, "OnMouseWheel", -1)
assert(f.psStatus:GetText():find("Page 2 of 2", 1, true), "past the last page")
f.footerButtons.right[2]:Click()
assert(f.psStatus:GetText():find("Page 1 of 2", 1, true), "previous")
f.footerButtons.right[1]:Click()
assert(f.psStatus:GetText():find("Page 2 of 2", 1, true) and not f.footerButtons.right[1]:IsEnabled(), "next")
-- Drawn back on page 1: the favorites first, Toy 3 uncollected, the Orb cooling down.
f.footerButtons.right[2]:Click()
