#### Mail (`MailFrame`, `OpenMailFrame`) — Risk: low
Opened by the interaction manager (MailInfo), taken as above
(`ns.Interaction`, `CloseMail`; the read emote as the stock show does).
- **Shell:** plain, 760×600, no sidebar. Tabs: Inbox, Send.
- **Inbox:** a row per letter (`GetInboxHeaderInfo`): the package or the
  sender's icon in a well, sender in Label, subject in Small textDim, days
  left at the right (warning under 3), money and COD as Money lines. Click
  opens it in a flyout right of the list (`ns.DockFlyout`): body text,
  attachments as an Item Grid (16), money; Take (`TakeInboxItem`,
  `TakeInboxMoney`), Return, Delete (danger, `W.Modal`); COD asks first
  (`W.Modal` naming the price). Footer: "Open all" (the stock
  `C_Mail.SetOpeningAll` loop, one item per `MAIL_INBOX_UPDATE`).
- **Send:** To (editbox with the stock autocomplete off: our own list from
  friends and guild), Subject, Body (multi-line editbox), 12 attachment wells
  (`ClickSendMailItemButton` takes the cursor item), Money or COD (a toggle
  and a Money Input), the postage as a Money line. Footer: "Send" (primary,
  `SendMail`).
- **Taint:** no protected calls.
- **Tests:** `stub_mail.lua` (inbox headers, attachments, COD); scenes `mail` (inbox), `mail-open` (a letter with attachments and COD), `mail-send`.

