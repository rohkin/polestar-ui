--@ title: Group Finder: Listing listed
--@ roots: PolestarUIGroupFinder
--@ stubs: stub_groupfinder.lua, stub_lfglisting.lua
-- Posting from the click lists the group (CreateListing with the activities, playstyle, voice mode and new player friendly; the client refuses it outside a click). Listed, the page shows the listing up: "Edit Listing" on the rail, Update greyed until something changes, no Categories. Update copies the listing into the client's creation fields before UpdateListing, so the comment the game's window gave it stays. Unlist is the game's window: a secure button of ours over it closes ours and clicks the micro button (RemoveListing is protected). Each post goes on to Browse with what was posted picked (as stock's LFGParentFrame_SearchActiveEntry) but not searched: the listing call spends the click's hardware event, so the client would block a Search in it; Browse asks for Refresh, whose click searches. Taken down there, what was chosen can be listed again.
PolestarUI.Show("groupfinder", "listing")
local f = PolestarUIGroupFinder
local function kids(fn)
	local out = {}
	for _, c in ipairs({ f.Body:GetChildren() }) do
		for _, k in ipairs({ c:GetChildren() }) do if k:IsShown() and fn(k) then out[#out + 1] = k end end
	end
	table.sort(out, function(a, b) return select(5, a:GetPoint(1)) > select(5, b:GetPoint(1)) end)
	return out
end
local function find(name) for _, r in ipairs(kids(function(k) return k.psGroup or k.psID end)) do if r.Name:GetText() == name then return r end end end
local function button(text) for _, k in ipairs(kids(function(k) return rawget(k, "Label") and k.Label.GetText and tostring(k.Label:GetText()):find(text, 1, true) end)) do return k end end
kids(function(k) return k.psCat == 2 end)[1]:Click()
button("playstyle"):Click()
PolestarMenu.rows[3]:Click()
button("Voice Chat"):Click()
PolestarMenu.rows[2]:Click()
assert(button("Voice Chat: Discord"), "voice mode")
find("The Deadmines"):Click()
find("Shadowfang Keep"):Click()
local post = f.footerButtons.right[1]
assert(post:IsEnabled(), "post greyed: " .. tostring(post.psReason))
post:Click()
local l = stub.listing
assert(l and not l.update and #l.activityIDs == 2 and l.activityIDs[1] == 3 and l.activityIDs[2] == 4, "not listed")
assert(l.generalPlaystyle == 3 and l.voiceMode == 1 and l.newPlayerFriendly == false, "listing fields")
assert(stub.cvars.voiceProvider == "1", "voice provider not set")
assert(PolestarUIDB.groupFinderPage == "browse" and not stub.searched, "post: not on Browse, or searched in the spent click")
assert(f.Subtitle:GetText():find("Listed", 1, true), "post: Browse not waiting for Refresh: " .. tostring(f.Subtitle:GetText()))
local function refresh() for _, k in ipairs({ f.TabRow:GetChildren() }) do if k.psIconName == "reload" and k:IsShown() then return k end end end
refresh():Click()
assert(stub.searched and stub.searched.category == 2 and #stub.searched.activityIDs == 2, "Refresh did not search the listing")
stub.fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
PolestarUI.Show("groupfinder", "listing")
-- Listed (the client's event redraws the rail).
stub.fire("LFG_LIST_ACTIVE_ENTRY_UPDATE", true)
assert(f.railButtons[1].psTip == "Edit Listing", "rail label")
assert(f.Subtitle:GetText():find("Listed: 2", 1, true), "subtitle: " .. tostring(f.Subtitle:GetText()))
assert(post.Label:GetText() == "Update" and not post:IsEnabled() and post.psReason == "Change something to update the listing.", "update: " .. tostring(post.psReason))
local function back() for _, k in ipairs({ f.TabRow:GetChildren() }) do if rawget(k, "Label") and k:IsShown() and k.Label:GetText() == "Categories" then return k end end end
assert(not back(), "Categories while listed")
local unlist = f.footerButtons.left[1]
assert(unlist:IsShown() and unlist.Label:GetText() == "Unlist" and unlist.psGame and unlist:IsEnabled(), "unlist")
-- A change, then Update: the copy first.
find("Wailing Caverns"):Click()
assert(post:IsEnabled(), "update greyed after a change")
assert(stub.copied == 0, "copied before the click")
post:Click()
assert(stub.listing.update and #stub.listing.activityIDs == 3 and stub.copied == 1 and stub.copiedListing == l, "update did not copy first")
assert(PolestarUIDB.groupFinderPage == "browse" and #stub.searched.activityIDs == 2, "update: not on Browse, or searched in the spent click")
refresh():Click()
assert(#stub.searched.activityIDs == 3, "Refresh did not search the updated listing")
stub.fire("LFG_LIST_SEARCH_RESULTS_RECEIVED")
PolestarUI.Show("groupfinder", "listing")
assert(not post:IsEnabled(), "still dirty")
-- Nothing ticked: Update greyed, Unlist is the way.
for _, n in ipairs({ "The Deadmines", "Shadowfang Keep", "Wailing Caverns" }) do find(n):Click() end
assert(not post:IsEnabled() and post.psReason:find("Unlist", 1, true), "empty update: " .. tostring(post.psReason))
find("The Deadmines"):Click()
-- Unlist: the game's window (the client's secure click: PreClick, then the macro's click).
stub.RunScript(unlist, "OnEnter")
local g = PolestarUIGroupFinderGame
assert(g:IsShown() and g:GetLeft() == unlist:GetLeft(), "no secure button over Unlist")
assert(not pcall(C_LFGList.RemoveListing), "RemoveListing allowed")
stub.RunScript(g, "PreClick", "LeftButton", false)
LFDMicroButton:Click()
assert(not f:IsShown() and LFGParentFrame:IsShown(), "the game's window did not open")
UIParent.Hide(LFGParentFrame)
-- Taken down there: what is chosen can be listed again.
stub.activeEntry = nil
stub.fire("LFG_LIST_ACTIVE_ENTRY_UPDATE")
PolestarUI.Show("groupfinder", "listing")
assert(post.Label:GetText() == "List Self" and post:IsEnabled(), "relist: " .. tostring(post.psReason))
assert(back() and not (f.footerButtons.left[1] and f.footerButtons.left[1]:IsShown()), "unlisted footer")
-- Listed again for the picture.
post:Click()
PolestarUI.Show("groupfinder", "listing")
stub.assertNoErrors()
