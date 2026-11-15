--@ title: Group Finder: Who, too many results
--@ roots: PolestarUIGroupFinder
--@ stubs: stub_groupfinder.lua, stub_who.lua
-- The server sends 50 players of a larger count: the subtitle has the count, a note above the cards says only the first 50 show (the stock totals line). No query goes out without a click or key.
PolestarUI.Show("groupfinder", "who")
local f = PolestarUIGroupFinder
assert(stub.who == nil, "a query went out on show")
assert(f.Body:IsShown(), "no body")
local list = {}
for i = 1, 50 do
	local p = stub.whoSample[(i - 1) % 5 + 1]
	list[i] = { fullName = p.fullName .. string.char(96 + (i - 1) % 26 + 1), level = p.level, raceStr = p.raceStr, classStr = p.classStr, filename = p.filename, area = p.area, fullGuildName = p.fullGuildName, gender = 2 }
end
stub.whoResults, stub.whoTotal = list, 137
stub.fire("WHO_LIST_UPDATE")
assert(f.Subtitle:GetText():find("137 found", 1, true), "subtitle")
assert(f.psWhoRows[50]:IsShown(), "50 cards")
assert(f.psWhoRows[1]:GetTop() < f.Body:GetTop() - 24, "no room for the note")
stub.assertNoErrors()
