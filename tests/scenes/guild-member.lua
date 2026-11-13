--@ title: Guild: member details
--@ roots: PolestarUIGuild, PolestarUIGuildMember
--@ stubs: stub_guild.lua
-- A click on a member opens the stock detail frame as a flyout: level and class, zone,
-- online; the rank menu with the ranks an officer may set (one needing an authenticator
-- greyed); note and officer note, each edited in a field of 31 letters; Remove behind a
-- confirm, and Group invite only for those in the game. The guild master's rank and the
-- player's own Remove stay out of reach.
PolestarUI.Show("guild", "roster")
local f = PolestarUIGuild
local d = PolestarUIGuildMember
local function row(name)
	for _, r in ipairs({ f.psRoster.Rows:GetChildren() }) do
		if r:IsShown() and r.Cells.name and r.Cells.name:GetText() == name then return r end
	end
end
local function menu()
	local t = {}
	for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() then t[#t + 1] = r.Text:GetText() .. (r.psItem.disabled and "(off)" or "") end end
	return table.concat(t, ",")
end
assert(not d:IsShown(), "details before a click")
stub.RunScript(row("Aelric"), "OnClick", "LeftButton")
assert(d:IsShown() and d.Name:GetText() == "Aelric", "details")
assert(d.Rank:IsShown() and not d.RankPick:IsShown(), "the guild master's rank can be moved")
assert(not d.Remove:IsEnabled(), "an officer can remove the guild master")
stub.RunScript(row("Testchar"), "OnClick", "LeftButton")
assert(not d.Remove:IsEnabled() and d.Remove.psReason:find("Leave", 1, true), "remove yourself")
stub.RunScript(row("Dovaline"), "OnClick", "LeftButton")
assert(not d.Invite:IsEnabled(), "invite someone on the app")
stub.RunScript(row("Brannoc"), "OnClick", "LeftButton")
assert(d.Line:GetText() == "Level 29 Priest" and d.Where:GetText() == "Westfall" and d.Online:GetText() == "Online", "facts")
assert(d.RankPick:IsShown() and d.Note.Text:GetText() == "Healer" and d.Officer.Text:GetText() == "Promote soon", "rank and notes")
d.RankPick:Click()
assert(menu() == "Veteran,Member,Initiate(off)", "rank menu: " .. menu())
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() and r.Text:GetText() == "Member" then r:Click() end end
assert(stub.rankSet and stub.rankSet[1] == "Player-1-3" and stub.rankSet[2] == 4, "rank set")
d.Note.Edit:Click()
assert(PolestarModal:IsShown() and stub.focus:GetText() == "Healer", "note field")
stub.focus:SetText("Raid healer")
PolestarModal.Box.Action:Click()
assert(stub.noteSet[2] == "Raid healer" and stub.noteSet[3] == true, "public note")
d.Officer.Edit:Click()
stub.focus:SetText("Ready")
PolestarModal.Box.Action:Click()
assert(stub.noteSet[2] == "Ready" and stub.noteSet[3] == false, "officer note")
d.Invite:Click()
assert(stub.invited == "Brannoc", "group invite")
d.Remove:Click()
assert(PolestarModal:IsShown() and not stub.removed, "remove without a confirm")
PolestarModal.Box.Action:Click()
assert(stub.removed == "Player-1-3" and not d:IsShown(), "removed")
-- Without officer rights: no rank menu, no officer note, no edits.
stub.noOfficer = true
stub.RunScript(row("Brannoc"), "OnClick", "LeftButton")
assert(not d.RankPick:IsShown() and not d.Officer.Text:IsShown() and not d.Note.Edit:IsShown(), "member rights")
stub.noOfficer = false
PolestarUI.Show("guild")
