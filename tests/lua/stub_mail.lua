-- The client's mail for the Mail window (MailInfoDocumentation.lua and the
-- globals MailFrame.lua calls); loaded after stub_npc.lua, which makes the
-- stock MailFrame and the interaction. Takes and sends are recorded, never
-- answered: a scene fires MAIL_INBOX_UPDATE itself, one per command, as the
-- server answers each.

-- item = { name, itemID, icon, count, quality, canUse }
local function item(name, id, icon, count, quality, canUse) return { name, id, icon, count, quality, canUse ~= false } end

-- letter = { package, stationery, sender, subject, money, cod, days, read, gm, canDelete, body, items }
stub.inbox = {
	{ 133784, 134939, "Auction House", "Auction successful: Linen Cloth", 48750, 0, 29.6, false, false, true, "", {},
		-- GetInboxInvoiceInfo: type, item, player, bid, buyout, deposit, cut, delay, etaHour, etaMin, count, commerce
		invoice = { "seller", "Linen Cloth", "Arthas", 50000, 50000, 1250, 2500, 0, nil, nil, 1, false } },
	{ 133784, 134939, "Thrall", "Supplies for the front", 0, 0, 2.4, false, false, false, "Take these to Ashenvale.",
		{ [1] = item("Silk Cloth", 4306, 132905, 20, 1), [3] = item("Mageweave Cloth", 4338, 132892, 8, 1) } },
	{ 132940, 134939, "Garrosh", "The axe, as agreed", 0, 250000, 0.4, false, false, false,
		"Pay up first. The axe is yours once the gold is mine; it cuts through anything Ashenvale grows.",
		{ [1] = item("Gorehowl Replica", 9000, 132940, 1, 4), [2] = item("Heavy Runecloth Bandage", 14530, 133690, 12, 1),
			[5] = item("Mithril Spurs", 7969, 132331, 1, 2, false) } },
	{ nil, 134939, "Game Master", "Your restored items", 12000, 0, 25, true, true, false, "As promised.", {} },
}

local function letter(i) return stub.inbox[i] end
local function itemCount(l)
	local n = 0
	for a = 1, 16 do if l[12][a] then n = n + 1 end end
	return n > 0 and n or nil
end

-- The server holds stub.waiting more than the inbox shows.
stub.waiting = 0
function GetInboxNumItems() return #stub.inbox, #stub.inbox + stub.waiting end
function GetInboxHeaderInfo(i)
	local l = letter(i)
	if not l then return end
	local first, link
	for a = 1, 16 do if l[12][a] then first, link = l[12][a][4], "item:" .. l[12][a][2]; break end end
	return l[1], l[2], l[3], l[4], l[5], l[6], l[7], itemCount(l), l[8], false, l.textCreated or false, not (l[9] or l.invoice), l[9], first, link
end
function GetInboxText(i)
	stub.inbox[i][8] = true
	-- A letter with text can be copied; an invoice (l.invoice) is one.
	return stub.inbox[i][11], nil, nil, stub.inbox[i][11] ~= "", stub.inbox[i].invoice ~= nil
end
function GetInboxItem(i, a)
	local it = letter(i)[12][a]
	if it then return unpack(it) end
end
function HasInboxItem(i, a) return letter(i)[12][a] ~= nil end
function InboxItemCanDelete(i) return letter(i)[10] end

stub.checked, stub.taken, stub.returned, stub.deleted = 0, {}, {}, {}
function CheckInbox() stub.checked = stub.checked + 1 end
stub.canCheck = true
C_Mail = C_Mail or {}
function C_Mail.CanCheckInbox() return stub.canCheck, 2 end
stub.freeSlots = 10
C_Container = C_Container or {}
function C_Container.CalculateTotalNumberOfFreeBagSlots() return stub.freeSlots end
-- Each take: { letter, attachment or "money" }; a COD is paid on the first item.
function TakeInboxMoney(i)
	local l = letter(i)
	stub.money = stub.money + l[5]
	l[5] = 0
	table.insert(stub.taken, { i, "money" })
end
function TakeInboxItem(i, a)
	local l = letter(i)
	stub.money = stub.money - l[6]
	l[6] = 0
	l[12][a] = nil
	table.insert(stub.taken, { i, a })
end
-- Shift-click: everything the letter holds, at once.
function AutoLootMailItem(i)
	local l = letter(i)
	table.insert(stub.taken, { i, "all" })
	stub.money, l[5] = stub.money + l[5], 0
	l[12] = {}
end
function TakeInboxTextItem(i)
	letter(i).textCreated = true
	table.insert(stub.taken, { i, "letter" })
