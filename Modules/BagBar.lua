-- Bag bar (docs/windows/bagbar.md): the game's backpack and bag slot buttons
-- in the action buttons' look (ns.ButtonLook, Modules/ActionBars.lua),
-- restyled in place, never rebuilt. BagsBar is an Edit Mode system
-- (docs/CLIENT.md, rule 17): its place, size, orientation, direction and
-- padding stay the game's; clicks, drag and drop, equipping a bag and the
-- tooltips stay the buttons' own. The bar's frame art and dividers are faded; the open-bag
-- highlight is faded and lights our accent instead (while our Bags window
-- shows, when it is on: the parked stock bags never light it). The game
-- re-sets the hover's alpha with every icon (UpdateTextures), so the driver
-- fades it again. Nothing is written on a stock frame; switched off, live,
-- everything is the game's again.

local ADDON, ns = ...
local Theme = Polestar.Theme

local M = { noun = "bag bar" }
local BUTTONS = { "MainMenuBarBackpackButton", "CharacterBag0Slot", "CharacterBag1Slot", "CharacterBag2Slot",
	"CharacterBag3Slot", "CharacterReagentBag0Slot", "KeyRingButton" }

local started, driver

local function on() return ns.Enabled("bagbar") end

-- Our Bags window open lights every slot (it shows them all); else the game's own highlight.
local function lit(b)
	if ns.Enabled("bags") and rawget(_G, "PolestarUIBags") then return PolestarUIBags:IsShown() end
	local h = rawget(b, "SlotHighlightTexture")
	return h and h:IsShown()
end

-- The dividers between the buttons (BagsBarMixin:UpdateDividers, Camelot's
-- useDividers): pooled frames the bar acquires again with each Layout.
local function dividers(a)
	for _, k in ipairs({ "HorizontalDividersPool", "VerticalDividersPool" }) do
		local pool = rawget(BagsBar, k)
		if pool then
			for d in pool:EnumerateActive() do
				if d:GetAlpha() ~= a then d:SetAlpha(a) end
			end
		end
	end
end

local function each(fn)
	for _, n in ipairs(BUTTONS) do
		local b = rawget(_G, n)
		if b then fn(b) end
	end
end

function M.Apply()
	if not started then return end
	local shown = on()
	each(function(b)
		ns.ButtonLook.paint(b, shown, lit)
		local h = rawget(b, "SlotHighlightTexture")
		if h then h:SetAlpha(shown and 0 or 1) end
		local hl = b:GetHighlightTexture()
		-- Off: UpdateTextures' own alpha for its hover.
		if hl and not shown then hl:SetAlpha(0.4) end
	end)
	local art = rawget(BagsBar, "BorderArt")
	if art then art:SetAlpha(shown and 0 or 1) end
	dividers(shown and 0 or 1)
	driver:SetShown(shown)
end

local function update()
	each(function(b)
		local hl = b:GetHighlightTexture()
		if hl and hl:GetAlpha() ~= 0 then hl:SetAlpha(0) end
		ns.ButtonLook.tick(b)
	end)
	dividers(0)
end

function M.Enable()
	if not (rawget(_G, "BagsBar") and ns.ButtonLook) then return end
	started = true
	driver = CreateFrame("Frame", nil, UIParent)
	driver:SetScript("OnUpdate", update)
	-- Edit Mode's Size scales the bar: the hairlines one pixel again.
	EventRegistry:RegisterCallback("EditMode.Exit", M.Apply, M)
	Polestar.RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", M.Apply)
	Theme.OnChanged(function() if on() then M.Apply() end end, true)
	M.Apply()
end

ns.Module("bagbar", M)
