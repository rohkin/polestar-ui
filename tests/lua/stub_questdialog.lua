-- The client's quest giver for the Quest dialog: the stock QuestFrame with the
-- events QuestFrame_OnLoad registers (shown on an open event, hidden on
-- QUEST_FINISHED), and the quest giver API (QuestFrame.lua, QuestInfo.lua's
-- npc branch). A scene sets stub.quest, then fires the open event.

-- The game's window: addon code must never show or hide it (docs/CLIENT.md, rule 8).
QuestFrame = QuestFrame or CreateFrame("Frame", "QuestFrame", UIParent)
QuestFrame:Hide()
for _, e in ipairs({ "QUEST_GREETING", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "QUEST_FINISHED", "QUEST_ITEM_UPDATE", "QUEST_LOG_UPDATE" }) do
	QuestFrame:RegisterEvent(e)
end
QuestFrame:SetScript("OnEvent", function(self, event)
	if event == "QUEST_FINISHED" then self:Hide()
	elseif event ~= "QUEST_ITEM_UPDATE" and event ~= "QUEST_LOG_UPDATE" then self:Show() end
end)

-- The quest the NPC offers. item = { name, icon, count, quality, usable, itemID, sellPrice }
local function item(name, icon, count, q, id, price, usable) return { name, icon, count, q, usable ~= false, id, price } end
stub.quest = {
	npc = "Marshal McBride", questID = 7, title = "Kobold Camp Cleanup",
	greeting = "Northshire stands, but only just. There is work for anyone with a strong arm.",
	active = { { "Wolves Across the Border", true, 33 } }, available = { { "Kobold Camp Cleanup", 7 } },
	objective = "Kill 10 Kobold Vermin, then return to Marshal McBride.",
	text = "Your first task is one of cleansing. A clan of kobolds has infested the woods to the north. Go there and fight the Kobold Vermin you find.",
	progress = "Have you cleared the camp? The vermin will not leave on their own.",
	reward = "Well done. Take one of these for your trouble.",
	required = { item("Kobold Ear", 133854, 4, 1, 50001) }, have = { [50001] = 3 }, money = 0,
	choices = { item("Militia Dagger", 135641, 1, 2, 2224, 120), item("Militia Buckler", 134955, 1, 2, 2219, 95), item("Kobold Ear Charm", 133437, 1, 3, 2225, 340) },
	rewards = { item("Linen Bandage", 133685, 5, 1, 1251, 10) },
	xp = 450, rewardMoney = 1250, spells = {}, completable = true, pvp = false, auto = false,
}
local q = stub.quest
stub.questCalls = {}
local function call(name, ...) stub.questCalls[#stub.questCalls + 1] = { name, ... } end

local unitName = UnitName
-- The NPC's name, unless another stub (stub_gossip.lua) already gives one.
function UnitName(unit, ...)
	if (unit == "npc" or unit == "questnpc") and unitName(unit, ...) == nil then return stub.quest.npc end
	return unitName(unit, ...)
end
-- The NPC's portrait (SetPortraitTexture) when there is one; its 3D portrait
-- (GetQuestPortraitGiver/TurnIn: display ID, text, name, mount, scene; 0 is none).
UnitExists = UnitExists or function(unit) return UnitName(unit) ~= nil end
SetPortraitTexture = SetPortraitTexture or function(tex) tex:SetTexture(132355) end
function GetQuestPortraitGiver() local p = stub.quest.giver or {}; return p[1] or 0, p[2], p[3], p[4] or 0, p[5] end
function GetQuestPortraitTurnIn() local p = stub.quest.turnIn or {}; return p[1] or 0, p[2], p[3] end
-- The offer's extras: a spell objective (spellID, name, icon), a suggested group, the giver's signature.
function GetCriteriaSpell() local s = stub.quest.criteriaSpell; if s then return s[1], s[2], s[3], false end end
function GetSuggestedGroupSize() return stub.quest.group or 0 end
-- Where the offer came from, and the tracker's pop-ups the client keeps.
function QuestIsFromAreaTrigger() return stub.quest.areaTrigger or false end
function QuestIsFromAdventureMap() return false end
stub.popUps = {}
function AddAutoQuestPopUp(id, kind) stub.popUps[id] = kind; return true end
function RemoveAutoQuestPopUp(id) stub.popUps[id] = nil end
-- No friendship NPC unless stub_gossip.lua gives one.
C_GossipInfo = C_GossipInfo or {}
C_GossipInfo.GetFriendshipReputation = C_GossipInfo.GetFriendshipReputation or function() return { friendshipFactionID = 0 } end
-- The client's text write-in: true while the gradient still runs.
stub.Methods.SetAlphaGradient = stub.Methods.SetAlphaGradient or function(self, start) self.gradient = start; return start < #tostring(self.text or "") end
function GetQuestID() return stub.quest.questID end
function GetTitleText() return stub.quest.title end
function GetGreetingText() return stub.quest.greeting end
function GetQuestText() return stub.quest.text end
function GetObjectiveText() return stub.quest.objective end
function GetProgressText() return stub.quest.progress end
function GetRewardText() return stub.quest.reward end
function GetNumActiveQuests() return #stub.quest.active end
function GetActiveTitle(i) return stub.quest.active[i][1], stub.quest.active[i][2] end
function GetActiveQuestID(i) return stub.quest.active[i][3] end
function IsActiveQuestTrivial() return false end
function GetNumAvailableQuests() return #stub.quest.available end
function GetAvailableTitle(i) return stub.quest.available[i][1] end
function GetAvailableQuestInfo(i) return false, 0, false, false, stub.quest.available[i][2], false, false, nil end
function SelectActiveQuest(i) call("SelectActiveQuest", i) end
function SelectAvailableQuest(i) call("SelectAvailableQuest", i) end
QuestUtil = QuestUtil or {}
QuestUtil.GetQuestIconActiveForQuestID = QuestUtil.GetQuestIconActiveForQuestID or function(_, done) return done and "Interface/GossipFrame/ActiveQuestIcon" or "Interface/GossipFrame/IncompleteQuestIcon", false end
QuestUtil.GetQuestIconOfferForQuestID = QuestUtil.GetQuestIconOfferForQuestID or function() return "Interface/GossipFrame/AvailableQuestIcon", false end

-- The quest giver's answers: each recorded; the server's reply is the scene's to fire.
function AcceptQuest() call("AcceptQuest") end
function AcknowledgeAutoAcceptQuest() call("AcknowledgeAutoAcceptQuest") end
function DeclineQuest() call("DeclineQuest") end
function CompleteQuest() call("CompleteQuest") end
function GetQuestReward(i) call("GetQuestReward", i) end
function QuestChooseRewardError() call("QuestChooseRewardError") end
-- Ending the dialog: the game answers with QUEST_FINISHED.
function CloseQuest()
	call("CloseQuest")
	stub.fire("QUEST_FINISHED")
end
function QuestFlagsPVP() return stub.quest.pvp end
function QuestGetAutoAccept() return stub.quest.auto end
function IsQuestCompletable() return stub.quest.completable end

-- Progress: required items, money, currencies.
C_QuestOffer = { GetHideRequiredItems = function() return false end, GetQuestRequiredCurrencyInfo = function() end,
	GetQuestRewardCurrencyInfo = function() end }
function GetNumQuestItems() return #stub.quest.required end
function IsQuestItemHidden() return 0 end
function GetNumQuestCurrencies() return 0 end
function GetQuestMoneyToGet() return stub.quest.money end
GetMoney = GetMoney or function() return 1234567 end
C_Item = C_Item or {}
function C_Item.GetItemCount(id) return stub.quest.have[id] or 0 end

-- Rewards.
local lists = { required = "required", choice = "choices", reward = "rewards" }
local function get(kind, i) return stub.quest[lists[kind]][i] end
function GetQuestItemInfo(kind, i) local it = get(kind, i); if it then return it[1], it[2], it[3], it[4], it[5], it[6] end end
function GetQuestItemLink(kind, i) local it = get(kind, i); return it and ("|cff1eff00|Hitem:%d|h[%s]|h|r"):format(it[6], it[1]) end
function GetQuestItemInfoLootType() return 0 end
function GetNumQuestChoices() return #stub.quest.choices end
function GetNumQuestRewards() return #stub.quest.rewards end
function GetRewardMoney() return stub.quest.rewardMoney end
function GetRewardXP() return stub.quest.xp end
function GetRewardHonor() return 0 end
function GetRewardTitle() return nil end
function GetRewardSkillPoints() return nil end
C_QuestLog = C_QuestLog or {}
function C_QuestLog.ShouldShowQuestRewards() return true end
C_QuestInfoSystem = {
	GetQuestRewardCurrencies = function() return {} end,
	GetQuestRewardSpells = function() return stub.quest.spells end,
	GetQuestRewardSpellInfo = function(_, spellID) return { name = "Healing Touch", texture = 136041, isSpellLearned = true, type = 0, spellID = spellID } end,
}
Enum.QuestCompleteSpellType = { LegacyBehavior = 0, Follower = 1, Tradeskill = 2, Ability = 3, Aura = 4, Spell = 5, Unlock = 6, Companion = 7, QuestlineUnlock = 8, QuestlineReward = 9, QuestlineUnlockPart = 10, PossibleReward = 11 }
Enum.SpellBookSpellBank = Enum.SpellBookSpellBank or { Player = 0 }
C_SpellBook = C_SpellBook or {}
C_SpellBook.IsSpellInSpellBook = C_SpellBook.IsSpellInSpellBook or function() return false end
-- Sell prices by item ID (C_Item.GetItemInfo's 11th value), as Polestar's ranking reads them.
local prices = {}
for _, k in ipairs({ "choices", "rewards", "required" }) do for _, it in ipairs(q[k]) do prices[it[6]] = it[7] end end
function C_Item.GetItemInfo(link)
	local id = tonumber(tostring(link):match("item:(%d+)") or link)
	if prices[id] then return nil, link, nil, nil, nil, nil, nil, nil, nil, nil, prices[id] end
end
function UnitXPMax() return 1280 end
GameRulesUtil = GameRulesUtil or { CanShowExperienceBar = function() return true end }
function GetMoneyString(m) return ("%ds %dc"):format(math.floor(m / 100), m % 100) end
REWARD_CHOOSE = "Choose your reward:"
REWARD_CHOICES, REWARD_ITEMS, REWARD_ITEMS_ONLY, REWARD_SPELL = "You will be able to choose one of these rewards:", "You will also receive:", "You will receive:", "You will learn:"
CONFIRM_COMPLETE_EXPENSIVE_QUEST = "Completing this quest requires the following amount of gold. Are you sure you want to complete this quest?"
CONFIRM_ACCEPT_PVP_QUEST = "Accepting this quest will flag you for PvP for as long as you are on it. Are you sure?"

-- The game's tooltips for a quest giver's items.
function GameTooltip.SetQuestItem(self, kind, i) self.lines = { "quest " .. kind .. " " .. i } end
function GameTooltip_ShowCompareItem() end
IsModifiedClick = IsModifiedClick or function() return IsShiftKeyDown() end
function HandleModifiedItemClick(link) call("HandleModifiedItemClick", link) return true end

-- Polestar's reward marks (QoL/Rewards.lua; the preview loads no QoL): its
-- ranking as a stand-in answering stub.verdicts, put in at login after
-- stub_ui installs Polestar's Engine (whose QUEST_DETAIL automation asks it).
-- verdicts = { list = { {index, value, upgrade, delta} }, complete, priced, rank }
stub.rewardMarks = true
stub.verdicts = {
	list = { { index = 1, value = 120, upgrade = true, delta = 6 }, { index = 2, value = 95, upgrade = true, delta = 2 }, { index = 3, value = 340, upgrade = false } },
	complete = true, priced = true, rank = { 1, 2, 3 },
}
local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function()
	Polestar.Engine.WantsQuest = function() return false end
	Polestar.Engine.AcceptRefusal = function() end
	Polestar.QoL = {
		On = function(k) return k == "rewardHighlight" and stub.rewardMarks end,
		Rewards = {
			ReadChoices = function(fromLog)
				assert(fromLog == false, "the quest giver's choices are read with fromLog false")
				return stub.verdicts.list, stub.verdicts.complete, stub.verdicts.priced
			end,
			Rank = function() return stub.verdicts.rank, "upgrade" end,
		},
	}
end)
