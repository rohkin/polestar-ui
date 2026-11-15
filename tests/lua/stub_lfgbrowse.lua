-- The Group Finder's Browse page data (over stub_groupfinder.lua, whose
-- guarded calls stay as they are): categories, activities by group with
-- levels and display types, and search results of every display type.
-- The player (level 24) is a healer or damage dealer. Records:
--   stub.whisper   the name ChatFrameUtil.SendTell was given
--   stub.invited   the name C_PartyInfo.InviteUnit was given
--   stub.reported  { reportType, resultID, name } from ReportFrame:InitiateReport
-- stub.results: resultID -> { info, leader, members, counts, encounters };
-- stub.resultOrder: what GetFilteredSearchResults hands back (unsorted).
-- stub.inGroup / stub.leader / stub.assistant: the player's group.

Enum.LFGListDisplayType = { RoleCount = 0, RoleEnumerate = 1, ClassEnumerate = 2, HideAll = 3, PlayerCount = 4, Comment = 5 }
Enum.LFGEntryVoiceMode = { None = 0, Legacy = 1, Discord = 2, Custom = 3 }
Enum.ReportType.GroupFinderPosting = 7
local DT = Enum.LFGListDisplayType
CLASS_SORT_ORDER = CLASS_SORT_ORDER or { "WARRIOR", "DEATHKNIGHT", "PALADIN", "MONK", "PRIEST", "SHAMAN", "DRUID", "ROGUE", "MAGE", "WARLOCK", "HUNTER", "DEMONHUNTER", "EVOKER" }

local CATEGORIES = { [2] = "Dungeons", [114] = "Raids", [116] = "Quests & Zones", [120] = "Custom" }
local GROUPS = { [1] = { "Classic Dungeons", 1 }, [2] = { "Classic Raids", 1 } }
local ACTIVITIES = {
	[11] = { "Deadmines", 2, 1, 17, 26, DT.RoleEnumerate, 5, true },
	[12] = { "Wailing Caverns", 2, 1, 17, 24, DT.RoleCount, 5, true },
	[13] = { "Scarlet Monastery", 2, 1, 26, 45, DT.ClassEnumerate, 5, true },
	[14] = { "Any Dungeon", 2, 0, 0, 0, DT.PlayerCount, 5, false },
	[21] = { "Molten Core", 114, 2, 60, 0, DT.RoleCount, 40, false },
	[31] = { "Stranglethorn Vale", 116, 0, 30, 45, DT.PlayerCount, 5, false },
	[41] = { "Custom", 120, 0, 0, 0, DT.Comment, 40, false },
	[42] = { "Chat", 120, 0, 0, 0, DT.HideAll, 40, false },
}

