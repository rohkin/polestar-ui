--@ title: Group Finder: Listing categories
--@ roots: PolestarUIGroupFinder
--@ stubs: stub_groupfinder.lua, stub_lfglisting.lua
-- The Listing page opens on the category cards: only categories with an activity at the player's level (24: Raids and Battlegrounds go), each a card with the stock art. The solo roles are the client's and saved on each click; new player friendly is the client's CVar. A card opens its activities; "Categories" on the tab row comes back. "Ignore level ranges" on the tab row (the client's CVar) brings every category. The comment door is the game's window.
PolestarUI.Show("groupfinder", "listing")
local f = PolestarUIGroupFinder
assert(not f.Subtitle:GetText():find(" · ", 1, true), "subtitle: " .. tostring(f.Subtitle:GetText()))
local function cards()
	local out = {}
	for _, c in ipairs({ f.Body:GetChildren() }) do
		for _, k in ipairs({ c:GetChildren() }) do if k.psCat and k:IsShown() then out[#out + 1] = k end end
	end
	table.sort(out, function(a, b) return select(5, a:GetPoint(1)) > select(5, b:GetPoint(1)) end)
	return out
end
local list = cards()
assert(#list == 3 and list[1].Name:GetText() == "Dungeons" and list[2].Name:GetText() == "Quests & Zones" and list[3].Name:GetText() == "Custom", "cards: " .. #list)
assert(list[1].Art.atlas == "groupfinder-button-dungeons", "card art")
assert(stub.raidInfoAsked > 0, "lockouts not asked for")
-- Footer: the comment door only (no category yet).
local b = f.footerButtons.right[1]
assert(b:IsShown() and b:IsEnabled() and b.psGame and not (f.footerButtons.right[2] and f.footerButtons.right[2]:IsShown()), "comment door")
-- Roles: dps saved; a click on Tank saves both.
local tank
for _, c in ipairs({ f.Body:GetChildren() }) do
	for _, k in ipairs({ c:GetChildren() }) do if rawget(k, "Label") and k.Label:GetText() == "Tank" then tank = k end end
end
assert(tank and not tank.Check:GetChecked(), "tank role")
tank:Click()
assert(stub.roles and stub.roles.tank and stub.roles.dps and tank.Check:GetChecked(), "role not saved")
-- New player friendly: the CVar.
local npf
for _, c in ipairs({ f.Body:GetChildren() }) do
	for _, k in ipairs({ c:GetChildren() }) do if rawget(k, "Label") and k.Label:GetText() == "New Player Friendly" then npf = k end end
end
assert(npf, "no npf")
npf:Click()
assert(stub.cvars.lfgNewPlayerFriendly == "1" and npf.Check:GetChecked(), "new player friendly")
-- A card opens its activities; Categories comes back.
list[1]:Click()
assert(f.Subtitle:GetText():find("0 chosen", 1, true) and f.psListingCat:IsShown() and f.psListingCat:GetText() == "Dungeons" and f.TabRow:IsShown(), "activities: " .. tostring(f.Subtitle:GetText()))
local back
for _, k in ipairs({ f.TabRow:GetChildren() }) do if rawget(k, "Label") and k:IsShown() and k.Label:GetText() == "Categories" then back = k end end
assert(back, "no Categories on the tab row")
back:Click()
assert(not f.Subtitle:GetText():find(" · ", 1, true) and not back:IsShown() and not f.psListingCat:IsShown(), "back")
-- Ignore level ranges (the tab row's right end): every category.
local levels
for _, k in ipairs({ f.TabRow:GetChildren() }) do if rawget(k, "Label") and k:IsShown() and k.Label:GetText() == "Ignore level ranges" then levels = k end end
assert(levels and not levels.Check:GetChecked(), "no level ranges toggle")
levels:Click()
assert(stub.cvars.disableSuggestedLevelActivityFilter == "1" and levels.Check:GetChecked() and #cards() == 5, "every category: " .. #cards())
levels:Click()
assert(#cards() == 3, "filter back on")
-- The window's menu is the shell's: only the game's-window line.
f.psMenu:Click()
assert(PolestarMenu.rows[1].psItem.text:find("shift-click", 1, true), "menu")
Polestar.Widgets.HideMenu()
-- Another page and back: the tab row is the other page's.
f.railButtons[2]:Click()
f.railButtons[1]:Click()
stub.assertNoErrors()
