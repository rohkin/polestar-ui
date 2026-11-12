--@ title: Social: Add friend
--@ roots: PolestarUISocial
--@ stubs: stub_social.lua
-- The stock Add Friend button: a friendly player targeted is added at once; else the dialog
-- ("Send request"): a BattleTag goes to Battle.net, a name to a WoW friend request where the
-- game has them, else the old friends list; Real ID requests turned off are refused. With adding
-- friends switched off the button greys. The Battle.net bar's menu sets the broadcast (the stock
-- broadcast box) and opens the ignore list.
PolestarUI.Show("social", "friends")
local f = PolestarUISocial
local add = f.footerButtons.right[1]
stub.target = "Grimble"
add:Click()
assert(stub.added == "Grimble" and not (PolestarModal and PolestarModal:IsShown()), "target added at once")
stub.target = "Aelric" -- already a friend: the dialog
add:Click()
assert(PolestarModal:IsShown() and PolestarModal.Box.Action.Label:GetText() == "Send request", "dialog")
stub.target = nil
f.psAdd.Box:SetText("Nora#2211")
PolestarModal.Box.Action:Click()
assert(stub.added == "Nora#2211", "BattleTag")
stub.titleFriends = true
add:Click()
f.psAdd.Box:SetText("Fenwick")
PolestarModal.Box.Action:Click()
assert(stub.titleInvite == "Fenwick", "WoW friend request")
add:Click()
f.psAdd.Box:SetText("someone@example.com")
PolestarModal.Box.Action:Click()
assert(stub.uiError == "Real ID friend requests are turned off.", "Real ID refused")
stub.friendsDisabled = true
PolestarUI.Show("social", "friends")
assert(not add:IsEnabled(), "adding friends disabled")
stub.friendsDisabled = false
PolestarUI.Show("social", "friends")
assert(add:IsEnabled(), "re-enabled")
-- The broadcast: the current one to edit; Update sends a change.
local items
local show = Polestar.Widgets.ShowMenu
Polestar.Widgets.ShowMenu = function(a, its, o) items = its; return show(a, its, o) end
stub.broadcast = "Out questing"
f.psStatus:Click()
local function pick(text) for _, it in ipairs(items) do if it.text == text then return it.onClick() end end error("no " .. text) end
pick("Set broadcast")
assert(PolestarModal:IsShown() and f.psCast.Box:GetText() == "Out questing", "broadcast box")
f.psCast.Box:SetText("Raiding tonight")
PolestarModal.Box.Action:Click()
assert(stub.broadcast == "Raiding tonight", "broadcast set")
f.psStatus:Click()
pick("Ignore list")
assert(f.Title:GetText() == "Ignored", "ignore list")
Polestar.Widgets.ShowMenu = show
PolestarUI.Show("social", "friends")
add:Click()
