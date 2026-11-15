--@ title: Group Finder: Listing a comment category
--@ roots: PolestarUIGroupFinder
--@ stubs: stub_groupfinder.lua, stub_lfglisting.lua
-- A category whose listing needs a comment (autoChooseActivity: stock shows only its comment box) is posted from the game's window: the comment box is the client's secure one and addon code cannot fill it. The page says so and its one button is the game's window, through a secure button of ours.
PolestarUI.Show("groupfinder", "listing")
local f = PolestarUIGroupFinder
for _, c in ipairs({ f.Body:GetChildren() }) do
	for _, k in ipairs({ c:GetChildren() }) do if k.psCat == 120 and k:IsShown() then k:Click() end end
end
assert(f.Subtitle:GetText():find("1 chosen", 1, true) and f.psListingCat:GetText() == "Custom", "subtitle: " .. tostring(f.Subtitle:GetText()))
local b = f.footerButtons.right[1]
assert(b.Label:GetText() == "Post in game's window" and b.psGame and b:IsEnabled(), "game's window button")
assert(not (f.footerButtons.right[2] and f.footerButtons.right[2]:IsShown()), "a Post of ours")
stub.RunScript(b, "OnEnter")
local g = PolestarUIGroupFinderGame
assert(g and g:IsShown() and g:GetLeft() == b:GetLeft(), "no secure button")
stub.RunScript(b, "OnLeave")
stub.assertNoErrors()
