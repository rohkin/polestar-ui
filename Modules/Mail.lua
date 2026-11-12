-- The Mail (docs/windows/mail.md): the mailbox's Inbox and Send pages in a
-- plain Polestar shell, the open letter in a flyout right of it.

local ADDON, ns = ...
local W = Polestar.Widgets
local Theme = Polestar.Theme

local NAME = "PolestarUIMail"
local ROW, LETTER_W, RECEIVE, SEND = 52, 340, 16, 12

local f, letter, send
local M = {}
local tab, open, taking = "inbox", nil, nil -- the page; the open letter; what the take loop empties (a letter, or "all")
local cod, copper = false, 0 -- the Send page's money: COD or sent, and how much
local rows = {}
local paint, codLine -- below

---------------------------------------------------------------------------
-- Taking: money and items, one per MAIL_INBOX_UPDATE
---------------------------------------------------------------------------

local function stopTaking()
	if taking == "all" then C_Mail.SetOpeningAll(false) end
	taking = nil
end

-- The next money or item of the letter being emptied; for Open all, of any
-- letter but a GM's or a COD's, which the player opens by hand (the stock
-- loop, OpenAllMailMixin). Stops when none is left.
local function takeNext()
	local n = GetInboxNumItems()
	local from, to = 1, n
	if taking ~= "all" then from, to = taking, math.min(taking, n) end
	for i = from, to do
		local _, _, _, _, money, price, _, _, _, _, _, _, gm = GetInboxHeaderInfo(i)
		if taking ~= "all" or not (gm or price > 0) then
			if money > 0 then return TakeInboxMoney(i) end
			for a = 1, RECEIVE do
				if HasInboxItem(i, a) then return TakeInboxItem(i, a) end
			end
		end
	end
	stopTaking()
end

local function startTaking(what)
	taking = what
	if what == "all" then C_Mail.SetOpeningAll(true) end
	takeNext()
end

-- A COD letter's items cost money: the dialog names the price first.
local function payFirst(i, fn)
	local price = select(6, GetInboxHeaderInfo(i))
	if price == 0 then return fn() end
	codLine = codLine or ns.Money(UIParent)
	ns.SetMoney(codLine, price, price > GetMoney() and "danger" or nil)
	ns.ModalWith({ title = "Pay for this letter?", text = "Its sender asks this much for its items (COD).", action = "Pay", onAccept = fn }, codLine)
end

---------------------------------------------------------------------------
-- The open letter (the flyout)
---------------------------------------------------------------------------

function M.Open(i)
	open = i
	paint()
end

local function discard()
	local i = open
	if not InboxItemCanDelete(i) then
		ReturnInboxItem(i)
		return M.Open(nil)
	end
	local subject = select(4, GetInboxHeaderInfo(i))
	W.Modal({ title = "Delete this letter?", text = subject, action = "Delete", danger = true,
		onAccept = function() DeleteInboxItem(i); M.Open(nil) end })
end

