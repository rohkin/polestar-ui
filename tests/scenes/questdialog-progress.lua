--@ title: Quest dialog: progress
--@ roots: PolestarUIQuestDialog
--@ stubs: stub_questdialog.lua
-- QUEST_PROGRESS opens ours on the progress page, never the stock window: the progress text, the money the quest takes (in danger when the player is short) and each required item as "have/need". Continue is enabled only when the quest can be completed, and completes it.
local f
local function look(fr, s) for _, r in ipairs({ fr:GetRegions() }) do if r:IsShown() and r.GetText and r:GetText() and tostring(r:GetText()):find(s, 1, true) then return r end end for _, k in ipairs({ fr:GetChildren() }) do if k:IsShown() then local r = look(k, s) if r then return r end end end end
local function calls(name) local n = 0 for _, c in ipairs(stub.questCalls) do if c[1] == name then n = n + 1 end end return n end

-- Not done yet: Continue waits.
stub.quest.completable = false
stub.fire("QUEST_PROGRESS")
f = PolestarUIQuestDialog
assert(f:IsShown() and not QuestFrame:IsShown(), "ours closed or the stock window open")
assert(look(f.Body, "Kobold Camp Cleanup") and look(f.Body, "cleared the camp") and look(f.Body, "Kobold Ear") and look(f.Body, "3/4"), "progress, required item as have/need")
assert(not f.footerButtons.right[1]:IsEnabled(), "Continue enabled on an unfinished quest")

-- Done, and it takes money the player is short of: the money in danger.
stub.quest.completable, stub.quest.have[50001], stub.quest.money = true, 4, 99999999
stub.fire("QUEST_PROGRESS")
assert(look(f.Body, "4/4") and f.footerButtons.right[1]:IsEnabled(), "completable")
local m = look(f.Body, GetMoneyString(99999999))
local r, g, b = m:GetTextColor()
local dr, dg, db = Polestar.Theme.Color("danger")
assert(m and math.abs(r - dr) + math.abs(g - dg) + math.abs(b - db) < 0.01, "the money the player is short of is not in danger")
stub.quest.money = 0
stub.fire("QUEST_PROGRESS")
assert(not look(f.Body, "Money"), "no money line for a quest that takes none")
f.footerButtons.right[1]:Click()
assert(calls("CompleteQuest") == 1, "continue")
