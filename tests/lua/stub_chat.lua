-- The game's chat windows as the client builds them (FloatingChatFrame.xml,
-- ChatFrameEditBox.xml, Blizzard_CombatLog.xml): each window's Background
-- and eight border pieces, its button frame (the same art), its tab's art and
-- glow, its edit box's art and focus pieces. Colour textures stand in for the
-- client's files. The FCF calls do what Modules/Chat.lua relies on: the
-- window alpha and colour are written into the stock pieces, a tab's
-- selected art follows FCFTab_UpdateColors, a whisper opens a new window.
-- stub.chatEvent runs the message event filters, as ChatFrame_MessageEventHandler.
-- Also each window's scroll bar, grip and scroll-to-bottom button, the side
-- buttons, a minimised window, the dock's overflow list, the chat's menus
-- (Blizzard_Menu's pooled frame) and chat bubbles.

local PIECES = { "TopLeftTexture", "BottomLeftTexture", "TopRightTexture", "BottomRightTexture", "LeftTexture", "RightTexture", "BottomTexture", "TopTexture" }
-- Each piece's anchors on the Background: corners 8 square, edges 3 thick, 4 outside it.
local AT = {
	TopLeftTexture = { { "BOTTOMRIGHT", "TOPLEFT", 4, -4 } }, TopRightTexture = { { "BOTTOMLEFT", "TOPRIGHT", -4, -4 } },
	BottomLeftTexture = { { "TOPRIGHT", "BOTTOMLEFT", 4, 4 } }, BottomRightTexture = { { "TOPLEFT", "BOTTOMRIGHT", -4, 4 } },
	LeftTexture = { { "TOPRIGHT", "TOPLEFT", -1, 0 }, { "BOTTOMRIGHT", "BOTTOMLEFT", -1, 0 } },
	RightTexture = { { "TOPLEFT", "TOPRIGHT", 1, 0 }, { "BOTTOMLEFT", "BOTTOMRIGHT", 1, 0 } },
	TopTexture = { { "BOTTOMLEFT", "TOPLEFT", 0, 1 }, { "BOTTOMRIGHT", "TOPRIGHT", 0, 1 } },
	BottomTexture = { { "TOPLEFT", "BOTTOMLEFT", 0, -1 }, { "TOPRIGHT", "BOTTOMRIGHT", 0, -1 } },
}

local function bordered(f, l, t, r, b)
	local name = f:GetName()
	local bg = f:CreateTexture(name .. "Background", "BACKGROUND")
	bg:SetPoint("TOPLEFT", f, "TOPLEFT", l, t)
	bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", r, b)
	bg:SetColorTexture(1, 1, 1, 1)
	f.Background = bg
	for _, k in ipairs(PIECES) do
		local p = f:CreateTexture(name .. k, "BORDER")
		for _, a in ipairs(AT[k]) do p:SetPoint(a[1], bg, a[2], a[3], a[4]) end
		local corner = #AT[k] == 1
		if corner or k:find("^Left") or k:find("^Right") then p:SetWidth(corner and 8 or 3) end
		if corner or k:find("^Top") or k:find("^Bottom") then p:SetHeight(corner and 8 or 3) end
		p:SetColorTexture(0.55, 0.55, 0.6, 1)
	end
end

local function each(frame, fn)
	for _, f in ipairs({ frame, frame.buttonFrame }) do
		local name = f:GetName()
		fn(f.Background)
		for _, k in ipairs(PIECES) do fn(_G[name .. k]) end
	end
end

function FCF_SetWindowAlpha(frame, alpha)
	each(frame, function(t) t:SetAlpha(alpha) end)
	frame.oldAlpha = alpha
end

function FCF_SetWindowColor(frame, r, g, b)
	each(frame, function(t) t:SetVertexColor(r, g, b) end)
end

NORMAL_FONT_COLOR = { r = 1, g = 0.82, b = 0 }
DEFAULT_TAB_SELECTED_COLOR_TABLE = { r = 1, g = 0.5, b = 0.25 }

-- The selected art, the label and glow coloured (the window's colour, else the game's gold).
function FCFTab_UpdateColors(tab, selected)
	for _, k in ipairs({ "ActiveLeft", "ActiveMiddle", "ActiveRight" }) do tab[k]:SetShown(selected) end
	local c = tab.selectedColorTable or DEFAULT_TAB_SELECTED_COLOR_TABLE
	local n = tab.selectedColorTable or NORMAL_FONT_COLOR
	if tab.Text then tab.Text:SetTextColor(n.r, n.g, n.b) end
	tab.glow:SetVertexColor(c.r, c.g, c.b)
end

-- The button frame on the window's left or right, 3 off its ground (FCF_SetButtonSide).
function FCF_SetButtonSide(frame, side)
	local b, bg = frame.buttonFrame, frame.Background
	b:ClearAllPoints()
	if side == "left" then
		b:SetPoint("TOPRIGHT", bg, "TOPLEFT", -3, -3)
		b:SetPoint("BOTTOMRIGHT", bg, "BOTTOMLEFT", -3, 6)
	else
		b:SetPoint("TOPLEFT", bg, "TOPRIGHT", 3, -3)
		b:SetPoint("BOTTOMLEFT", bg, "BOTTOMRIGHT", 3, 6)
	end
	frame.buttonSide = side
end

function FCF_StartAlertFlash(frame)
	_G[frame:GetName() .. "Tab"].glow:Show()
end

-- Button methods the chat's restyle reads.
local B = stub.Methods
B.GetDisabledTexture = B.GetDisabledTexture or function(self) return self.disabledTexture end
B.GetButtonState = B.GetButtonState or function(self) return self.buttonState or "NORMAL" end
B.SetButtonState = B.SetButtonState or function(self, s) self.buttonState = s end
B.IsForbidden = B.IsForbidden or function(self) return self.forbidden == true end

-- A stock button's art: its plate (normal), the pressed and disabled plates
-- (drawn only in their state, so hidden here) and the highlight.
local function art(b, r, g, bl)
	local function piece(layer, cr, cg, cb, ca)
		local t = b:CreateTexture(nil, layer)
		t:SetAllPoints(b)
		t:SetColorTexture(cr, cg, cb, ca)
		return t
	end
	b:SetNormalTexture(piece("ARTWORK", r, g, bl, 1))
	local p, d = piece("ARTWORK", r * 0.6, g * 0.6, bl * 0.6, 1), piece("ARTWORK", 0.3, 0.3, 0.3, 1)
	p:Hide()
	d:Hide()
	b:SetPushedTexture(p)
	b.disabledTexture = d
	b:SetHighlightTexture(piece("HIGHLIGHT", 1, 1, 1, 0.3))
	return b
end

local function button(name, parent, w, h, r, g, bl)
	local b = CreateFrame("Button", name, parent)
	b:SetSize(w, h)
	return art(b, r, g, bl)
end

-- An icon of its own (a voice button's state atlas), over the plate.
local function icon(b)
	b.Icon = b:CreateTexture(nil, "OVERLAY")
	b.Icon:SetSize(15, 15)
	b.Icon:SetPoint("CENTER", b, "CENTER", 0, 0)
	b.Icon:SetColorTexture(0.85, 0.85, 0.9, 1)
	return b
end

-- MinimalScrollBar: the track and thumb in three pieces each, the steppers' art a texture of their own.
local function scrollBar(f)
	local bar = CreateFrame("Frame", nil, f)
	bar:SetWidth(8)
	local function three(o, r, g, b)
		for _, k in ipairs({ "Begin", "Middle", "End" }) do
			local t = o:CreateTexture(nil, "ARTWORK")
			t:SetColorTexture(r, g, b, 1)
			t:SetPoint("LEFT", o, "LEFT", 0, 0)
			t:SetPoint("RIGHT", o, "RIGHT", 0, 0)
			o[k] = t
		end
		o.Begin:SetPoint("TOP", o, "TOP", 0, 0)
		o.Begin:SetHeight(4)
		o.End:SetPoint("BOTTOM", o, "BOTTOM", 0, 0)
		o.End:SetHeight(4)
		o.Middle:SetPoint("TOP", o.Begin, "BOTTOM", 0, 0)
		o.Middle:SetPoint("BOTTOM", o.End, "TOP", 0, 0)
	end
	bar.Track = CreateFrame("Frame", nil, bar)
	bar.Track:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, -13)
	bar.Track:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 13)
	three(bar.Track, 0.25, 0.22, 0.18)
	bar.Track.Thumb = CreateFrame("Button", nil, bar.Track)
	bar.Track.Thumb:SetPoint("TOPLEFT", bar.Track, "TOPLEFT", 0, -30)
	bar.Track.Thumb:SetPoint("TOPRIGHT", bar.Track, "TOPRIGHT", 0, -30)
	bar.Track.Thumb:SetHeight(23)
	three(bar.Track.Thumb, 0.8, 0.6, 0.2)
	for _, s in ipairs({ { "Back", "TOP" }, { "Forward", "BOTTOM" } }) do
		local b = CreateFrame("Button", nil, bar)
		b:SetSize(17, 11)
		b:SetPoint(s[2], bar, s[2], 0, 0)
		b.Texture = b:CreateTexture(nil, "BACKGROUND")
		b.Texture:SetAllPoints(b)
		b.Texture:SetColorTexture(0.8, 0.6, 0.2, 1)
		bar[s[1]] = b
	end
	return bar
