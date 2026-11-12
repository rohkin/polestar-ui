--@ title: Social: Recent allies
--@ roots: PolestarUISocial
--@ stubs: stub_social.lua
-- Recent allies (C_RecentAllies) in the client's order: opening the page asks the client for
-- them, says it is loading until they come (RECENT_ALLIES_CACHE_UPDATE), then lists each with
-- level, class, where they are and how you met. Click whispers, double-click invites,
-- right-click opens the game's recent ally menu.
stub.alliesReady = false
PolestarUI.Show("social", "allies")
local f = PolestarUISocial
assert(stub.alliesRequested, "data not requested")
assert(f.psEmpty:IsShown() and f.psEmpty:GetText() == "Loading recent allies...", "loading")
stub.alliesReady = true
stub.fire("RECENT_ALLIES_CACHE_UPDATE")
local function row(name)
	for _, r in ipairs({ f.psPanel:GetChildren() }) do
		if r:IsShown() and r.Name and r.Name:GetText() == name then return r end
	end
end
assert(f.Title:GetText() == "Recent allies" and not f.psEmpty:IsShown(), "page")
assert(row("Vessa").Sub:GetText() == "Level 23 Rogue · The Deadmines · Grouped in The Deadmines", "online: " .. tostring(row("Vessa").Sub:GetText()))
assert(row("Orrin").Sub:GetText() == "Level 21 Mage · Grouped in Westfall", "offline: " .. tostring(row("Orrin").Sub:GetText()))
stub.RunScript(row("Vessa"), "OnClick", "LeftButton")
stub.RunScript(row("Vessa"), "OnDoubleClick", "LeftButton")
stub.advance(0.5)
assert(stub.invited == "Vessa-Realm" and stub.told == nil, "double-click")
stub.RunScript(row("Orrin"), "OnClick", "RightButton")
assert(stub.popup[1] == "RECENT_ALLY_OFFLINE" and stub.popup[2] == "Orrin-Realm", "menu")
