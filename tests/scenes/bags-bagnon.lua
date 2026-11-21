--@ title: Bags: blocked beside Bagnon
--@ roots: ContainerFrameCombinedBags
--@ stubs: stub_bags.lua, stub_bagnon.lua
-- With Bagnon loaded, our Bags and Bank stay off and cannot switch on: Bagnon's own bag and bank windows take the keys. Shown: the stock bags B opened (Bagnon's, in game).
assert(not PolestarUI.Enabled("bags"), "bags on beside Bagnon")
assert(not PolestarUI.Enabled("bank"), "bank on beside Bagnon")
stub.pressKey("B")
assert(ContainerFrameCombinedBags:IsVisible() and not PolestarUIBags, "B opened ours")
-- Refused, with one line saying why; /pui bags does not open ours either.
local said = {}
print = function(m) said[#said + 1] = m end
PolestarUI.Switch("bags", true)
assert(not PolestarUI.Enabled("bags") and not PolestarUIBags, "switched on beside Bagnon")
assert(#said == 1 and said[1]:find("off while Bagnon is loaded"), "no refusal line")
assert(PolestarUIDB.modules.bags == nil, "the refusal saved a choice")
PolestarUI.Show("bags")
assert(not PolestarUIBags, "Show built ours")
-- Its settings toggle: off, greyed, the reason as its help.
local toggle, bank, note
Polestar.Widgets.OnOptionsRegistered(function(spec)
	local c = spec.key == "polestarui" and spec.controls or {}
	for i, x in ipairs(c) do
		if x.label == "Bags" then toggle = x end
		if x.label == "Bank" then bank = x end
		if x.label == "Bags" or x.label == "Bank" then note = c[i + 1] end
	end
	-- The pair sits side by side (first two rows, a column boundary) with one shared note after it.
	if c[1] and c[1].label == "Bank" then assert(c[1] and c[2] and not c[1].wide and not c[2].wide and c[3] == note and c[3].wide, "pair not first and adjacent") end
end)
assert(note and note.label == "Bags and Bank are off while Bagnon is loaded: its own bags and bank take their place." and note.disabled(), "no shared note after the pair")
assert(bank and bank.get() == false and bank.disabled and bank.disabled(), "the Bank toggle is not off and greyed")
assert(toggle and toggle.get() == false and toggle.disabled and toggle.disabled(), "the Bags toggle is not off and greyed")
assert(toggle.help:find("Bagnon"), "no reason: " .. toggle.help)
stub.assertNoErrors()
--@ panel
--@ roots: ContainerFrameCombinedBags
--@ stubs: stub_bags.lua, stub_bagnon.lua
--@ saved: PolestarUIDB = { modules = { bags = true, bank = true } }
-- Switched on before Bagnon came: the block wins over the saved choice.
assert(not PolestarUI.Enabled("bags"), "the saved choice beat the block (bags)")
assert(not PolestarUI.Enabled("bank"), "the saved choice beat the block (bank)")
stub.pressKey("B")
assert(ContainerFrameCombinedBags:IsVisible() and not PolestarUIBags, "B opened ours")
stub.assertNoErrors()
