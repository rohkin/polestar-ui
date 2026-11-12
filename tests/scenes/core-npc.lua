--@ title: Core: an NPC window
--@ roots: PolestarUITestNPC
--@ stubs: stub_npc.lua
-- The NPC windows' shared parts on a test window. ns.Interaction: the stock route stopped (TRAINER_SHOW opens nothing), the interaction opens ours and the bags, never the stock window; the player closing ours ends the interaction once, the game ending it closes ours without ending it again, the bags close with it; off waits for /reload. ns.SubjectBlock heads the sidebar; W.ShellTabs switches its pages. ns.ItemGrid with ns.PaintItem shows the backpack (C_Container): quality borders from uncommon up, stack counts, a locked item desaturated, an unusable one red. ns.Money writes coins as the game does (units at zero left out), in a colour token.
local ns, W = PolestarUI, Polestar.Widgets
local T = Enum.PlayerInteractionType
local M, f, tab, grid, money = {}, nil, "buy", nil, {}
ns.Module("testnpc", M)

local function paint()
	W.ShellTabs(f, { { key = "buy", label = "Buy" }, { key = "buyback", label = "Buyback" } }, tab, function(k) tab = k; paint() end)
	W.ShellTitle(f, tab == "buy" and "Buy" or "Buyback", "Click an item to buy it.")
	local wells = grid.Layout(C_Container.GetContainerNumSlots(0))
	local h = grid:GetHeight()
	for i, w in ipairs(wells) do
		local it = C_Container.GetContainerItemInfo(0, i)
		ns.PaintItem(w, it and { icon = it.iconFileID, quality = it.quality, count = it.stackCount, desat = it.isLocked, unusable = i == 3 })
	end
	ns.SetMoney(money[1], GetMoney())
	ns.SetMoney(money[2], 10005, "danger")
	ns.SetMoney(money[3], 0)
	money[1]:ClearAllPoints()
	money[1]:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -(24 + h + 16))
	W.ShellFooter(f, {}, {})
	W.ShellBody(f, 24 + h + 16 + 3 * 22)
end

function M.Show()
	if not f then
		f = W.Shell("PolestarUITestNPC", { scalePath = "ui.menuScale", width = 760, height = 600 })
		local b = ns.SubjectBlock(f)
		b.icon:SetTexture(136240)
		b.name:SetText("Test NPC")
		b.line:SetText("Trainer")
		grid = ns.ItemGrid(f.Body, 8, 36, 4)
		grid:SetPoint("TOPLEFT", f.Body, "TOPLEFT", W.SHELL.pad, -24)
		for i = 1, 3 do
			money[i] = ns.Money(f.Body)
			if i > 1 then money[i]:SetPoint("TOPLEFT", money[i - 1], "BOTTOMLEFT", 0, -8) end
		end
	end
	paint()
	f:Show()
end

ns.Interaction("testnpc", { T.Trainer }, { frame = "PolestarUITestNPC", close = CloseTrainer, internal = { "TRAINER_SHOW" }, bags = true })
assert(M.reloadOff, "switching off does not wait for /reload")
assert(stub.unrouted.TRAINER_SHOW, "the stock route is still there")
stub.fire("TRAINER_SHOW")
assert(not ClassTrainerFrame:IsShown(), "the stock route opened the stock window")

stub.interact(T.Trainer)
assert(PolestarUITestNPC:IsShown() and not ClassTrainerFrame:IsShown(), "the interaction did not open ours")
assert(stub.bagsOpen and stub.bagsOpener == "PolestarUITestNPC", "bags not opened by ours")
PolestarUITestNPC:Hide()
assert(stub.npcClosed.CloseTrainer == 1, "closing ours did not end the interaction once")
assert(not stub.bagsOpen, "bags left open")

stub.interact(T.Trainer)
stub.endInteraction(T.Trainer)
assert(not PolestarUITestNPC:IsShown(), "the game's end did not close ours")
assert(stub.npcClosed.CloseTrainer == 1, "the game's end was ended again")
assert(not stub.bagsOpen, "bags left open")

stub.interact(T.Trainer)
f.tabButtons[2]:Click()
assert(tab == "buyback" and f.Title:GetText() == "Buyback", "the tab did not switch")
f.tabButtons[1]:Click()
assert(tab == "buy" and f.tabButtons[1]:IsShown(), "back to Buy")
local wells = grid.Layout(16)
assert(grid:GetHeight() == 2 * 40 - 4, "grid height")
assert(tostring(wells[1].psCount:GetText()) == "20" and not wells[2].psCount, "stack counts")
assert(wells[6].Icon.desaturated and not wells[1].Icon.desaturated, "locked item not desaturated")
assert(money[2].psParts[2].text:IsShown() == false and tostring(money[2].psParts[1].text:GetText()) == "1", "1g 5c leaves out silver")
assert(tostring(money[3].psParts[3].text:GetText()) == "0" and not money[3].psParts[1].text:IsShown(), "none is 0 copper")
