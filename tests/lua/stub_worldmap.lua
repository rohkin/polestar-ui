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
	[1430] = { mapID = 1430, name = "Fargodeep Mine, Lower", mapType = 4, parentMapID = 37 },
	[291] = { mapID = 291, name = "The Deadmines", mapType = 4, parentMapID = 52 },
}
-- Fargodeep Mine is a map group of two floors, as the client gives them.
local GROUP = { { mapID = 1429, relativeHeightIndex = 0, name = "Upper Level" }, { mapID = 1430, relativeHeightIndex = 1, name = "Lower Level" } }
C_Map = C_Map or {}
function C_Map.GetMapInfo(id) return MAPS[id] end
function C_Map.GetMapGroupID(id) return (id == 1429 or id == 1430) and 7 or nil end
function C_Map.GetMapGroupMembersInfo(g) return g == 7 and GROUP or nil end
function C_Map.GetMapChildrenInfo(id)
	local t = {}
	for _, m in pairs(MAPS) do if m.parentMapID == id then t[#t + 1] = m end end
	return t
end
-- The stock nav bar's dropdown lists the cave's floors (once a scene sets
-- stub.caveListed, so the other scenes draw as before), never the Deadmines
-- (which the nav bar leaves out).
function C_Map.IsMapValidForNavBarDropdown(id) return stub.caveListed and (id == 1429 or id == 1430) or false end
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
function Canvas:RefreshAllDataProviders() self.refreshed = (self.refreshed or 0) + 1 end
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
	{ title = "Wolves Across the Border", questID = 33, level = 3, done = true, elite = true },
	{ title = "Westfall", isHeader = true, isCollapsed = true },
	{ title = "The Defias Brotherhood", questID = 65, level = 14 },
	{ title = "Hidden", questID = 99, level = 1, isHidden = true },
}
for i, q in ipairs(LOG) do q.questLogIndex = i end
stub.watched = { [7] = true, [33] = true }
function C_QuestLog.IsEliteQuest(id) for _, q in ipairs(LOG) do if q.questID == id then return q.elite or false end end return false end
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
-- The player's level takes 1,280 XP (450 is 35% of it); at the level cap the game shows no XP bar.
function UnitXP() return 300 end
function UnitXPMax() return stub.xpMax or 1280 end
GameRulesUtil = { CanShowExperienceBar = function() return not stub.maxLevel end }
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
QuestUtil = { CanRemoveQuestWatch = function() return not stub.cannotUntrack end, IsQuestTagIconHidden = function() return false end }
-- The Defias Brotherhood is a group quest (its stock tag); none has failed.
function C_QuestLog.IsFailed() return false end
function C_QuestLog.IsAccountQuest() return false end
function C_QuestLog.GetQuestTagInfo(id) return id == 65 and { tagID = 1 } or nil end
function QuestUtils_GetQuestTagAtlas(tag) return tag == 1 and "questlog-questtypeicon-group" or nil end
function C_QuestLog.IsPushableQuest(id) return sel().questID == id and sel().pushable or false end
function C_QuestLog.CanAbandonQuest(id) return id ~= stub.noAbandon end
function C_QuestLog.GetNumQuestWatches() local n = 0 for _ in pairs(stub.watched) do n = n + 1 end return n end
Constants = Constants or {}
Constants.QuestWatchConsts = { MAX_QUEST_WATCHES = 3 }
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

-- The map's filters (the stock tracking menu's): its CVars, on as the
-- preview draws, and the low-level quests' tracking filter.
for _, k in ipairs({ "questPOI", "showQuestLevel", "showQuestDifficultyColor", "contentTrackingFilter", "showQuestObjectivesInLog" }) do stub.cvars[k] = "1" end
Enum.MinimapTrackingFilter.TrivialQuests = 1024
stub.trivialOut = true
C_Minimap = { IsFilteredOut = function(id) return id == 1024 and stub.trivialOut end, SetTracking = function(i, on) if i == 9 then stub.trivialOut = not on end end }
MinimapUtil = { GetFilterIndexForFilterID = function(id) return id == 1024 and 9 or nil end }
SHOW_QUEST_OBJECTIVES_ON_MAP_TEXT, SHOW_QUEST_LEVELS, MAP_QUEST_DIFFICULTY_TEXT = "Quest Objectives", "Show Quest Levels", "Quest Difficulty Color"
MINIMAP_TRACKING_TRIVIAL_QUESTS, CONTENT_TRACKING_MAP_TOGGLE = "Low-Level Quests", "Tracked Items"
WORLD_MAP_FILTER_TITLE_SHOW_MAP, WORLD_MAP_FILTER_TITLE_SHOW_QUEST_LOG, QUEST_LOG_SHOW_OBJECTIVES = "Show on Map:", "Show in Quest Log:", "Quest Objectives"
-- A context menu: its tag and entries, as the generator describes them; a
-- checkbox keeps its tooltip (SetOnEnter), a button its click and state.
local function describe(m, list)
	local function item(t)
		t.SetOnEnter = function(self, fn) self.onEnter = fn end
		t.SetOnLeave = function() end
		t.SetEnabled = function(self, on) self.disabled = not on end
		t.items = {}
		t.CreateTitle = function(self, text) self.items[#self.items + 1] = { title = text } end
		t.CreateCheckbox = function(self, text, get, set) return self:add({ text = text, get = get, set = set }) end
		t.CreateButton = function(self, text, fn) return self:add({ text = text, click = fn, button = true }) end
		t.CreateDivider = function(self) self.items[#self.items + 1] = { divider = true } end
		t.add = function(self, x) self.items[#self.items + 1] = item(x); return self.items[#self.items] end
		return t
	end
	return item(m)
end
MenuUtil = { CreateContextMenu = function(owner, gen)
	local m = describe({ owner = owner })
	m.SetTag = function(_, tag) m.tag = tag end
	m.QueueSpacer, m.QueueDivider = function() end, function() end
	gen(owner, m)
	stub.menu = m
end }
-- The CVars' and tracking filter's defaults: as the preview draws.
function GetCVarDefault(k) return ({ questPOI = "1", showQuestLevel = "1", showQuestDifficultyColor = "1", contentTrackingFilter = "1", showQuestObjectivesInLog = "1", questPOIWQ = "1", primaryProfessionsFilter = "1", secondaryProfessionsFilter = "1" })[k] or "0" end
for _, k in ipairs({ "questPOIWQ", "primaryProfessionsFilter", "secondaryProfessionsFilter" }) do stub.cvars[k] = "1" end
function C_Minimap.GetDefaultTrackingValue() return false end
GameTooltip_SetTitle = GameTooltip_SetTitle or function(tip, text) tip:SetText(text) end
GameTooltip_AddNormalLine = GameTooltip_AddNormalLine or function(tip, text) tip:AddLine(text) end
GameTooltip_Hide = GameTooltip_Hide or function() GameTooltip:Hide() end
QUEST_OBJECTIVES_FILTER_DESCRIPTION, QUEST_LEVEL_FILTER_DESCRIPTION = "Show quest objectives on the map.", "Show the level of each quest."
QUEST_DIFFICULTY_FILTER_DESCRIPTION, TRIVIAL_QUESTS_FILTER_DESCRIPTION = "Colour quests by difficulty.", "Show quests far below your level."
TRACKED_ITEMS_FILTER_DESCRIPTION = "Show tracked items on the map."
