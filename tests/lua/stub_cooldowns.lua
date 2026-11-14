-- The Cooldown Viewer as the client builds it on Forever
-- (Blizzard_CooldownViewer: CooldownViewer.xml, CooldownViewer.lua): four
-- Edit Mode systems on CooldownViewerTemplate (EssentialCooldownViewer,
-- UtilityCooldownViewer, BuffIconCooldownViewer, BuffBarCooldownViewer),
-- shown with the cooldownViewerEnabled CVar or while Edit Mode is open, each
-- with a frame pool of its item template whose items are the viewer's
-- children, laid out as GridLayoutFrame does (Orientation, Icon Size as the
-- item's scale, Padding; the bars stacked, Bar Width, Bar Content). Items
-- carry the templates' regions: the icon under an unnamed mask (drawn as a
-- disc), the unnamed overlay (its atlas), OutOfRange, a Cooldown (its sweep
-- drawn as a texture: the stock file as a disc, a white one as a square),
-- the countdown, charges and stacks (never read by us: GetText is guarded,
-- they are secret in combat), the debuff border; a buff bar's StatusBar
-- (its fill tinted orange in XML), BarBG, Pip, Name and Duration. A non-item
-- child (the pandemic effects) and Edit Mode's Selection sit beside the
-- items. Every viewer, item and region is guarded (stub_editmode.lua).
--
--   stub.cdm({ essential = {...}, utility = {...}, buffs = {...}, bars = {...} })
--     icon items: { icon = {r, g, b}, cd = fraction left, time = "12", charges = "2", stacks = "3", debuff = true }
--     bars: { icon = {r, g, b}, name = "Ice Barrier", left = 15, duration = 30, stacks = "2" }
--   stub.cdmRelayout()   every viewer releases its items and acquires them again
--   stub.editCooldowns(viewer, { iconSize = 120, horizontal = false, padding = 2, barWidth = 260, barContent = "NameOnly", timer = false })

require("stub_editmode")

local M = stub.Methods
local CALLS = stub.SYSTEM_CALLS
local DISC = "Interface\\AddOns\\Polestar\\Media\\UI\\circle"
local RING = "Interface\\AddOns\\Polestar\\Media\\UI\\skin-ring"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local SWIPE = "Interface\\HUD\\UI-HUD-CoolDownManager-Icon-Swipe"

