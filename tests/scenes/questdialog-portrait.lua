--@ title: Quest dialog: portrait, extras, offers elsewhere
--@ roots: PolestarUIQuestDialog, PolestarUIQuestDialogPortrait
--@ stubs: stub_questdialog.lua
-- An offer with the giver's portrait (GetQuestPortraitGiver) in a flyout off the window's right edge, its name and text; the turn-in's on the reward page. The offer's extras as the stock detail: a spell to learn, the suggested group, the giver's signature. With instantQuestText off the description writes itself in and Accept waits for it. An offer an item starts, or an auto-accepted one from an area trigger, goes to the objective tracker as a pop-up and the dialog ends, as the stock frame does; an auto-accepted offer cannot be closed with the close button, and closing it takes its pop-up away.
local function look(fr, s) for _, r in ipairs({ fr:GetRegions() }) do if r:IsShown() and r.GetText and r:GetText() and tostring(r:GetText()):find(s, 1, true) then return r end end for _, k in ipairs({ fr:GetChildren() }) do if k:IsShown() then local r = look(k, s) if r then return r end end end end
local function calls(name) local n = 0 for _, c in ipairs(stub.questCalls) do if c[1] == name then n = n + 1 end end return n end
local q = stub.quest

-- An item starts it: a tracker pop-up, no window.
stub.fire("QUEST_DETAIL", 6948)
assert(not (PolestarUIQuestDialog and PolestarUIQuestDialog:IsShown()) and stub.popUps[7] == "OFFER" and calls("CloseQuest") == 1, "an item's offer opened a window")
stub.popUps[7] = nil
-- An area trigger's auto-accepted offer: the same.
q.auto, q.areaTrigger = true, true
stub.fire("QUEST_DETAIL", 0)
assert(not (PolestarUIQuestDialog and PolestarUIQuestDialog:IsShown()) and stub.popUps[7] == "OFFER" and calls("CloseQuest") == 2, "an area trigger's offer opened a window")
q.areaTrigger = nil

-- Auto-accepted from the NPC: shown, OK only, no close; closing takes the pop-up away.
stub.popUps[7] = "OFFER"
stub.fire("QUEST_DETAIL", 0)
local f = PolestarUIQuestDialog
assert(f:IsShown() and not f.Close:IsEnabled() and f.Close.psReason and not f.footerButtons.left[1], "auto-accept: closable, no reason, or a Decline")
f:Hide()
assert(not stub.popUps[7], "the pop-up stayed")
q.auto = false

-- The text writes itself in; Accept waits.
stub.cvars.instantQuestText = "0"
q.giver = { 3167, "Clear the kobolds from the camp to the north.", "Marshal McBride", 0 }
q.turnIn = { 3167, "Return to Marshal McBride.", "Marshal McBride" }
q.criteriaSpell = { 2580, "Find Minerals", 136025 }
q.group = 3
stub.fire("QUEST_DETAIL", 0)
local accept = f.footerButtons.right[1]
assert(not accept:IsEnabled() and accept.psReason and f.psDesc.gradient == 0, "Accept before the text is in, or no reason")
stub.advance(5)
assert(accept:IsEnabled(), "Accept still off after the text")
stub.cvars.instantQuestText = nil

local p = PolestarUIQuestDialogPortrait
assert(p:IsShown() and p.Name:GetText() == "Marshal McBride" and p.Text:GetText():find("kobolds"), "the giver's portrait")
assert(look(f.Body, "Find Minerals") and look(f.Body, "Suggested Players: [3]"), "the spell objective or the group")
stub.fire("QUEST_PROGRESS")
assert(not p:IsShown(), "a portrait on the progress page")
stub.fire("QUEST_COMPLETE")
assert(p:IsShown() and p.Text:GetText() == "Return to Marshal McBride.", "the turn-in portrait")
q.criteriaSpell, q.group = nil, nil
stub.fire("QUEST_DETAIL", 0)
QUEST_SUGGESTED_GROUP_NUM = "Suggested Players: [%d]"
