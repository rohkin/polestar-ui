-- The Personal Resource Display as the client builds it
-- (Blizzard_PersonalResourceDisplay.xml and .lua; Forever's Camelot file):
-- PersonalResourceDisplayFrame, an Edit Mode system (200 x 75) on UIParent,
-- not a nameplate. HealthBarsContainer.healthBar, PowerBar and
-- AlternatePowerBar (the Druid's mana in forms) on PersonalResourceStatusBar:
-- a StatusBar with an unnamed BACKGROUND atlas larger than the bar,
-- TextString, LeftText and RightText. The health bar carries the heal and
-- absorb textures, the power bar ManaCostPredictionBar, placed as the mixin
-- does (CompactUnitFrameUtil_UpdateFillBar: hidden at 0, else hung off the
-- previous texture and given a width), colours as it writes them
-- (SetStatusBarColor on every update; the cost bar's vertex colour, alpha
-- included). Values from stub.units.player: secret. In combat the bars
-- answer their size with secrets. The frame, its bars and every region are
-- guarded (stub_editmode.lua): Polestar: UI may only fade regions
-- (SetAlpha) and set fonts.
--
--   stub.prd({ heal, otherHeal, absorb, healAbsorb, cost, alt = true }): the player's state, and the mixin's update
--   stub.prdEdit({ size, width, health, power, padding, hideHealth, hidePower, hideAlt, classColor, barText })
--     Edit Mode's settings, through the mixin's setters (percent, px), then EDIT_MODE_LAYOUTS_UPDATED

require("stub_editmode")

local M = stub.Methods
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BG_ATLAS = "UI-HUD-CoolDownManager-Bar-BG"
local GREEN = { 0, 0.8, 0 } -- PERSONAL_RESOURCE_DISPLAY_DEFAULT_HEALTH_COLOR
local HEAL = { 0, 0.827, 0.765 } -- HEAL_PREDICTION_COLOR
local TEX_CALLS = { "SetPoint", "ClearAllPoints", "SetAllPoints", "Hide", "Show", "SetShown", "SetParent", "SetSize", "SetWidth", "SetHeight",
	"SetVertexColor", "SetTexture", "SetAtlas" }
local BAR_CALLS = { "SetStatusBarColor", "SetStatusBarTexture", "SetValue", "SetMinMaxValues", "SetForceShow" }
for _, c in ipairs(stub.SYSTEM_CALLS) do BAR_CALLS[#BAR_CALLS + 1] = c end

local s = { size = 100, width = 100, health = 15, power = 15, padding = 0 }
stub.prdState = s

local prd = CreateFrame("Frame", "PersonalResourceDisplayFrame", UIParent)
prd:SetSize(200, 75)
prd:SetPoint("CENTER", UIParent, "CENTER", 0, -150)

local function text(bar, key, point, x)
	local fs = bar:CreateFontString(nil, "OVERLAY")
	fs:SetFontObject(GameFontHighlightSmall)
	fs:SetPoint(point, bar, point, x, 0)
	fs:Hide()
	bar[key] = fs
end

local function statusBar(parent)
	local bar = CreateFrame("StatusBar", nil, parent)
	bar:SetStatusBarTexture(WHITE)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetColorTexture(0.05, 0.05, 0.05, 0.9)
	bg:SetAtlas(BG_ATLAS)
	bg:SetPoint("TOPLEFT", bar, "TOPLEFT", -2, 3)
	bg:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 6, -7)
	text(bar, "TextString", "RIGHT", -5)
	text(bar, "RightText", "RIGHT", -5)
	text(bar, "LeftText", "LEFT", 5)
	-- TextStatusBar:SetForceShow: the value as text.
	function bar.SetForceShow(self, on) self.forceShow = on end
	return bar, bg
end

local function region(bar, key, layer, sub, r, g, b, a)
	local t = bar:CreateTexture(nil, layer, nil, sub)
	t:SetColorTexture(r, g, b, a or 1)
	t:Hide()
	bar[key] = t
	return t
end

prd.HealthBarsContainer = CreateFrame("Frame", nil, prd)
local hc = prd.HealthBarsContainer
local health = statusBar(hc)
hc.healthBar = health
health:SetAllPoints(hc)
region(health, "myHealPrediction", "BORDER", 5, 1, 1, 1)
region(health, "otherHealPrediction", "BORDER", 5, 1, 1, 1)
region(health, "totalAbsorb", "BORDER", 5, 0.8, 0.9, 1)
region(health, "totalAbsorbOverlay", "BORDER", 6, 1, 1, 1, 0.5)
region(health, "myHealAbsorb", "ARTWORK", 1, 0.3, 0.1, 0.1)
region(health, "myHealAbsorbLeftShadow", "ARTWORK", 1, 0, 0, 0)
region(health, "myHealAbsorbRightShadow", "ARTWORK", 1, 0, 0, 0)
region(health, "overAbsorbGlow", "ARTWORK", 2, 1, 1, 1, 0.8)
region(health, "overHealAbsorbGlow", "ARTWORK", 2, 1, 0.3, 0.3, 0.8)
health.totalAbsorbOverlay:SetAllPoints(health.totalAbsorb)
health.overAbsorbGlow:SetPoint("TOPLEFT", health, "TOPRIGHT", -4, 1)
health.overAbsorbGlow:SetPoint("BOTTOMLEFT", health, "BOTTOMRIGHT", -4, -1)
health.overAbsorbGlow:SetWidth(8)
health.overHealAbsorbGlow:SetPoint("TOPRIGHT", health, "TOPLEFT", 2, 1)
health.overHealAbsorbGlow:SetPoint("BOTTOMRIGHT", health, "BOTTOMLEFT", 2, -1)
health.overHealAbsorbGlow:SetWidth(8)
for _, k in ipairs({ "myHealPrediction", "otherHealPrediction" }) do health[k]:SetVertexColor(HEAL[1], HEAL[2], HEAL[3]) end

prd.PowerBar = statusBar(prd)
local power = prd.PowerBar
region(power, "ManaCostPredictionBar", "ARTWORK", 0, 1, 1, 1)
power.ManaCostPredictionBar:SetPoint("TOPLEFT", power:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
power.ManaCostPredictionBar:SetPoint("BOTTOMLEFT", power:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
-- The builder/spender flash and the full-power pulse: the game's child frames.
power.FeedbackFrame = CreateFrame("Frame", nil, power)
power.FeedbackFrame:SetAllPoints(power)
power.FullPowerFrame = CreateFrame("Frame", nil, power)
power.FullPowerFrame:SetSize(86, 6)
power.FullPowerFrame:SetPoint("RIGHT", power, "RIGHT", 0, 0)

prd.AlternatePowerBar = statusBar(prd)
local alt = prd.AlternatePowerBar
alt:SetStatusBarColor(0, 0, 1)
alt:Hide()

prd.ClassFrameContainer = CreateFrame("Frame", nil, prd)
prd.ClassFrameContainer:SetSize(200, 15)
prd.ClassFrameContainer:Hide()

-- In combat the bars answer their size with secrets (they follow secret values).
for _, bar in ipairs({ health, power, alt }) do
	for _, name in ipairs({ "GetHeight", "GetWidth" }) do
		rawset(bar, name, function(self)
			if stub.inCombat then return stub.secret(M[name](self)) end
			return M[name](self)
		end)
	end
end

local function width() return 200 * s.width / 100 end
local function pad() return s.padding + 4 end

-- The mixin's layout: widths, heights, the power bar under health, the alt bar under both, the frame's height.
local function layout()
	local w = width()
	prd:SetScale(s.size / 100)
	prd:SetWidth(w)
	hc:SetSize(w, s.health)
	hc:ClearAllPoints()
	hc:SetPoint("TOP", prd, "TOP", 0, 0)
	hc:SetShown(not s.hideHealth)
	power:SetSize(w, s.power)
	power:ClearAllPoints()
	if s.hideHealth then power:SetPoint("TOP", prd, "TOP", 0, 0) else power:SetPoint("TOP", hc, "BOTTOM", 0, -pad()) end
	power:SetShown(not s.hidePower)
	alt:SetSize(w, s.power)
	alt:SetShown(s.alt and not s.hideAlt or false)
	alt:ClearAllPoints()
	if not s.hidePower then alt:SetPoint("TOP", power, "BOTTOM", 0, -pad())
	elseif not s.hideHealth then alt:SetPoint("TOP", hc, "BOTTOM", 0, -pad())
	else alt:SetPoint("TOP", prd, "TOP", 0, 0) end
	local h = 0
	if not s.hideHealth then h = h + s.health end
	if not s.hidePower then h = h + (s.hideHealth and 0 or pad()) + s.power end
	if alt:IsShown() then h = h + ((s.hidePower and s.hideHealth) and 0 or pad()) + s.power end
	prd:SetHeight(math.max(h, 15))
end

-- CompactUnitFrameUtil_UpdateFillBar.
local function fillBar(prev, t, amount, max, offset)
	if amount <= 0 then t:Hide() return prev end
	local w = width()
	t:ClearAllPoints()
	t:SetPoint("TOPLEFT", prev, "TOPRIGHT", (offset or 0) * w, 0)
	t:SetPoint("BOTTOMLEFT", prev, "BOTTOMRIGHT", (offset or 0) * w, 0)
	t:SetWidth(amount / max * w)
	t:Show()
	return t
end

local function barText(bar, v, max)
	for _, k in ipairs({ "TextString", "LeftText", "RightText" }) do bar[k]:Hide() end
	if not s.barText then return end
	bar.TextString:SetText(string.format("%d / %d", v, max))
	bar.TextString:Show()
end

-- The mixin's update: health and its colour, the predictions, power, cost, alt.
local function update()
	local r = stub.reveal
	local hp, max = UnitHealth("player"), UnitHealthMax("player")
	health:SetMinMaxValues(0, max)
	health:SetValue(hp)
	local c = GREEN
	if s.classColor then
		local _, file = UnitClass("player")
		local rc = RAID_CLASS_COLORS[file]
		c = rc and { rc.r, rc.g, rc.b } or GREEN
	end
	health:SetStatusBarColor(c[1], c[2], c[3])
	hp, max = r(hp), r(max)
	local fill = health:GetStatusBarTexture()
	local ha = math.min(s.healAbsorb or 0, hp)
	local heals = math.min((s.heal or 0) + (s.otherHeal or 0), max - hp + ha)
	local mine = math.min(s.heal or 0, heals)
	local absorb = math.min(s.absorb or 0, math.max(0, max - (hp - ha + heals)))
	health.overAbsorbGlow:SetShown((s.absorb or 0) > absorb)
	local haTex
	if ha > heals then haTex = fillBar(fill, health.myHealAbsorb, ha - heals, max, -(ha - heals) / max) else health.myHealAbsorb:Hide() end
	local t = fillBar(fill, health.myHealPrediction, mine, max, -ha / max)
	t = fillBar(t, health.otherHealPrediction, heals - mine, max)
	fillBar(haTex or t, health.totalAbsorb, absorb, max)
	barText(health, hp, max)

	local kind, token = UnitPowerType("player")
	local pc = PowerBarColor[token] or PowerBarColor[kind] or { r = 0, g = 0, b = 1 }
	power:SetStatusBarColor(pc.r, pc.g, pc.b)
	local pv, pmax = r(UnitPower("player")), r(UnitPowerMax("player"))
	local cost = s.cost or 0
	power:SetMinMaxValues(0, stub.secret(pmax))
	power:SetValue(stub.secret(pv - cost))
	-- The cost bar's colour, alpha included (POWERBAR_PREDICTION_COLOR_MANA).
	power.ManaCostPredictionBar:SetVertexColor(0.3, 0.6, 1, 1)
	if cost > 0 and pmax > 0 then
		power.ManaCostPredictionBar:SetWidth(cost / pmax * width())
		power.ManaCostPredictionBar:Show()
	else
		power.ManaCostPredictionBar:Hide()
	end
	barText(power, pv, pmax)

	-- Forever's Druid: the mana bar while the main bar shows another power.
	local mana = PowerBarColor.MANA
	alt:SetStatusBarColor(mana.r, mana.g, mana.b)
	alt:SetMinMaxValues(0, stub.secret(s.manaMax or 4000))
	alt:SetValue(stub.secret(s.mana or 2600))
	barText(alt, s.mana or 2600, s.manaMax or 4000)
	layout()
end

function stub.prd(o)
	for _, k in ipairs({ "heal", "otherHeal", "absorb", "healAbsorb", "cost", "alt", "mana", "manaMax" }) do s[k] = o[k] end
	update()
end

function stub.prdEdit(o)
	for k, v in pairs(o) do s[k] = v end
	prd.showClassColor = s.classColor -- the mixin's SetShowClassColor
	for _, bar in ipairs({ health, power, alt }) do bar:SetForceShow(s.barText) end
	update()
	stub.fire("EDIT_MODE_LAYOUTS_UPDATED")
end

update()

stub.guard(prd, stub.SYSTEM_CALLS)
for _, f in ipairs({ hc, prd.ClassFrameContainer, power.FeedbackFrame, power.FullPowerFrame }) do stub.guard(f, stub.SYSTEM_CALLS, "a PRD part") end
for name, bar in pairs({ healthBar = health, PowerBar = power, AlternatePowerBar = alt }) do
	stub.guard(bar, BAR_CALLS, name)
	stub.guard(bar:GetStatusBarTexture(), TEX_CALLS, name .. "'s fill")
	for _, r in ipairs({ bar:GetRegions() }) do
		if r ~= bar:GetStatusBarTexture() then stub.guard(r, r.kind == "Texture" and TEX_CALLS or nil, name .. "'s region") end
	end
end
