--@ title: Mail: an auction's invoice
--@ roots: PolestarUIMail, PolestarUIMailLetter
--@ stubs: stub_npc.lua, stub_mail.lua
-- An auction house letter shows its invoice under the text, as the stock letter: sold (the buyer, the sale price, the deposit back, the house cut in danger, what was received), won (the seller and what was paid), and a sale whose money is still on its way (pending, not yet sent, when it arrives). A sale with no buyer named says "Multiple buyers"; a stack names its count.
local T = Enum.PlayerInteractionType
stub.interact(T.MailInfo)
local f, L = PolestarUIMail, PolestarUIMailLetter
local function lines()
	local out = {}
	for _, r in ipairs({ L:GetRegions() }) do
		if r.GetText and r:IsShown() and r ~= L.Sender and r ~= L.Subject and r ~= L.Text and r ~= L.MoneyLabel then
			local t = r:GetText()
			if t and t ~= "" and not tonumber(t) then out[#out + 1] = tostring(t) end
		end
	end
	return table.concat(out, "|")
end
local function reopen()
	stub.fire("MAIL_INBOX_UPDATE")
	f.psInbox:GetChildren():Click()
end

-- Won: the seller and what was paid.
stub.inbox[1].invoice = { "buyer", "Silk Cloth", "Thrall", 30000, 30000, 0, 0, 0, nil, nil, 1, false }
reopen()
assert(lines() == "Item purchased: Silk Cloth|Sold by: Thrall|Amount paid:", "won: " .. lines())

-- Pending: no buyer named, a stack, the money on its way.
stub.inbox[1].invoice = { "seller_temp_invoice", "Linen Cloth", nil, 50000, 50000, 1250, 2500, 3600, 18, 5, 20, false }
reopen()
assert(lines() == "Item sold: Linen Cloth (20)|Purchased by: Multiple buyers|Pending funds:|Not yet sent.|The money arrives at 18:05.", "pending: " .. lines())
-- A pending sale's letter is never deleted as it closes.
stub.inbox[1].textCreated, stub.inbox[1][5] = true, 0
L.Close:Click()
assert(#stub.deleted == 0, "a pending sale deleted on close")
stub.inbox[1].textCreated, stub.inbox[1][5] = nil, 48750

-- Sold: the whole sum, the house cut in danger.
stub.inbox[1].invoice = { "seller", "Linen Cloth", "Arthas", 50000, 50000, 1250, 2500, 0, nil, nil, 1, false }
reopen()
assert(lines() == "Item sold: Linen Cloth|Purchased by: Arthas|Sale price:|Deposit:|Auction house cut:|Amount received:", "sold: " .. lines())
