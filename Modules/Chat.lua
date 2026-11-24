-- Chat (docs/DESIGN.md, "Chat"): the game's own chat windows in Polestar's
-- look, restyled in place, never replaced: every addon that writes into them
-- (AddMessage, message filters, chat mods) still does, and the edit box,
-- which runs secure slash commands, is only drawn over. Only the art changes
-- (docs/CLIENT.md, rule 15): the stock border pieces hidden, the stock ground
-- emptied (SetTexture(nil)) but left to the game, which keeps writing its
-- alpha. Calm at rest: a soft ground, no outline, the side icons gone; warm
-- (the game's mouse-over fade-in, read from `hasBeenFaded`, or typing): the
-- full ground and its hairline, the side icons back. Calm only with "Fade
-- chat when idle" on (PolestarUIDB.chatFade); off, the default, always warm.
-- The tabs', edit box's and buttons'
-- art faded with SetAlpha; textures of ours added, kept in a weak table by
-- frame (on the chat's menus, through the menu's own compositor). No
-- key is written on a stock frame, nothing is moved, sized or reparented.
-- The tabs take Polestar's face; the messages and the edit box keep the
-- game's chat font (Polestar's face there read poorly in game). Switched off, all
-- of it is the game's again at once. Also ours: a copy window and the chat history across sessions
-- ("Copy and history", below).

local ADDON, ns = ...
local Theme = Polestar.Theme

-- FloatingBorderedFrame's border pieces (FloatingChatFrame.xml), on a chat
-- window and on its button frame; its Background is the ground.
local PIECES = { "TopLeftTexture", "BottomLeftTexture", "TopRightTexture", "BottomRightTexture", "LeftTexture", "RightTexture", "BottomTexture", "TopTexture" }
local GROUND = "Interface\\ChatFrame\\ChatFrameBackground"
-- ChatTabArtTemplate's art (its glow, the new-message flash, stays the game's).
local TAB = { "Left", "Middle", "Right", "ActiveLeft", "ActiveMiddle", "ActiveRight", "HighlightLeft", "HighlightMiddle", "HighlightRight" }
-- ChatFrameEditBoxTemplate's art, by global name after the edit box's.
local INPUT = { "Left", "Mid", "Right", "FocusLeft", "FocusMid", "FocusRight" }

local looks = setmetatable({}, { __mode = "k" }) -- stock frame -> its textures of ours
local M = { noun = "chat" }
local driver

local tex = ns.HUD.Tex

local hairline, paintLine = ns.Hairlines, ns.PaintHairlines

-- A frame never restyled has nothing to give back.
local function look(f, make)
	if not f then return end
	if not looks[f] and ns.Enabled("chat") then looks[f] = make(f) end
	return looks[f]
end

-- The stock border pieces hidden and the stock ground emptied (a chat
-- window's or its button frame's); the game keeps fading that ground.
local function bare(f, on)
	f.Background:SetTexture(not on and GROUND or nil)
	local name = f:GetName()
	for _, k in ipairs(PIECES) do
		local p = name and _G[name .. k]
		if p then p:SetShown(not on) end
	end
end

-- The window as one flat Polestar surface: one ground round the message
-- area and the button strip on its side, its hairline only while warm; the
-- tab header above both (the dock's, below); the edit box hangs below as its
-- footer (input) while typing. All of it textures of ours, anchored to the
-- stock grounds: no stock frame moves.
-- Nothing of ours on the window reaches above its ground: the window (frame
-- level 5) draws above the docked tabs, children of GeneralDockManager (LOW
-- strata, a level or two), so a ground of ours there covered the tabs.
local HEADER = 32 -- a tab's band: all of its 32 (its whole clickable area), the label centred in it
local LABEL_LIFT = 5 -- the stock label sits 5 low (CENTER 0,-5: centred in the old 22 band)
local PAD = 6 -- room left of the text when the button strip is on the right

-- The button frame's ground sits 1px off the window's, level with it, on
-- the side FCF_SetButtonSide picked (re-placed from its hook).
local function place(f, l)
	local bg, side = f.Background, f.buttonFrame.Background
	local left = f.buttonSide ~= "right"
	-- shortcut: the strip's room stays while the game hides the button frame (gamepad mode); follow its OnHide if players ask.
	l.fill:ClearAllPoints()
	l.fill:SetPoint("TOPLEFT", left and side or bg, "TOPLEFT", left and 0 or -PAD, 0)
	l.fill:SetPoint("BOTTOMRIGHT", left and bg or side, "BOTTOMRIGHT", 0, 0)
end

-- Polestar's window ground (bg at the Background opacity setting), not the
-- player's chat opacity, and its hairline: REST of them at rest, all of them
-- while warm (the panel keeps a faint outline at rest). The driver eases `l.warm` between 0 and 1.
local REST = 0.35
local FADE_IN, FADE_OUT = 0.15, 1 -- seconds: the game's fade-in, a calmer fade-out

local function panel(f)
	local l = look(f, function()
		local l = { win = f, warm = 0, fill = tex(f, "BACKGROUND", -8) }
		l.edges = hairline(f, l.fill)
		return l
	end)
	if not l then return end
	local on = ns.Enabled("chat")
	bare(f, on)
	bare(f.buttonFrame, on)
	place(f, l)
	ns.PaintGround(l.fill, on)
	paintLine(l.edges, on, Theme.Color("border"))
	l.paint = nil -- the driver repaints the warmth
end

-- The warmth `w` (0 at rest, 1 warm) on a window's ground and hairline (a
-- texture's alpha is its vertex colour's: the whole alpha is set here).
-- A docked window's top edge is the header's foot: not drawn (the header's
-- own edges carry the outline round both). The header's foot never is.
local function paintWarm(l, w)
	local k = REST + (1 - REST) * w
	l.fill:SetAlpha(Theme.GroundAlpha() * k)
	local r, g, b, a = Theme.Color("border")
	for i, t in ipairs(l.edges) do
		local open = i == 1 and l.win and l.win.isDocked or i == 2 and l.dock
		t:SetVertexColor(r, g, b, open and 0 or (a or 1) * k)
	end
