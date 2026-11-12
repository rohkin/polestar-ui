--@ title: Bank
--@ roots: PolestarUIBank
--@ stubs: stub_npc.lua, stub_bank.lua
-- The banker opens ours, never the stock window, with the bags; closing ours ends the bank once, the game ending it closes ours without ending it again. Forever's bank holds bags: the sidebar lists the Bank and the Warband bank; the grid shows every bought bag's slots with counts, quality borders and quest marks, the subtitle how many are free; the search dims what does not match. Above the grid, the bank's bag slots: a bag in one shows its tooltip and lights its slots below, a click picks it up or puts one in, a slot not bought is faded, its tooltip names the next one's cost (as the label above does) and a click buys it. Hovering a slot puts the secure overlay over it (right-click is the game's "item" action on that bag and slot, none on an empty slot), none in combat; a left-click picks up, a shift-click splits the stack on a stepper. Clean up sorts the bank, asking first until told not to.
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
assert(table.concat(labels, ",") == "Bank,Warband bank", "nav: " .. table.concat(labels, ","))
assert(f.Title:GetText() == "Bank" and tostring(f.Subtitle:GetText()) == "35 of 42 slots free.", "the bank, its free slots")
local wells = { f.psGrid:GetChildren() }
assert(#wells == 42 and wells[42]:IsShown() and f.psGrid:GetHeight() == 4 * 40 - 4, "both bags' 42 slots, 11 to a row")
assert(tostring(wells[5].psCount:GetText()) == "20" and wells[6].Icon.desaturated, "count, locked")
assert(wells[29].psBag == 7 and wells[29].psSlot == 1 and wells[29].psQuest:IsShown() and not wells[1].psQuest:IsShown(), "the second bag, its quest mark")

-- The bag slots: the Runecloth Bag in the first, the rest not bought.
local bags = { f.psStrip:GetChildren() }
assert(#bags == 5 and bags[1]:GetAlpha() == 1 and bags[2]:GetAlpha() < 1, "five bag slots, one bought")
stub.RunScript(bags[1], "OnEnter")
assert(GameTooltip.lines[1] == "item 4002" and wells[29].psGlow:IsShown() and wells[42].psGlow:IsShown() and not wells[28].psGlow:IsShown(), "the bag's tooltip or its slots not lit")
stub.RunScript(bags[1], "OnLeave")
assert(not wells[29].psGlow:IsShown(), "slots left lit")
stub.RunScript(bags[2], "OnEnter")
assert(GameTooltip.lines[1] == "Bag slot not bought yet" and GameTooltip.lines[2] == "The next costs 25g 0s 0c.", "an unbought slot's tooltip")
assert(tostring(f.psStripLabel:GetText()) == "Bag slots (the next costs 25g 0s 0c)", "the next slot's cost")
bags[1]:Click()
assert(stub.picked[1] == -2 and stub.picked[2] == 2, "the bag not picked up")

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

-- The footer: clean up, deposit all.
local left = f.footerButtons.left
assert(tostring(left[1].Label:GetText()) == "Clean up" and not (left[2] and left[2]:IsShown())
	and tostring(f.footerButtons.right[1].Label:GetText()) == "Deposit all", "the footer")
-- Clean up asks; "Do not ask again" ticked, the next one sorts at once.
left[1]:Click()
assert(PolestarModal:IsShown() and not stub.sorted, "sorted without asking")
for _, c in ipairs({ PolestarModal.Box:GetChildren() }) do if c:IsShown() and rawget(c, "Check") then c.Check:SetChecked(true) end end
PolestarModal.Box.Action:Click()
assert(stub.sorted == 0 and stub.cvars.bankConfirmTabCleanUp == "0", "not sorted, or asked again")
stub.sorted = nil
left[1]:Click()
assert(stub.sorted == 0 and not PolestarModal:IsShown(), "asked again")
