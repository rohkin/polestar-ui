--@ title: Legacy: Reward Track
--@ roots: PolestarUILegacy
--@ stubs: stub_legacy.lua
-- The legacy key opens ours and closes it, never the stock window; the track lists each reward at its points, the next one marked; a level of two rewards lists both in its tooltip.
stub.pressKey("SHIFT-Y")
local f = PolestarUILegacy
assert(f:IsShown() and not LegacySystemFrame:IsShown(), "key")
stub.pressKey("SHIFT-Y")
assert(not f:IsShown(), "no toggle")
PolestarUI.Show("legacy", "track")
local rows = {}
for _, r in ipairs(f.psPages.track.rows) do if r:IsShown() then rows[#rows + 1] = r end end
assert(#rows == 4, "rows: " .. #rows)
assert(rows[1].Mark:IsShown() and not rows[2].Mark:IsShown(), "next reward not marked")
assert(f.psPages.track.Value:GetText() == "3 / 15", "progress: " .. f.psPages.track.Value:GetText())
stub.RunScript(rows[4], "OnEnter")
local all = table.concat(GameTooltip.lines, "/")
assert(all:find("Spectral Bear", 1, true) and all:find("the Enduring", 1, true), "tooltip: " .. all)
