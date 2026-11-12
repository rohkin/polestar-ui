--@ title: Gossip: quests
--@ roots: PolestarUIGossip
--@ stubs: stub_npc.lua, stub_gossip.lua, stub_questdialog.lua
-- Quests to hand in first (complete and not yet), then quests to take (a repeatable one, a trivial one in textMuted with its icon greyed), then the options. A long option wraps to a second line and its row grows. Picking a quest hands on to the quest dialog (the game's, until ours is built): ours closes without ending the gossip. QUEST_LOG_UPDATE redraws the list.
-- Polestar's quest automation reads the guide engine, not loaded here: off, as a player may have it.
Polestar.Set("behavior.autoAccept", false)
Polestar.Set("behavior.autoTurnin", false)
local function talk()
	stub.talk({
		name = "Marshal Dughan",
		text = "Ach, it's hard enough keeping order around here without all these new troubles popping up! I hope you have good news, $n...",
		active = {
			{ title = "Wolves Across the Border", questID = 33, isComplete = true },
			{ title = "The Fargodeep Mine", questID = 62, isComplete = false },
		},
		available = {
			{ title = "A Threat Within", questID = 783, repeatable = true },
			{ title = "Kobold Camp Cleanup", questID = 7, isTrivial = true },
		},
		options = {
			{ name = "I would like to hear the full tale of the Defias Brotherhood, from the rebuilding of Stormwind to this day.", icon = 132053, orderIndex = 1 },
		},
	})
end

talk()
local f = PolestarUIGossip
local r = f.psRows
assert(f:IsShown() and not GossipFrame:IsShown(), "ours closed or the stock window open")
assert(r[1].Text:GetText() == "Wolves Across the Border" and r[2].Text:GetText() == "The Fargodeep Mine", "quests to hand in not first")
assert(r[1].Icon.texture ~= r[2].Icon.texture, "complete and incomplete share an icon")
assert(r[3].Text:GetText() == "A Threat Within" and r[4].Text:GetText() == "Kobold Camp Cleanup", "quests to take not next")
assert(r[3].Icon.texture ~= r[4].Icon.texture, "the repeatable quest has the plain icon")
assert(r[4].Icon.desaturated and not r[3].Icon.desaturated, "the trivial quest's icon is not greyed")
assert(r[5]:GetHeight() > r[4]:GetHeight(), "the long option did not take a second line")

-- QUEST_LOG_UPDATE redraws: the quest handed in elsewhere is gone.
local active = C_GossipInfo.GetActiveQuests()
local done = table.remove(active, 1)
stub.fire("QUEST_LOG_UPDATE")
assert(r[1].Text:GetText() == "The Fargodeep Mine" and not r[5]:IsShown(), "the list did not redraw")
table.insert(active, 1, done)
stub.fire("QUEST_LOG_UPDATE")

-- A quest hands on to the stock quest dialog; the gossip is not ended under it.
stub.RunScript(r[1], "OnClick")
assert(stub.gossipPicked[1] == "active 33", "the quest was not picked")
assert(not f:IsShown() and stub.handedOn == "QUEST_PROGRESS" and stub.gossipClosed == 0, "the quest dialog was not handed on to, or ours ended the gossip")

talk()
