-- Baganator (the bag addon), as far as Addons/Baganator.lua reaches it: its
-- public skin API (Baganator.API.Skins, Baganator 857: RegisterListener,
-- GetAllFrames, GetCurrentSkin) and Baganator.Skins.AddFrame, which hands
-- each new frame to the listeners once. stub.baganator() builds a backpack
-- view in the shapes Baganator makes it (ButtonFrameTemplate with its
-- NineSlice, Bg, TopTileStreaks, title and Inset; a SearchBoxTemplate box;
-- UIPanelButtonTemplate icon buttons; item buttons with icon, IconBorder,
-- SlotBackground; category headers with an arrow; a divider), the stock art
-- as colour textures so the preview draws it.

stub.bagSkin = "blizzard"
local frames, listeners, added = {}, {}, {}

Baganator = { API = { Skins = {} }, Skins = {} }
function Baganator.API.Skins.GetCurrentSkin() return stub.bagSkin end
function Baganator.API.Skins.GetAllFrames() return frames end
function Baganator.API.Skins.RegisterListener(fn) listeners[#listeners + 1] = fn end
function Baganator.Skins.AddFrame(regionType, region, tags)
	if added[region] then return end
	added[region] = true
	local d = { regionType = regionType, region = region, tags = tags }
	frames[#frames + 1] = d
	for _, fn in ipairs(listeners) do fn(d) end
end

local FACE = "Fonts\\FRIZQT__.TTF"
local GOLD = { 1, 0.82, 0 }

local function art(f, key, layer, r, g, b, a)
	local t = f:CreateTexture(nil, layer or "BACKGROUND")
	t:SetColorTexture(r, g, b, a or 1)
	if key then f[key] = t end
	return t
end

local function text(f, s, size)
	local fs = f:CreateFontString(nil, "ARTWORK")
	fs:SetFont(FACE, size or 12, "")
	fs:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
	fs:SetText(s)
	return fs
end

-- A NineSlice holder with its nine pieces, a brown border round a dark centre.
local function nineSlice(f)
	local n = CreateFrame("Frame", nil, f)
	n:SetAllPoints(f)
	local e = 4
	local function piece(key, p1, p2, w, h, x1, y1, x2, y2)
		local t = art(n, key, "BORDER", 0.45, 0.32, 0.18)
		t:SetPoint(p1, f, p1, x1 or 0, y1 or 0)
		if p2 then t:SetPoint(p2, f, p2, x2 or 0, y2 or 0) end
		if w then t:SetWidth(w) end
		if h then t:SetHeight(h) end
	end
	piece("TopLeftCorner", "TOPLEFT", nil, e, e)
	piece("TopRightCorner", "TOPRIGHT", nil, e, e)
	piece("BottomLeftCorner", "BOTTOMLEFT", nil, e, e)
	piece("BottomRightCorner", "BOTTOMRIGHT", nil, e, e)
	piece("TopEdge", "TOPLEFT", "TOPRIGHT", nil, e, e, 0, -e, 0)
	piece("BottomEdge", "BOTTOMLEFT", "BOTTOMRIGHT", nil, e, e, 0, -e, 0)
	piece("LeftEdge", "TOPLEFT", "BOTTOMLEFT", e, nil, 0, -e, 0, e)
	piece("RightEdge", "TOPRIGHT", "BOTTOMRIGHT", e, nil, 0, -e, 0, e)
	local c = art(n, "Center", "BACKGROUND", 0.08, 0.07, 0.06)
	c:SetPoint("TOPLEFT", f, "TOPLEFT", e, -e)
	c:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -e, e)
	f.NineSlice = n
	return n
end

-- UIPanelButtonTemplate's thirds (red), with its highlight.
local function thirds(b, r, g, bl)
	local l = art(b, "Left", "BACKGROUND", r, g, bl)
	l:SetPoint("TOPLEFT")
	l:SetPoint("BOTTOMLEFT")
	l:SetWidth(8)
	local rt = art(b, "Right", "BACKGROUND", r, g, bl)
	rt:SetPoint("TOPRIGHT")
	rt:SetPoint("BOTTOMRIGHT")
	rt:SetWidth(8)
	local m = art(b, "Middle", "BACKGROUND", r, g, bl)
	m:SetPoint("TOPLEFT", l, "TOPRIGHT")
	m:SetPoint("BOTTOMRIGHT", rt, "BOTTOMLEFT")
end

-- A Button's font objects per state, as the client applies them: the label
-- takes the state's object (enabled: Normal; disabled: Disabled).
local function fontStates(b)
	local objs = {}
	local function apply(self)
		local o = self:IsEnabled() and objs.Normal or objs.Disabled or objs.Normal
		local fs = self:GetFontString()
		if o and fs then
			fs:SetFont(o:GetFont())
			fs:SetTextColor(o:GetTextColor())
		end
	end
	for _, s in ipairs({ "Normal", "Highlight", "Disabled" }) do
		b["Set" .. s .. "FontObject"] = function(self, o) objs[s] = o; apply(self) end
		b["Get" .. s .. "FontObject"] = function() return objs[s] end
	end
	b.Enable = function(self) stub.Methods.Enable(self); apply(self) end
	b.Disable = function(self) stub.Methods.Disable(self); apply(self) end
end

-- PanelTabButtonTemplate's selection (SharedUIPanelTemplates.lua).
PanelTemplates_SelectTab = PanelTemplates_SelectTab or function(tab)
	tab.Left:Hide(); tab.Middle:Hide(); tab.Right:Hide()
	tab:Disable()
	tab:SetDisabledFontObject(GameFontHighlightSmall)
	tab.LeftActive:Show(); tab.MiddleActive:Show(); tab.RightActive:Show()
end
PanelTemplates_DeselectTab = PanelTemplates_DeselectTab or function(tab)
	tab.Left:Show(); tab.Middle:Show(); tab.Right:Show()
	tab:Enable()
	tab.LeftActive:Hide(); tab.MiddleActive:Hide(); tab.RightActive:Hide()
end

-- A bank-style tab: thirds (brown), their Active versions (gold), a label.
local function tabButton(parent, label)
	local t = CreateFrame("Button", nil, parent)
	t:SetSize(90, 26)
	thirds(t, 0.3, 0.22, 0.12)
	for _, k in ipairs({ "LeftActive", "MiddleActive", "RightActive" }) do
		local a = art(t, k, "BACKGROUND", 0.6, 0.45, 0.1)
		a:SetAllPoints(t)
		a:Hide()
	end
	local fs = text(t, label, 10)
	fs:SetPoint("CENTER")
	t:SetFontString(fs)
	t.Text = fs
	fontStates(t)
	t:SetNormalFontObject(GameFontNormalSmall)
	t:SetHighlightFontObject(GameFontHighlightSmall)
	Baganator.Skins.AddFrame("TabButton", t)
	return t
end

-- The red close button (UIPanelCloseButton).
local function closeButton(f)
	local c = CreateFrame("Button", nil, f)
	c:SetSize(24, 24)
	c:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)
	c:SetNormalTexture(art(c, nil, "ARTWORK", 0.75, 0.1, 0.05))
	c:GetNormalTexture():SetAllPoints(c)
	c:SetPushedTexture(art(c, nil, "ARTWORK", 0.5, 0.05, 0.02))
	c:GetPushedTexture():SetAllPoints(c)
	c:GetPushedTexture():Hide()
	local h = art(c, nil, "HIGHLIGHT", 1, 1, 1, 0.3)
	h:SetAllPoints(c)
	c:SetHighlightTexture(h)
	f.CloseButton = c
