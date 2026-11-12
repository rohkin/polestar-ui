#### Bank (`BankFrame`) — Risk: medium
Opened by the interaction manager (Banker, CharacterBanker, AccountBanker),
taken as above (`ns.Interaction`, `C_Bank.CloseBankFrame`). Forever's bank is
the mainline tabbed bank (`BankPanel`, `C_Bank`): a Character bank and a
Warband bank, each of bought tabs (`C_Bank.FetchPurchasedBankTabData`).
- **Shell:** 760×600 with sidebar. Subject block: the bank icon, "Bank", the
  player's money.
- **Sidebar:** Character and Warband as headings, their tabs as nav rows (the
  tab's icon and name), then "Buy a tab" (its cost) while one can be bought
  (`C_Bank.PurchaseBankTab` behind `W.Modal`).
- **Main column:** title the tab's name, an Item Grid of the tab's slots
  (up to 98, 36px wells, 4px apart), the stock count and quality border on
  each, search on the band dims what does not match. Footer: "Deposit all"
  (`C_Bank.AutoDepositItemsIntoBank`), and on Warband "Deposit money" /
  "Withdraw money" (`W.Modal` with a Money Input; `C_Bank.DepositMoney`).
  Tab settings (name, icon, filters) stay the stock tab menu's: an Options
  entry says so, until ours has them.
- **Slots:** drag and left-click pick up and place
  (`C_Container.PickupContainerItem`, not protected); right-click moves the
  item to the bags, which is the protected `UseContainerItem`: a secure button
  of ours over the hovered slot (`ns.Overlay`, type `item`, "bag slot"), out of
  combat. Split with shift-drag (`C_Container.SplitContainerItem`, a stepper
  `W.Modal`).
- **Tests:** `stub_bank.lua` (tabs, `C_Container` slots, `C_Bank`); scenes `bank` (grid, overlay type `item` on the hovered slot, none in combat), `bank-warband`, `bank-buy-tab`.

