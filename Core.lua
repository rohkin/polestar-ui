-- Polestar: UI, a companion to Polestar: the game's own windows remade in
-- Polestar's look, drawn with Polestar's kit (Polestar.Widgets, Polestar.Theme).
--
-- Taint: Forever's gamepad UI reads parts of the default UI from secure code,
-- so nothing here writes into Blizzard frames; our windows are our own, and a
-- stock window is closed the moment the game opens it (docs/DESIGN.md, "The
-- Replacement Contract"). The exceptions are the tooltips and the chat,
-- restyled in place (Modules/Tooltips.lua, Modules/Chat.lua). With the gamepad UI on, every module starts off and
-- no slash command is registered.

local ADDON, ns = ...
PolestarUI = ns

-- Polestar 0.4.0 or newer (its settings registry, frame movers, coin
-- symbols); an older one gets a chat line at login and no module. Only a
-- plain release number ("0.3.7") is checked: a dev or test build passes.
local NEEDS = "Polestar: UI needs Polestar 0.4.0 or newer; update Polestar."
function ns.PolestarTooOld(v)
	local a, b, c = tostring(v):match("^(%d+)%.(%d+)%.(%d+)$")
	if not a then return false end
	a, b, c = tonumber(a), tonumber(b), tonumber(c)
	return a * 1e6 + b * 1e3 + c < 4000
end
ns.tooOld = ns.PolestarTooOld(Polestar.version)

-- Our folder was Polestar_UI until Polestar's rule took the Polestar_* names
-- for its own suite; an old copy left in AddOns would load beside us.
local OLD = "Polestar_UI"
local function oldFolder()
	local A = C_AddOns or {}
	local loaded, state = A.IsAddOnLoaded or IsAddOnLoaded, A.GetAddOnEnableState
	if loaded and loaded(OLD) then return true end
	return state ~= nil and (state(OLD, UnitName("player")) or 0) > 0
end

ns.modules, ns.order = {}, {}

-- A module: { Enable = fn (once, at login or when switched on), Show = fn(...),
-- stock = fn (the stock window it replaces, when that is the one shown),
-- reloadOff = true (switching it off waits for /reload), Apply = fn (a module
-- with no window: switched on or off again live, it restyles or restores),
-- noun = what it switches ("window" when not given), micro = the game's micro
-- button that opens its stock window (ns.Doors sets it; "Use game window"
-- clicks it) }, keyed by its
-- slash-command name.
function ns.Module(key, m)
	ns.modules[key] = m
	ns.order[#ns.order + 1] = key
	return m
end

-- Runs fn at PLAYER_LOGIN, before the modules are enabled (every addon and its
-- saved variables are loaded): for an Addons/*.lua file, which cannot rely on
-- load order. Now, if login has passed.
local late = {}
function ns.AfterLogin(fn)
	if late then late[#late + 1] = fn else fn() end
end

-- With no saved choice a module is on, unless the gamepad UI is, or the
-- module says `defaultOff` (our Bags beside Baganator, Addons/Baganator.lua).
-- A module with `blockedBy` (another addon's name, set in ns.AfterLogin: our
-- Bags and Bank beside Bagnon) is off whatever was saved, and cannot switch on.
function ns.Enabled(key)
	local m = ns.modules[key]
	if m and m.blockedBy then return false end
	local v = PolestarUIDB and PolestarUIDB.modules[key]
	if v == nil then
		return not Polestar.GamepadUI() and not (m and m.defaultOff)
	end
	return v
end

function ns.Say(msg) print("|cffe6ba66Polestar: UI|r " .. msg) end
local say = ns.Say

-- Says why a blocked module stays off; true when it is.
local function blocked(key)
	local m = ns.modules[key]
	if not (m and m.blockedBy) then return false end
	say(key .. ": off while " .. m.blockedBy .. " is loaded (its own window takes its place).")
	return true
end

function ns.Show(key, ...)
	if ns.tooOld then return print(NEEDS) end
	local m = ns.modules[key]
	if blocked(key) then return end
	if m and m.Show then m.Show(...) end
end

Polestar.OnLogin(function()
	PolestarUIDB = PolestarUIDB or {}
	PolestarUIDB.modules = PolestarUIDB.modules or {}
	PolestarUIDB.pos = PolestarUIDB.pos or {}
	PolestarUICharDB = PolestarUICharDB or {}
	if ns.tooOld then return print(NEEDS) end
	if oldFolder() then
		-- Both copies would take the same windows: none of ours starts, the old one is off after /reload.
		ns.tooOld, NEEDS = true, "Polestar: UI: the old Polestar_UI folder is still installed. Delete Interface\\AddOns\\Polestar_UI, then /reload."
		local A = C_AddOns or {}
		local disable = A.DisableAddOn or DisableAddOn
		if disable then disable(OLD) end
		return print(NEEDS)
	end
	local q = late
	late = nil
	for _, fn in ipairs(q) do fn() end
	for _, key in ipairs(ns.order) do
		if ns.Enabled(key) then
			ns.modules[key].psStarted = true
			ns.modules[key].Enable()
		end
	end
	if ns.WatchStock then ns.WatchStock() end
end)

-- Ends the shown tooltip with a hint of what the player can do here, in
-- textMuted after a blank line (docs/DESIGN.md, "Header").
function ns.TooltipHint(text)
	local r, g, b = Polestar.Theme.Color("textMuted")
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(text, r, g, b, true)
end

-- A shell made with `sidebar = 0` has no sidebar: the main column hangs off the
-- window itself, never off the 0-wide sidebar (docs/CLIENT.md, rule 12),
-- `left` past its left edge (a section rail's width). Polestar's emblem,
-- which sits on the sidebar or the rail, is parked out of sight.
function ns.Plain(f, left)
	f.Sidebar:Hide()
	if not f.psParked then
		f.psParked = CreateFrame("Frame", nil, f)
		f.psParked:Hide()
		for _, r in ipairs({ f.Emblem, f.Emblem.Glow, f.Emblem.Hot }) do r:SetParent(f.psParked) end
	end
	f.Main:ClearAllPoints()
	f.Main:SetPoint("TOPLEFT", f, "TOPLEFT", 1 + (left or 0), -1)
	f.Main:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
end

-- The compact grid (docs/DESIGN.md, "The Game Window Shell"): Polestar's shell
-- lays out by W.SHELL (a 112 band, 40 tabs, 56 footer, 32 pad) on every
-- ShellTabs, ShellFooter and ShellBody; a window made compact (ns.Compact) is
-- laid out again after each, by its own sizes (f.psHead, f.psTabsH, f.psFootH,
-- f.psPad). Polestar is not changed: these are post-hooks on its table.
local function compactPlace(f)
	local W, pad = Polestar.Widgets, f.psPad
	local mainW = f:GetWidth() - 2 - (f.psRail or 0) - (f.Sidebar:IsShown() and f.psSidebar or 0)
	f.BodyWidth = mainW - 2 * pad
	f.Band:SetTexCoord(Polestar.Theme.BandCoords(mainW, f.psHead))
	f.psHazeOpts.width = mainW * 0.9
	f.psHaze:SetSize(mainW * 0.9, f.psHead)
	f.psViewH = f:GetHeight() - f.psHead - (f.TabRow:IsShown() and f.psTabsH or 0) - (f.Footer:IsShown() and f.psFootH or 0)
	local x = pad - 12
	for _, t in ipairs(f.tabButtons) do
		if t:IsShown() then
			t:SetHeight(f.psTabsH)
			t:ClearAllPoints()
			t:SetPoint("BOTTOMLEFT", f.TabRow, "BOTTOMLEFT", x, 0)
			x = x + t:GetWidth() + 4
		end
	end
	f.psTabsRight = x
	for side, sign in pairs({ left = 1, right = -1 }) do
		local b = f.footerButtons[side][1]
		if b and b:IsShown() then
			b:ClearAllPoints()
			b:SetPoint(side == "left" and "LEFT" or "RIGHT", f.Footer, side == "left" and "LEFT" or "RIGHT", sign * (pad - (b.psGhost and 8 or 0)), 0)
		end
	end
	-- The search (ns.TopNav) takes the tab row's room right of the tabs, 200 at most.
	if f.psTopNav and not rawget(f, "psSearchInFilter") then
		local filter = rawget(f, "psFilter")
		local room = mainW - pad - x - 12 - (filter and 36 or 0)
		f.Search:SetWidth(math.max(120, math.min(200, room)))
	end
end

do
	local W = Polestar.Widgets
	for _, name in ipairs({ "ShellTabs", "ShellFooter" }) do
		hooksecurefunc(W, name, function(f) if rawget(f, "psCompact") then compactPlace(f) end end)
	end
	hooksecurefunc(W, "ShellBody", function(f) if rawget(f, "psCompact") then f.Body:SetWidth(f.BodyWidth + 2 * f.psPad) end end)
end

-- The header's tools on the compact band's middle: the close button (when the
-- skin draws it there; the game's looks put it on the frame's corner), the
-- "..." menu and the scale left of it; the title on the band's top line, clear of them.
local function compactHeader(f)
	local head, H, pad = f.Header, f.psHead, f.psPad
	f.Close:ClearAllPoints()
	f.Close:SetPoint("RIGHT", head, "TOPRIGHT", -12, -H / 2)
	local right = f.Close:IsShown() and f.Close or nil
	for _, it in ipairs({ { rawget(f, "psMenu"), 4 }, { rawget(f, "HeaderTools"), 14 } }) do
		local b = it[1]
		if b and b:IsShown() then
			b:ClearAllPoints()
			if right then b:SetPoint("RIGHT", right, "LEFT", -it[2], 0) else b:SetPoint("RIGHT", head, "TOPRIGHT", -pad, -H / 2) end
			right = b
		end
	end
	f.Title:ClearAllPoints()
	f.Title:SetPoint("TOPLEFT", head, "TOPLEFT", pad, -10)
	if right then
		f.Title:SetPoint("TOPRIGHT", right, "TOPLEFT", -16, H / 2 - right:GetHeight() / 2 - 10)
	else
		f.Title:SetPoint("TOPRIGHT", head, "TOPRIGHT", -pad, -10)
	end
end

-- A shell (W.Shell) on the compact grid: a 60 band (the title in Display, its
-- subtitle one line under it), 36 tabs (the skin's when smaller), a 44 footer
-- and a 24 pad (the skin's less 8). The band's art is cropped to the new
-- height, never stretched. f.psPad is the body's edge: lay content out by it,
-- not W.SHELL.pad. Call after ns.WindowMenu.
function ns.Compact(f)
	local W, Theme = Polestar.Widgets, Polestar.Theme
	f.psCompact = true
	f.psHead, f.psTabsH, f.psFootH, f.psPad = 60, math.min(W.SHELL.tabs, 36), 44, W.SHELL.pad - 8
	f.Header:SetHeight(f.psHead)
	f.TabRow:SetHeight(f.psTabsH)
	f.Footer:SetHeight(f.psFootH)
	-- Polestar's haze is sized to its band on every repaint: ours, as tall as this one.
	f.Haze:SetAlpha(0)
	f.psHazeOpts = { height = f.psHead }
	f.psHaze = W.Haze(f.Header, f.psHazeOpts)
	Theme.Font(f.Title, "display")
	f.Subtitle:SetWordWrap(false)
	f.Subtitle:SetHeight(16)
	f.Subtitle:ClearAllPoints()
	f.Subtitle:SetPoint("TOPLEFT", f.Title, "BOTTOMLEFT", 0, -4)
	f.Subtitle:SetPoint("TOPRIGHT", f.Title, "BOTTOMRIGHT", 0, -4)
	local tools = rawget(f, "HeaderTools")
	if tools then hooksecurefunc(tools, "Place", function() compactHeader(f) end) end
	compactHeader(f)
	compactPlace(f)
end

-- The search inside the filter's dropdown (the tab row keeps its room for the
-- tabs): f.psFilter, a "sliders" button (made here unless the window has one),
-- opens `menu(button)` (default: the search alone), which shows its rows
-- through ns.FilterMenu; the box takes the focus only when clicked (movement
-- keys must still move the character), Enter keeps the search and closes,
-- any other menu, the dropdown's or the window's hiding puts it away.
local filterHost -- the window ns.FilterMenu is showing, while it shows
function ns.SearchInFilter(f, menu)
	local W = Polestar.Widgets
	f.psSearchInFilter = true
	menu = menu or function() ns.FilterMenu(f, {}) end
	local function click(self)
		if W.MenuShown(self) then return W.HideMenu() end
		menu(self)
	end
	if rawget(f, "psFilter") then
		f.psFilter:SetScript("OnClick", click)
	else
		f.psFilter = W.IconButton(f.TabRow, "sliders", 30, "Search and filter", click, 14)
		Polestar.Theme.Skin(f.psFilter, "editbox")
	end
	f.psFilter.psTip = "Search and filter"
	f.Search:Hide()
	f.Search:HookScript("OnEnterPressed", function() W.HideMenu() end)
	f:HookScript("OnHide", function() if W.MenuShown(f.psFilter) then W.HideMenu() end end)
	-- Another menu on the shared frame (a submenu of the filter too) leaves the box out.
	hooksecurefunc(W, "ShowMenu", function() if filterHost ~= f then f.Search:ClearFocus(); f.Search:Hide() end end)
	return f.psFilter
end

-- W.ShowMenu on f.psFilter (opts as its) with f.Search over a blank first row.
function ns.FilterMenu(f, items, opts)
	local W = Polestar.Widgets
	local list = { { text = "", disabled = true } }
	if #items > 0 then list[2] = { separator = true } end
	for _, it in ipairs(items) do list[#list + 1] = it end
	opts = opts or {}
	opts.minWidth = math.max(opts.minWidth or 0, 220)
	filterHost = f
	local menu = W.ShowMenu(f.psFilter, list, opts)
	filterHost = nil
	local s, row = f.Search, menu.rows[1]
	if not rawget(f, "psFilterHooked") then
		f.psFilterHooked = true
		menu:HookScript("OnHide", function() s:ClearFocus(); s:Hide() end)
	end
	s:SetParent(menu)
	s:SetFrameLevel(row:GetFrameLevel() + 5)
	s:ClearAllPoints()
	s:SetPoint("TOPLEFT", row, "TOPLEFT", 6, 0)
	s:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -6, 0)
	s:Show()
	return menu
end

-- A game menu (Blizzard_Menu) as rows of Polestar's: `generator(owner, root)`
-- run into a root description as MenuUtil.CreateContextMenu does
-- (Menu.PopulateDescription), so what other addons add under its tag
-- (Menu.ModifyMenu) comes too; nothing of the game's menu frames is shown.
-- Titles are headings, dividers and spacers separators, checkboxes and radios
-- checked rows, a submenu a "…" row that opens it in place, a "Back" row
-- first (Polestar has one menu frame, no flyouts). A click picks the entry
-- as the game's menu would (its responder, then its MenuResponse): Open and
-- Refresh show the level again, regenerated so checks are read anew; Close
-- goes up one level; nil and CloseAll leave it shut. `show(items, depth)`
-- shows one level (ns.FilterMenu or W.ShowMenu) and returns the menu.
function ns.GameMenu(owner, generator, show)
	local path = {}
	local open
	local function hookRows(menu)
		for _, row in ipairs(menu.rows) do
			if not rawget(row, "psGameHooked") then
				row.psGameHooked = true
				-- The entry's own tooltip (its OnEnter), on our row.
				row:HookScript("OnEnter", function(self)
					local it = self.psItem
					if it and it.psEnter then pcall(it.psEnter, self, it.psDesc) end
				end)
				row:HookScript("OnLeave", function(self)
					local it = self.psItem
					if it and it.psLeave then pcall(it.psLeave, self, it.psDesc) end
				end)
			end
		end
	end
	local function rows(desc, depth)
		local items, gap = {}, false
		local function add(it)
			if gap and #items > 0 then items[#items + 1] = { separator = true } end
			gap = false
			items[#items + 1] = it
			return it
		end
		if depth > 0 then
			add({ text = BACK or "Back", onClick = function() path[#path] = nil; open() end })
			gap = true
		end
		for _, e in desc:EnumerateElementDescriptions() do
			local text, kids, picks = MenuUtil.GetElementText(e), e:HasElements(), e:HasResponder()
			if text == nil and not kids then
				gap = true
			else
				local it = add({ text = text, disabled = not e:IsEnabled(), psDesc = e, psEnter = e:GetOnEnter(), psLeave = e:GetOnLeave() })
				if picks then
					it.checked = (e:IsCheckbox() or e:IsRadio()) and e:IsSelected() or nil
					it.onClick = function()
						local _, r = e:Pick(MenuInputContext.MouseButton, "LeftButton")
						if r == MenuResponse.Close then path[#path] = nil end
						if r == MenuResponse.Open or r == MenuResponse.Refresh or (r == MenuResponse.Close and depth > 0) then open() end
					end
				elseif not kids then
					it.disabled = true -- a title
				end
				if kids then
					local into = { text = (text or "") .. "…", disabled = it.disabled, onClick = function() path[#path + 1] = text; open() end }
					if picks then add(into) else it.text, it.onClick = into.text, into.onClick end
				end
			end
		end
		return items
	end
	function open()
		local root = MenuUtil.CreateRootMenuDescription(MenuVariants.GetDefaultContextMenuMixin())
		Menu.PopulateDescription(generator, owner, root)
		-- Down the path by text: the description is new each time.
		local desc, depth = root, 0
		for _, text in ipairs(path) do
			local found
			for _, e in desc:EnumerateElementDescriptions() do
				if MenuUtil.GetElementText(e) == text and e:HasElements() then found = e break end
			end
			if not found then break end
			desc, depth = found, depth + 1
		end
		for i = #path, depth + 1, -1 do path[i] = nil end
		hookRows(show(rows(desc, depth), depth))
	end
	open()
end

-- Page nav as top tabs (docs/DESIGN.md, "The Game Window Shell"): the window
-- has no sidebar (ns.Plain); its pages are W.ShellTabs, each keeping a nav
-- row's state, and the search (f.Search, and f.psFilter when the window has
-- one) moves to the tab row's right end. items: { key, label, icon (a game
-- texture, cropped), count, dot, locked, tip }: a locked tab recedes and its
-- click does nothing; `tip` (its tooltip under the label) says why. `active`
-- nil marks none (a search across every page).
function ns.TopNav(f, items, active, onSelect)
	local W, Theme = Polestar.Widgets, Polestar.Theme
	if not f.psTopNav then
		f.psTopNav = true
		if f.Sidebar:IsShown() then ns.Plain(f, f.psRail) end
		f.psKeepTabRow = true
		local pad = f.psPad or W.SHELL.pad
		local filter = rawget(f, "psFilter")
		-- f.psSearchInFilter: the window hosts its search in the filter's dropdown (Spellbook).
		local inFilter = filter and rawget(f, "psSearchInFilter")
		if not inFilter then
			f.Search:SetParent(f.TabRow)
			f.Search:ClearAllPoints()
		end
		if filter then
			filter:SetParent(f.TabRow)
			filter:ClearAllPoints()
			filter:SetPoint("RIGHT", f.TabRow, "RIGHT", -pad, 0)
			if not inFilter then f.Search:SetPoint("RIGHT", filter, "LEFT", -6, 0) end
		else
			f.Search:SetPoint("RIGHT", f.TabRow, "RIGHT", -pad, 0)
		end
	end
	local locked = {}
	for _, it in ipairs(items) do locked[it.key] = it.locked end
	W.ShellTabs(f, items, active, function(k) if not locked[k] then onSelect(k) end end)
	for i, it in ipairs(items) do
		local t = f.tabButtons[i]
		if t and t:IsShown() then
			if not t.psNavIcon then
				t.psNavIcon = ns.GameIcon(t)
				t.psNavIcon:SetSize(16, 16)
				t.psNavIcon:SetPoint("RIGHT", t.Label, "LEFT", -6, 0)
				t.psNavCount = W.Text(t, "number", "textMuted")
				t.psNavCount:SetPoint("LEFT", t.Label, "RIGHT", 6, 0)
				t.psNavDot = W.Tex(t, "ARTWORK", "circle", "warning")
				t.psNavDot:SetSize(6, 6)
				t.psNavDot:SetPoint("LEFT", t.Label, "RIGHT", 6, 0)
				t:HookScript("OnEnter", function(self)
					if not self.psNavTip then return end
					GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
					GameTooltip:SetText(self.Label:GetText())
					if self.psNavLocked then
						GameTooltip:AddLine(self.psNavTip, 1, 0.2, 0.2, true)
					else
						GameTooltip:AddLine(self.psNavTip, 1, 1, 1, true)
					end
					GameTooltip:Show()
				end)
				t:HookScript("OnLeave", W.HideTooltip)
			end
			-- A locked page without a stock icon wears the lock glyph.
			local icon = it.icon or (it.locked and Theme.Media("lock"))
			t.psNavIcon:SetShown(icon and true or false)
			t.psNavIcon:SetTexture(icon)
			if it.icon then
				W.Uncolor(t.psNavIcon)
				t.psNavIcon:SetVertexColor(1, 1, 1, 1)
				t.psNavIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			elseif icon then
				t.psNavIcon:SetTexCoord(0, 1, 0, 1)
				W.Color(t.psNavIcon, "textMuted")
			end
			local count = it.count and it.count ~= 0 and not it.dot
			t.psNavCount:SetText(count and it.count or "")
			t.psNavCount:SetShown(count and true or false)
			t.psNavDot:SetShown(it.dot and true or false)
			t.psNavTip, t.psNavLocked = it.tip, it.locked
			if it.locked then W.Color(t.Label, "textMuted") end
			t:SetAlpha(it.locked and 0.55 or 1)
			-- The tab widens by what it now holds; its label shifts to keep the lot centred.
			local l = icon and 22 or 0
			local r = count and math.ceil(t.psNavCount:GetStringWidth()) + 6 or it.dot and 12 or 0
			t:SetWidth(t:GetWidth() + l + r)
			local p, rel, rp, _, y = t.Label:GetPoint(1)
			t.Label:ClearAllPoints()
			t.Label:SetPoint(p, rel, rp, (l - r) / 2, y)
		end
	end
	if f.psCompact then
		compactPlace(f)
	else
		local x = W.SHELL.pad - 12
		for _, t in ipairs(f.tabButtons) do
			if t:IsShown() then
				t:ClearAllPoints()
				t:SetPoint("BOTTOMLEFT", f.TabRow, "BOTTOMLEFT", x, 0)
				x = x + t:GetWidth() + 4
			end
		end
	end
end

-- A section rail (W.ShellRail) wearing the game's icons, not glyphs (the Two
-- Families Rule): the rail's tint taken off, the client's border cropped,
-- 24px. The rail grows to its widest label; a window without a sidebar hangs
-- its main column off the rail's edge (docs/CLIENT.md, rule 12). Shared by
-- Professions (ns.ProfessionTabs) and Character. items: { key, label, icon, tip }.
-- opts.slim: a 48 rail of icons only, from the band's line down, each label in
-- its tooltip (where the stock window has icon side-tabs).
local SLIM = 48
function ns.GameRail(win, items, active, onSelect, opts)
	local W = Polestar.Widgets
	W.ShellRail(win, items, nil, active, onSelect)
	for i, d in ipairs(items) do
		local t = win.railButtons[i].Icon
		W.Uncolor(t)
		t:SetVertexColor(1, 1, 1, 1)
		t:SetTexture(d.icon)
		t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		t:SetSize(24, 24)
	end
	if opts and opts.slim then
		local grow = SLIM - win.psRail
		if grow ~= 0 then
			win.psRail = SLIM
			win.Rail:SetWidth(SLIM)
			win.Sidebar:SetPoint("TOPLEFT", win, "TOPLEFT", 1 + SLIM, -1)
			win.Sidebar:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 1 + SLIM, 1)
			win:SetWidth(win:GetWidth() + grow)
			W.LayoutRim(win)
		end
		local top = win.psHead or W.SHELL.header
		for i, b in ipairs(win.railButtons) do
			if b:IsShown() then
				b:SetSize(SLIM, SLIM)
				b.Label:Hide()
				b.Icon:ClearAllPoints()
				b.Icon:SetPoint("CENTER", b, "CENTER", 0, 0)
				b:ClearAllPoints()
				b:SetPoint("TOPLEFT", win.Rail, "TOPLEFT", 0, -(top + (i - 1) * SLIM))
			end
		end
	end
	if not win.Sidebar:IsShown() then ns.Plain(win, win.psRail) end
	if win.psCompact then compactPlace(win) end
end

-- W.ShellFooter, its buttons back on at full alpha: the footer reuses them page
-- to page, and one greyed on the last page would stay greyed. The caller greys
-- its own after (ns.SetEnabled).
function ns.Footer(f, left, right)
	Polestar.Widgets.ShellFooter(f, left, right)
	for _, side in pairs(f.footerButtons) do
		for _, b in ipairs(side) do ns.SetEnabled(b, true) end
	end
end

-- A flyout: a window-skinned panel flush on the right edge of window `f`, as
-- tall as it and `width` wide, that takes the mouse. With the window it reads
-- as one window (joinFlyout): one border and one shadow round both, a
-- divider between. The caller shows it and calls ns.DockFlyout.
function ns.Flyout(f, name, width)
	local d = CreateFrame("Frame", name, f)
	d:SetPoint("TOPLEFT", f, "TOPRIGHT", 0, 0)
	d:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT", 0, 0)
	d:SetWidth(width)
	d:EnableMouse(true)
	-- Its outer border is the window's, drawn on psRim (joinFlyout).
	d.psNoBorder = true
	d.psRim = CreateFrame("Frame", nil, d)
	d.psDivider = Polestar.Widgets.Divider(d, true)
	d.psDivider:SetPoint("TOPLEFT", d, "TOPLEFT", 0, 0)
	d.psDivider:SetPoint("BOTTOMLEFT", d, "BOTTOMLEFT", 0, 0)
	Polestar.Theme.Skin(d, "window")
	return d
end

-- A piece Polestar's paint shows again (Show, SetShown) kept hidden while
-- r.psJoined.
local function keepHidden(r, on)
	if not r then return end
	if not r.psKeepHidden then
		r.psKeepHidden = true
		local function back(self) if self.psJoined then self:Hide() end end
		hooksecurefunc(r, "Show", back)
		hooksecurefunc(r, "SetShown", back)
	end
	r.psJoined = on
	if on then r:Hide() end
end

-- The window and its shown flyout as one window. Polestar paints each frame's
-- border (Theme.Border, growing n px outward), contact lines (psSkin.edge:
-- light, top, bottom, left, right) and shadow (psShadow) alone; here the
-- window's right border and contact line go while the flyout shows, the
-- flyout's border is the window's continued on psRim (its top and bottom from
-- where the window's end, no left one), and the window's shadow reaches round
-- the flyout, whose own never shows. Put away, the window is painted again.
-- Called again on each paint of the window's border (the Theme.Border hook
-- below) and full theme change.
local function joinFlyout(f, fly)
	local Theme = Polestar.Theme
	local on = fly:IsShown()
	local e, rim = f.psBorder, fly.psRim
	if e and e[1]:IsShown() then
		local n = f.psBorderSize or 1
		local o = (n - 1) * Theme.Pixel(fly)
		rim:ClearAllPoints()
		rim:SetPoint("TOPLEFT", fly, "TOPLEFT", 2 * o, 0)
		rim:SetPoint("BOTTOMRIGHT", fly, "BOTTOMRIGHT", 0, 0)
		local r, g, b, a = Theme.Color("windowBorder")
		Theme.Border(rim, r, g, b, a, nil, n)
		rim.psBorder[3]:Hide()
	elseif rim.psBorder then
		for i = 1, 4 do rim.psBorder[i]:Hide() end
	end
	local fe, de = f.psSkin and f.psSkin.edge, fly.psSkin and fly.psSkin.edge
	keepHidden(e and e[4], on)
	keepHidden(fe and fe[5], on)
	keepHidden(de and de[4], true)
	keepHidden(fly.psShadow, true)
	local s = f.psShadow
	if s and s.psOut then
		s:SetPoint("BOTTOMRIGHT", on and fly or f, "BOTTOMRIGHT", s.psOut, -s.psOut - s.psDrop)
	end
	local was = f.psJoined
	f.psJoined = on
	if was and not on then Theme.Repaint(f) end
end

-- A texture for a game icon (item, currency, spell), cropped of the border
-- the client bakes into its icons, as Polestar's own icons are.
function ns.GameIcon(parent, layer)
	local t = parent:CreateTexture(nil, layer or "ARTWORK")
	t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	return t
end

-- A game value the client may hand over secret in combat (docs/CLIENT.md, rule 3): nil when it is.
function ns.Clean(v)
	if v == nil or (issecretvalue and issecretvalue(v)) then return nil end
	return v
end

-- A class name (or any text) in its class colour, lifted to stay legible on the ground (Theme.Legible); plain when `token` is no class or secret.
function ns.ClassText(token, text)
	local c = ns.Clean(token) and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
	if not c then return text end
	local r, g, b = Polestar.Theme.Legible(c.r, c.g, c.b)
	return ("|cff%02x%02x%02x%s|r"):format(r * 255 + 0.5, g * 255 + 0.5, b * 255 + 0.5, text)
end

-- A number the client may hand over secret in combat (docs/CLIENT.md, rule 3): 0 when it is.
function ns.Num(v)
	if v == nil or (issecretvalue and issecretvalue(v)) then return 0 end
	return v
end

-- One cell of the client's grid: the smallest step between positions,
-- ignoring the few units the client nudges a node off it (steps under a
-- quarter of the largest).
function ns.GridCell(v)
	table.sort(v)
	local big, s = 0, nil
	for i = 2, #v do big = math.max(big, v[i] - v[i - 1]) end
	for i = 2, #v do
		local d = v[i] - v[i - 1]
		if d >= big / 4 and d > 0 and (not s or d < s) then s = d end
	end
	return s or 1
end

-- An inset well holding a game icon, in the Polestar look: returns the well and
-- its icon (also well.Icon). `kind` is its frame type, "Frame" when not given;
-- `template` and `name`, a template it inherits and its global name.
function ns.ItemWell(parent, size, kind, template, name)
	local well = CreateFrame(kind or "Frame", name, parent, template)
	well:SetSize(size, size)
	Polestar.Theme.Skin(well, "inset")
	Polestar.Theme.Border(well, Polestar.Theme.Wash("border"))
	local icon = ns.GameIcon(well)
	icon:SetPoint("TOPLEFT", 1, -1)
	icon:SetPoint("BOTTOMRIGHT", -1, 1)
	well.Icon = icon
	return well, icon
end

-- The player's name (UnitName, UnitPVPName: `fn`) as last read out of combat:
-- in combat the client may hand our code a secret one, which tooltips and our
-- strings refuse (docs/CLIENT.md, rule 3). A nil is kept too.
local knownName = {}
function ns.PlayerText(fn)
	local v = fn("player")
	if not (issecretvalue and issecretvalue(v)) then knownName[fn] = v or false end
	return knownName[fn] or nil
end

-- Player-written text (names, notes) in any script, without reading it: a
-- font family (CreateFontFamily) holds Polestar's face for Latin and the
-- client's own faces for Cyrillic, Hangul and Chinese, and the engine picks
-- one per glyph. Names are secret in combat and cannot be scanned
-- (docs/CLIENT.md, rule 3). One family per face, size and flags, made once.
local ALPHABETS = { "russian", "korean", "simplifiedchinese", "traditionalchinese" }
local families, familyCount, clientFaces = {}, 0, nil
function ns.FontFamily(path, size, flags)
	if not (CreateFontFamily and GameFontNormal and GameFontNormal.GetFontObjectForAlphabet) or not path then return nil end
	flags = flags or ""
	local key = path .. "|" .. size .. "|" .. flags
	if families[key] ~= nil then return families[key] or nil end
	if not clientFaces then
		clientFaces = {}
		for _, a in ipairs(ALPHABETS) do
			local ok, obj = pcall(GameFontNormal.GetFontObjectForAlphabet, GameFontNormal, a)
			clientFaces[a] = ok and obj and obj:GetFont() or nil
		end
	end
	local members = { { alphabet = "roman", file = path, height = size, flags = flags } }
	for _, a in ipairs(ALPHABETS) do
		members[#members + 1] = { alphabet = a, file = clientFaces[a] or path, height = size, flags = flags }
	end
	familyCount = familyCount + 1
	local ok, fam = pcall(CreateFontFamily, "PolestarUIFamily" .. familyCount, members)
	families[key] = ok and fam or false
	return families[key] or nil
end

-- Puts the font string on the family of its Polestar font and keeps it there:
-- every Polestar repaint (skin, font, text size, a CJK retext) ends in
-- fs:SetFont, and a post-hook moves it onto that font's family. Colour,
-- shadow and justification survive (SetFontObject would take the family's).
-- -> true, or false when the client has no font families (fs unchanged).
local named = setmetatable({}, { __mode = "k" })
local function onFamily(fs, path, size, flags)
	-- Polestar's own CJK font for a whole string (Theme.ScriptFont) is no Latin face: keep the family.
	local T = Polestar.Theme
	if path and (path == T.ScriptFont("\227\129\130") or path == T.ScriptFont("\234\176\128")) then path = nil end
	local fam = path and ns.FontFamily(path, size, flags) or named[fs]
	if not fam or fam == true then return end
	named[fs] = fam
	local r, g, b, a = fs:GetTextColor()
	local sr, sg, sb, sa = fs:GetShadowColor()
	local sx, sy = fs:GetShadowOffset()
	local jh, jv = fs:GetJustifyH(), fs:GetJustifyV()
	fs:SetFontObject(fam)
	fs:SetTextColor(r, g, b, a)
	if sr then fs:SetShadowColor(sr, sg, sb, sa) end
	if sx then fs:SetShadowOffset(sx, sy) end
	if jh then fs:SetJustifyH(jh) end
	if jv then fs:SetJustifyV(jv) end
end
function ns.NameFont(fs)
	if named[fs] then return true end
	local path, size, flags = fs:GetFont()
	if not ns.FontFamily(path, size, flags) then return false end
	named[fs] = true
	hooksecurefunc(fs, "SetFont", onFamily)
	onFamily(fs, path, size, flags)
	return true
end

-- A player name on a string made with W.Text in `role`: on the font family,
-- else (no families) the old scan, which reads the text and so only runs on
-- names that are never secret: a name past Latin-1 that Polestar's face may
-- not draw takes the game's font object; CJK is Polestar's own.
function ns.NameText(fs, role, text)
	text = text or ""
	if ns.NameFont(fs) then return fs:SetText(text) end
	local Theme = Polestar.Theme
	if text:find("[\196-\244]") and not Theme.ScriptFont(text) then
		fs:SetFontObject(GameFontHighlight)
		fs.psGameFace = true
	elseif fs.psGameFace then
		fs.psGameFace = nil
		Theme.Font(fs, role)
	end
	fs:SetText(text)
end

-- The sidebar's head in a game window (docs/DESIGN.md, "Subject Block"), in
-- place of Polestar's lockup: a 36px icon well on the band's title line, the
-- name in Title right of it, one Small textDim line under it. Returns
-- { icon, name, line }.
function ns.SubjectBlock(f)
	local W = Polestar.Widgets
	-- Reparented, not hidden: the shell re-shows its version line on every show.
	local holder = CreateFrame("Frame", nil, f)
	holder:Hide()
	for _, r in ipairs({ f.Emblem, f.Emblem.Glow, f.Emblem.Hot, f.Wordmark, f.Tagline, f.Status, f.Stage }) do r:SetParent(holder) end
	local well, icon = ns.ItemWell(f.Sidebar, 36)
	well:SetPoint("LEFT", f.Sidebar, "TOPLEFT", 24, -47)
	local name = W.Text(f.Sidebar, "title", "text")
	name:SetPoint("BOTTOMLEFT", f.Sidebar, "TOPLEFT", 24 + 36 + 12, -47)
	local line = W.Text(f.Sidebar, "small", "textDim")
	line:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)
	-- To the sidebar's 24 edge; longer text ends in the client's ellipsis.
	for _, t in ipairs({ name, line }) do t:SetWidth(f.Sidebar:GetWidth() - (24 + 36 + 12) - 24) end
	return { icon = icon, name = name, line = line }
end

-- Paints an item well (ns.ItemWell) as the game shows the item: its icon, a
-- border in its raw quality colour from uncommon up (docs/DESIGN.md, "Slot
-- Tile"), the stack count at the bottom right when over 1, desaturated (sold
-- out, locked) or red (unusable). `it` nil empties the well.
function ns.PaintItem(w, it)
	local Theme = Polestar.Theme
	it = it or {}
	w.Icon:SetTexture(it.icon)
	w.Icon:SetDesaturated(it.desat and true or false)
	if it.unusable then w.Icon:SetVertexColor(Theme.Color("danger")) else w.Icon:SetVertexColor(1, 1, 1) end
	local r, g, b = ns.QualityRGB(it.quality)
	if r and it.quality >= 2 then Theme.Border(w, r, g, b, 1) else Theme.Border(w, Theme.Wash("border")) end
	local n = it.count or 0
	if n > 1 and not w.psCount then
		w.psCount = Polestar.Widgets.Text(w, "number", "text", "OVERLAY")
		w.psCount:SetPoint("BOTTOMRIGHT", w, "BOTTOMRIGHT", -3, 3)
	end
	if w.psCount then w.psCount:SetText(n > 1 and n or "") end
end

-- A grid of item wells (buttons, with the hover wash), `cols` to a row, `size`
-- square, `gap` apart. Returns the grid's frame, for the caller to anchor;
-- grid.Layout(n) shows the first n wells (made as needed, kept for reuse),
-- hides the rest, fits the frame's height and returns those n wells.
function ns.ItemGrid(parent, cols, size, gap)
	local g = CreateFrame("Frame", nil, parent)
	g:SetSize(cols * (size + gap) - gap, 1)
	local wells = {}
	function g.Layout(n)
		local shown = {}
		for i = 1, n do
			local w = wells[i]
			if not w then
				w = ns.ItemWell(g, size, "Button")
				Polestar.Widgets.Hover(w)
				wells[i] = w
			end
			local k = i - 1
			w:ClearAllPoints()
			w:SetPoint("TOPLEFT", g, "TOPLEFT", (k % cols) * (size + gap), -math.floor(k / cols) * (size + gap))
			w:Show()
			shown[i] = w
		end
		for i = n + 1, #wells do wells[i]:Hide() end
		-- Never 0 high: a frame of size 0 has no rect (docs/CLIENT.md, rule 12).
		g:SetHeight(math.max(1, math.ceil(n / cols) * (size + gap) - gap))
		return shown
	end
	return g
end

-- A money line: gold, silver and copper, each a number and the game's coin.
local COINS = { { 10000, "Interface\\MoneyFrame\\UI-GoldIcon" }, { 100, "Interface\\MoneyFrame\\UI-SilverIcon" }, { 1, "Interface\\MoneyFrame\\UI-CopperIcon" } }
local COIN = 12

function ns.Money(parent)
	local m = CreateFrame("Frame", nil, parent)
	m:SetHeight(COIN + 2)
	m.psParts = {}
	for i, c in ipairs(COINS) do
		local p = { text = Polestar.Widgets.Text(m, "number", "text"), coin = m:CreateTexture(nil, "ARTWORK") }
		p.coin:SetSize(COIN, COIN)
		p.coin:SetTexture(c[2])
		m.psParts[i] = p
	end
	return m
end

-- Writes `copper` into a money line as the game writes it (GetMoneyString:
-- units at zero left out, copper alone for none), in the `color` token (text
-- when not given). The line is as wide as what it shows: anchor it by either end.
function ns.SetMoney(m, copper, color)
	copper = math.floor(copper or 0)
	local x = 0
	for i, c in ipairs(COINS) do
		local p = m.psParts[i]
		local n = math.floor(copper / c[1])
		if i > 1 then n = n % 100 end
		local on = n > 0 or (i == #COINS and copper == 0)
		p.text:SetShown(on)
		p.coin:SetShown(on)
		if on then
			if x > 0 then x = x + 6 end
			p.text:SetText(n)
			Polestar.Widgets.Color(p.text, color or "text")
			p.text:ClearAllPoints()
			p.text:SetPoint("LEFT", m, "LEFT", x, 0)
			x = x + math.ceil(p.text:GetStringWidth()) + 2
			p.coin:ClearAllPoints()
			p.coin:SetPoint("LEFT", m, "LEFT", x, 0)
			x = x + COIN
		end
	end
	m:SetWidth(x)
end

-- Enables or disables a button as Polestar disables: faded to 45%. `why`,
-- when given, is the reason a disabled one shows in its tooltip (the client
-- sends a disabled button its mouse-overs only when asked). A Polestar switch
-- (W.Switch) dims itself on each Refresh: it is told through
-- W.SetDisabledWhen, and its reason is its own tooltip while off.
function ns.SetEnabled(b, on, why)
	if rawget(b, "Knob") then
		if b.psOwnTip == nil then
			b.psOwnTip = b.psTip or false
			b:SetMotionScriptsWhileDisabled(true)
			Polestar.Widgets.SetDisabledWhen(b, function() return b.psOff end)
		end
		b.psOff, b.psTip = not on, not on and why or b.psOwnTip or nil
		return b:Refresh()
	end
	b:SetEnabled(on and true or false)
	b:SetAlpha(on and 1 or 0.45)
	b.psReason = not on and why or nil
	if not why or b.psReasonHooked then return end
	b.psReasonHooked = true
	b:SetMotionScriptsWhileDisabled(true)
	b:HookScript("OnEnter", function(self)
		if not self.psReason then return end
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(self.psReason, 1, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	b:HookScript("OnLeave", function(self) if GameTooltip:GetOwner() == self then GameTooltip:Hide() end end)
end

-- A pickup from a bag, bank or window slot: `fn(...)`, never while a spell
-- waits for its item. Then the click would apply the spell, forbidden to
-- addon code (docs/CLIENT.md, rule 4); a window that applies it does so from
-- its secure overlay. No combat block: container pickups are not protected.
function ns.Pickup(fn, ...)
	if not SpellIsTargeting() then return fn(...) end
end

-- A one-line text box in the Polestar look, `w` wide; Enter and Escape leave it.
function ns.TextField(parent, w, letters)
	local Theme, W = Polestar.Theme, Polestar.Widgets
	local e = CreateFrame("EditBox", nil, parent)
	e:SetSize(w, 30)
	e:SetAutoFocus(false)
	if letters then e:SetMaxLetters(letters) end
	e:SetTextInsets(10, 10, 0, 0)
	Theme.Font(e, "label")
	W.Color(e, "text")
	Theme.Skin(e, "editbox")
	e:SetScript("OnEditFocusGained", function(self) Theme.SetFocused(self, true) end)
	e:SetScript("OnEditFocusLost", function(self) Theme.SetFocused(self, false) end)
	e:SetScript("OnEscapePressed", e.ClearFocus)
	e:SetScript("OnEnterPressed", e.ClearFocus)
	return e
end

-- Coins as plain text for a label or dialog line ("1,234g 2s 3c", units
-- above the largest left out), in Polestar's coin symbols (the client's own,
-- else its translated g s c) and the gold in thousands.
function ns.Coins(c)
	local G, S, C = Polestar.CoinSymbols()
	local g, s = math.floor(c / 10000), math.floor(c / 100) % 100
	if g > 0 then return ("%s%s %d%s %d%s"):format(Polestar.Thousands(g), G, s, S, c % 100, C) end
	if s > 0 then return ("%d%s %d%s"):format(s, S, c % 100, C) end
	return ("%d%s"):format(c % 100, C)
end

-- A numeric editbox in the Polestar look; done(box) runs as it loses focus.
local function numberBox(parent, width, letters, done)
	local Theme, W = Polestar.Theme, Polestar.Widgets
	local e = CreateFrame("EditBox", nil, parent)
	e:SetSize(width, 28)
	e:SetAutoFocus(false)
	e:SetNumeric(true)
	e:SetMaxLetters(letters)
	e:SetJustifyH("CENTER")
	Theme.Font(e, "number")
	W.Color(e, "text")
	Theme.Skin(e, "editbox")
	e:SetScript("OnEditFocusGained", function(self)
		Theme.SetFocused(self, true)
		self:HighlightText()
	end)
	e:SetScript("OnEditFocusLost", function(self)
		Theme.SetFocused(self, false)
		if done then done(self) end
	end)
	e:SetScript("OnEnterPressed", e.ClearFocus)
	e:SetScript("OnEscapePressed", e.ClearFocus)
	return e
end

-- Gold, silver and copper fields, each with its coin; onChange(copper) as the
-- player types. Returns the frame; frame.Set(copper) fills it.
function ns.MoneyInput(parent, onChange)
	local m = CreateFrame("Frame", nil, parent)
	m:SetHeight(28)
	local boxes, x = {}, 0
	local function total()
		local c = 0
		for i, b in ipairs(boxes) do c = c + (tonumber(b:GetText()) or 0) * COINS[i][1] end
		return c
	end
	for i, c in ipairs(COINS) do
		local b = numberBox(m, i == 1 and 64 or 36, i == 1 and 6 or 2)
		b:SetPoint("LEFT", m, "LEFT", x, 0)
		b:SetScript("OnTextChanged", function(_, user) if user then onChange(total()) end end)
		local coin = m:CreateTexture(nil, "ARTWORK")
		coin:SetSize(COIN, COIN)
		coin:SetTexture(c[2])
		coin:SetPoint("LEFT", b, "RIGHT", 4, 0)
		x = x + b:GetWidth() + 4 + COIN + 10
		boxes[i] = b
	end
	m:SetWidth(x - 10)
	function m.Set(copper)
		copper = math.floor(copper or 0)
		boxes[1]:SetText(math.floor(copper / 10000))
		boxes[2]:SetText(math.floor(copper / 100) % 100)
		boxes[3]:SetText(copper % 100)
	end
	return m
end

-- A quantity stepper: -, the count, +, Max. `o`: get(), set(n) (n kept within
-- 1 and max()), max(). The owner calls stepper.Paint() after its own changes.
function ns.Stepper(parent, o)
	local W = Polestar.Widgets
	local s = CreateFrame("Frame", nil, parent)
	s:SetSize(200, 28)
	local function set(n)
		o.set(math.max(1, math.min(n, o.max())))
		s.Paint()
	end
	s.Less = W.Button(s, "\226\128\147", function() set(o.get() - 1) end, { width = 28 })
	s.Less:SetPoint("LEFT", s, "LEFT", 0, 0)
	s.Box = numberBox(s, 48, 3, function(self) set(tonumber(self:GetText()) or 1) end)
	s.Box:SetPoint("LEFT", s.Less, "RIGHT", 4, 0)
	s.More = W.Button(s, "+", function() set(o.get() + 1) end, { width = 28 })
	s.More:SetPoint("LEFT", s.Box, "RIGHT", 4, 0)
	s.Max = W.Button(s, "Max", function() set(math.huge) end, { ghost = true })
	s.Max:SetPoint("LEFT", s.More, "RIGHT", 8, 0)
	function s.Paint()
		local n, most = o.get(), o.max()
		if not s.Box:HasFocus() then s.Box:SetText(n) end
		ns.SetEnabled(s.Less, n > 1)
		ns.SetEnabled(s.More, n < most)
		ns.SetEnabled(s.Max, n < most)
	end
	return s
end

-- The NPC's portrait at the compact band's left (a 40px well, 10 from its
-- top), the title and subtitle beside it, as the stock windows'
-- (SetPortraitToUnit; the quest book when there is no unit). Shared by Gossip
-- and the Quest dialog; call after ns.Compact. Returns paint(unit).
function ns.NpcPortrait(f)
	local well, icon = ns.ItemWell(f.Header, 40)
	well:SetPoint("TOPLEFT", f.Header, "TOPLEFT", f.psPad, -10)
	-- The compact header re-anchors the title whenever its tools move: moved back after it.
	local function place() f.Title:SetPoint("TOPLEFT", f.Header, "TOPLEFT", f.psPad + 40 + 12, -10) end
	place()
	local tools = rawget(f, "HeaderTools")
	if tools then hooksecurefunc(tools, "Place", place) end
	f.psPortraitIcon = icon
	return function(unit)
		if UnitExists(unit) then SetPortraitTexture(icon, unit) else icon:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon") end
	end
end

-- A friendship NPC's standing (NPCFriendshipStatusBarMixin:Update): its icon,
-- the rank, a Skill Bar, and the stock tooltip's lines. Shared with the Quest
-- dialog. Returns the frame; frame.Paint() shows it for the NPC, or hides it.
function ns.FriendshipBar(parent)
	local W = Polestar.Widgets
	local b = CreateFrame("Frame", nil, parent)
	b:SetHeight(32)
	b:EnableMouse(true)
	b.Icon = ns.GameIcon(b)
	b.Icon:SetSize(24, 24)
	b.Icon:SetPoint("LEFT", b, "LEFT", 0, 0)
	b.Label = W.Text(b, "label", "text")
	b.Label:SetPoint("TOPLEFT", b.Icon, "TOPRIGHT", 10, 0)
	b.Value = W.Text(b, "small", "textDim")
	b.Value:SetPoint("TOPRIGHT", b, "TOPRIGHT", 0, -1)
	b.Bar = W.ProgressLine(b, 2)
	b.Bar:SetPoint("BOTTOMLEFT", b.Icon, "BOTTOMRIGHT", 10, 2)
	b.Bar:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 2)
	function b.Paint()
		local r = C_GossipInfo.GetFriendshipReputation and C_GossipInfo.GetFriendshipReputation(0)
		b.info = r and (r.friendshipFactionID or 0) > 0 and r or nil
		b:SetShown(b.info ~= nil)
		if not b.info then return end
		local ranks = C_GossipInfo.GetFriendshipReputationRanks(r.friendshipFactionID)
		b.ranks = ranks
		b.Icon:SetTexture(r.texture and r.texture ~= 0 and r.texture or "Interface\\Common\\friendship-heart")
		b.Label:SetText(r.reaction or "")
		local lo, hi = r.reactionThreshold or 0, r.nextThreshold
		b.Value:SetText(hi and ("%s / %s"):format(BreakUpLargeNumbers(r.standing - lo), BreakUpLargeNumbers(hi - lo)) or "")
		W.SetProgress(b.Bar, hi and (r.standing - lo) / math.max(1, hi - lo) or 1, b:GetWidth() - 34)
	end
	b:SetScript("OnEnter", function(self)
		local r, ranks = self.info, self.ranks
		if not r then return end
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
		local title = r.name or ""
		if ranks and ranks.maxLevel > 0 then title = ("%s (%d / %d)"):format(title, ranks.currentLevel, ranks.maxLevel) end
		GameTooltip:SetText(title, 1, 1, 1)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(r.text, nil, nil, nil, true)
		local lo = r.reactionThreshold or 0
		GameTooltip:AddLine(r.nextThreshold and ("%s (%d / %d)"):format(r.reaction, r.standing - lo, r.nextThreshold - lo) or r.reaction, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", W.HideTooltip)
	return b
end

-- The reward drawing the Quest dialog and the quest log's details share: a
-- column of pooled texts and reward tiles laid out top down from `c.y` in
-- `parent` (docs/DESIGN.md, "Reagent Tile"). `o`: x (left inset), width,
-- tip(tile) (the tooltip), click(tile); selected(type, index) (optional: the
-- reward page's choices, which carry Polestar's marks and a selection).
-- Per paint: c.Begin(y), draw with c.text/head/pair/tile/Rewards, c.End().
function ns.QuestRewards(parent, o)
	local W, Theme = Polestar.Widgets, Polestar.Theme
	local TILE = 32
	local c = { y = 0 }
	local texts, used, tiles, nTile = {}, {}, {}, 0
	local monies, nMoney -- c.money's lines, below
	function c.Begin(y) used, nTile, nMoney, c.y = {}, 0, 0, y end
	function c.End()
		for role, l in pairs(texts) do for i = (used[role] or 0) + 1, #l do l[i]:Hide() end end
		for i = nTile + 1, #tiles do tiles[i]:Hide() end
		for i = nMoney + 1, #monies do monies[i]:Hide() end
	end
	function c.text(role, color, s, gap, indent)
		used[role] = (used[role] or 0) + 1
		texts[role] = texts[role] or {}
		local t = texts[role][used[role]]
		if not t then
			t = W.Text(parent, role, "text")
			t:SetWordWrap(true)
			t:SetSpacing(2)
			texts[role][used[role]] = t
		end
		W.Color(t, color)
		t:ClearAllPoints()
		t:SetPoint("TOPLEFT", parent, "TOPLEFT", o.x + (indent or 0), -(c.y + gap))
		t:SetWidth(o.width - (indent or 0))
		t:SetJustifyH("LEFT")
		t:SetText(s or "")
		t:Show()
		c.y = c.y + gap + math.ceil(t:GetStringHeight())
		return t
	end
	function c.head(s) if s then c.text("label", "textDim", s, 14) end end
	-- A fact: its name, and its value at the right of the same line.
	function c.pair(label, value, color)
		local l = c.text("body", "textDim", label, 8)
		local v = c.text("number", color or "text", value, 0)
		v:ClearAllPoints()
		v:SetPoint("TOPRIGHT", l, "TOPRIGHT", 0, 0)
		v:SetJustifyH("RIGHT")
		c.y = c.y - math.ceil(v:GetStringHeight())
	end

	-- A money fact: its name, and the coins (ns.Money) at the right of the same line.
	monies = {}
	function c.money(label, copper, color)
		local l = c.text("body", "textDim", label, 8)
		nMoney = nMoney + 1
		local m = monies[nMoney] or ns.Money(parent)
		monies[nMoney] = m
		ns.SetMoney(m, copper, color)
		m:ClearAllPoints()
		m:SetPoint("RIGHT", l, "TOPRIGHT", 0, -math.ceil(l:GetStringHeight()) / 2)
		m:Show()
		return m
	end

	local function newTile()
		local t = CreateFrame("Button", nil, parent)
		t:SetHeight(TILE)
		W.Hover(t)
		if o.selected then
			t.Sel = W.Painter(W.Tex(t, "BACKGROUND"), function(s) s:SetVertexColor(Theme.Wash("selected")) end)
			t.Sel:SetAllPoints(t)
		end
		t.Well = CreateFrame("Frame", nil, t)
		t.Well:SetSize(TILE, TILE)
		t.Well:SetPoint("LEFT", t, "LEFT", 0, 0)
		Theme.Skin(t.Well, "inset")
		t.Icon = ns.GameIcon(t.Well)
		t.Icon:SetPoint("TOPLEFT", 1, -1)
		t.Icon:SetPoint("BOTTOMRIGHT", -1, 1)
		if o.selected then
			-- The marks: arrow and coin in the icon's top corners, the best in a 2px accent frame.
			t.Up = W.Tex(t.Well, "OVERLAY", "qol-upgrade", "success", 2)
			t.Up:SetSize(16, 16)
			t.Up:SetPoint("TOPLEFT", t.Well, "TOPLEFT", -2, 2)
			t.Coin = W.Tex(t.Well, "OVERLAY", "qol-coin", "accent", 2)
			t.Coin:SetSize(16, 16)
			t.Coin:SetPoint("TOPRIGHT", t.Well, "TOPRIGHT", 2, 2)
			t.Ring = {}
			for i, p in ipairs({ { "TOPLEFT", "TOPRIGHT", -2, 2, 2, 2 }, { "BOTTOMLEFT", "BOTTOMRIGHT", -2, -2, 2, -2 },
				{ "TOPLEFT", "BOTTOMLEFT", -2, 2, -2, -2 }, { "TOPRIGHT", "BOTTOMRIGHT", 2, 2, 2, -2 } }) do
				local e = W.Tex(t.Well, "OVERLAY", nil, "accent", 1)
				e:SetPoint(p[1], t.Well, p[1], p[3], p[4])
				e:SetPoint(p[2], t.Well, p[2], p[5], p[6])
				if i <= 2 then e:SetHeight(2) else e:SetWidth(2) end
				t.Ring[i] = e
			end
		end
		t.Count = W.Text(t, "number", "text")
		t.Count:SetPoint("RIGHT", t, "RIGHT", -8, 0)
		t.Name = W.Text(t, "label", "text")
		t.Name:SetPoint("LEFT", t.Well, "RIGHT", 8, 0)
		t.Name:SetPoint("RIGHT", t.Count, "LEFT", -8, 0)
		t:SetScript("OnEnter", o.tip)
		t:SetScript("OnLeave", W.HideTooltip)
		t:SetScript("OnClick", o.click)
		return t
	end
	-- `kind`: "item", "currency" or "spell" (nil: no tooltip); `type`: "choice",
	-- "reward" or "required"; `mark` = { up, coin, best } (the Polestar marks).
	function c.tile(kind, type, index, name, icon, count, q, usable, mark)
		nTile = nTile + 1
		local t = tiles[nTile] or newTile()
		tiles[nTile] = t
		t.psKind, t.psType, t.psIndex = kind, type, index
		t.Icon:SetTexture(icon)
		-- One the player cannot use, red as on the stock button.
		if usable == false then t.Icon:SetVertexColor(Theme.Color("danger")) else t.Icon:SetVertexColor(1, 1, 1) end
		t.Name:SetText(name or RETRIEVING_ITEM_INFO or "")
		t.Count:SetText(type == "required" and count or (count and count > 1 and count or ""))
		-- The name in its quality colour, lifted; the border raw from uncommon up.
		local col = q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
		W.Uncolor(t.Name)
		if col then t.Name:SetTextColor(Theme.Legible(col.r, col.g, col.b)) else W.Color(t.Name, "text") end
		-- OVERLAY: above the icon, which at a scaled pixel grid can cover the top line.
		local br, bg, bb, ba = 0, 0, 0, 1
		if col and q >= 2 then br, bg, bb = col.r, col.g, col.b else br, bg, bb, ba = Theme.Wash("border") end
		Theme.Border(t.Well, br, bg, bb, ba, "OVERLAY")
		if o.selected then
			mark = mark or {}
			t.Up:SetShown(mark.up or false)
			t.Coin:SetShown(mark.coin or false)
			for _, e in ipairs(t.Ring) do e:SetShown(mark.best or false) end
			t.Sel:SetShown(o.selected(type, index) or false)
		end
		t:ClearAllPoints()
		t:SetPoint("TOPLEFT", parent, "TOPLEFT", o.x, -(c.y + 6))
		t:SetWidth(o.width)
		t:Show()
		c.y = c.y + 6 + TILE
	end

	-- A spell reward's place and heading, by its kind (QuestInfo's
	-- GetRewardSpellBucketType and its ordering).
	local function spellKind(s)
		local T = Enum.QuestCompleteSpellType
		local k = (s.type and s.type ~= T.LegacyBehavior and s.type) or (s.isTradeskillSpell and T.Tradeskill)
			or (s.isBoostSpell and T.Ability) or (s.garrFollowerID and T.Follower) or (s.isSpellLearned and T.Spell)
			or (s.genericUnlock and T.Unlock) or T.Aura
		local order = { T.Follower, T.Companion, T.Tradeskill, T.Ability, T.Aura, T.Spell, T.Unlock, T.QuestlineUnlock,
			T.QuestlineReward, T.QuestlineUnlockPart, T.PossibleReward }
		local heads = { REWARD_FOLLOWER, REWARD_COMPANION, REWARD_TRADESKILL_SPELL, REWARD_ABILITY, REWARD_AURA, REWARD_SPELL,
			REWARD_UNLOCK, REWARD_QUESTLINE_UNLOCK, REWARD_QUESTLINE_REWARD, REWARD_QUESTLINE_UNLOCK_PART, REWARD_POSSIBLE_QUEST_REWARD }
		for i, v in ipairs(order) do if v == k then return i, heads[i] end end
		return #order + 1
	end
	-- What reward XP is worth of the player's level, as "35% of level 12"; nil
	-- where the game shows no XP bar (max level, XP turned off).
	local function levelShare(xp)
		local max = UnitXPMax("player")
		if not (max and max > 0 and GameRulesUtil.CanShowExperienceBar()) then return end
		local pct = xp / max * 100
		return ("%s of level %d"):format(pct < 1 and "<1%" or math.floor(pct) .. "%", UnitLevel("player"))
	end

	-- The rewards in QuestInfo_ShowRewards' order: choices, spells, a title,
	-- then what comes with them (experience, money, skill, items, currencies,
	-- honor). `d` = the counts and values the caller read (items, choices,
	-- money, xp, honor, title, skillName, skillIcon, skillPoints, chooseItems (the
	-- complete step: "Choose your reward:" for several choices)) and
	-- choice(i), reward(i) -> name, icon, count, quality, usable.
	function c.Rewards(id, d)
		local items, choices, money, xp, honor, title, skillPoints = d.items, d.choices, d.money, d.xp, d.honor, d.title, d.skillPoints
		local currencies = C_QuestInfoSystem.GetQuestRewardCurrencies(id) or {}
		local spells = {}
		for i, spellID in ipairs(C_QuestInfoSystem.GetQuestRewardSpells(id) or {}) do
			local s = spellID and spellID > 0 and C_QuestInfoSystem.GetQuestRewardSpellInfo(id, spellID)
			-- Only one the player can still learn, as the stock list.
			if s and s.texture and not C_SpellBook.IsSpellInSpellBook(spellID, Enum.SpellBookSpellBank.Player, true)
				and (not s.isBoostSpell or IsCharacterNewlyBoosted())
				and (not s.garrFollowerID or not C_Garrison.IsFollowerCollected(s.garrFollowerID)) then
				local order, h = spellKind(s)
				s.spellID, s.head, s.order = spellID, h, order * 1000 + i
				spells[#spells + 1] = s
			end
		end
		if items + choices + #currencies + #spells == 0 and money == 0 and xp == 0 and honor == 0 and not title and not skillPoints then return end
		c.text("heading", "text", "Rewards", 24)
		if choices > 0 then
			c.head(choices == 1 and REWARD_ITEMS_ONLY or (d.chooseItems and REWARD_CHOOSE or REWARD_CHOICES))
			for i = 1, choices do d.choice(i) end
		end
		table.sort(spells, function(a, b) return a.order < b.order end)
		local lastHead
		for _, s in ipairs(spells) do
			if s.head ~= lastHead and not s.hideSpellLearnText then c.head(s.head) end
			lastHead = s.head
			c.tile("spell", nil, s.spellID, s.name, s.texture)
		end
		if title then
			c.head(REWARD_TITLE)
			c.text("body", "text", title, 6)
		end
		if items + #currencies > 0 or money > 0 or xp > 0 or honor > 0 or skillPoints then
			c.head((choices > 0 or #spells > 0 or title) and REWARD_ITEMS or REWARD_ITEMS_ONLY)
			if xp > 0 then
				c.pair("Experience", BreakUpLargeNumbers(xp) .. " XP")
				-- The share under the amount, softer, at the right like the value.
				local share = levelShare(xp)
				if share then c.text("small", "textMuted", share, 2):SetJustifyH("RIGHT") end
			end
			if money > 0 then c.money("Money", money) end
			if skillPoints then c.tile(nil, nil, nil, d.skillName, d.skillIcon, skillPoints) end
			for i = 1, items do
				local name, icon, n, q, usable = d.reward(i)
				c.tile("item", "reward", i, name, icon, n, q, usable)
			end
			for i, cur in ipairs(currencies) do c.tile("currency", "reward", i, cur.name, cur.texture, cur.totalRewardAmount, cur.quality) end
			if honor > 0 then c.pair(HONOR or "Honor", BreakUpLargeNumbers(honor)) end
		end
	end
	return c
end

-- Polestar's dialog (W.Modal, `spec` as there) with a body of ours under its
-- text: a stepper, a money input, a field. The body hides with the dialog, or
-- when the next dialog takes its place.
local modalBody
function ns.ModalWith(spec, body)
	if not modalBody then
		hooksecurefunc(Polestar.Widgets, "Modal", function() if modalBody then modalBody:Hide() end end)
	end
	local s = Polestar.Widgets.Modal(spec)
	local box = s.Box
	if not body.psModal then
		body.psModal = true
		s:HookScript("OnHide", function() body:Hide() end)
	end
	body:SetParent(box)
	-- Its text ends 20 above the footer (54 tall): the body takes that place.
	local top = box:GetHeight() - 20 - 54
	body:ClearAllPoints()
	body:SetPoint("TOPLEFT", box, "TOPLEFT", 24, -(top + 8))
	box:SetHeight(box:GetHeight() + body:GetHeight() + 20)
	modalBody = body
	body:Show()
	return s
end

-- Closes Polestar's dialog while it still shows `spec`: a window's own
-- dialog, as the window hides.
function ns.CloseModal(spec)
	if spec and PolestarModal and PolestarModal:IsShown() and PolestarModal.psSpec == spec then PolestarModal:Hide() end
end

-- An item quality's colour as r, g, b (nil when the client has none).
function ns.QualityRGB(q)
	if q == nil then return end
	if C_Item and C_Item.GetItemQualityColor then
		local ok, r, g, b = pcall(C_Item.GetItemQualityColor, q)
		if ok and type(r) == "number" then return r, g, b end
	end
	local t = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
	if t then return t.r, t.g, t.b end
end

-- The in-place restyle kit (Tooltips.lua, Chat.lua): art of ours on a stock
-- frame, made and painted through widget calls only, never a key written on
-- it (docs/CLIENT.md, rule 15).
-- The NineSlice pieces (nineSliceSetup in NineSlice.lua) keyed on `holder`, at alpha `a`.
local NINE = { "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner", "TopEdge", "BottomEdge", "LeftEdge", "RightEdge", "Center" }
function ns.FadeNine(holder, a)
	for _, k in ipairs(NINE) do
		local p = holder[k]
		if p then p:SetAlpha(a) end
	end
end

-- Four hairlines round region `rel` (top, bottom, left, right): white
-- textures on frame `f`, or what `make()` returns (the caller's own, in another layer).
local EDGES = { { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }
function ns.Hairlines(f, rel, make)
	local e = {}
	for i, p in ipairs(EDGES) do
		local t = make and make()
		if not t then
			t = f:CreateTexture(nil, "BORDER", nil, 7)
			t:SetTexture(Polestar.Theme.Media("white"))
		end
		t:SetPoint(p[1], rel, p[1], 0, 0)
		t:SetPoint(p[2], rel, p[2], 0, 0)
		e[i] = t
	end
	e.rel = rel
	return e
end

-- Shows (or hides) hairlines `e` in r, g, b, a, `n` (default 1) pixels of
-- their frame thick, laid as Theme.Border lays a window's: the first pixel
-- inside `rel`, the rest outward; the sides between the top and the bottom.
-- (Hairlines `e` not made by ns.Hairlines: sized only.)
function ns.PaintHairlines(e, on, r, g, b, a, n)
	local px = Polestar.Theme.Pixel(e[1]:GetParent())
	n = n or 1
	local rel = e.rel
	if rel and (e.px ~= px or e.n ~= n) then
		e.px, e.n = px, n
		local o = px * (n - 1)
		local top, bottom, left, right = e[1], e[2], e[3], e[4]
		top:ClearAllPoints(); top:SetPoint("TOPLEFT", rel, "TOPLEFT", -o, o); top:SetPoint("TOPRIGHT", rel, "TOPRIGHT", o, o)
		bottom:ClearAllPoints(); bottom:SetPoint("BOTTOMLEFT", rel, "BOTTOMLEFT", -o, -o); bottom:SetPoint("BOTTOMRIGHT", rel, "BOTTOMRIGHT", o, -o)
		left:ClearAllPoints(); left:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, 0); left:SetPoint("BOTTOMLEFT", bottom, "TOPLEFT", 0, 0)
		right:ClearAllPoints(); right:SetPoint("TOPRIGHT", top, "BOTTOMRIGHT", 0, 0); right:SetPoint("BOTTOMRIGHT", bottom, "TOPRIGHT", 0, 0)
	end
	px = px * n
	for i, t in ipairs(e) do
		t:SetShown(on)
		t:SetVertexColor(r, g, b, a)
		if i <= 2 then t:SetHeight(px) else t:SetWidth(px) end
	end
end

-- Polestar's window ground on texture `fill`: bg at the HUD Frames look's
-- Background opacity (ns.HUD.GroundAlpha, HUD.lua loads after this file),
-- times `k` (0.85 for the tooltip look: 0.80 at the default 0.94).
function ns.PaintGround(fill, on, k)
	local r, g, b = Polestar.Theme.Color("bg")
	local H = ns.HUD
	fill:SetVertexColor(r, g, b, H.GroundAlpha(H.FRAMES) * (k or 1))
	fill:SetShown(on)
end

-- A game menu (Blizzard_Menu, pooled frames every menu shares) in our look;
-- call from a tag's root:AddMenuAcquiredCallback. The style's ground (a
-- compositor attachment, reset when the menu closes) is faded; ours is on a
-- frame of our own on the menu, under its items (they sit 20 levels up),
-- hidden with the menu so the next menu on that frame is the game's. Never
-- the menu's AttachTexture: its compositor lists and the shared texture
-- pool, written from our code, taint the menu code that walks them next
-- (closing one menu by opening another ran the session menu's generator
-- tainted: secret durations, s526; rule 15). `foot`: how far above the
-- menu's foot ours ends. `ns.MenuPiece(menu)`: a texture of ours on it.
local menuSkins = setmetatable({}, { __mode = "k" })
function ns.MenuLook(menu, foot)
	local s = menuSkins[menu]
	if not s then
		s = CreateFrame("Frame", nil, menu)
		s:SetAllPoints(menu)
		s:SetScript("OnHide", s.Hide) -- the menu closed: shown again only by a tagged menu
		s.fill = s:CreateTexture(nil, "BACKGROUND", nil, -8)
		s.fill:SetTexture(Polestar.Theme.Media("white"))
		s.fill:SetPoint("TOPLEFT", s, "TOPLEFT", 0, 0)
		s.edges = ns.Hairlines(s, s.fill)
		s.pieces, s.used = {}, 0
		menuSkins[menu] = s
	end
	for _, r in ipairs({ menu:GetRegions() }) do r:SetAlpha(0) end
	s:SetFrameLevel(menu:GetFrameLevel())
	s.fill:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", 0, foot or 0)
	ns.PaintGround(s.fill, true)
	ns.HUD.PaintEdge(s.edges, true, ns.HUD.FRAMES) -- the HUD Frames look's edge
	for _, t in ipairs(s.pieces) do t:Hide(); t:ClearAllPoints() end
	s.used = 0
	s:Show()
end

function ns.MenuPiece(menu)
	local s = menuSkins[menu]
	if not (s and s:IsShown()) then return end
	s.used = s.used + 1
	local t = s.pieces[s.used]
	if not t then
		t = s:CreateTexture(nil, "ARTWORK", nil, 7)
		s.pieces[s.used] = t
	end
	t:Show()
	return t
end

-- The model well's backdrop (docs/DESIGN.md, "Model Well"): Polestar's glow
-- texture in `shade` at 60%, fading out towards the edges, no border.
function ns.ModelShade(holder, layer)
	local shade = Polestar.Widgets.Tex(holder, layer or "BACKGROUND", "glow")
	shade:SetAllPoints(holder)
	Polestar.Widgets.Painter(shade, function(t) local r, g, b = Polestar.Theme.Color("shade"); t:SetVertexColor(r, g, b, 0.6) end)
	return shade
end

-- One secure button of ours over the hovered target (a spell row, a gear
-- slot), out of combat, for the clicks the game protects (docs/CLIENT.md,
-- rule 4). It hangs off UIParent above the window's strata, and hides as the
-- mouse leaves, the target moves (a scroll, the dock sliding its window) or
-- hides, or combat starts.
-- A drag keeps it shown, and a press keeps it on the pressed target, until
-- release (rule 9). `o`:
--   enter(t), pickup(t): the target's hover and drag;
--   attrs(over, t): its secure attributes;
--   stale(t): also hide when true (optional);
--   setup(over): extra scripts, added with HookScript (optional).
-- Returns place(t), for the target's OnEnter.
function ns.Overlay(name, o)
	local over
	local function place(t)
		if InCombatLockdown() then return end
		if not over then
			over = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
			over:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			over:RegisterForDrag("LeftButton")
			over:EnableMouse(true)
			over:SetAttribute("useOnKeyDown", false)
			local function release(self)
				self.psDragging, self.psPressed = nil, nil
				if not InCombatLockdown() and not self:IsMouseOver() then self:Hide() end
			end
			over:SetScript("OnMouseDown", function(self, button)
				if button == "LeftButton" then self.psPressed = self.psTarget end
			end)
			-- During a drag the release is the drag's: OnDragStop ends it.
			over:SetScript("OnMouseUp", function(self) if not self.psDragging then release(self) end end)
			over:SetScript("OnDragStart", function(self)
				self.psDragging = true
				o.pickup(self.psPressed or self.psTarget)
			end)
			over:SetScript("OnDragStop", release)
			over:SetScript("OnEnter", function(self) o.enter(self.psTarget) end)
			over:SetScript("OnLeave", function(self)
				Polestar.Widgets.HideTooltip()
				if not InCombatLockdown() and not self.psDragging and not self.psPressed then self:Hide() end
			end)
			over:SetScript("OnHide", function(self)
				self.psDragging, self.psPressed = nil, nil
				self.psTarget:UnlockHighlight()
			end)
			over:SetScript("OnUpdate", function(self)
				local t = self.psTarget
				if InCombatLockdown() then return end
				if not t:IsVisible() or t:GetTop() ~= self.psTop or t:GetLeft() ~= self.psLeft or (o.stale and o.stale(t)) then self:Hide() end
			end)
			Polestar.RegisterEvent("PLAYER_REGEN_DISABLED", function() over:Hide() end)
			if o.setup then o.setup(over) end
		end
		if over.psPressed then return end
		if over.psTarget and over.psTarget ~= t then over.psTarget:UnlockHighlight() end
		over.psTarget, over.psTop, over.psLeft = t, t:GetTop(), t:GetLeft()
		local k = t:GetEffectiveScale() / UIParent:GetEffectiveScale()
		over:ClearAllPoints()
		over:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", t:GetLeft() * k, t:GetTop() * k)
		over:SetSize(t:GetWidth() * k, t:GetHeight() * k)
		-- Above the window's strata: in it, a level higher, the game still gave
		-- the target the mouse.
		over:SetFrameStrata("DIALOG")
		over:SetFrameLevel(t:GetFrameLevel() + 20)
		o.attrs(over, t)
		t:LockHighlight() -- the target's hover wash, now under the button
		over:Show()
	end
	return place
end

-- A replaced window's doors that run no stock code (docs/CLIENT.md, rule 8):
-- each binding's keys click a button of ours (override bindings, set out of
-- combat), and an invisible secure button of ours lies over the micro button
-- while it is shown and enabled: a click opens ours, a shift-click clicks the
-- micro button from secure code, which opens the stock window untainted.
-- `actions` maps a binding name to its click. Only a module switched on
-- (ns.Enabled(`module`)) takes its doors; switched off, they are the game's.
local keyOwner, keyButtons, keySig = CreateFrame("Frame"), {}, nil
local function bindKeys()
	if InCombatLockdown() then return end -- PLAYER_REGEN_ENABLED binds them
	local sig = {}
	for action, d in pairs(keyButtons) do
		if ns.Enabled(d.module) then sig[#sig + 1] = action .. "=" .. table.concat({ GetBindingKey(action) }, ",") end
	end
	table.sort(sig)
	sig = table.concat(sig, ";")
	-- Only on a change: setting overrides fires UPDATE_BINDINGS again.
	if sig == keySig then return end
	keySig = sig
	ClearOverrideBindings(keyOwner)
	for action, d in pairs(keyButtons) do
		if ns.Enabled(d.module) then
			for _, key in ipairs({ GetBindingKey(action) }) do SetOverrideBindingClick(keyOwner, false, key, d.name) end
		end
	end
end

-- Our secure overlay over one micro button: its place, layer and visibility.
local function microDoor(module, micro, o)
	local on = ns.Enabled(module) and micro:IsVisible() and micro:IsEnabled()
	if on then
		local k = micro:GetEffectiveScale() / UIParent:GetEffectiveScale()
		local x, y, w, h = micro:GetLeft() * k, micro:GetBottom() * k, micro:GetWidth() * k, micro:GetHeight() * k
		if x ~= o.psX or y ~= o.psY or w ~= o:GetWidth() or h ~= o:GetHeight() then
			o.psX, o.psY = x, y
			o:ClearAllPoints()
			o:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
			o:SetSize(w, h)
		end
	end
	-- Above the micro button, wherever Edit Mode or the bar puts it.
	if on and (o:GetFrameStrata() ~= micro:GetFrameStrata() or o:GetFrameLevel() <= micro:GetFrameLevel()) then
		o:SetFrameStrata(micro:GetFrameStrata())
		o:SetFrameLevel(micro:GetFrameLevel() + 10)
	end
	o:SetShown(on)
end

local microDoors, microDriver = {}
function ns.Doors(module, name, actions, micro, onMicro)
	for action, fn in pairs(actions) do
		local b = CreateFrame("Button", "PolestarUI" .. name .. action, UIParent)
		b:SetScript("OnClick", function() fn() end)
		keyButtons[action] = { module = module, name = b:GetName() }
	end
	if not keySig then
		Polestar.RegisterEvent("UPDATE_BINDINGS", bindKeys)
		Polestar.RegisterEvent("PLAYER_REGEN_ENABLED", bindKeys)
	end
	keySig = false
	bindKeys()
	if not micro then return end
	ns.modules[module].micro = micro
	local o = CreateFrame("Button", "PolestarUI" .. name .. "Micro", UIParent, "SecureActionButtonTemplate")
	o:RegisterForClicks("LeftButtonUp")
	o:SetAttribute("useOnKeyDown", false)
	o:SetAttribute("shift-type1", "click")
	o:SetAttribute("clickbutton", micro)
	o:SetScript("PostClick", function() if not IsShiftKeyDown() then onMicro() end end)
	o:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(micro.tooltipText or "")
		ns.TooltipHint("Shift-click for the game's own window.")
		GameTooltip:Show()
	end)
	o:SetScript("OnLeave", function() GameTooltip:Hide() end)
	-- Our own frame, not the micro button's child, nor anchored to it: a secure
	-- frame anchored to a frame makes that frame protected, and the game's own
	-- Enable() of the micro button was then blocked in combat (docs/CLIENT.md,
	-- rule 10). A driver places it over the button by position, out of combat
	-- only (a secure button cannot be shown or moved in combat).
	microDoors[#microDoors + 1] = { module = module, micro = micro, o = o }
	if microDriver then return end
	-- One driver for every door: no hook tells us the micro bar moved (Edit Mode, the bar's layout).
	microDriver = CreateFrame("Frame", nil, UIParent)
	microDriver:SetScript("OnUpdate", function()
		if InCombatLockdown() then return end
		for _, d in ipairs(microDoors) do microDoor(d.module, d.micro, d.o) end
	end)
end

-- An NPC window (docs/DESIGN.md, "NPC windows: how they open"): the stock
-- window ends the interaction as it hides, so it is never opened. Ours takes
-- the interaction `types` from the game's manager (RegisterPlayerInteraction,
-- its own API, replacing the stock entry) and opens through ns.Show(key);
-- the routes Forever also sends through GameEvent (`o.internal`, event names)
-- are stopped. Ours is `o.frame` (its global name); closed by the player it
-- ends the interaction (`o.close`, the stock close call), closed by the game
-- it does not end it again. `o.bags` opens the bags with it and closes them
-- after, as the stock window did. `o.events = { show, hide }`: game events
-- that open and close it too (a route stopped in `o.internal`), for a client
-- that sends only those; when both routes fire it opens and closes once.
-- Off waits for /reload: routed back from our code, the stock window would
-- open tainted. Call it from the module's Enable.
function ns.Interaction(key, types, o)
	-- The preview loads the interaction manager only in NPC scenes.
	if not RegisterPlayerInteraction then return end
	ns.modules[key].reloadOff = true
	for _, e in ipairs(o.internal or {}) do GameEvent.UnregisterInternalEvent(e) end
	local hooked, ended
	local info = {
		frame = o.frame,
		showFunc = function()
			ns.Show(key)
			local f = _G[o.frame]
			-- Not opened: end the interaction, as the stock show does.
			if not (f and f:IsShown()) then return o.close() end
			if not hooked then
				hooked = true
				f:HookScript("OnHide", function(self)
					if o.bags then ns.CloseBags(self) end
					if not ended then o.close() end
					ended = nil
				end)
			end
			if o.bags then ns.OpenBags(f) end
		end,
		hideFunc = function()
			ended = true
			_G[o.frame]:Hide()
			ended = nil
		end,
	}
	for _, t in ipairs(types) do RegisterPlayerInteraction(t, info) end
	local function shown() return _G[o.frame] and _G[o.frame]:IsShown() end
	if o.events then
		Polestar.RegisterEvent(o.events[1], function() if not shown() then info.showFunc() end end)
		Polestar.RegisterEvent(o.events[2], function() if shown() then info.hideFunc() end end)
	end
end

-- The bags an NPC window opens and closes with it (ns.Interaction's o.bags),
-- `f` their opener as the stock FRAME_THAT_OPENED_BAGS: ours while the Bags
-- module is on (Modules/Bags.lua), else the game's.
local function ourBags()
	local m = ns.modules.bags
	return m and m.ready and ns.Enabled("bags") and m
end
function ns.OpenBags(f)
	local m = ourBags()
	if m then m.Open(f) else OpenAllBags(f) end
end
function ns.CloseBags(f)
	local m = ourBags()
	if m then m.Close(f) else CloseAllBags(f) end
end

-- Docking, the default (PolestarUIDB.free turns it off): our windows lay out
-- as the stock panel manager lays out pushable "left" panels
-- (UpdateUIPanelPositions in UIParentPanelManager.lua): from the top left, in
-- the order they opened, 32 apart, right of any stock panel open, and not
-- draggable. When they do not fit (GetMaxUIPanelsWidth), the oldest closes,
-- unless it is the one just opened (or whose flyout just opened): then the
-- next oldest. Their size is Polestar's Menu scale
-- (ui.menuScale), the player's to set. We cannot place the stock panels (their
-- manager is forbidden to us, docs/CLIENT.md rule 1), so ours give way to
-- them. A stock "center" panel closes ours itself: they are UISpecialFrames.
local dock, stock, hooked, newest, listening, swap = {}, {}, {}, nil, false, nil
function ns.Docked() return not PolestarUIDB.free end

-- A window's width with its shown flyouts (ns.DockFlyout).
local function footprint(f)
	local w = f:GetWidth()
	for _, o in ipairs(f.psFlyouts or {}) do if o:IsShown() then w = w + o:GetWidth() end end
	return w
end

local function layout()
	if not ns.Docked() then return end
	local L, ui = GetUIPanelLayoutAttribute, UIParent:GetEffectiveScale()
	local gap, x = L("PANEl_SPACING_X"), L("LEFT_OFFSET")
	for fr in pairs(stock) do
		if fr:IsShown() and fr:GetRight() then
			x = math.max(x, fr:GetRight() * fr:GetEffectiveScale() / ui + gap)
		else
			stock[fr] = nil
		end
	end
	-- A window filling the screen (the map's full screen) is out of the dock.
	local docked = {}
	for _, f in ipairs(dock) do if not f.psFull then docked[#docked + 1] = f end end
	local right = x
	for i, f in ipairs(docked) do
		right = right + footprint(f) * f:GetScale() + (i > 1 and gap or 0)
	end
	if right > GetMaxUIPanelsWidth() then
		-- The oldest that is not the newest (one just opened, or whose flyout did).
		for _, f in ipairs(docked) do
			if f ~= newest then
				f:Hide() -- its OnHide lays the rest out
				return
			end
		end
	end
	for _, f in ipairs(docked) do
		local s = f:GetScale()
		local h = f:GetHeight() * s
		-- The stock clamp (ClampUIPanelY): bottom no lower than 140, top at least 10 down.
		local y = L("TOP_OFFSET")
		local bottom = UIParent:GetTop() + y - h
		if bottom < 140 then y = y + 140 - bottom end
		y = math.min(y, -10)
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x / s, y / s)
		x = x + footprint(f) * s + gap
	end
end

local function undock(f)
	for i = #dock, 1, -1 do if dock[i] == f then table.remove(dock, i) end end
end

ns.Relayout = layout

-- A flyout hung off a docked window's right edge, outside it (the Character
-- window's stats drawer, ns.Flyout), one window with it (joinFlyout): while
-- shown, the dock counts its width as the window's and the window keeps it on
-- screen. A flyout inside the window (the map's quest log) needs none: the
-- window grows, and the dock follows its size.
function ns.DockFlyout(f, fly)
	f.psFlyouts = f.psFlyouts or {}
	table.insert(f.psFlyouts, fly)
	local function join() joinFlyout(f, fly) end
	local function changed()
		join()
		f:SetClampRectInsets(0, footprint(f) - f:GetWidth(), 0, 0)
		if f:IsShown() then layout() end
	end
	-- Opening a flyout counts as opening its window: the dock closes another.
	fly:HookScript("OnShow", function() if f:IsShown() then newest = f end; changed() end)
	fly:HookScript("OnHide", changed)
	fly:HookScript("OnSizeChanged", changed)
	-- Shown or hidden while the window was shut sends neither; a window shut
	-- through a theme change is painted as it shows, maybe after this.
	f:HookScript("OnShow", function() changed(); C_Timer.After(0, join) end)
	-- The window's border painted anew (its thickness), or turned off; a
	-- shadow made anew.
	f.psFlyoutJoins = f.psFlyoutJoins or {}
	table.insert(f.psFlyoutJoins, join)
	Polestar.Theme.OnChanged(join, true)
	join()
end
hooksecurefunc(Polestar.Theme, "Border", function(fr)
	for _, fn in ipairs(rawget(fr, "psFlyoutJoins") or {}) do fn() end
end)

function ns.SetDocked(on)
	PolestarUIDB.free = not on or nil
	layout()
end

-- W.Shell parents to Polestar's layer (Polestar.UIParent), which hiding
-- Polestar hides; ours stand in for the game's windows, so they hang off
-- UIParent (no secure child: allowed in combat too).
local function offLayer(f)
	local strata = f:GetFrameStrata()
	f:SetParent(UIParent)
	f:SetFrameStrata(strata)
end
hooksecurefunc(Polestar.Widgets, "Modal", function() if PolestarModal:GetParent() ~= UIParent then offLayer(PolestarModal) end end)

-- A window that floats, as the stock bags (no UI panel, so never docked: it
-- pushes no window aside and the dock never closes it): off Polestar's layer,
-- first where the stock bags open (UpdateContainerFrameAnchors: the bottom
-- right, clear of the right action bars), then draggable and kept where the
-- player leaves it (PolestarUIDB.pos, by its name). Polestar's Move frames
-- (Polestar.Movers) places it too, through that same saved place; `label`
-- names its box there.
local function floatPoint(f)
	local p = PolestarUIDB.pos[f:GetName()]
	if p then return "TOPLEFT", "BOTTOMLEFT", p[1], p[2] end
	return "BOTTOMRIGHT", "BOTTOMRIGHT", -(EditModeUtil:GetRightActionBarWidth() + 10), 85
end
local function floatPlace(f)
	local point, rel, x, y = floatPoint(f)
	f:ClearAllPoints()
	f:SetPoint(point, UIParent, rel, x, y)
end
function ns.Float(f, label)
	offLayer(f)
	local key = f:GetName()
	floatPlace(f)
	-- The shell drags it by its top-left off UIParent's bottom-left (Polestar's
	-- ns.DragWindow, no StopMovingOrSizing, no onStop the shell hands out): that
	-- point, set by a drag (or our own floatPlace), is the place kept.
	hooksecurefunc(f, "SetPoint", function(self, point, rel, relPoint, x, y)
		if point == "TOPLEFT" and rel == UIParent and relPoint == "BOTTOMLEFT" then PolestarUIDB.pos[key] = { x, y } end
	end)
	-- Movers speak UIParent's units; our place is in the window's (its Menu scale).
	-- Absent only where Polestar's UI is not loaded (the preview loads Core and Theme).
	local Movers = Polestar.Movers
	if not Movers then return end
	local function k() return f:GetEffectiveScale() / UIParent:GetEffectiveScale() end
	Movers.Register({ key = key, label = label or key, frame = function() return f end,
		anchor = function() return "TOPLEFT", "BOTTOMLEFT" end,
		get = function()
			local point, rel, x, y = floatPoint(f)
			return point, rel, x * k(), y * k()
		end,
		set = function(_, _, x, y)
			PolestarUIDB.pos[key] = { x / k(), y / k() }
			floatPlace(f)
		end,
		reset = function()
			PolestarUIDB.pos[key] = nil
			floatPlace(f)
		end })
end

function ns.Dock(f)
	offLayer(f)
	-- Docked, the dock places it: the shell's drag (Polestar's ns.StartDrag)
	-- moves only a frame that answers IsMovable.
	local isMovable = f.IsMovable
	f.IsMovable = function(self) return not ns.Docked() and not self.psFull and isMovable(self) end
	-- Windows sharing one place (psDockGroup, ns.LinkPlace) swap in place: one
	-- shown as its partner hides, the same moment, takes the partner's slot.
	f:HookScript("OnShow", function(self)
		undock(self)
		local g, at = self.psDockGroup, #dock + 1
		if g then
			for i, o in ipairs(dock) do if o.psDockGroup == g then at = i end end
			if swap and swap.group == g and swap.time == GetTime() then at = math.min(at, swap.at) end
		end
		table.insert(dock, at, self)
		newest = self
		layout()
	end)
	f:HookScript("OnHide", function(self)
		for i, o in ipairs(dock) do
			if o == self and self.psDockGroup then swap = { group = self.psDockGroup, at = i, time = GetTime() } end
		end
		undock(self)
		layout()
	end)
	f:HookScript("OnSizeChanged", function(self) if self:IsShown() then layout() end end)
	if listening then return end
	listening = true
	-- After the shells' own listeners have applied the new scale.
	Polestar.On("SETTING_CHANGED", function(path)
		if path == "ui.menuScale" or path == "" or path == "ui" then layout() end
	end)
	-- Next frame: a stock window we replace is shown and hidden again at once
	-- (ToggleCharacter), and must not push ours aside.
	EventRegistry:RegisterCallback("UIParentPanelManager.ShowUIPanel", function(_, fr)
		C_Timer.After(0, function()
			-- A frame with no panel area is only shown, never placed (a bag
			-- addon's bags): it is no panel, and pushes ours nowhere.
			if not (fr and fr:IsShown() and fr:GetAttribute("UIPanelLayout-defined")) then return end
			stock[fr], newest = true, fr
			if not hooked[fr] then
				hooked[fr] = true
				-- A stock panel hidden by Hide() sends no HideUIPanel event.
				fr:HookScript("OnHide", layout)
			end
			layout()
		end)
	end)
end

-- A window as Polestar's (on) or the game's (off), saved per window in
-- PolestarUIDB.modules. Live: switched off, ours closes and its doors (keys,
-- micro button, toggle hook) are the game's again at once; switched on, they
-- are ours (Enable runs the first time). A module whose stock routing we
-- stopped (reloadOff) is the game's again only after /reload. Never in
-- combat: the doors' override bindings and secure buttons cannot change then.
function ns.Switch(key, on)
	local m = ns.modules[key]
	if ns.tooOld then return print(NEEDS) end
	if InCombatLockdown() then return say("windows cannot switch in combat; try again after it.") end
	if on and blocked(key) then return end
	PolestarUIDB.modules[key] = on
	if ns.WatchStock then ns.WatchStock() end
	if on and not m.psStarted then
		m.psStarted = true
		m.Enable()
	elseif not on and m.reloadOff and m.psStarted then
		return say(key .. ": the game's window after /reload.")
	elseif m.Apply and m.psStarted then
		m.Apply()
	end
	if not on and m.psFrame then m.psFrame:Hide() end
	bindKeys()
	say(key .. ": " .. (on and "Polestar's " or "the game's ") .. (m.noun or "window") .. " (/pui " .. key .. (on and " off" or " on") .. " to switch back).")
end

local function stateOf(key)
	if ns.Enabled(key) then return "on" end
	if ns.modules[key].blockedBy then return "off while " .. ns.modules[key].blockedBy .. " is loaded" end
	return ns.modules[key].reloadOff and ns.modules[key].psStarted and "off after /reload" or "off"
end

-- The window's menu ("..."), Polestar's own (W.ShowMenu, as on the guide
-- window), left of the close button; the Menu scale slider moves left of it.
-- `options`: the window's own items (or a function(button) returning them),
-- first, a divider, then "Use game window".
-- "Use game window" closes ours and opens the game's window in its place. Our
-- code must not open it (rule 8), and a menu row is Polestar's, not secure: a
-- secure button of ours (PolestarUIGameWindow) lies over that row, placed by
-- position out of combat. Its PreClick switches the window off (ours closes,
-- the keys and micro button are the game's again); then its secure action
-- clicks the game's micro button, which opens the game's window from secure
-- code, as the micro overlays' shift-click does (ns.Doors). A window with no
-- micro button (Social) or that waits for /reload (NPC windows, crafting)
-- keeps the plain row: switched off, its keys open the game's window.
local gameDoor
local function gameMicro(key)
	local m = ns.modules[key]
	local micro = m.micro
	return not m.reloadOff and micro and micro:GetName() and micro
end
local function gameWindowDoor()
	local o = CreateFrame("Button", "PolestarUIGameWindow", UIParent, "SecureActionButtonTemplate")
	o:RegisterForClicks("LeftButtonUp")
	o:SetAttribute("useOnKeyDown", false)
	o:SetAttribute("type1", "macro")
	o:SetScript("PreClick", function(self)
		Polestar.Widgets.HideMenu()
		ns.Switch(self.psKey, false)
	end)
	local function row(script) return function() local r = o.psRow; if r and r:GetScript(script) then r:GetScript(script)(r) end end end
	o:SetScript("OnEnter", row("OnEnter"))
	o:SetScript("OnLeave", row("OnLeave"))
	o:Hide()
	-- Over the menu's row while it shows; out of combat only (a secure button
	-- cannot move or hide in combat; its macro does nothing there). Runs only
	-- while a window menu is open (ns.WindowMenu starts it): the first pass
	-- with no row, out of combat, hides the button and stops.
	o.psDriver = CreateFrame("Frame", nil, UIParent)
	o.psTick = function(self)
		if InCombatLockdown() then return end
		local menu, r = PolestarMenu
		for _, x in ipairs(menu and menu:IsVisible() and menu.rows or {}) do
			if x:IsVisible() and x.psItem == o.psItem then r = x end
		end
		o.psRow = r
		if not (r and r:GetLeft()) then
			o:Hide()
			return self:SetScript("OnUpdate", nil)
		end
		local k = r:GetEffectiveScale() / UIParent:GetEffectiveScale()
		o:ClearAllPoints()
		o:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", r:GetLeft() * k, r:GetBottom() * k)
		o:SetSize(r:GetWidth() * k, r:GetHeight() * k)
		o:SetFrameStrata(menu:GetFrameStrata())
		o:SetFrameLevel(r:GetFrameLevel() + 5)
		o:Show()
	end
	return o
end

function ns.WindowMenu(f, key, options)
	local W = Polestar.Widgets
	local m = ns.modules[key]
	m.psFrame = f
	local b = W.IconButton(f.Header, "menu", 28, "Menu", function(self)
		if W.MenuShown(self) then return W.HideMenu() end
		local items = {}
		for _, it in ipairs(type(options) == "function" and options(self) or options or {}) do items[#items + 1] = it end
		if ns.ShowSettings and Polestar.UI then -- Settings.lua: our page in Polestar's settings (no Polestar.UI: the preview)
			items[#items + 1] = { text = "Settings\226\128\166", icon = "gear", onClick = function() ns.ShowSettings(key) end,
				tip = "Polestar: UI's page in Polestar's settings." }
		end
		if #items > 0 then items[#items + 1] = { separator = true } end
		local micro = gameMicro(key)
		local item = { text = "Use game window", icon = "window", onClick = function() ns.Switch(key, false) end,
			tip = (m.reloadOff and "After /reload, the game's own window opens in its place."
				or micro and "Closes this one and opens the game's own window in its place."
				or "Its keys open the game's own window from now on.")
				.. " Type /pui " .. key .. " on to come back." }
		items[#items + 1] = item
		if micro and not InCombatLockdown() then
			gameDoor = gameDoor or gameWindowDoor()
			gameDoor.psKey, gameDoor.psItem = key, item
			gameDoor:SetAttribute("macrotext", "/click [nocombat] " .. micro:GetName())
			gameDoor.psDriver:SetScript("OnUpdate", gameDoor.psTick)
		end
		W.ShowMenu(self, items, #items > 1 and { minWidth = 200 } or nil)
	end, 14)
	local t = f.HeaderTools
	local function place()
		b:ClearAllPoints()
		if f.Close:IsShown() then
			b:SetPoint("RIGHT", f.Close, "LEFT", -4, 0)
		else
			b:SetPoint("TOPRIGHT", f.Header, "TOPRIGHT", -W.SHELL.pad, -12)
		end
		t:ClearAllPoints()
		t:SetPoint("RIGHT", b, "LEFT", -14, 0)
	end
	hooksecurefunc(t, "Place", place) -- the shell places the slider again on a theme change
	place()
	f.psMenu = b
end

if not Polestar.GamepadUI() then
	-- On a stock window shown in place of ours (switched off), a small button
	-- of ours above its top right corner switches back. It is ours, on
	-- UIParent, placed by position: nothing is added to, hooked on or anchored
	-- to the stock frame, which is only read (docs/CLIENT.md, rule 10). Not
	-- shown when there is no room above it (a maximised map).
	-- Clicked, the stock window closes and ours opens in its place. Our code
	-- must not hide it (rules 1, 8, 14), so the click is a secure button of
	-- ours (PolestarUISwitch<key>) over the drawn one, clicking the stock
	-- window's own close button from secure code, as the micro overlays'
	-- shift-click does (ns.Doors); then ours switches on and opens. Not for a
	-- window whose closing ends what it shows (reloadOff: NPC windows,
	-- crafting): that one stays open, and ours opens from the next time.
	-- Hidden in combat, when the switch is refused.
	local stockButtons = {}
	-- Its close button: the frame's own (PortraitFrameTemplate), else its
	-- border's (the world map's is on BorderFrame; WorldMapFrame.CloseButton is
	-- set only for the gamepad). rawget: the parentKey fields, not methods.
	local function closeButton(fr)
		local border = rawget(fr, "BorderFrame")
		return rawget(fr, "CloseButton") or border and rawget(border, "CloseButton") or nil
	end
	local function useOurs(key)
		ns.Switch(key, true)
		if not ns.Enabled(key) then return end
		local fr = ns.modules[key].stock()
		if fr and fr:IsShown() then return say(key .. ": Polestar's window from the next time it opens.") end
		ns.Show(key)
	end
	-- A stock frame says nothing we may hook when it shows or moves (rule 10),
	-- so this runs each frame, but only while some window is the game's:
	-- ns.WatchStock (login, ns.Switch) starts it; a pass with none off, out of
	-- combat (the buttons hidden), stops it.
	local watcher = CreateFrame("Frame", nil, UIParent)
	local function tick(self)
		local any = false
		for _, key in ipairs(ns.order) do
			local m, b = ns.modules[key], stockButtons[key]
			local on = PolestarUIDB and not ns.Enabled(key) and not m.blockedBy and m.stock
			any = any or on
			local fr = on and m.stock()
			local k = fr and fr:IsVisible() and fr:GetTop() and fr:GetEffectiveScale() / UIParent:GetEffectiveScale()
			if InCombatLockdown() then
				if b then b:Hide() end
			elseif k and (fr:GetTop() * k + 30 <= UIParent:GetTop()) then
				if not b then
					b = Polestar.Widgets.Button(UIParent, "Polestar", nil, { height = 22, icon = "emblem" })
					local o = CreateFrame("Button", "PolestarUISwitch" .. key, UIParent, "SecureActionButtonTemplate")
					o:RegisterForClicks("LeftButtonUp")
					o:SetAttribute("useOnKeyDown", false)
					o:SetScript("PostClick", function() useOurs(key) end)
					o:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetText("Use Polestar's window")
						ns.TooltipHint("Closes this one and opens Polestar's; its keys and micro button open Polestar's from now on. Or type /pui " .. key .. " on.")
						GameTooltip:Show()
					end)
					o:SetScript("OnLeave", function() GameTooltip:Hide() end)
					if RegisterStateDriver then RegisterStateDriver(o, "visibility", "[combat] hide; show") end
					b.psSecure = o
					stockButtons[key] = b
				end
				local o, close = b.psSecure, not m.reloadOff and closeButton(fr) or nil
				if o:GetAttribute("clickbutton") ~= close then
					o:SetAttribute("type1", close and "click" or nil)
					o:SetAttribute("clickbutton", close)
				end
				local x, y = fr:GetRight() * k, fr:GetTop() * k + 4
				b:ClearAllPoints()
				b:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", x, y)
				b:SetFrameStrata(fr:GetFrameStrata())
				b:Show()
				-- By position, on UIParent: anchored to ours, it would protect it (rule 10).
				o:ClearAllPoints()
				o:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", x, y)
				o:SetSize(b:GetWidth(), b:GetHeight())
				o:SetFrameStrata(b:GetFrameStrata())
				o:SetFrameLevel(b:GetFrameLevel() + 5)
				o:Show()
			elseif b then
				b:Hide()
				b.psSecure:Hide()
			end
		end
		if not any and not InCombatLockdown() then self:SetScript("OnUpdate", nil) end
	end
	function ns.WatchStock()
		watcher:SetScript("OnUpdate", tick)
		return watcher
	end

	-- /pui opens our settings; /pui help lists the windows and whether each is
	-- Polestar's; /pui <window> on|off switches it, /pui <window> opens ours.
	SLASH_POLESTARUI1 = "/pui"
	SlashCmdList.POLESTARUI = function(msg)
		local key, state = (msg or ""):lower():match("^(%S*)%s*(%S*)")
		if key == "dock" then
			if state == "on" or state == "off" then ns.SetDocked(state == "on") end
			say("windows " .. (ns.Docked() and "dock as the game's do" or "move freely") .. " (/pui dock on|off)")
		elseif key == "" then
			ns.ShowSettings()
		elseif not ns.modules[key] then
			say("/pui opens the settings. Windows (on: Polestar's, off: the game's): /pui <window> on|off, /pui dock on|off")
			for _, k in ipairs(ns.order) do say("  " .. k .. ": " .. stateOf(k)) end
		elseif state == "on" or state == "off" then
			ns.Switch(key, state == "on")
		else
			ns.Show(key)
		end
	end
end