end

-- The tab header of the docked windows: our ground and hairline on
-- GeneralDockManager, so under the tabs (its children), HEADER tall over the
-- first window's ground, as wide. Warm as the warmest shown docked window.
-- Undocked windows have none: their tab (MEDIUM strata) sits above them.
local function header()
	local d, w = _G.GeneralDockManager, looks[_G.ChatFrame1]
	if not d or not w then return end
	local l = look(d, function()
		local l = { dock = true, warm = 0, fill = tex(d, "BACKGROUND", -8) }
		l.fill:SetPoint("BOTTOMLEFT", w.fill, "TOPLEFT", 0, 0)
		l.fill:SetPoint("BOTTOMRIGHT", w.fill, "TOPRIGHT", 0, 0)
		l.fill:SetHeight(HEADER)
		l.edges = hairline(d, l.fill)
		return l
	end)
	if not l then return end
	local on = ns.Enabled("chat")
	ns.PaintGround(l.fill, on)
	paintLine(l.edges, on, Theme.Color("border"))
	l.paint = nil
end

-- A tab as the Character window's top tabs (Polestar's shell tab): plain
-- text centred in it, no box, no ground, the label textDim, the selected one
-- in the text colour over a 2px accent underline across the tab's foot; the
-- hover wash. A tab the game colours (a whisper's) keeps its label colour;
-- its conversation icon is drawn flat in Polestar's icon colour. The tabs' own
-- fade (0.4 selected, 0.2 others at rest) stays the game's. The new-message
-- glow stays the game's, in the accent. FCFTab_UpdateColors writes the
-- label, glow and icon colours; its hook paints ours over them. The label and
-- underline are out of the tab's fade (SetIgnoreParentAlpha: the game's 0.2
-- left a label unreadable over the world); the driver fades them itself,
-- legible at rest (TAB_REST, only with the fade on), full while the chat is
-- warm or the tab hovered.
local TAB_REST = { [true] = 0.85, [false] = 0.7 } -- the selected tab, the others
local function paintTab(t, l, selected)
	local on = ns.Enabled("chat")
	l.sel = selected
	l.bar:SetShown(on and selected)
	local c = t.selectedColorTable
	local icon = t.conversationIcon
	if icon then icon:SetDesaturated(on) end
	if on then
		if not c then t.Text:SetTextColor(Theme.Color(selected and "text" or "textDim")) end
		t.glow:SetVertexColor(Theme.Accent())
		if icon then icon:SetVertexColor(Theme.Color("icon")) end
	else
		local n = c or NORMAL_FONT_COLOR
		t.Text:SetTextColor(n.r, n.g, n.b)
		if icon then
			local x = icon.iconDisplayInfo and icon.iconDisplayInfo.allowColorOverride and c
			icon:SetVertexColor(x and x.r or 1, x and x.g or 1, x and x.b or 1)
		end
		c = c or DEFAULT_TAB_SELECTED_COLOR_TABLE
		t.glow:SetVertexColor(c.r, c.g, c.b)
	end
end

-- Whether a tab is the selected one, as the dock decides it (FCFDock_UpdateTabs:
-- undocked, or the dock's selected window). Not from its Active art, which
-- shows until the dock first colours the tab (the combat log's, at login).
local function selectedTab(t)
	local f = _G["ChatFrame" .. t:GetID()]
	if f and GENERAL_CHAT_DOCK and FCFDock_GetSelectedWindow then
		return not f.isDocked or FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK) == f
	end
	return t.ActiveMiddle:IsShown()
end

-- A docked tab the dock lays out in its scroll frame (a window the player
-- made, past the static General and Combat Log: FCFDock_UpdateTabs) sits a
-- few px off the dock's foot and is stretched to 90 (FCFDock_CalculateTabSize)
-- with its label centred in it: it sits a little high. So the label, wash
-- and underline are moved by `dy`, the tab's foot to the dock's, so all sit
-- on the header. Repainted by the driver.
local function placeTab(t, l, dy)
	l.dy = dy
	local a = l.at
	t.Text:ClearAllPoints()
	t.Text:SetPoint(a[1], a[2], a[3], a[4], a[5] + LABEL_LIFT + dy)
	l.hover:ClearAllPoints()
	l.hover:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 0, dy)
	l.hover:SetPoint("TOPRIGHT", t, "TOPRIGHT", 0, HEADER - 32 + dy)
end

-- The label in Polestar's face (the shell tabs' `label`) at the game's size:
-- the game sizes a tab to its text once, so a larger size would cut the name short.
local function tab(t)
	local l = look(t, function()
		-- The hover wash under the label (BACKGROUND, shown by the driver): in
		-- the HIGHLIGHT layer it drew over the label and washed it out.
		local l = { tab = true, bar = tex(t, "ARTWORK"), hover = tex(t, "BACKGROUND"), font = { t.Text:GetFont() },
			at = { t.Text:GetPoint(1) } }
		-- The underline: across the band's foot, as a shell tab's.
		l.bar:SetPoint("BOTTOMLEFT", l.hover, "BOTTOMLEFT", 0, 0)
		l.bar:SetPoint("BOTTOMRIGHT", l.hover, "BOTTOMRIGHT", 0, 0)
		l.bar:SetHeight(2)
		return l
	end)
	if not l then return end
	local on = ns.Enabled("chat")
	for _, k in ipairs(TAB) do t[k]:SetAlpha(on and 0 or 1) end
	l.bar:SetVertexColor(Theme.Accent())
	l.hover:SetVertexColor(Theme.Wash("hover"))
	l.over, l.alpha = nil, nil -- the driver repaints the hover and the fade
	l.hover:Hide()
	t.Text:SetIgnoreParentAlpha(on)
	l.bar:SetIgnoreParentAlpha(true)
	t.Text:SetAlpha(1)
	placeTab(t, l, 0) -- the driver measures the offset
	local f = l.font
	Theme.SetFace(t.Text, on and (Theme.FontSpec("label")) or f[1], f[2], f[3] or "")
	paintTab(t, l, selectedTab(t))
end