end

local tabs = {}
local function makeTab(id, text)
	local t = CreateFrame("Button", "ChatFrame" .. id .. "Tab", UIParent)
	t:SetID(id)
	t:SetSize(20 + 7 * #text, 32)
	t:SetFrameStrata("MEDIUM")
	local prev = tabs[#tabs]
	if prev then t:SetPoint("LEFT", prev, "RIGHT", 1, 0) else t:SetPoint("BOTTOMLEFT", ChatFrame1Background, "TOPLEFT", 0, 0) end
	tabs[#tabs + 1] = t
	local function piece(k, layer, r, g, b, a)
		local p = t:CreateTexture(nil, layer)
		p:SetColorTexture(r, g, b, a)
		t[k] = p
		return p
	end
	for _, set in ipairs({ { "", "BACKGROUND", 0.12, 0.1, 0.08, 0.85 }, { "Active", "BORDER", 0.45, 0.35, 0.1, 0.6 }, { "Highlight", "HIGHLIGHT", 0.4, 0.4, 0.4, 0.4 } }) do
		local left = piece(set[1] .. "Left", set[2], set[3], set[4], set[5], set[6])
		left:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", -2, 0)
		left:SetSize(16, 24)
		local right = piece(set[1] .. "Right", set[2], set[3], set[4], set[5], set[6])
		right:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", 2, 0)
		right:SetSize(16, 24)
		local mid = piece(set[1] .. "Middle", set[2], set[3], set[4], set[5], set[6])
		mid:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
		mid:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT", 0, 0)
	end
	t.glow = piece("glow", "BORDER", 1, 1, 1, 0.7)
	t.glow:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 8, 0)
	t.glow:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", -8, 0)
	t.glow:SetHeight(6)
	t.glow:Hide()
	t.Text = t:CreateFontString(nil, "ARTWORK", GameFontNormalSmall)
	t.Text:SetPoint("CENTER", t, "CENTER", 0, -5)
	t.Text:SetText(text)
	FCFTab_UpdateColors(t, false)
	return t
end

local function makeEditBox(f)
	local name = f:GetName() .. "EditBox"
	local e = CreateFrame("EditBox", name, f)
	e:SetHeight(32)
	e:SetPoint("TOPLEFT", f, "BOTTOMLEFT", -5, -2)
	e:SetPoint("RIGHT", f, "RIGHT", 16, 0)
	e:SetFrameStrata("DIALOG")
	for _, set in ipairs({ { "", "BACKGROUND", 0.1, 0.1, 0.1, 0.9 }, { "Focus", "BORDER", 0.7, 0.7, 0.7, 1 } }) do
		local l = e:CreateTexture(name .. set[1] .. "Left", set[2])
		local r = e:CreateTexture(name .. set[1] .. "Right", set[2])
		local m = e:CreateTexture(name .. set[1] .. "Mid", set[2])
		l:SetPoint("TOPLEFT", e, "TOPLEFT", 0, -5)
		l:SetPoint("BOTTOMLEFT", e, "BOTTOMLEFT", 0, 5)
		l:SetWidth(set[1] == "" and 32 or 3)
		r:SetPoint("TOPRIGHT", e, "TOPRIGHT", 0, -5)
		r:SetPoint("BOTTOMRIGHT", e, "BOTTOMRIGHT", 0, 5)
		r:SetWidth(set[1] == "" and 32 or 3)
		if set[1] == "" then
			m:SetPoint("TOPLEFT", l, "TOPRIGHT", 0, 0)
			m:SetPoint("BOTTOMRIGHT", r, "BOTTOMLEFT", 0, 0)
		else
			m:SetPoint("TOPLEFT", l, "TOPLEFT", 0, 0)
			m:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 0)
			m:SetHeight(3)
		end
		for _, t in ipairs({ l, r, m }) do t:SetColorTexture(set[3], set[4], set[5], set[6]) end
		if set[1] == "Focus" then
			e.focusLeft, e.focusRight, e.focusMid = l, r, m
			for _, t in ipairs({ l, r, m }) do t:Hide() end
		end
	end
	e.header = e:CreateFontString(name .. "Header", "ARTWORK", ChatFontNormal)
	e.header:SetPoint("LEFT", e, "LEFT", 15, 0)
	e:Hide()
	return e
end

local filters = {}
function ChatFrame_AddMessageEventFilter(event, fn)
	filters[event] = filters[event] or {}
	table.insert(filters[event], fn)
end

-- A chat event as ChatFrame_MessageEventHandler shows it: through the
-- filters (a filter may drop it or hand back new text), then AddMessage.
function stub.chatEvent(frame, event, msg, sender)
	for _, fn in ipairs(filters[event] or {}) do
		local drop, new = fn(frame, event, msg, sender)
		if drop then return end
		msg = new or msg
	end
	frame:AddMessage(string.format("[%s] says: %s", sender, msg), 1, 1, 1)
end

-- Opening a chat line, as ChatFrameUtil.ActivateChat: shown, focused, its focus art on.
function stub.activateChat(e)
	e:Show()
	e:SetFocus()
	for _, t in ipairs({ e.focusLeft, e.focusMid, e.focusRight }) do t:Show() end
end

local function makeChat(id, name)
	local f = _G["ChatFrame" .. id] or CreateFrame("ScrollingMessageFrame", "ChatFrame" .. id, UIParent)
	f:ClearAllPoints()
	f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 70, 120)
	f:SetSize(430, 120)
	f:SetFrameStrata("LOW")
	f:SetID(id)
	f.isDocked = true
	bordered(f, -2, 3, 15, -6)
	local b = CreateFrame("Frame", f:GetName() .. "ButtonFrame", f)
	b:SetWidth(29)
	bordered(b, -2, 3, 2, -6)
	f.buttonFrame = b
	FCF_SetButtonSide(f, "left")
	f.editBox = makeEditBox(f)
	f.lines = {}
	-- ScrollingMessageFrame: the newest line at the bottom.
	function f.AddMessage(self, text, r, g, b)
		table.insert(stub.messages, tostring(text))
		local fs = self:CreateFontString(nil, "ARTWORK", ChatFontNormal)
		fs:SetText(text)
		fs:SetTextColor(r or 1, g or 1, b or 1)
		fs:SetShadowOffset(1, -1)
		fs:SetShadowColor(0, 0, 0, 1)
		table.insert(self.lines, 1, fs)
		for i, l in ipairs(self.lines) do
			l:ClearAllPoints()
			l:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 2, 4 + (i - 1) * 16)
			l:SetShown(i <= 7)
		end
	end
	-- The grip (the first window's is edit mode's, hidden), scroll to bottom (shown once scrolled up), the scroll bar.
	f.ResizeButton = button(f:GetName() .. "ResizeButton", f, 16, 16, 0.7, 0.7, 0.7)
	f.ResizeButton:SetPoint("BOTTOMRIGHT", f.Background, "BOTTOMRIGHT", 0, 0)
	f.ResizeButton:SetShown(id ~= 1)
	f.ScrollToBottomButton = button(nil, f, 17, 15, 0.8, 0.6, 0.2)
	f.ScrollToBottomButton:SetPoint("BOTTOMRIGHT", f.ResizeButton, "TOPRIGHT", -2, -2)
	f.ScrollToBottomButton.Flash = f.ScrollToBottomButton:CreateTexture(nil, "OVERLAY")
	f.ScrollToBottomButton.Flash:SetAllPoints(f.ScrollToBottomButton)
	f.ScrollToBottomButton.Flash:SetColorTexture(1, 0.9, 0.4, 0.6)
	f.ScrollToBottomButton.Flash:Hide()
	f.ScrollBar = scrollBar(f)
	f.ScrollBar:SetPoint("TOPLEFT", f, "TOPRIGHT", 0, 0)
	f.ScrollBar:SetPoint("BOTTOMLEFT", f.ScrollToBottomButton, "TOPLEFT", 0, 2)
	-- The minimise button, on undocked windows only.
	b.minimizeButton = button(b:GetName() .. "MinimizeButton", b, 32, 32, 0.6, 0.5, 0.3)
	b.minimizeButton:SetPoint("TOP", b, "TOP", 0, 4)
	b.minimizeButton:SetShown(id ~= 1 and id < 11)
	table.insert(CHAT_FRAMES, f:GetName())
	makeTab(id, name)
	FCF_SetWindowColor(f, 0, 0, 0)
	FCF_SetWindowAlpha(f, 0.25)
	return f
