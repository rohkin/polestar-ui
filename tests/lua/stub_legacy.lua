-- The client calls the Legacy System reads; the values are the preview's
-- sample: legacy level 3 of 6, partway to 4; level 5 has two rewards.

local REWARDS = {
	[1] = { { name = "Heirloom Satchel", description = "A bag that grows with you.", icon = 1 } },
	[2] = { { name = "Swift Legacy Charger", description = "A mount for every character.", icon = 1 } },
	[3] = { { name = "Title: the Enduring", description = "Shown after your name.", icon = 1 } },
	[4] = { { name = "Legacy Tabard", description = "Worn proudly.", icon = 1 } },
	[5] = { { name = "Experience bonus", description = "Earn 10% more experience.", icon = 1 }, { name = "Bank tab", description = "", icon = 1 } },
	[6] = { { name = "Crown of Ages", description = "The last reward of the track.", icon = 1 } },
}

C_MajorFactions = C_MajorFactions or {}
function C_MajorFactions.GetCurrentRenownLevel(id) return 3 end
function C_MajorFactions.HasMaximumRenown(id) return false end
function C_MajorFactions.GetMajorFactionData(id)
	return { factionID = id, name = "Legacy", renownLevel = 3, maxLevel = 6, renownReputationEarned = 450, renownLevelThreshold = 1000, isUnlocked = true }
end
function C_MajorFactions.GetRenownLevels(id)
	local t = {}
	for i = 1, 7 do t[i] = { factionID = id, level = i, locked = i > 3, isMilestone = false, isCapstone = i == 6 } end
	return t
end
-- Level 7 has no reward: it is left off the track.
function C_MajorFactions.GetRenownRewardsForLevel(id, level) return REWARDS[level] or {} end

RenownRewardUtil = { GetRenownRewardInfo = function(r) return r.icon, r.name, r.description end }

-- The game's window: our doors must not open it.
LegacySystemFrame = CreateFrame("Frame", "LegacySystemFrame", UIParent)
LegacySystemFrame:Hide()
stub.bindings.TOGGLELEGACYSYSTEM = { "SHIFT-Y" }
function stub.bindingRun.TOGGLELEGACYSYSTEM() LegacySystemFrame:Show() end
LegacyMicroButton = CreateFrame("Button", "LegacyMicroButton", UIParent)
LegacyMicroButton.tooltipText = "Legacy (Shift-Y)"
