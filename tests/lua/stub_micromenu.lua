-- The game's micro menu as Forever builds it (Blizzard_MicroMenu: Camelot
-- MainMenuBarMicroMenu.xml and MicroMenuContainerOverrides.lua, Mainline
-- MainMenuBarMicroButtons.xml/.lua): MicroMenuContainer (an Edit Mode
-- system) holding MicroMenu (its frame art BorderArt and BackgroundArt) and
-- Forever's fourteen buttons, each with MainMenuBarMicroButton's regions
-- (Background, PushedBackground, the icon as its normal, pushed, disabled
-- and highlight textures, FlashBorder, NotificationOverlay), the Character
-- button's Portrait and the game menu's MainMenuBarPerformanceBar. Colour
-- textures stand in for the atlases (each keeps its atlas name). The mixin's
-- own writes are stub calls a scene makes (stub.micro*): hover alphas,
-- pushed/normal, disable, the alert pulse (UIFrameFlash's alpha), the
-- notification. A micro button a window stub made already (the doors) is
-- dressed in place. Everything is guarded (stub_editmode.lua).

require("stub_editmode")

local M = stub.Methods
local CALLS = stub.SYSTEM_CALLS
M.GetButtonState = M.GetButtonState or function(self) return self.buttonState or "NORMAL" end
M.SetButtonState = M.SetButtonState or function(self, s) self.buttonState = s end
M.GetDisabledTexture = M.GetDisabledTexture or function(self) return self.disabledTexture end
if not stub.mouseOverHooked then
	local over = M.IsMouseOver
	M.IsMouseOver = function(self, ...) return stub.mouseOver == self or over(self, ...) end
end
stub.mouseOverHooked = true
stub.netStats = { 0, 0, 120, 80 }
function GetNetStats() return unpack(stub.netStats) end

local NAMES = { { "CharacterMicroButton", "CharacterInfo" }, { "ProfessionMicroButton", "Professions" },
	{ "SpellbookMicroButton", "SpellbookAbilities" }, { "TalentMicroButton", "SpecTalents" },
	{ "LegacyMicroButton", "Achievements" }, { "QuestLogMicroButton", "Questlog" }, { "GuildMicroButton", "GuildCommunities" },
	{ "LFDMicroButton", "Groupfinder" }, { "CollectionsMicroButton", "Collections" }, { "StoreMicroButton", "Shop" },
	{ "MainMenuMicroButton", "GameMenu" } }
-- Turned off by Forever's game rules: made, never shown.
local HIDDEN = { "HousingMicroButton", "EJMicroButton", "HelpMicroButton" }
local W, H = 32, 40

local function color(f, layer, r, g, b, a, sub)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetColorTexture(r, g, b, a or 1)
	return t
end

local container = CreateFrame("Frame", "MicroMenuContainer", UIParent)
container:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -6, 6)
local menu = CreateFrame("Frame", "MicroMenu", container)
menu:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
menu.BorderArt = color(menu, "BACKGROUND", 0.35, 0.28, 0.16, 1, -3)
menu.BorderArt:SetPoint("TOPLEFT", menu, "TOPLEFT", -8, 8)
menu.BorderArt:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", 8, -8)
menu.BorderArt:SetAtlas("UI-HUD-ActionBar-Frame")
menu.BackgroundArt = color(menu, "BACKGROUND", 0.1, 0.08, 0.05, 1, -4)
menu.BackgroundArt:SetAllPoints(menu.BorderArt)
menu.BackgroundArt:SetAtlas("UI-HUD-ActionBar-IconFrame-Background")
stub.secureNames.MicroMenuContainer, stub.secureNames.MicroMenu = true, true

local function dress(name, kit, i)
	local b = rawget(_G, name) or CreateFrame("Button", name, menu)
	_G[name] = b
	b:SetParent(menu)
	b:SetSize(W, H)
	b.textureName = kit
	-- The plates' atlas size, centred (useAtlasSize): smaller than the button.
	b.Background = color(b, "BACKGROUND", 0.16, 0.13, 0.1, 1)
	b.Background:SetSize(24, 33)
	b.Background:SetPoint("CENTER", b, "CENTER", 0, 0.5)
	b.Background:SetAtlas("UI-HUD-MicroMenu-ButtonBG-Up")
	b.PushedBackground = color(b, "BACKGROUND", 0.1, 0.08, 0.06, 1)
	b.PushedBackground:SetAllPoints(b.Background)
	b.PushedBackground:SetAtlas("UI-HUD-MicroMenu-ButtonBG-Down")
	b.PushedBackground:Hide()
	-- The icon (LoadMicroButtonTextures): one hue per button.
	local h = (i - 1) / #NAMES
	local function icon(field, setter, state, a)
		local t = color(b, field == "highlightTexture" and "HIGHLIGHT" or "ARTWORK", 0.3 + 0.6 * h, 0.8 - 0.5 * h, 0.4 + 0.3 * h, a)
		t:SetPoint("TOPLEFT", b, "TOPLEFT", 6, -8)
		t:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -6, 8)
		t:SetAtlas("UI-HUD-MicroMenu-" .. kit .. "-" .. state)
		b[setter](b, t)
		return t
	end
	icon("normalTexture", "SetNormalTexture", "Up", 1)
	icon("pushedTexture", "SetPushedTexture", "Down", 1):Hide()
	icon("disabledTexture", "SetDisabledTexture", "Disabled", 0.5):Hide()
	icon("highlightTexture", "SetHighlightTexture", "Mouseover", 1)
	b.FlashBorder = color(b, "OVERLAY", 1, 0.8, 0.2, 1)
	b.FlashBorder:SetAllPoints(b)
	b.FlashBorder:SetAtlas("UI-HUD-MicroMenu-Highlightalert")
	b.FlashBorder:Hide()
	b.NotificationOverlay = CreateFrame("Frame", nil, b)
	b.NotificationOverlay:SetAllPoints(b)
	local mark = color(b.NotificationOverlay, "OVERLAY", 1, 0.2, 0.1, 1)
	mark:SetSize(10, 10)
	mark:SetPoint("TOPRIGHT", b, "TOPRIGHT", 0, 0)
	mark:SetAtlas("UI-HUD-MicroMenu-Communities-Icon-Notification")
	b.NotificationOverlay:Hide()
	b.tooltipText = b.tooltipText or kit
	return b
