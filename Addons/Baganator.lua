-- Baganator in Polestar's look (docs/addons.md). Baganator keeps its own bags,
-- categories and settings; we only repaint the frames it hands to skins,
-- through its public skin API (Baganator.API.Skins: RegisterListener,
-- GetAllFrames, GetCurrentSkin). That API cannot add an entry to Baganator's
-- skin list, so we paint over its default "Blizzard" skin: pick Blizzard in
-- Baganator's settings (any other skin is left as Baganator draws it), and
-- `/pui baganator off` gives the plain Blizzard look back, live.
-- As the tooltips (docs/CLIENT.md, rule 15): Baganator's art faded with
-- SetAlpha, a ground and hairlines of ours added, kept in weak tables, never a
-- key of ours on its frames (but its view windows, which take our windows' own
-- Theme.Skin paint: no secure code reads them). Its item buttons are the game's secure item
-- template; only their quality ring (IconBorder) is hooked, which only paint
-- code touches. Polestar's own bag marks (upgrade arrow, step glow, quest
-- mark) are Baganator corner widgets and stay as they are.
-- With Baganator in, our Bags and Bank are blocked (blockedBy, as beside
-- Bagnon): two bag windows would fight over the same keys.

local ADDON, ns = ...

ns.AfterLogin(function()
local B = _G.Baganator
local API = B and B.API and B.API.Skins
if not (API and API.RegisterListener and API.GetAllFrames and API.GetCurrentSkin) then return end

for _, k in ipairs({ "bags", "bank" }) do
	if ns.modules[k] then ns.modules[k].blockedBy = "Baganator" end
end

local Theme = Polestar.Theme
local SKIN = "blizzard" -- Baganator's default skin, the one we paint over
local WHITE = Theme.Media("white")
local masque = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Masque") -- Masque skins the slots
local M = { noun = "Baganator skin" }

local looks = setmetatable({}, { __mode = "k" }) -- region -> what we added and the alphas we faded
local skinOf = setmetatable({}, { __mode = "k" }) -- region -> Baganator's skin when it was made

local function active(r) return M.psStarted and ns.Enabled("baganator") and skinOf[r] == SKIN end

-- Regions faded while on, back at the alpha they had when off.
local function fade(l, on, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		if type(r) == "table" and r.SetAlpha then
			l.alpha[r] = l.alpha[r] or r:GetAlpha()
			r:SetAlpha(on and 0 or l.alpha[r])
		end
	end
end

local function nine(holder, on) if holder then ns.FadeNine(holder, on and 0 or 1) end end

-- Our fill on `f` round `rel` and the four hairlines.
local function ground(l, f, rel)
	l.fill = f:CreateTexture(nil, "BACKGROUND", nil, -8)
	l.fill:SetTexture(WHITE)
	l.fill:SetAllPoints(rel)
	l.edges = ns.Hairlines(f, rel)
end

local function box(l, on, r, g, b, a)
	l.fill:SetVertexColor(r, g, b, a)
	l.fill:SetShown(on)
	ns.PaintHairlines(l.edges, on, Theme.Color("border"))
end

-- A font string in a Polestar role at its own size and in a token; off, as it was.
local function face(l, fs, on, role, token)
	if not fs then return end
	l.font = l.font or { fs:GetFont() }
	l.color = l.color or { fs:GetTextColor() }
	local s = l.font
	if on then
		Theme.SetFace(fs, (Theme.FontSpec(role)), s[2] or 12, s[3] or "")
		fs:SetTextColor(Theme.Color(token))
	else
		if s[1] then Theme.SetFace(fs, s[1], s[2], s[3] or "") end
		fs:SetTextColor(unpack(l.color))
	end
end

-- The quality ring (hidden while on) read into our hairlines: its colour from
-- uncommon up, a plain edge for poor and common (grey and white), as
-- ns.PaintItem.
local function quality(b, l, on)
	local ring = rawget(b, "IconBorder")
	local r, g, bl = ring:GetVertexColor()
	if ring:IsShown() and math.max(r, g, bl) - math.min(r, g, bl) > 0.05 then
		ns.PaintHairlines(l.edges, on, r, g, bl, 1)
	else
		ns.PaintHairlines(l.edges, on, Theme.Wash("border"))
	end
end

-- A template's art pieces: UIPanelButton, SearchBox and InputBox (Left,
-- Middle/Mid, Right), the panel tabs (their Active and Highlight thirds) and
-- Baganator's side tabs (Background).
local PIECES = { "Left", "Middle", "Mid", "Right", "LeftActive", "MiddleActive", "RightActive",
	"LeftHighlight", "MiddleHighlight", "RightHighlight", "LeftDisabled", "MiddleDisabled", "RightDisabled", "Background" }

-- Our font objects, by role and colour token, repainted on each paint
-- (scheme, skin, text size).
local fonts = {}
local function fontObj(role, token)
	local key = role .. "_" .. token
	local o = fonts[key] or CreateFont("PolestarUIBaganator_" .. key)
	fonts[key] = o
	local path, size = Theme.FontSpec(role)
	Theme.SetFace(o, path, size, "")
	o:SetTextColor(Theme.Color(token))
	o:SetShadowOffset(1, -1)
	o:SetShadowColor(Theme.Color("shade"))
	return o
end

-- A button's label in our font objects, one per state: the client applies
-- the state's object on hover and enable/disable, so ours hold where a face
-- set on the label would not. Off, the button's own objects again.
local STATES = { "Normal", "Highlight", "Disabled" }
local function labels(f, l, on, set)
	if not (f.SetNormalFontObject and f.GetNormalFontObject) then return end
	if not l.fonts then
		l.fonts = {}
		for _, s in ipairs(STATES) do l.fonts[s] = f["Get" .. s .. "FontObject"](f) or false end
	end
	for _, s in ipairs(STATES) do
		local o = on and fontObj("label", set[s]) or l.fonts[s]
		if o then f["Set" .. s .. "FontObject"](f, o) end
	end
end
local BUTTON_FONTS = { Normal = "buttonText", Highlight = "text", Disabled = "textMuted" }
local TAB_FONTS = { Normal = "textDim", Highlight = "text", Disabled = "text" } -- a selected tab is disabled

-- The hover wash (a HIGHLIGHT texture: the client shows it on hover).
local function hoverWash(f, l, on)
	if not l.hover then
		l.hover = f:CreateTexture(nil, "HIGHLIGHT")
		l.hover:SetTexture(WHITE)
		l.hover:SetAllPoints(f)
	end
	l.hover:SetVertexColor(Theme.Wash("hover"))
	l.hover:SetShown(on)
end

-- A selected panel tab (PanelTemplates_SelectTab disables it): the selected
-- wash and an accent line along its foot.
local function tabState(f, l, on)
	local sel = on and not f:IsEnabled()
	if not l.under then
		l.under = f:CreateTexture(nil, "OVERLAY")
		l.under:SetTexture(WHITE)
		l.under:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 0)
		l.under:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 0)
		l.under:SetHeight(2)
	end
	l.under:SetVertexColor(Theme.Accent())
	l.under:SetShown(sel)
	l.fill:SetVertexColor(Theme.Color(sel and "selected" or "control"))
	labels(f, l, on, TAB_FONTS)
