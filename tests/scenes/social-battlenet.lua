--@ title: Social: Battle.net friends and a search
--@ roots: PolestarUISocial
--@ stubs: stub_social.lua
-- Battle.net friends on the Friends page: in WoW (character, level, class, zone), in the app,
-- offline (last online). Click whispers the account, right-click opens its menu (where the stock
-- list sets a favorite). The search finds a character name too.
PolestarUI.Show("social", "friends")
local f = PolestarUISocial
local function plain(t) return (t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
local function row(name)
	for _, r in ipairs({ f.psPanel:GetChildren() }) do
		if r:IsShown() and r.Name and r.Name:GetText() == name then return r end
	end
end
assert(plain(row("Mira").Sub:GetText()) == "Thessaly · Lvl 26 Druid · Darkshore", "in game: " .. tostring(row("Mira").Sub:GetText()))
assert(row("Jon").Sub:GetText() == "In the Battle.net app", "in the app")
assert(row("Sefa").Sub:GetText() == "Last online 3 days ago", "offline: " .. tostring(row("Sefa").Sub:GetText()))
-- The stock card's tooltip: character, level and class, race, zone, faction, the note, the
-- tags and the broadcast; offline, when last online; a WoW friend's note too.
local function tip(name)
	stub.RunScript(row(name), "OnEnter")
	local t = table.concat(GameTooltip.lines or {}, "|")
	stub.RunScript(row(name), "OnLeave")
	return t
end
local t = tip("Mira")
for _, want in ipairs({ "Thessaly", "Level 26 Druid", "Night Elf", "Darkshore", "Alliance", "Note: Raid healer", "Tags: Raiding, Healer", "LFG Deadmines" }) do
	assert(t:find(want, 1, true), "Mira's tooltip lacks " .. want .. ": " .. t)
end
assert(tip("Sefa"):find("Last online 3 days ago", 1, true), "offline tooltip")
assert(tip("Aelric"):find("Note: Guild officer", 1, true), "WoW friend's note")
stub.RunScript(row("Mira"), "OnClick", "LeftButton")
stub.advance(0.5)
assert(stub.told == "Mira", "whisper")
stub.RunScript(row("Sefa"), "OnClick", "RightButton")
assert(stub.popup[1] == "BN_FRIEND" and stub.popup[2] == "Sefa", "menu")
f.Search:SetText("thess")
stub.RunScript(f.Search, "OnTextChanged")
assert(row("Mira") and not row("Jon") and not row("Aelric"), "search by character")