local function buildLetter()
	letter = ns.Flyout(f, NAME .. "Letter", LETTER_W)
	letter:Hide()
	local w = LETTER_W - 48
	letter.Close = W.IconButton(letter, "close", 28, "Close", function() M.Open(nil) end, 14)
	letter.Close:SetPoint("TOPRIGHT", letter, "TOPRIGHT", -12, -12)
	letter.Sender = W.Text(letter, "heading", "text")
	letter.Sender:SetPoint("TOPLEFT", letter, "TOPLEFT", 24, -24)
	letter.Sender:SetWidth(w - 28)
	letter.Subject = W.Text(letter, "note", "textDim")
	letter.Subject:SetPoint("TOPLEFT", letter.Sender, "BOTTOMLEFT", 0, -6)
	letter.Subject:SetWidth(w)
	letter.Text = W.Text(letter, "note", "text")
	letter.Text:SetWidth(w)
	letter.Text:SetWordWrap(true)
	letter.Text:SetJustifyH("LEFT")
	letter.Text:SetJustifyV("TOP")
	letter.Grid = ns.ItemGrid(letter, 7, 36, 4)
	letter.MoneyLabel = W.Text(letter, "small", "textDim")
	letter.Money = ns.Money(letter)
	letter.Money:SetPoint("LEFT", letter.MoneyLabel, "RIGHT", 8, 0)
	letter.Take = W.Button(letter, "Take", function() payFirst(open, function() startTaking(open) end) end, { primary = true })
	letter.Take:SetPoint("BOTTOMRIGHT", letter, "BOTTOMRIGHT", -24, 16)
	letter.Discard = W.Button(letter, "Delete", discard)
	letter.Discard:SetPoint("BOTTOMLEFT", letter, "BOTTOMLEFT", 24, 16)
	-- The dock makes room for it, and the window keeps it on screen.
	ns.DockFlyout(f, letter, 1)
end

