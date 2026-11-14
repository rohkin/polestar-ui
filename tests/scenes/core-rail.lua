--@ title: Core: the slim rail (house style, then the game's looks)
--@ roots: PolestarUITestRail
-- ns.GameRail with { slim = true }: a 48 rail of the stock tab icons only, from the band's line down, each label in its tooltip; the window narrows by what the rail gave up and the main column hangs off its edge (no sidebar), on the compact grid.
local ns, W = PolestarUI, Polestar.Widgets
local f = W.Shell("PolestarUITestRail", { scalePath = "ui.menuScale", rail = true, sidebar = 0, width = 640 + 88, height = 420 })
ns.Plain(f, f.psRail)
ns.Compact(f)
local picked
local items = { { key = "a", label = "Roster", icon = 136243 }, { key = "b", label = "Guild News", icon = 136244 } }
ns.GameRail(f, items, "a", function(k) picked = k end, { slim = true })
W.ShellTitle(f, "Guild", "12 of 40 members online")
W.ShellTabs(f, { { key = "x", label = "Members" }, { key = "y", label = "Ranks" } }, "x", function() end)
ns.Footer(f, {}, {})
W.ShellBody(f, 200)
f:Show()
local b = f.railButtons
assert(f.Rail:GetWidth() == 48 and f.psRail == 48 and f:GetWidth() == 640 + 48, "not a slim rail")
assert(b[1]:GetWidth() == 48 and not b[1].Label:IsShown() and select(5, b[1]:GetPoint(1)) == -60, "rail rows not icon-only from the band's line")
assert(select(2, f.Main:GetPoint(1)) == f and select(4, f.Main:GetPoint(1)) == 1 + 48 and f.BodyWidth == 640 - 2 - 48, "main column not off the rail")
stub.RunScript(b[2], "OnEnter")
assert(GameTooltip.lines[1] == "Guild News", "no label in the tooltip")
b[2]:Click()
assert(picked == "b", "a rail icon did not select")
--@ panel
--@ roots: PolestarUITestRail
local ns, W = PolestarUI, Polestar.Widgets
Polestar.Set("ui.skin", "forever")
local f = W.Shell("PolestarUITestRail", { scalePath = "ui.menuScale", rail = true, sidebar = 0, width = 640 + 88, height = 420 })
ns.Plain(f, f.psRail)
ns.Compact(f)
ns.GameRail(f, { { key = "a", label = "Roster", icon = 136243 }, { key = "b", label = "Guild News", icon = 136244 } }, "b", function() end, { slim = true })
W.ShellTitle(f, "Guild", "12 of 40 members online")
W.ShellTabs(f, { { key = "x", label = "Members" }, { key = "y", label = "Ranks" } }, "x", function() end)
ns.Footer(f, {}, {})
W.ShellBody(f, 200)
f:Show()
assert(f.Rail:GetWidth() == 48 and f:GetWidth() == 640 + 48 and f.TabRow:GetHeight() == 32, "not a slim rail in the game's looks")
