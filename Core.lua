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

ns.modules, ns.order = {}, {}

-- A module: { Enable = fn (once, at login or when switched on), Show = fn(...),
-- stock = fn (the stock window it replaces, when that is the one shown),
-- reloadOff = true (switching it off waits for /reload), Apply = fn (a module
-- with no window: switched on or off again live, it restyles or restores),
-- noun = what it switches ("window" when not given) }, keyed by its
-- slash-command name.
function ns.Module(key, m)
	ns.modules[key] = m
	ns.order[#ns.order + 1] = key
	return m
end

function ns.Enabled(key)
	local v = PolestarUIDB and PolestarUIDB.modules[key]
	if v == nil then return not Polestar.GamepadUI() end
	return v
end

function ns.Show(key, ...)
	local m = ns.modules[key]
	if m and m.Show then m.Show(...) end
end

Polestar.OnLogin(function()
	PolestarUIDB = PolestarUIDB or {}
	PolestarUIDB.modules = PolestarUIDB.modules or {}
	PolestarUIDB.pos = PolestarUIDB.pos or {}
	PolestarUICharDB = PolestarUICharDB or {}
	for _, key in ipairs(ns.order) do
		if ns.Enabled(key) then
			ns.modules[key].psStarted = true
			ns.modules[key].Enable()
		end
	end
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

-- A flyout: a window-skinned panel on the right edge of window `f`, as tall as
-- it and `width` wide, that takes the mouse. The caller shows it and calls
-- ns.DockFlyout.
function ns.Flyout(f, name, width)
	local d = CreateFrame("Frame", name, f)
	d:SetPoint("TOPLEFT", f, "TOPRIGHT", -1, 0)
	d:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT", -1, 0)
	d:SetWidth(width)
	d:EnableMouse(true)
	Polestar.Theme.Skin(d, "window")
	return d
end

-- The band's Options button, a menu of `items` (or a function(button) returning
-- them) that a second click closes. Returns the button.
function ns.OptionsButton(f, items)
	local W = Polestar.Widgets
	local opt = CreateFrame("Button", nil, f.Header)
	opt:SetSize(96, 24)
	opt:SetPoint("BOTTOMRIGHT", f.Header, "BOTTOMRIGHT", -20, 12)
	W.Hover(opt)
	opt.Label = W.Text(opt, "small", "text")
	opt.Label:SetPoint("LEFT", opt, "LEFT", 10, 0)
	opt.Label:SetText("Options")
	opt.Arrow = W.Tex(opt, "ARTWORK", "chevron-down", "textDim")
	opt.Arrow:SetSize(12, 12)
	opt.Arrow:SetPoint("RIGHT", opt, "RIGHT", -10, 0)
	opt:SetScript("OnClick", function(self)
		if W.MenuShown(self) then return W.HideMenu() end
		W.ShowMenu(self, type(items) == "function" and items(self) or items, { minWidth = 200 })
	end)
	return opt
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
-- its icon (also well.Icon). `kind` is its frame type, "Frame" when not given.
function ns.ItemWell(parent, size, kind)
	local well = CreateFrame(kind or "Frame", nil, parent)
	well:SetSize(size, size)
	Polestar.Theme.Skin(well, "inset")
	Polestar.Theme.Border(well, Polestar.Theme.Wash("border"))
	local icon = ns.GameIcon(well)
	icon:SetPoint("TOPLEFT", 1, -1)
	icon:SetPoint("BOTTOMRIGHT", -1, 1)
	well.Icon = icon
	return well, icon
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
-- hides the rest, fits the frame's height and returns the wells.
function ns.ItemGrid(parent, cols, size, gap)
	local g = CreateFrame("Frame", nil, parent)
	g:SetSize(cols * (size + gap) - gap, 1)
	local wells = {}
	function g.Layout(n)
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
		end
		for i = n + 1, #wells do wells[i]:Hide() end
		-- Never 0 high: a frame of size 0 has no rect (docs/CLIENT.md, rule 12).
		g:SetHeight(math.max(1, math.ceil(n / cols) * (size + gap) - gap))
		return wells
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

-- Coins as plain text for a label or dialog line ("1g 2s 3c", units above
-- the largest left out), as Polestar's own Restock label writes them.
function ns.Coins(c)
	local g, s = math.floor(c / 10000), math.floor(c / 100) % 100
	if g > 0 then return ("%dg %ds %dc"):format(g, s, c % 100) end
	if s > 0 then return ("%ds %dc"):format(s, c % 100) end
	return ("%dc"):format(c % 100)
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

-- The NPC's portrait at the band's left, the title beside it, as the stock
-- windows' (SetPortraitToUnit; the quest book when there is no unit). Shared
-- with the Quest dialog. Returns paint(unit).
function ns.NpcPortrait(f)
	local W = Polestar.Widgets
	local well, icon = ns.ItemWell(f.Header, 48)
	well:SetPoint("TOPLEFT", f.Header, "TOPLEFT", W.SHELL.pad, -28)
	f.Title:SetPoint("TOPLEFT", f.Header, "TOPLEFT", W.SHELL.pad + 48 + 16, -32)
	f.psPortraitIcon = icon
	return function(unit)
		if UnitExists(unit) then SetPortraitTexture(icon, unit) else icon:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon") end
		f.Subtitle:SetWidth(f.BodyWidth - 48 - 16)
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
		if usable == false then t.Icon:SetVertexColor(0.9, 0, 0) else t.Icon:SetVertexColor(1, 1, 1) end
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
	CreateFrame("Frame", nil, UIParent):SetScript("OnUpdate", function()
		if InCombatLockdown() then return end
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
					if o.bags then CloseAllBags(self) end
					if not ended then o.close() end
					ended = nil
				end)
			end
			if o.bags then OpenAllBags(f) end
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

-- Docking, the default (PolestarUIDB.free turns it off): our windows lay out
-- as the stock panel manager lays out pushable "left" panels
-- (UpdateUIPanelPositions in UIParentPanelManager.lua): from the top left, in
-- the order they opened, 32 apart, right of any stock panel open, and not
-- draggable. When they do not fit (GetMaxUIPanelsWidth), the oldest closes,
-- unless it is the one just opened. Their size is Polestar's Menu scale
-- (ui.menuScale), the player's to set. We cannot place the stock panels (their
-- manager is forbidden to us, docs/CLIENT.md rule 1), so ours give way to
-- them. A stock "center" panel closes ours itself: they are UISpecialFrames.
local dock, stock, hooked, newest, listening, swap = {}, {}, {}, nil, false, nil
function ns.Docked() return not PolestarUIDB.free end

