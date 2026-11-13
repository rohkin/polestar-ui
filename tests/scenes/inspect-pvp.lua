--@ title: Inspect: PvP
--@ roots: PolestarUIInspect
--@ stubs: stub_inspect.lua
-- The PvP tab: the inspected rank and its title, the season, the points to the next rank over the bar, and the honorable kills (GetInspectHonorData), redrawn on INSPECT_HONOR_UPDATE.
InspectUnit("target")
stub.inspectReady("target")
local f = PolestarUIInspect
stub.RunScript(f.railButtons[2], "OnClick")
local v = f.psPages.pvp
assert(v:IsShown() and not f.psPages.gear:IsShown(), "PvP page not shown")
assert(v.Rank:GetText() == "Sergeant · Rank 5", "rank: " .. tostring(v.Rank:GetText()))
assert(v.Points:GetText() == "3400 / 5000" and v.Rows[1].Value:GetText() == "1,287", "points or kills")
local honor = GetInspectHonorData
GetInspectHonorData = function() return 4, 0, 0, 0, 1288, 0, 5, 3400, 5000 end
stub.fire("INSPECT_HONOR_UPDATE")
assert(v.Rows[2].Value:GetText() == "4", "not redrawn on INSPECT_HONOR_UPDATE")
GetInspectHonorData = honor
stub.fire("INSPECT_HONOR_UPDATE")
