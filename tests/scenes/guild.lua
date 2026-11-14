--@ title: Guild: roster
--@ roots: PolestarUIGuild
--@ stubs: stub_guild.lua
-- The guild key opens ours and closes it, in combat too, never the stock window; the micro
-- button's overlay opens ours and hands a shift-click to the micro button from secure code
-- (docs/CLIENT.md, rule 8). The roster: online members in the stock order, column headers that
-- sort (a second click reverses), Show offline (the stock CVar) from the Filter menu, a secret
-- roster read keeps the last, and right-click opens the game's guild member menu.
stub.neutral = true
stub.pressKey("J")
assert(not PolestarUIGuild or not PolestarUIGuild:IsShown(), "opened for a Neutral character")
stub.neutral = false
stub.pressKey("J")
assert(PolestarUIGuild:IsShown() and not CommunitiesFrame:IsShown() and not CommunitiesFrame.shown, "key")
stub.pressKey("J")
assert(not PolestarUIGuild:IsShown(), "no toggle")
stub.inCombat = true
stub.pressKey("J")
assert(PolestarUIGuild:IsShown(), "not in combat")
stub.pressKey("J")
stub.inCombat = false
stub.advance(0.1)
local o = PolestarUIGuildMicro
assert(o:IsShown() and o:GetAttribute("shift-type1") == "click" and o:GetAttribute("clickbutton") == GuildMicroButton, "no overlay")
assert(select(2, o:GetPoint(1)) ~= GuildMicroButton and o:GetLeft() == GuildMicroButton:GetLeft(), "overlay anchored to the micro button, or not over it")
stub.RunScript(o, "PostClick", "LeftButton")
local f = PolestarUIGuild
assert(f:IsShown() and not CommunitiesFrame.shown, "micro")
assert(stub.asked.roster, "roster not asked for")
assert(f.Title:GetText() == "The Night Watch" and f.Subtitle:GetText() == "Officer · 9 members", "band: " .. tostring(f.Subtitle:GetText()))
assert(f.psOnline:GetText() == "6 online" and f.TabRow:IsShown(), "online count on the tab row")

local function names()
	local t = {}
	for _, r in ipairs({ f.psRoster.Rows:GetChildren() }) do
		if r:IsShown() then t[#t + 1] = { r.psIndex, r.Cells.name:GetText() } end
	end
	table.sort(t, function(a, b) return a[1] < b[1] end)
	for i, e in ipairs(t) do t[i] = e[2] end
	return table.concat(t, ",")
end
local function row(name)
	for _, r in ipairs({ f.psRoster.Rows:GetChildren() }) do
		if r:IsShown() and r.Cells.name and r.Cells.name:GetText() == name then return r end
	end
end
local function head(label)
	for _, b in ipairs(f.psRoster.psHeads) do if b:IsShown() and b.Text:GetText() == label then return b end end
end
-- The stock order: presence (online, mobile, away, busy), then level, rank, name.
assert(names() == "Aelric,Testchar,Gwendolyn,Dovaline,Brannoc,Corwyn", "stock order: " .. names())
assert(row("Dovaline").Cells.zone:GetText() == "Mobile", "mobile zone")
head("Name"):Click()
assert(names() == "Aelric,Brannoc,Corwyn,Dovaline,Gwendolyn,Testchar", "name sort: " .. names())
head("Name"):Click()
assert(names() == "Testchar,Gwendolyn,Dovaline,Corwyn,Brannoc,Aelric", "reversed: " .. names())
head("Lvl"):Click()
assert(names() == "Dovaline,Gwendolyn,Brannoc,Testchar,Corwyn,Aelric", "level sort: " .. names())
-- Show offline: the stock check box, in the Filter menu.
f.psFilter:Click()
assert(PolestarMenu:IsShown(), "no filter menu")
local opts = {}
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() then opts[#opts + 1] = r.Text:GetText() end end
assert(table.concat(opts, ",") == "Show offline members,Extra column,Profession", "filter menu: " .. table.concat(opts, ","))
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() and r.Text:GetText() == "Show offline members" then r:Click() end end
assert(GetCVarBool("communitiesShowOffline"), "offline CVar")
head("Zone"):Click()
assert(names():find("Brannoc,Eldric,Fennick,Halvard$"), "zone sort puts offline last by recency: " .. names())
assert(row("Eldric").Cells.zone:GetText() == "Last online 3 days ago", "last online")
-- Right-click: the game's guild member menu.
stub.RunScript(row("Brannoc"), "OnClick", "RightButton")
assert(stub.popup and stub.popup[1] == "COMMUNITIES_GUILD_MEMBER" and stub.popup[2] == "Brannoc", "member menu")
-- A secret read (chat lockdown) keeps the last roster.
stub.secretRoster = true
PolestarUI.Show("guild")
assert(row("Brannoc") and f.Subtitle:GetText():find("9 members", 1, true), "secret roster dropped")
stub.secretRoster = false
-- Search: name, zone, rank, note.
f.psSearch:SetText("heal"); stub.RunScript(f.psSearch, "OnTextChanged", true)
assert(names() == "Brannoc", "search: " .. names())
f.psSearch:SetText(""); stub.RunScript(f.psSearch, "OnTextChanged", true)
head("Zone"):Click()
head("Zone"):Click()
assert(not CommunitiesFrame.shown, "stock window opened")