-- A window's width with its shown flyouts (ns.DockFlyout).
local function footprint(f)
	local w = f:GetWidth()
	for _, o in ipairs(f.psFlyouts or {}) do if o:IsShown() then w = w + o:GetWidth() - o.psOverlap end end
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
	if right > GetMaxUIPanelsWidth() and docked[1] and docked[1] ~= newest then
		docked[1]:Hide() -- its OnHide lays the rest out
		return
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
-- window's stats drawer), `overlap` px over its edge: while shown, the dock
-- counts its width as the window's and the window keeps it on screen. A
-- flyout inside the window (the map's quest log) needs none: the window
-- grows, and the dock follows its size.
function ns.DockFlyout(f, fly, overlap)
	fly.psOverlap = overlap or 0
	f.psFlyouts = f.psFlyouts or {}
	table.insert(f.psFlyouts, fly)
	local function changed()
		f:SetClampRectInsets(0, footprint(f) - f:GetWidth(), 0, 0)
		if f:IsShown() then layout() end
	end
	fly:HookScript("OnShow", changed)
	fly:HookScript("OnHide", changed)
	fly:HookScript("OnSizeChanged", changed)
	-- Shown or hidden while the window was shut sends neither.
	f:HookScript("OnShow", changed)
end

function ns.SetDocked(on)
	PolestarUIDB.free = not on or nil
	layout()
end

function ns.Dock(f)
	local startMoving = f.StartMoving
	-- The shell's drag handles call f:StartMoving(); docked, the dock places it.
	f.StartMoving = function(self) if not ns.Docked() and not self.psFull then startMoving(self) end end
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

local function say(msg) print("|cffe6ba66Polestar: UI|r " .. msg) end

-- A window as Polestar's (on) or the game's (off), saved per window in
-- PolestarUIDB.modules. Live: switched off, ours closes and its doors (keys,
-- micro button, toggle hook) are the game's again at once; switched on, they
-- are ours (Enable runs the first time). A module whose stock routing we
-- stopped (reloadOff) is the game's again only after /reload. Never in
-- combat: the doors' override bindings and secure buttons cannot change then.
function ns.Switch(key, on)
	local m = ns.modules[key]
	if InCombatLockdown() then return say("windows cannot switch in combat; try again after it.") end
	PolestarUIDB.modules[key] = on
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
	return ns.modules[key].reloadOff and ns.modules[key].psStarted and "off after /reload" or "off"
end

-- The window's menu ("..."), Polestar's own (W.ShowMenu, as on the guide
-- window), left of the close button; the Menu scale slider moves left of it.
function ns.WindowMenu(f, key)
	local W = Polestar.Widgets
	local m = ns.modules[key]
	m.psFrame = f
	local b = W.IconButton(f.Header, "menu", 28, "Menu", function(self)
		if W.MenuShown(self) then return W.HideMenu() end
		W.ShowMenu(self, {
			{ text = "Use game window", icon = "window", onClick = function() ns.Switch(key, false) end,
				tip = (m.reloadOff and "After /reload, the game's own window opens in its place." or "The game's own window opens in its place.")
					.. " Type /pui " .. key .. " on to come back." },
		})
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
	local stockButtons = {}
	CreateFrame("Frame", nil, UIParent):SetScript("OnUpdate", function()
		for _, key in ipairs(ns.order) do
			local m, b = ns.modules[key], stockButtons[key]
			local fr = PolestarUIDB and not ns.Enabled(key) and m.stock and m.stock()
			local k = fr and fr:IsVisible() and fr:GetTop() and fr:GetEffectiveScale() / UIParent:GetEffectiveScale()
			if k and (fr:GetTop() * k + 30 <= UIParent:GetTop()) then
				if not b then
					b = Polestar.Widgets.Button(UIParent, "Polestar", function() ns.Switch(key, true) end, { height = 22, icon = "emblem" })
					b:HookScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetText("Use Polestar's window")
						ns.TooltipHint("Its keys and micro button open Polestar's window in place of this one. Or type /pui " .. key .. " on.")
						GameTooltip:Show()
					end)
					b:HookScript("OnLeave", function() GameTooltip:Hide() end)
					stockButtons[key] = b
				end
				b:ClearAllPoints()
				b:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", fr:GetRight() * k, fr:GetTop() * k + 4)
				b:SetFrameStrata(fr:GetFrameStrata())
				b:Show()
			elseif b then
				b:Hide()
			end
		end
	end)

	-- /pui lists the windows and whether each is Polestar's; /pui <window>
	-- on|off switches it, /pui <window> opens ours.
	SLASH_POLESTARUI1 = "/pui"
	SlashCmdList.POLESTARUI = function(msg)
		local key, state = (msg or ""):lower():match("^(%S*)%s*(%S*)")
		if key == "dock" then
			if state == "on" or state == "off" then ns.SetDocked(state == "on") end
			say("windows " .. (ns.Docked() and "dock as the game's do" or "move freely") .. " (/pui dock on|off)")
		elseif not ns.modules[key] then
			say("windows (on: Polestar's, off: the game's). /pui <window> on|off, /pui dock on|off")
			for _, k in ipairs(ns.order) do say("  " .. k .. ": " .. stateOf(k)) end
		elseif state == "on" or state == "off" then
			ns.Switch(key, state == "on")
		else
			ns.Show(key)
		end
	end
end
