--@ title: Trainer
--@ roots: PolestarUITrainer
--@ stubs: stub_npc.lua, stub_trainer.lua
-- The trainer opens ours, never the stock window: Forever's TRAINER_SHOW route is stopped and the interaction taken; closing ours ends the trainer once, the game ending it closes ours without ending it again. The sidebar lists the categories with what can be learnt; the first learnable service is selected; Train buys it (BuyTrainerService), not one the player cannot afford or has not unlocked; at a profession trainer Train asks first. Polestar's Train All (a Shift-click says Shift stops it) shows only at a class trainer of the player's class with its button setting on, never at a profession trainer.
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
assert(table.concat(labels, ",") == "All=4,Arms=2,Protection=1,Fury=1", "nav: " .. table.concat(labels, ","))
assert(f.Title:GetText() == "Trainer", "title")
local rows = f.psRows
assert(rows[2].Sel:IsShown() and not rows[1].Sel:IsShown(), "the first learnable service not selected")
assert(rows[1].Sub:GetText() == "Known" and not rows[1].Money:IsShown(), "a known spell")
assert(rows[6].Sub:GetText() == "Requires level 28, Defensive Stance", "needs: " .. tostring(rows[6].Sub:GetText()))

local train, all = f.footerButtons.right[1], f.footerButtons.right[2]
assert(all and all:IsShown() and all.Label:GetText() == "Train all", "no Train all at a class trainer")
train:Click()
assert(stub.bought[1] == "Rend", "Train did not buy the selection")
-- Shift stops Polestar's run: a Shift-click says so and starts nothing.
stub.keys.shift = true
all:Click()
stub.keys.shift = false
assert(stub.trainAllRuns == 0 and stub.uiError and stub.uiError:find("Shift"), "Shift-click on Train all is silent")
all:Click()
assert(stub.trainAllRuns == 1, "Train all did not start Polestar's run")
-- Too dear (Shield Bash, 150g), not unlocked (Revenge): Train stays off.
stub.RunScript(rows[4], "OnClick")
assert(rows[4].Sel:IsShown() and not train:IsEnabled(), "Train on for a service the player cannot afford")
stub.RunScript(rows[5], "OnClick")
assert(not train:IsEnabled(), "Train on for an unavailable service")

-- Train all: off with the setting, off at a trainer not of the player's class.
stub.trainAllButton = false
stub.fire("TRAINER_UPDATE")
assert(not all:IsShown(), "Train all with its setting off")
stub.trainAllButton = true
local guid = UnitGUID
UnitGUID = function() return "Creature-0-4372-0-17-3153-0000123456" end
stub.fire("TRAINER_UPDATE")
assert(not all:IsShown(), "Train all at another class's trainer")
UnitGUID = guid

-- A profession trainer: no Train all; Train asks before it learns a profession.
stub.tradeskill = true
stub.trainer[2][8] = true
f:Hide()
stub.interact(T.Trainer)
assert(not all:IsShown(), "Train all at a profession trainer")
train:Click()
assert(PolestarModal:IsShown() and #stub.bought == 1, "no profession confirm")
PolestarModal.Box.Action:Click()
assert(stub.bought[2] == "Rend", "confirm did not learn it")
stub.tradeskill = false
stub.trainer[2][8] = nil
f:Hide()
stub.interact(T.Trainer)
stub.RunScript(rows[3], "OnClick")
