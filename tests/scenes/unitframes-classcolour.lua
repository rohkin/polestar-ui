--@ title: Unit frames, Class colour on: death knight, priest, rogue, pet, paladin, mage, warlock, druid
--@ roots: PolestarUIPlayerFrame, PolestarUITargetFrame, PolestarUITargetToT, PolestarUIFocusFrame, PolestarUIPetFrame, PolestarUIPartyFrame1, PolestarUIPartyFrame2, PolestarUIPartyFrame3, PolestarUIPartyFrame4, PolestarUIBossFrame1
--@ saved: PolestarDB = { schema = 1, settings = { ui = { classAccent = true } } }
stub.cvars.statusText = "1"
stub.units.player = { name = "Arthas", level = 80, class = "DEATHKNIGHT", player = true, health = 1830, max = 2400, absorbs = 300, power = 45, powerMax = 100, powerType = 1, reaction = 5 }
stub.units.target = { name = "Paxton", level = 80, class = "PRIEST", player = true, health = 12400, max = 20000, absorbs = 2000, power = 900, powerMax = 1200, reaction = 5 }
stub.units.targettarget = stub.units.player
stub.units.focus = { name = "Valeera", level = 80, class = "ROGUE", player = true, health = 2000, max = 2000, power = 80, powerMax = 100, powerType = 3, reaction = 5 }
stub.units.pet = { name = "Wolf", level = 79, health = 700, max = 900, power = 60, powerMax = 100, powerType = 3, reaction = 5 }
stub.units.party1 = { name = "Uther", level = 80, class = "PALADIN", player = true, health = 1500, max = 1800, healAbsorbs = 300, power = 2000, powerMax = 3000, reaction = 5 }
stub.units.party2 = { name = "Jaina", level = 80, class = "MAGE", player = true, health = 1100, max = 1400, absorbs = 200, reaction = 5 }
stub.units.party3 = { name = "Gul'dan", level = 80, class = "WARLOCK", player = true, health = 1700, max = 1700, reaction = 5 }
stub.units.party4 = { name = "Malfurion", level = 80, class = "DRUID", player = true, health = 900, max = 1700, reaction = 5 }
stub.units.boss1 = { name = "Edwin VanCleef", level = -1, health = 30000, max = 40000, reaction = 2, classification = "worldboss" }
stub.secure(function() PetFrame:Show() end)
stub.updateParty()
stub.updateBosses()
stub.fire("GROUP_ROSTER_UPDATE")
stub.fire("PLAYER_TARGET_CHANGED")
stub.fire("PLAYER_FOCUS_CHANGED")
stub.unitWatch()
for i = 1, 4 do stub.fire("UNIT_HEALTH", "party" .. i) end
stub.fire("UNIT_PET", "player")
stub.advance(0.3)
local function rgb(f) local c = f.Health.barColor return c[1], c[2], c[3] end
local T = Polestar.Theme
local r, g, b = T.ClassColor("PRIEST")
local x, y, z = rgb(PolestarUITargetFrame)
assert(x == r and y == g and z == b, "the priest's bar is not in the priest's class colour")

x, y, z = rgb(PolestarUIPartyFrame2)
r, g, b = T.ClassColor("MAGE")
assert(x == r and y == g and z == b, "the mage's bar is not in the mage's class colour")
x, y, z = rgb(PolestarUIPetFrame)
r, g, b = T.Color("sky")
assert(x == r and y == g and z == b, "a pet takes the header blue")
--@ panel
--@ title: Unit frames, Class colour on: hunter, shaman, paladin
--@ roots: PolestarUIPlayerFrame, PolestarUITargetFrame, PolestarUIFocusFrame
--@ saved: PolestarDB = { schema = 1, settings = { ui = { classAccent = true } } }
stub.units.player = { name = "Rexxar", level = 80, class = "HUNTER", player = true, health = 1830, max = 2400, power = 45, powerMax = 100, powerType = 1, reaction = 5 }
stub.units.target = { name = "Thrall", level = 80, class = "SHAMAN", player = true, health = 12400, max = 20000, power = 900, powerMax = 1200, reaction = 5 }
stub.units.focus = { name = "Tirion", level = 80, class = "PALADIN", player = true, health = 2000, max = 2000, power = 3000, powerMax = 4000, reaction = 5 }
stub.fire("PLAYER_TARGET_CHANGED")
stub.fire("PLAYER_FOCUS_CHANGED")
stub.unitWatch()
stub.advance(0.3)
