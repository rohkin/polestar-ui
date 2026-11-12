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
-- window itself, never off the 0-wide sidebar (docs/CLIENT.md, rule 12).
function ns.Plain(f)
	f.Sidebar:Hide()
	f.Main:ClearAllPoints()
	f.Main:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
	f.Main:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
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
	-- Disabled as Polestar disables: faded to 45%.
	local function enable(b, on)
		b:SetEnabled(on)
		b:SetAlpha(on and 1 or 0.45)
	end
	function s.Paint()
		local n, most = o.get(), o.max()
		if not s.Box:HasFocus() then s.Box:SetText(n) end
		enable(s.Less, n > 1)
		enable(s.More, n < most)
		enable(s.Max, n < most)
	end
	return s
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
-- after, as the stock window did. Off waits for /reload: routed back from our
-- code, the stock window would open tainted. Call it from the module's Enable.
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
			if not (fr and fr:IsShown()) then return end
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
