--@ title: Social: Raid
--@ roots: PolestarUISocial
--@ stubs: stub_social.lua
-- The raid's eight groups in two columns, read only: name in class colour, role; no footer.
-- Not in a raid, the page says so and draws no groups.
stub.raid = false
PolestarUI.Show("social", "raid")
local f = PolestarUISocial
assert(f.psEmpty:IsShown() and f.psEmpty:GetText() == "You are not in a raid.", "not in a raid")
stub.raid = true
stub.fire("GROUP_ROSTER_UPDATE")
assert(not f.psEmpty:IsShown() and not f.Footer:IsShown(), "raid page")
local heads = {}
for _, c in ipairs({ f.Body:GetChildren() }) do
	if type(c.Text) == "table" and c.Text:GetText() == "Group 2" then heads[#heads + 1] = c end
end
assert(#heads == 1 and heads[1]:IsShown(), "group heading")
assert(not f.psPanel:IsShown(), "friend rows on the raid page")
