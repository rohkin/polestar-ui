--@ title: Crafting: tool and gear slots
--@ roots: PolestarUICrafting
--@ stubs: stub_spellbook.lua, stub_professions.lua, stub_crafting.lua
-- Where the client lists slots for the profession (GetProfessionSlots), its tool and gear slots on the band left of Options, as the stock page: right to left the tool, then its gear; a click picks the worn item up; the secure button over a slot uses it on right-click. Without slot data, none show.
stub.openTradeSkill()
local f = PolestarUICrafting
assert(not f.psGear or not next(f.psGear), "slots without slot data")
f:Hide()
stub.profSlots = true
stub.openTradeSkill()
local tool, g0, g1 = f.psGear.Prof0ToolSlot, f.psGear.Prof0Gear0Slot, f.psGear.Prof0Gear1Slot
assert(tool:IsShown() and g0:IsShown() and g1:IsShown(), "no slots")
local function x(s) return select(4, s:GetPoint(1)) end
assert(x(tool) - x(g0) == 28 + 12 and x(g0) - x(g1) == 28 + 4, ("not tool, then its gear: %s %s %s"):format(x(tool), x(g0), x(g1)))
tool:Click("LeftButton")
assert(stub.pickedUp == 20, "no pickup")
stub.RunScript(tool, "OnEnter")
local o = PolestarUICraftingGear
assert(o:IsShown() and o:GetAttribute("type2") == "item" and o:GetAttribute("item") == "20", "no use")
