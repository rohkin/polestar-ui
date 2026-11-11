-- The game's chat windows as the client builds them (FloatingChatFrame.xml,
-- ChatFrameEditBox.xml, Blizzard_CombatLog.xml): each window's Background
-- and eight border pieces, its button frame (the same art), its tab's art and
-- glow, its edit box's art and focus pieces. Colour textures stand in for the
-- client's files. The FCF calls do what Modules/Chat.lua relies on: the
-- window alpha and colour are written into the stock pieces, a tab's
-- selected art follows FCFTab_UpdateColors, a whisper opens a new window.
-- stub.chatEvent runs the message event filters, as ChatFrame_MessageEventHandler.

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

function FCFTab_UpdateColors(tab, selected)
	for _, k in ipairs({ "ActiveLeft", "ActiveMiddle", "ActiveRight" }) do tab[k]:SetShown(selected) end
end

function FCF_StartAlertFlash(frame)
	_G[frame:GetName() .. "Tab"].glow:Show()
end

local tabs = {}
local function makeTab(id, text)
	local t = CreateFrame("Button", "ChatFrame" .. id .. "Tab", UIParent)
	t:SetSize(78, 32)
	t:SetFrameStrata("MEDIUM")
	local prev = tabs[#tabs]
	if prev then t:SetPoint("LEFT", prev, "RIGHT", 2, 0) else t:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", 0, 4) end
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
	t.glow = piece("glow", "BORDER", 1, 0.75, 0.25, 0.7)
	t.glow:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 8, 0)
	t.glow:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", -8, 0)
	t.glow:SetHeight(6)
	t.glow:Hide()
	t.Text = t:CreateFontString(nil, "ARTWORK", GameFontNormalSmall)
	t.Text:SetPoint("CENTER", t, "CENTER", 0, -5)
	t.Text:SetText(text)
	t.Text:SetTextColor(1, 0.82, 0)
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
	bordered(f, -2, 3, 15, -6)
	local b = CreateFrame("Frame", f:GetName() .. "ButtonFrame", f)
	b:SetPoint("TOPRIGHT", f, "TOPLEFT", -6, 0)
	b:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", -6, 0)
	b:SetWidth(29)
	bordered(b, -2, 3, 2, -6)
	f.buttonFrame = b
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
	table.insert(CHAT_FRAMES, f:GetName())
	makeTab(id, name)
	FCF_SetWindowColor(f, 0, 0, 0)
	FCF_SetWindowAlpha(f, 0.25)
	return f
end

makeChat(1, "General")
FCFTab_UpdateColors(ChatFrame1Tab, true)
makeChat(2, "Combat Log"):Hide()

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
