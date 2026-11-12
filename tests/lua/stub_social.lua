-- The client's friends lists, raid roster and FriendsFrame as the Social sees
-- them; the values are the preview's sample warrior and her friends.
-- stub.told, stub.invited, stub.popup, stub.unignored, stub.added, stub.chatText
-- record what our clicks asked of the client. stub.raid = false leaves the raid.

-- The game's window: addon code must never show or hide it (docs/CLIENT.md, rule 8).
FriendsFrame = CreateFrame("Frame", "FriendsFrame", UIParent)
FriendsFrame:Hide()
function FriendsFrame.Hide() error("addon code hid FriendsFrame", 2) end
function FriendsFrame.Show() error("addon code showed FriendsFrame", 2) end
stub.bindings.TOGGLESOCIAL = { "O" }
stub.bindings.TOGGLEFRIENDSTAB = { "SHIFT-O" }
stub.bindings.TOGGLERAIDTAB = { "CTRL-O" }
local function stockShow() FriendsFrame.shown = true end
stub.bindingRun.TOGGLESOCIAL, stub.bindingRun.TOGGLEFRIENDSTAB, stub.bindingRun.TOGGLERAIDTAB = stockShow, stockShow, stockShow

function UnitClass(unit) return "Warrior", "WARRIOR", 1 end
local CLASSES = { WARRIOR = "Warrior", PRIEST = "Priest", MAGE = "Mage", ROGUE = "Rogue", HUNTER = "Hunter", PALADIN = "Paladin", DRUID = "Druid" }
function GetPlayerInfoByGUID(guid)
	local file = guid and guid:match("^Player%-(%u+)")
	if file then return CLASSES[file], file end
end

-- { name, connected, level, class, zone }
local WOW = {
	{ "Aelric", true, 24, "PALADIN", "Elwynn Forest" },
	{ "Brannoc", true, 22, "PRIEST", "Westfall", afk = true },
	{ "Corwyn", true, 25, "ROGUE", "Redridge Mountains" },
	{ "Dovaline", false, 19, "MAGE" },
	{ "Eldric", false, 30, "HUNTER" },
}
local ignores = { "Spamalot", "Goldseller" }
C_FriendList = {}
function C_FriendList.GetNumFriends() return #WOW end
function C_FriendList.GetNumOnlineFriends() return 3 end
function C_FriendList.GetFriendInfoByIndex(i)
	local w = WOW[i]
	return w and { name = w[1], connected = w[2], level = w[2] and w[3] or 0, className = w[2] and CLASSES[w[4]] or nil,
		area = w[5], afk = w.afk, guid = "Player-" .. w[4] .. "-" .. i }
end
function C_FriendList.GetNumIgnores() return #ignores end
function C_FriendList.GetIgnoreName(i) return ignores[i] end
function C_FriendList.DelIgnore(name)
	for i, n in ipairs(ignores) do if n == name then table.remove(ignores, i); stub.unignored = name; return true end end
	return false