C_LFGList.GetAvailableCategories = function() return { 2, 114, 116, 120 } end
C_LFGList.GetLfgCategoryInfo = function(id) return CATEGORIES[id] and { name = CATEGORIES[id] } end
C_LFGList.GetAvailableActivities = function(cat)
	local out = {}
	for id, a in pairs(ACTIVITIES) do if a[2] == cat then out[#out + 1] = id end end
	table.sort(out)
	return out
end
C_LFGList.GetActivityInfoTable = function(id)
	local a = ACTIVITIES[id]
	return a and { fullName = a[1], shortName = "", categoryID = a[2], groupFinderActivityGroupID = a[3], minLevelSuggestion = a[4],
		maxLevelSuggestion = a[5], displayType = a[6], maxNumPlayers = a[7], useDungeonRoleExpectations = a[8], orderIndex = 0 }
end
C_LFGList.GetActivityGroupInfo = function(id) local g = GROUPS[id]; if g then return g[1], g[2] end end

local function counts(t, h, d, extra)
	local c = { TANK = t, HEALER = h, DAMAGER = d, NOROLE = 0, TANK_REMAINING = 1 - t, HEALER_REMAINING = 1 - h, DAMAGER_REMAINING = math.max(3 - d, 0) }
	for k, v in pairs(extra or {}) do c[k] = v end
	return c
end
local function member(name, class, level, role, leader, roles)
	return { name = name, classFilename = class, className = class, level = level, assignedRole = role or "NONE", isLeader = leader or false,
		lfgRoles = roles or { tank = false, healer = false, dps = false } }
end

-- One result of every kind: the player's own listing, a group of each display
-- type, a solo player listed for three activities, and a delisted solo player.
stub.results = {
	[1] = { info = { leaderName = "Testchar", activityIDs = { 11 }, numMembers = 1, hasSelf = true, age = 10, comment = "", voiceMode = 0, generalPlaystyle = 1 },
		members = { member("Testchar", "WARRIOR", 24, nil, true, { dps = true }) }, counts = counts(0, 0, 1, { LEADER_ROLE_DAMAGER = true }) },
	[2] = { info = { leaderName = "Brannoc", activityIDs = { 11 }, numMembers = 3, age = 300, comment = "", voiceMode = 2, newPlayerFriendly = true, generalPlaystyle = 2 },
		members = { member("Brannoc", "WARRIOR", 22, "TANK", true), member("Ellia", "PRIEST", 23, "HEALER"), member("Kezz", "MAGE", 21, "DAMAGER") },
		counts = counts(1, 1, 1), encounters = { "Rhahk'Zor", "Sneed" } },
	[3] = { info = { leaderName = "Saraphine", activityIDs = { 12 }, numMembers = 2, age = 200, comment = "", voiceMode = 0 },
		members = { member("Saraphine", "PRIEST", 22, "HEALER", true), member("Dorn", "PALADIN", 23, "TANK") }, counts = counts(1, 1, 0) },
	[4] = { info = { leaderName = "Velkar", activityIDs = { 13 }, numMembers = 4, age = 150, comment = "", voiceMode = 0 },
		members = { member("Velkar", "WARRIOR", 30, "TANK", true), member("Ana", "MAGE", 29, "DAMAGER"), member("Bo", "MAGE", 30, "DAMAGER"), member("Cyl", "PRIEST", 31, "HEALER") },
		counts = counts(1, 1, 2, { WARRIOR = 1, MAGE = 2, PRIEST = 1 }) },
	[5] = { info = { leaderName = "Grimtusk", activityIDs = { 14 }, numMembers = 3, age = 120, comment = "", voiceMode = 0 },
		members = { member("Grimtusk", "SHAMAN", 24, "DAMAGER", true), member("Ott", "ROGUE", 24, "DAMAGER"), member("Pim", "DRUID", 25, "HEALER") },
		counts = counts(0, 1, 2) },
	[6] = { info = { leaderName = "Mirelle", activityIDs = { 41 }, numMembers = 2, age = 100, comment = "LF healer, chill run", voiceMode = 3 },
		members = { member("Mirelle", "MAGE", 24, "DAMAGER", true), member("Quen", "HUNTER", 24, "DAMAGER") }, counts = counts(0, 0, 2) },
	[7] = { info = { leaderName = "Hollin", activityIDs = { 42 }, numMembers = 2, age = 90, comment = "", voiceMode = 0 },
		members = { member("Hollin", "WARLOCK", 24, "DAMAGER", true), member("Rue", "PRIEST", 24, "HEALER") }, counts = counts(0, 1, 1) },
	[8] = { info = { leaderName = "Thessa", activityIDs = { 11, 12, 14 }, numMembers = 1, age = 60, comment = "", voiceMode = 0 },
		members = { member("Thessa", "ROGUE", 24, nil, true, { dps = true }) }, counts = counts(0, 0, 1, { LEADER_ROLE_DAMAGER = true }) },
	[9] = { info = { leaderName = "Oakhart", activityIDs = { 12 }, numMembers = 1, age = 30, comment = "", voiceMode = 0, isDelisted = true },
		members = { member("Oakhart", "DRUID", 23, nil, true, { tank = true, healer = true }) }, counts = counts(0, 0, 0, { LEADER_ROLE_TANK = true, LEADER_ROLE_HEALER = true }) },
}
stub.resultOrder = { 9, 8, 7, 6, 5, 4, 3, 2, 1 }

C_LFGList.GetFilteredSearchResults = function()
	local list = {}
	for i, id in ipairs(stub.resultOrder) do list[i] = id end
	return #list, list
end
C_LFGList.GetSearchResultInfo = function(id)
	local r = stub.results[id]
	if not r then return nil end
	local t = { searchResultID = id }
	for k, v in pairs(r.info) do t[k] = v end
	t.hasSelf, t.isDelisted = t.hasSelf or false, t.isDelisted or false
	return t
end
C_LFGList.GetSearchResultPlayerInfo = function(id, i) local r = stub.results[id]; return r and r.members[i] end
C_LFGList.GetSearchResultLeaderInfo = function(id) local r = stub.results[id]; return r and r.members[1] end
C_LFGList.GetSearchResultMemberCounts = function(id) local r = stub.results[id]; return r and r.counts end
C_LFGList.GetSearchResultEncounterInfo = function(id) local r = stub.results[id]; return r and r.encounters end
C_LFGListRoles = C_LFGListRoles or {}
C_LFGListRoles.GetRoles = function() return { tank = false, healer = true, dps = true } end

function IsInGroup() return stub.inGroup or false end
function UnitIsGroupLeader(unit) return unit == "player" and (stub.leader or false) end
function UnitIsGroupAssistant(unit) return unit == "player" and (stub.assistant or false) end

ChatFrameUtil = ChatFrameUtil or {}
function ChatFrameUtil.SendTell(name) stub.whisper = name end
C_PartyInfo = C_PartyInfo or {}
function C_PartyInfo.InviteUnit(name) stub.invited = name end
ReportInfo = { CreateReportInfoFromType = function(_, t)
	return { reportType = t, SetGroupFinderSearchResultID = function(self, id) self.resultID = id end }
end }
ReportFrame = { InitiateReport = function(_, info, name) stub.reported = { info.reportType, info.resultID, name } end }
