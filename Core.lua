-- Polestar: UI, a companion to Polestar: the game's own windows remade in
-- Polestar's look, drawn with Polestar's kit (Polestar.Widgets, Polestar.Theme).
--
-- Taint: Forever's gamepad UI reads parts of the default UI from secure code,
-- so nothing here writes into Blizzard frames; our windows are our own, and a
-- stock window is closed the moment the game opens it (docs/DESIGN.md, "The
-- Replacement Contract"). With the gamepad UI on, every module starts off and
-- no slash command is registered.

local ADDON, ns = ...
PolestarUI = ns

ns.modules, ns.order = {}, {}

-- A module: { Enable = fn (once, at login), Show = fn(...) }, keyed by its
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
		if ns.Enabled(key) then ns.modules[key].Enable() end
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

-- One secure button of ours over the hovered target (a spell row, a gear
-- slot), out of combat, for the clicks the game protects (docs/CLIENT.md,
-- rule 4). It hangs off UIParent above the window's strata, and hides as the
-- mouse leaves, the target moves (a scroll) or hides, or combat starts.
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
				if not t:IsVisible() or t:GetTop() ~= self.psTop or (o.stale and o.stale(t)) then self:Hide() end
			end)
			Polestar.RegisterEvent("PLAYER_REGEN_DISABLED", function() over:Hide() end)
			if o.setup then o.setup(over) end
		end
		if over.psPressed then return end
		if over.psTarget and over.psTarget ~= t then over.psTarget:UnlockHighlight() end
		over.psTarget, over.psTop = t, t:GetTop()
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
-- `actions` maps a binding name to its click.
local keyOwner, keyButtons, keySig = CreateFrame("Frame"), {}, nil
local function bindKeys()
	if InCombatLockdown() then return end -- PLAYER_REGEN_ENABLED binds them
	local sig = {}
	for action in pairs(keyButtons) do sig[#sig + 1] = action .. "=" .. table.concat({ GetBindingKey(action) }, ",") end
	table.sort(sig)
	sig = table.concat(sig, ";")
	-- Only on a change: setting overrides fires UPDATE_BINDINGS again.
	if sig == keySig then return end
	keySig = sig
	ClearOverrideBindings(keyOwner)
	for action, name in pairs(keyButtons) do
		for _, key in ipairs({ GetBindingKey(action) }) do SetOverrideBindingClick(keyOwner, false, key, name) end
	end
end

function ns.Doors(name, actions, micro, onMicro)
	for action, fn in pairs(actions) do
		local b = CreateFrame("Button", "PolestarUI" .. name .. action, UIParent)
		b:SetScript("OnClick", function() fn() end)
		keyButtons[action] = b:GetName()
	end
	if not keySig then
		Polestar.RegisterEvent("UPDATE_BINDINGS", bindKeys)
		Polestar.RegisterEvent("PLAYER_REGEN_ENABLED", bindKeys)
	end
	keySig = false
	bindKeys()
	if not micro then return end
	local o = CreateFrame("Button", "PolestarUI" .. name .. "Micro", UIParent, "SecureActionButtonTemplate")
	o:SetAllPoints(micro)
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
	-- Our own frame, not the micro button's child: a driver keeps it over the
	-- button, out of combat only (a secure button cannot be shown or moved in combat).
	CreateFrame("Frame", nil, UIParent):SetScript("OnUpdate", function()
		if InCombatLockdown() then return end
		local on = micro:IsVisible() and micro:IsEnabled()
		-- Above the micro button, wherever Edit Mode or the bar puts it.
		if on and (o:GetFrameStrata() ~= micro:GetFrameStrata() or o:GetFrameLevel() <= micro:GetFrameLevel()) then
			o:SetFrameStrata(micro:GetFrameStrata())
			o:SetFrameLevel(micro:GetFrameLevel() + 10)
		end
		o:SetShown(on)
	end)
end

local function say(msg) print("|cffe6ba66Polestar: UI|r " .. msg) end

-- /pui <module> opens it; /pui <module> on|off takes effect after /reload.
if not Polestar.GamepadUI() then
	SLASH_POLESTARUI1 = "/pui"
	SlashCmdList.POLESTARUI = function(msg)
		local key, state = (msg or ""):lower():match("^(%S*)%s*(%S*)")
		if not ns.modules[key] then
			say("modules: " .. table.concat(ns.order, ", ") .. " (/pui <module> [on|off])")
		elseif state == "on" or state == "off" then
			PolestarUIDB.modules[key] = state == "on"
			say(key .. " " .. state .. ": /reload to apply.")
		else
			ns.Show(key)
		end
	end
end
