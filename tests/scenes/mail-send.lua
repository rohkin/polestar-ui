--@ title: Mail: send
--@ roots: PolestarUIMail
--@ stubs: stub_npc.lua, stub_mail.lua
-- The Send page. To suggests friends and guild members (our list, realm left off) as the player types; a pick fills it. The wells take the cursor's item (ClickSendMailItemButton), a right-click takes it back; the postage follows. Money or COD: the switch picks which the amount is, Send sets only that one and calls SendMail; MAIL_SEND_SUCCESS empties the page.
local T = Enum.PlayerInteractionType
stub.interact(T.MailInfo)
local f = PolestarUIMail
f.tabButtons[2]:Click()
assert(tostring(f.Title:GetText()) == "Send mail", "not on Send")
local inbox = f.psInbox
local send
for _, c in ipairs({ f.Body:GetChildren() }) do if c ~= inbox then send = c end end
assert(send:IsShown() and not inbox:IsShown(), "the pages did not switch")

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

-- Attachments: the cursor's item goes in, a right-click takes it out; the postage follows.
local wells = send.Wells
stub.cursor = stub.mailItem("Runecloth", 14047, 132903, 20, 1)
wells[1]:Click()
stub.cursor = stub.mailItem("Arcanite Bar", 12360, 133220, 1, 2)
wells[2]:Click()
stub.fire("MAIL_SEND_INFO_UPDATE")
assert(tostring(wells[1].psCount:GetText()) == "20" and stub.sendItems[2], "attached")
assert(tostring(send.Postage.psParts[3].text:GetText()) == "60", "postage")
stub.RunScript(wells[2], "OnClick", "RightButton")
stub.fire("MAIL_SEND_INFO_UPDATE")
assert(not stub.sendItems[2] and tostring(send.Postage.psParts[3].text:GetText()) == "30", "taken back")

-- COD: 1g 50s, set as COD only.
send.Subject:SetText("Runecloth")
send.Body:SetText("As asked.")
send.COD:Click()
local g = send.Money:GetChildren()
g:SetText("1")
stub.RunScript(g, "OnTextChanged", true)
assert(tostring(send.MoneyCaption:GetText()) == "COD amount", "the caption")
f.footerButtons.right[1]:Click()
assert(stub.sent and stub.sent.to == "Jaina" and stub.sent.subject == "Runecloth" and stub.sent.body == "As asked.", "not sent")
assert(stub.sent.cod == 10000 and stub.sent.money == 0, "COD set as money")
stub.fire("MAIL_SEND_SUCCESS")
assert(tostring(send.To:GetText()) == "" and tostring(send.MoneyCaption:GetText()) == "Money to send", "not emptied")

-- For the picture: a letter being written.
send.To:SetText("Thrall")
send.Subject:SetText("Silk for the front")
send.Body:SetText("Twenty bolts, as promised. More when the next shipment lands in Ratchet.")
stub.cursor = stub.mailItem("Bolt of Silk Cloth", 4305, 132905, 20, 1)
wells[1]:Click()
stub.fire("MAIL_SEND_INFO_UPDATE")
