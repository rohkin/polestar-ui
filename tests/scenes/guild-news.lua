--@ title: Guild: news
--@ roots: PolestarUIGuild
--@ stubs: stub_guild.lua
-- The stock news: the message of the day, the guild's calendar events, then the news under
-- their date headings, sticky ones starred. Items link on shift-click; right-click offers
-- Link item or View achievement and, for those who may edit the MOTD, sticky. The Filter
-- menu is the stock news filters (guild achievements hidden where off). The impeachment
-- banner shows where the guild master may be replaced.
stub.impeach = true
PolestarUI.Show("guild", "news")
local f = PolestarUIGuild
assert(stub.asked.news and stub.asked.calendar, "news not asked for")
assert(f.Title:GetText() == "News" and f.Subtitle:GetText() == "3 news items", "band: " .. tostring(f.Subtitle:GetText()))
local function line(pat)
	for _, r in ipairs({ f.psLines:GetChildren() }) do
		if r:IsShown() and ((r.Head:IsShown() and r.Head.Text:GetText():find(pat, 1, true)) or (r.Text:IsShown() and r.Text:GetText():find(pat, 1, true))) then return r end
	end
end
local function menu()
	local t = {}
	for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() then t[#t + 1] = r.Text:GetText() end end
	return table.concat(t, ",")
end
local function pick(text)
	for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() and r.Text:GetText() == text then return r:Click() end end
end
assert(line("guild master has been away"), "impeach banner")
assert(line("Message of the day: Raid tonight"), "MOTD row")
assert(line("Deadmines run"), "calendar event")
assert(line("Thursday, 11/12"), "date heading")
local IsModified = IsModifiedClick
IsModifiedClick = function() return true end
line("Gwendolyn got"):Click()
IsModifiedClick = IsModified
assert(stub.linked and stub.linked:find("Krol Blade", 1, true), "shift-click link")
assert(line("defeated Edwin VanCleef").Glyph:IsShown(), "sticky mark")
stub.RunScript(line("Corwyn earned"), "OnClick", "RightButton")
assert(menu() == "View achievement,Make sticky", "news menu: " .. menu())
pick("Make sticky")
assert(stub.sticky and stub.sticky[1] == 3 and stub.sticky[2] == 1, "sticky")
f.psFilter:Click()
assert(menu() == "Achievements,Dungeon encounters,Epic items looted,Epic items purchased,Epic items crafted,Legendary items looted", "filters: " .. menu())
pick("Epic items crafted")
assert(stub.newsFilter[1] == 6 and stub.newsFilter[2] == 0, "filter off")
Polestar.Widgets.HideMenu()