end
function GetInboxInvoiceInfo(i)
	local v = letter(i).invoice
	if v then return unpack(v) end
end
C_CurrencyInfo = C_CurrencyInfo or {}
function C_CurrencyInfo.GetCoinIcon() return 133784 end
function ReturnInboxItem(i) table.insert(stub.returned, table.remove(stub.inbox, i)[3]) end
function DeleteInboxItem(i) table.insert(stub.deleted, table.remove(stub.inbox, i)[3]) end

C_Mail = C_Mail or {}
stub.openingAll = false
function C_Mail.SetOpeningAll(v) stub.openingAll = v end
function C_Mail.IsCommandPending() return false end

-- Sending: the attachment slots (the cursor's item goes in), money or COD, the postage.
stub.sendItems, stub.cursor, stub.sendMoney, stub.sendCOD, stub.sent = {}, nil, 0, 0, nil
function ClickSendMailItemButton(i, clear)
	if clear then
		stub.sendItems[i] = nil
	elseif stub.cursor then
		stub.sendItems[i or #stub.sendItems + 1], stub.cursor = stub.cursor, nil
	end
end
function HasSendMailItem(i) return stub.sendItems[i] ~= nil end
function GetSendMailItem(i)
	local it = stub.sendItems[i]
	if it then return unpack(it) end
end
function GetSendMailPrice()
	local n = 0
	for a = 1, 12 do if stub.sendItems[a] then n = n + 1 end end
	return 30 * math.max(1, n)
end
function SetSendMailMoney(c) stub.sendMoney = c; return true end
function SetSendMailCOD(c) stub.sendCOD = c end
function SendMail(to, subject, body, replyID)
	stub.sent = { to = to, subject = subject, body = body, money = stub.sendMoney, cod = stub.sendCOD, replyID = replyID }
	stub.sendItems = {}
end
stub.mailItem = item
-- The Send page tells the client the bags' right-click attaches (SetSendMailShowing).
stub.sendShowing = false
function SetSendMailShowing(v) stub.sendShowing = v end
function CursorHasItem() return stub.cursor ~= nil end
-- A refundable attachment: the client asks, the answer recorded.
function RespondMailLockSendItem(slot, ok) stub.lockAnswer = { slot, ok } end
C_Item = C_Item or {}
function C_Item.GetItemInfo(link) return link == "item:12360" and "Arcanite Bar" or nil end
-- A trial account cannot send mail.
function GameLimitedMode_IsActive() return stub.trial or false end

-- The read emote: recorded, so a scene can check ours never performs it
-- (PerformEmote has restrictions).
C_ChatInfo = C_ChatInfo or {}
function C_ChatInfo.PerformEmote(e) stub.emote = e end
function C_ChatInfo.CancelEmote() stub.emote = nil end

-- Friends and guild, for the To list.
C_FriendList = C_FriendList or {}
local FRIENDS = { "Arthas", "Jaina" }
function C_FriendList.GetNumFriends() return #FRIENDS end
function C_FriendList.GetFriendInfoByIndex(i) return { name = FRIENDS[i] } end
local GUILD = { "Arator-Silvermoon", "Anduin", "Jaina" }
function IsInGuild() return true end
-- Empty until the roster is asked for, as at login.
function GetNumGuildMembers() return stub.rosterAsked and #GUILD or 0 end
function GetGuildRosterInfo(i) return GUILD[i] end
C_GuildInfo = C_GuildInfo or {}
function C_GuildInfo.GuildRoster() stub.rosterAsked = true end
function Ambiguate(name) return (name:gsub("%-.*", "")) end

-- Shift is the auto-loot toggle (MAILAUTOLOOTTOGGLE).
function IsModifiedClick(what) return IsShiftKeyDown() and (what == nil or what == "MAILAUTOLOOTTOGGLE") end
-- An attachment's quality by its link, from the inbox.
C_Item = C_Item or {}
function C_Item.GetItemQualityByID(link)
	local id = tonumber(tostring(link):match("item:(%d+)"))
	for _, l in ipairs(stub.inbox) do
		for a = 1, 16 do if l[12][a] and l[12][a][2] == id then return l[12][a][5] end end
	end
end
function GameTooltip:SetInboxItem(i, a)
	local it = letter(i)[12][a or 1]
	if not it then for k = 1, 16 do it = it or letter(i)[12][k] end end
	self:SetText(it and it[1] or "")
end
function GameTooltip:SetSendMailItem(i) self:SetText(stub.sendItems[i][1]) end
