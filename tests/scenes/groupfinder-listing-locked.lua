--@ title: Group Finder: Listing as a member
--@ roots: PolestarUIGroupFinder
--@ stubs: stub_groupfinder.lua, stub_lfglisting.lua
-- In a group led by someone else the page is read only: the leader's listing by activity group, Post greyed with the stock reason, new player friendly greyed. The group role is the member's own: its menu sets it from the click (UnitSetRole, refused outside one); the role check is the leader's or an assistant's.
stub.lfgGroup = { size = 3, leader = false }
stub.lfgRole = "HEALER"
stub.activeEntry = { activityIDs = { 3, 4, 8 }, newPlayerFriendly = true }
PolestarUI.Show("groupfinder", "listing")
local f = PolestarUIGroupFinder
local function kids(fn)
	local out = {}
	for _, c in ipairs({ f.Body:GetChildren() }) do
		for _, k in ipairs({ c:GetChildren() }) do if k:IsShown() and fn(k) then out[#out + 1] = k end end
	end
	table.sort(out, function(a, b) return select(5, a:GetPoint(1)) > select(5, b:GetPoint(1)) end)
	return out
end
local function button(text) for _, k in ipairs(kids(function(k) return rawget(k, "Label") and k.Label.GetText and tostring(k.Label:GetText()):find(text, 1, true) end)) do return k end end
assert(f.Subtitle:GetText():find("Leader's listing", 1, true), "subtitle: " .. tostring(f.Subtitle:GetText()))
local lines = {}
for _, k in ipairs(kids(function(k) return rawget(k, "Text") and k.Text.GetText and not k.psCat end)) do lines[#lines + 1] = tostring(k.Text:GetText()) end
local text = table.concat(lines, "|")
assert(text == "Your listing:|Any Dungeon|Classic Dungeons (2)|Shadowfang Keep|The Deadmines", "lines: " .. text)
assert(#kids(function(k) return k.psGroup or k.psID end) == 0 and #kids(function(k) return k.psCat end) == 0, "editable view shown")
local post = f.footerButtons.right[1]
assert(post.Label:GetText() == "Update" and not post:IsEnabled() and post.psReason == "Only your group leader can update the listing.", "post: " .. tostring(post.psReason))
assert(not (f.footerButtons.left[1] and f.footerButtons.left[1]:IsShown()), "a member may not unlist")
local npf = button("New Player Friendly")
assert(npf.Check:GetChecked() and not npf.Check:IsEnabled(), "new player friendly")
-- Group role: solo roles hidden, the menu sets the role from the click.
assert(not button("Tank"), "solo roles in a group")
local role = button("Role: Healer")
assert(role, "role button")
assert(not pcall(UnitSetRole, "player", "TANK"), "UnitSetRole ran outside a click")
role:Click()
PolestarMenu.rows[1]:Click()
assert(stub.roleSet == "TANK", "role not set")
local poll = button("Role Check")
assert(not poll:IsEnabled() and poll.psReason, "role check for a member")
-- Promoted to assistant: the role check works.
stub.lfgGroup.assistant = true
stub.fire("PARTY_LEADER_CHANGED")
poll:Click()
assert(stub.rolePoll == 1, "role check")
stub.lfgGroup.assistant = false
stub.fire("PARTY_LEADER_CHANGED")
stub.assertNoErrors()
