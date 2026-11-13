--@ title: Guild: professions
--@ roots: PolestarUIGuild
--@ stubs: stub_guild.lua
-- The stock column dropdown's Profession: the roster grouped under each profession, folded
-- as stock, the skill in the extra column (sortable), and a click on a member asks the
-- client for their recipes (C_GuildInfo.QueryGuildMemberRecipes).
SetCVar("communitiesShowOffline", "1")
PolestarUI.Show("guild", "roster")
local f = PolestarUIGuild
local function rows()
	local t = {}
	for _, r in ipairs({ f.psRoster.Rows:GetChildren() }) do if r:IsShown() then t[#t + 1] = r end end
	table.sort(t, function(a, b) return a.psIndex < b.psIndex end)
	return t
end
local function texts()
	local t = {}
	for _, r in ipairs(rows()) do t[#t + 1] = r.psMember.head and r.Head:GetText() or (r.Cells.name:GetText() .. " " .. r.Cells.prof:GetText()) end
	return table.concat(t, ",")
end
f.psFilter:Click()
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() and r.Text:GetText() == "Profession" then r:Click() end end
assert(texts() == "Blacksmithing (1),Mining (2),Tailoring (1)", "folded heads: " .. texts())
rows()[2]:Click()
assert(texts() == "Blacksmithing (1),Mining (2),Testchar 175,Eldric 90,Tailoring (1)", "mining open: " .. texts())
for _, b in ipairs(f.psRoster.psHeads) do if b:IsShown() and b.Text:GetText() == "Profession" then b:Click() end end
assert(texts() == "Blacksmithing (1),Mining (2),Eldric 90,Testchar 175,Tailoring (1)", "skill sort: " .. texts())
stub.RunScript(rows()[3], "OnClick", "LeftButton")
assert(stub.recipes and stub.recipes[1] == "Player-1-6" and stub.recipes[2] == 186, "recipes asked")
assert(not PolestarUIGuildMember:IsShown(), "details on a profession row")
