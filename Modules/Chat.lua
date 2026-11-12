-- Chat (docs/DESIGN.md, "Chat"): the game's own chat windows in Polestar's
-- look, restyled in place, never replaced: every addon that writes into them
-- (AddMessage, message filters, chat mods) still does, and the edit box,
-- which runs secure slash commands, is only drawn over. Only the art changes
-- (docs/CLIENT.md, rule 15): the stock border pieces hidden, the stock ground
-- emptied (SetTexture(nil)) but left to the game, which keeps writing the
-- player's opacity and the mouse-over fade into its alpha; our ground and
-- hairline copy that alpha each frame. The tabs', edit box's and buttons'
-- art faded with SetAlpha; textures of ours added, kept in a weak table by
-- frame (on the chat's menus, through the menu's own compositor). No
-- key is written on a stock frame, nothing is moved, sized or reparented,
-- and the messages' font stays the player's (the tabs take Polestar's face). Switched off, all of it is the game's again
-- at once.

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
local EDGES = { { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }

local looks = setmetatable({}, { __mode = "k" }) -- stock frame -> its textures of ours
local M = { noun = "chat" }
local driver

local function tex(f, layer, sub)
	local t = f:CreateTexture(nil, layer, nil, sub)
	t:SetTexture(Theme.Media("white"))
	return t
end

-- Four hairlines round region `r`, on frame `f`.
local function hairline(f, r)
	local e = {}
	for i, p in ipairs(EDGES) do
		local t = tex(f, "BORDER", 7)
		t:SetPoint(p[1], r, p[1], 0, 0)
		t:SetPoint(p[2], r, p[2], 0, 0)
		e[i] = t
	end
	return e
end

local function paintLine(e, on, r, g, b, a)
	local px = Theme.Pixel(e[1]:GetParent())
	for i, t in ipairs(e) do
		t:SetShown(on)
		t:SetVertexColor(r, g, b, a)
		if i <= 2 then t:SetHeight(px) else t:SetWidth(px) end
	end
end

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

-- The window as one Polestar window: one ground and one hairline round the
-- message area, the button strip on its side and the tab header above both,
-- the header under a divider as the guide window's tab strip; the edit box
-- hangs below as its footer (input). All of it textures of ours on the
-- window, anchored to the stock grounds: no stock frame moves.
local HEADER = 22 -- a tab's visible band: the bottom 22 of its 32, the label centred in it
local PAD = 6 -- room left of the text when the button strip is on the right

-- The button frame's ground sits 1px off the window's, level with it, on
-- the side FCF_SetButtonSide picked (re-placed from its hook).
local function place(f, l)
	local bg, side = f.Background, f.buttonFrame.Background
	local left = f.buttonSide ~= "right"
	-- shortcut: the strip's room stays while the game hides the button frame (gamepad mode); follow its OnHide if players ask.
	l.fill:ClearAllPoints()
	l.fill:SetPoint("TOPLEFT", left and side or bg, "TOPLEFT", left and 0 or -PAD, HEADER)
	l.fill:SetPoint("BOTTOMRIGHT", left and bg or side, "BOTTOMRIGHT", 0, 0)
end

-- Polestar's window ground (bg at the Background opacity setting) times the
-- alpha the game gives its own ground (the player's chat opacity, the
-- mouse-over fade): the driver copies it onto l.fade.
local function panel(f)
	local l = look(f, function()
		local l = { bg = f.Background, fill = tex(f, "BACKGROUND", -8), rule = tex(f, "BORDER", 6) }
		l.edges = hairline(f, l.fill)
		l.rule:SetPoint("TOPLEFT", l.fill, "TOPLEFT", 0, -HEADER)
		l.rule:SetPoint("TOPRIGHT", l.fill, "TOPRIGHT", 0, -HEADER)
		l.fade = { l.fill, l.rule, unpack(l.edges) }
		return l
	end)
	if not l then return end
	local on = ns.Enabled("chat")
	bare(f, on)
	bare(f.buttonFrame, on)
	place(f, l)
	local r, g, b = Theme.Color("bg")
	l.fill:SetVertexColor(r, g, b, Theme.GroundAlpha())
	l.fill:SetShown(on)
	paintLine(l.edges, on, Theme.Color("border"))
	l.rule:SetVertexColor(Theme.Wash("divider"))
	l.rule:SetHeight(Theme.Pixel(f))
	l.rule:SetShown(on)
end

-- A tab as the guide window's: no box, the label muted, the selected one in
-- the text colour over the accent bar; the hover wash (on no tab's ground
-- but a hovered one's, so hover never reads as selected).
-- A tab the game colours (a whisper's) keeps its label colour. The
-- new-message glow stays the game's, in the accent. FCFTab_UpdateColors
-- writes the label and glow colours; its hook paints ours over them.
local function paintTab(t, l, selected)
	local on = ns.Enabled("chat")
	l.bar:SetShown(on and selected)
	local c = t.selectedColorTable
	if on then
		if not c then t.Text:SetTextColor(Theme.Color(selected and "text" or "textMuted")) end
		t.glow:SetVertexColor(Theme.Accent())
	else
		local n = c or NORMAL_FONT_COLOR
		t.Text:SetTextColor(n.r, n.g, n.b)
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

-- The label in Polestar's face at the game's size: the game sizes a tab to
-- its text once, so a larger size would cut the name short.
local function tab(t)
	local l = look(t, function()
		local l = { bar = tex(t, "ARTWORK"), hover = tex(t, "HIGHLIGHT"), font = { t.Text:GetFont() } }
		-- The tab's visible band: its bottom HEADER px.
		l.hover:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 0, 0)
		l.hover:SetPoint("TOPRIGHT", t, "TOPRIGHT", 0, HEADER - 32)
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
	l.hover:SetShown(on)
	local f = l.font
	Theme.SetFace(t.Text, on and (Theme.FontSpec("small")) or f[1], f[2], f[3] or "")
	paintTab(t, l, selectedTab(t))
end

-- The edit box as the window's footer, in Polestar's input: the window's
-- ground (at the window's alpha) under the input well (inputBg), the
-- window's hairline carried round it, the window's bottom edge its divider;
-- a faint accent on that divider while typing (the driver follows the focus).
local FOOTER = 24 -- below the window's ground, the stock box's text centred in it
local function paintFocus(e, l)
	l.focus = e:HasFocus()
	l.lit:SetShown(l.focus)
end

local function input(e, f)
	local w = looks[f]
	local l = look(e, function()
		local l = { bg = f.Background, fill = tex(e, "BACKGROUND", -8), well = tex(e, "BACKGROUND", -7) }
		l.fill:SetPoint("TOPLEFT", w.fill, "BOTTOMLEFT", 0, 0)
		l.fill:SetPoint("TOPRIGHT", w.fill, "BOTTOMRIGHT", 0, 0)
		l.fill:SetHeight(FOOTER)
		l.well:SetAllPoints(l.fill)
		local edges = hairline(e, l.fill)
		l.lit = table.remove(edges, 1) -- the top edge, on the window's bottom one
		l.edges = edges
		l.fade = { l.fill, unpack(edges) }
		return l
	end)
	if not l then return end
	local on = ns.Enabled("chat")
	local name = e:GetName()
	for _, k in ipairs(INPUT) do
		local p = name and _G[name .. k]
		if p then p:SetAlpha(on and 0 or 1) end
	end
	local r, g, b = Theme.Color("bg")
	l.fill:SetVertexColor(r, g, b, Theme.GroundAlpha())
	l.fill:SetShown(on)
	l.well:SetVertexColor(Theme.Color("inputBg"))
	l.well:SetShown(on)
	paintLine(l.edges, on, Theme.Color("border"))
	r, g, b = Theme.Accent()
	paintLine({ l.lit }, on, r, g, b, 0.5)
	if on then paintFocus(e, l) else l.lit:Hide() end
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
-- one, the stock icon (a texture of its own, voice states and all) stays.
-- The driver nudges the glyph while pressed and dims it while disabled.
-- keepLit: the highlight is the game's alert pulse, kept.
local function iconButton(b, icon, size, keepLit)
	local l = look(b, function()
		local l = { hover = tex(b, "HIGHLIGHT") }
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
end

-- The driver's part: the glyph 1px down while pressed, dim while disabled.
local function paintState(b, l)
	local s = b:IsEnabled() and b:GetButtonState() or "DISABLED"
	if s == l.state then return end
	l.state = s
	l.glyph:SetPoint("CENTER", b, "CENTER", 0, s == "PUSHED" and -1 or 0)
	l.glyph:SetAlpha(s == "DISABLED" and 0.35 or 1)
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
local NINE = { "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner", "TopEdge", "BottomEdge", "LeftEdge", "RightEdge", "Center" }
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
	for _, k in ipairs(NINE) do
		local p = list.NineSlice[k]
		if p then p:SetAlpha(on and 0 or 1) end
	end
	local r, g, b = Theme.Color("bg")
	l.fill:SetVertexColor(r, g, b, Theme.GroundAlpha())
	l.fill:SetShown(on)
	paintLine(l.edges, on, Theme.Color("border"))
end

-- The chat's own menus (Blizzard_Menu, by their tags): a tab's right-click
-- menu, a channel name's, the chat menu button's (its submenus share the
-- callback). Menu frames are pooled and shared by every menu in the game,
-- so nothing of ours stays on one: our ground and hairline are attached
-- through the menu's compositor (AttachTexture, the API's own way to add
-- art), which frees them, and resets the style's art we faded, when the
-- menu closes. No other menu is touched.
local MENUS = { "MENU_FCF_TAB", "MENU_CHAT_FRAME_CHANNEL", "MENU_CHAT_SHORTCUTS" }
local function menuLook(menu)
	if not ns.Enabled("chat") then return end
	-- On acquire the menu's only regions are its style's ground (MenuStyle1: common-dropdown-bg, 10 out).
	fadeArt(true, menu:GetRegions())
	local function piece(layer, sub, r, g, b, a)
		local t = menu:AttachTexture()
		t:SetTexture(Theme.Media("white"))
		t:SetDrawLayer(layer, sub)
		t:SetVertexColor(r, g, b, a)
		return t
	end
	local r, g, b = Theme.Color("bg")
	local fill = piece("BACKGROUND", -8, r, g, b, Theme.GroundAlpha())
	-- The items sit 8 in from the top and 15 from the bottom (MenuStyle1's inset): 8 all round.
	fill:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, 0)
	fill:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", 0, 7)
	local px = Theme.Pixel(menu)
	for i, e in ipairs(EDGES) do
		local t = piece("BORDER", 7, Theme.Color("border"))
		t:SetPoint(e[1], fill, e[1], 0, 0)
		t:SetPoint(e[2], fill, e[2], 0, 0)
		if i <= 2 then t:SetHeight(px) else t:SetWidth(px) end
	end
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
	for _, k in ipairs(NINE) do
		local p = f[k]
		if p then p:SetAlpha(on and 0 or 1) end
	end
	f.Tail:SetAlpha(on and 0 or 1)
	local r, g, b = Theme.Color("bg")
	l.fill:SetVertexColor(r, g, b, Theme.GroundAlpha() * 0.85)
	l.fill:SetShown(on)
	paintLine(l.edges, on, Theme.Color("border"))
end

local function bubbles()
	for _, b in ipairs(C_ChatBubbles.GetAllChatBubbles()) do bubble((b:GetChildren()), true) end
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
			scrollbar(f.ScrollBar)
			minimized(_G[name .. "Minimized"])
		end
	end
	strip()
	for _, b in ipairs(SIDE) do iconButton(_G[b[1]], b[2], 14) end
	overflow()
	if ns.Enabled("chat") then
		bubbles()
	else
		for f, l in pairs(looks) do if l.bubble then bubble(f, false) end end
	end
	driver:SetShown(ns.Enabled("chat"))
end

function M.Enable()
	-- Ours copies the alpha the game writes into its ground (FCF_SetWindowAlpha,
	-- FCF_FadeInChatFrame's fades), and follows the edit box's focus.
	driver = CreateFrame("Frame", nil, UIParent)
	local scan = 0
	driver:SetScript("OnUpdate", function(_, elapsed)
		-- New bubbles, a few times a second (no event says one opened).
		scan = scan + elapsed
		if scan >= 0.1 then
			scan = 0
			bubbles()
		end
		for f, l in pairs(looks) do
			if l.bg then
				local a = l.bg:GetAlpha()
				if a ~= l.alpha then
					l.alpha = a
					for _, t in ipairs(l.fade) do t:SetAlpha(a) end
				end
			end
			if l.focus ~= nil and l.focus ~= f:HasFocus() and f:IsVisible() then
				paintFocus(f, l)
			elseif l.glyph and f:IsVisible() then
				paintState(f, l)
			end
		end
	end)
	-- A new whisper window (a new frame the first time), a tab selected.
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
	Polestar.RegisterEvent("ADDON_LOADED", function(_, name)
		if name == "Blizzard_CombatLog" and ns.Enabled("chat") then strip() end
	end)
	Theme.OnChanged(function() if ns.Enabled("chat") then M.Apply() end end)
	M.Apply()
end

ns.Module("chat", M)
