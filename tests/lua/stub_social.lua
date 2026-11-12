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
	{ "Brannoc", true, 22, "PRIEST", "Westfall" },
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
		area = w[5], guid = "Player-" .. w[4] .. "-" .. i }
end
function C_FriendList.GetNumIgnores() return #ignores end
function C_FriendList.GetIgnoreName(i) return ignores[i] end
function C_FriendList.DelIgnore(name)
	for i, n in ipairs(ignores) do if n == name then table.remove(ignores, i); stub.unignored = name; return true end end
	return false
end
function C_FriendList.AddFriend(name) stub.added = name end
function BNSendFriendInvite(tag) stub.added = tag end

-- Battle.net: one in WoW, one in the app, one offline. In combat their names
-- reach addon code secret, as on some clients. The client lists favorites
-- first (Sefa, offline), then the online ones.
local BN = {
	{ name = "Sefa", tag = "Sefa#4410", online = false, last = 3 * 86400, favorite = true },
	{ name = "Mira", tag = "Mira#1123", online = true, char = "Thessaly", level = 26, class = "DRUID", zone = "Darkshore" },
	{ name = "Jon", tag = "Jon#2871", online = true, rich = "In the Battle.net app" },
}
C_BattleNet = {}
function BNGetNumFriends() return #BN, 2, 1, 0 end
function BNConnected() return true end
function BNGetInfo() return 1, "Testchar#1000", nil, "", stub.bnAFK or false, false, true end
function C_BattleNet.GetFriendAccountInfo(i)
	local b = BN[i]
	if not b then return nil end
	local secret = InCombatLockdown() and stub.SECRET
	return { bnetAccountID = 100 + i, accountName = secret or b.name, isFavorite = b.favorite or false, battleTag = b.tag, lastOnlineTime = b.last and time() - b.last,
		gameAccountInfo = { isOnline = b.online, characterName = b.char and (secret or b.char), characterLevel = b.level,
			className = b.class and CLASSES[b.class], areaName = b.zone, richPresence = b.rich,
			playerGuid = b.class and "Player-" .. b.class .. "-9" } }
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

-- Pending Battle.net friend requests: stub.accepted / stub.declined record the answer.
local invites = { { inviteID = 7, accountName = "Rook" } }
function BNGetNumFriendInvites() return #invites end
function C_BattleNet.GetFriendInviteInfo(i) return invites[i] end
local function answer(id)
	for i, v in ipairs(invites) do if v.inviteID == id then table.remove(invites, i) end end
end
function BNAcceptFriendInvite(id) stub.accepted = id; answer(id) end
function BNDeclineFriendInvite(id) stub.declined = id; answer(id) end

-- Recent allies, presorted by the client; stub.alliesReady = false while it loads.
local CLASS_IDS = { [1] = "WARRIOR", [4] = "ROGUE", [8] = "MAGE" }
C_CreatureInfo = { GetClassInfo = function(id) local f = CLASS_IDS[id]; return f and { classFile = f, className = CLASSES[f] } end }
stub.alliesReady = true
C_RecentAllies = {
	IsSystemEnabled = function() return true end,
	IsRecentAllyDataReady = function() return stub.alliesReady end,
	TryRequestRecentAlliesData = function() stub.alliesRequested = true end,
	GetRecentAllies = function()
		return {
			{ characterData = { guid = "Player-ROGUE-20", name = "Vessa", fullName = "Vessa-Realm", level = 23, classID = 4 },
				stateData = { isOnline = true, currentLocation = "The Deadmines" },
				interactionData = { interactions = { { description = "Grouped in The Deadmines" } } } },
			{ characterData = { guid = "Player-MAGE-21", name = "Orrin", fullName = "Orrin-Realm", level = 21, classID = 8 },
				stateData = { isOnline = false },
				interactionData = { interactions = { { description = "Grouped in Westfall" } } } },
		}
	end,
}
function UnitPopup_OpenMenu(which, context) stub.popup = { which, context.name } end