end

local function iconButton(parent, tag)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(32, 22)
	thirds(b, 0.55, 0.08, 0.05)
	local h = art(b, nil, "HIGHLIGHT", 1, 1, 1, 0.3)
	h:SetAllPoints(b)
	b:SetHighlightTexture(h)
	b.Icon = art(b, nil, "ARTWORK", 1, 0.82, 0)
	b.Icon:SetSize(14, 14)
	b.Icon:SetPoint("CENTER")
	Baganator.Skins.AddFrame("IconButton", b, { tag })
	return b
end

-- The game's quality ring, as SetItemButtonQuality paints it: shown in the
-- quality's colour, hidden with none.
local QUALITY = { [0] = { 0.62, 0.62, 0.62 }, { 1, 1, 1 }, { 0.12, 1, 0 }, { 0, 0.44, 0.87 }, { 0.64, 0.21, 0.93 } }
function stub.bagQuality(b, q)
	local c = q and QUALITY[q]
	b.IconBorder:SetShown(c ~= nil)
	if c then b.IconBorder:SetVertexColor(c[1], c[2], c[3]) end
end

local function itemButton(parent, q, r, g, b)
	local btn = CreateFrame("Button", nil, parent)
	btn:SetSize(37, 37)
	btn.icon = art(btn, nil, "BORDER", r or 0, g or 0, b or 0, r and 1 or 0)
	btn.icon:SetAllPoints(btn)
	btn.SlotBackground = art(btn, nil, "BACKGROUND", 0.2, 0.17, 0.12)
	btn.SlotBackground:SetAllPoints(btn.icon)
	btn.IconBorder = art(btn, nil, "OVERLAY", 1, 1, 1, 0.9)
	btn.IconBorder:SetPoint("TOPLEFT", -2, 2)
	btn.IconBorder:SetPoint("BOTTOMRIGHT", 2, -2)
	btn.IconBorder:Hide()
	Baganator.Skins.AddFrame("ItemButton", btn)
	stub.bagQuality(btn, q)
	return btn
end

