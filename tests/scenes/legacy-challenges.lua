--@ title: Legacy: Challenges
--@ roots: PolestarUILegacy
--@ stubs: stub_legacy.lua
-- The achievements key opens Challenges on the class's category; the categories fold under their groups at any depth, in the client’s order with children named first (the class one open), only those the client shows, no icons; a click unfolds a challenge's objectives, shift-click links it (chat open) or tracks it; the filter menu at the search hides the incomplete ones (one earned on another character among them).
stub.pressKey("Y")
local f = PolestarUILegacy
assert(f:IsShown() and not LegacySystemFrame:IsShown(), "key")
assert(f.Title:GetText() == "Warrior", "not the class category: " .. f.Title:GetText())
local v = f.psPages.challenges
local function shown() local t = {} for _, r in ipairs(v.rows) do if r:IsShown() then t[#t + 1] = r end end return t end
assert(#shown() == 3, "rows")
assert(shown()[1].Name.wrap == false, "challenge names never wrap") -- the preview stub keeps SetWordWrap as .wrap
local function cat(n) for _, b in ipairs({ f.NavScroll.Child:GetChildren() }) do if b:IsShown() and b.psCat and b.psCat.name == n then return b end end end
local dw = cat("Warrior")
assert(select(2, dw.Dot:GetPoint(1)) == dw and select(2, cat("Classes").Dot:GetPoint(1)) == cat("Classes"), "the unviewed dot in a fixed slot, not on the count")
local groups, kids = 0, {}
for _, b in ipairs({ f.NavScroll.Child:GetChildren() }) do if b:IsShown() and b.psCat then if b.psGroup then groups = groups + 1 elseif b.psGroup == nil then kids[#kids + 1] = b.psCat.name end end end
assert(groups == 3 and #kids == 2 and cat("Dungeons"), "groups " .. groups .. ", unfolded " .. table.concat(kids, ","))
assert(not cat("Season Journey"), "a category the client does not show")
assert(cat("Classes").psCat.count == 4 and cat("Druid").psCat.parent, "child named before its parent taken as a top category")
cat("Adventure"):Click()
cat("Explorer"):Click()
assert(cat("Eastern Kingdoms") and cat("Adventure").psCat.count == 1, "third level")
assert(f.Title:GetText() == "Warrior", "a group with no challenges of its own was opened")
for _, b in ipairs(f.navButtons) do assert(not b:IsShown(), "a shell nav row shows") end
stub.modified.CHATLINK, stub.modified.QUESTWATCHTOGGLE = true, true
stub.chatOpen = true
shown()[2]:Click()
assert(stub.linked == "[Experienced Warrior]" and not stub.tracked[902], "link")
stub.chatOpen = false
shown()[2]:Click()
assert(stub.tracked[902], "track")
stub.modified = {}
local function item(t) for _, r in ipairs({ PolestarMenu:GetChildren() }) do if r:IsShown() and r.Text and r.Text:GetText() == t then return r end end end
assert(not f.TabRow:IsShown(), "the filters still on a tab row")
stub.RunScript(f.psFilter, "OnClick")
item("Incomplete"):Click()
assert(PolestarMenu:IsShown() and #shown() == 1, "completed only: " .. #shown())
item("Incomplete"):Click()
PolestarMenu:Hide()
shown()[2]:Click()
assert(shown()[2].crits[1]:IsShown() and shown()[2].crits[1].Bar:IsShown(), "objectives")
