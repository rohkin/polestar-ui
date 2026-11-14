--@ title: Quest dialog: the game's looks
--@ roots: PolestarUIQuestDialog
--@ stubs: stub_questdialog.lua
-- In the game's looks (Forever's), the compact grid takes the skin's pad (20) and the 44 footer; the NPC's portrait well stays in the 60 band, the name beside it.
Polestar.Set("ui.skin", "forever")
stub.fire("QUEST_DETAIL", 0)
local f = PolestarUIQuestDialog
assert(f:IsShown() and f.psPad == 20 and f.Header:GetHeight() == 60 and f.Footer:GetHeight() == 44 and f.psPortraitIcon.texture == 132355, "not the game's looks")
