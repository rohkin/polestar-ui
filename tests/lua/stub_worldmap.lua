-- The client's map reads and the game's map canvas; the values are the
-- preview's sample: Azeroth > Eastern Kingdoms > Elwynn Forest, the player in
-- Elwynn. The canvas (PolestarUIMapCanvasTemplate, from XML the stub does not
-- read) records its map and providers and draws a flat well for the art.

local MAPS = {
	[947] = { mapID = 947, name = "Azeroth", mapType = 1, parentMapID = 0 },
	[13] = { mapID = 13, name = "Eastern Kingdoms", mapType = 2, parentMapID = 947 },
	[12] = { mapID = 12, name = "Kalimdor", mapType = 2, parentMapID = 947 },
	[37] = { mapID = 37, name = "Elwynn Forest", mapType = 3, parentMapID = 13 },
	[52] = { mapID = 52, name = "Westfall", mapType = 3, parentMapID = 13 },
	[47] = { mapID = 47, name = "Duskwood", mapType = 3, parentMapID = 13 },
	[1429] = { mapID = 1429, name = "Fargodeep Mine", mapType = 4, parentMapID = 37 },
}
C_Map = C_Map or {}
function C_Map.GetMapInfo(id) return MAPS[id] end
function C_Map.GetMapChildrenInfo(id)
	local t = {}
	for _, m in pairs(MAPS) do if m.parentMapID == id then t[#t + 1] = m end end
	return t
end
MapUtil = { GetDisplayableMapForPlayer = function() return 37 end }
function GetZoneText() return "Elwynn Forest" end
C_QuestLog = C_QuestLog or {}
function C_QuestLog.GetMaxNumQuests() return 25 end

QuestDataProviderMixin = {}
AreaLabelDataProviderMixin = { SetOffsetY = function(self, y) self.offsetY = y end }

local Canvas = {}
function Canvas:SetShouldZoomInOnClick() end
function Canvas:SetShouldPanOnClick() end
function Canvas:SetShouldNavigateOnClick(on) self.navigateOnClick = on end
function Canvas:SetShouldZoomInstantly() end
function Canvas:GetPinFrameLevelsManager() return { AddFrameLevel = function(_, name) self.levels[#self.levels + 1] = name end } end
function Canvas:AddDataProvider(p) self.providers[#self.providers + 1] = p end
function Canvas:SetMapID(id) if id ~= self.mapID then self.mapID = id; self:OnMapChanged() end end
function Canvas:GetMapID() return self.mapID end
function Canvas:OnMapChanged() end
function Canvas:ResetZoom() self.zoomedOut = true end
-- The map art's one zoom step, as Forever's art gives it.
function Canvas:OnFrameSizeChanged() self.ScrollContainer:CreateZoomLevels() end
local function oneStep(self) self.zoomLevels = { { scale = 0.8, layerIndex = 1 } } end

local createFrame = CreateFrame
function CreateFrame(kind, name, parent, template, ...)
	local f = createFrame(kind, name, parent, template, ...)
	if template == "PolestarUIMapCanvasTemplate" then
		for k, v in pairs(Canvas) do f[k] = v end
		f.providers, f.levels, f.events = {}, {}, {}
		f:SetFrameStrata("MEDIUM") -- as the template sets it
		f:Hide()
		f.ScrollContainer = createFrame("ScrollFrame", nil, f)
		f.ScrollContainer:SetAllPoints(f)
		f.ScrollContainer.CreateZoomLevels = oneStep
		local art = f.ScrollContainer:CreateTexture(nil, "BACKGROUND")
		art:SetAllPoints(f.ScrollContainer)
		art:SetColorTexture(0.18, 0.22, 0.2, 1)
	end
	return f
end

-- The game's own map: our doors must not open it.
WorldMapFrame = createFrame("Frame", "WorldMapFrame", UIParent)
WorldMapFrame:Hide()
stub.bindings.TOGGLEWORLDMAP = { "M" }
function stub.bindingRun.TOGGLEWORLDMAP() WorldMapFrame:Show() end

-- The quest log: two headers, Elwynn Forest's three quests (one done, one
-- tracked) and Westfall's one, folded. Folding sends no event (rule 6).
function Canvas:TriggerEvent(event, ...) self.events[#self.events + 1] = { event, ... } end
local LOG = {
	{ title = "Elwynn Forest", isHeader = true, isCollapsed = false },
	{ title = "A Threat Within", questID = 783, level = 1 },
	{ title = "Kobold Camp Cleanup", questID = 7, level = 2, goals = { { "Kobold Vermin slain: 4/10", false }, { "Kobold camp found", true } },
		summary = "Kill 10 Kobold Vermin, then return to Marshal McBride.",
		text = "Your first task is one of cleansing. A clan of kobolds has infested the woods to the north. Go there and fight the Kobold Vermin you find.",
		money = 1250, xp = 450, pushable = true,
		rewards = { { "Militia Buckler", 134955, 1, 2, true, 101 } },
		choices = { { "Militia Dagger", 135641, 1, 1, true, 102 }, { "Kobold Ear Charm", 133345, 2, 3, false, 103 } },
		spells = { 8921 } },
	{ title = "Wolves Across the Border", questID = 33, level = 3, done = true },
	{ title = "Westfall", isHeader = true, isCollapsed = true },
	{ title = "The Defias Brotherhood", questID = 65, level = 14 },
	{ title = "Hidden", questID = 99, level = 1, isHidden = true },
}
for i, q in ipairs(LOG) do q.questLogIndex = i end
stub.watched = { [7] = true }
function C_QuestLog.GetNumQuestLogEntries()
	local n = 0
	for _, q in ipairs(LOG) do if not q.isHeader then n = n + 1 end end
	return #LOG, n
end
function C_QuestLog.GetInfo(i)
	local q = LOG[i]
	if not q then return nil end
	local t = {}
	for k, v in pairs(q) do t[k] = v end
	return t
end
function C_QuestLog.GetMaxNumQuestsCanAccept() return 25 end
function C_QuestLog.IsComplete(id) for _, q in ipairs(LOG) do if q.questID == id then return q.done or false end end return false end
function C_QuestLog.IsQuestDisabledForSession() return false end
function ExpandQuestHeader(i) LOG[i].isCollapsed = false end
function CollapseQuestHeader(i) LOG[i].isCollapsed = true end
function GetNumQuestLeaderBoards(i) return #(LOG[i].goals or {}) end
function GetQuestLogLeaderBoard(n, i) local g = LOG[i].goals[n]; return g[1], "monster", g[2] end
function QuestUtils_IsQuestWatched(id) return stub.watched[id] or false end
function QuestMapQuestOptions_TrackQuest(id) stub.watched[id] = not stub.watched[id] or nil end
function GetQuestUiMapID(id) return id == 65 and 52 or 37 end
C_PlayerInfo = C_PlayerInfo or {}
function C_PlayerInfo.GetContentDifficultyQuestForPlayer(id) return id == 65 and 4 or 1 end
local DIFF = { [1] = { r = 0.25, g = 0.75, b = 0.25 }, [4] = { r = 1, g = 0.1, b = 0.1 } }
function GetDifficultyColor(d) return DIFF[d] end
ChatFrameUtil = { TryInsertQuestLinkForQuestID = function(id) if stub.chatOpen then stub.linked = id; return true end return false end }

-- The details read the selected quest, as the client's quest log functions do.
local selected, abandoning = 0, nil
local function sel() for _, q in ipairs(LOG) do if q.questID == selected then return q end end return {} end
function C_QuestLog.SetSelectedQuest(id) selected = id end
function C_QuestLog.GetSelectedQuest() return selected end
function C_QuestLog.GetLogIndexForQuestID(id) for i, q in ipairs(LOG) do if q.questID == id then return i end end end
function GetQuestLogQuestText() return sel().text or "", sel().summary or "" end
function C_QuestLog.GetNextWaypointText() return nil end
function C_QuestLog.GetRequiredMoney() return 0 end
function C_QuestLog.GetSuggestedGroupSize() return 0 end
function C_QuestLog.ShouldShowQuestRewards() return true end
function GetNumQuestLogRewards() return #(sel().rewards or {}) end
function GetNumQuestLogChoices() return #(sel().choices or {}) end
function GetQuestLogRewardMoney() return sel().money or 0 end
function GetQuestLogRewardXP() return sel().xp or 0 end
function GetQuestLogRewardHonor() return 0 end
function GetQuestLogRewardTitle() return nil end
function GetQuestLogRewardSkillPoints() return nil end
function GetQuestLogRewardInfo(i) return unpack(sel().rewards[i]) end
function GetQuestLogChoiceInfo(i) return unpack(sel().choices[i]) end
function GetQuestLogChoiceInfoLootType() return 0 end
function GetMoneyString(m) return ("%ds %dc"):format(math.floor(m / 100), m % 100) end
C_QuestInfoSystem = {
	GetQuestRewardCurrencies = function() return {} end,
	GetQuestRewardSpells = function(id) return id == selected and sel().spells or {} end,
	GetQuestRewardSpellInfo = function(_, spellID) return { name = "Healing Touch", texture = 136041, isSpellLearned = true, type = 0, spellID = spellID } end,
}
Enum.QuestCompleteSpellType = { LegacyBehavior = 0, Follower = 1, Tradeskill = 2, Ability = 3, Aura = 4, Spell = 5, Unlock = 6, Companion = 7, QuestlineUnlock = 8, QuestlineReward = 9, QuestlineUnlockPart = 10, PossibleReward = 11 }
C_SpellBook = C_SpellBook or {}
C_SpellBook.IsSpellInSpellBook = C_SpellBook.IsSpellInSpellBook or function() return false end
REWARD_CHOICES, REWARD_ITEMS, REWARD_ITEMS_ONLY, REWARD_SPELL = "You will be able to choose one of these rewards:", "You will also receive:", "You will receive:", "You will learn:"
function GameTooltip.SetQuestLogItem(self, kind, i) self.lines = { "quest log " .. kind .. " " .. i } end
function GameTooltip_ShowCompareItem() end
QuestUtil = { CanRemoveQuestWatch = function() return true end }
function C_QuestLog.IsPushableQuest(id) return sel().questID == id and sel().pushable or false end
function C_QuestLog.CanAbandonQuest() return true end
function IsInGroup() return stub.inGroup or false end
function QuestMapQuestOptions_ShareQuest(id) stub.shared = id end
-- Abandoning: the quest set aside, then dropped from the log on AbandonQuest.
function C_QuestLog.SetAbandonQuest() abandoning = selected end
function C_QuestLog.GetAbandonQuest() return abandoning end
function C_QuestLog.GetAbandonQuestItems() return {} end
function QuestUtils_GetQuestName(id) for _, q in ipairs(LOG) do if q.questID == id then return q.title end end return "" end
function C_QuestLog.AbandonQuest()
	for i, q in ipairs(LOG) do if q.questID == abandoning then table.remove(LOG, i); stub.abandoned = abandoning break end end
	for i, q in ipairs(LOG) do q.questLogIndex = i end
end

stub.bindings.TOGGLEQUESTLOG = { "L" }
function stub.bindingRun.TOGGLEQUESTLOG() WorldMapFrame:Show() end
QuestLogMicroButton = createFrame("Button", "QuestLogMicroButton", UIParent)
QuestLogMicroButton.tooltipText = "Quest Log (L)"
