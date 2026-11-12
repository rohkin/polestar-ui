--@ title: Trainer: a pet trainer
--@ roots: PolestarUITrainer
--@ stubs: stub_npc.lua, stub_trainer.lua
-- A pet trainer (C_Trainer.GetTrainerType = Pet): the pet heads the subject block, costs are training points at the money's place (danger when the pet has too few), the footer shows the points left with the stock tooltip, levels are the pet's, no categories (TrainerUI_UseCategories), and Train buys only what the points pay for.
stub.trainerType = 1
stub.points = { 30, 10 }
stub.petLevel = 22
stub.trainer = {
	{ "Bite", "used", 132278, 1, "Rank 2", "", 7 },
	{ "Bite", "available", 132278, 16, "Rank 3", "", 10 },
	{ "Claw", "available", 132140, 20, "Rank 3", "", 25 },
	{ "Growl", "unavailable", 132270, 30, "Rank 4", "", 15 },
}
stub.interact(Enum.PlayerInteractionType.Trainer)
local f = PolestarUITrainer
local rows = f.psRows
assert(f.psPoints:IsShown() and not f.psMoney:IsShown() and f.psPoints.Text:GetText() == "Training Points: 20", "the points left")
assert(rows[2].Points:IsShown() and rows[2].Points:GetText() == "10 TP" and not rows[2].Money:IsShown(), "a cost in points")
assert(rows[2].Sub:GetText() == "Requires Level 16" and rows[4].Sub:GetText():find("|c", 1, true), "the pet's level")
assert(not f.navButtons[2] or not f.navButtons[2]:IsShown(), "categories at a pet trainer")
local train = f.footerButtons.right[1]
assert(rows[2].Sel:IsShown() and train:IsEnabled(), "the first learnable")
stub.RunScript(rows[3], "OnClick")
assert(not train:IsEnabled(), "Train on for more points than the pet has")
stub.RunScript(f.psPoints, "OnEnter")
assert(GameTooltip:IsShown(), "no points tooltip")
stub.RunScript(f.psPoints, "OnLeave")
stub.RunScript(rows[2], "OnClick")
train:Click()
assert(stub.bought[1] == "Bite", "not bought")
