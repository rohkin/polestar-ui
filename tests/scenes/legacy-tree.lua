--@ title: Legacy: Tree, Adventure
--@ roots: PolestarUILegacy
--@ stubs: stub_legacy.lua
-- The tree: Adventure picked in the sidebar; a click stages a rank (Undo takes it back), Apply waits for the client; a talent behind another says so in its tooltip; the search; with no point left every unlearnt talent greys, as the stock buttons.
PolestarUI.Show("legacy", "tree")
local f = PolestarUILegacy
local v = f.psPages.tree
local function row(n) for _, r in ipairs({ f.NavScroll.Child:GetChildren() }) do if r:IsShown() and r.psIdx and r.Label:GetText() == n then return r end end end
local function node(n) for _, b in ipairs({ v.Grid:GetChildren() }) do if b:IsShown() and b.psName == n then return b end end end
assert(row("Professions") and row("Progression"), "trees")
row("Adventure"):Click()
assert(v.Name:GetText() == "Adventure", "not Adventure")
assert(node("Swift Traveller").Rank:GetText() == "3/5", "ranks")
local foot = f.footerButtons.right
assert(not foot[1]:IsEnabled(), "Apply with nothing staged")
node("Swift Traveller"):Click("LeftButton")
assert(node("Swift Traveller").Rank:GetText() == "4/5" and foot[1]:IsEnabled() and f.Subtitle:GetText():find("not applied"), "staged")
foot[2]:Click()
assert(node("Swift Traveller").Rank:GetText() == "3/5", "undo")
node("Keen Senses"):Click("LeftButton")
foot[1]:Click()
assert(stub.legacyCommitting and f.Subtitle:GetText():find("Applying"), "apply")
node("Keen Senses"):Click("LeftButton")
assert(node("Keen Senses").Rank:GetText() == "1/3", "changed while applying")
stub.finishLegacyCommit()
assert(not f.Subtitle:GetText():find("Applying") and not foot[1]:IsEnabled(), "commit did not end")
stub.RunScript(node("Hidden Road"), "OnEnter")
assert(table.concat(GameTooltip.lines, "/"):find("before it", 1, true), "prerequisite")
GameTooltip:Hide()
f.Search:SetText("keen")
stub.RunScript(f.Search, "OnTextChanged")
assert(f.Subtitle:GetText() == "1 talent matches." and node("Hardy"):GetAlpha() < 1, "search: " .. f.Subtitle:GetText())
f.Search:SetText("")
stub.RunScript(f.Search, "OnTextChanged")
assert(not node("Hardy").Icon.desaturated, "a talent that can take a point is greyed")
stub.treePoints = 4
PolestarUI.Show("legacy", "tree")
assert(node("Hardy").Icon.desaturated and node("Trailblazer").Icon.desaturated and not node("Keen Senses").Icon.desaturated, "no points left, yet an unlearnt talent is in colour")
node("Hardy"):Click("LeftButton")
assert(node("Hardy").Rank:GetText() == "0/5", "spent a point not on hand")
