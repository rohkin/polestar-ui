--@ title: Group Finder: Browse actions
--@ roots: PolestarUIGroupFinder
--@ stubs: stub_groupfinder.lua, stub_lfgbrowse.lua
-- A click selects a listing (again: unselects); the player's own and a delisted one take no click. Send Message whispers the selected leader; Group Invite invites only a solo player, and only while the player may invite (solo, leader or assistant); a group says to whisper its leader. Right-click opens the stock menu: the leader, Send Message, Group Invite, Report Group, Report Advertisement (the game's report dialog). Listed and leading, Unlist is the game's window (C_LFGList.RemoveListing is protected): a secure button of ours over it opens the game's Group Finder. A heading folds its rows. The ignore-level-ranges option sets the CVar and the client's CVAR_UPDATE resets the pickers, as stock.
stub.activeEntry = { activityIDs = { 11 } }
PolestarUI.Show("groupfinder", "browse")
local f = PolestarUIGroupFinder
-- The row showing a listing now (rows are pooled: the sort moves listings between them).
local rows = setmetatable({}, { __index = function(_, id)
	for _, c in ipairs({ f.Body:GetChildren() }) do
		for _, r in ipairs({ c:GetChildren() }) do if r.psID == id and r:IsShown() then return r end end
	end
end })
local invite, send = f.footerButtons.right[1], f.footerButtons.right[2]
assert(invite.Label:GetText() == "Group Invite" and send.Label:GetText() == "Send Message", "footer")
assert(not send:IsEnabled() and send.psReason == "Select a listing first.", "Send Message without a selection")
-- The own listing and a delisted player take no click.
rows[1]:Click()
rows[9]:Click()
assert(not send:IsEnabled(), "own or delisted listing selected")
-- A solo player: whisper and invite.
rows[8]:Click()
assert(rows[8].Sel:IsShown() and send:IsEnabled() and invite:IsEnabled(), "solo player not selected")
send:Click()
invite:Click()
assert(stub.whisper == "Thessa" and stub.invited == "Thessa", "whisper or invite")
rows[8]:Click()
assert(not rows[8].Sel:IsShown() and not send:IsEnabled(), "second click does not unselect")
-- A group: whisper only.
stub.invited = nil
rows[2]:Click()
assert(send:IsEnabled() and not invite:IsEnabled() and invite.psReason:find("whisper a group's leader", 1, true), "group invite: " .. tostring(invite.psReason))
-- In a group, not leading: no invite even for a solo player, no Unlist.
local unlist = f.footerButtons.left[1]
assert(unlist:IsShown() and unlist.Label:GetText() == "Unlist" and unlist:IsEnabled(), "no Unlist while listed")
stub.inGroup = true
rows[8]:Click()
assert(not invite:IsEnabled() and invite.psReason:find("leader or an assistant", 1, true), "invite while not leading")
assert(not f.footerButtons.left[1]:IsShown(), "Unlist while not leading")
stub.assistant = true
rows[8]:Click(); rows[8]:Click()
assert(invite:IsEnabled(), "an assistant can invite")
stub.inGroup, stub.assistant = false, false
-- Right-click: the stock menu, report through the game's dialog.
rows[2]:Click("RightButton")
local texts = {}
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() then texts[#texts + 1] = r.psItem.text end end
assert(table.concat(texts, "/") == "Brannoc/Send Message/Group Invite/Report Group/Report Advertisement", "menu: " .. table.concat(texts, "/"))
assert(PolestarMenu.rows[3].psItem.disabled, "invite offered for a group")
PolestarMenu.rows[4]:Click()
assert(stub.reported and stub.reported[1] == Enum.ReportType.GroupFinderPosting and stub.reported[2] == 2 and stub.reported[3] == "Brannoc", "report")
-- Unlist is the game's window: our secure button over it closes ours and clicks the micro button.
stub.RunScript(f.footerButtons.left[1], "OnEnter")
local g = PolestarUIGroupFinderGame
assert(g and g:IsShown() and g:GetLeft() == f.footerButtons.left[1]:GetLeft(), "no secure button over Unlist")
stub.RunScript(f.footerButtons.left[1], "OnLeave")
-- A heading folds its group.
local head
for _, c in ipairs({ f.Body:GetChildren() }) do
	for _, h in ipairs({ c:GetChildren() }) do if h.psKind == 1 and h:IsShown() then head = h end end
end
head:Click()
assert(rows[8] == nil, "Solo Players did not fold")
-- Ignore level ranges: the CVar, then the client's CVAR_UPDATE resets the pickers (stock ActivityFiltersChanged).
local opt
for _, c in ipairs({ f.TabRow:GetChildren() }) do if c.psIconName == "sliders" then opt = c end end
opt:Click()
PolestarMenu.rows[1]:Click()
assert(GetCVarBool("disableSuggestedLevelActivityFilter"), "option not set")
stub.fire("CVAR_UPDATE", "disableSuggestedLevelActivityFilter")
rows[2]:Click()
stub.assertNoErrors()
