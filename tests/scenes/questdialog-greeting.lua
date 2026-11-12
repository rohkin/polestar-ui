--@ title: Quest dialog: an NPC's quests
--@ roots: PolestarUIQuestDialog
--@ stubs: stub_questdialog.lua
-- QUEST_GREETING opens ours on the NPC's list, never the stock window: the NPC's portrait and name on the band, the greeting, then Current Quests (to hand in) and Available Quests (to take) under their headings, as QuestFrameGreetingPanel_OnShow, each with the game's quest icon; a click picks it. No 3D portrait on the greeting.
local function look(fr, s) for _, r in ipairs({ fr:GetRegions() }) do if r:IsShown() and r.GetText and r:GetText() == s then return r end end end
stub.fire("QUEST_GREETING")
local f = PolestarUIQuestDialog
assert(f:IsShown() and not QuestFrame:IsShown(), "ours closed or the stock window open")
assert(f.Title:GetText() == "Marshal McBride" and f.psPortraitIcon.texture == 132355, "the NPC and its portrait head the band")
assert(look(f.Body, "Current Quests") and look(f.Body, "Available Quests"), "the list headings")
local active, available = { f.psPanel:GetChildren() }, { f.psPanel2:GetChildren() }
assert(#active == 1 and active[1].Text:GetText() == "Wolves Across the Border", "current quests")
assert(#available == 1 and available[1].Text:GetText() == "Kobold Camp Cleanup", "available quests")
-- No instruction in the band.
assert((f.Subtitle:GetText() or "") == "", "an instruction in the band")
assert(not f.psPortrait:IsShown(), "a 3D portrait on the greeting")
active[1]:Click()
available[1]:Click()
local c = stub.questCalls
assert(c[1][1] == "SelectActiveQuest" and c[1][2] == 1 and c[2][1] == "SelectAvailableQuest" and c[2][2] == 1, "picks")
