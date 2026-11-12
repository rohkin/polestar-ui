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
local replyTo -- the letter the Send page answers (Reply), as the stock sendMode "reply"
local sending -- Send pressed: off until the server answers (MAIL_SUCCESS, MAIL_FAILED)
local autoSubject = "" -- the subject the first attachment wrote (the stock previousItem)
local MAX_COD = (MAX_COD_AMOUNT or 10000) * 10000
local rows = {}
local paint, codLine -- below

---------------------------------------------------------------------------
-- Taking: money and items, one per MAIL_INBOX_UPDATE
---------------------------------------------------------------------------

local failed = {} -- item IDs Open all could not take (MAIL_FAILED), skipped as the stock loop does

local function stopTaking()
	if taking == "all" then
		C_Mail.SetOpeningAll(false)
		failed = {}
		if f and f:IsShown() then paint() end
	end
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
				if HasInboxItem(i, a) and not (taking == "all" and failed[select(2, GetInboxItem(i, a))]) then
					-- Open all stops with the bags full, as the stock loop.
					if taking == "all" and C_Container.CalculateTotalNumberOfFreeBagSlots() == 0 then return stopTaking() end
					return TakeInboxItem(i, a)
				end
			end
		end
	end
	stopTaking()
end

local function startTaking(what)
	taking = what
	if what == "all" then
		C_Mail.SetOpeningAll(true)
		paint()
	end
	takeNext()
end

-- A COD letter's items cost money: the dialog names the price first, or says
-- the player cannot pay it (the stock COD_CONFIRMATION and COD_ALERT).
local function payFirst(i, fn)
	local price = select(6, GetInboxHeaderInfo(i))
	if price == 0 then return fn() end
	if price > GetMoney() then
		return W.Modal({ title = "Not enough money", text = ("This letter's items cost %s (COD), more than you have."):format(ns.Coins(price)), action = "OK" })
	end
	codLine = codLine or ns.Money(UIParent)
	ns.SetMoney(codLine, price, price > GetMoney() and "danger" or nil)
	ns.ModalWith({ title = "Pay for this letter?", text = "Its sender asks this much for its items (COD).", action = "Pay", onAccept = fn }, codLine)
end

---------------------------------------------------------------------------
-- The open letter (the flyout)
---------------------------------------------------------------------------

-- Closing a letter whose copy was taken and that holds nothing more deletes
-- it, as the stock OpenMailFrame's OnHide (never a pending auction sale's).
local function closing()
	if not open or open > GetInboxNumItems() then return end
	local _, _, _, _, money, _, _, items, _, _, textCreated = GetInboxHeaderInfo(open)
	local isInvoice = select(5, GetInboxText(open))
	if isInvoice and GetInboxInvoiceInfo(open) == "seller_temp_invoice" then return end
	if money == 0 and not items and textCreated then DeleteInboxItem(open) end
end

-- Fetches the inbox, at most as often as the client allows (MailMixin:RefreshInbox).
local queued
function M.RefreshInbox()
	if queued then return end
	local can, wait = C_Mail.CanCheckInbox()
	if can then return CheckInbox() end
	queued = true
	C_Timer.After(wait, function()
		queued = nil
		M.RefreshInbox()
	end)
end

function M.Open(i)
	if i ~= open then closing() end
	open = i
	paint()
end

-- Delete asks first when the letter still holds items or money (the stock
-- DELETE_MAIL and DELETE_MONEY); a letter from a player goes back instead.
local function discard()
	local i = open
	if not InboxItemCanDelete(i) then
		ReturnInboxItem(i)
		open = nil
		return M.Open(nil)
	end
	local money, items = select(5, GetInboxHeaderInfo(i)), select(8, GetInboxHeaderInfo(i))
	local text
	if items then
		for a = 1, RECEIVE do text = text or (HasInboxItem(i, a) and GetInboxItem(i, a)) end
		text = ("It still holds %s."):format(text or "items")
	elseif money > 0 then
		text = ("It still holds %s."):format(ns.Coins(money))
	end
	local function delete() DeleteInboxItem(i); open = nil; M.Open(nil) end
	if not text then return delete() end
	W.Modal({ title = "Delete this letter?", text = text, action = "Delete", danger = true, onAccept = delete })
