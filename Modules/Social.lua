-- The Social (docs/windows/social.md): the stock FriendsFrame's Contacts and
-- Raid tabs in a Polestar shell. Quick Join and Recruit a Friend, where the
-- game has them, stay on the stock window.

local ADDON, ns = ...
local W = Polestar.Widgets
local Theme = Polestar.Theme

local NAME = "PolestarUISocial"
local ROW_H, HEAD_H, RAID_H, COL_GAP = 44, 32, 28, 24

local f, page, query = nil, "friends", ""
local collapsed = {}
-- Each list's own filter picks, as the stock Friends and Recent Allies tabs keep them.
local filterSets = { friends = {}, allies = {} }
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

-- A tooltip line in a theme colour.
local function tipLine(text, token)
	local r, g, b = Theme.Color(token or "textDim")
	GameTooltip:AddLine(text, r, g, b, true)
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

-- Battle.net friends in a queue or free for one (no account field says so):
-- the client's search found them at the last filter pick. shortcut:
-- C_BattleNet.SearchFriends is restricted, so it runs only from that click and
-- the queue picks hold until the next one; read it live once seen to work in game.
local queued

local function searchQueue()
	local s = filterSets.friends
	queued = nil
	if not (s.isInQueue or s.isAvailableForQueue) then return end
	queued = {}
	local found = C_BattleNet.SearchFriends({ searchText = "", isOnline = false, isOffline = false, isAFK = false, isDND = false,
		isInQueue = s.isInQueue or false, isAvailableForQueue = s.isAvailableForQueue or false, tags = {} })
	for _, i in ipairs(found or {}) do
		local a = C_BattleNet.GetFriendAccountInfo(i)
		if a then queued[a.bnetAccountID] = true end
	end
end

-- The checked filters as the stock list's search applies them: any checked
-- status, then any checked tag. WoW friends have no tags or queue state.
local function friendShown(online, afk, dnd, tags, id)
	local s = filterSets.friends
	local status = false
	for _, o in ipairs(STATUS) do status = status or s[o[1]] or false end
	if status and not ((s.isOnline and online) or (s.isAFK and afk) or (s.isDND and dnd) or (s.isOffline and not online)
		or (id and queued and queued[id])) then
		return false
	end
	local want, has = false, false
	for _, list in ipairs({ INTERESTS, ROLES }) do
		for _, t in ipairs(list) do
			local v = s[t[1]] and tagValue(t)
			if v then
				want = true
				for _, x in ipairs(tags or {}) do if x == v then has = true end end
			end
		end
	end
	return not want or has
end

