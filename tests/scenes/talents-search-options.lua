--@ title: Talents: search options
--@ roots: PolestarUITalents, PolestarMenu
--@ stubs: stub_talents.lua
-- The stock search options on a filter at the end of the search row: "Hide passives" leaves passive talents out of the matches, "Show ranks" shows each match's ranks of the most ("2/3"); the filter is lit while one is on, and "Clear filters" turns them off.
PolestarUI.Show("talents")
local f = PolestarUITalents
local function item(t) for _, r in ipairs({ PolestarMenu:GetChildren() }) do if r:IsShown() and r.Text and r.Text:GetText() == t then return r end end end
f.Search:SetText("i")
stub.RunScript(f.Search, "OnTextChanged")
local all = tonumber(f.Subtitle:GetText():match("%d+"))
f.psFilter:Click()
item("Hide passives"):Click()
local active = tonumber(f.Subtitle:GetText():match("%d+"))
assert(f.psFilter.psActive and active < all, ("passives not left out: %d of %d"):format(active, all))
item("Hide passives"):Click()
item("Show ranks"):Click()
local shown
for _, c in ipairs({ f.Body:GetChildren() }) do
	if c.psInfo and c:IsShown() and c:GetAlpha() == 1 and c.psInfo.currentRank == 0 then shown = c end
end
assert(shown and shown.Chip:IsShown() and shown.Rank:GetText() == "0/" .. shown.psInfo.maxRanks, "no ranks on a match")
f.psFilter:Click()
f.psFilter:Click()
item("Clear filters"):Click()
assert(not f.psFilter.psActive and not shown.Chip:IsShown(), "not cleared")
f.psFilter:Click()
item("Show ranks"):Click()
