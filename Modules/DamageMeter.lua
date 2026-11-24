-- Damage meter (docs/windows/damagemeter.md): the game's own damage meter
-- (Blizzard_DamageMeter) in the HUD's look, restyled in place, never rebuilt.
-- DamageMeter is an Edit Mode system (docs/CLIENT.md, rule 17): window 1 is
-- anchored to it, so Edit Mode places and sizes it; windows 2 and up are the
-- player's (the game's drag, resize, lock and minimize). Only the game's
-- untainted code can read the session data in combat (rule 3), so every
-- row, number, menu, the breakdown and every setting stay the game's.
-- Nothing of the meter is moved, sized, shown, hidden or hooked; no key is
-- written on it and no ScrollBox, Menu or EventRegistry callback registered
-- on its objects (rule 15; its menus are restyled by tag, Menu.ModifyMenu,
-- as Chat.lua's). Ours: the header art and buttons' art faded under glyphs
-- of ours, the window ground
-- (whose alpha the game writes: Background Transparency) emptied and our HUD
-- ground in its place at that alpha times the HUD's Background opacity, the
-- texts in Polestar's faces, and on each row a track and a flat fill whose
-- edge hangs on the game's fill (no value read), the accent or the class colour
-- with the meter's own Show Class Color. Textures of ours are made on the
-- stock frames (widget calls) and kept in weak tables.

local ADDON, ns = ...
local Theme = Polestar.Theme
local H = ns.HUD

local M = { noun = "damage meter" }
local KEY = "damagemeter"
local WINDOWS = 3 -- MAX_DAMAGE_METER_SESSION_WINDOWS (local to DamageMeter.lua)
local GROUND = "damagemeters-background" -- the window ground's atlas, given back when off
local FLYOUT_GROUND = 0.94 -- the breakdown's ground (the game's is opaque)

local windows = setmetatable({}, { __mode = "k" }) -- session window -> ours
local flyouts = setmetatable({}, { __mode = "k" }) -- breakdown (SourceWindow) -> ours
local rows = setmetatable({}, { __mode = "k" }) -- entry -> ours
local driver, started, on

local function usable(f)
	return f and not (f.IsForbidden and f:IsForbidden()) and f or nil
end

local function white(f, layer, sub)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetTexture(Theme.Media("white"))
	return t
end

local function showGround(g, shown)
	g.fill:SetShown(shown)
	for _, t in ipairs(g.edges) do t:SetShown(shown) end
	if not shown then
		for _, t in ipairs(g.glow) do t:Hide() end
		for _, t in ipairs(g.shadow) do t:Hide() end
	end
end

-- A row (a pooled ScrollBox entry, the pinned player row, a breakdown row).
local function row(e)
	local l = rows[e]
	if l then return l end
	local sb = rawget(e, "StatusBar")
	local fill = sb and sb:GetStatusBarTexture()
	if not fill then return end
	l = { sb = sb, icon = rawget(e, "Icon") }
	-- Under the game's texts (OVERLAY), over its fill (ARTWORK), which ours
	-- covers edge to edge: anchored to it, nothing of its size read (rule 3).
	l.track = white(sb, "BACKGROUND", -8)
	l.track:SetAllPoints(sb)
	l.fill = white(sb, "ARTWORK", 7)
	l.fill:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, 0)
	l.fill:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 0)
	if l.icon then l.edges = ns.Hairlines(l.icon, l.icon, function() return white(l.icon, "OVERLAY", 7) end) end
	rows[e] = l
	return l
end

local function dressRow(e, l)
	local sb = l.sb
	for _, k in ipairs({ "Background", "BackgroundEdge" }) do
		local t = rawget(sb, k)
		if t then t:SetAlpha(on and 0 or 1) end -- the game sets it to 1 again (UpdateBackground): faded each frame
	end
	H.Face(rawget(sb, "Name"), "label", on)
	H.Face(rawget(sb, "Value"), "number", on)
	l.track:SetShown(on)
	l.fill:SetShown(on)
	l.fill:SetTexture(H.FillTexture())
	l.color = nil
	if l.edges then
		H.PaintEdge(l.edges, on, H.FRAME_ICONS)
	end
end

