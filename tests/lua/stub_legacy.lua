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

-- The legacy trees, laid out as the game's Professions and Adventure trees:
-- { node, column, row, max ranks, name, edge to } on a grid in the client's
-- units, a few off it as the client's are. Adventure has 3 of 5 in its first
-- talent; 2 legacy points are left to spend (one currency for all trees).
local TREE_NODES = {
	[1187] = {
		{ 1, 1, 0, 5, "Deft Hands" }, { 2, 0, 1, 5, "Gatherer's Eye" }, { 3, 1, 1, 2, "Spare Parts", 4 }, { 4, 2, 1, 1, "Master's Cache" },
		{ 5, 0, 2, 5, "Quick Study", 6 }, { 6, 1, 2, 3, "Steady Work" }, { 7, 2, 2, 1, "Hidden One", 8 }, { 8, 3, 2, 1, "Hidden Two" }, { 9, 1, 3, 2, "Packhorse" },
	},
	[1188] = {
		{ 21, 1, 0, 2, "Trailblazer" }, { 22, 0, 1, 5, "Hardy", 23 }, { 23, 1, 1, 5, "Seasoned" }, { 24, 2, 1, 1, "Hidden Path", 25 }, { 25, 3, 1, 1, "Hidden Road" },
		{ 26, 0, 2, 5, "Swift Traveller" }, { 27, 1, 2, 3, "Keen Senses", 28 }, { 28, 2, 2, 1, "Last Stand" }, { 29, 1, 3, 2, "Second Wind" },
	},
	[1189] = {},
}
-- stub.treePoints: the legacy points earned for the trees (5).
local function TREE_POINTS() return stub.treePoints or 5 end
local nodeTree, nodeDef = {}, {}
for tree, list in pairs(TREE_NODES) do for _, n in ipairs(list) do nodeTree[n[1]], nodeDef[n[1]] = tree, n end end
stub.legacyRanks = { [26] = 3 }
stub.legacyStaged = { [26] = 3 }
local function staged(id) return stub.legacyStaged[id] or 0 end
local function spentIn(tree)
	local s = 0
	for id, r in pairs(stub.legacyStaged) do if not tree or nodeTree[id] == tree then s = s + r end end
	return s
end

function C_Traits.GetConfigIDByTreeID(tree) return 7 end
function C_Traits.GetTreeCurrencyInfo(config, tree)
	return { { traitCurrencyID = 4225, quantity = TREE_POINTS() - spentIn(), spent = spentIn(tree), maxQuantity = 65 } }
end
function C_Traits.GetTreeNodes(tree)
	local ids = {}
	for _, n in ipairs(TREE_NODES[tree] or {}) do ids[#ids + 1] = n[1] end
	return ids
end
local function meets(id)
	for src, n in pairs(nodeDef) do if n[6] == id and staged(src) == 0 then return false end end
	return true
end
function C_Traits.GetNodeInfo(config, id)
	local n = nodeDef[id]
	local cur, learnt = staged(id), stub.legacyRanks[id] or 0
	local edges = n[6] and { { targetNode = n[6], isActive = cur > 0 } } or {}
	return { ID = id, posX = n[2] * 1800 + id % 3 * 7, posY = n[3] * 1500 - id % 4 * 9, isVisible = true, entryIDs = { 100 + id },
		currentRank = cur, ranksPurchased = cur, maxRanks = n[4], meetsEdgeRequirements = meets(id), visibleEdges = edges,
		-- As the client's: whether a rank can go in, its cost aside (GetNodeCost).
		canPurchaseRank = cur < n[4], canRefundRank = cur > learnt,
		activeEntry = cur > 0 and { entryID = 100 + id, rank = cur } or nil, nextEntry = cur < n[4] and { entryID = 100 + id, rank = cur + 1 } or nil }
end
function C_Traits.GetEntryInfo(config, entry) return { definitionID = entry } end
function C_Traits.GetDefinitionInfo(def) return { overrideName = nodeDef[def - 100][5], overrideIcon = 1 } end
function C_Traits.GetNodeCost(config, id) return { { ID = 4225, amount = 1 } } end
function C_Traits.PurchaseRank(config, id)
	local n = C_Traits.GetNodeInfo(config, id)
	if not (n.canPurchaseRank and n.meetsEdgeRequirements and TREE_POINTS() - spentIn() > 0) then return false end
	stub.legacyStaged[id] = staged(id) + 1
	return true
end
function C_Traits.RefundRank(config, id)
	if not C_Traits.GetNodeInfo(config, id).canRefundRank then return false end
	stub.legacyStaged[id] = staged(id) - 1
	return true
end
function C_Traits.ConfigHasStagedChanges(config)
	for id in pairs(nodeDef) do if staged(id) ~= (stub.legacyRanks[id] or 0) then return true end end
	return false
end
function C_Traits.RollbackConfig(config)
	stub.legacyStaged = {}
	for k, v in pairs(stub.legacyRanks) do stub.legacyStaged[k] = v end
	return true
end
function C_Traits.ResetTree(config, tree)
	for id in pairs(stub.legacyStaged) do if nodeTree[id] == tree then stub.legacyStaged[id] = 0 end end
end
-- The commit: applied when the client says so (TRAIT_CONFIG_UPDATED).
function C_Traits.CommitConfig(config)
	stub.legacyCommitting = true
	return true
end
function stub.finishLegacyCommit()
	stub.legacyRanks = {}
	for k, v in pairs(stub.legacyStaged) do stub.legacyRanks[k] = v end
	stub.legacyCommitting = nil
	stub.fire("TRAIT_CONFIG_UPDATED", 7)
end

C_Spell = C_Spell or {}
C_Spell.GetSpellTexture = C_Spell.GetSpellTexture or function() return 134400 end
C_Spell.GetSpellName = C_Spell.GetSpellName or function() return nil end
C_Spell.GetSpellDescription = C_Spell.GetSpellDescription or function() return "" end
function GameTooltip:AppendInfo(kind, entry, rank) self:AddLine(("[%s %d rank %d]"):format(kind, entry, rank)) end
GameTooltip_SetTitle = GameTooltip_SetTitle or function(tip, text) tip:SetText(text) end
GameTooltip_AddBlankLineToTooltip = GameTooltip_AddBlankLineToTooltip or function(tip) tip:AddLine(" ") end
GameTooltip_AddHighlightLine = GameTooltip_AddHighlightLine or function(tip, text) tip:AddLine(text) end
GameTooltip_AddErrorLine = GameTooltip_AddErrorLine or function(tip, text) tip:AddLine(text) end
TALENT_BUTTON_TOOLTIP_RANK_FORMAT, TALENT_BUTTON_TOOLTIP_NEXT_RANK = "Rank %s/%s", "Next Rank:"
GENERIC_TRAIT_FRAME_EDGE_REQUIREMENTS_BUTTON_TOOLTIP = "Requires the talents before it."
function UIErrorsFrame:AddExternalErrorMessage(msg) stub.uiError = msg end