-- A region's guard: what Edit Mode's rule forbids, but SetAlpha (rule 17
-- lets the art fade). A text's: GetText too (secret in combat; never read).
local REGION = {}
for _, k in ipairs(CALLS) do if k ~= "SetAlpha" then REGION[#REGION + 1] = k end end
local TEXT = { "GetText" }
for _, k in ipairs(REGION) do TEXT[#TEXT + 1] = k end

-- Masks as the client keeps them (stub_actionbars.lua has the same).
function M.GetMaskTexture(self, i) if i == 1 then return self.mask end end
function M.RemoveMaskTexture(self, m)
	if self.mask ~= m then error("RemoveMaskTexture: not a mask of this texture", 2) end
	self.mask = nil
end
function M.AddMaskTexture(self, m)
	if self.mask == m then error("AddMaskTexture: already masked", 2) end
	self.mask = m
end

-- A Cooldown: its sweep drawn as a texture under the countdown, over the
-- swipe file's opaque part (Polestar_UI's cooldown-swipe-<n>: an n-texel
-- white square with a 2-texel transparent margin, on an n-unit item; the
-- preview cannot load it, so white stands in), covering the fraction left
-- from the top down.
local FONTS = { GameFontHighlightHugeOutline = 20, GameFontHighlightOutline = 12 }
local function sweep(cd)
	local t = cd.swipeTex
	local m = tostring(cd.swipe):find("cooldown%-swipe%-%d+$") and 2 or 0
	t:SetTexture(cd.swipe == SWIPE and DISC or m > 0 and WHITE or cd.swipe)
	t:ClearAllPoints()
	t:SetPoint("TOPLEFT", cd, "TOPLEFT", m, -m)
	t:SetPoint("TOPRIGHT", cd, "TOPRIGHT", -m, -m)
	t:SetHeight((cd.size - 2 * m) * (cd.left or 1))
	local c = cd.swipeColor or { 0, 0, 0, 0.7 }
	t:SetVertexColor(c[1], c[2], c[3], c[4])
	t:SetShown(cd.left ~= nil and cd.drawSwipe ~= false)
end
function M.SetSwipeTexture(self, file, r, g, b, a)
	self.swipe = file
	if r then self.swipeColor = { r, g, b, a } end
	if self.swipeTex then sweep(self) end
end
function M.SetSwipeColor(self, r, g, b, a) self.swipeColor = { r, g, b, a } end
function M.SetDrawSwipe(self, on) self.drawSwipe = on end
function M.GetCountdownFontString(self) return self.countdown end
function M.SetCountdownFont(self, name) self.countdown:SetFont(STANDARD_TEXT_FONT, FONTS[name] or 12, "OUTLINE") end
function M.SetHideCountdownNumbers(self, hide) self.countdown:SetShown(not hide) end

local function color(f, layer, r, g, b, a, sub)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetColorTexture(r, g, b, a or 1)
	return t
end
local function text(f, size, layer)
	local fs = f:CreateFontString(nil, layer or "OVERLAY")
	fs:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE")
	return fs
end

local function guard(o, calls, label) stub.guard(o, calls, label) end

-- The icon, its mask and the overlay on `f` (an item, or a bar item's Icon frame).
local function icon(f, label)
	f.Icon = color(f, "ARTWORK", 0.5, 0.5, 0.5, 1)
	f.Icon:SetAllPoints(f)
	local mask = f:CreateMaskTexture()
	mask:SetAllPoints(f)
	mask:SetTexture(DISC)
	mask.psStock = true -- the game's rounded mask (scenes tell it from ours)
	f.Icon:AddMaskTexture(mask)
	local w = f:GetWidth()
	local ov = f:CreateTexture(nil, "OVERLAY")
	ov:SetTexture(RING)
	ov:SetVertexColor(0.55, 0.5, 0.42, 1)
	ov:SetAtlas("UI-HUD-CoolDownManager-IconOverlay")
	ov:SetPoint("TOPLEFT", f, "TOPLEFT", -9 * w / 50, 8 * w / 50)
	ov:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 9 * w / 50, -8 * w / 50)
	guard(f.Icon, REGION, label .. ".Icon")
	guard(mask, REGION, label .. "'s mask")
	guard(ov, REGION, label .. "'s overlay")
end

local TEMPLATES = {
	EssentialCooldownViewer = { size = 50, font = "GameFontHighlightHugeOutline", count = 12, charges = true },
	UtilityCooldownViewer = { size = 30, font = "GameFontHighlightOutline", count = 10, charges = true },
	BuffIconCooldownViewer = { size = 40, font = "GameFontHighlightOutline", count = 12, buff = true },
	BuffBarCooldownViewer = { bar = true },
}

local function iconItem(v, t)
	local label = v:GetName() .. "'s item"
	local it = CreateFrame("Frame", nil, v)
	it:SetSize(t.size, t.size)
	icon(it, label)
	it.OutOfRange = color(it, "OVERLAY", 0, 0, 0, 0.5)
	it.OutOfRange:SetAllPoints(it)
	it.OutOfRange:Hide()
	guard(it.OutOfRange, REGION, label .. ".OutOfRange")
	local cd = CreateFrame("Cooldown", nil, it)
	cd:SetAllPoints(it)
	cd.swipe, cd.reverse = SWIPE, t.buff
	cd.swipeTex = cd:CreateTexture(nil, "ARTWORK")
	cd.size = t.size
	cd.countdown = text(cd, 12)
	cd.countdown:SetPoint("CENTER", cd, "CENTER", 0, 0)
	cd:SetCountdownFont(t.font) -- CooldownViewerItemMixin:OnLoad, once
	it.Cooldown = cd
	guard(cd, CALLS, label .. ".Cooldown")
	guard(cd.countdown, TEXT, label .. "'s countdown")
	local holder = CreateFrame("Frame", nil, it)
	holder:SetAllPoints(it)
	local fs = text(holder, t.count)
	fs:SetPoint("BOTTOMRIGHT", it, "BOTTOMRIGHT", -2, 2)
	if t.charges then it.ChargeCount, holder.Current = holder, fs else it.Applications, holder.Applications = holder, fs end
	guard(holder, CALLS, label .. "'s counts")
	guard(fs, TEXT, label .. "'s count")
	if t.buff then
		it.DebuffBorder = CreateFrame("Frame", nil, it)
		it.DebuffBorder:SetPoint("TOPLEFT", it, "TOPLEFT", -3, 3)
		it.DebuffBorder:SetPoint("BOTTOMRIGHT", it, "BOTTOMRIGHT", 3, -3)
		it.DebuffBorder.Texture = color(it.DebuffBorder, "OVERLAY", 0.8, 0.1, 0.1, 0.9)
		it.DebuffBorder.Texture:SetAllPoints(it.DebuffBorder)
		guard(it.DebuffBorder, CALLS, label .. ".DebuffBorder")
		guard(it.DebuffBorder.Texture, REGION, label .. ".DebuffBorder.Texture")
	end
	guard(it, CALLS, label)
	return it
end

local function barItem(v)
	local label = v:GetName() .. "'s item"
	local it = CreateFrame("Frame", nil, v)
	it:SetSize(220, 30)
	local ic = CreateFrame("Frame", nil, it)
	ic:SetSize(30, 30)
	ic:SetPoint("LEFT", it, "LEFT", 0, 0)
	ic:SetFrameLevel(512)
	icon(ic, label .. ".Icon")
	ic.Applications = text(ic, 10)
	ic.Applications:SetPoint("BOTTOMRIGHT", ic, "BOTTOMRIGHT", -2, 2)
	it.Icon = ic
	local bar = CreateFrame("StatusBar", nil, it)
	bar:SetFrameLevel(511)
	bar:SetHeight(19)
	bar:SetPoint("LEFT", ic, "RIGHT", 2, 0)
	bar:SetPoint("RIGHT", it, "RIGHT", 0, 0)
	bar:SetStatusBarTexture(WHITE)
	bar:SetStatusBarColor(1, 0.5, 0.25)
	bar.BarBG = color(bar, "BACKGROUND", 0.1, 0.07, 0.04, 0.9)
	bar.BarBG:SetPoint("TOPLEFT", bar, "TOPLEFT", -2, 2)
	bar.BarBG:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 4, -7)
	bar.Pip = color(bar, "OVERLAY", 1, 0.9, 0.6, 1)
	bar.Pip:SetSize(4, 22)
	bar.Pip:SetPoint("CENTER", bar:GetStatusBarTexture(), "RIGHT", 0, -1) -- OnLoad
	bar.Name = text(bar, 12)
	bar.Name:SetJustifyH("LEFT")
	bar.Name:SetPoint("TOPLEFT", bar, "TOPLEFT", 5, 0)
	bar.Name:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -25, 0)
	bar.Duration = text(bar, 12)
	bar.Duration:SetPoint("RIGHT", bar, "RIGHT", -8, 0)
	it.Bar = bar
	it.DebuffBorder = CreateFrame("Frame", nil, it)
	it.DebuffBorder:SetAllPoints(ic)
	it.DebuffBorder:Hide()
	guard(ic, CALLS, label .. ".Icon")
	guard(ic.Applications, TEXT, label .. "'s stacks")
	guard(bar, { "SetStatusBarTexture", "SetStatusBarColor", "SetMinMaxValues", "SetValue", unpack(CALLS) }, label .. ".Bar")
	guard(bar:GetStatusBarTexture(), REGION, label .. "'s fill")
	for _, k in ipairs({ "BarBG", "Pip" }) do guard(bar[k], REGION, label .. ".Bar." .. k) end
	for _, k in ipairs({ "Name", "Duration" }) do guard(bar[k], TEXT, label .. ".Bar." .. k) end
	guard(it.DebuffBorder, CALLS, label .. ".DebuffBorder")
	guard(it, CALLS, label)
	return it
