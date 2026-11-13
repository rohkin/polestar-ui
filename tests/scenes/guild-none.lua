--@ title: Guild: not in a guild
--@ roots: PolestarUIGuild
--@ stubs: stub_guild.lua
-- Out of a guild ours says so and points to the game's window for Guild Finder and
-- communities (shift-click the micro button); no footer. Joining one brings the roster.
stub.guildNone = true
PolestarUI.Show("guild")
local f = PolestarUIGuild
assert(f.psEmpty:IsShown() and f.psEmpty:GetText():find("not in a guild", 1, true), "not in a guild")
assert(f.psName:GetText() == "No guild", "subject block")
assert(not stub.asked.roster, "roster asked out of a guild")
stub.guildNone = false
PolestarUI.Show("guild")
assert(f.Title:GetText() == "Roster", "back to the roster")
stub.guildNone = true
PolestarUI.Show("guild")
