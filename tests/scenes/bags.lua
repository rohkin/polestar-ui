--@ title: Bags
--@ roots: PolestarUIBags
--@ stubs: stub_bags.lua
-- B opens ours and closes it, running no stock toggle (docs/CLIENT.md, rule 8). One grid of every bag (backpack and bags, then the reagent bag, then the keyring), each slot the stock ContainerFrameItemButtonTemplate made by us: its bag is its holder's ID (no bagID key written), so a right-click uses the item and a left-click picks it up through the template's own script. The equipped bags and the money on the first row, "Name · n of m free." under the title, the search on the tab row, Clean up in the footer. A new item wears a pulsing accent edge; hover clears it, closing ours clears them all. Shown last: open again, a cooldown, a quest item and its bang, a locked stack.
local function well(bag, slot)
	for i = 1, 200 do
		local w = _G["PolestarUIBagsItem" .. i]
		if not w then return end
		if w.psBag == bag and w.psSlot == slot then return w end
	end
end
stub.pressKey("B")
local f = PolestarUIBags
assert(f and f:IsShown(), "B did not open ours")
assert(not stub.stockShown.ContainerFrameCombinedBags and not stub.stockOpener(), "a stock toggle ran")
stub.pressKey("B")
assert(not f:IsShown(), "B did not close ours")
stub.pressKey("B")
local w = well(0, 1)
assert(w.template == "ContainerFrameItemButtonTemplate" and w:GetParent():GetID() == 0 and w:GetID() == 1 and rawget(w, "bagID") == nil, "not the template, its bag from the parent")
assert(#w.points == 1 and w.points[1].point == "TOPLEFT", "the template's own anchor kept")
assert(well(-2, 1) and well(5, 6) and well(4, 12), "a bag missing from the grid")
-- The template's script uses and picks up.
stub.mouseClick(w, {}, "RightButton")
assert(stub.used[1] and stub.used[1][1] == 0 and stub.used[1][2] == 1, "right-click did not use the item")
stub.mouseClick(well(1, 1), {}, "LeftButton")
assert(stub.picked and stub.picked[1] == 1 and stub.picked[2] == 1, "left-click did not pick up")
-- New items glow until hovered; closing clears them all (the first close did).
stub.newItems["0:2"], stub.newItems["1:5"] = true, true
stub.fire("BAG_NEW_ITEMS_UPDATED")
local new, other = well(0, 2), well(1, 5)
assert(new.psNew:IsShown() and other.psNew:IsShown(), "a new item does not glow")
stub.RunScript(new, "OnEnter")
assert(not new.psNew:IsShown() and not stub.newItems["0:2"], "hover left it new")
f:Hide()
assert(not stub.newItems["1:5"], "closing left it new")
-- The search dims misses; closing ours ends it.
stub.pressKey("B")
f.Search:SetText("x")
assert(stub.search == "x", "search not the client's")
stub.fire("INVENTORY_SEARCH_UPDATE")
assert(well(0, 1):GetAlpha() == 0.25, "a miss not dimmed")
f:Hide()
assert(stub.search == "", "search left on")
-- Clean up sorts.
stub.pressKey("B")
f.footerButtons.left[1]:Click()
assert(stub.sortedBags == 1, "Clean up did not sort")
assert(tostring(f.Subtitle:GetText()):match("· 57 of 70 free%.$"), "subtitle: " .. tostring(f.Subtitle:GetText()))
assert(not other.psNew:IsShown(), "a cleared item glows again")
