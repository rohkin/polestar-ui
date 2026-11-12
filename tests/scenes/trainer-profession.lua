--@ title: Trainer: a profession trainer
--@ roots: PolestarUITrainer
--@ stubs: stub_npc.lua, stub_trainer.lua
-- A profession trainer: the rank in the band (the stock status bar's "Skill 75/150"); the next rank (GetTrainerServiceStepIndex, the stock skill step button) heads the list in every category; a new profession with both slots taken leaves Train off, and its tooltip says why.
stub.tradeskill = true
stub.rank = { 75, 150, 5 }
stub.professions = { 1, 2 }
stub.trainer = {
	{ "Bolt of Woolen Cloth", "available", 132882, 1, "", "Cloth", 200 },
	{ "Gray Woolen Shirt", "available", 135022, 1, "", "Shirts", 250, nil, { "Tailoring", 70, true } },
	{ "Heavy Woolen Gloves", "unavailable", 132149, 1, "", "Gloves", 300, nil, { "Tailoring", 85, false } },
	{ "Journeyman Tailoring", "available", 136249, 10, "", "", 500, true },
}
stub.step = 4
stub.interact(Enum.PlayerInteractionType.Trainer)
local f = PolestarUITrainer
local rows = f.psRows
assert(f.Subtitle:GetText():find("Skill 75 (+5)/150", 1, true), "rank: " .. tostring(f.Subtitle:GetText()))
assert(rows[1].Name:GetText() == "Journeyman Tailoring", "the next rank not first")
f.navButtons[4]:Click()
assert(rows[1].Name:GetText() == "Journeyman Tailoring" and rows[2].Name:GetText() == "Gray Woolen Shirt", "the next rank not in the category")
f.navButtons[1]:Click()
local train = f.footerButtons.right[1]
stub.RunScript(rows[1], "OnClick")
assert(not train:IsEnabled(), "Train on with no profession slot")
stub.RunScript(train, "OnEnter")
assert(GameTooltip:IsShown(), "no reason given")
stub.RunScript(train, "OnLeave")
assert(rows[3].Sub:GetText() == "Requires Tailoring (70)", "skill need: " .. tostring(rows[3].Sub:GetText()))