-- The accent, or with the meter's Show Class Color (the row's own flag) a
-- player's class colour; either mixed FILL_MIX into the ground colour, so the
-- white names read on a light one (the priest's white, a gold accent). Mixed,
-- not faded: ours must stay opaque over the game's fill.
-- `classFilename` is never secret (DamageMeterDocumentation); guarded all
-- the same. A creature has none: the accent.
local FILL_MIX = 0.55
local function rowColor(e)
	local file = ns.Clean(rawget(e, "classFilename"))
	if ns.Clean(rawget(e, "isClassColorDesired")) and type(file) == "string" and file ~= "" then
		local r, g, b = Theme.ClassColor(file)
		if r then return r, g, b end
	end
	return Theme.Accent()
end

local function paintRow(e)
	local l = row(e)
	if not l then return end
	if not l.dressed then
		l.dressed = true
		dressRow(e, l)
	end
	local sb = l.sb
	for _, k in ipairs({ "Background", "BackgroundEdge" }) do
		local t = rawget(sb, k)
		if t then t:SetAlpha(0) end
	end
	local r, g, b = rowColor(e)
	local c = l.color
	if not (c and c[1] == r and c[2] == g and c[3] == b) then
		l.color = { r, g, b }
		local br, bg, bb = Theme.Color("bg")
		local k = FILL_MIX
		l.fill:SetVertexColor(r * k + br * (1 - k), g * k + bg * (1 - k), b * k + bb * (1 - k), 1)
		l.track:SetVertexColor(br, bg, bb, H.GroundAlpha())
	end
end

-- Every row frame under a ScrollBox (pooled: hidden ones too, so a row is
-- ready before the game shows it).
local function paintRows(box)
	local target = box and rawget(box, "ScrollTarget")
	if not target then return end
	for _, e in ipairs({ target:GetChildren() }) do paintRow(e) end
end

-- A session window: its ground on the minimize container (where the game's
-- is, so it hides with it when minimized), a hairline under the header strip.
local function window(w)
	local l = windows[w]
	if l then return l end
	local c = rawget(w, "MinimizeContainer")
	local bg = c and rawget(c, "Background")
	local header = rawget(w, "Header")
	if not (bg and header) then return end
	l = { c = c, bg = bg, header = header, ground = H.Ground(c) }
	l.line = white(c, "BORDER", 7)
	l.line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
	l.line:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
	windows[w] = l
	return l
end

local function texts(w, l)
	if l.texts then return l.texts end
	local session, kind = rawget(w, "SessionDropdown"), rawget(w, "DamageMeterTypeDropdown")
	-- { font string, role, colour }: the type label as a window title, the
	-- session letter as a chip's caption on our pill, the timer secondary.
	l.texts = {
		{ rawget(w, "SessionTimer"), "number", "textDim" },
		{ session and rawget(session, "SessionName"), "caption", "accent" }, -- the session letter ("C", "O", a number)
		{ kind and rawget(kind, "TypeName"), "heading", "text", 1 }, -- +1: with the game's face (one weight) the heading reads only by size
		{ rawget(l.c, "NotActive"), "label", "textMuted" },
	}
	l.faced, l.colors = {}, {}
	return l.texts
end

-- The header's texts in Polestar's faces and theme colours (the game writes
-- only their text; their colour is kept and put back when off). Font (face
-- and size) and colour are checked each frame, so either set again by anyone
-- is followed.
local function faceKey(fs)
	local path, size = fs:GetFont()
	return tostring(path) .. ":" .. tostring(size)
end

local function faceTexts(w, l, force)
	for _, t in ipairs(texts(w, l)) do
		local fs, role = t[1], t[2]
		if fs and not on then
			H.Face(fs, role, false)
			local c = l.colors[fs]
			if c then fs:SetTextColor(c[1], c[2], c[3], c[4]) end
			l.colors[fs], l.faced[fs] = nil, nil
		elseif fs then
			if force or faceKey(fs) ~= l.faced[fs] then
				H.Face(fs, role, true)
				if t[4] then
					local path, size, flags = fs:GetFont()
					Theme.SetFace(fs, path, size + t[4], flags)
				end
				l.faced[fs] = faceKey(fs)
				l.colors[fs] = l.colors[fs] or { fs:GetTextColor() }
			end
			local r, g, b = Theme.Color(t[3])
			local cr, cg, cb = fs:GetTextColor()
			if cr ~= r or cg ~= g or cb ~= b then fs:SetTextColor(r, g, b) end
		end
	end
end

-- The header's buttons (the game's clicks, menus and states): their art
-- faded (the game swaps it with SetAtlas on hover, press and open, which
-- keeps the alpha), ours over it: a glyph in the `icon` token, a hover wash
-- in a HIGHLIGHT layer (the client shows it on mouse-over: no script); the
-- session button a Polestar chip: an accent pill under its letter, the wash
-- a pill too. `art(b)`: the regions faded.
-- One centre line: the visual centre of the game's texts (the type label's
-- capitals 15.1 px, the session letter 14.5 px under the window's top at the
-- user's 0.84 UI scale), measured in game; the template's anchors put the
-- type arrow, settings and minimize buttons lower than they read. The game's
-- buttons and texts stay where they are (rule 17); our glyphs are offset onto
-- the line by `dy` (UI units) from what they hang on (constants: no stock
-- geometry read, rule 3).
local BUTTONS = {
	{ key = "MinimizeButton", icon = "chevron-up", size = 12, dy = 1.4,
		art = function(b) return { b:GetNormalTexture(), b:GetPushedTexture(), b:GetHighlightTexture() } end },
	{ key = "SettingsDropdown", icon = "gear", size = 14, dy = 4.4, art = function(b) return { rawget(b, "Icon") } end },
	{ key = "SessionDropdown", pill = true, nohover = true, art = function(b) return { rawget(b, "Background"), rawget(b, "Arrow") } end },
	{ key = "DamageMeterTypeDropdown", icon = "chevron-down", size = 10, at = "Arrow", dy = 5.6, art = function(b) return { rawget(b, "Arrow") } end },
	-- The resize handle (alpha 0 till the game fades it in on mouse-over): our grip in the container's corner, no wash.
	{ key = "ResizeButton", parent = "MinimizeContainer", icon = "resize", size = 12, corner = true, nohover = true,
		art = function(b) return { b:GetNormalTexture(), b:GetPushedTexture(), b:GetHighlightTexture() } end },
}
local buttons = setmetatable({}, { __mode = "k" }) -- stock button -> ours

