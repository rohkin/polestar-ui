--@ title: Trainer
--@ roots: PolestarUITrainer
--@ stubs: stub_npc.lua, stub_trainer.lua
-- The trainer opens ours (the service-type header skipped, needs as the stock row with each unmet part in danger, the player's money in the footer), never the stock window: Forever's TRAINER_SHOW route is stopped and the interaction taken; closing ours ends the trainer once, the game ending it closes ours without ending it again. The sidebar lists the categories with what can be learnt; the first learnable service is selected; Train buys it (BuyTrainerService), not one the player cannot afford or has not unlocked; at a profession trainer Train asks first.
local T = Enum.PlayerInteractionType
assert(PolestarUI.modules.trainer.reloadOff, "switching off does not wait for /reload")
assert(stub.unrouted.TRAINER_SHOW, "TRAINER_SHOW still routed")
stub.fire("TRAINER_SHOW")
assert(not ClassTrainerFrame:IsShown(), "the stock route opened the stock window")

stub.interact(T.Trainer)
local f = PolestarUITrainer
assert(f and f:IsShown() and not ClassTrainerFrame:IsShown(), "the trainer did not open ours")
assert(not stub.bagsOpen, "the trainer opens no bags")
f:Hide()
assert(stub.npcClosed.CloseTrainer == 1, "closing ours did not end the trainer once")
stub.interact(T.Trainer)
stub.endInteraction(T.Trainer)
assert(not f:IsShown() and stub.npcClosed.CloseTrainer == 1, "the game's end did not close ours, or was ended again")

stub.interact(T.Trainer)
local labels = {}
for _, b in ipairs(f.navButtons) do if b:IsShown() then labels[#labels + 1] = b.Label:GetText() .. "=" .. b.Count:GetText() end end
assert(table.concat(labels, ",") == "All=4,Arms=2,Fury=1,Protection=1", "nav: " .. table.concat(labels, ","))
assert(f.Title:GetText() == "Trainer", "title")
local rows = f.psRows
assert(rows[2].Sel:IsShown() and not rows[1].Sel:IsShown(), "the first learnable service not selected")
assert(rows[1].Sub:GetText() == "Already known" and not rows[1].Money:IsShown(), "a known spell")
local needs = rows[6].Sub:GetText()
assert(needs:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") == "Requires Level 28, Defensive Stance" and select(2, needs:gsub("|c", "")) == 2, "needs: " .. tostring(needs))
assert(select(2, rows[3].Sub:GetText():gsub("|c", "")) == 0, "a met level in danger")
-- The service-type header is no row; the client's selection follows ours.
local n = 0
for _, r in ipairs(rows) do if r:IsShown() then n = n + 1 end end
assert(n == 8, "rows: " .. n)
assert(stub.selected == 2, "SelectTrainerService not called for the selection")
assert(f.psMoney:IsShown() and not f.psPoints:IsShown(), "the player's money")

local train = f.footerButtons.right[1]
train:Click()
assert(stub.bought[1] == "Rend", "Train did not buy the selection")
-- Too dear (Shield Bash, 150g), not unlocked (Revenge): Train stays off.
stub.RunScript(rows[4], "OnClick")
assert(rows[4].Sel:IsShown() and not train:IsEnabled(), "Train on for a service the player cannot afford")
stub.RunScript(rows[5], "OnClick")
assert(not train:IsEnabled(), "Train on for an unavailable service")

-- A profession trainer: Train asks before it learns a profession.
stub.tradeskill = true
stub.trainer[2][8] = true
f:Hide()
stub.interact(T.Trainer)
train:Click()
assert(PolestarModal:IsShown() and #stub.bought == 1, "no profession confirm")
PolestarModal.Box.Action:Click()
assert(stub.bought[2] == "Rend", "confirm did not learn it")
stub.tradeskill = false
stub.trainer[2][8] = nil
f:Hide()
stub.interact(T.Trainer)
stub.RunScript(rows[3], "OnClick")
