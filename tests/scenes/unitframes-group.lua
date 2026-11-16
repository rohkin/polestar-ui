--@ title: Unit frames: pet, party and bosses
--@ roots: PolestarUIPlayerFrame, PolestarUIPetFrame, PolestarUIPartyFrame1, PolestarUIPartyFrame2, PolestarUIPartyFrame3, PolestarUIPartyFrame4, PolestarUIBossFrame1, PolestarUIBossFrame2, PolestarUIBossFrame3
stub.cvars.statusText = "1"
stub.units.pet = { name = "Wolf", level = 23, health = 700, max = 900, power = 60, powerMax = 100, powerType = 3, reaction = 5 }
stub.units.party1 = { name = "Paxton", level = 25, class = "PRIEST", player = true, health = 1500, max = 1800, healAbsorbs = 300, power = 2000, powerMax = 3000, reaction = 5 }
stub.units.party2 = { name = "Aria", level = 24, class = "MAGE", player = true, health = 0, max = 1400, dead = true, reaction = 5 }
stub.units.party3 = { name = "Thorn", level = 26, class = "ROGUE", player = true, health = 1700, max = 1700, power = 80, powerMax = 100, powerType = 3, reaction = 5, offline = true }
stub.units.boss1 = { name = "Edwin VanCleef", level = -1, health = 30000, max = 40000, power = 0, powerMax = 0, reaction = 2, classification = "worldboss", threat = 3 }
stub.units.boss2 = { name = "Defias Blackguard", level = 21, health = 2000, max = 2000, reaction = 2, classification = "elite" }
stub.secure(function() PetFrame:Show() end)
stub.updateParty()
stub.updateBosses()
stub.fire("GROUP_ROSTER_UPDATE")
stub.unitWatch()
stub.advance(0.1)
local P1, P4, Pet, B1, B3 = PolestarUIPartyFrame1, PolestarUIPartyFrame4, PolestarUIPetFrame, PolestarUIBossFrame1, PolestarUIBossFrame3
assert(Pet:IsShown() and P1:IsShown() and PolestarUIPartyFrame3:IsShown() and not P4:IsShown(), "pet and party shown by unit")
assert(B1:IsShown() and PolestarUIBossFrame2:IsShown() and not B3:IsShown(), "bosses shown by unit")
-- Each sits on its stock frame: the pet's Edit Mode box, the party member, the boss frame's body.
assert(select(4, Pet:GetPoint(1)) == PetFrame.Selection:GetLeft(), "pet on its box")
local m1 = PartyFrame.MemberFrame1
assert(select(4, P1:GetPoint(1)) == m1:GetLeft() and select(5, P1:GetPoint(1)) == m1:GetTop() and P1:GetWidth() == m1:GetWidth(), "party member 1 on its frame")
assert(select(5, PolestarUIPartyFrame2:GetPoint(1)) == PartyFrame.MemberFrame2:GetTop(), "party member 2 under it")
assert(select(4, B1:GetPoint(1)) == Boss1TargetFrame:GetLeft() + 20 and B1:GetScale() == 0.75, "boss on its frame's body, at its scale")
-- A boss the game has not shown yet stands where its container will put it.
assert(select(5, B3:GetPoint(1)) == Boss3TargetFrame:GetTop() - 16, "boss 3 placed before it shows: " .. tostring(select(5, B3:GetPoint(1))) .. " " .. Boss3TargetFrame:GetTop())
-- The stock pieces veiled; happiness, the party's icons, the frames themselves kept.
assert(PetPortrait:GetAlpha() == 0 and PetFrameHealthBar:GetAlpha() == 0 and PetFrameHappiness:GetAlpha() == 1 and PetFrame:IsShown(), "pet veiled")
assert(not PetFrameHealthBar:IsMouseMotionEnabled() and not PetFrameManaBar:IsMouseMotionEnabled(), "the pet's faded bars still take the mouse")
-- The game writes the threat flash's and attack pulse's vertex alpha (which is
-- their alpha): emptied, not faded, they stay unseen.
stub.secure(function() PetFrameFlash:SetVertexColor(1, 0, 0); PetAttackModeTexture:SetVertexColor(1, 0, 0, 1) end)
assert(PetFrameFlash:GetAtlas() == nil and PetAttackModeTexture:GetAtlas() == nil and PetAttackModeTexture:GetTexture() == nil,"pet flash and attack pulse emptied")
assert(not m1.Portrait:IsShown() and m1.HealthBarContainer:GetAlpha() == 0 and m1.PartyMemberOverlay.LeaderIcon:GetAlpha() == 1 and not m1:IsMouseEnabled(), "party member veiled")
assert(not m1.HealthBarContainer.HealthBar:IsMouseMotionEnabled() and not m1.ManaBar:IsMouseMotionEnabled(), "a party member's faded bars still take the mouse")
assert(Boss1TargetFrame.TargetFrameContainer:IsShown() == false, "boss veiled")
-- Texts: a dead member, an offline one, a boss's ?? level.
assert(PolestarUIPartyFrame2.healthText:GetText() == "Dead" and PolestarUIPartyFrame3.healthText:GetText() == "Offline", "dead and offline")
assert(B1.levelText:GetText() == "?? Boss", "boss level: " .. tostring(B1.levelText:GetText()))
assert(issecretvalue(P1.HealAbsorb:GetValue()), "heal absorb handed over")
-- A party member in another group: the game fades its frame; ours follow.
stub.secure(function() PartyFrame.MemberFrame3:SetAlpha(0.6) end)
stub.fire("UNIT_PHASE", "party3")
assert(PolestarUIPartyFrame3:GetAlpha() == 0.6, "faded as the game's")
-- In a raid the party frames step aside (the raid frames show).
stub.inRaid = true
stub.unitWatch()
assert(not P1:IsShown(), "no party frames in a raid")
stub.inRaid = false
stub.unitWatch()
-- Edit Mode's Raid-Style Party Frames: ours stand down, and come back.
stub.raidStyleParty = true
stub.fire("EDIT_MODE_LAYOUTS_UPDATED")
stub.advance(0.1)
assert(not P1:IsShown(), "raid-style party: ours stand down")
stub.raidStyleParty = false
stub.fire("EDIT_MODE_LAYOUTS_UPDATED")
stub.advance(0.1)
assert(P1:IsShown(), "back")
