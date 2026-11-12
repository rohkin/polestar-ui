--@ title: Talents: a point staged
--@ roots: PolestarUITalents
--@ stubs: stub_talents.lua
-- Spending: right-click takes the staged Arcane point back, a click puts it into Frost; Apply and Undo show while something is staged; Apply commits as a cast, the window waiting until it ends; Undo drops what is staged.
PolestarUI.Show("talents")
local f = PolestarUITalents
local function find(test) for _, c in ipairs({ f.Body:GetChildren() }) do if c.psInfo and c:IsShown() and test(c.psInfo) then return c end end end
local function footer() local k = 0
for _, b in ipairs(f.footerButtons.right) do assert(b:IsShown(), "a footer button hidden: the layout would move")
if b:IsEnabled() then k = k + 1 end end
return k end
local function sub() return f.Subtitle:GetText() end
assert(footer() == 2 and sub():find("not applied"), "a staged point: " .. sub())
local function frost() return find(function(n) return n.currentRank == 0 and n.isAvailable and n.meetsEdgeRequirements and n.groupIDs[1] == 1003 end) end
assert(frost().Icon.desaturated, "an open talent with no point to spend is not greyed, as the stock button greys it")
f.footerButtons.right[2]:Click()
assert(footer() == 0 and sub():find("1 point to spend"), "undo: " .. sub())
local function tip(b) stub.RunScript(b, "OnEnter"); return GameTooltip.lines[1] end
assert(tip(f.footerButtons.right[1]) == "Nothing to apply" and tip(f.footerButtons.right[2]) == "Nothing to undo", "no reason on a disabled button")
assert(not frost().Icon.desaturated, "an open talent with a point to spend is greyed")
local open = find(function(n) return n.canPurchaseRank and n.groupIDs[1] == 1003 end)
local id, rank = open.psInfo.ID, open.psInfo.currentRank
local headW = f.psHeads[3]:GetWidth()
open:Click("LeftButton")
assert(f.psHeads[3]:GetWidth() == headW, "the Frost heading moved as its count changed")
assert(find(function(n) return n.ID == id end).psInfo.currentRank == rank + 1 and footer() == 2, "purchase")
find(function(n) return n.ID == id end):Click("RightButton")
assert(footer() == 0 and find(function(n) return n.ID == id end).psInfo.currentRank == rank, "refund")
find(function(n) return n.ID == id end):Click("LeftButton")
f.footerButtons.right[1]:Click()
assert(stub.committing and sub():find("Applying") and footer() == 0, "apply")
find(function(n) return n.canRefundRank end):Click("RightButton")
assert(find(function(n) return n.ID == id end).psInfo.currentRank == rank + 1, "changed while applying")
stub.finishCommit()
assert(sub():find("Every point is spent") and footer() == 0, "commit did not end: " .. sub())
find(function(n) return n.canPurchaseRank or true end)
PolestarUI.Show("talents")
stub.RunScript(find(function(n) return n.ID == id end), "OnEnter")
