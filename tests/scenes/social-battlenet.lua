--@ title: Social: Battle.net
--@ roots: PolestarUISocial
--@ stubs: stub_social.lua
-- Battle.net friends: in WoW (character, level, class, zone), in the app, offline (last online).
-- The search finds a character name too; click whispers the account, right-click opens its menu.
PolestarUI.Show("social", "bnet")
local f = PolestarUISocial
local function row(name)
	for _, r in ipairs({ f.psPanel:GetChildren() }) do
		if r:IsShown() and r.Name and r.Name:GetText() == name then return r end
	end
end
assert(row("Mira").Sub:GetText() == "Thessaly · Level 26 Druid · Darkshore", "in game: " .. tostring(row("Mira").Sub:GetText()))
assert(row("Jon").Sub:GetText() == "In the Battle.net app", "in the app")
assert(row("Sefa").Sub:GetText() == "Last online 3 days", "offline: " .. tostring(row("Sefa").Sub:GetText()))
stub.RunScript(row("Mira"), "OnClick", "LeftButton")
assert(stub.told == "Mira", "whisper")
stub.RunScript(row("Sefa"), "OnClick", "RightButton")
assert(stub.popup[1] == "BN_FRIEND" and stub.popup[2] == "Sefa", "menu")
f.Search:SetText("thess")
stub.RunScript(f.Search, "OnTextChanged")
assert(row("Mira") and not row("Jon"), "search by character")
f.Search:SetText("")
stub.RunScript(f.Search, "OnTextChanged")
assert(row("Jon"), "search cleared")
