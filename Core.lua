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