end

-- A button, tab or input: its art faded, our fill and hairlines, and on a
-- button our hover wash.
local function bar(f, l, on, token)
	if not l.fill then ground(l, f, f) end
	for _, k in ipairs(PIECES) do fade(l, on, rawget(f, k)) end
	if f.GetHighlightTexture then
		fade(l, on, f:GetHighlightTexture())
		hoverWash(f, l, on)
	end
	box(l, on, Theme.Color(token))
end

local function button(f, l, on)
	bar(f, l, on, "control")
	labels(f, l, on, BUTTON_FONTS)
end
local function input(f, l, on) bar(f, l, on, "inputBg") end
local function tab(f, l, on)
	bar(f, l, on, "control")
	tabState(f, l, on)
end

-- A glyph (an icon of the button's, or our own) in Polestar's header-button
-- colours: icon at rest, iconHover under the mouse.
local function tint(g, token) g:SetVertexColor(Theme.Color(token)) end
local function glyphHover(f, g)
	f:HookScript("OnEnter", function() if looks[f] and looks[f].on then tint(g, "iconHover") end end)
	f:HookScript("OnLeave", function() if looks[f] and looks[f].on then tint(g, "icon") end end)
end

-- Baganator's title-bar and search-row icon buttons, as our header buttons
-- (W.IconButton): no frame, the icon desaturated in our icon colour, the
-- hover wash.
local function iconButton(f, l, on)
	local icon = rawget(f, "Icon")
	if l.on == nil and icon then
		l.iconColor = { icon:GetVertexColor() }
		glyphHover(f, icon)
	end
	for _, k in ipairs(PIECES) do fade(l, on, rawget(f, k)) end
	if f.GetHighlightTexture then fade(l, on, f:GetHighlightTexture()) end
	hoverWash(f, l, on)
	if icon then
		icon:SetDesaturated(on)
		if on then tint(icon, "icon") else icon:SetVertexColor(unpack(l.iconColor)) end
	end
end

-- The window's close button (UIPanelCloseButton, red): its art faded, our
-- close glyph and hover wash.
local function closeButton(c, on)
	local l = looks[c] or { alpha = {} }
	looks[c] = l
	if not l.glyph then
		l.glyph = c:CreateTexture(nil, "ARTWORK")
		l.glyph:SetSize(14, 14)
		l.glyph:SetPoint("CENTER")
		glyphHover(c, l.glyph)
	end
	l.on = on
	fade(l, on, c:GetNormalTexture(), c.GetPushedTexture and c:GetPushedTexture(), c:GetHighlightTexture(),
		c.GetDisabledTexture and c:GetDisabledTexture())
	l.glyph:SetTexture(Theme.Media(Theme.Icon("close")))
	tint(l.glyph, "icon")
	l.glyph:SetShown(on)
	hoverWash(c, l, on)
end

local PAINT = {
	-- Theme.Skin's window paint, as on our own windows (ground at the
	-- player's Window opacity, border, shadow, in every Polestar skin); its
	-- keys go on Baganator's own view frame, which no secure code reads.
	-- Off: psBare hides it. Baganator's transparency slider fades only its own
	-- art, which stays hidden while ours is on.
	ButtonFrame = function(f, l, on)
		if l.on == nil then
			-- Baganator writes its Blizzard skin's alphas again on a setting change.
			f:HookScript("OnShow", function() if active(f) then fade(l, true, rawget(f, "Bg"), rawget(f, "TopTileStreaks")) end end)
		end
		f.psBare = (not on) or nil
		if on and not f.psSkin then Theme.Skin(f, "window") else Theme.Repaint(f) end
		nine(rawget(f, "NineSlice"), on)
		fade(l, on, rawget(f, "Bg"), rawget(f, "TopTileStreaks"))
		local inset = rawget(f, "Inset")
		if inset then
			nine(rawget(inset, "NineSlice"), on)
			fade(l, on, rawget(inset, "Bg"))
		end
		face(l, rawget(f, "TitleContainer") and rawget(f, "TitleContainer").TitleText, on, "title", "text")
		local close = rawget(f, "CloseButton")
		if close then closeButton(close, on) end
	end,
	InsetFrame = function(f, l, on)
		if not l.fill then ground(l, f, f) end
		nine(rawget(f, "NineSlice"), on)
		fade(l, on, rawget(f, "Bg"))
		box(l, on, 1, 1, 1, 0.04) -- Polestar's inset well
	end,
	Button = button,
	IconButton = iconButton,
	TabButton = tab,
	TopTabButton = tab,
	SideTabButton = function(f, l, on) bar(f, l, on, "control") end,
	SearchBox = input,
	EditBox = input,
	ItemButton = function(b, l, on)
		if masque or not rawget(b, "IconBorder") then return end
		if not l.fill then
			ground(l, b, rawget(b, "icon") or b)
			local function sync() if active(b) then quality(b, l, true) end end
			for _, m in ipairs({ "SetVertexColor", "Show", "Hide", "SetShown" }) do hooksecurefunc(rawget(b, "IconBorder"), m, sync) end
		end
		fade(l, on, rawget(b, "SlotBackground"), rawget(b, "IconBorder"), b.GetNormalTexture and b:GetNormalTexture())
		l.fill:SetVertexColor(Theme.Color("inputBg"))
		l.fill:SetShown(on)
		quality(b, l, on)
	end,
	CategorySectionHeader = function(b, l, on)
		face(l, b:GetFontString(), on, "heading", "textDim")
		local arrow = rawget(b, "arrow")
		if arrow then
			arrow:SetDesaturated(on)
			if on then arrow:SetVertexColor(Theme.Color("textMuted")) else arrow:SetVertexColor(1, 1, 1) end
		end
	end,
	-- A texture: faded, our hairline along the top of its frame instead.
	Divider = function(d, l, on)
		local f = d:GetParent()
		if not l.line then
			l.line = f:CreateTexture(nil, "BACKGROUND")
			l.line:SetTexture(WHITE)
			l.line:SetPoint("TOPLEFT", f, "TOPLEFT")
			l.line:SetPoint("TOPRIGHT", f, "TOPRIGHT")
		end
		fade(l, on, d)
		l.line:SetHeight(Theme.Pixel(f))
		l.line:SetVertexColor(Theme.Wash("divider"))
		l.line:SetShown(on)
	end,
}

local function paint(d, on)
	local r, fn = d.region, PAINT[d.regionType]
	if not fn or skinOf[r] ~= SKIN or (not on and not looks[r]) then return end
	local l = looks[r]
	if not l then
		l = { alpha = {} }
		looks[r] = l
	end
	fn(r, l, on)
	l.on = on
end

-- Selecting a tab sets the game's disabled font again and moves the selection.
local function retab(t)
	local l = looks[t]
	if l and l.under and active(t) then tabState(t, l, true) end
end
if PanelTemplates_SelectTab then
	hooksecurefunc("PanelTemplates_SelectTab", retab)
	hooksecurefunc("PanelTemplates_DeselectTab", retab)
end

function M.Apply()
	local on = ns.Enabled("baganator")
	for _, d in ipairs(API.GetAllFrames()) do paint(d, on) end
end

function M.Enable()
	Theme.OnChanged(function() if ns.Enabled("baganator") then M.Apply() end end, true)
	M.Apply()
end

-- Baganator makes its frames at login and later (each view, pooled slots and
-- headers, a skin switch's new set); each is painted as it comes.
for _, d in ipairs(API.GetAllFrames()) do skinOf[d.region] = API.GetCurrentSkin() end
API.RegisterListener(function(d)
	skinOf[d.region] = API.GetCurrentSkin()
	if active(d.region) then paint(d, true) end
end)

ns.Module("baganator", M)
end)
