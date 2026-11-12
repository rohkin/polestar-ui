--@ title: Social: Friends
--@ roots: PolestarUISocial
--@ stubs: stub_social.lua
-- The keys open ours through override bindings, never the stock window (docs/CLIENT.md, rule 8);
-- in combat they still do, and the switch to the game's window is refused.
stub.pressKey("O")
local f = PolestarUISocial
assert(f:IsShown() and not FriendsFrame:IsShown(), "the social key")
stub.pressKey("O")
assert(not f:IsShown(), "no toggle")
stub.pressKey("CTRL-O")
assert(f:IsShown() and f.Title:GetText() == "Raid", "the raid key")
stub.pressKey("SHIFT-O")
assert(f.Title:GetText() == "Friends", "the friends key")
stub.inCombat = true
stub.pressKey("SHIFT-O")
assert(not f:IsShown(), "keys lost in combat")
PolestarUI.Switch("social", false)
assert(PolestarUI.Enabled("social") and stub.overrides["O"], "switched in combat")
stub.pressKey("O")
assert(f:IsShown() and not FriendsFrame:IsShown(), "the key in combat")
stub.inCombat = false
-- The sidebar counts each page; the subject block counts friends online.
assert(f.psLine:GetText() == "5 of 8 friends online", "subject line: " .. tostring(f.psLine:GetText()))
assert(f.psName:GetText() == "Testchar", "player name")
-- Rows: online first; click whispers, double-click invites, right-click opens the game's menu.
local function row(name)
	for _, r in ipairs({ f.psPanel:GetChildren() }) do
		if r:IsShown() and r.Name and r.Name:GetText() == name then return r end
	end
end
assert(row("Aelric") and row("Eldric"), "rows")
assert(select(2, row("Aelric"):GetPoint(1)) == f.psPanel and select(5, row("Aelric"):GetPoint(1)) == 0, "online first")
assert(row("Aelric").Sub:GetText() == "Level 24 Paladin · Elwynn Forest", "detail: " .. tostring(row("Aelric").Sub:GetText()))
assert(row("Eldric").Sub:GetText() == "Offline", "offline")
stub.RunScript(row("Brannoc"), "OnClick", "LeftButton")
assert(stub.told == "Brannoc", "click whispers")
stub.RunScript(row("Brannoc"), "OnDoubleClick", "LeftButton")
assert(stub.invited == "Brannoc", "double-click invites")
stub.RunScript(row("Eldric"), "OnClick", "RightButton")
assert(stub.popup[1] == "FRIEND" and stub.popup[2] == "Eldric", "right-click menu")
-- Add friend: our dialog with a name field.
f.footerButtons.right[1]:Click()
assert(PolestarModal:IsShown(), "no add friend dialog")
f.psAdd.Box:SetText("Fenwick")
PolestarModal.Box.Action:Click()
assert(stub.added == "Fenwick" and not PolestarModal:IsShown(), "add friend")
-- Ignored: the ✕ stops ignoring at once.
PolestarUI.Show("social", "ignored")
local spam = row("Spamalot")
assert(spam and spam.Remove:IsShown(), "ignore row")
spam.Remove:Click()
assert(stub.unignored == "Spamalot" and not row("Spamalot"), "unignore")
PolestarUI.Show("social", "friends")
assert(not FriendsFrame:IsShown(), "stock window")
