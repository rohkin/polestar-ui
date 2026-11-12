--@ title: Quest dialog: an NPC's quests
--@ roots: PolestarUIQuestDialog
--@ stubs: stub_questdialog.lua
-- QUEST_GREETING opens ours on the NPC's list, never the stock window: the greeting, then the quests to hand in and the quests to take, each with the game's quest icon; a click picks it.
stub.fire("QUEST_GREETING")
local f = PolestarUIQuestDialog
assert(f:IsShown() and not QuestFrame:IsShown(), "ours closed or the stock window open")
assert(f.Title:GetText() == "Marshal McBride", "the NPC heads the band")
local rows = { f.psPanel:GetChildren() }
assert(#rows == 2 and rows[1].Text:GetText() == "Wolves Across the Border" and rows[2].Text:GetText() == "Kobold Camp Cleanup", "hand in, then take")
rows[1]:Click()
rows[2]:Click()
local c = stub.questCalls
assert(c[1][1] == "SelectActiveQuest" and c[1][2] == 1 and c[2][1] == "SelectAvailableQuest" and c[2][2] == 1, "picks")
