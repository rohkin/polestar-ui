--@ title: Guild: benefits
--@ roots: PolestarUIGuild
--@ stubs: stub_guild.lua
-- The stock Guild Benefits tab: guild reputation as a Skill Bar, the perks, and the rewards
-- with what each needs (an achievement greys it; a standing names it) and its cost, red when
-- short. Shift-click links a reward.
PolestarUI.Show("guild", "benefits")
local f = PolestarUIGuild
assert(stub.asked.rewards, "rewards not asked for")
assert(f.Title:GetText() == "The Night Watch" and f.Subtitle:GetText() == "Officer · 9 members · 2 perks · 3 rewards", "band: " .. tostring(f.Subtitle:GetText()))
local function line(pat)
	for _, r in ipairs({ f.psLines:GetChildren() }) do
		if r:IsShown() and r.Text:IsShown() and r.Text:GetText():find(pat, 1, true) then return r end
	end
end
assert(line("The Night Watch: Friendly") and line("The Night Watch: Friendly").Right:GetText() == "2100/6000", "reputation")
assert(line("Fast Track") and line("Mount Up"), "perks")
local banner = line("Ancient Guild Banner")
assert(banner.Sub:GetText() == "Requires Level 30", "achievement reward: " .. tostring(banner.Sub:GetText()))
assert(line("Wrap of Unity").Sub:GetText() == "Requires Revered" and line("Wrap of Unity").Right:GetText() == "300g 0s 0c", "standing reward")
assert(line("Guild Vault").Right:GetText() == "50g 0s 0c", "cost")
local IsModified = IsModifiedClick
IsModifiedClick = function() return true end
line("Guild Vault"):Click()
IsModifiedClick = IsModified
assert(stub.linked, "link reward")