end

makeChat(1, "General")
FCFTab_UpdateColors(ChatFrame1Tab, true)
-- The dock (FloatingChatFrame.lua): every window docked, General selected.
GENERAL_CHAT_DOCK = { selected = ChatFrame1 }
function FCFDock_GetSelectedWindow(dock) return dock.selected end
makeChat(2, "Combat Log"):Hide()
stub.makeChat = makeChat

-- The first window's side buttons (FloatingChatFrame.xml, FloatingChatFrameVoiceChat.xml):
-- the chat menu's icon drawn into its plate, the channel and voice buttons' icons their own.
local channel = icon(button("ChatFrameChannelButton", ChatFrame1ButtonFrame, 27, 26, 0.35, 0.3, 0.25))
channel:SetPoint("TOP", ChatFrame1ButtonFrame, "TOP", 0, 0)
channel.Flash = channel:CreateTexture(nil, "OVERLAY")
channel.Flash:SetAllPoints(channel)
channel.Flash:SetColorTexture(1, 0.8, 0.3, 0.5)
channel.Flash:Hide()
local deafen = icon(button("ChatFrameToggleVoiceDeafenButton", UIParent, 27, 26, 0.35, 0.3, 0.25))
deafen:SetPoint("TOP", channel, "BOTTOM", 0, -2)
local mute = icon(button("ChatFrameToggleVoiceMuteButton", UIParent, 27, 26, 0.35, 0.3, 0.25))
mute:SetPoint("TOP", deafen, "BOTTOM", 0, -2)
button("ChatFrameMenuButton", ChatFrame1ButtonFrame, 32, 32, 0.6, 0.5, 0.3):SetPoint("BOTTOM", ChatFrame1ButtonFrame, "BOTTOM", 0, 0)