end

-- Fill an item as the game's RefreshData does.
local function fill(it, d, bar)
	local c = d.icon or { 0.5, 0.5, 0.5 }
	if bar then
		local b = it.Bar
		it.Icon.Icon:SetColorTexture(c[1], c[2], c[3], 1)
		it.Icon.Applications:SetText(d.stacks or "")
		b:SetMinMaxValues(0, d.duration or 1)
		b:SetValue(d.left or 0)
		b.Name:SetText(d.name or "")
		b.Duration:SetText(d.left and string.format("%.1f", d.left) or "")
		b.Pip:SetShown(d.left ~= nil)
		return
	end
	it.Icon:SetColorTexture(c[1], c[2], c[3], 1)
	it.Icon:SetDesaturated(d.desat == true)
	local cd = it.Cooldown
	cd.left = d.cd
	cd:SetSwipeColor(0, 0, 0, d.cd and 0.7 or 0)
	sweep(cd)
	cd.countdown:SetText(d.time or "")
	if rawget(it, "ChargeCount") then it.ChargeCount.Current:SetText(d.charges or "") end
	if rawget(it, "Applications") then it.Applications.Applications:SetText(d.stacks or "") end
	if rawget(it, "DebuffBorder") then it.DebuffBorder:SetShown(d.debuff == true) end
