-- What's Training? (WhatsTraining) loaded: its public WT_API (Api.lua, version 1)
-- with a few spells across its groups, for the preview's level 24 mage.
GetMoney = GetMoney or function() return 25000 end

local STATUS = {
	AVAILABLE = "available", MISSINGREQS = "missingReqs", NEXTLEVEL = "nextLevel", NOTLEVEL = "notLevel",
	MISSINGTALENT = "missingTalent", IGNORED = "ignored", KNOWN = "known", PET = "pet",
	WEAPON_AVAILABLE = "weaponAvailable", WEAPON_NEXTLEVEL = "weaponNextLevel", WEAPON_NOTLEVEL = "weaponNotLevel",
}

-- { id, name, rank, level, cost, status, quest }
local SPELLS = {
	{ 8413, "Fire Ward", "Rank 2", 24, 18000, "available" },
	{ 8406, "Frostbolt", "Rank 5", 24, 18000, "available" },
	{ 227, "Staves", nil, 1, 1000, "weaponAvailable" },
	{ 1463, "Mana Shield", "Rank 1", 20, 9000, "missingReqs" },
	{ 8444, "Flamestrike", "Rank 3", 26, 22000, "nextLevel" },
	{ 8417, "Arcane Missiles", "Rank 4", 26, 22000, "nextLevel" },
	{ 10, "Blizzard", "Rank 1", 20, 0, "notLevel", true },
	{ 12505, "Pyroblast", "Rank 2", 24, 18000, "missingTalent" },
	{ 168, "Frost Armor", "Rank 1", 1, 10, "known" },
	{ 116, "Frostbolt", "Rank 1", 4, 100, "ignored" },
}

local callbacks = {}
stub.wtCallbacks = callbacks

WT_API = {
	version = 1,
	Status = STATUS,
	IsReady = function() return true end,
	GetSpells = function()
		local out = {}
		for _, s in ipairs(SPELLS) do
			out[#out + 1] = { id = s[1], name = s[2], subText = s[3], level = s[4], cost = s[5], baseCost = s[5],
				status = s[6], quest = s[7] == true, isItem = false, icon = 135800 + #out }
		end
		return out
	end,
	RegisterCallback = function(owner, event, fn) callbacks[event] = fn end,
}

-- Fires a WT_API event, as its CallbackHandler registry does.
function stub.wtFire(event, ...) if callbacks[event] then callbacks[event](event, ...) end end
stub.wtSpells = SPELLS
