-- The client's trainer as the Trainer sees it (Blizzard_TrainerUI, Camelot's
-- categories): the services, their costs and needs, the type filter, the
-- trainer's unit. Load after stub_npc.lua (the
-- interaction manager, TRAINER_SHOW's route, CloseTrainer, money).

-- Services: { name, kind, icon, reqLevel, rank, category, cost, profession?, skill req?, ability req? }.
stub.trainer = {
	{ "Heroic Strike", "used", 132282, 1, "Rank 3", "Arms", 0 },
	{ "Rend", "available", 132155, 20, "Rank 3", "Arms", 6000 },
	{ "Overpower", "available", 132223, 24, "Rank 2", "Arms", 20000 },
	{ "Shield Bash", "available", 132357, 12, "Rank 2", "Protection", 1500000 },
	{ "Revenge", "unavailable", 132353, 26, "Rank 3", "Protection", 22000 },
	{ "Shield Wall", "unavailable", 132362, 28, "", "Protection", 25000, nil, nil, { "Defensive Stance", false } },
	{ "Cleave", "available", 132338, 20, "Rank 2", "Fury", 9000 },
	{ "Intercept", "unavailable", 132307, 30, "Rank 1", "Fury", 30000 },
	-- A service-type header, as old trainers list: never a row.
	{ "Warrior Skills", "header", nil, 0, "", "", 0 },
}
stub.tradeskill = false
stub.trainerType = 0
stub.typeFilter = { available = true, unavailable = true, used = true }
stub.bought = {}

-- The list honours the type filter, as the client's does.
local function shown()
	local out = {}
	for _, s in ipairs(stub.trainer) do if s[2] == "header" or stub.typeFilter[s[2]] then out[#out + 1] = s end end
	return out
end
function GetNumTrainerServices() return #shown() end
function GetTrainerServiceInfo(i)
	local s = shown()[i]
	if s then return s[1], s[2], s[3], s[4], s[5], s[6] end
end
function GetTrainerServiceCost(i) local s = shown()[i]; return s and s[7] or 0, s and s[8] or false end
function GetTrainerServiceSkillReq(i) local r = shown()[i][9]; if r then return r[1], r[2], r[3] end end
function GetTrainerServiceNumAbilityReq(i) return shown()[i][10] and 1 or 0 end
function GetTrainerServiceAbilityReq(i) local r = shown()[i][10]; return r[1], r[2] end
function GetTrainerServiceSkillLine(i) return shown()[i][1] end
function GetTrainerServiceTypeFilter(k) return stub.typeFilter[k] end
function SetTrainerServiceTypeFilter(k, on) stub.typeFilter[k] = on and true or false end
function IsTradeskillTrainer() return stub.tradeskill end
function BuyTrainerService(i) stub.bought[#stub.bought + 1] = shown()[i][1] end
stub.professions = {}
PROFESSION_CONFIRMATION1 = "Do you really want to learn %s as your first profession?"
PROFESSION_CONFIRMATION2 = "Do you really want to learn %s as your second profession?"
function GetProfessions() return stub.professions[1], stub.professions[2] end
Enum.TrainerType = { Normal = 0, Pet = 1 }
-- The stock list's Categorize setting (account-wide, on by default).
stub.categorize = true
C_Trainer = { GetTrainerType = function() return stub.trainerType end,
	GetCategorizeTrainerUI = function() return stub.categorize end, SetCategorizeTrainerUI = function(on) stub.categorize = on end }
-- The client's selection (SelectTrainerService), a profession's next rank
-- (stub.step: its index) and rank values (stub.rank = { rank, max, modifier }).
function SelectTrainerService(i) stub.selected = i end
function GetTrainerServiceStepIndex() return stub.step end
function GetTrainerTradeskillRankValues() if stub.rank then return unpack(stub.rank) end return 0, 0, 0 end
-- A pet trainer: costs in the pet's training points (stub.points = { total, used }), its level.
stub.points = { 0, 0 }
C_PetInfo = C_PetInfo or {}
function C_PetInfo.GetPetTrainingPoints() return stub.points[1], stub.points[2] end
local unitLevel = UnitLevel
function UnitLevel(unit) if unit == "pet" then return stub.petLevel or 20 end return unitLevel(unit) end
stub.Methods.SetMotionScriptsWhileDisabled = stub.Methods.SetMotionScriptsWhileDisabled or function(self, on) self.motionWhileDisabled = on end
REQUIRES_LABEL, TRAINER_REQ_LEVEL, ITEM_SPELL_KNOWN = "Requires", "Level %d", "Already known"
TRAINING_POINTS, TRAINING_POINTS_ABBREV, TRAINING_POINTS_TUTORIAL = "Training Points: %d", "%s TP", "Your pet spends training points to learn new abilities."
TRADESKILL_RANK, TRADESKILL_RANK_WITH_MODIFIER = "Skill %d/%d", "Skill %d (+%d)/%d"
TRAINER_CANNOT_EXCEED_MAX_PROFESSIONS, CATEGORIZE = "You can only learn two professions.", "Categorize"
GameTooltip.SetTrainerService = GameTooltip.SetTrainerService or function(self, i) self:SetText(shown()[i][1]) end

-- The trainer: Thurman, npc 914, a warrior trainer.
local unitName = UnitName
function UnitName(unit, ...)
	if unit == "npc" then return "Thurman Schneider" end
	if unit == "pet" and stub.trainerType == 1 then return "Grimclaw" end
	return unitName(unit, ...)
end
function UnitGUID(unit) if unit == "npc" then return "Creature-0-4372-0-17-914-0000123456" end end
function SetPortraitTexture(tex, unit) tex:SetTexture(132355) end

-- Polestar's class-trainer check (Engine.IsClassTrainer, Compat.GetNpcID: the
-- preview's Engine and Compat are stub_ui's), put in at login, after stub_ui installs them.
local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function()
	Polestar.Engine.IsClassTrainer = function(npc) return npc == 914 end
	Polestar.Compat.GetNpcID = function(unit) return tonumber((select(6, strsplit("-", UnitGUID(unit) or "")))) end
end)
