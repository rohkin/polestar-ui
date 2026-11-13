-- The client's guild as the Guild window sees it: the stock CommunitiesFrame
-- (never touched), the guild's club members (C_Club), C_GuildInfo, the news,
-- perks, rewards, challenges and the guild log. The player (Testchar) is an
-- officer of The Night Watch. stub.guildNone leaves the guild; stub.gm makes
-- the player its master; stub.noOfficer drops the officer rights.
-- What our clicks asked: stub.rankSet, stub.noteSet, stub.removed,
-- stub.guildInvited, stub.left, stub.motdSet, stub.infoSet, stub.sticky,
-- stub.newsFilter, stub.popup, stub.recipes, stub.guildControl, stub.chatText,
-- stub.invited, stub.asked[what].

-- The game's window: addon code must never show or hide it (docs/CLIENT.md, rule 8).
CommunitiesFrame = CreateFrame("Frame", "CommunitiesFrame", UIParent)
CommunitiesFrame:Hide()
function CommunitiesFrame.Hide() error("addon code hid CommunitiesFrame", 2) end
function CommunitiesFrame.Show() error("addon code showed CommunitiesFrame", 2) end
GuildMicroButton = CreateFrame("Button", "GuildMicroButton", UIParent)
GuildMicroButton:SetSize(28, 36)
GuildMicroButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -200, 2)
GuildMicroButton.tooltipText = "Guild & Communities (J)"
stub.bindings.TOGGLEGUILDTAB = { "J" }
function stub.bindingRun.TOGGLEGUILDTAB() CommunitiesFrame.shown = true end
function UnitFactionGroup() return stub.neutral and "Neutral" or "Alliance" end
stub.asked = {}

Enum.ClubMemberPresence = { Unknown = 0, Online = 1, OnlineMobile = 2, Offline = 3, Away = 4, Busy = 5 }
Enum.ClubType = { BattleNet = 0, Character = 1, Guild = 2, Other = 3 }
local PR = Enum.ClubMemberPresence

local CLASSES = { [1] = { "WARRIOR", "Warrior" }, [2] = { "PALADIN", "Paladin" }, [4] = { "ROGUE", "Rogue" }, [5] = { "PRIEST", "Priest" },
	[8] = { "MAGE", "Mage" }, [9] = { "WARLOCK", "Warlock" }, [11] = { "DRUID", "Druid" }, [3] = { "HUNTER", "Hunter" } }
C_CreatureInfo = C_CreatureInfo or {}
function C_CreatureInfo.GetClassInfo(id) local c = CLASSES[id]; return c and { classFile = c[1], className = c[2] } end
function C_CreatureInfo.GetRaceInfo() return { raceName = "Human" } end
function GetClassAtlas(class) return "classicon-" .. class end

-- { name, level, classID, zone, rank order, presence, note, officer note, last online {y, m, d, h}, professions }
local RANKS = { "Guild Master", "Officer", "Veteran", "Member", "Initiate" }
local MEMBERS = {
	{ "Testchar", 30, 1, "Stormwind City", 2, PR.Online, "Main tank", "Reliable", nil, { 164, "Blacksmithing", 150, 186, "Mining", 175 } },
	{ "Aelric", 32, 2, "Elwynn Forest", 1, PR.Online, "Guild master", "", nil, { 197, "Tailoring", 120 } },
	{ "Brannoc", 29, 5, "Westfall", 3, PR.Away, "Healer", "Promote soon" },
	{ "Corwyn", 31, 4, "Redridge Mountains", 4, PR.Busy, "", "" },
	{ "Dovaline", 25, 8, nil, 4, PR.OnlineMobile, "Alt of Corwyn", "" },
	{ "Eldric", 33, 3, nil, 3, PR.Offline, "Hunter pets", "", { 0, 0, 3, 0 }, { 186, "Mining", 90 } },
	{ "Fennick", 18, 9, nil, 5, PR.Offline, "", "Trial ends Friday", { 0, 2, 0, 0 } },
	{ "Gwendolyn", 28, 11, "Darkshore", 4, PR.Online, "Feral and resto", "" },
	{ "Halvard", 22, 1, nil, 5, PR.Offline, "", "", { 1, 0, 0, 0 } },
}
local function member(i)
	local m = MEMBERS[i]
	local prof = m[10] or {}
	local info = { memberId = i, name = m[1], level = m[2], classID = m[3], zone = m[4], guildRankOrder = m[5], guildRank = RANKS[m[5]],
		presence = m[6], memberNote = m[7], officerNote = m[8], isSelf = i == 1, guid = "Player-1-" .. i, race = 1,
		profession1ID = prof[1], profession1Name = prof[2], profession1Rank = prof[3],
		profession2ID = prof[4], profession2Name = prof[5], profession2Rank = prof[6], clubType = Enum.ClubType.Guild }
	if m[9] then info.lastOnlineYear, info.lastOnlineMonth, info.lastOnlineDay, info.lastOnlineHour = unpack(m[9]) end
	-- In chat lockdown the members' names reach addon code secret.
	if stub.secretRoster then info.name = stub.SECRET end
	return info
