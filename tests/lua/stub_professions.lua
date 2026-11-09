-- The client calls the Professions reads; the values are the preview's sample:
-- Tailoring and Mining (a bonus from gear), Cooking and First Aid, no Fishing.
-- Their spells sit in the spellbook after stub_spellbook.lua's.

-- { name, icon, rank, max, spells, modifier, skill line }
local PROFS = {
	{ "Tailoring", 1, 112, 150, { { "Tailoring", "Journeyman" } }, 0, 197 },
	{ "Mining", 1, 145, 150, { { "Smelting", "" }, { "Find Minerals", "" } }, 5, 186 },
	{ "Cooking", 1, 60, 75, { { "Cooking", "Apprentice" }, { "Basic Campfire", "" } }, 0, 185 },
	{ "First Aid", 1, 150, 150, { { "First Aid", "Journeyman" } }, 0, 129 },
}
local SPELLS, OFFSET = {}, {}
for i, p in ipairs(PROFS) do
	OFFSET[i] = 19 + #SPELLS
	for _, s in ipairs(p[5]) do SPELLS[#SPELLS + 1] = s end
end

-- Primary 1, primary 2, First Aid, Fishing, Cooking: as the stock page reads them.
function GetProfessions() return 1, 2, 4, nil, 3 end
function GetProfessionInfo(i)
	local p = PROFS[i]
	return p[1], p[2], p[3], p[4], #p[5], OFFSET[i], p[7], p[6], 0, 0
end

local bookInfo = C_SpellBook.GetSpellBookItemInfo
function C_SpellBook.GetSpellBookItemInfo(slot, bank)
	local s = bank == 0 and SPELLS[slot - 19]
	if not s then return bookInfo(slot, bank) end
	return { actionID = 100 + slot, spellID = 100 + slot, itemType = 1, name = s[1], subName = s[2], iconID = 1,
		isPassive = s[3] or false, isOffSpec = false }
end

function C_SkillInfo.AbandonSkill(skillLine) stub.abandoned = skillLine end

-- The game's window: our doors must not open it.
ProfessionsFrame = CreateFrame("Frame", "ProfessionsFrame", UIParent)
ProfessionsFrame:Hide()
function stub.bindingRun.TOGGLEPROFESSIONBOOK() ProfessionsFrame:Show() end
ProfessionMicroButton = CreateFrame("Button", "ProfessionMicroButton", UIParent)
ProfessionMicroButton.tooltipText = "Professions (K)"