-- The edit box as the window's footer, in Polestar's input, only while
-- typing: the window's ground under the input well (inputBg), ringed as a
-- focused ns.TextField is (the accent at 0.8); its text stays the game's chat
-- font. Its letter limit stays the game's (255 visible). Not typing, no
-- footer, whether the game hides the box (classic style) or leaves it shown
-- at 0.35 (IM style, the default). The driver follows the focus.
local FOOTER = 24 -- below the window's ground, the stock box's text centred in it
local function paintFocus(e, l)
	l.focus = e:HasFocus()
	l.fill:SetShown(l.focus)
	l.well:SetShown(l.focus)
	for _, t in ipairs(l.edges) do t:SetShown(l.focus) end
end

local function input(e, f)
	local w = looks[f]
	local l = look(e, function()
		local l = { fill = tex(e, "BACKGROUND", -8), well = tex(e, "BACKGROUND", -7) }
		l.fill:SetPoint("TOPLEFT", w.fill, "BOTTOMLEFT", 0, 0)
		l.fill:SetPoint("TOPRIGHT", w.fill, "BOTTOMRIGHT", 0, 0)
		l.fill:SetHeight(FOOTER)
		l.well:SetAllPoints(l.fill)
		l.edges = hairline(e, l.fill)
		return l
	end)
	if not l then return end
	local on = ns.Enabled("chat")
	local name = e:GetName()
	for _, k in ipairs(INPUT) do
		local p = name and _G[name .. k]
		if p then p:SetAlpha(on and 0 or 1) end
	end
	ns.PaintGround(l.fill, on)
	l.well:SetVertexColor(Theme.Color("inputBg"))
	l.well:SetShown(on)
	local r, g, b = Theme.Accent()
	paintLine(l.edges, on, r, g, b, 0.8)
	if on then paintFocus(e, l) end
end

-- The combat log's filter strip (Blizzard_CombatLog, loaded on demand): its
-- black band faded, a divider under it; the window's ground shows through.
local function strip()
	local f = _G.CombatLogQuickButtonFrame_Custom
	local l = look(f, function()
		local l = { line = tex(f, "BORDER", 7) }
		l.line:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
		l.line:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
		return l
	end)
	if not l then return end
	local on = ns.Enabled("chat")
	local band = _G.CombatLogQuickButtonFrame_CustomTexture
	if band then band:SetAlpha(on and 0 or 1) end
	l.line:SetVertexColor(Theme.Color("divider"))
	l.line:SetHeight(Theme.Pixel(f))
	l.line:SetShown(on)
end

-- The side buttons, scroll bars, grips, minimised windows and the dock's
-- overflow. Their stock art is faded with SetAlpha: the game swaps their
-- atlases on state changes (SetAtlas keeps the alpha) but never writes it.
local function fadeArt(on, ...)
	for i = 1, select("#", ...) do
		local t = select(i, ...)
		if t then t:SetAlpha(on and 0 or 1) end
	end
end

-- A stock button as Polestar's icon button: its plate faded, the hover
-- wash, and `icon` (a Polestar glyph) in place of the stock one; without
-- one, the stock icon (`b.Icon`, which the game swaps through the voice
-- states) stays, drawn flat in Polestar's icon colour.
-- The driver nudges the glyph while pressed and dims it while disabled.
-- keepLit: the highlight is the game's alert pulse, kept. side: a button of
-- the side strip, whose icon shows only while the chat is warm.
local function iconButton(b, icon, size, keepLit, side)
	local l = look(b, function()
		local l = { hover = tex(b, "HIGHLIGHT"), side = side }
		l.hover:SetAllPoints(b)
		if icon then
			l.glyph = b:CreateTexture(nil, "ARTWORK")
			l.glyph:SetSize(size, size)
			l.glyph:SetPoint("CENTER", b, "CENTER", 0, 0)
		end
		return l
	end)
	if not l then return end
	local on = ns.Enabled("chat")
	fadeArt(on, b:GetNormalTexture(), b:GetPushedTexture(), b:GetDisabledTexture(), not keepLit and b:GetHighlightTexture())
	l.hover:SetVertexColor(Theme.Wash("hover"))
	l.hover:SetShown(on)
	if l.glyph then
		l.glyph:SetTexture(Theme.Media(Theme.Icon(icon)))
		l.glyph:SetVertexColor(Theme.Color("icon"))
		l.glyph:SetShown(on)
		l.state = nil
	end
	local i = not icon and b.Icon
	if i then
		i:SetDesaturated(on)
		if on then i:SetVertexColor(Theme.Color("icon")) else i:SetVertexColor(1, 1, 1) end
		i:SetAlpha(1)
	end
	-- What the driver fades: the glyph, else the stock icon.
	l.mark = l.glyph or i or nil
	l.dim, l.shown = 1, nil
end

-- The driver's part: the glyph 1px down while pressed, dim while disabled.
local function paintState(b, l)
	local s = b:IsEnabled() and b:GetButtonState() or "DISABLED"
	if s == l.state then return end
	l.state = s
	l.glyph:SetPoint("CENTER", b, "CENTER", 0, s == "PUSHED" and -1 or 0)
	l.dim = s == "DISABLED" and 0.35 or 1
end

-- The scroll-to-bottom button's flash (an ADD arrow the game plays while the
-- window is scrolled up: ChatFrameMixin:OnUpdate) is hidden by its vertex
-- colour (black, clear: nothing under ADD), not its alpha: StartFlash and
-- StopFlash write that (0, 1), and the animation drives it. Our glyph takes
-- the accent while it plays instead.
local function scrollFlash(b)
	local l, fl = looks[b], b.Flash
	if not l or not fl then return end
	if ns.Enabled("chat") then fl:SetVertexColor(0, 0, 0, 0) else fl:SetVertexColor(1, 1, 1, 1) end
	l.glyph:SetVertexColor(Theme.Color("icon"))
end

