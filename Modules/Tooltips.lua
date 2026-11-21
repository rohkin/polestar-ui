-- Tooltips (docs/DESIGN.md, "Tooltips"): the game's own tooltips in
-- Polestar's look, restyled in place, never replaced, so every addon that
-- adds lines to them (AddLine, TooltipDataProcessor) still does. Their text
-- is the game's; only the art changes (docs/CLIENT.md, rule 15): the stock
-- border's pieces faded out with SetAlpha, a ground and hairline of ours
-- under them on the tooltip's NineSlice (so they hide with it on an embedded
-- tooltip), the health bar flat on a shade track, the comparison's
-- "Equipped" plate on our ground, and the tooltip fonts in Polestar's face at
-- the game's sizes. No key is written on a stock frame:
-- what is ours is kept in a weak table by tooltip. Switched off, all of it
-- is the game's again at once.

local ADDON, ns = ...
local Theme = Polestar.Theme

local NAMES = { "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "ItemRefShoppingTooltip1",
	"ItemRefShoppingTooltip2", "EmbeddedItemTooltip", "GameNoHeaderTooltip", "GameSmallHeaderTooltip" }
-- The tooltip font objects, each in the weight of a Polestar role.
local FONTS = { GameTooltipHeaderText = "heading", GameTooltipText = "body", GameTooltipTextSmall = "small" }
local BAR = "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill" -- the health bar's stock fill (GameTooltip.xml)

local looks = setmetatable({}, { __mode = "k" }) -- tooltip or plate -> { fill, edges, track | art, color }
local stockFonts = {}
local M = { noun = "tooltips" }

-- A style reset (SharedTooltip_SetBackdropStyle, every hide) can lay a new
-- layout's pieces: faded again.
local function fade(tip, a) ns.FadeNine(tip.NineSlice, a) end

-- Our ground (fill) and the four hairlines round `rel`, on frame `f`.
local function ground(f, rel)
	local l = { fill = f:CreateTexture(nil, "BACKGROUND", nil, -8) }
	l.fill:SetTexture(Theme.Media("white"))
	l.fill:SetAllPoints(rel)
	l.edges = ns.Hairlines(f, rel)
	return l
end

local function look(tip)
	local l = looks[tip]
	if l then return l end
	l = ground(tip.NineSlice, tip)
	local bar = tip.StatusBar
	if bar then
		l.track = bar:CreateTexture(nil, "BACKGROUND")
		l.track:SetTexture(Theme.Media("white"))
		l.track:SetAllPoints(bar)
	end
	looks[tip] = l
	return l
end

-- The ground: the scheme's bg where white text still reads on it (7:1), else
-- the fixed dark Theme.TIP_GROUND (a light look's tooltip stays dark; the
-- game's lines and Theme.TipColor assume it). Solid; follows the scheme live.
local WHITE = { 1, 1, 1 }
local function groundRGB()
	local c = { Theme.Color("bg") }
	if Theme.Contrast(WHITE, c) >= 7 then return c[1], c[2], c[3] end
	return Theme.TIP_GROUND[1], Theme.TIP_GROUND[2], Theme.TIP_GROUND[3]
end

local function paintGround(l, on)
	local r, g, b = groundRGB()
	l.fill:SetVertexColor(r, g, b, 1)
	l.fill:SetShown(on)
	ns.PaintHairlines(l.edges, on, Theme.Color("border"))
end

-- The comparison's "Equipped" plate (ShoppingTooltipTemplate's CompareHeader,
-- GameTooltip.xml): its atlas (the plate's first region) faded, our ground
-- and hairline under its label, the label in text. The game sets the label's
-- text and the plate's width on each comparison, never this art or colour.
local function plate(tip, on)
	local h = rawget(tip, "CompareHeader") -- only the comparison tooltips have one
	if not h then return end
	local l = looks[h]
	if not l then
		local art = h:GetRegions()
		l = ground(h, h)
		l.art, l.color = art, { h.Label:GetTextColor() }
		looks[h] = l
	end
	l.art:SetAlpha(on and 0 or 1)
	paintGround(l, on)
	if on then h.Label:SetTextColor(Theme.Color("text")) else h.Label:SetTextColor(unpack(l.color)) end
end

local function paint(tip, on)
	local l = look(tip)
	fade(tip, on and 0 or 1)
	paintGround(l, on)
	if l.track then
		-- The fill's colour stays the game's (health, HealthBar_OnValueChanged).
		tip.StatusBar:SetStatusBarTexture(on and Theme.Media("white") or BAR)
		local r, g, b = Theme.Color("shade")
		l.track:SetVertexColor(r, g, b, 0.6)
		l.track:SetShown(on)
	end
	plate(tip, on)
end

function M.Apply()
	local on = ns.Enabled("tooltips")
	for _, name in ipairs(NAMES) do
		local tip = _G[name]
		if tip then paint(tip, on) end
	end
	for name, role in pairs(FONTS) do
		local f = _G[name]
		if f then
			stockFonts[name] = stockFonts[name] or { f:GetFont() }
			local s = stockFonts[name]
			Theme.SetFace(f, on and (Theme.FontSpec(role)) or s[1], s[2], s[3] or "")
		end
	end
end

function M.Enable()
	hooksecurefunc("SharedTooltip_SetBackdropStyle", function(tip)
		if looks[tip] and ns.Enabled("tooltips") then fade(tip, 0) end
	end)
	Theme.OnChanged(function() if ns.Enabled("tooltips") then M.Apply() end end)
	M.Apply()
end

ns.Module("tooltips", M)
