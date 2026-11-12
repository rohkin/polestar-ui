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
assert(f.Subtitle:GetText() == "3 of 65 legacy points earned", "status line: " .. f.Subtitle:GetText())
assert(f.railButtons[2].psTipLines[1]:find("shared by all your characters", 1, true), "what a page is for, in its rail tooltip")
local rows = {}
for _, r in ipairs(f.psPages.track.rows) do if r:IsShown() then rows[#rows + 1] = r end end
assert(#rows == 4, "rows: " .. #rows)
assert(rows[1].Mark:IsShown() and not rows[2].Mark:IsShown(), "next reward not marked")
assert(select(1, rows[3].Name:GetPoint(1)) == "LEFT" and not rows[3].Desc:IsShown() and select(1, rows[1].Name:GetPoint(1)) == "BOTTOMLEFT", "a name with no description centred")
assert(rows[1].Name.wrap == false, "reward names never wrap") -- the preview stub keeps SetWordWrap as .wrap
assert(f.psPages.track.Value:GetText() == "3 / 15", "progress: " .. f.psPages.track.Value:GetText())
stub.RunScript(rows[4], "OnEnter")
local all = table.concat(GameTooltip.lines, "/")
assert(all:find("Spectral Bear", 1, true) and all:find("the Enduring", 1, true), "tooltip: " .. all)
