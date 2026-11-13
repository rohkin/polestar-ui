-- Action bars (docs/windows/actionbars.md): the game's own action buttons in
-- Polestar's look, restyled in place, never rebuilt. The bars are Edit Mode
-- systems and the buttons secure: their place, size, rows, icon size, art
-- setting and paging stay the game's and the player's (docs/CLIENT.md, rule
-- 16). On each button only its art changes: the slot and frame art faded
-- with SetAlpha (the game swaps their atlases, which keeps the alpha), the
-- hover faded, the checked glow emptied (its alpha the game writes), the
-- icon unmasked and cropped square, and textures of ours added: a ground, a
-- 1px hairline, the hover wash, an accent wash while pressed or checked and
-- an accent hairline while checked. The key, count and macro name in
-- Polestar's faces at the game's sizes and colours (the count is never read:
-- secret in combat). The equipped item's green border, the flash, the spell
-- alerts, cooldowns and the bar art (end caps, dividers: Edit Mode's Hide Bar
-- Art) stay the game's. What is ours is kept in weak tables; no key is written
-- on a stock frame. Buttons the game makes later (the spell flyout, the
-- zone ability, the override bar) are restyled out of combat.

local ADDON, ns = ...
local Theme = Polestar.Theme

local M = { noun = "action bars" }
-- The buttons by name (ActionBar.lua names the bars' buttons; the others are
-- their templates' names), with how many each bar has at most.
local NAMED = {
	{ "ActionButton", 12 }, { "MultiBarBottomLeftButton", 12 }, { "MultiBarBottomRightButton", 12 },
	{ "MultiBarLeftButton", 12 }, { "MultiBarRightButton", 12 }, { "MultiBar5Button", 12 }, { "MultiBar6Button", 12 },
	{ "MultiBar7Button", 12 }, { "PetActionButton", 10 }, { "StanceButton", 10 }, { "PossessButton", 2 },
	{ "MultiCastActionButton", 12 }, { "MultiCastSummonSpellButton" }, { "MultiCastRecallSpellButton" },
	{ "OverrideActionBarButton", 6 }, { "SpellFlyoutPopupButton", 40 },
}
-- ActionButtonTemplate's slot art (UpdateButtonArt shows one or the other).
local SLOT = { "SlotArt", "SlotBackground" }
local FONTS = { { "HotKey", "number" }, { "Count", "number" }, { "Name", "small" } }
local EDGES = { { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }
local CROP = 0.08 -- the icon's baked border, cropped as ns.GameIcon does

local looks = setmetatable({}, { __mode = "k" }) -- stock button -> its textures of ours and what it was
local driver, started

local function on() return ns.Enabled("actionbars") end

local function tex(f, layer, sub)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetTexture(Theme.Media("white"))
	return t
end

local function look(b)
	local l = looks[b]
	if l then return l end
	local icon = rawget(b, "icon") or rawget(b, "Icon")
	if not icon then return end
	l = { icon = icon, mask = rawget(b, "IconMask"), fill = tex(b, "BACKGROUND", -8), wash = tex(b, "OVERLAY", 6),
		hover = tex(b, "HIGHLIGHT"), edges = {}, fonts = {} }
	l.checked = b.GetCheckedTexture and b:GetCheckedTexture()
	l.atlas = l.checked and l.checked:GetAtlas()
	l.fill:SetAllPoints(b)
	l.wash:SetAllPoints(b)
	l.hover:SetAllPoints(b)
	for i, p in ipairs(EDGES) do
		local t = tex(b, "OVERLAY", 7)
		t:SetPoint(p[1], b, p[1], 0, 0)
		t:SetPoint(p[2], b, p[2], 0, 0)
		l.edges[i] = t
	end
	for _, f in ipairs(FONTS) do
		local fs = rawget(b, f[1])
		if fs then l.fonts[#l.fonts + 1] = { fs = fs, role = f[2], stock = { fs:GetFont() } } end
	end
	looks[b] = l
	return l
end

-- Pressed (a click or its key) or checked (a stance, an auto-attack, a
-- spell waiting for its target): the accent wash; checked, the accent hairline.
local function paintState(b, l)
	local pushed = b:GetButtonState() == "PUSHED"
	local checked = b.GetChecked and b:GetChecked() and true or false
	l.pushed, l.isChecked = pushed, checked
	local r, g, bl = Theme.Accent()
	l.wash:SetVertexColor(r, g, bl, pushed and 0.3 or 0.15)
	l.wash:SetShown(pushed or checked)
	local px = Theme.Pixel(b)
	for i, t in ipairs(l.edges) do
		if checked then t:SetVertexColor(r, g, bl, 1) else t:SetVertexColor(Theme.Color("border")) end
		if i <= 2 then t:SetHeight(px) else t:SetWidth(px) end
	end
end

local function fade(a, ...)
	for i = 1, select("#", ...) do
		local t = select(i, ...)
		if t then t:SetAlpha(a) end
	end
end

local function paint(b, shown)
	local l = look(b)
	if not l then return end
	local a = shown and 0 or 1
	for _, k in ipairs(SLOT) do fade(a, rawget(b, k)) end
	fade(a, b:GetNormalTexture(), b:GetPushedTexture(), b:GetHighlightTexture())
	if l.checked then
		if shown then l.checked:SetTexture(nil) elseif l.atlas then l.checked:SetAtlas(l.atlas) end
	end
	if shown ~= (l.square or false) then
		if l.mask then
			if shown then l.icon:RemoveMaskTexture(l.mask) else l.icon:AddMaskTexture(l.mask) end
		end
		if shown then l.icon:SetTexCoord(CROP, 1 - CROP, CROP, 1 - CROP) else l.icon:SetTexCoord(0, 1, 0, 1) end
	end
	l.square = shown
	for _, f in ipairs(l.fonts) do
		local s = f.stock
		if s[1] then Theme.SetFace(f.fs, shown and (Theme.FontSpec(f.role)) or s[1], s[2], s[3] or "") end
	end
	local r, g, bl = Theme.Color("bg")
	l.fill:SetVertexColor(r, g, bl, Theme.GroundAlpha())
	l.hover:SetVertexColor(Theme.Wash("hover"))
	l.fill:SetShown(shown)
	l.hover:SetShown(shown)
	for _, t in ipairs(l.edges) do t:SetShown(shown) end
	if shown then paintState(b, l) else l.wash:Hide() end
end

-- Every button there is now: the bars' (by name) and the zone ability's.
local function each(fn)
	for _, n in ipairs(NAMED) do
		if n[2] then
			for i = 1, n[2] do
				local b = rawget(_G, n[1] .. i)
				if b then fn(b) end
			end
		elseif rawget(_G, n[1]) then
			fn(_G[n[1]])
		end
	end
	local z = rawget(_G, "ZoneAbilityFrame")
	local c = z and rawget(z, "SpellButtonContainer")
	if c then for _, b in ipairs({ c:GetChildren() }) do fn(b) end end
end

function M.Apply()
	if not started then return end
	local shown = on()
	each(function(b)
		-- A button not yet restyled waits for the end of combat.
		if looks[b] or not InCombatLockdown() then paint(b, shown) end
	end)
	driver:SetShown(shown)
end

-- New buttons out of combat (a flyout's, the zone ability's: the game makes
-- them when they are first needed), and the pressed and checked states (no
-- event says a key pressed a button).
local scan = 0
local function update(_, elapsed)
	scan = scan + elapsed
	if scan >= 0.25 then
		scan = 0
		if not InCombatLockdown() then each(function(b) if not looks[b] then paint(b, true) end end) end
	end
	for b, l in pairs(looks) do
		if l.square and b:IsVisible() then
			local pushed = b:GetButtonState() == "PUSHED"
			local checked = b.GetChecked and b:GetChecked() and true or false
			if pushed ~= l.pushed or checked ~= l.isChecked then paintState(b, l) end
		end
	end
end

function M.Enable()
	if not rawget(_G, "MainActionBar") then return end
	started = true
	driver = CreateFrame("Frame", nil, UIParent)
	driver:SetScript("OnUpdate", update)
	-- Edit Mode's icon size scales the buttons: the hairlines one pixel again.
	EventRegistry:RegisterCallback("EditMode.Exit", M.Apply, M)
	Polestar.RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", M.Apply)
	Polestar.RegisterEvent("PLAYER_REGEN_ENABLED", M.Apply)
	Polestar.RegisterEvent("ADDON_LOADED", function(_, name)
		if name == "Blizzard_OverrideActionBar" or name == "Blizzard_ZoneAbility" then M.Apply() end
	end)
	Theme.OnChanged(function() if on() then M.Apply() end end)
	M.Apply()
end

ns.Module("actionbars", M)
