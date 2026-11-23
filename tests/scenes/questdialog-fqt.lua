--@ title: Quest dialog: ForeverQuestTint
--@ roots: PolestarUIQuestDialog
--@ stubs: stub_questdialog.lua, stub_foreverquesttint.lua
-- With ForeverQuestTint, a quest Forever added (here quest 7, taken out of the original list) shows the teal wash over the dialog's body and, with showLogo, the Forever logo in the band; an original Classic quest (33) and a greeting show neither.
local R = PolestarUI.FQTData.ranges
for i, r in ipairs(R) do if r[1] == 5 and r[2] == 40 then table.remove(R, i); table.insert(R, i, { 8, 40 }); break end end
ForeverQuestTintDB.showLogo = true
stub.fire("QUEST_DETAIL")
local f = PolestarUIQuestDialog
assert(f.psGlow:IsShown() and f.psLogo:IsShown(), "wash and logo on the marked quest")
assert(f.psLogo.Tex:GetTexture():find("ForeverLogo", 1, true), "their logo texture")
stub.quest.questID = 33
stub.fire("QUEST_DETAIL")
assert(not f.psGlow:IsShown() and not f.psLogo:IsShown(), "none on a classic quest")
stub.quest.questID = 7
stub.fire("QUEST_DETAIL")
ForeverQuestTintDB.showLogo = false
stub.fire("QUEST_PROGRESS")
assert(f.psGlow:IsShown() and not f.psLogo:IsShown(), "wash without the logo when showLogo is off")
stub.fire("QUEST_GREETING")
assert(not f.psGlow:IsShown(), "none on a greeting")
ForeverQuestTintDB.showLogo = true
stub.fire("QUEST_DETAIL")
