--@ title: Character: Titles
--@ roots: PolestarUICharacter, PolestarUICharacterStats
-- The Titles tab lists None and the known titles by name, the worn one checked; a click wears another.
PolestarUI.Show("character")
local d = PolestarUICharacterStats
local tab
for _, t in ipairs(d.Tabs) do if t:IsShown() and t.Label:GetText() == "Titles" then tab = t end end
assert(tab, "no Titles tab")
tab:Click()
local sf = d.panes.titles.psView
assert(d.panes.titles:IsShown() and not d.panes.stats:IsShown(), "pane not shown")
local names = {}
for _, r in ipairs(sf.rows) do if r:IsShown() then names[#names + 1] = r.Name:GetText() end end
assert(table.concat(names, ",") == "None,Scout,the Explorer,Private" or table.concat(names, ",") == "None,Private,Scout,the Explorer", "titles: " .. table.concat(names, ","))
assert(sf.rows[3].Check:IsShown(), "worn title not checked")
sf.rows[4]:Click()
assert(stub.title == 4 or stub.title == sf.rows[4].psID, "not worn")
