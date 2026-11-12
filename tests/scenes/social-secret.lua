--@ title: Social: Battle.net in combat
--@ roots: PolestarUISocial
--@ stubs: stub_social.lua
-- Battle.net names and the player's name are secret in combat (docs/CLIENT.md, rule 3): read in
-- the background out of combat, the window first opened mid-fight shows the last names read.
stub.fire("BN_FRIEND_INFO_CHANGED")
assert(not PolestarUISocial, "built before it was opened")
stub.inCombat = true
PolestarUI.Show("social", "friends")
local function plain(t) return (t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
local function row(name)
	for _, r in ipairs({ PolestarUISocial.psPanel:GetChildren() }) do
		if r:IsShown() and r.Name and r.Name:GetText() == name then return r end
	end
end
assert(row("Mira") and row("Sefa"), "secret names not kept")
assert(plain(row("Mira").Sub:GetText()) == "Thessaly · Lvl 26 Druid" and row("Mira").Where:GetText() == "Darkshore", "secret character not kept")
assert(PolestarUISocial.psName:GetText() == "Testchar", "player name not kept")
stub.RunScript(row("Mira"), "OnClick", "LeftButton")
stub.advance(0.5)
assert(stub.told == "Mira", "whispered a secret name")
