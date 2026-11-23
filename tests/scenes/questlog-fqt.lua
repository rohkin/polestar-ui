--@ title: Quest Log: ForeverQuestTint
--@ roots: PolestarUIWorldMap
--@ stubs: stub_worldmap.lua, stub_foreverquesttint.lua
-- With ForeverQuestTint, a quest Forever added (here "Kobold Camp Cleanup": taken out of the original list) shows its marker beside the title in the list, its unfinished objectives in the tint (objectiveTint), and the teal wash on its details; an original Classic quest has none of these.
local R = PolestarUI.FQTData.ranges
for i, r in ipairs(R) do if r[1] == 5 and r[2] == 40 then table.remove(R, i); table.insert(R, i, { 8, 40 }); break end end
assert(PolestarUI.FQTMarked(7) and not PolestarUI.FQTMarked(33) and not PolestarUI.FQTMarked(0) and not PolestarUI.FQTMarked(nil) and PolestarUI.FQTMarked(9999), "lookup")
stub.pressKey("L")
local f = PolestarUIWorldMap
local q = f.psQuests
local d = q.Details
local function row(n) for _, r in ipairs({ q.Scroll.Child:GetChildren() }) do if r:IsShown() and r.psTitle == n then return r end end end
assert(row("Kobold Camp Cleanup").Name:GetText():find("|T", 1, true), "marker on the marked quest")
assert(not row("Wolves Across the Border").Name:GetText():find("|T", 1, true), "no marker on a classic quest")
local g = row("Kobold Camp Cleanup").Goals
local r, gg, b = g:GetTextColor()
assert(math.abs(r - 0.6) < 0.01 and math.abs(gg - 0.9) < 0.01 and math.abs(b - 0.95) < 0.01, "objectives in the tint")
row("Kobold Camp Cleanup"):Click()
assert(d.Glow:IsShown(), "wash on the marked quest")
d.Back:Click()
row("Wolves Across the Border"):Click()
assert(not d.Glow:IsShown(), "no wash on a classic quest")
d.Back:Click()
ForeverQuestTintDB.markerAtStart = true
q.Paint()
assert(row("Kobold Camp Cleanup").Name:GetText():find("^|T"), "marker at the start")
row("Kobold Camp Cleanup"):Click()
assert(d.Glow:IsShown(), "wash again")