end
function C_FriendList.AddFriend(name) stub.added = name end
function C_FriendList.AddIgnore(name) ignores[#ignores + 1] = name; stub.ignoredName = name end
-- The target: stub.target = name of a friendly player, else none.
function UnitCanCooperate() return stub.target ~= nil end
function UnitIsHumanPlayer() return stub.target ~= nil end
function GetUnitName() return stub.target end
function BNSendFriendInvite(tag) stub.added = tag end

-- Battle.net: one in WoW, one in the app, one offline. In combat their names
-- reach addon code secret, as on some clients. The client lists favorites
-- first (Sefa, offline), then the online ones. Mira is away and free to
-- queue, Jon busy; tags are the friends' own (Enum.BattleNetFriendTag).
Enum.BattleNetFriendTag = { Professions = 0, PvP = 1, Raiding = 2, Dungeons = 3, Delves = 4, Questing = 5, Roleplaying = 6,
	DamagerRole = 7, HealerRole = 8, TankRole = 9 }
local TAG = Enum.BattleNetFriendTag
local BN = {
	{ name = "Sefa", tag = "Sefa#4410", online = false, last = 3 * 86400, favorite = true, tags = { TAG.Raiding } },
	{ name = "Mira", tag = "Mira#1123", online = true, client = "WoW", char = "Thessaly", level = 26, class = "DRUID", zone = "Darkshore",
		afk = true, free = true, tags = { TAG.Raiding, TAG.HealerRole } },
	{ name = "Jon", tag = "Jon#2871", online = true, client = "App", rich = "In the Battle.net app", dnd = true, tags = { TAG.Roleplaying } },
}
C_BattleNet = {}
function BNGetNumFriends() return #BN, 2, 1, 0 end
function BNConnected() return true end
-- The player's presence: stub.bnAFK, stub.bnDND, stub.bnHidden; the Set calls change it.
function BNGetInfo() return 1, "Testchar#1000", nil, "", stub.bnAFK or false, stub.bnDND or false, true, stub.bnHidden or false end
function C_BattleNet.SetAFK(on) stub.bnAFK = on end
function C_BattleNet.SetDND(on) stub.bnDND = on end
function C_BattleNet.SetAppearOffline(on) stub.bnHidden = on end
-- Forever's game type has no Delves tag.
function C_BattleNet.AreFriendTagsEnabled() return true end
function C_BattleNet.IsFriendTagSupportedForCurrentGameType(t) return t ~= TAG.Delves end
-- The client's search, as the stub reads it: any checked status, then any
-- checked tag. stub.searchInfo is the last search asked for.
function C_BattleNet.SearchFriends(info)
	stub.searchInfo = info
	local out = {}
	for i, b in ipairs(BN) do
		local anyStatus = info.isOnline or info.isOffline or info.isAFK or info.isDND or info.isInQueue or info.isAvailableForQueue
		local status = not anyStatus or (info.isOnline and b.online) or (info.isOffline and not b.online)
			or (info.isAFK and b.afk) or (info.isDND and b.dnd) or (info.isAvailableForQueue and b.free)
		local tagged = #info.tags == 0
		for _, want in ipairs(info.tags) do
			for _, t in ipairs(b.tags or {}) do if t == want then tagged = true end end
		end
		if status and tagged then out[#out + 1] = i end
	end
	return out
end
function C_BattleNet.GetFriendAccountInfo(i)
	local b = BN[i]
	if not b then return nil end
	local secret = InCombatLockdown() and stub.SECRET
	return { bnetAccountID = 100 + i, accountName = secret or b.name, isFavorite = b.favorite or false, battleTag = b.tag, lastOnlineTime = b.last and time() - b.last,
		isAFK = b.afk or false, isDND = b.dnd or false, friendTags = b.tags or {},
		gameAccountInfo = { isOnline = b.online, clientProgram = b.client or "", wowProjectID = b.client == "WoW" and WOW_PROJECT_ID or nil, characterName = b.char and (secret or b.char), characterLevel = b.level,
			className = b.class and CLASSES[b.class], areaName = b.zone, richPresence = b.rich,
			playerGuid = b.class and "Player-" .. b.class .. "-9" } }
end
-- The client's title icons: the texture records the client it was set for.
BNET_CLIENT_WOW, WOW_PROJECT_ID = "WoW", 1
Enum.TitleIconVersion = { Small = 0, Medium = 1, Large = 2 }
C_Texture = C_Texture or {}
function C_Texture.SetTitleIconTexture(tex, client, version)
	tex.psClient, tex.psVersion = client, version
end
function FriendsFrame_GetLastOnline(t) return ("%d days"):format(math.floor((time() - t) / 86400)) end

-- What the clicks reach: the chat, the group invite, the game's unit menu.
SLASH_WHISPER1 = "/w"
ChatFrameUtil = {
	SendTell = function(name) stub.told = name end,
	SendBNetTell = function(name) stub.told = name end,
	OpenChat = function(text) stub.chatText = text end,
}
C_PartyInfo = { InviteUnit = function(name) stub.invited = name end }
function FriendsFrame_BattlenetInviteByIndex(i) stub.invited = i end
function FriendsFrame_ShowDropdown(name, connected) stub.popup = { "FRIEND", name } end
function FriendsFrame_ShowBNDropdown(name, connected) stub.popup = { "BN_FRIEND", name } end

-- A raid of twelve over three groups: { name, group, class, role, online }
TANK, HEALER, DAMAGER = "Tank", "Healer", "Damage"
local RAID = {
	{ "Testchar", 1, "WARRIOR", "TANK" }, { "Aelric", 1, "PALADIN", "HEALER" }, { "Brannoc", 1, "PRIEST", "HEALER" },
	{ "Corwyn", 1, "ROGUE", "DAMAGER" }, { "Thessaly", 1, "DRUID", "DAMAGER" },
	{ "Garrick", 2, "WARRIOR", "TANK" }, { "Hollis", 2, "MAGE", "DAMAGER" }, { "Ingra", 2, "HUNTER", "DAMAGER" },
	{ "Jessamy", 2, "PRIEST", "HEALER", false },
	{ "Kael", 3, "MAGE", "DAMAGER" }, { "Lorne", 3, "ROGUE", "DAMAGER" }, { "Maelis", 3, "DRUID", "HEALER" },
}
stub.raid = true
function IsInRaid() return stub.raid end
function GetNumGroupMembers() return stub.raid and #RAID or 0 end
function GetRaidRosterInfo(i)
	local m = RAID[i]
	if not m then return end
	return m[1], 0, m[2], 25, CLASSES[m[3]], m[3], "", m[5] ~= false, false, nil, false, m[4]
end

-- Pending Battle.net friend requests: stub.accepted / stub.declined record the
-- answer, stub.blocked the blocked account, stub.reported the report asked for.
Enum.BattleNetFriendLevel = { BattleTag = 0, RealID = 1, Title = 2 }
local invites = {
	{ inviteID = 7, accountName = "Rook", friendLevel = Enum.BattleNetFriendLevel.BattleTag, creationTimestamp = time() - 2 * 86400 },
	{ inviteID = 8, accountName = "Wren", friendLevel = Enum.BattleNetFriendLevel.Title },
	{ inviteID = 9, accountName = "Tamsin Ashby", friendLevel = Enum.BattleNetFriendLevel.RealID, creationTimestamp = time() - 5 * 86400 },
}
-- Battle.net accounts whose invites are blocked: { id, name }.
local blocks = { { 31, "Hexley" } }
function BNGetNumBlocked() return #blocks end
function BNGetBlockedInfo(i) local b = blocks[i]; if b then return b[1], b[2] end end
function C_BattleNet.SetBlocked(id, on)
	stub.blocked = on and id or nil
	for i, b in ipairs(blocks) do if b[1] == id and not on then table.remove(blocks, i); stub.unblocked = id end end
end
Enum.ReportType = { Friend = 3 }
ReportInfo = { CreateReportInfoFromType = function(_, t) return { reportType = t } end }
PlayerLocation = { CreateFromBattleNetID = function(_, id) return { bnetID = id } end }
ReportFrame = { InitiateReport = function(_, info, name, loc) stub.reported = { info.reportType, name, loc.bnetID } end }
function BNGetNumFriendInvites() return #invites end
function C_BattleNet.GetFriendInviteInfo(i) return invites[i] end
local function answer(id)
	for i, v in ipairs(invites) do if v.inviteID == id then table.remove(invites, i) end end
end
function BNAcceptFriendInvite(id) stub.accepted = id; answer(id) end
function BNDeclineFriendInvite(id) stub.declined = id; answer(id) end

-- Recent allies, presorted by the client (pinned first); stub.alliesReady = false
-- while it loads. Pins change through SetRecentAllyPinned (stub.pinned records it);
-- the search keeps the allies a status or category filter asks for (stub.allySearch).
local CLASS_IDS = { [1] = "WARRIOR", [4] = "ROGUE", [8] = "MAGE" }
C_CreatureInfo = {
	GetClassInfo = function(id) local f = CLASS_IDS[id]; return f and { classFile = f, className = CLASSES[f] } end,
	GetRaceInfo = function(id) return id and { raceName = "Human" } end,
	GetFactionInfo = function(id) return id and { name = "Alliance" } end,
}
function SecondsToTime(s) return ("%d days"):format(math.floor(s / 86400)) end
Enum.RecentAlliesInteractionCategoryFilter = { Professions = 0, PvP = 1, Raiding = 2, Dungeons = 3, Delves = 4, Questing = 5 }
stub.alliesReady = true
local ALLIES = {
	{ characterData = { guid = "Player-ROGUE-20", name = "Vessa", fullName = "Vessa-Realm", level = 23, classID = 4, raceID = 1 },
		stateData = { isOnline = true, currentLocation = "The Deadmines", pinExpirationDate = GetServerTime() + 20 * 86400 },
		interactionData = { note = "Great tank", interactions = { { description = "Grouped in The Deadmines", timestamp = time() - 86400, category = 3 } } } },
	{ characterData = { guid = "Player-MAGE-21", name = "Orrin", fullName = "Orrin-Realm", level = 21, classID = 8, raceID = 1 },
		stateData = { isOnline = false },
		interactionData = { interactions = { { description = "Grouped in Westfall", timestamp = time() - 2 * 86400, category = 5 } } } },
}
C_RecentAllies = {
	IsSystemEnabled = function() return true end,
	IsRecentAllyDataReady = function() return stub.alliesReady end,
	-- Restricted to the game's code: addon code may not call it.
	TryRequestRecentAlliesData = function() stub.forbidden = "TryRequestRecentAlliesData" end,
	GetRecentAllies = function() return ALLIES end,
	IsInteractionCategoryFilterSupportedForCurrentGameType = function(v) return v ~= Enum.RecentAlliesInteractionCategoryFilter.Delves end,
	SearchRecentAllies = function(info)
		stub.allySearch = info
		local out = {}
		for _, a in ipairs(ALLIES) do
			local st, ok = a.stateData, true
			if info.isOnline or info.isOffline or info.isAFK or info.isDND then
				ok = (info.isOnline and st.isOnline) or (info.isOffline and not st.isOnline) or false
			end
			if ok and #info.interactionCategoryFilters > 0 then
				ok = false
				for _, c in ipairs(info.interactionCategoryFilters) do
					for _, i in ipairs(a.interactionData.interactions) do if i.category == c then ok = true end end
				end
			end
			if ok then out[#out + 1] = a end
		end
		return out
	end,
	SetRecentAllyPinned = function(guid, on)
		stub.pinned = { guid, on }
		for _, a in ipairs(ALLIES) do
			if a.characterData.guid == guid then a.stateData.pinExpirationDate = on and GetServerTime() + 3 * 86400 or nil end
		end
	end,
}
function UnitPopup_OpenMenu(which, context) stub.popup = { which, context.name } end
