--@ title: Quest dialog: rewards with Polestar's marks
--@ roots: PolestarUIQuestDialog
--@ stubs: stub_questdialog.lua
-- QUEST_COMPLETE opens ours on the reward page, never the stock window. Polestar's marks sit on our choices as on the stock buttons: the upgrade arrow on each upgrade, the coin on the highest vendor value once every price is known, the accent frame on the best of two or more once every verdict is in; Polestar's rewardHighlight off, none. Completing asks for a choice first (the game's error); a click picks one, and Complete takes it; a quest that takes money asks first in our dialog, and cancelling declines.
local f
local function look(fr, s) for _, r in ipairs({ fr:GetRegions() }) do if r:IsShown() and r.GetText and r:GetText() and tostring(r:GetText()):find(s, 1, true) then return r end end for _, k in ipairs({ fr:GetChildren() }) do if k:IsShown() then local r = look(k, s) if r then return r end end end end
local function calls(name) local n, last = 0 for _, c in ipairs(stub.questCalls) do if c[1] == name then n, last = n + 1, c[2] end end return n, last end
local function tile(name) return look(f.Body, name):GetParent() end
local function marks(name) local t = tile(name) return t.Up:IsShown(), t.Coin:IsShown(), t.Ring[1]:IsShown(), t.Sel:IsShown() end

-- Verdicts not all in: arrows and the coin, no best yet.
stub.verdicts.complete = false
stub.fire("QUEST_COMPLETE")
f = PolestarUIQuestDialog
assert(f:IsShown() and not QuestFrame:IsShown(), "ours closed or the stock window open")
assert(look(f.Body, "Well done") and look(f.Body, "Militia Dagger"), "reward text and choices")
local up, coin, best = marks("Militia Dagger")
assert(up and not coin and not best, "dagger: an upgrade, no best before every verdict")
up, coin, best = marks("Kobold Ear Charm")
assert(not up and coin and not best, "charm: the coin")

-- Polestar's setting off: no marks.
stub.rewardMarks = false
stub.fire("QUEST_COMPLETE")
for _, n in ipairs({ "Militia Dagger", "Militia Buckler", "Kobold Ear Charm" }) do
	up, coin, best = marks(n)
	assert(not (up or coin or best), "a mark with rewardHighlight off: " .. n)
end
stub.rewardMarks = true

-- No price for one: no coin.
stub.verdicts.priced = false
stub.fire("QUEST_COMPLETE")
assert(not select(2, marks("Kobold Ear Charm")), "a coin without every price")
stub.verdicts.priced = true

-- Every verdict in: the best framed.
stub.verdicts.complete = true
stub.fire("QUEST_COMPLETE")
up, coin, best = marks("Militia Dagger")
assert(up and not coin and best, "dagger: the best")
assert(not select(3, marks("Militia Buckler")) and not select(3, marks("Kobold Ear Charm")), "one best")

-- No choice yet: the game's error, nothing taken.
f.footerButtons.right[1]:Click()
assert(calls("QuestChooseRewardError") == 1 and calls("GetQuestReward") == 0, "completed without a choice")

-- A quest that takes money asks first; cancelling declines.
tile("Militia Buckler"):Click()
assert(select(4, marks("Militia Buckler")) and not select(4, marks("Militia Dagger")), "the click did not select")
stub.quest.money = 5000
f.footerButtons.right[1]:Click()
assert(PolestarModal:IsShown() and calls("GetQuestReward") == 0, "paid without asking")
PolestarModal.Box.Cancel:Click()
assert(calls("DeclineQuest") == 1 and calls("GetQuestReward") == 0, "cancel did not decline")
stub.quest.money = 0
f.footerButtons.right[1]:Click()
local n, i = calls("GetQuestReward")
assert(n == 1 and i == 2, "not the chosen reward")
