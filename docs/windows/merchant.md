#### Merchant (`MerchantFrame`) — Risk: medium
Opened by the interaction manager (Merchant), taken as above
(`ns.Interaction`, `CloseMerchant`). Polestar's own merchant features stay
whole: Vendor and Keep (sell junk, repair) run on `MERCHANT_SHOW`, no
frame; Restock hangs its button under `MerchantFrame`, so ours carries it in
the footer instead (Polestar's `QoL.Restock.Plan`/`Run`, its total in the
label; gone when the plan is empty).
- **Shell:** plain, 640×600, no sidebar; band: the NPC's name, subtitle "Click
  an item to buy it. Right-click an item in your bags to sell it."
- **Tabs:** Buy, Buyback (`W.ShellTabs`; the stock `MerchantFrameTab1/2`).
- **Buy:** every item on one scrolling page (the stock 10 a page is gone):
  two columns of item rows, each an Item Well (36px), the name in Label
  (quality colour, legible), under it the price as a Money line (or the
  currency's icon and count), stack size "×5" in Number textDim, red icon
  when unusable, desaturated when sold out. Click buys one
  (`BuyMerchantItem`), shift-click asks how many (a stepper in `W.Modal`),
  right-click buys a stack, ctrl-click previews; tooltip
  `GameTooltip:SetMerchantItem`. The stock's high-cost and non-refundable
  confirms become `W.Modal`. The filter (`MENU_MERCHANT_FRAME`) is the
  sliders button on the band, the game's Menu kept.
- **Buyback:** the 12 buyback items, same rows (`BuybackItem`).
- **Footer:** left: Repair all (`RepairAllItems`, with its cost; guild repair
  when `CanGuildBankRepair`), Sell junk (`C_MerchantFrame.SellAllJunkItems`,
  confirmed); right: Restock (Polestar's). Above it, the player's money.
- **Taint:** no protected calls; dropping a cursor item on the window sells it
  (`PickupMerchantItem(0)`, as the stock frame).
- **Tests:** `stub_merchant.lua` (interaction manager, `GetMerchantItemInfo`, buyback, repair cost); scenes `merchant` (`RegisterPlayerInteraction` took the type; `MerchantFrame` never shown; closing ours ends the interaction once), `merchant-buyback`, `merchant-restock` (Polestar's plan shows in the footer).

