--@ title: Group Finder: Who
--@ roots: PolestarUIGroupFinder
--@ stubs: stub_groupfinder.lua, stub_who.lua
-- The Who page: results come to the UI while it shows (SetWhoToUi, as the stock page) and go back to chat when it is left or closed. Enter or Search sends the query with the stock filters (C_FriendList.SendWho is restricted: the stub refuses it outside a click or key); WHO_LIST_UPDATE draws a card per player, the invite button left off the player's own card. A click whispers, the invite button invites, a right-click opens the game's player menu. The filter menu's sections open in place; an unticked class and a ticked zone go with the next query; a sort asks the client and redraws.
stub.pressKey("SHIFT-I")
local f = PolestarUIGroupFinder
assert(f:IsShown() and stub.whoToUi == true, "Who to UI not on")
local s = f.psWhoSearch
assert(s:IsVisible() and f.TabRow:IsShown(), "no query box on the tab row")
assert(f.psWhoRows[1] == nil, "rows before a search")
-- Enter sends the query (a hardware event).
s:SetText("42-60")
stub.RunScript(s, "OnEnterPressed")
assert(stub.who and stub.who.text == "42-60" and stub.who.origin == Enum.SocialWhoOrigin.Social and #stub.who.filters.classIDs == 0, "Enter did not send")
-- The server answers.
stub.whoResults = stub.whoSample
stub.fire("WHO_LIST_UPDATE")
local rows = f.psWhoRows
assert(rows[5] and rows[5]:IsShown() and rows[1].Name:GetText() == "Aldwyn", "no cards")
assert(rows[1].Sub:GetText():find("Level 60 Human", 1, true) and rows[1].Area:GetText() == "Stormwind City", "card text")
assert(f.Subtitle:GetText():find("5 found", 1, true), "subtitle: " .. tostring(f.Subtitle:GetText()))
-- Names sit on a font family (Polestar's face for Latin, the client's for Cyrillic, Hangul and Chinese): the engine picks the face per glyph, nothing reads the name (secret in combat).
local function onFamily(fs)
	local fam = fs:GetFontObject()
	local by = {}
	for _, m in ipairs(fam and fam.members or {}) do by[m.alphabet] = m.file end
	return fam and stub.fontFamilies[fam.name] == fam and by.roman and by.russian == "Fonts\\FRIZQT___CYR.TTF" and by.korean == "Fonts\\2002.TTF"
end
local was, was5 = stub.whoResults[4].fullName, stub.whoResults[5].fullName
stub.whoResults[4].fullName = "Дарий"
stub.whoResults[5].fullName = "하늘"
stub.fire("WHO_LIST_UPDATE")
assert(onFamily(rows[4].Name) and onFamily(rows[5].Name) and onFamily(rows[1].Name) and rows[4].Name:GetText() == "Дарий", "names not on the font family")
-- A Polestar repaint (skin, font, text size) keeps it there, colour included.
local r, g, b = rows[4].Name:GetTextColor()
Polestar.Theme.Refresh()
local r2, g2, b2 = rows[4].Name:GetTextColor()
assert(onFamily(rows[4].Name) and r == r2 and g == g2 and b == b2, "a repaint took the name off the family")
stub.whoResults[4].fullName = was
stub.whoResults[5].fullName = was5
stub.fire("WHO_LIST_UPDATE")
assert(rows[1].Invite:IsShown() and not rows[3].Invite:IsShown(), "invite on the player's own card")
-- Whisper, invite, the player menu.
stub.RunScript(rows[2], "OnClick", "LeftButton")
assert(stub.told == "Brakka", "click did not whisper")
rows[4].Invite:Click()
assert(stub.invited == "Thessaly", "invite")
stub.RunScript(rows[5], "OnClick", "RightButton")
assert(stub.popup and stub.popup[1] == "Vex" and stub.popup[2] == 1, "no player menu")
-- The filter menu: Class, then untick Mage; Zone, Eastern Kingdoms, tick Elwynn Forest.
local function pick(text)
	for _, r in ipairs(PolestarMenu.rows) do
		if r:IsShown() and r.psItem and r.psItem.text == text then return r:Click() end
	end
	error("no menu item " .. text)
end
f.psWhoFilter:Click()
pick("Class")
pick("Mage")
assert(PolestarMenu:IsShown(), "a pick closed the menu")
pick("Back")
pick("Zone")
pick("Eastern Kingdoms")
pick("Elwynn Forest")
pick("Back")
pick("Back")
pick("Sort")
pick("Level")
assert(stub.whoSort.sorting == "level" and rows[1].Name:GetText() == "Vex", "sort: " .. rows[1].Name:GetText())
Polestar.Widgets.HideMenu()
f.footerButtons.right[1]:Click()
local w = stub.who.filters
assert(#w.classIDs == 1 and w.classIDs[1] == 8 and #w.uiMapIDs == 1 and w.uiMapIDs[1] == 1429, "filters not sent")
-- Leaving the page sends results back to chat; coming back takes them again.
f.railButtons[1]:Click()
assert(stub.whoToUi == false and not s:IsVisible(), "left: Who to UI still on")
f.railButtons[3]:Click()
assert(stub.whoToUi == true, "back: Who to UI off")
f:Hide()
assert(stub.whoToUi == false, "closed: Who to UI still on")
PolestarUI.Show("groupfinder", "who")
stub.assertNoErrors()