end

stub.microButtons = {}
for i, n in ipairs(NAMES) do stub.microButtons[i] = dress(n[1], n[2], i) end
for _, n in ipairs(HIDDEN) do dress(n, "GameMenu", 1):Hide() end
CharacterMicroButton.Portrait = color(CharacterMicroButton, "ARTWORK", 0.85, 0.65, 0.5, 1, 1)
CharacterMicroButton.Portrait:SetPoint("TOPLEFT", CharacterMicroButton, "TOPLEFT", 7, -7)
CharacterMicroButton.Portrait:SetPoint("BOTTOMRIGHT", CharacterMicroButton, "BOTTOMRIGHT", -7, 7)
CharacterMicroButton:GetNormalTexture():SetAlpha(0) -- the portrait is its icon
local bar = color(MainMenuMicroButton, "OVERLAY", 0, 1, 0, 1)
bar:SetSize(18, 3)
bar:SetPoint("BOTTOM", MainMenuMicroButton, "BOTTOM", 0, 3)
MainMenuMicroButton.MainMenuBarPerformanceBar = bar

-- MicroMenu:Layout (a GridLayoutFrame) with Edit Mode's orientation and Size:
-- childXPadding/childYPadding -5 (MicroMenuTemplate), the buttons overlap.
stub.microVertical = false
local function layout()
	local x = 0
	for _, b in ipairs(stub.microButtons) do
		b:ClearAllPoints()
		if stub.microVertical then b:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -x) else b:SetPoint("TOPLEFT", menu, "TOPLEFT", x, 0) end
		x = x + (stub.microVertical and H or W) - 5
	end
	if stub.microVertical then menu:SetSize(W, x + 5) else menu:SetSize(x + 5, H) end
	container:SetSize(menu:GetWidth() * menu:GetScale(), menu:GetHeight() * menu:GetScale())
end
layout()

-- Edit Mode's micro menu settings (EditModeMicroMenuSystemMixin): orientation and Size.
function stub.editMicroMenu(o)
	if o.size then menu:SetScale(o.size / 100) end
	if o.vertical ~= nil then stub.microVertical = o.vertical end
	layout()
	stub.exitEditMode()
end

-- The mixin's own writes (MainMenuBarMicroButtons.lua).
function stub.microHover(b, over)
	stub.mouseOver = over and b or nil
	b:GetNormalTexture():SetAlpha(over and 0 or 1)
end
function stub.microSetPushed(b, pushed)
	b.Background:SetShown(not pushed)
	b.PushedBackground:SetShown(pushed)
	b:SetButtonState(pushed and "PUSHED" or "NORMAL")
	b:GetHighlightTexture():SetAtlas("UI-HUD-MicroMenu-" .. b.textureName .. (pushed and "-Down" or "-Mouseover"))
	b:GetHighlightTexture():SetAlpha(pushed and 0.5 or 1)
end
function stub.microDisable(b)
	b:Disable()
	b:SetAlpha(0.5)
end
-- UIFrameFlash on FlashBorder: shown, its alpha stepping (nil: stopped).
function stub.microPulse(b, a)
	b.FlashBorder:SetShown(a ~= nil)
	b.FlashBorder:SetAlpha(a or 1)
end
function stub.microNotify(b, on) b.NotificationOverlay:SetShown(on) end

stub.guard(container, CALLS)
stub.guard(menu, CALLS)
stub.guard(menu.BorderArt, nil, "MicroMenu.BorderArt")
stub.guard(menu.BackgroundArt, nil, "MicroMenu.BackgroundArt")
local all = { unpack(stub.microButtons) }
for _, n in ipairs(HIDDEN) do all[#all + 1] = _G[n] end
for _, b in ipairs(all) do
	stub.guard(b, CALLS)
	local name = b:GetName()
	for _, k in ipairs({ "Background", "PushedBackground", "FlashBorder", "normalTexture", "pushedTexture", "disabledTexture", "highlightTexture" }) do
		stub.guard(rawget(b, k), nil, name .. "." .. k)
	end
	stub.guard(b.NotificationOverlay, CALLS, name .. ".NotificationOverlay")
end
stub.guard(CharacterMicroButton.Portrait, nil, "CharacterMicroButton.Portrait")
stub.guard(bar, nil, "MainMenuBarPerformanceBar")