end

C_Club = {}
function C_Club.GetGuildClubId() return not stub.guildNone and 77 or nil end
function C_Club.GetClubMembers(id)
	local ids = {}
	for i in ipairs(MEMBERS) do ids[i] = i end
	return ids
end
function C_Club.GetMemberInfo(id, i) return MEMBERS[i] and member(i) end
function C_Club.GetMemberInfoForSelf() local m = member(1); m.guildRankOrder = stub.gm and 1 or 2; return m end
function C_Club.GetClubInfo(id) return { clubId = id, name = "The Night Watch", clubType = Enum.ClubType.Guild } end
function C_Club.GetClubPrivileges() return {} end
function C_Club.GetAssignableRoles() return {} end
function UnitPopup_OpenMenu(which, ctx) stub.popup = { which, ctx.name } end

function IsInGuild() return not stub.guildNone end
function GetGuildInfo(unit) return InCombatLockdown() and stub.SECRET or "The Night Watch", "Officer", 1 end
function IsGuildLeader() return stub.gm or false end
local function officer() return not stub.noOfficer end
function CanGuildPromote() return officer() end
function CanGuildDemote() return officer() end
function CanGuildInvite() return officer() end
function CanGuildRemove() return officer() end
function CanEditMOTD() return officer() end
function CanEditGuildInfo() return officer() end
function CanEditPublicNote() return officer() end
function CanReplaceGuildMaster() return stub.impeach or false end
function GuildControlGetNumRanks() return #RANKS end
function GuildControlGetRankName(i) return RANKS[i] end
function GuildControlUI_Show() stub.guildControl = true end
SLASH_GUILD1 = "/g"
ChatFrameUtil = ChatFrameUtil or {}
function ChatFrameUtil.OpenChat(text) stub.chatText = text end
function ChatFrameUtil.LinkItem(id, link) stub.linked = link or id end
C_PartyInfo = C_PartyInfo or {}
function C_PartyInfo.InviteUnit(name) stub.invited = name end

local motd, info = "Raid tonight at 8: bring flasks.", "A levelling guild for steady players.\nRaids Friday and Sunday."
C_GuildInfo = C_GuildInfo or {}
function C_GuildInfo.GuildRoster() stub.asked.roster = true end
function C_GuildInfo.GetMOTD() return motd end
function C_GuildInfo.GetInfoText() return info end
function C_GuildInfo.SetMOTD(t) motd = t; stub.motdSet = t end
function C_GuildInfo.SetInfoText(t) info = t; stub.infoSet = t end
function C_GuildInfo.CanViewOfficerNote() return officer() end
function C_GuildInfo.CanEditOfficerNote() return officer() end
function C_GuildInfo.IsGuildOfficer() return officer() end
function C_GuildInfo.CanSpeakInGuildChat() return true end
function C_GuildInfo.IsGuildReputationEnabled() return true end
function C_GuildInfo.IsEncounterGuildNewsEnabled() return true end
function C_GuildInfo.GetGuildTabardInfo() return { emblemFileID = 1234 } end
-- The Initiate rank needs an authenticator on the account.
function C_GuildInfo.IsGuildRankAssignmentAllowed(guid, rank) return rank ~= 5 end
function C_GuildInfo.SetGuildRankOrder(guid, rank) stub.rankSet = { guid, rank } end
function C_GuildInfo.SetNote(guid, note, public) stub.noteSet = { guid, note, public } end
function C_GuildInfo.RemoveFromGuild(guid) stub.removed = guid end
function C_GuildInfo.Invite(name) stub.guildInvited = name end
function C_GuildInfo.Leave() stub.left = true end
function C_GuildInfo.QueryGuildMemberRecipes(guid, prof) stub.recipes = { guid, prof } end
C_TradeSkillUI = C_TradeSkillUI or {}
function C_TradeSkillUI.IsGuildTradeSkillsEnabled() return true end
C_MythicPlus = { IsMythicPlusActive = function() return false end }

