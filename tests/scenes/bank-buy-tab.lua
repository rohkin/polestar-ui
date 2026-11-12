--@ title: Bank: buying a bag slot
--@ roots: PolestarUIBank, PolestarModal
--@ stubs: stub_npc.lua, stub_bank.lua
-- A bag slot not bought yet buys the next: the game's prompt with its cost (red when the player cannot pay); Buy buys it, the strip gains the slot and the grid its slots, and the label's cost goes once no more can be bought. A bank with nothing bought yet (the Warband bank before its first) says what buying gives, with Buy and the cost in the footer. A client whose bank has tabs instead lists them under Character and Warband, with "Buy a tab" rows.
local T = Enum.PlayerInteractionType
stub.interact(T.Banker)
local f = PolestarUIBank
local function button(label)
	for _, side in ipairs({ "left", "right" }) do
		for _, b in ipairs(f.footerButtons[side]) do if b:IsShown() and tostring(b.Label:GetText()):find(label, 1, true) == 1 then return b end end
	end
end
local bags = { f.psStrip:GetChildren() }
bags[3]:Click()
assert(PolestarModal:IsShown() and PolestarModal.Box.Title:GetText() == "Purchase Bank Tab" and not stub.picked, "no prompt")
PolestarModal.Box.Action:Click()
assert(stub.boughtTab == 0, "not bought")
assert(bags[2]:GetAlpha() == 1 and #{ f.psGrid:GetChildren() } == 56, "the new bag slot and its slots not shown")
stub.tabCost[0] = nil
stub.fire("BANK_TABS_CHANGED", 0)
assert(tostring(f.psStripLabel:GetText()) == "Bag slots", "a cost with nothing to buy")

-- The Warband bank before its first: what buying gives, and its cost (more than the player has).
stub.bankTabs[2] = {}
f.navButtons[2]:Click()
assert(f.Title:GetText() == "Warband bank" and f.psNote:IsShown() and tostring(f.psNote:GetText()) == "Do you want to buy a new bank tab?", "no purchase prompt")
assert(not f.psStrip:IsShown() and not button("Clean up") and not button("Deposit all"), "a bank with nothing bought offers its slots")
button("Buy (1000g"):Click()
local cost
for _, c in ipairs({ PolestarModal.Box:GetChildren() }) do if c:IsShown() and c.psParts then cost = c end end
local r, g, b = cost.psParts[1].text:GetTextColor()
local dr, dg, db = Polestar.Theme.Color("danger")
assert(r == dr and g == dg and b == db and tostring(cost.psParts[1].text:GetText()) == "1000", "cost not in danger")
PolestarModal.Box.Cancel:Click()

-- A bank of tabs: each tab its own page, "Buy a tab" rows.
stub.bagMode = false
stub.tabCost[0] = 250000
stub.fire("BANK_TABS_CHANGED", 0)
local labels = {}
for _, nb in ipairs(f.navButtons) do if nb:IsShown() then labels[#labels + 1] = nb.Label:GetText() end end
assert(table.concat(labels, ",") == "Character,Gear,Herbs,Tab 3,Buy a tab,Warband,Buy a tab", "nav: " .. table.concat(labels, ","))
f.navButtons[3]:Click()
assert(f.Title:GetText() == "Herbs" and #{ f.psGrid:GetChildren() } >= 14 and f.psGrid:GetHeight() == 2 * 40 - 4 and not f.psStrip:IsShown(), "a tab's own page")
f.navButtons[5]:Click()
assert(PolestarModal:IsShown() and f.Title:GetText() == "Herbs", "the buy row was selected")
PolestarModal.Box.Cancel:Click()
stub.bagMode = true
f.navButtons[1]:Click()
stub.fire("BANK_TABS_CHANGED", 0)
