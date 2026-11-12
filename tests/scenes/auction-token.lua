--@ title: Auction House: WoW Token
--@ roots: PolestarUIAuction
--@ stubs: stub_npc.lua, stub_auction.lua
-- The stock WoW Token category, listed only where the client shows it (C_WowTokenUI.ShouldDisplayInAuctionHouse): the market price asked for as it opens, and Buy (C_WowTokenPublic.BuyToken from its click) while the player can pay it; the game's token dialog confirms. None for sale says so and holds Buy for a minute. A token put up for sale is the game's window's: ours says so and keeps it off the well. Shown last: the token page, its body saying what a token is for.
local T = Enum.PlayerInteractionType
stub.interact(T.Auctioneer)
local f = PolestarUIAuction
local function nav(label)
	for _, b in ipairs(f.navButtons) do if b:IsShown() and tostring(b.Label:GetText()) == label then return b end end
end
assert(not nav("WoW Token"), "the token listed where the client hides it")
f:Hide()
stub.tokenShown = true
stub.money = 50000000
stub.interact(T.Auctioneer)
nav("WoW Token"):Click()
assert(tostring(f.Title:GetText()) == "WoW Token" and tostring(f.Subtitle:GetText()) == "Market price: 250g 0s 0c", "the market price")
local buy = f.footerButtons.right[1]
assert(buy:IsEnabled(), "Buy not offered")
buy:Click()
assert(stub.tokenBought == 1, "not bought")
-- None for sale: said, Buy held for a minute.
stub.tokenResult = LE_TOKEN_RESULT_ERROR_NONE_FOR_SALE
buy:Click()
assert(PolestarModal:IsShown() and not f.footerButtons.right[1]:IsEnabled(), "none for sale not said, or Buy not held")
PolestarModal.Box.Action:Click()
stub.advance(61)
assert(f.footerButtons.right[1]:IsEnabled(), "Buy held past the minute")
stub.tokenResult = 0
-- Short of money: Buy held.
stub.money = 100
stub.fire("PLAYER_MONEY")
assert(not f.footerButtons.right[1]:IsEnabled(), "Buy with too little money")
stub.money = 50000000
stub.fire("PLAYER_MONEY")
-- A token to sell: the game's window's.
f.tabButtons[2]:Click()
stub.holdItem(122270)
f.psSell.Well:Click("LeftButton")
assert(tostring(f.psSell.Name:GetText()) == "No item" and PolestarModal:IsShown() and tostring(PolestarModal.Box.Text:GetText()):find("game's own", 1, true), "a token taken to sell")
PolestarModal.Box.Action:Click()
ClearCursor()
f.tabButtons[1]:Click()
nav("WoW Token"):Click()
assert(f.psEmpty:IsShown() and tostring(f.psEmpty:GetText()):find("game time", 1, true), "the token page's body empty")