-- The buttons left of the first window (FloatingChatFrame.xml,
-- FloatingChatFrameVoiceChat.xml, TextToSpeech.xml): the chat menu's icon in
-- Polestar's speech glyph; the channel, voice and speech buttons keep their
-- own icons on our ground.
local SIDE = { { "ChatFrameMenuButton", "icon-talk" }, { "ChatFrameChannelButton" }, { "ChatFrameToggleVoiceDeafenButton" },
	{ "ChatFrameToggleVoiceMuteButton" }, { "TextToSpeechButton" } }

-- A window's scroll bar (MinimalScrollBar) as Polestar's thin strip: the
-- track's and thumb's art faded, a 2px thumb of ours (4px under the cursor),
-- the steppers as glyph buttons.
local function scrollbar(bar)
	if not bar then return end
	local thumb = bar.Track.Thumb
	local l = look(bar, function()
		local l = { thumb = tex(thumb, "ARTWORK", 7), lit = tex(thumb, "HIGHLIGHT") }
		l.thumb:SetPoint("TOP", thumb, "TOP", 0, 0)
		l.thumb:SetPoint("BOTTOM", thumb, "BOTTOM", 0, 0)
		l.thumb:SetWidth(2)
		l.lit:SetPoint("TOP", thumb, "TOP", 0, 0)
		l.lit:SetPoint("BOTTOM", thumb, "BOTTOM", 0, 0)
		l.lit:SetWidth(4)
		return l
	end)
	if not l then return end
	local on = ns.Enabled("chat")
	local t = bar.Track
	fadeArt(on, t.Begin, t.Middle, t.End, thumb.Begin, thumb.Middle, thumb.End, bar.Back.Texture, bar.Forward.Texture)
	l.thumb:SetVertexColor(Theme.Color("textMuted"))
	l.thumb:SetShown(on)
	l.lit:SetVertexColor(Theme.Color("iconHover"))
	l.lit:SetShown(on)
	iconButton(bar.Back, "chevron-up", 8)
	iconButton(bar.Forward, "chevron-down", 8)
end

-- A minimised window (FloatingChatFrameMinimizedTemplate, made the first
-- time FCF_MinimizeFrame runs) as a tab: Polestar's panel and hairline, the
-- hover wash; its new-message glow stays the game's.
local MINI = { "Left", "Middle", "Right", "HighlightLeft", "HighlightMiddle", "HighlightRight" }
local function minimized(m)
	local l = look(m, function()
		local l = { fill = tex(m, "BACKGROUND", -8), hover = tex(m, "HIGHLIGHT") }
		-- The stock art's visible part: the middle 22 of its 32.
		l.fill:SetPoint("TOPLEFT", m, "TOPLEFT", 0, -5)
		l.fill:SetPoint("BOTTOMRIGHT", m, "BOTTOMRIGHT", 0, 5)
		l.edges = hairline(m, l.fill)
		l.hover:SetAllPoints(l.fill)
		return l
	end)
	if not l then return end
	local on = ns.Enabled("chat")
	for _, k in ipairs(MINI) do m[k]:SetAlpha(on and 0 or 1) end
	l.fill:SetVertexColor(Theme.Color("panel"))
	l.fill:SetShown(on)
	paintLine(l.edges, on, Theme.Color("border"))
	l.hover:SetVertexColor(Theme.Wash("hover"))
	l.hover:SetShown(on)
	iconButton(_G[m:GetName() .. "MaximizeButton"], "chevron-up", 12)
end

-- The dock's overflow button (its highlight is the alert pulse, kept) and
-- its list (TooltipBackdropTemplate): the list's NineSlice faded under our
-- ground and hairline.
local function overflow()
	iconButton(_G.GeneralDockManagerOverflowButton, "chevron-right", 12, true)
	local list = _G.GeneralDockManagerOverflowButtonList
	local l = look(list, function()
		local l = { fill = tex(list.NineSlice, "BACKGROUND", -8) }
		l.fill:SetAllPoints(list)
		l.edges = hairline(list.NineSlice, l.fill)
		return l
	end)
	if not l then return end
	local on = ns.Enabled("chat")
	ns.FadeNine(list.NineSlice, on and 0 or 1)
	ns.PaintGround(l.fill, on)
	paintLine(l.edges, on, Theme.Color("border"))
end

-- The chat's own menus (Blizzard_Menu, by their tags): a tab's right-click
-- menu, a channel name's, the chat menu button's (its submenus share the
-- callback). Menu frames are pooled and shared by every menu in the game:
-- ns.MenuLook (Core.lua). No other menu is touched.
local MENUS = { "MENU_FCF_TAB", "MENU_CHAT_FRAME_CHANNEL", "MENU_CHAT_SHORTCUTS" }
-- The items sit 8 in from the top and 15 from the bottom (MenuStyle1's inset): 8 all round.
local function menuLook(menu)
	if ns.Enabled("chat") then ns.MenuLook(menu, 7) end
end

-- Chat bubbles (ChatBubbleTemplate, a NineSlice panel inside each bubble)
-- in our tooltip look: the pieces and tail faded, our ground (a touch more
-- see-through than the windows', as the tooltips') and hairline 8 in from
-- the frame (the text sits 16 in). C_ChatBubbles hands out only the bubbles
-- addons may touch: in instances they are forbidden and stay the game's.
-- The engine reuses bubble frames, so ours are repainted whenever the scan
-- sees them, and given back, switched off, while not forbidden.
local function bubble(f, on)
	if not f or f:IsForbidden() then return end
	local l = look(f, function()
		local l = { fill = tex(f, "BACKGROUND", -8) }
		l.fill:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -8)
		l.fill:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)
		l.edges = hairline(f, l.fill)
		l.bubble = true
		return l
	end)
	if not l then return end
	ns.FadeNine(f, on and 0 or 1)
	f.Tail:SetAlpha(on and 0 or 1)
	ns.PaintGround(l.fill, on, 0.85)
	paintLine(l.edges, on, Theme.Color("border"))
end

local function bubbles()
	for _, b in ipairs(C_ChatBubbles.GetAllChatBubbles()) do bubble((b:GetChildren()), true) end
end

