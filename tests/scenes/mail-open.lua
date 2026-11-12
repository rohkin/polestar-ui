--@ title: Mail: a letter with attachments and COD
--@ roots: PolestarUIMail, PolestarUIMailLetter
--@ stubs: stub_npc.lua, stub_mail.lua
-- A click opens the letter in a flyout right of the list (the dock counts it): its text, its attachments in an item grid, its COD in danger. Taking an item or all of a COD letter asks first, naming the price; cancelled, nothing is taken; paid, Take empties the letter one item per MAIL_INBOX_UPDATE. A COD the player cannot pay says so and takes nothing. A letter with text offers a copy of itself first in the grid; its money is a well of its own. A letter a player sent is returned, not deleted; one that still holds money or items is deleted only after a danger dialog naming them, an empty one at once; closing a letter whose copy was taken and that holds nothing more deletes it. Reply (not to a GM) opens Send with the sender and "RE: subject", sends as a reply, and goes back to the inbox once sent. The game closing a letter closes its flyout.
local T = Enum.PlayerInteractionType
stub.interact(T.MailInfo)
local f, L = PolestarUIMail, PolestarUIMailLetter
local rows = { f.psInbox:GetChildren() }
assert(not L:IsShown(), "a letter open at the start")

-- Reply to Thrall: Send with his name and "RE:", sent as a reply to his letter.
rows[4]:Click()
assert(not L.Reply:IsEnabled(), "a GM's letter can be answered")
rows[2]:Click()
assert(L.Reply:IsEnabled(), "Reply off")
L.Reply:Click()
local send = PolestarUIMail.tabButtons[2] and select(2, f.Body:GetChildren())
assert(tostring(f.Title:GetText()) == "Send mail" and not L:IsShown(), "Reply did not open Send")
assert(tostring(send.To:GetText()) == "Thrall" and tostring(send.Subject:GetText()) == "RE: Supplies for the front", "not filled")
send.Body:SetText("On my way.")
f.footerButtons.right[1]:Click()
assert(stub.sent.replyID == 2 and stub.sent.to == "Thrall", "not sent as a reply")
stub.fire("MAIL_SEND_SUCCESS")
assert(tostring(f.Title:GetText()) == "Inbox", "not back on the inbox")

-- Thrall's letter goes back to him; the next opens in its place.
rows[2]:Click()
assert(L:IsShown() and tostring(L.Sender:GetText()) == "Thrall" and stub.inbox[2][8], "not opened, or not marked read")
assert(tostring(L.Discard.Label:GetText()) == "Return", "a player's letter is returned")
L.Discard:Click()
assert(stub.returned[1] == "Thrall" and not L:IsShown(), "not returned")

-- The Auction House's letter can go: it holds money, so a danger dialog asks first.
f.psInbox:GetChildren():Click()
assert(tostring(L.Discard.Label:GetText()) == "Delete", "not deletable")
local mw = L.Grid:GetChildren()
assert(mw:IsShown() and mw.psAttachment == "money", "no money well")
L.Discard:Click()
assert(PolestarModal:IsShown() and PolestarModal.Box.Action.psDanger and #stub.deleted == 0, "no danger dialog")
assert(tostring(PolestarModal.Box.Text:GetText()) == "It still holds 4g 87s 50c.", "the dialog does not name the money")
PolestarModal.Box.Action:Click()
assert(stub.deleted[1] == "Auction House" and not L:IsShown(), "not deleted")

-- Garrosh's COD letter (now the first).
f.psInbox:GetChildren():Click()
local wells = { L.Grid:GetChildren() }
assert(tostring(L.Sender:GetText()) == "Garrosh" and tostring(L.MoneyLabel:GetText()) == "COD", "the COD letter")
assert(wells[1].psAttachment == "letter" and wells[4]:IsShown() and wells[4].psAttachment == 5 and not (wells[5] and wells[5]:IsShown()), "the copy and its three attachments")
assert(select(2, wells[4].Icon:GetVertexColor()) < 1 and select(2, wells[2].Icon:GetVertexColor()) == 1, "an unusable item not red")
-- Short of money: the game's alert, nothing taken.
local purse = stub.money
stub.money = 1000
wells[3]:Click()
assert(PolestarModal:IsShown() and tostring(PolestarModal.Box.Title:GetText()) == "Not enough money" and #stub.taken == 0, "no COD alert")
PolestarModal.Box.Action:Click()
assert(#stub.taken == 0, "taken without the money")
stub.money = purse
wells[3]:Click()
assert(PolestarModal:IsShown() and #stub.taken == 0, "an item taken before the COD was asked")
local price
for _, c in ipairs({ PolestarModal.Box:GetChildren() }) do if c.psParts and c:IsShown() then price = tostring(c.psParts[1].text:GetText()) end end
assert(price == "25", "the dialog does not name the price")
PolestarModal.Box.Cancel:Click()
assert(#stub.taken == 0 and not PolestarModal:IsShown(), "cancelled, yet taken")
local money = stub.money
L.Take:Click()
assert(PolestarModal:IsShown() and #stub.taken == 0, "Take did not ask first")
PolestarModal.Box.Action:Click()
assert(#stub.taken == 1 and stub.taken[1][2] == 1 and stub.money == money - 250000, "paid and the first item taken")
stub.fire("MAIL_INBOX_UPDATE")
assert(#stub.taken == 2 and stub.taken[2][2] == 2 and not PolestarModal:IsShown(), "the next item asked again, or not taken")
stub.fire("MAIL_INBOX_UPDATE")
stub.fire("MAIL_INBOX_UPDATE")
assert(#stub.taken == 3 and not L.Take:IsEnabled(), "not emptied, or Take still on")

-- Its copy taken and nothing left, closing it deletes it.
wells[1]:Click()
assert(stub.taken[4][2] == "letter" and stub.inbox[1].textCreated, "the copy not taken")
stub.fire("MAIL_INBOX_UPDATE")
L.Close:Click()
assert(stub.deleted[2] == "Garrosh" and not L:IsShown(), "an emptied letter not deleted on close")

-- The game closes the letter: its flyout goes.
f.psInbox:GetChildren():Click()
stub.fire("CLOSE_INBOX_ITEM", 1)
assert(not L:IsShown(), "the flyout stayed")

-- For the picture: a fresh COD letter, open.
stub.inbox[1] = { 132940, 134939, "Garrosh", "The axe, as agreed", 0, 250000, 0.4, false, false, false,
	"Pay up first. The axe is yours once the gold is mine; it cuts through anything Ashenvale grows.",
	{ [1] = stub.mailItem("Gorehowl Replica", 9000, 132940, 1, 4), [2] = stub.mailItem("Heavy Runecloth Bandage", 14530, 133690, 12, 1),
		[5] = stub.mailItem("Mithril Spurs", 7969, 132331, 1, 2, false) } }
stub.fire("MAIL_INBOX_UPDATE")
f.psInbox:GetChildren():Click()
assert(L:IsShown() and f.psFlyouts[1] == L, "not a dock flyout")
