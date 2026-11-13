--@ title: Unit frames: Edit Mode with no party, pet or boss (ours stand in, as the game's do)
--@ roots: PolestarUIPetFrame, PolestarUIPartyFrame1, PolestarUIPartyFrame2, PolestarUIPartyFrame3, PolestarUIPartyFrame4, PolestarUIBossFrame1, PolestarUIBossFrame2, PolestarUIBossFrame3, PolestarUIBossFrame4, PolestarUIBossFrame5, PetFrameSelection, PartyFrameSelection, BossTargetFrameContainerSelection
stub.cvars.statusText = "1"
stub.showPartyInEditMode = true
assert(not PolestarUIPartyFrame1:IsShown() and not PolestarUIBossFrame1:IsShown() and not PolestarUIPetFrame:IsShown(), "nothing to show")
stub.enterEditMode()
stub.advance(0.1)
for i = 1, 4 do assert(_G["PolestarUIPartyFrame" .. i]:IsShown() and _G["PolestarUIPartyFrame" .. i]:GetAttribute("unit") == "player", "party " .. i .. " stands in") end
for i = 1, 5 do assert(_G["PolestarUIBossFrame" .. i]:IsShown(), "boss " .. i .. " stands in") end
assert(PolestarUIPetFrame:IsShown(), "pet stands in")
-- The player drags the party box: ours follow.
stub.moveSystem(PartyFrame, 60, 280)
stub.advance(0.1)
assert(select(5, PolestarUIPartyFrame1:GetPoint(1)) == PartyFrame.MemberFrame1:GetTop(), "party follows the drag")
-- Closed: back to their units (none: hidden).
stub.exitEditMode()
stub.advance(0.1)
assert(not PolestarUIPartyFrame1:IsShown() and PolestarUIPartyFrame1:GetAttribute("unit") == "party1", "party back to its unit")
assert(not PolestarUIBossFrame1:IsShown() and not PolestarUIPetFrame:IsShown(), "bosses and pet hidden again")
-- Open again for the picture.
stub.enterEditMode()
stub.advance(0.1)
