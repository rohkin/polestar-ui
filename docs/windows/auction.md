#### Auction House (`AuctionHouseFrame`) — Risk: medium
Forever loads the mainline auction house (`C_AuctionHouse`, commodities and
items), demand-loaded. Opened by the interaction manager (Auctioneer) and by
`GameEvent` (`AUCTION_HOUSE_SHOW`/`CLOSED`): both are taken
(`ns.Interaction`, `C_AuctionHouse.CloseAuctionHouse`); the stock addon is
never loaded while ours is on.
- **Shell:** 960×680 with sidebar. Subject block: the auction icon, "Auction
  House", the player's money. Tabs: Buy, Sell, Auctions.
- **Buy:** the stock categories (`AuctionCategories`) in the sidebar, the
  shell's search (`C_AuctionHouse.SendBrowseQuery`), filters on the sliders
  button; results as rows (Item Well, name, count, unit price as a Money line,
  time left). A commodity opens its price list and a quantity stepper;
  Buy is `StartCommoditiesPurchase` then `ConfirmCommoditiesPurchase` on the
  quote, an item `PlaceBid` (buyout or bid), confirmed by `W.Modal`.
- **Sell:** drop an item on the well, quantity stepper, unit price (Money
  Input, the stock default from the lowest listing), duration (three choices),
  the deposit as a Money line; Post (`PostItem`/`PostCommodity`).
- **Auctions:** the player's auctions and bids (`GetOwnedAuctions`), Cancel
  (`CancelAuction`, `W.Modal` naming the fee).
- **Taint:** purchases and posts need a hardware event: only from our
  buttons' clicks, never from a timer or an event.
- **Tests:** `stub_auction.lua` (`C_AuctionHouse` browse results, commodity quote, owned auctions; both open routes); scenes `auction` (both routes stopped, the stock addon not loaded), `auction-commodity`, `auction-sell`, `auction-owned`.

