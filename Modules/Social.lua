-- The Social (docs/windows/social.md): the stock FriendsFrame's Contacts and
-- Raid tabs in a Polestar shell. Quick Join, Recruit a Friend and the raid's
-- drag and ready check stay on the stock window.

local ADDON, ns = ...
local W = Polestar.Widgets
local Theme = Polestar.Theme

local NAME = "PolestarUISocial"
local ROW_H, HEAD_H, RAID_H, COL_GAP = 44, 32, 28, 24

local f, page, query = nil, "friends", ""
local collapsed, filters, lastSearch = {}, {}, nil
local M = {}
local rows, groups = {}, {}

-- A value the client may hand over secret (Battle.net names in combat, the
-- player's name): the last one read clean under `key` (docs/CLIENT.md, rule 3).
local known = {}
local function keep(key, v)
	if v ~= nil and not (issecretvalue and issecretvalue(v)) then known[key] = v end
	return known[key]
end

local function classFile(guid)
	return guid and select(2, GetPlayerInfoByGUID(guid))
end

local function lastOnline(t)
	return t and t > 0 and FriendsFrame_GetLastOnline and ("Last online %s ago"):format(FriendsFrame_GetLastOnline(t)) or "Offline"
end

-- "Lvl 24 Paladin · Zone", the class in its colour (legible) as the stock
-- card writes it; `file` nil leaves the class plain (offline).
local function detail(level, class, zone, file)
	local parts = {}
	local c = file and class and RAID_CLASS_COLORS[file]
	if c then
		local r, g, b = Theme.Legible(c.r, c.g, c.b)
		class = ("|cff%02x%02x%02x%s|r"):format(r * 255 + 0.5, g * 255 + 0.5, b * 255 + 0.5, class)
	end
	if level and level > 0 then parts[1] = ("Lvl %d %s"):format(level, class or "") end
	if zone and zone ~= "" then parts[#parts + 1] = zone end
	return table.concat(parts, " · ")
end

-- Presence as the stock social UI reads it (SocialUIUtil.GetPresenceType*).
local PRESENCE_COLOR = { online = "success", away = "warning", busy = "danger", offline = "textMuted", hidden = "textMuted" }

-- The stock list's filter menu (FriendsListTemplates.lua): status flags and
-- Battle.net friend tags, handed to C_BattleNet.SearchFriends.
local STATUS = {
	{ "isOnline", "Online" }, { "isAFK", "Away" }, { "isDND", "Busy" }, { "isOffline", "Offline" },
	{ "isInQueue", "In Queue" }, { "isAvailableForQueue", "Available For Queue" },
}
local INTERESTS = { { "Professions" }, { "PvP" }, { "Raiding" }, { "Dungeons" }, { "Delves" }, { "Questing" }, { "Roleplaying" } }
local ROLES = { { "DamagerRole", "DPS" }, { "HealerRole", "Healer" }, { "TankRole", "Tank" } }

-- A tag's enum value, nil when this game type has no such tag (Forever: no Delves).
local function tagValue(t)
	local v = Enum.BattleNetFriendTag and Enum.BattleNetFriendTag[t[1]]
	if v == nil or (C_BattleNet.IsFriendTagSupportedForCurrentGameType and not C_BattleNet.IsFriendTagSupportedForCurrentGameType(v)) then return end
	return v
end

-- The search info for the checked filters, nil when none is.
local function searchInfo()
	local info, on = { searchText = "", tags = {} }, false
	for _, o in ipairs(STATUS) do
		info[o[1]] = filters[o[1]] or false
		on = on or info[o[1]]
	end
	for _, list in ipairs({ INTERESTS, ROLES }) do
		for _, t in ipairs(list) do
			local v = filters[t[1]] and tagValue(t)
			if v then info.tags[#info.tags + 1] = v; on = true end
		end
	end
	return on and info or nil
end

-- WoW friends have no tags or queue state: only the presence filters keep them.
local function wowShown(info, connected, afk, dnd)
	if not info then return true end
	if #info.tags > 0 or info.isInQueue or info.isAvailableForQueue then return false end
	return (info.isOnline and connected) or (info.isAFK and afk) or (info.isDND and dnd) or (info.isOffline and not connected) or false
end

-- The friends list as the stock one orders it (FriendsList_Update): Battle.net
-- favorites, then online Battle.net and WoW friends, then offline ones; the
-- client already lists each kind online first, favorites first.
local function friends()
	local list, filter = {}, searchInfo()
	-- The client's own filter for Battle.net friends (presence, queue, tags);
	-- in combat the last result stands.
	local bnShown
	if filter then
		if not InCombatLockdown() then
			lastSearch = {}
			for _, i in ipairs(C_BattleNet.SearchFriends(filter) or {}) do lastSearch[i] = true end
		end
		bnShown = lastSearch or {}
	end
	for i = 1, C_FriendList.GetNumFriends() do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info and wowShown(filter, info.connected, info.afk, info.dnd) then
			list[#list + 1] = { name = info.name, online = info.connected, class = classFile(info.guid),
				rank = info.connected and 2 or 4, order = i, canInvite = info.connected,
				status = not info.connected and "offline" or info.dnd and "busy" or info.afk and "away" or "online",
				sub = info.connected and detail(info.level, info.className, info.area, classFile(info.guid)) or "Offline",
				whisper = function() ChatFrameUtil.SendTell(info.name) end,
				invite = function() C_PartyInfo.InviteUnit(info.name) end,
				menu = function() FriendsFrame_ShowDropdown(info.name, info.connected, nil, nil, nil, 1, nil, nil, nil, nil, info.guid) end }
		end
	end
	for i = 1, (BNGetNumFriends()) do
		local a = C_BattleNet.GetFriendAccountInfo(i)
		if a then
			local g, id = a.gameAccountInfo or {}, a.bnetAccountID
			local name = keep("bn" .. id, a.accountName) or a.battleTag or ""
			local char = keep("bnc" .. id, g.characterName)
			local sub
			if not g.isOnline then
				sub = lastOnline(a.lastOnlineTime)
			elseif char then
				sub = char .. " · " .. detail(g.characterLevel, g.className, keep("bnz" .. id, g.areaName), classFile(g.playerGuid))
			else
				sub = keep("bnr" .. id, g.richPresence) or "Online"
			end
			local status = not g.isOnline and "offline" or (a.isAFK or g.isGameAFK) and "away" or (a.isDND or g.isGameBusy) and "busy" or "online"
			-- Favorites are set from the right-click menu, as in the stock list.
			-- The client's own icon (Battle.net app, WoW...), faded for another WoW project, as the stock card.
			local client = g.isOnline and g.clientProgram ~= "" and g.clientProgram or nil
			if not bnShown or bnShown[i] then list[#list + 1] = { name = name, char = char, online = g.isOnline, sub = sub,
				client = client, subIcon = g.subIcon, faded = client == BNET_CLIENT_WOW and g.wowProjectID ~= WOW_PROJECT_ID,
				bnet = true, favorite = a.isFavorite, rank = a.isFavorite and 0 or g.isOnline and 1 or 3, order = 1000 + i,
				status = status, canInvite = g.isOnline and char ~= nil,
				whisper = function() ChatFrameUtil.SendBNetTell(name) end,
				invite = function() FriendsFrame_BattlenetInviteByIndex(i) end,
				menu = function() FriendsFrame_ShowBNDropdown(name, g.isOnline, nil, nil, nil, 1, id, nil, nil, nil, nil, a.battleTag) end } end
		end
	end
	table.sort(list, function(x, y)
		if x.rank ~= y.rank then return x.rank < y.rank end
		return x.order < y.order
	end)
	return list
end

-- Pending Battle.net friend requests, above the friends as in the stock list.
local function requests()
	local list = {}
	for i = 1, BNGetNumFriendInvites() do
		local inv = C_BattleNet.GetFriendInviteInfo(i)
		if inv then
			list[#list + 1] = { name = keep("inv" .. inv.inviteID, inv.accountName) or "", online = true, bnet = true,
				sub = "Wants to be your Battle.net friend", request = inv.inviteID }
		end
	end
	return list
end

-- Recent allies (C_RecentAllies, presorted by the client: pinned, online, latest).
local function allies()
	local list = {}
	if not C_RecentAllies.IsRecentAllyDataReady() then return list end
	for _, a in ipairs(C_RecentAllies.GetRecentAllies() or {}) do
		local c, st = a.characterData, a.stateData
		local cls = C_CreatureInfo.GetClassInfo(c.classID)
		local recent = a.interactionData and a.interactionData.interactions and a.interactionData.interactions[1]
		local parts = { detail(c.level, cls and cls.className, st.isOnline and st.currentLocation, st.isOnline and cls and cls.classFile) }
		if recent and recent.description and recent.description ~= "" then parts[2] = recent.description end
		local full = c.fullName
		list[#list + 1] = { name = c.name or full, online = st.isOnline, class = cls and cls.classFile,
			sub = table.concat(parts, " · "),
			whisper = function() ChatFrameUtil.SendTell(full) end,
			invite = function() C_PartyInfo.InviteUnit(full) end,
			menu = function()
				UnitPopup_OpenMenu(st.isOnline and "RECENT_ALLY" or "RECENT_ALLY_OFFLINE",
					{ recentAllyData = a, name = full, guid = c.guid, isOffline = not st.isOnline })
			end }
	end
	return list
end

local function alliesOn() return C_RecentAllies and C_RecentAllies.IsSystemEnabled() end

local function ignored()
	local list = {}
	for i = 1, C_FriendList.GetNumIgnores() do
		local name = C_FriendList.GetIgnoreName(i)
		if name then list[#list + 1] = { name = name, online = true, sub = "", unignore = name } end
	end
	return list
end

local function matches(e)
	return query == "" or e.name:lower():find(query, 1, true) or (e.char and e.char:lower():find(query, 1, true))
end

-- The stock list's two folding groups, Favorites and Friends, each headed
-- "online/total" of the friends shown; requests stay above them.
local function withHeads(list)
	local out = {}
	local heads = { fav = { head = "Favorites", key = "fav", kids = {} }, all = { head = "Friends", key = "all", kids = {} } }
	for _, e in ipairs(list) do
		local h = not e.request and heads[e.favorite and "fav" or "all"]
		if h then h.kids[#h.kids + 1] = e else out[#out + 1] = e end
	end
	for _, h in ipairs({ heads.fav, heads.all }) do
		if #h.kids > 0 then
			local on = 0
			for _, e in ipairs(h.kids) do if e.online then on = on + 1 end end
			h.name, h.online = ("%s %d/%d"):format(h.head, on, #h.kids), true
			out[#out + 1] = h
			if not collapsed[h.key] then for _, e in ipairs(h.kids) do out[#out + 1] = e end end
		end
	end
	return out
end

---------------------------------------------------------------------------
-- Friend rows: name over a detail line, in one row panel.

-- A click whispers only once no second click made it a double-click (invite).
local DOUBLE_CLICK = 0.3

local function rowEnter(r)
	local e = r.psEntry
	if not e.whisper then return end
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:SetText(e.name)
	ns.TooltipHint("Click to whisper. Double-click to invite to your group. Right-click for more.")
	GameTooltip:Show()
end

local function newRow(panel, i)
	local r = CreateFrame("Button", nil, panel)
	r:SetHeight(ROW_H)
	r:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -(i - 1) * ROW_H)
	r:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
	if i > 1 then
		local d = W.Divider(r)
		d:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
		d:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 0)
	end
	W.Hover(r)
	-- A group heading's fold chevron; a friend's presence pip in the corner, as the stock card.
	r.Chevron = W.Tex(r, "ARTWORK", "chevron-down", "textDim")
	r.Chevron:SetSize(12, 12)
	r.Chevron:SetPoint("LEFT", r, "LEFT", 16, 0)
	r.Pip = W.Tex(r, "OVERLAY", "circle", "success")
	r.Pip:SetSize(8, 8)
	r.Pip:SetPoint("TOPLEFT", r, "TOPLEFT", 5, -5)
	r.Name = W.Text(r, "body", "text")
	r.Sub = W.Text(r, "small", "textDim")
	r.Sub:SetPoint("TOPLEFT", r, "LEFT", 16, -3)
	for _, t in ipairs({ r.Name, r.Sub }) do t:SetJustifyH("LEFT") end
	-- Fixed slots at the right, so they line up down the list: the friend's
	-- client icon (the game's own), then the invite button. A favorite's star
	-- follows the name (the stock card's atlases).
	r.Invite = W.IconButton(r, "plus", 24, "Invite to group", function(self) self:GetParent().psEntry.invite() end)
	r.Invite:SetPoint("RIGHT", r, "RIGHT", -12, 0)
	if r.Invite.SetMotionScriptsWhileDisabled then r.Invite:SetMotionScriptsWhileDisabled(true) end
	r.Client = r:CreateTexture(nil, "ARTWORK")
	r.Client:SetSize(20, 20)
	r.Client:SetPoint("RIGHT", r.Invite, "LEFT", -6, 0)
	r.Fav = r:CreateTexture(nil, "ARTWORK")
	r.Fav:SetSize(14, 14)
	r.Remove = W.IconButton(r, "close", 24, "Stop ignoring", function(self)
		C_FriendList.DelIgnore(self:GetParent().psEntry.unignore)
		M.Show() -- at once, not on the client's event (docs/CLIENT.md, rule 6)
	end)
	r.Remove:SetPoint("RIGHT", r, "RIGHT", -12, 0)
	r.Decline = W.Button(r, "Decline", function(self)
		BNDeclineFriendInvite(self:GetParent().psEntry.request)
		M.Show()
	end)
	r.Decline:SetWidth(84)
	r.Decline:SetPoint("RIGHT", r, "RIGHT", -12, 0)
	r.Accept = W.Button(r, "Accept", function(self)
		BNAcceptFriendInvite(self:GetParent().psEntry.request)
		M.Show()
	end, { primary = true })
	r.Accept:SetWidth(84)
	r.Accept:SetPoint("RIGHT", r.Decline, "LEFT", -8, 0)
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	r:SetScript("OnClick", function(self, button)
		local e = self.psEntry
		if e.head then
			collapsed[e.key] = not collapsed[e.key] or nil
			return M.Show() -- at once (docs/CLIENT.md, rule 6)
		end
		if not e.whisper then return end
		if button == "RightButton" then return e.menu() end
		if self.psWhisper then self.psWhisper:Cancel() end
		self.psWhisper = C_Timer.NewTimer(DOUBLE_CLICK, function() self.psWhisper = nil; e.whisper() end)
	end)
	r:SetScript("OnDoubleClick", function(self, button)
		if button == "RightButton" or not self.psEntry.invite then return end
		if self.psWhisper then self.psWhisper:Cancel(); self.psWhisper = nil end
		self.psEntry.invite()
	end)
	r:SetScript("OnEnter", rowEnter)
	r:SetScript("OnLeave", W.HideTooltip)
	return r
end

local function paintName(t, class, dim)
	local c = class and RAID_CLASS_COLORS[class]
	W.Uncolor(t)
	if c and not dim then t:SetTextColor(Theme.Legible(c.r, c.g, c.b)) else W.Color(t, dim and "textMuted" or "text") end
end

local function paintRows(list)
	local p, y = f.psPanel, 0
	for i, e in ipairs(list) do
		local r = rows[i] or newRow(p, i)
		rows[i] = r
		r.psEntry = e
		r:SetHeight(e.head and HEAD_H or ROW_H)
		r:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -y)
		y = y + r:GetHeight()
		r.Name:SetText(e.name)
		if e.head then W.Uncolor(r.Name); W.Color(r.Name, "textDim") else paintName(r.Name, e.class, not e.online) end
		r.Chevron:SetShown(e.head ~= nil)
		r.Chevron:SetTexture(Theme.Media(collapsed[e.key] and "chevron-right" or "chevron-down"))
		r.Pip:SetShown(e.status ~= nil)
		if e.status then W.Color(r.Pip, PRESENCE_COLOR[e.status]) end
		r.Invite:SetShown(e.status ~= nil)
		if e.status then
			-- Disabled: a faint glyph and a tooltip saying why.
			W.SetIconState(r.Invite, false, e.canInvite)
			r.Invite.psTip = e.canInvite and "Invite to group" or not e.online and "Offline: can't invite" or "Not in this game: can't invite"
		end
		local sub = e.sub or ""
		r.Sub:SetText(sub)
		W.Color(r.Sub, e.online and "textDim" or "textMuted")
		r.Sub:SetShown(sub ~= "")
		local right = e.request and 200 or e.status and 80 or 64
		r.Name:ClearAllPoints()
		r.Name:SetPoint(sub ~= "" and "BOTTOMLEFT" or "LEFT", r, "LEFT", e.head and 36 or 16, sub ~= "" and 1 or 0)
		r.Name:SetPoint("RIGHT", r, "RIGHT", -right, 0)
		r.Sub:SetPoint("RIGHT", r, "RIGHT", -right, 0)
		local client = e.client and C_Texture and C_Texture.SetTitleIconTexture and Enum.TitleIconVersion
		if client then
			C_Texture.SetTitleIconTexture(r.Client, e.client, Enum.TitleIconVersion.Small, e.subIcon)
			r.Client:SetAlpha(e.faded and 0.6 or 1)
		end
		r.Client:SetShown(client and true or false)
		r.Fav:SetShown(e.favorite or false)
		if e.favorite then
			r.Fav:SetAtlas(e.online and "friends-icon-favorites" or "friends-icon-favorites-dis")
			r.Fav:ClearAllPoints()
			r.Fav:SetPoint("LEFT", r.Name, "LEFT", math.min(r.Name:GetStringWidth(), r.Name:GetWidth()) + 4, 0)
		end
		r.Remove:SetShown(e.unignore ~= nil)
		r.Accept:SetShown(e.request ~= nil)
		r.Decline:SetShown(e.request ~= nil)
		r:Show()
	end
	for i = #list + 1, #rows do rows[i]:Hide() end
	p:SetHeight(math.max(1, y))
	p:SetShown(#list > 0)
	f.psEmpty:SetShown(#list == 0)
	return 24 + y + 24
end

---------------------------------------------------------------------------
-- Raid: the eight groups in two columns, read only.

local function raidGroup(i)
	local g = groups[i]
	if g then return g end
	g = { Head = W.SectionHeader(f.Body, { plain = true }), Panel = W.RowPanel(f.Body), rows = {} }
	for k = 1, 5 do
		local r = CreateFrame("Frame", nil, g.Panel)
		r:SetHeight(RAID_H)
		r:SetPoint("TOPLEFT", g.Panel, "TOPLEFT", 0, -(k - 1) * RAID_H)
		r:SetPoint("RIGHT", g.Panel, "RIGHT", 0, 0)
		if k > 1 then
			local d = W.Divider(r)
			d:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
			d:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 0)
		end
		r.Role = W.Text(r, "small", "textDim")
		r.Role:SetPoint("RIGHT", r, "RIGHT", -12, 0)
		r.Name = W.Text(r, "label", "text")
		r.Name:SetPoint("LEFT", r, "LEFT", 12, 0)
		r.Name:SetPoint("RIGHT", r.Role, "LEFT", -8, 0)
		r.Name:SetJustifyH("LEFT")
		g.rows[k] = r
	end
	groups[i] = g
	return g
end

local function paintRaid()
	local members = {}
	for i = 1, 8 do members[i] = {} end
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local name, _, sub, _, _, class, _, online, _, _, _, role = GetRaidRosterInfo(i)
			if name and members[sub] then
				local m = members[sub]
				m[#m + 1] = { name = keep("raid" .. i, name) or "", class = class, online = online, role = role }
			end
		end
	end
	local col = (f.BodyWidth - COL_GAP) / 2
	local y = { 24, 24 }
	for i = 1, 8 do
		local g, c = raidGroup(i), i <= 4 and 1 or 2
		local x = W.SHELL.pad + (c - 1) * (col + COL_GAP)
		W.SetSection(g.Head, ("Group %d"):format(i))
		g.Head:SetWidth(col)
		g.Head:SetPoint("TOPLEFT", f.Body, "TOPLEFT", x, -y[c])
		g.Panel:SetWidth(col)
		g.Panel:SetPoint("TOPLEFT", f.Body, "TOPLEFT", x, -(y[c] + W.PLAIN_SECTION_H))
		g.Panel:SetHeight(5 * RAID_H)
		for k, r in ipairs(g.rows) do
			local m = members[i][k]
			r.Name:SetText(m and m.name or "")
			if m then paintName(r.Name, m.class, not m.online) end
			r.Role:SetText(m and m.role and m.role ~= "NONE" and _G[m.role] or "")
		end
		g.Head:Show()
		g.Panel:Show()
		y[c] = y[c] + W.PLAIN_SECTION_H + 5 * RAID_H + 16
	end
	return math.max(y[1], y[2]) + 8
end

---------------------------------------------------------------------------
-- The window.

-- The Nothing Lost Rule: what stays on the stock window, and the way to it.
local optionsItems = {
	{ text = "Game's window: the friends button by the chat, or /friends", disabled = true },
	{ text = "There: Quick Join, Recruit a Friend, and the raid's groups and ready check", disabled = true },
}

-- A one-line field for a modal's body; Enter takes the modal's action.
local function fieldBody()
	local body = CreateFrame("Frame", nil, f)
	body:SetSize(352, 30)
	local e = ns.TextField(body, 352)
	e:SetAllPoints(body)
	e:SetScript("OnEnterPressed", function() PolestarModal.Box.Action:Click() end)
	body.Box = e
	return body
end

local function addFriend()
	f.psAdd = f.psAdd or fieldBody()
	local e = f.psAdd.Box
	e:SetText("")
	ns.ModalWith({ title = "Add friend", text = "A character's name, or a BattleTag (Name#1234) for Battle.net.", action = "Add",
		onAccept = function()
			local name = strtrim(e:GetText() or "")
			if name == "" then return end
			-- As the stock dialog decides (AddFriendTemplates.lua).
			if name:find("#", 1, true) then BNSendFriendInvite(name, "") else C_FriendList.AddFriend(name) end
		end }, f.psAdd)
	e:SetFocus()
end

-- The filter menu: the stock list's Status and Tags submenus in one list;
-- a pick keeps it open.
local function filterItems()
	local items = {}
	local function section(title, list, always)
		local any = false
		for _, o in ipairs(list) do
			local k = o[1]
			if always or tagValue(o) ~= nil then
				if not any then
					if #items > 0 then items[#items + 1] = { separator = true } end
					items[#items + 1] = { text = title, disabled = true }
					any = true
				end
				items[#items + 1] = { text = o[2] or o[1], checked = filters[k], onClick = function()
					filters[k] = not filters[k] or nil
					M.Show()
					W.ShowMenu(f.psFilter, filterItems(), { minWidth = 200 })
				end }
			end
		end
	end
	section("Status", STATUS, true)
	if not C_BattleNet.AreFriendTagsEnabled or C_BattleNet.AreFriendTagsEnabled() then
		section("Interests", INTERESTS)
		section("Roles", ROLES)
	end
	if next(filters) then
		items[#items + 1] = { separator = true }
		items[#items + 1] = { text = "Clear filters", onClick = function() filters = {}; M.Show() end }
	end
	return items
end

-- The player's Battle.net presence and BattleTag (the stock BattleNetBar).
local function presence()
	local _, _, _, _, afk, dnd, _, hidden = BNGetInfo()
	return hidden and "hidden" or afk and "away" or dnd and "busy" or "online"
end

local function setPresence(p)
	-- As SocialUIUtil.SetBattleNetPresenceFromSocialUIPresence.
	if p == "online" then
		C_BattleNet.SetAFK(false); C_BattleNet.SetDND(false); C_BattleNet.SetAppearOffline(false)
	elseif p == "away" then C_BattleNet.SetAFK(true)
	elseif p == "busy" then C_BattleNet.SetDND(true)
	else C_BattleNet.SetAppearOffline(true) end
	M.Show() -- at once, not on BN_INFO_CHANGED (docs/CLIENT.md, rule 6)
end

local function battleTag() return keep("tag", (select(2, BNGetInfo()))) or "" end

-- shortcut: a selected field to copy from, not CopyToClipboard (restricted and
-- unproven from addon code); switch once it is seen to work in game.
local function copyTag()
	f.psCopy = f.psCopy or fieldBody()
	local e = f.psCopy.Box
	e:SetText(battleTag())
	ns.ModalWith({ title = "Copy BattleTag", text = "Press Ctrl+C to copy your BattleTag.", action = "Done", onAccept = function() end }, f.psCopy)
	e:SetFocus()
	e:HighlightText()
end

local function presenceItems()
	local now, items = presence(), {}
	for _, o in ipairs({ { "online", "Online" }, { "away", "Away" }, { "busy", "Busy" }, { "hidden", "Appear offline" } }) do
		items[#items + 1] = { text = o[2], checked = now == o[1], onClick = function() setPresence(o[1]) end }
	end
	items[#items + 1] = { separator = true }
	items[#items + 1] = { text = "Copy BattleTag", onClick = copyTag }
	return items
end

local function build()
	f = W.Shell(NAME, { scalePath = "ui.menuScale", width = 760, height = 600, sidebar = 240, searchPlaceholder = "Search for keywords",
		onSearch = function(text)
			query = (text or ""):lower()
			if f:IsShown() then M.Show() end
		end })
	ns.Dock(f)
	ns.WindowMenu(f, "social")
	local b = ns.SubjectBlock(f)
	f.psClass, f.psName, f.psLine = b.icon, b.name, b.line
	-- The player's Battle.net status (the stock BattleNetBar) is the subject
	-- block: a dot on the class icon, the BattleTag under the name, and a click
	-- for the presence menu.
	local well = f.psClass:GetParent()
	f.psDot = W.Tex(well, "OVERLAY", "circle", "success")
	f.psDot:SetSize(10, 10)
	f.psDot:SetPoint("CENTER", well, "BOTTOMRIGHT", -2, 2)
	local st = CreateFrame("Button", nil, f.Sidebar)
	st:SetPoint("TOPLEFT", well, "TOPLEFT", -8, 8)
	st:SetPoint("BOTTOMRIGHT", f.Sidebar, "TOPRIGHT", -16, -47 - 26)
	W.Hover(st)
	st.Label, st.Dot = f.psLine, f.psDot
	f.psLine:SetWidth(f.psLine:GetWidth() - 16)
	st.Arrow = W.Tex(st, "ARTWORK", "chevron-down", "textDim")
	st.Arrow:SetSize(12, 12)
	st.Arrow:SetPoint("RIGHT", st, "RIGHT", -8, 0)
	st:SetScript("OnClick", function(self)
		if W.MenuShown(self) then return W.HideMenu() end
		W.ShowMenu(self, presenceItems(), { minWidth = 200 })
	end)
	st:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Battle.net status")
		ns.TooltipHint("Click to set your status or copy your BattleTag.")
		GameTooltip:Show()
	end)
	st:SetScript("OnLeave", W.HideTooltip)
	f.psStatus = st
	f.psOptions = ns.OptionsButton(f, optionsItems)
	-- The filter acts on the list: it ends the search row as in Crafting, its
	-- glyph in the accent while a filter is on.
	f.psFilter = W.IconButton(f.Sidebar, "sliders", 30, "Filter", function(self)
		if W.MenuShown(self) then return W.HideMenu() end
		W.ShowMenu(self, filterItems(), { minWidth = 200 })
	end, 14)
	f.psFilter:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -W.SHELL.side, -(W.SHELL.header - 30))
	Theme.Skin(f.psFilter, "editbox")
	f.psPanel = W.RowPanel(f.Body)
	f.psPanel:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
	f.psPanel:SetPoint("RIGHT", f.Body, "RIGHT", -W.SHELL.pad, 0)
	f.psEmpty = W.Text(f.Body, "default", "textDim")
	f.psEmpty:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
	f.psEmpty:SetPoint("RIGHT", f.Body, "RIGHT", -W.SHELL.pad, 0)
	f.psEmpty:SetJustifyH("LEFT")
	f.psEmpty:SetWordWrap(true)
	-- The stock window's sounds: it never opens now to play them.
	f:HookScript("OnShow", function() PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) end)
	f:HookScript("OnHide", function() PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE) end)
	Polestar.CloseOnEscape(NAME)
end

local function statusColor()
	return BNConnected() and PRESENCE_COLOR[presence()] or "textMuted"
end

local PAGES = {
	friends = { "Friends", nil, "No friends yet. Add one below." }, -- subtitle: friends online
	allies = { "Recent allies", "Players you grouped or played with lately.", "No recent allies yet." },
	ignored = { "Ignored", "You see nothing these players say.", "You ignore no one." },
	raid = { "Raid", "Your raid by group. To move players, see Options.", nil },
}

local function refresh()
	if page == "allies" and not alliesOn() then page = "friends" end
	local lists = { friends = friends(), ignored = ignored(), allies = alliesOn() and allies() or {} }
	local _, bnOnline = BNGetNumFriends()
	local online = C_FriendList.GetNumOnlineFriends() + bnOnline
	f.psName:SetText(keep("player", UnitName("player")) or "")
	f.psClass:SetTexture("Interface\\Icons\\ClassIcon_" .. select(2, UnitClass("player")))
	W.Color(f.psDot, statusColor())
	local st, n = f.psStatus, 0
	for _ in pairs(filters) do n = n + 1 end
	W.SetIconState(f.psFilter, n > 0)
	f.psFilter.psTip = n > 0 and ("Filter (%d on)"):format(n) or "Filter"
	f.psFilter:SetShown(page == "friends")
	f.Search:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -(W.SHELL.side + (page == "friends" and 36 or 0)), -(W.SHELL.header - 30))
	st.Label:SetText(BNConnected() and battleTag() or "Battle.net offline")
	st:SetEnabled(BNConnected())
	st.Arrow:SetShown(BNConnected())
	local nFriends, inv = #lists.friends, requests()
	-- Requests head the list unless a search is on.
	if query == "" then
		for i = #inv, 1, -1 do table.insert(lists.friends, 1, inv[i]) end
	end
	local nav = { { key = "friends", label = "Friends", icon = "star", count = nFriends } }
	if alliesOn() then nav[#nav + 1] = { key = "allies", label = "Recent allies", icon = "compact", count = #lists.allies } end
	nav[#nav + 1] = { key = "ignored", label = "Ignored", icon = "close", count = #lists.ignored }
	nav[#nav + 1] = { key = "raid", label = "Raid", icon = "bolt", count = IsInRaid() and GetNumGroupMembers() or 0 }
	W.ShellNav(f, nav, page, function(k) page = k; M.Show() end)
	local p = PAGES[page]
	W.ShellTitle(f, p[1], p[2] or ("%d of %d friends online"):format(online, nFriends))
	W.ShellTabs(f, nil)
	W.ShellFooter(f, {}, page == "raid" and {} or {
		{ label = "Add friend", onClick = addFriend, opts = { primary = true } },
		{ label = "Send message", onClick = function() ChatFrameUtil.OpenChat(SLASH_WHISPER1 .. " ") end },
	})
	for _, g in ipairs(groups) do g.Head:Hide(); g.Panel:Hide() end
	local h
	if page == "raid" then
		f.psPanel:Hide()
		f.psEmpty:SetText("You are not in a raid.")
		f.psEmpty:SetShown(not IsInRaid())
		h = IsInRaid() and paintRaid() or 60
	else
		local list = {}
		for _, e in ipairs(lists[page]) do if matches(e) then list[#list + 1] = e end end
		if page == "friends" then list = withHeads(list) end
		local ready = page ~= "allies" or C_RecentAllies.IsRecentAllyDataReady()
		f.psEmpty:SetText(not ready and "Recent allies load in the game's Social window: type /friends and open its Recent Allies tab." or (query ~= "" or next(filters)) and "No one matches." or p[3])
		h = paintRows(list)
	end
	W.ShellBody(f, h)
end

function M.Show(key)
	if not f then build() end
	page = key or page
	-- No TryRequestRecentAlliesData: it is restricted to the game's code; the
	-- stock Recent Allies tab asks, and RECENT_ALLIES_DATA_READY fills ours.
	refresh()
	f:Show()
end

function M.Toggle(key)
	if f and f:IsShown() and (key == nil or key == page) then f:Hide() else M.Show(key) end
end

function M.Enable()
	-- The keys open ours; the stock window is never touched (docs/CLIENT.md,
	-- rule 8). Forever has no social micro button; the chat's friends button,
	-- /friends and toasts stay the game's: they are the way to the stock window.
	ns.Doors("social", "Social", {
		TOGGLESOCIAL = function() M.Toggle() end,
		TOGGLEFRIENDSTAB = function() M.Toggle("friends") end,
		TOGGLERAIDTAB = function() M.Toggle("raid") end,
	})
	local function changed() if f and f:IsShown() then refresh() end end
	for _, ev in ipairs({ "FRIENDLIST_UPDATE", "IGNORELIST_UPDATE", "BN_DISCONNECTED", "BN_INFO_CHANGED", "GROUP_ROSTER_UPDATE", "PLAYER_REGEN_ENABLED",
		"BN_FRIEND_INVITE_ADDED", "BN_FRIEND_INVITE_REMOVED", "BN_FRIEND_INVITE_LIST_INITIALIZED", "RECENT_ALLIES_CACHE_UPDATE", "RECENT_ALLIES_DATA_READY" }) do
		Polestar.RegisterEvent(ev, changed)
	end
	-- Battle.net reads also run hidden, so a window first opened in combat
	-- has the names last read clean.
	local function bnet()
		if f and f:IsShown() then return refresh() end
		friends()
		keep("player", UnitName("player"))
	end
	for _, ev in ipairs({ "BN_FRIEND_INFO_CHANGED", "BN_FRIEND_LIST_SIZE_CHANGED", "BN_CONNECTED" }) do Polestar.RegisterEvent(ev, bnet) end
end

-- The stock window, for the button that switches back to ours (Core.lua).
function M.stock() return FriendsFrame and FriendsFrame:IsShown() and FriendsFrame end

ns.Module("social", M)
