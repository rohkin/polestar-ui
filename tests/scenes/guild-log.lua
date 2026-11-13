--@ title: Guild: log
--@ roots: PolestarUIGuild
--@ stubs: stub_guild.lua
-- The stock guild log, newest first, each with how long ago.
PolestarUI.Show("guild", "log")
local f = PolestarUIGuild
assert(stub.asked.log, "log not asked for")
assert(f.Title:GetText() == "Log" and f.Subtitle:GetText() == "4 events", "band")
local t = {}
for _, r in ipairs({ f.psLines:GetChildren() }) do if r:IsShown() then t[#t + 1] = r.Text:GetText() .. " | " .. r.Right:GetText() end end
assert(t[1] == "Ishara left the guild | 5 hours ago" and t[4] == "Halvard joined the guild | 1 month ago", "log: " .. table.concat(t, "; "))
assert(t[3] == "Aelric invited Fennick | 12 days ago" and t[2] == "Aelric promoted Brannoc to Veteran | 2 days ago", "log: " .. table.concat(t, "; "))