-- The social (Quick Join) button in the side strip, at its foot: just above
-- the chat menu button, which the game keeps at the strip's bottom, so it
-- stays inside the strip whether the voice buttons show or not, and never
-- above the window. The stock QuickJoinToastButton cannot move:
-- ChatAlertFrame places it (an auto-anchored alert subsystem) and would put
-- it back, and a move of ours would taint that layout. So ours is a copy, one
-- more button of the strip: a voice button's size (27x26) and spacing (2), a
-- 15px friend icon (flat in Polestar's icon colour) centred as the voice
-- icons are, the online count at its foot, faded with the strip.
-- Its clicks go through a secure button of ours, placed over the icon out
-- of combat (a secure frame anchored to a frame would protect it:
-- docs/CLIENT.md, rule 10). With our Social window on, a click opens ours
-- (PostClick, as our doors do), shift-click the stock button; with it off,
-- or while a Quick Join toast shows (its click opens that group), a click is
-- the stock button's own (type "click": its OnClick runs untainted). The
-- route is set out of combat (attributes are locked in combat).
-- The stock button's icon, count and highlight are faded; its toasts and
-- queue icon (alpha the game animates) stay, and so does its click area.
local SOCIAL_W, SOCIAL_H, SOCIAL_ICON = 27, 26, 15 -- VoiceToggleButtonTemplate's
local social -- { icon frame, glyph, count, hit (the secure button) }
local function socialButton()
	local q = _G.QuickJoinToastButton
	local strip = _G.ChatFrameMenuButton
	if not q or not strip then return end
	if not social and ns.Enabled("chat") then
		local f = CreateFrame("Frame", "PolestarUIChatSocialIcon", UIParent)
		f:SetSize(SOCIAL_W, SOCIAL_H)
		f:SetFrameStrata("MEDIUM")
		f:SetPoint("BOTTOM", strip, "TOP", 0, 2)
		local glyph = f:CreateTexture(nil, "ARTWORK")
		glyph:SetSize(SOCIAL_ICON, SOCIAL_ICON)
		glyph:SetPoint("CENTER", f, "CENTER", 0, 0)
		-- A friend silhouette with no plate (the stock button's atlas has one).
		glyph:SetAtlas("groupfinder-icon-friend")
		local hover = tex(f, "BACKGROUND")
		hover:SetAllPoints(f)
		hover:Hide()
		local count = f:CreateFontString(nil, "OVERLAY")
		count:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
		local hit = CreateFrame("Button", "PolestarUIChatSocial", UIParent, "SecureActionButtonTemplate")
		hit:RegisterForClicks("LeftButtonUp")
		hit:SetAttribute("useOnKeyDown", false)
		hit:SetAttribute("shift-type1", "click")
		hit:SetAttribute("clickbutton", q)
		hit:SetScript("PostClick", function()
			local m = ns.modules.social
			if not IsShiftKeyDown() and not hit:GetAttribute("type1") and m and m.Toggle then m.Toggle() end
		end)
		hit:SetFrameStrata("MEDIUM")
		hit:SetScript("OnEnter", function(self)
			hover:Show()
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			if q:IsEnabled() then
				GameTooltip_SetTitle(GameTooltip, MicroButtonTooltipText(SOCIAL_BUTTON, "TOGGLESOCIAL"))
				if not hit:GetAttribute("type1") then ns.TooltipHint("Shift-click for the game's own window.") end
			elseif q.disabledTooltip then
				GameTooltip:AddLine(q.disabledTooltip, ERROR_COLOR.r, ERROR_COLOR.g, ERROR_COLOR.b)
			end
			GameTooltip:Show()
		end)
		hit:SetScript("OnLeave", function() hover:Hide() GameTooltip:Hide() end)
		social = { f = f, glyph = glyph, hover = hover, count = count, hit = hit }
	end
	if not social then return end
	local on = ns.Enabled("chat")
	for _, k in ipairs({ "FriendsButton", "FriendCount" }) do
		if q[k] then q[k]:SetAlpha(on and 0 or 1) end
	end
	fadeArt(on, q:GetHighlightTexture())
	social.glyph:SetDesaturated(true)
	social.glyph:SetVertexColor(Theme.Color("icon"))
	social.hover:SetVertexColor(Theme.Wash("hover"))
	Theme.SetFace(social.count, Theme.FontSpec("small"))
	social.count:SetTextColor(Theme.Color("textMuted"))
	social.text, social.x, social.y = nil, nil, nil
	social.f:SetShown(on)
	if not on and not InCombatLockdown() then social.hit:Hide() end
end

-- The driver's part: the count copied, the icon shown with the stock button,
-- the secure button over the icon (out of combat; its alpha any time).
local function paintSocial(alpha)
	local q, s = _G.QuickJoinToastButton, social
	local text = q.FriendCount and q.FriendCount:GetText()
	if text ~= s.text then
		s.text = text
		s.count:SetText(text ~= "0" and text or "")
	end
	s.f:SetAlpha(alpha)
	s.hit:SetAlpha(alpha)
	if InCombatLockdown() then return end
	-- The route: ours, unless our Social window is off or a toast shows.
	local route = (not ns.Enabled("social") or q.displayedToast) and "click" or nil
	if s.hit:GetAttribute("type1") ~= route then s.hit:SetAttribute("type1", route) end
	local show = q:IsShown() and _G.ChatFrameMenuButton:IsVisible()
	if s.f:IsShown() ~= show then s.f:SetShown(show) end
	if s.hit:IsShown() ~= show then s.hit:SetShown(show) end
	if show then
		local k = s.f:GetEffectiveScale() / UIParent:GetEffectiveScale()
		local x, y = s.f:GetLeft(), s.f:GetBottom()
		if x and (x ~= s.x or y ~= s.y) then
			s.x, s.y = x, y
			s.hit:ClearAllPoints()
			s.hit:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x * k, y * k)
			s.hit:SetSize(SOCIAL_W * k, SOCIAL_H * k)
		end
	end
end

-- Copy and history. Neither hooks a chat window nor writes a key on one
-- (rule 15; ChatFrame1 is an Edit Mode system, rule 17): lines are read
-- from the window's own buffer (GetNumMessages, GetMessageInfo), so every
-- addon's AddMessage hook and message filter has already had its say, and
-- put back with the frame's own BackFillMessage, the call addons write
-- chat with (as AddMessage). A line the game keeps secret (rule 3: in
-- combat, in instances) is never read: skipped in the history, a
-- placeholder in the copy.
local W = Polestar.Widgets
local MARK, DIVIDER = "PolestarUIHistory", "PolestarUIHistoryDivider" -- a put-back line's extra data, after the game's three (id, access id, line id)
-- A put-back line's colour, faded toward grey (a saturated colour stays
-- readable, as a plain darkening did not): c * DIM + GREY, undone at save.
local DIM, GREY = 0.6, 0.2
-- Per window: the game's chat keeps 128 lines (SetMaxLines), all of them
-- kept; a mod that raises that is cut to the newest 500 (some 75 KB a window).
local CAP = 500
local HIDDEN = "(hidden: the game keeps this line secret)"

