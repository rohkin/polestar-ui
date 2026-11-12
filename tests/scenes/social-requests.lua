--@ title: Social: Friend requests
--@ roots: PolestarUISocial
--@ stubs: stub_social.lua
-- The stock Friend Requests tab: its own page under "Received (3)", each card with who, what kind
-- and when; Accept, and Decline's menu (Decline, Report player, Block invites behind a confirm;
-- no block for a WoW friend's request). A Real ID request shows the one-time notice.
PolestarUI.Show("social", "requests")
local f = PolestarUISocial
assert(PolestarModal:IsShown() and PolestarModal.Box.Title:GetText() == "Real ID friend requests", "Real ID notice")
PolestarModal.Box.Action:Click()
assert(GetCVarBool("pendingInviteInfoShown"), "notice remembered")
PolestarUI.Show("social", "requests")
assert(not PolestarModal:IsShown(), "notice twice")
local function row(name)
	for _, r in ipairs({ f.psPanel:GetChildren() }) do
		if r:IsShown() and r.Name and r.Name:GetText() == name then return r end
	end
end
assert(f.Title:GetText() == "Friend requests" and row("Received (3)") and row("Rook") and row("Wren"), "requests page")
assert(not row("Mira"), "friends on the requests page")
assert(row("Rook").Sub:GetText() == "Battle.net friend · Sent 2 days ago", "card: " .. tostring(row("Rook").Sub:GetText()))
assert(row("Wren").Sub:GetText() == "WoW friend", "title card: " .. tostring(row("Wren").Sub:GetText()))
assert(row("Rook").Accept:IsShown() and row("Rook").Decline:IsShown() and not row("Rook").Invite:IsShown(), "request buttons")
-- The tooltip: when, what kind.
stub.RunScript(row("Rook"), "OnEnter")
assert(GameTooltip.lines and table.concat(GameTooltip.lines, "|"):find("Sent 2 days ago", 1, true), "request tooltip")
stub.RunScript(row("Rook"), "OnLeave")
-- Decline's menu.
local items
local show = Polestar.Widgets.ShowMenu
Polestar.Widgets.ShowMenu = function(a, its, o) items = its; return show(a, its, o) end
row("Wren").Decline:Click()
local t = {}
for _, it in ipairs(items) do t[#t + 1] = it.text end
assert(table.concat(t, ",") == "Decline,Report player", "title menu: " .. table.concat(t, ","))
row("Rook").Decline:Click()
t = {}
for _, it in ipairs(items) do t[#t + 1] = it.text end
assert(table.concat(t, ",") == "Decline,Report player,Block invites", "menu: " .. table.concat(t, ","))
items[2].onClick()
assert(stub.reported and stub.reported[1] == Enum.ReportType.Friend and stub.reported[2] == "Rook" and stub.reported[3] == 7, "report")
items[3].onClick()
assert(PolestarModal:IsShown() and not stub.blocked, "block asks first")
PolestarModal.Box.Action:Click()
assert(stub.blocked == 7 and stub.declined == 7 and not row("Rook"), "block declines")
-- Accept answers the other.
row("Wren").Accept:Click()
assert(stub.accepted == 8 and not row("Wren") and row("Received (1)") and row("Tamsin Ashby"), "accept")
Polestar.Widgets.ShowMenu = show
