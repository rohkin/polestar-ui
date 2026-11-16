#### Merchant (`MerchantFrame`) — Risk: medium
Polestar export: Restock (`QoL.Restock.Plan`/`Run`) needs a new export from Polestar, which needs a Polestar PR
approved first. The window feature-detects it and ships without the Restock button until
Polestar has it, as the World Map does with `Polestar.MapCanvas.Add`.
Opened by the interaction manager (Merchant), taken as above
(`ns.Interaction`, `CloseMerchant`). Polestar's own merchant features stay
whole: Vendor and Keep (sell junk, repair) run on `MERCHANT_SHOW`, no
frame; Restock hangs its button under `MerchantFrame`, so ours carries it in
the footer instead (Polestar's `QoL.Restock.Plan`/`Run`, its total in the
label; gone when the plan is empty).
- **Shell:** 640×560 on the compact grid (`ns.Compact`), no sidebar. Band:
  "Merchant" or "Buyback", subtitle the vendor's name then how many items
  ("Harlan Bagley · 9 items for sale", "… · 1 of 9 items for sale" while
  searching, "… · 2 items to buy back"); the portrait is gone. Tab row
  (`ns.TopNav`): the tabs Merchant and Buyback (the stock `MerchantFrameTab1/2`),
  at its right the vendor's currencies the player holds
  (`C_MerchantFrame.GetMerchantCurrencies`, each with its tooltip), the
  player's money and, ending the row, the filter: Polestar's dropdown
  (`ns.SearchInFilter`), the search on top (the wares' names, on both tabs),
  then `MENU_MERCHANT_FRAME`'s choices with "Clear filters": lit while it
  hides anything (the visit starts on the class, as the stock show resets it)
  or a search runs, "Search and filter (1 on)" in its tooltip; under the
  `MerchantFilterDisabled` game rule the dropdown holds the search alone.
- **Buy:** every item on one scrolling page (the stock 10 a page is gone):
  two columns of item rows, each an Item Well (36px), the name in Label
  (quality colour, legible; one line, truncated; centred on the well when
  nothing is under it), under it the price as a Money line and each other
  cost (a currency or an item, up to 3) as its count and icon with its own
  tooltip (`SetMerchantCostItem`), danger when not affordable; stack size
  "×5", stock left or "Sold out"; red when unusable (never an heirloom), faded
  when sold out or an heirloom already owned; the quest bang on a ware that
  starts a quest. Click buys one (`BuyMerchantItem`), shift-click asks how
  many (a stepper in `W.Modal`, capped by the money and the cost items held),
  right-click buys a stack, ctrl-click previews, a drag picks it up (never
  one that asks first, nor while a spell waits for its item); tooltip
  `GameTooltip:SetMerchantItem` ending with the clicks and selling as a hint,
  the game's buy cursor. The stock confirms
  become `W.Modal` on the stock rules (`MerchantFrame_ConfirmExtendedItemCost`):
  a high price; a currency; an item above uncommon; a purchase that cannot be
  refunded; a limited currency's remainder; with the specs the item is for.
  Under the wares, the last item sold, to buy back (`MerchantBuyBackItem`).
- **Buyback:** the 12 buyback items, same rows (`BuybackItem`), the game's
  buy-back cursor.
- **Footer:** left: Repair all (`RepairAllItems`, with its cost; guild repair
  when `CanGuildBankRepair`; the stock tooltips: cost, guild funds, what the
  player pays on top), Repair an item (`ShowRepairCursor`, "Stop repairing"
  while `InRepairMode`, off as the window hides), Sell junk
  (`C_MerchantFrame.SellAllJunkItems`, confirmed); right: Restock (Polestar's).
- **Selling:** dropping a cursor item on the window sells it
  (`PickupMerchantItem(0)`, as the stock frame); one still refundable asks
  first, naming what comes back, and is refunded
  (`C_Container.ContainerRefundItemPurchase`, the stock
  `CONFIRM_REFUND_TOKEN_ITEM`). The trade-timer warning
  (`MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL`) stays the stock frame's: it is
  registered at load and shows its popup with the frame hidden.
- **Left to the stock code:** the bags' own buttons check
  `MerchantFrame:IsShown()` (`ContainerFrame.lua`): their junk coin
  (`UpdateJunkItem`) and the refund prompt on a right-click sell
  (`ContainerFrame_GetExtendedPriceString`) show only with the stock window.
  Bringing them back means hooking and drawing on the stock bag buttons, which
  the Replacement Contract forbids; a right-click sell of a refundable item
  sells it without asking.
- **Taint:** no protected calls (`ShowRepairCursor` is not protected).
- **Tests:** `stub_merchant.lua` (interaction manager, `GetMerchantItemInfo`, costs, currencies, buyback, repair, refunds); scenes `merchant` (`RegisterPlayerInteraction` took the type; `MerchantFrame` never shown; closing ours ends the interaction once; the band's subtitle, the search, the filter lit and cleared, no drag while targeting), `merchant-buyback`, `merchant-restock` (Polestar's plan shows in the footer).