-- News: a date heading, then an item, an achievement and a sticky boss kill.
local NEWS = {
	{ isHeader = true, weekday = 4, month = 10, day = 11 },
	{ newsType = 3, whoText = "Gwendolyn", whatText = "|cffa335ee|Hitem:2244|h[Krol Blade]|h|r", newsDataID = 2244 },
	{ newsType = 1, whoText = "Corwyn", whatText = "Level 30", newsDataID = 9 },
	{ newsType = 2, whoText = "The guild", whatText = "Edwin VanCleef", data = { 36 }, isSticky = true },
}
function GetNumGuildNews() return #NEWS end
function C_GuildInfo.GetGuildNewsInfo(i) return NEWS[i] end
function QueryGuildNews() stub.asked.news = true end
function GuildNewsSort() end
function GuildNewsSetSticky(i, on) stub.sticky = { i, on } end
local filters = { true, true, true, true, true, true, false, false, true }
function GetGuildNewsFilters() return unpack(filters) end
function SetGuildNewsFilter(id, on) filters[id] = on == 1; stub.newsFilter = { id, on } end
C_AchievementInfo = C_AchievementInfo or {}
function C_AchievementInfo.AreGuildAchievementsEnabled() return false end
function CanShowAchievementUI() return true end
function GetAchievementInfo(id) return id, "Level 30", 10, true, nil, nil, nil, "Reach level 30." end
function GetRealZoneText() return "The Deadmines" end
function ShowAchievementFrameForAchievement(id) stub.achievement = id end
C_Calendar = { OpenCalendar = function() stub.asked.calendar = true end, GetNumGuildEvents = function() return 1 end,
	GetGuildEventInfo = function() return { title = "Deadmines run", weekday = 6, month = 1, monthDay = 1, hour = 20, minute = 0 } end }

-- Challenges: two of three this week.
local CHALLENGES = { { 1, 2, 7 }, { 2, 1, 1 }, { 3, 0, 3 } }
GUILD_CHALLENGE_TYPE1, GUILD_CHALLENGE_TYPE2, GUILD_CHALLENGE_TYPE3 = "Dungeon", "Raid", "Rated Battleground"
function GetNumGuildChallenges() return #CHALLENGES end
function GetGuildChallengeInfo(i) return unpack(CHALLENGES[i]) end
function RequestGuildChallengeInfo() stub.asked.challenges = true end

-- Benefits: two perks, three rewards (one behind an achievement, one a standing).
function GetNumGuildPerks() return 2 end
local PERKS = { { "Fast Track", 78631, 132307 }, { "Mount Up", 78633, 132261 } }
function GetGuildPerkInfo(i) return unpack(PERKS[i]) end
C_Spell = C_Spell or {}
function C_Spell.GetSpellLink(id) return "|Hspell:" .. id .. "|h[spell]|h" end
local REWARDS = {
	{ 0, 62286, "Guild Vault", 236250, 5, 500000 },
	{ 5035, 62040, "Ancient Guild Banner", 133781, 4, 1500000 },
	{ 0, 63206, "Wrap of Unity", 133770, 7, 3000000 },
}
function GetNumGuildRewards() return #REWARDS end
function GetGuildRewardInfo(i) return unpack(REWARDS[i]) end
function RequestGuildRewards() stub.asked.rewards = true end
FACTION_STANDING_LABEL4, FACTION_STANDING_LABEL5, FACTION_STANDING_LABEL6, FACTION_STANDING_LABEL7 = "Neutral", "Friendly", "Honored", "Revered"
C_Reputation = C_Reputation or {}
function C_Reputation.GetGuildFactionData()
	return { name = "The Night Watch", reaction = 5, currentReactionThreshold = 3000, nextReactionThreshold = 9000, currentStanding = 5100 }
end
function GetMoney() return 1000000 end

-- The guild log: oldest first, as the client lists it.
local EVENTS = {
	{ "join", "Halvard", nil, nil, 0, 1, 0, 0 },
	{ "invite", "Aelric", "Fennick", nil, 0, 0, 12, 0 },
	{ "promote", "Aelric", "Brannoc", "Veteran", 0, 0, 2, 0 },
	{ "quit", "Ishara", nil, nil, 0, 0, 0, 5 },
}
function QueryGuildEventLog() stub.asked.log = true end
function GetNumGuildEvents() return #EVENTS end
function GetGuildEventInfo(i) return unpack(EVENTS[i]) end