-- A capsule (W.Pill's shape) of textures on `b`, centred on it and PILL_PAD
-- wider each side (the letter's box is 18 wide, 32 in long-name locales):
-- textures, so nothing of the game's button is sized. The accent at
-- PILL_ALPHA (a chip's 0.16 read as a dark disc over the game world).
local PILL_H, PILL_PAD, PILL_ALPHA = 16, 2, 0.35
local function pill(b, layer)
	local l = b:CreateTexture(nil, layer)
	l:SetTexture(Theme.Media("circle"))
	l:SetTexCoord(0, 0.5, 0, 1)
	l:SetSize(PILL_H / 2, PILL_H)
	l:SetPoint("LEFT", b, "LEFT", -PILL_PAD, 0)
	local r = b:CreateTexture(nil, layer)
	r:SetTexture(Theme.Media("circle"))
	r:SetTexCoord(0.5, 1, 0, 1)
	r:SetSize(PILL_H / 2, PILL_H)
	r:SetPoint("RIGHT", b, "RIGHT", PILL_PAD, 0)
	local m = white(b, layer)
	m:SetPoint("TOPLEFT", l, "TOPRIGHT", 0, 0)
	m:SetPoint("BOTTOMRIGHT", r, "BOTTOMLEFT", 0, 0)
	return { l, m, r }
end

local function paintPill(parts, shown, r, g, b, a)
	for _, t in ipairs(parts) do
		t:SetVertexColor(r, g, b, a)
		t:SetShown(shown)
	end
end

local function button(b, spec)
	local l = buttons[b]
	if l then return l end
	l = { spec = spec }
	if not spec.nohover then
		l.hover = white(b, "HIGHLIGHT")
		l.hover:SetAllPoints(b)
	end
	if spec.pill then
		l.pill, l.pillHover = pill(b, "ARTWORK"), pill(b, "HIGHLIGHT")
	end
	if spec.icon then
		l.glyph = b:CreateTexture(nil, "ARTWORK", nil, 7)
		l.glyph:SetSize(spec.size, spec.size)
		if spec.corner then
			l.glyph:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -11, 10) -- the button hangs 9 right, 8 below the container's corner
		else
			l.glyph:SetPoint("CENTER", spec.at and rawget(b, spec.at) or b, "CENTER", 0, spec.dy)
		end
	end
	buttons[b] = l
	return l
end

local function dressButton(b, l)
	for _, t in pairs(l.spec.art(b)) do t:SetAlpha(on and 0 or 1) end
	if l.hover then
		l.hover:SetVertexColor(Theme.Wash("hover"))
		l.hover:SetShown(on)
	end
	if l.pill then
		local r, g, b = Theme.Accent()
		paintPill(l.pill, on, r, g, b, PILL_ALPHA)
		paintPill(l.pillHover, on, r, g, b, 0.2)
	end
	l.icon = nil -- the minimize glyph's state, set again by the driver
	if l.glyph then
		l.glyph:SetTexture(Theme.Media(Theme.Icon(l.spec.icon)))
		l.glyph:SetVertexColor(Theme.Color("icon"))
		l.glyph:SetShown(on)
	end
end

local function eachButton(w, fn)
	for _, spec in ipairs(BUTTONS) do
		local holder = spec.parent and rawget(w, spec.parent) or w
		local b = holder and usable(rawget(holder, spec.key))
		if b then fn(b, button(b, spec)) end
	end
end

local function dressWindow(w, l)
	eachButton(w, dressButton)
	l.header:SetAlpha(on and 0 or 1)
	-- The game writes this texture's alpha (Background Transparency): emptied,
	-- never faded, so its alpha stays live for ours to copy.
	if on then l.bg:SetTexture(nil) elseif not l.bg:GetAtlas() then l.bg:SetAtlas(GROUND) end
	faceTexts(w, l, true)
	showGround(l.ground, on)
	l.line:SetShown(on)
	l.alpha = nil
end

local function paintWindow(w)
	local l = window(w)
	if not l then return end
	if not l.dressed then
		l.dressed = true
		dressWindow(w, l)
	end
	local a = l.bg:GetAlpha() * H.GroundAlpha()
	if a ~= l.alpha then
		l.alpha = a
		H.PaintGround(l.ground, a)
		local r, g, b, ba = Theme.Color("border")
		ns.PaintHairlines({ l.line }, true, r, g, b, ba)
	end
	faceTexts(w, l)
	-- The minimize button's glyph: collapse while the container shows, expand while minimized.
	local min = usable(rawget(w, "MinimizeButton"))
	local mb = min and buttons[min]
	if mb and mb.glyph then
		local icon = l.c:IsShown() and "chevron-up" or "chevron-down"
		if mb.icon ~= icon then
			mb.icon = icon
			mb.glyph:SetTexture(Theme.Media(Theme.Icon(icon)))
		end
	end
	paintRows(rawget(l.c, "ScrollBox"))
	local own = rawget(l.c, "LocalPlayerEntry")
	if own then paintRow(own) end
	-- The breakdown flyout (HIGH strata, a child of the container): its
	-- ground is the game's plain atlas, faded; ours under it.
	local sw = usable(rawget(l.c, "SourceWindow"))
	if sw and sw:IsVisible() then
		local fl = flyouts[sw]
		local fbg = rawget(sw, "Background")
		if not fl and fbg then
			fl = { bg = fbg, ground = H.Ground(sw) }
			flyouts[sw] = fl
		end
		if fl then
			if not fl.dressed then
				fl.dressed = true
				fl.bg:SetAlpha(on and 0 or 1)
				showGround(fl.ground, on)
				if on then H.PaintGround(fl.ground, FLYOUT_GROUND) end
			end
			paintRows(rawget(sw, "ScrollBox"))
		end
	end
end

local function update()
	local dm = usable(rawget(_G, "DamageMeter"))
	if not (dm and dm:IsVisible()) then return end
	for i = 1, WINDOWS do
		local w = usable(rawget(_G, "DamageMeterSessionWindow" .. i))
		if w and w:IsVisible() then paintWindow(w) end
	end
end

function M.Apply()
	if not started then return end
	on = ns.Enabled(KEY)
	-- Everything dressed so far, again (on, or given back); new frames are
	-- dressed by the driver as it meets them.
	for w, l in pairs(windows) do l.dressed = true; dressWindow(w, l) end
	for e, l in pairs(rows) do l.dressed = true; dressRow(e, l) end
	for _, fl in pairs(flyouts) do
		fl.dressed = true
		fl.bg:SetAlpha(on and 0 or 1)
		showGround(fl.ground, on)
		if on then H.PaintGround(fl.ground, FLYOUT_GROUND) end
	end
	driver:SetShown(on)
	if on then update() end
end

-- The meter's menus (Blizzard_Menu, by their tags, as Chat.lua's): the
-- menu look of ns.MenuLook (Core.lua, rule 15). The value: how far above
-- the menu's foot ours ends (MenuStyle1 pads its items 8 at the top, 15 at
-- the foot; the session menu's MenuStyle2 is even).
local MENUS = { MENU_DAMAGE_METER_WINDOW_TRACKED_TYPE = 7, MENU_DAMAGE_METER_WINDOW_SETTINGS = 7, MENU_DAMAGE_METER_SESSIONS = 0 }

local function menuLook(menu, foot)
	if ns.Enabled(KEY) then ns.MenuLook(menu, foot) end
end

-- A menu item, after the game's initializers built it (AddInitializer: the
-- menu system's own per-item hook, on these menus' descriptions only). The
-- game's pieces are the item's compositor attachments, made fresh for this
-- item (MenuVariants.CreateRadio/CreateCheckbox: leftTexture1, and
-- leftTexture2 when selected; CreateSubmenuArrow: arrow; CreateHighlight:
-- highlight), its keys in the compositor's table for this use only (read
-- by index: rawget finds none in game); faded, they are set back to their
-- defaults when the menu closes. Ours are pieces of the menu's look
-- (ns.MenuPiece, under the items), hidden with the menu.
local function itemLook(item, desc, menu)
	if not ns.Enabled(KEY) then return end
	local function piece(icon, size, token, a)
		local t = ns.MenuPiece(menu)
		if not t then return end
		t:SetTexture(Theme.Media(icon))
		t:SetSize(size, size)
		t:SetDrawLayer("ARTWORK", 7)
		local r, g, b = Theme.Color(token)
		t:SetVertexColor(r, g, b, a or 1)
		return t
	end
	if item:GetObjectType() ~= "Button" then
		-- A divider (MenuVariants.CreateDivider, its one texture): a hairline instead.
		for _, t in ipairs({ item:GetRegions() }) do
			if t:GetObjectType() == "Texture" and t:IsShown() then
				local line = ns.MenuPiece(menu)
				if not line then return end
				t:SetAlpha(0)
				line:SetTexture(Theme.Media("white"))
				line:SetSize(0, 0)
				line:SetPoint("LEFT", t, "LEFT", 0, 0)
				line:SetPoint("RIGHT", t, "RIGHT", 0, 0)
				line:SetHeight(Theme.Pixel(item))
				line:SetVertexColor(Theme.Color("border"))
				return
			end
		end
		return
	end
	local radio, check = desc:IsRadio(), desc:IsCheckbox()
	local slot = (radio or check) and item.leftTexture1
	if slot then
		local on2 = item.leftTexture2
		slot:SetAlpha(0)
		if on2 then on2:SetAlpha(0) end
		-- A ring or a box in the border token; selected, the accent dot or tick.
		local back = piece(radio and "skin-ring" or "white", radio and 12 or 11, "textMuted", radio and 1 or 0.35)
		back:SetPoint("CENTER", slot, "CENTER", 0, 0)
		if on2 then
			local mark = piece(radio and "circle" or "check", radio and 6 or 12, "accent")
			mark:SetPoint("CENTER", back, "CENTER", 0, 0)
		end
	end
	local arrow = desc:CanOpenSubmenu() and item.arrow
	if arrow then
		arrow:SetAlpha(0)
		piece(Theme.Icon("chevron-right"), 10, "icon"):SetPoint("CENTER", arrow, "CENTER", 0, 0)
	end
	-- The hover: the game shows it and writes its alpha (1, or 0.4 when
	-- disabled), so it is recoloured in place, its colour carrying ours.
	local hl = item.highlight
	if hl then
		local r, g, b, a = Theme.Wash("hover")
		hl:SetColorTexture(r, g, b, a)
		hl:SetBlendMode("BLEND")
	end
end

-- Every item of a menu description, submenus too.
local function addItemLook(desc)
	for _, d in desc:EnumerateElementDescriptions() do
		d:AddInitializer(itemLook)
		addItemLook(d)
	end
end

function M.Enable()
	started = true
	if Menu and Menu.ModifyMenu then
		for tag, foot in pairs(MENUS) do
			Menu.ModifyMenu(tag, function(_, root)
				root:AddMenuAcquiredCallback(function(menu) menuLook(menu, foot) end)
				if root.EnumerateElementDescriptions then addItemLook(root) end
			end)
		end
	end
	driver = CreateFrame("Frame", nil, UIParent)
	-- Each frame while the meter shows: windows 2+ and rows are made as the
	-- player opens them and as sources appear, and the game sets the rows'
	-- art and the ground's alpha again on its own changes.
	driver:SetScript("OnUpdate", update)
	Theme.OnChanged(function() if ns.Enabled(KEY) then M.Apply() end end, true)
	M.Apply()
end

ns.Module(KEY, M)
