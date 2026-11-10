-- The client calls the Legacy System reads; the values are the preview's
-- sample, as Forever has them: 3 legacy points of 65, rewards at 15, 25, 40
-- and 55 points (the last of two rewards); the Warrior challenges, one done.

local REWARDS = {
	[15] = { { name = "Holstered Replica Ironforge Air Rifle", description = "A toy for every character.", icon = 1 } },
	[25] = { { name = "Spectral Bear Cub", description = "A companion pet.", icon = 1 } },
	[40] = { { name = "Spectral Bear Tabard", description = "Worn proudly.", icon = 1 } },
	[55] = { { name = "Reins of the Spectral Bear", description = "A mount for every character.", icon = 1 }, { name = "Title: the Enduring", description = "", icon = 1 } },
}

C_MajorFactions = C_MajorFactions or {}
function C_MajorFactions.GetCurrentRenownLevel(id) return stub.legacyPoints or 3 end
function C_MajorFactions.GetRenownLevels(id)
	local t = {}
	for i = 1, 55 do t[i] = { factionID = id, level = i, locked = i > 3, isMilestone = false, isCapstone = false } end
	return t
end
function C_MajorFactions.GetRenownRewardsForLevel(id, level) return REWARDS[level] or {} end

RenownRewardUtil = { GetRenownRewardInfo = function(r) return r.icon, r.name, r.description end }

-- Challenges: Classes (Druid and Warrior), Tradeskills (Mining), Adventure
-- (Explorer, with Eastern Kingdoms under it) and Dungeons; Season Journey
-- holds a challenge the client does not show (not in its search list).
local CATS = { [1] = { "Classes", -1 }, [11] = { "Druid", 1 }, [19] = { "Warrior", 1 }, [2] = { "Tradeskills", -1 }, [21] = { "Mining", 2 },
	[4] = { "Adventure", -1 }, [41] = { "Explorer", 4 }, [411] = { "Eastern Kingdoms", 41 }, [3] = { "Dungeons", -1 }, [5] = { "Season Journey", -1 } }
-- { id, name, description, done here, done on another character, criteria }
local ACH = {
	[19] = {
		{ 901, "Novice Warrior", "Reach level 25 for the first time on a Warrior.", true },
		{ 902, "Experienced Warrior", "Reach level 45 for the first time on a Warrior.", false, false,
			{ { "Reach level 45", false, 0, 31, 45 } } },
		{ 903, "Master Warrior", "Reach level 60 for the first time on a Warrior, and learn every weapon skill a warrior can use before you do.", false, true },
	},
	[11] = { { 911, "Novice Druid", "Reach level 25 for the first time on a Druid.", false } },
	[21] = { { 921, "Deep Miner", "Mine each of these ores.", false, false,
		{ { "Copper Ore", true }, { "Tin Ore", true }, { "Iron Ore", false }, { "Mithril Ore", false }, { "Thorium Ore", false } } } },
	[3] = { { 931, "Into the Deadmines", "Defeat Edwin VanCleef.", false } },
	[411] = { { 941, "Explore Elwynn Forest", "Explore Elwynn Forest.", true } },
	[5] = { { 951, "Hidden Journey", "Not shown by the client.", false } },
}
local BY_ID = {}
for _, list in pairs(ACH) do for _, a in ipairs(list) do BY_ID[a[1]] = a end end

Constants = Constants or {}
Constants.LegacyConsts = { LEGACY_REWARD_TRACK_FACTION_ID = 2802, LEGACY_POINTS_TRAIT_CURRENCY_ID = 4225, LEGACY_DEFAULT_CATEGORY_WARRIOR = 19 }

-- As the client's: children can come before their parents.
function GetCategoryList() return { 11, 21, 411, 1, 19, 2, 41, 4, 3, 5 } end
-- Statistics (stub_character.lua) keep their own categories.
local statInfo, statNum, statAch = GetCategoryInfo, GetCategoryNumAchievements, GetAchievementInfo
function GetCategoryInfo(id)
	if not CATS[id] then return statInfo(id) end
	return CATS[id][1], CATS[id][2]
end
function GetCategoryNumAchievements(id)
	if not CATS[id] then return statNum(id) end
	return #(ACH[id] or {})
end
function GetAchievementInfo(cat, i)
	if not CATS[cat] then return statAch(cat, i) end
	local a = ACH[cat] and ACH[cat][i]
	if not a then return end
	local completed = a[4] or a[5]
	return a[1], a[2], 10, completed, 11, 6, 26, a[3], 0, 1, "", false, a[4]
end
function GetAchievementNumCriteria(id) return #(BY_ID[id][6] or {}) end
EVALUATION_TREE_FLAG_PROGRESS_BAR = 1
function GetAchievementCriteriaInfo(id, i)
	local c = BY_ID[id][6][i]
	return c[1], 0, c[2], c[4] or 0, c[5] or 0, "", c[5] and 1 or 0
end
function GetAchievementLink(id) return "[" .. BY_ID[id][2] .. "]" end
function FormatShortDate(d, m, y) return ("%d/%d/%d"):format(m, d, y) end

-- The client's search list: nothing until a search is set; with an empty one,
-- every challenge it shows; "miner" finds Deep Miner.
stub.searched = nil
function SetAchievementSearchString(s) stub.searched = s end
local function found()
	if stub.searched == nil then return {} end
	if stub.searched ~= "" then return { 921 } end
	local t = {}
	for id in pairs(BY_ID) do if id ~= 951 then t[#t + 1] = id end end
	table.sort(t)
	return t
end
function GetNumFilteredAchievements() return #found() end
function GetFilteredAchievementID(i) return found()[i] end

C_Traits = C_Traits or {}
function C_Traits.GetTraitCurrencyForAchievement(cur, id) return 1 end
function C_Traits.GetMaxAvailableTraitCurrency(cur, limit) return 65 end

Enum.ContentTrackingType = { Achievement = 2 }
Enum.ContentTrackingStopType = { Manual = 1 }
stub.tracked = {}
C_ContentTracking = {
	IsTracking = function(t, id) return stub.tracked[id] or false end,
	StartTracking = function(t, id) stub.tracked[id] = true end,
	StopTracking = function(t, id) stub.tracked[id] = nil end,
}
ChatFrameUtil = { InsertLink = function(link) if stub.chatOpen then stub.linked = link; return true end return false end }
stub.modified = {}
function IsModifiedClick(what) return stub.modified[what or "any"] or false end

-- The game's window: our doors must not open it.
LegacySystemFrame = CreateFrame("Frame", "LegacySystemFrame", UIParent)
LegacySystemFrame:Hide()
stub.bindings.TOGGLELEGACYSYSTEM = { "SHIFT-Y" }
stub.bindings.TOGGLEACHIEVEMENT = { "Y" }
function stub.bindingRun.TOGGLELEGACYSYSTEM() LegacySystemFrame:Show() end
function stub.bindingRun.TOGGLEACHIEVEMENT() LegacySystemFrame:Show() end
LegacyMicroButton = CreateFrame("Button", "LegacyMicroButton", UIParent)
LegacyMicroButton.tooltipText = "Legacy (Shift-Y)"