end

-- Reply: the Send page with the sender and "RE: subject" filled, the cursor
-- in the message (OpenMailReplyMixin:Reply).
local function reply()
	local _, _, sender, subject = GetInboxHeaderInfo(open)
	local prefix = (MAIL_REPLY_PREFIX or "RE:") .. " "
	subject = subject or ""
	if subject:sub(1, #prefix) ~= prefix then subject = prefix .. subject end
	tab, replyTo = "send", open
	send.To:SetText(sender)
	send.Subject:SetText(subject)
	paint()
	send.Body:SetFocus()
end

-- The invoice under an auction's letter (the stock OpenMailInvoiceFrame), or a
-- crafting order's (ConsortiumMailFrame): label and amount lines.
local invoiceLines = {}
local function invoiceLine(k, y, label, copper, color)
	local l = invoiceLines[k]
	if not l then
		l = { label = W.Text(letter, "small", "textDim"), money = ns.Money(letter) }
		l.label:SetWidth(LETTER_W - 48)
		l.label:SetWordWrap(true)
		l.label:SetJustifyH("LEFT")
		invoiceLines[k] = l
	end
	l.label:SetText(label)
	l.label:ClearAllPoints()
	l.label:SetPoint("TOPLEFT", letter, "TOPLEFT", 24, -y)
	l.label:Show()
	l.money:SetShown(copper ~= nil)
	if copper then
		ns.SetMoney(l.money, copper, color)
		l.money:ClearAllPoints()
		l.money:SetPoint("RIGHT", letter, "TOPRIGHT", -24, -(y + 7))
	end
	return y + math.max(16, math.ceil(l.label:GetStringHeight())) + 6
end

-- The invoice's lines from y; returns the y under them.
local function paintInvoice(y, isInvoice, isConsortium)
	local k = 0
	local function line(...) k = k + 1; y = invoiceLine(k, y, ...) end
	local kind, item, who, bid, _, deposit, cut, _, etaHour, etaMin, count, commerce = nil
	if isInvoice then kind, item, who, bid, _, deposit, cut, _, etaHour, etaMin, count, commerce = GetInboxInvoiceInfo(open) end
	if kind then
		who = who or (kind == "buyer" and "Multiple sellers" or "Multiple buyers")
		if count and count > 1 then item = ("%s (%d)"):format(item, count) end
		if kind == "buyer" then
			line("Item purchased: " .. item)
			if not commerce then line("Sold by: " .. who) end
			line("Amount paid:", bid)
		else
			line("Item sold: " .. item)
			if not commerce then line("Purchased by: " .. who) end
			if kind == "seller" then
				line(count and count > 1 and ("Sale price (each of %d):"):format(count) or "Sale price:", count and count > 1 and bid / count or bid)
				line("Deposit:", deposit)
				line("Auction house cut:", cut, "danger")
				line("Amount received:", bid + deposit - cut)
			else
				line("Pending funds:", bid + deposit - cut)
				line("Not yet sent.")
				if etaHour then line(("The money arrives at %02d:%02d."):format(etaHour, etaMin or 0)) end
			end
		end
	elseif isConsortium and C_Mail.GetCraftingOrderMailInfo then
		local info = C_Mail.GetCraftingOrderMailInfo(open)
		if info then
			if info.recipeName then line("Crafting order: " .. info.recipeName) end
			if info.crafterName then line("Crafter: " .. info.crafterName) end
			if info.customerName then line("Customer: " .. info.customerName) end
			if (info.crafterNote or "") ~= "" then line(info.crafterNote) end
			if (info.commissionPaid or 0) > 0 then line("Commission:", info.commissionPaid) end
		end
	end
	for j = k + 1, #invoiceLines do invoiceLines[j].label:Hide(); invoiceLines[j].money:Hide() end
	return k > 0 and y + 14 or y
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
	letter.Sender:SetWordWrap(false)
	letter.Subject = W.Text(letter, "note", "textDim")
	letter.Subject:SetPoint("TOPLEFT", letter.Sender, "BOTTOMLEFT", 0, -6)
	letter.Subject:SetWidth(w)
	letter.Subject:SetWordWrap(false)
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
	letter.Reply = W.Button(letter, "Reply", reply)
	letter.Reply:SetPoint("RIGHT", letter.Take, "LEFT", -8, 0)
	letter.Discard = W.Button(letter, "Delete", discard)
	letter.Discard:SetPoint("BOTTOMLEFT", letter, "BOTTOMLEFT", 24, 16)
	-- The dock makes room for it, and the window keeps it on screen.
	ns.DockFlyout(f, letter, 1)
end

local function paintLetter()
	letter:SetShown(open ~= nil and tab == "inbox")
	if not letter:IsShown() then return end
	local _, stationery, sender, subject, money, price, _, _, _, _, textCreated, canReply = GetInboxHeaderInfo(open)
	-- No reply to the game's letters, to oneself, or without a sender.
	local own = sender and sender == ns.Clean(UnitName("player"))
	ns.SetEnabled(letter.Reply, sender and canReply and not own, not sender and "This letter has no sender."
		or own and "You sent this letter yourself." or "This letter cannot be answered.")
	letter.Sender:SetText(sender or "Unknown")
	letter.Subject:SetText(subject or "")
	-- Reading the text marks the letter read, as the stock open does.
	local body, _, _, takeable, isInvoice, isConsortium = GetInboxText(open)
	letter.Text:SetText(body or "")
	local y = 24 + 24 + 6 + 16 + 20
	letter.Text:ClearAllPoints()
	letter.Text:SetPoint("TOPLEFT", letter, "TOPLEFT", 24, -y)
	if (body or "") ~= "" then y = y + math.ceil(letter.Text:GetStringHeight()) + 20 end
	y = paintInvoice(y, isInvoice, isConsortium)
	-- As the stock letter: a copy of the letter to take, its money, its items.
	local list = {}
	if takeable and not textCreated then list[1] = "letter" end
	if money > 0 then list[#list + 1] = "money" end
	for a = 1, RECEIVE do if HasInboxItem(open, a) then list[#list + 1] = a end end
	local wells = letter.Grid.Layout(#list)
	for k, well in ipairs(wells) do
		local a = list[k]
		if a == "letter" then
			ns.PaintItem(well, { icon = stationery })
		elseif a == "money" then
			ns.PaintItem(well, { icon = C_CurrencyInfo.GetCoinIcon(money) })
		else
			local _, _, icon, count, quality, canUse = GetInboxItem(open, a)
			ns.PaintItem(well, { icon = icon, quality = quality, count = count, unusable = not canUse })
		end
		well.psAttachment = a
		if not well.psMail then
			well.psMail = true
			well:SetScript("OnClick", function(self)
				local i, at = open, self.psAttachment
				if at == "letter" then return TakeInboxTextItem(i) end
				if at == "money" then return TakeInboxMoney(i) end
				payFirst(i, function() TakeInboxItem(i, at) end)
			end)
			well:HookScript("OnEnter", function(self)
				local at = self.psAttachment
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				if at == "letter" then
					GameTooltip:SetText("A copy of this letter")
					ns.TooltipHint("Click to take it.")
				elseif at == "money" then
					GameTooltip:SetText(ns.Coins(select(5, GetInboxHeaderInfo(open))))
					ns.TooltipHint("Click to take it.")
				else
					GameTooltip:SetInboxItem(open, at)
					local cost = select(6, GetInboxHeaderInfo(open))
					if cost > 0 then
						local r, g, b = Theme.Color(cost > GetMoney() and "danger" or "text")
						GameTooltip:AddLine("COD: " .. ns.Coins(cost), r, g, b)
					end
				end
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
	ns.SetEnabled(letter.Take, money > 0 or select(8, GetInboxHeaderInfo(open)) ~= nil, "Nothing left to take.")
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
	r.Sender:SetWordWrap(false)
	r.Subject = W.Text(r, "small", "textDim")
	r.Subject:SetPoint("TOPLEFT", r.Sender, "BOTTOMLEFT", 0, -5)
	r.Subject:SetWidth(textW)
	r.Subject:SetWordWrap(false)
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
	-- Over 50, the rest wait at the mailbox (the stock InboxTooMuchMail).
	local _, total = GetInboxNumItems()
	W.ShellTitle(f, "Inbox", total > n and ("%d of %d letters. The rest arrive as you make room."):format(n, total)
		or n == 0 and "No mail." or n == 1 and "1 letter." or n .. " letters.")
	W.ShellFooter(f, { { label = taking == "all" and "Opening..." or "Open all", onClick = function() startTaking("all") end } }, {})
	ns.SetEnabled(f.footerButtons.left[1], taking ~= "all" and n > 0, taking == "all" and "Opening your mail now." or "No mail to open.")
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

-- Send needs a name, a subject and a COD under the cap (SendMailFrame_CanSend).
local function canSend()
	local b = f.footerButtons.right[1]
	if tab ~= "send" or not b then return end
	local over = cod and copper > MAX_COD
	send.CODError:SetShown(over)
	local why = sending and "Sending..." or (send.To:GetText() or "") == "" and "Enter who to send it to."
		or (send.Subject:GetText() or "") == "" and "Enter a subject." or over and send.CODError:GetText() or nil
	ns.SetEnabled(b, not why, why)
end

local function paintSend()
	local n, first = 0, nil
	for i, well in ipairs(send.Wells) do
		if HasSendMailItem(i) then
			local name, _, icon, count, quality = GetSendMailItem(i)
			ns.PaintItem(well, { icon = icon, quality = quality, count = count })
			n = n + 1
			first = first or name and ((count or 1) > 1 and ("%s (%d)"):format(name, count) or name)
		else
			ns.PaintItem(well, nil)
		end
	end
	-- As SendMailFrame_Update: the subject follows the first item until the
	-- player writes one; COD needs an item.
	local subject = send.Subject:GetText() or ""
	if n > 0 then
		if subject == "" or subject == autoSubject then
			autoSubject = first or ""
			send.Subject:SetText(autoSubject)
		end
	else
		if subject == autoSubject then send.Subject:SetText("") end
		autoSubject, cod = "", false
	end
	send.psNoItems = n == 0
	send.MoneyCaption:SetText(cod and "COD amount" or "Money to send")
	send.COD.psTip = send.psNoItems and "Attach an item to send it cash on delivery." or nil
	send.COD:Refresh()
	local price = GetSendMailPrice()
	ns.SetMoney(send.Postage, price, price > GetMoney() and "danger" or nil)
	W.ShellTitle(f, "Send mail", n == 0 and "No attachments." or ("%d of %d attachments."):format(n, SEND))
	W.ShellFooter(f, {}, { { label = "Send", onClick = function()
		sending = true
		canSend()
		SetSendMailCOD(0)
		SetSendMailMoney(0)
		if copper > 0 then
			if cod then SetSendMailCOD(copper) else SetSendMailMoney(copper) end
		end
		SendMail(send.To:GetText(), send.Subject:GetText(), send.Body:GetText(), replyTo)
	end, opts = { primary = true } } })
	canSend()
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
	send.To:HookScript("OnTextChanged", function(self, user)
		if user then suggest(self) end
		canSend()
	end)
	send.Subject = ns.TextField(send, w - 236, 64)
	send.Subject:SetPoint("TOPLEFT", send, "TOPLEFT", x + 236, -(y + 18))
	send.Subject:HookScript("OnTextChanged", canSend)
	y = y + 18 + 30 + 20
	caption(send, "Message", x, y)
	send.Body = messageBox(send, w)
	send.Body.Well:SetPoint("TOPLEFT", send, "TOPLEFT", x, -(y + 18))
	-- Tab walks To, Subject, Message; Enter in Subject goes on to the message.
	send.To:SetScript("OnTabPressed", function() send.Subject:SetFocus() end)
	send.Subject:SetScript("OnTabPressed", function() send.Body:SetFocus() end)
	send.Subject:SetScript("OnEnterPressed", function() send.Body:SetFocus() end)
	send.Body:SetScript("OnTabPressed", function() send.To:SetFocus() end)
	-- An item dropped anywhere on the page goes in the first free well.
	local function drop() if CursorHasItem() then ClickSendMailItemButton() end end
	send:EnableMouse(true)
	send:SetScript("OnMouseUp", drop)
	send.Body.Well:HookScript("OnMouseUp", drop)
	y = y + 18 + BODY_H + 20
	caption(send, "Attachments", x, y)
	local grid = ns.ItemGrid(send, SEND, 36, 4)
	grid:SetPoint("TOPLEFT", send, "TOPLEFT", x, -(y + 18))
	send.Wells = grid.Layout(SEND)
	for i, well in ipairs(send.Wells) do
		-- The cursor's item goes in; a right-click takes it back out.
		well:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		-- Never while a spell waits for its item: the click would pick up.
		well:SetScript("OnClick", function(_, button) if not SpellIsTargeting() then ClickSendMailItemButton(i, button == "RightButton") end end)
		well:SetScript("OnReceiveDrag", function() if not SpellIsTargeting() then ClickSendMailItemButton(i) end end)
		well:HookScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			if HasSendMailItem(i) then
				GameTooltip:SetSendMailItem(i)
				ns.TooltipHint("Right-click to take it back out.")
			else
				GameTooltip:SetText("Attachment")
				ns.TooltipHint("Drop an item here, or right-click one in your bags, to attach it.")
			end
			GameTooltip:Show()
		end)
		well:HookScript("OnLeave", function() GameTooltip:Hide() end)
	end
	y = y + 18 + 36 + 20
	send.MoneyCaption = caption(send, "", x, y)
	send.Money = ns.MoneyInput(send, function(c)
		copper = c
		canSend()
	end)
	send.Money:SetPoint("TOPLEFT", send, "TOPLEFT", x, -(y + 18))
	send.COD = W.Switch(send, function() return cod end, function(v) cod = v; paintSend() end)
	send.COD:SetPoint("LEFT", send.Money, "RIGHT", 24, 0)
	W.SetDisabledWhen(send.COD, function() return send.psNoItems end)
	-- Off without an item, saying why.
	send.COD:SetMotionScriptsWhileDisabled(true)
	local codText = W.Text(send, "label", "text")
	codText:SetPoint("LEFT", send.COD, "RIGHT", 8, 0)
	codText:SetText("Cash on delivery")
	send.CODError = W.Text(send, "small", "danger")
	send.CODError:SetPoint("TOPLEFT", send.Money, "BOTTOMLEFT", 0, -6)
	send.CODError:SetText(("A COD cannot be over %d gold."):format(MAX_COD / 10000))
	send.CODError:Hide()
	caption(send, "Postage", x + w - 120, y)
	send.Postage = ns.Money(send)
	send.Postage:SetPoint("LEFT", send, "TOPLEFT", x + w - 120, -(y + 18 + 14))
end

-- A refundable item attached: the client holds the page until the player
-- says the refund may go (MAIL_LOCK_SEND_ITEMS, the stock
-- CONFIRM_MAIL_ITEM_UNREFUNDABLE), in Polestar's dialog.
local lockSpec
local function lockAsk(_, slot, link)
	local name = link and C_Item.GetItemInfo(link) or "this item"
	lockSpec = { title = "Mail a refundable item?", action = "Mail it",
		text = ("You can no longer sell %s back for a refund once it is mailed."):format(name),
		onAccept = function() RespondMailLockSendItem(slot, true) end,
		onCancel = function() RespondMailLockSendItem(slot, false) end }
	W.Modal(lockSpec)
end
local function lockEnd()
	if lockSpec and PolestarModal and PolestarModal:IsShown() and PolestarModal.psSpec == lockSpec then PolestarModal:Hide() end
	lockSpec = nil
end

local function resetSend(quiet)
	send.To:SetText("")
	send.Subject:SetText("")
	send.Body:SetText("")
	cod, copper, autoSubject = false, 0, ""
	send.Money.Set(0)
	if not quiet then paint() end
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
	-- As the stock show and hide: the inbox fetched, the guild roster asked
	-- for (the To list reads it). Not the read emote: PerformEmote has
	-- restrictions, and ours opens from the interaction, not a click.
	f:HookScript("OnShow", function()
		M.RefreshInbox()
		if IsInGuild() and GetNumGuildMembers() == 0 then C_GuildInfo.GuildRoster() end
	end)
	f:HookScript("OnHide", function()
		stopTaking()
		closing()
		open = nil
		-- As the stock hide: the page emptied, the bags' right-click theirs again.
		SetSendMailShowing(false)
		lockEnd()
		resetSend(true)
	end)
	Polestar.CloseOnEscape(NAME)
end

function paint()
	-- Trial accounts cannot send mail: no Send page (MailMixin:UpdateTrialState).
	local trial = GameLimitedMode_IsActive()
	if trial then tab = "inbox" end
	W.ShellTabs(f, { { key = "inbox", label = "Inbox" }, not trial and { key = "send", label = "Send" } or nil }, tab, function(k)
		tab, replyTo = k, nil
		paint()
	end)
	f.psInbox:SetShown(tab == "inbox")
	send:SetShown(tab == "send")
	-- On Send, the bags' right-click attaches an item, as the stock page.
	SetSendMailShowing(tab == "send")
	W.ShellBody(f, tab == "inbox" and paintInbox() or paintSend())
	paintLetter()
end

function M.Show()
	if not f then build() end
	tab, replyTo = "inbox", nil
	paint()
	f:Show()
end

function M.Enable()
	-- The mailbox is the only door: ours takes its interaction, and the stock
	-- window is never opened (docs/DESIGN.md, "NPC windows: how they open").
	ns.Interaction("mail", { Enum.PlayerInteractionType.MailInfo }, { frame = NAME, close = CloseMail, bags = true })
	local function shown() return f and f:IsShown() end
	Polestar.RegisterEvent("MAIL_INBOX_UPDATE", function()
		-- Room made under 50 with more waiting: fetch them (InboxMixin:Update).
		local n, total = GetInboxNumItems()
		if shown() and n ~= total and n < (MAX_INBOX_SIZE or 50) then M.RefreshInbox() end
		if taking and not C_Mail.IsCommandPending() then takeNext() end
		if shown() then paint() end
	end)
	Polestar.RegisterEvent("MAIL_SEND_INFO_UPDATE", function() if shown() then paint() end end)
	Polestar.RegisterEvent("MAIL_SEND_SUCCESS", function()
		if not send then return end
		-- A reply sent goes back to the inbox, as the stock window does.
		if replyTo then tab, replyTo = "inbox", nil end
		PlaySound(SOUNDKIT.IG_ABILITY_PAGE_TURN)
		resetSend()
	end)
	Polestar.RegisterEvent("MAIL_LOCK_SEND_ITEMS", lockAsk)
	Polestar.RegisterEvent("MAIL_UNLOCK_SEND_ITEMS", lockEnd)
	Polestar.RegisterEvent("MAIL_SUCCESS", function()
		sending = nil
		if shown() then canSend() end
	end)
	Polestar.RegisterEvent("MAIL_FAILED", function(_, itemID)
		sending = nil
		-- Open all goes on past an item it could not take; one letter's take stops.
		if taking == "all" and itemID then
			failed[itemID] = true
			C_Timer.After(0.15, function() if taking == "all" and not C_Mail.IsCommandPending() then takeNext() end end)
		else
			stopTaking()
		end
		if shown() then canSend() end
	end)
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
