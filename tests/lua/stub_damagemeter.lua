-- The damage meter as the client builds it (Blizzard_DamageMeter:
-- DamageMeter.lua, DamageMeterSessionWindow.xml/.lua, DamageMeterEntry.xml/.lua,
-- DamageMeterSourceWindow.xml): DamageMeter, an Edit Mode system holding the
-- session windows; window 1 anchored to it (TOPLEFT, BOTTOMRIGHT), windows 2+
-- on UIParent, movable and resizable by the player. Each window: the Header
-- atlas, SessionTimer, the dropdown buttons (SessionName, TypeName), the
-- minimize button, MinimizeContainer (Background, alpha written by the game:
-- Background Transparency; NotActive; ScrollBox with its ScrollTarget of
-- pooled entries; the pinned LocalPlayerEntry; ScrollBar; SourceWindow, the
-- breakdown). Each entry: a clipping Button, Icon.Icon, StatusBar (its fill
-- tinted by the game, Background and BackgroundEdge whose atlas UpdateStyle
-- sets again and whose alpha UpdateBackground sets to 1 again, Name, Value),
-- laid out per Style as the game does. Colour textures stand in for the
-- atlases. In combat the session data is secret (names, amounts, icons);
-- `classFilename` never is. Every frame and region is guarded
-- (stub_editmode.lua).
--
--   stub.damage({ { name, class, amount, me = true }, ... })   the session's sources (sorted by the game)
--   stub.dmSetting(key, value)   Edit Mode: barHeight, spacing, textScale, style, bgAlpha (0..1), alpha,
--                                classColor, icons, width, height
--   stub.dmWindow(i, x, y, w, h)   the player opens window i (2+), placed by the game where the player left it
--   stub.dmMinimize(i, on)   stub.dmBreakdown(i, row)   the breakdown of window i's row
--   stub.openMenu(owner, tag, labels, style2)   a header menu (MenuStyle1, or the session menu's MenuStyle2); stub.closeMenu()

require("stub_editmode")

local M = stub.Methods
local CALLS = stub.SYSTEM_CALLS
local WHITE = "Interface\\Buttons\\WHITE8X8"
GameFontNormalMed1 = GameFontNormalMed1 or GameFontNormal

Enum.DamageMeterStyle = { Default = 0, Thin = 1, Bordered = 2, FullBackground = 3 }
local STYLE = Enum.DamageMeterStyle

-- The meter's atlases, as colours.
local ATLAS = {
	["ui-damagemeters-header-bar"] = { 0.16, 0.12, 0.06, 0.95 },
	["damagemeters-background"] = { 0.02, 0.02, 0.03, 1 },
	["ui-damagemeters-bar-shadowbg"] = { 0.12, 0.09, 0.05, 0.9 },
	["ui-damagemeters-bar-shadowedge"] = { 0.7, 0.55, 0.3, 0.25 },
	["UI-HUD-CoolDownManager-Bar-BG"] = { 0.35, 0.28, 0.16, 1 },
	["common-dropdown-bg"] = { 0.06, 0.06, 0.07, 0.96 },
	["ui-questtrackerbutton-collapse-all"] = { 0.75, 0.6, 0.25, 1 },
	["ui-questtrackerbutton-expand-all"] = { 0.75, 0.6, 0.25, 1 },
	["ui-questtrackerbutton-collapse-all-pressed"] = { 0.6, 0.45, 0.2, 1 },
	["ui-questtrackerbutton-red-highlight"] = { 0.9, 0.3, 0.2, 0.5 },
	["common-dropdown-a-button-settings-shadowless"] = { 0.7, 0.6, 0.35, 1 },
	["common-dropdown-c-button"] = { 0.2, 0.16, 0.1, 1 },
	["common-dropdown-c-button-hover-arrow"] = { 0.9, 0.75, 0.3, 1 },
	["common-dropdown-a-button-shadowless"] = { 0.85, 0.7, 0.3, 1 },
	["common-dropdown-c-bg"] = { 0.08, 0.07, 0.06, 0.96 },
}
local setAtlas = M.SetAtlas
function M.SetAtlas(self, atlas, ...)
	local c = ATLAS[atlas]
	if c then self:SetColorTexture(c[1], c[2], c[3], c[4]) end
	return setAtlas(self, atlas, ...)
end
function M.SetTextScale(self, s) self.textScale = s end
function M.GetTextScale(self) return self.textScale or 1 end

-- Edit Mode's settings, as the game holds them (display values).
local dm = { barHeight = 24, spacing = 4, textScale = 1, style = STYLE.Default, bgAlpha = 0.6, alpha = 1, classColor = false, icons = true, width = 300, height = 200 }
stub.dm = dm

local function wrap(v) if stub.inCombat then return stub.secret(v) end return v end

local CLASS = { MAGE = { 0.25, 0.78, 0.92 }, WARRIOR = { 0.78, 0.61, 0.43 }, PRIEST = { 1, 1, 1 }, HUNTER = { 0.67, 0.83, 0.45 },
	DEATHKNIGHT = { 0.77, 0.12, 0.23 }, WARLOCK = { 0.53, 0.53, 0.93 }, DEMONHUNTER = { 0.64, 0.19, 0.79 }, SHAMAN = { 0, 0.44, 0.87 },
	PALADIN = { 0.96, 0.55, 0.73 }, ROGUE = { 1, 0.96, 0.41 } }
local DEFAULT = { 0.85, 0.62, 0.1 } -- DAMAGE_METER_STATUS_BAR_DEFAULT_COLOR (gold)
local CREATURE = { 0.6, 0.6, 0.6 }

local function guardRegions(f, label)
	for _, r in ipairs({ f:GetRegions() }) do stub.guard(r, nil, label .. "'s region") end
end

local function text(parent, layer, font)
	local fs = parent:CreateFontString(nil, layer or "OVERLAY")
	fs:SetFontObject(font or GameFontNormalMed1)
	return fs
end

---------------------------------------------------------------------------
-- Entries (DamageMeterEntryMixin)
---------------------------------------------------------------------------

local entries = {}
local function newEntry(parent, label)
	local e = CreateFrame("Button", nil, parent)
	e:SetClipsChildren(true)
	e:SetHeight(24)
	e.Icon = CreateFrame("Frame", nil, e)
	e.Icon:SetSize(24, 24)
	e.Icon:SetPoint("LEFT", e, "LEFT", 0, 0)
	e.Icon.Icon = e.Icon:CreateTexture(nil, "ARTWORK")
	e.Icon.Icon:SetAllPoints(e.Icon)
	local sb = CreateFrame("StatusBar", nil, e)
	e.StatusBar = sb
	sb:SetStatusBarTexture(WHITE)
	sb.Background = sb:CreateTexture(nil, "BACKGROUND")
	sb.BackgroundEdge = sb:CreateTexture(nil, "OVERLAY")
	sb.BackgroundEdge:SetPoint("TOPLEFT", sb, "TOPLEFT", -2, 2)
	sb.BackgroundEdge:SetPoint("BOTTOMRIGHT", sb, "BOTTOMRIGHT", 2, -2)
	sb.BackgroundEdge:SetAtlas("ui-damagemeters-bar-shadowedge")
	sb.Value = text(sb, "OVERLAY", NumberFontNormal)
	sb.Value:SetJustifyH("LEFT")
	sb.Name = text(sb, "OVERLAY", NumberFontNormal)
	sb.Name:SetJustifyH("LEFT")
	sb.Name:SetWordWrap(false)
	e:Hide()
	for _, f in ipairs({ e, e.Icon, sb }) do stub.guard(f, CALLS, label) end
	guardRegions(e.Icon, label)
	guardRegions(sb, label)
	entries[#entries + 1] = e
	return e
end

-- UpdateStyle: the bar, name and value laid out per Style; the background's atlas set again.
local function updateStyle(e)
	local sb, st = e.StatusBar, e.style
	sb:ClearAllPoints(); sb.Name:ClearAllPoints(); sb.Value:ClearAllPoints()
	e.Icon:SetShown(e.showBarIcons)
	local rel, rp, x = e, "LEFT", 0
	if e.showBarIcons then
		rel, rp = e.Icon, "RIGHT"
		if st == STYLE.Bordered or st == STYLE.Thin then x = 5 end
	end
	local l, t, r, b = -2, 2, 2, -2
	if st == STYLE.Bordered then l, t, r, b = -2, 2, 6, -7 end
	sb.Background:ClearAllPoints()
	sb.Background:SetPoint("TOPLEFT", sb, "TOPLEFT", l, t)
	sb.Background:SetPoint("BOTTOMRIGHT", sb, "BOTTOMRIGHT", r, b)
	sb.Background:SetAtlas(st == STYLE.Bordered and "UI-HUD-CoolDownManager-Bar-BG" or "ui-damagemeters-bar-shadowbg")
	sb.BackgroundEdge:SetShown(st ~= STYLE.Bordered)
	if st == STYLE.Thin then
		sb.Name:SetPoint("TOPLEFT", rel, rp == "RIGHT" and "TOPRIGHT" or "TOPLEFT", x, 0)
		sb.Name:SetPoint("RIGHT", sb.Value, "LEFT", -25, 0)
		sb.Name:SetHeight(12)
		sb.Value:SetPoint("TOPRIGHT", e, "TOPRIGHT", -3, 0)
		sb.Value:SetHeight(12)
		sb:SetPoint("TOPLEFT", sb.Name, "BOTTOMLEFT", 0, 0)
		sb:SetPoint("BOTTOMRIGHT", e, "BOTTOMRIGHT", 0, 1)
	else
		sb:SetPoint("TOPLEFT", rel, rp == "RIGHT" and "TOPRIGHT" or "TOPLEFT", x, 0)
		sb:SetPoint("BOTTOMRIGHT", e, "BOTTOMRIGHT", -4, 1)
		sb.Name:SetPoint("LEFT", sb, "LEFT", 2, 0)
		sb.Name:SetPoint("RIGHT", sb.Value, "LEFT", -25, 0)
		sb.Value:SetPoint("RIGHT", sb, "RIGHT", -3, 0)
	end
end

-- UpdateBackground: both background regions at 1 (now only the window's alpha rules them).
local function updateBackground(e)
	e.StatusBar.Background:SetAlpha(1)
	e.StatusBar.BackgroundEdge:SetAlpha(1)
end

local function barColor(e)
	if e.isClassColorDesired then
		if e.classFilename == "" then return CREATURE end
		return CLASS[e.classFilename] or DEFAULT
	end
	return DEFAULT
end

-- SetupEntry (on acquire), then Init (each refresh).
local function setupEntry(e)
	e.isClassColorDesired = dm.classColor
	e:SetHeight(dm.barHeight)
	e.StatusBar.Name:SetTextScale(dm.textScale)
	e.StatusBar.Value:SetTextScale(dm.textScale)
	e.showBarIcons = dm.icons
	e.style = dm.style
	updateBackground(e)
	updateStyle(e)
end

local function init(e, src, i, max)
	e.classFilename = src.class or ""
	e.isLocalPlayer = src.me or false
	e.sourceName = wrap(src.name)
	e.value, e.maxValue = wrap(src.amount), wrap(max)
	e.specIconID = wrap(src.class and 135932 or 0)
	local c = CLASS[src.class] or CREATURE
	e.Icon.Icon:SetColorTexture(c[1] * 0.6, c[2] * 0.6, c[3] * 0.6, 1) -- the spec icon (secret in combat)
	local sb = e.StatusBar
	sb:SetMinMaxValues(0, wrap(max))
	sb:SetValue(wrap(src.amount))
	sb.Name:SetFormattedText(i and "%d. %s" or "%s%s", i or "", wrap(src.name))
	sb.Value:SetFormattedText("%s", AbbreviateNumbers(wrap(src.amount)))
	local col = barColor(e)
	sb:GetStatusBarTexture():SetVertexColor(col[1], col[2], col[3])
end

---------------------------------------------------------------------------
-- Session windows (DamageMeterSessionWindowMixin)
---------------------------------------------------------------------------

local DM = CreateFrame("Frame", "DamageMeter", UIParent)
DM:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 40, -60)
DM:SetSize(dm.width, dm.height)

local wins = {}
local sources = {}

-- A texture region on a button, in an atlas (shown, or only in a state the client draws).
local function art(b, layer, atlas, shown)
	local t = b:CreateTexture(nil, layer)
	t:SetAllPoints(b)
	t:SetAtlas(atlas)
	t:SetShown(shown ~= false)
	return t
end

local function newWindow(i)
	local w = CreateFrame("Frame", "DamageMeterSessionWindow" .. i, DM)
	stub.secureNames[w:GetName()] = true
	w.Header = w:CreateTexture(nil, "BACKGROUND")
	w.Header:SetHeight(32)
	w.Header:SetPoint("TOPLEFT", w, "TOPLEFT", 0, 0)
	w.Header:SetPoint("TOPRIGHT", w, "TOPRIGHT", 0, 0)
	w.Header:SetAtlas("ui-damagemeters-header-bar")
	w.SessionTimer = text(w)
	w.SessionTimer:SetPoint("TOPLEFT", w.Header, "TOPLEFT", 1, -9)
	w.SessionTimer:SetJustifyH("LEFT")
	-- The minimize button (normal, pushed, highlight atlases; SetMinimized swaps them).
	local min = CreateFrame("Button", nil, w)
	w.MinimizeButton = min
	min:SetSize(18, 19)
	min:SetPoint("TOPRIGHT", w.Header, "TOPRIGHT", -3, -5)
	min:SetNormalTexture(art(min, "ARTWORK", "ui-questtrackerbutton-collapse-all"))
	min:SetPushedTexture(art(min, "ARTWORK", "ui-questtrackerbutton-collapse-all-pressed", false))
	min:SetHighlightTexture(art(min, "HIGHLIGHT", "ui-questtrackerbutton-red-highlight", false))
	-- DamageMeterSettingsDropdownButtonTemplate: its Icon atlas per state.
	local set = CreateFrame("Button", nil, w)
	w.SettingsDropdown = set
	set:SetSize(27, 27)
	set:SetPoint("RIGHT", min, "LEFT", -2, -2)
	set.Icon = art(set, "ARTWORK", "common-dropdown-a-button-settings-shadowless")
	-- WowStyle2DropdownTemplate: Background (7 out), the hover Arrow, the SessionName on top.
	local ses = CreateFrame("Button", nil, w)
	w.SessionDropdown = ses
	ses:SetSize(18, 18)
	ses:SetPoint("RIGHT", set, "LEFT", -2, 3)
	ses.Background = ses:CreateTexture(nil, "BACKGROUND")
	ses.Background:SetPoint("TOPLEFT", ses, "TOPLEFT", -7, 7)
	ses.Background:SetPoint("BOTTOMRIGHT", ses, "BOTTOMRIGHT", 7, -7)
	ses.Background:SetAtlas("common-dropdown-c-button")
	ses.Arrow = ses:CreateTexture(nil, "OVERLAY")
	ses.Arrow:SetSize(10, 6)
	ses.Arrow:SetPoint("BOTTOM", ses, "BOTTOM", 0, -5)
	ses.Arrow:SetAtlas("common-dropdown-c-button-hover-arrow")
	ses.Arrow:Hide()
	ses.Text = text(ses, "OVERLAY", GameFontNormal) -- the template's own selection text, unused here
	ses.Text:SetPoint("LEFT", ses, "LEFT", 13, 0)
	ses.Text:SetPoint("RIGHT", ses, "RIGHT", -13, 0)
	ses.ResetButton = CreateFrame("Button", nil, ses) -- UIResetButtonTemplate, hidden (shown only for filter dropdowns)
	ses.ResetButton:SetSize(16, 16)
	ses.ResetButton:SetPoint("CENTER", ses, "TOPRIGHT", -3, -5)
	art(ses.ResetButton, "ARTWORK", "common-dropdown-c-button")
	ses.ResetButton:Hide()
	ses.SessionName = text(ses)
	ses.SessionName:SetAllPoints(ses)
	-- WowStyle1ArrowDropdownTemplate (25 x 25, its Arrow atlas per state); TypeName right of the arrow.
	w.DamageMeterTypeDropdown = CreateFrame("Button", nil, w)
	local kind = w.DamageMeterTypeDropdown
	kind:SetSize(25, 25)
	kind:SetPoint("TOPLEFT", w.SessionTimer, "TOPRIGHT", 0, 6)
	kind.Arrow = kind:CreateTexture(nil, "OVERLAY")
	kind.Arrow:SetSize(14, 14)
	kind.Arrow:SetPoint("CENTER", kind, "CENTER", 0, -2)
	kind.Arrow:SetAtlas("common-dropdown-a-button-shadowless")
	kind.TypeName = text(kind)
	kind.TypeName:SetPoint("LEFT", kind.Arrow, "RIGHT", 0, 3)
	kind.TypeName:SetPoint("RIGHT", ses, "LEFT", -5, 0)
	kind.TypeName:SetJustifyH("LEFT")
	kind.TypeName:SetText("Damage Done")
	w.SessionDropdown.SessionName:SetText("C")

	w:SetFrameLevel(i) -- SetupSessionWindow: each window above the previous ones
	local c = CreateFrame("Frame", nil, w)
	c:SetFrameLevel(i) -- useParentLevel: under the header's buttons
	c:SetAllPoints(w)
	w.MinimizeContainer = c
	c.Background = c:CreateTexture(nil, "BACKGROUND")
	c.Background:SetPoint("TOPLEFT", c, "TOPLEFT", 0, 0)
	c.Background:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", 0, 0)
	c.Background:SetAtlas("damagemeters-background")
	c.Background:SetAlpha(dm.bgAlpha)
	c.NotActive = text(c)
	c.NotActive:SetPoint("TOPLEFT", w.Header, "BOTTOMLEFT", 20, 0)
	c.NotActive:SetPoint("BOTTOMRIGHT", c.Background, "BOTTOMRIGHT", -20, 0)
	c.ScrollBox = CreateFrame("Frame", nil, c)
	c.ScrollBox:SetPoint("TOPLEFT", w.Header, "BOTTOMLEFT", 5, -2)
	c.ScrollBox:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -1, 6)
	c.ScrollBox:SetClipsChildren(true)
	c.ScrollBox.ScrollTarget = CreateFrame("Frame", nil, c.ScrollBox)
	c.ScrollBox.ScrollTarget:SetAllPoints(c.ScrollBox)
	c.LocalPlayerEntry = newEntry(c, w:GetName() .. ".LocalPlayerEntry")
	c.ScrollBar = CreateFrame("Frame", nil, c)
	c.ScrollBar:SetAlpha(0.3)
	local sw = CreateFrame("Frame", w:GetName() .. "Breakdown", c) -- unnamed in the game; named here to be a scene root
	c.SourceWindow = sw
	sw:SetFrameStrata("HIGH")
	sw:Hide()
	sw.Background = sw:CreateTexture(nil, "BACKGROUND")
	sw.Background:SetAllPoints(sw)
	sw.Background:SetAtlas("common-dropdown-bg")
	sw.ScrollBox = CreateFrame("Frame", nil, sw)
	sw.ScrollBox:SetPoint("TOPLEFT", sw, "TOPLEFT", 6, -6)
	sw.ScrollBox:SetPoint("BOTTOMRIGHT", sw, "BOTTOMRIGHT", -6, 6)
	sw.ScrollBox.ScrollTarget = CreateFrame("Frame", nil, sw.ScrollBox)
	sw.ScrollBox.ScrollTarget:SetAllPoints(sw.ScrollBox)

	w.pool, w.spellPool, w.index = {}, {}, i
	local label = w:GetName()
	for _, f in ipairs({ w, w.MinimizeButton, w.SettingsDropdown, w.SessionDropdown, kind, c, c.ScrollBox, c.ScrollBox.ScrollTarget, c.ScrollBar,
		sw, sw.ScrollBox, sw.ScrollBox.ScrollTarget }) do
		stub.guard(f, CALLS, label)
	end
	for _, f in ipairs({ w, w.MinimizeButton, w.SettingsDropdown, w.SessionDropdown, kind, c, sw }) do guardRegions(f, label) end
	wins[i] = w
	return w
end

-- The edit mode sample (EDIT_MODE_SESSION in DamageMeterSessionWindow.lua).
local SAMPLE = {
	{ name = "Kel'Thuzad", class = "DEATHKNIGHT", amount = 100 }, { name = "Jaina", class = "MAGE", amount = 100 },
	{ name = "Gul'dan", class = "WARLOCK", amount = 80 }, { name = "Rexxar", class = "HUNTER", amount = 80 },
	{ name = "Illidan", class = "DEMONHUNTER", amount = 70 }, { name = "Thrall", class = "SHAMAN", amount = 70 },
	{ name = "Uther", class = "PALADIN", amount = 50 },
}

-- Refresh: the data provider's rows on pooled entries, the pinned player
-- row when the player's falls below the visible rows.
local function refresh(w)
	local list = w.editing and SAMPLE or sources
	local max = 0
	for _, s in ipairs(list) do if s.amount > max then max = s.amount end end
	local h = w.index == 1 and dm.height or w.h
	local step = dm.barHeight + dm.spacing
	local visible = math.floor((h - 40 + dm.spacing) / step)
	local target = w.MinimizeContainer.ScrollBox.ScrollTarget
	local mine
	for i = 1, math.max(#list, #w.pool) do
		local s, e = list[i], w.pool[i]
		if s and not e then
			e = newEntry(target, w:GetName() .. " row " .. i)
			w.pool[i] = e
		end
		if s then
			setupEntry(e)
			init(e, s, i, max)
			e:ClearAllPoints()
			e:SetPoint("TOPLEFT", target, "TOPLEFT", 0, -(i - 1) * step)
			e:SetPoint("TOPRIGHT", target, "TOPRIGHT", 0, -(i - 1) * step)
			e:SetShown(i <= visible + 1)
			if s.me and i > visible then mine = i end
		elseif e then
			e:Hide()
		end
	end
	local own = w.MinimizeContainer.LocalPlayerEntry
	if mine then
		setupEntry(own)
		init(own, list[mine], mine, max)
		own:ClearAllPoints()
		own:SetPoint("BOTTOMLEFT", target, "BOTTOMLEFT", 0, -4)
		own:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 0, -4)
		own:Show()
	else
		own:Hide()
	end
	w.SessionTimer:SetText(stub.inCombat and "[00:42] " or "")
end

local function each(fn) for _, w in pairs(wins) do fn(w) end end

local w1 = newWindow(1)
w1:SetPoint("TOPLEFT", DM, "TOPLEFT", 0, 0)
w1:SetPoint("BOTTOMRIGHT", DM, "BOTTOMRIGHT", 0, 0)
stub.guard(DM, CALLS, "DamageMeter")
refresh(w1)

function stub.damage(list)
	sources = list
	each(refresh)
end

function stub.dmSetting(key, value)
	dm[key] = value
	if key == "width" or key == "height" then DM:SetSize(dm.width, dm.height) end
	each(function(w)
		if key == "alpha" then w:SetAlpha(value) end
		if key == "bgAlpha" then w.MinimizeContainer.Background:SetAlpha(value) end
		refresh(w)
	end)
	stub.fire("EDIT_MODE_LAYOUTS_UPDATED")
end

function stub.dmWindow(i, x, y, width, height)
	local w = wins[i] or newWindow(i)
	w.h = height
	-- The game's own placing of a player's window (SetupSessionWindow, then the saved position).
	w:ClearAllPoints()
	w:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x, y)
	w:SetSize(width, height)
	w:SetMovable(true)
	w:SetResizable(true)
	w:Show()
	refresh(w)
	return w
