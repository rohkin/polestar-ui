--@ title: Bank: the Warband bank
--@ roots: PolestarUIBank, PolestarModal
--@ stubs: stub_npc.lua, stub_bank.lua
-- At a Warband banker only the Warband bank is viewable: its slots, what it holds in money, Clean up, Deposit money and Withdraw money beside Deposit all. Deposit all asks first (refundable items stop being refundable), and so does a refundable item placed on a slot: cancelled, the cursor is emptied; accepted, it goes in, unless the cursor now holds something else. The money dialogs take gold, silver and copper and move that much, and nothing for none. Another character holding the Warband bank locks it: it says so, with nothing to click.
local T = Enum.PlayerInteractionType
stub.bankViewable = { [2] = true }
stub.interact(T.AccountBanker)
local f = PolestarUIBank
assert(f:IsShown() and f.Title:GetText() == "Warband bank", "Warband bank not shown")
assert(f.navButtons[1].Label:GetText() == "Warband bank" and not (f.navButtons[2] and f.navButtons[2]:IsShown()), "the Bank listed at a Warband banker")
assert(tostring(f.Subtitle:GetText()) == "26 of 28 slots free. Holds 500g 0s 0c.", "subtitle: " .. tostring(f.Subtitle:GetText()))
local fb = {}
for _, side in ipairs({ "left", "right" }) do
	for _, b in ipairs(f.footerButtons[side]) do if b:IsShown() then fb[#fb + 1] = b end end
end
assert(#fb == 4 and tostring(fb[2].Label:GetText()) == "Deposit money" and fb[2]:IsEnabled() and fb[3]:IsEnabled(), "footer buttons: " .. #fb)

fb[4]:Click()
assert(PolestarModal:IsShown() and not stub.autoDeposited, "Deposit all did not ask")
PolestarModal.Box.Action:Click()
assert(stub.autoDeposited == 2, "Deposit all did not deposit into the Warband bank")

-- A refundable item placed on a slot asks first.
local wells = { f.psGrid:GetChildren() }
stub.held = { guid = "g1", refundable = true }
stub.RunScript(wells[3], "OnClick", "LeftButton")
assert(PolestarModal:IsShown() and not stub.picked, "placed without asking")
PolestarModal.Box.Cancel:Click()
assert(not stub.held and not stub.picked, "cancel left it on the cursor, or placed it")
stub.held = { guid = "g1", refundable = true }
stub.RunScript(wells[3], "OnReceiveDrag")
PolestarModal.Box.Action:Click()
assert(stub.picked and stub.picked[1] == 15 and stub.picked[2] == 3, "accepted, not placed")
stub.picked = nil
stub.RunScript(wells[3], "OnClick", "LeftButton")
stub.held = { guid = "g2", refundable = false }
PolestarModal.Box.Action:Click()
assert(not stub.picked, "placed what the cursor held instead")
stub.held = nil

fb[2]:Click()
PolestarModal.Box.Action:Click()
assert(not stub.moneyMoved, "deposited nothing")
fb[2]:Click()
local boxes = {}
for _, c in ipairs({ PolestarModal.Box:GetChildren() }) do
	if c:IsShown() and c.Set then boxes = { c:GetChildren() } end
end
boxes[1]:SetText("12")
stub.RunScript(boxes[1], "OnTextChanged", true)
PolestarModal.Box.Action:Click()
assert(stub.moneyMoved[1] == "deposit" and stub.moneyMoved[2] == 2 and stub.moneyMoved[3] == 120000, "deposit")

-- Nothing held: Withdraw money is off and says why.
stub.warbandMoney = 0
stub.fire("ACCOUNT_MONEY")
assert(not fb[3]:IsEnabled() and fb[3].psReason == "Your Warband bank holds no money.", "Withdraw money on with nothing held")
stub.warbandMoney = 5000000
stub.fire("ACCOUNT_MONEY")
assert(fb[3]:IsEnabled() and not fb[3].psReason, "Withdraw money stayed off")

-- Locked by another character: it says so; nothing to click.
stub.locked[2] = Enum.BankLockedReason.NoAccountInventoryLock
stub.fire("BANK_TABS_CHANGED", 2)
assert(f.psNote:IsShown() and tostring(f.psNote:GetText()):find("Another of your characters") and not f.Footer:IsShown() and not f.psGrid:GetChildren():IsShown(), "not locked")
stub.locked[2] = nil
stub.fire("BANK_TABS_CHANGED", 2)

fb[3]:Click()
assert(PolestarModal.Box.Text:GetText():find("500g"), "withdraw does not say what the bank holds")
for _, c in ipairs({ PolestarModal.Box:GetChildren() }) do
	if c:IsShown() and c.Set then boxes = { c:GetChildren() } end
end
boxes[2]:SetText("50")
stub.RunScript(boxes[2], "OnTextChanged", true)
assert(stub.moneyMoved[1] == "deposit", "moved before accept")
