--@ title: Mail
--@ roots: PolestarUIMail
--@ stubs: stub_npc.lua, stub_mail.lua
-- The mailbox opens ours, never the stock window, with the bags, the read emote and the inbox fetched; closing ours ends the interaction once, the game ending it closes ours. A row per letter: the package or the stationery, read letters faded, days left (warning under 3), money and COD lines. Open all takes one money or item per MAIL_INBOX_UPDATE, never a COD's or a GM's, and stops when none is left.
local T = Enum.PlayerInteractionType
local ns = PolestarUI
assert(ns.modules.mail.reloadOff, "switching off does not wait for /reload")

stub.interact(T.MailInfo)
assert(PolestarUIMail:IsShown() and not MailFrame:IsShown(), "the mailbox did not open ours")
assert(stub.bagsOpen and stub.emote == "READ" and stub.checked == 1 and stub.rosterAsked, "bags, emote, inbox, roster")
PolestarUIMail:Hide()
assert(stub.npcClosed.CloseMail == 1 and not stub.bagsOpen and stub.emote == nil, "closing ours did not end the mail once")
stub.interact(T.MailInfo)
stub.endInteraction(T.MailInfo)
assert(not PolestarUIMail:IsShown() and stub.npcClosed.CloseMail == 1, "the game's end")

stub.interact(T.MailInfo)
assert(tostring(PolestarUIMail.Title:GetText()) == "Inbox", "not on the inbox")
local rows = { PolestarUIMail.psInbox:GetChildren() }
assert(#rows == 4, "a row per letter")
assert(tostring(rows[3].Sender:GetText()) == "Garrosh" and tostring(rows[3].Days:GetText()) == "Under a day", "sender and days")
assert(rows[3].COD:IsShown() and tostring(rows[3].Money.psParts[1].text:GetText()) == "25", "the COD line")
assert(rows[1].Money:IsShown() and not rows[1].COD:IsShown() and not rows[2].Money:IsShown(), "money lines")
assert(rows[4].Well.Icon.desaturated and not rows[1].Well.Icon.desaturated, "read letters fade")

-- Open all: the Auction House's money, then Thrall's two items, one per update.
local before = stub.money
PolestarUIMail.footerButtons.left[1]:Click()
assert(stub.openingAll and #stub.taken == 1 and stub.taken[1][2] == "money", "money first")
stub.fire("MAIL_INBOX_UPDATE")
assert(#stub.taken == 2 and stub.taken[2][1] == 2 and stub.taken[2][2] == 1, "then an item")
stub.fire("MAIL_INBOX_UPDATE")
assert(#stub.taken == 3 and stub.taken[3][2] == 3, "then the next")
stub.fire("MAIL_INBOX_UPDATE")
assert(#stub.taken == 3 and not stub.openingAll, "a COD's or a GM's taken, or the loop not stopped")
assert(stub.money == before + 48750, "money")
stub.fire("MAIL_INBOX_UPDATE")
assert(#stub.taken == 3, "taken after the loop stopped")
