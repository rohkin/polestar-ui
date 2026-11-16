-- Cooldown Viewer (docs/windows/cooldowns.md): the game's own cooldown and
-- tracked buff viewers (EssentialCooldownViewer, UtilityCooldownViewer,
-- BuffIconCooldownViewer, BuffBarCooldownViewer) in the HUD's look, restyled
-- in place, never rebuilt. The four are Edit Mode systems and their items
-- are pooled frames the game (and its secure aura map) writes into
-- (docs/CLIENT.md, rules 15 and 17): their place, Orientation, Icon Size,
-- Padding, Opacity, Bar Content, Bar Width and what shows them stay the
-- game's. On each item only its art changes: the icon unmasked and cropped
-- square, the game's overlay faded, textures of ours added (a ground and a
-- 1px hairline, as the action buttons), the sweep made square (the user's
-- leave, rule 17), the countdown, charges, stacks, name and time in
-- Polestar's faces (never read: secret in combat, rule 3); on a buff bar a
-- track and a flat fill of ours whose edge hangs on the game's fill. The
-- debuff border, range shadow, flash and spell alert stay the game's. What
-- is ours is kept in a weak table; no key is written on a stock frame.

local ADDON, ns = ...
local Theme = Polestar.Theme
local H = ns.HUD

local M = { noun = "cooldown viewer" }
local KEY = "cooldowns"
local VIEWERS = { "EssentialCooldownViewer", "UtilityCooldownViewer", "BuffIconCooldownViewer", "BuffBarCooldownViewer" }
local CROP = 0.08 -- the icon's baked border, cropped as ns.GameIcon does
local OVERLAY = "UI-HUD-CoolDownManager-IconOverlay" -- the unnamed rounded frame over each icon
local SWIPE = "Interface\\HUD\\UI-HUD-CoolDownManager-Icon-Swipe" -- the templates' rounded sweep (set in XML only)
-- The game lays items out at Edit Mode's Padding less 4 (GetAdditionalPaddingOffset):
-- frames overlap 2 at the default Padding 2, the rounded mask inside each makes the gap.
-- Our tile (ground, hairline, sweep) sits INSET inside the item, the icon a unit
-- further in, so the gap shows and the hairline lies on the ground, not on the art.
local INSET = 2
-- Each icon viewer's item size, and our square sweep for it: white with an INSET margin.
local SIZES = { EssentialCooldownViewer = 50, UtilityCooldownViewer = 30, BuffIconCooldownViewer = 40 }
local function sweep(size) return "Interface\\AddOns\\" .. ADDON .. "\\Media\\cooldown-swipe-" .. size end

local looks = setmetatable({}, { __mode = "k" }) -- stock item -> its textures of ours and what it was
local driver, started

local function on() return ns.Enabled(KEY) end

local function tex(f, layer, sub)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetTexture(Theme.Media("white"))
	return t
end

local function byAtlas(f, atlas)
	for _, r in ipairs({ f:GetRegions() }) do
		if r.GetAtlas and r:GetAtlas() == atlas then return r end
	end
end

-- An item's parts, found once: pooled frames are released and acquired
-- again, and keep what we added.
local function look(item, size)
	local l = looks[item]
	if l then return l end
	local bar, cd = rawget(item, "Bar"), rawget(item, "Cooldown")
	local holder = bar and rawget(item, "Icon") or item -- the frame holding the icon's regions
	local icon = holder and rawget(holder, "Icon")
	if not (icon and (bar or cd)) then return end
	l = { icon = icon, mask = icon.GetMaskTexture and icon:GetMaskTexture(1), overlay = byAtlas(holder, OVERLAY), cd = cd, size = size, fonts = {} }
	l.ground = tex(holder, "BACKGROUND", -8)
	l.ground:SetPoint("TOPLEFT", holder, "TOPLEFT", INSET, -INSET)
	l.ground:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -INSET, INSET)
	l.edges = ns.Hairlines(holder, l.ground, function() return tex(holder, "OVERLAY", 7) end)
	-- Ours in place of the game's rounded mask (a mask swap, rule 17): the icon inside the hairline.
	l.square = holder:CreateMaskTexture()
	l.square:SetTexture(Theme.Media("white"), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	l.square:SetPoint("TOPLEFT", holder, "TOPLEFT", INSET + 1, -INSET - 1)
	l.square:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -INSET - 1, INSET + 1)
	local function font(fs, role) if fs then l.fonts[#l.fonts + 1] = { fs, role } end end
	if cd then font(cd.GetCountdownFontString and cd:GetCountdownFontString(), "number") end
	local charges, stacks = rawget(item, "ChargeCount"), rawget(item, "Applications")
	font(charges and rawget(charges, "Current"), "number")
	font(stacks and rawget(stacks, "Applications"), "number")
	if bar then
		font(rawget(holder, "Applications"), "number")
		font(rawget(bar, "Name"), "label")
		font(rawget(bar, "Duration"), "number")
		-- Under the game's name, time and pip (the bar's OVERLAY), over its
		-- fill. Our fill's edge is the game's: no value or size read (rule 3).
		local fill = bar:GetStatusBarTexture()
		l.bar, l.faded = bar, { rawget(bar, "BarBG"), rawget(bar, "Pip") }
		l.track = tex(bar, "BACKGROUND", 7)
		l.track:SetAllPoints(bar)
		l.fill = tex(bar, "ARTWORK", 7)
		l.fill:SetPoint("TOPLEFT", fill, "TOPLEFT", 0, 0)
		l.fill:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 0)
		l.barEdges = ns.Hairlines(bar, bar, function() return tex(bar, "OVERLAY", 7) end)
	end
	looks[item] = l
	return l
