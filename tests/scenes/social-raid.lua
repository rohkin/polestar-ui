--@ title: Social: Raid
--@ roots: PolestarUISocial
--@ stubs: stub_social.lua
-- The stock Raid tab. Out of a raid: what a raid is, and Convert to raid. In one: All assist
-- (the leader's), the role counts, the eight groups two to a row, each player's name in class
-- colour (red dead, faint offline), level and class, the lead / assist mark, the main tank /
-- assist mark, and the ready check's answer in that slot. A hovered player gets our secure
-- button: a click targets, a right-click opens the game's RAID menu, and the leader drags a
-- player onto another (swap) or into a group with room (move). Raid info lists the saved
-- instances with Extend; Ready check and Convert to party end the footer.
stub.raid = false
PolestarUI.Show("social", "raid")
local f = PolestarUISocial
assert(stub.raidInfoAsked, "saved instances not asked for")
assert(f.psEmpty:IsShown() and f.psEmpty:GetText():find("You are not in a raid.", 1, true), "not in a raid")
local fb = f.footerButtons
assert(fb.right[1].Label:GetText() == "Convert to raid", "convert button")
fb.right[1]:Click()
assert(stub.converted == "raid", "convert to raid")
stub.raid = true
stub.fire("GROUP_ROSTER_UPDATE")
assert(not f.psEmpty:IsShown() and f.psRaidBar:IsShown(), "raid page")
assert(f.psRaidBar.Counts:GetText() == "2 Tanks · 4 Healers · 6 Damage", "counts: " .. f.psRaidBar.Counts:GetText())
assert(f.psRaidBar.All:IsEnabled(), "all assist for the leader")
f.psRaidBar.All:SetChecked(true)
stub.RunScript(f.psRaidBar.All, "OnClick")
assert(stub.allAssist == true, "all assist")
assert(not f.psPanel:IsShown(), "friend rows on the raid page")
local function row(name)
	for _, c in ipairs({ f.Body:GetChildren() }) do
		for _, r in ipairs({ c:GetChildren() }) do
			if r:IsShown() and r.psMember and r.psMember.name == name then return r end
		end
	end
end
-- Two groups to a row, as the stock grid: group 2 beside group 1.
local g1, g2 = row("Testchar"), row("Garrick")
local function at(r) local _, _, _, x, y = r:GetParent():GetPoint(1); return x, y end
local x1, y1 = at(g1)
local x2, y2 = at(g2)
assert(y1 == y2 and x2 > x1, "group 2 beside group 1")
assert(row("Testchar").Lead:IsShown() and row("Testchar").Lead.atlas == "friends-icon-raidLead", "leader mark")
assert(row("Aelric").Lead.atlas == "friends-icon-raidAssist" and not row("Brannoc").Lead:IsShown(), "assist mark")
assert(row("Testchar").Mark.atlas == "RaidFrame-Icon-MainTank" and row("Garrick").Mark.atlas == "RaidFrame-Icon-MainAssist", "main tank / assist")
assert(row("Kael").Role:GetText() == "25 Mage", "level and class")
-- A ready check: each answer in the mark's slot.
stub.ready = { raid3 = "ready", raid4 = "notready", raid5 = "waiting" }
stub.fire("READY_CHECK")
assert(row("Brannoc").Mark:IsShown() and row("Brannoc").Mark.texture == "ReadyCheck-Ready" and row("Thessaly").Mark.texture == "ReadyCheck-Waiting", "ready check")
-- The secure button over a hovered player: target on a click, RAID menu on a right-click.
stub.RunScript(row("Kael"), "OnEnter")
local over = PolestarUISocialRaidUnit
assert(over and over:IsShown() and over.attributes.type1 == "target" and over.attributes.unit == "raid10", "target button")
assert(over:GetParent() == UIParent, "secure button on our window")
stub.RunScript(over, "PostClick", "RightButton")
assert(stub.popup[1] == "RAID" and stub.popup[2] == "Kael", "raid menu")
-- Drag Kael onto Hollis: a swap. Then Lorne into group 4 (room): a move.
local hollis = row("Hollis")
hollis.IsMouseOver = function() return true end
stub.RunScript(over, "OnDragStart")
stub.RunScript(over, "OnDragStop")
hollis.IsMouseOver = nil
assert(stub.moved[1] == "swap" and stub.moved[2] == 10 and stub.moved[3] == 7, "swap")
assert(row("Kael").psMember.sub == 2 and row("Hollis").psMember.sub == 3, "swapped at once")
stub.RunScript(row("Lorne"), "OnEnter")
local panel4
-- Group 4's panel: beside group 3's.
local g3 = row("Maelis"):GetParent()
local x3, y3 = at(row("Maelis"))
for _, c in ipairs({ f.Body:GetChildren() }) do
	local p, _, _, x, y = c:GetPoint(1)
	if c ~= g3 and c.psRows == nil and p == "TOPLEFT" and y == y3 and x > x3 and c:GetChildren() then panel4 = c end
end
assert(panel4, "group 4")
panel4.IsMouseOver = function() return true end
stub.RunScript(over, "OnDragStart")
stub.RunScript(over, "OnDragStop")
panel4.IsMouseOver = nil
assert(stub.moved[1] == "set" and stub.moved[2] == 11 and stub.moved[3] == 4, "move: " .. tostring(stub.moved[1]) .. tostring(stub.moved[3]))
-- A plain member cannot drag.
stub.notLeader = true
stub.moved = nil
PolestarUI.Show("social", "raid")
stub.RunScript(row("Lorne"), "OnEnter")
stub.RunScript(over, "OnDragStart")
stub.RunScript(over, "OnDragStop")
assert(stub.moved == nil and not f.psRaidBar.All:IsEnabled(), "member arranged the raid")
assert(f.psRaidBar.All.psReason == "Only the raid leader can set this.", "all assist reason")
stub.notLeader = false
PolestarUI.Show("social", "raid")
-- No drag while a spell waits for its target.
stub.targeting = true
stub.RunScript(row("Kael"), "OnEnter")
hollis = row("Hollis")
hollis.IsMouseOver = function() return true end
stub.RunScript(over, "OnDragStart")
stub.RunScript(over, "OnDragStop")
hollis.IsMouseOver = nil
assert(stub.moved == nil, "dragged while targeting")
stub.targeting = false
-- Footer: Ready check, Convert to party (refused for a raid this size), Raid info.
assert(fb.right[1].Label:GetText() == "Ready check" and fb.right[2].Label:GetText() == "Convert to party", "footer")
fb.right[1]:Click()
assert(stub.readyCheck, "ready check")
assert(not fb.right[2]:IsEnabled(), "convert to party allowed")
-- Raid info: the saved instances, Extend on the locked one.
fb.left[1]:Click()
assert(f.Title:GetText() == "Raid info" and fb.left[1].Label:GetText() == "Groups", "raid info")
local function lrow(name)
	for _, r in ipairs({ f.psPanel:GetChildren() }) do
		if r:IsShown() and r.Name and r.Name:GetText() == name then return r end
	end
end
assert(lrow("Molten Core").Sub:GetText() == "40 Player · Resets in 3 days", "lock: " .. lrow("Molten Core").Sub:GetText())
assert(lrow("Onyxia's Lair").Sub:GetText() == "40 Player · Expired" and lrow("Azuregos"), "expired, world boss")
assert(lrow("Molten Core").Act.Label:GetText() == "Extend", "extend")
lrow("Molten Core").Act:Click()
assert(stub.extended[1] == 1 and stub.extended[2] == true and lrow("Molten Core").Act.Label:GetText() == "Unextend", "extended")
fb.left[1]:Click()
assert(f.Title:GetText() == "Raid" and f.psRaidBar:IsShown(), "back to groups")
assert(f.Subtitle:GetText() == "12 of 40 players", "status: " .. tostring(f.Subtitle:GetText()))