-- A window minimised (FCF_MinimizeFrame): its minimised frame, made the first time, in its place.
function FCF_MinimizeFrame(chatFrame)
	local name = chatFrame:GetName() .. "Minimized"
	local m = _G[name]
	if not m then
		m = CreateFrame("Button", name, UIParent)
		m:SetSize(180, 32)
		m:SetPoint("TOPLEFT", chatFrame, "TOPLEFT", 0, 0)
		for _, set in ipairs({ { "", "BACKGROUND", 0.12, 0.1, 0.08, 0.85 }, { "Highlight", "HIGHLIGHT", 0.4, 0.4, 0.4, 0.4 } }) do
			local l, r, mid = m:CreateTexture(nil, set[2]), m:CreateTexture(nil, set[2]), m:CreateTexture(nil, set[2])
			l:SetPoint("LEFT", m, "LEFT", 0, 0)
			l:SetSize(16, 32)
			r:SetPoint("RIGHT", m, "RIGHT", 0, 0)
			r:SetSize(16, 32)
			mid:SetPoint("TOPLEFT", l, "TOPRIGHT", 0, 0)
			mid:SetPoint("BOTTOMRIGHT", r, "BOTTOMLEFT", 0, 0)
			for _, t in ipairs({ l, r, mid }) do t:SetColorTexture(set[3], set[4], set[5], set[6]) end
			m[set[1] .. "Left"], m[set[1] .. "Right"], m[set[1] .. "Middle"] = l, r, mid
		end
		m.glow = m:CreateTexture(nil, "BORDER")
		m.glow:SetPoint("BOTTOMLEFT", m, "BOTTOMLEFT", 8, 7)
		m.glow:SetPoint("BOTTOMRIGHT", m, "BOTTOMRIGHT", -24, 7)
		m.glow:SetHeight(6)
		m.glow:SetColorTexture(1, 0.75, 0.25, 0.7)
		m.glow:Hide()
		m.Text = m:CreateFontString(nil, "ARTWORK", GameFontNormalSmall)
		m.Text:SetPoint("LEFT", m, "LEFT", 15, 0)
		m.Text:SetText(_G[chatFrame:GetName() .. "Tab"].Text:GetText())
		m.Text:SetTextColor(1, 0.82, 0)
		button(name .. "MaximizeButton", m, 25, 25, 0.6, 0.5, 0.3):SetPoint("RIGHT", m, "RIGHT", -3, 0)
	end
	m:Show()
	chatFrame:Hide()
	_G[chatFrame:GetName() .. "Tab"]:Hide()