-- The stock friend card's tooltip (FriendsListSocialCardMixin:BuildTooltip):
-- what is secret in combat keeps its last clean read.
local TAG_LABEL = { DamagerRole = "DPS", HealerRole = "Healer", TankRole = "Tank" }
local function tagLabels(tags)
	local names = {}
	for _, t in ipairs(tags or {}) do
		for k, v in pairs(Enum.BattleNetFriendTag or {}) do
			if v == t then names[#names + 1] = TAG_LABEL[k] or k end
		end
	end
	return table.concat(names, ", ")
end

local function noteLine(note, online)
	if note and note ~= "" then tipLine("Note: " .. note, online and "accent" or "textMuted") end
end

local function bnTip(i, a, g, id)
	local online = g.isOnline
	local note = keep("bnn" .. id, a.note)
	if online and g.gameAccountID then
		GameTooltip:AddLine(" ")
		local char = keep("bnc" .. id, g.characterName)
		if g.clientProgram == BNET_CLIENT_WOW and g.wowProjectID == WOW_PROJECT_ID and g.areaName then
			tipLine(char or "", "accent")
			tipLine(("Level %d %s"):format(g.characterLevel or 0, g.className or ""), "text")
			if g.raceName then tipLine(g.raceName, "text") end
			tipLine(keep("bnz" .. id, g.areaName) or "", "text")
			if g.factionName then tipLine(g.factionName, "text") end
			if g.playerGuid and C_SocialQueue and C_SocialQueue.IsSystemSupported() and C_SocialQueue.GetGroupForPlayer(g.playerGuid) then
				tipLine("In a group", "text")
			end
		else
			if char then tipLine(char, "accent") end
			local rich = keep("bnr" .. id, g.richPresence)
			if rich and rich ~= "" then tipLine(rich, "text") end
		end
	elseif (note or "") ~= "" or #(a.friendTags or {}) > 0 then
		GameTooltip:AddLine(" ")
	end
	noteLine(note, online)
	local tags = tagLabels(a.friendTags)
	if tags ~= "" then tipLine("Tags: " .. tags, online and "text" or "textMuted") end
	-- The friend's broadcast, and when it was sent.
	local msg = keep("bnm" .. id, a.customMessage)
	if msg and msg ~= "" then
		GameTooltip:AddLine(" ")
		local when = a.customMessageTime and a.customMessageTime > 0 and FriendsFrame_GetLastOnline
			and (" (%s ago)"):format(FriendsFrame_GetLastOnline(a.customMessageTime)) or ""
		tipLine(msg .. when, "accent")
	end
	if not online then
		GameTooltip:AddLine(" ")
		tipLine(lastOnline(a.lastOnlineTime), "textMuted")
	end
	-- Other game accounts, as the stock tooltip lists them (at most four).
	local n = online and C_BattleNet.GetFriendNumGameAccounts and C_BattleNet.GetFriendNumGameAccounts(i) or 0
	local shown = 0
	for k = 1, n > 1 and n or 0 do
		local o = C_BattleNet.GetFriendGameAccountInfo(i, k)
		if o and not o.hasFocus and o.clientProgram ~= "App" and o.clientProgram ~= "BSAp" and shown < 4 then
			if shown == 0 then GameTooltip:AddLine(" ") end
			shown = shown + 1
			local name = ns.Clean(o.characterName) or ""
			tipLine(o.characterLevel and o.wowProjectID == WOW_PROJECT_ID and ("%s, Level %d %s"):format(name, o.characterLevel, o.className or "") or name, "accent")
			local rich = ns.Clean(o.richPresence)
			if rich and rich ~= "" then tipLine(rich, "text") end
		end
	end
end

-- The friends list as the stock one orders it (FriendsList_Update): Battle.net
-- favorites, then online Battle.net and WoW friends, then offline ones; the
-- client already lists each kind online first, favorites first.
local function friends()
	local list = {}
	for i = 1, C_FriendList.GetNumFriends() do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info and friendShown(info.connected, info.afk, info.dnd) then
			list[#list + 1] = { name = info.name, online = info.connected, class = classFile(info.guid),
				rank = info.connected and 2 or 4, order = i, canInvite = info.connected,
				status = not info.connected and "offline" or info.dnd and "busy" or info.afk and "away" or "online",
				sub = info.connected and detail(info.level, info.className, info.area, classFile(info.guid)) or "Offline",
				whisper = function() ChatFrameUtil.SendTell(info.name) end,
				invite = function() C_PartyInfo.InviteUnit(info.name) end,
				menu = function() FriendsFrame_ShowDropdown(info.name, info.connected, nil, nil, nil, 1, nil, nil, nil, nil, info.guid) end,
				tip = function()
					if info.connected then
						GameTooltip:AddLine(" ")
						tipLine(("Level %d %s"):format(info.level or 0, info.className or ""), "text")
						if info.area then tipLine(info.area, "text") end
					end
					noteLine(info.notes, info.connected)
				end }
		end
	end
	for i = 1, (BNGetNumFriends()) do
		local a = C_BattleNet.GetFriendAccountInfo(i)
		if a then
			local g, id = a.gameAccountInfo or {}, a.bnetAccountID
			local name = keep("bn" .. id, a.accountName) or a.battleTag or ""
			local char = keep("bnc" .. id, g.characterName)
			keep("bnn" .. id, a.note); keep("bnm" .. id, a.customMessage) -- read out of combat for the tooltip
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
			if friendShown(g.isOnline, a.isAFK or g.isGameAFK, a.isDND or g.isGameBusy, a.friendTags, id) then list[#list + 1] = { name = name, char = char, online = g.isOnline, sub = sub,
				client = client, subIcon = g.subIcon, faded = client == BNET_CLIENT_WOW and g.wowProjectID ~= WOW_PROJECT_ID,
				bnet = true, favorite = a.isFavorite, rank = a.isFavorite and 0 or g.isOnline and 1 or 3, order = 1000 + i,
				status = status, canInvite = g.isOnline and char ~= nil,
				whisper = function() ChatFrameUtil.SendBNetTell(name) end,
				invite = function() FriendsFrame_BattlenetInviteByIndex(i) end,
				menu = function() FriendsFrame_ShowBNDropdown(name, g.isOnline, nil, nil, nil, 1, id, nil, nil, nil, nil, a.battleTag) end,
				tip = function() bnTip(i, a, g, id) end } end
		end
	end
	table.sort(list, function(x, y)
		if x.rank ~= y.rank then return x.rank < y.rank end
		return x.order < y.order
	end)
	return list
end

-- Pending Battle.net friend requests: the stock Friend Requests tab's cards
-- (FriendRequestsListTemplates.lua): who, what kind, and when it was sent.
local function requestKind(level)
	local L = Enum.BattleNetFriendLevel or {}
	return level == L.RealID and "Real ID friend" or level == L.Title and "WoW friend" or "Battle.net friend"
end

local function requests()
	local list = {}
	local L = Enum.BattleNetFriendLevel or {}
	for i = 1, BNGetNumFriendInvites() do
		local inv = C_BattleNet.GetFriendInviteInfo(i)
		if inv then
			local sent = inv.creationTimestamp and inv.creationTimestamp > 0 and FriendsFrame_GetLastOnline
				and ("Sent %s ago"):format(FriendsFrame_GetLastOnline(inv.creationTimestamp))
			local kind = requestKind(inv.friendLevel)
			list[#list + 1] = { name = keep("inv" .. inv.inviteID, inv.accountName) or "", online = true, bnet = true,
				sub = sent and kind .. " · " .. sent or kind, request = inv.inviteID, realID = inv.friendLevel == L.RealID,
				-- As FriendsListUtil.CanAddFriendRequestSenderToBattleNetBlockList: not a WoW friend's.
				blockable = inv.friendLevel ~= nil and inv.friendLevel ~= L.Title,
				tip = function()
					if sent then tipLine(sent, "text") end
					tipLine(kind, "textDim")
				end }
		end
	end
	return list
end

-- The stock Recent Allies tab's filter (Status, Categories), handed to
-- C_RecentAllies.SearchRecentAllies.
local ALLY_STATUS = { { "isOnline", "Online" }, { "isAFK", "Away" }, { "isDND", "Busy" }, { "isOffline", "Offline" } }
local CATEGORIES = { { "Professions" }, { "PvP" }, { "Raiding" }, { "Dungeons" }, { "Delves" }, { "Questing" } }

-- A category's enum value, nil when this game type has none.
local function categoryValue(t)
	local E = Enum.RecentAlliesInteractionCategoryFilter
	local v = E and E[t[1]]
	local ok = C_RecentAllies.IsInteractionCategoryFilterSupportedForCurrentGameType
	if v == nil or (ok and not ok(v)) then return end
	return v
end

local function allyData()
	local set, info, on = filterSets.allies, { searchText = "", interactionCategoryFilters = {} }, false
	for _, o in ipairs(ALLY_STATUS) do
		info[o[1]] = set[o[1]] or false
		on = on or info[o[1]]
	end
	for _, c in ipairs(CATEGORIES) do
		local v = set[c[1]] and categoryValue(c)
		if v then info.interactionCategoryFilters[#info.interactionCategoryFilters + 1] = v; on = true end
	end
	if on then return C_RecentAllies.SearchRecentAllies(info) end
	return C_RecentAllies.GetRecentAllies()
end

-- A pin near its end shows the stock card's red pin and says when it ends.
local function pinEnding(t)
	local days = Constants and Constants.RecentAlliesConsts and Constants.RecentAlliesConsts.PIN_EXPIRATION_WARNING_DAYS or 7
	return t and (t - GetServerTime()) / 86400 <= days
end

-- Recent allies (C_RecentAllies, presorted by the client: pinned, online, latest).
local function allies()
	local list = {}
	if not C_RecentAllies.IsRecentAllyDataReady() then return list end
	for _, a in ipairs(allyData() or {}) do
		local c, st, it = a.characterData, a.stateData, a.interactionData or {}
		local cls = C_CreatureInfo.GetClassInfo(c.classID)
		local recent = it.interactions and it.interactions[1]
		local parts = { detail(c.level, cls and cls.className, st.isOnline and st.currentLocation, st.isOnline and cls and cls.classFile) }
		if recent and recent.description and recent.description ~= "" then parts[#parts + 1] = recent.description end
		if st.friendRequestSentThisSession then parts[#parts + 1] = "Friend request sent" end
		local full, pinned = c.fullName, st.pinExpirationDate ~= nil
		list[#list + 1] = { name = c.name or full, title = full, online = st.isOnline, class = cls and cls.classFile,
			sub = table.concat(parts, " · "), guid = c.guid, pinned = pinned, pinUntil = st.pinExpirationDate,
			legacy = pinned and st.isConvertedLegacyFriend, canInvite = st.isOnline,
			status = not st.isOnline and "offline" or st.isAFK and "away" or st.isDND and "busy" or "online",
			whisper = function() ChatFrameUtil.SendTell(full) end,
			invite = function() C_PartyInfo.InviteUnit(full) end,
			menu = function()
				UnitPopup_OpenMenu(st.isOnline and "RECENT_ALLY" or "RECENT_ALLY_OFFLINE",
					{ recentAllyData = a, name = full, guid = c.guid, isOffline = not st.isOnline })
			end,
			-- The stock card's tooltip: level and class, race, faction, where, note, latest activity.
			tip = function()
				local tok = st.isOnline and "text" or "textMuted"
				tipLine(("Level %d %s"):format(c.level or 0, cls and cls.className or ""), tok)
				local race = C_CreatureInfo.GetRaceInfo and C_CreatureInfo.GetRaceInfo(c.raceID)
				local faction = C_CreatureInfo.GetFactionInfo and C_CreatureInfo.GetFactionInfo(c.raceID)
				if race then tipLine(race.raceName, tok) end
				if faction then tipLine(faction.name, tok) end
				if st.currentLocation then tipLine(st.currentLocation, tok) end
				if it.note and it.note ~= "" then tipLine("Note: " .. it.note, st.isOnline and "accent" or "textMuted") end
				if recent then
					GameTooltip:AddLine(" ")
					local when = recent.timestamp and FriendsFrame_GetLastOnline and (" · %s ago"):format(FriendsFrame_GetLastOnline(recent.timestamp)) or ""
					tipLine("Recent activity" .. when, st.isOnline and "accent" or "textMuted")
					tipLine(recent.description or "", tok)
				end
			end }
	end
	return list
end

local function alliesOn() return C_RecentAllies and C_RecentAllies.IsSystemEnabled() end

-- The stock ignore list (SocialUIIgnoreListMixin): ignored players, then
-- the Battle.net accounts whose invites are blocked.
local function ignored()
	local list = {}
	for i = 1, C_FriendList.GetNumIgnores() do
		local name = C_FriendList.GetIgnoreName(i)
		if name then list[#list + 1] = { name = name, online = true, sub = "", unignore = name } end
	end
	for i = 1, BNGetNumBlocked() do
		local id, name = BNGetBlockedInfo(i)
		if id then list[#list + 1] = { name = keep("blk" .. id, name) or "", online = true, sub = "", unblock = id } end
	end
	return list
end

local function matches(e)
	return query == "" or e.name:lower():find(query, 1, true) or (e.char and e.char:lower():find(query, 1, true))
end

-- Folding groups as the stock lists head them, each entry under the first
-- head whose test it passes; `label(online, total)` names the head. An empty
-- group shows no head.
local function grouped(list, heads)
	local kids, out = {}, {}
	for i in ipairs(heads) do kids[i] = {} end
	for _, e in ipairs(list) do
		for i, h in ipairs(heads) do
			if not h.test or h.test(e) then kids[i][#kids[i] + 1] = e; break end
		end
	end
	for i, h in ipairs(heads) do
		local k = kids[i]
		if #k > 0 then
			local on = 0
			for _, e in ipairs(k) do if e.online then on = on + 1 end end
			out[#out + 1] = { head = true, key = h.key, name = h.label(on, #k), online = true }
			if not collapsed[h.key] then for _, e in ipairs(k) do out[#out + 1] = e end end
		end
	end
	return out
end

-- The stock friends list's Favorites and Friends groups, "online/total" of those shown.
local FRIEND_HEADS = {
	{ key = "fav", test = function(e) return e.favorite end, label = function(on, n) return ("Favorites %d/%d"):format(on, n) end },
	{ key = "all", label = function(on, n) return ("Friends %d/%d"):format(on, n) end },
}
local IGNORE_HEADS = {
	{ key = "ign", test = function(e) return e.unignore end, label = function(_, n) return ("Ignored players (%d)"):format(n) end },
	{ key = "blk", label = function(_, n) return ("Blocked Battle.net invites (%d)"):format(n) end },
}
-- The stock Recent Allies tab's groups: legacy friends kept pinned, pinned, the rest.
local ALLY_HEADS = {
	{ key = "legacy", test = function(e) return e.legacy end, label = function(on, n) return ("Legacy friends %d/%d"):format(on, n) end },
	{ key = "pinned", test = function(e) return e.pinned end, label = function(on, n) return ("Pinned %d/%d"):format(on, n) end },
	{ key = "recent", label = function(on, n) return ("Recent allies %d/%d"):format(on, n) end },
}
local REQUEST_HEADS = { { key = "recv", label = function(_, n) return ("Received (%d)"):format(n) end } }

---------------------------------------------------------------------------
-- Friend rows: name over a detail line, in one row panel.

-- A click whispers only once no second click made it a double-click (invite).
local DOUBLE_CLICK = 0.3

local function rowEnter(r)
	local e = r.psEntry
	if not e.whisper and not e.tip then return end
	GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
	GameTooltip:SetText(e.title or e.name)
	-- The stock card's tooltip lines (details, note, tags, broadcast...).
	if e.tip then e.tip() end
	if e.whisper then ns.TooltipHint("Click to whisper. Double-click to invite to your group. Right-click for more.") end
	GameTooltip:Show()
end

-- The stock Decline menu (FriendRequestsListSocialCardDeclineButtonMixin).
local function declineItems(e)
	local id = e.request
	local items = {
		{ text = "Decline", onClick = function() BNDeclineFriendInvite(id); M.Show() end },
		{ text = "Report player", onClick = function()
			ReportFrame:InitiateReport(ReportInfo:CreateReportInfoFromType(Enum.ReportType.Friend), e.name,
				PlayerLocation:CreateFromBattleNetID(id), true)
		end },
	}
	if e.blockable then
		items[#items + 1] = { text = "Block invites", onClick = function()
			W.Modal({ title = "Block invites", text = ("Block all future invites from %s?"):format(e.name), action = "Block", danger = true,
				onAccept = function()
					C_BattleNet.SetBlocked(id, true)
					BNDeclineFriendInvite(id)
					M.Show() -- at once (docs/CLIENT.md, rule 6)
				end })
		end }
	end
	return items
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
	-- A recent ally's pin in the client icon's slot: the stock card's pin mark,
	-- and a click pins or unpins (C_RecentAllies.SetRecentAllyPinned).
	r.Pin = CreateFrame("Button", nil, r)
	r.Pin:SetSize(20, 20)
	r.Pin:SetPoint("RIGHT", r.Invite, "LEFT", -6, 0)
	r.Pin.Icon = r.Pin:CreateTexture(nil, "ARTWORK")
	r.Pin.Icon:SetAllPoints()
	r.Pin:SetScript("OnClick", function(self)
		local e = self:GetParent().psEntry
		C_RecentAllies.SetRecentAllyPinned(e.guid, not e.pinned)
		M.Show() -- at once (docs/CLIENT.md, rule 6)
	end)
	r.Pin:SetScript("OnEnter", function(self)
		local e = self:GetParent().psEntry
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if e.pinned then
			GameTooltip:SetText("Pinned")
			local left = e.pinUntil and math.max(e.pinUntil - GetServerTime(), 1)
			tipLine(pinEnding(e.pinUntil) and left and ("The pin ends in %s."):format(SecondsToTime(left, true)) or "Kept in your recent allies.", "text")
			ns.TooltipHint("Click to unpin.")
		else
			GameTooltip:SetText("Pin")
			tipLine("Keep this ally in your recent allies.", "text")
		end
		GameTooltip:Show()
	end)
	r.Pin:SetScript("OnLeave", W.HideTooltip)
	r.Fav = r:CreateTexture(nil, "ARTWORK")
	r.Fav:SetSize(14, 14)
	r.Remove = W.IconButton(r, "close", 24, "Stop ignoring", function(self)
		local e = self:GetParent().psEntry
		if e.unblock then C_BattleNet.SetBlocked(e.unblock, false) else C_FriendList.DelIgnore(e.unignore) end
		M.Show() -- at once, not on the client's event (docs/CLIENT.md, rule 6)
	end)
	r.Remove:SetPoint("RIGHT", r, "RIGHT", -12, 0)
	-- Decline opens the stock card's menu: Decline, Report player, Block invites.
	r.Decline = W.Button(r, "Decline", function(self)
		if W.MenuShown(self) then return W.HideMenu() end
		W.ShowMenu(self, declineItems(self:GetParent().psEntry), { minWidth = 160 })
	end)
	r.Decline:SetWidth(84)
	r.Decline:SetPoint("RIGHT", r, "RIGHT", -12, 0)
	r.Accept = W.Button(r, "Accept", function(self)
		BNAcceptFriendInvite(self:GetParent().psEntry.request)
		M.Show()
	end, { primary = true })
	r.Accept:SetWidth(84)
	r.Act = W.Button(r, "", function(self) self:GetParent().psEntry.actFn() end)
	r.Act:SetWidth(100)
	r.Act:SetPoint("RIGHT", r, "RIGHT", -12, 0)
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
		local right = e.request and 200 or e.act and 124 or e.status and 80 or 64
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
		r.Pin:SetShown(e.guid ~= nil)
		if e.guid then
			r.Pin.Icon:SetAtlas(pinEnding(e.pinUntil) and "friendslist-recentallies-pin" or "friendslist-recentallies-pin-yellow")
			r.Pin.Icon:SetDesaturated(not e.pinned)
			r.Pin:SetAlpha(e.pinned and 1 or 0.35)
		end
		r.Fav:SetShown(e.favorite or false)
		if e.favorite then
			r.Fav:SetAtlas(e.online and "friends-icon-favorites" or "friends-icon-favorites-dis")
			r.Fav:ClearAllPoints()
			r.Fav:SetPoint("LEFT", r.Name, "LEFT", math.min(r.Name:GetStringWidth(), r.Name:GetWidth()) + 4, 0)
		end
		r.Remove:SetShown(e.unignore ~= nil or e.unblock ~= nil)
		r.Remove.psTip = e.unblock and "Unblock invites" or "Stop ignoring"
		r.Accept:SetShown(e.request ~= nil)
		r.Act:SetShown(e.act ~= nil)
		if e.act then
			W.SetButtonText(r.Act, e.act)
			ns.SetEnabled(r.Act, not e.actOff, "This lockout can't be extended now.")
		end
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
-- Raid: the stock Raid tab (RaidFrameSocialView.lua). Eight groups, two to a
-- row as the stock grid lays them; each player's name in class colour (red
-- dead, faint offline), level and class, the leader or assistant mark, the
-- main tank or assist mark, and the ready check's answer in that slot while
-- one runs. A hovered player has a secure button of ours over it
-- (ns.Overlay): a click targets, as the stock SecureUnitButton does, a
-- right-click opens the game's RAID menu, and the leader or an assistant
-- drags a player onto another (SwapRaidSubgroup) or into a group with room
-- (SetRaidSubgroup). Out of combat only: the button hides in combat.

local raidRows, dragFrom, raidInfo = {}, nil, false

local function canArrange() return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") end

-- The row or group under the mouse at a drop.
local function dropOn()
	for _, r in ipairs(raidRows) do
		if r:IsShown() and r.psMember and r:IsMouseOver() then return r, nil end
	end
	for i, g in ipairs(groups) do
		if g.Panel:IsShown() and g.Panel:IsMouseOver() then return nil, i end
	end
end

local function drop()
	local from = dragFrom
	dragFrom = nil
	if not from or InCombatLockdown() or not canArrange() then return end
	local r, gi = dropOn()
	if r and r.psMember.sub ~= from.sub then
		SwapRaidSubgroup(from.id, r.psMember.id)
	elseif gi and gi ~= from.sub and (groups[gi].psCount or 0) < 5 then
		SetRaidSubgroup(from.id, gi)
	end
	M.Show() -- at once (docs/CLIENT.md, rule 6)
end

local overRaid = ns.Overlay("PolestarUISocialRaidUnit", {
	enter = function(r)
		local m = r.psMember
		if not m then return end
		GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
		GameTooltip:SetUnit(m.unit)
		ns.TooltipHint(canArrange() and "Click to target. Drag to another group. Right-click for more." or "Click to target. Right-click for more.")
		GameTooltip:Show()
	end,
	pickup = function(r)
		if r.psMember and canArrange() and not InCombatLockdown() and not SpellIsTargeting() then dragFrom = r.psMember end
	end,
	setup = function(over)
		over:HookScript("OnDragStop", drop)
		over:HookScript("PostClick", function(self, button)
			local m = self.psTarget and self.psTarget.psMember
			if button == "RightButton" and m then UnitPopup_OpenMenu("RAID", { unit = m.unit, name = m.name }) end
		end)
	end,
	attrs = function(over, r)
		local m = r.psMember
		over:SetAttribute("type1", m and "target" or nil)
		over:SetAttribute("unit", m and m.unit or nil)
	end,
	stale = function(r) return not r.psMember end,
})

local READY = { ready = "READY_CHECK_READY_TEXTURE", notready = "READY_CHECK_NOT_READY_TEXTURE", waiting = "READY_CHECK_WAITING_TEXTURE" }

local function raidGroup(i)
	local g = groups[i]
	if g then return g end
	g = { Head = W.SectionHeader(f.Body, { plain = true }), Panel = W.RowPanel(f.Body), rows = {} }
	g.Panel:EnableMouse(true)
	for k = 1, 5 do
		local r = CreateFrame("Button", nil, g.Panel)
		r:SetHeight(RAID_H)
		r:SetPoint("TOPLEFT", g.Panel, "TOPLEFT", 0, -(k - 1) * RAID_H)
		r:SetPoint("RIGHT", g.Panel, "RIGHT", 0, 0)
		if k > 1 then
			local d = W.Divider(r)
			d:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
			d:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, 0)
		end
		W.Hover(r)
		r.Lead = r:CreateTexture(nil, "ARTWORK")
		r.Lead:SetSize(12, 12)
		r.Lead:SetPoint("LEFT", r, "LEFT", 8, 0)
		r.Mark = r:CreateTexture(nil, "ARTWORK")
		r.Mark:SetSize(14, 14)
		r.Mark:SetPoint("RIGHT", r, "RIGHT", -8, 0)
		r.Role = W.Text(r, "small", "textDim")
		r.Role:SetPoint("RIGHT", r, "RIGHT", -28, 0)
		r.Name = W.Text(r, "label", "text")
		r.Name:SetPoint("LEFT", r, "LEFT", 24, 0)
		r.Name:SetPoint("RIGHT", r.Role, "LEFT", -6, 0)
		r.Name:SetJustifyH("LEFT")
		r:SetScript("OnEnter", function(self) if self.psMember then overRaid(self) end end)
		g.rows[k] = r
		raidRows[#raidRows + 1] = r
	end
	groups[i] = g
	return g
end

local function raidBar()
	if f.psRaidBar then return f.psRaidBar end
	local b = CreateFrame("Frame", nil, f.Body)
	b:SetHeight(24)
	-- The stock All Assist box: everyone an assistant, the leader's to set.
	b.All = W.Checkbox(b, function(self)
		C_PartyInfo.SetEveryoneIsAssistant(self:GetChecked() and true or false)
		M.Show()
	end)
	b.All:SetPoint("LEFT", b, "LEFT", 0, 0)
	if b.All.SetMotionScriptsWhileDisabled then b.All:SetMotionScriptsWhileDisabled(true) end
	b.All:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("All assist")
		tipLine("Makes every raid member an assistant.", "text")
		GameTooltip:Show()
	end)
	b.All:SetScript("OnLeave", W.HideTooltip)
	b.AllText = W.Text(b, "label", "text")
	b.AllText:SetPoint("LEFT", b.All, "RIGHT", 8, 0)
	b.AllText:SetText("All assist")
	-- The stock role counts.
	b.Counts = W.Text(b, "label", "textDim")
	b.Counts:SetPoint("RIGHT", b, "RIGHT", 0, 0)
	f.psRaidBar = b
	return b
end

local function paintRaid()
	local members, roles = {}, { TANK = 0, HEALER = 0, DAMAGER = 0 }
	for i = 1, 8 do members[i] = {} end
	for i = 1, GetNumGroupMembers() do
		local name, rank, sub, level, class, file, _, online, dead, role, _, combat = GetRaidRosterInfo(i)
		if name and members[sub] and #members[sub] < 5 then
			local m = members[sub]
			m[#m + 1] = { id = i, unit = "raid" .. i, name = keep("raid" .. i, name) or "", rank = rank, sub = sub, level = level,
				className = class, class = file, online = online, dead = dead, role = role }
			if roles[combat] then roles[combat] = roles[combat] + 1 end
		end
	end
	local bar = raidBar()
	bar:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
	bar:SetPoint("RIGHT", f.Body, "RIGHT", -W.SHELL.pad, 0)
	bar.All:SetChecked(IsEveryoneAssistant())
	ns.SetEnabled(bar.All, UnitIsGroupLeader("player"), "Only the raid leader can set this.")
	bar.Counts:SetText(("%d Tanks · %d Healers · %d Damage"):format(roles.TANK, roles.HEALER, roles.DAMAGER))
	bar:Show()
	local col = (f.BodyWidth - COL_GAP) / 2
	local top, y = 24 + 24 + 16, 0
	for i = 1, 8 do
		local g, c = raidGroup(i), (i - 1) % 2
		local x = W.SHELL.pad + c * (col + COL_GAP)
		y = top + math.floor((i - 1) / 2) * (W.PLAIN_SECTION_H + 5 * RAID_H + 16)
		W.SetSection(g.Head, ("Group %d"):format(i))
		g.Head:SetWidth(col)
		g.Head:SetPoint("TOPLEFT", f.Body, "TOPLEFT", x, -y)
		g.Panel:SetWidth(col)
		g.Panel:SetPoint("TOPLEFT", f.Body, "TOPLEFT", x, -(y + W.PLAIN_SECTION_H))
		g.Panel:SetHeight(5 * RAID_H)
		g.psCount = #members[i]
		for k, r in ipairs(g.rows) do
			local m = members[i][k]
			r.psMember = m
			r.Name:SetText(m and m.name or "")
			if m then
				W.Uncolor(r.Name)
				if not m.online then W.Color(r.Name, "textMuted")
				elseif m.dead then W.Color(r.Name, "danger")
				else paintName(r.Name, m.class) end
			end
			r.Role:SetText(m and m.level and m.level > 0 and ("%d %s"):format(m.level, m.className or "") or m and m.className or "")
			r.Lead:SetShown(m ~= nil and (m.rank or 0) > 0)
			if m and (m.rank or 0) > 0 then r.Lead:SetAtlas(m.rank == 1 and "friends-icon-raidAssist" or "friends-icon-raidLead") end
			-- The ready check's answer takes the main tank / assist mark's slot while it runs.
			local ready = m and GetReadyCheckStatus(m.unit)
			if ready then
				r.Mark:SetTexture(_G[READY[ready]])
			elseif m and m.role == "MAINTANK" then r.Mark:SetAtlas("RaidFrame-Icon-MainTank")
			elseif m and m.role == "MAINASSIST" then r.Mark:SetAtlas("RaidFrame-Icon-MainAssist") end
			r.Mark:SetShown(ready ~= nil or (m ~= nil and (m.role == "MAINTANK" or m.role == "MAINASSIST")))
			r:EnableMouse(m ~= nil)
		end
		g.Head:Show()
		g.Panel:Show()
	end
	return y + W.PLAIN_SECTION_H + 5 * RAID_H + 24
end

-- The stock Raid Info side window: saved instances and world bosses, when
-- each resets, and Extend where the game has lock extending.
local function raidLocks()
	local list = {}
	local canExtend = C_RaidLocks and C_RaidLocks.IsRaidLockExtendFeatureSupported and C_RaidLocks.IsRaidLockExtendFeatureSupported()
	for i = 1, GetNumSavedInstances() do
		local name, _, reset, _, locked, extended, _, _, _, difficulty, _, _, extendDisabled = GetSavedInstanceInfo(i)
		local on = locked or extended
		local e = { name = name or "", online = on,
			sub = (difficulty or "") .. " · " .. (on and ("Resets in %s"):format(SecondsToTime(reset, true)) or "Expired") .. (extended and " · Extended" or "") }
		if canExtend then
			e.act = extended and "Unextend" or locked and "Extend" or "Reactivate"
			e.actOff = extendDisabled
			e.actFn = function() SetSavedInstanceExtend(i, not extended); RequestRaidInfo(); M.Show() end
		end
		list[#list + 1] = e
	end
	for i = 1, GetNumSavedWorldBosses() do
		local name, _, reset = GetSavedWorldBossInfo(i)
		list[#list + 1] = { name = name or "", online = true, sub = ("World boss · Resets in %s"):format(SecondsToTime(reset, true)) }
	end
	return list
end

local function hasLocks() return GetNumSavedInstances() + GetNumSavedWorldBosses() > 0 end

---------------------------------------------------------------------------
-- The window.

-- The Nothing Lost Rule: what stays on the stock window, and the way to it.
local optionsItems = {
	{ text = "Game's window: the friends button by the chat, or /friends", disabled = true },
	{ text = "There: Quick Join and Recruit a Friend, where the game has them", disabled = true },
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

local function uiError(text) UIErrorsFrame:AddExternalErrorMessage(text) end

-- A name the stock dialog sends to Battle.net (AddFriendFrame_IsValidBattlenetName).
local function bnName(text)
	local _, tag, _, _, _, _, rid = BNGetInfo()
	return (rid and text:find("@", 1, true)) or (tag and text:find("#", 1, true))
end

-- As the stock AddFriendFrame_Accept: a BattleTag or email to Battle.net, else
-- a WoW friend request by name, else the old friends list.
local function sendFriendRequest(name)
	local L = Enum.BattleNetFriendLevel or {}
	if C_BattleNet.GetFriendLevelFromInviteText and C_BattleNet.GetFriendLevelFromInviteText(name) == L.RealID
		and not C_BattleNet.AreRealIDFriendsEnabled() then
		return uiError("Real ID friend requests are turned off.")
	end
	if bnName(name) and BNConnected() then BNSendFriendInvite(name, "")
	elseif C_BattleNet.AreTitleFriendsEnabled and C_BattleNet.AreTitleFriendsEnabled() then C_BattleNet.SendTitleFriendInviteByName(name)
	elseif C_FriendList.IsLegacyFriendSystemEnabled() then C_FriendList.AddFriend(name)
	else uiError("That system is currently disabled.") end
end

-- The stock Add Friend button (AddFriendFrame_Show): a friendly player
-- targeted becomes a friend at once; else the dialog, which needs Battle.net
-- or the old friends list.
local function addFriend()
	local target = GetUnitName("target", true)
	local legacy = C_FriendList.IsLegacyFriendSystemEnabled()
	if target and UnitIsHumanPlayer("target") and UnitCanCooperate("player", "target") and legacy and not C_FriendList.GetFriendInfo(target) then
		C_FriendList.AddFriend(target)
		return M.Show()
	end
	local _, tag, _, _, _, _, rid = BNGetInfo()
	local bn = (tag or rid) and BNConnected()
	if not bn and not legacy then return uiError("Battle.net is unavailable.") end
	f.psAdd = f.psAdd or fieldBody()
	local e = f.psAdd.Box
	e:SetText("")
	local text = not bn and "A character's name. (Battle.net is unavailable: BattleTags can't be added now.)"
		or rid and "A BattleTag (Name#1234), an email address, or a character's name."
		or "A BattleTag (Name#1234) or a character's name."
	ns.ModalWith({ title = "Add friend", text = text, action = "Send request",
		onAccept = function()
			local name = strtrim(e:GetText() or "")
			if name ~= "" then sendFriendRequest(name) end
		end }, f.psAdd)
	e:SetFocus()
end

-- The stock ignore list's Block button: the target if a friendly player,
-- else a name (the ADD_IGNORE dialog).
local function ignorePlayer()
	if UnitCanCooperate("player", "target") and UnitIsHumanPlayer("target") then
		C_FriendList.AddIgnore(GetUnitName("target", true))
		return M.Show()
	end
	f.psIgnore = f.psIgnore or fieldBody()
	local e = f.psIgnore.Box
	e:SetText("")
	ns.ModalWith({ title = "Ignore player", text = "The character to ignore: you see nothing they say.", action = "Ignore",
		onAccept = function()
			local name = strtrim(e:GetText() or "")
			if name ~= "" then C_FriendList.AddIgnore(name); M.Show() end
		end }, f.psIgnore)
	e:SetFocus()
end

-- The filter menu: the stock list's submenus in one list (Friends: Status
-- and Tags; Recent allies: Status and Categories); a pick keeps it open.
local function filterItems()
	local items, filters = {}, filterSets[page]
	local function section(title, list, valid)
		local any = false
		for _, o in ipairs(list) do
			local k = o[1]
			if not valid or valid(o) ~= nil then
				if not any then
					if #items > 0 then items[#items + 1] = { separator = true } end
					items[#items + 1] = { text = title, disabled = true }
					any = true
				end
				items[#items + 1] = { text = o[2] or o[1], checked = filters[k], onClick = function()
					filters[k] = not filters[k] or nil
					if page == "friends" then searchQueue() end -- from the click (restricted)
					M.Show()
					W.ShowMenu(f.psFilter, filterItems(), { minWidth = 200 })
				end }
			end
		end
	end
	if page == "allies" then
		section("Status", ALLY_STATUS)
		section("Categories", CATEGORIES, categoryValue)
	else
		section("Status", STATUS)
		if not C_BattleNet.AreFriendTagsEnabled or C_BattleNet.AreFriendTagsEnabled() then
			section("Interests", INTERESTS, tagValue)
			section("Roles", ROLES, tagValue)
		end
	end
	if next(filters) then
		items[#items + 1] = { separator = true }
		items[#items + 1] = { text = "Clear filters", onClick = function()
			filterSets[page] = {}
			if page == "friends" then queued = nil end
			M.Show()
		end }
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

-- The stock broadcast box (SocialUIBattleNetBroadcastFrameMixin): the status
-- message your Battle.net friends see, 127 letters.
local function setBroadcast()
	f.psCast = f.psCast or fieldBody()
	local e = f.psCast.Box
	e:SetMaxLetters(127)
	local now = ns.Clean((select(4, BNGetInfo()))) or ""
	e:SetText(now)
	ns.ModalWith({ title = "Broadcast", text = "A message your Battle.net friends see.", action = "Update",
		onAccept = function()
			local text = e:GetText() or ""
			if text ~= now then C_BattleNet.SetCustomMessage(text) end
		end }, f.psCast)
	e:SetFocus()
	e:HighlightText()
end

local function presenceItems()
	local now, items = presence(), {}
	for _, o in ipairs({ { "online", "Online" }, { "away", "Away" }, { "busy", "Busy" }, { "hidden", "Appear offline" } }) do
		items[#items + 1] = { text = o[2], checked = now == o[1], onClick = function() setPresence(o[1]) end }
	end
	items[#items + 1] = { separator = true }
	items[#items + 1] = { text = "Set broadcast", onClick = setBroadcast }
	items[#items + 1] = { text = "Copy BattleTag", onClick = copyTag }
	-- The stock Battle.net bar's menu: Ignore List.
	items[#items + 1] = { text = "Ignore list", onClick = function() M.Show("ignored") end }
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

-- Each page's title, its band status (a fact about the page now, from its
-- list), and the line an empty list shows.
local function online(list)
	local n = 0
	for _, e in ipairs(list) do if e.online then n = n + 1 end end
	return n
end
local function count(n, one) return ("%d %s"):format(n, n == 1 and one or one .. "s") end
local PAGES = {
	friends = { "Friends", function(l) return ("%d of %d friends online"):format(online(l), #l) end, "No friends yet. Add one below." },
	allies = { "Recent allies", function(l)
		return C_RecentAllies.IsRecentAllyDataReady() and ("%d of %d online"):format(online(l), #l) or "Not loaded yet"
	end, "No recent allies yet." },
	requests = { "Friend requests", function(l) return count(#l, "request") end, "No friend requests." },
	ignored = { "Ignored", function(l)
		local blocked = 0
		for _, e in ipairs(l) do if e.unblock then blocked = blocked + 1 end end
		return ("%d ignored"):format(#l - blocked) .. (blocked > 0 and (" · %d blocked"):format(blocked) or "")
	end, "You ignore no one." },
	raid = { "Raid", function()
		return not IsInRaid() and "Not in a raid" or ("%d of %d players"):format(GetNumGroupMembers(), MAX_RAID_MEMBERS or 40)
	end, nil },
	raidinfo = { "Raid info", function(l) return count(#l, "lockout") end, "You are saved to no instance." },
}

-- The stock Friend Requests tab's one-time notice: a Real ID friend sees
-- your real name (FriendRequestsListRealIDWarningMixin; CVar pendingInviteInfoShown).
local function realIDWarning()
	if GetCVarBool("pendingInviteInfoShown") or not select(7, BNGetInfo()) then return end
	for _, e in ipairs(requests()) do
		if e.realID then
			return W.Modal({ title = "Real ID friend requests", action = "Continue",
				text = "Accepting a Real ID friend request shares your real name with that player, and theirs with you.",
				onAccept = function() SetCVar("pendingInviteInfoShown", 1) end })
		end
	end
end

local function refresh()
	if page == "allies" and not alliesOn() then page = "friends" end
	if page ~= "raid" then raidInfo = false end
	local lists = { friends = friends(), ignored = ignored(), allies = alliesOn() and allies() or {}, requests = requests() }
	f.psName:SetText(keep("player", UnitName("player")) or "")
	f.psClass:SetAtlas(GetClassAtlas(strlower(select(2, UnitClass("player")))))
	W.Color(f.psDot, statusColor())
	local st, n = f.psStatus, 0
	local filtered = filterSets[page] ~= nil
	for _ in pairs(filterSets[page] or {}) do n = n + 1 end
	W.SetIconState(f.psFilter, n > 0)
	f.psFilter.psTip = n > 0 and ("Filter (%d on)"):format(n) or "Filter"
	f.psFilter:SetShown(filtered)
	f.Search:SetPoint("TOPRIGHT", f.Sidebar, "TOPRIGHT", -(W.SHELL.side + (filtered and 36 or 0)), -(W.SHELL.header - 30))
	st.Label:SetText(BNConnected() and battleTag() or "Battle.net offline")
	st:SetEnabled(BNConnected())
	st.Arrow:SetShown(BNConnected())
	local nFriends = #lists.friends
	local nav = { { key = "friends", label = "Friends", icon = "star", count = nFriends } }
	if alliesOn() then nav[#nav + 1] = { key = "allies", label = "Recent allies", icon = "compact", count = #lists.allies } end
	nav[#nav + 1] = { key = "requests", label = "Friend requests", icon = "plus", count = #lists.requests }
	nav[#nav + 1] = { key = "ignored", label = "Ignored", icon = "close", count = #lists.ignored }
	nav[#nav + 1] = { key = "raid", label = "Raid", icon = "bolt", count = IsInRaid() and GetNumGroupMembers() or 0 }
	W.ShellNav(f, nav, page, function(k) page = k; M.Show() end)
	local p = PAGES[page == "raid" and raidInfo and "raidinfo" or page]
	W.ShellTitle(f, p[1], p[2](page == "raid" and raidInfo and raidLocks() or lists[page] or {}))
	W.ShellTabs(f, nil)
	local lead = UnitIsGroupLeader("player")
	ns.Footer(f, page == "raid" and {
		-- The stock Raid Info button: on while there are saved instances.
		{ label = raidInfo and "Groups" or "Raid info", onClick = function() raidInfo = not raidInfo; M.Show() end },
	} or {}, page == "raid" and (not IsInRaid() and {
		{ label = "Convert to raid", onClick = function() C_PartyInfo.ConvertToRaid(); M.Show() end, opts = { primary = true } },
	} or {
		{ label = "Ready check", onClick = function() DoReadyCheck() end, opts = { primary = true } },
		{ label = "Convert to party", onClick = function() C_PartyInfo.ConvertToParty(); M.Show() end },
	}) or page == "ignored" and {
		{ label = "Ignore player", onClick = ignorePlayer, opts = { primary = true } },
	} or {
		{ label = "Add friend", onClick = addFriend, opts = { primary = true } },
		{ label = "Send message", onClick = function() ChatFrameUtil.OpenChat(SLASH_WHISPER1 .. " ") end },
	})
	local fb = f.footerButtons
	if page ~= "raid" then
		ns.SetEnabled(fb.right[1], page == "ignored" or not C_SocialRestrictions.IsFriendsDisabled(), "Adding friends is disabled.")
	elseif not IsInRaid() then
		ns.SetEnabled(fb.right[1], C_PartyInfo.AllowedToDoPartyConversion(true), "Only a party's leader can make it a raid.")
		ns.SetEnabled(fb.left[1], raidInfo or hasLocks(), "You are saved to no instance.")
	else
		ns.SetEnabled(fb.right[1], lead or UnitIsGroupAssistant("player"), "Only the leader or an assistant can start a ready check.")
		ns.SetEnabled(fb.right[2], C_PartyInfo.AllowedToDoPartyConversion(false), "Only the leader of a raid of five or fewer can make it a party.")
		ns.SetEnabled(fb.left[1], raidInfo or hasLocks(), "You are saved to no instance.")
	end
	if f.psRaidBar then f.psRaidBar:Hide() end
	for _, g in ipairs(groups) do g.Head:Hide(); g.Panel:Hide() end
	local h
	local story = DifficultyUtil and DifficultyUtil.InStoryRaid and DifficultyUtil.InStoryRaid()
	if page == "raid" and not raidInfo then
		f.psPanel:Hide()
		-- The stock tab is off in a story raid; out of a raid it explains raids.
		f.psEmpty:SetText(story and "The raid list is unavailable in story raids."
			or "You are not in a raid. A raid holds up to forty players in eight groups: the party's leader can make the party a raid.")
		f.psEmpty:SetShown(story or not IsInRaid())
		h = IsInRaid() and not story and paintRaid() or 80
	else
		local list = {}
		local src = page == "raid" and raidLocks() or lists[page]
		for _, e in ipairs(src) do if matches(e) then list[#list + 1] = e end end
		if page == "friends" then list = grouped(list, FRIEND_HEADS) end
		if page == "requests" then list = grouped(list, REQUEST_HEADS) end
		if page == "ignored" then list = grouped(list, IGNORE_HEADS) end
		if page == "allies" then list = grouped(list, ALLY_HEADS) end
		local ready = page ~= "allies" or C_RecentAllies.IsRecentAllyDataReady()
		f.psEmpty:SetText(not ready and "Recent allies load in the game's Social window: type /friends and open its Recent Allies tab."
			or (query ~= "" or n > 0) and page ~= "raid" and "No one matches." or p[3])
		h = paintRows(list)
	end
	W.ShellBody(f, h)
end

function M.Show(key)
	if not f then build() end
	page = key or page
	-- No TryRequestRecentAlliesData: it is restricted to the game's code; the
	-- stock Recent Allies tab asks, and RECENT_ALLIES_DATA_READY fills ours.
	if page == "raid" then RequestRaidInfo() end
	refresh()
	f:Show()
	if page == "requests" then realIDWarning() end
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
		"RAID_ROSTER_UPDATE", "PARTY_LEADER_CHANGED", "PLAYER_ROLES_ASSIGNED", "UNIT_CONNECTION", "UNIT_LEVEL",
		"READY_CHECK", "READY_CHECK_CONFIRM", "READY_CHECK_FINISHED", "UPDATE_INSTANCE_INFO",
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
-- In game the Social UI (SocialUIFrame) stands in for FriendsFrame (ToggleFriendsFrame).
function M.stock()
	for _, fr in ipairs({ SocialUIFrame or false, FriendsFrame or false }) do
		if fr and fr:IsShown() then return fr end
	end
end

ns.Module("social", M)