end

local function paint(l, shown)
	-- No mask found (a client without GetMaskTexture): the icon stays the game's rounded one.
	if l.mask and shown ~= (l.squared or false) then
		if shown then
			l.icon:RemoveMaskTexture(l.mask)
			l.icon:AddMaskTexture(l.square)
			l.icon:SetTexCoord(CROP, 1 - CROP, CROP, 1 - CROP)
		else
			l.icon:RemoveMaskTexture(l.square)
			l.icon:AddMaskTexture(l.mask)
			l.icon:SetTexCoord(0, 1, 0, 1)
		end
		if l.cd and l.cd.SetSwipeTexture then l.cd:SetSwipeTexture(shown and l.size and sweep(l.size) or SWIPE, 0, 0, 0, 0.7) end
		l.squared = shown
	end
	if l.overlay then l.overlay:SetAlpha(shown and 0 or 1) end
	for _, f in ipairs(l.fonts) do H.Face(f[1], f[2], shown) end
	local r, g, b = Theme.Color("bg")
	local a = H.GroundAlpha()
	l.ground:SetVertexColor(r, g, b, a)
	l.ground:SetShown(shown)
	local br, bg, bb, ba = Theme.Color("border")
	ns.PaintHairlines(l.edges, shown, br, bg, bb, ba)
	if l.bar then
		for _, t in pairs(l.faded) do t:SetAlpha(shown and 0 or 1) end
		l.track:SetVertexColor(r, g, b, a)
		l.track:SetShown(shown)
		l.fill:SetTexture(H.FillTexture())
		local fr, fg, fb = H.FillColor("player")
		l.fill:SetVertexColor(fr, fg, fb, 1)
		l.fill:SetShown(shown)
		ns.PaintHairlines(l.barEdges, shown, br, bg, bb, ba)
	end
end

-- A viewer's items not yet dressed (they are its children with a Cooldown
-- or a Bar; the pandemic effects and Edit Mode's Selection have neither).
local function dressNew(size, c, ...)
	if not c then return end
	if not looks[c] and (rawget(c, "Cooldown") or rawget(c, "Bar")) then
		local l = look(c, size)
		if l then paint(l, true) end
	end
	return dressNew(size, ...)
end

-- Each frame: items the game acquired since (a relayout, a new aura, Edit
-- Mode's samples), dressed before they have shown long. Mid-fight too: only
-- textures and faces on plain frames, nothing read.
local function update()
	for _, name in ipairs(VIEWERS) do
		local v = rawget(_G, name)
		if v and v:IsVisible() then dressNew(SIZES[name], v:GetChildren()) end
	end
end

function M.Apply()
	if not started then return end
	local shown = on()
	for _, l in pairs(looks) do paint(l, shown) end
	driver:SetShown(shown)
	if shown then update() end
end

function M.Enable()
	if not rawget(_G, "EssentialCooldownViewer") then return end
	started = true
	driver = CreateFrame("Frame", nil, UIParent)
	driver:SetScript("OnUpdate", update)
	-- Icon Size scales the items: the hairlines one pixel again.
	EventRegistry:RegisterCallback("EditMode.Exit", M.Apply, M)
	Polestar.RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", M.Apply)
	Theme.OnChanged(function() if on() then M.Apply() end end, true)
	M.Apply()
end

ns.Module(KEY, M)