end

-- NineSlice pieces round frame `f`: corners `c` square, edges `e` thick, the centre inside.
local NINE = { TopLeftCorner = { "TOPLEFT" }, TopRightCorner = { "TOPRIGHT" }, BottomLeftCorner = { "BOTTOMLEFT" }, BottomRightCorner = { "BOTTOMRIGHT" },
	TopEdge = { "TOPLEFT", "TOPRIGHT", "h" }, BottomEdge = { "BOTTOMLEFT", "BOTTOMRIGHT", "h" }, LeftEdge = { "TOPLEFT", "BOTTOMLEFT", "w" }, RightEdge = { "TOPRIGHT", "BOTTOMRIGHT", "w" } }
local function nine(host, f, c, e, inset, r, g, b)
	for _, k in ipairs({ "Center", "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner", "TopEdge", "BottomEdge", "LeftEdge", "RightEdge" }) do
		local a = NINE[k]
		local t = host:CreateTexture(nil, k == "Center" and "BACKGROUND" or "BORDER")
		if not a then
			t:SetPoint("TOPLEFT", f, "TOPLEFT", inset, -inset)
			t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -inset, inset)
			t:SetColorTexture(0.05, 0.05, 0.08, 0.85)
		else
			t:SetPoint(a[1], f, a[1], 0, 0)
			if a[2] then t:SetPoint(a[2], f, a[2], 0, 0) else t:SetSize(c, c) end
			if a[3] == "h" then t:SetHeight(e) elseif a[3] == "w" then t:SetWidth(e) end
			t:SetColorTexture(r, g, b, 1)
		end
		host[k] = t
	end
