#### Auction House (`AuctionHouseFrame`) — Risk: medium
Forever loads the mainline auction house (`C_AuctionHouse`, commodities and
items), demand-loaded, with Camelot's category data. Opened by the
interaction manager (Auctioneer) and by `GameEvent`
(`AUCTION_HOUSE_SHOW`/`CLOSED`): both are taken (`ns.Interaction`,
`C_AuctionHouse.CloseAuctionHouse`); the stock addon is never loaded while
ours is on.
- **Shell:** 960×680 with sidebar. Subject block: the auctioneer's portrait
  (`SetPortraitTexture(…, "npc")`, as the stock frame's `SetPortraitToUnit`),
  "Auction House", the player's money. Tabs: Buy, Sell, Auctions, Bids (the
  stock Auctions tab's two sub-tabs as tabs of their own). The band's
  subtitle is a count: the results, how many of the item are in the bags,
  the auctions and how many sold, an item's listings, the bids and how many
  are outbid; what a click does is in each row's tooltip.
- **Lists:** every list is the stock table: a header row, the sortable
  columns a click away (the last clicked first, a second click turns it, two
  sorts at most, kept for the account per list as the stock
  `g_auctionHouseSortsBySearchContext`); each row the item's well and name
  (equipment with its required level after it, unless a column shows it), a
  line under it (sellers, bid status; a row with none has its name in the
  middle), then the columns from the right. The
  row tooltip is the stock one: the item's link, a listing's sellers and time
  left, the player's bid status, the high bidder or buyer of the player's own
  (`RequestOwnedAuctionBidderInfo`). Ctrl-click dresses up, shift-click links
  in chat. Long lists ask for their next page within 30 rows of the end
  (`RequestMore*Results`).
- **Buy:** the sidebar is the stock category tree, built as Camelot's
  `Blizzard_AuctionData.lua` builds it (names from the client): a category
  picked opens its subcategories under it, a subcategory its own, indented;
  a click on one on the picked path closes it. Each searches with its item
  class filters. All, Favorites (dimmed with none), and the WoW Token where
  the client shows it (`C_WowTokenUI.ShouldDisplayInAuctionHouse`). The
  shell's search sends on Enter; a link shift-clicked with no chat line open
  fills it. The sliders button holds the stock search options: a level
  range, the client's filter groups (`GetFilterGroups`: usable, upgrades,
  the rarities), kept per character, the glyph lit while one is set, its
  tooltip counting them ("Search options (2 on)"), and Clear filters. Results:
  name, the category's column (required level, slots, skill), available,
  lowest price (red over the player's money), a favorite star; a right-click
  is the stock favorite menu. The window opens on the favorites when there
  are any.
  - A commodity: its listings (unit price, quantity, sellers), how many are
    up, a quantity stepper with unit price and total; a listing clicked
    picks every unit up to its price. Buy is `StartCommoditiesPurchase` then
    `ConfirmCommoditiesPurchase` on the quote in `W.Modal` (Buy off, saying
    why, when the total is over the player's money), its last ten
    seconds counting down in the title (`GetQuoteDurationRemaining`), closed
    and dropped at none left; a quote over 5% dearer is refused.
  - An item: its auctions (current or least bid, buyout, quantity, time
    left; the player's bid green, outbid red). A click buys out, a
    right-click (or no buyout) bids, as the stock bid and buyout frames: the
    highest bidder cannot bid again, a bid at the buyout buys out, one under
    the least is refused. The footer: Back, Refresh, Set/Remove favorite.
  - WoW Token: the market price and Buy (`C_WowTokenPublic.BuyToken`), which
    the game's token dialog confirms; none for sale holds Buy a minute.
    The body says what a token is for (redeemed for game time).
- **Sell:** drop an item on the well, or right-click it in the bags (the
  well's tooltip: the item, or how to put one there). Two
  columns: quantity (only when more than one could go; a commodity starts at
  its stack), duration (kept in the stock `auctionHouseDurationDropdown`
  CVar), deposit; the price (Unit price, or Buyout), an item's starting price
  while Buyout only is off (a buyout at or under it refused), the total.
  The price starts at the stock default, then the best listing (an item's
  cheapest buyout at its level) until the player types one. Post
  (`PostItem`/`PostCommodity`) is disabled with the stock reason under the
  form and in its tooltip (no price, the deposit, the throttle); every
  disabled button says why (`ns.SetEnabled`), the favorite star too; a post the client wants
  confirmed asks (`AUCTION_HOUSE_POST_WARNING`), one it refuses says so
  (`AUCTION_HOUSE_POST_ERROR`). Several items post one by one, their progress
  shown (`AUCTION_MULTISELL_*`), stopped as the window closes (`CancelSell`).
  Under the form, the item's current listings: a click takes a price, a
  silver under shows the stock undercut tip; they stay after a post.
- **Right-click from the bags:** the game's bag code sells to the stock
  window by name (`AuctionHouseFrame:SetPostItem`), never loaded now. A
  button of ours lies over the hovered bag slot while ours is open
  (`ContainerFrameItemButton.EnterButton`, `ns.Overlay`, out of combat and
  never while a spell waits for an item, whose click is the slot's own), for
  an item the auction house takes or any while selling: its right-click puts
  the item on Sell, its left-click and drag pick it up, a modified click is
  the bag button's own `OnModifiedClick`.
- **Auctions:** the player's auctions (`QueryOwnedAuctions`): bid (green
  once someone bid; Incoming when sold), buyout, time left; a click on an
  active one cancels (`CancelAuction`, `W.Modal` naming the fee). The sidebar
  is the stock summary list: all, then each item among them
  (`GetOwnedAuctionType`); an item picked shows all its listings, the
  player's own to cancel, others to buy. Refresh asks again.
- **Bids:** the auctions the player bid on, asked for by the IDs kept per
  character as the stock `g_activeBidAuctionIDs` (`QueryBids`, also as the
  window opens for the outbid marks); outbid ones in red. The sidebar lists
  each item bid on (`GetBidType`). `AUCTION_HOUSE_NEW_BID_RECEIVED` asks again.
- **Left to the game's window:** selling a WoW Token: the stock post calls
  `C_WowTokenUI.StartTokenSell`, whose argument the client accepts only from
  untainted code (`SecretArguments = "AllowedWhenUntainted"`); a token put
  on our well says so. Not carried over, as Forever has no such items: the
  Shadowlands unique-crafted purchase warning (`PURCHASE_AUCTION_UNIQUE`,
  limit category 481) and battle pet links.
- **Taint:** purchases, bids, posts and cancels need a hardware event: only
  from our buttons' clicks, never from a timer or an event.
- **Tests:** `stub_auction.lua` (`C_AuctionHouse` browse, favorites,
  commodity and item listings, a quote with its countdown, owned auctions and
  bids by item, posts and multisells, filters, bag slots, the token; both
  open routes); scenes `auction` (both routes, search, sort headers),
  `auction-categories`, `auction-filters`, `auction-favorites`,
  `auction-commodity`, `auction-item`, `auction-sell`, `auction-sell-list`,
  `auction-bags`, `auction-owned`, `auction-owned-item`, `auction-bids`,
  `auction-links`, `auction-token`. They also check the band's counts,
  the one-line row, the filter count and Clear filters, Post's reason in its
  tooltip, the well's hint and no bag button while targeting.
