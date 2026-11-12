--@ title: Mail
--@ roots: PolestarUIMail
--@ stubs: stub_npc.lua, stub_mail.lua
-- The mailbox opens ours, never the stock window, with the bags, the read emote and the inbox fetched; closing ours ends the interaction once, the game ending it closes ours. A row per letter: the package or the stationery, read letters faded, unread letters bright, read ones faded, days left (warning under 3, danger in hours under a day), the first item's quality on the well, a tooltip naming the item, the money or COD and when the letter goes; shift-click takes all of a letter (never a COD's) and opens it, money and COD lines. Open all takes one money or item per MAIL_INBOX_UPDATE, never a COD's or a GM's, and stops when none is left.
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
assert(tostring(rows[3].Sender:GetText()) == "Garrosh" and tostring(rows[3].Days:GetText()) == "9 hours", "sender and days")
assert(rows[3].COD:IsShown() and tostring(rows[3].Money.psParts[1].text:GetText()) == "25", "the COD line")
assert(rows[1].Money:IsShown() and not rows[1].COD:IsShown() and not rows[2].Money:IsShown(), "money lines")
assert(rows[4].Well.Icon.desaturated and not rows[1].Well.Icon.desaturated, "read letters fade")
local function is(t, token) local r, g, b = t:GetTextColor(); local tr, tg, tb = Polestar.Theme.Color(token); return r == tr and g == tg and b == tb end
assert(is(rows[4].Sender, "textDim") and is(rows[4].Subject, "textMuted") and is(rows[1].Sender, "text"), "read and unread text")
assert(is(rows[3].Days, "danger") and is(rows[2].Days, "warning"), "days colours")
stub.RunScript(rows[3], "OnEnter")
local tip = table.concat(GameTooltip.lines, "|")
assert(tip:find("Multiple items %(3%)") and tip:find("COD: 25g") and tip:find("Returned in 9 hours"), "row tooltip: " .. tip)
stub.RunScript(rows[1], "OnEnter")
tip = table.concat(GameTooltip.lines, "|")
assert(tip:find("Enclosed money: 4g 87s 50c") and tip:find("Deleted in 29 days") and tip:find("Shift%-click"), "row tooltip: " .. tip)
GameTooltip:Hide()

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

-- Shift-click takes a letter whole and opens it; a COD's is only opened.
stub.keys.shift = true
rows[3]:Click()
assert(#stub.taken == 3 and PolestarUIMailLetter:IsShown(), "a COD letter auto-looted")
assert(rows[3].Sel:IsShown() and not rows[1].Sel:IsShown(), "the open letter's row not marked")
rows[4]:Click()
stub.keys.shift = false
assert(stub.taken[4][1] == 4 and stub.taken[4][2] == "all", "shift-click did not take all")
PolestarUIMailLetter.Close:Click()
assert(not rows[4].Sel:IsShown(), "closed, still marked")