local function keeping() return not PolestarUICharDB.chatNoHistory end

-- The permanent windows by index (a whisper window's index is not the
-- same next session), not the combat log (ChatFrame2, IsCombatLog).
local function windows()
	local out = {}
	for i = 1, NUM_CHAT_WINDOWS or 10 do
		local f = _G["ChatFrame" .. i]
		if i ~= 2 and f and f.GetNumMessages and f.BackFillMessage then out[i] = f end
	end
	return out
end

-- The 8th of a line's values: our mark on a put-back line.
local function mark(...) return ns.Clean((select(8, ...))) end
local function old(...)
	local m = mark(...)
	return m == MARK or m == DIVIDER
end
local function round(v) return math.floor(v * 1000 + 0.5) / 1000 end

-- At logout (and /reload), each window's lines into PolestarUICharDB.chat
-- (oldest first, { text, r, g, b }): a put-back line at its own colour
-- again, the divider left out, so nothing is kept twice. A Battle.net
-- name is a token good for one session only: its link made plain text,
-- the name a placeholder.
local function save()
	if not ns.Enabled("chat") then return end
	if not keeping() then
		PolestarUICharDB.chat = nil
		return
	end
	local out = { at = time() }
	for i, f in pairs(windows()) do
		local list, n = {}, f:GetNumMessages()
		for j = math.max(1, n - CAP + 1), n do
			local text, r, g, b = f:GetMessageInfo(j)
			local m = mark(f:GetMessageInfo(j))
			text = ns.Clean(text)
			if type(text) == "string" and m ~= DIVIDER then
				local function c(v)
					v = ns.Clean(v) or 1
					return round(m == MARK and (v - GREY) / DIM or v)
				end
				text = text:gsub("|HBNplayer.-|h(.-)|h", "%1"):gsub("|K.-|k", "Battle.net friend")
				list[#list + 1] = { text, c(r), c(g), c(b) }
			end
		end
		if #list > 0 then out[i] = list end
	end
	PolestarUICharDB.chat = out
end

-- At login, the last session's lines above this one's, dimmed, under a
-- divider with the time they were saved.
local function replay()
	local h = PolestarUICharDB.chat
	if not h or not keeping() then return end
	local wins = windows()
	local r, g, b = Theme.Color("textMuted")
	for i, list in pairs(h) do
		local f = type(i) == "number" and wins[i]
		if f and #list > 0 then
			f:BackFillMessage(("- previous session, %s -"):format(date("%d %b %H:%M", h.at or time())), r, g, b, nil, nil, nil, DIVIDER)
			for j = #list, 1, -1 do
				local l = list[j]
				local function c(v) return (v or 1) * DIM + GREY end
				f:BackFillMessage(l[1], c(l[2]), c(l[3]), c(l[4]), nil, nil, nil, MARK)
			end
		end
	end
end

-- The copy window: a window's lines as plain text, colours, textures and
-- links' codes stripped (an item stays "[Name]"), oldest first, scrolled to
-- the newest. All of it selected as it opens (Ctrl+C); a drag selects a part.
local COPY_W, COPY_H, PAD = 560, 440, 20
local TOP, FOOT = 80, 52 -- the well's top and the footer's height
local WELL_W, WELL_H = COPY_W - 2 * PAD, COPY_H - TOP - FOOT
local copy

local function plain(text)
	return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn.-:", ""):gsub("|r", "")
		:gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|K.-|k", "?"))
end

local function chatText(f)
	local out, hidden = {}, 0
	for i = 1, f:GetNumMessages() do
		local text = ns.Clean((f:GetMessageInfo(i)))
		if type(text) ~= "string" then
			hidden = hidden + 1
			text = HIDDEN
		end
		out[#out + 1] = plain(text)
	end
	return table.concat(out, "\n"), hidden
end

-- The last sessions' lines out of the saved history and out of the windows.
local function clearHistory()
	PolestarUICharDB.chat = nil
	for _, f in pairs(windows()) do
		if f.RemoveMessagesByPredicate then f:RemoveMessagesByPredicate(old) end
	end
	if copy and copy:IsShown() then M.Copy(copy.chat) end
end

local function buildCopy()
	local f = CreateFrame("Frame", "PolestarUIChatCopy", UIParent)
	f:SetSize(COPY_W, COPY_H)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:Hide()
	Theme.Skin(f, "window")
	f.Close = W.IconButton(f, "close", 28, "Close", function() f:Hide() end, 14)
	f.Close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)
	f.Title = W.Text(f, "heading", "text")
	f.Title:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -18)
	f.Title:SetPoint("RIGHT", f.Close, "LEFT", -8, 0)
	f.Title:SetJustifyH("LEFT")
	f.Title:SetWordWrap(false)
	f.Hint = W.Text(f, "note", "textDim")
	f.Hint:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -50)
	f.Hint:SetWidth(WELL_W)
	f.Hint:SetJustifyH("LEFT")
	f.Hint:SetWordWrap(false)
	-- The box scrolls in its well (as Polestar's report box, UI/Report.lua).
	local well = CreateFrame("Frame", nil, f)
	well:SetSize(WELL_W, WELL_H)
	well:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -TOP)
	f.Scroll = W.Scroll(well)
	f.Scroll:SetAllPoints(well)
	f.Box = W.ScrollChild(f.Scroll, W.CopyBox(f.Scroll, { lines = 2, well = well }))
	Theme.Font(f.Box, "small")
	f.Box:SetWidth(WELL_W)
	f.Box:SetScript("OnMouseUp", nil) -- a click or drag selects what it covers, not all of it
	f.Box:SetScript("OnEscapePressed", function() f:Hide() end)
	-- The text in the box's font at its inner width: what its height is measured on.
	f.Measure = W.Text(f, "small", "text")
	f.Measure:SetWidth(WELL_W - 20)
	f.Measure:SetJustifyH("LEFT")
	f.Measure:SetWordWrap(true)
	f.Measure:SetNonSpaceWrap(true)
	f.Measure:Hide()
	-- The history's switch and its clear button.
	f.Keep = W.Switch(f, keeping, function(v) PolestarUICharDB.chatNoHistory = not v or nil end,
		"Keep each chat window's last lines across /reload and logout, on this computer only (whispers too). Off, they are forgotten at logout.")
	f.Keep:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD - 4, 14)
	f.KeepLabel = W.Text(f, "label", "text")
	f.KeepLabel:SetPoint("LEFT", f.Keep, "RIGHT", 6, 0)
	f.KeepLabel:SetText("Keep chat across sessions")
	f.Clear = W.Button(f, "Clear history", clearHistory)
	f.Clear:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, 12)
	Polestar.CloseOnEscape("PolestarUIChatCopy")
	copy = f
