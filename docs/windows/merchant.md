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
- **Shell:** plain, 640×600, no sidebar; band: the NPC's name, subtitle "Click
  an item to buy it. Right-click an item in your bags to sell it."
- **Tabs:** Buy, Buyback (`W.ShellTabs`; the stock `MerchantFrameTab1/2`). By
  the tabs: the vendor's currencies the player holds
  (`C_MerchantFrame.GetMerchantCurrencies`, each with its tooltip), then the
  money.
- **Buy:** every item on one scrolling page (the stock 10 a page is gone):
  two columns of item rows, each an Item Well (36px), the name in Label
  (quality colour, legible), under it the price as a Money line and each other
  cost (a currency or an item, up to 3) as its count and icon with its own
  tooltip (`SetMerchantCostItem`), danger when not affordable; stack size
  "×5", stock left or "Sold out"; red when unusable (never an heirloom), faded
  when sold out or an heirloom already owned; the quest bang on a ware that
  starts a quest. Click buys one (`BuyMerchantItem`), shift-click asks how
  many (a stepper in `W.Modal`, capped by the money and the cost items held),
  right-click buys a stack, ctrl-click previews; tooltip
  `GameTooltip:SetMerchantItem`, the game's buy cursor. The stock confirms
  become `W.Modal` on the stock rules (`MerchantFrame_ConfirmExtendedItemCost`):
  a high price; a currency; an item above uncommon; a purchase that cannot be
  refunded; a limited currency's remainder; with the specs the item is for.
  Under the wares, the last item sold, to buy back (`MerchantBuyBackItem`).
  The filter (`MENU_MERCHANT_FRAME`) is the sliders button on the band, the
  game's Menu kept, gone under the `MerchantFilterDisabled` game rule.
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
- **Tests:** `stub_merchant.lua` (interaction manager, `GetMerchantItemInfo`, costs, currencies, buyback, repair, refunds); scenes `merchant` (`RegisterPlayerInteraction` took the type; `MerchantFrame` never shown; closing ours ends the interaction once), `merchant-buyback`, `merchant-restock` (Polestar's plan shows in the footer).
