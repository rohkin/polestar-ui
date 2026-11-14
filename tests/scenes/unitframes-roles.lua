--@ title: Unit frames: the party's roles, class colours and power strip
--@ roots: PolestarUIPartyFrame1, PolestarUIPartyFrame2, PolestarUIPartyFrame3, PolestarUIPartyFrame4
-- A party of a tank, a healer, a damage dealer and a member with no role: each block wears the game's own role icon top right (where the stock member frame has it; none without a role), the member's class colour as its health fill whatever Polestar's "Class colour" says, and a power strip 6 units thick under a hairline, in the power's colour.
stub.cvars.statusText = "1"
stub.units.party1 = { name = "Brakk", level = 25, class = "WARRIOR", player = true, health = 2100, max = 2600, power = 40, powerMax = 100, powerType = 1, reaction = 5, role = "TANK" }
stub.units.party2 = { name = "Paxton", level = 25, class = "PRIEST", player = true, health = 1500, max = 1800, power = 2000, powerMax = 3000, reaction = 5, role = "HEALER" }
stub.units.party3 = { name = "Thorn", level = 26, class = "ROGUE", player = true, health = 1700, max = 1700, power = 80, powerMax = 100, powerType = 3, reaction = 5, role = "DAMAGER" }
stub.units.party4 = { name = "Aria", level = 24, class = "MAGE", player = true, health = 900, max = 1400, power = 1200, powerMax = 2400, reaction = 5 }
stub.updateParty()
stub.fire("GROUP_ROSTER_UPDATE")
stub.unitWatch()
stub.advance(0.1)
local P = { PolestarUIPartyFrame1, PolestarUIPartyFrame2, PolestarUIPartyFrame3, PolestarUIPartyFrame4 }
assert(P[1].role:IsShown() and P[1].role:GetAtlas() == "roleicon-tiny-tank", "the tank's icon")
assert(P[2].role:GetAtlas() == "roleicon-tiny-healer" and P[3].role:GetAtlas() == "roleicon-tiny-dps", "the healer's and the damage dealer's icons")
assert(not P[4].role:IsShown(), "a member with no role shows an icon")
-- Where the game's own is: 12 units, 5 in from the member frame's top right; the name ends before it.
local point, rel, _, x, y = P[1].role:GetPoint(1)
assert(point == "TOPRIGHT" and rel == P[1] and x == -5 and y == -5 and P[1].role:GetWidth() == 12, "the icon is not where the game's is")
assert(select(2, P[1].Name:GetPoint(2)) == P[1].role, "the name runs under the icon")
-- Class colours, with Polestar's "Class colour" off.
assert(not Polestar.Theme.FollowsClassAccent(), "the scene needs Class colour off")
for i, class in ipairs({ "WARRIOR", "PRIEST", "ROGUE", "MAGE" }) do
	local r, g, b = Polestar.Theme.ClassColor(class)
	local c = P[i].Health.barColor
	assert(c[1] == r and c[2] == g and c[3] == b, class .. " is not in its class colour")
end
-- The power strip: 6 thick under its hairline, the block's size unchanged.
assert(P[2].Power:GetHeight() == 6 and P[2].Sep:IsShown() and P[2]:GetHeight() == PartyFrame.MemberFrame2:GetHeight(), "the power strip")
-- A role changed (PLAYER_ROLES_ASSIGNED), and one the client keeps secret: no icon, no error.
stub.units.party4.role = "HEALER"
stub.units.party3.role = stub.secret("DAMAGER")
stub.fire("PLAYER_ROLES_ASSIGNED")
assert(P[4].role:IsShown() and P[4].role:GetAtlas() == "roleicon-tiny-healer" and not P[3].role:IsShown(), "roles assigned")
stub.units.party4.role, stub.units.party3.role = nil, "DAMAGER"
stub.fire("PLAYER_ROLES_ASSIGNED")
--@ panel
--@ title: Edit Mode's sample party
--@ roots: PolestarUIPartyFrame1, PolestarUIPartyFrame2, PolestarUIPartyFrame3, PolestarUIPartyFrame4
-- Edit Mode's "Party Frames" with no party: ours stand in with the player, as the game's do, each with the player's class colour and role.
stub.units.player = { name = "Testchar", level = 24, class = "WARRIOR", player = true, health = 1830, max = 2400, power = 45, powerMax = 100, powerType = 1, reaction = 5, role = "TANK" }
stub.showPartyInEditMode = true
stub.enterEditMode()
stub.advance(0.1)
local r, g, b = Polestar.Theme.ClassColor("WARRIOR")
for i = 1, 4 do
	local f = _G["PolestarUIPartyFrame" .. i]
	assert(f:IsShown() and f.role:IsShown() and f.role:GetAtlas() == "roleicon-tiny-tank", "the sample party member " .. i .. " has no role icon")
	assert(f.Health.barColor[1] == r and f.Health.barColor[3] == b, "the sample party is not in the player's class colour")
end
