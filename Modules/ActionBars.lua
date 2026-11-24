-- Action bars (docs/windows/actionbars.md): the game's own action buttons in
-- Polestar's look, restyled in place, never rebuilt. The bars are Edit Mode
-- systems and the buttons secure: their place, size, rows, icon size, art
-- setting and paging stay the game's and the player's (docs/CLIENT.md, rule
-- 16). On each button only its art changes: the slot and frame art faded
-- with SetAlpha (the game swaps their atlases, which keeps the alpha), the
-- hover faded, the checked glow emptied (its alpha the game writes), the
-- icon unmasked and cropped square, and textures of ours added: a ground, a
-- 1px hairline, the hover wash, an accent wash while pressed or checked and
-- an accent hairline while checked, and Polestar's emblem faint in an empty
-- slot (its icon hidden: the game hides it with no action). The key, count and macro name in
-- Polestar's faces at the game's sizes and colours, the key and count
-- outlined (the count is never read: secret in combat). The equipped item's
-- green border, the flash, the spell alerts, cooldowns and the bar art (end
-- caps, dividers: Edit Mode's Hide Bar Art) stay the game's. What is ours is
-- kept in weak tables; no key is written on a stock frame. Buttons the game
-- makes later (the spell flyout, the zone ability, the override bar) are
-- restyled out of combat.

local ADDON, ns = ...
local Theme = Polestar.Theme
local H = ns.HUD

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
-- Each with its face and, on ours, its outline (the key and count legible over any icon).
-- FreeSlots: the backpack's free count (the bag bar, Modules/BagBar.lua).
local FONTS = { { "HotKey", "number", "OUTLINE", true }, { "Count", "number", "OUTLINE" }, { "Name", "small" },
	{ "FreeSlots", "number", "OUTLINE" } }
local CROP = 0.08 -- the icon's baked border, cropped as ns.GameIcon does
local LOOK, SHADOW = H.ICONS, 6 -- the HUD look's Icons group (2 px at most while it follows Polestar); the shadow's reach

local looks = setmetatable({}, { __mode = "k" }) -- stock button -> its textures of ours and what it was
local driver, started

local function on() return ns.Enabled("actionbars") end

local tex = ns.HUD.Tex

local function look(b)
	local l = looks[b]
	if l then return l end
	local icon = rawget(b, "icon") or rawget(b, "Icon")
	if not icon then return end
	-- An item button's icon also wears ItemButtonMixin:PostOnLoad's rounded `Mask` (the bag bar).
	l = { icon = icon, masks = { rawget(b, "IconMask") or rawget(b, "SquareMask"), b.GetItemButtonIconTexture and rawget(b, "Mask") or nil }, fill = tex(b, "BACKGROUND", -8), wash = tex(b, "OVERLAY", 6),
		hover = tex(b, "HIGHLIGHT"), edges = ns.Hairlines(b, b, function() return tex(b, "OVERLAY", 7) end), fonts = {}, shadow = H.Shadow(b, b, SHADOW) }
	l.checked = b.GetCheckedTexture and b:GetCheckedTexture()
	l.atlas = l.checked and l.checked:GetAtlas()
	l.fill:SetAllPoints(b)
	l.wash:SetAllPoints(b)
	l.hover:SetAllPoints(b)
	l.logo = b:CreateTexture(nil, "ARTWORK")
	l.logo:SetTexture(Theme.Media("emblem"))
	l.logo:SetPoint("CENTER", b, "CENTER")
	for _, f in ipairs(FONTS) do
		local fs = rawget(b, f[1])
		if fs then l.fonts[#l.fonts + 1] = { fs = fs, role = f[2], flags = f[3], dot = f[4], stock = { fs:GetFont() } } end
	end
	looks[b] = l
	return l
end

-- Pressed (a click or its key) or checked (a stance, an auto-attack, a
-- spell waiting for its target): the accent wash; checked, the accent hairline.
-- The key's range dot (RANGE_INDICATOR, "●"; "•" in some locales), written
-- in place of a missing binding: Fira Sans and Open Sans have no glyph for it
-- (a box), so the dot keeps the game's face. The game compares this text too.
local function dotted(fs)
	local t = fs:GetText()
	return RANGE_INDICATOR ~= nil and ns.Clean(t) == RANGE_INDICATOR
end

local function setFace(f, shown)
	local s = f.stock
	if not s[1] then return end
	f.isDot = f.dot and dotted(f.fs) or false
	local ours = shown and not f.isDot
	Theme.SetFace(f.fs, ours and (Theme.FontSpec(f.role)) or s[1], s[2], (shown and f.flags) or s[3] or "")
end

-- Checked, or lit by the caller's own test (`l.lit`: the bag bar's open bags).
local function isChecked(b, l)
	if l.lit then return l.lit(b) and true or false end
	return b.GetChecked and b:GetChecked() and true or false
end

local function paintState(b, l)
	local pushed = b:GetButtonState() == "PUSHED"
	local checked = isChecked(b, l)
	l.pushed, l.isChecked = pushed, checked
	local r, g, bl = Theme.Accent()
	l.wash:SetVertexColor(r, g, bl, pushed and 0.3 or 0.15)
	l.wash:SetShown(pushed or checked)
	if checked then H.PaintTint(l.edges, true, LOOK, r, g, bl, 1) else H.PaintEdge(l.edges, true, LOOK) end
end

-- Empty (the game hides the icon of a slot with no action): Polestar's emblem, faint, in the
-- lighter accent: the accent half way to white (Polestar 0.4.0 has no lighter accent token; its
-- own bright star, emblem-hot, is a fixed light gold), so it follows every scheme and skin.
-- A caller's own test (`l.isEmpty`: the bag bar's slot with no bag, whose icon shows the game's
-- empty-bag art) is read only when painted (the caller's events); its icon is then faded.
local LOGO = 0.6 -- of the button: the emblem's ink is 32 of its 44px box, so about 45% of the slot
local LIGHT, FAINT = 0.5, 0.05 -- the mix toward white; the alpha
local function paintLogo(b, l, shown)
	if l.isEmpty then
		l.empty = l.isEmpty(b) and true or false
		l.icon:SetAlpha(shown and l.empty and 0 or 1)
	else
		l.empty = not l.icon:IsShown()
	end
	if shown and l.empty then
		local r, g, bl = Theme.Accent()
		local s = (b:GetWidth() or 0) * LOGO
		l.logo:SetSize(s, s)
		l.logo:SetVertexColor(r + (1 - r) * LIGHT, g + (1 - g) * LIGHT, bl + (1 - bl) * LIGHT, FAINT)
	end
	l.logo:SetShown(shown and l.empty)
end

local fade = H.Fade

local function paint(b, shown, lit, isEmpty)
	local l = look(b)
	if not l then return end
	l.lit = lit or l.lit
	l.isEmpty = isEmpty or l.isEmpty
	local a = shown and 0 or 1
	for _, k in ipairs(SLOT) do fade(a, rawget(b, k)) end
	fade(a, b:GetNormalTexture(), b:GetPushedTexture(), b:GetHighlightTexture())
	if l.checked then
		if shown then l.checked:SetTexture(nil) elseif l.atlas then l.checked:SetAtlas(l.atlas) end
	end
	if shown ~= (l.square or false) then
		for _, m in pairs(l.masks) do
			if shown then l.icon:RemoveMaskTexture(m) else l.icon:AddMaskTexture(m) end
		end
		if shown then l.icon:SetTexCoord(CROP, 1 - CROP, CROP, 1 - CROP) else l.icon:SetTexCoord(0, 1, 0, 1) end
	end
	l.square = shown
	for _, f in ipairs(l.fonts) do setFace(f, shown) end
	local r, g, bl = Theme.Color("bg")
	l.fill:SetVertexColor(r, g, bl, H.GroundAlpha(LOOK))
	l.hover:SetVertexColor(Theme.Wash("hover"))
	l.fill:SetShown(shown)
	l.hover:SetShown(shown)
	H.PaintShadow(l.shadow, shown, nil, LOOK)
	paintLogo(b, l, shown)
	if shown then paintState(b, l) else l.wash:Hide(); ns.PaintHairlines(l.edges, false, 0, 0, 0, 0) end
end

-- One restyled button's states, each frame: pressed, checked, empty, the range dot.
local function tick(b)
	local l = looks[b]
	if not (l and l.square and b:IsVisible()) then return end
	if (b:GetButtonState() == "PUSHED") ~= l.pushed or isChecked(b, l) ~= l.isChecked then paintState(b, l) end
	-- A slot given or emptied of its action (a drag, a page or form swap: the game shows or hides its icon).
	if not l.isEmpty and l.icon:IsShown() == l.empty then paintLogo(b, l, true) end
	-- An item button's new icon resets its coords (SetItemButtonTexture: SetTexCoord(0, 1, 0, 1)).
	-- (Coords come back as float32: compared loosely.)
	if math.abs((l.icon:GetTexCoord() or 0) - CROP) > 1e-3 then l.icon:SetTexCoord(CROP, 1 - CROP, CROP, 1 - CROP) end
	-- The key turned into the range dot or back (no event says so).
	for _, f in ipairs(l.fonts) do
		if f.dot and dotted(f.fs) ~= f.isDot then setFace(f, true) end
	end
end

-- The look for other stock item buttons (the bag bar), whatever this
-- module's switch: paint(b, shown, lit?, isEmpty?) and tick(b) from the caller's driver.
ns.ButtonLook = { paint = paint, tick = tick }

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

-- New buttons out of combat: the game makes a flyout's and the zone ability's
-- when their frame first shows (from the frame's own code, the same moment or
-- just after), so a hidden frame of ours on each says when (rule 17: a frame
-- of ours under it, nothing written on it); the end of combat (M.Apply) does
-- any made mid-fight.
local function dressNew()
	if started and on() and not InCombatLockdown() then each(function(b) if not looks[b] then paint(b, true) end end) end
end
local watched = setmetatable({}, { __mode = "k" })
local function watch(f)
	if not f or watched[f] or InCombatLockdown() then return end
	watched[f] = Polestar.CreateFrameUnder("Frame", nil, f)
	watched[f]:SetScript("OnShow", function() C_Timer.After(0, dressNew) end)
end

function M.Apply()
	if not started then return end
	local shown = on()
	each(function(b)
		-- A button not yet restyled waits for the end of combat.
		if looks[b] or not InCombatLockdown() then paint(b, shown) end
	end)
	watch(rawget(_G, "SpellFlyout"))
	watch(rawget(_G, "ZoneAbilityFrame"))
	driver:SetShown(shown)
end

-- The pressed and checked states, each frame (no event says a key pressed a button).
local function update()
	for b in pairs(looks) do tick(b) end
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
	Theme.OnChanged(function() if on() then M.Apply() end end, true)
	M.Apply()
end

ns.Module("actionbars", M)
