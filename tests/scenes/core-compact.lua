--@ title: Core: the compact grid and top tabs (house style, then the game's looks)
--@ roots: PolestarUITestCompact
-- ns.Compact: a 60 band (Display title, its subtitle on one line), 36 tabs (32 in the game's looks), a 44 footer, the pad 8 in from the skin's; the band's art cropped to the band, the body's view and width by those sizes, after every ShellTabs and ShellFooter. ns.TopNav: the page nav as tabs (no sidebar), each keeping a nav row's state (count, dot, locked with its tooltip, a game icon), the search and the filter on the tab row's right end; a locked tab's click does nothing.
local ns, W = PolestarUI, Polestar.Widgets
local f = W.Shell("PolestarUITestCompact", { scalePath = "ui.menuScale", width = 640, height = 420, searchPlaceholder = "Search" })
ns.Compact(f)
f.psFilter = W.IconButton(f.TabRow, "sliders", 30, "Filter", function() end, 14)
Polestar.Theme.Skin(f.psFilter, "editbox")
local picked
ns.TopNav(f, {
	{ key = "a", label = "General", icon = 136243, dot = true },
	{ key = "b", label = "Arcane", count = 12 },
	{ key = "c", label = "Secondary", locked = true, tip = "Learn it from a trainer." },
}, "a", function(k) picked = k end)
W.ShellTitle(f, "Compact", "Level 24 Mage · Every point is spent.")
ns.Footer(f, { { label = "Reset" } }, { { label = "Apply", opts = { primary = true } } })
W.ShellBody(f, 600)
f:Show()
assert(f.Header:GetHeight() == 60 and f.TabRow:GetHeight() == 36 and f.Footer:GetHeight() == 44 and f.psPad == 24, "not the compact grid")
assert(f.psViewH == 420 - 60 - 36 - 44 and f.BodyWidth == 640 - 2 - 48 and f.Body:GetWidth() == 640 - 2, "body not laid out by the compact grid")
assert(f.Band.texCoord[4] == 60 / Polestar.Theme.BAND_H, "band art stretched")
assert(not f.Sidebar:IsShown() and f.Search:GetParent() == f.TabRow and select(2, f.psFilter:GetPoint(1)) == f.TabRow, "search not on the tab row")
local t = f.tabButtons
assert(t[1].psNavDot:IsShown() and t[1].psNavIcon:IsShown() and t[2].psNavCount:GetText() == "12" and t[3]:GetAlpha() < 1, "a tab lost its nav state")
assert(select(4, t[1]:GetPoint(1)) == 24 - 12 and select(4, f.footerButtons.left[1]:GetPoint(1)) == 24, "tabs or footer not on the compact pad")
t[3]:Click()
assert(picked == nil, "a locked tab opened")
stub.RunScript(t[3], "OnEnter")
assert(GameTooltip.lines[1] == "Secondary" and GameTooltip.lines[2]:find("trainer"), "no tooltip on the locked tab")
t[2]:Click()
assert(picked == "b", "a tab did not select")
--@ panel
--@ roots: PolestarUITestCompact
local ns, W = PolestarUI, Polestar.Widgets
Polestar.Set("ui.skin", "forever")
local f = W.Shell("PolestarUITestCompact", { scalePath = "ui.menuScale", width = 640, height = 420, searchPlaceholder = "Search" })
ns.WindowMenu(f, "spellbook")
ns.Compact(f)
f.psFilter = W.IconButton(f.TabRow, "sliders", 30, "Filter", function() end, 14)
Polestar.Theme.Skin(f.psFilter, "editbox")
ns.TopNav(f, {
	{ key = "a", label = "General", icon = 136243, dot = true },
	{ key = "b", label = "Arcane", count = 12 },
	{ key = "c", label = "Secondary", locked = true, tip = "Learn it from a trainer." },
}, "b", function() end)
W.ShellTitle(f, "Compact", "Level 24 Mage · Every point is spent.")
ns.Footer(f, { { label = "Reset" } }, { { label = "Apply", opts = { primary = true } } })
W.ShellBody(f, 600)
f:Show()
assert(f.TabRow:GetHeight() == 32 and f.psPad == 20 and not f.Close:IsShown(), "not the game's looks")
assert(f.psViewH == 420 - 60 - 32 - 44, "body not laid out by the compact grid")
local p, rel = f.psMenu:GetPoint(1)
assert(rel == f.Header and select(4, f.psMenu:GetPoint(1)) == -20, "menu not on the pad without the close button")