end

-- The selected docked window, else the first.
local function current()
	local f = GENERAL_CHAT_DOCK and FCFDock_GetSelectedWindow and FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)
	return f or _G.ChatFrame1
end

function M.Copy(f)
	f = f or current()
	if not f or not f.GetNumMessages then return end
	if not copy then buildCopy() end
	copy.chat = f
	local tab = _G[f:GetName() .. "Tab"]
	copy.Title:SetText("Copy chat: " .. (tab and tab.Text:GetText() or f:GetName()))
	local text, hidden = chatText(f)
	copy.Hint:SetText(hidden > 0 and ("%d line(s) the game keeps secret are left out. Ctrl+C copies the rest."):format(hidden)
		or "All of it is selected: Ctrl+C copies it. Drag over a part to copy only that.")
	W.SetCopyText(copy.Box, text)
	copy.Measure:SetText(text)
	local _, breaks = text:gsub("\n", "")
	local h = math.floor(math.max(copy.Measure:GetStringHeight(), (breaks + 1) * 12) + 16 + 0.5)
	copy.Box:SetHeight(h)
	W.SetScrollContent(copy.Scroll, h, WELL_H)
	W.ScrollTo(copy.Scroll, h - WELL_H)
	copy.Keep:Refresh()
	copy:Show()
	copy:Raise()
	W.SelectCopy(copy.Box)
end

