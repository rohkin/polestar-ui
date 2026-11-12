--@ title: Quest dialog: an offer
--@ roots: PolestarUIQuestDialog
--@ stubs: stub_questdialog.lua
-- The stock QuestFrame's four open events are unregistered on it (rule 15's exception), so QUEST_DETAIL opens ours, whoever led there, and never the stock window. The band names the NPC; the body has the quest's title, the objectives, the description and the rewards (choices, experience with its share of the level, money, an item). Accept accepts; a PvP quest asks first in our dialog, and cancelling declines. Closing ours ends the dialog once; the game's QUEST_FINISHED closes ours without ending it again. Off waits for /reload.
local f
local function look(fr, s) for _, r in ipairs({ fr:GetRegions() }) do if r:IsShown() and r.GetText and r:GetText() and tostring(r:GetText()):find(s, 1, true) then return r end end for _, k in ipairs({ fr:GetChildren() }) do if k:IsShown() then local r = look(k, s) if r then return r end end end end
local function calls(name) local n = 0 for _, c in ipairs(stub.questCalls) do if c[1] == name then n = n + 1 end end return n end

for _, e in ipairs({ "QUEST_GREETING", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE" }) do
	assert(not QuestFrame:IsEventRegistered(e), "stock still opens on " .. e)
end
assert(QuestFrame:IsEventRegistered("QUEST_FINISHED") and QuestFrame:IsEventRegistered("QUEST_ITEM_UPDATE"), "more than the open events unregistered")
assert(PolestarUI.modules.questdialog.reloadOff, "switching off does not wait for /reload")
PolestarUI.Show("questdialog")
assert(not (PolestarUIQuestDialog and PolestarUIQuestDialog:IsShown()), "opened away from a quest giver")

-- Another addon's handler, run before ours, accepts at once: the client ends
-- the dialog (QUEST_FINISHED) and the quest's text goes, before ours opens.
local auto = CreateFrame("Frame")
table.insert(stub.frames, 1, table.remove(stub.frames))
auto:RegisterEvent("QUEST_DETAIL")
auto:SetScript("OnEvent", function()
	AcceptQuest()
	stub.quest.title = ""
	stub.fire("QUEST_FINISHED")
end)
stub.fire("QUEST_DETAIL", 0)
assert(not (PolestarUIQuestDialog and PolestarUIQuestDialog:IsShown()), "open on a quest another addon accepted")
auto:UnregisterEvent("QUEST_DETAIL")
stub.quest.title = "Kobold Camp Cleanup"
stub.questCalls = {}

-- A PvP offer asks first; cancelling declines it.
stub.quest.pvp = true
stub.fire("QUEST_DETAIL", 0)
f = PolestarUIQuestDialog
assert(f:IsShown() and not QuestFrame:IsShown(), "ours closed or the stock window open")
f.footerButtons.right[1]:Click()
assert(PolestarModal:IsShown() and calls("AcceptQuest") == 0, "a PvP quest accepted without asking")
PolestarModal.Box.Cancel:Click()
assert(calls("DeclineQuest") == 1 and calls("AcceptQuest") == 0, "cancel did not decline")
stub.quest.pvp = false

-- The game ends the dialog: ours closes without ending it again.
stub.fire("QUEST_FINISHED")
assert(not f:IsShown() and calls("CloseQuest") == 0, "QUEST_FINISHED")

-- Closed by the player, ours ends the dialog once.
stub.fire("QUEST_DETAIL", 0)
f.Close:Click()
assert(not f:IsShown() and calls("CloseQuest") == 1, "closing ours did not end the dialog once: " .. calls("CloseQuest"))

-- The offer drawn.
stub.fire("QUEST_DETAIL", 0)
assert(f:IsShown() and not QuestFrame:IsShown(), "reopen")
assert(f.Title:GetText() == "Marshal McBride" and look(f.Body, "Kobold Camp Cleanup"), "the NPC on the band, the quest heading the body")
assert(look(f.Body, "Kill 10 Kobold Vermin") and look(f.Body, "cleansing"), "objectives and description")
assert(look(f.Body, REWARD_CHOICES) and look(f.Body, "Militia Dagger") and look(f.Body, "Kobold Ear Charm") and look(f.Body, "450 XP")
	and look(f.Body, "35% of level") and look(f.Body, "Money") and look(f.Body, "Money"):GetText() == "Money" and look(f.Body, "50") and look(f.Body, "Linen Bandage"), "rewards")
assert(tostring(f.footerButtons.left[1].Label:GetText()) == "Decline", "decline")
stub.RunScript(look(f.Body, "Kobold Ear Charm"):GetParent(), "OnEnter")
assert(GameTooltip.lines[1] == "quest choice 3", "the game's tooltip")
GameTooltip:Hide()
f.footerButtons.right[1]:Click()
assert(calls("AcceptQuest") == 1, "accept")