end

stub.cooldownViewers = {}
local order = { "EssentialCooldownViewer", "UtilityCooldownViewer", "BuffIconCooldownViewer", "BuffBarCooldownViewer" }
local spots = { EssentialCooldownViewer = { 0, 300 }, UtilityCooldownViewer = { 0, 250 }, BuffIconCooldownViewer = { 0, 370 }, BuffBarCooldownViewer = { -330, 300 } }
local data = {}
local SAMPLES = {
	EssentialCooldownViewer = { { icon = { 0.75, 0.3, 0.2 } }, { icon = { 0.3, 0.5, 0.85 } }, { icon = { 0.85, 0.7, 0.25 } } },
	UtilityCooldownViewer = { { icon = { 0.4, 0.7, 0.35 } }, { icon = { 0.6, 0.35, 0.75 } } },
	BuffIconCooldownViewer = { { icon = { 0.3, 0.65, 0.7 } }, { icon = { 0.75, 0.3, 0.2 } } },
	BuffBarCooldownViewer = { { icon = { 0.85, 0.7, 0.25 }, name = "Buff Bar", left = 20, duration = 30 } },
}

local function shouldShow(v) return GetCVarBool("cooldownViewerEnabled") or stub.cdmEditing end

-- CooldownViewerMixin:RefreshLayout: release every item, acquire them again
-- (the pool hands back released frames first), lay them out.
local function relayout(v)
	local t = TEMPLATES[v:GetName()]
	for _, it in ipairs(v.active) do
		it:Hide()
		it:ClearAllPoints()
		table.insert(v.free, it)
	end
	v.active = {}
	local list = data[v:GetName()] or {}
	if stub.cdmEditing and #list == 0 then list = SAMPLES[v:GetName()] end -- SetEditModeData
	local s = v.iconScale
	local w, h = t.bar and v.barWidth or t.size, t.bar and 30 or t.size
	for i, d in ipairs(list) do
		local it = table.remove(v.free, 1) or (t.bar and barItem(v) or iconItem(v, t))
		if t.bar then
			it:SetWidth(v.barWidth) -- SetBarWidth
			local ic, name, bar = it.Icon, it.Bar.Name, it.Bar
			ic:SetShown(v.barContent ~= "NameOnly")
			name:SetShown(v.barContent ~= "IconOnly")
			if v.barContent == "NameOnly" then bar:SetPoint("LEFT", ic, "LEFT", 0, 0) else bar:SetPoint("LEFT", ic, "RIGHT", 2, 0) end
			it.Bar.Duration:SetShown(v.timer)
		else
			it.Cooldown:SetHideCountdownNumbers(not v.timer)
		end
		it:SetScale(s)
		local step = (v.horizontal and w or h) * s + v.padding + v.offset
		if v.horizontal then it:SetPoint("TOPLEFT", v, "TOPLEFT", (i - 1) * step / s, 0) else it:SetPoint("TOPLEFT", v, "TOPLEFT", 0, -(i - 1) * step / s) end
		fill(it, d, t.bar)
		it:Show()
		v.active[i] = it
	end
	local n = math.max(#list, 1)
	local pad = v.padding + v.offset
	if v.horizontal then v:SetSize(n * (w * s + pad) - pad, h * s) else v:SetSize(w * s, n * (h * s + pad) - pad) end
	v:SetShown(shouldShow(v))
end

for _, name in ipairs(order) do
	local v = CreateFrame("Frame", name, UIParent)
	v.active, v.free = {}, {}
	-- The preset layouts' Padding (EditModePresetLayouts.lua), laid out less 4, the bars less 2 (GetAdditionalPaddingOffset).
	v.iconScale, v.timer = 1, true
	v.padding = (name == "EssentialCooldownViewer" or name == "UtilityCooldownViewer") and 2 or 5
	v.offset = name == "BuffBarCooldownViewer" and -2 or -4
	v.horizontal = name ~= "BuffBarCooldownViewer"
	v.barWidth, v.barContent = 220, "IconAndName"
	v:SetPoint("BOTTOM", UIParent, "BOTTOM", spots[name][1], spots[name][2])
	v:SetSize(50, 50)
	v:Hide()
	-- Beside the items: the pandemic effects' pooled frame and Edit Mode's Selection.
	local fx = CreateFrame("Frame", nil, v)
	fx:Hide()
	v.Selection = CreateFrame("Frame", nil, v)
	v.Selection:SetAllPoints(v)
	v.Selection:Hide()
	guard(fx, CALLS, name .. "'s pandemic effect")
	guard(v.Selection, CALLS, name .. ".Selection")
	guard(v, CALLS)
	stub.secureNames[name] = true
	stub.cooldownViewers[#stub.cooldownViewers + 1] = v
end

function stub.cdmRelayout()
	for _, v in ipairs(stub.cooldownViewers) do relayout(v) end
end

function stub.cdm(d)
	data = {
		EssentialCooldownViewer = d.essential, UtilityCooldownViewer = d.utility,
		BuffIconCooldownViewer = d.buffs, BuffBarCooldownViewer = d.bars,
	}
	stub.setCVar("cooldownViewerEnabled", "1")
	stub.cdmRelayout()
end

-- Edit Mode's viewer settings (EditModeCooldownViewerSystemMixin): each
-- setting runs RefreshLayout.
function stub.editCooldowns(name, o)
	local v = _G[name]
	if o.iconSize then v.iconScale = o.iconSize / 100 end
	if o.horizontal ~= nil then v.horizontal = o.horizontal end
	if o.padding then v.padding = o.padding end
	if o.barWidth then v.barWidth = o.barWidth end
	if o.barContent then v.barContent = o.barContent end
	if o.timer ~= nil then v.timer = o.timer end
	relayout(v)
	stub.fire("EDIT_MODE_LAYOUTS_UPDATED")
end

-- Edit Mode shows every viewer, empty ones with sample items.
local enter, exit = stub.enterEditMode, stub.exitEditMode
function stub.enterEditMode()
	stub.cdmEditing = true
	stub.cdmRelayout()
	for _, v in ipairs(stub.cooldownViewers) do v.Selection:Show() end
	enter()
end
function stub.exitEditMode()
	stub.cdmEditing = false
	stub.cdmRelayout()
	for _, v in ipairs(stub.cooldownViewers) do v.Selection:Hide() end
	exit()
end
