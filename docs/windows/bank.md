#### Bank (`BankFrame`) — Risk: medium
Opened by the interaction manager (Banker, CharacterBanker, AccountBanker),
taken as above (`ns.Interaction`, `C_Bank.CloseBankFrame`). Forever loads
Camelot's `BankFrame.lua` over the mainline `BankFrameTemplates`: a bank of
bags (`C_Bank.ShouldUsePlayerBagsInBank`). The Bank and the Warband bank each
have bought bags (`C_Bank.FetchPurchasedBankTabData`, the first the bank
itself) and bag slots to put more in.
- **Shell:** 760×600 with sidebar. Subject block: the bank icon, "Bank", the
  player's money.
- **Sidebar:** a row per viewable bank, "Bank" and "Warband bank" (the stock
  page tabs' icons). A client that reports tabs instead lists each bank's tabs
  under its heading, with "Buy a tab" (the mainline layout).
- **Main column:** title the bank's name; subtitle the free slots, and what
  the Warband bank holds. "Bag slots": a strip of the bank's bag slots past
  its first (`FetchMaxNumBankTabs`): a bag in one shows its tooltip
  (`SetBagItem` on `Characterbanktab`/`Accountbanktab`) and lights its slots
  below (the stock `BagIndicator`); a click or drag picks it up or puts a bag
  in (`C_Container.PickupContainerItem`); a slot not bought is faded, its
  tooltip names the next one's cost and a click buys it (the label says the
  cost too, as the stock "Cost:" beside Purchase). Then an Item Grid of every
  bought bag's slots (36px wells, 4px apart; the stock pages of 88 are one
  scrolling grid): count, quality border, locked faded, quest marks and
  cooldown sweep as `BankPanelItemButtonMixin:Refresh`; the search on the band
  dims what does not match. A bank with nothing bought says what buying gives,
  with Buy and its cost; a locked bank (`FetchBankLockedReason`) says why.
- **Footer:** Clean up (`C_Container.SortBank`, asked first while
  `bankConfirmTabCleanUp` is on, with "Do not ask again"); on Warband
  "Deposit money" / "Withdraw money" (`W.Modal` with a Money Input; off as
  `CanDepositMoney`/`CanWithdrawMoney` say); "Deposit all"
  (`C_Bank.AutoDepositItemsIntoBank`, asked first on Warband).
- **Slots:** drag and left-click pick up and place
  (`C_Container.PickupContainerItem`, not protected); a refundable item placed
  in a Warband slot asks first and goes only if still held
  (`ACCOUNT_BANK_DEPOSIT_NO_REFUND_CONFIRM`); right-click moves the item to the
  bags, which is the protected `UseContainerItem`: a secure button of ours
  over the hovered slot (`ns.Overlay`, type `item`, "bag slot"), out of combat.
  Split with shift-click (`C_Container.SplitContainerItem`, a stepper
  `W.Modal`). Our dialogs close with the bank.
- **Left to the stock code:** tab settings (name, icon, filters, "Assign to")
  open only from a right-click on a stock `BankPanelTab`, which Forever's bank
  of bags never makes; the menu itself (`BankPanel.TabSettingsMenu`) is a child
  of the never-shown `BankFrame` and reads the global `BankPanel`. The bags'
  right-click into the bank is the stock bag button's code: it deposits into
  `BankFrame:GetActiveBankType()` and warns of refunds only while the stock
  bank shows, so with ours it cannot pick the Warband bank or warn.
- **Tests:** `stub_bank.lua` (bags, bag slots, `C_Container` slots, `C_Bank`, the cursor); scenes `bank` (grid, bag slots, overlay type `item` on the hovered slot, none in combat, Clean up), `bank-warband` (money, the refund prompt, the lock), `bank-buy-tab` (bag slots, the first purchase, the tab layout).
