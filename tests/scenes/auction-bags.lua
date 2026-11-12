--@ title: Auction House: selling from the bags
--@ roots: PolestarUIAuction
--@ stubs: stub_npc.lua, stub_auction.lua
-- Right-click from the bags sells, as the stock bag code does for the stock window: while ours is open, a button of ours lies over the hovered bag slot (ContainerFrameItemButton.EnterButton, out of combat), for an item the auction house takes, or any while selling; its right-click puts the item on the Sell page, its left-click and drag pick it up, a modified click is the bag button's own. Not over an item the auction house refuses on another page, not in combat, and gone once ours closes. Shown last: Whirlwind Axe put on the Sell page from the bags.
local T = Enum.PlayerInteractionType
local linen, axe, bread = stub.bagButton(0, 1), stub.bagButton(0, 2), stub.bagButton(0, 3)
local function hover(b) EventRegistry:TriggerEvent("ContainerFrameItemButton.EnterButton", b) end
hover(linen)
assert(not PolestarUIAuctionBagSlot, "a button over the bags with the auction house closed")
stub.interact(T.Auctioneer)
local f = PolestarUIAuction
hover(bread)
assert(not PolestarUIAuctionBagSlot or not PolestarUIAuctionBagSlot:IsShown(), "over an item the auction house refuses")
hover(linen)
local over = PolestarUIAuctionBagSlot
assert(over and over:IsShown() and over:GetLeft() == linen:GetLeft() and over:GetTop() == linen:GetTop(), "not over the hovered slot")
-- Left-click picks up; a modified click is the bag button's.
stub.RunScript(over, "PostClick", "LeftButton")
assert(stub.picked[1] == 0 and stub.picked[2] == 1, "left-click did not pick up")
stub.keys.shift = true
stub.modified.any = true
stub.RunScript(over, "PostClick", "LeftButton")
assert(stub.bagModified == "LeftButton", "the modified click not the bag's")
stub.keys.shift = false
stub.modified.any = nil
-- Right-click: on the Sell page.
stub.RunScript(over, "PostClick", "RightButton")
assert(tostring(f.Title:GetText()) == "Sell" and tostring(f.psSell.Name:GetText()) == "Linen Cloth", "not put on the Sell page")
-- While selling, any item: the client says why it refuses one.
hover(bread)
assert(over:IsShown(), "not over a refused item while selling")
-- Not in combat.
over:Hide()
stub.inCombat = true
hover(axe)
assert(not over:IsShown(), "placed in combat")
stub.inCombat = false
-- Not while a spell waits for an item: the slot's own click applies it.
stub.targeting = true
hover(axe)
assert(not over:IsShown(), "placed while a spell waits for an item")
stub.targeting = false
-- From Buy, the axe.
f.tabButtons[1]:Click()
hover(axe)
stub.RunScript(over, "PostClick", "RightButton")
assert(tostring(f.psSell.Name:GetText()) == "Whirlwind Axe" and f.psSell:IsShown(), "not from Buy")
-- Closed: gone.
over:Hide()
f:Hide()
hover(linen)
assert(not over:IsShown(), "over the bags after closing")
stub.interact(T.Auctioneer)
hover(axe)
stub.RunScript(over, "PostClick", "RightButton")
