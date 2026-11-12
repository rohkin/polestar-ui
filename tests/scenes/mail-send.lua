--@ title: Mail: send
--@ roots: PolestarUIMail
--@ stubs: stub_npc.lua, stub_mail.lua
-- The Send page. To suggests friends and guild members (our list, realm left off) as the player types; a pick fills it. The wells take the cursor's item (ClickSendMailItemButton), a right-click takes it back; the postage follows. An item dropped on the page goes in the first free well, and the bags' right-click attaches while the page shows (SetSendMailShowing). The subject follows the first item until the player writes one. Money or COD: the switch picks which the amount is, and needs an item; a COD over 10,000 gold says so. Send is off until To and Subject are filled, and while the server answers; it sets only the money or the COD and calls SendMail; MAIL_SEND_SUCCESS empties the page. A trial account has no Send page.
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

-- To: typing "a" lists Anduin, Arator, Arthas; a pick fills the field.
send.To:SetText("a")
stub.RunScript(send.To, "OnTextChanged", true)
assert(PolestarMenu:IsShown(), "no suggestions")
local picks = {}
for _, r in ipairs(PolestarMenu.rows) do if r:IsShown() then picks[#picks + 1] = tostring(r.Text:GetText()) end end
table.sort(picks)
assert(table.concat(picks, ",") == "Anduin,Arator,Arthas", "suggestions: " .. table.concat(picks, ","))
send.To:SetText("jai")
stub.RunScript(send.To, "OnTextChanged", true)
assert(PolestarMenu.rows[1].Text:GetText() == "Jaina" and not PolestarMenu.rows[2]:IsShown(), "a friend in the guild twice")
PolestarMenu.rows[1]:Click()
assert(tostring(send.To:GetText()) == "Jaina" and not PolestarMenu:IsShown(), "the pick")
assert(not sendBtn:IsEnabled(), "Send on with no subject")

-- Attachments: the cursor's item goes in, a right-click takes it out; the postage follows.
local wells = send.Wells
stub.cursor = stub.mailItem("Runecloth", 14047, 132903, 20, 1)
wells[1]:Click()
stub.cursor = stub.mailItem("Arcanite Bar", 12360, 133220, 1, 2)
wells[2]:Click()
stub.fire("MAIL_SEND_INFO_UPDATE")
assert(tostring(wells[1].psCount:GetText()) == "20" and stub.sendItems[2], "attached")
assert(tostring(send.Subject:GetText()) == "Runecloth (20)" and sendBtn:IsEnabled() and send.COD:IsEnabled(), "the subject not filled from the item")
-- Dropped on the page: the first free well.
stub.cursor = stub.mailItem("Thorium Bar", 12359, 133221, 5, 1)
stub.RunScript(send, "OnMouseUp")
assert(stub.sendItems[3] and stub.sendItems[3][1] == "Thorium Bar", "a drop on the page not attached")
stub.sendItems[3] = nil
assert(tostring(send.Postage.psParts[3].text:GetText()) == "60", "postage")
stub.RunScript(wells[2], "OnClick", "RightButton")
stub.fire("MAIL_SEND_INFO_UPDATE")
assert(not stub.sendItems[2] and tostring(send.Postage.psParts[3].text:GetText()) == "30", "taken back")

-- COD: 1g 50s, set as COD only.
send.Subject:SetText("Runecloth")
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
stub.cursor = stub.mailItem("Bolt of Silk Cloth", 4305, 132905, 20, 1)
wells[1]:Click()
stub.fire("MAIL_SEND_INFO_UPDATE")
