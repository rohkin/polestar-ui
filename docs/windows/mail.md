#### Mail (`MailFrame`, `OpenMailFrame`) — Risk: low
Opened by the interaction manager (MailInfo), taken as above
(`ns.Interaction`, `CloseMail`; the read emote as the stock show does).
- **Shell:** plain, 760×600, no sidebar. Tabs: Inbox, Send (no Send for a
  trial account, `GameLimitedMode_IsActive`).
- **Inbox:** a row per letter (`GetInboxHeaderInfo`): the package or the
  sender's icon in a well (the first item's quality border), sender in Label,
  subject in Small; unread letters text and textDim, read ones textDim and
  textMuted with the icon faded; days left at the right (warning under 3,
  danger in hours under a day); money and COD as Money lines. The open
  letter's row has the selection wash and accent bar. Tooltip as
  `InboxFrameItem_OnEnter`: the one item (`SetInboxItem`) or "Multiple items
  (n)", the money or COD, when it is deleted or returned. Shift-click
  (`MAILAUTOLOOTTOGGLE`) takes a letter whole (`AutoLootMailItem`, never a
  COD's) and opens it. Over 50 letters the subtitle says how many wait; room
  made fetches more (`CheckInbox` as often as `C_Mail.CanCheckInbox` allows,
  as `InboxMixin:Update`). The stock 7-a-page paging is one scrolling list.
  Footer: "Open all" (the stock `C_Mail.SetOpeningAll` loop, one money or item
  per `MAIL_INBOX_UPDATE`; "Opening..." and off while it runs; skips GM and
  COD letters and items `MAIL_FAILED` names; stops with the bags full).
- **Open letter:** a flyout right of the list (`ns.DockFlyout`): sender,
  subject, body text; an auction invoice (`GetInboxInvoiceInfo`: sold, won,
  pending with its arrival time) or a crafting order
  (`C_Mail.GetCraftingOrderMailInfo`) as label and amount lines; then an Item
  Grid: the letter's copy (`TakeInboxTextItem`, when takeable and not yet
  taken), its money (`TakeInboxMoney`), its items (`TakeInboxItem`, tooltip
  with the COD). Take (all), Reply (`SendMail` with the reply ID; off for the
  game's letters, oneself and no sender), Return or Delete. COD asks first
  naming the price, or says the money is short (`COD_CONFIRMATION`,
  `COD_ALERT`); Delete asks only while items or money remain (`DELETE_MAIL`,
  `DELETE_MONEY`); closing a letter whose copy was taken and that holds
  nothing more deletes it (not a pending sale's), as the stock `OnHide`.
  Outbid and cancelled auction letters are plain letters with money or items.
- **Send:** To (our own list from friends and guild), Subject, Body (Tab walks
  them, Enter in Subject goes on), 12 attachment wells
  (`ClickSendMailItemButton`; an item dropped on the page takes the first free
  well; `SetSendMailShowing` while the page shows, so the bags' right-click
  attaches), Money or COD (COD needs an item, capped at 10,000 gold with the
  stock error), the postage. The subject follows the first item until the
  player writes one. "Send" is off until To and Subject are filled, and from
  the press until `MAIL_SUCCESS` or `MAIL_FAILED`. A refundable attachment
  (`MAIL_LOCK_SEND_ITEMS`) asks in Polestar's dialog and answers
  `RespondMailLockSendItem`; `MAIL_UNLOCK_SEND_ITEMS` closes it. A reply sent
  goes back to the inbox. Hiding clears the page, as the stock hide.
- **Left to the stock window:** Report spam (`CanComplainInboxItem`): the
  stock `ReportFrame` opened from our code would reach
  `C_ReportSystem.SendReport` tainted, and that call has restrictions. The
  stationery art and the gamepad options menu have no counterpart.
- **Taint:** no protected calls.
- **Tests:** `stub_mail.lua` (inbox headers, attachments, COD, invoices,
  waiting mail, the send lock); scenes `mail` (inbox, Open all, waiting mail,
  shift-click), `mail-open` (a letter with its copy, attachments and COD,
  Reply, Delete and Return), `mail-invoice`, `mail-send`.