end

-- The dock (GeneralDockManager) and its overflow button, whose list
-- (TooltipBackdropTemplate: a NineSlice) names the docked windows.
local dock = CreateFrame("Frame", "GeneralDockManager", UIParent)
dock:SetPoint("BOTTOMLEFT", ChatFrame1Background, "TOPLEFT", 0, 0)
dock:SetPoint("BOTTOMRIGHT", ChatFrame1Background, "TOPRIGHT", 0, 0)
dock:SetHeight(26)
local over = button("GeneralDockManagerOverflowButton", dock, 16, 16, 0.8, 0.7, 0.5)
over:SetPoint("BOTTOMRIGHT", dock, "BOTTOMRIGHT", 0, 0)
over:SetAlpha(0.6)
local list = CreateFrame("Frame", "GeneralDockManagerOverflowButtonList", over)
list:SetPoint("BOTTOMLEFT", over, "BOTTOMRIGHT", 0, 0)
list:SetWidth(160)
list.NineSlice = CreateFrame("Frame", nil, list)
list.NineSlice:SetAllPoints(list)
nine(list.NineSlice, list, 8, 3, 3, 0.6, 0.6, 0.65)
list:Hide()
-- The overflow list opened (FCFDockOverflowButton_OnClick): a row per window, under its count.
function stub.openOverflow()
	local n = list:CreateFontString(nil, "ARTWORK", GameFontDisable)
	n:SetPoint("TOPLEFT", list, "TOPLEFT", 24, -5)
	n:SetText(#CHAT_FRAMES .. " chat windows")
	n:SetTextColor(0.5, 0.5, 0.5)
	for i, name in ipairs(CHAT_FRAMES) do
		local r = list:CreateFontString(nil, "ARTWORK", GameFontNormalSmall)
		r:SetPoint("TOPLEFT", list, "TOPLEFT", 25, -19 - (i - 1) * 15)
		r:SetText(_G[name .. "Tab"].Text:GetText())
		r:SetTextColor(1, 0.82, 0)
	end
	list:SetHeight(25 + #CHAT_FRAMES * 15)
	list:Show()
end

-- Blizzard_Menu as the chat's menus use it: a tagged menu's ModifyMenu
-- callbacks run as it is built; its root's acquired callbacks run on the
-- pooled menu frame (one, shared by every menu) once its style laid its
-- ground (MenuStyle1: common-dropdown-bg 10 out, 3 above and below, at
-- 92.5%). What is attached (AttachTexture) is freed when the menu closes.
local modifiers, menu, attached = {}, nil, {}
Menu = { ModifyMenu = function(tag, fn) modifiers[tag] = modifiers[tag] or {}; table.insert(modifiers[tag], fn) end }
function stub.closeMenu()
	if not menu then return end
	for _, t in ipairs(attached) do
		t:Hide()
		for i, r in ipairs(menu.regions) do if r == t then table.remove(menu.regions, i) break end end
	end
	attached = {}
	menu:Hide()
end
function stub.openMenu(owner, tag, labels)
	stub.closeMenu()
	local root = { callbacks = {} }
	function root.AddMenuAcquiredCallback(self, fn) table.insert(self.callbacks, fn) end
	for _, fn in ipairs(modifiers[tag] or {}) do fn(owner, root) end
	if not menu then
		menu = CreateFrame("Frame", "StubMenu", UIParent)
		menu:SetFrameStrata("FULLSCREEN_DIALOG")
		menu.AttachTexture = function(self)
			local t = self:CreateTexture(nil, "ARTWORK")
			table.insert(attached, t)
			return t
		end
	end
	menu:ClearAllPoints()
	menu:SetPoint("BOTTOMLEFT", owner, "TOPRIGHT", 10, 0)
	menu:SetSize(150, 8 + #labels * 20 + 15)
	local bg = menu:AttachTexture()
	bg:SetPoint("TOPLEFT", menu, "TOPLEFT", -10, 3)
	bg:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", 10, -3)
	bg:SetColorTexture(0.1, 0.1, 0.1, 1)
	bg:SetAlpha(0.925)
	for _, fn in ipairs(root.callbacks) do fn(menu) end
	for i, text in ipairs(labels) do
		local fs = menu:CreateFontString(nil, "ARTWORK", GameFontHighlight)
		fs:SetPoint("TOPLEFT", menu, "TOPLEFT", 8, -8 - (i - 1) * 20)
		fs:SetText(text)
		table.insert(attached, fs)
	end
	menu:Show()
	return menu, bg
end

-- Chat bubbles: the engine's frame (on the world) round a ChatBubbleTemplate,
-- a NineSlice panel 16 out round its text, with a tail. In an instance they
-- are forbidden, and C_ChatBubbles leaves them out.
local bubbleList = {}
C_ChatBubbles = { GetAllChatBubbles = function(includeForbidden)
	local out = {}
	for _, b in ipairs(bubbleList) do
		if b:IsShown() and (includeForbidden or not b.forbidden) then out[#out + 1] = b end
	end
	return out
end }
function stub.chatBubble(name, text, x, y, forbidden)
	local b = CreateFrame("Frame", nil, UIParent)
	b.forbidden = forbidden
	table.insert(bubbleList, b)
	local f = CreateFrame("Frame", name, b)
	f.forbidden = forbidden
	f.String = f:CreateFontString(nil, "ARTWORK", ChatFontNormal)
	f.String:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
	f.String:SetText(text)
	f:SetPoint("TOPLEFT", f.String, "TOPLEFT", -16, 16)
	f:SetPoint("BOTTOMRIGHT", f.String, "BOTTOMRIGHT", 16, -16)
	nine(f, f, 16, 6, 6, 0.75, 0.65, 0.4)
	f.Tail = f:CreateTexture(nil, "ARTWORK", nil, 7)
	f.Tail:SetSize(16, 12)
	f.Tail:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 24, 4)
	f.Tail:SetColorTexture(0.75, 0.65, 0.4, 1)
	return f
end

-- The combat log's filter strip, when Blizzard_CombatLog loads (on demand).
function stub.loadCombatLog()
	local q = CreateFrame("Frame", "CombatLogQuickButtonFrame_Custom", ChatFrame2Tab)
	local t = q:CreateTexture("CombatLogQuickButtonFrame_CustomTexture", "BACKGROUND")
	t:SetAllPoints(q)
	t:SetColorTexture(0, 0, 0, 0.7)
	q:SetPoint("BOTTOMLEFT", ChatFrame2, "TOPLEFT", 0, 3)
	q:SetPoint("BOTTOMRIGHT", ChatFrame2, "TOPRIGHT", 0, 3)
	q:SetHeight(24)
	stub.addonLoaded("Blizzard_CombatLog")
end

-- A whisper in its own window: docked, not selected, the first time a new frame.
local maxTemp = 11
function FCF_OpenTemporaryWindow(chatType, chatTarget, source, select)
	local f = makeChat(maxTemp, chatTarget)
	maxTemp = maxTemp + 1
	FCF_SetWindowAlpha(f, source and source.oldAlpha or 0.25)
	if not select then f:Hide() end
	return f
end
