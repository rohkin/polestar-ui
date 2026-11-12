--@ title: Legacy: Challenges, searched
--@ roots: PolestarUILegacy
--@ stubs: stub_legacy.lua
-- The search: every category but Mining comes up empty (dimmed), and Mining\'s challenge unfolds its objectives in two columns.
PolestarUI.Show("legacy", "challenges")
local f = PolestarUILegacy
f.Search:SetText("miner")
stub.RunScript(f.Search, "OnTextChanged")
assert(stub.searched == "miner", "not searched")
stub.fire("ACHIEVEMENT_SEARCH_UPDATED")
local mining
for _, b in ipairs({ f.NavScroll.Child:GetChildren() }) do if b:IsShown() and b.psCat and b.psCat.id == 21 then mining = b end end
assert(mining and mining.psCat.count == 1, "Mining not unfolded by the search, or empty")
mining:Click()
local r = f.psPages.challenges.rows[1]
r:Click()
assert(r.crits[5]:IsShown() and not r.crits[1].Bar:IsShown(), "objectives")
