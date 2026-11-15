-- The Group Finder's Listing data (load after stub_groupfinder.lua, whose
-- guarded calls stay as they are): categories, activity groups and
-- activities with levels, a saved lockout, the solo roles, the group, and the
-- enums and voice chat state the page reads. The player is level 24.
-- Records:
--   stub.copied        CopyActiveEntryInfoToCreationFields calls; stub.copiedListing, stub.listing then
--   stub.roles         the last C_LFGListRoles.SetRoles table
--   stub.rolePoll      InitiateRolePoll calls
-- stub.lfgGroup = { size, leader, assistant } puts the player in a group;
-- stub.lfgRole is the role assigned there.

Enum = Enum or {}
Enum.LFGEntryGeneralPlaystyle = { None = 0, Learning = 1, FunRelaxed = 2, FunSerious = 3, Expert = 4 }
Enum.LFGEntryVoiceMode = { None = 0, Discord = 1, Legacy = 2, Custom = 3 }
Enum.VoiceProviderID = { Legacy = 0, Discord = 1 }
LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME or 1
Constants = Constants or {}
Constants.LFGConstsExposed = { GROUP_FINDER_MAX_ACTIVITY_CAPACITY = 6 }
C_Discord = { IsVoiceEnabled = function() return true end }
C_VoiceChat = { GetActiveChannelID = function() return nil end }

local CATEGORIES = {
	[2] = { name = "Dungeons" },
	[114] = { name = "Raids" },
	[116] = { name = "Quests & Zones" },
	[118] = { name = "Battlegrounds" },
	[120] = { name = "Custom", autoChooseActivity = true },
}
local GROUPS = { [10] = { "Classic Dungeons", 1 }, [11] = { "Dungeon Challenges", 2 }, [20] = { "Classic Raids", 1 } }
-- id = { name, category, group, min, max, order, mapID, difficulty, maxPlayers }
local ACTIVITIES = {
	[1] = { "Ragefire Chasm", 2, 10, 13, 18, 0, 389, 1, 5 },
	[2] = { "Wailing Caverns", 2, 10, 17, 24, 0, 43, 1, 5 },
	[3] = { "The Deadmines", 2, 10, 17, 26, 0, 36, 1, 5 },
	[4] = { "Shadowfang Keep", 2, 10, 22, 30, 0, 33, 1, 5 },
	[5] = { "Blackfathom Deeps", 2, 10, 20, 30, 0, 48, 1, 5 },
	[6] = { "Scarlet Monastery: Armory", 2, 10, 32, 42, 0, 189, 1, 5 },
	[7] = { "Stratholme Challenge", 2, 11, 58, 60, 0, 329, 2, 5 },
	[8] = { "Any Dungeon", 2, 0, 0, 0, 1, nil, nil, 5 },
	[20] = { "Molten Core", 114, 20, 60, 60, 0, 409, 9, 40 },
	[30] = { "Stranglethorn Vale", 116, 0, 30, 45, 0 },
	[31] = { "Ashenvale", 116, 0, 18, 30, 0 },
	[40] = { "Warsong Gulch", 118, 0, 50, 60, 0 },
	[50] = { "Custom", 120, 0, 0, 0, 0 },
}

function C_LFGList.GetAvailableCategories() return { 2, 114, 116, 118, 120 } end
function C_LFGList.GetLfgCategoryInfo(id) return CATEGORIES[id] end
-- A new table each call (stock's filter removes from it).
function C_LFGList.GetAvailableActivities(category, group)
	local out = {}
	for id, a in pairs(ACTIVITIES) do
		if (not category or a[2] == category) and (group == nil or a[3] == group) then out[#out + 1] = id end
	end
	table.sort(out)
	return out
end
function C_LFGList.GetAvailableActivityGroups(category)
	local out, seen = {}, {}
	for _, a in pairs(ACTIVITIES) do
		if a[2] == category and a[3] ~= 0 and not seen[a[3]] then seen[a[3]] = true; out[#out + 1] = a[3] end
	end
	table.sort(out)
	return out
end
function C_LFGList.GetActivityGroupInfo(id) local g = GROUPS[id] if g then return g[1], g[2] end end
function C_LFGList.GetActivityInfoTable(id)
	local a = ACTIVITIES[id]
	if not a then return nil end
	return { fullName = a[1], shortName = "", categoryID = a[2], groupFinderActivityGroupID = a[3], minLevelSuggestion = a[4],
		maxLevelSuggestion = a[5], orderIndex = a[6], mapID = a[7], difficultyID = a[8], maxNumPlayers = a[9] or 0 }
end
stub.copied = 0
function C_LFGList.CopyActiveEntryInfoToCreationFields()
	stub.copied = stub.copied + 1
	stub.copiedListing = stub.listing
end

-- Solo roles: the client keeps them (saved across sessions).
stub.savedRoles = { tank = false, healer = false, dps = true }
C_LFGListRoles = {
	GetSavedRoles = function() return stub.savedRoles end,
	GetRoles = function() return stub.savedRoles end,
	SetRoles = function(t)
		stub.roles = t
		stub.savedRoles = { tank = t.tank and true or false, healer = t.healer and true or false, dps = t.dps and true or false }
		return true
	end,
}

-- The group: none unless a scene sets stub.lfgGroup.
function IsInGroup() return stub.lfgGroup ~= nil end
function UnitIsGroupLeader() return stub.lfgGroup ~= nil and stub.lfgGroup.leader or false end
function UnitIsGroupAssistant() return stub.lfgGroup ~= nil and stub.lfgGroup.assistant or false end
function GetNumGroupMembers() return stub.lfgGroup and stub.lfgGroup.size or 0 end
local rolesAssigned = UnitGroupRolesAssigned
function UnitGroupRolesAssigned(unit)
	if unit == "player" and stub.lfgGroup then return stub.lfgRole or "NONE" end
	return rolesAssigned and rolesAssigned(unit) or "NONE"
end
stub.rolePoll = 0
function InitiateRolePoll() stub.rolePoll = stub.rolePoll + 1 end

-- One lockout: Shadowfang Keep, 2 of 4 bosses down.
function GetNumSavedInstances() return 1 end
function GetSavedInstanceInfo(i)
	if i == 1 then return "Shadowfang Keep", 1, 0, 1, true, false, 0, false, 5, "Normal", 4, 2, false, 33 end
end
stub.raidInfoAsked = 0
function RequestRaidInfo() stub.raidInfoAsked = stub.raidInfoAsked + 1 end
