--@ title: Bank: the Warband bank
--@ roots: PolestarUIBank, PolestarModal
--@ stubs: stub_npc.lua, stub_bank.lua
-- At a Warband banker only the Warband bank is viewable: its tab is shown, with Deposit money and Withdraw money beside Deposit all. Deposit all asks first (refundable items stop being refundable); the money dialogs take gold, silver and copper and move that much, and nothing for none.
local T = Enum.PlayerInteractionType
stub.bankViewable = { [2] = true }
stub.interact(T.AccountBanker)
local f = PolestarUIBank
assert(f:IsShown() and f.Title:GetText() == "Warband", "Warband tab not shown")
assert(f.navButtons[1].Label:GetText() == "Warband" and f.navButtons[1].psHeading, "Character listed at a Warband banker")
local fb = {}
for _, side in ipairs({ "left", "right" }) do
	for _, b in ipairs(f.footerButtons[side]) do if b:IsShown() then fb[#fb + 1] = b end end
end
assert(#fb == 3, "footer buttons: " .. #fb)

fb[3]:Click()
assert(PolestarModal:IsShown() and not stub.autoDeposited, "Deposit all did not ask")
PolestarModal.Box.Action:Click()
assert(stub.autoDeposited == 2, "Deposit all did not deposit into the Warband bank")

fb[1]:Click()
PolestarModal.Box.Action:Click()
assert(not stub.moneyMoved, "deposited nothing")
fb[1]:Click()
local boxes = {}
for _, c in ipairs({ PolestarModal.Box:GetChildren() }) do
	if c:IsShown() and c.Set then boxes = { c:GetChildren() } end
end
boxes[1]:SetText("12")
stub.RunScript(boxes[1], "OnTextChanged", true)
PolestarModal.Box.Action:Click()
assert(stub.moneyMoved[1] == "deposit" and stub.moneyMoved[2] == 2 and stub.moneyMoved[3] == 120000, "deposit")

fb[2]:Click()
assert(PolestarModal.Box.Text:GetText():find("500g"), "withdraw does not say what the bank holds")
for _, c in ipairs({ PolestarModal.Box:GetChildren() }) do
	if c:IsShown() and c.Set then boxes = { c:GetChildren() } end
end
boxes[2]:SetText("50")
stub.RunScript(boxes[2], "OnTextChanged", true)
assert(stub.moneyMoved[1] == "deposit", "moved before accept")
