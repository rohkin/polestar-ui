--@ title: Guild: info
--@ roots: PolestarUIGuild
--@ stubs: stub_guild.lua
-- The stock Guild Info tab: the message of the day and the guild information, each with Edit
-- for those allowed (a field of 255 letters; a box of 499), and the week's guild challenges
-- with progress or a check. Members without the rights get no Edit.
PolestarUI.Show("guild", "info")
local f = PolestarUIGuild
assert(stub.asked.roster and stub.asked.challenges, "info not asked for")
assert(f.Title:GetText() == "The Night Watch" and f.Subtitle:GetText() == "Officer · 9 members" and f.psOnline:GetText() == "1 of 3 challenges done this week", "band: " .. tostring(f.psOnline:GetText()))
local function line(text)
	for _, r in ipairs({ f.psLines:GetChildren() }) do
		if r:IsShown() and ((r.Head:IsShown() and r.Head.Text:GetText() == text) or (r.Text:IsShown() and r.Text:GetText() == text)) then return r end
	end
end
local m = line("Message of the day")
assert(m and m.Edit:IsShown(), "MOTD edit")
assert(line("Raid tonight at 8: bring flasks."), "MOTD text")
m.Edit:Click()
assert(PolestarModal:IsShown() and stub.focus:GetText() == "Raid tonight at 8: bring flasks.", "MOTD field")
stub.focus:SetText("Raid at 9 tonight.")
PolestarModal.Box.Action:Click()
assert(stub.motdSet == "Raid at 9 tonight.", "MOTD set")
line("Guild information").Edit:Click()
stub.focus:SetText("A levelling guild.")
PolestarModal.Box.Action:Click()
assert(stub.infoSet == "A levelling guild." and line("A levelling guild."), "info set")
assert(line("Dungeon").Right:GetText() == "2/7" and line("Raid").Right:GetText() == "Done", "challenges")
stub.noOfficer = true
PolestarUI.Show("guild")
assert(not line("Message of the day").Edit:IsShown(), "member can edit")
stub.noOfficer = false
PolestarUI.Show("guild")
-- No challenges: the row falls back to the online count, and the row stays.
local n = GetNumGuildChallenges
GetNumGuildChallenges = function() return 0 end
PolestarUI.Show("guild")
assert(f.psOnline:GetText() == "6 online" and f.TabRow:IsShown(), "no-challenges row")
GetNumGuildChallenges = n
PolestarUI.Show("guild")
