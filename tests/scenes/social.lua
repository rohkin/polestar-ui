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
-- The sidebar counts each page; the subtitle counts friends online; the subject block holds the BattleTag.
assert(f.psSubtitle == "5 of 8 friends online", "subtitle: " .. tostring(f.psSubtitle))
assert(f.psLine:GetText() == "Testchar#1000", "subject line: " .. tostring(f.psLine:GetText()))
assert(f.psName:GetText() == "Testchar", "player name")
-- One list, as the stock one orders it: the friend request, then the Favorites and Friends
-- groups headed online/total, online Battle.net then WoW friends before offline ones;
-- online Battle.net rows carry their client's icon, favorites a star after the name.
local function rowsInOrder()
	local t = {}
	for _, r in ipairs({ f.psPanel:GetChildren() }) do
		if r:IsShown() and r.Name then t[#t + 1] = { r, -select(5, r:GetPoint(1)) } end
	end
	table.sort(t, function(a, b) return a[2] < b[2] end)
	local names = {}
	for i, e in ipairs(t) do names[i] = e[1].Name:GetText() end
	return table.concat(names, ",")
end
local function plain(t) return (t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end
local function row(name)
	for _, r in ipairs({ f.psPanel:GetChildren() }) do
		if r:IsShown() and r.Name and r.Name:GetText() == name then return r end
	end
end
assert(rowsInOrder() == "Rook,Favorites 0/1,Sefa,Friends 5/7,Mira,Jon,Aelric,Brannoc,Corwyn,Dovaline,Eldric", "order: " .. rowsInOrder())
assert(row("Sefa").Fav:IsShown() and row("Sefa").Fav.atlas == "friends-icon-favorites-dis" and not row("Mira").Fav:IsShown(), "favorite mark")
assert(row("Mira").Client:IsShown() and row("Mira").Client.psClient == "WoW" and row("Jon").Client.psClient == "App", "client icon")
assert(row("Mira").Client.psVersion == Enum.TitleIconVersion.Small, "client icon size")
assert(not row("Sefa").Client:IsShown() and not row("Aelric").Client:IsShown(), "client icon offline or WoW-only")
-- The client icon and invite sit in fixed slots: the same x on every row.
local function x(t) local _, rel, _, ox = t:GetPoint(1); return rel, ox end
assert(select(2, x(row("Mira").Client)) == select(2, x(row("Jon").Client)) and row("Mira").Client:GetPoint(1) == "RIGHT", "client slot")
-- A single line sits centred, two lines either side of the centre.
assert(row("Jon").Name:GetPoint(1) == "BOTTOMLEFT" and row("Jon").Sub:GetPoint(1) == "TOPLEFT", "two-line row")
assert(plain(row("Aelric").Sub:GetText()) == "Lvl 24 Paladin · Elwynn Forest", "detail: " .. tostring(row("Aelric").Sub:GetText()))
assert(row("Aelric").Sub:GetText():find("|c", 1, true), "class in colour")
assert(row("Eldric").Sub:GetText() == "Offline", "offline")
-- A click whispers once no second click follows; a double-click only invites.
stub.RunScript(row("Brannoc"), "OnClick", "LeftButton")
assert(stub.told == nil, "whispered before a double-click could follow")
stub.advance(0.5)
assert(stub.told == "Brannoc", "click whispers")
stub.told = nil
stub.RunScript(row("Corwyn"), "OnClick", "LeftButton")
stub.RunScript(row("Corwyn"), "OnDoubleClick", "LeftButton")
stub.advance(0.5)
assert(stub.invited == "Corwyn" and stub.told == nil, "double-click whispered too")
stub.RunScript(row("Eldric"), "OnClick", "RightButton")
assert(stub.popup[1] == "FRIEND" and stub.popup[2] == "Eldric", "right-click menu")
-- The friend request: Accept answers it and it leaves the list.
assert(row("Rook").Accept:IsShown() and row("Rook").Decline:IsShown() and not row("Rook").Client:IsShown(), "request row")
row("Rook").Accept:Click()
assert(stub.accepted == 7 and not row("Rook"), "accept")
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
assert(spam.Name:GetPoint(1) == "LEFT" and not spam.Sub:IsShown(), "one line, centred")
spam.Remove:Click()
assert(stub.unignored == "Spamalot" and not row("Spamalot"), "unignore")
PolestarUI.Show("social", "friends")
assert(not FriendsFrame:IsShown(), "stock window")