local function paintLetter()
	letter:SetShown(open ~= nil and tab == "inbox")
	if not letter:IsShown() then return end
	local _, _, sender, subject, money, price = GetInboxHeaderInfo(open)
	letter.Sender:SetText(sender or "Unknown")
	letter.Subject:SetText(subject or "")
	-- Reading the text marks the letter read, as the stock open does.
	letter.Text:SetText(GetInboxText(open) or "")
	local y = 24 + 24 + 6 + 16 + 20
	letter.Text:ClearAllPoints()
	letter.Text:SetPoint("TOPLEFT", letter, "TOPLEFT", 24, -y)
	y = y + math.ceil(letter.Text:GetStringHeight()) + 20
	local list = {}
	for a = 1, RECEIVE do if HasInboxItem(open, a) then list[#list + 1] = a end end
	local wells = letter.Grid.Layout(#list)
	for k, well in ipairs(wells) do
		local _, _, icon, count, quality, canUse = GetInboxItem(open, list[k])
		ns.PaintItem(well, { icon = icon, quality = quality, count = count, unusable = not canUse })
		well.psAttachment = list[k]
		if not well.psMail then
			well.psMail = true
			well:SetScript("OnClick", function(self)
				local i, a = open, self.psAttachment
				payFirst(i, function() TakeInboxItem(i, a) end)
			end)
			well:HookScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetInboxItem(open, self.psAttachment)
				GameTooltip:Show()
			end)
			well:HookScript("OnLeave", function() GameTooltip:Hide() end)
		end
	end
	letter.Grid:ClearAllPoints()
	letter.Grid:SetPoint("TOPLEFT", letter, "TOPLEFT", 24, -y)
	if #list > 0 then y = y + letter.Grid:GetHeight() + 20 end
	local shown = money > 0 or price > 0
	letter.MoneyLabel:SetShown(shown)
	letter.Money:SetShown(shown)
	if shown then
		letter.MoneyLabel:SetText(price > 0 and "COD" or "Money")
		letter.MoneyLabel:ClearAllPoints()
		letter.MoneyLabel:SetPoint("TOPLEFT", letter, "TOPLEFT", 24, -y)
		ns.SetMoney(letter.Money, price > 0 and price or money, price > 0 and "danger" or nil)
	end
	ns.SetEnabled(letter.Take, money > 0 or #list > 0)
	local deletes = InboxItemCanDelete(open)
	W.SetButtonText(letter.Discard, deletes and "Delete" or "Return")
	letter.Discard.psDanger = deletes
	Theme.Repaint(letter.Discard)
	W.RepaintButton(letter.Discard)
end

---------------------------------------------------------------------------
-- Inbox
---------------------------------------------------------------------------

-- A row's tooltip, as the stock inbox's (InboxFrameItem_OnEnter): its one
-- item, or how many; the money it holds or asks (COD); when it goes.
local function rowTip(r)
	local i = r.psIndex
	local _, _, _, _, money, price, days, items = GetInboxHeaderInfo(i)
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	if items == 1 then GameTooltip:SetInboxItem(i) elseif items then GameTooltip:SetText(("Multiple items (%d)"):format(items)) else GameTooltip:SetText(r.Subject:GetText() or "") end
	if money > 0 then GameTooltip:AddLine("Enclosed money: " .. ns.Coins(money)) end
	if price > 0 then
		local r2, g, b = Theme.Color(price > GetMoney() and "danger" or "text")
		GameTooltip:AddLine("COD: " .. ns.Coins(price), r2, g, b)
	end
	local dr, dg, db = Theme.Color("textDim")
	GameTooltip:AddLine((InboxItemCanDelete(i) and "Deleted in %s" or "Returned in %s"):format(r.Days:GetText():lower()), dr, dg, db)
	ns.TooltipHint(price > 0 and "Click to open it." or "Click to open it. Shift-click takes all of it.")
	GameTooltip:Show()
end

local function row(i)
	if rows[i] then return rows[i] end
	local r = CreateFrame("Button", nil, f.psInbox)
	r:SetSize(f.BodyWidth, ROW)
	W.Hover(r)
	-- The open letter's row: the selection wash and the accent bar.
	r.Sel = r:CreateTexture(nil, "BACKGROUND")
	r.Sel:SetTexture("Interface\\Buttons\\WHITE8X8")
	r.Sel:SetAllPoints(r)
	W.Painter(r.Sel, function(t) t:SetVertexColor(Theme.Wash("selected")) end)
	r.Bar = r:CreateTexture(nil, "ARTWORK")
	r.Bar:SetTexture("Interface\\Buttons\\WHITE8X8")
	r.Bar:SetWidth(2)
	r.Bar:SetPoint("TOPLEFT")
	r.Bar:SetPoint("BOTTOMLEFT")
	W.Color(r.Bar, "accent")
	r.Well = ns.ItemWell(r, 36)
	r.Well:SetPoint("LEFT", r, "LEFT", 8, 0)
	local textW = f.BodyWidth - (8 + 36 + 12) - 200
	r.Sender = W.Text(r, "label", "text")
	r.Sender:SetPoint("TOPLEFT", r, "TOPLEFT", 8 + 36 + 12, -9)
	r.Sender:SetWidth(textW)
	r.Subject = W.Text(r, "small", "textDim")
	r.Subject:SetPoint("TOPLEFT", r.Sender, "BOTTOMLEFT", 0, -5)
	r.Subject:SetWidth(textW)
	r.Days = W.Text(r, "small", "textDim")
	r.Days:SetPoint("TOPRIGHT", r, "TOPRIGHT", -8, -9)
	r.Money = ns.Money(r)
	r.Money:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", -8, 8)
	r.COD = W.Text(r, "small", "danger")
	r.COD:SetPoint("RIGHT", r.Money, "LEFT", -6, 0)
	r.COD:SetText("COD")
	r:SetScript("OnClick", function(self)
		local i = self.psIndex
		-- Shift-click takes everything, as the stock MAILAUTOLOOTTOGGLE (never a COD's).
		if IsModifiedClick("MAILAUTOLOOTTOGGLE") and select(6, GetInboxHeaderInfo(i)) == 0 then AutoLootMailItem(i) end
		M.Open(i)
	end)
	r:SetScript("OnEnter", rowTip)
	r:SetScript("OnLeave", W.HideTooltip)
	rows[i] = r
	return r
end

local function daysLeft(d)
	if d < 1 then
		local h = math.floor(d * 24)
		return h < 1 and "Under an hour" or h == 1 and "1 hour" or h .. " hours"
	end
	local n = math.floor(d)
	return n == 1 and "1 day" or n .. " days"
end

local function paintInbox()
	local n = GetInboxNumItems()
	local pad = W.SHELL.pad
	for i = 1, n do
		local package, stationery, sender, subject, money, price, days, _, read, _, _, _, gm, first, firstLink = GetInboxHeaderInfo(i)
		local r = row(i)
		r.psIndex = i
		r:SetPoint("TOPLEFT", f.psInbox, "TOPLEFT", pad - 8, -(16 + (i - 1) * (ROW + 4)))
		ns.PaintItem(r.Well, { icon = package and not gm and package or stationery, count = first, desat = read,
			quality = firstLink and C_Item.GetItemQualityByID(firstLink) })
		-- Unread letters stand out, read ones fade, as on the stock inbox.
		r.Sender:SetText(sender or "Unknown")
		W.Color(r.Sender, read and "textDim" or "text")
		r.Subject:SetText(subject or "")
		W.Color(r.Subject, read and "textMuted" or "textDim")
		r.Sel:SetShown(open == i)
		r.Bar:SetShown(open == i)
		r.Days:SetText(daysLeft(days))
		W.Color(r.Days, days < 1 and "danger" or days < 3 and "warning" or "textDim")
		r.Money:SetShown(money > 0 or price > 0)
		r.COD:SetShown(price > 0)
		ns.SetMoney(r.Money, price > 0 and price or money, price > 0 and "danger" or nil)
		r:Show()
	end
	for i = n + 1, #rows do rows[i]:Hide() end
	W.ShellTitle(f, "Inbox", n == 0 and "No mail." or n == 1 and "1 letter." or n .. " letters.")
	W.ShellFooter(f, { { label = "Open all", onClick = function() startTaking("all") end } }, {})
	return 16 + n * (ROW + 4) + 12
end

---------------------------------------------------------------------------
-- Send
---------------------------------------------------------------------------

local function caption(parent, text, x, y)
	local t = W.Text(parent, "small", "textDim")
	t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
	t:SetText(text)
	return t
end

-- Friends and guild members, for the To field: ours, not the stock
-- autocomplete (an addon edit box has none).
local function names()
	local list, seen = {}, {}
	local function add(n) if n and not seen[n] then seen[n] = true; list[#list + 1] = n end end
	for i = 1, C_FriendList.GetNumFriends() do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		add(info and info.name)
	end
	if IsInGuild() then
		for i = 1, GetNumGuildMembers() do
			local n = GetGuildRosterInfo(i)
			add(n and Ambiguate(n, "mail"))
		end
	end
	return list
end

local function suggest(box)
	local typed, items = box:GetText():lower(), {}
	if typed ~= "" then
		for _, n in ipairs(names()) do
			local low = n:lower()
			if #items < 8 and low ~= typed and low:sub(1, #typed) == typed then
				items[#items + 1] = { text = n, onClick = function() box:SetText(n); send.Subject:SetFocus() end }
			end
		end
	end
	if #items > 0 then
		W.ShowMenu(box, items, { point = "TOPLEFT", relPoint = "BOTTOMLEFT", minWidth = box:GetWidth() })
	elseif W.MenuShown(box) then
		W.HideMenu()
	end
end

-- The message: a multi-line box scrolled in its well, following the cursor.
local BODY_H = 120
local function messageBox(parent, w)
	local well = CreateFrame("Frame", nil, parent)
	well:SetSize(w, BODY_H)
	Theme.Skin(well, "editbox")
	local sf = W.Scroll(well)
	sf:SetAllPoints(well)
	local e = W.ScrollChild(sf, CreateFrame("EditBox", nil, sf))
	well:EnableMouse(true)
	well:SetScript("OnMouseUp", function() e:SetFocus() end)
	e:SetAutoFocus(false)
	e:SetMultiLine(true)
	e:SetMaxLetters(500)
	e:SetSize(w, BODY_H)
	e:SetTextInsets(10, 10, 8, 8)
	Theme.Font(e, "label")
	W.Color(e, "text")
	e:SetScript("OnEditFocusGained", function() Theme.SetFocused(well, true) end)
	e:SetScript("OnEditFocusLost", function() Theme.SetFocused(well, false) end)
	e:SetScript("OnEscapePressed", e.ClearFocus)
	e:SetScript("OnCursorChanged", function(_, _, y, _, h)
		local at, top = sf:GetVerticalScroll(), -(y or 0)
		local bottom = top + (h or 16) + 8
		if top < at then W.ScrollTo(sf, top) elseif bottom > at + BODY_H then W.ScrollTo(sf, bottom - BODY_H) end
	end)
	e.Well = well
	return e
end

local function paintSend()
	for i, well in ipairs(send.Wells) do
		if HasSendMailItem(i) then
			local _, _, icon, count, quality = GetSendMailItem(i)
			ns.PaintItem(well, { icon = icon, quality = quality, count = count })
		else
			ns.PaintItem(well, nil)
		end
	end
	send.MoneyCaption:SetText(cod and "COD amount" or "Money to send")
	send.COD:Refresh()
	local price = GetSendMailPrice()
	ns.SetMoney(send.Postage, price, price > GetMoney() and "danger" or nil)
	W.ShellTitle(f, "Send mail", "Click a well with an item on the cursor to attach it.")
	W.ShellFooter(f, {}, { { label = "Send", onClick = function()
		SetSendMailCOD(0)
		SetSendMailMoney(0)
		if copper > 0 then
			if cod then SetSendMailCOD(copper) else SetSendMailMoney(copper) end
		end
		SendMail(send.To:GetText(), send.Subject:GetText(), send.Body:GetText())
	end, opts = { primary = true } } })
	return 24 + 18 + 30 + 20 + 18 + BODY_H + 20 + 18 + 36 + 20 + 18 + 28 + 12
end

local function buildSend()
	send = CreateFrame("Frame", nil, f.Body)
	send:SetPoint("TOPLEFT", f.Body, "TOPLEFT", 0, 0)
	send:SetSize(f.BodyWidth + 2 * W.SHELL.pad, 1)
	local x, w = W.SHELL.pad, f.BodyWidth
	local y = 24
	caption(send, "To", x, y)
	caption(send, "Subject", x + 236, y)
	send.To = ns.TextField(send, 220, 77)
	send.To:SetPoint("TOPLEFT", send, "TOPLEFT", x, -(y + 18))
	send.To:HookScript("OnTextChanged", function(self, user) if user then suggest(self) end end)
	send.Subject = ns.TextField(send, w - 236, 64)
	send.Subject:SetPoint("TOPLEFT", send, "TOPLEFT", x + 236, -(y + 18))
	y = y + 18 + 30 + 20
	caption(send, "Message", x, y)
	send.Body = messageBox(send, w)
	send.Body.Well:SetPoint("TOPLEFT", send, "TOPLEFT", x, -(y + 18))
	y = y + 18 + BODY_H + 20
	caption(send, "Attachments", x, y)
	local grid = ns.ItemGrid(send, SEND, 36, 4)
	grid:SetPoint("TOPLEFT", send, "TOPLEFT", x, -(y + 18))
	send.Wells = grid.Layout(SEND)
	for i, well in ipairs(send.Wells) do
		-- The cursor's item goes in; a right-click takes it back out.
		well:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		well:SetScript("OnClick", function(_, button) ClickSendMailItemButton(i, button == "RightButton") end)
		well:SetScript("OnReceiveDrag", function() ClickSendMailItemButton(i) end)
		well:HookScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			if HasSendMailItem(i) then GameTooltip:SetSendMailItem(i) else GameTooltip:SetText("Attachment") end
			GameTooltip:Show()
		end)
		well:HookScript("OnLeave", function() GameTooltip:Hide() end)
	end
	y = y + 18 + 36 + 20
	send.MoneyCaption = caption(send, "", x, y)
	send.Money = ns.MoneyInput(send, function(c) copper = c end)
	send.Money:SetPoint("TOPLEFT", send, "TOPLEFT", x, -(y + 18))
	send.COD = W.Switch(send, function() return cod end, function(v) cod = v; paintSend() end)
	send.COD:SetPoint("LEFT", send.Money, "RIGHT", 24, 0)
	local codText = W.Text(send, "label", "text")
	codText:SetPoint("LEFT", send.COD, "RIGHT", 8, 0)
	codText:SetText("Cash on delivery")
	caption(send, "Postage", x + w - 120, y)
	send.Postage = ns.Money(send)
	send.Postage:SetPoint("LEFT", send, "TOPLEFT", x + w - 120, -(y + 18 + 14))
end

local function resetSend()
	send.To:SetText("")
	send.Subject:SetText("")
	send.Body:SetText("")
	cod, copper = false, 0
	send.Money.Set(0)
	paint()
end

---------------------------------------------------------------------------
-- The window
---------------------------------------------------------------------------

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 760, height = 600, sidebar = 0 })
	ns.Plain(f)
	ns.Dock(f)
	ns.WindowMenu(f, "mail")
	f.psInbox = CreateFrame("Frame", nil, f.Body)
	f.psInbox:SetPoint("TOPLEFT", f.Body, "TOPLEFT", 0, 0)
	f.psInbox:SetSize(f.BodyWidth + 2 * W.SHELL.pad, 1)
	buildSend()
	buildLetter()
	-- As the stock show and hide: the read emote, the inbox fetched, the
	-- guild roster asked for (the To list reads it).
	f:HookScript("OnShow", function()
		C_ChatInfo.PerformEmote("READ", nil, true)
		CheckInbox()
		if IsInGuild() and GetNumGuildMembers() == 0 then C_GuildInfo.GuildRoster() end
	end)
	f:HookScript("OnHide", function()
		C_ChatInfo.CancelEmote()
		stopTaking()
		open = nil
	end)
	Polestar.CloseOnEscape(NAME)
end

function paint()
	W.ShellTabs(f, { { key = "inbox", label = "Inbox" }, { key = "send", label = "Send" } }, tab, function(k)
		tab = k
		paint()
	end)
	f.psInbox:SetShown(tab == "inbox")
	send:SetShown(tab == "send")
	W.ShellBody(f, tab == "inbox" and paintInbox() or paintSend())
	paintLetter()
end

function M.Show()
	if not f then build() end
	tab = "inbox"
	paint()
	f:Show()
end

function M.Enable()
	-- The mailbox is the only door: ours takes its interaction, and the stock
	-- window is never opened (docs/DESIGN.md, "NPC windows: how they open").
	ns.Interaction("mail", { Enum.PlayerInteractionType.MailInfo }, { frame = NAME, close = CloseMail, bags = true })
	local function shown() return f and f:IsShown() end
	Polestar.RegisterEvent("MAIL_INBOX_UPDATE", function()
		if taking and not C_Mail.IsCommandPending() then takeNext() end
		if shown() then paint() end
	end)
	Polestar.RegisterEvent("MAIL_SEND_INFO_UPDATE", function() if shown() then paint() end end)
	Polestar.RegisterEvent("MAIL_SEND_SUCCESS", function() if send then resetSend() end end)
	Polestar.RegisterEvent("MAIL_FAILED", stopTaking)
	Polestar.RegisterEvent("MAIL_OPEN_ALL_CANCELED", stopTaking)
	-- The game closed a letter (taken whole, or gone): its flyout goes too.
	Polestar.RegisterEvent("CLOSE_INBOX_ITEM", function(_, i)
		if taking == i then stopTaking() end
		if open == i and shown() then M.Open(nil) end
	end)
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return MailFrame and MailFrame:IsShown() and MailFrame end

ns.Module("mail", M)