-- The copy button in the side strip, above the social button (a voice
-- button's size and spacing), faded with the strip; a click copies the
-- selected docked window. Not secure: it only opens our window.
local copyButton
local function copyStrip()
	local strip = _G.ChatFrameMenuButton
	if not strip then return end
	if not copyButton and ns.Enabled("chat") then
		-- Named, for /fstack and the preview (W.IconButton makes it unnamed, on this frame).
		copyButton = CreateFrame("Frame", "PolestarUIChatCopyButton", UIParent)
		copyButton:SetSize(SOCIAL_H, SOCIAL_H)
		copyButton:SetFrameStrata("MEDIUM")
		copyButton:SetPoint("BOTTOM", social and social.f or strip, "TOP", 0, 2)
		copyButton.Button = W.IconButton(copyButton, "compact", SOCIAL_H, "Copy chat text", function() M.Copy() end, SOCIAL_ICON)
		copyButton.Button:SetAllPoints(copyButton)
	end
	if copyButton then copyButton:SetShown(ns.Enabled("chat") and strip:IsVisible()) end
end

function M.Apply()
	for _, name in ipairs(CHAT_FRAMES) do
		local f = _G[name]
		if f then
			panel(f)
			tab(_G[name .. "Tab"])
			input(f.editBox, f)
			iconButton(f.buttonFrame.minimizeButton, "chevron-down", 12)
			iconButton(f.ResizeButton, "resize", 10)
			iconButton(f.ScrollToBottomButton, "chevron-down", 12)
			scrollFlash(f.ScrollToBottomButton)
			scrollbar(f.ScrollBar)
			minimized(_G[name .. "Minimized"])
		end
	end
	header()
	strip()
	for _, b in ipairs(SIDE) do iconButton(_G[b[1]], b[2], 14, false, true) end
	socialButton()
	copyStrip()
	overflow()
	if ns.Enabled("chat") then
		bubbles()
	else
		for f, l in pairs(looks) do if l.bubble then bubble(f, false) end end
	end
	driver:SetShown(ns.Enabled("chat"))
end

function M.Enable()
	-- Ours eases each window's warmth (the game's mouse-over fade-in, read
	-- from its hasBeenFaded, or its edit box typed in), follows the edit box's
	-- focus, and shows the side strip's icons while a shown window is warm.
	driver = CreateFrame("Frame", nil, UIParent)
	-- New bubbles: no event says one opened, but only a message said aloud
	-- shows one, so the scan runs a few times a second for a second after one.
	local scan, listen = 0, 0
	for _, e in ipairs({ "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
		"CHAT_MSG_MONSTER_SAY", "CHAT_MSG_MONSTER_YELL", "CHAT_MSG_MONSTER_PARTY" }) do
		Polestar.RegisterEvent(e, function() listen = 1 end)
	end
	driver:SetScript("OnUpdate", function(_, elapsed)
		-- Off (the default): always warm; on, calm at rest (Settings, "Fade chat when idle").
		local fading = PolestarUIDB.chatFade
		if listen > 0 then
			listen = listen - elapsed
			scan = scan + elapsed
			if scan >= 0.1 then
				scan = 0
				bubbles()
			end
		end
		local warmest, docked, dockTab = 0, 0, false
		for _, name in ipairs(CHAT_FRAMES) do
			local t = _G[name .. "Tab"]
			if t and _G[name].isDocked and t:IsVisible() and t:IsMouseOver() then dockTab = true end
		end
		for f, l in pairs(looks) do
			if l.win then
				-- Also over its tab (any docked tab, docked), its edit box or our
				-- social button: the game's fade-in waits for a still mouse, and
				-- leaves at the edit box.
				local tab, e = _G[f:GetName() .. "Tab"], f.editBox
				local hot = f.hasBeenFaded or (e and (e:HasFocus() or (e:IsVisible() and e:IsMouseOver())))
					or (f.isDocked and dockTab) or (tab and tab:IsVisible() and tab:IsMouseOver())
					or (f == ChatFrame1 and social and social.hit:IsVisible() and social.hit:IsMouseOver())
					or (f == ChatFrame1 and copyButton and copyButton:IsVisible() and copyButton.Button:IsMouseOver())
				local w = (hot or not fading) and math.min(1, l.warm + elapsed / FADE_IN) or math.max(0, l.warm - elapsed / FADE_OUT)
				l.warm = w
				if w ~= l.paint or l.docked ~= f.isDocked then
					l.paint, l.docked = w, f.isDocked
					paintWarm(l, w)
				end
				if f:IsShown() and w > warmest then warmest = w end
				if f:IsShown() and f.isDocked and w > docked then docked = w end
			end
		end
		local h = looks[_G.GeneralDockManager]
		if h and h.paint ~= docked then
			h.paint = docked
			paintWarm(h, docked)
		end
		for f, l in pairs(looks) do
			if l.focus ~= nil and l.focus ~= f:HasFocus() and f:IsVisible() then
				paintFocus(f, l)
			elseif l.glyph and f:IsVisible() then
				paintState(f, l)
			end
			if l.mark then
				local a = l.dim * (l.side and warmest or 1)
				if a ~= l.shown then
					l.shown = a
					l.mark:SetAlpha(a)
				end
			end
			-- A hovered tab: the wash under its label. Label and
			-- underline faded by ours: legible at rest, full while warm (its
			-- window's warmth, the header's when docked) or hovered, under any
			-- fade above the tab (its parent's alpha).
			if l.tab then
				local over = f:IsVisible() and f:IsMouseOver() or false
				if over ~= l.over then
					l.over = over
					l.hover:SetShown(over)
					paintTab(f, l, selectedTab(f))
				end
				local win = _G["ChatFrame" .. f:GetID()]
				local wl = win and looks[win.isDocked and _G.GeneralDockManager or win]
				-- On the header: a docked tab's foot to the dock's.
				local dock, bottom = _G.GeneralDockManager, f:GetBottom()
				local dy = win and win.isDocked and bottom and dock:GetBottom() and math.floor((dock:GetBottom() - bottom) * 10 + 0.5) / 10 or 0
				if dy ~= l.dy then placeTab(f, l, dy) end
				local rest = TAB_REST[l.sel and true or false]
				local w = over and 1 or wl and wl.paint or 0
				local a = (rest + (1 - rest) * w) * (f:GetParent():GetEffectiveAlpha() or 1)
				if a ~= l.alpha then
					l.alpha = a
					f.Text:SetAlpha(a)
					l.bar:SetAlpha(a)
				end
			end
		end
		if social then paintSocial(warmest) end
		if copyButton then
			copyButton:SetAlpha(warmest)
			local show = _G.ChatFrameMenuButton:IsVisible()
			if copyButton:IsShown() ~= show then copyButton:SetShown(show) end
		end
	end)
	-- A new whisper window (a new frame the first time), a tab selected.
	if ChatFrameUtil and ChatFrameUtil.StartFlash then
		local function glyph(region, on)
			local b = region:GetParent()
			local l = looks[b]
			if l and l.glyph and region == b.Flash and ns.Enabled("chat") then
				region:SetVertexColor(0, 0, 0, 0) -- again: the game just wrote its alpha
				if on then l.glyph:SetVertexColor(Theme.Accent()) else l.glyph:SetVertexColor(Theme.Color("icon")) end
			end
		end
		hooksecurefunc(ChatFrameUtil, "StartFlash", function(region) glyph(region, true) end)
		hooksecurefunc(ChatFrameUtil, "StopFlash", function(region) glyph(region, false) end)
	end
	hooksecurefunc("FCF_OpenTemporaryWindow", function() if ns.Enabled("chat") then M.Apply() end end)
	-- A window minimised (its minimised frame made the first time).
	hooksecurefunc("FCF_MinimizeFrame", function(f) if ns.Enabled("chat") then minimized(_G[f:GetName() .. "Minimized"]) end end)
	hooksecurefunc("FCFTab_UpdateColors", function(t, selected)
		local l = looks[t]
		if l and ns.Enabled("chat") then paintTab(t, l, selected and true or false) end
	end)
	-- The window moved to the other side of the screen: its button strip with it.
	hooksecurefunc("FCF_SetButtonSide", function(f)
		local l = looks[f]
		if l and ns.Enabled("chat") then place(f, l) end
	end)
	-- Each time one of the chat's menus is built, ours is laid on it as it opens.
	for _, tag in ipairs(MENUS) do
		Menu.ModifyMenu(tag, function(_, root) root:AddMenuAcquiredCallback(menuLook) end)
	end
	-- The tab menu's "Copy chat text", under the game's items.
	Menu.ModifyMenu("MENU_FCF_TAB", function(owner, root)
		local f = ns.Enabled("chat") and owner and _G["ChatFrame" .. owner:GetID()]
		if not f then return end
		root:CreateDivider()
		root:CreateButton("Copy chat text", function() M.Copy(f) end)
	end)
	Polestar.RegisterEvent("PLAYER_LOGOUT", save)
	Polestar.RegisterEvent("ADDON_LOADED", function(_, name)
		if name == "Blizzard_CombatLog" and ns.Enabled("chat") then strip() end
	end)
	Theme.OnChanged(function() if ns.Enabled("chat") then M.Apply() end end, true)
	M.Apply()
	replay()
end

ns.Module("chat", M)
