--@ title: Bank
--@ roots: PolestarUIBank
--@ stubs: stub_npc.lua, stub_bank.lua
-- The banker opens ours, never the stock window, with the bags; closing ours ends the bank once, the game ending it closes ours without ending it again. The sidebar lists Character and Warband with their tabs; the grid shows the tab's slots with counts and quality borders; the search dims what does not match. Hovering a slot puts the secure overlay over it (right-click is the game's "item" action on that bag and slot, none on an empty slot), none in combat; a left-click picks up, a shift-click splits the stack on a stepper.
local T = Enum.PlayerInteractionType
local f = PolestarUIBank
assert(PolestarUI.modules.bank.reloadOff, "switching off does not wait for /reload")

stub.interact(T.Banker)
f = PolestarUIBank
assert(f and f:IsShown() and not BankFrame:IsShown(), "the banker did not open ours")
assert(stub.bagsOpen and stub.bagsOpener == "PolestarUIBank", "bags not opened by ours")
f:Hide()
assert(stub.npcClosed.CloseBankFrame == 1, "closing ours did not end the bank once")
assert(not stub.bagsOpen, "bags left open")
stub.interact(T.CharacterBanker)
stub.endInteraction(T.CharacterBanker)
assert(not f:IsShown() and stub.npcClosed.CloseBankFrame == 1, "the game's end did not close ours, or was ended again")

-- Nothing viewable: nothing opens, and the bank ends.
stub.bankViewable = {}
stub.interact(T.Banker)
assert(not f:IsShown() and stub.npcClosed.CloseBankFrame == 2, "opened with no bank to show")
stub.bankViewable = { [0] = true, [2] = true }

stub.interact(T.Banker)
local labels = {}
for _, b in ipairs(f.navButtons) do if b:IsShown() then labels[#labels + 1] = b.Label:GetText() end end
assert(table.concat(labels, ",") == "Character,Gear,Herbs,Buy a tab,Warband,Warband,Buy a tab", "nav: " .. table.concat(labels, ","))
assert(f.Title:GetText() == "Gear", "first tab not shown")
local wells = { f.psGrid:GetChildren() }
assert(#wells == 98 and f.psGrid:GetHeight() == 9 * 40 - 4, "98 slots, 11 to a row")
assert(tostring(wells[5].psCount:GetText()) == "20" and wells[6].Icon.desaturated, "count, locked")

-- The search is the client's: what does not match dims.
f.Search:SetText("cloth")
stub.RunScript(f.Search, "OnTextChanged")
assert(stub.search == "cloth", "search not sent")
assert(wells[5]:GetAlpha() == 1 and wells[1]:GetAlpha() < 1 and wells[4]:GetAlpha() == 1, "search does not dim")
f.Search:SetText("")
stub.RunScript(f.Search, "OnTextChanged")
assert(wells[1]:GetAlpha() == 1, "search left dimmed")

stub.RunScript(wells[2], "OnEnter")
local a = PolestarUIBankSlot
assert(a and a:IsShown(), "no overlay")
assert(a:GetAttribute("type2") == "item" and a:GetAttribute("item") == "6 2", "no move to bags")
stub.RunScript(wells[4], "OnEnter")
assert(a:GetAttribute("type2") == nil and a:GetAttribute("item") == "6 4", "empty slot")
stub.RunScript(a, "PostClick", "LeftButton")
assert(stub.picked[1] == 6 and stub.picked[2] == 4, "left-click did not pick up")
stub.inCombat = true
stub.fire("PLAYER_REGEN_DISABLED")
assert(not a:IsShown(), "overlay in combat")
stub.RunScript(wells[2], "OnEnter")
assert(not a:IsShown(), "overlay placed in combat")
stub.RunScript(wells[2], "OnClick", "LeftButton")
assert(stub.picked[2] == 2, "no pickup in combat")
stub.inCombat = false

stub.keys.shift = true
stub.RunScript(wells[5], "OnClick", "LeftButton")
stub.keys.shift = false
assert(PolestarModal:IsShown(), "no split dialog")
PolestarModal.Box.Action:Click()
assert(stub.split and stub.split[1] == 6 and stub.split[2] == 5 and stub.split[3] == 1, "split")

f.navButtons[3]:Click()
assert(f.Title:GetText() == "Herbs" and f.psGrid:GetHeight() == 9 * 40 - 4, "tab not switched")
f.navButtons[2]:Click()
