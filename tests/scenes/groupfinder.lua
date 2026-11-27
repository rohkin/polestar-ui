--@ title: Group Finder
--@ roots: PolestarUIGroupFinder
--@ stubs: stub_groupfinder.lua
-- The Group Finder key opens ours on Listing and closes it, the Who key on Who, never the stock window; the micro button's overlay opens ours on the last page and hands a shift-click to the micro button from secure code (docs/CLIENT.md, rule 8). The slim rail's labels follow the listing ("Edit Listing" while listed). A footer button marked for the game's window (Listing's "Post with a comment") gets a secure button of ours over it that closes ours and clicks the micro button. Every client call a page makes is feature-detected (this scene loads no page stub). The stub refuses the restricted calls outside a click or key.
stub.pressKey("I")
local f = PolestarUIGroupFinder
assert(f:IsShown() and not LFGParentFrame:IsShown(), "key")
assert(f.Title:GetText() == "Group Finder" and f.Subtitle:GetText():find("^Level %d+ "), "band: " .. tostring(f.Subtitle:GetText()))
assert(f.railButtons[1].psTip == "Create a Listing" and f.railButtons[2].psTip == "Browse Groups" and f.railButtons[3].psTip == "Who", "rail labels")
stub.pressKey("I")
assert(not f:IsShown(), "no toggle")
stub.pressKey("SHIFT-I")
assert(f:IsShown() and PolestarUIDB.groupFinderPage == "who", "Who key")
f:Hide()
stub.advance(0.1)
local o = PolestarUIGroupFinderMicro
assert(o:IsShown() and o:GetAttribute("shift-type1") == "click" and o:GetAttribute("clickbutton") == LFDMicroButton, "no overlay")
assert(select(2, o:GetPoint(1)) ~= LFDMicroButton and o:GetLeft() == LFDMicroButton:GetLeft(), "overlay anchored to the micro button, or not over it")
stub.RunScript(o, "PostClick", "LeftButton")
assert(f:IsShown() and PolestarUIDB.groupFinderPage == "who", "micro: not the last page")
f.railButtons[1]:Click()
assert(PolestarUIDB.groupFinderPage == "listing", "rail click")
-- Listed: the Listing item says "Edit Listing" (the client's event redraws it).
stub.activeEntry = { activityIDs = { 1 } }
stub.fire("LFG_LIST_ACTIVE_ENTRY_UPDATE")
assert(f.railButtons[1].psTip == "Edit Listing", "listed label")
stub.activeEntry = nil
stub.fire("LFG_LIST_ACTIVE_ENTRY_UPDATE")
-- The window's menu points to the game's window.
f.psMenu:Click()
assert(PolestarMenu.rows[1].psItem.text:find("shift-click the Group Finder button", 1, true), "menu")
Polestar.Widgets.HideMenu()
-- The game's window from Listing's comment button (the client's secure click: PreClick, then the macro's click).
local b = f.footerButtons.right[1]
assert(b:IsShown() and b:IsEnabled() and b.psGame and b.Label:GetText():find("comment", 1, true), "no game's window button")
stub.RunScript(b, "OnEnter")
local g = PolestarUIGroupFinderGame
local k = b:GetEffectiveScale() / UIParent:GetEffectiveScale() -- the window draws at the Menu scale
assert(g and g:IsShown() and select(2, g:GetPoint(1)) == UIParent and math.abs(g:GetLeft() - b:GetLeft() * k) < 1e-6 and math.abs(g:GetTop() - b:GetTop() * k) < 1e-6, "no secure button over it")
assert(g:GetAttribute("type1") == "macro" and g:GetAttribute("macrotext") == "/click [nocombat] LFDMicroButton", "it does not click the micro button")
stub.RunScript(g, "PreClick", "LeftButton", false)
LFDMicroButton:Click()
assert(not f:IsShown() and LFGParentFrame:IsShown(), "the game's window did not open in place of ours")
UIParent.Hide(LFGParentFrame)
stub.advance(0.1)
assert(not g:IsShown(), "secure button left up")
-- The hardware guard: refused outside a click, allowed inside one.
assert(not pcall(C_LFGList.Search, 2), "Search ran outside a click")
assert(not pcall(C_FriendList.SendWho, "x"), "SendWho ran outside a click")
local t = CreateFrame("Button", nil, UIParent)
t:SetScript("OnClick", function() C_LFGList.Search(2, 0, 0, nil, false, nil, { 5 }) end)
t:Click()
assert(stub.searched and stub.searched.activityIDs[1] == 5, "Search refused inside a click")
PolestarUI.Show("groupfinder", "browse")
stub.assertNoErrors()