end

-- SetMinimized: the button's atlases swapped, the container shown or hidden.
function stub.dmMinimize(i, minimized)
	local w = wins[i]
	local b = w.MinimizeButton
	b:GetNormalTexture():SetAtlas(minimized and "ui-questtrackerbutton-expand-all" or "ui-questtrackerbutton-collapse-all")
	b:GetPushedTexture():SetAtlas(minimized and "ui-questtrackerbutton-expand-all-pressed" or "ui-questtrackerbutton-collapse-all-pressed")
	w.MinimizeContainer:SetShown(not minimized)
end

-- The header's menus (Blizzard_Menu): a tagged menu's ModifyMenu callbacks
-- run as it is built, its root's acquired callbacks on the pooled menu frame
-- once its style laid its ground (MenuStyle1: common-dropdown-bg 10 out at
-- 92.5%; MenuStyle2, the session menu's: common-dropdown-c-bg). What is
-- attached is freed when the menu closes. stub_chat.lua has the same, when loaded.
if not stub.openMenu then
	local modifiers, menu, attached, items = {}, nil, {}, {}
	Menu = { ModifyMenu = function(tag, fn) modifiers[tag] = modifiers[tag] or {}; table.insert(modifiers[tag], fn) end }
	-- The compositor: an attached region, freed (and set to its defaults) when the menu closes.
	-- AttachTexture from our code writes the compositor's lists and the shared
	-- texture pool tainted: the menu code that walks them next runs as ours
	-- (s526: the session menu's generator on secret durations). Reported.
	local function attachGuard()
		for level = 2, 40 do
			local info = debug.getinfo(level, "S")
			if not info then break end
			if stub.addonSources[info.source] == "PolestarUI" then
				return geterrorhandler()("AttachTexture called from PolestarUI code (taints the menu's compositor)")
			end
		end
	end
	local function attach(f, kind)
		attachGuard()
		local t = kind == "FontString" and f:CreateFontString(nil, "ARTWORK", GameFontHighlight) or f:CreateTexture(nil, "ARTWORK", nil, 7)
		table.insert(attached, t)
		return t
	end
	function stub.closeMenu()
		if not menu then return end
		for _, t in ipairs(attached) do
			t:Hide()
			local p = t:GetParent()
			for k, r in ipairs(p.regions) do if r == t then table.remove(p.regions, k) break end end
		end
		for _, f in ipairs(items) do f:Hide() end
		attached, items = {}, {}
		local c = stub.cascadeVisibility
		stub.cascadeVisibility = true -- as the client: what is on the menu hides with it
		menu:Hide()
		stub.cascadeVisibility = c
	end
	-- An item's description: { text, radio, check, selected, submenu, divider }; the game's initializers
	-- (ButtonInitializer, MenuVariants.CreateRadio/CreateCheckbox/CreateSubmenuArrow/CreateDivider), then those added.
	local function description(o)
		local d = { o = o, inits = {} }
		function d.AddInitializer(self, fn) for _, f in ipairs(self.inits) do if f == fn then return end end table.insert(self.inits, fn) end
		function d.IsRadio() return o.radio == true end
		function d.IsCheckbox() return o.check == true end
		function d.CanOpenSubmenu() return o.submenu == true end
		function d.EnumerateElementDescriptions() return ipairs({}) end
		return d
	end
	local function stockItem(item, o)
		if o.divider then
			local t = item:AttachTexture()
			t:SetPoint("LEFT", item, "LEFT", 0, 0)
			t:SetPoint("RIGHT", item, "RIGHT", 0, 0)
			t:SetHeight(13)
			t:SetColorTexture(0.5, 0.45, 0.35, 0.6)
			return
		end
		if o.submenu then
			item.arrow = item:AttachTexture()
			item.arrow:SetPoint("RIGHT", item, "RIGHT", 0, 0)
			item.arrow:SetSize(16, 16)
			item.arrow:SetColorTexture(0.95, 0.8, 0.2, 1)
		end
		item.highlight = item:AttachTexture()
		item.highlight:SetAllPoints(item)
		item.highlight:SetColorTexture(1, 0.85, 0.4, 0.4)
		item.highlight:SetDrawLayer("BACKGROUND")
		item.highlight:SetShown(o.hover == true)
		local left = item
		if o.radio or o.check then
			item.leftTexture1 = item:AttachTexture()
			item.leftTexture1:SetSize(16, 16)
			item.leftTexture1:SetPoint("LEFT", item, "LEFT", o.radio and -3 or 0, 0)
			item.leftTexture1:SetColorTexture(0.25, 0.22, 0.18, 1)
			item.leftTexture2 = nil
			if o.selected then
				item.leftTexture2 = item:AttachTexture()
				item.leftTexture2:SetSize(10, 10)
				item.leftTexture2:SetPoint("CENTER", item.leftTexture1, "CENTER", 0, 0)
				item.leftTexture2:SetColorTexture(1, 0.8, 0.1, 1)
			end
			left = item.leftTexture1
		end
		local fs = attach(item, "FontString")
		fs:SetPoint("LEFT", left, left == item and "LEFT" or "RIGHT", left == item and 0 or 3, 0)
		fs:SetText(o.text)
	end
	-- items: labels, or item descriptions as above.
	function stub.openMenu(owner, tag, list, style2)
		stub.closeMenu()
		local descs = {}
		for k, o in ipairs(list) do descs[k] = description(type(o) == "table" and o or { text = o }) end
		local root = { callbacks = {} }
		function root.AddMenuAcquiredCallback(self, fn) table.insert(self.callbacks, fn) end
		function root.EnumerateElementDescriptions() return ipairs(descs) end
		for _, fn in ipairs(modifiers[tag] or {}) do fn(owner, root) end
		if not menu then
			menu = CreateFrame("Frame", "StubMenu", UIParent)
			menu:SetFrameStrata("FULLSCREEN_DIALOG")
			menu.AttachTexture = function(self) return attach(self) end
		end
		menu:ClearAllPoints()
		menu:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -4)
		menu:SetSize(160, (style2 and 13 or 23) + #descs * 20)
		local bg = menu:AttachTexture()
		if style2 then
			bg:SetPoint("TOPLEFT", menu, "TOPLEFT", -17, 12)
			bg:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", 17, -22)
			bg:SetAtlas("common-dropdown-c-bg")
		else
			bg:SetPoint("TOPLEFT", menu, "TOPLEFT", -10, 3)
			bg:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", 10, -3)
			bg:SetAtlas("common-dropdown-bg")
			bg:SetAlpha(0.925)
		end
		for _, fn in ipairs(root.callbacks) do fn(menu) end
		for k, d in ipairs(descs) do
			local item = CreateFrame(d.o.divider and "Frame" or "Button", nil, menu)
			item.AttachTexture = function(self) return attach(self) end
			item:SetFrameLevel(menu:GetFrameLevel() + 20) -- the client lays items 20 levels over the menu
			item:SetPoint("TOPLEFT", menu, "TOPLEFT", style2 and 3 or 8, (style2 and -6 or -8) - (k - 1) * 20)
			item:SetSize(144, 20)
			table.insert(items, item)
			stockItem(item, d.o)
			for _, fn in ipairs(d.inits) do fn(item, d, menu) end
		end
		menu:Show()
		return menu, bg, items
	end
end

-- ShowSourceWindow: the breakdown of a row, spell rows of the source's class.
function stub.dmBreakdown(i, n)
	local w = wins[i]
	local s = sources[n]
	local sw = w.MinimizeContainer.SourceWindow
	local spells = { { name = "Fireball", amount = s.amount * 0.6 }, { name = "Pyroblast", amount = s.amount * 0.3 }, { name = "Scorch", amount = s.amount * 0.1 } }
	local step = dm.barHeight + dm.spacing
	sw:ClearAllPoints()
	sw:SetPoint("TOPLEFT", w, "TOPRIGHT", 4, 0)
	sw:SetSize(240, #spells * step + 12)
	for k, sp in ipairs(spells) do
		local e = w.spellPool[k] or newEntry(sw.ScrollBox.ScrollTarget, w:GetName() .. " spell " .. k)
		w.spellPool[k] = e
		setupEntry(e)
		init(e, { name = sp.name, class = s.class, amount = sp.amount }, nil, spells[1].amount)
		e:ClearAllPoints()
		e:SetPoint("TOPLEFT", sw.ScrollBox.ScrollTarget, "TOPLEFT", 0, -(k - 1) * step)
		e:SetPoint("TOPRIGHT", sw.ScrollBox.ScrollTarget, "TOPRIGHT", 0, -(k - 1) * step)
		e:Show()
	end
	sw:Show()
end

-- Edit Mode shows the primary window's sample session (SetIsEditing).
local enter, exit = stub.enterEditMode, stub.exitEditMode
function stub.enterEditMode()
	w1.editing = true
	refresh(w1)
	enter()
end
function stub.exitEditMode()
	w1.editing = false
	refresh(w1)
	exit()
end

stub.dmEntries = entries
