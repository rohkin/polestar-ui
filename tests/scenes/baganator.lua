--@ title: Baganator: Polestar skin
--@ roots: BaganatorBackpackView
--@ stubs: stub_baganator.lua
-- Baganator's backpack view on its Blizzard skin, painted through its skin API: the stock art faded under our ground and hairlines, the title and category headers in Polestar's face, the close button and title-bar icon buttons as our header buttons, the text buttons and tabs on our control fill with our label fonts (the selected tab on the selected wash with an accent foot), the search box on our input fill, each slot an inset well edged in its quality from uncommon up. A quality change repaints the edge. Our Bags window starts off beside Baganator. Switched off, Baganator's art is back at once, and on again; a view made on another Baganator skin is left alone.
local f = stub.baganator()
local T = Polestar.Theme
assert(not PolestarUI.Enabled("bags") and not PolestarUI.Enabled("bank"), "our Bags or Bank is on beside Baganator")
PolestarUI.Switch("bags", true)
assert(not PolestarUI.Enabled("bags") and PolestarUIDB.modules.bags == nil, "Bags switched on beside Baganator")
assert(PolestarUI.Enabled("baganator"), "the skin is off")
local function edge(b) for _, r in ipairs({ b:GetRegions() }) do if r ~= b.icon and r.layer == "BORDER" and r.sublayer == 7 then return r end end end
local function painted(v)
	return v.NineSlice.TopEdge:GetAlpha() == 0 and v.Bg:GetAlpha() == 0 and v.SearchBox.Middle:GetAlpha() == 0 and v.Sort.Left:GetAlpha() == 0
		and v.items[1].IconBorder:GetAlpha() == 0 and v.items[1].SlotBackground:GetAlpha() == 0 and v.Divider:GetAlpha() == 0
		and v.TitleContainer.TitleText:GetFont() == T.FontSpec("title")
end
assert(painted(f), "not painted")
local ir, ig, ib = T.Color("icon")
local r0, g0, b0 = f.Sort.Icon:GetVertexColor()
assert(f.Sort.Icon.desaturated and r0 == ir and g0 == ig and b0 == ib and f.CloseButton:GetNormalTexture():GetAlpha() == 0, "the header buttons keep the game's art")
local function under(t) for _, x in ipairs({ t:GetRegions() }) do if x.layer == "OVERLAY" then return x end end end
assert(under(f.Tabs[1]):IsShown() and not under(f.Tabs[2]):IsShown(), "the selected tab is not marked")
PanelTemplates_SelectTab(f.Tabs[2]); PanelTemplates_DeselectTab(f.Tabs[1])
assert(under(f.Tabs[2]):IsShown() and not under(f.Tabs[1]):IsShown() and f.Tabs[2]:GetFontString():GetFont() == T.FontSpec("label"), "a tab change is not followed")
PanelTemplates_SelectTab(f.Tabs[1]); PanelTemplates_DeselectTab(f.Tabs[2])
assert(f.Deposit:GetFontString():GetFont() == T.FontSpec("label"), "the button label keeps the game's font")
local r, g, b = edge(f.items[1]):GetVertexColor()
assert(r == 0.64 and g == 0.21 and b == 0.93, "the epic slot is not edged in its quality")
stub.bagQuality(f.items[1], 2)
r, g, b = edge(f.items[1]):GetVertexColor()
assert(r == 0.12 and g == 1 and b == 0, "a quality change is not followed")
local wr, wg, wb = T.Wash("border")
r, g, b = edge(f.items[4]):GetVertexColor()
assert(r == wr and g == wg and b == wb, "a common slot is edged in a quality colour")
PolestarUI.Switch("baganator", false)
assert(f.Deposit:GetNormalFontObject() == GameFontNormal and f.CloseButton:GetNormalTexture():GetAlpha() == 1, "the button fonts and close art are not back")
assert(f.NineSlice.TopEdge:GetAlpha() == 1 and f.Bg:GetAlpha() == 1 and f.items[1].IconBorder:GetAlpha() == 1 and not edge(f.items[1]):IsShown()
	and f.TitleContainer.TitleText:GetFont() == "Fonts\\FRIZQT__.TTF", "not Baganator's art when off")
PolestarUI.Switch("baganator", true)
assert(painted(f), "not painted when on again")
stub.bagQuality(f.items[1], 4)
stub.bagSkin = "dark"
local d = stub.baganator("BaganatorDarkView")
assert(d.Bg:GetAlpha() == 1 and d.NineSlice.TopEdge:GetAlpha() == 1, "another Baganator skin is painted over")
d:Hide()
