--@ title: Group Finder: Listing activities
--@ roots: PolestarUIGroupFinder
--@ stubs: stub_groupfinder.lua, stub_lfglisting.lua
-- The activity tree, with level ranges ignored (the tab row): the free activity first, then the groups; a group with nothing at the player's level starts folded, and its heading folds and unfolds it. Names below the player's level recede, above it warn; a saved lockout shows its warning with "2/4 Bosses Defeated". A group's box ticks every activity or clears them, showing a dash while only some are ticked. Post waits for a playstyle and an activity (its reason in the tooltip), then lists from the click only, with the playstyle, voice mode and new player friendly.
PolestarUI.Show("groupfinder", "listing")
local f = PolestarUIGroupFinder
for _, k in ipairs({ f.TabRow:GetChildren() }) do if rawget(k, "Label") and k:IsShown() and k.Label:GetText() == "Ignore level ranges" then k:Click() end end
assert(stub.cvars.disableSuggestedLevelActivityFilter == "1", "level ranges not ignored")
local function kids(fn)
	local out = {}
	for _, c in ipairs({ f.Body:GetChildren() }) do
		for _, k in ipairs({ c:GetChildren() }) do if k:IsShown() and fn(k) then out[#out + 1] = k end end
	end
	table.sort(out, function(a, b) return select(5, a:GetPoint(1)) > select(5, b:GetPoint(1)) end)
	return out
end
local dungeons = kids(function(k) return k.psCat == 2 end)[1]
dungeons:Click()
local function rows() return kids(function(k) return k.psGroup or k.psID end) end
local function find(name) for _, r in ipairs(rows()) do if r.Name:GetText() == name then return r end end end
local list = rows()
-- Free activity, Classic Dungeons (open) with its six, Dungeon Challenges (folded).
local names = {} for i, r in ipairs(list) do names[i] = tostring(r.Name:GetText()) end
assert(list[1].Name:GetText() == "Any Dungeon" and list[2].Name:GetText() == "Classic Dungeons" and #list == 9, "tree: " .. table.concat(names, ", "))
assert(list[9].Name:GetText() == "Dungeon Challenges" and list[9].Chevron:IsShown(), "folded group")
list[9]:Click()
assert(#rows() == 10 and find("Stratholme Challenge"), "unfold")
-- Colours and levels.
local function color(fs) local r, g, b = fs:GetTextColor() return r, g, b end
local tr, tg, tb = Polestar.Theme.Color("textMuted")
local dr, dg, db = Polestar.Theme.Color("danger")
local r1, g1, b1 = color(find("Ragefire Chasm").Name)
assert(r1 == tr and g1 == tg and b1 == tb, "trivial colour")
local r2, g2, b2 = color(find("Scarlet Monastery: Armory").Name)
assert(r2 == dr and g2 == dg and b2 == db, "difficult colour")
assert(find("The Deadmines").Level:GetText() == "17\226\128\14726", "level range")
-- The lockout warning.
local sfk = find("Shadowfang Keep")
assert(sfk.Lock:IsShown() and not find("The Deadmines").Lock:IsShown(), "lock warning")
stub.RunScript(sfk.Lock, "OnEnter")
assert(GameTooltip:IsShown(), "lock tooltip")
stub.RunScript(sfk.Lock, "OnLeave")
-- Post: a playstyle first.
local post = f.footerButtons.right[1]
assert(post.Label:GetText() == "List Self" and not post:IsEnabled() and post.psReason == "Choose a playstyle.", "post: " .. tostring(post.psReason))
local style
for _, k in ipairs(kids(function(k) return rawget(k, "Label") and k.Label.GetText and tostring(k.Label:GetText()):find("playstyle") end)) do style = k end
style:Click()
PolestarMenu.rows[2]:Click()
assert(post.psReason == "Choose an activity.", "reason: " .. tostring(post.psReason))
-- A group's box: all, none; one ticked shows the dash.
local classic = find("Classic Dungeons")
classic.Check:Click()
assert(classic.Check:GetChecked() and find("Wailing Caverns").Check:GetChecked() and post:IsEnabled(), "group ticks all")
classic.Check:Click()
assert(not classic.Check:GetChecked() and not find("Wailing Caverns").Check:GetChecked() and not post:IsEnabled(), "group clears")
find("The Deadmines"):Click()
find("Wailing Caverns").Check:Click()
classic = find("Classic Dungeons")
assert(not classic.Check:GetChecked() and classic.Dash:IsShown(), "partial dash")
assert(f.Subtitle:GetText():find("2 chosen", 1, true), "subtitle")
assert(post:IsEnabled(), "post not enabled")
-- Refused outside a click (the client's hardware rule), listed from the click.
assert(not pcall(C_LFGList.CreateListing, {}), "CreateListing ran outside a click")
assert(stub.listing == nil, "listed already")
stub.assertNoErrors()
