-- Micro menu (docs/windows/micromenu.md): the game's micro buttons in
-- Polestar's look, restyled in place, never rebuilt. MicroMenuContainer is an
-- Edit Mode system (docs/CLIENT.md, rule 17): orientation, order and size,
-- the vehicle bar's move and which buttons show stay the game's. The icons
-- stay the game's (their normal texture's alpha the game writes on every
-- hover; their highlight is the icon's glow). Per button: the stock
-- background faded (the game only shows and hides it); ours, inset to the
-- stock plate (the buttons overlap), a ground, a 1px
-- hairline, a hover wash (read from IsMouseOver: our doors' secure buttons
-- lie over some micro buttons and take their mouse, Core.lua ns.Doors) and,
-- while its window shows (the game's pushed state, or our window of that
-- door), the accent wash and hairline. The alert pulse's border is emptied
-- (UIFrameFlash writes its alpha) and its alpha drives our accent hairline;
-- the notification mark is faded under an accent dot of ours on the game's
-- own overlay (so it shows and hides with it). The game menu button's
-- latency strip is faded under a dot of ours in the game's latency colours
-- (its tooltip stays the game's). The bar's frame art is faded. Nothing is
-- written on a stock frame, no method hooked; switched off, live, all back.

local ADDON, ns = ...
local Theme = Polestar.Theme
local H = ns.HUD

local M = { noun = "micro menu" }
-- Forever's buttons (Camelot MicroMenuContainerOverrides.lua); the game hides those its rules turn off.
local BUTTONS = { "CharacterMicroButton", "ProfessionMicroButton", "SpellbookMicroButton", "TalentMicroButton",
	"LegacyMicroButton", "QuestLogMicroButton", "HousingMicroButton", "GuildMicroButton", "LFDMicroButton",
	"CollectionsMicroButton", "EJMicroButton", "HelpMicroButton", "StoreMicroButton", "MainMenuMicroButton" }
local FLASH = "UI-HUD-MicroMenu-Highlightalert" -- FlashBorder's atlas (MainMenuBarMicroButtons.xml)
-- The game's latency colours (PERFORMANCEBAR_LOW_LATENCY, _MEDIUM_LATENCY: green, yellow, red).
local LOW, MEDIUM = 300, 600

local looks = setmetatable({}, { __mode = "k" }) -- stock button -> its textures of ours
local started, driver, ping

local function on() return ns.Enabled("micromenu") end

local tex = ns.HUD.Tex

-- The stock plate inside a button (UI-HUD-MicroMenu-ButtonBG-Up, centred,
-- about 24x33 on a 32x40 button): the layout overlaps the buttons
-- (MicroMenuTemplate's childXPadding/childYPadding -5), so a ground the size
-- of the button would run into its neighbours. Offsets per corner, in the
-- button's own units (Edit Mode's Size scales them with it).
local INSET = { TOPLEFT = { 4, -4 }, TOPRIGHT = { -4, -4 }, BOTTOMLEFT = { 4, 3 }, BOTTOMRIGHT = { -4, 3 } }
-- Every dot (the alert, the latency): this size, this far inside the plate's top right corner.
local DOT, PAD = 6, 2
local LOOK, SHADOW = H.ICONS, 4 -- the HUD look's Icons group (2 px at most while it follows Polestar); the shadow's reach

-- `o` further in on every side: a border thicker than a pixel grows outward
-- (ns.PaintHairlines, as a window's), so the plate gives it that room and the
-- gap to the next button stays.
local function plate(t, b, o)
	o = o or 0
	t:ClearAllPoints()
	t:SetPoint("TOPLEFT", b, "TOPLEFT", INSET.TOPLEFT[1] + o, INSET.TOPLEFT[2] - o)
	t:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", INSET.BOTTOMRIGHT[1] - o, INSET.BOTTOMRIGHT[2] + o)
end

local function dotAt(t, b, left)
	t:SetSize(DOT, DOT)
	t:ClearAllPoints()
	t:SetPoint("TOPRIGHT", b, "TOPRIGHT", INSET.TOPRIGHT[1] - PAD - (left or 0), INSET.TOPRIGHT[2] - PAD)
end

local function look(b)
	local l = looks[b]
	if l then return l end
	l = { fill = tex(b, "BACKGROUND", -8), wash = tex(b, "OVERLAY", 6), hover = tex(b, "OVERLAY", 5) }
	plate(l.fill, b)
	plate(l.wash, b)
	plate(l.hover, b)
	l.shadow = H.Shadow(b, l.fill, SHADOW)
	l.edges = ns.Hairlines(b, l.fill, function() return tex(b, "OVERLAY", 7) end)
	local n = rawget(b, "NotificationOverlay")
	if n then
		l.marks = { n:GetRegions() }
		l.dot = tex(n, "OVERLAY", 7, "disc-16")
		dotAt(l.dot, b)
	end
	looks[b] = l
	return l
end

-- Our window behind this door is open (ns.Doors sets m.micro; Character too).
local function ours(b)
	for key, m in pairs(ns.modules) do
		if m.micro == b and m.psFrame and m.psFrame:IsShown() and ns.Enabled(key) then return true end
	end
end

local function pulse(b)
	local f = rawget(b, "FlashBorder")
	return f and f:IsShown() and f:GetAlpha() or 0
end

local function paintState(b, l)
	local active = b:GetButtonState() == "PUSHED" or ours(b) or false
	local hover = b:IsMouseOver() and true or false
	local flash = pulse(b)
	l.active, l.hovered, l.flash = active, hover, flash
	local r, g, bl = Theme.Accent()
	l.wash:SetVertexColor(r, g, bl, 0.15)
	l.wash:SetShown(active)
	l.hover:SetShown(hover)
	-- The border off (H.Edge): the edge only while active or pulsing, from clear.
	local edged, br, bg, bb, ba, n = H.Edge(LOOK)
	if not edged then ba = 0 end
	local o = Theme.Pixel(b) * (n - 1)
	if l.o ~= o then
		l.o = o
		plate(l.fill, b, o); plate(l.wash, b, o); plate(l.hover, b, o)
	end
	local er, eg, eb, ea = br, bg, bb, ba
	if active then
		er, eg, eb, ea = r, g, bl, 1
	elseif flash > 0 then
		-- The alert pulse: the border's colour to the accent, as the game's glow fades in.
		er, eg, eb, ea = br + (r - br) * flash, bg + (g - bg) * flash, bb + (bl - bb) * flash, (ba or 1) + (1 - (ba or 1)) * flash
	end
	ns.PaintHairlines(l.edges, edged or active or flash > 0, er, eg, eb, ea, n)
end

-- The latency dot steps left of the alert dot while that one shows on the same button.
local pingLeft
local function placePing()
	local l = looks[MainMenuMicroButton]
	local left = l and l.dot and l.dot:IsVisible() and DOT + PAD or 0
	if left ~= pingLeft then
		pingLeft = left
		dotAt(ping, MainMenuMicroButton, left)
	end
end

local function paintPing()
	if not ping then return end
	placePing()
	local home, world = select(3, GetNetStats())
	local ms = math.max(ns.Num(home), ns.Num(world))
	ping:SetVertexColor(Theme.Color(ms > MEDIUM and "danger" or ms > LOW and "warning" or "success"))
end

local fade = H.Fade

local function paint(b, shown)
	local l = look(b)
	fade(shown and 0 or 1, rawget(b, "Background"), rawget(b, "PushedBackground"))
	local f = rawget(b, "FlashBorder")
	if f then
		if shown then f:SetTexture(nil) else f:SetAtlas(FLASH) end
	end
	if l.marks then fade(shown and 0 or 1, unpack(l.marks)) end
	if l.dot then
		l.dot:SetVertexColor(Theme.Accent())
		l.dot:SetShown(shown)
	end
	local r, g, bl = Theme.Color("bg")
	l.fill:SetVertexColor(r, g, bl, H.GroundAlpha(LOOK))
	l.hover:SetVertexColor(Theme.Wash("hover"))
	l.fill:SetShown(shown)
	for _, t in ipairs(l.edges) do t:SetShown(shown) end
	H.PaintShadow(l.shadow, shown, nil, LOOK)
	if shown then paintState(b, l) else l.wash:Hide(); l.hover:Hide() end
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
	each(function(b) paint(b, shown) end)
	fade(shown and 0 or 1, rawget(MicroMenu, "BorderArt"), rawget(MicroMenu, "BackgroundArt"))
	local mm = rawget(_G, "MainMenuMicroButton")
	local bar = mm and rawget(mm, "MainMenuBarPerformanceBar")
	if bar then
		fade(shown and 0 or 1, bar)
		if not ping then
			ping = tex(mm, "OVERLAY", 7, "disc-16")
		end
		ping:SetShown(shown)
		paintPing()
	end
	driver:SetShown(shown)
end

-- States no event tells (hover, the pulse, a window opening), each frame; the latency each second.
local wait = 0
local function update(_, elapsed)
	for b, l in pairs(looks) do
		if b:IsVisible() and ((b:GetButtonState() == "PUSHED" or ours(b) or false) ~= l.active
			or (b:IsMouseOver() and true or false) ~= l.hovered or pulse(b) ~= l.flash) then
			paintState(b, l)
		end
	end
	if ping then placePing() end
	wait = wait - elapsed
	if wait <= 0 then
		wait = 1
		paintPing()
	end
end

function M.Enable()
	if not rawget(_G, "MicroMenu") then return end
	started = true
	driver = CreateFrame("Frame", nil, UIParent)
	driver:SetScript("OnUpdate", update)
	-- Edit Mode's Size scales the menu: the hairlines one pixel again.
	EventRegistry:RegisterCallback("EditMode.Exit", M.Apply, M)
	Polestar.RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", M.Apply)
	Theme.OnChanged(function() if on() then M.Apply() end end, true)
	M.Apply()
end

ns.Module("micromenu", M)