local function header(parent, label)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(200, 20)
	local fs = text(b, label, 14)
	fs:SetPoint("LEFT", 20, 0)
	b:SetFontString(fs)
	b.arrow = art(b, nil, "ARTWORK", GOLD[1], GOLD[2], GOLD[3])
	b.arrow:SetSize(10, 10)
	b.arrow:SetPoint("LEFT", 2, 0)
	Baganator.Skins.AddFrame("CategorySectionHeader", b)
	return b
end

-- A backpack view: title, search, two icon buttons, two categories of items
-- (one row each) parted by a divider.
function stub.baganator(name)
	local f = CreateFrame("Frame", name or "BaganatorBackpackView", UIParent)
	f:SetSize(360, 260)
	f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -20)
	f.Bg = art(f, nil, "BACKGROUND", 0.1, 0.09, 0.08)
	f.Bg:SetPoint("TOPLEFT", 4, -21)
	f.Bg:SetPoint("BOTTOMRIGHT", -4, 4)
	f.TopTileStreaks = art(f, nil, "BACKGROUND", 0.3, 0.22, 0.12)
	f.TopTileStreaks:SetPoint("TOPLEFT", 4, -21)
	f.TopTileStreaks:SetPoint("TOPRIGHT", -4, -21)
	f.TopTileStreaks:SetHeight(40)
	nineSlice(f)
	closeButton(f)
	f.TitleContainer = CreateFrame("Frame", nil, f)
	f.TitleContainer:SetPoint("TOPLEFT", 0, 0)
	f.TitleContainer:SetPoint("TOPRIGHT", 0, 0)
	f.TitleContainer:SetHeight(20)
	f.TitleContainer.TitleText = text(f.TitleContainer, "Cerys's Bags", 12)
	f.TitleContainer.TitleText:SetPoint("CENTER")
	Baganator.Skins.AddFrame("ButtonFrame", f, { "backpack" })

	local s = CreateFrame("EditBox", nil, f)
	s:SetSize(200, 20)
	s:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -32)
	thirds(s, 0.25, 0.22, 0.18)
	Baganator.Skins.AddFrame("SearchBox", s)
	f.SearchBox = s

	f.Sort = iconButton(f, "sort")
	f.Sort:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -31)
	f.Customise = iconButton(f, "customise")
	f.Customise:SetPoint("RIGHT", f.Sort, "LEFT", -4, 0)

	f.items = {}
	local function row(label, y, list)
		local h = header(f, label)
		h:SetPoint("TOPLEFT", f, "TOPLEFT", 16, y)
		for i, it in ipairs(list) do
			local b = itemButton(f, it[1], it[2], it[3], it[4])
			b:SetPoint("TOPLEFT", f, "TOPLEFT", 16 + (i - 1) * 41, y - 24)
			f.items[#f.items + 1] = b
		end
		return h
	end
	f.Header1 = row("Equipment", -64, { { 4, 0.5, 0.3, 0.6 }, { 3, 0.3, 0.4, 0.6 }, { 2, 0.3, 0.5, 0.3 }, { 1, 0.5, 0.45, 0.4 } })
	local div = CreateFrame("Frame", nil, f)
	div:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -138)
	div:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -138)
	div:SetHeight(1)
	div.Divider = art(div, nil, "BACKGROUND", GOLD[1], GOLD[2], GOLD[3])
	div.Divider:SetPoint("TOPLEFT")
	div.Divider:SetPoint("TOPRIGHT")
	div.Divider:SetHeight(4)
	Baganator.Skins.AddFrame("Divider", div.Divider)
	f.Divider = div.Divider
	f.Tabs = { tabButton(f, "Character"), tabButton(f, "Warband") }
	f.Tabs[1]:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 12, 0)
	f.Tabs[2]:SetPoint("LEFT", f.Tabs[1], "RIGHT", 4, 0)
	PanelTemplates_SelectTab(f.Tabs[1])
	PanelTemplates_DeselectTab(f.Tabs[2])
	f.Deposit = CreateFrame("Button", nil, f)
	f.Deposit:SetSize(110, 22)
	f.Deposit:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 12)
	thirds(f.Deposit, 0.55, 0.08, 0.05)
	local dl = text(f.Deposit, "Deposit All", 12)
	dl:SetPoint("CENTER")
	f.Deposit:SetFontString(dl)
	fontStates(f.Deposit)
	f.Deposit:SetNormalFontObject(GameFontNormal)
	f.Deposit:SetHighlightFontObject(GameFontHighlight)
	f.Deposit:SetDisabledFontObject(GameFontDisable)
	Baganator.Skins.AddFrame("Button", f.Deposit)
	f.Header2 = row("Consumables", -150, { { 1, 0.6, 0.2, 0.2 }, { 0, 0.4, 0.4, 0.4 }, { nil }, { nil } })
	return f
end
