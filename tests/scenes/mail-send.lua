--@ title: Mail: send
--@ roots: PolestarUIMail
--@ stubs: stub_npc.lua, stub_mail.lua
-- The Send page. To completes names as the stock field does (the game's list in its order, your characters first; the rest typed in, highlighted; Tab, arrows, Enter, Escape). The wells take the cursor's item (ClickSendMailItemButton), a right-click takes it back; the postage follows. An item dropped on the page goes in the first free well, and the bags' right-click attaches while the page shows (SetSendMailShowing). The subject follows the first item until the player writes one, and empties when the last goes. Money or COD: the switch picks which the amount is, and needs an item; a COD over 10,000 gold says so. Send is off until To and Subject are filled, and while the server answers; it sets only the money or the COD and calls SendMail; MAIL_SEND_SUCCESS empties the page. A refundable item attached asks first in Polestar's dialog, its answer sent back to the client (RespondMailLockSendItem); the client's unlock closes the dialog. A trial account has no Send page.
local T = Enum.PlayerInteractionType
stub.interact(T.MailInfo)
local f = PolestarUIMail
f.tabButtons[2]:Click()
assert(tostring(f.Title:GetText()) == "Send mail", "not on Send")
local inbox = f.psInbox
local send
for _, c in ipairs({ f.Body:GetChildren() }) do if c ~= inbox then send = c end end
assert(send:IsShown() and not inbox:IsShown(), "the pages did not switch")
assert(stub.sendShowing, "the bags' right-click does not attach")
local sendBtn = f.footerButtons.right[1]
assert(not sendBtn:IsEnabled() and not send.COD:IsEnabled(), "Send or COD on with nothing filled")
assert(sendBtn.psReason == "Enter who to send it to." and send.COD.psTip == "Attach an item to send it cash on delivery.", "off without saying why")
assert(tostring(f.Subtitle:GetText()) == "No attachments.", "the status: " .. tostring(f.Subtitle:GetText()))

-- To: the game's completion (C_AutoComplete, the MAIL flags), in its order:
-- your characters, then friends, then the guild. Typing "a" fills in the
-- first name, the rest highlighted; five rows, the fifth "..." for more.
local to = send.To
local function typeTo(text)
	to:SetText(text)
	stub.RunScript(to, "OnTextChanged", true)
	stub.RunScript(to, "OnChar", text:sub(-1))
end
local function listed()
	local out = {}
	for _, r in ipairs(PolestarUIMailTo.rows) do
		if r:IsShown() then out[#out + 1] = tostring(r.Name:GetText()) .. (r.Tag:GetText() ~= "" and "/" .. tostring(r.Tag:GetText()) or "") end
	end
	return table.concat(out, ",")
end
local function selected()
	for i, r in ipairs(PolestarUIMailTo.rows) do if r.Sel:IsShown() then return i end end
end
to:SetFocus()
typeTo("a")
assert(stub.completeFlags[1] == AUTOCOMPLETE_LIST.MAIL.include and stub.completeFlags[2] == AUTOCOMPLETE_LIST.MAIL.exclude, "not the mail flags")
assert(PolestarUIMailTo:IsShown() and listed() == "Arathel,Aelwyn,Arthas/Friend,Alleria/Friend,...", "the list: " .. listed())
assert(tostring(to:GetText()) == "Arathel" and to.highlight and to.highlight[1] == 1 and to.highlight[2] == 7, "no inline completion")
assert(not PolestarUIMailTo.rows[5]:IsEnabled(), "the ... row picks")
-- Tab and Down go on, Shift-Tab and Up go back, round the four names.
assert(selected() == 1, "the first not selected")
stub.RunScript(to, "OnTabPressed")
assert(selected() == 2 and to:HasFocus(), "Tab did not walk the list")
stub.keys.shift = true
stub.RunScript(to, "OnTabPressed")
stub.keys.shift = false
assert(selected() == 1, "Shift-Tab")
stub.RunScript(to, "OnArrowPressed", "UP")
assert(selected() == 4, "Up did not wrap")
stub.RunScript(to, "OnArrowPressed", "DOWN")
assert(selected() == 1, "Down did not wrap")
stub.RunScript(to, "OnArrowPressed", "DOWN")
-- Enter takes the pick; with no list, Tab and Enter go on to the subject.
stub.RunScript(to, "OnEnterPressed")
assert(tostring(to:GetText()) == "Aelwyn" and not PolestarUIMailTo:IsShown() and to:HasFocus(), "Enter: " .. tostring(to:GetText()))
stub.RunScript(to, "OnTabPressed")
assert(send.Subject:HasFocus(), "Tab did not go on")
-- Backspace lists nothing; Escape closes the list, then leaves the field.
to:SetFocus()
typeTo("al")
assert(listed() == "Alleria/Friend", "al: " .. listed())
stub.RunScript(to, "OnKeyDown", "BACKSPACE")
to:SetText("a")
stub.RunScript(to, "OnTextChanged", true)
stub.RunScript(to, "OnKeyUp", "BACKSPACE")
assert(not PolestarUIMailTo:IsShown(), "listed while erasing")
typeTo("j")
stub.RunScript(to, "OnEscapePressed")
assert(not PolestarUIMailTo:IsShown() and to:HasFocus(), "Escape")
stub.RunScript(to, "OnEscapePressed")
assert(not to:HasFocus(), "the second Escape")
-- A click on a name takes it.
typeTo("j")
PolestarUIMailTo.rows[1]:Click()
assert(tostring(to:GetText()) == "Jaina" and not PolestarUIMailTo:IsShown(), "the click")
assert(not sendBtn:IsEnabled() and sendBtn.psReason == "Enter a subject.", "Send on with no subject")

-- Attachments: the cursor's item goes in, a right-click takes it out; the postage follows.
-- Never while a spell waits for its item.
local wells = send.Wells
local function attach(i, ...) stub.cursor = stub.mailItem(...); wells[i]:Click() end
local function detach(i) stub.RunScript(wells[i], "OnClick", "RightButton") end
local function subject() return tostring(send.Subject:GetText()) end
stub.targeting = true
attach(1, "Runecloth", 14047, 132903, 20, 1)
assert(not stub.sendItems[1], "attached while a spell waits for its item")
stub.targeting = false
-- The subject, as SendMailFrame_Update: the first item's name and stack.
attach(1, "Runecloth", 14047, 132903, 20, 1)
assert(subject() == "Runecloth (20)", "the subject not filled from the item: " .. subject())
attach(2, "Arcanite Bar", 12360, 133220, 1, 2)
assert(subject() == "Runecloth (20)", "a second item renamed it")
assert(tostring(wells[1].psCount:GetText()) == "20" and stub.sendItems[2], "attached")
assert(sendBtn:IsEnabled() and send.COD:IsEnabled(), "Send or COD off with To, a subject and an item")
assert(tostring(f.Subtitle:GetText()) == "2 of 12 attachments." and not send.COD.psTip, "the status: " .. tostring(f.Subtitle:GetText()))
-- Dropped on the page: the first free well.
stub.cursor = stub.mailItem("Thorium Bar", 12359, 133221, 5, 1)
stub.RunScript(send, "OnMouseUp")
assert(stub.sendItems[3] and stub.sendItems[3][1] == "Thorium Bar", "a drop on the page not attached")
assert(tostring(send.Postage.psParts[3].text:GetText()) == "90", "postage")
detach(3)
assert(not stub.sendItems[3] and tostring(send.Postage.psParts[3].text:GetText()) == "60", "taken back")
-- The first item out: the subject follows the next; the last out empties it.
detach(1)
assert(subject() == "Arcanite Bar", "the subject did not follow: " .. subject())
detach(2)
assert(subject() == "" and not send.COD:IsEnabled(), "the subject outlived the items: " .. subject())
-- A subject the player wrote stays, items in or out.
attach(1, "Runecloth", 14047, 132903, 20, 1)
send.Subject:SetText("Runecloth")
stub.RunScript(send.Subject, "OnTextChanged", true)
attach(2, "Arcanite Bar", 12360, 133220, 1, 2)
detach(1)
detach(2)
assert(subject() == "Runecloth", "the player's subject replaced: " .. subject())
attach(1, "Runecloth", 14047, 132903, 20, 1)
assert(subject() == "Runecloth", "the player's subject replaced on attach")

-- COD: 1g 50s, set as COD only.
send.Body:SetText("As asked.")
send.COD:Click()
local g = send.Money:GetChildren()
g:SetText("10001")
stub.RunScript(g, "OnTextChanged", true)
assert(send.CODError:IsShown() and not sendBtn:IsEnabled(), "a COD over the cap")
g:SetText("1")
stub.RunScript(g, "OnTextChanged", true)
assert(not send.CODError:IsShown() and sendBtn:IsEnabled(), "the cap error stayed")
assert(tostring(send.MoneyCaption:GetText()) == "COD amount", "the caption")
f.footerButtons.right[1]:Click()
assert(not sendBtn:IsEnabled(), "Send on while the server answers")
stub.fire("MAIL_SUCCESS")
assert(sendBtn:IsEnabled(), "Send stayed off")
assert(stub.sent and stub.sent.to == "Jaina" and stub.sent.subject == "Runecloth" and stub.sent.body == "As asked.", "not sent")
assert(stub.sent.cod == 10000 and stub.sent.money == 0, "COD set as money")
stub.fire("MAIL_SEND_SUCCESS")
assert(tostring(send.To:GetText()) == "" and tostring(send.MoneyCaption:GetText()) == "Money to send", "not emptied")

-- A refundable item: the client asks, ours answers.
stub.fire("MAIL_LOCK_SEND_ITEMS", 2, "item:12360")
assert(PolestarModal:IsShown() and tostring(PolestarModal.Box.Text:GetText()):find("Arcanite Bar"), "no refund dialog")
PolestarModal.Box.Cancel:Click()
assert(stub.lockAnswer[1] == 2 and stub.lockAnswer[2] == false, "cancel not sent")
stub.fire("MAIL_LOCK_SEND_ITEMS", 2, "item:12360")
PolestarModal.Box.Action:Click()
assert(stub.lockAnswer[2] == true, "accept not sent")
stub.fire("MAIL_LOCK_SEND_ITEMS", 2, "item:12360")
stub.fire("MAIL_UNLOCK_SEND_ITEMS")
assert(not PolestarModal:IsShown(), "the dialog outlived the unlock")

f.tabButtons[1]:Click()
assert(not stub.sendShowing, "the bags still attach on the inbox")
-- Trial accounts: no Send page.
stub.trial = true
PolestarUIMail:Hide()
stub.interact(T.MailInfo)
assert(not f.tabButtons[2]:IsShown() and tostring(f.Title:GetText()) == "Inbox", "a trial can send")
stub.trial = false
PolestarUIMail:Hide()
stub.interact(T.MailInfo)
f.tabButtons[2]:Click()

-- For the picture: a letter being written.
send.To:SetText("Thrall")
send.Subject:SetText("Silk for the front")
send.Body:SetText("Twenty bolts, as promised. More when the next shipment lands in Ratchet.")
attach(1, "Bolt of Silk Cloth", 4305, 132905, 20, 1)
